import Foundation

enum SocketClient {
    static func send(_ request: IPCRequest, socketPath: String = IPCConstants.socketPath) -> IPCResponse? {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            fputs("Error: could not create socket\n", stderr)
            return nil
        }
        defer { close(fd) }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            let buf = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: CChar.self)
            _ = socketPath.withCString { strcpy(buf, $0) }
        }

        let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
        let connectResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                connect(fd, sockPtr, addrLen)
            }
        }
        guard connectResult == 0 else {
            fputs("Error: Wally is not running (could not connect to \(socketPath))\n", stderr)
            return nil
        }

        guard var data = try? JSONEncoder().encode(request) else {
            fputs("Error: failed to encode request\n", stderr)
            return nil
        }
        data.append(UInt8(ascii: "\n"))
        let written = data.withUnsafeBytes { ptr in
            write(fd, ptr.baseAddress!, ptr.count)
        }
        guard written == data.count else {
            fputs("Error: failed to send request\n", stderr)
            return nil
        }

        var buffer = [UInt8](repeating: 0, count: 65536)
        let bytesRead = read(fd, &buffer, buffer.count)
        guard bytesRead > 0 else {
            fputs("Error: no response from Wally\n", stderr)
            return nil
        }

        let responseData = Data(buffer.prefix(bytesRead))
        return try? JSONDecoder().decode(IPCResponse.self, from: responseData)
    }
}
