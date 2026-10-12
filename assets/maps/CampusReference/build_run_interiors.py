"""Campus V4: themed interiors and authored future activity sites.
Run against the live V3 scene or Campus_V3_WorkingCheckpoint.blend.
No Roblox scripts, rewards, enemy events or economy behavior are implemented here.
"""
import bpy,bmesh,math,random,os,json,io,contextlib
from mathutils import Vector
R=random.Random(41112)
OUT=r'C:\Roblox\ZombilkaFPS\assets\maps\CampusReference'
scene=bpy.context.scene
if scene.get('run_interiors_v4'):raise RuntimeError('Already V4; reopen the V3 working checkpoint before reproducing.')
if bpy.context.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
root=bpy.data.collections['Campus_Map'];old=bpy.data.collections['Campus_Expansion_V2'];pres=bpy.data.collections['Presentation']
interiors=bpy.data.collections.new('V4_Run_Interiors');scene.collection.children.link(interiors)
sites_collection=bpy.data.collections.new('V4_Activity_Sites');scene.collection.children.link(sites_collection)
markers_collection=bpy.data.collections.new('V4_Activity_Markers');scene.collection.children.link(markers_collection)
materials=[]
def material(name,c,metal=0,rough=.6,emission=0):
    m=bpy.data.materials.get('Campus_'+name)
    if not m:
        m=bpy.data.materials.new('Campus_'+name);m.use_nodes=True;m.diffuse_color=(*c,1)
        p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
        if emission:p.inputs['Emission Color'].default_value=(*c,1);p.inputs['Emission Strength'].default_value=emission
    if m not in materials:materials.append(m)
    return materials.index(m)
STEEL=material('Steel',(.11,.14,.16),.6);CHROME=material('Chrome',(.5,.54,.57),.8,.2);BLACK=material('InteriorBlack',(.023,.03,.035));PANEL=material('Cladding',(.38,.42,.43),.28);GRAY=material('V4CabinetGray',(.25,.3,.32),.25)
IVORY=material('V4Ivory',(.68,.7,.67));PAPER=material('V4Paper',(.74,.73,.66));WOOD=material('Bark',(.14,.1,.075));SEAT=material('V4Seat',(.11,.17,.2));RED=material('V4Red',(.42,.055,.035),.25);ORANGE=material('V4Orange',(.72,.29,.065));TAN=material('V4CargoTan',(.4,.29,.17));BLUE=material('V4Blue',(.05,.13,.25));TEAL=material('V4Teal',(.035,.25,.24));GOLD=material('V4LootAmber',(.95,.54,.11),.3,.27,1);CYAN=material('V4Cyan',(.08,.6,.79),.1,.35,1.6);MINT=material('V4Mint',(.12,.62,.38),.15,.4,1.1);PURPLE=material('V4RiskPurple',(.42,.065,.57),.15,.4,1.2);SOFT=material('V4SoftWhite',(.77,.83,.85),0,.6,2.5);WARM=material('WarmLight',(1,.62,.25),emission=3);GLASS=material('V4LabGlass',(.16,.3,.32),.1,.1);SOIL=material('Soil',(.085,.062,.045));LEAF=material('Foliage',(.1,.19,.11));CONCRETE=material('Concrete',(.29,.33,.34));LABFLOOR=material('V4LabFloor',(.32,.4,.4),.12,.57);OFFICEFLOOR=material('V4OfficeFloor',(.23,.24,.235));SHOPFLOOR=material('V4WorkshopFloor',(.23,.27,.29),.15,.65);HOSPITALFLOOR=material('V4HospitalFloor',(.43,.49,.45));CAFEFLOOR=material('V4CafeFloor',(.33,.23,.15))
p=next(n for n in materials[GLASS].node_tree.nodes if n.type=='BSDF_PRINCIPLED');p.inputs['Transmission Weight'].default_value=.48
ORIGIN=(0,0,0);ROTATION=0;current_building='Structures';current_floor='';forced=None
batches={};activity_records=[];breakables=[];labels=[];light_records=[];nav_records=[];solid_records=[];counts={};vehicle_displays=[]
CUBE=[(-.5,-.5,-.5),(.5,-.5,-.5),(.5,.5,-.5),(-.5,.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(.5,.5,.5),(-.5,.5,.5)]
CF=[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)]
def world(p):
    c=math.cos(ROTATION);s=math.sin(ROTATION)
    return [ORIGIN[0]+p[0]*c-p[1]*s,ORIGIN[1]+p[0]*s+p[1]*c,ORIGIN[2]+p[2]]
def oriented(fn,x,y,angle=0):
    global ORIGIN,ROTATION
    previous_origin=ORIGIN;previous_rotation=ROTATION
    ORIGIN=world((x,y,0));ROTATION+=angle
    fn(0,0)
    ORIGIN=previous_origin;ROTATION=previous_rotation
def emit(cat,p,vs,fs,m,smooth=False):
    key=('Independent',forced) if forced else (current_building,current_floor,cat)
    if key not in batches:batches[key]=[[],[],[],[]]
    b=batches[key];start=len(b[0]);b[0].extend(world(v) for v in vs);b[1].extend(tuple(start+i for i in f) for f in fs);b[2].extend([m]*len(fs));b[3].extend([smooth]*len(fs));counts[cat]=counts.get(cat,0)+1
def box(cat,p,s,m,angle=0):
    c=math.cos(angle);t=math.sin(angle)
    emit(cat,p,[(p[0]+x*s[0]*c-y*s[1]*t,p[1]+x*s[0]*t+y*s[1]*c,p[2]+z*s[2]) for x,y,z in CUBE],CF,m)
    if cat in ['Cover','CargoRacks','Servers','LabPods','Medical','Armory','Workshop','Storage','Retail','Furniture','Activity']:
        solid_records.append({'building':current_building,'floor':current_floor,'p':world(p),'s':list(s),'angle':angle,'kind':cat})
def rod(cat,a,b,r,m,n=10,r2=None):
    a=Vector(a);b=Vector(b);q=(b-a).to_track_quat('Z','Y');vs=[]
    for p,rr in [(a,r),(b,r if r2 is None else r2)]:
        for j in range(n):v=q@Vector((math.cos(j*math.tau/n)*rr,math.sin(j*math.tau/n)*rr,0));vs.append(tuple(p+v))
    fs=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
    emit(cat,tuple(a),vs,fs,m,True)
def cylinder(cat,p,r,h,m,n=16):rod(cat,(p[0],p[1],p[2]-h/2),(p[0],p[1],p[2]+h/2),r,m,n)
def beam(cat,a,b,w,h,m):
    a=Vector(a);b=Vector(b);q=(b-a).to_track_quat('Z','Y');mid=(a+b)/2
    emit(cat,tuple(mid),[tuple(mid+q@Vector((x*w,y*h,z*(b-a).length))) for x,y,z in CUBE],CF,m)
