import bpy, math, json
from pathlib import Path
from mathutils import Vector
BASE=Path(r'C:\Roblox\ZombilkaFPS\assets\environment\office')
source=(BASE/'tools'/'build_office_kit.py').read_text(encoding='utf-8')
exec(compile(source.split("desk();asset('OfficeDesk')")[0],'helpers','exec'))
OUT=BASE.parent/'parking'/'expansion';(OUT/'exports').mkdir(parents=True,exist_ok=True)
scene.name='ParkingExpansion'
categories={}
def save(name,zone):
 o=asset(name);categories[o.name]=zone;return o
def mesh(label,verts,faces,mat):
 m=bpy.data.meshes.new(label);m.from_pydata(verts,[],faces);m.update();o=bpy.data.objects.new(label,m);scene.collection.objects.link(o);return finish(o,label,mat)
def line(a,b,r=.015,c=2):return rod('Tube',a,b,r,c)
def text(value,p,size,c=6):
 bpy.ops.object.text_add(location=p,rotation=(math.pi/2,0,0));o=bpy.context.object;o.data.body=value;o.data.align_x='CENTER';o.data.align_y='CENTER';o.data.size=size;o.data.extrude=.001;bpy.ops.object.convert(target='MESH');finish(bpy.context.object,'Label',c)
def ring(p,r=.30,minor=.055,c=0,rot=(0,0,0)):
 bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=6,major_radius=r,minor_radius=minor,location=p,rotation=rot);return finish(bpy.context.object,'Ring',c)
for roundpost,w,name in [(False,.55,'ConcreteSupportSquare'),(False,.90,'ConcreteSupportWide'),(True,.37,'ConcreteSupportRound')]:
 if roundpost:cyl('Column',(0,0,1.5),w,3,2,16)
 else:box('Column',(0,0,1.5),(w,w,3),2)
 box('Foot',(0,0,.075),(w*2.3 if roundpost else w+.18,w*2.3 if roundpost else w+.18,.15),1)
 if roundpost:
  cyl('SafetyBand',(0,0,.72),w+.008,.16,10,16)
 else:box('SafetyBand',(0,0,.72),(w+.014,w+.014,.16),10)
 save(name,'structure')
for length,name in [(1.6,'ConcreteIslandShort'),(3.2,'ConcreteIslandLong')]:
 box('Island',(0,0,.16),(length,.72,.32),2,.09)
 for x in [-length*.32,0,length*.32]:box('Reflector',(x,-.368,.19),(.22,.009,.09),10,0)
 save(name,'cover')
for length,name in [(1.4,'JerseyBarrierShort'),(2.8,'JerseyBarrierLong'),(4.0,'JerseyBarrierWide')]:
 verts=[]
 for x in [-length/2,length/2]:
  verts.extend([(x,-.40,0),(x,.40,0),(x,.40,.20),(x,.15,.68),(x,.15,.95),(x,-.15,.95),(x,-.15,.68),(x,-.40,.20)])
 faces=[tuple(reversed(range(8))),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]
 mesh('Barrier',verts,faces,2)
 for x in [-length*.30,length*.30]:box('Reflector',(x,-.156,.82),(.22,.014,.075),10,0)
 save(name,'cover')
def railing(x,y0,y1,z0,z1):
 for i in range(5):
  t=i/4;y=y0+(y1-y0)*t;z=z0+(z1-z0)*t;line((x,y,z),(x,y,z+.90),.025,1)
 line((x,y0,z0+.90),(x,y1,z1+.90),.03,2)
for steps,width,name in [(10,1.4,'StairFlight'),(16,1.6,'StairFlightTall')]:
 for i in range(steps):box('Step',(0,i*.28,.09+i*.18),(width,.28,.18),2,0)
 for x in [-width/2,width/2]:railing(x,0,(steps-1)*.28,.18,steps*.18)
 save(name,'structure')
