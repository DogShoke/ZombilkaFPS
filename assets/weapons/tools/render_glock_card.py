import ast,bpy,os
from mathutils import Vector,Matrix
ROOT=r'C:\Roblox\ZombilkaFPS\assets\weapons'
tree=ast.parse(open(os.path.join(ROOT,'tools','prepare_weapons.py'),encoding='utf8').read())
fn=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='render_card')
exec(compile(ast.Module(body=[fn],type_ignores=[]),'render_card','exec'))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r'C:\Roblox\ZombilkaFPS\assets\FpsGlock_FullyTextured.fbx',use_anim=False)
gun=next(o for o in bpy.context.scene.objects if o.type=='MESH' and 'Glock' in o.name)
dg=bpy.context.evaluated_depsgraph_get(); mesh=bpy.data.meshes.new_from_object(gun.evaluated_get(dg),preserve_all_data_layers=True,depsgraph=dg)
rot=Matrix(((0,-1,0,0),(0,0,1,0),(-1,0,0,0),(0,0,0,1)))
mesh.transform(rot@gun.matrix_world); gun.parent=None; gun.matrix_world=Matrix.Identity(4); gun.modifiers.clear(); gun.data=mesh
render_card(gun,'Glock')
