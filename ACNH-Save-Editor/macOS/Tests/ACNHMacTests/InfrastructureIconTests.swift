import AppKit
import XCTest
import ACNHCore
@testable import ACNHMac

final class InfrastructureIconTests: XCTestCase {
    func testEveryStandardStyleLoadsItsOwnTransparentOverheadSprite() async throws {
        try await MainActor.run {
            let bridges: [(BridgeStyle, String)] = [(.log,"log"),(.suspension,"suspension"),(.stone,"stone"),(.wooden,"wooden"),(.brick,"brick"),(.iron,"iron"),(.redZen,"red-zen"),(.zen,"zen")]
            let inclines: [(InclineStyle, String)] = [(.naturalRamp,"natural"),(.bluePlankRamp,"blue-plank"),(.whitePlankRamp,"white-plank"),(.logStaircase,"log"),(.stoneStaircase,"stone"),(.brickStaircase,"brick"),(.blueSteelStaircase,"blue-steel"),(.redSteelStaircase,"red-steel")]
            for id: UInt16 in 0...55 {
                guard let type = BridgeType(id), let name = bridges.first(where: { $0.0 == type.style })?.1 else { continue }
                XCTAssertEqual(BuildingIconStore.resource(for: 26, subtype: id), "building-icon-bridge-" + name)
            }
            let cases = bridges.map { (UInt16(26), BridgeType(0)!.replacingStyle(with: $0.0).id, "bridge-" + $0.1) }
                + inclines.map { (UInt16(27), $0.0.rawValue, "incline-" + $0.1) }
            for (kind, subtype, name) in cases {
                XCTAssertEqual(BuildingIconStore.resource(for: kind, subtype: subtype), "building-icon-" + name)
                let image = try XCTUnwrap(BuildingIconStore.shared.image(for: kind, subtype: subtype))
                let bitmap = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation)))
                XCTAssertTrue(bitmap.hasAlpha)
                XCTAssertEqual(bitmap.pixelsHigh, 512)
                XCTAssertLessThan(bitmap.pixelsWide, bitmap.pixelsHigh)
                XCTAssertGreaterThan(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: 256)!.alphaComponent, 0.9)
                for (x,y) in [(0,0),(bitmap.pixelsWide - 1,0),(0,511),(bitmap.pixelsWide - 1,511)] {
                    XCTAssertEqual(bitmap.colorAt(x: x, y: y)!.alphaComponent, 0, accuracy: 0.001)
                }
            }
            for subtype: UInt16 in [26,65535] { XCTAssertEqual(BuildingIconStore.resource(for: 26, subtype: subtype), "building-icon-bridge") }
            for subtype: UInt16 in [5,65535] { XCTAssertEqual(BuildingIconStore.resource(for: 27, subtype: subtype), "building-icon-incline") }
            XCTAssertEqual(BuildingIconStore.resource(for: 19, subtype: 0), "building-icon-nooks-cranny")
        }
    }

    func testRotatedSpritesKeepTheirAspectRatioAndFitSelectionBounds() {
        let imageSize = CGSize(width: 256, height: 512)
        for (kind, subtype): (UInt16, UInt16) in [(26,0),(26,2),(26,3),(26,55),(27,29)] {
            for angle: UInt8 in 0..<4 {
                let building = MapBuilding(id: 0, kind: kind, position: BuildingPosition(x: 100, y: 100, angle: angle), subtype: subtype)
                for zoom in [3.0, 8, 14] {
                    let bounds = MapCoordinates.buildingBounds(building, zoom: zoom)
                    let placement = InfrastructureIconPlacement(building: building, imageSize: imageSize, bounds: bounds.size)
                    XCTAssertEqual(placement.size.width / placement.size.height, 0.5, accuracy: 0.000001)
                    XCTAssertEqual(placement.rotation, [90.0, 180, 270, 0][Int(angle)] + (BuildingFootprint.isDiagonalBridge(building) ? 45 : 0))
                    let r = placement.rotation * .pi / 180
                    let width = placement.size.width * abs(cos(r)) + placement.size.height * abs(sin(r))
                    let height = placement.size.width * abs(sin(r)) + placement.size.height * abs(cos(r))
                    XCTAssertLessThanOrEqual(width, bounds.width + 0.000001)
                    XCTAssertLessThanOrEqual(height, bounds.height + 0.000001)
                    XCTAssertTrue(abs(width - bounds.width) < 0.000001 || abs(height - bounds.height) < 0.000001)
                }
            }
        }
    }
}
