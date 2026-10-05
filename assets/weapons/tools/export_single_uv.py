import bpy,os
ROOT=r'C:\Roblox\ZombilkaFPS\assets\weapons'
for key in ['AKM','Mossberg']:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT,key+'_Prepared.blend'))
    rig=bpy.data.objects['Armature']
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent==rig]
    for o in meshes:
        target=next(u for u in o.data.uv_layers if 'BaseColor_UV' in u.name)
        keep=target.name
        for uv in list(o.data.uv_layers):
            if uv.name!=keep: o.data.uv_layers.remove(uv)
        o.data.uv_layers.active_index=0; o.data.uv_layers[0].active_render=True
    bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True)
    for o in meshes: o.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.fbx(filepath=os.path.join(ROOT,'exports','Fps'+key+'_Roblox.fbx'),use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,use_mesh_modifiers=False,bake_anim=False,apply_scale_options='FBX_SCALE_ALL',axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,key+'_Roblox.blend'))
    print(key,[(o.name,[u.name for u in o.data.uv_layers]) for o in meshes],flush=True)