box('Landing',(0,0,.1),(3.2,1.8,.2),2)
for x in [-1.5,1.5]:railing(x,-.8,.8,.2,.2)
save('StairLanding','structure')
box('Floor',(0,0,.08),(3.8,2.6,.16),2)
for x in [-1.86,1.86]:box('SideWall',(x,0,1.35),(.12,2.6,2.7),2)
box('BackWall',(0,1.25,1.35),(3.8,.10,2.7),2)
for x in [-.43,.43]:box('LiftDoor',(x,1.17,1.18),(.82,.035,2.2),3)
for x in [-.93,.93]:box('LiftTrim',(x,1.16,1.19),(.09,.06,2.35),1)
box('Header',(0,1.16,2.37),(1.92,.06,.10),1);box('CallButtons',(1.15,1.14,1.2),(.15,.05,.26),0)
text('ELEVATOR',(0,1.10,2.57),.16)
for x in [-1.5,1.5]:box('WallLight',(x,1.10,2.25),(.32,.08,.08),6)
save('ElevatorHallModule','structure')
frame(1.15,2.35,4);box('DoorWindow',(0,-.039,1.65),(.72,.012,.75),11);box('PushBar',(0,-.10,1.05),(.84,.04,.04),3)
text('SERVICE',(0,-.052,2.20),.12);save('BuildingServiceDoor','structure')
verts=[(-1.7,-3,0),(1.7,-3,0),(1.7,3,1.2),(-1.7,3,1.2),(-1.7,-3,-.12),(1.7,-3,-.12),(1.7,3,1.08),(-1.7,3,1.08)]
mesh('Ramp',verts,[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],2)
for x in [-1.65,1.65]:railing(x,-2.8,2.8,.05,1.17)
save('InterLevelRamp','structure')
for i,(x,y,z,s) in enumerate([(-.35,0,.24,.48),(.30,0,.28,.56),(-.18,.02,.73,.46),(.35,.02,.82,.45)]):
 box('Box',(x,y,z),(s,.58,s),15);box('Tape',(x,y,z+s/2+.003),(.045,.58,.006),5,0)
save('StackedBoxesCover','cover')
for i in range(5):ring((0,0,.085+i*.16),.30,.085)
save('TyreStack','cover')
for x,y in [(-.24,-.15),(.24,-.15),(0,.26)]:
 box('Canister',(x,y,.27),(.34,.22,.54),9,.035);box('TopHandle',(x,y,.57),(.22,.10,.065),1)
 cyl('Cap',(x-.10,y,.58),.034,.05,0,8)
save('CanisterCluster','cover')
box('Deck',(0,0,.23),(1.2,.7,.09),1)
for x in [-.5,.5]:
 for y in [-.27,.27]:cyl('Wheel',(x,y,.11),.1,.055,0,12,(math.pi/2,0,0))
for x in [-.53,.53]:line((x,.28,.28),(x,.28,.97),.025)
line((-.53,.28,.97),(.53,.28,.97),.025);save('ServiceFlatbedCart','cover')
for x in [-.27,.27]:
 box('Fork',(x,-.35,.10),(.18,1.35,.12),10,.018);cyl('Roller',(x,-.87,.075),.07,.09,0,12,(0,math.pi/2,0))
box('Pump',(0,.30,.22),(.55,.32,.35),10)
line((0,.30,.35),(0,.43,1.06),.035,1)
for x in [-.20,.20]:line((0,.43,1.06),(x,.43,1.17),.024,1)
line((-.20,.43,1.17),(.20,.43,1.17),.024,1);cyl('SteeringWheel',(0,.33,.10),.095,.30,0,12,(0,math.pi/2,0));save('HandPalletJack','cover')
cabinet(.85,1.85);text('TOOLS',(0,-.282,1.62),.12);save('ServiceLockerTall','technical')
box('Case',(0,0,.47),(.60,.17,.94),2);box('Door',(0,-.099,.47),(.53,.025,.86),1)
for z in [.28,.44,.60]:box('Breaker',(0,-.12,z),(.34,.016,.07),0)
text('HIGH VOLTAGE',(0,-.131,.80),.06,10);save('WallElectricalBoard','technical')
for length,name in [(1.4,'CeilingLampShort'),(2.8,'CeilingLampLong')]:
 box('Case',(0,0,.055),(length,.20,.11),1);box('Diffuser',(0,-.105,.04),(length-.09,.014,.065),6)
 for x in [-length*.32,length*.32]:line((x,0,.11),(x,0,.45),.008,1)
 save(name,'atmosphere')
