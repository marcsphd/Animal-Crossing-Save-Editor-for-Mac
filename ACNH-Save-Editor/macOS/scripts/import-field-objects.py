#!/usr/bin/env python3
"""Build display metadata from NHSE's pinned FieldItemList; never modifies save IDs.

Usage: python3 scripts/import-field-objects.py [FieldItemList.cs]
The bundled reference is from REFERENCE-REVISION.txt (GPL-3.0).
"""
import json
from pathlib import Path
import re
import sys


def generate(source=None):
    root = Path(__file__).resolve().parent.parent
    source = Path(source) if source else root / "scripts/reference/FieldItemList.cs"
    resources = root / "Sources/ACNHMac/Resources"
    names = (resources / "items.txt").read_text().splitlines()
    icons = json.loads((resources / "item-icons.json").read_text())
    pattern = r'\{0x([0-9A-F]+),\s*new FieldItemDefinition\(\s*(\d+),\s*(\d+)\s*,\s*(\d+)\s*,\s*"([^"]+)"\s*,\s*FieldItemKind\.(\w+)'
    records = {}
    for hex_id, decimal_id, dig, pick, model, kind in re.findall(pattern, source.read_text(encoding="utf-8-sig")):
        item_id, dig, pick = int(decimal_id), int(dig), int(pick)
        assert item_id == int(hex_id, 16) and 60000 <= item_id < 0xFFFD
        assert str(item_id) not in records
        held = pick if pick != 65534 else dig if dig != 65534 else None
        record = {"model": model, "kind": kind}
        if held is not None and held < len(names) and names[held] and not names[held].startswith("(None)"):
            record.update(name=names[held], heldItemID=held, icon=icons.get(str(held), "item-icon-leaf"))
        elif re.fullmatch(r"Stone[A-E]", model):
            record.update(name=f"Rock ({model[-1]})", icon="item-icon-OreStone")
        elif "Stump" in model:
            species = next(value for token, value in [("Oak", "Hardwood"), ("Cedar", "Cedar"), ("Palm", "Coconut"), ("Bamboo", "Bamboo"), ("Fruit", "Fruit tree")] if token in model)
            stage = re.search(r"[1-4]", model).group()
            suffix = {"1": " (small young)", "2": " (medium young)", "3": " (large young)", "4": ""}[stage]
            record.update(name=f"{species} stump{suffix}", icon="field-icon-stump")
        elif model == "Hole":
            record.update(name="Hole", icon="field-icon-hole")
        elif model in ("FenceCommune", "FenceGardenPegRope"):
            record.update(name="Communal island fence" if model == "FenceCommune" else "Garden rope fence", icon="item-icon-Fence")
        else:
            raise ValueError(f"Unmapped outdoor object {item_id}: {model}")
        assert record["name"] and record["icon"]
        if record["icon"].startswith("item-icon-"):
            assert (resources / (record["icon"] + ".png")).is_file(), record
        records[str(item_id)] = record
    assert len(records) >= 500, "Unexpected/truncated field-object reference"
    (resources / "field-objects.json").write_text(json.dumps(records, indent=2, sort_keys=True) + "\n")
    print(f"Mapped {len(records)} outdoor objects; {sum('heldItemID' not in r for r in records.values())} have explicit non-inventory mappings")


if __name__ == "__main__":
    generate(sys.argv[1] if len(sys.argv) > 1 else None)
