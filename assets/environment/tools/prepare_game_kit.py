"""Copy the user's four authored kits into a separate export scene; keep sources intact."""
import bpy, json, math, shutil
from pathlib import Path
from mathutils import Vector

ROOT = Path(r'C:\Roblox\ZombilkaFPS\assets\environment')
OUT = ROOT / 'gamekit'
(OUT / 'exports').mkdir(parents=True, exist_ok=True)
groups = [('office', 'OfficeKit.blend'), ('office/zones', 'OfficeZones.blend'),
          ('parking', 'ParkingKit.blend'), ('parking/expansion', 'ParkingExpansion.blend')]
original_scene = bpy.data.scenes.get('ParkingExpansion') or bpy.context.window.scene
for previous in list(bpy.data.scenes):
    if previous.name.startswith('EnvironmentGameKitExport'):
        for obj in list(previous.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.scenes.remove(previous)
scene = bpy.data.scenes.new('EnvironmentGameKitExport')
bpy.context.window.scene = scene
manifest = []
for group, filename in groups:
    source = json.loads((ROOT / group / 'Manifest.json').read_text(encoding='utf-8'))['assets']
    names = [a['name'] for a in source]
    if (ROOT / group / filename).resolve() == Path(bpy.data.filepath).resolve():
        source_objects = [original_scene.objects[n].copy() for n in names]
    else:
        with bpy.data.libraries.load(str(ROOT / group / filename), link=False) as (available, loaded):
            assert all(n in available.objects for n in names), group
            loaded.objects = names
        source_objects = loaded.objects
    for metadata, obj in zip(source, source_objects):
        assert obj.type == 'MESH'
        obj.data = obj.data.copy()
        obj.parent = None
        scene.collection.objects.link(obj)
        # Names can be suffixed when Blender already contains the source gallery.
        # The export-only name stays unique and is resolved through this manifest.
        obj.name = 'Game_' + metadata['name']
        obj.location = (0, 0, 0)
        bpy.context.view_layer.update()
        low = min((obj.matrix_world @ Vector(v)).z for v in obj.bound_box)
        obj.location.z -= low
        bpy.context.view_layer.update()
        assert len(obj.data.uv_layers) == 1, obj.name
        assert obj.scale.x > 0 and obj.scale.y > 0 and obj.scale.z > 0
        obj.data.calc_loop_triangles()
        dims = [round(v, 5) for v in obj.dimensions]
        assert max(abs(a-b) for a,b in zip(dims, metadata['size_m'])) < .002, obj.name
        corners = [obj.matrix_world @ Vector(v) for v in obj.bound_box]
        world_dims = [round(max(v[k] for v in corners)-min(v[k] for v in corners),5) for k in range(3)]
        i = len(manifest)
        obj.location.x = (i % 16) * 9
        obj.location.y = (i // 16) * 9
        manifest.append({**metadata, 'group': group, 'export_name': obj.name,
                         'source_dimensions_local_m': dims, 'dimensions_xyz_m': world_dims, 'grounded': True})
assert len(manifest) == 203 and len({a['name'] for a in manifest}) == 203
bpy.ops.object.select_all(action='DESELECT')
for obj in scene.objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = next(iter(scene.objects))
bpy.ops.export_scene.fbx(filepath=str(OUT / 'exports' / 'Environment_GameKit.fbx'),
    use_selection=True, add_leaf_bones=False, bake_anim=False,
    path_mode='COPY', embed_textures=True, axis_forward='-Z', axis_up='Y',
    apply_unit_scale=True, use_space_transform=True, bake_space_transform=False)
(OUT / 'Manifest.json').write_text(json.dumps({'count': len(manifest), 'assets': manifest,
    'units': 'metres', 'palette': 'OfficePalette.png', 'blender_up': 'Z',
    'fbx_up': 'Y', 'front_blender': '-Y', 'source_scenes_preserved': True}, indent=2), encoding='utf-8')
# All four kits use the same palette. Use a packed copy from the source materials.
image = next(n.image for obj in scene.objects for mat in obj.data.materials
             if mat and mat.use_nodes for n in mat.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image)
shutil.copyfile(ROOT / 'office' / 'OfficePalette.png', OUT / 'OfficePalette.png')
bpy.context.window.scene = original_scene
print(json.dumps({'count': len(manifest), 'triangles': sum(a['triangles'] for a in manifest),
                  'fbx': str(OUT / 'exports' / 'Environment_GameKit.fbx'),
                  'source_file_unchanged': bpy.data.filepath}))
