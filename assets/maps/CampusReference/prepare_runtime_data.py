"""Complete Rojo-ready collision/navigation data from the authored Blender scene."""
import bpy,json,os,math,collections
from mathutils import Vector,Matrix
ROOT=os.path.dirname(__file__);OUT=os.path.join(ROOT,'roblox_import')
path=os.path.join(OUT,'Campus_RuntimeData.json');data=json.load(open(path,encoding='utf-8'))
scale=data['scale'];conversion=Matrix(((1,0,0),(0,0,1),(0,-1,0)))
def cv(p):return [round(p.x*scale,5),round(p.z*scale,5),round(-p.y*scale,5)]
windows=[o for o in bpy.data.collections['Campus_Map'].all_objects if o.type=='MESH' and ('_Window' in o.name or '_Glass' in o.name)]
for o in windows:
    if len(o.data.vertices)!=8:continue
    pts=[v.co for v in o.data.vertices];lo=Vector(tuple(min(p[i]for p in pts)for i in range(3)));hi=Vector(tuple(max(p[i]for p in pts)for i in range(3)))
    r=conversion@o.matrix_world.to_3x3().normalized()
    data['colliders'].append({'name':o.name,'p':cv(o.matrix_world@((lo+hi)/2)),'s':[(hi[i]-lo[i])*o.scale[i]*scale for i in range(3)],'r':[float(v)for row in r for v in row]})
# Cylindrical laboratory capsules: one hull per sizeable vertical cylinder.
cylinder_objects=list(bpy.data.collections['V4_Run_Interiors'].all_objects)+list(bpy.data.collections['Campus_Expansion_V2'].all_objects)+list(bpy.data.collections['Campus_Map'].all_objects)
for o in cylinder_objects:
    if o.type!='MESH' or (o.get('role') not in ['LabPods','LabGlass','Utilities'] and not o.name.startswith('FountainRim')):continue
    m=o.data;adj=[[]for _ in m.vertices]
    for e in m.edges:a,b=e.vertices;adj[a].append(b);adj[b].append(a)
    visited=set()
    for i in range(len(m.vertices)):
        if i in visited:continue
        todo=[i];visited.add(i);ids=[]
        while todo:
            j=todo.pop();ids.append(j)
            for k in adj[j]:
                if k not in visited:visited.add(k);todo.append(k)
        if len(ids)<16 or len(ids)>192:continue
        pts=[o.matrix_world@m.vertices[j].co for j in ids];lo=Vector(tuple(min(p[k]for p in pts)for k in range(3)));hi=Vector(tuple(max(p[k]for p in pts)for k in range(3)));dim=hi-lo
        if dim.z<.75 or min(dim.x,dim.y)<.8 or abs(dim.x-dim.y)>.05:continue
        if len({round(p.z,4)for p in pts})!=2:continue
        data['colliders'].append({'name':o.name,'p':cv((lo+hi)/2),'s':[dim.z*scale,dim.x*scale,dim.y*scale],'r':[0,1,0,1,0,0,0,0,-1],'shape':'Cylinder'})
scene=bpy.context.scene;deps=bpy.context.evaluated_depsgraph_get()
def support(x,y,z):
    hit,p,n,_,o,_=scene.ray_cast(deps,Vector((x,y,z+.65)),Vector((0,0,-1)),distance=1.35)
    if not hit or n.z<.65 or o.type!='MESH':return None
    if o.get('role') in ['Furniture','SmallProps','Lab','LabPods','LabGlass','Servers','Cover','Storage','Activity'] or 'Water' in o.name:return None
    if scene.ray_cast(deps,p+Vector((0,0,.1)),Vector((0,0,1)),distance=1.9)[0]:return None
    for dx,dy in [(-.6,0),(.6,0),(0,-.6),(0,.6)]:
        if scene.ray_cast(deps,p+Vector((0,0,.95)),Vector((dx,dy,0)).normalized(),distance=.65)[0]:return None
    return p
points={}
def add(x,y,z):
    p=support(x,y,z)
    if p is not None:points[tuple(round(v,2)for v in p)]=cv(p)
for x in range(-204,205,12):
    for y in range(-180,181,12):add(x,y,0)
for room in data['layout']['nav_room_records']:
    x0,y0,x1,y1=room['bounds'];z=room['floor_z'];cross=room.get('transverse_route_y_m',y0+4)
    for x in range(math.ceil(x0+3),math.floor(x1-2),6):add(x,cross,z)
    for y in range(math.ceil(y0+3),math.floor(y1-2),6):add((x0+x1)/2,y,z)
for site in data['layout']['activity_sites']:add(*site['recommended_approach_m'])
spawn=support(0,-12,0)
if spawn is None:raise RuntimeError('Campus player spawn has no clear authored floor')
data['spawn']=cv(spawn);data['spawn_zones']=list(points.values())
# Sparse direction hints; pathfinding still computes actual routes at runtime.
data['nav_nodes']=list(points.values())[::8]
with open(path,'w',encoding='utf-8')as f:json.dump(data,f,separators=(',',':'))
print('colliders',len(data['colliders']),'ground and interior spawn sites',len(points),'spawn',data['spawn'])
