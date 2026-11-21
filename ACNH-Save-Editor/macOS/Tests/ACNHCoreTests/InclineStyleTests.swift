import XCTest
@testable import ACNHCore

final class InclineStyleTests: XCTestCase {
    func testEveryStyleWritesOnlyTheInclineModel() throws {
        var before = IslandSnapshot.preview().main
        let index = 10, offset = IslandLayout.buildings + index * IslandLayout.buildingSize
        before.replaceSubrange((offset + 6)..<(offset + 20), with: Data((0xA0...0xAD).map(UInt8.init)))
        before[offset + 6] = 3
        for style in InclineStyle.allCases {
            var main = before, edits = IslandEdits()
            edits.inclineTypes[index] = style.rawValue
            XCTAssertFalse(edits.isEmpty)
            XCTAssertEqual(IslandSnapshot(main: before).building(index, edits: edits).subtype, style.rawValue)
            try edits.applying(to: &main)
            XCTAssertEqual(IslandSnapshot(main: main).building(index).subtype, style.rawValue)
            main.replaceSubrange((offset + 8)..<(offset + 10), with: before[(offset + 8)..<(offset + 10)])
            XCTAssertEqual(main, before, "Style changes must preserve coordinates, angle, flags, TypeArg, and identity")
        }
    }

    func testInvalidModelsAndNonInclineTargetsAreRejected() {
        for (index, id): (Int, UInt16) in [(-1,0),(46,0),(0,0),(9,0),(45,0),(10,6),(10,28),(10,32),(10,65535)] {
            let before = IslandSnapshot.preview().main
            var main = before, edits = IslandEdits()
            edits.inclineTypes[index] = id
            XCTAssertThrowsError(try edits.applying(to: &main))
            XCTAssertEqual(main, before)
        }
    }

    func testMoveAndStyleChangesComposeWithoutChangingTheBridge() throws {
        let world = IslandSnapshot.preview()
        var edits = IslandEdits(), main = world.main
        let moved = BuildingPosition(x: 181, y: 151, angle: 2)
        edits.buildings[10] = moved
        edits.inclineTypes[10] = InclineStyle.blueSteelStaircase.rawValue
        edits.bridgeTypes[9] = BridgeType(0)!.replacingStyle(with: .brick).id
        let preview = world.building(10, edits: edits)
        XCTAssertEqual(preview.position, moved)
        try edits.applying(to: &main)
        let saved = IslandSnapshot(main: main)
        XCTAssertEqual(saved.building(10).position, preview.position)
        XCTAssertEqual(saved.building(10).subtype, preview.subtype)
        XCTAssertEqual(saved.building(9).subtype, edits.bridgeTypes[9])
        edits.inclineTypes.removeAll()
        XCTAssertEqual(world.building(10, edits: edits).subtype, world.building(10).subtype)
        XCTAssertEqual(world.building(10, edits: edits).position, moved)
    }
}
