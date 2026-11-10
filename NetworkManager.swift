import Foundation
import Combine
import MultipeerConnectivity
import os

#if os(iOS)
import UIKit
import Photos
#elseif os(tvOS)
import UIKit
#endif

let transferLog = Logger(subsystem: "com.talat.imeds", category: "transfer")

final class NetworkManager: NSObject, ObservableObject {
    private let serviceType = "imeds-transfer"

    private let myPeerId: MCPeerID
    private var session: MCSession
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser

    /// Alınan dosyaların yazıldığı klasör. İlk erişimde çözümlenir ve
    /// yazma testinden geçen ilk aday kullanılır.
    private lazy var receivedDirectory: URL = resolveReceivedDirectory()

    @Published var connectedPeers: [MCPeerID] = []
    @Published var selectedPeer: MCPeerID?
    @Published var receivedFiles: [SharedFile] = []

    @Published var isSending = false
    @Published var isReceiving = false
    @Published var transferProgress: Double = 0.0
    /// Aktarılan / toplam bayt ve anlık hız (bayt/sn). Gönderim ve alım
    /// ilerlemesini kullanıcıya sayısal olarak göstermek için tutulur.
    @Published var transferredBytes: Int64 = 0
    @Published var totalTransferBytes: Int64 = 0
    @Published var transferSpeed: Double = 0
    @Published var lastError: String?

    /// Aynı eşe art arda davet göndermemek için.
    private var invitedPeers = Set<MCPeerID>()
    private var retriedPeers = Set<MCPeerID>()
    /// Tarayıcının gördüğü eşler; iptal sonrası yeniden davet için kullanılır.
    private var discoveredPeers = Set<MCPeerID>()
    private var receiveProgressObservation: NSKeyValueObservation?
    private var sendProgress: Progress?
    private var receiveProgress: Progress?
    private var userCancelledTransfer = false

    /// Progress KVO'ları arka planda gelebilir; hız hesabı ve arayüz
    /// güncellemeleri bu seri kuyrukta sıraya alınır.
    private let progressQueue = DispatchQueue(label: "com.talat.imeds.transfer-progress")
    private var lastProgressRefresh = Date.distantPast
    private var speedSample: (time: Date, bytes: Int64)?
    private var smoothedSpeed: Double = 0

    #if os(iOS)
    /// Aktarım sırasında uygulamanın askıya alınmasını geciktiren arka plan görevi.
    private var transferBackgroundTask: UIBackgroundTaskIdentifier = .invalid
    #endif

    override init() {
        #if os(macOS)
        let displayName = Host.current().localizedName ?? "Mac"
        #else
        let displayName = UIDevice.current.name
        #endif

        self.myPeerId = MCPeerID(displayName: displayName)
        self.session = MCSession(peer: myPeerId,
                                 securityIdentity: nil,
                                 encryptionPreference: .required)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId,
                                                           discoveryInfo: nil,
                                                           serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId,
                                                     serviceType: serviceType)

        super.init()

        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self

