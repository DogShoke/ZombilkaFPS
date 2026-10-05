import bpy, os, json, math
from mathutils import Vector, Matrix
ROOT=r'C:\Roblox\ZombilkaFPS\assets\weapons'
os.makedirs(os.path.join(ROOT,'textures'),exist_ok=True)
os.makedirs(os.path.join(ROOT,'exports'),exist_ok=True)
ROT=Matrix(((0,-1,0,0),(0,0,1,0),(-1,0,0,0),(0,0,0,1)))
def activate(obj):
    bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
def freeze(objects, rig, transform, names=None):
    bpy.context.view_layer.update(); dg=bpy.context.evaluated_depsgraph_get()
    rest={b.name:transform@rig.matrix_world@b.matrix for b in rig.pose.bones}
    meshes=[]
    for obj in objects:
        mesh=bpy.data.meshes.new_from_object(obj.evaluated_get(dg),preserve_all_data_layers=True,depsgraph=dg)
        mesh.transform(transform@obj.matrix_world)
        obj.parent=None; obj.matrix_world=Matrix.Identity(4); obj.modifiers.clear(); obj.data=mesh
        meshes.append(obj)
    rig.animation_data_clear(); rig.parent=None; rig.matrix_world=Matrix.Identity(4)
    activate(rig); bpy.ops.object.mode_set(mode='EDIT')
    for b in rig.data.edit_bones:
        b.matrix=rest[b.name].normalized(); b.length=0.1
    bpy.ops.object.mode_set(mode='OBJECT')
    for b in rig.pose.bones: b.matrix_basis=Matrix.Identity(4)
    for obj in meshes:
        mod=obj.modifiers.new('Skin','ARMATURE'); mod.object=rig; obj.parent=rig
    bpy.context.view_layer.update()
    return rest
def bake(obj, name):
    activate(obj)
    old=obj.data.uv_layers.active
    uv=obj.data.uv_layers.new(name=name+'_UV',do_init=True)
    obj.data.uv_layers.active=uv; uv.active_render=True
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=0.006)
    bpy.ops.object.mode_set(mode='OBJECT')
    image=bpy.data.images.new(name,2048,2048,alpha=False); image.colorspace_settings.name='sRGB'
    for mat in obj.data.materials:
        node=mat.node_tree.nodes.new('ShaderNodeTexImage'); node.image=image
        mat.node_tree.nodes.active=node; node.select=True
    scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=8
    scene.render.bake.use_pass_direct=False; scene.render.bake.use_pass_indirect=False; scene.render.bake.use_pass_color=True; scene.render.bake.margin=16
    bpy.ops.object.bake(type='DIFFUSE')
    pixels=image.pixels[:]; samples=pixels[::4]
    assert max(samples)>0.05 and sum(samples)/len(samples)>0.002, 'Empty bake '+name
    image.filepath_raw=os.path.join(ROOT,'textures',name+'.png'); image.file_format='PNG'; image.save(); image.pack()
    mat=bpy.data.materials.new(name+'_Visible'); mat.use_nodes=True
    bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    node=mat.node_tree.nodes.new('ShaderNodeTexImage'); node.image=image
    mat.node_tree.links.new(node.outputs['Color'],bs.inputs['Base Color']); bs.inputs['Roughness'].default_value=0.6
    obj.data.materials.clear(); obj.data.materials.append(mat)
    for p in obj.data.polygons: p.material_index=0
    return name+'.png'
