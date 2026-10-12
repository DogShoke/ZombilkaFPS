"""Generate static Rojo geometry/config. Python, not Blender."""
from pathlib import Path
import json,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parents[2]
d=json.loads((ROOT/'roblox_import/Campus_RuntimeData.json').read_text(encoding='utf-8'))
def item(parent,kind,name):
    i=ET.SubElement(parent,'Item',{'class':kind});p=ET.SubElement(i,'Properties');ET.SubElement(p,'string',{'name':'Name'}).text=name;return i,p
def val(p,typ,name,text):ET.SubElement(p,typ,{'name':name}).text=str(text).lower()if isinstance(text,bool)else str(text)
def vector(p,name,values):
    v=ET.SubElement(p,'Vector3',{'name':name})
    for k,n in zip('XYZ',values):ET.SubElement(v,k).text=str(n)
root=ET.Element('roblox',{'version':'4'});model,_=item(root,'Model','CampusCollisionTemplate')
for n,c in enumerate(d['colliders']):
    if n%400==0:group,_=item(model,'Folder',f'Collision_{n//400:02d}')
    name='Floor' if ('Floor' in c['name'] or 'Terrain' in c['name'] or 'Paving' in c['name'] or 'GroundV2' in c['name'] or 'Asphalt' in c['name']) else 'CampusCollision'
    i,p=item(group,'Part',name);vector(p,'Size',c['s']);cf=ET.SubElement(p,'CoordinateFrame',{'name':'CFrame'})
    for k,x in zip(['X','Y','Z']+[f'R{a}{b}'for a in range(3)for b in range(3)],c['p']+c['r']):ET.SubElement(cf,k).text=str(x)
    for k,x in {'Anchored':True,'CanCollide':True,'CanQuery':True,'CanTouch':False,'CastShadow':False}.items():val(p,'bool',k,x)
    val(p,'float','Transparency',1);val(p,'token','Material',256)
    if c.get('shape')=='Cylinder':val(p,'token','Shape',2)
target=ROOT/'roblox_runtime';target.mkdir(exist_ok=True)
(target/'CampusCollisionTemplate.rbxmx').write_bytes(ET.tostring(root,encoding='utf-8'))
def lua(v):
    if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
    if isinstance(v,bool):return 'true'if v else'false'
    if v is None:return 'nil'
    if isinstance(v,(int,float)):return str(round(v,5))
    if isinstance(v,list):return '{'+','.join(lua(x)for x in v)+'}'
    return '{'+','.join('['+lua(k)+']='+lua(x)for k,x in v.items())+'}'
config={'Version':4,'Scale':d['scale'],'Spawn':d['spawn'],'HalfWidth':762,'HalfDepth':727,'Zones':d['spawn_zones'],'Nodes':d['nav_nodes'],'Activities':d['layout']['activity_sites'],'MeshCount':d['mesh_count']}
(PROJECT/'src/shared/CampusLayout.luau').write_text('-- Generated from Blender V4 by write_rojo_runtime.py. Positions are local Roblox studs.\nreturn '+lua(config)+'\n',encoding='utf-8')
print('Rojo collision template and CampusLayout written:',len(d['colliders']),'colliders')
