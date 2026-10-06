-- Native Studio Script while idle, outside the shipping tree.
local Config=require(game.ReplicatedStorage.Shared.Config)
local Layout=require(game.ServerScriptService.Server.FloorLayout)
local Office=require(game.ServerScriptService.Server.OfficeMap)
local Progress=require(game.ServerScriptService.Server.EncounterProgress)
local function equal(a,b)
 if typeof(a)~=typeof(b)then return false end
 if type(a)~="table"then return a==b end
 for k,v in a do if not equal(v,b[k])then return false end end
 for k in b do if a[k]==nil then return false end end
 return true
end
local report={Plans=0,Themes={},Macros={},Modes={},Examples={},Navigation={},Failed={}}
for _,seed in {123456,246813,987654}do
 local sequence={}
 for n=1,200 do sequence[n]=Layout.Generate(seed,n)end
 for n=200,1,-1 do
  local p=Layout.Generate(seed,n);local ok,r=Layout.Validate(p);assert(ok,tostring(r))
  assert(equal(p,sequence[n]),"Order-dependent plan");assert(n~=1 or p.Encounter.Mode=="KillQuota")
  if n>1 then assert(p.Macro~=sequence[n-1].Macro)end
  assert(p.OpenSpaceFraction>=Config.Run.Generation.MinOpenFraction and #p.Edges>=3)
  report.Plans+=1;report.Themes[p.Theme]=true;report.Macros[p.Macro]=true;report.Modes[p.Encounter.Mode]=true
  if not report.Examples[p.Macro]then report.Examples[p.Macro]={Seed=seed,Floor=n,Theme=p.Theme}end
 end
end
for _,x in Config.Run.Generation.Macros do assert(report.Macros[x])end
for _,x in Config.Run.Generation.Themes do assert(report.Themes[x])end
for _,x in Config.Run.Encounters.Modes do assert(report.Modes[x])end
local bad=Layout.Generate(1,1);bad.Covers[1].X=0;bad.Covers[1].Z=bad.HalfDepth-34;assert(not Layout.Validate(bad))
bad=Layout.Generate(1,1);bad.Encounter.Mode="Survival";assert(not Layout.Validate(bad))
local p=Progress.New({Mode="KillQuota",Quota=2});Progress.Spawned(p);Progress.Requeue(p);assert(p.Defeated==0)
Progress.Spawned(p);Progress.Spawned(p);Progress.Spawned(p);Progress.Defeated(p);Progress.Defeated(p)
assert(Progress.Step(p,0,true,{},0)and p.Alive==1,"Last live zombie must not lock quota")
p=Progress.New({Mode="Survival",Quota=2,Duration=2});Progress.Step(p,3,false,{},0);assert(p.Elapsed==0)
Progress.Step(p,3,true,{},0);assert(not p.Complete);Progress.Spawned(p);Progress.Defeated(p);Progress.Spawned(p);Progress.Defeated(p);assert(Progress.Step(p,0,true,{},0))
p=Progress.New({Mode="WideGauntlet",Quota=2});local sections={{Quota=1},{Quota=1}}
Progress.Spawned(p);Progress.Defeated(p);local _,advanced=Progress.Step(p,0,true,sections,0);assert(advanced and not p.Complete)
Progress.Spawned(p);Progress.Defeated(p);assert(Progress.Step(p,0,true,sections,0))
report.Progress="Passed"
local holder=Instance.new("Folder");holder.Name="ArenaVerification";holder.Parent=workspace
local ok,err=pcall(function()
 for _,seed in {123456,246813}do for _,theme in Config.Run.Generation.Themes do for _,macro in Config.Run.Generation.Macros do
  local created,f=pcall(Office.CreateFloor,{Run=holder,Seed=seed},8,4,{FullValidation=true,Override={Theme=theme,Macro=macro}})
  if not created then table.insert(report.Failed,{Seed=seed,Theme=theme,Macro=macro,Error=tostring(f)})
  elseif f.Model:GetAttribute("Fallback")then table.insert(report.Failed,{Seed=seed,Theme=theme,Macro=macro,Error=f.Model:GetAttribute("FallbackReason")});f.Model:Destroy()
  else
   table.insert(report.Navigation,{Seed=seed,Theme=theme,Macro=macro,Checks=f.Model:GetAttribute("NavigationChecks"),Parts=f.Model:GetAttribute("PartCount"),Seconds=f.Model:GetAttribute("ValidationSeconds"),Density=f.Model:GetAttribute("CombatStructureFraction"),Visibility=f.Model:GetAttribute("VisibleCombatPoints"),Signature=f.Layout.Signature,Variant=f.Layout.Variant})
   f.Model:Destroy()
  end
  script:SetAttribute("Samples",#report.Navigation+#report.Failed)
  script:SetAttribute("ProgressReport",game:GetService("HttpService"):JSONEncode(report))
 end end end
end)
holder:Destroy();assert(ok,err);assert(#report.Failed==0,"Rejected layout samples: "..#report.Failed)
return report
