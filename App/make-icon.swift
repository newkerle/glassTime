#!/usr/bin/env swift
// Renders a LAYER of the macOS 26 .icon bundle (App/AppIcon.icon) at 1024×1024.
//
//   swift make-icon.swift clock <out.png>   the white clock line-art (transparent)
//   swift make-icon.swift bg    <out.png>    the pale-blue frosted-glass tile
//
// bundle.sh renders both, and actool composites them: the system masks the bg
// to the Tahoe squircle and frosts it, with the clock extruded as glass on top.
import AppKit

let size: CGFloat = 1024
let mode = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "clock"
let outPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "\(mode)-1024.png"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("no context") }

let rect = CGRect(x: 0, y: 0, width: size, height: size)
let center = CGPoint(x: size / 2, y: size / 2)
let faceR = size * 0.40

ctx.clear(rect)

switch mode {
case "bg":
    // Full-bleed pale-blue gradient; actool masks it to the squircle and the
    // Tahoe glass treatment turns it into a soft, translucent frosted tile.
    let g = NSGradient(colors: [
        NSColor(calibratedRed: 0.74, green: 0.84, blue: 0.96, alpha: 1),
        NSColor(calibratedRed: 0.52, green: 0.66, blue: 0.88, alpha: 1),
    ])!
    g.draw(in: rect, angle: -90)

case "clock":
    // Clock rim (an open ring).
    let faceRect = CGRect(x: center.x - faceR, y: center.y - faceR, width: faceR * 2, height: faceR * 2)
    let rim = NSBezierPath(ovalIn: faceRect)
    rim.lineWidth = size * 0.022
    NSColor.white.setStroke()
    rim.stroke()

    // Hour ticks — bold so they extrude clearly as glass.
    NSColor.white.setStroke()
    for i in 0..<12 {
        let angle = CGFloat(i) / 12 * 2 * .pi
        let isMajor = i % 3 == 0
        let outer = faceR * 0.88
        let inner = faceR * (isMajor ? 0.70 : 0.76)
        let p = NSBezierPath()
        p.lineWidth = size * (isMajor ? 0.024 : 0.015)
        p.lineCapStyle = .round
        p.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
        p.line(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
        p.stroke()
    }

    // Hands at a classic 10:10.
    func hand(angleDeg: CGFloat, length: CGFloat, width: CGFloat, color: NSColor) {
        let a = (90 - angleDeg) * .pi / 180  // clock degrees → screen radians
        let p = NSBezierPath()
        p.lineWidth = width
        p.lineCapStyle = .round
        p.move(to: center)
        p.line(to: CGPoint(x: center.x + cos(a) * length, y: center.y + sin(a) * length))
        color.setStroke()
        p.stroke()
    }
    hand(angleDeg: 300, length: faceR * 0.50, width: size * 0.026, color: .white) // hour → 10
    hand(angleDeg: 60,  length: faceR * 0.70, width: size * 0.020, color: .white) // minute → 2
    hand(angleDeg: 90,  length: faceR * 0.74, width: size * 0.009,
         color: NSColor(calibratedRed: 0.10, green: 0.45, blue: 0.95, alpha: 1)) // second

    // Hub.
    NSColor.white.setFill()
    let hubR = size * 0.020
    NSBezierPath(ovalIn: CGRect(x: center.x - hubR, y: center.y - hubR, width: hubR * 2, height: hubR * 2)).fill()

default:
    fatalError("unknown mode \(mode) — use 'clock' or 'bg'")
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("encode failed")
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
