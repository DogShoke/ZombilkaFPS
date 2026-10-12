"""Detail pass called by expand_campus.py before mesh batching."""
# New roofs: useful furniture, planted beds, pergolas, PV panels, skylights,
# cable trays, air handling, vents, coping, drainage and roof-panel seams.
roofs=[(-174,54,57,51,8.6,'garden'),(-174,-49,48,32,4.3,'medical'),(174,65,58,36,4.3,'industrial'),(174,2,58,30,4.3,'industrial'),(-4,-175,104,23,4.3,'industrial'),(176,-175,40,16,4.3,'solar'),(-52,155,44,26,4.3,'garden'),(-161,151,49,29,8.6,'garden')]
for x,y,w,d,h,style in roofs:
    for xx in range(int(-w/2+1),int(w/2),4): box('RoofSeams',(x+xx,y,h+.168),(.02,d-.5,.015),DARK)
    for yy in range(int(-d/2+1),int(d/2),4): box('RoofSeams',(x,y+yy,h+.17),(w-.5,.02,.015),DARK)
    for dx in [-w/2+1,w/2-1]:
        for dy in [-d/2+1,d/2-1]:
            cylinder('RoofEquipment',(x+dx,y+dy,h+.4),.25,.45,METAL)
            box('RoofEquipment',(x+dx,y+dy,h+.66),(.7,.7,.12),PANEL)
    box('RoofEquipment',(x,y+d/2-2,h+.22),(w-5,.3,.15),METAL)
    for xx in range(int(-w/2+3),int(w/2-2),1): box('RoofEquipment',(x+xx,y+d/2-2,h+.3),(.05,.5,.04),CHROME)
    pipe((x-w/2+2,y+d/2-3,h+.35),(x+w/2-2,y+d/2-3,h+.35),.08)
    for xx in [-w/2+3,w/2-3]:
        pipe((x+xx,y+d/2-3,h+.35),(x+xx,y-1,h+.35),.08)
    if style=='garden':
        # Deck with slatted pergola and cafe furnishings, access route clear.
        box('RoofGarden',(x,y-d*.2,h+.26),(w*.5,d*.35,.16),WOOD)
        for xx in range(int(-w*.25),int(w*.25),1): box('RoofGarden',(x+xx,y-d*.2,h+.35),(.025,d*.35,.025),DARK)
        for xx in [-w*.23,w*.23]:
            for yy in [-d*.36,-d*.04]: box('RoofGarden',(x+xx,y+yy,h+1.75),(.15,.15,3),WOOD)
        for xx in range(int(-w*.24),int(w*.24)+1,2): box('RoofGarden',(x+xx,y-d*.2,h+3.3),(.12,d*.35,.18),WOOD)
        for dx in [-w*.22,0,w*.22]:
            table(x+dx,y-d*.18,h+.34)
            planter(x+dx,y+d*.24,5,3,h+.18)
        for dx in [-w*.38,w*.38]:
            hedge(x+dx,y,3,d*.45,h+.2)
            box('RoofGarden',(x+dx,y-d*.32,h+.62),(3.5,.8,.8),BLUE)
        box('RoofEquipment',(x+w*.25,y+d*.2,h+.55),(7,5,.4),GLASS)
        for dx in [-3.5,0,3.5]: box('RoofEquipment',(x+w*.25+dx,y+d*.2,h+.8),(.1,5,.1),STONE)
    else:
        for dx in [-w*.26,0,w*.26]:
            for dy in [-d*.23,d*.18]:
                box('RoofSolar',(x+dx,y+dy,h+.45),(8,3.8,.18),SOLAR)
                for j in range(11): box('RoofSolar',(x+dx-3.9+j*.78,y+dy,h+.55),(.025,3.8,.025),CHROME)
                for yy in [-1.9,0,1.9]: box('RoofSolar',(x+dx,y+dy+yy,h+.57),(8,.03,.025),CHROME)
        for dx in [-w*.2,w*.2]: hvac(x+dx,y,h+.2,4.5)
        for dx in [-w*.35,w*.35]:
            box('RoofEquipment',(x+dx,y,h+.62),(3.8,2.5,.8),GLASS)
            for yy in [-1.25,0,1.25]: box('RoofEquipment',(x+dx,y+yy,h+1.06),(3.8,.07,.1),STONE)
    for yy in [-d/2,d/2]:
        box('RoofCoping',(x,y+yy,h+1.42),(w+.3,.4,.1),IVORY)
    for dx in [-w/2,w/2]:
        if dx>0: box('RoofCoping',(x+dx,y,h+1.42),(.4,d,.1),IVORY)
        else: box('RoofCoping',(x+dx,y+2.5,h+1.42),(.4,d-5,.1),IVORY)

