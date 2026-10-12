"""Persist the user-imported Studio mesh IDs and normalized transforms into Rojo."""
from pathlib import Path
import json,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parent
rows=[json.loads(s) for s in (ROOT/'roblox_staging/uploaded_assets.jsonl').read_text(encoding='utf-8').splitlines()]
d=next(r for r in reversed(rows)if r['key']=='visual_template')
root=ET.Element('roblox',{'version':'4'});model=ET.SubElement(root,'Item',{'class':'Model'});props=ET.SubElement(model,'Properties');ET.SubElement(props,'string',{'name':'Name'}).text='CampusVisualTemplate'
for n,row in enumerate(d['parts']):
    if n%40==0:
        group=ET.SubElement(model,'Item',{'class':'Folder'});p=ET.SubElement(group,'Properties');ET.SubElement(p,'string',{'name':'Name'}).text=f'Visual_{n//40:02d}'
    part=ET.SubElement(group,'Item',{'class':'MeshPart'});p=ET.SubElement(part,'Properties');ET.SubElement(p,'string',{'name':'Name'}).text=row['name']
    cf=ET.SubElement(p,'CoordinateFrame',{'name':'CFrame'})
    for key,v in zip(['X','Y','Z']+[f'R{a}{b}'for a in range(3)for b in range(3)],row['cf']):ET.SubElement(cf,key).text=str(v)
    size=ET.SubElement(p,'Vector3',{'name':'Size'})
    for key,v in zip('XYZ',row['size']):ET.SubElement(size,key).text=str(v)
    colour=ET.SubElement(p,'Color3',{'name':'Color'})
    for key in 'RGB':ET.SubElement(colour,key).text='1'
    for key,value in {'Anchored':'true','CanCollide':'false','CanQuery':'false','CanTouch':'false','CastShadow':'true','DoubleSided':'true'}.items():ET.SubElement(p,'bool',{'name':key}).text=value
    for key,value in {'MeshId':row['mesh'],'TextureID':row['texture']}.items():ET.SubElement(ET.SubElement(p,'Content',{'name':key}),'url').text=value
    ET.SubElement(p,'float',{'name':'Transparency'}).text=str(row['transparency'])
    ET.SubElement(p,'token',{'name':'Material'}).text=str(row['material'])
    ET.SubElement(p,'token',{'name':'RenderFidelity'}).text='0'
    ET.SubElement(p,'token',{'name':'CollisionFidelity'}).text='0'
target=ROOT/'roblox_runtime/CampusVisualTemplate.rbxmx';target.write_bytes(ET.tostring(root,encoding='utf-8'))
(ROOT/'roblox_import/Imported_Assets.json').write_text(json.dumps(d,indent=2),encoding='utf-8')
print('Rojo visuals saved:',len(d['parts']),'meshes')
