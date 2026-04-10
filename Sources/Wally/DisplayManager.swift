import AppKit
import CoreGraphics

class DisplayManager {
    private let wallpaperManager: WallpaperManager
    private let config: Config
    private(set) var windows: [CGDirectDisplayID: WallpaperWindow] = [:]
    private(set) var isPaused = false

    init(wallpaperManager: WallpaperManager, config: Config) {
        self.wallpaperManager = wallpaperManager
        self.config = config

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func setupDisplays() {
        let displayIDs = activeDisplayIDs()
        for id in displayIDs {
            guard let screen = screen(for: id) else { continue }
            let window = WallpaperWindow(displayID: id, screen: screen)
            windows[id] = window
            loadAssignedWallpaper(for: id, in: window)
        }
    }

    func setWallpaper(_ video: String, displayID: CGDirectDisplayID) {
        config.setAssignment(displayID: displayID, video: video)
        if let window = windows[displayID] {
            window.loadVideo(url: wallpaperManager.videoURL(for: video))
        }
    }

    func setWallpaperOnAll(_ video: String) {
        let url = wallpaperManager.videoURL(for: video)
        for (id, window) in windows {
            config.setAssignment(displayID: id, video: video)
            window.loadVideo(url: url)
        }
    }

    func reloadAll() {
        for (id, window) in windows {
            loadAssignedWallpaper(for: id, in: window)
        }
    }

    func pauseAll() {
        isPaused = true
        for (_, window) in windows {
            window.pauseVideo()
        }
    }

    func resumeAll() {
        isPaused = false
        for (_, window) in windows {
            window.resumeVideo()
        }
    }

    func displayInfo() -> [(index: Int, displayID: CGDirectDisplayID, video: String?)] {
        let sortedIDs = windows.keys.sorted()
        return sortedIDs.enumerated().map { index, id in
            (index: index, displayID: id, video: config.assignment(for: id))
        }
    }

    func displayID(at index: Int) -> CGDirectDisplayID? {
        let sortedIDs = windows.keys.sorted()
        guard index >= 0, index < sortedIDs.count else { return nil }
        return sortedIDs[index]
    }

    // MARK: - Private

    private func loadAssignedWallpaper(for displayID: CGDirectDisplayID, in window: WallpaperWindow) {
        let videos = wallpaperManager.availableVideos()
        let video = config.assignment(for: displayID) ?? videos.first
        guard let video else { return }

        if !videos.contains(video), let fallback = videos.first {
            config.setAssignment(displayID: displayID, video: fallback)
            window.loadVideo(url: wallpaperManager.videoURL(for: fallback))
        } else {
            config.setAssignment(displayID: displayID, video: video)
            window.loadVideo(url: wallpaperManager.videoURL(for: video))
        }
    }

    @objc private func screensDidChange() {
        reconfigureDisplays()
    }

    @objc private func didWake() {
        if !isPaused {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.resumeAll()
            }
        }
    }

    private func reconfigureDisplays() {
        let currentIDs = Set(activeDisplayIDs())
        let existingIDs = Set(windows.keys)

        // Remove windows for disconnected displays
        for id in existingIDs.subtracting(currentIDs) {
            windows[id]?.close()
            windows.removeValue(forKey: id)
        }

        // Add windows for new displays
        for id in currentIDs.subtracting(existingIDs) {
            guard let screen = screen(for: id) else { continue }
            let window = WallpaperWindow(displayID: id, screen: screen)
            windows[id] = window
            loadAssignedWallpaper(for: id, in: window)
        }

        // Update frames for existing displays
        for id in currentIDs.intersection(existingIDs) {
            if let screen = screen(for: id), let window = windows[id] {
                window.updateFrame(for: screen)
            }
        }
    }

    private func activeDisplayIDs() -> [CGDirectDisplayID] {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        CGGetActiveDisplayList(16, &displayIDs, &count)
        return Array(displayIDs.prefix(Int(count)))
    }

    private func screen(for displayID: CGDirectDisplayID) -> NSScreen? {
        NSScreen.screens.first { screen in
            let key = NSDeviceDescriptionKey("NSScreenNumber")
            return (screen.deviceDescription[key] as? CGDirectDisplayID) == displayID
        }
    }
}
