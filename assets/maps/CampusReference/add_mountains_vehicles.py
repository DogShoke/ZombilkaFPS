"""V3 art pass. Run with the preserved Campus_Expanded.blend open.
Only generated campus objects are changed; V1/V2 .blend files remain untouched.
"""
import bpy, bmesh, math, random, os, json
from mathutils import Vector
R=random.Random(12031)
OUT=r'C:\Roblox\ZombilkaFPS\assets\maps\CampusReference'
scene=bpy.context.scene
if scene.get('mountain_vehicle_v3'):
    raise RuntimeError('V3 already built. Open Campus_Expanded.blend to reproduce.')
root=bpy.data.collections['Campus_Map']; expanded=bpy.data.collections['Campus_Expansion_V2']; pres=bpy.data.collections['Presentation']
scenery=bpy.data.collections.new('V3_Mountains_Exterior');scene.collection.children.link(scenery)
fleet=bpy.data.collections.new('V3_Detailed_Vehicles');scene.collection.children.link(fleet)
materials=[]
def mat(name,color,metal=0,rough=.55,emit=0):
    m=bpy.data.materials.get('Campus_'+name)
    if not m:
        m=bpy.data.materials.new('Campus_'+name);m.use_nodes=True;m.diffuse_color=(*color,1)
        p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
        if emit:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emit
    if m not in materials:materials.append(m)
    return materials.index(m)
METAL=mat('Steel',(.11,.14,.16),.6,.4);RUBBER=mat('Rubber',(.025,.028,.03));CHROME=mat('Chrome',(.5,.54,.57),.8,.2)
BLACK=mat('CarBlackTrim',(.012,.016,.021),.1,.47);TREAD=mat('TyreTread',(.048,.052,.056),.1,.8);SEAT=mat('Upholstery',(.085,.075,.065),0,.83)
GLASS=mat('VehicleGlassV3',(.095,.15,.18),.18,.1);MIRROR=mat('MirrorGlass',(.6,.68,.74),.96,.055)
WHITE=mat('CarPearlWhite',(.8,.8,.74),.42,.25);SILVER=mat('CarSilver',(.48,.54,.58),.78,.24);RED=mat('CarBurgundy',(.28,.022,.018),.5,.24);BLUE=mat('CarMidnightBlue',(.025,.065,.13),.55,.24);GREEN=mat('CarForestGreen',(.055,.13,.105),.55,.3);TEAL=mat('CarPetrolTeal',(.035,.23,.24),.45,.26);SAND=mat('CarDesertTan',(.47,.38,.22),.3,.32);ORANGE=mat('CarCopper',(.48,.17,.035),.56,.26);YELLOW=mat('CarTaxiOchre',(.73,.43,.035),.4,.3)
WARM=mat('WarmLight',(1,.62,.25),emit=3);HEAD=mat('CarLEDLens',(.72,.85,.95),.25,.17,1.3);TAIL=mat('CarRedLens',(.68,.012,.009),.2,.15,.65);AMBER=mat('CarIndicator',(.9,.29,.025),.2,.22,.4);PLATE=mat('CarPlate',(.83,.83,.76),.1,.48);BRUSH=mat('BrakeDisc',(.3,.33,.34),.78,.42);CALIPER=mat('BrakeCaliper',(.45,.045,.025),.45,.3);WOOD=mat('Bark',(.14,.1,.075));LEAF=mat('MountainPine',(.055,.115,.085));LEAF2=mat('MountainPineLight',(.08,.15,.11))
GRASS=mat('MountainMoss',(.14,.19,.115),0,.94);EARTH=mat('MountainEarth',(.23,.21,.16),0,.96);ROCK=mat('MountainSlate',(.22,.255,.265),0,.88);ROCK2=mat('MountainGranite',(.37,.405,.405),0,.88);PEAK=mat('MountainHighRock',(.48,.51,.51),0,.9);FAR=mat('MountainDistantStone',(.32,.38,.4),0,.95);ASPHALT=mat('Asphalt',(.075,.09,.105));LINE=mat('Markings',(.65,.68,.62));CON=mat('Concrete',(.29,.33,.34))
p=next(n for n in materials[GLASS].node_tree.nodes if n.type=='BSDF_PRINCIPLED');p.inputs['Transmission Weight'].default_value=.4;p.inputs['IOR'].default_value=1.45
# Surface variation is kept in Blender; baking is a separate Roblox import step.
for idx,col in [(GRASS,(.14,.19,.115)),(EARTH,(.23,.21,.16)),(ROCK,(.22,.255,.265)),(ROCK2,(.37,.405,.405)),(PEAK,(.48,.51,.51)),(FAR,(.32,.38,.4))]:
    m=materials[idx];nt=m.node_tree;p=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED')
    tc=nt.nodes.new('ShaderNodeTexCoord');noise=nt.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=.27;noise.inputs['Detail'].default_value=5;noise.inputs['Roughness'].default_value=.72
    nt.links.new(tc.outputs['Object'],noise.inputs['Vector']);ramp=nt.nodes.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].color=tuple(c*.58 for c in col)+(1,);ramp.color_ramp.elements[1].color=tuple(min(1,c*1.3) for c in col)+(1,)
    nt.links.new(noise.outputs['Fac'],ramp.inputs['Fac']);nt.links.new(ramp.outputs['Color'],p.inputs['Base Color'])
    bump=nt.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.32;bump.inputs['Distance'].default_value=.2
    nt.links.new(noise.outputs['Fac'],bump.inputs['Height']);nt.links.new(bump.outputs['Normal'],p.inputs['Normal'])
