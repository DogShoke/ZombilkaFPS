import bpy, math, json
from pathlib import Path
from mathutils import Vector
BASE=Path(r'C:\Roblox\ZombilkaFPS\assets\environment\office')
source=(BASE/'tools'/'build_office_kit.py').read_text(encoding='utf-8')
exec(compile(source.split("desk();asset('OfficeDesk')")[0],'office_helpers','exec'))
OUT=BASE.parent/'parking';(OUT/'exports').mkdir(parents=True,exist_ok=True)
scene.name='ParkingKit'
categories={}
def save(name,zone):
 o=asset(name);categories[name]=zone;return o
def mesh(label,verts,faces,mat):
 m=bpy.data.meshes.new(label);m.from_pydata(verts,[],faces);m.update();o=bpy.data.objects.new(label,m);scene.collection.objects.link(o);return finish(o,label,mat)
def text(label,value,p,size,mat):
 bpy.ops.object.text_add(location=p,rotation=(math.pi/2,0,0));o=bpy.context.object;o.data.body=value;o.data.align_x='CENTER';o.data.align_y='CENTER';o.data.size=size;o.data.extrude=.001
 bpy.ops.object.convert(target='MESH');return finish(bpy.context.object,label,mat)
def line(a,b,r=.012,c=2):return rod('Tube',a,b,r,c)
def torus(p,major,minor,mat=1,rot=(math.pi/2,0,0)):
 bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=6,major_radius=major,minor_radius=minor,location=p,rotation=rot);return finish(bpy.context.object,'Ring',mat)
def stripebar(length,z=1.05,angle=0):
 n=len(pieces);box('Arm',(length/2,0,z),(length,.075,.10),3)
 for i in range(5):box('Reflector',((i+.5)*length/5,-.043,z),(.26,.012,.065),8,0)
 for o in pieces[n:]:
  x=o.location.x;o.location.x=x*math.cos(angle);o.location.z=z+x*math.sin(angle);o.rotation_euler.y=-angle
for angle,name in [(0,'BarrierGateClosed'),(math.radians(48),'BarrierGateRaised')]:
 box('Base',(0,0,.055),(.40,.45,.11),1);box('Housing',(0,0,.55),(.31,.34,.99),1,.03)
 box('Cap',(0,0,1.04),(.34,.37,.18),10,.025);cyl('Pivot',(.19,0,1.05),.095,.10,2,12,(0,math.pi/2,0))
 stripebar(2.6,1.05,angle);save(name,'access')
for name,mat in [('ParkingPaymentKiosk',10),('TicketTerminal',3)]:
 box('Body',(0,0,.88),(.44,.36,1.76),1);box('Front',(0,-.20,1.04),(.39,.05,1.3),mat)
 box('Screen',(0,-.233,1.36),(.29,.012,.28),14);box('ScreenGlow',(0,-.243,1.36),(.24,.006,.23),11)
 for z in [.76,.94]:box('Slot',(0,-.24,z),(.22,.012,.045),0)
 box('Reader',(.08,-.25,.61),(.10,.03,.07),9);box('Foot',(0,0,.045),(.51,.43,.09),1)
 save(name,'access')
box('Floor',(0,0,.10),(1.8,1.6,.20),2)
for x in [-.82,.82]:
 for y in [-.70,.70]:box('Post',(x,y,1.23),(.09,.09,2.26),3)
 box('LowerWall',(x,0,.61),(.07,1.40,1.03),2)
 box('SideGlass',(x,0,1.57),(.032,1.30,.82),11)
 box('WindowDivider',(x,0,1.57),(.08,.045,.87),3)
