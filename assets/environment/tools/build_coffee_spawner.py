import bpy, math, random, json
from mathutils import Vector
from pathlib import Path

ROOT=Path(r'C:\Roblox\ZombilkaFPS\assets\environment')
(ROOT/'exports').mkdir(parents=True,exist_ok=True)
scene=bpy.data.scenes.new('Zombilka_CoffeeSpawner')
bpy.context.window.scene=scene
scene.render.engine='BLENDER_EEVEE'
scene.render.resolution_x=1100;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('CoffeeWorld');scene.world.use_nodes=True
scene.world.node_tree.nodes.get('Background').inputs[0].default_value=(.045,.06,.085,1)
scene.world.node_tree.nodes.get('Background').inputs[1].default_value=.5
colors=[(.035,.055,.07,1),(.12,.19,.22,1),(.31,.44,.45,1),(.71,.55,.29,1),(.9,.85,.68,1),(.18,.68,.53,1),(.56,.035,.09,1),(.26,.035,.065,1),(.055,.07,.075,1),(.65,.22,.08,1)]
materials=[]
for i,c in enumerate(colors):
 m=bpy.data.materials.new('CoffeePalette_%02d'%i);m.diffuse_color=c;m.use_nodes=True
 n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');n.inputs['Base Color'].default_value=c;n.inputs['Roughness'].default_value=.62
 materials.append(m)
pieces=[]
def finish(o,name,color,bevel=0):
 o.name=name;o.data.materials.clear();o.data.materials.append(materials[color]);pieces.append(o)
 if bevel:
  mod=o.modifiers.new('FacetedEdges','BEVEL');mod.width=bevel;mod.segments=1
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def box(name,loc,size,c,bev=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,name,c,bev)
def sphere(name,loc,size,c):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=loc);o=bpy.context.object;o.scale=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,name,c)
def tube(name,pts,r,c):
 curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.resolution_u=1;curve.bevel_depth=r;curve.bevel_resolution=0;curve.resolution_u=1
 s=curve.splines.new('POLY');s.points.add(len(pts)-1)
 for p,v in zip(s.points,pts):p.co=(*v,1)
 o=bpy.data.objects.new(name,curve);scene.collection.objects.link(o);bpy.context.view_layer.objects.active=o;o.select_set(True)
 bpy.ops.object.convert(target='MESH');return finish(bpy.context.object,name,c)
def text(label,loc,size,c):
 bpy.ops.object.text_add(location=loc,rotation=(math.pi/2,0,0));o=bpy.context.object;o.data.body=label;o.data.size=size;o.data.align_x='CENTER';o.data.extrude=.004
 bpy.ops.object.convert(target='MESH');return finish(bpy.context.object,label,c)
