import bpy, json, os
from mathutils import Vector
ROOT=r'C:\Roblox\ZombilkaFPS\assets'
OUT=os.path.join(ROOT,'weapons')
os.makedirs(OUT,exist_ok=True)
all_reports={}
for key,filename in [('AKM','Fps Rig AKM.glb'),('Arms','Rigged Fps Arms.glb'),('Mossberg','Mossberg 590A1.glb')]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT,filename))
    objects=[]
    for o in bpy.data.objects:
        d={'name':o.name,'type':o.type,'parent':o.parent.name if o.parent else None,'location':list(o.location),'scale':list(o.scale),'rotation':list(o.rotation_euler),'worldMatrix':[list(r) for r in o.matrix_world]}
        if o.type=='MESH':
            points=[o.matrix_world@Vector(v) for v in o.bound_box]
            d.update(vertices=len(o.data.vertices),faces=len(o.data.polygons),uvs=[u.name for u in o.data.uv_layers],materials=[m.name for m in o.data.materials],low=[min(p[i] for p in points) for i in range(3)],high=[max(p[i] for p in points) for i in range(3)],groups=[g.name for g in o.vertex_groups],modifiers=[{'type':m.type,'target':m.object.name if m.type=='ARMATURE' and m.object else None} for m in o.modifiers])
        if o.type=='ARMATURE':
            d['bones']=[{'name':b.name,'parent':b.parent.name if b.parent else None,'head':list(b.head_local),'tail':list(b.tail_local)} for b in o.data.bones]
        objects.append(d)
    materials=[]
    for m in bpy.data.materials:
        bs=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
        materials.append({'name':m.name,'base':list(bs.inputs['Base Color'].default_value) if bs else None,'nodes':[{'type':n.type,'image':n.image.name if n.type=='TEX_IMAGE' and n.image else None} for n in m.node_tree.nodes]})
    report={'objects':objects,'materials':materials,'actions':[{'name':a.name,'range':list(a.frame_range)} for a in bpy.data.actions],'images':[{'name':i.name,'size':list(i.size)} for i in bpy.data.images]}
    all_reports[key]=report
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,key+'_Source.blend'))
with open(os.path.join(OUT,'source_inventory.json'),'w',encoding='utf8') as f: json.dump(all_reports,f,indent=2)
print(json.dumps({k:{'objects':[(o['name'],o['type'],o.get('vertices'),o.get('materials')) for o in v['objects']],'actions':v['actions'],'materials':v['materials']} for k,v in all_reports.items()}),flush=True)
