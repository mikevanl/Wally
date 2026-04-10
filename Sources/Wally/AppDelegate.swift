import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var config: Config!
    private var wallpaperManager: WallpaperManager!
    private var displayManager: DisplayManager!
    private var menuBarController: MenuBarController!
    private var socketServer: SocketServer!

    func applicationDidFinishLaunching(_ notification: Notification) {
        config = Config()
        wallpaperManager = WallpaperManager(config: config)
        displayManager = DisplayManager(wallpaperManager: wallpaperManager, config: config)
        displayManager.setupDisplays()
        menuBarController = MenuBarController(
            displayManager: displayManager,
            wallpaperManager: wallpaperManager,
            config: config
        )
        socketServer = SocketServer(
            displayManager: displayManager,
            wallpaperManager: wallpaperManager,
            config: config
        )
        socketServer.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        socketServer?.stop()
    }
}
