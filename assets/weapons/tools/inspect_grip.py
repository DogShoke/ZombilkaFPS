import bpy,json
bpy.ops.wm.open_mainfile(filepath=r'C:\Roblox\ZombilkaFPS\assets\weapons\Mossberg_GripAnimations.blend')
rig=bpy.data.objects['Armature']; mesh=bpy.data.objects['ArmModel']
bpy.context.view_layer.update(); evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get()).data
out={}
for side in ['.L','.R.001']:
    name='Hand'+side; group=mesh.vertex_groups[name].index
    points=[mesh.matrix_world@evaluated.vertices[v.index].co for v in mesh.data.vertices if any(g.group==group and g.weight>.5 for g in v.groups)]
    out[name]={'wrist':list(rig.pose.bones[name].matrix.translation),'center':[sum(p[i] for p in points)/len(points) for i in range(3)],'min':[min(p[i] for p in points) for i in range(3)],'max':[max(p[i] for p in points) for i in range(3)]}
print(json.dumps(out),flush=True)
