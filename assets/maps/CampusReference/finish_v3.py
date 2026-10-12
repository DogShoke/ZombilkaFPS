"""Final exterior shader and shared seam normals; called by the V3 builder.
May also be run independently in the V3 scene; node graph is replaced deterministically.
"""
import bpy,math,ast,os
from mathutils import Vector
path=r'C:\Roblox\ZombilkaFPS\assets\maps\CampusReference'
# Reuse the exact terrain function without recreating materials or map geometry.
tree=ast.parse(open(os.path.join(path,'add_mountains_vehicles.py'),encoding='utf-8').read())
height_ns={'math':math}
selected=[n for n in tree.body if (isinstance(n,ast.FunctionDef) and n.name in ['smoothstep','road_x','height']) or (isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='peaks' for t in n.targets))]
exec(compile(ast.Module(body=selected,type_ignores=[]),'terrain_helpers','exec'),height_ns)
terrain_height=height_ns['height']
m=bpy.data.materials.get('Campus_MountainSurfaceV3')
if not m:m=bpy.data.materials.new('Campus_MountainSurfaceV3')
m.use_nodes=True;m.diffuse_color=(.2,.25,.18,1);nt=m.node_tree;nt.nodes.clear()
out=nt.nodes.new('ShaderNodeOutputMaterial');p=nt.nodes.new('ShaderNodeBsdfPrincipled');p.inputs['Roughness'].default_value=.92
nt.links.new(p.outputs['BSDF'],out.inputs['Surface'])
geo=nt.nodes.new('ShaderNodeNewGeometry');height_xyz=nt.nodes.new('ShaderNodeSeparateXYZ');nt.links.new(geo.outputs['Position'],height_xyz.inputs[0])
alt=nt.nodes.new('ShaderNodeMapRange');alt.inputs['From Min'].default_value=5;alt.inputs['From Max'].default_value=175;nt.links.new(height_xyz.outputs['Z'],alt.inputs['Value'])
colors=nt.nodes.new('ShaderNodeValToRGB');r=colors.color_ramp
r.elements[0].position=0;r.elements[0].color=(.085,.13,.055,1);r.elements[1].position=1;r.elements[1].color=(.47,.5,.5,1)
for pos,col in [(.25,(.145,.18,.095,1)),(.42,(.21,.225,.17,1)),(.66,(.29,.32,.305,1))]:r.elements.new(pos).color=col
nt.links.new(alt.outputs['Result'],colors.inputs['Fac'])
normal_xyz=nt.nodes.new('ShaderNodeSeparateXYZ');nt.links.new(geo.outputs['Normal'],normal_xyz.inputs[0])
slope=nt.nodes.new('ShaderNodeMapRange');slope.inputs['From Min'].default_value=.28;slope.inputs['From Max'].default_value=.85;nt.links.new(normal_xyz.outputs['Z'],slope.inputs['Value'])
blend=nt.nodes.new('ShaderNodeMixRGB');blend.inputs[1].default_value=(.24,.27,.265,1);nt.links.new(colors.outputs['Color'],blend.inputs[2]);nt.links.new(slope.outputs['Result'],blend.inputs[0])
noise=nt.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=.3;noise.inputs['Detail'].default_value=5;noise.inputs['Roughness'].default_value=.7;nt.links.new(geo.outputs['Position'],noise.inputs['Vector'])
nr=nt.nodes.new('ShaderNodeValToRGB');nr.color_ramp.elements[0].color=(.56,.59,.55,1);nr.color_ramp.elements[1].color=(1,1,1,1);nt.links.new(noise.outputs['Fac'],nr.inputs['Fac'])
mix=nt.nodes.new('ShaderNodeMixRGB');mix.blend_type=next(i.identifier for i in mix.bl_rna.properties['blend_type'].enum_items if i.identifier=='MULTIPLY');mix.inputs[0].default_value=.55
nt.links.new(blend.outputs['Color'],mix.inputs[1]);nt.links.new(nr.outputs['Color'],mix.inputs[2]);nt.links.new(mix.outputs['Color'],p.inputs['Base Color'])
bump=nt.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.25;bump.inputs['Distance'].default_value=.18;nt.links.new(noise.outputs['Fac'],bump.inputs['Height']);nt.links.new(bump.outputs['Normal'],p.inputs['Normal'])
tiles=0
for o in bpy.data.collections['V3_Mountains_Exterior'].objects:
    if not o.name.startswith('MountainTerrain'):continue
    me=o.data;me.materials.clear();me.materials.append(m)
    for poly in me.polygons:poly.material_index=0;poly.use_smooth=True
    normals=[]
    for v in me.vertices:
        x,y,z=v.co;dx=(terrain_height(x+.25,y)-terrain_height(x-.25,y))/.5;dy=(terrain_height(x,y+.25)-terrain_height(x,y-.25))/.5
        normals.append(tuple(Vector((-dx,-dy,1)).normalized()))
    me.normals_split_custom_set_from_vertices(normals);me.update();tiles+=1
for o in bpy.data.collections['Presentation'].objects:
    if o.type=='CAMERA':o.data.clip_end=5000
print('Continuous terrain surface and matching normals:',tiles,'tiles; camera clipping fixed')
