import bpy, math
from pathlib import Path
from mathutils import Vector
root=Path(r'C:\Roblox\ZombilkaFPS\assets\zombies')
bpy.ops.wm.open_mainfile(filepath=str(root/'Zombies_Prepared.blend'))
scene=bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.samples=16
scene.render.resolution_x=1400
scene.render.resolution_y=650
scene.render.resolution_percentage=100
if not scene.world:
    scene.world=bpy.data.worlds.new('PreviewWorld')
scene.world.color=(0.3,0.3,0.3)
camera_data=bpy.data.cameras.new('PreviewCamera')
camera=bpy.data.objects.new('PreviewCamera',camera_data)
scene.collection.objects.link(camera)
camera.location=(4.8,-14,7)
target=Vector((4.8,1.5,0.9))
camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
camera_data.type='ORTHO'
camera_data.ortho_scale=13
scene.camera=camera
for loc,power,size in [((3,-5,8),1700,10),((6,6,7),1300,8)]:
    data=bpy.data.lights.new('PreviewLight','AREA')
    obj=bpy.data.objects.new('PreviewLight',data)
    scene.collection.objects.link(obj)
    obj.location=loc
    obj.rotation_euler=(target-obj.location).to_track_quat('-Z','Y').to_euler()
    data.energy=power
    data.shape='DISK'
    data.size=size
scene.render.filepath=str(root/'Zombies_Preview.png')
bpy.ops.render.render(write_still=True)