def export(key, rig, meshes):
    bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True)
    for m in meshes: m.select_set(True)
    bpy.context.view_layer.objects.active=rig
    rig.animation_data_clear()
    for b in rig.pose.bones: b.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()
    # Export only the baked UV while retaining source UVs in the prepared blend.
    original={obj:obj.data for obj in meshes}
    temporary=[]
    try:
        for obj in meshes:
            obj.data=obj.data.copy(); temporary.append(obj.data)
            keep=next(u.name for u in obj.data.uv_layers if 'BaseColor_UV' in u.name)
            for uv in list(obj.data.uv_layers):
                if uv.name!=keep: obj.data.uv_layers.remove(uv)
            obj.data.uv_layers.active_index=0; obj.data.uv_layers[0].active_render=True
        bpy.ops.export_scene.fbx(filepath=os.path.join(ROOT,'exports','Fps'+key+'_Roblox.fbx'),use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,use_mesh_modifiers=False,bake_anim=False,apply_scale_options='FBX_SCALE_ALL',axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
    finally:
        for obj,data in original.items(): obj.data=data
        for data in temporary: bpy.data.meshes.remove(data)
def cf(m): return [round(v,7) for row in m for v in row][:]
def rows12(m): return [round(m[0][3],7),round(m[1][3],7),round(m[2][3],7)]+[round(m[r][c],7) for r in range(3) for c in range(3)]
def render_card(obj,key):
    scene=bpy.context.scene
    for o in scene.objects:
        if o.type=='MESH': o.hide_render=o!=obj
    points=[obj.matrix_world@Vector(v) for v in obj.bound_box]
    low=Vector([min(p[i] for p in points) for i in range(3)]); high=Vector([max(p[i] for p in points) for i in range(3)])
    center=(low+high)/2
    cam_data=bpy.data.cameras.new('CardCamera'); camera=bpy.data.objects.new('CardCamera',cam_data); scene.collection.objects.link(camera)
    location=center+Vector((6,2,2)); forward=(center-location).normalized(); right=forward.cross(Vector((0,1,0))).normalized(); up=right.cross(forward)
    camera.matrix_world=Matrix((right,up,-forward)).transposed().to_4x4(); camera.location=location; cam_data.type='ORTHO'; cam_data.ortho_scale=(high-low).length*1.2
    scene.camera=camera
    for pos,energy,size in [((2,5,3),600,5),((-3,3,-3),500,4)]:
        d=bpy.data.lights.new('Softbox','AREA'); d.energy=energy; d.shape='DISK'; d.size=size
        l=bpy.data.objects.new('Softbox',d); scene.collection.objects.link(l); l.location=center+Vector(pos); l.rotation_euler=(center-l.location).to_track_quat('-Z','Y').to_euler()
    scene.world=bpy.data.worlds.new('WeaponWorld'); scene.world.use_nodes=True; next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND').inputs['Color'].default_value=(0.3,0.3,0.3,1)
    scene.render.engine='CYCLES'; scene.cycles.samples=16; scene.render.film_transparent=True
    scene.render.resolution_x=900; scene.render.resolution_y=480; scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'; scene.render.filepath=os.path.join(ROOT,key+'_Card.png'); bpy.ops.render.render(write_still=True)
    for o in scene.objects:
        if o.type=='MESH': o.hide_render=False

# AKM: freeze the visible idle pose, then retain sampled original motion in the new bind space.
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT,'AKM_Source.blend'))
rig=bpy.data.objects['Armature']; gun=bpy.data.objects['AKM_model']; arms=bpy.data.objects['ArmModel']
actions=list(bpy.data.actions); idle=next(a for a in actions if a.name.endswith('|Idle'))
rig.animation_data.action=idle; bpy.context.scene.frame_set(0); bpy.context.view_layer.update()
dg=bpy.context.evaluated_depsgraph_get(); ev=gun.evaluated_get(dg)
coords=[gun.matrix_world@v.co for v in ev.data.vertices]; length=max(p.x for p in coords)-min(p.x for p in coords)
grip=rig.matrix_world@rig.pose.bones['Trigger'].matrix.translation
transform=Matrix.Scale(4.2/length,4)@ROT@Matrix.Translation(-grip)
original_rest={b.name:transform@rig.matrix_world@b.matrix for b in rig.pose.bones}
clips={}
for action in actions:
    rig.animation_data.action=action; frames=[]
    first,last=map(int,action.frame_range)
    for frame in range(first,last+1):
        bpy.context.scene.frame_set(frame); bpy.context.view_layer.update()
        frames.append({b.name:rows12(transform@rig.matrix_world@b.matrix@original_rest[b.name].inverted()) for b in rig.pose.bones})
    clips[action.name.split('|')[-1]]={'fps':bpy.context.scene.render.fps,'frames':frames}