def join_palette(items,name):
 bpy.ops.object.select_all(action='DESELECT')
 for o in items:o.select_set(True)
 bpy.context.view_layer.objects.active=items[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 uv=o.data.uv_layers.new(name='BaseColorUV') if not o.data.uv_layers else o.data.uv_layers[0]
 for poly in o.data.polygons:
  mat=o.data.materials[poly.material_index];idx=int(mat.name.split('_')[-1].split('.')[0])
  for li in poly.loop_indices:uv.data[li].uv=((idx+.5)/len(colors),.5)
 o.data.materials.clear();o.data.materials.append(texmat)
 for p in o.data.polygons:p.material_index=0;p.use_smooth=False
 # Put the origin on the floor without moving the model.
 scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 return o
image=bpy.data.images.new('ArenaPalette',width=500,height=50,alpha=False)
image.colorspace_settings.name='sRGB'
pixels=[]
for y in range(50):
 for x in range(500):pixels.extend(colors[min(9,x//50)])
image.pixels.foreach_set(pixels);image.filepath_raw=str(ROOT/'ArenaPalette.png');image.file_format='PNG';image.save()
texmat=bpy.data.materials.new('Arena_BaseColor');texmat.use_nodes=True
bsdf=next(n for n in texmat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');node=texmat.node_tree.nodes.new('ShaderNodeTexImage');node.image=image;texmat.node_tree.links.new(node.outputs['Color'],bsdf.inputs['Base Color']);bsdf.inputs['Roughness'].default_value=.65

# Angular commercial coffee dispenser, front faces -Y.
box('Plinth',(0,0,.15),(2.25,1.55,.3),0,.08)
box('Body',(0,.15,1.85),(2.0,1.15,3.4),1,.1)
box('TopCowl',(0,-.08,3.55),(2.25,1.5,.46),0,.08)
box('GoldHeader',(0,-.865,3.46),(1.92,.07,.27),3)
text('COFFEE',(0,-.91,3.36),.24,4)
box('CrackedPanel',(-.5,-.56,2.75),(.88,.2,.98),0,.04)
box('Display',(-.5,-.675,2.91),(.66,.03,.48),5,.01)
text('BREW',(-.5,-.71,2.83),.12,0)
for i in range(3):box('MenuButton',(.45,-.54,2.8-i*.25),(.43,.18,.15),3 if i==0 else 2,.025)
box('BrewWellBack',(0,-.46,1.72),(1.62,.02,1.28),8,0)
box('WellLeft',(-.88,-.72,1.76),(.22,.66,1.52),0)
box('WellRight',(.88,-.72,1.76),(.22,.66,1.52),0)
box('WellRoof',(0,-.72,2.43),(1.72,.68,.18),2)
box('WellTray',(0,-.76,1.09),(1.95,.84,.16),2)
for x in [-.7,-.45,-.2,.05,.3,.55,.8]:box('TrayGrate',(x,-.84,1.183),(.065,.5,.03),0,0)
box('LowerPanel',(0,-.535,.57),(1.82,.13,.78),0,.06)
text('MOKA  09',(0,-.62,.57),.15,3)
for x in [-.82,.82]:
 for z in [.35,3.2]:sphere('Bolt',(x,-.635,z),(.045,.018,.045),3)
# The infection breaks the familiar silhouette instead of hiding the machine.
sphere('CorruptedCore',(.07,-.73,1.8),(.5,.25,.49),7)
sphere('LuminousHeart',(.07,-1.02,1.86),(.3,.11,.31),5)
for i in range(7):
 a=i*math.tau/7;sphere('CoreRim',(.07+math.cos(a)*.46,-.95,1.8+math.sin(a)*.43),(.16,.12,.15),6)
for j in range(5):
 x=-.7+j*.33;tube('TornTube',[(x,-.64,2.35),(x*.9,-.99,2.19),(x*.7,-1.03,1.97)],.055,6 if j%2 else 3)
tube('RightVein',[(.63,-.7,1.2),(1.04,-.74,1.8),(1.08,-.45,2.48),(.88,-.58,2.75)],.095,7)
tube('LeftVein',[(-.45,-.74,1.16),(-1.06,-.53,.9),(-1.08,-.16,.4),(-1.45,-.42,.13)],.1,6)
tube('FloorRoot',[(.37,-.8,1.16),(.75,-.9,.45),(1.3,-1.0,.12),(1.58,-.7,.1)],.09,7)
for i in range(3):sphere('Growth',(1.05,-.32,1.0+i*.36),(.21,.23,.3),7 if i%2 else 6)
# Shattered inspection door and leaked coffee.
flap=box('BrokenServiceDoor',(-1.06,-.6,1.34),(.56,.08,1.16),2,.04);flap.rotation_euler[2]=-.48
for i in range(4):box('DangerStripe',(.45,-.628,.38+i*.09),(.49,.025,.034),3,0).rotation_euler[1]=-.2
for i in range(8):
 a=i*math.tau/8;sphere('CoffeeCrust',(math.cos(a)*1.2,math.sin(a)*.83,.035),(.31,.27,.04),7 if i%3==0 else 9)
machine=join_palette(pieces,'CoffeeSpawner');pieces=[]

# Reusable cracked ground lip: dark cavity, jagged concrete and displaced chunks.
sphere('Hole',(0,0,.025),(1.15,1.04,.035),8)
random.seed(119)
for i in range(13):
 a=i*math.tau/13;r=1.04+random.uniform(-.12,.12)
 o=box('BrokenConcrete',(math.cos(a)*r,math.sin(a)*r,.09),(.52,.35,.18),2,.025);o.rotation_euler=(random.uniform(-.16,.16),random.uniform(-.16,.16),a)
for i in range(5):
 a=i*1.4;tube('Crack',[(math.cos(a)*.8,math.sin(a)*.8,.021),(math.cos(a+.1)*1.35,math.sin(a+.1)*1.35,.021),(math.cos(a)*1.7,math.sin(a)*1.7,.021)],.027,8)
crack=join_palette(pieces,'GroundCracks');pieces=[]
for i in range(5):sphere('Debris',(math.sin(i*2)*.3,math.cos(i*2)*.3,.08),(.13,.11,.08),2)
debris=join_palette(pieces,'GroundDebris');debris.hide_render=True;crack.hide_render=True
for o in [machine,crack,debris]:o['ArenaAsset']=True
# Export only authored assets, keep the original scene untouched.
bpy.ops.object.select_all(action='DESELECT')
for o in [machine,crack,debris]:o.select_set(True)
bpy.context.view_layer.objects.active=machine
bpy.ops.export_scene.fbx(filepath=str(ROOT/'exports'/'CoffeeSpawner_Kit.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',add_leaf_bones=False,bake_anim=False,path_mode='COPY',embed_textures=True,use_mesh_modifiers=True)
# Presentation scene is separate from the export.
box('DisplayFloor',(0,0,-.15),(200,200,.2),0,0)
for loc,power,size,color in [((4,-5,7),1700,5,(.75,.86,1)),((-4,-3,4),1200,4,(1,.66,.36)),((2,4,6),1900,4,(.22,1,.68))]:
 bpy.ops.object.light_add(type='AREA',location=loc);l=bpy.context.object;l.data.energy=power;l.data.shape='DISK';l.data.size=size;l.data.color=color;l.rotation_euler=(Vector((0,0,1.8))-l.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.light_add(type='POINT',location=(.05,-1.18,1.9));bpy.context.object.data.energy=32;bpy.context.object.data.color=(.12,1,.53)
bpy.ops.object.camera_add(location=(5.7,-9.2,5.3));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1.9))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=5.35;scene.camera=cam
scene.render.filepath=str(ROOT/'CoffeeSpawner_Preview.png')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'CoffeeSpawner.blend'))
bpy.ops.render.render(write_still=True)
manifest=[]
for o in [machine,crack,debris]:manifest.append({'Name':o.name,'Vertices':len(o.data.vertices),'Triangles':sum(len(p.vertices)-2 for p in o.data.polygons),'UVMaps':[u.name for u in o.data.uv_layers],'Dimensions':list(o.dimensions),'BlenderForward':'-Y','RobloxTargetHeight':8 if o==machine else None})
(ROOT/'CoffeeSpawner_Manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps(manifest))
