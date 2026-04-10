import Foundation

class WallpaperManager {
    private let config: Config

    init(config: Config) {
        self.config = config
    }

    var wallpaperDirectoryURL: URL {
        config.wallpaperDirectoryURL
    }

    func availableVideos() -> [String] {
        let url = config.wallpaperDirectoryURL
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: nil
        ) else { return [] }
        return contents
            .filter { $0.pathExtension.lowercased() == "mp4" }
            .map { $0.lastPathComponent }
            .sorted()
    }

    func videoURL(for filename: String) -> URL {
        config.wallpaperDirectoryURL.appendingPathComponent(filename)
    }
}