def sphere(cat,p,r,m,s=(1,1,1),n=12,levels=7):
    vs=[(p[0],p[1],p[2]+r*s[2])]
    for j in range(1,levels):
        phi=j*math.pi/levels
        for i in range(n):a=i*math.tau/n;vs.append((p[0]+math.cos(a)*math.sin(phi)*r*s[0],p[1]+math.sin(a)*math.sin(phi)*r*s[1],p[2]+math.cos(phi)*r*s[2]))
    vs.append((p[0],p[1],p[2]-r*s[2]));last=len(vs)-1
    fs=[(0,1+i,1+(i+1)%n) for i in range(n)]
    for j in range(levels-2):
        for i in range(n):a=1+j*n+i;b=1+j*n+(i+1)%n;fs.append((a,a+n,b+n,b))
    fs.extend((last,last-n+(i+1)%n,last-n+i) for i in range(n));emit(cat,p,vs,fs,m,True)
def torus(cat,p,r,thick,m):
    vs=[];n=24;s=6
    for i in range(n):
        a=i*math.tau/n
        for j in range(s):b=j*math.tau/s;rr=r+math.cos(b)*thick;vs.append((p[0]+math.cos(a)*rr,p[1]+math.sin(a)*rr,p[2]+math.sin(b)*thick))
    fs=[(i*s+j,((i+1)%n)*s+j,((i+1)%n)*s+(j+1)%s,i*s+(j+1)%s) for i in range(n) for j in range(s)];emit(cat,p,vs,fs,m,True)
def sign(body,p,size=.5,angle=0):labels.append((body,world(p),size,angle+ROTATION,current_building,current_floor))
def area_light(p,power=600,color=(.68,.8,1),size=4):light_records.append({'p':world(p),'power':power,'color':color,'size':size,'building':current_building})
def rail(a,b):
    a=Vector(a);b=Vector(b);rod('Rails',a+Vector((0,0,1.05)),b+Vector((0,0,1.05)),.035,STEEL)
    num=max(2,int((b-a).length/1.7))
    for j in range(num+1):p=a.lerp(b,j/num);rod('Rails',p,p+Vector((0,0,1.05)),.028,STEEL)
def stairs(x,y,w,run,rise,z=0):
    n=max(10,int(rise/.16))
    for j in range(n):
        top=z+rise*(j+1)/n;yy=y+run*(j+.5)/n
        box('Stairs',(x,yy,(z+top)/2),(w,abs(run)/n,top-z),CONCRETE)
        box('StairNosings',(x,y+run*j/n,top+.013),(w,.07,.023),STEEL)
    for dx in [-w/2+.13,w/2-.13]:rail((x+dx,y,z),(x+dx,y+run,z+rise))
exec(compile(open(os.path.join(OUT,'interior_assets.py'),encoding='utf-8').read(),'interior_assets.py','exec'))

def building(id,label,x,y,w,d,base,top,theme,core=None,upper=None,mezz=None,small=False):
    return {'id':id,'label':label,'x':x,'y':y,'w':w,'d':d,'base':base,'top':top,'theme':theme,'core':core,'upper':upper,'mezz':mezz,'small':small,'entries':[],'rooms':[]}
buildings=[
 building('Atrium','COMMAND / ATRIUM',0,63,66,30,3,17,'Command','Atrium',mezz=8.2),
 building('Office','OFFICE / SALVAGE',-57,35,42,47,4,9,'Office','WestWing'),
 building('Biolab','BIOLAB / QUARANTINE',57,35,42,47,4,9,'Biolab','EastWing'),
 building('Armory','ARMORY / SECURITY',-69,68,28,22,.44,12,'Armory','WestAnnex',mezz=5),
 building('DataCentre','DATA / COOLING',72,69,30,22,.44,12,'Servers','EastAnnex',mezz=5),
 building('PowerShop','POWER / REPAIR',80,-39,28,35,.44,8,'Workshop','Warehouse',mezz=4.2),
 building('GateOffice','ACCESS / CONTROL',15,-76,9,7,.44,4,'Security','Security',small=True),
 building('Research','RESEARCH / REACTOR',-174,54,57,51,.26,8.6,'Research',upper=4.46),
 building('Medical','MEDICAL / TRIAGE',-174,-49,48,32,.26,4.3,'Medical'),
 building('Logistics','LOGISTICS / CARGO',174,65,58,36,.26,4.3,'Logistics'),
 building('VehicleShop','GARAGE / WORKSHOP',174,2,58,30,.26,4.3,'Workshop'),
 building('Transit','TRANSIT / DISPATCH',-4,-175,104,23,.26,4.3,'Transit'),
 building('FuelMart','SUPPLIES / FUEL MART',176,-175,40,16,.26,4.3,'Retail'),
 building('Cafe','CAFE / PANTRY',-52,155,44,26,.26,4.3,'Cafe'),
 building('FieldLab','FIELD LAB / RADIO',-161,151,49,29,.26,8.6,'FieldLab',upper=4.46),
 building('SouthSecurity','SECURITY / SOUTH',32,-195,14,10,.26,4.3,'Security',small=True),
 building('UtilityEast','UTILITY / EAST',204,-56,7,5,.26,3.5,'Utility',small=True),
 building('UtilityWest','UTILITY / WEST',-204,27,7,5,.26,3.5,'Utility',small=True),
 building('UtilityPark','UTILITY / PARK',94,174,7,5,.26,3.5,'Utility',small=True),
 building('CoffeeWest','COFFEE / KIOSK',-91,154,5,3.5,.2,3,'Kiosk',small=True),
 building('CoffeePark','COFFEE / KIOSK',18,179,5,3.5,.2,3,'Kiosk',small=True),
]
for i,(x,y) in enumerate([(-205,-180),(-205,180),(205,-180),(205,180)]):buildings.append(building('Watch'+str(i+1),'WATCH / RADIO',x,y,3.2,3.2,6.125,8.3,'Watch',small=True))