        prepareReceivedDirectory()
        loadReceivedFiles()
        cleanupOutgoingFiles()

        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }

    deinit {
        serviceBrowser.stopBrowsingForPeers()
        serviceAdvertiser.stopAdvertisingPeer()
        session.disconnect()
        receiveProgressObservation?.invalidate()
    }

    // MARK: - Gönderim

    func sendFile(url: URL, to peer: MCPeerID? = nil) {
        guard let target = peer ?? selectedPeer ?? connectedPeers.first else {
            publishError("Gönderilecek bir cihaz seçili değil.")
            return
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            publishError("Gönderilecek dosya bulunamadı. Lütfen dosyayı yeniden seçin.")
            return
        }

        let name = url.lastPathComponent.isEmpty ? "Dosya" : url.lastPathComponent
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int64 ?? 0

        // Gönderim sırasında eski hata mesajı ekranda kalmasın.
        lastError = nil

        DispatchQueue.main.async {
            self.isSending = true
            self.transferProgress = 0
            self.transferredBytes = 0
            self.totalTransferBytes = fileSize
            self.transferSpeed = 0
            self.updateTransferActivity()
        }

        let activeSession = session
        let progress = activeSession.sendResource(at: url, withName: name, toPeer: target) { [weak self] error in
            DispatchQueue.main.async {
                guard let self, self.session === activeSession else { return }

                self.isSending = false
                self.sendProgress = nil

                if let error {
                    transferLog.error("Gönderim hatası: \(error.localizedDescription, privacy: .public)")
                    if !self.userCancelledTransfer {
                        self.lastError = "Gönderim hatası: \(error.localizedDescription)"
                    }
                } else {
                    self.lastError = nil
                    self.transferProgress = 1
                }
                self.userCancelledTransfer = false
                self.updateTransferActivity()
            }

            // ÖNEMLİ: Geçici dosyayı burada silmiyoruz. MCSession dosyayı
            // okumayı bitirmeden silinirse alıcı tarafta "daha yazılacak
            // bayt varken akış kapandı" hatası oluşuyor. Temizlik uygulama
            // açılışında cleanupOutgoingFiles() ile yapılıyor.
        }

        sendProgress = progress

        if let progress {
            observeTransferProgress(progress, fallbackTotalBytes: fileSize)
        } else {
            transferLog.error("Gönderim ilerlemesi alınamadı (Progress nil).")
        }
    }

    /// `MCSession`'ın döndürdüğü `Progress` nesnesini izler; yüzde, bayt ve
    /// anlık hız bilgisini arayüze taşır. KVO arka plan kuyruğunda gelebilir,
    /// bu yüzden güncellemeler `progressQueue` üzerinden sıraya alınır.
    private func observeTransferProgress(_ progress: Progress, fallbackTotalBytes: Int64) {
        receiveProgressObservation?.invalidate()

        progressQueue.sync {
            lastProgressRefresh = .distantPast
            speedSample = nil
            smoothedSpeed = 0
        }

        let initialTotal = progress.totalUnitCount > 0 ? progress.totalUnitCount : fallbackTotalBytes
        DispatchQueue.main.async {
            self.totalTransferBytes = initialTotal
            self.transferredBytes = 0
            self.transferSpeed = 0
        }

        receiveProgressObservation = progress.observe(\.fractionCompleted, options: [.initial, .new]) { [weak self] progress, _ in
            guard let self else { return }

            let fraction = progress.fractionCompleted

            // Bazı durumlarda (özellikle alım tarafında) `totalUnitCount` 0
            // geliyor. O zaman toplam boyutu tamamlanan bayt / orandan
            // hesaplayarak yüzde ve hızın görünmesini sağlıyoruz.
            var total = progress.totalUnitCount > 0 ? progress.totalUnitCount : fallbackTotalBytes
            if total <= 0, progress.completedUnitCount > 0, fraction > 0.01 {
                total = Int64(Double(progress.completedUnitCount) / fraction)
            }

            let completed: Int64
            if progress.completedUnitCount > 0 {
                completed = progress.completedUnitCount
            } else if total > 0 {
                completed = Int64(fraction * Double(total))
            } else {
                completed = 0
            }

            self.progressQueue.async {
                let now = Date()
                let isFinished = fraction >= 1

                // Arayüzü saniyede ~6 kez güncellemek yeterli.
                guard isFinished || now.timeIntervalSince(self.lastProgressRefresh) >= 0.15 else { return }
                self.lastProgressRefresh = now

                var speed = self.smoothedSpeed
                if let sample = self.speedSample {
                    let elapsed = now.timeIntervalSince(sample.time)
                    if elapsed >= 0.2 {
                        let instant = Double(completed - sample.bytes) / elapsed
                        speed = self.smoothedSpeed == 0
                            ? instant
                            : self.smoothedSpeed * 0.6 + instant * 0.4
                        self.smoothedSpeed = speed
                        self.speedSample = (now, completed)
                    }
                } else {
                    self.speedSample = (now, completed)
                }

                DispatchQueue.main.async {
                    self.transferProgress = fraction
                    self.transferredBytes = completed
                    self.totalTransferBytes = total
                    self.transferSpeed = max(0, speed)
                }
            }
        }
    }

    /// "45%" biçiminde yüzde metni.
    var transferPercentText: String {
        guard transferProgress > 0 else { return "" }
        return "\(Int((transferProgress * 100).rounded()))%"
    }

    /// "12,4 MB / 48,1 MB" biçiminde boyut metni.
    var transferSizeText: String {
        guard totalTransferBytes > 0 else { return "" }
        let done = ByteCountFormatter.string(fromByteCount: transferredBytes, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: totalTransferBytes, countStyle: .file)
        return "\(done) / \(total)"
    }

    /// "8,2 MB/sn" biçiminde hız metni.
    var transferSpeedText: String {
        guard transferSpeed >= 1024 else { return "" }
        let value = ByteCountFormatter.string(fromByteCount: Int64(transferSpeed), countStyle: .file)
        return "\(value)/sn"
    }

    /// Devam eden gönderimi/alımı `Progress.cancel()` ile iptal eder.
    /// Oturum bağlantısı korunur; iptal sonrası yeni aktarım hemen yapılabilir.
    func cancelTransfer() {
        transferLog.notice("Aktarım kullanıcı tarafından iptal edildi")

        userCancelledTransfer = true
        sendProgress?.cancel()
        receiveProgress?.cancel()
        sendProgress = nil
        receiveProgress = nil

        receiveProgressObservation?.invalidate()
        receiveProgressObservation = nil

        progressQueue.sync {
            lastProgressRefresh = .distantPast
            speedSample = nil
            smoothedSpeed = 0
        }

        DispatchQueue.main.async {
            self.isSending = false
            self.isReceiving = false
            self.transferProgress = 0
            self.transferredBytes = 0
            self.totalTransferBytes = 0
            self.transferSpeed = 0
            self.lastError = nil
            self.updateTransferActivity()
        }

        // İptal bazen MCSession bağlantısını düşürebiliyor. Kullanıcı beklemeden
        // yeniden gönderebilsin diye bilinen eşlere birkaç kez davet gönderilir.
        reconnectKnownPeers()
    }

    // MARK: - Aktarım sırasında uygulamayı uyanık tutma

    /// Aktarım sürerken ekranın otomatik kapanmasını ve uygulamanın askıya
    /// alınmasını engeller. Ekran kapanınca iOS Wi-Fi trafiğini yavaşlattığı
    /// için bu, gerçek cihazda aktarım hızını belirgin biçimde artırır.
    /// Yalnızca iOS'ta gereklidir; tvOS zaten uykuya geçmez.
    private func updateTransferActivity() {
        #if os(iOS)
        let apply = { [weak self] in
            guard let self else { return }
            let active = self.isSending || self.isReceiving
            UIApplication.shared.isIdleTimerDisabled = active

            if active {
                if self.transferBackgroundTask == .invalid {
                    self.transferBackgroundTask = UIApplication.shared.beginBackgroundTask(withName: "imeds-transfer") { [weak self] in
                        self?.endTransferBackgroundTask()
                    }
                }
            } else {
                self.endTransferBackgroundTask()
            }
        }

        if Thread.isMainThread {
            apply()
        } else {
            DispatchQueue.main.async(execute: apply)
        }
        #endif
    }

    #if os(iOS)
    private func endTransferBackgroundTask() {
        guard transferBackgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(transferBackgroundTask)
        transferBackgroundTask = .invalid
    }
    #endif

    /// İptal sonrası keşfedilen eşlere kademeli olarak yeniden davet gönderir.
    /// Tarayıcı durdurulmuyor; böylece CoreFoundation tarafında kararsızlık oluşmuyor.
    private func reconnectKnownPeers() {
        let peers = discoveredPeers
        guard !peers.isEmpty else { return }

        for delay in [1.5, 4.0, 8.0, 14.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                for peer in peers where peer != self.myPeerId {
                    guard !self.session.connectedPeers.contains(peer) else { continue }
                    self.invitedPeers.remove(peer)
                    self.invite(peer, using: self.serviceBrowser)
                }
            }
        }
    }

    // MARK: - Dosya yönetimi

    func deleteFile(_ file: SharedFile) {
        try? FileManager.default.removeItem(at: file.url)
        receivedFiles.removeAll { $0.id == file.id }
    }

    /// Alınan dosyalar için yazılabilir bir klasör bulur.
    ///
    /// tvOS'ta uygulama veri kabı sistem tarafından temizlenebildiği için
    /// yalnızca `Documents` varsayılmıyor: sırasıyla Documents, Application
    /// Support ve tmp denenir; yazma testinden geçen ilk aday kullanılır.
    private func resolveReceivedDirectory() -> URL {
        let fileManager = FileManager.default
        var candidates: [URL] = []

        if let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            candidates.append(documents.appendingPathComponent("Received", isDirectory: true))
        }
        if let support = fileManager.urls(for: .applicationSupportDirectory,
                                          in: .userDomainMask).first {
            candidates.append(support.appendingPathComponent("Received", isDirectory: true))
        }
        candidates.append(fileManager.temporaryDirectory
            .appendingPathComponent("Received", isDirectory: true))

        for candidate in candidates {
            do {
                try fileManager.createDirectory(at: candidate,
                                                withIntermediateDirectories: true)

                // Gerçekten yazılabildiğini doğrula.
                let probe = candidate.appendingPathComponent(".imeds-write-test")
                try Data("ok".utf8).write(to: probe, options: .atomic)
                try? fileManager.removeItem(at: probe)

                transferLog.notice("Alınan dosya klasörü: \(candidate.path, privacy: .public)")
                return candidate
            } catch {
                transferLog.error("Klasör kullanılamıyor \(candidate.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }

        // Hiçbiri yazılamadıysa ilk adayı döndür; hata mesajı çağıran tarafta oluşur.
        return candidates[0]
    }

    /// Klasörün var olduğundan emin olur (sistem temizlemiş olabilir).
    @discardableResult
    private func ensureReceivedDirectory() throws -> URL {
        let directory = receivedDirectory
        try FileManager.default.createDirectory(at: directory,
                                                withIntermediateDirectories: true)
        return directory
    }

    private func prepareReceivedDirectory() {
        do {
            try ensureReceivedDirectory()
        } catch {
            transferLog.error("Alınan dosya klasörü hazırlanamadı: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// FilePicker'ın seçilen medyayı kopyaladığı geçici klasör.
    /// MCSession bu dosyayı okuyup gönderimi bitirene kadar silinmemelidir.
    private func outgoingDirectoryURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImedsOutgoing", isDirectory: true)
        return directory
    }

    /// Uygulama açılırken önceki oturumlardan kalan geçici gönderim
    /// dosyalarını temizler. Gönderim tamamlanınca dosya silinmez; böylece
    /// MCSession dosyayı okurken ortadan kalkmaz.
    private func cleanupOutgoingFiles() {
        let directory = outgoingDirectoryURL()
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    private func loadReceivedFiles() {
        guard let directory = try? ensureReceivedDirectory() else { return }
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey]

        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return }

        receivedFiles = urls.compactMap { url -> SharedFile? in
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else { return nil }

            return SharedFile(
                name: url.lastPathComponent,
                url: url,
                size: Int64(values.fileSize ?? 0),
                receivedAt: values.contentModificationDate ?? Date()
            )
        }
        .sorted { $0.receivedAt > $1.receivedAt }
    }

    /// Gelen dosya adını temizler ve aynı isim varsa benzersiz bir ad üretir.
    private func uniqueDestinationURL(for proposedName: String) -> URL {
        let directory = (try? ensureReceivedDirectory()) ?? receivedDirectory

        var safeName = URL(fileURLWithPath: proposedName).lastPathComponent
        if safeName.isEmpty || safeName == "." || safeName == ".." {
            safeName = "Dosya"
        }

        let base = (safeName as NSString).deletingPathExtension
        let ext = (safeName as NSString).pathExtension

        var candidate = directory.appendingPathComponent(safeName)
        var index = 1

        while FileManager.default.fileExists(atPath: candidate.path) {
            let suffix = ext.isEmpty ? "_\(index)" : "_\(index).\(ext)"
            candidate = directory.appendingPathComponent(base + suffix)
            index += 1
        }

        return candidate
    }

    // MARK: - Galeri

    #if os(iOS)
    private func saveToPhotosAlbum(url: URL, isVideo: Bool) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self?.lastError = "Galeriye kaydetmek için izin verilmedi."
                }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                if isVideo {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                } else {
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                }
            }) { success, error in
                guard !success, let error else { return }
                DispatchQueue.main.async {
                    self?.lastError = "Galeriye kaydetme hatası: \(error.localizedDescription)"
                }
            }
        }
    }
    #endif

    private func publishError(_ message: String) {
        DispatchQueue.main.async { self.lastError = message }
    }

    /// İptal/bağlantı kopması hatalarını kullanıcıya anlaşılır biçimde gösterir.
    private static func friendlyReceiveError(_ error: Error) -> String {
        let text = error.localizedDescription.lowercased()
        if text.contains("cancel") || text.contains("no longer connected")
            || text.contains("not connected") || text.contains("bağlantı") {
            return "Aktarım iptal edildi."
        }
        return "Dosya alınamadı: \(error.localizedDescription)"
    }
}

