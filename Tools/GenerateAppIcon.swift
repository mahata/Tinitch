#!/usr/bin/env swift

// Draws the Tinitch app icon and writes every size the asset catalog needs.
//
//     swift Tools/GenerateAppIcon.swift Tinitch/Assets.xcassets/AppIcon.appiconset
//
// The artwork is a blue squircle holding a tilted photo card with an annotation
// arrow sweeping across it, mirroring what the app does: mark up images.

import AppKit
import CoreGraphics
import Foundation

let design: CGFloat = 1024

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

/// Apple-style continuous corner rounding, approximated with a superellipse.
func squirclePath(in rect: CGRect, exponent: CGFloat = 5) -> CGPath {
    let path = CGMutablePath()
    let a = rect.width / 2
    let b = rect.height / 2
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let steps = 720
    for step in 0...steps {
        let theta = CGFloat(step) / CGFloat(steps) * 2 * .pi
        let c = cos(theta)
        let s = sin(theta)
        let x = center.x + a * copysign(pow(abs(c), 2 / exponent), c)
        let y = center.y + b * copysign(pow(abs(s), 2 / exponent), s)
        if step == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()
    return path
}

func linearGradient(_ colors: [CGColor], _ locations: [CGFloat]) -> CGGradient {
    CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors as CFArray,
        locations: locations
    )!
}

func fill(_ context: CGContext, path: CGPath, gradient: CGGradient, from: CGPoint, to: CGPoint) {
    context.saveGState()
    context.addPath(path)
    context.clip()
    context.drawLinearGradient(gradient, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    context.restoreGState()
}

// MARK: - Arrow geometry

let arrowStart = CGPoint(x: 258, y: 318)
let arrowControl1 = CGPoint(x: 420, y: 214)
let arrowControl2 = CGPoint(x: 566, y: 408)
let arrowEnd = CGPoint(x: 742, y: 648)
let arrowWidth: CGFloat = 62
let headLength: CGFloat = 132
let headHalfWidth: CGFloat = 104

func arrowPaths() -> (shaft: CGPath, head: CGPath) {
    let tangent = CGVector(dx: arrowEnd.x - arrowControl2.x, dy: arrowEnd.y - arrowControl2.y)
    let length = sqrt(tangent.dx * tangent.dx + tangent.dy * tangent.dy)
    let unit = CGVector(dx: tangent.dx / length, dy: tangent.dy / length)
    let normal = CGVector(dx: -unit.dy, dy: unit.dx)

    let shaft = CGMutablePath()
    shaft.move(to: arrowStart)
    shaft.addCurve(to: arrowEnd, control1: arrowControl1, control2: arrowControl2)
    let stroked = shaft.copy(strokingWithWidth: arrowWidth, lineCap: .round, lineJoin: .round, miterLimit: 10)

    let base = CGPoint(x: arrowEnd.x - unit.dx * 18, y: arrowEnd.y - unit.dy * 18)
    let tip = CGPoint(x: base.x + unit.dx * headLength, y: base.y + unit.dy * headLength)
    let head = CGMutablePath()
    head.move(to: tip)
    head.addLine(to: CGPoint(x: base.x + normal.dx * headHalfWidth, y: base.y + normal.dy * headHalfWidth))
    head.addLine(to: CGPoint(x: base.x - normal.dx * headHalfWidth, y: base.y - normal.dy * headHalfWidth))
    head.closeSubpath()

    return (stroked, head)
}

// MARK: - Drawing

func drawIcon(in context: CGContext) {
    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    // Squircle body, inset the way macOS icon artwork expects.
    let bodyRect = CGRect(x: 100, y: 110, width: 824, height: 824)
    let body = squirclePath(in: bodyRect)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -18), blur: 42, color: rgb(0x0A1A3C, 0.32))
    context.addPath(body)
    context.setFillColor(rgb(0x2E63E8))
    context.fillPath()
    context.restoreGState()

    fill(
        context,
        path: body,
        gradient: linearGradient([rgb(0x6AA8FF), rgb(0x3A6BF0), rgb(0x1E3FC4)], [0, 0.55, 1]),
        from: CGPoint(x: bodyRect.minX, y: bodyRect.maxY),
        to: CGPoint(x: bodyRect.maxX, y: bodyRect.minY)
    )

    // Soft sheen across the top half.
    context.saveGState()
    context.addPath(body)
    context.clip()
    context.drawLinearGradient(
        linearGradient([rgb(0xFFFFFF, 0.30), rgb(0xFFFFFF, 0)], [0, 1]),
        start: CGPoint(x: bodyRect.midX, y: bodyRect.maxY),
        end: CGPoint(x: bodyRect.midX, y: bodyRect.midY),
        options: []
    )
    context.restoreGState()

    // Photo card, tilted slightly counter-clockwise.
    let cardRect = CGRect(x: -290, y: -216, width: 580, height: 432)
    context.saveGState()
    context.translateBy(x: 500, y: 536)
    context.rotate(by: -7 * .pi / 180)

    let card = CGPath(roundedRect: cardRect, cornerWidth: 38, cornerHeight: 38, transform: nil)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -16), blur: 34, color: rgb(0x0A1A3C, 0.40))
    context.addPath(card)
    context.setFillColor(rgb(0xFFFFFF))
    context.fillPath()
    context.restoreGState()

    // Card contents: a sun and two ridges, clipped to the card.
    context.saveGState()
    context.addPath(card)
    context.clip()

    context.setFillColor(rgb(0xDCE9FF))
    context.fillEllipse(in: CGRect(x: -232, y: 96, width: 108, height: 108))

    let farRidge = CGMutablePath()
    farRidge.move(to: CGPoint(x: -290, y: -40))
    farRidge.addLine(to: CGPoint(x: -96, y: 118))
    farRidge.addLine(to: CGPoint(x: 96, y: -40))
    farRidge.addLine(to: CGPoint(x: 290, y: 118))
    farRidge.addLine(to: CGPoint(x: 290, y: -216))
    farRidge.addLine(to: CGPoint(x: -290, y: -216))
    farRidge.closeSubpath()
    context.addPath(farRidge)
    context.setFillColor(rgb(0xC7DBFF))
    context.fillPath()

    let nearRidge = CGMutablePath()
    nearRidge.move(to: CGPoint(x: -290, y: -112))
    nearRidge.addLine(to: CGPoint(x: -34, y: 42))
    nearRidge.addLine(to: CGPoint(x: 290, y: -144))
    nearRidge.addLine(to: CGPoint(x: 290, y: -216))
    nearRidge.addLine(to: CGPoint(x: -290, y: -216))
    nearRidge.closeSubpath()
    context.addPath(nearRidge)
    context.setFillColor(rgb(0x9BBEF7))
    context.fillPath()

    context.restoreGState()
    context.restoreGState()

    // Annotation arrow with a white keyline so it reads over the card.
    let (shaft, head) = arrowPaths()
    let keylineWidth: CGFloat = 30

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 26, color: rgb(0x2A0A14, 0.38))
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    context.setFillColor(rgb(0xFFFFFF))
    for path in [shaft, head] {
        context.addPath(path.copy(strokingWithWidth: keylineWidth, lineCap: .round, lineJoin: .round, miterLimit: 10))
        context.addPath(path)
        context.fillPath()
    }
    context.endTransparencyLayer()
    context.restoreGState()

    let arrowGradient = linearGradient([rgb(0xFF9A3D), rgb(0xFF5C5C), rgb(0xF0356F)], [0, 0.55, 1])
    for path in [shaft, head] {
        fill(context, path: path, gradient: arrowGradient, from: arrowStart, to: arrowEnd)
    }
}

