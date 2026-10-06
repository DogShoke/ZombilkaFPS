import bpy, math, json
from pathlib import Path
base=Path(r'C:\Roblox\ZombilkaFPS\assets\environment\tools\build_coffee_spawner.py').read_text(encoding='utf-8').split('# Angular commercial')[0]
exec(compile(base,'palette_helpers','exec'))
scene.name='Zombilka_ArenaKit'
assets=[]
def asset(name):
 global pieces
 o=join_palette(pieces,name);pieces=[];assets.append(o);return o
# Compact car with a shaped roof, readable windows, grille and individual wheels.
box('Chassis',(0,0,.53),(1.85,4,.6),1,.13)
box('Hood',(0,-1.35,.96),(1.8,1.22,.24),2,.09)
box('Boot',(0,1.5,.9),(1.8,.75,.26),2,.07)
box('Roof',(0,.2,1.6),(1.55,1.9,.18),2,.08)
for x in [-.72,.72]:
 for y in [-.78,1.2]:box('Pillar',(x,y,1.25),(.14,.13,.7),1,.025)
 box('SideGlass',(x,.18,1.29),(.025,1.72,.45),0,.01)
box('FrontGlass',(0,-.82,1.28),(1.38,.06,.49),0,.01)
box('RearGlass',(0,1.21,1.28),(1.38,.06,.49),0,.01)
for y in [-1.27,1.3]:
 for x in [-.92,.92]:
  bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.42,depth=.18,location=(x,y,.42),rotation=(0,math.pi/2,0));finish(bpy.context.object,'Tyre',8)
  bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.23,depth=.19,location=(x,y,.42),rotation=(0,math.pi/2,0));finish(bpy.context.object,'Hub',3)
for x in [-.58,.58]:box('Headlight',(x,-2.035,.66),(.42,.035,.19),4,.01);box('RearLight',(x,2.035,.66),(.42,.035,.17),6,.01)
box('Grille',(0,-2.035,.56),(.52,.035,.22),0,.01)
for x in [-.8,.8]:box('Mirror',(x,-.5,1.36),(.25,.26,.11),2,.03)
car=asset('ArenaCar')
# Corrugated container with reinforced corners and shipping labels.
box('ContainerBody',(0,0,1.05),(2.8,4.8,2.1),1,.06)
for x in [-1.43,1.43]:
 for y in [-2.36,2.36]:box('Corner',(x,y,1.05),(.13,.13,2.16),3,.02)
 for y in [-2,-1.5,-1,-.5,0,.5,1,1.5,2]:box('Rib',(x,y,1.05),(.07,.075,1.8),2,.01)
for x in [-.9,.9]:box('DoorLock',(x,-2.43,1.1),(.07,.07,1.8),3,.01)
text('CARGO',(0,-2.445,1.28),.25,4);text('09',(0,-2.445,.66),.3,3)
container=asset('ArenaContainer')
# Desk bank: actual legs, top, monitor, office partition, cable housing.
for x in [-.95,.95]:
 box('DeskTop',(x,0,.88),(1.76,1.08,.1),3,.025)
 for dx in [-.68,.68]:box('DeskLeg',(x+dx,0,.44),(.075,.88,.82),1,.01)
 box('Monitor',(x,-.24,1.28),(.69,.08,.45),0,.025)
 box('MonitorScreen',(x,-.29,1.28),(.57,.015,.34),5,.005)
 box('Keyboard',(x,.28,.955),(.59,.23,.035),0,.01)
box('Partition',(0,-.58,1.07),(3.74,.12,1.02),2,.04)
desk=asset('ArenaDeskBank')
for x in [-1.4,1.4]:
 for y in [-.5,.5]:box('RackUpright',(x,y,1.3),(.12,.12,2.6),3,.015)
for z in [.13,1.1,2.1]:
 box('Shelf',(0,0,z),(2.95,1.2,.12),1,.025)
 for x in [-.92,0,.92]:box('Box',(x,0,z+.35),(.8,.85,.61),2 if z>1 else 9,.03)
rack=asset('ArenaRack')
box('BarrierBody',(0,0,.56),(3.8,.54,1.12),2,.07)
for x in [-1.35,1.35]:box('BarrierFoot',(x,0,.13),(.45,1.15,.26),1,.025)
for x in [-1.45,-.75,0,.75,1.45]:
 o=box('Hazard',(x,-.291,.6),(.25,.025,.57),3,.005);o.rotation_euler[1]=-.25
barrier=asset('ArenaBarrier')
box('Bench',(0,0,.64),(3.5,1.45,1.28),2,.06)
box('Worktop',(0,0,1.31),(3.62,1.55,.12),0,.02)
for x in [-1.14,0,1.14]:
 box('SampleHousing',(x,-.16,1.82),(.58,.64,.9),1,.025)
 box('SampleWindow',(x,-.49,1.86),(.42,.02,.55),5,.01)
 box('Handle',(x,.78,.79),(.26,.09,.08),3,.01)
lab=asset('ArenaLabBank')
# Bring copies of coffee kit meshes into the export scene; keep authored originals.
for name in ['CoffeeSpawner','GroundCracks','GroundDebris']:
 original=bpy.data.objects[name];copy=original.copy();copy.data=original.data.copy();copy.name=name+'_Export';copy.hide_render=False;scene.collection.objects.link(copy);assets.append(copy)
bpy.ops.object.select_all(action='DESELECT')
for o in assets:o.select_set(True)
bpy.context.view_layer.objects.active=assets[0]
bpy.ops.export_scene.fbx(filepath=str(ROOT/'exports'/'Zombilka_ArenaKit.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',add_leaf_bones=False,bake_anim=False,path_mode='COPY',embed_textures=True)
manifest=[{'Name':o.name,'Triangles':sum(len(p.vertices)-2 for p in o.data.polygons),'Dimensions':list(o.dimensions),'UVMaps':[u.name for u in o.data.uv_layers]}for o in assets]
(ROOT/'ArenaKit_Manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'ArenaKit.blend'))
bpy.context.window.scene=bpy.data.scenes['Zombilka_CoffeeSpawner']
print(json.dumps(manifest))
