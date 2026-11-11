import SwiftUI
import AVKit
import UIKit
import MultipeerConnectivity
import os
import Combine

struct AppleTVView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject private var dil: Yerellestirme

    /// Son medya büyük oynatıcıda mı gösteriliyor? Kumandanın "Geri"
    /// tuşuna basınca uygulamadan çıkmak yerine oynatıcı kapatılır ve son
    /// medya ekranın altındaki şeritte kalmaya devam eder.
    @State private var isMediaExpanded = true
    @State private var isLanguagePresented = false

    private var latestFile: SharedFile? { networkManager.receivedFiles.first }

    var body: some View {
        Group {
            if isMediaExpanded, latestFile != nil {
                content
                    .onExitCommand {
                        // "Geri" uygulamayı kapatmasın; ana ekrana dön ve
                        // son medyayı altta küçük şerit olarak bırak.
                        collapseMedia()
                    }
            } else {
                content
            }
        }
        .onChange(of: latestFile?.id) { _, newValue in
            // Yeni bir dosya gelince büyük görünüme geri dön.
            if newValue != nil {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isMediaExpanded = true
                }
            }
        }
        .sheet(isPresented: $isLanguagePresented) {
            DilSecici()
        }
    }

    private var content: some View {
        VStack(spacing: 24) {
            HStack(spacing: 40) {
                statusColumn
                mediaColumn
            }
            .frame(maxHeight: .infinity)

            if !isMediaExpanded, let lastFile = latestFile {
                lastMediaBar(lastFile)
            }
        }
        .padding(50)
    }

    /// Son medyayı büyük görünümden çıkarıp ekranın altındaki şeride indirir.
    /// Uygulama açık kalır; yeni dosya gelince tekrar büyütülür.
    private func collapseMedia() {
        transferLog.notice("Geri tuşu: medya küçültülüyor")
        withAnimation(.easeInOut(duration: 0.2)) {
            isMediaExpanded = false
        }
    }

    // MARK: - Sol taraf: bağlantı ve aktarım durumu

    private var statusColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                Text(dil.metin("tv.receiver"))
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .bold()

                Spacer()

                Button {
                    isLanguagePresented = true
                } label: {
                    Label(dil.metin("dil.sec"), systemImage: "globe")
                }
                .buttonStyle(.card)
            }

            if networkManager.connectedPeers.isEmpty {
                HStack {
                    ProgressView().padding(.trailing, 10)
                    Text(dil.metin("tv.waitingSource"))
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            } else {
                ForEach(networkManager.connectedPeers, id: \.self) { peer in
                    HStack {
                        Image(systemName: "airplayvideo").foregroundColor(.orange)
                        Text(dil.metin("tv.readyFrom", peer.displayName))
                            .font(.headline)
                    }
                }
            }

            if networkManager.isReceiving {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(dil.metin("tv.receiving")).font(.headline)
                        Spacer()
                        if !networkManager.transferPercentText.isEmpty {
                            Text(networkManager.transferPercentText)
                                .font(.headline.monospacedDigit())
                                .foregroundColor(.orange)
                        }
                    }
                    ProgressView(value: networkManager.transferProgress, total: 1.0)
                        .tint(.orange)
                    HStack {
                        Text(networkManager.transferSizeText)
                        Spacer()
                        if !networkManager.transferSpeedText.isEmpty {
                            Label(networkManager.transferSpeedText, systemImage: "speedometer")
                        }
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
                    Button(role: .destructive) {
                        networkManager.cancelTransfer()
                    } label: {
                        Label(dil.metin("transfer.cancel"), systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(.card)
                }
            }

            if let error = networkManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Spacer()

            Text(dil.metin("tv.hint"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 500)
    }

    // MARK: - Sağ taraf: son medya

    private var mediaColumn: some View {
        VStack {
            if isMediaExpanded, let lastFile = latestFile {
                VStack(spacing: 20) {
                    HStack {
                        Text(dil.metin("tv.latestMedia"))
                            .font(.headline)
                        Spacer()
                        Button {
                            collapseMedia()
                        } label: {
                            Label(dil.metin("tv.home"), systemImage: "chevron.down.circle")
                        }
                        .buttonStyle(.card)
                    }

                    mediaView(for: lastFile)
                }
            } else if latestFile == nil {
                ContentUnavailableView(
                    dil.metin("tv.ready.title"),
                    systemImage: "airplayvideo",
                    description: Text(dil.metin("tv.ready.desc"))
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func mediaView(for file: SharedFile) -> some View {
        if file.isImage,
           let image = UIImage(contentsOfFile: file.url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 600)
                .cornerRadius(20)
                .shadow(radius: 10)
        } else if file.isVideo {
            VideoPlaybackPane(file: file, onClose: collapseMedia)
        } else if file.isAudio {
            AudioPlaybackPane(file: file, onClose: collapseMedia)
        } else {
            VStack(spacing: 15) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                Text(file.name)
                    .font(.headline)
                    .lineLimit(1)
            }
            .padding(40)
        }
    }

    /// Ana ekrana dönüldüğünde son medyayı ekranın altında tutan şerit.
    private func lastMediaBar(_ file: SharedFile) -> some View {
        HStack(spacing: 20) {
            lastMediaThumbnail(file)

            VStack(alignment: .leading, spacing: 6) {
                Text(dil.metin("tv.lastMedia"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(file.name)
                    .font(.headline)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isMediaExpanded = true
                }
            } label: {
                Label(dil.metin("tv.show"), systemImage: "rectangle.expand.vertical")
            }
            .buttonStyle(.card)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.12))
        .cornerRadius(16)
    }

    @ViewBuilder
    private func lastMediaThumbnail(_ file: SharedFile) -> some View {
        if file.isImage,
           let image = UIImage(contentsOfFile: file.url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 68)
                .clipped()
                .cornerRadius(8)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 120, height: 68)
                Image(systemName: file.isVideo ? "film.fill" : (file.isAudio ? "music.note" : "doc.fill"))
                    .font(.system(size: 30))
                    .foregroundColor(.orange)
            }
        }
    }
}