# Give original faceted broadleaf trees smaller overlapping foliage masses.
for o in list(root.all_objects):
    if o.name.startswith('TreeCanopy'):
        pos=o.location.copy()
        # Retain geometry in the original file; remove this coarse crown only from v2.
        bpy.data.objects.remove(o,do_unlink=True)
        for j in range(11):
            a=random.random()*math.tau; rr=random.uniform(.1,1.4); zz=random.uniform(-.9,.8)
            sphere('TreeDetail',(pos.x+math.cos(a)*rr,pos.y+math.sin(a)*rr,pos.z+zz),random.uniform(.65,1.15),LEAF2 if j%3 else MOSS,10,6,(1,1,.82))
# Enrich new trees with irregular outer foliage clusters; avoid opaque spheres.
for x,y,z in [(-190,-7,.9),(-158,12,.9),(-178,183,.9),(-86,153,0),(5,173,0),(91,159,0),(-110,181,0),(116,180,0),(-69,134,.9),(-161,158,9.6)]:
    for j in range(16):
        a=random.random()*math.tau; rr=random.uniform(1.2,3.1)
        sphere('TreeDetail',(x+math.cos(a)*rr,y+math.sin(a)*rr,z+random.uniform(4.5,7.6)),.7,LEAF2,9,5)

# Dense but localized landscaping: paved links rather than an empty lawn.
for x,y,w,d in [(-174,-89,58,9),(-171,100,65,7),(-161,178,60,7),(169,106,62,6),(173,-91,65,6),(-52,180,70,6),(88,-179,37,8)]:
    box('WalkLinks',(x,y,.16),(w,d,.3),WALK)
    for xx in range(int(-w/2),int(w/2),3): box('GroundDetail',(x+xx,y,.318),(.018,d,.015),DARK)
    for dx in [-w*.32,w*.32]: planter(x+dx,y,5,3); bench(x+dx,y-d/2+1); lamp(x+dx,y+d/2-1)
for x,y in [(-193,92),(-152,90),(-203,-82),(-144,-83),(-118,175),(-104,135),(108,130),(191,177),(203,-91),(142,-90),(-90,-181),(82,-180)]:
    hedge(x,y,8,3); tree(x,y+3)

# Glass bus shelters with route panels, slatted seating and transparent sides.
for x,y in [(-78,-118),(57,-118),(-135,18),(135,88)]:
    box('Shelters',(x,y,2.9),(7,2.3,.16),PANEL)
    for dx in [-3.2,3.2]:
        box('Shelters',(x+dx,y,1.45),(.09,.09,2.9),METAL)
        box('Shelters',(x+dx,y+.2,1.45),(.06,1.7,2.3),GLASS)
    box('Shelters',(x,y+1,1.45),(6.4,.06,2.3),GLASS)
    bench(x,y+.35)
    box('Shelters',(x-2.7,y+.9,1.6),(.8,.12,1.4),IVORY)
    text('CAMPUS SHUTTLE',(x-2.3,y-1.18,2.65),.38)
    lights.append(((x,y,2.6),350))

# Small power/substation compound, transformer fins, warning stripes and ducts.
box('Substation',(109,38,.1),(18,26,.3),CON)
for y in [31,42]:
    box('Substation',(108,y,1.5),(5,3,2.6),PANEL)
    for dx in [-2.6,2.6]:
        for j in range(13): box('Substation',(108+dx,y-1.4+j*.23,1.6),(.5,.07,2.3),METAL)
    for xx in [-1.5,0,1.5]:
        cylinder('Substation',(108+xx,y,3.4),.14,.7,IVORY,12)
        for zz in [3.2,3.35,3.5,3.65]: cylinder('Substation',(108+xx,y,zz),.25,.055,IVORY,12)
    box('Substation',(108,y-1.54,1.7),(.8,.03,.5),YELLOW)
for x in [100,117]:
    for y in range(26,52,3): cylinder('Substation',(x,y,1.35),.055,2.7,METAL)
    for z in [.3,1.2,2.5]: rod('Substation',(x,26,z),(x,51,z),.03,METAL)
for y in [26,51]: rod('Substation',(100,y,2.5),(117,y,2.5),.03,METAL)
text('HIGH VOLTAGE',(102,25.9,1.6),.4)

# Additional service structures make the new yards feel occupied.
for x,y in [(204,-56),(-204,27),(94,174)]:
    box('Maintenance',(x,y,1.75),(7,5,3.5),PANEL)
    box('Maintenance',(x,y,3.6),(7.5,5.5,.2),METAL)
    box('Maintenance',(x,y-2.54,1.35),(1.1,.08,2.7),BLUE)
    for dx in [-2,2]: box('Maintenance',(x+dx,y-2.54,2),(.9,.08,.6),GLASS)
    hvac(x,y,3.7,2)
    rubbish(x+4,y-1)
    cargo(x+4,y+1)
    for i in range(3): pallet(x+4,y+1,.3+i*.28)

