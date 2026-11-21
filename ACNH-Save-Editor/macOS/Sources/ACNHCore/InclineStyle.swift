// Adapted from NHSE.Core SlopeType, GPL-3.0.
// See THIRD-PARTY-NOTICES.md and REFERENCE-REVISION.txt for upstream provenance.
import Foundation

public enum InclineStyle: UInt16, CaseIterable, Identifiable {
    case stoneStaircase = 0x00, redSteelStaircase = 0x01, whitePlankRamp = 0x02
    case logStaircase = 0x03, brickStaircase = 0x04, reserved = 0x05
    case naturalRamp = 0x1D, bluePlankRamp = 0x1E, blueSteelStaircase = 0x1F

    public var id: UInt16 { rawValue }
    public var name: String {
        switch self {
        case .stoneStaircase: return "Stone staircase"
        case .redSteelStaircase: return "Red steel staircase"
        case .whitePlankRamp: return "White-plank ramp"
        case .logStaircase: return "Log staircase"
        case .brickStaircase: return "Brick staircase"
        case .reserved: return "Reserved (NHSE)"
        case .naturalRamp: return "Natural ramp"
        case .bluePlankRamp: return "Blue-plank ramp"
        case .blueSteelStaircase: return "Blue steel staircase"
        }
    }
}
