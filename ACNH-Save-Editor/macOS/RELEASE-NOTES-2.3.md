# Version 2.3 · Map improvements

- Change existing inclines between all eight standard styles, with review, undo/redo, revert, save, and export. Position and rotation are preserved.
- Individual overhead icons represent all eight bridge and eight incline styles.
- Corrected the 90-degree mismatch in bridge and incline artwork, plot guides, and map click targets. Saved positions and rotations are unchanged.
- Recognize 540 known outdoor-object definitions, including rocks, trees, flowers, stumps, holes, and fences. Saved IDs remain visible; truly unmapped IDs still show their code.
- Show the plaza as a plain brown rectangle with rounded corners.

## Downloads

Open NHSE-for-Mac.dmg and drag ACNH Save Editor.app to Applications, replacing the previous copy after quitting it. NHSE-for-Mac.zip contains the same app. SHA256SUMS.txt contains download checksums.

Version 2.3, build 18. Universal app for Apple silicon and Intel, macOS 14 or later. Offline save editing supports ACNH 3.0.0–3.0.3. Live Pockets retains its existing ACNH 3.0.3 / nxnative / Apple silicon requirements.

The app is ad-hoc signed and is not notarized by Apple. See the repository installation guide if macOS blocks the first launch.

Building outlines remain placement guides. Exact anchors, collisions, Intel hardware execution, and importing edited saves back into the game still need manual verification. Keep an original save backup.

## Verification

All 105 automated tests passed (86 core and 19 native app tests). The release app contains arm64 and x86_64 executables targeting macOS 14.0. App signature, ZIP integrity, and DMG checksums were verified. The corrected bridge direction was visually checked against the island river using a disposable save copy.
