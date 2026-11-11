#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct UniversalFilePicker: UIViewControllerRepresentable {
    var onStart: () -> Void = {}
    var onPick: (URL) -> Void
    var onError: (String) -> Void = { _ in }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item, .data])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: UniversalFilePicker

        init(_ parent: UniversalFilePicker) {
            self.parent = parent
        }

        func documentPicker(_ picker: UIDocumentPickerViewController,
                            didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            let didStartAccessing = url.startAccessingSecurityScopedResource()
            // Kapanış (closure) koordinatörden bağımsız tutulur: kullanıcı
            // seçim yapınca pencere kapanıyor, kopyalama arka planda devam
            // ediyor ve sonuç yine de ana ekrana iletiliyor.
            let parent = self.parent
            parent.onStart()

            // Kopyalama büyük dosyalarda uzun sürebileceği için ana iş
            // parçacığını bloklamamak adına arka planda yapılır.
            DispatchQueue.global(qos: .userInitiated).async {
                defer {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                // Seçilen dosya iCloud'da veya başka bir uygulamanın alanında olabilir.
                // Erişim izni açıkken kendi geçici klasörümüze kopyalıyoruz; gönderim
                // asenkron olduğu için orijinal URL'in iznine güvenmiyoruz.
                let fileManager = FileManager.default
                let folder = fileManager.temporaryDirectory
                    .appendingPathComponent("ImedsOutgoing", isDirectory: true)
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)

                do {
                    try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

                    let name = url.lastPathComponent.isEmpty ? Yerellestirme.paylasilan.metin("file.default") : url.lastPathComponent
                    let destination = folder.appendingPathComponent(name)
                    try fileManager.copyItem(at: url, to: destination)

                    DispatchQueue.main.async {
                        parent.onPick(destination)
                    }
                } catch {
                    DispatchQueue.main.async {
                        parent.onError(Yerellestirme.paylasilan.metin("error.fileCopy", error.localizedDescription))
                    }
                }
            }
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    var onStart: () -> Void = {}
    var onPick: (URL) -> Void
    var onCancel: () -> Void = {}
    var onError: (String) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            // Kapanışlar koordinatörden bağımsız tutulur; seçim penceresi
            // kapansa da iCloud'dan indirme/kopyalama tamamlanınca sonuç
            // ana ekrana iletilir.
            let parent = self.parent

            guard let provider = results.first?.itemProvider else {
                // Kullanıcı seçim yapmadan kapattı.
                DispatchQueue.main.async {
                    parent.onCancel()
                }
                return
            }

            let typeIdentifier = provider.registeredTypeIdentifiers.first { identifier in
                guard let type = UTType(identifier) else { return false }
                return type.conforms(to: .image) || type.conforms(to: .movie)
            } ?? UTType.data.identifier

            DispatchQueue.main.async {
                parent.onStart()
            }

            provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                guard let url, error == nil else {
                    let message = error?.localizedDescription ?? Yerellestirme.paylasilan.metin("error.unknown")
                    DispatchQueue.main.async {
                        parent.onError(Yerellestirme.paylasilan.metin("error.mediaRead", message))
                    }
                    return
                }

                // loadFileRepresentation'ın verdiği URL yalnızca bu blok içinde geçerli.
                let fileManager = FileManager.default
                let folder = fileManager.temporaryDirectory
                    .appendingPathComponent("ImedsOutgoing", isDirectory: true)
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)

                do {
                    try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

                    let providerName = provider.suggestedName ?? Yerellestirme.paylasilan.metin("media.default")
                    let rawBase = URL(fileURLWithPath: providerName).deletingPathExtension().lastPathComponent
                    let baseName = rawBase.isEmpty || rawBase == "." || rawBase == ".." ? Yerellestirme.paylasilan.metin("media.default") : rawBase

                    let ext = url.pathExtension.isEmpty
                        ? (UTType(typeIdentifier)?.preferredFilenameExtension ?? "dat")
                        : url.pathExtension

                    let destination = folder.appendingPathComponent("\(baseName).\(ext)")
                    try fileManager.copyItem(at: url, to: destination)

                    DispatchQueue.main.async {
                        parent.onPick(destination)
                    }
                } catch {
                    DispatchQueue.main.async {
                        parent.onError(Yerellestirme.paylasilan.metin("error.mediaCopy", error.localizedDescription))
                    }
                }
            }
        }
    }
}
#endif
