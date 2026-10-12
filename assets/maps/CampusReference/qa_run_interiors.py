"""Geometry-only QA in Blender. Not a substitute for Studio player/NPC tests."""
import bpy,json,math,os
from mathutils import Vector
OUT=r'C:\Roblox\ZombilkaFPS\assets\maps\CampusReference'
layout=json.load(open(os.path.join(OUT,'Campus_RunSpaces_layout.json'),encoding='utf-8'))
scene=bpy.context.scene;deps=bpy.context.evaluated_depsgraph_get()
tests=[]
def line(name,a,b):
    a=Vector(a);b=Vector(b);direction=(b-a).normalized();hit,loc,normal,index,obj,matrix=scene.ray_cast(deps,a,direction,distance=(b-a).length-.04)
    rec={'name':name,'a':list(a),'b':list(b),'clear':not hit}
    if hit:rec.update({'hit_object':obj.name,'hit_position':list(loc)})
    tests.append(rec)
def floor(name,p,target):
    hit,loc,normal,index,obj,matrix=scene.ray_cast(deps,Vector((p[0],p[1],target+1.25)),Vector((0,0,-1)),distance=1.5)
    ok=hit and abs(loc.z-target)<.12
    tests.append({'name':name,'supported':bool(ok),'actual_z':loc.z if hit else None,'target_z':target,'hit_object':obj.name if hit else None})
for b in layout['buildings']:
    for e in b['entries']:
        x,y,z=e['position'];side=e['side']
        lateral=max(0,e['width']/2-.75)
        for offset in [-lateral,0,lateral]:
            for eye in [.18,.75,1.45]:
                a=(x+offset,y-1.05,z+eye) if side in ['front','rear'] else (x-1.05,y+offset,z+eye)
                c=(x+offset,y+1.05,z+eye) if side in ['front','rear'] else (x+1.05,y+offset,z+eye)
                line(b['id']+'_door_'+side+'_'+str(z)+'_'+str(offset)+'_'+str(eye),a,c)
    for room in b['rooms']:
        l,front,r,back=room['bounds'];z=room['floor_z'];x=(l+r)/2;y=(front+back)/2
        if b['small']:continue
        if back-front<10:continue
        transverse=room.get('transverse_route_y_m',y)
        for offset in [-2.35,0,2.35]:
            for eye in [.75,1.45]:
                line(room['id']+'_long_'+str(offset)+'_'+str(eye),(x+offset,front+3,z+eye),(x+offset,back-3,z+eye))
                line(room['id']+'_cross_'+str(offset)+'_'+str(eye),(l+3,transverse+offset,z+eye),(r-3,transverse+offset,z+eye))
        floor(room['id']+'_centre_floor',(x,y),z)
    if b['upper']:
        sx=b['x']-b['w']/2+4.5;sy=b['y']-b['d']/2+6;rise=b['upper']-b['base'];n=max(10,int(rise/.16))
        for j in range(1,n,4):
            yy=sy+11*(j+.5)/n;top=b['base']+rise*(j+1)/n
            # Upward free space at the real step centre detects forgotten floor/ceiling slabs.
            line(b['id']+'_stair_headroom_'+str(j),(sx,yy,top+.2),(sx,yy,top+1.95))
            floor(b['id']+'_stair_support_'+str(j),(sx,yy),top)
        floor(b['id']+'_upper_landing',(sx,sy+12),b['upper'])
    if b['mezz']:
        upper=b['mezz'];rise=upper-b['base'];n=max(10,int(rise/.16))
        if b['id']=='Atrium':starts=[(b['x']+side*24,b['y']-7,12.5) for side in [-1,1]]
        else:
            depth=6 if b['id'] in ['Armory','DataCentre'] else 8;end=b['y']+b['d']/2-depth;run=rise*(2 if b['id'] in ['Armory','DataCentre'] else 2.5)
            starts=[(b['x']+side*(b['w']/2-4.2),end-run,run) for side in [-1,1]]
        for si,(sx,sy,run) in enumerate(starts):
            for j in range(1,n,5):
                yy=sy+run*(j+.5)/n;top=b['base']+rise*(j+1)/n
                line(b['id']+'_mezz_stair_headroom_'+str(si)+'_'+str(j),(sx,yy,top+.2),(sx,yy,top+1.95))
                floor(b['id']+'_mezz_stair_support_'+str(si)+'_'+str(j),(sx,yy),top)
for site in layout['activity_sites']:
    x,y,z=site['recommended_approach_m']
    line(site['id']+'_approach_headroom',(x,y,z+.18),(x,y,z+1.93))
    floor(site['id']+'_approach_support',(x,y),z)
meshes=[o for o in scene.objects if o.type=='MESH'];empty=[o.name for o in meshes if not o.data.polygons];invalid=[o.name for o in meshes if any(not math.isfinite(c) for v in o.data.vertices for c in v.co)]
failures=[t for t in tests if ('clear' in t and not t['clear']) or ('supported' in t and not t['supported'])]
qa={'method':'Blender scene ray casts at multiple lateral/height samples plus stair support/headroom; visual art checks only','samples':len(tests),'failures':failures,'empty_meshes':empty,'invalid_coordinates':invalid,'studio_runtime_verified':False}
layout['blender_qa']=qa
with open(os.path.join(OUT,'Campus_RunSpaces_layout.json'),'w',encoding='utf-8') as f:json.dump(layout,f,ensure_ascii=False,indent=2)
with open(os.path.join(OUT,'Campus_RunSpaces_geometry_qa.json'),'w',encoding='utf-8') as f:json.dump({'summary':qa,'samples':tests},f,indent=2)
print(json.dumps({'samples':len(tests),'failures':len(failures),'empty_meshes':empty,'invalid_coordinates':invalid,'first_failures':failures[:18]}))