# Carve authored boxes by exact AABB subdivision, retaining all six wall caps.
# This avoids applying hundreds of heavyweight booleans to batched architecture.
def overlap(a,b):return all(a[0][k]<b[1][k]-.00001 and a[1][k]>b[0][k]+.00001 for k in range(3))
def subtract_box(a,b):
    if not overlap(a,b):return [a]
    lo,hi=a;bl=[max(lo[k],b[0][k]) for k in range(3)];bh=[min(hi[k],b[1][k]) for k in range(3)];pieces=[]
    def piece(l,h):
        if all(h[k]-l[k]>.00002 for k in range(3)):pieces.append((list(l),list(h)))
    piece(lo,[bl[0],hi[1],hi[2]]);piece([bh[0],lo[1],lo[2]],hi)
    piece([bl[0],lo[1],lo[2]],[bh[0],bl[1],hi[2]]);piece([bl[0],bh[1],lo[2]],[bh[0],hi[1],hi[2]])
    piece([bl[0],bl[1],lo[2]],[bh[0],bh[1],bl[2]]);piece([bl[0],bl[1],bh[2]],[bh[0],bh[1],hi[2]])
    return pieces
def carve_boxes(obj,cuts):
    if obj.type!='MESH' or not obj.data.vertices:return 0
    coords=[obj.matrix_world@v.co for v in obj.data.vertices];bounds=([min(v[k] for v in coords) for k in range(3)],[max(v[k] for v in coords) for k in range(3)])
    cuts=[c for c in cuts if overlap(bounds,c)]
    if not cuts:return 0
    by_vertex=[[] for v in coords]
    for pi,p in enumerate(obj.data.polygons):
        for v in p.vertices:by_vertex[v].append(pi)
    done=set();components=[]
    for seed in range(len(coords)):
        if seed in done or not by_vertex[seed]:continue
        stack=[seed];verts=set();polys=set()
        while stack:
            v=stack.pop()
            if v in verts:continue
            verts.add(v);done.add(v)
            for pi in by_vertex[v]:
                polys.add(pi)
                for vi in obj.data.polygons[pi].vertices:
                    if vi not in verts:stack.append(vi)
        components.append((verts,polys))
    newvs=[];newfs=[];newm=[];news=[];changed=0;inverse=obj.matrix_world.inverted()
    for indices,polys in components:
        pts=[coords[i] for i in indices];lo=[min(v[k] for v in pts) for k in range(3)];hi=[max(v[k] for v in pts) for k in range(3)]
        isbox=len(indices)==8 and len(polys)==6 and all(len(obj.data.polygons[i].vertices)==4 for i in polys) and all(all(min(abs(v[k]-lo[k]),abs(v[k]-hi[k]))<.002 for k in range(3)) for v in pts)
        relevant=[c for c in cuts if overlap((lo,hi),c)]
        if isbox and relevant:
            pieces=[(lo,hi)]
            for cut in relevant:pieces=[p for part in pieces for p in subtract_box(part,cut)]
            mi=obj.data.polygons[next(iter(polys))].material_index
            for l,h in pieces:
                start=len(newvs)
                for vx,vy,vz in CUBE:newvs.append(tuple(inverse@Vector(((l[0]+h[0])/2+vx*(h[0]-l[0]),(l[1]+h[1])/2+vy*(h[1]-l[1]),(l[2]+h[2])/2+vz*(h[2]-l[2])))))
                newfs.extend(tuple(start+v for v in f) for f in CF);newm.extend([mi]*6);news.extend([False]*6)
            changed+=1
        else:
            remap={}
            for vi in sorted(indices):remap[vi]=len(newvs);newvs.append(tuple(obj.data.vertices[vi].co))
            for pi in sorted(polys):p=obj.data.polygons[pi];newfs.append(tuple(remap[i] for i in p.vertices));newm.append(p.material_index);news.append(p.use_smooth)
    if not changed:return 0
    me=bpy.data.meshes.new(obj.data.name+'_V4Cuts');me.from_pydata(newvs,[],newfs)
    for m in obj.data.materials:me.materials.append(m)
    for p,mi,sm in zip(me.polygons,newm,news):p.material_index=mi;p.use_smooth=sm
    me.update();obj.data=me;return changed

# Replace generic indoor props only; garden furniture/cargo outside remains.
for o in list(bpy.data.collections['Interiors'].objects):bpy.data.objects.remove(o,do_unlink=True)
for o in list(old.objects):
    if o.get('role') in ['CoreInterior','Interior']:bpy.data.objects.remove(o,do_unlink=True)
    elif o.get('role') in ['Furniture','Cargo','Landscape','TreeDetail']:
        bm=bmesh.new();bm.from_mesh(o.data);remove=[]
        for f in bm.faces:
            p=o.matrix_world@f.calc_center_median()
            for b in buildings:
                if b['small']:continue
                if abs(p.x-b['x'])<b['w']/2-.5 and abs(p.y-b['y'])<b['d']/2-.5 and b['base']-.6<p.z<b['top']-.3:remove.append(f);break
        if remove:
            bmesh.ops.delete(bm,geom=remove,context='FACES');loose=[v for v in bm.verts if not v.link_faces]
            if loose:bmesh.ops.delete(bm,geom=loose,context='VERTS')
            if bm.faces:bm.to_mesh(o.data);o.data.update()
            else:bpy.data.objects.remove(o,do_unlink=True)
        bm.free()

portal_cuts=[];slab_cuts=[];cavity_cuts=[]
def portal(b,p,side,width=6,base=None):
    z=b['base'] if base is None else base;height=min(3.4,b['top']-z-.3)
    if side in ['front','rear']:cut=([p[0]-width/2,p[1]-1.2,z+.012],[p[0]+width/2,p[1]+1.2,z+height])
    else:cut=([p[0]-1.2,p[1]-width/2,z+.012],[p[0]+1.2,p[1]+width/2,z+height])
    portal_cuts.append(cut);b['entries'].append({'side':side,'position':[p[0],p[1],z],'width':width,'headroom':height})
for b in buildings:
    x,y,w,d,z=b['x'],b['y'],b['w'],b['d'],b['base']
    if b['theme']=='Watch':continue
    if b['theme'] in ['Utility','Kiosk']:
        cavity_cuts.append(([x-w/2+.2,y-d/2+.2,z],[x+w/2-.2,y+d/2-.2,b['top']-.25]))
        portal(b,(x,y-d/2),'front',1.8 if b['theme']=='Kiosk' else 2.2)
        portal(b,(x+w/2,y),'right',1.8)
    elif b['id']=='Atrium':
        portal(b,(x,y-d/2),'front',8)
        portal(b,(x-w/2,y+2),'left');portal(b,(x+w/2,y+2),'right')
    elif b['id'] in ['Office','Biolab']:
        portal(b,(x,y-d/2),'front')
        # Inner flank exits avoid the rear-overlapping annex volumes.
        portal(b,(x+(w/2 if x<0 else -w/2),y),'right' if x<0 else 'left')
    elif b['id'] in ['Armory','DataCentre']:
        portal(b,(x,y+d/2),'rear')
        portal(b,(x+w/2,y-7),'right',4.6)
    elif b['small']:
        portal(b,(x,y-d/2),'front',3 if w>10 else 2)
        portal(b,(x,y+d/2),'rear',3 if w>10 else 2)
    else:
        portal(b,(x,y-d/2),'front');portal(b,(x,y+d/2),'rear')
    if b['upper']:
        portal(b,(x+w/2,y-d/2+18),'right',5,base=b['upper'])
        sx=x-w/2+4.5;sy=y-d/2+6
        slab_cuts.append(([sx-2.8,sy-.2,b['upper']-.6],[sx+2.8,sy+11.3,b['upper']+.05]))