/// Gelen videoyu tvOS üzerinde oynatır.
///
/// Video önce `AVURLAsset` ile doğrulanır: oynatılabilir ve en az bir video
/// izi varsa oynatıcı açılır. Aksi halde sessizce hiçbir şey olmaması yerine
/// nedeni ekranda gösterilir. Oynatıcı tam ekran yerine yerleşik gösterilir;
/// böylece fullScreenCover'ın boş açılması gibi sorunlar yaşanmaz.
private struct VideoPlaybackPane: View {
    @EnvironmentObject private var dil: Yerellestirme
    let file: SharedFile
    var onClose: () -> Void = {}

    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 14) {
            if let player {
                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity, maxHeight: 560)
                    .cornerRadius(20)
                    .shadow(radius: 10)
            } else if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text(dil.metin("video.preparing"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(60)
            } else {
                Button(action: preparePlayback) {
                    VStack(spacing: 15) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                        Text(file.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text(dil.metin("video.tapToPlay"))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(40)
                }
                .buttonStyle(.card)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .onDisappear {
            player?.pause()
        }
        .onExitCommand {
            onClose()
        }
        .onChange(of: file.id) { _, _ in
            player?.pause()
            player = nil
            errorMessage = nil
            isLoading = false
        }
    }

    @MainActor
    private func preparePlayback() {
        errorMessage = nil
        isLoading = true

        let url = file.url
        transferLog.notice("Video oynatma denemesi: \(url.lastPathComponent, privacy: .public)")

        Task { @MainActor in
            let asset = AVURLAsset(url: url)

            do {
                let isPlayable = try await asset.load(.isPlayable)
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                let duration = try await asset.load(.duration)
                let seconds = CMTimeGetSeconds(duration)

                transferLog.notice("Video bilgisi: oynatılabilir=\(isPlayable, privacy: .public), video izi=\(videoTracks.count), süre=\(seconds, privacy: .public)s, boyut=\(file.formattedSize, privacy: .public)")

                guard isPlayable, !videoTracks.isEmpty else {
                    isLoading = false
                    errorMessage = dil.metin("video.error")
                    return
                }

                isLoading = false
                let newPlayer = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                player = newPlayer
                newPlayer.play()
            } catch {
                transferLog.error("Video açılamadı: \(error.localizedDescription, privacy: .public)")
                isLoading = false
                errorMessage = dil.metin("video.openError", error.localizedDescription)
            }
        }
    }
}

/// Gelen müzik/ses dosyasını Apple TV'de çalar.
///
/// Video oynatıcıdan farklı olarak siyah bir görüntü yerine albüm kapağı
/// benzeri bir kart, çalma/duraklatma düğmesi ve süre çubuğu gösterilir.
/// `mp3`, `wav`, `m4a`, `m4r` gibi yaygın ses formatları desteklenir.
private struct AudioPlaybackPane: View {
    @EnvironmentObject private var dil: Yerellestirme
    let file: SharedFile
    var onClose: () -> Void = {}

    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isPlaying = false
    @State private var duration: Double = 0
    @State private var currentTime: Double = 0

    private let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 200, height: 200)

                Image(systemName: isPlaying ? "music.note" : "music.note.list")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
            }

            Text(file.name)
                .font(.headline)
                .lineLimit(1)
                .frame(maxWidth: 520)

            Text(file.formattedSize)
                .font(.caption)
                .foregroundColor(.secondary)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            } else if isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(dil.metin("audio.preparing"))
                        .foregroundColor(.secondary)
                }
            } else if player != nil {
                VStack(spacing: 12) {
                    ProgressView(value: duration > 0 ? min(currentTime / duration, 1) : 0, total: 1)
                        .tint(.orange)

                    HStack {
                        Text(timeText(currentTime))
                        Spacer()
                        Text(timeText(duration))
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)

                    Button(action: togglePlayback) {
                        Label(isPlaying ? dil.metin("audio.pause") : dil.metin("audio.play"),
                              systemImage: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.card)
                }
                .frame(maxWidth: 520)
            } else {
                Button(action: preparePlayback) {
                    VStack(spacing: 14) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.orange)
                        Text(dil.metin("audio.tapToPlay"))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(30)
                }
                .buttonStyle(.card)
            }
        }
        .onReceive(ticker) { _ in
            guard let player else { return }
            let seconds = player.currentTime().seconds
            if seconds.isFinite {
                currentTime = seconds
            }
            isPlaying = player.timeControlStatus == .playing
        }
        .onDisappear {
            player?.pause()
        }
        .onExitCommand {
            onClose()
        }
        .onChange(of: file.id) { _, _ in
            player?.pause()
            player = nil
            errorMessage = nil
            isLoading = false
            isPlaying = false
            currentTime = 0
            duration = 0
        }
    }

    @MainActor
    private func preparePlayback() {
        errorMessage = nil
        isLoading = true

        let url = file.url
        transferLog.notice("Ses oynatma denemesi: \(url.lastPathComponent, privacy: .public)")

        Task { @MainActor in
            let asset = AVURLAsset(url: url)

            do {
                let isPlayable = try await asset.load(.isPlayable)
                let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                let assetDuration = try await asset.load(.duration)
                let seconds = CMTimeGetSeconds(assetDuration)

                transferLog.notice("Ses bilgisi: oynatılabilir=\(isPlayable, privacy: .public), ses izi=\(audioTracks.count), süre=\(seconds, privacy: .public)s")

                guard isPlayable, !audioTracks.isEmpty else {
                    isLoading = false
                    errorMessage = dil.metin("audio.error")
                    return
                }

                duration = seconds.isFinite && seconds > 0 ? seconds : 0
                currentTime = 0
                isLoading = false

                let newPlayer = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                player = newPlayer
                isPlaying = true
                newPlayer.play()
            } catch {
                transferLog.error("Ses dosyası açılamadı: \(error.localizedDescription, privacy: .public)")
                isLoading = false
                errorMessage = dil.metin("audio.openError", error.localizedDescription)
            }
        }
    }

    private func togglePlayback() {
        guard let player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    private func timeText(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
