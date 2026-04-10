import Foundation

struct IPCRequest: Codable {
    let command: String
    let video: String?
    let display: Int?
    let all: Bool?
    var path: String? = nil
}

struct IPCResponse: Codable {
    let success: Bool
    let message: String?
    let data: [String]?
}

enum IPCConstants {
    static let socketPath = "/tmp/com.mikevanleeuwen.wally.sock"
}
