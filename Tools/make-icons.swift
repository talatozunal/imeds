#!/usr/bin/env swift
//
//  make-icons.swift
//  imeds / imedtv
//
//  Uygulama ikonlarını üreten betik:
//    • imeds  (iPhone/iPad, gönderici) → uçan kağıt uçak, 1024x1024
//    • imedtv (Apple TV, alıcı)         → sabit TV + gelen medya, katmanlı brandassets
//
//  Kullanım:
//
//      swift Tools/make-icons.swift <Assets.xcassets yolu>
//
//  Betik ayrıca Tools/ altına iki önizleme PNG'si yazar.
//

import Foundation
import AppKit
import CoreGraphics

let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: sRGB, components: [
        CGFloat((hex >> 16) & 0xFF) / 255.0,
        CGFloat((hex >> 8) & 0xFF) / 255.0,
        CGFloat(hex & 0xFF) / 255.0,
        alpha
    ])!
}

func makeContext(_ width: Int, _ height: Int) -> CGContext {
    CGContext(data: nil,
              width: width,
              height: height,
              bitsPerComponent: 8,
              bytesPerRow: 0,
              space: sRGB,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

/// iOS uygulama ikonları alfa kanalı içeremez; bu bağlam opak üretir.
func makeOpaqueContext(_ width: Int, _ height: Int) -> CGContext {
    CGContext(data: nil,
              width: width,
              height: height,
              bitsPerComponent: 8,
              bytesPerRow: 0,
              space: sRGB,
              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
}

func writePNG(_ image: CGImage, to url: URL) throws {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "make-icons", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "PNG üretilemedi"])
    }
    try data.write(to: url)
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect,
           cornerWidth: radius,
           cornerHeight: radius,
           transform: nil)
}

// MARK: - Ortak arka plan

func drawBackground(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat) {
    let base = CGGradient(colorsSpace: sRGB,
                          colors: [color(0x3E0734), color(0x5B0C46), color(0x1A0216)] as CFArray,
                          locations: [0.0, 0.45, 1.0])!
    ctx.drawLinearGradient(base,
                           start: CGPoint(x: 0, y: h),
                           end: CGPoint(x: w, y: 0),
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

    // Sol üstte sıcak magenta parıltı.
    let magenta = CGGradient(colorsSpace: sRGB,
                             colors: [color(0xB02B82, 0.55), color(0xB02B82, 0.0)] as CFArray,
                             locations: [0.0, 1.0])!
    ctx.drawRadialGradient(magenta,
                           startCenter: CGPoint(x: 0.32 * w, y: 0.68 * h), startRadius: 0,
                           endCenter: CGPoint(x: 0.32 * w, y: 0.68 * h), endRadius: 0.66 * w,
                           options: [])

    // Köşelerde koyu vinyet.
    let vignette = CGGradient(colorsSpace: sRGB,
                              colors: [color(0x0C010A, 0.0), color(0x0C010A, 0.8)] as CFArray,
                              locations: [0.0, 1.0])!
    ctx.drawRadialGradient(vignette,
                           startCenter: CGPoint(x: 0.52 * w, y: 0.54 * h), startRadius: 0.30 * w,
                           endCenter: CGPoint(x: 0.52 * w, y: 0.54 * h), endRadius: 0.86 * w,
                           options: [])
}

// MARK: - Gönderici (imeds) — uçan kağıt uçak

func drawSenderMiddle(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat) {
    let s = w / 1280.0

    // Mavi ışık, gönderim simgesinin arkasında toplanır.
    let blue = CGGradient(colorsSpace: sRGB,
                          colors: [color(0x5286F5, 0.42), color(0x5286F5, 0.0)] as CFArray,
                          locations: [0.0, 1.0])!
    ctx.drawRadialGradient(blue,
                           startCenter: CGPoint(x: 0.56 * w, y: 0.52 * h), startRadius: 0,
                           endCenter: CGPoint(x: 0.56 * w, y: 0.52 * h), endRadius: 0.46 * w,
                           options: [])

    // Gönderim yolu: noktalı bir yay.
    ctx.saveGState()
    ctx.setStrokeColor(color(0xCBE5FF, 0.32))
    ctx.setLineWidth(9 * s)
    ctx.setLineCap(.round)
    ctx.setLineDash(phase: 0, lengths: [3 * s, 28 * s])
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 0.14 * w, y: 0.20 * h))
    path.addCurve(to: CGPoint(x: 0.42 * w, y: 0.44 * h),
                  control1: CGPoint(x: 0.24 * w, y: 0.20 * h),
                  control2: CGPoint(x: 0.33 * w, y: 0.32 * h))
    ctx.addPath(path)
    ctx.strokePath()
    ctx.restoreGState()
}

