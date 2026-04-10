import Foundation

func printUsage() {
    let usage = """
    Usage: wallpaper <command> [options]

    Commands:
      list                          List available videos
      set <video> [--display N]     Set wallpaper on a specific display (0-indexed)
      set <video> [--all]           Set wallpaper on all displays (default)
      reload                        Reload all webviews
      displays                      List connected displays with current assignments
      pause                         Pause video playback
      resume                        Resume video playback
    """
    print(usage)
}

let args = Array(CommandLine.arguments.dropFirst())

guard let command = args.first else {
    printUsage()
    exit(1)
}

let request: IPCRequest

switch command {
case "list":
    request = IPCRequest(command: "list", video: nil, display: nil, all: nil)

case "set":
    guard args.count >= 2 else {
        fputs("Error: 'set' requires a video name\n", stderr)
        exit(1)
    }
    let video = args[1]
    let hasAll = args.contains("--all")
    var display: Int? = nil
    if let idx = args.firstIndex(of: "--display"), idx + 1 < args.count,
       let n = Int(args[args.index(after: idx)]) {
        display = n
    }
    let all = hasAll || display == nil
    request = IPCRequest(command: "set", video: video, display: display, all: all)

case "reload":
    request = IPCRequest(command: "reload", video: nil, display: nil, all: nil)

case "displays":
    request = IPCRequest(command: "displays", video: nil, display: nil, all: nil)

case "pause":
    request = IPCRequest(command: "pause", video: nil, display: nil, all: nil)

case "resume":
    request = IPCRequest(command: "resume", video: nil, display: nil, all: nil)

case "help", "--help", "-h":
    printUsage()
    exit(0)

default:
    fputs("Unknown command: \(command)\n", stderr)
    printUsage()
    exit(1)
}

guard let response = SocketClient.send(request) else {
    exit(1)
}

if let data = response.data {
    for line in data {
        print(line)
    }
} else if let message = response.message {
    if response.success {
        print(message)
    } else {
        fputs("Error: \(message)\n", stderr)
    }
}

exit(response.success ? 0 : 1)
