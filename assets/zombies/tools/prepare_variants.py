import bpy, json, math
from pathlib import Path
from mathutils import Vector, Matrix
from bpy_extras.io_utils import axis_conversion
from io_scene_fbx import parse_fbx
from io_scene_fbx.fbx_utils import array_to_matrix4, RIGHT_HAND_AXES

root = Path(r'C:\Roblox\ZombilkaFPS\assets\zombies')
out = root / 'exports'
out.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(root / 'source/zombie_ani_player.fbx'), use_image_search=False, use_anim=False)
tree, _ = parse_fbx.parse(str(root/'source/zombie_ani_player.fbx'))
fbx_objects = {e.props[0]:e for e in next(e for e in tree.elems if e.id==b'Objects').elems}
connections = next(e for e in tree.elems if e.id==b'Connections').elems
parents = {}
for c in connections:
    if c.props[0]==b'OO':
        parents.setdefault(c.props[1],[]).append(c.props[2])
settings = next(e for e in tree.elems if e.id==b'GlobalSettings')
props = {e.props[0].decode():e.props[-1] for e in next(e for e in settings.elems if e.id==b'Properties70').elems}
axis_key = tuple((int(props[n+'Axis']),int(props[n+'AxisSign'])) for n in ('Up','Front','Coord'))
axis_up,axis_forward = {v:k for k,v in RIGHT_HAND_AXES.items()}[axis_key]
global_matrix = Matrix.Scale(float(props['UnitScaleFactor'])/100,4) @ axis_conversion(from_forward=axis_forward,from_up=axis_up).to_4x4()
mesh_bind = {}
for uid,e in fbx_objects.items():
    if e.id==b'Deformer' and e.props[2]==b'Cluster':
        values={v.id:v for v in e.elems}
        matrix=global_matrix @ array_to_matrix4(values[b'TransformLink'].props[0]) @ array_to_matrix4(values[b'Transform'].props[0])
        for skin in parents.get(uid,[]):
            for geometry in parents.get(skin,[]):
                for model in parents.get(geometry,[]):
                    item=fbx_objects.get(model)
                    if item and item.id==b'Model':
                        mesh_bind[item.props[1].split(b'\x00\x01')[0].decode()] = matrix
with bpy.data.libraries.load(str(root/'source/Inspected_Zombies.blend'), link=False) as (source, target):
    target.actions = source.actions
for action in bpy.data.actions:
    action.use_fake_user = True
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
image = bpy.data.images.load(str(root / 'textures/world_people_colors.png'), check_existing=True)
image.pack()
for mat in bpy.data.materials:
    if mat.use_nodes:
        bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        tex = next(n for n in mat.node_tree.nodes if n.type == 'TEX_IMAGE')
        tex.image = image
        for link in list(mat.node_tree.links):
            if link.to_node == bsdf and link.to_socket.name in ('Base Color', 'Normal'):
                mat.node_tree.links.remove(link)
        mat.node_tree.links.new(tex.outputs['Color'], bsdf.inputs['Base Color'])
        bsdf.inputs['Base Color'].default_value = (1,1,1,1)
        bsdf.inputs['Roughness'].default_value = 0.85