batches={};counts={};active_car=None
CUBE=[(-.5,-.5,-.5),(.5,-.5,-.5),(.5,.5,-.5),(-.5,.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(.5,.5,.5),(-.5,.5,.5)]
CF=[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)]
def emit(cat,pos,vs,fs,m,smooth=False):
    key=('Car',active_car) if active_car is not None else (cat,math.floor(pos[0]/70),math.floor(pos[1]/70))
    if key not in batches:batches[key]=[[],[],[],[]]
    b=batches[key];base=len(b[0]);b[0].extend(tuple(v) for v in vs);b[1].extend(tuple(base+i for i in f) for f in fs);b[2].extend([m]*len(fs));b[3].extend([smooth]*len(fs));counts[cat]=counts.get(cat,0)+1
def box(cat,p,s,m,angle=0):
    c=math.cos(angle);t=math.sin(angle);emit(cat,p,[(p[0]+x*s[0]*c-y*s[1]*t,p[1]+x*s[0]*t+y*s[1]*c,p[2]+z*s[2]) for x,y,z in CUBE],CF,m)
def rod(cat,a,b,r,m,n=10,r2=None,smooth=True):
    a=Vector(a);b=Vector(b);q=(b-a).to_track_quat('Z','Y');vs=[]
    for p,rr in [(a,r),(b,r if r2 is None else r2)]:
        for i in range(n):vs.append(tuple(p+q@Vector((math.cos(i*math.tau/n)*rr,math.sin(i*math.tau/n)*rr,0))))
    fs=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    emit(cat,tuple(a),vs,fs,m,smooth)
def beam(cat,a,b,w,h,m):
    a=Vector(a);b=Vector(b);mid=(a+b)/2;q=(b-a).to_track_quat('Z','Y')
    emit(cat,tuple(mid),[tuple(mid+q@Vector((x*w,y*h,z*(b-a).length))) for x,y,z in CUBE],CF,m)
def sphere(cat,p,r,m,scale=(1,1,1),n=12,levels=7,smooth=True):
    vs=[(p[0],p[1],p[2]+r*scale[2])]
    for j in range(1,levels):
        phi=math.pi*j/levels
        for i in range(n):
            a=i*math.tau/n;vs.append((p[0]+math.cos(a)*math.sin(phi)*r*scale[0],p[1]+math.sin(a)*math.sin(phi)*r*scale[1],p[2]+math.cos(phi)*r*scale[2]))
    vs.append((p[0],p[1],p[2]-r*scale[2]));last=len(vs)-1
    fs=[(0,1+i,1+(i+1)%n) for i in range(n)]
    for j in range(levels-2):
        for i in range(n):a=1+j*n+i;b=1+j*n+(i+1)%n;fs.append((a,a+n,b+n,b))
    fs.extend((last,last-n+(i+1)%n,last-n+i) for i in range(n))
    emit(cat,p,vs,fs,m,smooth)
def ring(cat,p,r,thick,m,axis='X',segments=28,sides=6):
    vs=[]
    for i in range(segments):
        a=i*math.tau/segments
        for j in range(sides):
            b=j*math.tau/sides;rr=r+math.cos(b)*thick
            v=(math.sin(b)*thick,math.cos(a)*rr,math.sin(a)*rr)
            if axis=='Y':v=(v[1],v[0],v[2])
            if axis=='Z':v=(v[1],v[2],v[0])
            vs.append(tuple(p[k]+v[k] for k in range(3)))
    fs=[(i*sides+j,((i+1)%segments)*sides+j,((i+1)%segments)*sides+(j+1)%sides,i*sides+(j+1)%sides) for i in range(segments) for j in range(sides)]
    emit(cat,p,vs,fs,m,True)

# Continuous outer terrain, connected to the original ground instead of a flat slab.
def smoothstep(a,b,x):
    t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
def road_x(y):return 12*math.sin(max(0,-y-220)/68)
peaks=[(-370,-105,180,92,128),(-405,190,220,120,90),(-215,380,173,108,90),(83,360,205,105,85),(344,322,215,105,115),(389,27,193,95,137),(382,-237,146,105,100),(-332,-382,128,92,104),(162,-425,137,99,113),(-560,-250,235,135,140),(526,470,230,130,130),(-536,500,246,140,140),(570,-470,163,130,150)]
def height(x,y):
    d=max(abs(x)-240,abs(y)-220,0)
    if d<=0:return -.15
    h=0
    for px,py,ph,sx,sy in peaks:h+=ph*math.exp(-(((x-px)/sx)**2+((y-py)/sy)**2)*.8)
    ridges=(math.sin(x*.041+y*.018)+math.sin(x*.018-y*.039)*.7+math.cos(x*.073+y*.053)*.35)
    detail=math.sin(x*.157+y*.071)*math.cos(y*.129-x*.037)*2.2
    h=(h*.76+27+ridges*10+detail)*smoothstep(0,58,d)
    # Carve a graded southern pass: trees and boulders respect it too.
    if y< -220:
        passage=smoothstep(19,64,abs(x-road_x(y)))
        grade=max(0,-y-220)*.008
        h=h*passage+grade*(1-passage)
    return h-.15
xs=sorted(set(list(range(-700,701,6))+[-700,-240,-220,0,220,240,700]));ys=sorted(set(list(range(-630,631,6))+[-630,-220,-199,0,199,220,630]))
terrain_tiles={}
for iy in range(len(ys)-1):
    for ix in range(len(xs)-1):
        xa,xb=xs[ix:ix+2];ya,yb=ys[iy:iy+2];x=(xa+xb)/2;y=(ya+yb)/2
        if abs(x)<240 and abs(y)<220:continue
        z=height(x,y);slope=math.hypot(height(x+2,y)-height(x-2,y),height(x,y+2)-height(x,y-2))/4
        m=GRASS  # Continuous altitude/slope shader is applied in finish_v3.py.
        vs=[(xa,ya,height(xa,ya)),(xb,ya,height(xb,ya)),(xb,yb,height(xb,yb)),(xa,yb,height(xa,yb))]
        emit('MountainTerrain',(x,y,z),vs,[(0,1,2),(0,2,3)],m,True)
