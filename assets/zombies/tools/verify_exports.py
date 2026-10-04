import bpy,json
from pathlib import Path
from mathutils import Vector
root=Path(r'C:\Roblox\ZombilkaFPS\assets\zombies')
out=[]
for path in sorted((root/'exports').glob('Zombie_*.fbx')):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(path),use_anim=False,use_image_search=False)
    arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
    body=next(o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('lp'))
    points=[body.matrix_world@v.co for v in body.data.vertices]
    head=next(b for b in arm.data.bones if ' Head' in b.name and 'Nub' not in b.name)
    group=body.vertex_groups.get(head.name)
    verts=[body.matrix_world@v.co for v in body.data.vertices if any(g.group==group.index and g.weight>0.5 for g in v.groups)]
    center=sum(verts,Vector())/len(verts)
    bone_head=arm.matrix_world@head.head_local
    out.append({'file':path.name,'height':max(p.z for p in points)-min(p.z for p in points),
        'headBindDistance':(center-bone_head).length,'bones':len(arm.data.bones),
        'meshScale':list(body.scale),'armScale':list(arm.scale)})
(root/'export_verification.json').write_text(json.dumps(out,indent=2))
assert all(1.5 < r['height'] < 1.9 and r['headBindDistance'] < .3 for r in out),out
print('All ten exports: dimensions and head bind checked')