box('RearWall',(0,.7,.61),(1.60,.065,1.03),2);box('RearGlass',(0,.7,1.57),(1.60,.025,.82),11)
box('DoorLower',(.38,-.71,.62),(.72,.055,1.04),2);box('DoorGlass',(.38,-.71,1.58),(.68,.028,.84),11)
box('FrontLower',(-.44,-.71,.62),(.73,.055,1.04),2);box('FrontGlass',(-.44,-.71,1.58),(.73,.028,.84),11)
box('DoorSeam',(0,-.76,1.23),(.05,.03,2.22),3);box('Handle',(.09,-.78,1.04),(.025,.04,.15),1)
box('Roof',(0,0,2.39),(1.99,1.79,.15),2);box('RoofVent',(.38,.18,2.50),(.27,.28,.065),1)
box('ACUnit',(.94,.35,.68),(.25,.46,.38),2);cyl('Fan', (1.075,.35,.68),.14,.026,0,16,(0,math.pi/2,0))
save('SecurityBooth','access')
box('Fixture',(0,0,.085),(1.3,.22,.17),1);box('Diffuser',(0,-.118,.055),(1.20,.02,.09),6)
for x in [-.46,.46]:line((x,0,.17),(x,0,.63),.009,1)
save('ParkingHangingLight','security')
box('Camera',(0,-.14,.32),(.17,.38,.15),3,.025);box('Hood',(0,-.20,.40),(.23,.49,.035),3)
box('LensPanel',(0,-.339,.32),(.13,.018,.10),0);cyl('Lens',(0,-.354,.32),.035,.015,11,12,(math.pi/2,0,0))
line((0,0,.31),(0,.17,.20),.025);box('Mount',(0,.20,.20),(.16,.06,.20),2);save('BulletSecurityCamera','security')
cyl('CeilingMount',(0,0,.35),.16,.07,3,20)
bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=.14,location=(0,0,.25));o=finish(bpy.context.object,'Dome',0);o.scale.z=.72
cyl('Lens',(0,-.127,.245),.028,.025,11,12,(math.pi/2,0,0));save('DomeSecurityCamera','security')
for h,mat,name in [(1,10,'BollardYellow'),(.9,3,'BollardWhite'),(.7,3,'BollardShort'),(.75,0,'BollardBlack'),(.95,8,'BollardRed')]:
 cyl('Foot',(0,0,.03),.12,.06,1);cyl('Post',(0,0,h/2+.05),.077,h,mat)
 for z in [h*.60,h*.82]:cyl('ReflectiveBand',(0,0,z),.079,.075,3 if mat in [8,10] else 10)
 save(name,'traffic')
def cone(damaged=False):
 box('Foot',(0,0,.03),(.33,.33,.06),8,.012)
 bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=.135,radius2=.025,depth=.43,location=(0,0,.275));o=finish(bpy.context.object,'Cone',8)
 bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=.104,radius2=.078,depth=.10,location=(0,0,.27));finish(bpy.context.object,'Reflector',3)
 if damaged:
  for o in pieces[1:]:o.rotation_euler.y=.25;o.location.x=.035
cone();save('TrafficCone','traffic');cone(True);save('BentTrafficCone','traffic')
for name,c in [('WheelStopStriped',1),('WheelStopPlain',1),('SpeedBump',10)]:
 box('Base',(0,0,.08),(1.6,.28,.16),c,.035)
 for x in [-.65,.65]:cyl('Bolt',(x,0,.165),.022,.008,0,8)
 if name!='WheelStopPlain':
  for x in [-.5,0,.5]:box('Stripe',(x,-.149,.09),(.22,.014,.08),10 if name!='SpeedBump' else 0,0);box('TopStripe',(x,0,.17),(.22,.20,.009),10 if name!='SpeedBump' else 0,0)
 save(name,'traffic')
box('LimitBar',(0,0,.07),(2.4,.12,.14),10)
for x in [-1,-.6,-.2,.2,.6,1]:
 o=box('BlackStripe',(x,-.068,.07),(.22,.012,.12),0,0);o.rotation_euler.y=-.45
for x in [-1.0,1.0]:
 for i in range(10):torus((x,0,.18+i*.055),.030,.007,1,(math.pi/2,0,0) if i%2==0 else (0,math.pi/2,0))
save('HangingHeightLimiter','traffic')
box('Pillar',(0,0,1.25),(.45,.45,2.5),2)
for z,c in [(0.65,0),(.83,10)]:box('SafetyBand',(0,0,z),(.46,.46,.18),c)
save('ParkingColumn','structure')
frame(1,2.1,4);box('DoorInset',(0,-.04,1.1),(.87,.018,1.93),4);box('PushBar',(0,-.12,1.05),(.69,.05,.045),3)
for x in [-.33,.33]:box('BarMount',(x,-.085,1.05),(.05,.07,.11),2)
box('ExitSign',(0,0,2.28),(.43,.08,.17),9);text('EXIT','EXIT',(0,-.049,2.28),.11,6);save('EmergencyExitDoor','security')
box('Case',(0,0,.45),(.42,.16,.9),8);box('Window',(0,-.089,.47),(.30,.017,.70),0)
cyl('Extinguisher',(0,-.115,.40),.067,.39,8);cyl('Band',(0,-.115,.4),.069,.1,6)
line((0,-.115,.62),(.10,-.115,.65),.012,1);save('FireCabinet','security')
box('Body',(0,0,.42),(.39,.36,.84),1,.025);box('Lid',(0,0,.89),(.43,.39,.14),1,.025);box('Opening',(0,-.209,.89),(.29,.015,.075),0)
save('OutdoorTrashBin','service')
box('Bin',(0,0,.56),(1.40,.90,1.05),4,.035)
for x in [-.71,.71]:
 for y in [-.32,.32]:cyl('Wheel',(x,y,.09),.09,.045,0,10,(0,math.pi/2,0))
 box('Handle',(x,0,.73),(.08,.50,.06),1)
