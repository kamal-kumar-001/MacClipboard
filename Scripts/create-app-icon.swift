import AppKit
import ImageIO

let outputDirectory = CommandLine.arguments[1]
let fileManager = FileManager.default
try fileManager.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("16x16", 16), ("16x16@2x", 32),
    ("32x32", 32), ("32x32@2x", 64),
    ("128x128", 128), ("128x128@2x", 256),
    ("256x256", 256), ("256x256@2x", 512),
    ("512x512", 512), ("512x512@2x", 1024)
]

for (name, size) in sizes {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    NSColor(calibratedRed: 0.12, green: 0.48, blue: 0.92, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size), xRadius: size * 0.22, yRadius: size * 0.22).fill()

    if let symbol = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil) {
        let symbolSize = size * 0.58
        let symbolRect = NSRect(
            x: (size - symbolSize) / 2,
            y: (size - symbolSize) / 2,
            width: symbolSize,
            height: symbolSize
        )
        NSColor.white.set()
        symbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1)
    }

    image.unlockFocus()

    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
          let destination = CGImageDestinationCreateWithURL(
              URL(fileURLWithPath: "\(outputDirectory)/icon_\(name).png") as CFURL,
              "public.png" as CFString,
              1,
              nil
          ) else {
        exit(1)
    }

    CGImageDestinationAddImage(destination, cgImage, nil)
    CGImageDestinationFinalize(destination)
}