structural=list(bpy.data.collections['Architecture'].objects)+list(bpy.data.collections['Lighting'].objects)+list(bpy.data.collections['Perimeter'].objects)
structural.extend(o for o in old.objects if o.get('role') in ['ArchitectureV2','Facade','CoreFacade','FacadeDetails','Maintenance','Kiosks','CoreDetail'])
structural.extend(o for o in root.all_objects if o.name.startswith('AtriumFin') or o.name.startswith('AtriumTransom'))
seen=set();carved=0
for o in structural:
    if o.as_pointer() in seen:continue
    seen.add(o.as_pointer());carved+=carve_boxes(o,portal_cuts+slab_cuts+cavity_cuts)
# Internal campus fence receives broad links; outer mountain fence remains intact.
fencecuts=[]
for x in [-98,98]:
    for y in [-62,-39,8,70]:fencecuts.append(([x-1,y-3.5,0],[x+1,y+3.5,3.3]))
for o in list(bpy.data.collections['Perimeter'].objects):
    carved+=carve_boxes(o,fencecuts)
    if o.type=='MESH' and not o.data.polygons:bpy.data.objects.remove(o,do_unlink=True)
# Correct the old atrium steps which intersected the raised entry-deck face.
for o in list(bpy.data.collections['Stairs'].objects):
    if abs(abs(o.location.x)-22)<.1 and 37.9<o.location.y<48.1:bpy.data.objects.remove(o,do_unlink=True)
ORIGIN=(0,0,0);current_building='ExteriorAccess';current_floor='Ground'
for x in [-22,0,22]:stairs(x,33,8 if x==0 else 10,9,3)
# Seal old annex front bays instead of suggesting a drop into the adjacent wing.
for b in buildings:
    if b['id'] in ['Armory','DataCentre']:
        box('FacadeRepair',(b['x'],b['y']-b['d']/2,b['base']+1.8),(7,.28,3.6),PANEL)
        sign('ACCESS ON REAR / SIDE',(b['x']-2.6,b['y']-b['d']/2-.17,b['base']+2.7),.35)

def exterior_access(b):
    global ORIGIN,current_building,current_floor
    ORIGIN=(0,0,0);current_building=b['id']+'_Access';current_floor='Ground'
    for entry in b['entries']:
        if entry['position'][2]!=b['base']:continue
        x,y,z=entry['position'];side=entry['side'];w=entry['width']
        if b['id'] in ['Office','Biolab'] and side=='front':continue
        if b['id']=='Atrium' and side=='front':continue
        if z<.6:
            if side in ['front','rear']:box('Threshold',(x,y,z-.1),(w,2,.2),CONCRETE)
            else:box('Threshold',(x,y,z-.1),(2,w,.2),CONCRETE)
            continue
        # Side landing and broad stair facing away from the wall.
        if side in ['left','right']:
            direction=-1 if side=='left' else 1;box('Landings',(x+direction*2,y,z-.15),(4,w,.3),CONCRETE)
            run=z*2.5;n=max(10,int(z/.16))
            for j in range(n):
                xx=x+direction*(4+run-(j+.5)*run/n);h=z*(j+1)/n
                box('Stairs',(xx,y,h/2),(run/n,w,h),CONCRETE)
            for dy in [-w/2+.1,w/2-.1]:rail((x+direction*(4+run),y+dy,0),(x+direction*4,y+dy,z))
        else:
            direction=-1 if side=='front' else 1;box('Landings',(x,y+direction*2,z-.15),(w,4,.3),CONCRETE)
            if direction<0:stairs(x,y-4-z*2.5,w,z*2.5,z)
            else:stairs(x,y+4+z*2.5,w,-z*2.5,z)
for b in buildings:exterior_access(b)

def activity(b,floor_id,kind,x,y,z=0,description='',radius=2):
    global forced
    if b['id']=='Outdoor' or b.get('theme') in ['Utility','Kiosk']:
        p=world((x,y,z));deps=bpy.context.evaluated_depsgraph_get()
        hit,loc,normal,poly,obj,matrix=scene.ray_cast(deps,Vector((p[0],p[1],.9)),Vector((0,0,-1)),distance=3)
        if hit:z+=loc.z-p[2]
    id=f'Site_{len(activity_records)+1:03d}_{b["id"]}_{kind}';prev=forced;forced=id
    label_start=len(labels)
    activity_model(kind,x,y,z);floor_ring(x,y,min(radius,2.5),ORANGE if kind in ['EliteSignal','BossBeacon'] else GOLD if kind=='LootCache' else CYAN,z)
    activity_records.append({'id':id,'building':b['id'],'floor':floor_id,'type':kind,'position_m':world((x,y,z)),'interaction_radius_m':2,'event_radius_m':radius,'description':description,'implementation':'authored_site_only','activation':'server-selected subset per run','recommended_approach_m':world((x,y-2,z))})
    if b.get('theme')=='Watch':activity_records[-1]['recommended_approach_m']=world((x+1,y,z))
    if b['id']=='FuelMart' and kind=='LootCache':activity_records[-1]['recommended_approach_m']=world((x-2,y,z))
    if b['id']=='Outdoor' and kind=='ChargeRelay':activity_records[-1]['recommended_approach_m']=world((x+3,y,z))
    if b.get('theme')=='Utility':activity_records[-1]['recommended_approach_m']=world((x-2,y,z))
    if b['id']=='Outdoor' or b.get('theme') in ['Utility','Kiosk']:
        p=activity_records[-1]['recommended_approach_m']
        hit,loc,normal,poly,obj,matrix=scene.ray_cast(bpy.context.evaluated_depsgraph_get(),Vector((p[0],p[1],.9)),Vector((0,0,-1)),distance=3)
        if hit:activity_records[-1]['recommended_approach_m'][2]=loc.z
    player_label={'LootCache':'SUPPLY CACHE','ChargeRelay':'POWER RELAY','RiskTerminal':'UNSTABLE EXPERIMENT','EliteSignal':'SECURITY ALERT','RecoveryStation':'RECOVERY','Recycler':'RECYCLER','WeaponBench':'UPGRADE BENCH','SampleHunt':'SPECIMENS','PurifierDefence':'PURIFIER','BossBeacon':'ELITE BEACON','TradeStation':'SUPPLY TRADE','DataCache':'DATA CACHE'}[kind]
    label_z=z+2.8 if kind not in ['LootCache','DataCache'] else z+1.5
    rod('ActivitySign',(x-.1,y+.65,z),(x-.1,y+.65,label_z+.2),.025,STEEL,8)
    box('ActivitySign',(x,y+.65,label_z),(2,.1,.4),BLACK)
    sign(player_label,(x-.87,y+.585,label_z-.08),.17)
    if b.get('theme')=='Watch':
        pivot=Vector(world((x,y,z)));data=batches[('Independent',id)]
        data[0]=[tuple(pivot+(Vector(v)-pivot)*.55) for v in data[0]]
        for i in range(label_start,len(labels)):
            text,p,size,angle,bi,fi=labels[i];labels[i]=(text,tuple(pivot+(Vector(p)-pivot)*.55),size*.55,angle,bi,fi)
    forced=prev

