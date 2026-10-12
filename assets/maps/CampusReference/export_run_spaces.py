"""Export V4 full map and a separate authored-interior kit. No publishing."""
import bpy,os,json,io,contextlib
OUT=r'C:\Roblox\ZombilkaFPS\assets\maps\CampusReference'
names=['Campus_Map','Campus_Expansion_V2','V3_Mountains_Exterior','V3_Detailed_Vehicles','V4_Run_Interiors','V4_Activity_Sites']
objects=[o for name in names for o in bpy.data.collections[name].all_objects if o.type=='MESH']
kit=[o for name in ['V4_Run_Interiors','V4_Activity_Sites'] for o in bpy.data.collections[name].all_objects if o.type=='MESH']
copies=[];logs=io.StringIO()
try:
    for o in bpy.data.collections['V3_Mountains_Exterior'].objects:
        if o.name.startswith('AlpinePine_'):
            old=o.data;unique=old.copy();o.data=unique;copies.append((o,old,unique))
    with contextlib.redirect_stdout(logs):
        for filename,selected in [('Campus_RunSpaces.fbx',objects),('Campus_RunSpaces_Interiors.fbx',kit)]:
            with bpy.context.temp_override(selected_objects=selected,selected_editable_objects=selected,active_object=selected[0]):
                bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,filename),use_selection=True,add_leaf_bones=False,axis_forward='-Z',axis_up='Y',use_mesh_modifiers=True)
finally:
    for o,old,unique in copies:o.data=old;bpy.data.meshes.remove(unique)
warnings=[s for s in logs.getvalue().splitlines() if 'WARNING' in s or 'ERROR' in s]
deps=bpy.context.evaluated_depsgraph_get()
report={'full_map_meshes':len(objects),'interior_and_activity_meshes':len(kit),'base_triangles':sum(len(p.vertices)-2 for o in objects for p in o.data.polygons),'evaluated_triangles':sum(len(p.vertices)-2 for o in objects for p in o.evaluated_get(deps).data.polygons),'export_warnings':warnings,'runtime_verified':False}
with open(os.path.join(OUT,'Campus_RunSpaces_export.json'),'w',encoding='utf-8') as f:json.dump(report,f,indent=2)
print(json.dumps(report))
