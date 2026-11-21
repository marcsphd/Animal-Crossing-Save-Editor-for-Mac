import Foundation

/// Display-only metadata for NHSE field IDs, independent of placeable pocket items.
/// Generated from the revision in REFERENCE-REVISION.txt; see THIRD-PARTY-NOTICES.md.
struct FieldObjectDefinition: Decodable {
    let name: String
    let model: String
    let kind: String
    let icon: String
    let heldItemID: UInt16?
}

struct FieldObjectCatalog {
    static let shared = FieldObjectCatalog()
    let byID: [UInt16: FieldObjectDefinition]

    init() {
        let decoded = Bundle.module.url(forResource: "field-objects", withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode([String: FieldObjectDefinition].self, from: $0) } ?? [:]
        byID = Dictionary(uniqueKeysWithValues: decoded.compactMap { key, value in
            UInt16(key).map { ($0, value) }
        })
    }
}