def theme_island(theme,x,y,index,upper=False):
    if theme=='FieldLab' and index==1:y+=1.8
    if theme=='Office':
        if index==3:bookshelf(x,y,3);bookshelf(x,y+1.6,3);crate(x+2.8,y-1)
        else:
            for dx in [-2,2]:
                for dy in [-1.8,1.8]:desk(x+dx,y+dy)
            low_partition(x,y+3.2,8,1.25);low_partition(x-4,y,6,1.7,math.pi/2)
    elif theme in ['Biolab','Research','FieldLab','Analysis']:
        for dx in [-2.5,2.5]:
            labbench(x+dx,y+2.1,3);microscope(x+dx,y+2.1,.98)
            specimen(x+dx,y-.6,h=2.4)
        labbench(x,y-2.4,3.4);screen(x,y-2.18,1.6,1.2,.55)
        low_partition(x,y+3.2,8,1.45)
        box('Lab',(x-4.3,y,1.25),(.16,6,2.5),PANEL)
        for zz in [.6,1.6]:rod('Lab',(x-4.16,y-2.8,zz),(x-4.16,y+2.8,zz),.04,CHROME)
        if theme=='Biolab' and index==2:
            decon_arch(x,y-3.7);sign('QUARANTINE',(x-1,y-4.01,2.67),.22)
    elif theme=='Medical':
        if index==3:operating_table(x,y);labbench(x+2.1,y,1.4)
        else:
            for dx in [-1.8,1.8]:
                for dy in [-1.8,1.8]:medical_bed(x+dx,y+dy)
            box('Medical',(x,y+3.1,1.55),(6,.08,2.4),TEAL)
    elif theme=='Armory':
        if index%2:weapon_wall(x,y+1.1,4);workbench(x,y-.8,4)
        else:lockers(x,y+1,5);crate(x-1.1,y-1.2);crate(x+1.1,y-1.2)
    elif theme=='Servers':
        for dx in [-1.8,-.6,.6,1.8]:server(x+dx,y)
        for dx in [-1.8,-.6,.6,1.8]:server(x+dx,y+1.3)
        box('Servers',(x,y+.6,2.6),(5,.2,.1),STEEL)
    elif theme in ['Workshop','Utility']:
        workbench(x,y+2.2,4 if current_building=='PowerShop' else 6);engine(x-1.5,y-.7);engine(x+1.5,y-.7)
        for dx in [-1.5,0,1.5]:crate(x+dx,y-2.4,w=.8)
        if current_building=='VehicleShop' and index==1:
            # A parked display car and workshop lift use the already-authored fleet.
            vehicle_displays.append({'position':world((x,y-.2,.12)),'building':current_building})
            for dx in [-1.7,1.7]:
                box('Workshop',(x+dx,y,1.35),(.28,.4,2.7),BLUE)
                box('Workshop',(x+dx,y,.32),(1.2,.6,.08),STEEL)
        if index==3:lockers(x,y+2,3)
    elif theme=='Logistics':
        for dx in [-2.5,2.5]:oriented(lambda xx,yy:rack(xx,yy,6,2.7),x+dx,y,math.pi/2)
        crate(x,y+2.1,w=.9);crate(x,y+2.1,.9,.7)
    elif theme=='Transit':
        for yy in [-.8,.8]:bench(x,y+yy,length=5)
        for dx in [-1.7,0,1.7]:box('Luggage',(x+dx,y-1.8,.35),(.6,.35,.7),R.choice([BLUE,TAN,RED]))
        box('Cover',(x,y+1.7,.7),(5,.25,1.4),PANEL)
    elif theme=='Retail':
        retail_shelf(x,y,4.5);retail_shelf(x,y+math.copysign(1.3,y),4.5)
    elif theme in ['Cafe','Kiosk']:
        if index>1:kitchen(x,y,5);fridge(x+2.3,y+1.2)
        else:
            sofa(x,y+.8,length=3);coffee_table(x,y-.55);chair(x+1.8,y-1)
    elif theme in ['Command','Security','Control','Radio','Watch']:
        control_desk(x,y,0,3);screen(x,y+1,2.1,3,1.1)
        if index%2:lockers(x+2.2,y,2)
        else:sofa(x,y-2,length=3)
    else:crate(x,y);crate(x+1.5,y);bookshelf(x,y+1.5)

