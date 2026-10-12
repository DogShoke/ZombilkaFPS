exec_globals=globals()
for x,y,w,d,z in [(-57,35,42,47,9.4),(57,35,42,47,9.4),(-69,68,28,22,12.4),(72,69,30,22,12.4)]:
    for dx in [-w/2+4,w/2-4]:
        for dy in [-d/2+5,d/2-5]: planter(x+dx,y+dy,5,3,z)
    for dx in [-9,0,9]:
        for dy in [-12,0,12]:
            if abs(dy)>d/2-4: continue
            cyl('RoofTable',(x+dx,y+dy,z+.85),.85,.15,sand,'Rooftops')
            cyl('TableLeg',(x+dx,y+dy,z+.4),.08,.8,steel,'Rooftops')
            for a in [0,math.pi/2,math.pi,3*math.pi/2]:
                xx=x+dx+math.cos(a)*1.4; yy=y+dy+math.sin(a)*1.4
                box('RoofChair',(xx,yy,z+.45),(.65,.65,.12),bark,'Rooftops')
                box('ChairSupport',(xx,yy,z+.23),(.12,.12,.46),steel,'Rooftops')
    for dx in [-w/2+1,w/2-1]:
        box('RoofRail',(x+dx,y,z+1.1),(.08,d-2,.08),steel,'Rooftops')
        for dy in range(int(-d/2+2),int(d/2),4): box('RailPost',(x+dx,y+dy,z+.55),(.08,.08,1.1),steel,'Rooftops')
for x in [-23,0,23]:
    box('AtriumSkylight',(x,64,17.65),(13,13,.4),glass,'Rooftops')
    for dx in [-6.5,0,6.5]: box('SkylightFrame',(x+dx,64,17.9),(.15,13,.15),trim,'Rooftops')
for x in [-14,14]:
    planter(x,53,7,3,17.4)
for i in range(100):
    if i<50: x=random.choice([-1,1])*random.uniform(104,117); y=random.uniform(-96,101)
    else: x=random.uniform(-99,99); y=random.uniform(93,105)
    pine(x,y,random.uniform(8,15))
for o in list(groups['Lighting'].objects):
    if o.name.startswith('LampGlow'):
        data=bpy.data.lights.new('CampusWarmLamp','POINT'); data.energy=1600; data.color=(1,.62,.3); data.shadow_soft_size=1
        obj=bpy.data.objects.new('CampusWarmLamp',data); pres.objects.link(obj); obj.location=o.location-Vector((0,0,.2))
sun.data.energy=.9
bg.inputs[0].default_value=(.09,.14,.23,1); bg.inputs[1].default_value=.35
light.data.energy=70000
for x,y,z in [(0,46,7),(-57,11,5),(57,11,5),(80,-57,4),(0,-79,4)]:
    data=bpy.data.lights.new('EntranceWarm','AREA'); data.energy=2200; data.color=(1,.62,.3); data.shape='DISK'; data.size=8
    obj=bpy.data.objects.new('EntranceWarm',data); pres.objects.link(obj); obj.location=(x,y,z); obj.rotation_euler=(Vector((x,y-8,0))-obj.location).to_track_quat('-Z','Y').to_euler()
scene.cycles.samples=32
bpy.ops.object.select_all(action='DESELECT')
for o in root.all_objects:
    if o.type=='MESH': o.select_set(True)
tris=sum(len(p.vertices)-2 for o in root.all_objects if o.type=='MESH' for p in o.data.polygons)
print('Mesh objects:',sum(o.type=='MESH' for o in root.all_objects),'Triangles:',tris)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'Campus.blend'))
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,'Campus.fbx'),use_selection=True,add_leaf_bones=False,axis_forward='-Z',axis_up='Y')
bpy.ops.render.render(write_still=True)
