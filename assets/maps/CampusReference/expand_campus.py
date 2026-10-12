"""Run in Blender with Campus.blend open. Original file is preserved on disk.
Fast spatially batched geometry, deterministic seed. No external assets.
"""
import bpy, math, random, os, json
from mathutils import Vector, Matrix
random.seed(1012)
OUT=r'C:\Roblox\ZombilkaFPS\assets\maps\CampusReference'
scene=bpy.context.scene
if scene.get('expanded_v2'):
    raise RuntimeError('Expanded scene already present. Open original Campus.blend before rerunning.')
root=bpy.data.collections['Campus_Map']
extra=bpy.data.collections.new('Campus_Expansion_V2'); scene.collection.children.link(extra)
pres=bpy.data.collections['Presentation']
materials=[]
def material(n,c,metal=0,rough=.6,emission=0):
    m=bpy.data.materials.get('Campus_'+n)
    if m is None:
        m=bpy.data.materials.new('Campus_'+n); m.use_nodes=True
        p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        p.inputs['Base Color'].default_value=(*c,1); p.inputs['Roughness'].default_value=rough; p.inputs['Metallic'].default_value=metal
        if emission: p.inputs['Emission Color'].default_value=(*c,1); p.inputs['Emission Strength'].default_value=emission
        m.diffuse_color=(*c,1)
    if m not in materials: materials.append(m)
    return materials.index(m)
CON=material('Concrete',(.29,.33,.34)); STONE=material('Limestone',(.55,.57,.53)); ROAD=material('Asphalt',(.075,.09,.105)); GLASS=material('BlueGlass',(.055,.15,.19),.4,.17)
METAL=material('Steel',(.11,.14,.16),.6,.4); GRASS=material('Ground',(.075,.12,.085)); LEAF=material('Pine',(.035,.12,.09)); LEAF2=material('Foliage',(.1,.19,.11)); WOOD=material('Bark',(.14,.1,.075)); WHITE=material('Markings',(.65,.68,.62)); WARM=material('WarmLight',(1,.62,.25),emission=3); WATER=material('Water',(.06,.2,.23),.45,.16)
RED=material('Red',(.32,.07,.045)); BLUE=material('Blue',(.09,.16,.2)); SAND=material('Sand',(.45,.38,.25)); RUBBER=material('Rubber',(.025,.028,.03))
ORANGE=material('SafetyOrange',(.9,.29,.045)); YELLOW=material('SafetyYellow',(.91,.65,.13)); PANEL=material('Cladding',(.38,.42,.43),.28,.52); DARK=material('InteriorDark',(.1,.12,.125)); FLOOR=material('InteriorFloor',(.35,.31,.26)); SOIL=material('Soil',(.085,.062,.045)); SOLAR=material('SolarCells',(.035,.075,.14),.6,.2); IVORY=material('Ivory',(.73,.72,.64)); CHROME=material('Chrome',(.5,.54,.57),.8,.2); LED=material('ColdLED',(.45,.79,1),emission=2); TAIL=material('TailLight',(.8,.035,.012),emission=1.2); BRICK=material('Brick',(.28,.16,.11)); MOSS=material('Moss',(.12,.17,.08)); WALK=material('Walkway',(.36,.39,.38))
# Procedural surface variation for the Blender preview. FBX needs baked texture later.
for idx,scale,strength,lo,hi in [(ROAD,32,.12,(.028,.038,.046,1),(.12,.135,.145,1)),(CON,13,.08,(.22,.25,.26,1),(.38,.41,.4,1)),(STONE,9,.055,(.4,.43,.4,1),(.63,.64,.6,1)),(GRASS,2,.14,(.05,.065,.038,1),(.16,.2,.095,1)),(WOOD,7,.1,(.065,.04,.024,1),(.2,.13,.075,1))]:
    m=materials[idx]; nt=m.node_tree; p=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED')
    tc=nt.nodes.new('ShaderNodeTexCoord'); noise=nt.nodes.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value=scale; noise.inputs['Detail'].default_value=3
    nt.links.new(tc.outputs['Object'],noise.inputs['Vector'])
    ramp=nt.nodes.new('ShaderNodeValToRGB'); ramp.color_ramp.elements[0].color=lo; ramp.color_ramp.elements[1].color=hi
    nt.links.new(noise.outputs['Fac'],ramp.inputs['Fac']); nt.links.new(ramp.outputs['Color'],p.inputs['Base Color'])
    bump=nt.nodes.new('ShaderNodeBump'); bump.inputs['Strength'].default_value=strength; bump.inputs['Distance'].default_value=.025
    nt.links.new(noise.outputs['Fac'],bump.inputs['Height']); nt.links.new(bump.outputs['Normal'],p.inputs['Normal'])
p=next(n for n in materials[GLASS].node_tree.nodes if n.type=='BSDF_PRINCIPLED'); p.inputs['Metallic'].default_value=.32; p.inputs['Roughness'].default_value=.16; p.inputs['Transmission Weight'].default_value=.12
# One mesh per district/category/spatial cell, preserving separate material slots.
batches={}; counts={}; lights=[]; labels=[]
def batch(cat,pos):
    k=(cat,math.floor(pos[0]/32),math.floor(pos[1]/32))
    if k not in batches: batches[k]=[[],[],[]]
    return batches[k]
def add(cat,pos,verts,faces,mat):
    b=batch(cat,pos); base=len(b[0]); b[0].extend(verts); b[1].extend(tuple(base+i for i in f) for f in faces); b[2].extend([mat]*len(faces)); counts[cat]=counts.get(cat,0)+1
CUBE=[(-.5,-.5,-.5),(.5,-.5,-.5),(.5,.5,-.5),(-.5,.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(.5,.5,.5),(-.5,.5,.5)]
FACES=[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)]
def box(cat,p,s,m,angle=0):
    if cat=='GroundV2': p=(p[0],p[1],p[2]+counts.get(cat,0)*.00025)
    c=math.cos(angle); t=math.sin(angle)
    add(cat,p,[(p[0]+x*s[0]*c-y*s[1]*t,p[1]+x*s[0]*t+y*s[1]*c,p[2]+z*s[2]) for x,y,z in CUBE],FACES,m)
def rod(cat,a,b,r,m,n=10,r2=None):
    a=Vector(a); b=Vector(b); q=(b-a).to_track_quat('Z','Y'); verts=[]
    for pt,rr in [(a,r),(b,r if r2 is None else r2)]:
        for i in range(n): verts.append(tuple(pt+q@Vector((rr*math.cos(2*math.pi*i/n),rr*math.sin(2*math.pi*i/n),0))))
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    add(cat,tuple(a),verts,faces,m)
def cylinder(cat,p,r,h,m,n=12): rod(cat,(p[0],p[1],p[2]-h/2),(p[0],p[1],p[2]+h/2),r,m,n)
def beam(cat,a,b,w,h,m):
    a=Vector(a); b=Vector(b); q=(b-a).to_track_quat('Z','Y'); mid=(a+b)/2
    add(cat,tuple(mid),[tuple(mid+q@Vector((x*w,y*h,z*(b-a).length))) for x,y,z in CUBE],FACES,m)
def sphere(cat,p,r,m,n=10,levels=6,s=(1,1,1)):
    vs=[]
    for j in range(levels+1):
        phi=math.pi*j/levels
        for i in range(n):
            a=2*math.pi*i/n; vs.append((p[0]+math.sin(phi)*math.cos(a)*r*s[0],p[1]+math.sin(phi)*math.sin(a)*r*s[1],p[2]+math.cos(phi)*r*s[2]))
    fs=[(j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i) for j in range(levels) for i in range(n)]
    add(cat,p,vs,fs,m)
