import bpy, math, json
from pathlib import Path
from mathutils import Vector

OUT=Path(r'C:\Roblox\ZombilkaFPS\assets\environment\office')
(OUT/'exports').mkdir(parents=True,exist_ok=True)
scene=bpy.data.scenes.new('OfficeReferenceKit')
bpy.context.window.scene=scene
colors=[('Charcoal',(0.075,.085,.095)),('Steel',(.26,.29,.32)),('Grey',(.48,.51,.53)),('Ivory',(.75,.78,.77)),('Teal',(.13,.27,.30)),('Wood',(.48,.32,.20)),('Paper',(.93,.92,.82)),('Blue',(.035,.22,.60)),('Red',(.58,.065,.06)),('Green',(.20,.42,.08)),('Yellow',(.88,.65,.06)),('Glass',(.22,.36,.41)),('Cork',(.46,.33,.22)),('LeafLight',(.36,.60,.12)),('Screen',(.035,.065,.085)),('Cardboard',(.56,.40,.21))]
materials=[]
for name,c in colors:
 m=bpy.data.materials.new('Office_'+name);m.diffuse_color=(*c,1);m.use_nodes=True
 p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=.8
 materials.append(m)
pieces=[];assets=[]
def finish(o,label,mat):
 o.name=label;o.data.materials.append(materials[mat]);pieces.append(o);return o
def box(label,p,s,mat=2,bevel=.008):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.scale=s
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  b=o.modifiers.new('Small edge bevel','BEVEL');b.width=bevel;b.segments=1
  bpy.ops.object.modifier_apply(modifier=b.name)
 return finish(o,label,mat)
def cyl(label,p,r,h,mat=2,n=12,rot=None):
 bpy.ops.mesh.primitive_cylinder_add(vertices=n,radius=r,depth=h,location=p,rotation=rot or (0,0,0));return finish(bpy.context.object,label,mat)
