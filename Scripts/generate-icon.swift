#!/usr/bin/env swift
import AppKit
import CoreGraphics

let size = 1024
let cgSize = CGSize(width: size, height: size)

guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
      let ctx = CGContext(
          data: nil, width: size, height: size,
          bitsPerComponent: 8, bytesPerRow: 0,
          space: colorSpace,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ) else {
    fatalError("Failed to create CGContext")
}

let rect = CGRect(origin: .zero, size: cgSize)

// macOS rounded rect (squircle)
let inset: CGFloat = 12
let iconRect = rect.insetBy(dx: inset, dy: inset)
let cornerRadius: CGFloat = 200
let roundedPath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

// Background gradient — deep navy to dark purple
ctx.saveGState()
ctx.addPath(roundedPath)
ctx.clip()

let gradientColors = [
    CGColor(red: 0.08, green: 0.08, blue: 0.18, alpha: 1.0),
    CGColor(red: 0.14, green: 0.06, blue: 0.28, alpha: 1.0),
    CGColor(red: 0.10, green: 0.04, blue: 0.22, alpha: 1.0),
]
let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: gradientColors as CFArray,
    locations: [0.0, 0.5, 1.0]
)!
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: CGFloat(size)),
    end: CGPoint(x: CGFloat(size), y: 0),
    options: []
)
ctx.restoreGState()

// Subtle border
ctx.saveGState()
ctx.addPath(roundedPath)
ctx.setStrokeColor(CGColor(red: 0.45, green: 0.35, blue: 0.75, alpha: 0.3))
ctx.setLineWidth(3)
ctx.strokePath()
ctx.restoreGState()

// Monitor shape — centered, slightly above middle
let monitorW: CGFloat = 520
let monitorH: CGFloat = 340
let monitorX = (CGFloat(size) - monitorW) / 2
let monitorY: CGFloat = 340
let monitorRect = CGRect(x: monitorX, y: monitorY, width: monitorW, height: monitorH)
let monitorRadius: CGFloat = 24

// Monitor bezel
ctx.saveGState()
let bezelPath = CGPath(roundedRect: monitorRect.insetBy(dx: -8, dy: -8), cornerWidth: monitorRadius + 4, cornerHeight: monitorRadius + 4, transform: nil)
ctx.addPath(bezelPath)
ctx.setFillColor(CGColor(red: 0.20, green: 0.18, blue: 0.30, alpha: 1.0))
ctx.fillPath()
ctx.restoreGState()

// Monitor screen with gradient
ctx.saveGState()
let screenPath = CGPath(roundedRect: monitorRect, cornerWidth: monitorRadius, cornerHeight: monitorRadius, transform: nil)
ctx.addPath(screenPath)
ctx.clip()

let screenColors = [
    CGColor(red: 0.12, green: 0.10, blue: 0.24, alpha: 1.0),
    CGColor(red: 0.18, green: 0.12, blue: 0.35, alpha: 1.0),
]
let screenGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: screenColors as CFArray,
    locations: [0.0, 1.0]
)!
ctx.drawLinearGradient(
    screenGradient,
    start: CGPoint(x: monitorX, y: monitorY + monitorH),
    end: CGPoint(x: monitorX + monitorW, y: monitorY),
    options: []
)
ctx.restoreGState()

// Monitor stand
let standW: CGFloat = 80
let standH: CGFloat = 50
let standX = (CGFloat(size) - standW) / 2
let standY = monitorY - standH - 8
ctx.setFillColor(CGColor(red: 0.20, green: 0.18, blue: 0.30, alpha: 1.0))
ctx.fill(CGRect(x: standX, y: standY, width: standW, height: standH + 8))

// Stand base
let baseW: CGFloat = 160
let baseH: CGFloat = 16
let baseX = (CGFloat(size) - baseW) / 2
let baseY = standY - 4
let basePath = CGPath(roundedRect: CGRect(x: baseX, y: baseY, width: baseW, height: baseH), cornerWidth: 8, cornerHeight: 8, transform: nil)
ctx.addPath(basePath)
ctx.setFillColor(CGColor(red: 0.20, green: 0.18, blue: 0.30, alpha: 1.0))
ctx.fillPath()

// Play triangle — centered on monitor screen
let playSize: CGFloat = 120
let playCenterX = CGFloat(size) / 2
let playCenterY = monitorY + monitorH / 2

// Soft glow behind play button
ctx.saveGState()
let glowRadius: CGFloat = 100
let glowGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(red: 0.55, green: 0.40, blue: 1.0, alpha: 0.3),
        CGColor(red: 0.55, green: 0.40, blue: 1.0, alpha: 0.0),
    ] as CFArray,
    locations: [0.0, 1.0]
)!
ctx.drawRadialGradient(
    glowGradient,
    startCenter: CGPoint(x: playCenterX, y: playCenterY),
    startRadius: 0,
    endCenter: CGPoint(x: playCenterX, y: playCenterY),
    endRadius: glowRadius,
    options: []
)
ctx.restoreGState()

// Play triangle
let triPath = CGMutablePath()
let offsetX: CGFloat = 12 // optical center adjustment
triPath.move(to: CGPoint(x: playCenterX - playSize * 0.38 + offsetX, y: playCenterY + playSize * 0.5))
triPath.addLine(to: CGPoint(x: playCenterX - playSize * 0.38 + offsetX, y: playCenterY - playSize * 0.5))
triPath.addLine(to: CGPoint(x: playCenterX + playSize * 0.5 + offsetX, y: playCenterY))
triPath.closeSubpath()

ctx.saveGState()
ctx.addPath(triPath)
ctx.clip()

let playColors = [
    CGColor(red: 0.65, green: 0.50, blue: 1.0, alpha: 0.95),
    CGColor(red: 0.45, green: 0.30, blue: 0.90, alpha: 0.95),
]
let playGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: playColors as CFArray,
    locations: [0.0, 1.0]
)!
ctx.drawLinearGradient(
    playGradient,
    start: CGPoint(x: playCenterX, y: playCenterY + playSize / 2),
    end: CGPoint(x: playCenterX, y: playCenterY - playSize / 2),
    options: []
)
ctx.restoreGState()

// Generate image
guard let cgImage = ctx.makeImage() else {
    fatalError("Failed to create image")
}

let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to create PNG")
}

// Write 1024x1024 master
let masterURL = URL(fileURLWithPath: "Resources/AppIcon.png")
try! pngData.write(to: masterURL)
print("Wrote master icon: Resources/AppIcon.png")

// Create iconset
let iconsetPath = "Resources/AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetPath)
try! FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

let masterImage = NSImage(cgImage: cgImage, size: NSSize(width: 1024, height: 1024))

for (name, px) in sizes {
    let targetSize = NSSize(width: px, height: px)
    let resized = NSImage(size: targetSize)
    resized.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    masterImage.draw(in: NSRect(origin: .zero, size: targetSize))
    resized.unlockFocus()

    guard let tiffData = resized.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiffData),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to resize to \(name)")
    }
    try! png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name)"))
}

print("Created iconset at \(iconsetPath)")
print("Run: iconutil -c icns \(iconsetPath) -o Resources/AppIcon.icns")
