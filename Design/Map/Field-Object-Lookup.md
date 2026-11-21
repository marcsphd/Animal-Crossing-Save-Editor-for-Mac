# Outdoor-object name and icon lookup

Outdoor map records use their own IDs, generally starting at 60000. These are not array indices into the pocket-item name table. For example, `EB12` (60178) is NHSE's `StoneA` world rock, not the pocket material or furniture named rock.

The app now bundles `field-objects.json`, covering all 540 definitions in the project's NHSE reference revision `cb0745415945776f73375bf0a434a8babf059307`. Each record stores the original model and kind, readable name, icon resource, and inventory equivalent when one exists. Display resolution never replaces the actual saved ID, flags, quantity bytes or linked footprint cells.

| Map ID | Original model | Display name | Thumbnail |
| --- | --- | --- | --- |
| EB12 | StoneA | Rock (A) | Existing stone category artwork |
| EB13 | StoneB | Rock (B) | Existing stone category artwork |
| EB14 | StoneE | Rock (E) | Existing stone category artwork |
| EB15 | StoneD | Rock (D) | Existing stone category artwork |
| EB16 | StoneC | Rock (C) | Existing stone category artwork |
| EA60 | PltTreeOak4 | hardwood tree | Corresponding inventory artwork |
| EA71 | PltFlwCosmos3Red | red cosmos | Corresponding inventory artwork |
| EA79 | Hole | Hole | Simple overhead hole symbol |
| EA9F | PltTreeOak4Stump | Hardwood stump | Simple overhead stump symbol |

Names for the 512 objects with inventory equivalents come from the existing English name table. The other 28 definitions have explicit mappings: five rock variants, stumps including growth stages, holes, and two special fences. Existing inventory icons are category thumbnails rather than exact per-model renders; all five rocks share the bundled `OreStone` artwork. Stump and hole symbols are native vector category symbols. No game models are extracted or generated here.

`Catalog.name` checks regular items, then known field objects, then retains `Unknown item (XXXX)` for genuinely unmapped IDs. `ItemIconStore` uses the same field definitions, so the inspector and map agree. The inspector keeps the hexadecimal ID visible for identification. Field-only entries are not added to the pocket catalog or the drop-item menu.

To regenerate after updating the pinned reference:

```sh
python3 ACNH-Save-Editor/macOS/scripts/import-field-objects.py
```

The standalone importer reads `macOS/scripts/reference/FieldItemList.cs`. The existing NHSE inventory-artwork importer also regenerates this metadata from the checkout it imports. Generation fails on a new object without a usable name/icon mapping instead of silently calling it known. Check the revision, regenerate resources, and run `FieldObjectCatalogTests` when refreshing the data. The complete reference snapshot is retained to make generation reproducible offline.

Source: https://github.com/kwsch/NHSE/blob/cb0745415945776f73375bf0a434a8babf059307/NHSE.Core/Structures/Item/FieldItem/FieldItemList.cs (GPL-3.0). See the Mac port's third-party notices for existing Nintendo/NHSE artwork attribution.

Verification: all 540 definitions resolve to nonempty names and loadable thumbnails; all five rock IDs are checked explicitly, including NHSE's E/D/C ordering. Tests also cover unknown/empty items, exclusion from inventory placement, unchanged raw item records, byte-identical no-op save encoding, and existing object copy/paste/snap behavior.

Native visual verification passed in a separately identified test app using an exported copy of the example island. Selecting the existing rock at (122, 148) displayed `Rock (D)`, `Item ID: EB15`, and the stone thumbnail in the inspector; its map marker also used the rock image. The user's running app and unsaved draft were left intact. The 12 selected mapping, metadata, raw-record, no-op save, clipboard and tile-snap tests passed.