def rod(label,a,b,r,mat=1,n=8):
 a=Vector(a);b=Vector(b);o=cyl(label,(a+b)/2,r,(b-a).length,mat,n);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def asset(name):
 global pieces
 bpy.ops.object.select_all(action='DESELECT')
 for o in pieces:o.select_set(True)
 bpy.context.view_layer.objects.active=pieces[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');assets.append(o);pieces=[];return o
def legs(w,d,h,mat=1):
 for x in [-w/2+.06,w/2-.06]:
  for y in [-d/2+.06,d/2-.06]:box('Leg',(x,y,h/2),(.065,.065,h),mat)
def monitor(x=0,z=.0):
 box('Base',(x,0,z+.025),(.30,.22,.05),0);box('Stem',(x,.025,z+.15),(.065,.06,.24),1)
 box('Bezel',(x,.025,z+.41),(.69,.065,.43),0,.016);box('Display',(x,-.011,z+.41),(.63,.008,.365),14,.002)
def chair(office=False):
 box('Seat',(0,0,.47),(.48,.48,.11),1 if office else 4,.035)
 box('Back',(0,.21,.82),(.48,.09,.58),1 if office else 4,.045)
 if office:
  cyl('Piston',(0,0,.26),.04,.34,1)
  for i in range(5):
   a=i*math.tau/5;x=.33*math.cos(a);y=.33*math.sin(a)
   rod('Spoke',(0,0,.12),(x,y,.10),.026);cyl('Castor',(x,y,.07),.047,.05,0,10,(math.pi/2,0,a))
 else:legs(.47,.46,.43)
 for x in [-.28,.28]:
  box('Arm',(x,0,.65),(.045,.43,.045),1);box('ArmSupport',(x,.13,.56),(.035,.035,.19),1)
def drawers(w,d,h,count=3,mat=2):
 box('Case',(0,0,h/2),(w,d,h),mat)
 for i in range(count):
  z=(i+.5)*h/count;box('Drawer',(0,-d/2-.012,z),(w-.045,.025,h/count-.024),mat)
  box('Handle',(0,-d/2-.038,z+.05),(w*.28,.026,.025),1)
def desk(w=1.6,d=.75):
 box('Top',(0,0,.77),(w,d,.065),3,.013)
 for x in [-w/2+.05,w/2-.05]:box('SideLeg',(x,0,.37),(.06,d-.06,.74),2)
 box('Modesty',(0,d*.32,.49),(w-.12,.035,.40),2)
def frame(w,h,mat=3):
 box('Panel',(0,0,h/2),(w,.06,h),mat)
 for x in [-w/2,w/2]:box('Frame',(x,-.025,h/2),(.035,.05,h+.04),2)
 for z in [0,h]:box('Frame',(0,-.025,z),(w+.035,.05,.035),2)
def cabinet(w=.9,h=1.7,wood=False):
 box('Case',(0,0,h/2),(w,.45,h),2)
 for x in [-w/4,w/4]:
  box('Door',(x,-.24,h/2),(w/2-.02,.035,h-.04),3)
  box('Handle',(x+(-1 if x>0 else 1)*w*.17,-.27,h*.47),(.025,.035,.19),1)
 if wood:box('WoodTop',(0,0,h+.035),(w+.05,.50,.065),5)
def plant(h=1.2):
 bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=h*.12,radius2=h*.16,depth=h*.3,location=(0,0,h*.15));finish(bpy.context.object,'Pot',3)
 for i in range(9):
  a=i*2.4;z=h*(.38+.052*i);end=Vector((math.cos(a)*h*.27,math.sin(a)*h*.27,z+h*.20))
  rod('Stem',(0,0,h*.25),end,.012*h,9)
  root=Vector((0,0,z));side=Vector((-math.sin(a),math.cos(a),0))*h*.085
  mid=(root+end)/2+Vector((0,0,h*.09));verts=[root,mid+side,end,mid-side,mid+Vector((0,0,h*.03))]
  mesh=bpy.data.meshes.new('Leaf');mesh.from_pydata(verts,[],[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(0,3,2,1)]);o=bpy.data.objects.new('Leaf',mesh);scene.collection.objects.link(o);finish(o,'Leaf',9 if i%2 else 13)

desk();asset('OfficeDesk')
desk();start=len(pieces);drawers(.40,.62,.69)
for o in pieces[start:]:o.location.x+=.52
monitor(-.20,.81);asset('DeskWorkstation')
desk(2,.85);monitor(-.43,.82);monitor(.38,.82);asset('DualMonitorDesk')
desk(2.4,1.0);asset('MeetingTable')
cyl('Top',(0,0,.76),.60,.065,3,32);cyl('Pedestal',(0,0,.38),.07,.70,1);cyl('Base',(0,0,.04),.31,.065,1,16);asset('RoundTable')
chair();asset('VisitorChair');chair(True);asset('OfficeChair')
for x in [-.73,.73]:box('Foot',(x,0,.065),(.09,.65,.13),1)
box('Base',(0,0,.27),(1.65,.78,.33),1,.04)
for x in [-.42,.42]:box('Cushion',(x,-.04,.48),(.80,.65,.17),2,.05);box('Back',(x,.29,.78),(.80,.18,.60),2,.045)
for x in [-.88,.88]:box('Arm',(x,0,.51),(.17,.80,.60),1,.04)
asset('TwoSeatSofa')
box('Top',(0,0,.43),(1.15,.60,.05),5);legs(1.1,.56,.40);box('Shelf',(0,0,.13),(1.03,.48,.045),1);asset('CoffeeTable')
box('Body',(0,0,.54),(2.0,.65,1.08),3)
for x in [-1.03,1.03]:box('Side',(x,.06,.56),(.09,.8,1.12),2);box('SideCounter',(x,.05,1.16),(.16,.85,.065),5)
box('Counter',(0,-.32,1.16),(2.15,.18,.065),5);box('ToeKick',(0,-.02,.055),(1.96,.60,.11),1);asset('ReceptionDesk')
for w,h,name in [(1.5,1.6,'TallPartition'),(1.5,1.05,'DeskPartition')]:
 frame(w,h,4)
 for x in [-w/2,w/2]:box('Foot',(x,0,.035),(.12,.40,.07),2)
 asset(name)