rig.animation_data.action=idle; bpy.context.scene.frame_set(0)
freeze([gun,arms],rig,transform)
print('AKM_READY',[(o.name,list(o.dimensions)) for o in [gun,arms]],flush=True)
textures={'AKM_model':bake(gun,'AKM_BaseColor'),'ArmModel':bake(arms,'AKM_Arms_BaseColor')}
with open(os.path.join(ROOT,'AKM_Clips.json'),'w') as f: json.dump(clips,f,separators=(',',':'))
export('AKM',rig,[gun,arms]); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'AKM_Prepared.blend')); render_card(gun,'AKM')
with open(os.path.join(ROOT,'AKM_Manifest.json'),'w') as f: json.dump({'textures':textures,'bones':list(original_rest),'clips':{k:len(v['frames']) for k,v in clips.items()}},f,indent=2)

# Separate shotgun and arms copies, with arm lengths normalized before fitting the hands.
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT,'Mossberg_Source.blend'))
gun=bpy.data.objects['Mossberg590A1']; grig=bpy.data.objects['Armature']; bpy.context.view_layer.update()
coords=[gun.matrix_world@v.co for v in gun.evaluated_get(bpy.context.evaluated_depsgraph_get()).data.vertices]
length=max(p.x for p in coords)-min(p.x for p in coords)
grip=grig.matrix_world@grig.pose.bones['Trigger'].matrix.translation
freeze([gun],grig,Matrix.Scale(4.5/length,4)@ROT@Matrix.Translation(-grip))
grig.name='ShotgunRig'; grig.data.bones['Root'].name='ShotgunRoot'
with bpy.data.libraries.load(os.path.join(ROOT,'Arms_Source.blend'),link=False) as (src,dst): dst.objects=['Armature','ArmModel']
arig,arms=dst.objects
for o in [arig,arms]: bpy.context.scene.collection.objects.link(o)
arig.name='ArmsRig'; bpy.context.view_layer.update()
p={b.name:arig.matrix_world@b.matrix for b in arig.pose.bones}
length=(p['UpperArm.L'].translation-p['LowerArm.L'].translation).length+(p['LowerArm.L'].translation-p['Hand.L'].translation).length
freeze([arms],arig,Matrix.Scale(2.5/length,4)@ROT)
activate(grig); arig.select_set(True); bpy.ops.object.join(); rig=bpy.context.object; rig.name='Armature'
for o in [gun,arms]:
    o.parent=rig
    for mod in o.modifiers:
        if mod.type=='ARMATURE': mod.object=rig
rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
hand_basis={side:rest['Hand'+('.L' if side=='L' else '.R.001')].to_3x3().to_4x4() for side in ['L','R']}
def fit_arm(side, wrist, elbow_out):
    suffix='.L' if side=='L' else '.R.001'
    upper=rig.pose.bones['UpperArm'+suffix]; lower=rig.pose.bones['LowerArm'+suffix]; hand=rig.pose.bones['Hand'+suffix]
    a,b,c=[rest[n].translation for n in [upper.name,lower.name,hand.name]]
    l1,l2=(b-a).length,(c-b).length
    shoulder=Vector((-0.62 if side=='L' else 0.62,-0.45,0.8))
    d=wrist-shoulder; distance=min(d.length,l1+l2-0.002); axis=d.normalized()
    along=(l1*l1-l2*l2+distance*distance)/(2*distance)
    bend=Vector((elbow_out,-1,0)); bend=(bend-axis*bend.dot(axis)).normalized()
    elbow=shoulder+axis*along+bend*math.sqrt(max(0,l1*l1-along*along))
    q1=(b-a).rotation_difference(elbow-shoulder).to_matrix().to_4x4()
    q2=(c-b).rotation_difference(wrist-elbow).to_matrix().to_4x4()
    upper.matrix=Matrix.Translation(shoulder)@q1@Matrix.Translation(-a)@rest[upper.name]
    bpy.context.view_layer.update()
    lower.matrix=Matrix.Translation(elbow)@q2@Matrix.Translation(-b)@rest[lower.name]
    bpy.context.view_layer.update()
    hand.matrix=Matrix.Translation(wrist)@Matrix.Rotation(math.pi/2 if side=='R' else -math.pi/2,4,'Y')@hand_basis[side]
    bpy.context.view_layer.update()
