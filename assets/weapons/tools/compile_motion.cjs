const fs=require('node:fs');
const folder='assets/weapons/motion'; fs.mkdirSync(folder,{recursive:true});
fs.writeFileSync(folder+'/init.meta.json',JSON.stringify({className:'Folder'}));
for (const weapon of ['AKM','Mossberg']) {
  const clips=JSON.parse(fs.readFileSync('assets/weapons/'+weapon+'_Clips.json','utf8'));
  const inventory=JSON.parse(fs.readFileSync('assets/weapons/source_inventory.json','utf8'));
  const bones=inventory[weapon==='AKM'?'AKM':'Arms'].objects.find(o=>o.type==='ARMATURE').bones;
  const parents=Object.fromEntries(bones.filter(b=>b.parent).map(b=>[b.name,b.parent]));
  if(weapon==='Mossberg'){parents.Trigger='ShotgunRoot';parents.FR='ShotgunRoot';}
  let output='-- Sampled Blender poses; unchanged child bones inherit their parent world delta.\nreturn {parents={'+Object.entries(parents).map(([a,b])=>'["'+a+'"]="'+b+'"').join(',')+'},\n';
  for (const [name,clip] of Object.entries(clips)) {
    output+='["'+name+'"]={fps='+clip.fps+',frames={\n';
    for (const frame of clip.frames) {
      output+='{';
      for (const [bone,values] of Object.entries(frame)) {
        const parent=frame[parents[bone]]||[0,0,0,1,0,0,0,1,0,0,0,1];
        if(values.every((v,i)=>Math.abs(v-parent[i])<0.00003)) continue;
        output+='["'+bone+'"]={'+values.join(',')+'},';
      }
      output+='},\n';
    }
    output+='}},\n';
  }
  output+='}\n'; fs.writeFileSync(folder+'/'+weapon+'Clips.luau',output);
  console.log(weapon,output.length);
}
