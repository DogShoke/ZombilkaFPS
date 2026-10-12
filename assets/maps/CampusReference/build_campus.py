import bpy, math, random, os
from mathutils import Vector
random.seed(27)
OUT = r'C:\Roblox\ZombilkaFPS\assets\maps\CampusReference'
scene=bpy.data.scenes.new('Zombilka_Campus')
bpy.context.window.scene=scene
root=bpy.data.collections.new('Campus_Map'); scene.collection.children.link(root)
groups={}
def group(n):
    if n not in groups:
        groups[n]=bpy.data.collections.new(n); root.children.link(groups[n])
    return groups[n]
def mat(n,c,metal=0,rough=.7,emit=0):
    m=bpy.data.materials.new('Campus_'+n); m.diffuse_color=(*c,1); m.use_nodes=True
    p=next(x for x in m.node_tree.nodes if x.type=='BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value=(*c,1); p.inputs['Roughness'].default_value=rough; p.inputs['Metallic'].default_value=metal
    if emit: p.inputs['Emission Color'].default_value=(*c,1); p.inputs['Emission Strength'].default_value=emit
    return m
con=mat('Concrete',(.29,.33,.34)); trim=mat('Limestone',(.55,.57,.53)); asphalt=mat('Asphalt',(.075,.09,.105)); glass=mat('BlueGlass',(.055,.15,.19),.65,.2)
steel=mat('Steel',(.11,.14,.16),.6); grass=mat('Ground',(.075,.12,.085)); leaf=mat('Pine',(.035,.12,.09)); leaf2=mat('Foliage',(.1,.19,.11)); bark=mat('Bark',(.14,.1,.075)); white=mat('Markings',(.65,.68,.62)); amber=mat('WarmLight',(1,.62,.25),emit=3); water=mat('Water',(.06,.2,.23),.45,.16)
red=mat('Red',(.32,.07,.045)); blue=mat('Blue',(.09,.16,.2)); sand=mat('Sand',(.45,.38,.25)); rubber=mat('Rubber',(.025,.028,.03))
def put(o,n,m,g):
    o.name=n; o.data.materials.append(m)
    for c in list(o.users_collection): c.objects.unlink(o)
    group(g).objects.link(o); return o
def box(n,p,s,m,g='Architecture',rot=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p); o=bpy.context.object; o.scale=s; o.rotation_euler.z=rot
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); return put(o,n,m,g)
def cyl(n,p,r,h,m,g='Props',verts=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=h,location=p); return put(bpy.context.object,n,m,g)
def pine(x,y,h=10):
    cyl('PineTrunk',(x,y,h*.28),.22,h*.56,bark,'Forest',8)
    for k in range(3):
        bpy.ops.mesh.primitive_cone_add(vertices=9,radius1=h*(.24-.045*k),radius2=0,depth=h*.48,location=(x,y,h*(.48+.18*k)))
        put(bpy.context.object,'PineCrown',leaf,'Forest')
def tree(x,y,z=0):
    cyl('TreeTrunk',(x,y,z+2),.18,4,bark,'Landscape',8)
    for dx,dy,dz in [(0,0,0),(1,0,-.4),(-.8,.6,-.2)]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=2.2,location=(x+dx,y+dy,z+5+dz)); put(bpy.context.object,'TreeCanopy',leaf2,'Landscape')
def planter(x,y,sx=8,sy=3,z=0):
    box('Planter',(x,y,z+.5),(sx,sy,1),trim,'Landscape'); box('Soil',(x,y,z+1.02),(sx-.4,sy-.4,.1),grass,'Landscape'); tree(x,y,z+1)
def lamp(x,y,z=0):
    cyl('LampPole',(x,y,z+3),.09,6,steel,'Lighting'); box('LampHead',(x,y,z+6),(1.1,.5,.18),steel,'Lighting'); box('LampGlow',(x,y,z+5.88),(.8,.35,.05),amber,'Lighting')
def stairs(x,y,width,run,rise,n=12):
    for i in range(n): box('Stair',(x,y+run*(i+.5)/n,rise*(i+1)/n/2),(width,run/n,rise*(i+1)/n),trim,'Stairs')
