import Foundation
import UniformTypeIdentifiers

struct SharedFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let size: Int64
    let receivedAt: Date

    var formattedSize: String {
        Yerellestirme.paylasilan.baytMetni(size)
    }

    /// Uzantıyı boşluklardan arındırıp küçük harfe çevirir.
    /// Gelen dosya adı bazen "video.mp4 " gibi sonu boşluklu olabiliyor.
    private var fileExtension: String {
        url.pathExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    var isImage: Bool {
        if Self.imageExtensions.contains(fileExtension) { return true }
        // Bilinen listede yoksa UniformTypeIdentifiers ile aile kontrolü yap.
        guard let type = UTType(filenameExtension: fileExtension) else { return false }
        return type.conforms(to: .image)
    }

    var isVideo: Bool {
        if Self.videoExtensions.contains(fileExtension) { return true }
        guard let type = UTType(filenameExtension: fileExtension) else { return false }
        return type.conforms(to: .movie) || type.conforms(to: .video)
    }

    /// Müzik/ses dosyası mı?
    var isAudio: Bool {
        if isVideo { return false }
        if Self.audioExtensions.contains(fileExtension) { return true }
        guard let type = UTType(filenameExtension: fileExtension) else { return false }
        return type.conforms(to: .audio)
    }

    /// Galeriye kaydedilebilecek medya mı?
    var isMedia: Bool { isImage || isVideo }

    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "gif", "webp", "tiff", "bmp"
    ]

    private static let videoExtensions: Set<String> = [
        "mp4", "mov", "m4v", "avi", "mkv", "webm", "3gp", "mpg", "mpeg", "ts"
    ]

    /// Apple TV'de çalınabilecek ses dosyası uzantıları.
    private static let audioExtensions: Set<String> = [
        "mp3", "wav", "m4a", "m4r", "aac", "flac", "aiff", "aif", "caf",
        "ogg", "opus", "wma", "alac"
    ]
}
