local C=require 'SARPG_Core'
local M=require 'SARPG_Runtime'
local D=require 'PRPGE_PDA'
local H=require 'PRPGE_PDAHome'
local U={}
local accent={.40,.95,.70}
local function text(ui,s,x,y,c) c=c or accent;ui:drawText(tostring(s),x,y,c[1],c[2],c[3],1,UIFont.Small) end
local function wrap(ui,s,x,y,w)
 local line=''
 for word in s:gmatch('%S+') do
  local nextLine=line=='' and word or line..' '..word
  if line~='' and getTextManager():MeasureStringX(UIFont.Small,nextLine)>w then
   text(ui,line,x,y,{.73,.80,.77});y=y+18;line=word
  else line=nextLine end
 end
 text(ui,line,x,y,{.73,.80,.77});return y+18
end
local function button(ui,id,label,x,y,w,enabled)
 local r={id=id,x=x,y=y,w=w,h=28,enabled=enabled~=false};ui._sarpgButtons[#ui._sarpgButtons+1]=r
 ui:drawRect(x,y,w,28,1,.05,.15,.11)
 ui:drawRectBorder(x,y,w,28,r.enabled and .8 or .2,.4,.95,.7)
 text(ui,label,x+8,y+5,r.enabled and accent or {.38,.40,.39})
end
function U.Render(ui)
 local p=ui.player or getPlayer();if not p then return end
 local r=D.PageRect(ui);local x,y,w=r.x+14,r.y+48,r.w-28
 D.Panel(ui,r.x,r.y+40,r.w,r.h-40,accent)
 if not M.Ready(p) then text(ui,'Waiting for the server to sync ARPG progression...',x,y);return end
 local s=M.State(p);local talents=ui._sarpgPage=='talents';local kind=talents and 'talent' or 'attribute'
 text(ui,talents and 'SPECIAL SKILLS' or 'CHARACTER ATTRIBUTES',x,y)
 text(ui,'Level '..s.levelSeen..'  |  '..C.Points(s,kind,M.RPG(p))..' unspent '..(talents and 'skill' or 'attribute')..' points',x,y+24)
 y=wrap(ui,talents and 'Uses the SAME skill points as the original PDA tree. Follow prerequisites below. These purchases are permanent; resetting the original tree does not refund them.'
  or '3 attribute points per level. Each point is a permanent bonus, separate from skill-tree points. Progress carries through Respawn.',x,y+48,w)+16
 for _,def in ipairs(talents and C.TALENTS or C.ATTRIBUTES) do
  local rank=C.Rank(s,def.id)
  local can=C.Points(s,kind,M.RPG(p))>0 and rank<def.max and (not def.requires or C.Rank(s,def.requires)>0)
  text(ui,def.name..'  '..rank..' / '..def.max,x,y)
  button(ui,'buy:'..def.id,rank>=def.max and 'MAX' or '+ 1',x+w-70,y,66,can)
  y=wrap(ui,def.desc,x,y+23,w-86)+16
  ui:drawRect(x,y-8,w,1,.2,.4,.95,.7)
 end
 if talents then
  text(ui,'Field Medic  >  Bite Ward  >  Second Wind',x,y);y=y+28
  local ready=math.max(0,(s.windReady or 0)-getGameTime():getWorldAgeHours())
  button(ui,'wind',ready>0 and string.format('Second Wind: %.1fh',ready) or 'Use Second Wind',x,y,205,C.Rank(s,'secondwind')>0 and ready==0)
  y=y+40
  button(ui,'ammo','Ammo pickup: '..(s.autoAmmo and 'ON' or 'OFF'),x,y,205)
  button(ui,'bandage','Auto bandage: '..(s.autoBandage and 'ON' or 'OFF'),x+220,y,210)
  y=y+42
  wrap(ui,'Bite Ward reduces NEW bite infection rolls only when PDA Danger infection rules are enabled. It never removes existing infection. Auto actions wait while moving, aiming, or busy.',x,y,w)
 end
 local errors={};for name in pairs(M.errors) do errors[#errors+1]=name end;table.sort(errors)
 if #errors>0 then wrap(ui,'Unavailable this session: '..table.concat(errors,', ')..'. See console.txt.',x,r.y+r.h-60,w) end
end
function U.Install()
 if U.installed then return end;U.installed=true
 local render,click=H.Render,H.Click
 H.Render=function(ui,...)
  ui._sarpgButtons={}
  local r=D.PageRect(ui)
  if ui._sarpgPage then
   H.Hide(ui);U.Render(ui)
  else
   -- Make real space above Home; avoid covering existing controls or portraits.
   local pageRect=D.PageRect
   D.PageRect=function(u) local t=pageRect(u);return {x=t.x,y=t.y+40,w=t.w,h=t.h-40} end
   local ok,err=pcall(render,ui,...);D.PageRect=pageRect
   if not ok then error(err) end
  end
  button(ui,'home','Survivor',r.x+8,r.y+4,110)
  button(ui,'attributes','Attributes',r.x+126,r.y+4,125)
  button(ui,'talents','Skills',r.x+259,r.y+4,100)
 end
 H.Click=function(ui,x,y,...)
  for _,b in ipairs(ui._sarpgButtons or {}) do
   if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then
    if not b.enabled then return true end
    local p=ui.player or getPlayer();local s=M.State(p)
    if b.id=='home' then ui._sarpgPage=nil
    elseif b.id=='attributes' or b.id=='talents' then ui._sarpgPage=b.id
    elseif b.id:sub(1,4)=='buy:' then M.Buy(p,b.id:sub(5))
    elseif b.id=='ammo' then M.Toggle(p,'autoAmmo',not s.autoAmmo)
    elseif b.id=='bandage' then M.Toggle(p,'autoBandage',not s.autoBandage)
    elseif b.id=='wind' then M.Wind(p) end
    return true
   end
  end
  if ui._sarpgPage then return false end
  return click(ui,x,y,...)
 end
end
Events.OnGameStart.Add(U.Install)
return U