# Terrain vertices at tile boundaries coincide; weld per tile before rendering.
mountain_points=[]
for i in range(650):
    a=R.random()*math.tau;edge=R.randrange(4)
    if edge<2:x=R.choice([-1,1])*R.uniform(246,450);y=R.uniform(-420,430)
    else:x=R.uniform(-420,425);y=R.choice([-1,1])*R.uniform(226,415)
    if y< -215 and abs(x-road_x(y))<35:continue
    z=height(x,y);slope=math.hypot(height(x+2,y)-height(x-2,y),height(x,y+2)-height(x,y-2))/4
    if slope>1.22 or z>157:continue
    mountain_points.append((x,y,z,R.uniform(8,17)))
for i in range(120):
    edge=R.randrange(4)
    if edge<2:x=R.choice([-1,1])*R.uniform(242,400);y=R.uniform(-365,370)
    else:x=R.uniform(-370,370);y=R.choice([-1,1])*R.uniform(223,380)
    if y< -220 and abs(x-road_x(y))<39:continue
    z=height(x,y);sphere('MountainBoulders',(x,y,z+R.uniform(.3,1.8)),R.uniform(1,4.5),ROCK2,(R.uniform(.8,1.7),R.uniform(.8,1.4),R.uniform(.6,1.6)),9,5,False)
# Approach road follows the pass and continues out of the normal camera framing.
for road_index,y in enumerate(range(-220,-627,-7)):
    y2=y-7;x=road_x(y);x2=road_x(y2)
    vs=[(x-5.5,y,height(x-5.5,y)+.24),(x+5.5,y,height(x+5.5,y)+.24),(x2+5.5,y2,height(x2+5.5,y2)+.24),(x2-5.5,y2,height(x2-5.5,y2)+.24)]
    emit('ApproachRoad',(x,y,0),vs,[(0,3,2,1)],ASPHALT)
    mid=(Vector((x,y,height(x,y)+.26))+Vector((x2,y2,height(x2,y2)+.26)))/2
    beam('ApproachMarkings',mid-Vector((0,1.6,0)),mid+Vector((0,1.6,0)),.12,.02,LINE)
    for side in [-1,1]:
        a=(x+side*5,y,height(x+side*5,y)+.28);b=(x2+side*5,y2,height(x2+side*5,y2)+.28)
        beam('ApproachMarkings',a,b,.1,.02,LINE)
    if road_index%3==0:
        for side in [-1,1]:
            xx=x+side*6.5;z=height(xx,y)
            rod('ApproachPosts',(xx,y,z),(xx,y,z+1),.04,METAL,8);box('ApproachPosts',(xx,y,z+.87),(.14,.04,.14),PLATE)

# Identify the old cars before removing only their generated geometry.
sites=[]
for o in list(bpy.data.collections['Vehicles'].objects):
    if not o.name.startswith('CarBody'):continue
    sites.append({'x':o.location.x,'y':o.location.y,'angle':o.rotation_euler.z-math.pi/2,'source':'base','paint':o.data.materials[0].name})
v2_sites=[]
for o in list(expanded.objects):
    if not o.name.startswith('VehiclesV2'):continue
    vs=o.data.vertices
    for i in range(len(vs)-7):
        block=[v.co for v in vs[i:i+8]]
        lo=[min(v[k] for v in block) for k in range(3)];hi=[max(v[k] for v in block) for k in range(3)];dim=[hi[k]-lo[k] for k in range(3)]
        if abs(dim[2]-.46)>.005:continue
        if not ((abs(dim[0]-1.88)<.015 and abs(dim[1]-4.45)<.015) or (abs(dim[1]-1.88)<.015 and abs(dim[0]-4.45)<.015)):continue
        x=(lo[0]+hi[0])/2;y=(lo[1]+hi[1])/2
        if any(abs(x-s['x'])<.05 and abs(y-s['y'])<.05 for s in v2_sites):continue
        d=block[1]-block[0];angle=math.atan2(d.y,d.x)
        v2_sites.append({'x':x,'y':y,'angle':angle,'source':'v2'})
sites.extend(v2_sites)
if len(sites)!=41:raise RuntimeError(f'Expected 41 known generated cars, found {len(sites)}. Refusing removal.')
for o in list(bpy.data.collections['Vehicles'].objects):bpy.data.objects.remove(o,do_unlink=True)
removed_vehicle_faces=0
for o in list(expanded.objects):
    if o.name.startswith('CarDetails'):
        bpy.data.objects.remove(o,do_unlink=True);continue
    if not o.name.startswith('VehiclesV2'):continue
    bm=bmesh.new();bm.from_mesh(o.data);remove=[]
    for f in bm.faces:
        p=o.matrix_world@f.calc_center_median()
        for s in v2_sites:
            dx=p.x-s['x'];dy=p.y-s['y'];c=math.cos(s['angle']);t=math.sin(s['angle'])
            lx=dx*c+dy*t;ly=-dx*t+dy*c
            if abs(lx)<1.45 and abs(ly)<2.5 and -.05<p.z<2.6:remove.append(f);break
    removed_vehicle_faces+=len(remove)
    bmesh.ops.delete(bm,geom=remove,context='FACES')
    loose=[v for v in bm.verts if not v.link_faces]
    if loose:bmesh.ops.delete(bm,geom=loose,context='VERTS')
    if not bm.faces:
        bm.free();bpy.data.objects.remove(o,do_unlink=True)
    else:bm.to_mesh(o.data);bm.free();o.data.update()