box('Lid',(0,0,1.12),(1.50,.99,.10),1)
for x in [-.58,-.38,-.18,.02,.22,.42,.62]:box('LidRib',(x,0,1.181),(.02,.85,.025),0)
for x in [-.5,-.25,0,.25,.5]:box('BodyRib',(x,-.461,.6),(.025,.026,.78),4)
save('Dumpster','service')
box('Case',(0,0,.46),(.62,.42,.83),8)
for z in [.22,.34,.46,.58,.70,.79]:box('Drawer',(0,-.223,z),(.56,.022,.065),8);box('Handle',(0,-.247,z),(.48,.026,.012),2)
box('Worktop',(0,0,.91),(.67,.47,.045),1)
for x in [-.24,.24]:
 for y in [-.15,.15]:cyl('Castor',(x,y,.07),.06,.035,0,10,(math.pi/2,0,0))
save('ToolTrolley','service')
for x in [-.45,0,.45]:box('Runner',(x,0,.06),(.11,.95,.12),5)
for y in [-.40,-.20,0,.20,.40]:box('Slat',(0,y,.15),(1.08,.16,.06),5)
save('ParkingPallet','service')
box('Case',(0,0,.59),(1.25,.58,1.12),2)
for x in [-.59,.59]:box('Foot',(x,0,.035),(.12,.50,.07),1)
for x in [-.31,.31]:box('Door',(x,-.306,.6),(.59,.024,1.04),3);box('Handle',(x+.18,-.33,.61),(.025,.03,.14),1)
for z in [.23,.30,.37,.44]:box('Vent',(-.31,-.324,z),(.34,.011,.025),1)
text('Warning','!',(.31,-.326,.74),.22,10);save('ElectricalServiceCabinet','service')
box('Case',(0,0,.48),(1.15,.42,.88),3)
cyl('FanRim',(-.20,-.233,.49),.33,.032,1,24,(math.pi/2,0,0));cyl('FanCore',(-.20,-.254,.49),.055,.03,0,12,(math.pi/2,0,0))
for i in range(9):box('Grille',(-.20,-.274,.21+i*.07),(.56,.012,.014),2,0)
for z in [.20,.31,.42,.53,.64,.75]:box('Vent',(.40,-.23,z),(.20,.022,.055),1)
for x in [-.43,.43]:box('Foot',(x,0,.025),(.10,.35,.05),1)
save('AirConditioningUnit','service')

# Vehicle silhouettes use tapering cross sections instead of stacked cuboids.
def hull(label,sections,mat):
 verts=[]
 for y,w,zlo,zhi in sections:verts.extend([(-w,y,zlo),(w,y,zlo),(w,y,zhi),(-w,y,zhi)])
 faces=[(3,2,1,0)]
 for i in range(len(sections)-1):
  for j in range(4):a=i*4+j;b=i*4+(j+1)%4;faces.append((a,b,b+4,a+4))
 faces.append(tuple(range((len(sections)-1)*4,len(sections)*4)))
 return mesh(label,verts,faces,mat)