cabinet();asset('TallCabinet');cabinet(1,.8,True);asset('LowCabinet')
drawers(.46,.54,1.25,4,1)
for z in [.17,.48,.80,1.11]:box('Label',(0,-.29,z),(.17,.01,.07),6)
asset('FilingCabinet')
box('Case',(0,0,.94),(.43,.45,1.88),2)
for z in [.32,.94,1.56]:
 box('Door',(0,-.24,z),(.39,.025,.59),3);box('Handle',(-.12,-.27,z),(.025,.035,.11),0)
 for dz in [.15,.20,.25]:box('Vent',(.055,-.257,z+dz),(.12,.009,.016),1)
asset('ThreeDoorLocker')
for x in [-.48,.48]:
 for y in [-.20,.20]:box('Upright',(x,y,.83),(.045,.045,1.66),2)
for z in [.08,.60,1.12,1.64]:box('Shelf',(0,0,z),(1,.45,.045),2)
asset('MetalShelf')
for x in [-.48,.48]:box('Side',(x,0,.83),(.065,.37,1.66),1)
box('Back',(0,.17,.83),(.94,.03,1.66),1)
for z in [.045,.57,1.10,1.64]:box('Shelf',(0,0,z),(.94,.37,.05),2)
asset('Bookcase')
box('Cabinet',(0,0,.91),(.6,.70,1.82),1)
box('Front',(0,-.364,.92),(.52,.035,1.65),0)
for z in [.28,.48,.68,.88,1.10,1.32,1.54]:
 box('Unit',(0,-.39,z),(.44,.015,.15),1)
 for x in [-.15,-.10,-.05,0,.05]:box('LED',(x,-.401,z),(.023,.009,.013),7 if z>1 else 9,0)
box('Handle',(.23,-.405,.9),(.025,.035,.35),2);asset('ServerRack')
box('Body',(0,0,.48),(.7,.64,.96),3)
for z in [.17,.39]:box('Drawer',(0,-.33,z),(.61,.024,.20),2);box('Pull',(0,-.35,z),(.17,.025,.023),1)
box('DarkOutput',(0,-.336,.72),(.52,.015,.22),0)
box('Scanner',(0,0,1.01),(.77,.70,.11),3)
o=box('OpenLid',(0,.16,1.25),(.74,.62,.055),2);o.rotation_euler[0]=math.radians(-30)
box('Control',(0,-.25,1.075),(.44,.18,.025),0)
for x in [-.14,-.05,.05,.14]:box('Button',(x,-.26,1.094),(.05,.045,.012),7 if x<0 else 2,0)
for z in [.4,.65]:box('SideTray',(.42,0,z),(.20,.43,.035),2)
asset('Photocopier')
box('Body',(0,0,.16),(.47,.36,.30),1,.025);box('Slot',(0,-.19,.14),(.37,.02,.06),0)
box('PaperTray',(0,-.26,.035),(.38,.23,.025),1);box('Paper',(0,-.25,.054),(.30,.18,.01),6,0);box('Control',(.12,-.05,.318),(.12,.09,.013),0);asset('DesktopPrinter')
box('Case',(0,0,.27),(.36,.32,.54),1,.03);box('TopSlot',(0,-.01,.55),(.27,.035,.012),0);box('Window',(0,-.171,.29),(.21,.01,.25),0);asset('PaperShredder')
box('Body',(0,0,.46),(.34,.34,.92),3,.022);box('Dispenser',(0,-.176,.70),(.24,.016,.28),1)
for x,c in [(-.075,7),(.075,8)]:box('Tap',(x,-.20,.74),(.028,.035,.055),c)
box('DripTray',(0,-.20,.53),(.24,.14,.03),1)
cyl('Bottle',(0,0,1.19),.17,.45,7,12)
for z in [.99,1.20,1.39]:cyl('BottleRidge',(0,0,z),.177,.025,7,12)
asset('WaterCooler')
for name,mat in [('WasteBin',2),('RecycleBin',7)]:
 for x in [-.15,.15]:box('Wall',(x,0,.24),(.025,.32,.46),mat)
 for y in [-.15,.15]:box('Wall',(0,y,.24),(.32,.025,.46),mat)
 box('Bottom',(0,0,.025),(.30,.30,.025),mat)
 for x in [-.16,.16]:box('Rim',(x,0,.48),(.035,.35,.045),mat)
 for y in [-.16,.16]:box('Rim',(0,y,.48),(.35,.035,.045),mat)
 if mat==7:
  for a in [0,2.094,4.189]:
   o=box('RecycleMark',(.065*math.sin(a),-.168,.29+.065*math.cos(a)),(.07,.008,.025),6,0);o.rotation_euler[1]=a
 asset(name)