func makePlaneLayer(_ w: CGFloat, _ h: CGFloat) -> CGImage {
    let ctx = makeContext(Int(w), Int(h))
    let s = w / 1280.0

    let planeWidth = 0.44 * w
    let planeHeight = planeWidth * 0.86
    let center = CGPoint(x: 0.545 * w, y: 0.545 * h)

    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y)
    ctx.rotate(by: -9.0 * .pi / 180.0)
    ctx.scaleBy(x: planeWidth, y: planeHeight)
    ctx.translateBy(x: -0.5, y: -0.43)

    let leftTip  = CGPoint(x: 0.00, y: 0.50)
    let nose     = CGPoint(x: 1.00, y: 0.86)
    let crease   = CGPoint(x: 0.46, y: 0.44)
    let tail     = CGPoint(x: 0.58, y: 0.00)

    // Üst kanat (ışığı alan yüzey).
    let upper = CGMutablePath()
    upper.move(to: leftTip)
    upper.addLine(to: nose)
    upper.addLine(to: crease)
    upper.closeSubpath()

    // Alt kanat (gölgede kalan yüzey).
    let lower = CGMutablePath()
    lower.move(to: crease)
    lower.addLine(to: nose)
    lower.addLine(to: tail)
    lower.closeSubpath()

    ctx.setLineJoin(.round)
    ctx.setLineWidth(0.012)

    ctx.setFillColor(color(0xF3FAFF))
    ctx.setStrokeColor(color(0xF3FAFF))
    ctx.addPath(upper)
    ctx.drawPath(using: .fillStroke)

    ctx.setFillColor(color(0x9EC6F2))
    ctx.setStrokeColor(color(0x9EC6F2))
    ctx.addPath(lower)
    ctx.drawPath(using: .fillStroke)

    // Katlama çizgisi.
    ctx.setStrokeColor(color(0xD9EEFF, 0.95))
    ctx.setLineWidth(0.009)
    ctx.setLineCap(.round)
    ctx.move(to: crease)
    ctx.addLine(to: nose)
    ctx.strokePath()

    ctx.restoreGState()

    // Yol üzerindeki küçük izler.
    let dots: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (0.360, 0.400, 9.5, 0.85),
        (0.300, 0.330, 7.0, 0.62),
        (0.250, 0.270, 5.0, 0.42)
    ]
    for (x, y, r, a) in dots {
        ctx.setFillColor(color(0xD6EBFF, a))
        ctx.fillEllipse(in: CGRect(x: x * w - r * s, y: y * h - r * s,
                                   width: r * 2 * s, height: r * 2 * s))
    }

    return ctx.makeImage()!
}

func drawSenderForeground(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat) {
    let s = w / 1280.0
    let plane = makePlaneLayer(w, h)

    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 55 * s, color: color(0x7FB4FF, 0.85))
    ctx.draw(plane, in: CGRect(x: 0, y: 0, width: w, height: h))
    ctx.restoreGState()
}

// MARK: - Alıcı (imedtv) — sabit TV + gelen medya