func renderIcon(size: CGFloat) -> CGImage {
    let pixels = Int(size)
    let context = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    let scale = size / design
    context.scaleBy(x: scale, y: scale)
    drawIcon(in: context)
    return context.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) throws {
    let rep = NSBitmapImageRep(cgImage: image)
    rep.size = NSSize(width: image.width, height: image.height)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "GenerateAppIcon", code: 1)
    }
    try data.write(to: url)
}

// MARK: - Asset catalog output

struct IconEntry {
    let point: Int
    let scale: Int
    var pixels: Int { point * scale }
    var filename: String { "icon_\(point)x\(point)\(scale == 2 ? "@2x" : "").png" }
}

let entries = [16, 32, 128, 256, 512].flatMap { point in
    [IconEntry(point: point, scale: 1), IconEntry(point: point, scale: 2)]
}

let arguments = CommandLine.arguments
guard arguments.count > 1 else {
    FileHandle.standardError.write("usage: GenerateAppIcon.swift <AppIcon.appiconset path>\n".data(using: .utf8)!)
    exit(2)
}
let outputDirectory = URL(fileURLWithPath: arguments[1])
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

// Unique pixel sizes are rendered once and shared by the entries that need them.
var rendered: [Int: CGImage] = [:]
for entry in entries {
    let image = rendered[entry.pixels] ?? {
        let image = renderIcon(size: CGFloat(entry.pixels))
        rendered[entry.pixels] = image
        return image
    }()
    try writePNG(image, to: outputDirectory.appendingPathComponent(entry.filename))
}

let images = entries.map { entry in
    """
        {
          "filename" : "\(entry.filename)",
          "idiom" : "mac",
          "scale" : "\(entry.scale)x",
          "size" : "\(entry.point)x\(entry.point)"
        }
    """
}

let contents = """
{
  "images" : [
\(images.joined(separator: ",\n"))
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

"""
try contents.write(to: outputDirectory.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)

print("Wrote \(entries.count) icon images to \(outputDirectory.path)")
