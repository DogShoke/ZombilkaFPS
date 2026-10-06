import bpy, math, json
from pathlib import Path
from mathutils import Vector
BASE=Path(r'C:\Roblox\ZombilkaFPS\assets\environment\office')
source=(BASE/'tools'/'build_office_kit.py').read_text(encoding='utf-8')
exec(compile(source.split("desk();asset('OfficeDesk')")[0],'office_helpers','exec'))
OUT=BASE/'zones';(OUT/'exports').mkdir(parents=True,exist_ok=True)
scene.name='OfficeZoneModules'
categories={}
def save(name,zone):
 o=asset(name);categories[name]=zone;return o
def shift(start,x=0,y=0,angle=0):
 for o in pieces[start:]:
  v=o.location.copy();o.location=(v.x*math.cos(angle)-v.y*math.sin(angle)+x,v.x*math.sin(angle)+v.y*math.cos(angle)+y,v.z)
  o.rotation_euler.z+=angle
def panel(w,h):
 frame(w,h,4)
 for x in [-w/2,w/2]:box('Foot',(x,0,.03),(.14,.44,.06),1)
for w,h,name in [(1.2,1.3,'PartitionShort'),(2.4,1.6,'PartitionWide')]:panel(w,h);save(name,'open_space')
panel(1.6,1.6);n=len(pieces);panel(1.2,1.6);shift(n,.8,.6,math.pi/2);save('PartitionCorner','open_space')
for count in [2,4]:
 for row in range(count//2):
  for col in range(2):
   n=len(pieces);desk(1.4,.7);monitor(0,.81)
   box('Keyboard',(0,-.23,.825),(.44,.15,.025),0)
   shift(n,(col-.5)*1.44,(row-(count//2-1)/2)*.74,math.pi if row==1 else 0)
 box('Divider',(0,0,1.06),(.06,(count//2)*.74,.56),4)
 if count==4:box('Divider',(0,0,1.06),(2.8,.06,.56),4)
 save(f'WorkstationBank{count}','open_space')
drawers(.40,.50,.63);save('UnderDeskPedestal','open_space')
for w,d,name in [(1.8,.7,'ReceptionCompact'),(3.2,.85,'ReceptionWide')]:
 box('Body',(0,0,.55),(w,d,1.1),3)
 box('Kick',(0,0,.055),(w-.08,d-.03,.11),1)
 box('FrontAccent',(0,-d/2-.009,.74),(w-.12,.018,.18),4)
 box('Counter',(0,-d*.34,1.15),(w+.12,.27,.08),5)
 for x in [-w/2,w/2]:box('Return',(x,0,1.15),(.14,d+.12,.08),5)
 save(name,'reception')
for wide in [False,True]:
 for x in [-.55,.55] if wide else [0]:
  box('Housing',(x,0,.50),(.32,.85,1),1,.04);box('Reader',(x,-.15,1.02),(.18,.22,.035),0)
  box('ReaderLED',(x,-.18,1.044),(.09,.06,.008),9)
 if wide:
  box('ClosedGlassGate',(0,0,.68),(.80,.05,.52),11);name='SecuritySwingGate'
 else:
  cyl('Hub',(.19,0,.7),.085,.07,2,12,(0,math.pi/2,0))
  for i in range(3):
   a=i*math.tau/3;rod('TripodArm',(.22,0,.7),(.60,.30*math.sin(a),.7+.30*math.cos(a)),.022,2)
  name='TripodTurnstile'
 save(name,'reception')
for x in [-.58,.58]:box('Post',(x,0,1.10),(.12,.38,2.2),2)
box('Header',(0,0,2.17),(1.28,.38,.12),2)
for x in [-.515,.515]:box('Sensor',(x,-.12,1.22),(.017,.10,.30),0)
box('Status',(0,-.201,2.17),(.30,.016,.04),9);save('AccessScannerArch','reception')
desk(1.1,.6);monitor(0,.81);save('SecurityDesk','reception')
for width,name in [(.65,'FridgeCompact'),(.95,'FridgeWide')]:
 box('Body',(0,0,.94),(width,.68,1.88),3,.028)
 for z,h in [(1.55,.57),(.61,1.15)]:
  box('Door',(0,-.359,z),(width-.04,.045,h),2,.016);box('Handle',(width*.32,-.406,z),(.032,.035,.26),1)
 box('Kick',(0,-.36,.055),(width-.04,.03,.08),1);save(name,'kitchen')
box('Body',(0,0,.16),(.54,.38,.32),3,.02);box('Front',(0,-.20,.16),(.50,.022,.275),0)
box('Window',(-.06,-.216,.16),(.34,.008,.20),14);box('Handle',(.12,-.24,.16),(.026,.035,.19),2)
box('Display',(.21,-.218,.23),(.055,.009,.037),9)
for z in [.08,.13,.18]:cyl('Button',(.21,-.222,z),.012,.012,2,8,(math.pi/2,0,0))
save('Microwave','kitchen')
cabinet(1.2,.86,True)
box('SinkBasin',(0,0,.913),(.60,.38,.018),1)
for x in [-.31,.31]:box('SinkRim',(x,0,.932),(.025,.42,.024),2)
for y in [-.21,.21]:box('SinkRim',(0,y,.932),(.62,.025,.024),2)
rod('FaucetStem',(0,.18,.95),(0,.18,1.16),.019,2);rod('FaucetSpout',(0,.18,1.16),(0,0,1.16),.019,2);save('KitchenSinkCabinet','kitchen')
cabinet(1.8,.86,True);save('KitchenCounterWide','kitchen')
box('Body',(0,0,.25),(.32,.40,.50),0,.02);box('Front',(-.04,-.209,.28),(.20,.019,.32),2)
box('Screen',(0,-.224,.39),(.14,.009,.075),14);box('Tray',(0,-.27,.035),(.28,.20,.035),1)
rod('Spout',(-.05,-.23,.26),(-.05,-.26,.21),.018,2);cyl('Cup',(-.05,-.27,.11),.04,.10,6)
save('CounterCoffeeMachine','kitchen')
for snack,name in [(True,'SnackVending'),(False,'DrinkVending')]:
 box('Case',(0,0,1.0),(.92,.76,2.0),1,.035)
 box('WindowFrame',(-.12,-.398,1.20),(.60,.028,1.26),0)
 box('Interior',(-.12,-.416,1.20),(.53,.009,1.17),14)
 for row in range(4):
  z=.76+row*.27;box('Shelf',(-.12,-.445,z-.10),(.53,.05,.02),2)
  for col in range(3):
   x=-.30+col*.18
   if snack:
    box('SnackPack',(x,-.456,z),(.115,.038,.17),[10,8,9][(col+row)%3],.013)
   else:
    cyl('Can',(x,-.45,z),.046,.16,[7,8,9][(row+col)%3],10)
 box('Display',(.32,-.406,1.56),(.13,.02,.12),14)
 for z in [1.1,1.2,1.3]:box('Button',(.32,-.423,z),(.08,.015,.035),3)
 box('CoinSlot',(.32,-.423,.82),(.06,.012,.012),0)
 box('Pickup',(0,-.404,.29),(.64,.018,.20),0);box('PickupLip',(0,-.46,.18),(.65,.12,.04),2)
 save(name,'kitchen')
for width,name in [(1.6,'ArchiveCabinetWide'),(2.4,'ArchiveCabinetBank')]:
 cabinet(width,1.9)
 if width>2:
  for x in [-.8,0,.8]:box('DoorSeam',(x,-.265,.95),(.014,.013,1.85),1)
 save(name,'archive')
for width,name in [(.65,'ServerRackCompact'),(1.3,'ServerRackTwin')]:
 box('Case',(0,0,1.05),(width,.82,2.1),1)
 for col in range(1 if width<1 else 2):
  x=0 if width<1 else (col-.5)*.62
  box('Front',(x,-.43,1.05),(.56,.025,1.95),0)
  for row in range(9):
   z=.22+row*.20;box('ServerUnit',(x,-.448,z),(.50,.015,.15),1)
   for dx in [-.17,-.12,-.07]:box('LED',(x+dx,-.460,z),(.017,.008,.013),9 if row<4 else 7,0)
   for dx in [.06,.10,.14,.18]:box('Vent',(x+dx,-.46,z),(.009,.008,.07),0,0)
  box('Handle',(x+.25,-.47,1.05),(.02,.03,.35),2)
 save(name,'server_room')
box('Case',(0,0,.26),(.36,.55,.52),1);box('Display',(0,-.287,.40),(.18,.012,.07),9)
for x in [-.11,-.07,-.03,.01,.05,.09,.13]:box('Vent',(x,-.286,.20),(.015,.01,.19),0)
save('UPSUnit','server_room')
for y in [-.10,0,.10]:
 rod('Cable',(0,y,.045),(.45,y,.045),.018,0)
for x in [.08,.36]:box('CableTie',(x,0,.046),(.025,.27,.04),10)
save('CableBundle','server_room')
box('Body',(0,0,1.0),(.7,.6,2),2)
for z in [.25,.5,.75,1.0,1.25,1.5,1.75]:box('Louvre',(0,-.315,z),(.59,.035,.10),1)
save('VentilationCabinet','server_room')
box('Panel',(0,0,.36),(.55,.12,.72),2)
for x in [-.17,0,.17]:
 for z in [.19,.31,.43]:box('Breaker',(x,-.074,z),(.11,.018,.075),0);box('Switch',(x,-.091,z),(.025,.02,.045),8)
box('Warning',(0,-.072,.62),(.13,.01,.065),10);save('ElectricalPanel','technical')
for x in [-.42,.42]:
 for y in [-.25,.25]:cyl('Wheel',(x,y,.09),.08,.045,0,10,(math.pi/2,0,0))
box('Platform',(0,0,.18),(.94,.60,.075),1)
for x in [-.42,.42]:rod('Handle',(x,.23,.2),(x,.23,.91),.023,2)
rod('Crossbar',(-.42,.23,.91),(.42,.23,.91),.023,2);save('WarehouseTrolley','archive')
for x in [-.45,0,.45]:box('Runner',(x,0,.06),(.10,1.0,.12),5)
for y in [-.44,-.22,0,.22,.44]:box('Slat',(0,y,.145),(1.1,.15,.05),5)
save('WoodPallet','archive')
for scale,name in [(.65,'BoxSmall'),(1.4,'BoxLarge')]:
 box('Box',(0,0,.20*scale),(.55*scale,.42*scale,.40*scale),15)
 box('Tape',(0,0,.402*scale),(.05*scale,.42*scale,.005),5,0);save(name,'archive')
desk(3.6,1.2);save('ConferenceTableLong','meeting')
box('Frame',(0,0,.50),(1.5,.075,1),0,.016);box('Screen',(0,-.044,.5),(1.41,.012,.90),14);save('WallTelevision','meeting')
box('Case',(0,0,.08),(.30,.25,.16),3,.03);cyl('Lens',(0,-.135,.075),.045,.04,0,16,(math.pi/2,0,0))
for x in [-.10,-.07,-.04,-.01]:box('Vent',(x,.02,.162),(.014,.14,.005),1,0)
save('Projector','meeting')
box('Base',(0,0,.025),(.22,.19,.05),0,.025);box('Screen',(0,.025,.058),(.075,.06,.016),11)
for x in [-.065,0,.065]:box('Speaker',(x,-.055,.054),(.043,.05,.009),1)
save('ConferencePhone','meeting')
chair(True)
box('Headrest',(0,.21,1.21),(.31,.10,.18),0,.045);save('ExecutiveChair','meeting')
chair(True)
for o in pieces:
 if o.name.startswith('Back'):o.data.materials.clear();o.data.materials.append(materials[4])
save('TaskChairTeal','open_space')

# Six authored static damaged variants. Ground them after applying their rotation.
desk();o=save('OverturnedDesk','damaged');o.rotation_euler.y=math.radians(105)
chair(True)
for o in list(pieces):
 if o.name.startswith('Arm') and o.location.x>0:pieces.remove(o);bpy.data.objects.remove(o,do_unlink=True)
for o in pieces:
 if o.name.startswith('Back'):o.rotation_euler.y=.40;o.location.x=.12
o=save('BrokenChair','damaged');o.rotation_euler.x=math.radians(72)
monitor()
for a,b in [((-.29,-.025,.54),(.06,-.025,.26)),((.06,-.025,.26),(.25,-.025,.42)),((.06,-.025,.26),(-.16,-.025,.22))]:rod('ScreenCrack',a,b,.007,3,4)
o=save('BrokenMonitor','damaged');o.rotation_euler.y=.18
cabinet(1.4,1.8);o=save('FallenArchiveCabinet','damaged');o.rotation_euler.x=math.pi/2
for i in range(32):
 a=i*2.399;x=math.cos(a)*(.1+.025*i);y=math.sin(a)*(.1+.02*i)
 o=box('LoosePaper',(x,y,.005+.002*(i%5)),(.20,.28,.003),6,0);o.rotation_euler.z=a
save('ScatteredPaperPile','damaged')
for x in [-.48,.48]:box('Jamb',(x,0,1.03),(.06,.15,2.06),2)
box('Header',(0,0,2.06),(1.02,.15,.06),2)
box('LowerDoor',(-.22,.10,.42),(.45,.045,.85),5)
o=box('UpperDoor',(.10,.15,1.48),(.70,.045,1.0),5);o.rotation_euler.y=-.16;o.rotation_euler.z=.18
for x,z in [(-.22,1.1),(.23,.85),(.38,1.1)]:
 o=box('Splinter',(x,.16,z),(.06,.03,.30),5);o.rotation_euler.y=.45
save('BrokenOfficeDoor','damaged')

exec(compile(source.split('# One palette texture, single UV channel; no baking or external dependencies.')[1].split('manifest=[]')[0],'palette','exec'))
manifest=[]
for i,o in enumerate(assets):
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 ground=min(v.co.z for v in o.data.vertices)
 for v in o.data.vertices:v.co.z-=ground
 for layer in list(o.data.uv_layers):o.data.uv_layers.remove(layer)
 uv=o.data.uv_layers.new(name='PaletteUV');uv.active_render=True
 for p in o.data.polygons:
  ci=materials.index(o.data.materials[p.material_index])
  for li in p.loop_indices:uv.data[li].uv=((ci+.5)/len(colors),.5)
  p.material_index=0
 o.data.materials.clear();o.data.materials.append(palette);o.data.update();o.data.calc_loop_triangles()
 dims=[round(v,4) for v in o.dimensions]
 bpy.ops.export_scene.fbx(filepath=str(OUT/'exports'/f'{o.name}.fbx'),use_selection=True,add_leaf_bones=False,bake_anim=False,path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y')
 manifest.append({'name':o.name,'zone':categories[o.name],'size_m':dims,'triangles':len(o.data.loop_triangles),'file':f'exports/{o.name}.fbx','placement':'floor origin, front -Y','collision':'add simple proxy in Studio'})
 o.location=((i%8)*4,(i//8)*4,0)
bpy.ops.object.select_all(action='DESELECT')
for o in assets:o.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT/'exports'/'OfficeZones_All.fbx'),use_selection=True,add_leaf_bones=False,bake_anim=False,path_mode='COPY',embed_textures=True,axis_forward='-Z',axis_up='Y')
(OUT/'Manifest.json').write_text(json.dumps({'count':len(assets),'units':'metres','assets':manifest},indent=2),encoding='utf-8')
scene.unit_settings.system='METRIC'

preview=bpy.data.scenes.new('OfficeZonesCatalog');preview.world=bpy.data.worlds.new('ZonesWorld');preview.world.use_nodes=True
bg=next(n for n in preview.world.node_tree.nodes if n.type=='BACKGROUND');bg.inputs[0].default_value=(.08,.09,.11,1);bg.inputs[1].default_value=.5
for i,o in enumerate(assets):
 c=o.copy();preview.collection.objects.link(c);s=1.6/max(o.dimensions);c.scale=(s,s,s);c.location=((i%8)*2.4,(i//8)*2.6,0)
d=bpy.data.cameras.new('ZonesCamera');cam=bpy.data.objects.new('ZonesCamera',d);preview.collection.objects.link(cam);cam.location=(10,-15,26)
target=Vector((8.4,((len(assets)-1)//8)*1.3,.5));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();d.type='ORTHO';d.ortho_scale=21;preview.camera=cam
for loc,power in [((4,-4,14),5500),((15,9,15),4500)]:
 d=bpy.data.lights.new('Softbox','AREA');d.energy=power;d.shape='DISK';d.size=10;l=bpy.data.objects.new('Softbox',d);preview.collection.objects.link(l);l.location=loc;l.rotation_euler=(target-l.location).to_track_quat('-Z','Y').to_euler()
preview.render.engine='CYCLES';preview.cycles.samples=24;preview.render.resolution_x=1800;preview.render.resolution_y=1500;preview.render.resolution_percentage=100;preview.render.film_transparent=True
preview.render.image_settings.file_format='PNG';preview.render.filepath=str(OUT/'OfficeZones_Catalog.png')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'OfficeZones.blend'))
def render_preview():
 bpy.context.window.scene=preview;bpy.ops.render.render(write_still=True);bpy.context.window.scene=scene;return None
bpy.app.timers.register(render_preview,first_interval=1)
print(json.dumps({'models':len(assets),'triangles':sum(a['triangles'] for a in manifest),'saved':str(OUT)}))