func drawReceiverMiddle(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat) {
    // Sabit TV'nin arkasında toplanan mavi ışık.
    let blue = CGGradient(colorsSpace: sRGB,
                          colors: [color(0x5286F5, 0.40), color(0x5286F5, 0.0)] as CFArray,
                          locations: [0.0, 1.0])!
    ctx.drawRadialGradient(blue,
                           startCenter: CGPoint(x: 0.50 * w, y: 0.52 * h), startRadius: 0,
                           endCenter: CGPoint(x: 0.50 * w, y: 0.52 * h), endRadius: 0.46 * w,
                           options: [])
}

func drawReceiverForeground(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat) {
    let s = w / 1280.0
    let cx = 0.50 * w

    // --- TV gövdesi ---
    let bodyW = 0.46 * w
    let bodyH = bodyW * 0.60
    let bodyRect = CGRect(x: cx - bodyW / 2,
                          y: 0.50 * h - bodyH / 2 + 0.01 * h,
                          width: bodyW,
                          height: bodyH)
    let bodyCorner = 0.028 * w

    // --- Ayak ---
    let neckW = 0.055 * w
    let neckH = 0.040 * h
    let baseW = 0.20 * w
    let baseH = 0.032 * h
    let neckRect = CGRect(x: cx - neckW / 2,
                          y: bodyRect.minY - neckH + 3 * s,
                          width: neckW,
                          height: neckH)
    let baseRect = CGRect(x: cx - baseW / 2,
                          y: neckRect.minY - baseH + 3 * s,
                          width: baseW,
                          height: baseH)

    let standGradient = CGGradient(colorsSpace: sRGB,
                                   colors: [color(0xEAF4FF), color(0xB9D4F2)] as CFArray,
                                   locations: [0.0, 1.0])!

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6 * s),
                  blur: 26 * s,
                  color: color(0x5B8FD8, 0.55))
    ctx.setFillColor(color(0xD6E8FC))
    ctx.addPath(roundedRect(baseRect, radius: baseH / 2))
    ctx.fillPath()
    ctx.addPath(roundedRect(neckRect, radius: 6 * s))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(roundedRect(baseRect, radius: baseH / 2))
    ctx.addPath(roundedRect(neckRect, radius: 6 * s))
    ctx.clip()
    ctx.drawLinearGradient(standGradient,
                           start: CGPoint(x: baseRect.minX, y: baseRect.maxY),
                           end: CGPoint(x: baseRect.maxX, y: baseRect.minY),
                           options: [])
    ctx.restoreGState()

    // --- Gövde ---
    let bodyGradient = CGGradient(colorsSpace: sRGB,
                                  colors: [color(0xFAFDFF), color(0xBFD9F5)] as CFArray,
                                  locations: [0.0, 1.0])!

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * s),
                  blur: 46 * s,
                  color: color(0x6FA8F0, 0.65))
    ctx.setFillColor(color(0xEAF4FF))
    ctx.addPath(roundedRect(bodyRect, radius: bodyCorner))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(roundedRect(bodyRect, radius: bodyCorner))
    ctx.clip()
    ctx.drawLinearGradient(bodyGradient,
                           start: CGPoint(x: bodyRect.minX, y: bodyRect.maxY),
                           end: CGPoint(x: bodyRect.maxX, y: bodyRect.minY),
                           options: [])
    ctx.restoreGState()

    // --- Ekran ---
    let insetX = 0.030 * w
    let insetY = 0.034 * h
    let screenRect = bodyRect.insetBy(dx: insetX, dy: insetY)
    let screenCorner = 0.020 * w

    let screenGradient = CGGradient(colorsSpace: sRGB,
                                    colors: [color(0x2D1C52), color(0x120A26)] as CFArray,
                                    locations: [0.0, 1.0])!

    ctx.saveGState()
    ctx.addPath(roundedRect(screenRect, radius: screenCorner))
    ctx.clip()
    ctx.drawLinearGradient(screenGradient,
                           start: CGPoint(x: screenRect.midX, y: screenRect.maxY),
                           end: CGPoint(x: screenRect.midX, y: screenRect.minY),
                           options: [])

    // Ekranın üst solunda hafif cam yansıması.
    let reflection = CGGradient(colorsSpace: sRGB,
                                colors: [color(0xFFFFFF, 0.10), color(0xFFFFFF, 0.0)] as CFArray,
                                locations: [0.0, 1.0])!
    ctx.drawRadialGradient(reflection,
                           startCenter: CGPoint(x: screenRect.minX + 0.30 * screenRect.width,
                                                y: screenRect.maxY - 0.18 * screenRect.height),
                           startRadius: 0,
                           endCenter: CGPoint(x: screenRect.minX + 0.30 * screenRect.width,
                                              y: screenRect.maxY - 0.18 * screenRect.height),
                           endRadius: 0.55 * screenRect.width,
                           options: [])
    ctx.restoreGState()

    // --- Ekran içeriği: medya klasörü ---
    let sw = screenRect.width
    let sh = screenRect.height

    let folderW = 0.56 * sw
    let folderH = 0.42 * sh
    let folderRect = CGRect(x: screenRect.minX + (sw - folderW) / 2,
                            y: screenRect.minY + 0.16 * sh,
                            width: folderW,
                            height: folderH)
    let folderCorner = 0.020 * sw
    let tabW = 0.52 * folderW
    let tabH = 0.22 * folderH
    let tabRect = CGRect(x: folderRect.minX,
                         y: folderRect.maxY - 4 * s,
                         width: tabW,
                         height: tabH)
    let tabCorner = 0.012 * sw

    // Klasör gölgesi.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -5 * s),
                  blur: 16 * s,
                  color: color(0x05010A, 0.55))
    ctx.setFillColor(color(0x8FB8EE))
    ctx.addPath(roundedRect(tabRect, radius: tabCorner))
    ctx.fillPath()
    ctx.addPath(roundedRect(folderRect, radius: folderCorner))
    ctx.fillPath()
    ctx.restoreGState()

    // Klasör dolgusu.
    let folderGradient = CGGradient(colorsSpace: sRGB,
                                    colors: [color(0xAFD2F8), color(0x6C9BE0)] as CFArray,
                                    locations: [0.0, 1.0])!
    ctx.saveGState()
    ctx.addPath(roundedRect(tabRect, radius: tabCorner))
    ctx.addPath(roundedRect(folderRect, radius: folderCorner))
    ctx.clip()
    ctx.drawLinearGradient(folderGradient,
                           start: CGPoint(x: folderRect.minX, y: folderRect.maxY),
                           end: CGPoint(x: folderRect.minX, y: folderRect.minY),
                           options: [])
    ctx.restoreGState()

    // Klasör üst kenarında ince ışık.
    ctx.saveGState()
    ctx.setStrokeColor(color(0xE4F2FF, 0.65))
    ctx.setLineWidth(3 * s)
    ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: folderRect.minX + 18 * s, y: folderRect.maxY - 14 * s))
    ctx.addLine(to: CGPoint(x: folderRect.maxX - 18 * s, y: folderRect.maxY - 14 * s))
    ctx.strokePath()
    ctx.restoreGState()

    // --- Medya (oynat) üçgeni ---
    let playCenter = CGPoint(x: folderRect.midX + 2 * s,
                             y: folderRect.minY + 0.42 * folderRect.height)
    let playH = 0.36 * folderH
    let playW = playH * 0.78

    let play = CGMutablePath()
    play.move(to: CGPoint(x: playCenter.x - playW / 2, y: playCenter.y + playH / 2))
    play.addLine(to: CGPoint(x: playCenter.x - playW / 2, y: playCenter.y - playH / 2))
    play.addLine(to: CGPoint(x: playCenter.x + playW / 2, y: playCenter.y))
    play.closeSubpath()

    ctx.saveGState()
    ctx.setFillColor(color(0xF7FCFF))
    ctx.addPath(play)
    ctx.fillPath()
    ctx.restoreGState()

    // --- Gelen medya oku ---
    let stemW = 0.050 * sw
    let stemTop = screenRect.minY + 0.95 * sh
    let stemBottom = screenRect.minY + 0.72 * sh
    let headHalf = 0.095 * sw
    let apexY = screenRect.minY + 0.58 * sh

    let arrow = CGMutablePath()
    arrow.move(to: CGPoint(x: cx - stemW / 2, y: stemTop))
    arrow.addLine(to: CGPoint(x: cx + stemW / 2, y: stemTop))
    arrow.addLine(to: CGPoint(x: cx + stemW / 2, y: stemBottom))
    arrow.addLine(to: CGPoint(x: cx + headHalf, y: stemBottom))
    arrow.addLine(to: CGPoint(x: cx, y: apexY))
    arrow.addLine(to: CGPoint(x: cx - headHalf, y: stemBottom))
    arrow.addLine(to: CGPoint(x: cx - stemW / 2, y: stemBottom))
    arrow.closeSubpath()

    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 24 * s, color: color(0x9CC8FF, 0.9))
    ctx.setFillColor(color(0xF3FAFF))
    ctx.addPath(arrow)
    ctx.fillPath()
    ctx.restoreGState()

    // Okun iki yanında ince hareket çizgileri.
    ctx.saveGState()
    ctx.setStrokeColor(color(0xCBE5FF, 0.45))
    ctx.setLineWidth(0.012 * sw)
    ctx.setLineCap(.round)
    for offset in [-0.17 * sw, 0.17 * sw] {
        ctx.move(to: CGPoint(x: cx + offset, y: stemTop - 4 * s))
        ctx.addLine(to: CGPoint(x: cx + offset, y: stemTop - 0.14 * sh))
        ctx.strokePath()
    }
    ctx.restoreGState()
}

