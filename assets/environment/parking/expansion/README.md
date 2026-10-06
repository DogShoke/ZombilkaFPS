# Parking gameplay and atmosphere expansion

52 original static low-poly models, authored in Blender via MCP. Same 16-color palette as the existing office and parking kits; 24,768 triangles total.

- `ParkingExpansion.blend`: full-size assets in `ParkingExpansion`; normalized preview copies in `ParkingExpansionCatalog`.
- `exports/<Name>.fbx`: 52 individual meshes, metres, front -Y, Z up in Blender, grounded origin.
- `exports/ParkingExpansion_All.fbx`: complete gallery with spacing.
- `OfficePalette.png`: shared color palette, embedded in exports.
- `Manifest.json`: dimensions, zone/category, triangle counts and placement conventions.
- `Verification.json`: all 52 exports reimported into Blender; one mesh, UV and material each, matching dimensions and triangles, grounded lower bounds.
- `ParkingExpansion_Catalog.png`: overview; each model is scaled to fit its cell.
- `../../office/tools/build_parking_expansion.py`: reproducible construction source; uses previous authored helper scripts.

Structure: three concrete supports, two concrete islands, three Jersey barriers, two stair flights, landing, elevator hall, service door and inter-level ramp.

Cover/service: stacked boxes, tyre stack, canister cluster, flatbed cart, hand pallet jack, tall service locker and wall electrical board.

Atmosphere: two ceiling lamps, straight/elbow ducts, cable bundle, amber beacon, oil puddle, garbage bags and litter pile.

Wayfinding: section A1/B2/P3 panels, Exit/Elevator/Stairs arrows, Entry/Exit/Service signs, three color-zone floor tiles and turning tyre marks.

Damage/infection: bloody footprints, blood stain, wrecked sedan, overturned motorcycle, broken barrier, crushed cone, open damaged electrical board, infected parking meter and scratched metal panel.

All models are static scenery. The beacon and yellow spark strokes are geometry, without blinking or particle effects. Vehicles and elevator do not move, and the parking meter has no spawning behavior. Stair flights are open modules to assemble with landings and walls; the elevator hall is open at the front and top. Stairs have 0.18 m rises / 0.28 m treads (10 or 16 steps). Ramp rises 1.2 m over 6 m; choose floor heights and connectors accordingly. Collision proxies, navigation and clearance need verification after import into Studio. Floor stains are thin meshes, not transparent decal textures.

The catalog render was visually inspected and all individual FBX files passed reimport checks. No Roblox upload, Rojo integration or Studio runtime verification has been performed. Game code was not changed.
