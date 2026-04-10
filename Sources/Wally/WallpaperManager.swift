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

    func htmlString(for video: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <style>
        *{margin:0;padding:0}
        body{overflow:hidden;background:#000}
        video{width:100vw;height:100vh;object-fit:cover}
        </style>
        </head>
        <body>
        <video autoplay muted loop playsinline>
        <source src="\(video)" type="video/mp4">
        </video>
        </body>
        </html>
        """
    }
}