def car(kind,paint,name):
 van=kind=='van';suv=kind=='suv';length=4.5 if van else 4.1;w=.92 if van else .86
 hull('Body',[(-length/2,w*.85,.38,.69),(-1.4,w,.38,.88),(1.4,w,.38,.90),(length/2,w*.88,.38,.74)],paint)
 if van:
  hull('Cabin',[(-1.25,w*.98,.85,1.10),(-.65,w*.94,.85,1.96),(1.98,w*.94,.85,1.96)],paint)
  mesh('Windshield',[(-.75,-1.23,1.15),(.75,-1.23,1.15),(.74,-.69,1.94),(-.74,-.69,1.94)],[(0,1,2,3)],11)
  for x in [-w*.947,w*.947]:
   box('CabWindow',(x,-.33,1.52),(.013,.48,.52),11,0)
   box('PanelSeam',(x,.68,1.32),(.016,.018,1.06),1,0)
   box('Handle',(x,-.01,1.10),(.025,.16,.035),0)
 else:
  h=1.76 if suv else 1.44;back=1.35 if suv or kind=='hatch' else .92
  hull('Cabin',[(-1.04,.77,.90,1.04),(-.48,.69,.90,h),(back,.69,.90,h),(1.54,.77,.90,1.01)],paint)
  mesh('Windshield',[(-.71,-1.06,1.07),(.71,-1.06,1.07),(.63,-.50,h+.018),(-.63,-.50,h+.018)],[(0,1,2,3)],11)
  mesh('RearGlass',[(-.64,back+.02,h+.02),(.64,back+.02,h+.02),(.70,1.57,1.07),(-.70,1.57,1.07)],[(0,1,2,3)],11)
  for side in [-1,1]:
   for ya,yb in [(-.47,.30),(.36,back-.04)]:
    mesh('SideWindow',[(side*.703,ya,1.06),(side*.703,yb,1.06),(side*.697,yb,h-.08),(side*.697,ya,h-.08)],[(0,1,2,3)],11)
   for y in [-.25,.75]:box('Handle',(side*.879,y,.96),(.025,.15,.026),1)
   box('DoorSeam',(side*.875,.34,.70),(.012,.014,.38),1,0)
  if suv:
   for x in [-.58,.58]:line((x,-.4,h+.035),(x,1.2,h+.035),.028,1)
 for y in [-1.31,1.35]:
  for side in [-1,1]:
   cyl('Tyre',(side*w,y,.40),.35,.18,0,16,(0,math.pi/2,0));cyl('Hub',(side*(w+.10),y,.40),.20,.018,2,12,(0,math.pi/2,0));cyl('HubCentre',(side*(w+.114),y,.40),.07,.02,1,8,(0,math.pi/2,0))
 for y in [-length/2-.012,length/2+.012]:
  box('Bumper',(0,y,.46),(w*1.78,.09,.15),1)
  for x in [-.56,.56]:box('Light',(x,y,.70),(.34,.024,.13),6 if y<0 else 8,.006)
 box('Grille',(0,-length/2-.026,.65),(.60,.02,.19),0)
 for z in [.60,.65,.70]:box('GrilleBar',(0,-length/2-.043,z),(.56,.012,.018),2,0)
 box('Plate',(0,-length/2-.064,.46),(.31,.016,.085),3)
 for x in [-w-.07,w+.07]:box('Mirror',(x,-.62,1.06),(.16,.20,.10),paint,.018)
 save(name,'vehicles')
car('sedan',3,'SedanWhite');car('hatch',7,'HatchbackBlue');car('suv',1,'SUVGrey');car('van',3,'ServiceVan')
def bike(motor=False):
 radius=.30 if motor else .34
 for y in [-.64,.64]:
  torus((0,y,radius),radius-.045,.045 if not motor else .065,0,(0,math.pi/2,0))
  cyl('Hub',(0,y,radius),.06,.16,1,10,(0,math.pi/2,0))
  for i in range(8):
   a=i*math.tau/8;line((0,y,radius),(0,y+(radius-.07)*math.cos(a),radius+(radius-.07)*math.sin(a)),.007,2)
 for a,b in [((0,-.64,radius),(0,-.25,.76)),((0,-.25,.76),(0,.35,.80)),((0,.35,.80),(0,.08,.30)),((0,.08,.30),(0,-.64,radius)),((0,.35,.80),(0,.64,radius)),((0,.64,radius),(0,.08,.30))]:line(a,b,.025 if not motor else .045,7 if not motor else 1)
 box('Seat',(0,.32,.85),(.15 if not motor else .31,.32,.065),0,.025)
 line((0,-.64,radius),(0,-.39,.99),.025,1);line((-.22,-.38,1.01),(.22,-.38,1.01),.02,1)
 if motor:
  box('Tank',(0,-.03,.76),(.32,.46,.23),8,.05);box('Engine',(0,.04,.45),(.32,.30,.28),1,.025)
  for z in [.35,.41,.47,.53]:box('CoolingFin',(0,-.01,z),(.35,.25,.016),2,0)
  line((.19,.03,.36),(.19,.63,.25),.04,2);cyl('Headlight',(0,-.50,.83),.09,.07,6,12,(math.pi/2,0,0))
  box('RearCushion',(0,.59,.84),(.29,.25,.075),8);save('MotorcycleRed','vehicles')
 else:save('BicycleBlue','vehicles')