box('Duct',(0,0,.21),(2.4,.42,.42),2)
for x in [-1.15,0,1.15]:box('Joint',(x,0,.21),(.035,.46,.46),1)
save('VentDuctStraight','technical')
box('Duct',(0,-.4,.21),(.42,1.2,.42),2);box('Duct',(.40,0,.21),(1.2,.42,.42),2)
for y in [-.96,-.40]:box('Joint',(0,y,.21),(.46,.035,.46),1)
save('VentDuctElbow','technical')
for x in [-.06,0,.06]:line((x,-.8,.07),(x,.8,.07),.023,0)
for y in [-.7,0,.7]:box('Clamp',(0,y,.07),(.23,.04,.07),1)
save('CeilingCableBundle','technical')
box('Bracket',(0,0,.05),(.24,.24,.10),1);cyl('AmberLens',(0,0,.17),.095,.17,10,16);save('AmberWarningBeacon','technical')
for value,c,name in [('A1',7,'SectionA1'),('B2',9,'SectionB2'),('P3',10,'SectionP3')]:
 box('Panel',(0,0,.44),(1.2,.06,.88),c);text(value,(0,-.039,.44),.52);save(name,'wayfinding')
for value,name,c in [('EXIT >','ExitArrowSign',9),('ELEVATOR >','ElevatorArrowSign',7),('STAIRS >','StairsArrowSign',7),('ENTRY','EntrySign',9),('EXIT','ExitSign',8),('SERVICE ONLY','ServiceAreaSign',10)]:
 box('Panel',(0,0,.16),(1.2,.05,.32),c);text(value,(0,-.032,.16),.12 if len(value)>9 else .17);save(name,'wayfinding')
for c,name in [(7,'BlueZoneFloor'),(9,'GreenZoneFloor'),(10,'YellowZoneFloor')]:
 box('Floor',(0,0,.02),(2,2,.04),2);box('Stripe',(0,-.85,.044),(1.90,.17,.008),c,0);save(name,'markings')
def patch(radius,c,label,seed=0):
 verts=[(0,0,.008)]
 for i in range(16):
  a=i*math.tau/16;r=radius*(.8+.18*math.sin(i*2.7+seed));verts.append((r*math.cos(a),r*.65*math.sin(a),.008))
 mesh(label,verts,[(0,i+1,((i+1)%16)+1) for i in range(16)],c)
patch(.85,0,'Oil');save('OilPuddle','atmosphere')
for i in range(6):
 x=.16*(-1 if i%2 else 1);y=(i-2.5)*.28
 o=box('BloodyFootprint',(x,y,.006),(.10,.20,.01),8,.025);o.rotation_euler.z=-.13 if i%2 else .13
save('BloodyFootprints','damaged')
patch(.55,8,'Blood');save('BloodStain','damaged')
box('Tile',(0,0,.015),(2,2,.03),2)
for i in range(15):
 a=i*math.pi/28
 for r in [.65,.92]:
  o=box('CurveMark',(r*math.sin(a)-.6,r*math.cos(a)-.4,.034),(.11,.03,.008),1,0);o.rotation_euler.z=-a
save('TurningTyreTrackTile','markings')
for x,y,s in [(-.25,0,.25),(.25,.05,.30),(0,.33,.22)]:
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=s,location=(x,y,s*.78));o=finish(bpy.context.object,'Bag',0);o.scale=(1,.83,1.1)
 cyl('Tie',(x,y,s*1.9),.025,.07,1,6)
save('GarbageBagPile','atmosphere')
for i in range(17):
 a=i*2.4;x=math.cos(a)*.65;y=math.sin(a)*.5
 o=box('Paper',(x,y,.01+.002*(i%3)),(.12,.18,.004),6,0);o.rotation_euler.z=a
for x,y in [(-.3,.12),(.3,-.2),(0,.4)]:cyl('DiscardedCan',(x,y,.055),.035,.10,7,8)
save('SmallLitterPile','atmosphere')
# Build vehicle damage from the original authored construction functions.
parking=(BASE/'tools'/'build_parking_kit.py').read_text(encoding='utf-8')
exec(compile(parking.split('def hull(')[1].split("car('sedan'")[0].join(['def hull(','']),'vehicle_helpers','exec'))
car('sedan',1,'WreckedSedan');o=assets.pop();categories.pop(o.name);o.name='WreckBody'
for v in o.data.vertices:
 if v.co.y<-.95:v.co.y+=.28*(v.co.z/.9);v.co.z-=.12
 if v.co.z>1.30:v.co.z-=.10*(1-abs(v.co.x))