def text(body,p,size=1,angle=0): labels.append((body,p,size,angle))
def pine(x,y,h=12):
    rod('Forest',(x,y,0),(x,y,h*.75),.23,WOOD,8,.12)
    for j in range(5): rod('Forest',(x,y,h*(.28+j*.12)),(x,y,h*(.63+j*.095)),h*(.235-j*.034),LEAF if j%2 else LEAF2,11,.035)
def tree(x,y,z=0):
    rod('Landscape',(x,y,z),(x,y,z+5),.24,WOOD,9,.1)
    for a in [0,2.1,4.2]:
        dx=math.cos(a)*1.5; dy=math.sin(a)*1.5
        beam('Landscape',(x,y,z+2.4),(x+dx,y+dy,z+5),.14,.13,WOOD)
        sphere('Landscape',(x+dx,y+dy,z+5.7),2.4,LEAF2,9,5,(1,1,.9))
    sphere('Landscape',(x,y,z+7),2.3,LEAF2,10,5)
def hedge(x,y,sx,sy,z=0):
    box('Landscape',(x,y,z+.36),(sx,sy,.72),STONE)
    box('Landscape',(x,y,z+.76),(sx-.25,sy-.25,.1),SOIL)
    for xx in range(max(1,int(sx/1.2))):
        sphere('Landscape',(x-sx/2+.7+xx*1.2,y,z+1.1),.7,LEAF2,8,4,(1,sy*.5,1))
def planter(x,y,sx=7,sy=3,z=0):
    box('Landscape',(x,y,z+.4),(sx,sy,.8),STONE); box('Landscape',(x,y,z+.86),(sx-.3,sy-.3,.1),SOIL)
    tree(x,y,z+.9)
    for i in range(5): sphere('Landscape',(x+random.uniform(-sx*.35,sx*.35),y+random.uniform(-sy*.3,sy*.3),z+1.05),.36,MOSS,7,4)
def lamp(x,y,z=0,double=False):
    cylinder('StreetFurniture',(x,y,z+.12),.25,.24,METAL)
    rod('StreetFurniture',(x,y,z+.2),(x,y,z+6),.09,METAL,10,.06)
    beam('StreetFurniture',(x,y,z+6),(x+.9,y,z+6),.08,.08,METAL)
    box('StreetFurniture',(x+.8,y,z+6),(1,.42,.13),METAL); box('StreetFurniture',(x+.8,y,z+5.91),(.8,.3,.04),WARM)
    lights.append(((x+.8,y,z+5.7),600))
def bench(x,y,z=0,angle=0):
    for i in range(5): box('StreetFurniture',(x,y-.38+i*.19,z+.5),(2.8,.14,.08),WOOD,angle)
    for dx in [-1,1]:
        box('StreetFurniture',(x+dx,y,z+.24),(.12,.72,.48),METAL)
        beam('StreetFurniture',(x+dx,y+.4,z+.4),(x+dx,y+.55,z+1.2),.1,.1,METAL)
    for zz in [.85,1.08]: box('StreetFurniture',(x,y+.5,z+zz),(2.8,.09,.15),WOOD)
def chair(x,y,z=0,angle=0):
    c=math.cos(angle); t=math.sin(angle)
    def pos(dx,dy,dz): return (x+dx*c-dy*t,y+dx*t+dy*c,z+dz)
    box('Furniture',pos(0,0,.47),(.65,.65,.1),WOOD,angle)
    box('Furniture',pos(0,.28,.82),(.65,.09,.6),WOOD,angle)
    for dx in [-.25,.25]:
        for dy in [-.25,.25]: box('Furniture',pos(dx,dy,.23),(.055,.055,.46),METAL,angle)
def table(x,y,z=0):
    cylinder('Furniture',(x,y,z+.82),.86,.12,WOOD,20); cylinder('Furniture',(x,y,z+.4),.065,.8,METAL)
    cylinder('Furniture',(x,y,z+.08),.4,.08,METAL)
    for a in [0,math.pi/2,math.pi,math.pi*1.5]: chair(x+math.sin(a)*1.35,y+math.cos(a)*1.35,z,a)
def bollard(x,y):
    cylinder('StreetFurniture',(x,y,.48),.1,.96,METAL); cylinder('StreetFurniture',(x,y,.7),.105,.14,WHITE)
def rubbish(x,y):
    box('StreetFurniture',(x,y,.58),(.6,.6,1.16),METAL)
    for xx in [-.18,0,.18]: box('StreetFurniture',(x+xx,y-.31,.55),(.04,.04,.85),CHROME)
    box('StreetFurniture',(x,y,1.18),(.65,.65,.08),METAL)
def handrail(a,b,z=1):
    a=Vector(a); b=Vector(b)
    rod('Rails',a+Vector((0,0,z)),b+Vector((0,0,z)),.04,METAL)
    for i in range(max(2,int((b-a).length/2))+1):
        p=a.lerp(b,i/max(2,int((b-a).length/2))); rod('Rails',p,p+Vector((0,0,z)),.035,METAL)
def steps(x,y,w,run,rise,z=0,n=16):
    for i in range(n):
        zz=z+rise*(i+1)/n; box('Stairs',(x,y+run*(i+.5)/n,(z+zz)/2),(w,abs(run)/n,zz-z),STONE)
        box('Stairs',(x,y+run*i/n+.05,zz+.013),(w,.09,.025),METAL)
    for dx in [-w/2+.15,w/2-.15]: handrail((x+dx,y,z),(x+dx,y+run,z+rise))
def roof_access(xleft,yfront,rise):
    run=rise*1.2
    steps(xleft-2.3,yfront,4,run,rise/2,n=max(12,int(rise*2.5)))
    box('Stairs',(xleft,yfront+run+1,rise/2-.12),(9,2,.24),CON)
    handrail((xleft-4.5,yfront+run+2,rise/2),(xleft+4.5,yfront+run+2,rise/2))
    steps(xleft+2.3,yfront+run,4,-run,rise/2,z=rise/2,n=max(12,int(rise*2.5)))
    box('Stairs',(xleft+5,yfront+.8,rise-.12),(6,2.4,.24),CON)
    handrail((xleft+2,yfront-.4,rise),(xleft+8,yfront-.4,rise))
def drain(x,y,sx=1.8,sy=.6):
    box('Utilities',(x,y,.075),(sx,sy,.05),METAL)
    for i in range(12): box('Utilities',(x-sx/2+(i+.5)*sx/12,y,.11),(.035,sy-.06,.015),CHROME)
def pallet(x,y,z=0):
    for dx in [-.44,0,.44]: box('Cargo',(x+dx,y,z+.1),(.14,1,.2),WOOD)
    for dy in [-.44,-.22,0,.22,.44]: box('Cargo',(x,y+dy,z+.24),(1.2,.15,.08),WOOD)
def cargo(x,y,z=0):
    pallet(x,y,z); box('Cargo',(x,y,z+.82),(1.04,.9,1.08),SAND)
    for dx in [-.35,.35]: box('Cargo',(x+dx,y-.46,z+.84),(.065,.015,1.06),IVORY)
    box('Cargo',(x,y-.47,z+.95),(.23,.02,.14),WHITE)
def pipe(a,b,r=.12): rod('Utilities',a,b,r,CHROME)
def hvac(x,y,z=0,w=3):
    box('RoofEquipment',(x,y,z+.8),(w,2,1.6),PANEL)
    for xx in [-w*.22,w*.22]:
        cylinder('RoofEquipment',(x+xx,y,z+1.65),.64,.15,METAL,20)
        cylinder('RoofEquipment',(x+xx,y,z+1.75),.12,.12,CHROME)
        for a in [0,math.pi/3,2*math.pi/3]: box('RoofEquipment',(x+xx,y,z+1.78),(1.05,.1,.02),CHROME,a)
        for j in range(8): box('RoofEquipment',(x+xx-.55+j*.15,y-1.02,z+.8),(.045,.04,1.1),METAL)
    box('RoofEquipment',(x,y+2,z+.55),(w*.7,2,.9),CHROME)
    for yy in [1.1,1.5,1.9,2.3,2.7]: box('RoofEquipment',(x,y+yy,z+.55),(w*.7+.08,.06,1),METAL)