# Cars are modeled in their own local coordinates, then positioned at old sites.
car_models={};paint_palette=[SILVER,RED,BLUE,GREEN,WHITE,TEAL,SAND,ORANGE]
def car(site,index):
    global active_car
    active_car=index
    styles=['Sedan','Hatchback','SUV','Wagon','Pickup','SportCoupe','Sedan','Hatchback']
    style=styles[index%len(styles)]
    if index==9:style='SecuritySUV'
    if abs(site['x']+162)<.1 and abs(site['y']+71)<.1:style='Ambulance'
    paint=paint_palette[(index*3)%len(paint_palette)]
    if style=='SecuritySUV':paint=WHITE
    if style=='Ambulance':paint=WHITE
    SUV=style in ['SUV','SecuritySUV'];PICK=style=='Pickup';VAN=style=='Ambulance';SPORT=style=='SportCoupe';HATCH=style=='Hatchback';WAGON=style=='Wagon'
    L=5.0 if PICK else 5.15 if VAN else 4.75 if WAGON else 4.72 if SUV else 4.15 if HATCH else 4.55 if SPORT else 4.65
    W=1.95 if SUV or PICK or VAN else 1.86 if SPORT else 1.82
    wheel_r=.49 if SUV or PICK else .45 if VAN else .415 if HATCH else .44
    wheel_z=wheel_r+.09;belt=1.24 if SUV or PICK else 1.31 if VAN else 1.12 if SPORT else 1.1
    roof=2.34 if VAN else 1.98 if SUV else 1.86 if PICK else 1.69 if HATCH else 1.53 if SPORT else 1.73
    front_axle=-L*.29;rear_axle=L*.29
    def width(y):return W/2*(.84+.16*math.sin(math.pi*min(1,max(0,(y+L/2)/L)))**.3)
    def hoodz(y):return belt-.07+.08*math.cos(y/L*math.pi)
    # Side panels explicitly follow wheel arches; tyres are not embedded in blocks.
    N=58
    for side in [-1,1]:
        vs=[]
        for j in range(N+1):
            y=-L/2+j*L/N;bot=.37 if not SUV and not PICK else .46
            for axle in [front_axle,rear_axle]:
                dy=y-axle;r=wheel_r+.075
                if abs(dy)<r:bot=max(bot,wheel_z+math.sqrt(r*r-dy*dy))
            vs.extend([(side*width(y),y,bot),(side*(width(y)-.035),y,hoodz(y))])
        fs=[(2*j,2*j+2,2*j+3,2*j+1) if side<0 else (2*j+1,2*j+3,2*j+2,2*j) for j in range(N)]
        emit('CarBody', (0,0,0),vs,fs,paint,True)
        # Sculpted wheel-arch molding and fender edge.
        for axle in [front_axle,rear_axle]:
            for j in range(25):
                a=j*math.pi/25;b=(j+1)*math.pi/25;rr=wheel_r+.083
                pa=(side*(W/2+.018),axle+math.cos(a)*rr,wheel_z+math.sin(a)*rr)
                pb=(side*(W/2+.018),axle+math.cos(b)*rr,wheel_z+math.sin(b)*rr)
                rod('CarFenderTrim',pa,pb,.035,BLACK if SUV or PICK else paint,6)
        box('CarTrim',(side*(W/2+.02),.06,.5),(.055,L*.36,.12),BLACK)
        box('CarTrim',(side*(W/2+.03),.07,belt-.18),(.015,L*.43,.05),CHROME)
    # Hood and rear deck are subtly curved surfaces rather than rectangular slabs.
    def surface(y0,y1,zfun,m,width_scale=1):
        vs=[];nx=10;ny=10
        for j in range(ny+1):
            y=y0+(y1-y0)*j/ny
            for i in range(nx+1):
                u=-1+2*i/nx;vs.append((width(y)*u*width_scale,y,zfun(y)+.035*(1-u*u)))
        fs=[(j*(nx+1)+i,j*(nx+1)+i+1,(j+1)*(nx+1)+i+1,(j+1)*(nx+1)+i) for j in range(ny) for i in range(nx)]
        emit('CarSheetmetal',(0,0,1),vs,fs,m,True)
    windshield_y=-.92 if not VAN else -1.15
    roof_front=-.4 if not SUV and not VAN else -.71
    roof_rear=.64 if not SUV and not WAGON and not HATCH else 1.13 if not HATCH else .86
    rear_base=1.21 if not SUV and not WAGON else 1.69
    if PICK:roof_rear=.1;rear_base=.4
    if VAN:roof_rear=1.63;rear_base=1.95
    surface(-L/2,windshield_y,hoodz,paint)
    if not PICK:surface(rear_base,L/2,hoodz,paint)
    box('CarChassis',(0,0,.39),(W*.77,L*.78,.15),BLACK)
    # Front and rear bumper shells with curved rings.
    for front in [True,False]:
        y=-L/2 if front else L/2;vs=[]
        for zz,ww,dy in [(.45,.9,.02),(.62,1,.04),(.89,.94,.04),(hoodz(y),.83,0)]:
            for j in range(11):
                u=-1+j*.2;vs.append((u*W/2*ww,y+(1 if front else -1)*(.11*u*u+dy),zz))
        fs=[(j*11+i,j*11+i+1,(j+1)*11+i+1,(j+1)*11+i) for j in range(3) for i in range(10)]
        emit('CarBumper',(0,y,.7),vs,fs,paint,True)
        box('CarTrim',(0,y+(-.015 if front else .015),.46),(W*.92,.07,.13),BLACK)
        box('CarPlate',(0,y+(-.065 if front else .065),.71),(.46,.045,.12),PLATE)
        for j in range(7):box('PlateCharacters',(-.17+j*.052,y+(-.09 if front else .09),.71),(.026,.01,.06),BLACK)
        for dx in [-.7,.7]:
            box('CarLampHousing',(dx,y+(-.045 if front else .045),.95),(.47,.07,.19),BLACK)
            if front:
                for dd in [-.11,.08]:sphere('CarProjector',(dx+dd,y-.091,.965),.075,HEAD,(1,.25,1),12,7)
                box('CarLampDRL',(dx,y-.105,1.047),(.42,.035,.023),HEAD)
                box('CarFogLamp',(dx*.92,y-.058,.59),(.22,.04,.055),HEAD)
            else:
                box('CarTailLens',(dx,y+.09,.96),(.43,.055,.13),TAIL)
                for z in [.938,.98]:box('CarTailLens',(dx,y+.121,z),(.39,.016,.013),TAIL)
            box('CarIndicator',(dx+(1 if dx>0 else -1)*.18,y+(-.11 if front else .11),.975),(.04,.018,.09),AMBER)
    # Unique grilles and bumper intakes.
    box('CarGrille',(0,-L/2-.056,.975),(.81,.045,.15),BLACK)
    for j in range(9):box('CarGrille',(-.36+j*.09,-L/2-.09,.975),(.025,.016,.12),CHROME)
    for dx in [-.21,.21]:box('CarAirIntake',(dx,-L/2-.06,.55),(.26,.03,.08),BLACK)
    sphere('CarBadge',(0,-L/2-.11,1.0),.05,CHROME,(1,.12,1),10,6)
    for x in [-W*.28,W*.28]:rod('CarExhaust',(x,L/2-.18,.39),(x,L/2+.02,.39),.065,CHROME,12)
    # Glazing: sloped windshield, rear glass and side windows, with A/B/C pillars.
    bw=W*.43;tw=W*.36
    frontglass=[(-bw,windshield_y,belt+.015),(bw,windshield_y,belt+.015),(tw,roof_front,roof-.075),(-tw,roof_front,roof-.075)]
    emit('CarWindshield',(0,-.7,1.5),frontglass,[(0,1,2,3)],GLASS)
    backglass=[(-tw,roof_rear,roof-.08),(tw,roof_rear,roof-.08),(bw,rear_base,belt+.015),(-bw,rear_base,belt+.015)]
    emit('CarRearGlass',(0,1,1.5),backglass,[(0,1,2,3)],GLASS)
    for side in [-1,1]:
        # A continuous roof bow with side windows split by structural pillars.
        coords=[(side*bw,windshield_y,belt),(side*tw,roof_front,roof-.06),(side*tw,roof_rear,roof-.07),(side*bw,rear_base,belt)]
        emit('CarSideGlass',(0,0,1.5),coords,[(0,1,2,3)] if side>0 else [(3,2,1,0)],GLASS)
        for a,b in [(coords[0],coords[1]),(coords[1],coords[2]),(coords[2],coords[3]),(coords[3],coords[0])]:rod('CarWindowTrim',a,b,.026,CHROME if not SUV else BLACK,8)
        for yy in ([.11,.92] if VAN or SUV or WAGON else [.12]):
            beam('CarPillars',(side*bw,yy,belt),(side*tw,yy,roof-.065),.052,.055,BLACK)
        for yy in ([.09,.99] if not PICK and not SPORT else [.14]):
            box('CarDoorHandle',(side*(W/2+.016),yy-.14,belt-.07),(.055,.19,.048),CHROME)
            # Fine dark seam along each door trailing edge.
            beam('CarDoorSeam',(side*(W/2+.01),yy,.52),(side*(W/2-.035),yy,belt-.04),.012,.012,BLACK)
        box('CarMirrorStalk',(side*(W/2+.055),windshield_y+.26,belt+.1),(.15,.08,.065),BLACK)
        sphere('CarMirrorHousing',(side*(W/2+.19),windshield_y+.22,belt+.18),.14,paint,(1.13,1.2,.55),12,7)
        box('CarMirrorLens',(side*(W/2+.2),windshield_y+.375,belt+.19),(.19,.022,.095),MIRROR)
    surface(roof_front,roof_rear,lambda y:roof+.022*math.sin((y-roof_front)/(roof_rear-roof_front)*math.pi),paint,.74)
    box('CarRoofHeader',(0,roof_front,roof-.027),(W*.74,.13,.105),paint)
    box('CarRoofHeader',(0,roof_rear,roof-.042),(W*.74,.13,.105),paint)
    # Roof edge sheet metal connects the glazed cabin to the body.
    for side in [-1,1]:
        beam('CarRoofRails',(side*tw,roof_front,roof),(side*tw,roof_rear,roof-.01),.065,.065,paint)
        beam('CarPillars',(side*bw,windshield_y,belt),(side*tw,roof_front,roof-.06),.06,.08,paint)
        beam('CarPillars',(side*tw,roof_rear,roof-.07),(side*bw,rear_base,belt),.065,.085,paint)
    # Wipers, hood shut lines, glass seals and antenna.
    for xx in [-.38,.28]:
        rod('CarWipers',(xx,windshield_y-.01,belt+.055),(xx+.24,windshield_y+.13,belt+.17),.012,BLACK,6)
        rod('CarWipers',(xx+.24,windshield_y+.13,belt+.17),(xx+.49,windshield_y+.13,belt+.17),.019,BLACK,6)
    for xx in [-W*.3,W*.3]:beam('CarHoodCrease',(xx,-L/2+.2,hoodz(-L/2+.2)+.02),(xx,windshield_y-.02,belt+.025),.014,.014,paint)
    rod('CarAntenna',(0,roof_rear-.07,roof+.03),(0,roof_rear+.04,roof+.24),.014,BLACK,6)
    # Interior visible through tint: dashboard, seats, headrests and wheel.
    box('CarInterior',(0,windshield_y+.26,belt-.1),(W*.77,.4,.18),BLACK)
    box('CarInterior',(-.38,windshield_y+.26,belt+.03),(.29,.08,.12),BLACK)
    box('CarInterior',(.1,windshield_y+.24,belt+.04),(.21,.028,.13),GLASS)
    ring('CarSteering',(-.38,windshield_y+.52,belt-.02),.15,.024,BLACK,'Y',20,6)
    for dx in [-.37,.37]:
        box('CarInterior',(dx,-.05,.77),(.46,.51,.12),SEAT)
        box('CarInterior',(dx,.16,1.08),(.47,.13,.55),SEAT)
        sphere('CarInterior',(dx,.16,1.4),.14,SEAT,(1.35,.7,.7),10,6)
        for yy in [-.2,-.05,.1]:box('CarInterior',(dx,yy,.84),(.43,.015,.018),BLACK)
    if not PICK:box('CarInterior',(0,.91,.83),(W*.74,.45,.16),SEAT)
    box('CarInterior',(0,.08,.89),(.18,.44,.13),BLACK)
    rod('CarGearLever',(0,-.05,.96),(0,-.1,1.08),.018,CHROME,8)
    # Detailed tyres, rim lips, ventilated brake discs, spokes, lugs and tread blocks.
    for side in [-1,1]:
        for axle in [front_axle,rear_axle]:
            x=side*(W/2+.008);prof=[(-.145,.29),(-.165,.34),(-.145,wheel_r-.035),(-.095,wheel_r),(.095,wheel_r),(.145,wheel_r-.035),(.165,.34),(.145,.29)]
            vs=[];ns=36
            for j in range(ns):
                a=j*math.tau/ns
                for xx,rr in prof:vs.append((x+xx,axle+math.cos(a)*rr,wheel_z+math.sin(a)*rr))
            fs=[(j*8+i,((j+1)%ns)*8+i,((j+1)%ns)*8+(i+1)%8,j*8+(i+1)%8) for j in range(ns) for i in range(8)]
            emit('CarTyres',(x,axle,wheel_z),vs,fs,RUBBER,True)
            hubx=x+side*.15
            ring('CarRim',(hubx,axle,wheel_z),.28,.025,CHROME,'X',32,7)
            rod('CarBrakeDisc',(hubx-side*.07,axle,wheel_z),(hubx-side*.055,axle,wheel_z),.255,BRUSH,30)
            box('CarBrakeCaliper',(hubx-side*.035,axle+.19,wheel_z),(.05,.1,.21),CALIPER)
            rod('CarHub',(hubx,axle,wheel_z),(hubx+side*.035,axle,wheel_z),.072,CHROME,16)
            spokes=5 if SPORT or HATCH else 6
            for j in range(spokes):
                a=j*math.tau/spokes
                for off in [-.05,.05]:
                    beam('CarSpokes',(hubx,axle+math.cos(a+off)*.08,wheel_z+math.sin(a+off)*.08),(hubx,axle+math.cos(a+off)*.26,wheel_z+math.sin(a+off)*.26),.045,.03,CHROME)
                rod('CarLugs',(hubx+side*.02,axle+math.cos(a)*.045,wheel_z+math.sin(a)*.045),(hubx+side*.045,axle+math.cos(a)*.045,wheel_z+math.sin(a)*.045),.011,METAL,6)
            for j in range(40):
                a=j*math.tau/40
                for shift in [-.085,.085]:
                    pa=(x+shift-.035,axle+math.cos(a)*wheel_r,wheel_z+math.sin(a)*wheel_r)
                    pb=(x+shift+.035,axle+math.cos(a+.022)*wheel_r,wheel_z+math.sin(a+.022)*wheel_r)
                    beam('CarTreads',pa,pb,.018,.012,TREAD)
            # Valve stem and small rim balancing weight.
            rod('CarValve',(hubx,axle-.21,wheel_z+.14),(hubx+side*.04,axle-.21,wheel_z+.14),.012,BLACK,6)
    if SUV or WAGON:
        for xx in [-.57,.57]:
            rod('CarRoofRack',(xx,roof_front+.15,roof+.07),(xx,roof_rear-.05,roof+.07),.045,CHROME,10)
        for yy in [roof_front+.25,roof_rear-.15]:beam('CarRoofRack',(-.58,yy,roof+.14),(.58,yy,roof+.14),.07,.04,BLACK)
        if index%3==0:
            sphere('CarRoofCargo',(0,.3,roof+.29),.55,BLACK,(.9,1.7,.32),16,9)
    if PICK:
        # Open pickup bed, corrugated floor, wheel housings, tailgate and a toolbox.
        box('PickupBed',(0,1.26,.95),(W*.76,1.58,.09),BLACK)
        for xx in [-W*.4,W*.4]:box('PickupBed',(xx,1.3,1.18),(.14,1.73,.45),paint)
        box('PickupBed',(0,L/2-.05,1.12),(W*.81,.12,.37),paint)
        for xx in [-.5,-.25,0,.25,.5]:box('PickupBed',(xx,1.3,1.012),(.035,1.54,.035),METAL)
        box('PickupBed',(0,.63,1.2),(W*.75,.38,.32),CHROME)
        box('PickupBed',(0,L/2+.025,1.2),(.25,.035,.05),BLACK)
    if SPORT:
        for xx in [-.56,.56]:box('CarSpoiler',(xx,1.56,1.13),(.055,.08,.2),BLACK)
        box('CarSpoiler',(0,1.56,1.25),(1.37,.22,.07),BLACK)
        for xx in [-.16,.16]:
            box('CarStripes',(xx,-1.6,hoodz(-1.6)+.045),(.12,.95,.008),BLACK)
    if style=='SecuritySUV':
        for side in [-1,1]:box('SecurityLivery',(side*(W/2+.025),.45,1.03),(.018,1.05,.3),BLUE)
        box('EmergencyLights',(0,.25,roof+.13),(1.15,.25,.12),BLACK)
        for xx in [-.38,.38]:box('EmergencyLights',(xx,.25,roof+.22),(.3,.23,.12),BLUE if xx<0 else TAIL)
        for dx in [-.62,.62]:rod('SecurityPushbar',(dx,-L/2-.2,.45),(dx,-L/2-.2,1.0),.05,BLACK,8)
        rod('SecurityPushbar',(-.62,-L/2-.2,.85),(.62,-L/2-.2,.85),.06,BLACK,8)
    if VAN:
        for side in [-1,1]:
            box('AmbulanceLivery',(side*(W/2+.025),.83,1.16),(.025,2.64,.27),RED)
            box('AmbulanceLivery',(side*(W/2+.04),.75,1.53),(.02,.45,.12),RED)
            box('AmbulanceLivery',(side*(W/2+.045),.75,1.53),(.02,.12,.45),RED)
        box('EmergencyLights',(0,-.45,roof+.15),(1.16,.3,.1),BLACK)
        for xx in [-.4,.4]:box('EmergencyLights',(xx,-.45,roof+.24),(.3,.25,.15),TAIL)
    if index%6==0:
        # Grounded wear: small paint chips and contrasting lower panels.
        for j in range(9):
            y=R.uniform(-.5,.5);side=R.choice([-1,1]);box('CarWear',(side*(W/2+.026),y,.63+R.random()*.3),(.012,R.uniform(.025,.08),.013),SILVER)
    car_models[index]={'model':style,'position':[site['x'],site['y'],.08],'angle_radians':site['angle'],'length_metres':L,'width_metres':W,'paint':materials[paint].name}
    active_car=None