def setup_room(b,floor_id,floor,theme,w=None,d=None,cy=None,upper=False):
    global ORIGIN,current_building,current_floor
    w=b['w'] if w is None else w;d=b['d'] if d is None else d;cy=b['y'] if cy is None else cy
    ORIGIN=(b['x'],cy,floor);current_building=b['id'];current_floor=floor_id
    finish=LABFLOOR if theme in ['Biolab','Research','FieldLab','Analysis','Servers'] else HOSPITALFLOOR if theme=='Medical' else SHOPFLOOR if theme in ['Workshop','Logistics','Utility'] else CAFEFLOOR if theme in ['Cafe','Kiosk'] else OFFICEFLOOR
    box('Floor',(0,0,-.018),(w-.6,d-.6,.04),finish)
    for xx in range(int(-w/2+1),int(w/2),3):box('FloorMarkings',(xx,0,.01),(.015,d-.8,.008),GRAY)
    for yy in range(int(-d/2+1),int(d/2),3):box('FloorMarkings',(0,yy,.012),(w-.8,.015,.008),GRAY)
    room={'id':b['id']+'_'+floor_id,'floor_z':floor,'bounds':[b['x']-w/2,cy-d/2,b['x']+w/2,cy+d/2],'theme':theme,'main_route_width_m':6 if not b['small'] and d>12 else 1.8,'status':'authored_geometry_runtime_pending'}
    if b['id']=='Atrium' and floor_id=='Ground':room['transverse_route_y_m']=cy-11
    if b['id']=='FieldLab' and d>12:room['transverse_route_y_m']=cy-d/2+3
    b['rooms'].append(room);nav_records.append(room)
    if b['small']:
        # Compact wall furniture keeps the entrance-to-exit strip open.
        if theme=='Watch':
            box('Electronics',(0,-.95,.55),(2.1,.35,1.1),PANEL);screen(0,-1.04,1.1,1.3,.5)
            box('SmallProps',(-.65,-.78,1.16),(.32,.22,.15),BLACK);rod('Electronics',(-.7,-.8,1.3),(-.7,-.8,1.65),.012,CHROME,6)
        elif theme=='Utility':
            box('Utility',(0,.9,1.0),(2,.8,2),STEEL)
            for dx in [-.7,0,.7]:cylinder('Utility',(dx,.45,1.1),.1,.25,CHROME)
            for dx in [-.4,.4]:screen(dx,.44,1.55,.45,.24)
            lockers(-2.3,.6,1);crate(-2.3,-.8,w=.7)
        elif theme=='Kiosk':
            kitchen(-.5,.8,2.5);box('Kitchen',(1.7,.9,1),(1,.45,2),IVORY)
        else:
            control_desk(-w*.25,d*.2,0,2);lockers(w*.28,d*.24,2);planter(w/2-1,-d/2+1)
        ceiling_lamp(0,0,min(b['top']-floor-(.1 if theme=='Watch' else .25),2.8),1.5);area_light((0,0,min(b['top']-floor-.4,2.7)),170,size=2)
        return room
    if d<10:
        # Mezzanine workstations against the rear wall, with a broad front promenade.
        for xx in [-w*.3,w*.3]:
            if theme=='Armory':weapon_wall(xx,d/2-.6,3)
            elif theme=='Servers':control_desk(xx,d/2-1.3,0,2)
            else:desk(xx,d/2-1.2)
        ceiling_lamp(0,0,3,4);area_light((0,0,3.1),550,size=5)
        return room
    cx=w*.24;cy_offset=d*.22
    if b['id'] in ['Armory','DataCentre','PowerShop'] and not upper:
        for index,dx in enumerate([-5.2,5.2]):theme_island(theme,dx,6,index)
        room['transverse_route_y_m']=cy+(-7 if b['id']!='PowerShop' else -12)
    else:
        for index,(dx,dy) in enumerate([(-cx,-cy_offset),(cx,-cy_offset),(-cx,cy_offset),(cx,cy_offset)]):
            if index in [0,3]:
                if d>28:low_partition(dx,dy+2.7,4,1.05)
                continue  # Dedicated activity islands; keep the terminal approaches empty.
            theme_island(theme,dx,dy,index,upper)
    # Accent hardware, papers and plants stay near walls rather than filling routes.
    if theme not in ['Workshop','Logistics','Servers']:
        for dx in [-w/2+2,w/2-2]:planter(dx,d/2-2)
    for dx in [-w/2+2,w/2-2]:
        box('WallDetails',(dx,d/2-.48,1.2),(.35,.12,.55),RED)
    # Wall programs add identity and useful cover without filling the main cross.
    for dx in [-w*.28,w*.28]:
        yy=d/2-1
        if theme in ['Biolab','Research','FieldLab','Analysis']:
            labbench(dx,yy,4);screen(dx,yy+.38,1.8,1.6,.7)
            for j in [-1,1]:microscope(dx+j,yy,.98)
        elif theme=='Medical':retail_shelf(dx,yy,4);fridge(dx+2.5,yy)
        elif theme=='Logistics':rack(dx,yy,5,2.6)
        elif theme=='Armory':weapon_wall(dx,yy,4)
        elif theme=='Servers':
            for j in [-1.2,0,1.2]:server(dx+j,yy)
        elif theme=='Workshop':workbench(dx,yy,4)
        elif theme in ['Cafe','Kiosk']:kitchen(dx,yy,5)
        elif theme=='Retail':retail_shelf(dx,yy,4)
        elif theme in ['Command','Control','Radio','Security']:control_desk(dx,yy-.4,0,3)
        elif theme=='Transit':control_desk(dx,yy-.5,0,3)
        else:bookshelf(dx,yy,3)
    # Shallow side-wall bays preserve 6m circulation between wall and main islands.
    for side in [-1,1]:
        px=side*(w/2-.65)
        if theme=='Office':oriented(lambda x,y:bookshelf(x,y,2),px,d*.15,-side*math.pi/2)
        elif theme in ['Biolab','Research','FieldLab','Analysis']:oriented(lambda x,y:labbench(x,y,3),px,-d*.22,-side*math.pi/2)
        elif theme=='Medical':oriented(lambda x,y:lockers(x,y,3),px,d*.1,-side*math.pi/2)
        elif theme in ['Command','Transit']:oriented(lambda x,y:sofa(x,y,length=4),px,-d*.2 if theme=='Command' else d*.12,-side*math.pi/2)
    for side in [-1,1]:
        box('WallPanels',(side*(w/2-.35),0,.32),(.12,d-.8,.6),PANEL)
        for yy in [-d*.28,d*.28]:box('WallPanels',(side*(w/2-.29),yy,2),(.08,2.4,1.25),GRAY)
    for i in range(14):
        dx=R.choice([-1,1])*R.uniform(w*.3,w*.42);dy=R.uniform(-d*.35,d*.35)
        box('Scatter',(dx,dy,.023),(.15,.22,.008),PAPER,R.random()*math.tau)
    for dx in [-w*.25,w*.25]:
        for dy in [-d*.25,d*.25]:
            h=min(3.4,b['top']-floor-.45)
            ceiling_lamp(dx,dy,h,3);area_light((dx,dy,h-.1),650 if theme not in ['Command','Research'] else 1000,size=5)
    sign(b['label'],(-w/2+2,d/2-.55,2.7),.48)
    return room

