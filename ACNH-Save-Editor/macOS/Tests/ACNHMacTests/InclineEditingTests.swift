import XCTest
import ACNHCore
@testable import ACNHMac

final class InclineEditingTests: XCTestCase {
    func testStyleSupportsUndoRedoRevertAndOriginalValueNormalization() async throws {
        await MainActor.run {
            let model = EditorModel()
            model.previewWorld = IslandSnapshot.preview()
            model.draft = SaveDraft(economy: [0], pockets: [])
            let position = BuildingPosition(x: 181, y: 151, angle: 2)
            model.change { $0.island.buildings[10] = position }
            model.change { $0.island.inclineTypes[10] = InclineStyle.naturalRamp.rawValue }
            XCTAssertEqual(model.world?.building(10, edits: model.draft!.island).subtype, 0x1D)
            model.undo()
            XCTAssertTrue(model.draft!.island.inclineTypes.isEmpty)
            XCTAssertEqual(model.draft?.island.buildings[10], position)
            model.redo()
            XCTAssertEqual(model.draft?.island.inclineTypes[10], 0x1D)
            model.change { $0.island.inclineTypes.removeValue(forKey: 10) }
            XCTAssertTrue(model.draft!.island.inclineTypes.isEmpty)
            XCTAssertEqual(model.draft?.island.buildings[10], position)
            model.undo()
            model.change { $0.island.inclineTypes[10] = InclineStyle.stoneStaircase.rawValue }
            XCTAssertTrue(model.draft!.island.inclineTypes.isEmpty)
            model.change {
                $0.island.inclineTypes[10] = InclineStyle.bluePlankRamp.rawValue
                $0.island.buildings.removeValue(forKey: 10)
            }
            model.change {
                $0.island.inclineTypes.removeValue(forKey: 10)
                $0.island.buildings.removeValue(forKey: 10)
            }
            XCTAssertTrue(model.draft!.island.isEmpty)
        }
    }

    func testReviewAndExportRoundTrip() async throws {
        try await MainActor.run {
            let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
                .deletingLastPathComponent().appendingPathComponent("Sources/ACNHMac/ExampleSave/Save")
            // The contributed island has no inclines. Add one to a temporary fixture only.
            let fixture = FileManager.default.temporaryDirectory.appendingPathComponent("ACNH-Incline-\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: fixture) }
            let source = fixture.appendingPathComponent("Source")
            try FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: folder, to: source)
            let originalSession = try SaveSession(folder: folder)
            let originalWorld = IslandSnapshot(main: originalSession.main)
            let empty = try XCTUnwrap((0..<IslandLayout.buildingCount).first { originalWorld.building($0).kind == 0 })
            var main = originalSession.main
            let offset = IslandLayout.buildings + empty * IslandLayout.buildingSize
            main.put16(27, at: offset)
            main.put16(InclineStyle.stoneStaircase.rawValue, at: offset + 8)
            SaveLayout.rehash(&main, regions: SaveLayout.mainRegions)
            try SaveCodec.crypt(main, header: originalSession.originals["mainHeader.dat"]!).write(to: source.appendingPathComponent("main.dat"))
            let session = try SaveSession(folder: source)
            let world = IslandSnapshot(main: session.main)
            let index = try XCTUnwrap((0..<IslandLayout.buildingCount).first { world.building($0).kind == 27 })
            let original = try XCTUnwrap(InclineStyle(rawValue: world.building(index).subtype))
            let style: InclineStyle = original == .naturalRamp ? .blueSteelStaircase : .naturalRamp
            let model = EditorModel()
            model.session = session
            model.draft = session.initial
            model.change { $0.island.inclineTypes[index] = style.rawValue }
            XCTAssertEqual(model.changes, ["Incline [\(index + 1)]: \(original.name) → \(style.name)"])
            let destination = fixture.appendingPathComponent("Export")
            try session.export(model.draft!, to: destination)
            let reopened = try SaveSession(folder: destination)
            let building = IslandSnapshot(main: reopened.main).building(index)
            XCTAssertEqual(building.subtype, style.rawValue)
            XCTAssertEqual(building.position, world.building(index).position)
            XCTAssertEqual(reopened.personal, session.personal)
            try session.ensureUnchanged()
        }
    }
}