for index,site in enumerate(sites):car(site,index)

# Supplement existing buses/trucks rather than replacing their map locations.
for x,y in [(-30,-137),(13,-137)]:
    for side in [-1,1]:
        box('TransitDetail',(x+side*1.39,y-4.85,1.65),(.04,.75,2),BLACK)
        for z in [1.13,1.92,2.55]:box('TransitDetail',(x+side*1.42,y-4.85,z),(.018,.7,.025),CHROME)
        beam('TransitDetail',(x+side*1.25,y-5.2,2.75),(x+side*1.72,y-5.52,2.7),.06,.06,BLACK)
        box('TransitDetail',(x+side*1.72,y-5.5,2.42),(.18,.2,.55),BLACK)
        for yy in [-3.6,3.5]:ring('TransitDetail',(x+side*1.475,y+yy,.55),.32,.035,CHROME,'X',24,6)
    for xx in [-.5,.5]:rod('TransitDetail',(x+xx,y-5.91,1.6),(x+xx+.35,y-5.94,2.1),.014,BLACK,6)
    for xx in [-.8,-.6,-.4,0,.4,.6,.8]:box('TransitDetail',(x+xx,y-5.92,.56),(.08,.035,.25),METAL)
for x in [152,184,196]:
    y=35
    for side in [-1,1]:
        beam('TruckDetail',(x+side*1.32,y-3.65,2.8),(x+side*1.73,y-3.82,2.65),.05,.05,METAL)
        box('TruckDetail',(x+side*1.73,y-3.82,2.36),(.17,.25,.55),BLACK)
        for yy in [-3,1.2,2.5]:ring('TruckDetail',(x+side*1.455,y+yy,.65),.35,.025,CHROME,'X',24,6)
        box('TruckDetail',(x+side*1.32,y-2.7,.7),(.24,1.2,.11),METAL)
    for zz in [1.03,1.16,1.29]:box('TruckDetail',(x,y-4.3,zz),(1.6,.045,.04),CHROME)
    for xx in [-.9,0,.9]:box('TruckDetail',(x+xx,y-4,2.89),(.1,.1,.08),AMBER)

