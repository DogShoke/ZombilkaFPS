# Office zone modules

44 original Blender-authored static assets extending the base office kit. Shared low-poly style and 16-color palette. Total 20,572 triangles; individual mesh details are in `Manifest.json`.

- `OfficeZones.blend`: editable source; `OfficeZoneModules` is the full-size gallery and `OfficeZonesCatalog` contains display copies scaled for readability.
- `exports/OfficeZones_All.fbx`: all 44 models with gallery spacing.
- `exports/<Name>.fbx`: centred individual models, front facing -Y, Z up in Blender, origin at the lowest point. Dimensions use metres.
- `OfficePalette.png`: shared palette embedded in FBX files; one UV channel and one material per model.
- `OfficeZones_Catalog.png`: visual overview; displayed sizes are normalized, not comparative.
- `../tools/build_office_zones.py`: construction script, reuses the base kit's geometry helpers.

## Zones and variants

- Open space: short/wide/corner partitions, two/four workstation banks, under-desk pedestal, teal task chair.
- Reception: compact/wide counters, tripod turnstile, swing gate, scanner arch and security desk.
- Kitchen: compact/wide refrigerators, microwave, sink cabinet, wide counter, countertop coffee machine, snack/drink vending machines.
- Archive: two large cabinet variants, trolley, pallet and small/large boxes.
- Server room: compact/twin racks, UPS, cable bundle, ventilation cabinet; electrical panel for technical zones.
- Meeting: long conference table, wall television, projector, conference phone and executive chair.
- Damaged: overturned desk, broken chair, cracked monitor, fallen archive cabinet, paper pile and broken door.

The door, scanner and gates are static visual meshes. The sink uses a dark inset basin; glass is opaque stylized blue. Turnstile arms, doors and chair components are combined into each model rather than rigged. No automatic opening, destruction, spawning or electrical behavior is supplied. Existing infected coffee spawner remains in the separate arena kit.

For procedural placement, use the manifest's zone tags and dimensions to reserve footprints and walkways. Large furniture needs simple collision proxies in Studio. These assets have been saved for import; they are not yet uploaded or connected to the runtime generator. Roblox Studio runtime behavior has not been verified.

Validation: all 44 individual FBX exports were reimported through Blender MCP. Each retained one mesh, one UV layer, one material, matching dimensions and triangle count. Ground offsets and results are recorded in `Verification.json`. Catalog render visually inspected.