def container(x,y,m=BLUE):
    box('Logistics',(x,y,1.5),(12,4.8,3),m)
    for i in range(41): box('Logistics',(x-5.9+i*.29,y-2.42,1.5),(.075,.06,2.78),PANEL)
    for side in [-1,1]:
        box('Logistics',(x+side*6.02,y,1.5),(.06,4.65,2.85),m)
        for dy in [-1.5,-.4,.4,1.5]: pipe((x+side*6.08,y+dy,.2),(x+side*6.08,y+dy,2.8),.04)
    for dx in [-5.8,5.8]:
        for dy in [-2.2,2.2]: box('Logistics',(x+dx,y+dy,1.5),(.16,.16,3.1),CHROME)
def car(x,y,m=BLUE,angle=0,van=False):
    c=math.cos(angle); s=math.sin(angle)
    def p(dx,dy,dz): return (x+dx*c-dy*s,y+dx*s+dy*c,dz)
    # Front is -Y; bevel modifiers applied only to vehicle chunks.
    box('VehiclesV2',p(0,0,.62),(1.88,4.45,.46),m,angle)
    box('VehiclesV2',p(0,0,1.02),(1.87,3.9,.32),m,angle)
    box('VehiclesV2',p(0,.18,1.45),(1.6,2.05,.57),GLASS,angle)
    box('VehiclesV2',p(0,.28,1.78),(1.7,1.75,.1),m,angle)
    if van: box('VehiclesV2',p(0,.8,1.64),(1.85,2.7,1.1),m,angle)
    for dy in [-.75,.12,1.13]: box('VehiclesV2',p(0,dy,1.48),(1.68,.07,.65),m,angle)
    for dx in [-.94,.94]:
        for dy in [-1.38,1.4]:
            a=p(dx-.12,dy,.53); b=p(dx+.12,dy,.53); rod('VehiclesV2',a,b,.45,RUBBER,18)
            side=1 if dx>0 else -1
            a=p(dx+side*.13,dy,.53); b=p(dx+side*.145,dy,.53); rod('VehiclesV2',a,b,.28,CHROME,16)
            for ang in range(0,360,60):
                aa=math.radians(ang); beam('VehiclesV2',p(dx+side*.15,dy,.53),p(dx+side*.15,dy+math.sin(aa)*.22,.53+math.cos(aa)*.22),.04,.04,METAL)
        for dy in [-.42,.85]:
            box('VehiclesV2',p(dx,dy,.99),(.025,.025,.4),METAL,angle)
            box('VehiclesV2',p(dx,dy+.12,1.1),(.04,.22,.055),CHROME,angle)
        box('VehiclesV2',p(dx*1.12,-.55,1.35),(.28,.3,.12),m,angle)
    for dx in [-.62,.62]:
        box('VehiclesV2',p(dx,-2.18,.9),(.45,.07,.21),LED,angle)
        box('VehiclesV2',p(dx,2.17,.9),(.35,.07,.24),TAIL,angle)
    box('VehiclesV2',p(0,-2.23,.57),(1.76,.11,.14),METAL,angle)
    box('VehiclesV2',p(0,2.23,.57),(1.76,.11,.14),METAL,angle)
    box('VehiclesV2',p(0,-2.25,.83),(.48,.04,.12),WHITE,angle)
    for dx in [-.25,0,.25]: box('VehiclesV2',p(dx,-2.23,.68),(.12,.035,.06),CHROME,angle)
    for dx in [-.45,.45]:
        box('VehiclesV2',p(dx,.15,1.25),(.48,.65,.15),DARK,angle)
        box('VehiclesV2',p(dx,.48,1.49),(.48,.12,.5),DARK,angle)
def truck(x,y):
    box('VehiclesV2',(x,y,1),(2.5,9,.6),METAL)
    box('VehiclesV2',(x,y+1.4,2.9),(2.7,6.2,3.7),IVORY)
    box('VehiclesV2',(x,y-3,1.8),(2.65,2.5,2.1),BLUE)
    box('VehiclesV2',(x,y-4.27,2.1),(2.35,.06,.8),GLASS)
    for dx in [-1.32,1.32]:
        box('VehiclesV2',(x+dx,y-3,2.2),(.04,1.6,.8),GLASS)
        for dy in [-3,1.2,2.5]: rod('VehiclesV2',(x+dx-.12,y+dy,.65),(x+dx+.12,y+dy,.65),.6,RUBBER,18)
    for dx in [-.9,.9]: box('VehiclesV2',(x+dx,y-4.29,1.2),(.45,.08,.22),LED)
    for yy in range(7): box('VehiclesV2',(x,y-1.4+yy*.8,4.78),(2.65,.06,.05),PANEL)
def desk(x,y,z=0):
    box('Interior',(x,y,z+.76),(1.6,.8,.08),IVORY)
    for dx in [-.65,.65]: box('Interior',(x+dx,y,z+.35),(.06,.65,.7),METAL)
    box('Interior',(x,y+.14,z+1.13),(.68,.08,.4),METAL); box('Interior',(x,y+.09,z+1.13),(.59,.01,.31),LED)
    box('Interior',(x,y-.15,z+.815),(.46,.15,.025),DARK); box('Interior',(x+.45,y-.15,z+.82),(.06,.09,.035),DARK)
    chair(x,y-1,z)
    cylinder('Interior',(x-.58,y-.1,z+.86),.045,.1,WHITE)
def vending(x,y,z=0):
    box('Interior',(x,y,z+1.05),(1.05,.75,2.1),BLUE)
    box('Interior',(x-.1,y-.385,z+1.2),(.6,.02,1.18),GLASS)
    for zz in [.8,1.1,1.4,1.7]:
        box('Interior',(x-.1,y-.4,z+zz),(.59,.02,.045),CHROME)
        for dx in [-.25,-.07,.12]: cylinder('Interior',(x+dx,y-.43,z+zz+.1),.055,.17,random.choice([RED,YELLOW,WHITE]),8)
    box('Interior',(x+.36,y-.41,z+1.5),(.12,.02,.16),LED); box('Interior',(x,y-.41,z+.35),(.6,.02,.15),DARK)
