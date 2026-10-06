-- Continuous encounters count confirmed kills, never recycled NPCs.
local P={}
function P.New(plan)
 return {Mode=plan.Mode,Quota=plan.Quota,Duration=plan.Duration or 0,Alive=0,Defeated=0,Issued=0,Requeued=0,Elapsed=0,Complete=false,Section=1,SectionKills=0,DestroyedSources=0}
end
function P.Spawned(p)p.Alive+=1;p.Issued+=1 end
function P.Defeated(p)p.Alive=math.max(0,p.Alive-1);p.Defeated+=1;p.SectionKills+=1 end
function P.Requeue(p)p.Alive=math.max(0,p.Alive-1);p.Requeued+=1 end
function P.Step(p,dt,healthy,sections,sourceCount)
 if p.Complete then return true,false end
 -- A failed spawner is not free survival time.
 if healthy then p.Elapsed+=dt end
 local advanced=false
 if p.Mode=="WideGauntlet"then
  local section=sections[p.Section]
  if p.SectionKills>=section.Quota then
   if p.Section==#sections then p.Complete=true
   else p.Section+=1;p.SectionKills=0;advanced=true end
  end
 elseif p.Mode=="SpawnerHunt"then p.Complete=p.DestroyedSources>=sourceCount and sourceCount>0
 elseif p.Mode=="Survival"then p.Complete=p.Elapsed>=p.Duration and p.Defeated>=p.Quota
 else p.Complete=p.Defeated>=p.Quota end
 return p.Complete,advanced
end
return P