frame(.9,2.05,5);box('Window',(0,-.036,1.38),(.18,.015,.63),11)
for x in [-.11,.11]:box('WindowTrim',(x,-.049,1.38),(.023,.025,.69),2)
box('Handle',(.30,-.075,.94),(.14,.04,.025),2);asset('OfficeDoor')
frame(1.8,1.2,11);box('Mullion',(0,-.045,.60),(.045,.03,1.2),2);asset('OfficeWindow')
frame(1.6,1.05,3);box('Tray',(0,-.10,.025),(1.5,.14,.035),2)
for x,c in [(.40,8),(.52,7),(.64,0)]:box('Marker',(x,-.10,.055),(.09,.018,.018),c)
asset('Whiteboard')
frame(.8,1.0,12)
for x,z in [(-.19,.65),(.16,.42),(0,.20)]:box('Note',(x,-.04,z),(.15,.01,.19),6);cyl('Pin',(x,-.052,z+.07),.012,.014,8,8,(math.pi/2,0,0))
asset('NoticeBoard')
cyl('Rim',(0,0,.20),.20,.045,1,32,(math.pi/2,0,0));cyl('Face',(0,-.028,.20),.18,.014,6,32,(math.pi/2,0,0))
for i in range(12):
 a=i*math.tau/12;o=box('Tick',(.155*math.sin(a),-.041,.20+.155*math.cos(a)),(.008,.008,.025),0,0);o.rotation_euler[1]=a
rod('Hand',(0,-.05,.20),(-.07,-.05,.26),.006,0);rod('Hand',(0,-.05,.20),(.11,-.05,.26),.005,0);asset('WallClock')
cyl('Tank',(0,0,.29),.09,.49,8);cyl('Band',(0,0,.30),.094,.15,6);cyl('Neck',(0,0,.56),.03,.06,1)
rod('Lever',(-.03,0,.6),(.13,0,.63),.014);rod('Hose',(.05,.02,.58),(.11,.02,.39),.015,0);asset('FireExtinguisher')
plant();asset('LargePlant');plant(.55);asset('SmallPlant')
for x in [-.3,0,.3]:
 plant(.45)
 for o in pieces[-19:]:o.location.x+=x
asset('PlantCluster')
cyl('Base',(0,0,.025),.22,.05,1);cyl('Pole',(0,0,.85),.026,1.65,1)
for i in range(4):
 a=i*math.pi/2;rod('Hook',(0,0,1.53),(.17*math.cos(a),.17*math.sin(a),1.62),.019)