def building(name,x,y,w,d,floors=2,kind='office'):
    h=floors*4.3
    box('ArchitectureV2',(x,y,.13),(w,d,.26),FLOOR)
    for level in range(1,floors+1): box('ArchitectureV2',(x,y,level*4.3),(w+.6,d+.6,.32),CON)
    for side in [-1,1]:
        if side==1 and floors>1:
            door_y=y-d/2+18
            for ya,yb in [(y-d/2,door_y-2),(door_y+2,y+d/2)]:
                if yb>ya: box('ArchitectureV2',(x+w/2,(ya+yb)/2,h/2),(.35,yb-ya,h),PANEL)
            box('ArchitectureV2',(x+w/2,door_y,2),(.35,4,4),PANEL)
            box('ArchitectureV2',(x+w/2,door_y,h-.5),(.35,4,1),PANEL)
        else: box('ArchitectureV2',(x+side*w/2,y,h/2),(.35,d,h),PANEL)
        for zz in [1.1,h-.5]: box('Facade',(x+side*(w/2+.2),y,zz),(.18,d,.2),STONE)
    for yy in [-d/2,d/2]:
        for xx in range(int(-w/2+2),int(w/2),4):
            if yy<0 and abs(xx)<4: continue
            for level in range(floors):
                zz=level*4.3
                box('Facade',(x+xx,y+yy,zz+2.2),(3.5,.1,2.75),GLASS)
                for dx in [-1.85,0,1.85]: box('Facade',(x+xx+dx,y+yy-.08,zz+2.2),(.06,.12,3.1),METAL)
                box('Facade',(x+xx,y+yy-.08,zz+2.2),(3.65,.12,.055),METAL)
                box('Facade',(x+xx,y+yy,zz+.48),(4,.25,.8),PANEL)
                box('Facade',(x+xx,y+yy,zz+3.98),(4,.25,.64),PANEL)
    for dx in [-w/2,w/2]:
        if dx<0:
            for ya,yb in [(y-d/2,y-d/2+1),(y-d/2+5,y+d/2)]:
                if yb>ya: box('RoofEquipment',(x+dx,(ya+yb)/2,h+.75),(.25,yb-ya,1.2),STONE)
        else: box('RoofEquipment',(x+dx,y,h+.75),(.25,d,1.2),STONE)
    for yy in [-d/2,d/2]: box('RoofEquipment',(x,y+yy,h+.75),(w,.25,1.2),STONE)
    box('Facade',(x,y-d/2-1.8,3.5),(9,4,.25),PANEL)
    for dx in [-4,4]: box('Facade',(x+dx,y-d/2-2.7,1.75),(.17,.17,3.5),METAL)
    text(name,(x-4,y-d/2-.32,3.9),.8)
    # Open ground entrance: decorative door frames do not close the route.
    for dx in [-3.2,3.2]: box('Facade',(x+dx,y-d/2,1.5),(.16,.28,3),METAL)
    for dx in [-w/2+3,w/2-3]:
        pipe((x+dx,y+d/2+.3,.2),(x+dx,y+d/2+.3,h+.5),.09)
        hvac(x+dx,y+d*.2,h+.2)
    for xx in range(int(-w/2+5),int(w/2-3),5):
        for yy in range(int(-d/2+6),int(d/2-3),7):
            if abs(xx)<4: continue
            if kind=='office':
                desk(x+xx,y+yy)
                if floors>1: desk(x+xx,y+yy,4.45)
            else: cargo(x+xx,y+yy); cargo(x+xx,y+yy+1.5)
    if floors>1:
        steps(x+w/2+3,y-d/2+4,4,13,4.3,n=24)
        box('ArchitectureV2',(x+w/2+1,y-d/2+18,4.15),(5,3,.3),CON)
    for xx in [-w/3,w/3]:
        box('Facade',(x+xx,y-d/2-.25,h-.4),(4,.15,.08),WARM)
        lights.append(((x+xx,y-d/2-1,3),900))
    vending(x-w/2+2,y-d/2+2)
    roof_access(x-w/2-6,y-d/2+2,h+.16)
    return h

# Expand the footprint rather than enlarging human-scale furniture.
terrain=bpy.data.objects['Terrain']; terrain.dimensions=(480,440,1)
scene.unit_settings.system='METRIC'; scene.unit_settings.scale_length=1
box('GroundV2',(0,-110,-.07),(422,14,.14),ROAD)
box('GroundV2',(0,110,-.07),(422,14,.14),ROAD)
for x in [-125,125]: box('GroundV2',(x,0,-.07),(14,220,.14),ROAD)
for y in [-110,110]:
    for x in range(-205,206,9): box('RoadMarkings',(x,y,.035),(4,.16,.025),YELLOW)
for x in [-125,125]:
    for y in range(-99,100,9): box('RoadMarkings',(x,y,.035),(.16,4,.025),YELLOW)
for x in [-133,133]:
    box('GroundV2',(x,0,.11),(2.8,215,.22),WALK)
for y in [-120,120]: box('GroundV2',(0,y,.11),(422,3,.22),WALK)
for x in range(-205,206,12):
    for y in [-119,119]:
        box('GroundDetail',(x,y,.225),(.025,2.8,.01),METAL)
for x,y in [(-125,-110),(125,-110),(-125,110),(125,110)]:
    for i in range(8): box('RoadMarkings',(x-4+i*1.1,y+7.2,.04),(.55,5,.025),WHITE)
    drain(x-5.5,y-5.5); drain(x+5.5,y+5.5)
    for dx in [-9,9]: bollard(x+dx,y-9)
for y in [-128,130]:
    for x in range(-190,191,28): lamp(x,y)
for x in [-136,136]:
    for y in [-86,-45,0,45,86]: lamp(x,y)

# West: research and medical district, courtyards and a helipad.
box('GroundV2',(-176,26,.03),(73,142,.14),WALK)
building('RESEARCH / B-02',-174,54,57,51,2)
building('MEDICAL / C-04',-174,-49,48,32,1)
box('GroundV2',(-174,2,.05),(52,36,.2),STONE)
for x in [-190,-158]:
    for y in [-7,12]: planter(x,y,7,3); bench(x,y-3); lamp(x,y-5)
for x in [-186,-177,-168,-159]: table(x,4)
for x in [-196,-152]: hedge(x,3,3,29)
for y in [-26,-22,-18]:
    box('GroundDetail',(-173,y,.15),(24,.12,.05),WHITE)
car(-162,-71,WHITE,0,True)
box('VehiclesV2',(-162,-70.4,2.35),(.3,.3,.13),TAIL)
text('AMBULANCE',(-162.9,-72.5,1.15),.25,math.pi/2)
box('GroundV2',(-174,-151,.08),(62,57,.22),ROAD)
box('RoadMarkings',(-174,-151,.22),(29,29,.07),WALK)
# Helipad circle, segmented beams; H and approach markings.
for i in range(64):
    a=2*math.pi*i/64; b=2*math.pi*(i+1)/64
    beam('RoadMarkings',(-174+math.cos(a)*12,-151+math.sin(a)*12,.28),(-174+math.cos(b)*12,-151+math.sin(b)*12,.28),.24,.045,WHITE)
for x in [-177,-171]: box('RoadMarkings',(x,-151,.29),(.55,9,.06),WHITE)
box('RoadMarkings',(-174,-151,.29),(6,.55,.06),WHITE)
for x in [-196,-152]:
    for y in [-170,-131]: cylinder('StreetFurniture',(x,y,.3),.17,.3,LED)
# Detailed original helicopter silhouette: fuselage, canopy, tail, rotor, landing skids.
sphere('Helicopter',(-174,-151,2.4),2.1,PANEL,20,12,(.65,1.7,.65))
sphere('Helicopter',(-174,-153.5,2.5),1.6,GLASS,18,10,(.68,1,.65))
beam('Helicopter',(-174,-149,2.6),(-174,-143,3.3),.6,.45,PANEL)
box('Helicopter',(-174,-142.9,3.5),(.12,1.4,2.2),PANEL)
box('Helicopter',(-174,-145,3.4),(3.2,.7,.12),PANEL)
cylinder('Helicopter',(-174,-150,4.1),.18,1.8,METAL)
for a in [0,math.pi/2]: box('Helicopter',(-174,-150,5),(13,.25,.065),METAL,a+.3)
for dx in [-1.3,1.3]:
    rod('Helicopter',(-174+dx,-154,.9),(-174+dx,-148,.9),.1,METAL)
    for yy in [-152,-149]: beam('Helicopter',(-174+dx,yy,.9),(-174+dx*.7,yy,1.9),.07,.07,METAL)
