# Wally

A native macOS menu bar app that renders video wallpapers on your desktop using AVPlayer. Built with Swift and AppKit — no third-party dependencies.

Replaces [Plash](https://github.com/nickmilo/plash) with a scriptable CLI, per-display wallpaper assignments, and a clean menu bar interface.

## Features

- Full-screen video wallpaper on every connected display
- Per-display wallpaper assignments (different video per monitor)
- Hardware-accelerated H.264 playback via VideoToolbox
- CLI tool for scripting and automation
- Menu bar dropdown for quick wallpaper switching
- Configurable wallpaper directory
- Persists assignments across restarts
- Auto-detects display connect/disconnect
- Resumes playback after system sleep
- Launch at Login support via SMAppService
- No Dock icon (LSUIElement)

## Requirements

- macOS 14+ (Sonoma)
- Xcode Command Line Tools (`xcode-select --install`)

## Installation

### Build from source

```bash
git clone https://github.com/mikevanl/Wally.git
cd Wally
bash Scripts/build.sh
```

### Install

```bash
cp -r .build/release/Wally.app /Applications/
cp .build/release/wallpaper ~/.local/bin/
```

Make sure `~/.local/bin` is in your `PATH`.

### Launch

```bash
open /Applications/Wally.app
```

## Usage

### CLI

```bash
wallpaper list                        # List available videos
wallpaper set <video>                 # Set wallpaper on all displays
wallpaper set <video> --all           # Set wallpaper on all displays (explicit)
wallpaper set <video> --display 0     # Set wallpaper on a specific display (0-indexed)
wallpaper reload                      # Reload all webviews
wallpaper displays                    # List connected displays with current assignments
wallpaper pause                       # Pause video playback
wallpaper resume                      # Resume video playback
```

### Menu Bar

Click the menu bar icon to access:

- **Display N** — submenu listing available videos; checkmark shows current assignment
- **Set All** — set the same video on all displays
- **Reload** — reload all webviews
- **Pause / Resume** — toggle video playback
- **Wallpaper Folder...** — change the directory Wally scans for `.mp4` files
- **Launch at Login** — toggle auto-start
- **Quit**

## Configuration

Config is stored at `~/Library/Application Support/Wally/config.json`:

```json
{
  "wallpaperDirectory": "/Users/you/path/to/wallpapers",
  "assignments": {
    "5": "video-a.mp4",
    "6": "video-b.mp4"
  },
  "launchAtLogin": false
}
```

- `wallpaperDirectory` — path to the folder containing `.mp4` files
- `assignments` — maps display IDs to video filenames
- `launchAtLogin` — whether Wally starts on login

The wallpaper directory defaults to `~/.config/wally/wallpapers/` and can be changed via the menu bar or by editing the config file directly.

## SketchyBar Integration

If you use [SketchyBar](https://github.com/FelixKratz/SketchyBar) with a wallpaper switcher plugin, replace the Plash calls:

```bash
# Before
cat > "$HTML_FILE" <<EOF
...
EOF
plash reload

# After
wallpaper set "$VIDEO" --all
```

## Architecture

```
Wally.app (menu bar)  <-- Unix socket -->  wallpaper (CLI)
     |
     +-- DisplayManager --> [WallpaperWindow + AVPlayerLayer] per display
     +-- Config         --> ~/Library/Application Support/Wally/config.json
     +-- SocketServer   --> /tmp/com.mikevanleeuwen.wally.sock
```

The app and CLI communicate over a Unix domain socket using newline-delimited JSON. The app renders one borderless `NSWindow` per display at `kCGDesktopWindowLevel + 1`, each containing a `WKWebView` playing a looped `<video>` element.

## Project Structure

```
Wally/
├── Package.swift
├── Sources/
│   ├── Wally/                        # Menu bar app
│   │   ├── main.swift
│   │   ├── AppDelegate.swift
│   │   ├── Config.swift
│   │   ├── WallpaperManager.swift
│   │   ├── DisplayManager.swift
│   │   ├── WallpaperWindow.swift
│   │   ├── MenuBarController.swift
│   │   ├── SocketServer.swift
│   │   └── IPCProtocol.swift
│   └── wallpaper/                    # CLI tool
│       ├── main.swift
│       ├── SocketClient.swift
│       └── IPCProtocol.swift
├── Scripts/
│   └── build.sh
└── Resources/
    └── Info.plist
```

## License

MIT
