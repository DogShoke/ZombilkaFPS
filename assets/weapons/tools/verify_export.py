import bpy,os
ROOT=r'C:\Roblox\ZombilkaFPS\assets\weapons\exports'
for key in ['AKM','Mossberg']:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(ROOT,'Fps'+key+'_Roblox.fbx'),use_anim=False)
    for o in bpy.context.scene.objects:
        if o.type=='MESH':
            assert len(o.data.uv_layers)==1,(key,o.name,len(o.data.uv_layers))
            assert len(o.data.materials)==1,(key,o.name,'material slots')
            print(key,o.name,'UV:',o.data.uv_layers[0].name,'faces:',len(o.data.polygons),flush=True)
