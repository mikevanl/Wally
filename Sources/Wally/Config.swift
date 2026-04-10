import Foundation

struct WallyConfig: Codable {
    var wallpaperDirectory: String
    var assignments: [String: String]
    var launchAtLogin: Bool

    static let defaultDirectory = NSString(
        string: "~/.config/wally/wallpapers"
    ).expandingTildeInPath
}

class Config {
    private(set) var config: WallyConfig
    private let fileURL: URL
    private let directoryURL: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        directoryURL = appSupport.appendingPathComponent("Wally")
        fileURL = directoryURL.appendingPathComponent("config.json")

        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder().decode(WallyConfig.self, from: data) {
            config = loaded
        } else {
            config = WallyConfig(
                wallpaperDirectory: WallyConfig.defaultDirectory,
                assignments: [:],
                launchAtLogin: false
            )
        }

        ensureWallpaperDirectoryExists()
    }

    private func ensureWallpaperDirectoryExists() {
        let url = URL(fileURLWithPath: config.wallpaperDirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    var wallpaperDirectoryURL: URL {
        URL(fileURLWithPath: config.wallpaperDirectory, isDirectory: true)
    }

    func assignment(for displayID: UInt32) -> String? {
        config.assignments[String(displayID)]
    }

    func setAssignment(displayID: UInt32, video: String) {
        config.assignments[String(displayID)] = video
        save()
    }

    func setWallpaperDirectory(_ path: String) {
        config.wallpaperDirectory = path
        config.assignments = [:]
        save()
        ensureWallpaperDirectoryExists()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        config.launchAtLogin = enabled
        save()
    }

    func save() {
        do {
            try FileManager.default.createDirectory(
                at: directoryURL, withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("Wally: failed to save config: \(error)")
        }
    }
}
