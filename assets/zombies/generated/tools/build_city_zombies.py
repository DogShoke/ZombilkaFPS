"""Original faceted city zombies. Run in Blender; no downloaded geometry."""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(r'C:\Roblox\ZombilkaFPS\assets\zombies\generated')
ROOT.mkdir(exist_ok=True, parents=True)
(ROOT/'exports').mkdir(exist_ok=True)
scene = bpy.data.scenes.get('CityZombies') or bpy.data.scenes.new('CityZombies')
bpy.context.window.scene = scene
for obj in list(scene.objects):
    bpy.data.objects.remove(obj, do_unlink=True)
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1

COLORS = {'skin':(119,139,119),'skinDark':(85,108,93),'bone':(207,203,158),
 'blood':(111,29,42),'bloodBright':(158,40,51),'mouth':(28,24,33),'eye':(219,244,208),
 'hair':(42,44,49),'shoe':(39,43,51),'metal':(106,125,137),'white':(194,208,198),
 'yellow':(208,176,55),'orange':(201,100,47),'blue':(61,86,127),'teal':(73,147,138),
 'red':(166,58,60),'purple':(106,71,127),'green':(107,136,65),'navy':(45,61,84),
 'brown':(104,79,66),'pants':(65,73,84),'pink':(177,104,121)}
palette=[]; palette_index={}
for name,c in COLORS.items():
    for shade in range(5):
        rgb=tuple(min(255,int(v*(.76+shade*.1))) for v in c)
        palette_index[(name,shade)]=len(palette); palette.append(rgb)
image=bpy.data.images.new('CityZombies_BaseColor',width=512,height=512)
image.colorspace_settings.name='sRGB'
pixels=[0.0]*(512*512*4)
for y in range(512):
    for x in range(512):
        idx=(y//32)*16+x//32; rgb=palette[idx] if idx<len(palette) else (40,42,48)
        off=(y*512+x)*4
        pixels[off:off+4]=[v/255 for v in rgb]+[1]
image.pixels.foreach_set(pixels)
image.filepath_raw=str(ROOT/'CityZombies_BaseColor.png'); image.file_format='PNG'; image.save(); image.pack()
mat=bpy.data.materials.new('CityZombies_Palette'); mat.diffuse_color=(.5,.5,.5,1)
bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
tex=mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=image; tex.interpolation='Closest'
mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color']); bsdf.inputs['Roughness'].default_value=.92

BONES=[('bip Pelvis',None,(0,0,.90),(0,0,1.02)),
 ('bip Spine','bip Pelvis',(0,0,1.02),(0,0,1.36)),
 ('bip Neck','bip Spine',(0,0,1.36),(0,0,1.48)),
 ('bip Head','bip Neck',(0,0,1.48),(0,0,1.78))]
for side,sg in [('L',-1),('R',1)]:
    BONES += [(f'bip {side} UpperArm','bip Spine',(sg*.25,0,1.35),(sg*.59,0,1.35)),
     (f'bip {side} Forearm',f'bip {side} UpperArm',(sg*.59,0,1.35),(sg*.89,0,1.35)),
     (f'bip {side} Hand',f'bip {side} Forearm',(sg*.89,0,1.35),(sg*1.04,0,1.35)),
     (f'bip {side} Thigh','bip Pelvis',(sg*.13,0,.91),(sg*.14,-.015,.51)),
     (f'bip {side} Calf',f'bip {side} Thigh',(sg*.14,-.015,.51),(sg*.14,0,.13)),
     (f'bip {side} Foot',f'bip {side} Calf',(sg*.14,0,.13),(sg*.14,-.15,.06))]

SPECS=[('Office','Офисный работник','blue','pants',False),
 ('Medic','Медик','teal','teal',True),('Firefighter','Пожарный','navy','navy',False),
 ('Builder','Строитель','white','orange',False),('Courier','Курьер','red','navy',True),
 ('Security','Охранник','navy','navy',False),('Mechanic','Механик','blue','brown',False),
 ('Chef','Повар','white','pants',False),('Biker','Байкер','hair','pants',False),
 ('Punk','Панк','purple','pants',True)]
manifest=[]; rigs=[]
class Builder:
    def __init__(self,seed):
        self.v=[]; self.f=[]; self.colors=[]; self.weights=[]; self.r=random.Random(seed)
    def vertex(self,p,bone):
        self.v.append(tuple(p)); self.weights.append(bone); return len(self.v)-1
    def face(self,ids,color,shade=None):
        self.f.append(tuple(ids)); self.colors.append(palette_index[(color,self.r.randrange(5) if shade is None else shade)])
    def rings(self,levels,bone,color,sides=8):
        rings=[]
        for x,y,z,rx,ry in levels:
            rings.append([self.vertex((x+math.cos(2*math.pi*i/sides+math.pi/8)*rx,y+math.sin(2*math.pi*i/sides+math.pi/8)*ry,z),bone) for i in range(sides)])
        self.face(list(reversed(rings[0])),color)
        for a,b in zip(rings,rings[1:]):
            for i in range(sides):
                j=(i+1)%sides; self.face((a[i],a[j],b[j]),color); self.face((a[i],b[j],b[i]),color)
        self.face(rings[-1],color)
    def box(self,c,size,bone,color,rot=0):
        center=Vector(c); ids=[]
        for x,y,z in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]:
            p=Vector((x*size[0]/2,y*size[1]/2,z*size[2]/2)); p=Matrix.Rotation(rot,3,'Y')@p
            ids.append(self.vertex(center+p,bone))
        for face in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]: self.face([ids[i] for i in face],color,2)
    def limb(self,a,b,r1,r2,bone,color):
        a,b=Vector(a),Vector(b); direction=(b-a).normalized(); u=direction.cross(Vector((0,1,0))).normalized(); w=direction.cross(u)
        rings=[]
        for p,r in [(a,r1),(a.lerp(b,.52),(r1+r2)*.53),(b,r2)]:
            rings.append([self.vertex(p+(u*math.cos(i*math.pi/3)+w*math.sin(i*math.pi/3))*r,bone) for i in range(6)])
        self.face(list(reversed(rings[0])),color)
        for first,second in zip(rings,rings[1:]):
            for i in range(6): j=(i+1)%6; self.face((first[i],first[j],second[j],second[i]),color)
        self.face(rings[-1],color)
    def patch(self,c,size,bone,color,count=1):
        x,y,z=c; sx,sz=size
        for _ in range(count):
            px=x+self.r.uniform(-sx*.3,sx*.3); pz=z+self.r.uniform(-sz*.3,sz*.3)
            points=[(px-sx*.3,y,pz-sz*.45),(px+sx*.15,y-.001,pz-sz*.25),(px+sx*.32,y,pz+sz*.30),(px-sx*.12,y,pz+sz*.5)]
            self.face([self.vertex(p,bone) for p in points],color,2)

