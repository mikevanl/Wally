import AppKit
import AVFoundation

class WallpaperWindow: NSWindow {
    let displayID: CGDirectDisplayID
    private let playerLayer: AVPlayerLayer
    private var player: AVPlayer?
    private var loopObserver: Any?
    private var isPaused = false

    init(displayID: CGDirectDisplayID, screen: NSScreen) {
        self.displayID = displayID
        self.playerLayer = AVPlayerLayer()
        playerLayer.videoGravity = .resizeAspectFill

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

        let view = NSView(frame: screen.frame)
        view.wantsLayer = true
        view.layer = CALayer()
        playerLayer.frame = view.bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer?.addSublayer(playerLayer)
        contentView = view

        orderFrontRegardless()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func loadVideo(url: URL) {
        removeLoopObserver()

        let item = AVPlayerItem(url: url)
        if let player {
            player.replaceCurrentItem(with: item)
        } else {
            player = AVPlayer(playerItem: item)
            player?.isMuted = true
            playerLayer.player = player
        }

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }

        player?.play()
        isPaused = false
    }

    func pauseVideo() {
        player?.pause()
        isPaused = true
    }

    func resumeVideo() {
        player?.play()
        isPaused = false
    }

    var isVideoPaused: Bool { isPaused }

    func updateFrame(for screen: NSScreen) {
        setFrame(screen.frame, display: true)
        contentView?.frame = NSRect(origin: .zero, size: screen.frame.size)
        playerLayer.frame = contentView?.bounds ?? .zero
    }

    private func removeLoopObserver() {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
        loopObserver = nil
    }

    deinit {
        removeLoopObserver()
    }
}
