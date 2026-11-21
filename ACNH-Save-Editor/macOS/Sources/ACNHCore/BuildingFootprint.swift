import Foundation

/// Converts the saved infrastructure angle to our north-up, vertical-base artwork.
/// Angle 0 has an east-west span; angle 1 has a north-south span.
/// Only presentation changes: the stored angle is never normalized or rewritten.
public enum InfrastructureOrientation {
    public static func spriteQuarterTurns(for angle: UInt8) -> Int { (Int(angle) + 1) % 4 }

    public static func rotationDegrees(for building: MapBuilding) -> Double {
        let diagonal = building.kind == 26 && BridgeType(building.subtype)?.isDiagonal == true
        return Double(spriteQuarterTurns(for: building.position.angle)) * 90 + (diagonal ? 45 : 0)
    }
}

/// Placement-plot dimensions in full terrain tiles, not model collision bounds.
/// Sources and outstanding alignment checks: Design/Map/Building-Artwork-and-Spacing.md.
public struct BuildingFootprint: Equatable {
    public let width: Double
    public let depth: Double
    public let note: String

    public static func forBuilding(_ building: MapBuilding) -> BuildingFootprint? {
        let size: (Double, Double)
        switch building.kind {
        case 1...8: size = (5, 4)
        case 9...18, 25: size = (4, 4)
        case 19, 21: size = (7, 4)
        case 20: size = (6, 4)
        case 24: size = (5, 4)
        case 27:
            guard building.position.angle < 4 else { return nil }
            size = InfrastructureOrientation.spriteQuarterTurns(for: building.position.angle) % 2 == 0 ? (2, 4) : (4, 2)
        case 26:
            guard building.position.angle < 4, let span = bridgeSpan(building.subtype) else { return nil }
            // Straight bridges include one bank tile at each end.
            size = InfrastructureOrientation.spriteQuarterTurns(for: building.position.angle) % 2 == 0 ? (4, span + 2) : (span + 2, 4)
        default: return nil
        }
        return BuildingFootprint(width: size.0, depth: size.1,
            note: "Placement plot guide; alignment to the saved marker needs in-game verification.")
    }

    /// Water span from NHSE BridgeType's 03/04/05 model suffixes.
    /// Diagonal and unrecognized subtypes deliberately have no rectangular plot guide.
    public static func bridgeSpan(_ subtype: UInt16) -> Double? {
        guard let type = BridgeType(subtype), !type.isDiagonal else { return nil }
        return type.span
    }

    public static func isDiagonalBridge(_ building: MapBuilding) -> Bool {
        building.kind == 26 && BridgeType(building.subtype)?.isDiagonal == true
    }
}
