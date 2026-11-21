import AppKit
import XCTest
import ACNHCore
@testable import ACNHMac

final class FieldObjectCatalogTests: XCTestCase {
    func testEveryPinnedFieldDefinitionHasANameAndLoadableArtwork() async {
        await MainActor.run {
            let fields = FieldObjectCatalog.shared.byID
            XCTAssertEqual(fields.count, 540)
            XCTAssertEqual(fields.values.filter { $0.heldItemID == nil }.count, 28)
            let catalog = Catalog()
            for (id, definition) in fields {
                XCTAssertGreaterThanOrEqual(id, 60000)
                XCTAssertFalse(definition.name.isEmpty)
                XCTAssertFalse(definition.model.isEmpty)
                XCTAssertFalse(definition.icon.isEmpty)
                XCTAssertEqual(catalog.name(Self.item(id)), definition.name)
                XCTAssertNotNil(ItemIconStore.shared.image(for: id), "Missing artwork for \(id): \(definition.model)")
                XCTAssertNil(catalog.byID[id], "Outdoor-only objects must not become pocket/drop catalog items")
            }
        }
    }

    func testRockVariantsAndObjectsWithoutInventoryEquivalents() async throws {
        await MainActor.run {
            let catalog = Catalog()
            for (id, letter): (UInt16, String) in [(0xEB12,"A"),(0xEB13,"B"),(0xEB14,"E"),(0xEB15,"D"),(0xEB16,"C")] {
                XCTAssertEqual(catalog.name(Self.item(id)), "Rock (\(letter))")
                XCTAssertEqual(FieldObjectCatalog.shared.byID[id]?.model, "Stone" + letter)
                XCTAssertEqual(ItemIconStore.shared.resourceName(for: id), "item-icon-OreStone")
            }
            XCTAssertEqual(catalog.name(Self.item(60025)), "Hole")
            XCTAssertEqual(catalog.name(Self.item(60063)), "Hardwood stump")
            XCTAssertEqual(catalog.name(Self.item(60525)), "Hardwood stump (small young)")
            XCTAssertEqual(ItemIconStore.shared.resourceName(for: 60025), "field-icon-hole")
            XCTAssertEqual(ItemIconStore.shared.resourceName(for: 60063), "field-icon-stump")
            XCTAssertEqual(catalog.name(Self.item(60000)), "hardwood tree")
            XCTAssertEqual(catalog.name(Self.item(60017)), "red cosmos")
            XCTAssertEqual(catalog.name(Self.item(60160)), "brick fence")
            XCTAssertEqual(catalog.name(Self.item(65532)), "Unknown item (FFFC)")
            XCTAssertEqual(ItemIconStore.shared.resourceName(for: 65532), "item-icon-leaf")
            XCTAssertEqual(catalog.name(.empty, emptyLabel: "Empty map cell"), "Empty map cell")
            XCTAssertEqual(catalog.name(Self.item(2213)), catalog.byID[2213]?.name)
        }
    }

    func testNamingAndArtworkResolutionPreserveEveryRecordByte() async throws {
        try await MainActor.run {
            let catalog = Catalog()
            for id: UInt16 in [0xEB12,0xEB14,60063,60025,60000,60017,65532] {
                let before = Data([UInt8(truncatingIfNeeded: id), UInt8(id >> 8), 0xA1,0xB2,0xC3,0xD4,0xE5,0xF6])
                let item = PocketItem(raw: before)
                _ = catalog.name(item)
                _ = ItemIconStore.shared.image(for: item.id)
                XCTAssertEqual(item.raw, before)
            }
            // Open/check/export a fixture with real field objects. Naming is display-only.
            let folder = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
                .deletingLastPathComponent().appendingPathComponent("Sources/ACNHMac/ExampleSave/Save")
            let session = try SaveSession(folder: folder)
            let world = IslandSnapshot(main: session.main)
            for index in 0..<IslandLayout.fieldCount {
                let item = world.fieldItem(index)
                if item.id >= 60000 && !item.isEmpty && item.id != 0xFFFD { _ = catalog.name(item) }
            }
            let encoded = try session.encoded(session.initial)
            for (path, bytes) in encoded { XCTAssertEqual(bytes, session.originals[path], path) }
            try session.ensureUnchanged()
            if let destination = ProcessInfo.processInfo.environment["ACNH_FIELD_VISUAL_FIXTURE"] {
                let rock = (0..<IslandLayout.fieldCount).first { (0xEB12...0xEB16).contains(world.fieldItem($0).id) }
                let index = rock ?? (0..<IslandLayout.fieldCount).first { world.fieldItem($0).isEmpty }!
                var draft = session.initial
                if rock == nil { draft.island.fieldItems[index] = Self.item(0xEB12) }
                try session.export(draft, to: URL(fileURLWithPath: destination))
                let coordinates = ["x": index / IslandLayout.fieldHeight, "y": index % IslandLayout.fieldHeight]
                try JSONSerialization.data(withJSONObject: coordinates).write(to: URL(fileURLWithPath: destination + "-rock.json"))
            }
        }
    }

    private static func item(_ id: UInt16) -> PocketItem {
        var raw = Data(repeating: 0, count: 8)
        raw.put16(id, at: 0)
        return PocketItem(raw: raw)
    }
}