asset('CoatStand')
box('Housing',(0,0,.055),(1.1,.25,.09),1);box('Diffuser',(0,0,.008),(1.03,.20,.012),6)
for x in [-.4,.4]:rod('Suspension',(x,0,.10),(x,0,.55),.005)
asset('HangingLight');box('Housing',(0,0,.04),(.6,.6,.08),2);box('Diffuser',(0,0,.005),(.54,.54,.012),6);asset('CeilingLight')
monitor();asset('Monitor');monitor();
for o in pieces:o.location.x-=.37
monitor(.37);asset('DualMonitor')
box('Tower',(0,0,.24),(.20,.43,.48),1)
for z in [.32,.38]:box('Drive',(0,-.221,z),(.16,.012,.045),0)
cyl('Power',(0,-.23,.10),.012,.01,9,8,(math.pi/2,0,0));asset('ComputerTower')
box('Base',(0,0,.017),(.34,.23,.034),1)
o=box('Display',(0,.097,.14),(.34,.02,.24),0);o.rotation_euler[0]=math.radians(-12)
o=box('Screen',(0,.083,.14),(.30,.006,.20),14);o.rotation_euler[0]=math.radians(-12)
box('Keyboard',(0,-.015,.038),(.29,.13,.005),2,0);asset('Laptop')
box('Body',(0,0,.014),(.45,.15,.028),0)
for row in range(5):
 for col in range(15):box('Key',(-.205+col*.029,-.055+row*.026,.032),(.023,.018,.008),2,.002)
asset('Keyboard');box('Body',(0,0,.023),(.062,.105,.045),1,.016);box('Wheel',(0,0,.049),(.009,.020,.009),0);asset('Mouse')
box('Base',(0,0,.025),(.18,.15,.05),1);rod('Stem',(0,.04,.05),(0,.04,.35),.014);rod('Arm',(0,.04,.35),(0,-.07,.43),.012)
o=box('Shade',(0,-.10,.43),(.16,.12,.05),1);o.rotation_euler[0]=.4;asset('DeskLamp')
for i in range(3):
 z=.025+i*.065;box('Tray',(0,0,z),(.25,.33,.016),1);box('Paper',(0,0,z+.012),(.21,.29,.009),6,0)
 for x in [-.13,.13]:box('Side',(x,.02,z+.025),(.015,.29,.05),1)
 box('Back',(0,.16,z+.025),(.25,.015,.05),1)
asset('PaperTrayStack')
for i,c in enumerate([7,0,8]):
 x=(i-1)*.065;box('Binder',(x,0,.15),(.058,.24,.30),c);box('Label',(x,-.126,.055),(.022,.006,.06),6,0)
asset('BinderSet')
for name,c in [('CardboardBox',15),('ArchiveBox',3),('DarkStorageBox',1)]:
 box('Box',(0,0,.16),(.40,.34,.32),c);box('Lid',(0,0,.325),(.42,.36,.032),c)
 box('Handle',(0,-.177,.23),(.12,.009,.027),0)
 if c==15:box('Tape',(0,0,.346),(.045,.36,.003),5,0)
 asset(name)
cyl('Cup',(0,0,.05),.035,.10,3);cyl('Lid',(0,0,.104),.039,.013,6);cyl('Sleeve',(0,0,.05),.036,.045,5);asset('CoffeeCup')
cyl('Holder',(0,0,.046),.045,.09,1)
for i,c in enumerate([8,7,10]):rod('Pencil',((i-1)*.025,0,.04),((i-1)*.025,.008,.17),.006,c,6)
asset('PenHolder')
box('Base',(0,0,.012),(.10,.035,.023),1);o=box('Top',(0,0,.044),(.10,.033,.027),0);o.rotation_euler[1]=-.13;asset('Stapler')
box('Stack',(0,0,.01),(.08,.08,.02),10);asset('StickyNotes')
box('Board',(0,0,.008),(.23,.32,.016),5);box('Paper',(0,0,.019),(.21,.28,.004),6,0);box('Clip',(0,.13,.025),(.075,.027,.008),2);asset('Clipboard')
box('Page',(0,0,.12),(.16,.025,.23),6)
for x in [-.06,-.035,-.01,.015,.04,.065]:box('Grid',(x,-.014,.12),(.001,.003,.17),2,0)
for z in [.05,.08,.11,.14,.17,.20]:box('Grid',(0,-.014,z),(.14,.003,.001),2,0)
rod('Stand',(-.07,.06,0),(-.07,0,.22),.007);rod('Stand',(.07,.06,0),(.07,0,.22),.007);asset('DeskCalendar')

