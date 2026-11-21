import AppKit
import SwiftUI
import ACNHCore

/// Original generated fan artwork, separate from NHSE/Nintendo inventory assets.
@MainActor final class BuildingIconStore {
    static let shared = BuildingIconStore()
    private var images: [String: NSImage] = [:]
    static func resource(for kind: UInt16, subtype: UInt16? = nil) -> String? {
        if let subtype {
            if kind == 26, let style = BridgeType(subtype)?.style {
                let names: [BridgeStyle: String] = [.log: "log", .suspension: "suspension", .stone: "stone", .wooden: "wooden", .brick: "brick", .iron: "iron", .redZen: "red-zen", .zen: "zen"]
                if let name = names[style] { return "building-icon-bridge-" + name }
            }
            if kind == 27, let style = InclineStyle(rawValue: subtype) {
                let names: [InclineStyle: String] = [.naturalRamp: "natural", .bluePlankRamp: "blue-plank", .whitePlankRamp: "white-plank", .logStaircase: "log", .stoneStaircase: "stone", .brickStaircase: "brick", .blueSteelStaircase: "blue-steel", .redSteelStaircase: "red-steel"]
                if let name = names[style] { return "building-icon-incline-" + name }
            }
        }
        let name: String
        switch kind {
        case 1...8: name = "player-house"
        case 9...18: name = "villager-house"
        case 19: name = "nooks-cranny"
        case 20: name = "resident-services"
        case 21: name = "museum"
        case 22: name = "airport"
        case 23: name = "resident-tent"
        case 24: name = "able-sisters"
        case 25: name = "campsite"
        case 26: name = "bridge"
        case 27: name = "incline"
        case 28: name = "redd-trawler"
        case 29: name = "studio"
        case 42: name = "hotel"
        default: return nil
        }
        return "building-icon-" + name
    }
    func image(for kind: UInt16, subtype: UInt16? = nil) -> NSImage? {
        guard let name = Self.resource(for: kind, subtype: subtype) else { return nil }
        if let cached = images[name] { return cached }
        guard let url = Bundle.module.url(forResource: name, withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        images[name] = image
        return image
    }
}

/// Fits the overhead sprite inside its existing map selection bounds after rotation.
/// This is display geometry, independent of the saved marker and placement guide.
struct InfrastructureIconPlacement {
    let rotation: Double
    let size: CGSize
    init(building: MapBuilding, imageSize: CGSize, bounds: CGSize) {
        rotation = InfrastructureOrientation.rotationDegrees(for: building)
        let radians = rotation * .pi / 180
        let c = abs(cos(radians)), s = abs(sin(radians))
        let width = max(1, imageSize.width), height = max(1, imageSize.height)
        let scale = min(bounds.width / (width * c + height * s), bounds.height / (width * s + height * c))
        size = CGSize(width: width * scale, height: height * scale)
    }
}

struct BuildingIcon: View {
    let kind: UInt16
    var subtype: UInt16? = nil
    var size: CGFloat = 64
    var body: some View {
        Group {
            if let image = BuildingIconStore.shared.image(for: kind, subtype: subtype) {
                Image(nsImage: image).resizable().scaledToFit()
            } else {
                Image(systemName: "building.2.fill").resizable().scaledToFit().foregroundStyle(Color.island)
            }
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}