for index,(key,label,shirt,pants,female) in enumerate(SPECS):
    b=Builder(721+index); waist=.165 if female else .205; shoulder=.245 if female else .285
    b.rings([(0,0,.85,.225,.14),(0,0,1.0,waist,.13),(0,0,1.20,shoulder,.16),(0,0,1.37,shoulder,.135)],'bip Spine',shirt)
    b.rings([(0,0,.77,.205,.145),(0,0,.93,.235,.15)],'bip Pelvis',pants)
    b.rings([(0,0,1.35,.07,.075),(0,0,1.50,.07,.075)],'bip Neck','skinDark',6)
    # Angular jaw, cheek ridge and larger forehead rather than a sphere.
    b.rings([(0,0,1.48,.085,.09),(0,-.015,1.54,.13,.125),(0,0,1.64,.15,.14),(0,.015,1.77,.143,.125),(0,.025,1.83,.09,.085)],'bip Head','skin')
    for sg,side in [(-1,'L'),(1,'R')]:
        upper=f'bip {side} UpperArm'; lower=f'bip {side} Forearm'; hand=f'bip {side} Hand'
        b.limb((sg*.23,0,1.35),(sg*.59,0,1.35),.12,.08,upper,shirt)
        b.limb((sg*.59,0,1.35),(sg*.88,0,1.35),.078,.052,lower,shirt if key in ('Firefighter','Courier','Security') else 'skin')
        b.box((sg*.93,-.005,1.35),(.13,.075,.12),hand,'blood' if index%3!=0 else 'skinDark')
        for finger in range(4): b.limb((sg*.98,-.005,1.31+finger*.026),(sg*(1.075-(finger%2)*.015),-.018,1.30+finger*.026),.017,.010,hand,'blood')
        b.limb((sg*.93,-.025,1.39),(sg*.99,-.065,1.43),.023,.013,hand,'skin')
        b.limb((sg*.13,0,.86),(sg*.14,-.015,.51),.123,.082,f'bip {side} Thigh',pants)
        b.limb((sg*.14,-.015,.51),(sg*.14,0,.12),.083,.056,f'bip {side} Calf',pants)
        b.box((sg*.14,-.075,.06),(.15,.29,.12),f'bip {side} Foot','shoe')
        b.box((sg*.147,-.083,.54),(.11,.035,.105),f'bip {side} Thigh','blood' if sg==1 else pants)
        b.box((sg*.15,-.05,1.645),(.045,.095,.085),'bip Head','skinDark')
        # Recessed sockets and tiny pale rectangular eyes with angry brows.
        b.box((sg*.069,-.136,1.692),(.105,.027,.067),'bip Head','skinDark',sg*.10)
        b.box((sg*.069,-.152,1.688),(.069,.011,.032),'bip Head','eye')
        b.box((sg*.069,-.152,1.727),(.115,.025,.03),'bip Head','skinDark',-sg*.19)
    b.box((0,-.134,1.551),(.153,.038,.10),'bip Head','blood')
    b.box((0,-.157,1.558),(.122,.012,.064),'bip Head','mouth')
    for sg in [-1,1]:
        b.box((sg*.043,-.167,1.580),(.024,.012,.025),'bip Head','bone')
        b.box((sg*.021,-.167,1.537),(.020,.012,.02),'bip Head','bone')
    b.box((0,-.15,1.638),(.048,.048,.057),'bip Head','skinDark',.1)
    b.patch((-.085,-.135,1.606),(.065,.095),'bip Head','blood')
    b.patch((.095,-.115,1.761),(.055,.066),'bip Head','bloodBright')
    b.patch((-.12,-.151,1.14),(.12,.21),'bip Spine','blood',2)
    b.patch((.12,-.151,.86),(.09,.17),'bip Pelvis','blood')
    # Hair caps vary in silhouette; helmets replace them where appropriate.
    if key not in ('Firefighter','Builder','Chef','Security'):
        b.rings([(0,.03,1.75,.147,.125),(0,.035,1.845,.105,.10)],'bip Head','green' if key=='Punk' else 'hair')
        if female:
            b.limb((0,.14,1.77),(.035,.22,1.56),.065,.042,'bip Head','hair')
        if key=='Biker':
            b.box((0,0,1.86),(.055,.22,.10),'bip Head','red')
    if key=='Office':
        b.box((0,-.162,1.15),(.048,.018,.34),'bip Spine','red',.08)
        for sg in [-1,1]:
            b.box((sg*.09,-.164,1.365),(.105,.025,.075),'bip Spine','white',sg*.5)
            b.box((sg*.070,-.164,1.695),(.118,.01,.082),'bip Head','hair')
            b.box((sg*.070,-.173,1.696),(.094,.009,.059),'bip Head','eye')
    elif key=='Medic':
        b.box((.12,-.168,1.30),(.10,.015,.07),'bip Spine','white')
        b.box((.12,-.18,1.30),(.019,.01,.052),'bip Spine','red')
        b.box((.12,-.18,1.30),(.054,.01,.016),'bip Spine','red')
        b.rings([(0,.02,1.80,.149,.13),(0,.02,1.87,.12,.11)],'bip Head','teal')
    elif key in ('Firefighter','Builder','Security'):
        hat='red' if key=='Firefighter' else 'yellow' if key=='Builder' else 'navy'
        b.rings([(0,0,1.78,.16,.15),(0,0,1.87,.155,.135),(0,0,1.94,.06,.075)],'bip Head',hat)
        b.box((0,-.035,1.78),(.38,.38 if key=='Firefighter' else .32,.024),'bip Head',hat)
        b.box((0,-.16,1.86),(.068,.025,.083),'bip Head','metal' if key=='Firefighter' else 'yellow')
        if key=='Builder':
            for sg in [-1,1]: b.box((sg*.125,-.166,1.18),(.105,.025,.40),'bip Spine','yellow')
            for z in [1.09,1.26]: b.box((0,-.186,z),(.44,.013,.032),'bip Spine','white')
        elif key=='Firefighter':
            for z in [1.00,1.20]: b.box((0,-.166,z),(.49,.018,.040),'bip Spine','yellow')
            for sg,side in [(-1,'L'),(1,'R')]:
                b.box((sg*.45,-.10,1.35),(.070,.018,.18),f'bip {side} UpperArm','yellow')
                b.box((sg*.14,-.085,.34),(.13,.03,.06),f'bip {side} Calf','yellow')
            b.box((0,.20,1.15),(.25,.16,.35),'bip Spine','yellow')
        else:
            b.box((0,-.165,1.16),(.42,.025,.35),'bip Spine','hair')
            b.box((-.13,-.185,1.32),(.052,.016,.06),'bip Spine','yellow')
            b.box((.26,0,1.39),(.04,.23,.075),'bip R UpperArm','blue')
    elif key=='Courier':
        b.box((0,.23,1.18),(.39,.20,.43),'bip Spine','yellow')
        for sg in [-1,1]: b.box((sg*.19,-.157,1.20),(.041,.024,.39),'bip Spine','hair')
        b.box((0,-.16,1.32),(.12,.018,.08),'bip Spine','white')
    elif key=='Mechanic':
        b.box((0,-.168,1.13),(.29,.026,.27),'bip Spine','brown')
        for sg in [-1,1]: b.box((sg*.12,-.159,1.29),(.035,.025,.24),'bip Spine','brown',sg*.10)
        b.box((.22,-.07,.88),(.11,.07,.18),'bip Pelvis','metal')
    elif key=='Chef':
        b.rings([(0,0,1.80,.145,.135),(0,0,1.98,.16,.15),(0,0,2.04,.12,.11)],'bip Head','white')
        b.box((0,-.165,1.14),(.29,.025,.39),'bip Spine','white')
        b.box((0,-.155,.84),(.35,.025,.23),'bip Pelvis','white')
        b.patch((0,-.185,1.10),(.17,.24),'bip Spine','blood',3)
        for z in [1.16,1.25,1.34]: b.box((.16,-.166,z),(.019,.018,.019),'bip Spine','hair')
    elif key=='Biker':
        for sg in [-1,1]: b.box((sg*.13,-.168,1.18),(.13,.03,.36),'bip Spine','hair')
        b.box((0,-.17,1.11),(.065,.025,.26),'bip Spine','skinDark')
        b.box((0,-.17,.95),(.42,.027,.04),'bip Pelvis','metal')
        b.box((0,-.175,1.40),(.14,.025,.025),'bip Spine','metal')
    elif key=='Punk':
        for sg in [-1,1]:
            b.box((sg*.13,-.161,1.27),(.013,.02,.15),'bip Spine','white')
            b.box((sg*.151,-.055,1.62),(.028,.04,.038),'bip Head','metal')
        b.box((0,-.17,1.10),(.26,.018,.10),'bip Spine','green')
    # Irregular stains sit on the garment patches too.
    b.patch((.05,-.205,1.10),(.085,.18),'bip Spine','bloodBright',2)
    mesh=bpy.data.meshes.new('Zombie_'+key+'_Mesh'); mesh.from_pydata(b.v,[],b.f); mesh.update()
    obj=bpy.data.objects.new('Zombie_'+key,mesh); scene.collection.objects.link(obj); mesh.materials.append(mat)
    uv=mesh.uv_layers.new(name='BaseColor_UV')
    for poly,color in zip(mesh.polygons,b.colors):
        u=((color%16)+.5)/16; v=((color//16)+.5)/16
        for loop in poly.loop_indices: uv.data[loop].uv=(u,v)
    armdata=bpy.data.armatures.new('Rig_'+key); arm=bpy.data.objects.new('Rig_'+key,armdata); scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active=arm; arm.select_set(True); bpy.ops.object.mode_set(mode='EDIT')
    for name,parent,head,tail in BONES:
        bone=armdata.edit_bones.new(key+' '+name); bone.head=head; bone.tail=tail
        if parent: bone.parent=armdata.edit_bones[key+' '+parent]
    bpy.ops.object.mode_set(mode='OBJECT'); arm.select_set(False)
    groups={name:obj.vertex_groups.new(name=key+' '+name) for name,_,_,_ in BONES}
    for vi,bone in enumerate(b.weights): groups[bone].add([vi],1,'REPLACE')
    mod=obj.modifiers.new('ZombieSkin','ARMATURE'); mod.object=arm; obj.parent=arm
    mesh.calc_loop_triangles()
    # Reflect coordinates to match Roblox +Y up / -Z front, reverse triangle winding.
    scale=3.2; center=Vector((0,0,.90)); S=Matrix(((1,0,0),(0,0,1),(0,1,0)))
    verts=[tuple(round(c,6) for c in (S@(v.co-center))*scale) for v in mesh.vertices]
    faces=[]
    for tri in mesh.loop_triangles:
        color=b.colors[tri.polygon_index]
        faces.append({'v':list(reversed(list(tri.vertices))),'uv':[((color%16)+.5)/16,1-((color//16)+.5)/16]})
    bind=[]
    for bone in armdata.bones:
        M=S@bone.matrix_local.to_3x3()@S
        p=(S@(bone.head_local-center))*scale
        bind.append({'name':bone.name,'parent':bone.parent.name if bone.parent else None,'cf':[p.x,p.y,p.z]+[M[r][c] for r in range(3) for c in range(3)]})
    data={'name':obj.name,'label':label,'vertices':verts,'faces':faces,'bones':bind,'weights':[key+' '+n for n in b.weights],'height':max(v[1] for v in verts)-min(v[1] for v in verts)}
    (ROOT/'exports'/('Zombie_'+key+'.json')).write_text(json.dumps(data,separators=(',',':')),encoding='utf8')
    manifest.append({'name':obj.name,'label':label,'vertices':len(mesh.vertices),'triangles':len(faces),'bones':len(bind),'height':data['height']})
    bpy.ops.object.select_all(action='DESELECT'); arm.select_set(True); obj.select_set(True); bpy.context.view_layer.objects.active=arm
    bpy.ops.export_scene.fbx(filepath=str(ROOT/'exports'/('Zombie_'+key+'.fbx')),use_selection=True,add_leaf_bones=False,bake_anim=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
    # Pose presentation copy in the same walking/attack stance used by the game.
    for side,sg in [('L',-1),('R',1)]:
        pb=arm.pose.bones[f'{key} bip {side} UpperArm']; R=pb.bone.matrix_local.to_3x3()
        pb.matrix_basis=(R.inverted()@Matrix.Rotation(sg*math.radians(66),3,'Y')@R).to_4x4()
    arm.location=((index%5)*2.0,(index//5)*2.6,0); rigs.append(arm)
    obj['OriginalAsset']=True; obj['VariantLabel']=label

scene.world=bpy.data.worlds.new('CityZombiesWorld'); scene.world.use_nodes=True
worldbg=next(n for n in scene.world.node_tree.nodes if n.type=='BACKGROUND'); worldbg.inputs[0].default_value=(.14,.16,.20,1); worldbg.inputs[1].default_value=.5
def aim(obj,target): obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
camdata=bpy.data.cameras.new('ZombiePreviewCamera'); cam=bpy.data.objects.new('ZombiePreviewCamera',camdata); scene.collection.objects.link(cam)
cam.location=(5,-12,6); aim(cam,(4,1.3,1)); camdata.type='ORTHO'; camdata.ortho_scale=11.3; scene.camera=cam
for loc,power,size in [((1,-5,7),1700,7),((9,1,6),1500,5),((4,6,5),1800,5)]:
    ld=bpy.data.lights.new('ZombiePreviewLight','AREA'); light=bpy.data.objects.new(ld.name,ld); scene.collection.objects.link(light); light.location=loc; aim(light,(4,1,1)); ld.energy=power; ld.size=size
scene.render.resolution_x=1800; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.render.engine='CYCLES'; scene.cycles.samples=24
scene.view_settings.view_transform='Standard'
scene.render.image_settings.file_format='PNG'; scene.render.filepath=str(ROOT/'CityZombies_Preview.png')
(ROOT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
bpy.ops.object.select_all(action='DESELECT')
# Complete pack, exported in the undeformed bind pose. Preview poses stay editable.
saved_poses={arm:{pb.name:pb.matrix_basis.copy() for pb in arm.pose.bones} for arm in rigs}
for arm in rigs:
    arm.select_set(True)
    for pb in arm.pose.bones: pb.matrix_basis=Matrix.Identity(4)
    for child in arm.children: child.select_set(True)
bpy.context.view_layer.update()
bpy.context.view_layer.objects.active=rigs[0]
bpy.ops.export_scene.fbx(filepath=str(ROOT/'exports'/'CityZombies_Roblox.fbx'),use_selection=True,add_leaf_bones=False,bake_anim=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True)
for arm in rigs:
    for pb in arm.pose.bones: pb.matrix_basis=saved_poses[arm][pb.name]
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'CityZombies.blend'))
print(json.dumps(manifest,ensure_ascii=False))
