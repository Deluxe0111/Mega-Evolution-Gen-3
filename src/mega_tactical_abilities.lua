-- Mega tactical abilities integrated at native Gen3 action boundaries.
-- All effects require an active Mega battle view. No save/ROM/type registry edits.
local Tactical={}

local function ability(game,b)
  if not (type(game)=="table" and type(game.view)=="function"
      and type(b)=="table" and type(b.mon)=="table") then return nil end
  local view=game.view(b.mon)
  return view and view.ability or nil
end
Tactical.ability=ability

-- Trigger only after a real stat drop caused by an opposing action. Native
-- Secondary.changeStat is authoritative about Mist, Clear Body and -6 caps.
-- Self-inflicted drops (e.g. Superpower) have flags.user=true; don't trigger.
function Tactical.afterStatChange(game,Secondary,adapter,b,stat,delta,flags,result)
  if result~="worked" or (tonumber(delta) or 0)>=0
      or (flags and (flags.user or flags.curse))
      or ability(game,b)~="DEFIANT" or type(b.stages)~="table"
      or type(Secondary.changeStat)~="function" then return false end
  if (tonumber(b.stages.attack) or 0)>=6 then return false end
  return Secondary.changeStat(adapter,b,"attack",2,
    {user=true,allowPtr=true})=="worked"
end

-- A Mega with Infiltrator ignores opposing Reflect/Light Screen in the
-- existing damage calculation, preserving the defender's screen state.
function Tactical.damageOptions(game,attacker,opts)
  if ability(game,attacker)~="INFILTRATOR"
      or not (opts and (opts.reflect or opts.lightScreen)) then return opts end
  local copy={}
  for k,v in pairs(opts) do copy[k]=v end
  copy.reflect=false
  copy.lightScreen=false
  return copy
end

-- Bypass active Substitute and Safeguard for the single target action
-- (including damaging moves and status moves). Never destroy the actual
-- Substitute, advance its HP, or permanently unset the side's safeguard.
-- This is scoped around the native per-target body so both mechanics are
-- restored even on errors. A different target in doubles remains untouched.
function Tactical.withInfiltrator(game,M,body)
  if type(body)~="function" then return nil end
  local target=M and M.target
  if not (target and M.user and target~=M.user
      and ability(game,M.user)=="INFILTRATOR") then return body(M) end
  local sub=target.substituteHP
  local adapter=M.adapter
  local side=adapter and type(adapter.ownSide)=="function"
    and adapter:ownSide(target) or nil
  local safeguard=side and side.expSafeguardTurns
  if not ((tonumber(sub) or 0)>0
      or (side and (tonumber(safeguard) or 0)>0)) then return body(M) end
  target.substituteHP=nil
  if side then side.expSafeguardTurns=nil end
  local packed=table.pack and table.pack(pcall(body,M))
    or {pcall(body,M)}
  target.substituteHP=sub
  if side then side.expSafeguardTurns=safeguard end
  if not packed[1] then error(packed[2],0) end
  return (table.unpack or unpack)(packed,2,packed.n or #packed)
end

local function moveInfo(Moves,ref)
  if not ref or not Moves then return nil end
  local ok,m=pcall(Moves.get,ref)
  return ok and m or nil
end

local function priority(Moves,move)
  if not move then return 0 end
  local ref=type(move)=="table" and (move.id or move.numId
    or move.name or move.move) or move
  if type(Moves.priority)~="function" then return 0 end
  local ok,value=pcall(Moves.priority,ref)
  return ok and (tonumber(value) or 0) or 0
end

local function isStatus(Moves,move)
  if not move then return false end
  if type(move)=="table" and tonumber(move.power)~=nil then
    return tonumber(move.power)<=0
  end
  local m=moveInfo(Moves,move)
  return m and (tonumber(m.power) or 0)<=0 or false
end

-- battle.turn_order is the native sorter hook in both singles and doubles.
-- Only decide when Prankster's +1 makes the priorities UNEQUAL; otherwise
-- preserve vanilla's (or earlier mods') speed/tie result. Call next first
-- to keep other hook users and their side effects in the chain.
function Tactical.turnOrder(game,Moves,first,firstMove,second,secondMove,default)
  local a=priority(Moves,firstMove)
  local b=priority(Moves,secondMove)
  if ability(game,first)=="PRANKSTER" and isStatus(Moves,firstMove) then
    a=a+1
  end
  if ability(game,second)=="PRANKSTER" and isStatus(Moves,secondMove) then
    b=b+1
  end
  if a~=b then return a>b end
  return default
end

-- Classic pre-Gen IX Protean: type becomes the resolved move's type before
-- the move executes. The native battle battler is temporary; saved party
-- type bytes are not touched. Game's Mega controller restores baseline types
-- at battle cleanup; switch-out discards this transient battler.
function Tactical.beforeMove(game,Moves,b,moveRef)
  if ability(game,b)~="PROTEAN" or type(b)~="table"
      or not b.mon then return false end
  local row=moveInfo(Moves,moveRef)
  local ty=row and tonumber(row.type)
  if not ty or ty<0 or ty>255 or (row.id=="STRUGGLE") then return false end
  if b.type1==ty and (b.type2==nil or b.type2==ty) then return false end
  b.type1=ty
  b.type2=nil
  return true
end

return Tactical