rod('Helicopter',(-174.4,-142.9,3.6),(-173.6,-142.9,3.6),.2,METAL)
for a in [0,math.pi/2]: beam('Helicopter',(-174.45,-142.9-math.cos(a)*1.2,3.6-math.sin(a)*1.2),(-174.45,-142.9+math.cos(a)*1.2,3.6+math.sin(a)*1.2),.09,.09,METAL)
text('H1 / EMERGENCY',(-201,-178,.3),1.3)

# East: distribution warehouses, loading docks, industrial plant.
box('GroundV2',(174,18,.02),(75,158,.16),ROAD)
building('LOGISTICS / D-01',174,65,58,36,1,'warehouse')
building('WORKSHOP / D-02',174,2,58,30,1,'warehouse')
for x in [152,164,184,196]:
    box('LoadingDocks',(x,45,.55),(8,5,1.1),CON)
    for dx in [-3.5,3.5]: box('LoadingDocks',(x+dx,42.4,.7),(.16,.25,1.4),YELLOW)
    box('LoadingDocks',(x,46.9,2),(5,.13,3.8),PANEL)
    for i in range(17): box('LoadingDocks',(x,46.8,.3+i*.2),(4.8,.04,.025),METAL)
    box('LoadingDocks',(x,46.72,2.2),(2,.1,.6),GLASS)
    box('LoadingDocks',(x,46.6,4.3),(6,.7,.2),METAL)
    lights.append(((x,45.8,4.1),650))
for x in [152,184,196]: truck(x,35)
for x,y,m in [(156,-42,RED),(174,-42,BLUE),(193,-42,SAND),(155,-52,BLUE),(193,-52,RED)]: container(x,y,m)
for x in [151,157,180,186,202]:
    for y in [-24,-28]: cargo(x,y); cargo(x,y,.32)
for x in [165,178,191]:
    cylinder('Industry',(x,-74,3),2.4,6,CHROME,24)
    cylinder('Industry',(x,-74,6.2),2.5,.35,PANEL,24)
    handrail((x-2.3,-74,6.4),(x+2.3,-74,6.4))
    pipe((x,-74,6.5),(x,-72,7),.22); pipe((x,-72,7),(x,-63,7),.22)
for y in [-66,-81]:
    box('Industry',(177,y,1),(43,2,2),CON)
    for x in range(158,199,4): pipe((x,y,2),(x,y,4),.14)
text('UTILITIES / RESTRICTED',(150,-87,2),.7)
# Forklift with mast, forks, roof and hydraulic details.
for x,y in [(173,-26),(198,25)]:
    box('Forklifts',(x,y,.7),(1.7,2.5,1.1),YELLOW)
    for dx in [-.9,.9]:
        for dy in [-.8,.8]: rod('Forklifts',(x+dx-.1,y+dy,.45),(x+dx+.1,y+dy,.45),.38,RUBBER,16)
    for dx in [-.6,.6]:
        box('Forklifts',(x+dx,y,2),(.08,.08,2),METAL)
        box('Forklifts',(x+dx,y-1.4,2),(.11,.14,3.8),METAL)
        box('Forklifts',(x+dx,y-2.1,.2),(.16,1.6,.12),METAL)
    box('Forklifts',(x,y,3),(1.55,1.7,.13),YELLOW)
    box('Forklifts',(x,y+.15,1.4),(.7,.7,.12),DARK)
    rod('Forklifts',(x,y-1.4,.4),(x,y-1.4,3.6),.07,CHROME)

# South: bus terminal, additional parking and petrol station.
box('GroundV2',(0,-156,.03),(240,74,.18),ROAD)
building('TRANSIT / SOUTH GATE',-4,-175,104,23,1)
for x in [-42,-20,2,24,46]:
    box('Transit',(x,-154,3.6),(15,8,.3),PANEL)
    for dx in [-6,6]: box('Transit',(x+dx,-153,1.8),(.16,.16,3.6),METAL)
    bench(x,-151); rubbish(x+5,-151)
    box('Transit',(x-6,-153,1.8),(1,.18,1.7),BLUE)
    text('BUS', (x-6.3,-153.12,2.05),.24)
    lights.append(((x,-154,3.2),450))
def bus(x,y):
    box('VehiclesV2',(x,y,1.6),(2.65,11.7,2.9),IVORY)
    box('VehiclesV2',(x,y,1.1),(2.69,11.5,.35),BLUE)
    for side in [-1,1]:
        for dy in [-4.1,-2.3,-.5,1.3,3.1,4.9]:
            box('VehiclesV2',(x+side*1.34,y+dy,2.25),(.03,1.55,1.05),GLASS)
        for dy in [-3.6,3.5]: rod('VehiclesV2',(x+side*1.22,y+dy,.55),(x+side*1.46,y+dy,.55),.53,RUBBER,18)
    box('VehiclesV2',(x,y-5.87,2.15),(2.42,.04,1.38),GLASS)
    box('VehiclesV2',(x,y-5.89,2.96),(2.3,.05,.2),DARK)
    for dx in [-.9,.9]: box('VehiclesV2',(x+dx,y-5.9,.85),(.4,.04,.16),LED)
    hvac(x,y+.8,3.08,1.8)
bus(-30,-137); bus(13,-137)
for x in [-102,-89,-76,73,86,99]:
    for y in [-171,-150,-131]:
        box('RoadMarkings',(x,y,.14),(.12,8,.03),WHITE)
        if random.random()<.7: car(x+3,y,random.choice([BLUE,RED,IVORY,PANEL]),random.choice([0,math.pi]))
for x in [-110,58,110]: planter(x,-156,3,24); lamp(x,-157)
box('GroundV2',(171,-143,.06),(69,76,.2),WALK)
building('FUEL / MART',176,-175,40,16,1)
box('FuelStation',(171,-138,5.3),(43,24,.55),IVORY)
box('FuelStation',(171,-150,5.22),(43,.2,.65),RED)
text('NORTHSTAR ENERGY',(153,-150.15,5.15),1.1)
for x in [156,171,186]:
    for y in [-145,-132]:
        box('FuelStation',(x,y,.15),(4,2,.3),STONE)
        box('FuelStation',(x,y,2.55),(.27,.27,5.1),METAL)
        for dx in [-.85,.85]:
            box('FuelStation',(x+dx,y,1.2),(.72,.5,1.8),IVORY)
            box('FuelStation',(x+dx,y-.26,1.55),(.5,.03,.3),DARK)
            box('FuelStation',(x+dx,y-.28,1.58),(.3,.01,.1),LED)
            for yy,zz in [(-.38,1.3),(-.55,.9),(-.4,.5)]:
                pipe((x+dx+.3,y+yy,zz),(x+dx+.3,y+yy-.08,zz-.32),.035)
        lights.append(((x,y,4.9),550))
car(162,-143,RED); car(181,-132,BLUE); car(194,-157,IVORY,math.pi/2)
for x in [140,201]: lamp(x,-137); rubbish(x,-140)
for x in range(148,197,4): bollard(x,-162)

# North: landscaped park, pond, café, sports court and research annex.
box('GroundV2',(0,153,.02),(204,65,.16),GRASS)
box('GroundV2',(0,133,.13),(200,5,.24),WALK)
box('GroundV2',(-7,152,.13),(5,39,.24),WALK)
building('LAKESIDE / CAFE',-52,155,44,26,1)
for x in [-69,-56,-43,-30]:
    for y in [131,137]: table(x,y)
for x in [-76,-28]: planter(x,134,3,15)
# Non-square pond mesh with stone shoreline.
pv=[(47,157,.12)]; N=64
for i in range(N):
    a=2*math.pi*i/N; rr=1+.09*math.sin(3*a)+.06*math.cos(5*a)
    pv.append((47+math.cos(a)*31*rr,157+math.sin(a)*18*rr,.12))
