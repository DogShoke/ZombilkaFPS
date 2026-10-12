"""Export spatially grouped original art and exact box collision components.
Runs in Blender. Does not modify the authored scene or publish assets.
"""
import bpy,os,json,math,collections
from mathutils import Vector,Matrix
ROOT=os.path.dirname(__file__)
OUT=os.path.join(ROOT,'roblox_import');os.makedirs(OUT,exist_ok=True)
SCALE=3.5
NAMES=['Campus_Map','Campus_Expansion_V2','V3_Mountains_Exterior','V3_Detailed_Vehicles','V4_Run_Interiors','V4_Activity_Sites']
objects=[o for n in NAMES for o in bpy.data.collections[n].all_objects if o.type=='MESH']
materials=list(dict.fromkeys(m for o in objects for m in o.data.materials if m))
def colour(m):
    if m and m.use_nodes:
        p=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
        if p and not p.inputs['Base Color'].is_linked:return tuple(p.inputs['Base Color'].default_value)
    return tuple(m.diffuse_color) if m else (.5,.5,.5,1)
palette=[colour(m) for m in materials]+[(.5,.5,.5,1)]
palette_index={m:i for i,m in enumerate(materials)}
width=512;height=4
pixels=[]
for y in range(height):
    for x in range(width):pixels.extend(palette[min(len(palette)-1,x//2)])
image=bpy.data.images.new('CampusImportPalette',width=width,height=height)
image.pixels=pixels;image.filepath_raw=os.path.join(OUT,'Campus_Palette.png');image.file_format='PNG';image.save()
mat=bpy.data.materials.new('CampusImportPalette');mat.use_nodes=True
bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Closest'
mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
temp=bpy.data.scenes.new('CampusImportExportOnly');groups={};counts=collections.Counter()
def group(key):
    if key not in groups:groups[key]=[[],[],[],[]]
    return groups[key]
for o in objects:
    m=o.data;m.calc_loop_triangles();world=o.matrix_world
    ids={}
    activity=o.name in bpy.data.collections['V4_Activity_Sites'].all_objects
    for t in m.loop_triangles:
        material=m.materials[t.material_index] if t.material_index<len(m.materials) else None
        name=material.name.lower() if material else ''
        kind='Glass' if any(s in name for s in ['glass','glazing','water']) else ('Glow' if any(s in name for s in ['emiss','screen','glow','lamp','led']) else 'Solid')
        centre=sum((world@m.vertices[i].co for i in t.vertices),Vector())/3
        region=o.name if activity else f'{math.floor(centre.x/96)}_{math.floor(centre.y/96)}'
        base=(region,kind);chunk=counts[base]//12000;counts[base]+=1;key=(region,kind,chunk)
        g=group(key);tri=[]
        for i in t.vertices:
            cache=(key,i)
            if cache not in ids:ids[cache]=len(g[0]);g[0].append(world@m.vertices[i].co)
            tri.append(ids[cache])
        g[1].append(tri);g[2].append(palette_index.get(material,len(palette)-1));g[3].append(m.polygons[t.polygon_index].use_smooth)
    ids.clear()
exported=[]
for index,(key,(verts,faces,colours,smooth)) in enumerate(sorted(groups.items())):
    name=f'Campus_{key[1]}_{index:04d}'
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.materials.append(mat);mesh.update()
    uv=mesh.uv_layers.new(name='PaletteUV')
    for p,c,s in zip(mesh.polygons,colours,smooth):
        p.use_smooth=s
        for i in p.loop_indices:uv.data[i].uv=((c*2+1)/width,.5)
    ob=bpy.data.objects.new(name,mesh);temp.collection.objects.link(ob);exported.append(ob)
anchor_mesh=bpy.data.meshes.new('Campus_ImportOrigin');anchor_mesh.from_pydata([(-.5,-.5,-.5),(.5,-.5,-.5),(.5,.5,-.5),(-.5,.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(.5,.5,.5),(-.5,.5,.5)],[],[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)])
anchor=bpy.data.objects.new('Campus_ImportOrigin',anchor_mesh);temp.collection.objects.link(anchor);exported.append(anchor)
with bpy.context.temp_override(scene=temp,view_layer=temp.view_layers[0],selected_objects=exported,selected_editable_objects=exported,active_object=exported[0]):
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,'Campus_Roblox_Import.fbx'),use_selection=True,add_leaf_bones=False,axis_forward='-Z',axis_up='Y',use_mesh_modifiers=False,path_mode='COPY',embed_textures=True)
def convert(p):return [round(p.x*SCALE,5),round(p.z*SCALE,5),round(-p.y*SCALE,5)]
convert_rotation=Matrix(((1,0,0),(0,0,1),(0,-1,0)))
colliders=[]
core_skip=['Stripe','Mark','Light','Lamp','Tree','Plant','Grass','Bush','Rock','Vehicle','Car','Fountain','Chair','Bench','Sign','Window','Glass','HVAC','Aircon','Solar','Umbrella','Rail','FenceWire']
exp_roles={'ArchitectureV2','GroundV2','Stairs','WalkLinks','CorePaving','LoadingDocks','Watchtower','Maintenance','Shelters','Kiosks','Transit','Logistics','Security','FuelStation','Industry','PerimeterV2','CoreFacade','Facade','ParkBoardwalk','BridgeSupports','Sports','Substation','Cargo','VehiclesV2','Forklifts','Utilities'}
v4_roles={'Floor','Stairs','Landings','MezzFloor','Threshold','FacadeRepair','Cover','Storage','WallPanels','Workshop','Lab','Medical','CargoRacks','Servers','Retail','Kitchen','Utility','Armory'}
for o in objects:
    core=any(c.name=='Campus_Map' or c.name in ['Ground','Buildings','Architecture'] for c in o.users_collection)
    in_core=o.name in bpy.data.collections['Campus_Map'].all_objects
    role=o.get('role')
    take=(in_core and not any(s.lower() in o.name.lower() for s in core_skip)) or (o.name in bpy.data.collections['Campus_Expansion_V2'].all_objects and role in exp_roles) or (o.name in bpy.data.collections['V4_Run_Interiors'].all_objects and role in v4_roles)
    if not take:continue
    m=o.data;adj=[[] for _ in m.vertices]
    for e in m.edges:a,b=e.vertices;adj[a].append(b);adj[b].append(a)
    visited=set()
    for start in range(len(m.vertices)):
        if start in visited:continue
        stack=[start];component=[];visited.add(start)
        while stack:
            i=stack.pop();component.append(i)
            for j in adj[i]:
                if j not in visited:visited.add(j);stack.append(j)
        if len(component)!=8 or len(adj[start])!=3:continue
        points=[o.matrix_world@m.vertices[i].co for i in component]
        p=o.matrix_world@m.vertices[start].co
        edges=[o.matrix_world@m.vertices[j].co-p for j in adj[start]]
        if min(v.length for v in edges)<.035:continue
        axes=[v.normalized() for v in edges]
        if any(abs(axes[i].dot(axes[j]))>.0001 for i,j in [(0,1),(0,2),(1,2)]):continue
        dimensions=[v.length*SCALE for v in edges]
        if max(dimensions)<1 or math.prod(dimensions)<.18:continue
        centre=sum(points,Vector())/8
        if abs(centre.x)>221 or abs(centre.y)>200:continue
        rotation=convert_rotation@Matrix(axes).transposed()
        if rotation.determinant()<0:rotation.col[2]=-rotation.col[2]
        colliders.append({'name':o.name,'p':convert(centre),'s':[round(v,5) for v in dimensions],'r':[round(v,7) for row in rotation for v in row]})
# Passenger vehicles use one simple box each; detail remains visual.
for o in bpy.data.collections['V3_Detailed_Vehicles'].all_objects:
    if not o.name.startswith('V3Car_'):continue
    pts=[Vector(v) for v in o.bound_box];lo=Vector(tuple(min(v[i] for v in pts) for i in range(3)));hi=Vector(tuple(max(v[i] for v in pts) for i in range(3)))
    centre=o.matrix_world@((lo+hi)/2);r=convert_rotation@o.matrix_world.to_3x3().normalized()
    colliders.append({'name':o.name,'p':convert(centre),'s':[(hi[i]-lo[i])*o.scale[i]*SCALE for i in range(3)],'r':[float(v) for row in r for v in row]})
layout=json.load(open(os.path.join(ROOT,'Campus_RunSpaces_layout.json'),encoding='utf-8'))
data={'scale':SCALE,'axis':'Blender(x,y,z) -> Roblox(x,z,-y)','colliders':colliders,'layout':layout,'mesh_count':len(exported),'triangles':sum(len(g[1]) for g in groups.values()),'activation':'pending Studio importer / asset IDs'}
with open(os.path.join(OUT,'Campus_RuntimeData.json'),'w',encoding='utf-8')as f:json.dump(data,f,separators=(',',':'))
for o in exported:
    m=o.data;bpy.data.objects.remove(o,do_unlink=True);bpy.data.meshes.remove(m)
bpy.data.scenes.remove(temp);bpy.data.materials.remove(mat);bpy.data.images.remove(image)
print(json.dumps({k:v for k,v in data.items() if k not in ['colliders','layout']}));print('exact box colliders',len(colliders))