base_left=rest['FR'].translation+Vector((-0.09,-0.15,0))
base_right=Vector((0.12,-0.13,0.04))
fit_arm('L',base_left,-1); fit_arm('R',base_right,1)
for b in rig.pose.bones:
    if any(n in b.name for n in ['DoubleFingers.','DoubleFingersTip.','Index.','IndexTip.','Thumb.','ThumbTip.']):
        pivot=b.matrix.translation.copy()
        angle=math.radians((45 if 'Tip' in b.name else 60)*(-1 if '.L' in b.name else 1))
        b.matrix=Matrix.Translation(pivot)@Matrix.Rotation(angle,4,'Z')@Matrix.Translation(-pivot)@b.matrix
        bpy.context.view_layer.update()
bpy.context.view_layer.update()
freeze([gun,arms],rig,Matrix.Identity(4))
idle_rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
rest=idle_rest
clips={}
scene=bpy.context.scene; scene.render.fps=30
for name,count in [('Idle',60),('Shoot',24),('Reload',108)]:
    frames=[]
    for frame in range(count+1):
        for b in rig.pose.bones: b.matrix_basis=Matrix.Identity(4)
        t=frame/30
        if name=='Shoot':
            pump=0.32*max(0,math.sin(math.pi*max(0,min(1,(t-0.12)/0.48))))
            rig.pose.bones['FR'].matrix=Matrix.Translation((0,0,pump))@rest['FR']
            fit_arm('L',base_left+Vector((0,0,pump)),-1); fit_arm('R',base_right,1)
        elif name=='Reload':
            blend=min(1,frame/12,(count-frame)/12); pulse=(math.sin((frame-12)/84*math.pi*12)*0.5+0.5)*blend
            target=base_left.lerp(Vector((-0.05,-0.44,0.12+0.12*pulse)),blend)
            fit_arm('L',target,-1); fit_arm('R',base_right,1)
        bpy.context.view_layer.update()
        frames.append({b.name:rows12(b.matrix@idle_rest[b.name].inverted()) for b in rig.pose.bones})
        for b in rig.pose.bones: b.keyframe_insert('location',frame=frame); b.keyframe_insert('rotation_quaternion',frame=frame); b.keyframe_insert('scale',frame=frame)
    if rig.animation_data and rig.animation_data.action:
        rig.animation_data.action.name='Mossberg_'+name; rig.animation_data.action.use_fake_user=True
    rig.animation_data_clear(); clips[name]={'fps':30,'frames':frames}
for b in rig.pose.bones: b.matrix_basis=Matrix.Identity(4)
textures={'Mossberg590A1':bake(gun,'Mossberg_BaseColor'),'ArmModel':bake(arms,'Mossberg_Arms_BaseColor')}
with open(os.path.join(ROOT,'Mossberg_Clips.json'),'w') as f: json.dump(clips,f,separators=(',',':'))
export('Mossberg',rig,[gun,arms]); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'Mossberg_Prepared.blend')); render_card(gun,'Mossberg')
with open(os.path.join(ROOT,'Mossberg_Manifest.json'),'w') as f: json.dump({'textures':textures,'bones':list(idle_rest),'clips':{k:len(v['frames']) for k,v in clips.items()}},f,indent=2)
print('WEAPONS_PREPARED',flush=True)