add('ParkWater',(47,157,.12),pv,[(0,i+1,(i+1)%N+1) for i in range(N)],WATER)
for i in range(N):
    a=pv[i+1]; b=pv[(i+1)%N+1]; beam('ParkShore',a,b,.55,.2,STONE)
    if i%3==0:
        x,y,_=a; sphere('ParkShore',(x,y,.27),random.uniform(.4,.8),CON,8,5,(1,1,.7))
for x in [33,38,43]:
    for y in [137,177]:
        for j in range(7):
            xx=x+random.uniform(-.6,.6); yy=y+random.uniform(-.5,.5)
            rod('ParkPlants',(xx,yy,.14),(xx+.1,yy,random.uniform(.8,1.4)),.022,MOSS,5)
box('ParkBoardwalk',(46,132,.35),(38,5,.45),WOOD)
for x in range(28,65): box('ParkBoardwalk',(x,132,.59),(.035,4.8,.02),METAL)
handrail((27,134.3,.6),(65,134.3,.6))
for x in [31,48,63]: bench(x,132,.6); lamp(x,128)
building('FIELD LAB / E-03',-161,151,49,29,2)
box('Sports',(153,151,.1),(55,37,.24),BLUE)
for x in [126,180]: box('Sports',(x,151,.25),(.11,35,.04),WHITE)
for y in [133,169]: box('Sports',(153,y,.25),(54,.11,.04),WHITE)
box('Sports',(153,151,.25),(.11,35,.04),WHITE)
for x in [134,172]:
    box('Sports',(x,151,.25),(.1,14,.04),WHITE)
    for y in [144,158]: box('Sports',((x+153)/2,y,.25),(19,.1,.04),WHITE)
for x in [127,179]:
    cylinder('Sports',(x,151,2),.09,4,METAL)
    box('Sports',(x,151,3.4),(.12,2.2,1.2),IVORY)
    for i in range(24):
        a=i*2*math.pi/24; b=(i+1)*2*math.pi/24
        xx=x+(1 if x<153 else -1)*.75
        rod('Sports',(xx+math.cos(a)*.35,151+math.sin(a)*.35,3.1),(xx+math.cos(b)*.35,151+math.sin(b)*.35,3.1),.025,ORANGE,6)
for x in [-204,-103,102,204]:
    for y in [134,166]: planter(x,y,5,4)
for x,y in [(-86,153),(5,173),(91,159),(95,133),(-110,181),(116,180),(-178,183)]: tree(x,y); bench(x+3,y-3)

# Enrich existing architecture, raised entry floors, railing and façade joints.
for x,y,w,d,z in [(0,63,66,30,3),(-57,35,42,47,4),(57,35,42,47,4)]:
    box('CoreInterior',(x,y,z-.13),(w-.8,d-.8,.26),FLOOR)
    for xx in [-w*.3,w*.3]:
        for yy in [-d*.12,d*.22]: desk(x+xx,y+yy,z)
    for xx in range(int(-w/2+4),int(w/2),5):
        if abs(xx)<5: continue
        box('CoreInterior',(x+xx,y+d*.12,z+1.3),(3.8,.12,1.2),PANEL)
    vending(x-w/2+2,y-d/2+2,z)
    for xx in [-w/2+2,w/2-2]:
        box('CoreInterior',(x+xx,y+d*.3,z+1.15),(1,3,2.3),WOOD)
        for zz in [.3,.85,1.4,1.95]:
            box('CoreInterior',(x+xx,y+d*.3,z+zz),(1.05,3,.07),STONE)
            for j in range(9): box('CoreInterior',(x+xx,y+d*.3-1.25+j*.28,z+zz+.17),(.55,.18,.32),random.choice([BLUE,RED,SAND,IVORY]))
for o in list(bpy.data.collections['Interiors'].objects):
    if abs(o.location.x)<33 and o.location.y>48: o.location.z+=3
    elif 36<abs(o.location.x)<78 and 11<o.location.y<60: o.location.z+=4
for name,x,y,w,d,h in [('Atrium',0,63,66,30,17),('WestWing',-57,35,42,47,9),('EastWing',57,35,42,47,9),('WestAnnex',-69,68,28,22,12),('EastAnnex',72,69,30,22,12),('Warehouse',80,-39,28,35,8)]:
    for yy in [-d/2,d/2]:
        for zz in [h*.33,h*.66]: box('CoreFacade',(x,y+yy-.12,zz),(w,.2,.16),STONE)
        for xx in range(int(-w/2+2),int(w/2),2):
            if yy<0 and abs(xx)<4: continue
            box('CoreFacade',(x+xx,y+yy-.1,h*.49),(.06,.18,h*.8),METAL)
    for side in [-1,1]:
        for dy in range(int(-d/2+2),int(d/2),4):
            box('CoreFacade',(x+side*(w/2+.28),y+dy,h/2),(.18,.22,h),PANEL)
        for zz in [h*.33,h*.66,h-.3]: box('CoreFacade',(x+side*(w/2+.32),y,zz),(.12,d,.16),STONE)
        pipe((x+side*(w/2-.6),y+d/2+.35,.2),(x+side*(w/2-.6),y+d/2+.35,h+.9),.085)
    for xx in [-w*.3,w*.3]: hvac(x+xx,y+d*.22,h+.42)
    for xx in [-w*.2,w*.2]:
        for yy in [-d*.05,d*.13]:
            box('RoofSolar',(x+xx,y+yy,h+.66),(5,2.8,.12),SOLAR)
            for i in range(9): box('RoofSolar',(x+xx-2.4+i*.6,y+yy,h+.73),(.025,2.8,.015),CHROME)
            for dy in [-1.4,0,1.4]: box('RoofSolar',(x+xx,y+yy+dy,h+.74),(5,.035,.02),CHROME)
    for xx in [-w/2+1,w/2-1]:
        for yy in [-d/2+1,d/2-1]: cylinder('RoofEquipment',(x+xx,y+yy,h+.65),.28,.45,METAL)
    # Surface seams read as panels rather than blank slabs.
    for xx in range(int(-w/2+1),int(w/2),5): box('RoofSeams',(x+xx,y,h+.415),(.018,d-.4,.013),DARK)
    for yy in range(int(-d/2+1),int(d/2),5): box('RoofSeams',(x,y+yy,h+.42),(w-.4,.018,.013),DARK)
    # Rear wide exterior staircase and walk-off upper landing to accessible roof.
    roof_access(x-w/2-6,y-d/2+2,h+.4)
    # Cut a visible opening in the original left parapet at the stair landing.
    for old in list(root.all_objects):
        if old.type!='MESH' or not old.name.startswith(name+'_Parapet'): continue
        if abs(old.location.x-(x-w/2))<.1 and old.dimensions.x<.5:
            old.dimensions.y=d-5; old.location.y=y+2.5
    box('CoreFacade',(x-w/2,y-d/2+.5,h+.9),(.3,1,1.4),STONE)
for x in [-57,57]:
    for dx in [-19,19]: handrail((x+dx,-3,4),(x+dx,13,4))
    for dx in [-19,-9,9,19]: box('CoreDetail',(x+dx,-3,4.8),(.12,.12,1.6),METAL)
    for xx in [-14,14]:
        for yy in [23,44]: table(x+xx,yy,9.4)
text('NORTHSTAR / CAMPUS',(-21,47.32,14.3),1.6)
text('VISITORS / RECEPTION',(-8,47.22,5.3),.62)
# Atrium reception, indoor greenery, chandelier and seating.
box('CoreInterior',(0,65,4.15),(8,1.8,2.3),PANEL)
box('CoreInterior',(0,65,5.35),(8.3,2,.16),IVORY)
for x in [-2.5,2.5]: box('CoreInterior',(x,65,5.65),(.8,.1,.5),METAL)
for x in [-23,23]:
    planter(x,69,4,3,3)
    for y in [54,60]:
        box('CoreInterior',(x,y,3.6),(3.5,1.2,1.2),BLUE)
        box('CoreInterior',(x,y+.55,4.2),(3.5,.2,1.1),BLUE)
    box('CoreInterior',(x,57,3.65),(1.5,1.5,.15),WOOD)
