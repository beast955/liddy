// Renders Liddy's dark tech icon: an open MacBook with a glowing tap zone on its display.
import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func c(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
}

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Dark graphite tile.
    let tile = NSRect(x: s * 0.075, y: s * 0.075, width: s * 0.85, height: s * 0.85)
    let tilePath = NSBezierPath(roundedRect: tile, xRadius: s * 0.20, yRadius: s * 0.20)
    let tileShadow = NSShadow()
    tileShadow.shadowColor = NSColor.black.withAlphaComponent(0.50)
    tileShadow.shadowBlurRadius = s * 0.04
    tileShadow.shadowOffset = NSSize(width: 0, height: -s * 0.012)
    tileShadow.set()
    NSGradient(colors: [c(0.035, 0.045, 0.075), c(0.075, 0.085, 0.15)])!.draw(in: tilePath, angle: -38)
    NSShadow().set()
    tilePath.lineWidth = s * 0.006
    c(0.43, 0.55, 0.76, 0.24).setStroke()
    tilePath.stroke()

    // Open laptop base, drawn first so the screen rests naturally on the hinge.
    let deck = NSBezierPath()
    deck.move(to: NSPoint(x: s * 0.25, y: s * 0.475))
    deck.line(to: NSPoint(x: s * 0.75, y: s * 0.475))
    deck.curve(to: NSPoint(x: s * 0.865, y: s * 0.275),
               controlPoint1: NSPoint(x: s * 0.805, y: s * 0.425),
               controlPoint2: NSPoint(x: s * 0.855, y: s * 0.305))
    deck.line(to: NSPoint(x: s * 0.135, y: s * 0.275))
    deck.curve(to: NSPoint(x: s * 0.25, y: s * 0.475),
               controlPoint1: NSPoint(x: s * 0.145, y: s * 0.305),
               controlPoint2: NSPoint(x: s * 0.195, y: s * 0.425))
    deck.close()
    NSGradient(colors: [c(0.12, 0.16, 0.24), c(0.045, 0.06, 0.095)])!.draw(in: deck, angle: -90)
    deck.lineWidth = s * 0.008
    c(0.40, 0.67, 0.89, 0.62).setStroke()
    deck.stroke()

    // Keyboard: small, dim keys that remain legible without clutter at icon size.
    for (row, y, count, totalWidth) in [(0, 0.405, 6, 0.37), (1, 0.365, 6, 0.45)] {
        let keyGap = s * 0.012
        let keyWidth = (s * totalWidth - CGFloat(count - 1) * keyGap) / CGFloat(count)
        let x0 = s * 0.5 - s * totalWidth / 2
        for col in 0..<count {
            let key = NSRect(x: x0 + CGFloat(col) * (keyWidth + keyGap), y: s * y,
                             width: keyWidth, height: s * 0.019)
            let keyPath = NSBezierPath(roundedRect: key, xRadius: s * 0.006, yRadius: s * 0.006)
            c(0.42, 0.58, 0.78, 0.58).setFill()
            keyPath.fill()
        }
        _ = row
    }

    // Trackpad and the bright front lip identify the sloping piece as a MacBook base.
    let trackpad = NSBezierPath(roundedRect: NSRect(x: s * 0.39, y: s * 0.305, width: s * 0.22, height: s * 0.038),
                                xRadius: s * 0.012, yRadius: s * 0.012)
    trackpad.lineWidth = s * 0.006
    c(0.42, 0.63, 0.83, 0.52).setStroke()
    trackpad.stroke()
    let frontLip = NSBezierPath()
    frontLip.lineWidth = s * 0.008
    frontLip.lineCapStyle = .round
    c(0.38, 0.78, 0.98, 0.78).setStroke()
    frontLip.move(to: NSPoint(x: s * 0.20, y: s * 0.282))
    frontLip.line(to: NSPoint(x: s * 0.80, y: s * 0.282))
    frontLip.stroke()

    // Thin electric hinge.
    let hinge = NSBezierPath(roundedRect: NSRect(x: s * 0.36, y: s * 0.458, width: s * 0.28, height: s * 0.012),
                             xRadius: s * 0.006, yRadius: s * 0.006)
    let hingeGlow = NSShadow()
    hingeGlow.shadowColor = c(0.13, 0.76, 1.0, 0.58)
    hingeGlow.shadowBlurRadius = s * 0.022
    hingeGlow.shadowOffset = .zero
    hingeGlow.set()
    c(0.26, 0.83, 1.0, 0.90).setFill()
    hinge.fill()
    NSShadow().set()

    // Dark glass display with a restrained cyan edge.
    let screen = NSRect(x: s * 0.235, y: s * 0.465, width: s * 0.53, height: s * 0.39)
    let screenPath = NSBezierPath(roundedRect: screen, xRadius: s * 0.055, yRadius: s * 0.055)
    c(0.035, 0.055, 0.095).setFill()
    screenPath.fill()
    let edgeGlow = NSShadow()
    edgeGlow.shadowColor = c(0.12, 0.77, 1.0, 0.48)
    edgeGlow.shadowBlurRadius = s * 0.022
    edgeGlow.shadowOffset = .zero
    edgeGlow.set()
    screenPath.lineWidth = s * 0.009
    c(0.27, 0.75, 1.0, 0.72).setStroke()
    screenPath.stroke()
    NSShadow().set()

    // Three-by-three tap zones and one active cell.
    let grid = screen.insetBy(dx: s * 0.054, dy: s * 0.050)
    let gap = s * 0.010
    let cellW = (grid.width - 2 * gap) / 3
    let cellH = (grid.height - 2 * gap) / 3
    let active = NSRect(x: grid.minX + 2 * (cellW + gap), y: grid.minY + 2 * (cellH + gap),
                        width: cellW, height: cellH)
    let activePath = NSBezierPath(roundedRect: active, xRadius: s * 0.018, yRadius: s * 0.018)
    NSGradient(colors: [c(0.10, 0.54, 0.76, 0.54), c(0.34, 0.25, 0.78, 0.34)])!
        .draw(in: activePath, angle: -45)

    let lines = NSBezierPath()
    lines.lineWidth = s * 0.006
    lines.lineCapStyle = .round
    c(0.40, 0.57, 0.78, 0.32).setStroke()
    for step in 1...2 {
        let x = grid.minX + CGFloat(step) * (cellW + gap) - gap / 2
        let y = grid.minY + CGFloat(step) * (cellH + gap) - gap / 2
        lines.move(to: NSPoint(x: x, y: grid.minY))
        lines.line(to: NSPoint(x: x, y: grid.maxY))
        lines.move(to: NSPoint(x: grid.minX, y: y))
        lines.line(to: NSPoint(x: grid.maxX, y: y))
    }
    lines.stroke()

    // Tap pulse and luminous core.
    let target = NSPoint(x: active.midX, y: active.midY)
    for (radius, alpha, width) in [(s * 0.047, 0.72, s * 0.010), (s * 0.029, 0.98, s * 0.009)] {
        let ring = NSBezierPath(ovalIn: NSRect(x: target.x - radius, y: target.y - radius,
                                               width: radius * 2, height: radius * 2))
        ring.lineWidth = width
        let pulse = NSShadow()
        pulse.shadowColor = c(0.18, 0.84, 1.0, alpha * 0.70)
        pulse.shadowBlurRadius = s * 0.018
        pulse.shadowOffset = .zero
        pulse.set()
        c(0.34, 0.91, 1.0, alpha).setStroke()
        ring.stroke()
        NSShadow().set()
    }
    let dotRadius = s * 0.016
    c(0.31, 0.94, 1.0).setFill()
    NSBezierPath(ovalIn: NSRect(x: target.x - dotRadius, y: target.y - dotRadius,
                                width: dotRadius * 2, height: dotRadius * 2)).fill()
    let glintRadius = s * 0.005
    NSColor.white.setFill()
    NSBezierPath(ovalIn: NSRect(x: target.x - glintRadius, y: target.y - glintRadius,
                                width: glintRadius * 2, height: glintRadius * 2)).fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for (name, px) in [("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64), ("128x128", 128), ("128x128@2x", 256),
                   ("256x256", 256), ("256x256@2x", 512), ("512x512", 512), ("512x512@2x", 1024)] {
    try render(px).write(to: out.appendingPathComponent("icon_\(name).png"))
}