# Flush mesh batches. Cars receive independent pivots and descriptive metadata.
new_meshes=[]
for key,(vs,fs,indices,smooth) in batches.items():
    iscar=key[0]=='Car'
    name=(f"V3Car_{key[1]:02d}_{car_models[key[1]]['model']}" if iscar else '_'.join(str(x) for x in key))
    me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update()
    if key[0]=='MountainTerrain':
        bm=bmesh.new();bm.from_mesh(me);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.0001);bm.to_mesh(me);bm.free();me.update()
    obj=bpy.data.objects.new(name,me);(fleet if iscar or key[0] in ['TransitDetail','TruckDetail'] else scenery).objects.link(obj)
    used=sorted(set(indices));remap={i:j for j,i in enumerate(used)}
    for i in used:me.materials.append(materials[i])
    for p,i,sm in zip(me.polygons,indices,smooth):p.material_index=remap[i];p.use_smooth=sm
    if iscar:
        info=car_models[key[1]];obj.location=info['position'];obj.rotation_euler.z=info['angle_radians'];obj['vehicle_variant']=info['model'];obj['paint']=info['paint']
        # Body panels and roof are curved meshes; tyres have modeled round sections.
        # Avoid beveling every tread/bolt, which multiplies the export cost.
    new_meshes.append(obj)