variants = []
meshes = sorted([o for o in scene.objects if o.type == 'MESH' and o.name.startswith(('lpMale_zombie_', 'lpFemale_zombie_'))], key=lambda o:o.name)
for index, body in enumerate(meshes):
    arm = body.parent
    group = [o for o in scene.objects if o.type == 'MESH' and o.parent == arm]
    # Keep the authored bone take, remove scene-layout/root motion from the export copy.
    action = bpy.data.actions.get(arm.name+'|Take 001|BaseLayer')
    arm.animation_data_clear()
    arm.data.pose_position = 'REST'
    bpy.context.view_layer.update()
    # Restore the actual cluster bind matrices; scene layout transforms disagree with them.
    bone_bind = {b.name:(arm.matrix_world @ b.matrix_local, (arm.matrix_world @ b.tail_local-arm.matrix_world @ b.head_local).length) for b in arm.data.bones}
    arm.parent=None
    arm.matrix_world=Matrix.Identity(4)
    bpy.ops.object.select_all(action='DESELECT')
    arm.select_set(True)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.object.mode_set(mode='EDIT')
    for bone in arm.data.edit_bones:
        matrix,length=bone_bind[bone.name]
        bone.matrix=matrix.normalized()
        bone.length=length
    bpy.ops.object.mode_set(mode='OBJECT')
    for pose in arm.pose.bones:
        pose.matrix_basis=Matrix.Identity(4)
    arm_world=arm.matrix_world.copy()
    mesh_world={o:mesh_bind[o.name] for o in group}
    # The source scene rotates characters onto their sides. Align anatomical up first.
    head = next(b for b in arm.data.bones if b.name.split(' ', 1)[-1].startswith('Head') and 'Nub' not in b.name)
    feet = [b for b in arm.data.bones if b.name.split(' ', 1)[-1].startswith(('L Foot', 'R Foot'))]
    up = (arm_world @ head.head_local - sum((arm_world @ b.head_local for b in feet), Vector()) / len(feet)).normalized()
    rotation = up.rotation_difference(Vector((0,0,1))).to_matrix().to_4x4()
    left = next(b for b in arm.data.bones if ' L UpperArm' in b.name)
    right = next(b for b in arm.data.bones if ' R UpperArm' in b.name)
    across = rotation.to_3x3() @ (arm_world.to_3x3() @ (right.head_local-left.head_local))
    rotation = Matrix.Rotation(-math.atan2(across.y, across.x), 4, 'Z') @ rotation
    arm.parent = None
    arm.matrix_world = arm_world
    for obj in group:
        obj.parent = None
        obj.matrix_world = mesh_world[obj]
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    points = []
    for obj in group:
        evaluated = obj.evaluated_get(dg)
        mesh = evaluated.to_mesh()
        points.extend(rotation @ (obj.matrix_world @ v.co) for v in mesh.vertices)
        evaluated.to_mesh_clear()
    low = Vector([min(p[i] for p in points) for i in range(3)])
    high = Vector([max(p[i] for p in points) for i in range(3)])
    scale = 1.8 / (high.z-low.z)
    center = Vector(((low.x+high.x)/2, (low.y+high.y)/2, low.z))
    normalizer = Matrix.Scale(scale, 4) @ Matrix.Translation(-center) @ rotation
    arm.matrix_world = normalizer @ arm_world
    for obj in group:
        obj.matrix_world = normalizer @ mesh_world[obj]
    # Bake the export copy's matrices into mesh/rest-bone data so Studio sees unit-scale rigs.
    arm.data.transform(arm.matrix_world)
    arm.matrix_world = Matrix.Identity(4)
    for pose in arm.pose.bones:
        pose.matrix_basis = Matrix.Identity(4)
    for obj in group:
        obj.data.transform(obj.matrix_world)
        obj.matrix_world = Matrix.Identity(4)
    variant_name = body.name.replace('lpFemale_zombie_', 'Zombie_Female_').replace('lpMale_zombie_', 'Zombie_Male_')
    empty = bpy.data.objects.new(variant_name, None)
    scene.collection.objects.link(empty)
    for obj in [arm]+group:
        world = obj.matrix_world.copy()
        obj.parent = empty
        obj.matrix_world = world
    arm.name = variant_name + '_Rig'
    # A dedicated FBX per character; bone names/weights/UVs are retained.
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [empty, arm]+group:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = arm
    fbx = out / (variant_name+'.fbx')
    bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=True, object_types={'EMPTY','ARMATURE','MESH'},
        add_leaf_bones=False, use_mesh_modifiers=False, bake_anim=False, apply_scale_options='FBX_SCALE_ALL',
        path_mode='COPY', embed_textures=True, axis_forward='-Z', axis_up='Y')
    variants.append({'name':variant_name, 'file':fbx.name, 'body':body.name,
        'rig':arm.name, 'meshes':[o.name for o in group], 'boneCount':len(arm.data.bones),
        'sourceAction':action.name if action else None, 'sourceHeight':high.z-low.z, 'normalizedHeightMeters':1.8})
    arm['source_action'] = action.name if action else ''
    # Layout for one bulk import; the individual files remain centered.
    empty.location = (index%5 * 2.4, index//5 * 3.0, 0)

keep = {o for o in scene.objects if o.name.startswith(('Zombie_', 'lpMale_zombie_', 'lpFemale_zombie_', 'acc_'))}
for obj in list(scene.objects):
    if obj not in keep:
        bpy.data.objects.remove(obj, do_unlink=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.fbx(filepath=str(out/'Zombies_All_Roblox.fbx'), use_selection=True,
    object_types={'EMPTY','ARMATURE','MESH'}, add_leaf_bones=False, use_mesh_modifiers=False,
    bake_anim=False, apply_scale_options='FBX_SCALE_ALL', path_mode='COPY', embed_textures=True, axis_forward='-Z', axis_up='Y')
bpy.ops.wm.save_as_mainfile(filepath=str(root/'Zombies_Prepared.blend'))
(root/'variants.json').write_text(json.dumps({'variants':variants,'bulkImport':'exports/Zombies_All_Roblox.fbx',
    'texture':'textures/world_people_colors.png','animationNote':'Authored source actions retained in blend; FBX import files contain rest rigs.'},indent=2),encoding='utf-8')
print('PREPARED',len(variants),'VARIANTS')
