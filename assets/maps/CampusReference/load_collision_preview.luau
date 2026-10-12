-- One-off Studio Edit import helper, outside Rojo scripts. HTTP is restored on completion.
local h=game:GetService("HttpService")
local was=h.HttpEnabled;h.HttpEnabled=true
local ok,result=pcall(function()
	local data=h:JSONDecode(h:GetAsync("http://127.0.0.1:8766/runtime.json"))
	local assets=game.ServerStorage.CampusAssets
	local previous=assets.CampusCollisionTemplate
	assert(previous:GetAttribute("CampusImportOwned")==true,"Refusing to replace unrelated geometry")
	local model=Instance.new("Model");model.Name="CampusCollisionPending"
	model:SetAttribute("CampusImportOwned",true);model.Parent=assets
	local chunk
	for i,c in data.colliders do
		if (i-1)%400==0 then
			if chunk then chunk.Parent=model;task.wait()end
			chunk=Instance.new("Folder");chunk.Name=string.format("Collision_%02d",math.floor((i-1)/400))
		end
		local p=Instance.new("Part")
		p.Name=(string.find(c.name,"Floor")or string.find(c.name,"Terrain")or string.find(c.name,"Paving")or string.find(c.name,"GroundV2")or string.find(c.name,"Asphalt"))and "Floor"or "CampusCollision"
		p.Anchored=true;p.Transparency=1;p.CanTouch=false;p.CastShadow=false
		p.Size=Vector3.new(unpack(c.s));p.CFrame=CFrame.new(c.p[1],c.p[2],c.p[3],unpack(c.r))
		if c.shape=="Cylinder"then p.Shape=Enum.PartType.Cylinder end
		p.Parent=chunk
	end
	chunk.Parent=model;previous:Destroy();model.Name="CampusCollisionTemplate"
	local old=workspace.CampusComplex;assert(old:GetAttribute("EndlessPrototypePreview"));old:Destroy()
	-- Fresh module copies avoid MCP's separate require cache during Edit verification.
	local source=game.ServerScriptService.Server.CampusMap:Clone()
	source.Source=source.Source:gsub("require%(game.ReplicatedStorage.Shared.CampusLayout%)","require(script.FreshLayout)")
	local layout=game.ReplicatedStorage.Shared.CampusLayout:Clone();layout.Name="FreshLayout";layout.Parent=source
	source.Parent=game.ServerStorage
	local map=require(source).Build();source:Destroy()
	map.Model:SetAttribute("EndlessPrototypePreview",true)
	return {colliders=#data.colliders,zones=#map.Zones,parts=map.Model:GetAttribute("PartCount")}
end)
h.HttpEnabled=was
return {ok=ok,result=result,httpRestored=h.HttpEnabled==was}