// MARK: - Üretim

let arguments = CommandLine.arguments
guard arguments.count > 1 else {
    print("Kullanım: swift Tools/make-icons.swift <Assets.xcassets yolu>")
    exit(64)
}

let catalog = URL(fileURLWithPath: arguments[1])
let brandName = "tvOS App Icon & Top Shelf Image.brandassets"
let brand = catalog.appendingPathComponent(brandName, isDirectory: true)

// Eski düz (flat) brandassets kalıntılarını temizle.
try? FileManager.default.removeItem(at: brand)
try? FileManager.default.createDirectory(at: brand, withIntermediateDirectories: true)

struct Layer {
    let name: String
    let fileName: String
    let draw: (CGContext, CGFloat, CGFloat) -> Void
}

/// tvOS katmanları: ön = sabit TV, orta = mavi ışık, arka = magenta zemin.
let layers: [Layer] = [
    Layer(name: "Front", fileName: "front", draw: drawReceiverForeground),
    Layer(name: "Middle", fileName: "middle", draw: drawReceiverMiddle),
    Layer(name: "Back", fileName: "back", draw: drawBackground)
]

/// Bir görsel katmanını `.imagestacklayer/Content.imageset` yapısında yazar.
func writeLayer(_ layer: Layer,
                to stack: URL,
                images: [(scale: String, width: Int, height: Int)]) throws {
    let layerDir = stack.appendingPathComponent("\(layer.name).imagestacklayer",
                                                isDirectory: true)
    let imageset = layerDir.appendingPathComponent("Content.imageset", isDirectory: true)
    try FileManager.default.createDirectory(at: imageset, withIntermediateDirectories: true)

    var imageEntries: [String] = []

    for image in images {
        let width = image.width
        let height = image.height
        let ctx = makeContext(width, height)
        layer.draw(ctx, CGFloat(width), CGFloat(height))

        let fileName = "\(layer.fileName)_\(width)x\(height).png"
        try writePNG(ctx.makeImage()!, to: imageset.appendingPathComponent(fileName))

        imageEntries.append("""
            {
              "filename" : "\(fileName)",
              "idiom" : "tv",
              "scale" : "\(image.scale)"
            }
        """)
    }

    let imagesetContents = """
    {
      "images" : [
    \(imageEntries.joined(separator: ",\n"))
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    try imagesetContents.write(to: imageset.appendingPathComponent("Contents.json"),
                               atomically: true, encoding: .utf8)

    let layerContents = """
    {
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    try layerContents.write(to: layerDir.appendingPathComponent("Contents.json"),
                            atomically: true, encoding: .utf8)
}

func writeStack(_ stack: URL, images: [(scale: String, width: Int, height: Int)]) throws {
    try FileManager.default.createDirectory(at: stack, withIntermediateDirectories: true)

    for layer in layers {
        try writeLayer(layer, to: stack, images: images)
    }

    let contents = """
    {
      "layers" : [
        { "filename" : "Front.imagestacklayer" },
        { "filename" : "Middle.imagestacklayer" },
        { "filename" : "Back.imagestacklayer" }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    try contents.write(to: stack.appendingPathComponent("Contents.json"),
                       atomically: true, encoding: .utf8)
}

// App Store vitrini: 1280x768 (1x).
try writeStack(brand.appendingPathComponent("App Icon - App Store.imagestack", isDirectory: true),
               images: [("1x", 1280, 768)])

// Apple TV ana ekranı: 400x240 (1x) ve 800x480 (2x).
try writeStack(brand.appendingPathComponent("App Icon.imagestack", isDirectory: true),
               images: [("1x", 400, 240), ("2x", 800, 480)])

let brandContents = """
{
  "assets" : [
    {
      "filename" : "App Icon - App Store.imagestack",
      "idiom" : "tv",
      "role" : "primary-app-icon",
      "size" : "1280x768"
    },
    {
      "filename" : "App Icon.imagestack",
      "idiom" : "tv",
      "role" : "primary-app-icon",
      "size" : "400x240"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
try brandContents.write(to: brand.appendingPathComponent("Contents.json"),
                        atomically: true, encoding: .utf8)

// MARK: - iOS simgesi (imeds, gönderici)

let appIconDir = catalog.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
try? FileManager.default.createDirectory(at: appIconDir, withIntermediateDirectories: true)

let iOSSide = 1024
let iosCtx = makeOpaqueContext(iOSSide, iOSSide)
drawBackground(iosCtx, CGFloat(iOSSide), CGFloat(iOSSide))
drawSenderMiddle(iosCtx, CGFloat(iOSSide), CGFloat(iOSSide))
drawSenderForeground(iosCtx, CGFloat(iOSSide), CGFloat(iOSSide))
try writePNG(iosCtx.makeImage()!, to: appIconDir.appendingPathComponent("AppIcon-1024.png"))

// MARK: - Önizlemeler

let projectRoot = catalog.deletingLastPathComponent().deletingLastPathComponent()
let tools = projectRoot.appendingPathComponent("Tools", isDirectory: true)
try? FileManager.default.createDirectory(at: tools, withIntermediateDirectories: true)

// Gönderici önizlemesi (kare).
let senderPreview = tools.appendingPathComponent("imeds-icon-preview.png")
let senderCtx = makeOpaqueContext(iOSSide, iOSSide)
drawBackground(senderCtx, CGFloat(iOSSide), CGFloat(iOSSide))
drawSenderMiddle(senderCtx, CGFloat(iOSSide), CGFloat(iOSSide))
drawSenderForeground(senderCtx, CGFloat(iOSSide), CGFloat(iOSSide))
try writePNG(senderCtx.makeImage()!, to: senderPreview)

// Alıcı önizlemesi (16:9).
let receiverPreview = tools.appendingPathComponent("imedtv-icon-preview.png")
let receiverCtx = makeContext(1280, 768)
drawBackground(receiverCtx, 1280, 768)
drawReceiverMiddle(receiverCtx, 1280, 768)
drawReceiverForeground(receiverCtx, 1280, 768)
try writePNG(receiverCtx.makeImage()!, to: receiverPreview)

print("iOS ikonu yazıldı: \(appIconDir.appendingPathComponent("AppIcon-1024.png").path)")
print("tvOS ikon seti üretildi: \(brandName)")
print("önizlemeler:")
print("  \(senderPreview.path)")
print("  \(receiverPreview.path)")
