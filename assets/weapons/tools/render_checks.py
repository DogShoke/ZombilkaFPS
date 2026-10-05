import bpy, os, json
from mathutils import Vector, Matrix
ROOT=r'C:\Roblox\ZombilkaFPS\assets\weapons'
def matrix(a): return Matrix(((a[3],a[4],a[5],a[0]),(a[6],a[7],a[8],a[1]),(a[9],a[10],a[11],a[2]),(0,0,0,1)))
for key,frames in [('AKM',[('Idle',0),('Shoot',2),('Reload',30)]),('Mossberg',[('Idle',0),('Shoot',10),('Reload',35)])]:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT,key+'_Prepared.blend'))
    scene=bpy.context.scene; rig=bpy.data.objects['Armature']
    for o in list(scene.objects):
        if o.type not in ['MESH','ARMATURE']: bpy.data.objects.remove(o,do_unlink=True)
        elif o.type=='MESH' and o.name=='Icosphere': o.hide_render=True
    d=bpy.data.cameras.new('FPSCamera'); camera=bpy.data.objects.new('FPSCamera',d); scene.collection.objects.link(camera)
    camera.matrix_world=Matrix.Translation(Vector((-0.5,0.64,0.8))); d.lens=24; scene.camera=camera
    for pos,energy in [((1,4,2),500),((-3,2,-1),350)]:
        ld=bpy.data.lights.new('Key','AREA'); ld.energy=energy; ld.size=4
        l=bpy.data.objects.new('Key',ld); scene.collection.objects.link(l); l.location=pos; l.rotation_euler=(Vector((0,0,-1))-l.location).to_track_quat('-Z','Y').to_euler()
    scene.world=bpy.data.worlds.new('PreviewWorld'); scene.world.use_nodes=True
    next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND').inputs['Color'].default_value=(0.04,0.055,0.075,1)
    scene.render.engine='CYCLES'; scene.cycles.samples=16; scene.render.resolution_x=960; scene.render.resolution_y=540; scene.render.resolution_percentage=100
    clips=json.load(open(os.path.join(ROOT,key+'_Clips.json')))
    rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
    for clip,index in frames:
        for b in rig.pose.bones: b.matrix=matrix(clips[clip]['frames'][index][b.name])@rest[b.name]; bpy.context.view_layer.update()
        scene.render.filepath=os.path.join(ROOT,key+'_'+clip+'_Check.png'); bpy.ops.render.render(write_still=True)