for x in [-12,0,12]:
    rod('CoreInterior',(x,63,16.8),(x,63,12),.035,METAL)
    for a in range(0,360,60):
        aa=math.radians(a); cylinder('CoreInterior',(x+math.cos(aa)*1.1,63+math.sin(aa)*1.1,11.7),.08,.5,WARM,8)
for x,y in [(-24,18),(24,18),(-24,-5),(24,-5)]: bench(x,y); rubbish(x+2,y)
# Fountain rim coping, water jets and tiled plaza.
for i in range(64):
    a=i*math.tau/64; b=(i+1)*math.tau/64
    beam('Fountain',(math.cos(a)*9,11+math.sin(a)*9,.86),(math.cos(b)*9,11+math.sin(b)*9,.86),.35,.16,STONE)
for i in range(12):
    a=i*math.tau/12; x=math.cos(a)*6.8; y=11+math.sin(a)*6.8
    cylinder('Fountain',(x,y,.95),.08,.25,CHROME)
    # Geometric streams kept as preview decoration.
    for j in range(10):
        t=j/10; t2=(j+1)/10
        rod('Fountain',(x*(1-.35*t),11+(y-11)*(1-.35*t),.96+2*math.sin(math.pi*t)),(x*(1-.35*t2),11+(y-11)*(1-.35*t2),.96+2*math.sin(math.pi*t2)),.028,WATER,6)
for x in range(-45,46,3): box('CorePaving',(x,13,.019),(.02,44,.015),DARK)
for y in range(-8,36,3): box('CorePaving',(0,y,.021),(90,.02,.015),DARK)
# Existing vehicle details at original scale, no giant furniture scaling.
for o in list(bpy.data.collections['Vehicles'].objects):
    if not o.name.startswith('CarBody'): continue
    x,y,z=o.location; m=materials.index(o.data.materials[0]) if o.data.materials[0] in materials else BLUE
    # Base cars point along X; add tyres, trims, headlights, mirrors and door seams.
    for side in [-1,1]:
        for dx in [-1.2,1.2]:
            rod('CarDetails',(x+dx,y+side*.98,.55),(x+dx,y+side*1.12,.55),.28,CHROME,14)
        box('CarDetails',(x+.1,y+side*.965,.94),(.025,.025,.48),METAL)
        box('CarDetails',(x-.36,y+side*.99,1.07),(.19,.045,.045),CHROME)
        box('CarDetails',(x-.58,y+side*1.05,1.4),(.23,.25,.13),m)
        box('CarDetails',(x-1.91,y+side*.6,.95),(.05,.35,.17),LED)
        box('CarDetails',(x+1.91,y+side*.6,.95),(.05,.3,.17),TAIL)
    box('CarDetails',(x-1.95,y,.61),(.07,1.72,.15),METAL)
    box('CarDetails',(x-1.97,y,.83),(.025,.44,.12),WHITE)
for o in list(bpy.data.collections['Rooftops'].objects):
    if o.name.startswith('RoofChair'):
        x,y,z=o.location; box('ChairDetails',(x,y+.32,z+.36),(.65,.08,.65),WOOD)
        for dx in [-.26,.26]:
            for dy in [-.26,.26]: box('ChairDetails',(x+dx,y+dy,z-.22),(.05,.05,.44),METAL)
# Ground clutter with readable clusters rather than filling routes.
for x,y in [(-90,-24),(44,-64),(94,6),(-200,-87),(198,-95),(-58,-185),(206,52),(-115,102)]:
    rubbish(x,y); pallet(x+1.5,y)
    for i in range(5):
        box('Scatter',(x+random.uniform(-1,1),y+random.uniform(-1,1),.06),(.2,.15,.02),IVORY,random.random()*math.tau)
for x,y in [(-90,-58),(-42,-25),(28,-74),(67,-14),(161,27),(-157,-82)]:
    cylinder('Utilities',(x,y,.09),.65,.1,METAL,24)
    for i in range(7): box('Utilities',(x-.48+i*.16,y,.15),(.025,.85,.018),CHROME)
for x in [-90,-55,-20,15]:
    for y in [-69,-50,-31]:
        box('ParkingDetails',(x,y-3.8,.28),(2.1,.2,.4),CON)
        for dx in [-.7,.7]: box('ParkingDetails',(x+dx,y-3.92,.31),(.3,.035,.09),YELLOW)
for x,y in [(-97,-78),(39,-76),(61,-60),(201,38),(-141,126)]:
    cylinder('StreetFurniture',(x,y,1.6),.06,3.2,METAL)
    box('StreetFurniture',(x,y,2.7),(1.25,.12,1.1),BLUE)
    text('P', (x-.3,y-.08,2.35),.8)
# True chain-link outer fence geometry with gates and patrol road.
for x in [-215,215]: box('GroundV2',(x,0,.02),(5,394,.15),ROAD)
for y in [-194,194]: box('GroundV2',(0,y,.02),(428,5,.15),ROAD)
def fence(a,b,height=2.8):
    a=Vector(a); b=Vector(b); delta=b-a; L=delta.length; direction=delta.normalized()
    for i in range(int(L/3)+1):
        p=a+direction*min(L,i*3); rod('PerimeterV2',p,p+Vector((0,0,height+.2)),.05,METAL,8)
    rod('PerimeterV2',a+Vector((0,0,height)),b+Vector((0,0,height)),.035,METAL,8)
    rod('PerimeterV2',a+Vector((0,0,.25)),b+Vector((0,0,.25)),.025,METAL,8)
    # Diagonal wire diamonds, clipped at boundary (0.55m mesh).
    for slope in [-1,1]:
        for j in range(-int(height/.55)-1,int((L+height)/.55)+2):
            t=j*.55; lo=max(0,-t/slope) if slope>0 else max(0,t-L); hi=min(height,L-t) if slope>0 else min(height,t)
            if hi<=lo: continue
            p=a+direction*(t+slope*lo)+Vector((0,0,lo)); q=a+direction*(t+slope*hi)+Vector((0,0,hi))
            rod('FenceWire',p,q,.006,CHROME,4)
for x in [-220,220]: fence((x,-199,.1),(x,199,.1))
fence((-220,199,.1),(220,199,.1))
fence((-220,-199,.1),(-18,-199,.1)); fence((18,-199,.1),(220,-199,.1))
building('SECURITY / SOUTH',32,-195,14,10,1)
box('GroundV2',(0,-203,.01),(30,34,.14),ROAD)
for x in [-15,15]:
    box('Security',(x,-199,2.9),(1.5,2.3,5.8),CON)
    box('Security',(x,-199,5.9),(2,2.6,.2),METAL)
box('Security',(0,-199,6.3),(32,2.4,.6),PANEL)
text('NORTHSTAR / CAMPUS 01',(-11,-200.23,6.08),1)
for x in [-7,7]:
    box('Security',(x,-195,.7),(.6,.6,1.4),ORANGE)
    box('Security',(x,-192,1.15),(.14,6,.18),WHITE)
    for y in [-194,-192,-190]: box('Security',(x,y,1.16),(.15,.45,.19),RED)
for x in [-11,11]:
    for y in [-207,-193]: bollard(x,y)