# Shared pine meshes: all export instances remain real object placements.
for variant in range(3):
    name=f'AlpinePinePrototype_{variant}';vs=[];fs=[];ids=[]
    def cone(z0,z1,r0,r1,m,n=10):
        start=len(vs)
        for z,r in [(z0,r0),(z1,r1)]:
            for i in range(n):a=i*math.tau/n;vs.append((math.cos(a)*r,math.sin(a)*r,z))
        fs.extend([tuple(start+i for i in range(n-1,-1,-1)),tuple(start+n+i for i in range(n))]);ids.extend([m,m])
        for i in range(n):fs.append((start+i,start+(i+1)%n,start+(i+1)%n+n,start+i+n));ids.append(m)
    cone(0,10,.21,.06,WOOD,8)
    for j in range(7):cone(2+j*1.15,5.3+j*.95,2.5-j*.31,.025,LEAF if (j+variant)%3 else LEAF2,10)
    me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update()
    used=sorted(set(ids));remap={i:j for j,i in enumerate(used)}
    for i in used:me.materials.append(materials[i])
    for p,i in zip(me.polygons,ids):p.material_index=remap[i]
    for i,(x,y,z,h) in enumerate(mountain_points):
        if i%3!=variant:continue
        o=bpy.data.objects.new(f'AlpinePine_{i:03d}',me);scenery.objects.link(o);o.location=(x,y,z);o.scale=(h/12,h/12,h/12);o.rotation_euler.z=R.random()*math.tau;o['background_only']=True;new_meshes.append(o)
