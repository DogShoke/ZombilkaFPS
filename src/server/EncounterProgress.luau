-- Server-owned finite obligations; recovering an enemy never counts as a kill.
local Progress = {}
function Progress.New(phase)
	return {Budget=phase.Budget,Pending=phase.Budget,Alive=0,Defeated=0,Issued=0,Requeued=0,Elapsed=0,Mode=phase.Mode,Duration=phase.Duration or 0,LastPressure=-math.huge,Complete=false}
end
function Progress.Spawned(p) assert(p.Pending>0); p.Pending-=1; p.Alive+=1; p.Issued+=1 end
function Progress.Defeated(p) assert(p.Alive>0); p.Alive-=1; p.Defeated+=1 end
function Progress.Requeue(p) assert(p.Alive>0); p.Alive-=1; p.Pending+=1; p.Requeued+=1 end
function Progress.EnsurePressure(p,batch)
	if p.Mode=="Holdout" and p.Elapsed<p.Duration and p.Pending==0 and p.Alive==0 then
		p.Budget+=batch; p.Pending+=batch
	end
end
function Progress.Step(p,dt,now,inside,spawnHealthy,grace,pressure)
	if pressure then p.LastPressure=now end
	if p.Mode=="Holdout" then
		if inside and spawnHealthy and (pressure or (p.Pending>0 and now-p.LastPressure<=grace)) then p.Elapsed=math.min(p.Duration,p.Elapsed+dt) end
	elseif p.Mode=="Survival" then p.Elapsed=math.min(p.Duration,p.Elapsed+dt) end
	p.Complete=p.Pending==0 and p.Alive==0 and p.Defeated==p.Budget and (p.Mode=="ClearWaves" or p.Elapsed>=p.Duration)
	return p.Complete
end
return Progress