# One palette texture, single UV channel; no baking or external dependencies.
image=bpy.data.images.new('OfficePalette',width=len(colors)*32,height=32)
pixels=[]
for y in range(32):
 for i,(_,c) in enumerate(colors):
  for x in range(32):pixels.extend((*c,1))
image.pixels=pixels;image.filepath_raw=str(OUT/'OfficePalette.png');image.file_format='PNG';image.save()
palette=bpy.data.materials.new('OfficePaletteMaterial');palette.use_nodes=True
nodes=palette.node_tree.nodes;shader=next(n for n in nodes if n.type=='BSDF_PRINCIPLED');shader.inputs['Roughness'].default_value=.8
tex=nodes.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Closest';palette.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
manifest=[]
for idx,o in enumerate(assets):
 for layer in list(o.data.uv_layers):o.data.uv_layers.remove(layer)
 uv=o.data.uv_layers.new(name='PaletteUV')
 uv.active_render=True
 for poly in o.data.polygons:
  old=o.data.materials[poly.material_index];ci=materials.index(old)
  for li in poly.loop_indices:uv.data[li].uv=((ci+.5)/len(colors),.5)
  poly.material_index=0
 o.data.materials.clear();o.data.materials.append(palette)
 o.data.calc_loop_triangles();dims=[round(v,4) for v in o.dimensions]
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 bpy.ops.export_scene.fbx(filepath=str(OUT/'exports'/f'{o.name}.fbx'),use_selection=True,add_leaf_bones=False,bake_anim=False,path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y')
 manifest.append({'name':o.name,'triangles':len(o.data.loop_triangles),'size_m':dims,'file':f'exports/{o.name}.fbx'})
 o.location=((idx%8)*3,(idx//8)*3,0)
bpy.ops.object.select_all(action='DESELECT')
for o in assets:o.select_set(True)
bpy.context.view_layer.objects.active=assets[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/'exports'/'OfficeKit_All.fbx'),use_selection=True,add_leaf_bones=False,bake_anim=False,path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y')
(OUT/'Manifest.json').write_text(json.dumps({'assets':manifest,'count':len(assets),'units':'metres','palette':'OfficePalette.png'},indent=2),encoding='utf-8')
scene.unit_settings.system='METRIC'
scene.world=bpy.data.worlds.new('OfficeWorld');scene.world.use_nodes=True
bg=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND');bg.inputs[0].default_value=(.065,.075,.09,1);bg.inputs[1].default_value=.4
bpy.ops.object.camera_add(location=(31,-29,30));cam=bpy.context.object;cam.name='OfficeKitPreviewCamera';cam.rotation_euler=(Vector((10.5,9,0.5))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=33;scene.camera=cam
for loc,power,size in [((7,-5,15),5000,10),((20,10,14),4000,10),((-5,15,10),3000,8)]:
 bpy.ops.object.light_add(type='AREA',location=loc);light=bpy.context.object;light.data.energy=power;light.data.shape='DISK';light.data.size=size;light.rotation_euler=(Vector((10,9,0))-light.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=1600;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
try:scene.render.engine='CYCLES';scene.cycles.samples=24
except TypeError:pass
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'OfficeKit_Preview.png')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'OfficeKit.blend'))
print(json.dumps({'count':len(assets),'triangles':sum(a['triangles'] for a in manifest),'saved':str(OUT)},indent=2))
