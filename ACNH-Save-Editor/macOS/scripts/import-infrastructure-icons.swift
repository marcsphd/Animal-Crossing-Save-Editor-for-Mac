import AppKit
import ImageIO
import UniformTypeIdentifiers

// Deterministically slice the approved sheets, excluding review captions. Retain the
// original generated artwork; discard tiny disconnected alpha specks at export.
// Run from the repository root: swift <this script> <bridge sheet> <incline sheet>
guard CommandLine.arguments.count == 3 else { fatalError("Supply the approved bridge and incline PNG sheets.") }
let destination = URL(fileURLWithPath: "ACNH-Save-Editor/macOS/Sources/ACNHMac/Resources")
let bridgeNames = ["log", "suspension", "stone", "wooden", "brick", "iron", "red-zen", "zen"]
let inclineNames = ["natural", "blue-plank", "white-plank", "log", "stone", "brick", "blue-steel", "red-steel"]
for (sheet, family, names) in [(CommandLine.arguments[1], "bridge", bridgeNames), (CommandLine.arguments[2], "incline", inclineNames)] {
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: sheet) as CFURL, nil)!
    let original = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    precondition(original.width == (family == "bridge" ? 1448 : 1774))
    precondition(original.height == (family == "bridge" ? 1086 : 887))
    let columns = family == "bridge" ? [(60,325), (410,675), (765,1035), (1115,1410)] : [(210,450), (580,820), (950,1190), (1320,1565)]
    let rows = family == "bridge" ? [(12,446), (533,984)] : [(8,438), (450,884)]
    for (index, name) in names.enumerated() {
        let (left, right) = columns[index % 4], (top, bottom) = rows[index / 4]
        let crop = original.cropping(to: CGRect(x: left, y: top, width: right - left, height: bottom - top))!
        let w = crop.width, h = crop.height
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let flags = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        pixels.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                    bytesPerRow: w * 4, space: colorSpace, bitmapInfo: flags)!
            context.draw(crop, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        var visited = [Bool](repeating: false, count: w * h)
        var keep = visited
        for p in 0..<(w * h) where !visited[p] && pixels[p * 4 + 3] >= 96 {
            var queue = [p], cursor = 0
            visited[p] = true
            while cursor < queue.count {
                let q = queue[cursor]; cursor += 1
                let x = q % w, y = q / w
                for n in [x > 0 ? q - 1 : -1, x + 1 < w ? q + 1 : -1, y > 0 ? q - w : -1, y + 1 < h ? q + w : -1]
                    where n >= 0 && !visited[n] && pixels[n * 4 + 3] >= 96 {
                    visited[n] = true; queue.append(n)
                }
            }
            if queue.count >= 512 { for q in queue { keep[q] = true } }
        }
        var minX = w, minY = h, maxX = 0, maxY = 0
        for p in 0..<(w * h) {
            if keep[p] {
                minX = min(minX, p % w); maxX = max(maxX, p % w)
                minY = min(minY, p / w); maxY = max(maxY, p / w)
            } else { for channel in 0..<4 { pixels[p * 4 + channel] = 0 } }
        }
        precondition(minX < maxX && minY < maxY)
        let image = pixels.withUnsafeMutableBytes { bytes -> CGImage in
            CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8,
                      bytesPerRow: w * 4, space: colorSpace, bitmapInfo: flags)!.makeImage()!
        }.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))!
        let scale = 504.0 / Double(max(image.width, image.height))
        let outputW = Int((Double(image.width) * scale).rounded()) + 8
        let outputH = Int((Double(image.height) * scale).rounded()) + 8
        let output = CGContext(data: nil, width: outputW, height: outputH, bitsPerComponent: 8,
                               bytesPerRow: outputW * 4, space: colorSpace, bitmapInfo: flags)!
        output.interpolationQuality = .high
        output.draw(image, in: CGRect(x: 4, y: 4, width: outputW - 8, height: outputH - 8))
        let url = destination.appendingPathComponent("building-icon-\(family)-\(name).png")
        let writer = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(writer, output.makeImage()!, nil)
        precondition(CGImageDestinationFinalize(writer))
        print("\(url.lastPathComponent): \(outputW)×\(outputH)")
    }
}