def camera(name,loc,target,lens=38,ortho=None):
    d=bpy.data.cameras.new(name);d.clip_end=5000;o=bpy.data.objects.new(name,d);pres.objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler();d.lens=lens
    if ortho:d.type='ORTHO';d.ortho_scale=ortho
    return o
hero=camera('CampusV3_Hero',(490,-610,535),(0,15,12),ortho=810)
camera('CampusV3_Cars',(-59,-60,3.8),(-53,-51,1.1),lens=36)
camera('CampusV3_Fence',(185,91,4.3),(265,126,36),lens=30)
camera('CampusV3_Entry',(26,-245,5.3),(0,-320,15),lens=28)
scene.camera=hero;scene.render.resolution_x=2200;scene.render.resolution_y=1500;scene.render.resolution_percentage=100;scene.cycles.samples=36;scene.cycles.use_denoising=True;scene.render.filepath=os.path.join(OUT,'Campus_Mountains_preview.png')
scene['mountain_vehicle_v3']=True;scene['design']='V3: 480x440m campus; continuous exterior mountain terrain 1400x1260m; 41 detailed cars; mesh boundary and road pass. Roblox runtime pending.'
scene['playable_dimensions_metres']=[480,440]
exec(compile(open(os.path.join(OUT,'finish_v3.py'),encoding='utf-8').read(),'finish_v3.py','exec'))
mesh_objects=[o for c in [root,expanded,scenery,fleet] for o in c.all_objects if o.type=='MESH']
deps=bpy.context.evaluated_depsgraph_get()
report={'version':3,'playable_dimensions_metres':[480,440],'exterior_bounds_metres':[1400,1260],'mountain_peak_vertices_max_m':max(height(x,y) for x in xs for y in ys),'cars_replaced':len(sites),'vehicle_variants':sorted(set(c['model'] for c in car_models.values())),'cars':list(car_models.values()),'pine_instances':len(mountain_points),'mesh_objects':len(mesh_objects),'base_triangles':sum(len(p.vertices)-2 for o in mesh_objects for p in o.data.polygons),'evaluated_triangles':sum(len(p.vertices)-2 for o in mesh_objects for p in o.evaluated_get(deps).data.polygons),'removed_old_vehicle_faces':removed_vehicle_faces,'wire_fence_bounds':{'x':[-220,220],'y':[-199,199]},'south_approach_open':True,'runtime_verified':False,'visual_checked':[]}
with open(os.path.join(OUT,'Campus_Mountains_manifest.json'),'w',encoding='utf-8') as f:json.dump(report,f,indent=2)
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'Campus_Mountains.blend'))
# Blender 5.2 FBX material registration fails for some linked instances. Temporary
# unique mesh data avoids that exporter issue while the editable .blend stays linked.
export_copies=[]
try:
    for obj in scenery.objects:
        if obj.name.startswith('AlpinePine_'):
            shared=obj.data;copy=shared.copy();obj.data=copy;export_copies.append((obj,shared,copy))
    with bpy.context.temp_override(selected_objects=mesh_objects,selected_editable_objects=mesh_objects,active_object=mesh_objects[0]):
        bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,'Campus_Mountains.fbx'),use_selection=True,add_leaf_bones=False,axis_forward='-Z',axis_up='Y',use_mesh_modifiers=True)
finally:
    for obj,shared,copy in export_copies:
        obj.data=shared;bpy.data.meshes.remove(copy)
car_exports=[o for o in fleet.all_objects if o.name.startswith('V3Car_')]
with bpy.context.temp_override(selected_objects=car_exports,selected_editable_objects=car_exports,active_object=car_exports[0]):
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,'Detailed_Vehicles.fbx'),use_selection=True,add_leaf_bones=False,axis_forward='-Z',axis_up='Y',use_mesh_modifiers=True)
print(json.dumps({k:v for k,v in report.items() if k!='cars'}))
