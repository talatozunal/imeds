import SwiftUI
import MultipeerConnectivity

#if os(iOS)
import QuickLook
#endif

struct ContentView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @State private var isFilePickerPresented = false
    @State private var isPhotoPickerPresented = false
    @State private var isSendOptionsPresented = false
    @State private var isPreparingMedia = false
    @State private var previewURL: URL?

    /// Seçili cihaz yoksa bağlı ilk cihazı kullan.
    private var activePeer: MCPeerID? {
        networkManager.selectedPeer ?? networkManager.connectedPeers.first
    }

    var body: some View {
        NavigationStack {
            List {
                peerSection
                sendSection
                receivedFilesSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("imeds")
            .sheet(isPresented: $isFilePickerPresented) {
                UniversalFilePicker(
                    onStart: {
                        isPreparingMedia = true
                        isFilePickerPresented = false
                    },
                    onPick: { url in
                        isPreparingMedia = false
                        isFilePickerPresented = false
                        networkManager.sendFile(url: url)
                    },
                    onError: { message in
                        isPreparingMedia = false
                        isFilePickerPresented = false
                        networkManager.lastError = message
                    }
                )
            }
            .sheet(isPresented: $isPhotoPickerPresented) {
                PhotoPicker(
                    onStart: {
                        isPreparingMedia = true
                        isPhotoPickerPresented = false
                    },
                    onPick: { url in
                        isPreparingMedia = false
                        isPhotoPickerPresented = false
                        networkManager.sendFile(url: url)
                    },
                    onCancel: {
                        isPreparingMedia = false
                        isPhotoPickerPresented = false
                    },
                    onError: { message in
                        isPreparingMedia = false
                        isPhotoPickerPresented = false
                        networkManager.lastError = message
                    }
                )
            }
            .confirmationDialog(
                "Ne göndermek istiyorsun?",
                isPresented: $isSendOptionsPresented,
                titleVisibility: .visible
            ) {
                Button("Fotoğraf / Video Seç") {
                    isPhotoPickerPresented = true
                }
                Button("Dosya Seç") {
                    isFilePickerPresented = true
                }
                Button("İptal", role: .cancel) {}
            }
            #if os(iOS)
            .quickLookPreview($previewURL)
            #endif
            .alert("imeds", isPresented: Binding(
                get: { networkManager.lastError != nil },
                set: { if !$0 { networkManager.lastError = nil } }
            )) {
                Button("Tamam", role: .cancel) {
                    networkManager.lastError = nil
                }
            } message: {
                Text(networkManager.lastError ?? "")
            }
        }
    }

    // MARK: - Cihazlar

    @ViewBuilder
    private var peerSection: some View {
        Section("imeds Ağı") {
            if networkManager.connectedPeers.isEmpty {
                HStack {
                    ProgressView().padding(.trailing, 5)
                    Text("Cihaz aranıyor...").foregroundColor(.gray)
                }
            } else {
                ForEach(networkManager.connectedPeers, id: \.self) { peer in
                    Button {
                        networkManager.selectedPeer = peer
                    } label: {
                        HStack {
                            Image(systemName: "bolt.horizontal.fill")
                                .foregroundColor(.orange)
                            Text(peer.displayName)
                            Spacer()
                            if networkManager.selectedPeer == peer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.orange)
                            } else {
                                Circle()
                                    .frame(width: 8, height: 8)
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Gönderim

    @ViewBuilder
    private var sendSection: some View {
        Section {
            if let peer = activePeer {
                Button {
                    isSendOptionsPresented = true
                } label: {
                    Label("\(peer.displayName) cihazına gönder", systemImage: "paperplane.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(networkManager.isSending || isPreparingMedia)
                .opacity(networkManager.isSending || isPreparingMedia ? 0.6 : 1)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            } else {
                if #available(iOS 17.0, *) {
                    ContentUnavailableView(
                        "Cihaz Bekleniyor",
                        systemImage: "bolt.hybrid.page.fill",
                        description: Text("Diğer Apple cihazınızda imeds uygulamasını açın.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    // Fallback on earlier versions
                }
            }

            if isPreparingMedia {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ProgressView()
                        Text("Medya hazırlanıyor...")
                            .font(.caption)
                            .bold()
                    }
                    Text("Büyük videolar iCloud'dan indiriliyor olabilir; bu adım birkaç dakika sürebilir.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
            }

            if networkManager.isSending {
                transferCard(title: "Gönderiliyor...")
            }

            if networkManager.isReceiving {
                transferCard(title: "Alınıyor...")
            }
        }
    }

    /// Aktarım yüzdesi, boyutu ve hızını gösteren kart.
    @ViewBuilder
    private func transferCard(title: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title).font(.caption).bold()
                Spacer()
                if !networkManager.transferPercentText.isEmpty {
                    Text(networkManager.transferPercentText)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.orange)
                }
            }

            if networkManager.totalTransferBytes > 0 {
                ProgressView(value: networkManager.transferProgress, total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(.orange)
            } else {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(.orange)
            }

            HStack {
                Text(networkManager.transferSizeText)
                Spacer()
                if !networkManager.transferSpeedText.isEmpty {
                    Label(networkManager.transferSpeedText, systemImage: "speedometer")
                }
            }
            .font(.caption2.monospacedDigit())
            .foregroundColor(.secondary)

            cancelButton
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }

    /// Devam eden gönderimi veya alımı iptal eder.
    private var cancelButton: some View {
        Button(role: .destructive) {
            networkManager.cancelTransfer()
        } label: {
            Label("Vazgeç", systemImage: "xmark.circle.fill")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.12))
                .foregroundColor(.red)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Alınan dosyalar

    @ViewBuilder
    private var receivedFilesSection: some View {
        Section {
            if networkManager.receivedFiles.isEmpty {
                if #available(iOS 17.0, *) {
                    ContentUnavailableView(
                        "Henüz Dosya Yok",
                        systemImage: "tray",
                        description: Text("Gelen dosyalar burada listelenir.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    // Fallback on earlier versions
                }
            } else {
                ForEach(networkManager.receivedFiles) { file in
                    Button {
                        previewURL = file.url
                    } label: {
                        HStack {
                            Image(systemName: file.isImage ? "photo.fill" : (file.isVideo ? "film.fill" : (file.isAudio ? "music.note" : "doc.arrow.down.fill")))
                                .font(.title2)
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(file.name).font(.body).lineLimit(1)
                                HStack {
                                    Text(file.formattedSize)
                                    if file.isMedia {
                                        Text("• Galeriye Kaydedildi")
                                            .foregroundColor(.green)
                                            .bold()
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            networkManager.deleteFile(file)
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
                .onDelete { offsets in
                    offsets.map { networkManager.receivedFiles[$0] }
                        .forEach(networkManager.deleteFile)
                }
            }
        } header: {
            Text("Alınan Dosyalar")
        }
    }
}