bike(True);bike(False)
for x in [-.6,0,.6]:
 line((x,-.38,.05),(x,-.38,.65),.035,2);line((x,.38,.05),(x,.38,.65),.035,2);line((x,-.38,.65),(x,.38,.65),.035,2)
for y in [-.38,.38]:box('Foot',(0,y,.03),(1.5,.14,.06),1)
save('BicycleRack','traffic')
for value,name in [('P','ParkingSign'),('10','SpeedLimitSign'),('>','DirectionSign'),('ACCESS','AccessibleParkingSign')]:
 box('Foot',(0,0,.045),(.29,.26,.09),2);box('Post',(0,0,.72),(.05,.05,1.40),2)
 if value=='10':
  cyl('Rim',(0,-.034,1.39),.25,.05,8,32,(math.pi/2,0,0));cyl('Face',(0,-.068,1.39),.217,.016,6,32,(math.pi/2,0,0));text('Limit',value,(0,-.081,1.39),.26,0)
 else:
  width=.68 if value=='ACCESS' else .47;box('Sign',(0,0,1.39),(width,.05,.45),3);box('Face',(0,-.03,1.39),(width-.035,.012,.414),7)
  if value=='ACCESS':
   torus((-.025,-.05,1.32),.11,.015,6,(math.pi/2,0,0))
   cyl('Head',(.01,-.05,1.55),.027,.014,6,12,(math.pi/2,0,0))
   for a,b in [((.01,-.052,1.51),(.01,-.052,1.35)),((.01,-.052,1.35),(.12,-.052,1.35)),((.12,-.052,1.35),(.18,-.052,1.25)),((.01,-.052,1.42),(.10,-.052,1.42))]:line(a,b,.012,6)
  else:text('Symbol',value,(0,-.040,1.39),.39,6)
 save(name,'signs')
for length,name in [(1.2,'ConcreteBarrierShort'),(2.4,'ConcreteBarrierLong'),(2.0,'PlasticBarrierOrange')]:
 hull('Barrier',[(-.25,length/2,.02,.70),(.25,length/2,.02,.70)],8 if name.startswith('Plastic') else 2)
 for x in [-length*.32,length*.32]:box('Foot',(x,0,.05),(.30,.65,.10),8 if name.startswith('Plastic') else 2)
 if name.startswith('Plastic'):
  for x in [-.65,0,.65]:box('Rib',(x,-.267,.4),(.05,.03,.50),8)
 save(name,'traffic')
for x in [-1.2,1.2]:box('Post',(x,0,.45),(.11,.13,.90),2)
box('Rail',(0,-.08,.60),(2.7,.14,.14),2);box('Rail',(0,-.08,.80),(2.7,.14,.10),2);save('RoadGuardrail','traffic')
for x in [-.65,.65]:
 box('Foot',(x,0,.035),(.22,.22,.07),2);cyl('Post',(x,0,.45),.045,.84,10)
for i in range(19):
 x=-.60+i*.0667;z=.67+.18*(x/.60)**2;torus((x,0,z),.038,.009,10,(math.pi/2,0,0) if i%2==0 else (0,math.pi/2,0))
save('ChainBarrier','traffic')
for wall,name in [(False,'EVChargerPedestal'),(True,'EVChargerWall')]:
 h=.9 if wall else 1.45;box('Case',(0,0,h/2),(.34,.23,h),3,.03)
 box('Front',(0,-.129,h*.69),(.25,.024,.40),9);box('Screen',(0,-.15,h*.77),(.14,.012,.16),14)
 points=[(.20,0,h*.75),(.32,-.05,h*.56),(.33,-.06,.20),(.25,-.06,.10),(.12,-.12,.20),(.13,-.14,h*.51)]
 for a,b in zip(points,points[1:]):line(a,b,.018,0)
 box('Plug',(.13,-.16,h*.53),(.05,.07,.12),1);save(name,'service')