pieces=[o]
for a,b in [((-.56,-.93,1.09),(.1,-.64,1.29)),((.1,-.64,1.29),(.48,-.88,1.13))]:line(a,b,.012,6)
for x in [-.45,-.2,.15]:box('DamageScar',(x,-1.94,.62),(.16,.015,.026),0)
save('WreckedSedan','damaged')
# Reuse wheel/frame construction, then rotate and ground the authored wreck.
def torus(p,major,minor,mat=1,rot=(math.pi/2,0,0)):return ring(p,major,minor,mat,rot)
exec(compile('def bike('+parking.split('def bike(')[1].split('bike(True);bike(False)')[0],'bike_helpers','exec'))
bike(True);o=assets[-1];categories.pop(o.name);o.name='OverturnedMotorcycle';categories[o.name]='damaged';o.rotation_euler.y=math.pi/2
box('Base',(0,0,.045),(.4,.45,.09),1);box('Housing',(0,0,.54),(.3,.34,1),1);box('Cap',(0,0,1.04),(.33,.37,.13),10)
box('BrokenArmRoot',(.40,0,1.02),(.65,.075,.10),3)
o=box('FallenArm',(1.02,-.20,.14),(1.35,.075,.10),3);o.rotation_euler.z=.35
for x in [.5,.9,1.3]:box('RedReflector',(x,-.245,.15),(.18,.013,.07),8)
save('BrokenBarrierGate','damaged')
box('Base',(0,0,.025),(.35,.35,.05),8)
for angle in [-.22,.35]:
 bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=.125,radius2=.018,depth=.23,location=(angle*.2,0,.16));o=finish(bpy.context.object,'BrokenCone',8);o.rotation_euler.y=angle
box('Reflector',(0,-.11,.15),(.17,.018,.07),3);save('CrushedTrafficCone','damaged')
box('Case',(0,0,.44),(.56,.17,.88),2)
o=box('OpenDoor',(.40,-.24,.44),(.53,.035,.84),1);o.rotation_euler.z=-.9
for z in [.22,.40,.58]:box('BurnedBreaker',(0,-.102,z),(.32,.03,.09),0)
for a,b in [((-.12,-.13,.6),(.03,-.18,.46)),((.03,-.18,.46),(-.08,-.19,.33)),((.03,-.18,.46),(.19,-.16,.52))]:line(a,b,.011,10)
save('DamagedElectricalBoard','damaged')
box('Case',(0,0,.83),(.44,.36,1.66),1);box('Face',(0,-.2,1.01),(.39,.04,1.3),10)
box('BrokenScreen',(0,-.228,1.32),(.28,.02,.27),0)
for i in range(5):
 a=i*2.4;line((.15*math.cos(a),-.245,1.32+.1*math.sin(a)),(0,-.245,1.32),.007,6)
for i in range(7):
 a=i*2.4;line((0,0,.8),(.25*math.cos(a),-.27,.8+i*.10),.035,9)
box('Infection',(0,-.242,.69),(.21,.06,.12),9);save('InfectedParkingMeter','damaged')
box('Panel',(0,0,.46),(.8,.08,.92),2)
for i in range(5):line((-.28+i*.06,-.048,.2),(.04+i*.06,-.048,.72),.008,0)
save('ScratchedMetalPanel','damaged')

tail=(BASE/'tools'/'build_office_zones.py').read_text(encoding='utf-8').split("exec(compile(source.split('# One palette texture")[1]
tail="exec(compile(source.split('# One palette texture"+tail
tail=tail.replace('OfficeZones','ParkingExpansion').replace('(i%8)*4,(i//8)*4','(i%8)*8,(i//8)*8')
tail=tail.replace("d=bpy.data.cameras.new('ZonesCamera')", "for c in preview.objects:\n if c.type=='MESH' and c.name.startswith(('Wrecked','Overturned','Stair','InterLevel','ElevatorHall')):c.rotation_euler.z=-.6\nd=bpy.data.cameras.new('ZonesCamera')")
exec(compile(tail,'export','exec'))
