import AppKit
import WebKit

class WallpaperWindow: NSWindow {
    let displayID: CGDirectDisplayID
    let webView: WKWebView
    private var isPaused = false

    init(displayID: CGDirectDisplayID, screen: NSScreen) {
        self.displayID = displayID

        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        self.webView = WKWebView(frame: screen.frame, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        level = NSWindow.Level(
            rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1
        )
        ignoresMouseEvents = true
        hasShadow = false
        animationBehavior = .none
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        backgroundColor = .black
        isReleasedWhenClosed = false

        contentView = webView
        orderFrontRegardless()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func loadVideo(_ html: String, baseURL: URL) {
        // Write HTML to a temp file in the wallpaper directory so loadFileURL
        // can grant read access to sibling video files. loadHTMLString + file://
        // baseURL does not grant actual filesystem read access.
        let tempFile = baseURL.appendingPathComponent(".wally-\(displayID).html")
        do {
            try html.write(to: tempFile, atomically: true, encoding: .utf8)
            webView.loadFileURL(tempFile, allowingReadAccessTo: baseURL)
        } catch {
            NSLog("Wally: failed to write temp HTML for display \(displayID): \(error)")
            webView.loadHTMLString(html, baseURL: baseURL)
        }
        isPaused = false
    }

    func pauseVideo() {
        webView.evaluateJavaScript("document.querySelector('video')?.pause()")
        isPaused = true
    }

    func resumeVideo() {
        webView.evaluateJavaScript("document.querySelector('video')?.play()")
        isPaused = false
    }

    var isVideoPaused: Bool { isPaused }

    func updateFrame(for screen: NSScreen) {
        setFrame(screen.frame, display: true)
        webView.frame = NSRect(origin: .zero, size: screen.frame.size)
    }
}
