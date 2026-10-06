# Office Reference Kit

55 original static low-poly models authored in the connected Blender through MCP, inspired by the two user-supplied office references. These are stylized approximations, not extracted reference meshes.

- `OfficeKit.blend`: editable Blender scene, models arranged at real relative sizes.
- `exports/OfficeKit_All.fbx`: all models arranged as a gallery; import as separate objects.
- `exports/<Name>.fbx`: individual models with origin at their base / mounting baseline.
- `OfficePalette.png`: shared 512 x 32 color palette; one UV layer and one material per mesh. Palette embedded into the FBX exports and also provided separately.
- `Manifest.json`: asset names, dimensions in metres and triangle counts.
- `OfficeKit_Preview.png`: Blender render of the kit.
- `OfficeKit_Catalog.png`: readable overview with each object scaled to fit its cell; display sizes here are not comparative. The additional `OfficeCatalogPreview` scene contains these display copies; the main scene and exports retain actual sizes.
- `tools/build_office_kit.py`: reproducible Blender Python construction source.

Furniture: three desk variants, meeting and round tables, two chairs, sofa, coffee table, reception, two partitions, cabinets, filing cabinet, lockers, shelves. Equipment: server rack, copier, printer, shredder, water cooler, monitors, tower, laptop, keyboard, mouse. Decor: door, window, boards, clock, extinguisher, plants, coat stand, lights, bins. Small props: lamp, paper trays, binders, boxes, cup, pen holder, stapler, sticky notes, clipboard and calendar.

Total: 20,266 triangles across 55 meshes. Each asset is one combined static mesh; disconnected geometric components are intentional. Shelves and bookcase are empty so the separate boxes and binders can be placed freely. Windows use opaque stylized blue glass. No rig, animation or gameplay scripts.

In Roblox Studio use the 3D importer for the desired FBX and apply the supplied palette if embedded texture detection fails. Confirm scale against the character before placing. The combined export includes gallery spacing; individual exports are centred. Add simple collision proxies for furniture as appropriate.

Geometry and palette were visually inspected in Blender; all 56 FBX files are present. DeskWorkstation, OfficeChair, Photocopier, LargePlant and Keyboard were reimported into a temporary Blender scene: dimensions, triangle counts, one UV layer and one material were retained. Results are saved in `Verification.json`. The kit is saved on disk and has not been uploaded, integrated into Rojo templates or runtime-tested in Roblox Studio.
