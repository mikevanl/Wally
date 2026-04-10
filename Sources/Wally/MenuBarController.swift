import AppKit
import ServiceManagement

class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let displayManager: DisplayManager
    private let wallpaperManager: WallpaperManager
    private let config: Config

    init(displayManager: DisplayManager, wallpaperManager: WallpaperManager, config: Config) {
        self.displayManager = displayManager
        self.wallpaperManager = wallpaperManager
        self.config = config
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            if let font = NSFont(name: "JetBrainsMono NFM", size: 16) {
                button.attributedTitle = NSAttributedString(
                    string: "󰸉",
                    attributes: [.font: font]
                )
            } else {
                button.image = NSImage(
                    systemSymbolName: "play.display",
                    accessibilityDescription: "Wally"
                )
            }
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let videos = wallpaperManager.availableVideos()
        let displays = displayManager.displayInfo()

        // Per-display submenus
        for entry in displays {
            let displayItem = NSMenuItem(
                title: "Display \(entry.index)",
                action: nil,
                keyEquivalent: ""
            )
            let submenu = NSMenu()
            for video in videos {
                let videoItem = NSMenuItem(
                    title: video,
                    action: #selector(setDisplayWallpaper(_:)),
                    keyEquivalent: ""
                )
                videoItem.target = self
                videoItem.representedObject = (entry.displayID, video)
                if entry.video == video {
                    videoItem.state = .on
                }
                submenu.addItem(videoItem)
            }
            displayItem.submenu = submenu
            menu.addItem(displayItem)
        }

        // Set All submenu
        if displays.count > 1 {
            let allItem = NSMenuItem(title: "Set All", action: nil, keyEquivalent: "")
            let allSubmenu = NSMenu()
            for video in videos {
                let videoItem = NSMenuItem(
                    title: video,
                    action: #selector(setAllWallpaper(_:)),
                    keyEquivalent: ""
                )
                videoItem.target = self
                videoItem.representedObject = video
                allSubmenu.addItem(videoItem)
            }
            allItem.submenu = allSubmenu
            menu.addItem(allItem)
        }

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Reload",
            action: #selector(reloadAll),
            keyEquivalent: "r"
        ))
        menu.items.last?.target = self

        let pauseTitle = displayManager.isPaused ? "Resume" : "Pause"
        menu.addItem(NSMenuItem(
            title: pauseTitle,
            action: #selector(togglePause),
            keyEquivalent: "p"
        ))
        menu.items.last?.target = self

        menu.addItem(.separator())

        let dirItem = NSMenuItem(
            title: "Wallpaper Folder\u{2026}",
            action: #selector(changeWallpaperFolder),
            keyEquivalent: ""
        )
        dirItem.target = self
        menu.addItem(dirItem)

        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        ))
        menu.items.last?.target = self
    }

    // MARK: - Actions

    @objc private func setDisplayWallpaper(_ sender: NSMenuItem) {
        guard let pair = sender.representedObject as? (CGDirectDisplayID, String) else { return }
        displayManager.setWallpaper(pair.1, displayID: pair.0)
    }

    @objc private func setAllWallpaper(_ sender: NSMenuItem) {
        guard let video = sender.representedObject as? String else { return }
        displayManager.setWallpaperOnAll(video)
    }

    @objc private func reloadAll() {
        displayManager.reloadAll()
    }

    @objc private func togglePause() {
        if displayManager.isPaused {
            displayManager.resumeAll()
        } else {
            displayManager.pauseAll()
        }
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                config.setLaunchAtLogin(false)
            } else {
                try SMAppService.mainApp.register()
                config.setLaunchAtLogin(true)
            }
        } catch {
            NSLog("Wally: failed to toggle launch at login: \(error)")
        }
    }

    @objc private func changeWallpaperFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = config.wallpaperDirectoryURL
        panel.prompt = "Select"
        panel.message = "Choose the folder containing your wallpaper videos"

        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }

        config.setWallpaperDirectory(url.path)
        displayManager.reloadAll()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