# Canteen umbrellas and stalls, with chairs and tableware.
for x,y,z in [(-66,132,0),(-42,137,0),(-182,3,0),(-162,3,0),(-65,24,9.4),(65,24,9.4)]:
    rod('Umbrellas',(x,y,z+.1),(x,y,z+2.8),.04,METAL)
    rod('Umbrellas',(x,y,z+2.45),(x,y,z+3.05),1.8,SAND,12,.05)
    for i in range(8):
        a=i*math.tau/8; beam('Umbrellas',(x,y,z+3.04),(x+math.cos(a)*1.7,y+math.sin(a)*1.7,z+2.46),.025,.025,METAL)
    cylinder('Furniture',(x+.3,y,z+.94),.09,.08,WHITE)
for x,y in [(-91,154),(18,179)]:
    box('Kiosks',(x,y,1.5),(5,3.5,3),WOOD)
    box('Kiosks',(x,y-1.8,1.7),(3.8,.1,1.4),GLASS)
    box('Kiosks',(x,y-2.3,2.9),(5.4,1.2,.12),RED)
    box('Kiosks',(x,y-2.05,1.05),(4,.7,.15),IVORY)
    box('Kiosks',(x,y,3.1),(5.5,4,.18),METAL)
    text('COFFEE / TO GO',(x-2,y-2.95,2.88),.36)
    rubbish(x+3,y-2)

# Fire exits, wall lights, emergency panels, cameras and directional signs.
for x,y,h,w,d in [(0,63,17,66,30),(-57,35,9,42,47),(57,35,9,42,47),(-174,54,8.6,57,51),(174,65,4.3,58,36),(174,2,4.3,58,30),(-4,-175,4.3,104,23)]:
    for dx in [-w*.4,w*.4]:
        box('FacadeDetails',(x+dx,y-d/2-.2,2.8),(.4,.15,.12),METAL)
        box('FacadeDetails',(x+dx,y-d/2-.28,2.74),(.3,.05,.03),WARM)
        rod('FacadeDetails',(x+dx,y-d/2-.3,h-.8),(x+dx-.4,y-d/2-.7,h-1),.035,METAL)
        box('FacadeDetails',(x+dx-.45,y-d/2-.8,h-1),(.25,.42,.2),IVORY)
        box('FacadeDetails',(x+dx-.45,y-d/2-1.015,h-1),(.12,.015,.09),DARK)
    box('FacadeDetails',(x+w*.35,y-d/2-.25,1.1),(.5,.2,.9),RED)
    text('FIRE', (x+w*.35-.18,y-d/2-.37,1.3),.12)
    for xx in range(int(-w/2+3),int(w/2-2),5):
        box('FacadeDetails',(x+xx,y-d/2-.2,.43),(3,.05,.16),DARK)
        for j in range(12): box('FacadeDetails',(x+xx-1.4+j*.25,y-d/2-.235,.43),(.025,.02,.14),CHROME)
for x,y,body in [(-135,-97,'RESEARCH  <'),(135,-97,'LOGISTICS  >'),(-11,-121,'TERMINAL  v'),(-11,121,'PARK  ^'),(-90,-79,'VISITOR PARKING')]:
    for dx in [-1,1]: cylinder('Wayfinding',(x+dx,y,1.35),.06,2.7,METAL)
    box('Wayfinding',(x,y,2.55),(3.5,.16,.8),BLUE)
    text(body,(x-1.55,y-.1,2.4),.28)

# Main staircase railing and pedestrian links under the sky bridges.
for x in [-57,57]:
    for dx in [-5.8,5.8]: handrail((x+dx,-13,0),(x+dx,-3,4))
for x in [-22,22]:
    for dx in [-4.8,4.8]: handrail((x+dx,38,0),(x+dx,48,3))
for x in [-37,37]:
    for xx in [-4.5,4.5]: cylinder('BridgeSupports',(x+xx,40,3.4),.27,6.8,CON,12)
    for yy in [-2.2,2.2]: handrail((x-5.8,40+yy,7.3),(x+5.8,40+yy,7.3))

# Small weeds and tufts in landscaped areas; these remain decoration only.
for i in range(280):
    x=random.choice([-1,1])*random.uniform(207,217); y=random.uniform(-184,187)
    for j in range(4):
        a=random.random()*math.tau
        beam('GroundPlants',(x,y,.1),(x+math.cos(a)*.15,y+math.sin(a)*.15,random.uniform(.25,.6)),.025,.008,MOSS)

# Beveled original hard surfaces pick up light without turning walls into smooth blobs.
for cat in ['Architecture','Plaza','Vehicles','Service','Rooftops']:
    for o in list(bpy.data.collections[cat].objects):
        if o.type!='MESH' or o.name.startswith(('Pine','Tree')): continue
        if not o.modifiers:
            mod=o.modifiers.new('V2EdgeHighlights','BEVEL'); mod.width=.035; mod.segments=2; mod.limit_method='ANGLE'
            mod=o.modifiers.new('V2WeightedNormals','WEIGHTED_NORMAL'); mod.keep_sharp=True