activity_program={
 'Command':[('BossBeacon','Optional elite encounter arena',8),('WeaponBench','Choose a build route at command workshop',3)],
 'Office':[('LootCache','Office supply cache',2),('RiskTerminal','Optional threat increase for rarer loot',6)],
 'Biolab':[('PurifierDefence','Defend the decontamination purifier',7),('SampleHunt','Search for three specimen containers',3)],
 'Armory':[('WeaponBench','Weapon improvement site',3),('EliteSignal','Optional security elite beacon',6)],
 'Servers':[('ChargeRelay','Hold the server relay while it charges',6),('DataCache','Data vault reward candidate',2)],
 'Workshop':[('Recycler','Trade salvaged supplies for run rewards',3),('ChargeRelay','Restart workshop power under pressure',6)],
 'Research':[('ChargeRelay','Charge the experimental reactor',7),('RiskTerminal','Risk experiment reward candidate',5)],
 'Medical':[('RecoveryStation','Limited recovery service, future cost validation',3),('LootCache','Medical supply candidate',2)],
 'Logistics':[('LootCache','Supply cargo reward candidate',3),('EliteSignal','Optional cargo-yard elite alert',7)],
 'Transit':[('EliteSignal','Dispatch radio defence candidate',6),('LootCache','Luggage cache candidate',2)],
 'Retail':[('TradeStation','Run supplies trade candidate',3),('LootCache','Stockroom cache candidate',2)],
 'Cafe':[('RecoveryStation','Limited restorative brew candidate',3),('LootCache','Pantry cache candidate',2)],
 'FieldLab':[('SampleHunt','Field specimen search candidate',4),('PurifierDefence','Scan specimens under enemy pressure',6)],
 'Analysis':[('RiskTerminal','Optional unstable experiment',5),('DataCache','Analysis record cache candidate',2)],
 'Radio':[('ChargeRelay','Radio uplink defence candidate',5),('DataCache','Dispatch archive cache',2)]
}

for b in buildings:
    base_room=setup_room(b,'Ground',b['base'],b['theme'])
    if not b['small']:
        # Put activities on the inner edge of distinct cover islands, away from cross lanes.
        for index,(kind,description,radius) in enumerate(activity_program.get(b['theme'],[('LootCache','Supply cache candidate',2)])):
            x=(-1 if index==0 else 1)*b['w']*.24;y=(-1 if index==0 else 1)*b['d']*.22
            if b['id'] in ['Armory','DataCentre','PowerShop']:
                x=(-1 if index==0 else 1)*5.2;y=1.8 if b['id']!='PowerShop' else -6
            if b['id']=='FuelMart':y=-b['d']/2+1.8 if index==0 else b['d']/2-1.2
            activity(b,'Ground',kind,x,y+.5,description=description,radius=radius)
        for dx in [-b['w']*.35,b['w']*.35]:supply_barrel(dx,b['d']*.38 if b['id'] in ['Armory','DataCentre','PowerShop'] else -b['d']*.27)
    else:
        # Kiosks/utility sites are outside their narrow interiors; booth radios stay small.
        if b['theme'] in ['Utility','Kiosk']:
            activity(b,'Ground','RecoveryStation' if b['theme']=='Kiosk' else 'LootCache',-b['w']/2-1,-b['d']/2-1,description='Optional outdoor service site',radius=2)
        elif b['theme']=='Watch':
            activity(b,'Ground','DataCache',-.95,.1,description='Compact observation-booth cache; NPC stair test required',radius=1)
        else:activity(b,'Ground','DataCache',b['w']*.27,0,description='Security route cache',radius=1.5)
    if b['upper']:
        # Two-storey rooms retain upper external access and get real internal stairs.
        ORIGIN=(b['x'],b['y'],b['base']);current_building=b['id'];current_floor='Connections'
        sx=-b['w']/2+4.5;sy=-b['d']/2+6;stairs(sx,sy,5,11,b['upper']-b['base'])
        box('Landings',(sx,sy+12,b['upper']-b['base']-.12),(5.4,2,.24),CONCRETE)
        rail((sx-2.7,sy+11,b['upper']-b['base']),(sx-2.7,sy+13,b['upper']-b['base']))
        room=setup_room(b,'Upper',b['upper'],'Analysis' if b['id']=='Research' else 'Radio',upper=True)
        kind='RiskTerminal' if b['id']=='Research' else 'ChargeRelay'
        activity(b,'Upper',kind,b['w']*.22,b['d']*.22,description='Upper-floor optional encounter site',radius=5)
        activity(b,'Upper','DataCache',-b['w']*.16,b['d']*.22,description='Upper analysis/dispatch cache',radius=2)
    if b['mezz']:
        ORIGIN=(b['x'],b['y'],0);current_building=b['id'];current_floor='MezzStructure';z=b['mezz'];base=b['base']
        if b['id']=='Atrium':
            box('MezzFloor',(0,b['d']/2-3,z-.13),(b['w']-1,6,.26),CONCRETE)
            box('MezzFloor',(0,-b['d']/2+3,z-.13),(b['w']-1,6,.26),CONCRETE)
            for side in [-1,1]:
                box('MezzFloor',(side*(b['w']/2-3),0,z-.13),(6,b['d']-12,.26),CONCRETE)
                sx=side*24;stairs(sx,-7,5,12.5,z-base,base)
                box('Landings',(sx,7.3,z-.13),(7,3.6,.26),CONCRETE)
                rail((side*26,-9,z),(side*26,4.6,z))
            rail((-25,9,z),(25,9,z));rail((-31,-9,z),(31,-9,z))
            gallery_y=b['y']+b['d']/2-3;setup_room(b,'Gallery',z,'Control',b['w']-2,6,gallery_y,True)
            activity(b,'Gallery','DataCache',18,1.4,description='Gallery command record candidate',radius=2)
        else:
            depth=6 if b['id'] in ['Armory','DataCentre'] else 8
            localcy=b['d']/2-depth/2;start=b['d']/2-depth
            box('MezzFloor',(0,localcy,z-.13),(b['w']-1,depth,.26),CONCRETE)
            for side in [-1,1]:
                sx=side*(b['w']/2-4.2);run=(z-base)*(2 if b['id'] in ['Armory','DataCentre'] else 2.5);stairs(sx,start-run,4.5,run,z-base,base)
                rail((sx-2.35,start,z),(sx-2.35,start+1,z))
            rail((-b['w']/2+7,start,z),(b['w']/2-7,start,z))
            room_theme='Armory' if b['id']=='Armory' else 'Servers' if b['id']=='DataCentre' else 'Control'
            setup_room(b,'Mezzanine',z,room_theme,b['w']-2,depth,b['y']+localcy,True)
            activity(b,'Mezzanine','LootCache' if b['id']=='Armory' else 'DataCache',0,depth/2-1,description='Accessible mezzanine reward candidate',radius=2)

