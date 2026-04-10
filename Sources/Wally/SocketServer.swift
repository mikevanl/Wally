import Foundation

class SocketServer {
    private let displayManager: DisplayManager
    private let wallpaperManager: WallpaperManager
    private let config: Config
    private var listenerFD: Int32 = -1
    private let queue = DispatchQueue(label: "com.mikevanleeuwen.wally.socket")
    private let socketPath: String

    init(displayManager: DisplayManager, wallpaperManager: WallpaperManager, config: Config,
         socketPath: String = IPCConstants.socketPath) {
        self.displayManager = displayManager
        self.wallpaperManager = wallpaperManager
        self.config = config
        self.socketPath = socketPath
    }

    func start() {
        unlink(socketPath)

        listenerFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard listenerFD >= 0 else {
            NSLog("Wally: failed to create socket")
            return
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            let buf = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: CChar.self)
            _ = socketPath.withCString { strcpy(buf, $0) }
        }

        let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                bind(listenerFD, sockPtr, addrLen)
            }
        }
        guard bindResult == 0 else {
            NSLog("Wally: failed to bind socket: \(errno)")
            return
        }

        listen(listenerFD, 5)
        queue.async { [weak self] in self?.acceptLoop() }
        NSLog("Wally: socket server started at \(socketPath)")
    }

    func stop() {
        let fd = listenerFD
        listenerFD = -1
        if fd >= 0 { close(fd) }
        unlink(socketPath)
    }

    private func acceptLoop() {
        while listenerFD >= 0 {
            let clientFD = accept(listenerFD, nil, nil)
            guard clientFD >= 0 else { break }
            handleConnection(clientFD)
        }
    }

    private func handleConnection(_ clientFD: Int32) {
        defer { close(clientFD) }

        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = read(clientFD, &buffer, buffer.count)
        guard bytesRead > 0 else { return }

        let data = Data(buffer.prefix(bytesRead))
        let jsonData = data.prefix(while: { $0 != UInt8(ascii: "\n") })

        guard let request = try? JSONDecoder().decode(IPCRequest.self, from: jsonData) else {
            sendResponse(IPCResponse(success: false, message: "Invalid request", data: nil), to: clientFD)
            return
        }

        let semaphore = DispatchSemaphore(value: 0)
        var response: IPCResponse!
        DispatchQueue.main.async { [weak self] in
            response = self?.processRequest(request)
                ?? IPCResponse(success: false, message: "Server unavailable", data: nil)
            semaphore.signal()
        }
        semaphore.wait()

        sendResponse(response, to: clientFD)
    }

    private func processRequest(_ request: IPCRequest) -> IPCResponse {
        switch request.command {
        case "list":
            let videos = wallpaperManager.availableVideos()
            return IPCResponse(success: true, message: nil, data: videos)

        case "set":
            guard let video = request.video else {
                return IPCResponse(success: false, message: "Missing video name", data: nil)
            }
            let videos = wallpaperManager.availableVideos()
            guard videos.contains(video) else {
                return IPCResponse(success: false, message: "Video not found: \(video)", data: nil)
            }
            if request.all == true {
                displayManager.setWallpaperOnAll(video)
                return IPCResponse(success: true, message: "Set \(video) on all displays", data: nil)
            } else if let index = request.display {
                guard let displayID = displayManager.displayID(at: index) else {
                    return IPCResponse(success: false, message: "Invalid display index: \(index)", data: nil)
                }
                displayManager.setWallpaper(video, displayID: displayID)
                return IPCResponse(success: true, message: "Set \(video) on display \(index)", data: nil)
            } else {
                // Default: set on all displays
                displayManager.setWallpaperOnAll(video)
                return IPCResponse(success: true, message: "Set \(video) on all displays", data: nil)
            }

        case "reload":
            displayManager.reloadAll()
            return IPCResponse(success: true, message: "Reloaded all displays", data: nil)

        case "displays":
            let info = displayManager.displayInfo()
            let lines = info.map { entry in
                let video = entry.video ?? "(none)"
                return "Display \(entry.index): ID \(entry.displayID) → \(video)"
            }
            return IPCResponse(success: true, message: nil, data: lines)

        case "pause":
            displayManager.pauseAll()
            return IPCResponse(success: true, message: "Paused all displays", data: nil)

        case "resume":
            displayManager.resumeAll()
            return IPCResponse(success: true, message: "Resumed all displays", data: nil)

        default:
            return IPCResponse(success: false, message: "Unknown command: \(request.command)", data: nil)
        }
    }

    private func sendResponse(_ response: IPCResponse, to fd: Int32) {
        guard var data = try? JSONEncoder().encode(response) else { return }
        data.append(UInt8(ascii: "\n"))
        data.withUnsafeBytes { ptr in
            _ = Foundation.write(fd, ptr.baseAddress!, ptr.count)
        }
    }
}