frame(1.65,2.25,2)
for x in [-.39,.39]:box('LiftDoor',(x,-.048,1.10),(.76,.025,2.12),3)
box('Buttons',(.91,-.03,1.16),(.14,.08,.37),1);text('Up','^',(.91,-.078,1.25),.12,6);text('Down','v',(.91,-.078,1.05),.12,6)
box('Sill',(0,-.05,.025),(1.9,.30,.05),2);save('ServiceElevatorFront','structure')
def arrow(x,y,z,size=1):
 verts=[(x-.12*size,y-.55*size,z),(x+.12*size,y-.55*size,z),(x+.12*size,y+.10*size,z),(x+.36*size,y+.10*size,z),(x,y+.55*size,z),(x-.36*size,y+.10*size,z),(x-.12*size,y+.10*size,z)]
 mesh('Arrow',verts,[(0,1,2,3,4,5,6)],6)
box('Tile',(0,0,.035),(2,2,.07),2);arrow(0,0,.074,1.2);save('RoadArrowTile','markings')
box('Tile',(0,0,.035),(2,2,.07),2)
for x in [-1.25,-.8,-.35,.10,.55,1.0]:
 polygon=[(x-.075-.44,-.92),(x+.075-.44,-.92),(x+.075+.44,.92),(x-.075+.44,.92)]
 for edge,sign in [(-.92,1),(.92,-1)]:
  clipped=[]
  for a,b in zip(polygon,polygon[1:]+polygon[:1]):
   ia=(a[0]-edge)*sign>=0;ib=(b[0]-edge)*sign>=0
   if ia:clipped.append(a)
   if ia!=ib:
    t=(edge-a[0])/(b[0]-a[0]);clipped.append((edge,a[1]+t*(b[1]-a[1])))
  polygon=clipped
 if len(polygon)>2:mesh('HatchStripe',[(a,b,.076) for a,b in polygon],[tuple(range(len(polygon)))],10)
save('YellowHatchTile','markings')
box('Tile',(0,0,.035),(2,2,.07),2)
for x in [-.2,.2]:
 for i in range(23):
  y=-.9+i*.08;xx=x+.10*math.sin(y*2)
  o=box('TyrePrint',(xx,y,.075),(.16,.025,.006),1,0);o.rotation_euler.z=.25
save('TyreTrackTile','markings')
# Drive-through module, open at both ends, with separate roof / wall primitives.
box('Floor',(0,0,.05),(3.4,3.2,.10),2)
for x in [-1.6,1.6]:
 box('SideWall',(x,0,1.35),(.18,3.2,2.6),2)
 box('CurbStripe',(x- math.copysign(.105,x),0,.20),(.03,3.15,.18),10,0)
box('Roof',(0,0,2.69),(3.55,3.30,.14),2)
for x in [-1.1,0,1.1]:box('CeilingLight',(x,0,2.60),(.62,.25,.035),6)
arrow(0,-.45,.106,1.3);save('ParkingEntryTunnel','structure')
mesh('Ramp',[(-1.6,-1.6,0),(1.6,-1.6,0),(1.6,1.6,.65),(-1.6,1.6,.65),(-1.6,-1.6,-.12),(1.6,-1.6,-.12),(1.6,1.6,.50),(-1.6,1.6,.50)],[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],2)
for x in [-1.55,1.55]:
 for y in [-1.2,0,1.2]:line((x,y,.35+.203*y),(x,y,1.1+.203*y),.03,10)
 line((x,-1.4,.81),(x,1.4,1.39),.04,2)
mesh('RampArrow',[(-.13,-.9,.15),(.13,-.9,.15),(.13,.3,.395),(.40,.3,.395),(0,.85,.507),(-.40,.3,.395),(-.13,.3,.395)],[(0,1,2,3,4,5,6)],6)
save('ParkingRampModule','structure')

# Reuse the same export, palette and catalog conventions as the office expansion.
tail=(BASE/'tools'/'build_office_zones.py').read_text(encoding='utf-8').split("exec(compile(source.split('# One palette texture")[1]
tail="exec(compile(source.split('# One palette texture"+tail
tail=tail.replace('OfficeZones','ParkingKit').replace("(i%8)*4,(i//8)*4","(i%8)*6,(i//8)*6")
tail=tail.replace("d=bpy.data.cameras.new('ZonesCamera')", "for c in preview.objects:\n if c.type=='MESH' and (c.name.startswith(('Sedan','Hatchback','SUV','ServiceVan','Motorcycle','BicycleBlue','BulletSecurity'))):c.rotation_euler.z=-.65\nd=bpy.data.cameras.new('ZonesCamera')")
exec(compile(tail,'parking_export','exec'))
