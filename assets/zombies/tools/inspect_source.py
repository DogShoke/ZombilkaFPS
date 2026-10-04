import bpy, json
from pathlib import Path
from mathutils import Vector

root = Path(r'C:\Roblox\ZombilkaFPS\assets\zombies')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(root / 'source/zombie_ani_player.fbx'), use_image_search=False)
objects = []
for obj in bpy.data.objects:
    item = {'name': obj.name, 'type': obj.type, 'parent': obj.parent.name if obj.parent else None,
            'location': list(obj.location), 'scale': list(obj.scale)}
    if obj.type == 'MESH':
        points = [obj.matrix_world @ Vector(p) for p in obj.bound_box]
        item.update(vertices=len(obj.data.vertices), faces=len(obj.data.polygons),
                    materials=[m.name if m else None for m in obj.data.materials],
                    uvs=[u.name for u in obj.data.uv_layers], groups=[g.name for g in obj.vertex_groups],
                    bounds=[[min(p[i] for p in points) for i in range(3)], [max(p[i] for p in points) for i in range(3)]])
    if obj.type == 'ARMATURE':
        item['bones'] = [{'name': b.name, 'parent': b.parent.name if b.parent else None} for b in obj.data.bones]
    objects.append(item)
report = {'objects': objects, 'actions': [{'name': a.name, 'range': list(a.frame_range)} for a in bpy.data.actions],
          'images': [{'name': i.name, 'path': i.filepath} for i in bpy.data.images],
          'materials': [{'name': m.name, 'nodes': [{'type': n.type, 'image': n.image.filepath if n.type == 'TEX_IMAGE' and n.image else None} for n in m.node_tree.nodes] if m.use_nodes else []} for m in bpy.data.materials]}
(root / 'source_inventory.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'source/Inspected_Zombies.blend'))
