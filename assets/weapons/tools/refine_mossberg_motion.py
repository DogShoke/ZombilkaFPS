import bpy, os, json, math
from mathutils import Matrix, Vector
ROOT=r'C:\Roblox\ZombilkaFPS\assets\weapons'
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT,'Mossberg_Prepared.blend'))
rig=bpy.data.objects['Armature']; rig.animation_data_clear()
rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
for b in rig.pose.bones: b.rotation_mode='QUATERNION'
left=rest['FR'].translation+Vector((-.04,-.254,0))
right=Vector((.07,-.12,.10))
def fit(side,wrist):
    suffix='.L' if side=='L' else '.R.001'
    upper,lower,hand=[rig.pose.bones[n+suffix] for n in ['UpperArm','LowerArm','Hand']]
    a,b,c=[rest[o.name].translation for o in [upper,lower,hand]]
    l1,l2=(b-a).length,(c-b).length
    axis=(wrist-a).normalized(); distance=min((wrist-a).length,l1+l2-.002)
    along=(l1*l1-l2*l2+distance*distance)/(2*distance)
    bend=Vector((-1 if side=='L' else 1,-1,0)); bend=(bend-axis*bend.dot(axis)).normalized()
    elbow=a+axis*along+bend*math.sqrt(max(0,l1*l1-along*along))
    q1=(b-a).rotation_difference(elbow-a).to_matrix().to_4x4()
    q2=(c-b).rotation_difference(wrist-elbow).to_matrix().to_4x4()
    upper.matrix=Matrix.Translation(a)@q1@Matrix.Translation(-a)@rest[upper.name]
    bpy.context.view_layer.update()
    lower.matrix=Matrix.Translation(elbow)@q2@Matrix.Translation(-b)@rest[lower.name]
    bpy.context.view_layer.update()
    rotation=Matrix.Rotation(math.radians(-90 if side=='L' else 90),4,'Z')
    if side=='R': rotation=Matrix.Rotation(math.radians(-20),4,'X')@rotation
    orientation=rotation@rest[hand.name].to_3x3().to_4x4()
    hand.matrix=Matrix.Translation(wrist)@orientation
    bpy.context.view_layer.update()
def row12(m):
    return [round(m[0][3],7),round(m[1][3],7),round(m[2][3],7)]+[round(m[r][c],7) for r in range(3) for c in range(3)]
clips={}
for name,count in [('Idle',1),('Shoot',24),('ReloadShell',32)]:
    frames=[]
    for i in range(count+1):
        for b in rig.pose.bones: b.matrix_basis=Matrix.Identity(4)
        target=left.copy()
        if name=='Shoot':
            t=i/30; pump=.32*math.sin(math.pi*max(0,min(1,(t-.12)/.48)))
            rig.pose.bones['FR'].matrix=Matrix.Translation((0,0,pump))@rest['FR']
            bpy.context.view_layer.update(); target.z+=pump
        elif name=='ReloadShell':
            t=i/count; blend=min(1,t/.25,(1-t)/.28)
            phase=max(0,min(1,(t-.25)/.47))
            loading=Vector((-.04,-.44,.12+.10*math.sin(math.pi*phase)))
            target=left.lerp(loading,blend)
        fit('L',target); fit('R',right)
        # Fingers inherit the fitted wrist pose.
        frames.append({b.name:row12(b.matrix@rest[b.name].inverted()) for b in rig.pose.bones})
        for b in rig.pose.bones:
            b.keyframe_insert('location',frame=i); b.keyframe_insert('rotation_quaternion',frame=i); b.keyframe_insert('scale',frame=i)
    rig.animation_data.action.name='Mossberg_'+name+'_Refined'; rig.animation_data.action.use_fake_user=True
    rig.animation_data_clear(); clips[name]={'fps':30,'frames':frames}
with open(os.path.join(ROOT,'Mossberg_Clips.json'),'w') as f: json.dump(clips,f,separators=(',',':'))
# Retain the held pose and editable actions in a separate working copy.
for b in rig.pose.bones: b.matrix_basis=Matrix.Identity(4)
fit('L',left); fit('R',right)
# Fingers inherit the fitted wrist pose.
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'Mossberg_GripAnimations.blend'))
print('Refined grip and one-shell reload:',{k:len(v['frames']) for k,v in clips.items()},flush=True)





