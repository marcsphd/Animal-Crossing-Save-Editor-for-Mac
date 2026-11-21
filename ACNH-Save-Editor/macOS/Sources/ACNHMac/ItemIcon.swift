import AppKit
import SwiftUI

/// NHSE's bundled inventory icons, resolved by item ID rather than display name.
@MainActor final class ItemIconStore {
    static let shared = ItemIconStore()
    private let names: [String: String]
    private let images = NSCache<NSString, NSImage>()

    private init() {
        let data = Bundle.module.url(forResource: "item-icons", withExtension: "json").flatMap { try? Data(contentsOf: $0) }
        names = data.flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
        images.countLimit = 192
        images.totalCostLimit = 8 * 1024 * 1024
    }

    func resourceName(for id: UInt16) -> String {
        FieldObjectCatalog.shared.byID[id]?.icon ?? names[String(id)] ?? "item-icon-leaf"
    }

    func image(for id: UInt16) -> NSImage? {
        let name = resourceName(for: id)
        if let cached = images.object(forKey: name as NSString) { return cached }
        if name == "field-icon-hole" || name == "field-icon-stump" {
            let image = Self.fieldSymbol(stump: name == "field-icon-stump")
            images.setObject(image, forKey: name as NSString, cost: 64 * 64 * 4)
            return image
        }
        guard let url = Bundle.module.url(forResource: name, withExtension: "png"), let image = NSImage(contentsOf: url) else { return nil }
        images.setObject(image, forKey: name as NSString, cost: Int(image.size.width * image.size.height * 4))
        return image
    }

    /// Simple overhead category symbols for field objects with no menu artwork.
    /// They intentionally do not claim to reproduce the game's individual models.
    private static func fieldSymbol(stump: Bool) -> NSImage {
        NSImage(size: NSSize(width: 64, height: 64), flipped: false) { _ in
            let outline = NSBezierPath(ovalIn: CGRect(x: 5, y: 7, width: 54, height: 50))
            NSColor(calibratedRed: 0.33, green: 0.20, blue: 0.10, alpha: 1).setFill()
            outline.fill()
            let center = NSBezierPath(ovalIn: CGRect(x: 10, y: 12, width: 44, height: 40))
            NSColor(calibratedRed: stump ? 0.80 : 0.14, green: stump ? 0.60 : 0.08, blue: stump ? 0.34 : 0.04, alpha: 1).setFill()
            center.fill()
            if stump {
                NSColor(calibratedRed: 0.58, green: 0.37, blue: 0.17, alpha: 1).setStroke()
                for inset in [18, 25] {
                    let ring = NSBezierPath(ovalIn: CGRect(x: inset, y: inset, width: 64 - inset * 2, height: 64 - inset * 2))
                    ring.lineWidth = 1.5; ring.stroke()
                }
            }
            return true
        }
    }
}

struct ItemIcon: View {
    let id: UInt16
    var size: CGFloat = 32

    var body: some View {
        Group {
            if id == 0xFFFE {
                Image(systemName: "plus").font(.system(size: size * 0.55)).foregroundStyle(Color.secondary.opacity(0.35))
            } else if let image = ItemIconStore.shared.image(for: id) {
                Image(nsImage: image).resizable().renderingMode(.original).interpolation(.high).scaledToFit()
            } else {
                Image(systemName: "leaf.fill").resizable().scaledToFit().padding(size * 0.18).foregroundStyle(Color.island)
            }
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}
