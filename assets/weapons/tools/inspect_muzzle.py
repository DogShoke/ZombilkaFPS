import bpy, os, json
ROOT=r'C:\Roblox\ZombilkaFPS\assets\weapons'
out={}
for key,name in [('AKM','AKM_model'),('Mossberg','Mossberg590A1')]:
    bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT,key+'_Prepared.blend'))
    obj=bpy.data.objects[name]
    points=[obj.matrix_world@v.co for v in obj.data.vertices]
    z=min(p.z for p in points)
    section=[p for p in points if p.z<z+0.025]
    ys=sorted(p.y for p in section)
    out[key]={'frontZ':z,'frontX':[min(p.x for p in section),max(p.x for p in section)],'frontY':[min(ys),max(ys)],'count':len(ys),'yQuantiles':[ys[int((len(ys)-1)*q)] for q in [0,.1,.25,.5,.75,.9,1]],'avgY':sum(ys)/len(ys)}
    bins=[]
    for i in range(20):
        za=z+i*.2
        ps=[p for p in points if za<=p.z<za+.2 and abs(p.x)<.08]
        if ps: bins.append([round(za,3),round(max(p.y for p in ps),3)])
    out[key]['centerTopByZ']=bins
with open(os.path.join(ROOT,'MuzzleGeometry.json'),'w') as f: json.dump(out,f,indent=2)
print(json.dumps(out),flush=True)
