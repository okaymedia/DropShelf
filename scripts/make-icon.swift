import AppKit
import CoreGraphics
import Foundation

// Draw in a fixed, bottom-left-origin coordinate space, then rasterize each size.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("DropShelf/Resources/Assets.xcassets")

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: a)
}
func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}
func fill(_ ctx: CGContext, _ path: CGPath, _ c: CGColor) {
    ctx.addPath(path); ctx.setFillColor(c); ctx.fillPath()
}
func gradient(_ ctx: CGContext, _ path: CGPath, _ colors: [CGColor], _ start: CGPoint, _ end: CGPoint) {
    ctx.saveGState(); ctx.addPath(path); ctx.clip()
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
    ctx.drawLinearGradient(grad, start: start, end: end, options: [])
    ctx.restoreGState()
}
func shadow(_ ctx: CGContext, _ blur: CGFloat, _ y: CGFloat, _ alpha: CGFloat) {
    ctx.setShadow(offset: CGSize(width: 0, height: y), blur: blur, color: color(0.08, 0.08, 0.25, alpha))
}
func polygon(_ points: [CGPoint]) -> CGPath {
    let p = CGMutablePath(); p.move(to: points[0]); for point in points.dropFirst() { p.addLine(to: point) }; p.closeSubpath(); return p
}
func document(_ ctx: CGContext, x: CGFloat, y: CGFloat, angle: CGFloat, tint: CGColor, lines: Bool) {
    ctx.saveGState(); ctx.translateBy(x: x, y: y); ctx.rotate(by: angle)
    let card = polygon([CGPoint(x: -77, y: -105), CGPoint(x: 77, y: -105), CGPoint(x: 77, y: 59), CGPoint(x: 33, y: 105), CGPoint(x: -77, y: 105)])
    ctx.saveGState(); shadow(ctx, 18, -8, 0.25); fill(ctx, card, tint); ctx.restoreGState()
    fill(ctx, polygon([CGPoint(x: 33, y: 105), CGPoint(x: 33, y: 59), CGPoint(x: 77, y: 59)]), color(0.79, 0.84, 0.92))
    if lines {
        for y in [CGFloat(25), -8, -41] {
            fill(ctx, rounded(CGRect(x: -47, y: y, width: 91, height: 10), 5), color(0.65, 0.68, 0.75, 0.8))
        }
    }
    ctx.restoreGState()
}
func drawApp(_ ctx: CGContext) {
    let body = rounded(CGRect(x: 100, y: 100, width: 824, height: 824), 185)
    ctx.saveGState(); shadow(ctx, 32, -15, 0.28); fill(ctx, body, color(0.22, 0.24, 0.75)); ctx.restoreGState()
    gradient(ctx, body, [color(0x7A/255, 0x4D/255, 0xF0/255), color(0x3B/255, 0x3F/255, 0xD8/255)], CGPoint(x: 512, y: 100), CGPoint(x: 512, y: 924))
    ctx.saveGState(); ctx.addPath(body); ctx.clip()
    gradient(ctx, rounded(CGRect(x: 115, y: 730, width: 794, height: 190), 120), [color(1, 1, 1, 0), color(1, 1, 1, 0.12)], CGPoint(x: 512, y: 730), CGPoint(x: 512, y: 920))
    ctx.restoreGState()
    // Motion marks sit above the bold, overlapping paper silhouettes.
    for (x, y, h) in [(CGFloat(431), CGFloat(755), CGFloat(42)), (512, 775, 55), (593, 755, 42)] {
        fill(ctx, rounded(CGRect(x: x - 5, y: y, width: 10, height: h), 5), color(1, 1, 1, 0.45))
    }
    document(ctx, x: 383, y: 555, angle: 0.22, tint: color(0.82, 0.91, 1), lines: false)
    // Folder, behind the central document.
    ctx.saveGState(); ctx.translateBy(x: 646, y: 544); ctx.rotate(by: -0.20)
    let folder = polygon([CGPoint(x: -79, y: -75), CGPoint(x: 79, y: -75), CGPoint(x: 79, y: 67), CGPoint(x: 5, y: 67), CGPoint(x: -12, y: 87), CGPoint(x: -79, y: 87)])
    ctx.saveGState(); shadow(ctx, 18, -8, 0.25); fill(ctx, folder, color(1, 0.78, 0.27)); ctx.restoreGState()
    fill(ctx, rounded(CGRect(x: -79, y: -75, width: 158, height: 125), 13), color(1, 0.82, 0.36))
    ctx.restoreGState()
    document(ctx, x: 512, y: 567, angle: 0, tint: color(1, 1, 1), lines: true)
    // A shallow, translucent back rim and a solid front lip give the shelf depth.
    let tray = rounded(CGRect(x: 263, y: 322, width: 498, height: 135), 42)
    ctx.saveGState(); shadow(ctx, 24, -12, 0.25); fill(ctx, tray, color(1, 1, 1, 0.92)); ctx.restoreGState()
    gradient(ctx, tray, [color(0.82, 0.86, 0.97, 0.96), color(1, 1, 1, 0.95)], CGPoint(x: 512, y: 322), CGPoint(x: 512, y: 457))
    fill(ctx, rounded(CGRect(x: 290, y: 397, width: 444, height: 20), 10), color(0.53, 0.56, 0.76, 0.32))
    fill(ctx, rounded(CGRect(x: 275, y: 329, width: 474, height: 49), 22), color(0.75, 0.80, 0.93, 0.55))
}
func drawMenu(_ ctx: CGContext) {
    ctx.setStrokeColor(color(0, 0, 0)); ctx.setLineWidth(1.5); ctx.setLineCap(.round); ctx.setLineJoin(.round)
    ctx.move(to: CGPoint(x: 2, y: 7)); ctx.addLine(to: CGPoint(x: 3.3, y: 3)); ctx.addQuadCurve(to: CGPoint(x: 5, y: 2), control: CGPoint(x: 3.6, y: 2)); ctx.addLine(to: CGPoint(x: 13, y: 2)); ctx.addQuadCurve(to: CGPoint(x: 14.7, y: 3), control: CGPoint(x: 14.4, y: 2)); ctx.addLine(to: CGPoint(x: 16, y: 7)); ctx.strokePath()
    ctx.move(to: CGPoint(x: 2, y: 7)); ctx.addLine(to: CGPoint(x: 6.5, y: 7)); ctx.addLine(to: CGPoint(x: 7.3, y: 5.8)); ctx.addLine(to: CGPoint(x: 10.7, y: 5.8)); ctx.addLine(to: CGPoint(x: 11.5, y: 7)); ctx.addLine(to: CGPoint(x: 16, y: 7)); ctx.strokePath()
    ctx.addPath(rounded(CGRect(x: 6.3, y: 9, width: 5.4, height: 7), 0.7)); ctx.strokePath()
}
func writePNG(size: Int, logical: CGFloat, url: URL, draw: (CGContext) -> Void) throws {
    let space = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { fatalError("Cannot create bitmap") }
    ctx.scaleBy(x: CGFloat(size) / logical, y: CGFloat(size) / logical)
    draw(ctx)
    guard let image = ctx.makeImage(), let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { fatalError("Cannot encode PNG") }
    try data.write(to: url, options: .atomic)
}
let appDir = assets.appendingPathComponent("AppIcon.appiconset")
let menuDir = assets.appendingPathComponent("MenuBarIcon.imageset")
try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: menuDir, withIntermediateDirectories: true)
var images: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
    for scale in 1...2 {
        let filename = "icon_\(size)x\(size)@\(scale)x.png"
        try writePNG(size: size * scale, logical: 1024, url: appDir.appendingPathComponent(filename), draw: drawApp)
        images.append(["idiom": "mac", "size": "\(size)x\(size)", "scale": "\(scale)x", "filename": filename])
    }
}
let menuImages = (1...2).map { scale in ["idiom": "universal", "scale": "\(scale)x", "filename": "menu@\(scale)x.png"] }
for scale in 1...2 { try writePNG(size: 18 * scale, logical: 18, url: menuDir.appendingPathComponent("menu@\(scale)x.png"), draw: drawMenu) }
func writeJSON(_ object: [String: Any], _ url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try (data + Data("\n".utf8)).write(to: url, options: .atomic)
}
try writeJSON(["images": images, "info": ["author": "xcode", "version": 1]], appDir.appendingPathComponent("Contents.json"))
try writeJSON(["images": menuImages, "info": ["author": "xcode", "version": 1], "properties": ["template-rendering-intent": "template"]], menuDir.appendingPathComponent("Contents.json"))
print("Generated app and menu bar icons.")