// MARK: - MCSessionDelegate

extension NetworkManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // İptal sonrası eski oturumdan gelen gecikmiş callback'leri yok say.
        guard session === self.session else { return }

        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers

            switch state {
            case .connected:
                self.invitedPeers.remove(peerID)
                self.retriedPeers.remove(peerID)
                if self.selectedPeer == nil {
                    self.selectedPeer = peerID
                }
            case .notConnected:
                self.invitedPeers.remove(peerID)
                self.retriedPeers.remove(peerID)
                if self.selectedPeer == peerID {
                    self.selectedPeer = session.connectedPeers.first
                }
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {
        guard session === self.session else { return }

        receiveProgressObservation?.invalidate()
        receiveProgressObservation = nil

        if let error {
            transferLog.error("Alım hatası: \(error.localizedDescription, privacy: .public)")
            let message = Self.friendlyReceiveError(error)
            DispatchQueue.main.async {
                self.isReceiving = false
                self.receiveProgress = nil
                if self.userCancelledTransfer {
                    self.userCancelledTransfer = false
                    self.lastError = nil
                } else {
                    self.lastError = message
                }
                self.updateTransferActivity()
            }
            return
        }

        guard let tempURL = localURL else {
            DispatchQueue.main.async {
                self.isReceiving = false
                self.lastError = "Dosya alınamadı: geçici dosya adresi yok."
                self.updateTransferActivity()
            }
            return
        }

        let destination = uniqueDestinationURL(for: resourceName)

        do {
            try installReceivedFile(from: tempURL, to: destination)
            let attributes = try FileManager.default.attributesOfItem(atPath: destination.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            let newFile = SharedFile(name: destination.lastPathComponent,
                                     url: destination,
                                     size: fileSize,
                                     receivedAt: Date())

            transferLog.notice("Dosya kaydedildi: \(destination.path, privacy: .public)")

            DispatchQueue.main.async {
                self.receivedFiles.insert(newFile, at: 0)
                self.isReceiving = false
                self.receiveProgress = nil
                self.transferProgress = 1
                self.lastError = nil
                self.updateTransferActivity()

                #if os(iOS)
                if newFile.isMedia {
                    self.saveToPhotosAlbum(url: destination, isVideo: newFile.isVideo)
                }
                #endif
            }
        } catch {
            transferLog.error("Dosya kaydedilemedi: \(error.localizedDescription, privacy: .public)")
            publishError("Dosya kaydedilemedi: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isReceiving = false
                self.updateTransferActivity()
            }
        }
    }

    private enum ReceiveError: LocalizedError {
        case directoryUnavailable(URL, Error)
        case temporaryFileMissing

        var errorDescription: String? {
            switch self {
            case let .directoryUnavailable(url, error):
                return "Alınan dosyalar klasörü oluşturulamadı (\(url.lastPathComponent)): \(error.localizedDescription)"
            case .temporaryFileMissing:
                return "Aktarım yarıda kesildi: geçici dosya bulunamadı. Lütfen tekrar deneyin."
            }
        }
    }

    /// Alınan geçici dosyayı `Received/` içine taşır.
    ///
    /// tvOS'ta MCSession geçici dosyası callback dönüşünde temizlenebilir;
    /// bu yüzden önce kısa bir süre dosyanın görünmesini bekleriz. Taşıma
    /// başarısız olursa sırasıyla kopyalama ve belleğe okuyup yazma denenir.
    private func installReceivedFile(from source: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        let directory = destination.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw ReceiveError.directoryUnavailable(directory, error)
        }

        if !fileManager.fileExists(atPath: source.path) {
            for _ in 0..<20 {
                if fileManager.fileExists(atPath: source.path) { break }
                Thread.sleep(forTimeInterval: 0.05)
            }
        }

        guard fileManager.fileExists(atPath: source.path) else {
            throw ReceiveError.temporaryFileMissing
        }

        var lastError: Error?

        for attempt in 0..<3 {
            do {
                if fileManager.fileExists(atPath: destination.path) {
                    try? fileManager.removeItem(at: destination)
                }
                try fileManager.moveItem(at: source, to: destination)
                return
            } catch {
                lastError = error
            }

            do {
                try fileManager.copyItem(at: source, to: destination)
                try? fileManager.removeItem(at: source)
                return
            } catch {
                lastError = error
            }

            if attempt < 2 {
                Thread.sleep(forTimeInterval: 0.1)
            }
        }

        // Son çare: dosyayı belleğe okuyup yeni konuma yaz.
        do {
            let data = try Data(contentsOf: source)
            try data.write(to: destination, options: .atomic)
            try? fileManager.removeItem(at: source)
            return
        } catch {
            lastError = error
        }

        throw lastError ?? ReceiveError.temporaryFileMissing
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {
        guard session === self.session else { return }

        receiveProgress = progress
        observeTransferProgress(progress, fallbackTotalBytes: 0)

        DispatchQueue.main.async {
            self.isReceiving = true
            self.userCancelledTransfer = false
            // Yeni aktarım başlarken önceki hata mesajını temizle.
            self.lastError = nil
            self.updateTransferActivity()
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate / MCNearbyServiceBrowserDelegate

extension NetworkManager: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Zaten bağlıysa ikinci bir oturum açmaya çalışma.
        if session.connectedPeers.contains(peerID) {
            invitationHandler(false, nil)
        } else {
            invitationHandler(true, session)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            guard peerID != self.myPeerId else { return }
            self.discoveredPeers.insert(peerID)
            guard !self.session.connectedPeers.contains(peerID) else { return }

            // İki cihazın birbirine aynı anda davet göndermesini engellemek için
            // yalnızca ada göre "küçük" olan taraf hemen davet başlatır.
            let comparison = self.myPeerId.displayName
                .localizedCaseInsensitiveCompare(peerID.displayName)

            if comparison != .orderedDescending {
                self.invite(peerID, using: browser)
            } else {
                // Normalde diğer taraf davet eder. Yine de bağlantı kurulamazsa
                // 6 saniye sonra biz de bir kez davet ederiz.
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self, weak browser] in
                    guard let self, let browser else { return }
                    guard !self.session.connectedPeers.contains(peerID),
                          !self.invitedPeers.contains(peerID),
                          !self.retriedPeers.contains(peerID) else { return }

                    self.retriedPeers.insert(peerID)
                    self.invite(peerID, using: browser)
                }
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.discoveredPeers.remove(peerID)
            self.invitedPeers.remove(peerID)
            self.retriedPeers.remove(peerID)
            if self.selectedPeer == peerID {
                self.selectedPeer = self.session.connectedPeers.first
            }
        }
    }

    /// Davet gönderir; 16 saniye içinde bağlantı kurulamazsa bir kez daha dener.
    private func invite(_ peerID: MCPeerID, using browser: MCNearbyServiceBrowser) {
        guard peerID != myPeerId,
              !session.connectedPeers.contains(peerID),
              !invitedPeers.contains(peerID) else { return }

        invitedPeers.insert(peerID)
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 15)

        DispatchQueue.main.asyncAfter(deadline: .now() + 16) { [weak self, weak browser] in
            guard let self, let browser else { return }

            self.invitedPeers.remove(peerID)

            guard !self.session.connectedPeers.contains(peerID),
                  !self.retriedPeers.contains(peerID) else { return }

            self.retriedPeers.insert(peerID)
            self.invite(peerID, using: browser)
        }
    }
}