def building(n,x,y,w,d,h):
    box(n+'_Floor',(x,y,.22),(w,d,.44),con)
    box(n+'_Back',(x,y+d/2-.25,h/2),(w,.5,h),con)
    for side in [-1,1]: box(n+'_Side',(x+side*w/2,y,h/2),(.5,d,h),con)
    # Open interior behind segmented facade, entrance gap in centre.
    for xx in range(int(-w/2+2),int(w/2),4):
        if abs(xx)<4: continue
        box(n+'_Window',(x+xx,y-d/2,h*.48),(3.8,.16,h*.78),glass)
        box(n+'_Mullion',(x+xx-2,y-d/2,h*.5),(.12,.4,h),steel)
    box(n+'_Header',(x,y-d/2,h-.5),(w,.8,1),trim)
    box(n+'_Roof',(x,y,h+.2),(w+1,d+1,.4),con)
    for yy in [-d/2,d/2]: box(n+'_Parapet',(x,y+yy,h+.9),(w,.3,1.4),trim)
    for xx in [-w/2,w/2]: box(n+'_Parapet',(x+xx,y,h+.9),(.3,d,1.4),trim)
    for xx in [-w*.3,w*.3]:
        box('HVAC',(x+xx,y+d*.2,h+1),(3,2,1.6),steel,'Rooftops')
        cyl('HVACFan',(x+xx,y+d*.2,h+1.86),.65,.1,con,'Rooftops')
    for xx in range(int(-w/2+6),int(w/2-3),9):
        box('OfficeDesk',(x+xx,y,1.1),(2,1,.16),trim,'Interiors'); box('Monitor',(x+xx,y+.2,1.5),(.8,.12,.6),steel,'Interiors')
    box('InteriorLight',(x,y-d/2+.5,h-.9),(w-2,.15,.15),amber,'Lighting')
box('Terrain',(0,0,-.65),(240,220,1),grass,'Ground')
box('CampusPaving',(0,6,-.12),(196,174,.24),trim,'Ground')
box('ParkingAsphalt',(-24,-48,.03),(138,65,.12),asphalt,'Parking')
box('ServiceAsphalt',(74,-18,.03),(42,120,.12),asphalt,'Service')
box('OuterRoad',(0,-91,.03),(214,11,.15),asphalt,'Ground')
for x in range(-98,100,9): box('RoadDash',(x,-91,.12),(4,.18,.02),white,'Markings')
building('Atrium',0,63,66,30,17)
building('WestWing',-57,35,42,47,9)
building('EastWing',57,35,42,47,9)
building('WestAnnex',-69,68,28,22,12)
building('EastAnnex',72,69,30,22,12)
for x in [-57,57]:
    box('Terrace',(x,5,2),(42,16,4),con)
    stairs(x,-13,12,10,4)
    for xx in [-12,12]: planter(x+xx,5,6,3,4)
    for xx in [-10,10]:
        box('TerraceTable',(x+xx,9,4.9),(2,2,.15),sand,'Rooftops')
        for dx in [-1.5,1.5]: box('TerraceSeat',(x+xx+dx,9,4.5),(.8,.8,.9),con,'Rooftops')
for x in [-22,22]: stairs(x,38,10,10,3,10)
box('AtriumEntryDeck',(0,45,1.5),(66,6,3),con)
# Upper facade grid gives the central atrium its recognizable rhythm.
for x in range(-32,33,4): box('AtriumFin',(x,47.8,9),(.2,.6,16),trim)
box('AtriumTransom',(0,47.5,8.5),(66,.3,.2),steel)
for x in [-37,37]: box('SkyBridge',(x,40,7),(12,5,.5),trim)
cyl('FountainRim',(0,11,.4),9,.8,con,'Plaza',48); cyl('FountainWater',(0,11,.84),8.3,.08,water,'Plaza',48)
cyl('SculptureBase',(0,11,1.2),2.2,1,trim,'Plaza')
for a in [0,math.pi/2,math.pi/4]:
    bpy.ops.mesh.primitive_torus_add(major_radius=3,minor_radius=.12,major_segments=32,minor_segments=8,location=(0,11,4.5),rotation=(math.pi/2,0,a)); put(bpy.context.object,'OrbitalSculpture',steel,'Plaza')
for x,y in [(-28,22),(28,22),(-28,-2),(28,-2),(-43,-15),(43,-15)]: planter(x,y,9,4)
for x in [-19,19]:
    for y in [-9,24]: box('Bench',(x,y,.6),(4,.9,1.2),bark,'Plaza')
for x in range(-87,43,10):
    for y in [-70,-51,-31]:
        box('BayLine',(x,y,.13),(.12,8,.03),white,'Markings')
        if random.random()<.7:
            cx=x+4.5; cy=y; m=random.choice([white,steel,blue,red,sand])
            box('CarBody',(cx,cy,.8),(3.8,1.9,.9),m,'Vehicles',math.pi/2)
            box('CarCabin',(cx,cy,1.5),(2,1.65,.65),glass,'Vehicles',math.pi/2)
            for dx in [-.95,.95]:
                for dy in [-1.2,1.2]:
                    o=cyl('Wheel',(cx+dx,cy+dy,.55),.43,.25,rubber,'Vehicles'); o.rotation_euler.y=math.pi/2
