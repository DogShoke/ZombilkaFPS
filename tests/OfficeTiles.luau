local Office=require(game.ServerScriptService.Server.OfficeMap)
local Layout=require(game.ServerScriptService.Server.FloorLayout)
local report={Plans=0,Samples={},Failed={},Variants={}}
for seed=1,80 do
 local a=Layout.Generate(seed,1);local b=Layout.Generate(seed,1)
 assert(a.Variant==b.Variant and Layout.Validate(a));assert(#a.Cells==25 and a.HalfWidth==90)
 report.Plans+=1
end
local holder=Instance.new("Folder");holder.Name="OfficeTileQA";holder.Parent=workspace
for _,seed in {1,2,3,4,5,6,7,8,9,10,123456,987654}do
 local ok,f=pcall(Office.CreateFloor,{Run=holder,Seed=seed},1,5,{FullValidation=true})
 if not ok then table.insert(report.Failed,{Seed=seed,Error=tostring(f)})
 else
  if f.Model:GetAttribute("Fallback")then table.insert(report.Failed,{Seed=seed,Error=f.Model:GetAttribute("FallbackReason")})end
  for _,cell in f.Layout.Cells do if cell.Role=="COVER"or cell.Role=="LANDMARK"then report.Variants[cell.Module]=true end end
  table.insert(report.Samples,{Seed=seed,Variant=f.Layout.Variant,Attributes=f.Model:GetAttributes()});f.Model:Destroy()
 end
 script:SetAttribute("Report",game.HttpService:JSONEncode(report))
 script:SetAttribute("Samples",#report.Samples+#report.Failed)
end
holder:Destroy()
script:SetAttribute("Success",#report.Failed==0);script:SetAttribute("Complete",true)
