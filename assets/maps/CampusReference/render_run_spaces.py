"""Render FPS and an explicitly labeled art cutaway, restoring hidden geometry.
Run one selected camera per MCP call so render work does not block conversation.
"""
import bpy,os
OUT=r'C:\Roblox\ZombilkaFPS\assets\maps\CampusReference'
def render_view(camera,filename,samples=28):
    s=bpy.context.scene;s.camera=bpy.data.objects[camera];s.render.resolution_x=1600;s.render.resolution_y=1000;s.cycles.samples=samples;s.render.filepath=os.path.join(OUT,filename)
    bpy.ops.render.render(write_still=True)
def render_core_cutaway():
    hidden=[]
    try:
        # Snapshot RNA collections before changing visibility; live iterators can invalidate.
        for o in list(bpy.data.collections['Campus_Map'].all_objects):
            if o is None or o.type!='MESH':continue
            if any(o.name.startswith(prefix) for prefix in ['Atrium_Roof','WestWing_Roof','EastWing_Roof','WestAnnex_Roof','EastAnnex_Roof','Warehouse_Roof']):
                hidden.append((o,o.hide_render));o.hide_render=True
        coll=bpy.data.collections.get('Rooftops')
        if coll:
            for o in list(coll.all_objects):
                if o is not None and o.type=='MESH':hidden.append((o,o.hide_render));o.hide_render=True
        for o in list(bpy.data.collections['Campus_Expansion_V2'].objects):
            if o is not None and o.get('role') in ['RoofEquipment','RoofSolar','RoofSeams','RoofGarden','RoofCoping','TreeDetail','Landscape','ChairDetails']:
                hidden.append((o,o.hide_render));o.hide_render=True
        render_view('CampusV4_CoreCutaway','Campus_RunSpaces_cutaway.png',24)
    finally:
        for o,old in hidden:o.hide_render=old
    print('Art cutaway saved; roof visibility restored')