for x in [-78,-45,-12,21]:
    planter(x,-41,13,3); lamp(x,-41)
for y in [-76,-24]:
    for i in range(7): box('Crosswalk',(-6+i*.8,y,.14),(.45,7,.03),white,'Markings')
building('Warehouse',80,-39,28,35,8)
for y in [-62,-10,4]:
    box('Container',(75,y,1.5),(12,4.8,3),random.choice([red,blue]),'Service')
    for xx in range(70,81): box('ContainerRib',(xx,y-2.43,1.5),(.09,.06,2.8),steel,'Service')
for x in [60,67,90]:
    box('UtilityUnit',(x,-69,1.5),(3,3,3),steel,'Service'); cyl('CoolingFan',(x,-69,3.08),1,.12,con,'Service')
for y in [-58,-19]:
    box('LoadingCanopy',(80,y,4.5),(26,4,.35),trim,'Service')
    for x in [68,92]: box('CanopyPost',(x,y,2.3),(.25,.25,4.6),steel,'Service')
for x in [-98,98]:
    for y in range(-79,88,8): box('FencePost',(x,y,1.6),(.18,.18,3.2),steel,'Perimeter')
    for z in [.7,2.5]: box('FenceRail',(x,3,z),(.1,166,.1),steel,'Perimeter')
for x in list(range(-98,-10,8))+list(range(18,99,8)):
    box('FencePost',(x,-80,1.6),(.18,.18,3.2),steel,'Perimeter')
    box('FencePanel',(x,-80,1.4),(7.9,.1,2.4),steel,'Perimeter')
building('Security',15,-76,9,7,4)
for x in [-10,10]: box('GatePillar',(x,-80,3),(1.5,2,6),con,'Perimeter')
box('GateHeader',(0,-80,6),(22,2,1),trim,'Perimeter'); box('Barrier',(0,-76,1.2),(14,.2,.18),white,'Perimeter')
for x,y in [(-90,-20),(-90,20),(-90,65),(46,-62),(50,-20),(91,-70),(91,-5),(-15,-77),(15,-77),(-20,33),(20,33)]: lamp(x,y)
for i in range(165):
    x=random.uniform(-116,116); y=random.uniform(-103,103)
    if abs(x)>101 or y>89 or y< -97: pine(x,y,random.uniform(7,14))
for i in range(32):
    x=random.choice([-1,1])*random.uniform(102,118); y=random.uniform(-90,90)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=random.uniform(1,3),location=(x,y,0)); o=put(bpy.context.object,'Rock',con,'Forest'); o.scale.z=.6
# Camera and studio lighting, separate from exported map.
pres=bpy.data.collections.new('Presentation'); scene.collection.children.link(pres)
def presentation(o):
    for c in list(o.users_collection): c.objects.unlink(o)
    pres.objects.link(o)
bpy.ops.object.camera_add(location=(178,-220,184)); cam=bpy.context.object; presentation(cam); cam.rotation_euler=(Vector((0,10,0))-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.type='ORTHO'; cam.data.ortho_scale=283; scene.camera=cam
bpy.ops.object.light_add(type='SUN',location=(0,0,100)); sun=bpy.context.object; presentation(sun); sun.rotation_euler=(.5,-.4,-.6); sun.data.energy=2.5; sun.data.angle=.15
bpy.ops.object.light_add(type='AREA',location=(0,-40,100)); light=bpy.context.object; presentation(light); light.data.energy=95000; light.data.shape='DISK'; light.data.size=140
scene.world=bpy.data.worlds.new('CampusWorld'); scene.world.use_nodes=True; bg=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND'); bg.inputs[0].default_value=(.15,.2,.28,1); bg.inputs[1].default_value=.5
scene.render.resolution_x=1600; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
try: scene.render.engine='CYCLES'
except TypeError: pass
scene.cycles.samples=24
scene.render.filepath=os.path.join(OUT,'Campus_preview.png')
scene['design']='Reference-inspired campus; 240 x 220 metres; Roblox scale 3.5 studs/metre. Art prototype, runtime integration pending.'
bpy.ops.object.select_all(action='DESELECT')
for o in root.all_objects:
    if o.type=='MESH': o.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'Campus.blend'))
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,'Campus.fbx'),use_selection=True,add_leaf_bones=False,axis_forward='-Z',axis_up='Y')
print('Saved campus:',len(root.all_objects),'meshes; triangles',sum(len(o.data.polygons) for o in root.all_objects if o.type=='MESH'))
exec(compile(open(os.path.join(OUT,'detail_campus.py'),encoding='utf-8').read(),'detail_campus.py','exec'))
