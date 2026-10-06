# Parking and service area kit

52 original static low-poly assets authored in connected Blender via MCP from the user's parking reference. These are stylized approximations with the same palette as the office kit.

- `ParkingKit.blend`: full-size gallery in `ParkingKit`, display copies in `ParkingKitCatalog`.
- `exports/<Name>.fbx`: one combined mesh per asset, metres, ground origin, front -Y in Blender.
- `exports/ParkingKit_All.fbx`: all assets with gallery spacing.
- `OfficePalette.png`: 16-color shared palette; embedded in FBX exports. One material and one UV channel per model.
- `Manifest.json`: names, categories, triangle counts and dimensions.
- `ParkingKit_Catalog.png`: normalized-size catalog; visual sizes are not comparative.
- `../office/tools/build_parking_kit.py`: reproducible construction script, using office helper and export code.

Access: raised/closed barrier, payment and ticket kiosks, security booth. Security: hanging light, bullet/dome cameras, exit door, extinguisher cabinet. Traffic: five bollards, two cones, wheel stops, speed bump, hanging clearance bar, bicycle rack, three barriers, guardrail and chain posts. Service: bin, dumpster, pallet, tool trolley, electrical cabinet, AC unit, pedestal/wall EV chargers. Vehicles: white sedan, blue hatchback, grey SUV, service van, red motorcycle and blue bicycle. Signs: parking, accessible parking, speed limit and direction. Structure/markings: column, elevator front, arrow/hatch/tyre-track tiles, entry tunnel and ramp.

Vehicles, barriers, booth doors and elevator are static scenery. No rig, working vehicle, interactive gate or gameplay logic is included. Glass is opaque stylized blue. All models are visual meshes with intentional disconnected components; add simple collision proxies and confirm scale in Studio. FBX import and runtime placement in Roblox Studio are not yet verified. Existing game and Rojo code were not changed.

Validation: all 52 individual FBX exports reimported into Blender through MCP. Mesh count, one UV channel, one material, dimensions and triangle counts match the manifest. Results are in `Verification.json`. Total: 29,814 triangles. Catalog render visually inspected.