# Extra authored outdoor opportunities support exploration between buildings.
outdoor={'id':'Outdoor'};ORIGIN=(0,0,0);current_building='Outdoor';current_floor='Ground'
for kind,x,y,desc,radius in [('EliteSignal',-170,-117,'Helipad-adjacent elite alert',8),('ChargeRelay',110,34,'Substation power defence',7),('LootCache',-105,-48,'Parking salvage cache',3),('LootCache',153,-33,'Container-yard supply cache',3),('RecoveryStation',7,139,'Park recovery candidate',3),('RiskTerminal',97,168,'Lake-side risk encounter',7),('LootCache',-38,-10,'West-terrace exploration cache',3),('PurifierDefence',29,28,'Central plaza purifier candidate',8)]:activity(outdoor,'Ground',kind,x,y,description=desc,radius=radius)

# Build meshes with compact slots and explicit future roles; interactive objects stay separate.
new_mesh_objects=[]
for key,(vs,fs,indices,smoothing) in batches.items():
    name='V4_'+'_'.join(str(k) for k in key);me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update();used=sorted(set(indices));mapping={old:new for new,old in enumerate(used)}
    for mi in used:me.materials.append(materials[mi])
    for poly,mi,sm in zip(me.polygons,indices,smoothing):poly.material_index=mapping[mi];poly.use_smooth=sm
    o=bpy.data.objects.new(name,me);is_activity=key[0]=='Independent' and str(key[1]).startswith('Site_');(sites_collection if is_activity else interiors).objects.link(o)
    o['role']='activity_art_only' if is_activity else 'breakable_art_only' if key[0]=='Independent' else str(key[-1]);o['building']=str(key[0]);o['implementation']='geometry_only'
    if key[0]=='Independent':
        record=next((r for r in activity_records if r['id']==key[1]),None)
        if record:
            pivot=Vector(record['position_m'])
            for v in me.vertices:v.co-=pivot
            o.location=pivot;o['building']=record['building'];o['activity_type']=record['type'];o['site_id']=record['id'];o['handler_implemented']=False
    new_mesh_objects.append(o)
for o in new_mesh_objects:
    if o.get('role') in ['Floor','FloorMarkings']:carved+=carve_boxes(o,slab_cuts)
    elif o.get('role')=='WallPanels':carved+=carve_boxes(o,portal_cuts)
for record in activity_records:
    marker=bpy.data.objects.new('POI_'+record['id'],None);markers_collection.objects.link(marker);marker.location=record['position_m'];marker.empty_display_size=.6;marker['activity_type']=record['type'];marker['handler_implemented']=False
for text,p,size,angle,building_id,floor_id in labels:
    # Convert using explicit evaluated mesh data; no duplicate FONT copies in export.
    curve=bpy.data.curves.new('V4Sign_'+text,'FONT');curve.body=text;curve.size=size;curve.extrude=.002;curve.materials.append(materials[PAPER])
    temp=bpy.data.objects.new(curve.name,curve);interiors.objects.link(temp);temp.location=p;temp.rotation_euler=(math.pi/2,0,angle)
    deps=bpy.context.evaluated_depsgraph_get();me=bpy.data.meshes.new_from_object(temp.evaluated_get(deps))
    sign_obj=bpy.data.objects.new(temp.name+'_Mesh',me);interiors.objects.link(sign_obj);sign_obj.matrix_world=temp.matrix_world.copy()
    bpy.data.objects.remove(temp,do_unlink=True);bpy.data.curves.remove(curve);sign_obj['building']=building_id;sign_obj['role']='sign';new_mesh_objects.append(sign_obj)
for rec in light_records:
    data=bpy.data.lights.new('V4_InteriorLight','AREA');data.energy=rec['power'];data.color=rec['color'];data.size=rec['size']
    o=bpy.data.objects.new('V4Light_'+rec['building'],data);pres.objects.link(o);o.location=rec['p'];o['building']=rec['building']
for i,rec in enumerate(vehicle_displays):
    donor=next(o for o in bpy.data.collections['V3_Detailed_Vehicles'].objects if o.get('vehicle_variant')=='SportCoupe')
    me=donor.data.copy();o=bpy.data.objects.new('V4_Garage_DisplayCar_'+str(i),me);interiors.objects.link(o);o.location=rec['position'];o['building']=rec['building'];o['role']='display_vehicle';new_mesh_objects.append(o)
def camera(name,loc,target,lens=28,ortho=None):
    d=bpy.data.cameras.new(name);d.lens=lens;d.clip_end=5000;o=bpy.data.objects.new(name,d);pres.objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
    if ortho:d.type='ORTHO';d.ortho_scale=ortho
    return o
camera('CampusV4_Biolab',(51,38.5,5.8),(45,45.5,5.4),28)
camera('CampusV4_Armory',(-67,62,2.1),(-63,71,1.5),26)
camera('CampusV4_Medical',(-176,-57,1.9),(-165,-44,1.5),26)
camera('CampusV4_Logistics',(181,58,1.9),(161,73,1.4),26)
camera('CampusV4_Atrium',(0,51,4.7),(14,70,5.2),26)
camera('CampusV4_ResearchUpper',(-171,43,6.16),(-159,62,5.9),26)
camera('CampusV4_CoreCutaway',(6,20,130),(0,54,0),ortho=200)
scene['run_interiors_v4']=True;scene['design']='V4: 25 furnished buildings, distinct FPS zombie-run rooms, real door/slab openings and 6 added upper spaces; activity art/markers only, no gameplay handlers.'
scene.camera=bpy.data.objects['CampusV4_Atrium'];scene.render.resolution_x=1600;scene.render.resolution_y=1000;scene.cycles.samples=32;scene.render.filepath=os.path.join(OUT,'Campus_RunSpaces_atrium.png')
layout={'version':4,'scope':'Blender interiors and authored inactive activity sites','playable_dimensions_m':[480,440],'studs_per_metre':3.5,'buildings':buildings,'activity_sites':activity_records,'breakable_candidates':breakables,'lights':light_records,'nav_room_records':nav_records,'structural_boxes_carved':carved,'added_geometry_counts':counts,'runtime_handlers_implemented':False,'studio_runtime_verified':False,'blender_qa':{}}
with open(os.path.join(OUT,'Campus_RunSpaces_layout.json'),'w',encoding='utf-8') as f:json.dump(layout,f,ensure_ascii=False,indent=2)
with open(os.path.join(OUT,'Campus_RunSpaces_cover_bounds.json'),'w',encoding='utf-8') as f:json.dump(solid_records,f,indent=2)
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'Campus_RunSpaces.blend'))
print(json.dumps({'buildings':len(buildings),'room_floors':len(nav_records),'activity_sites':len(activity_records),'breakable_candidates':len(breakables),'structural_boxes_carved':carved,'new_mesh_objects':len(new_mesh_objects),'lights':len(light_records)}))