for x in [-205,205]:
    for y in [-180,180]:
        for dx in [-1.1,1.1]:
            for dy in [-1.1,1.1]: box('Watchtower',(x+dx,y+dy,3),(.14,.14,6),METAL)
        box('Watchtower',(x,y,6),(3.4,3.4,.25),CON)
        box('Watchtower',(x,y,8.3),(4,4,.25),PANEL)
        for dx in [-1.5,1.5]: box('Watchtower',(x+dx,y,7.15),(.08,3,1.3),GLASS)
        box('Watchtower',(x,y-1.5,7.15),(3,.08,1.3),GLASS)
        steps(x-4,y-7,3,14,6,n=36)
        box('Watchtower',(x-2.4,y+7.5,5.86),(6,2,.3),CON)
        handrail((x-4,y+7,6),(x,y+7,6))
        box('Watchtower',(x,y+4.5,5.86),(2.6,6,.3),CON)
        for dx in [-1.25,1.25]: handrail((x+dx,y+1.6,6.01),(x+dx,y+7.5,6.01))
        for yy in [4,7]: box('Watchtower',(x,y+yy,2.85),(.2,.2,5.7),METAL)
# Forest frame, dirt patches, layered boulders and fallen trunks.
for i in range(430):
    edge=random.randrange(4)
    if edge<2: x=random.choice([-1,1])*random.uniform(224,237); y=random.uniform(-208,209)
    else: x=random.uniform(-216,216); y=random.choice([-1,1])*random.uniform(204,215)
    if y< -199 and abs(x)<22: continue
    pine(x,y,random.uniform(7,18))
for i in range(60):
    x=random.choice([-1,1])*random.uniform(223,236); y=random.uniform(-200,205)
    sphere('Rocks',(x,y,.6),random.uniform(.7,2.4),CON,9,5,(1.3,1,.75))
for x,y in [(-231,-90),(231,102),(-227,178),(228,-172)]:
    rod('ForestDebris',(x,y,.7),(x+2,y+8,1),.4,WOOD,12,.3)
for x,y in [(-96,145),(103,-29),(-106,-147),(98,93),(-24,181),(195,111)]:
    for i in range(10):
        xx=x+random.uniform(-5,5); yy=y+random.uniform(-4,4); sphere('Landscape',(xx,yy,.35),random.uniform(.4,1),MOSS,8,4,(1,1,.65))
exec(compile(open(os.path.join(OUT,'polish_campus_v2.py'),encoding='utf-8').read(),'polish_campus_v2.py','exec'))
# Cameras intended for both overall composition and in-game scale inspection.
camera=scene.camera; camera.location=(365,-465,350); camera.rotation_euler=(Vector((0,8,0))-camera.location).to_track_quat('-Z','Y').to_euler(); camera.data.ortho_scale=567
camera.name='CampusV2_Hero'
def camera_new(name,loc,target,ortho=None,lens=40):
    data=bpy.data.cameras.new(name); obj=bpy.data.objects.new(name,data); pres.objects.link(obj); obj.location=loc; obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler(); data.lens=lens
    if ortho: data.type='ORTHO'; data.ortho_scale=ortho
    return obj
camera_new('CampusV2_Overview',(0,0,550),(0,0,0),495)
camera_new('CampusV2_Plaza',(48,-45,19),(-2,48,9),lens=32)
camera_new('CampusV2_Logistics',(213,-71,23),(172,37,3),lens=30)
camera_new('CampusV2_Park',(87,111,16),(-22,153,3),lens=33)
# Flush batches: direct mesh API avoids thousands of slow bpy primitive operators.
for (cat,tx,ty),(verts,faces,indices) in batches.items():
    mesh=bpy.data.meshes.new(f'{cat}_{tx}_{ty}'); mesh.from_pydata(verts,[],faces); mesh.update()
    obj=bpy.data.objects.new(mesh.name,mesh); extra.objects.link(obj)
    for m in materials: mesh.materials.append(m)
    for p,i in zip(mesh.polygons,indices):
        p.material_index=i
        if cat in ['Landscape','TreeDetail','Forest','Rocks','ParkShore'] and i in [LEAF,LEAF2,WOOD,CON,MOSS]: p.use_smooth=True
    obj['district_tile']=[tx,ty]; obj['role']=cat
    if cat in ['VehiclesV2','Furniture','CoreInterior','RoofEquipment','FuelStation','CoreFacade','ArchitectureV2','LoadingDocks']:
        mod=obj.modifiers.new('EdgeHighlights','BEVEL'); mod.width=.025 if cat!='VehiclesV2' else .045; mod.segments=2
        mod.limit_method='ANGLE'
        mod=obj.modifiers.new('WeightedNormals','WEIGHTED_NORMAL'); mod.keep_sharp=True
# Labels are real editable Blender text objects; convert to meshes for export.
for body,pos,size,angle in labels:
    curve=bpy.data.curves.new('Sign_'+body,'FONT'); curve.body=body; curve.size=size; curve.extrude=.003; curve.space_character=1.1
    obj=bpy.data.objects.new(curve.name,curve); extra.objects.link(obj); obj.location=pos; obj.rotation_euler=(math.pi/2,0,angle); curve.materials.append(materials[IVORY])
    bpy.context.view_layer.objects.active=obj; obj.select_set(True)
    bpy.ops.object.convert(target='MESH'); obj.select_set(False)
for i,(pos,power) in enumerate(lights):
    d=bpy.data.lights.new(f'V2_Warm_{i}','POINT'); d.energy=power; d.color=(1,.66,.35); d.shadow_soft_size=.65
    obj=bpy.data.objects.new(d.name,d); pres.objects.link(obj); obj.location=pos
sun=next(o for o in pres.objects if o.type=='LIGHT' and o.data.type=='SUN'); sun.data.energy=1.35; sun.rotation_euler=(.6,-.5,-.6)
area=next(o for o in pres.objects if o.type=='LIGHT' and o.data.type=='AREA'); area.location=(0,-40,200); area.data.energy=190000; area.data.size=300
scene.render.resolution_x=2200; scene.render.resolution_y=1500; scene.render.resolution_percentage=100
scene.cycles.samples=40; scene.cycles.use_denoising=True
scene.render.filepath=os.path.join(OUT,'Campus_Expanded_preview.png')
scene['expanded_v2']=True; scene['design']='480x440 metres. Human-scale buildings retained; six new districts, dense environment details. Runtime integration unverified.'
scene['export_scale_studs_per_metre']=3.5
bpy.ops.object.select_all(action='DESELECT')
for collection in [root,extra]:
    for o in collection.all_objects:
        if o.type=='MESH': o.select_set(True)
mesh_objects=[o for c in [root,extra] for o in c.all_objects if o.type=='MESH']
report={'dimensions_metres':[480,440],'roblox_studs_at_3_5':[1680,1540],'mesh_objects':len(mesh_objects),'base_triangles':sum(len(p.vertices)-2 for o in mesh_objects for p in o.data.polygons),'new_detail_primitives':counts,'batch_meshes':len(batches),'new_lights':len(lights),'camera_views':[o.name for o in pres.objects if o.type=='CAMERA'],'runtime_verified':False}
depsgraph=bpy.context.evaluated_depsgraph_get()
report['evaluated_triangles']=sum(len(p.vertices)-2 for o in mesh_objects for p in o.evaluated_get(depsgraph).data.polygons)
with open(os.path.join(OUT,'Campus_Expanded_manifest.json'),'w',encoding='utf-8') as f: json.dump(report,f,indent=2)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'Campus_Expanded.blend'))
with bpy.context.temp_override(selected_objects=mesh_objects,selected_editable_objects=mesh_objects,active_object=mesh_objects[0]):
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,'Campus_Expanded.fbx'),use_selection=True,add_leaf_bones=False,axis_forward='-Z',axis_up='Y',use_mesh_modifiers=True)
print(json.dumps(report))
