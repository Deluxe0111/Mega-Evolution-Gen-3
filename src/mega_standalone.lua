-- Standalone Gen 3 bridge. No Gen1Recomp patch or custom engine hook needed.
-- We wrap existing exported Lua entrypoints, retain the original chains, and
-- never replace Pokemon.frontPic/backPic (owned by G9 Battle Sprites).
local Standalone = {}

local function current(st, id)
  if not st then return nil end
  id = tonumber(id) or 0
  if st.battlers then return st.battlers[id] end
  return (id == 0 and st.player) or (id == 1 and st.enemy) or nil
end

local function cloneBattler(b, game)
  if type(b) ~= "table" or type(b.mon) ~= "table" then return b end
  local values, modified = {}, false
  for _, key in ipairs({ "attack", "defense", "spAtk", "spDef" }) do
    local stat = game.stat(b, key, nil)
    if stat ~= nil then values[key], modified = stat, true end
  end
  if not modified then return b end
  -- Copy just the view used by Damage.base: no party Pokémon/save mutation,
  -- including while exceptions or other mods are computing damage.
  local copy, mon = {}, {}
  for k, v in pairs(b) do copy[k] = v end
  for k, v in pairs(b.mon) do mon[k] = v end
  for k, v in pairs(values) do mon[k] = v end
  copy.mon = mon
  return copy
end

function Standalone.install(mod, game, modules, battleVisual)
  if type(game) ~= "table" then return nil, "missing Mega controller" end
  local req = modules and modules.require or require
  local function required(name)
    local ok, value = pcall(req, name)
    if not ok or type(value) ~= "table" then return nil end
    return value
  end
  local Ui = modules and modules.Ui or required("src.core.game3.battle.ui")
  local Engine = modules and modules.Engine or required("src.core.game3.battle.engine")
  local Damage = modules and modules.Damage or required("src.core.game3.battle.damage")
  local Battle = modules and modules.Battle or required("src.core.game3.battle")
  local Specialized=modules and modules.MegaSpecialized
  if not Specialized then
    local ok,module=pcall(req,"src.mega_specialized_abilities")
    if ok and type(module)=="table" then Specialized=module end
  end
  local EffectIds=modules and modules.EffectIds
    or required("src.core.game3.battle.effect_ids")
  local MegaAbilities=modules and modules.MegaAbilities
  local Weather=modules and modules.MegaWeather
  if not Weather then
    local ok,module=pcall(req,"src.mega_weather_abilities")
    if ok and type(module)=="table" then Weather=module end
  end
  local Types=modules and modules.Types or required("src.core.game3.battle.types")
  local Rules=modules and modules.Rules or required("src.core.game3.battle.rules")
  local NativeAbilities=modules and modules.NativeAbilities
    or required("src.core.game3.battle.abilities")
  local WeatherHandlers=modules and modules.WeatherHandlers
    or required("src.core.game3.battle.residual_handlers")
  local Status=modules and modules.Status
    or required("src.core.game3.battle.effects.status")
  local Tactical=modules and modules.MegaTactical
  if not Tactical then
    local ok,module=pcall(req,"src.mega_tactical_abilities")
    if ok and type(module)=="table" then Tactical=module end
  end
  local Moves=modules and modules.Moves or required("src.core.game3.battle.moves")
  local Reactive=modules and modules.MegaReactive
  local Hit=modules and modules.Hit or required("src.core.game3.battle.effects.hit")
  local Secondary=modules and modules.Secondary or required("src.core.game3.battle.effects.secondary")
  if not Reactive then
    local ok,module=pcall(req,"src.mega_reactive_abilities")
    if ok and type(module)=="table" then Reactive=module end
  end
  if not MegaAbilities then
    local ok, module=pcall(req,"src.mega_abilities")
    if ok and type(module)=="table" then MegaAbilities=module end
  end
  if not (Ui and Engine and Damage and Battle
      and type(Ui.handleInput) == "function"
      and type(Ui.takeCommand) == "function"
      and type(Ui.sidePic) == "function"
      and type(Engine.resolveMove) == "function"
      and type(Damage.base) == "function"
      and type(Battle.start) == "function"
      and type(Battle.reset) == "function") then
    return nil, "expected Gen 3 battle entrypoints unavailable"
  end

  local active = true
  local wrapped = {}
  local function enabled()
    if active and mod.enabled == false then
      game.finish()
      return false
    end
    return active
  end
  local function wrap(holder, key, body)
    local prev = holder[key]
    local func = function(...) return body(prev, ...) end
    holder[key] = func
    wrapped[#wrapped + 1] = { holder = holder, key = key, ours = func, old = prev }
  end

  wrap(Ui, "handleInput", function(next, input)
    if enabled() and Ui._mode == "moves" and Ui.waitingForCommand
        and Ui.waitingForCommand() and not Ui._swap then
      local st = Ui._st
      local b = current(st, Ui._active or 0)
      if battleVisual and battleVisual.handleInput
          and battleVisual:handleInput(Ui, st, b, input) then return true end
      if b and game.input(st, b, input) then return true end
    end
    return next(input)
  end)

  wrap(Ui, "takeCommand", function(next)
    local action = next()
    if not enabled() or not action then return action end
    local st = Ui._st
    local id = type(action) == "table" and action.battler or Ui._active
    local b = current(st, id or 0)
    return game.command(st, b, action)
  end)

  wrap(Engine, "resolveMove", function(next, user, target, move, slot, adapter, st, out, opts)
    if enabled() and st and not st.link and not st.spectate then
      local battler = type(user) == "table" and user or current(st, user)
      -- The turn planner may force Encore/Choice/etc. Recheck the exact
      -- *resolved* move and slot, never spend the Mega on a changed move.
      if battler and game.beforeResolved(st, battler, move, slot) then
        if battleVisual and battleVisual.onMegaEvolved then
          battleVisual:onMegaEvolved(battler)
        end
        if game.onMegaEvolved then game.onMegaEvolved(st, battler, adapter) end
        if Weather and Weather.activate then
          Weather.activate(game,st,battler,adapter)
        end
      end
      -- The move has been selected and Mega activation processed. Apply
      -- Protean to the live battle battler before Gen3 resolves damage/STAB.
      if battler and Tactical and Tactical.beforeMove and Moves then
        local resolved=battler.expLockedMove
          or ((battler.expEncoreTurns or 0)>0 and battler.expEncoreMove)
          or move
        Tactical.beforeMove(game,Moves,battler,resolved)
      end
    end
    return next(user, target, move, slot, adapter, st, out, opts)
  end)

  -- A targeted native status move enters Engine.forEachTarget before the
  -- engine's Magic Coat guard. Reuse that guard for Mega Magic Bounce without
  -- changing the move record or permanently setting expMagicCoat.
  if Reactive and Reactive.withMagicBounce
      and type(Engine.forEachTarget)=="function"
      and type(Engine.hasFlag)=="function" then
    wrap(Engine,"forEachTarget",function(next,M,body)
      if not enabled() then return next(M,body) end
      return next(M,function(ctx)
        local function magic(targetCtx)
          return Reactive.withMagicBounce(game,targetCtx,body,Engine.hasFlag)
        end
        local function infiltrate(c)
          if Tactical and Tactical.withInfiltrator then
            return Tactical.withInfiltrator(game,c,magic)
          end
          return magic(c)
        end
        if Specialized and Specialized.withMoldBreaker then
          return Specialized.withMoldBreaker(game,ctx,infiltrate)
        end
        return infiltrate(ctx)
      end)
    end)
  end

  -- Active Delta Stream suppresses normal native weather setters while
  -- the Mega holder remains on the field. Their other battle handlers
  -- continue to work because this only skips dedicated weather setters.
  if Weather and Weather.blockNativeWeather and NativeAbilities
      and type(NativeAbilities.switchIn)=="function" then
    wrap(NativeAbilities,"switchIn",function(next,adapter,b)
      if enabled() and Weather.blockNativeWeather(game,adapter,b) then
        return false
      end
      return next(adapter,b)
    end)
  end

  -- Weather-setting abilities also activate if an already Mega-Evolved
  -- battler is switched back in. Native Abilities.switchIn runs first.
  if Weather and Weather.activate
      and type(Engine.switchInEffects)=="function" then
    wrap(Engine,"switchInEffects",function(next,st,adapter,b,opts)
      local result=next(st,adapter,b,opts)
      if enabled() and Weather.activate(game,st,b,adapter) then return true end
      return result
    end)
  end

  -- Electric Terrain's finite duration and Delta Stream's weather cleanup
  -- run at the native weather-continuation residual tick, once per turn.
  if Weather and Weather.tick and WeatherHandlers
      and type(WeatherHandlers.tickWeather)=="function" then
    wrap(WeatherHandlers,"tickWeather",function(next,adapter,...)
      local result=next(adapter,...)
      if enabled() and adapter and adapter._st then
        Weather.tick(game,adapter._st,adapter)
      end
      return result
    end)
  end

  -- Electric Terrain prevents a grounded Pokémon falling asleep from a
  -- direct move, without reassigning the engine's terrain ID.
  if Weather and Weather.terrainBlocksSleep and Status
      and type(Status.cantMakeAsleep)=="function" then
    wrap(Status,"cantMakeAsleep",function(next,ctx,target)
      if enabled() and ctx and ctx.adapter and
          Weather.terrainBlocksSleep(ctx.adapter._st,target,ctx.adapter) then
        if ctx.adapter.sayText then
          ctx.adapter:sayText("STRINGID_ITDOESNTAFFECT",{def=target})
        end
        return true
      end
      return next(ctx,target)
    end)
  end

  -- Solar Power's HP chip occurs after the native ability end-turn event.
  if Weather and Weather.endTurn and NativeAbilities
      and type(NativeAbilities.endTurn)=="function" then
    wrap(NativeAbilities,"endTurn",function(next,adapter,b)
      local result=next(adapter,b)
      if enabled() and Weather.endTurn(game,adapter,b) then return true end
      return result
    end)
  end

  -- Defiant reacts only to native, successfully applied enemy stat drops.
  -- Its own +2 Attack is a standard positive Secondary.changeStat call.
  if Secondary and type(Secondary.changeStat)=="function"
      and Tactical and Tactical.afterStatChange then
    wrap(Secondary,"changeStat",function(next,ad,b,stat,delta,flags)
      local actual=delta
      if enabled() and Specialized and Specialized.contraryDelta then
        actual=Specialized.contraryDelta(game,b,delta)
      end
      local result=next(ad,b,stat,actual,flags)
      if enabled() then
        Tactical.afterStatChange(game,Secondary,ad,b,stat,actual,flags,result)
      end
      return result
    end)
  end

  -- Sheer Force suppresses only qualifying *additional* effects, while
  -- leaving primary effects, PP, status moves and recoil untouched.
  if Specialized and Specialized.suppressSecondary and Secondary
      and type(Secondary.withChance)=="function" then
    wrap(Secondary,"withChance",function(next,M,...)
      if enabled() and Specialized.suppressSecondary(game,M,EffectIds) then
        return false
      end
      return next(M,...)
    end)
  end

  -- Bulletproof stops ball/bomb moves *before* damage or secondary effects.
  -- Hit.run is the native attack boundary after target/PP validation.
  if Hit and type(Hit.run)=="function" and Reactive
      and Reactive.blockBulletproof then
    wrap(Hit,"run",function(next,M,...)
      if enabled() and Reactive.blockBulletproof(game,M) then return end
      if enabled() and Specialized and Specialized.withSkillLink then
        local args={...}
        return Specialized.withSkillLink(game,M,function(ctx)
          return next(ctx,(table.unpack or unpack)(args))
        end,EffectIds)
      end
      return next(M,...)
    end)
  end

  -- Cross the HP threshold only for real direct attack damage (never
  -- substitute), then invoke the engine's standard stat-stage function.
  if Hit and type(Hit.dealDamage)=="function" and Reactive and Secondary
      and Reactive.onDamaged then
    wrap(Hit,"dealDamage",function(next,M,...)
      if not enabled() then return next(M,...) end
      local target=M and M.target
      local adapter=M and M.adapter
      local before=target and adapter and adapter.hp and adapter:hp(target)
      local dealt=next(M,...)
      local after=target and adapter and adapter.hp and adapter:hp(target)
      if before and after then
        Reactive.onDamaged(game,M,before,after,Secondary)
      end
      if Weather and Weather.cleanStrongWinds and adapter then
        Weather.cleanStrongWinds(game,adapter._st,adapter)
      end
      return dealt
    end)
  end

  -- Engine.performSwitch invokes switchOutEffects before it copies HP back
  -- to the saved party. Native adapter.heal records HP and events correctly.
  if Reactive and Reactive.onSwitchOut
      and type(Engine.switchOutEffects)=="function" then
    wrap(Engine,"switchOutEffects",function(next,st,adapter,b)
      local result=next(st,adapter,b)
      if not enabled() then return result end
      local changed=Reactive.onSwitchOut(game,adapter,b)
      if Weather and Weather.onSwitchOut then
        Weather.onSwitchOut(game,st,b,adapter)
      end
      return changed or result
    end)
  end

  -- Native turn-order calculation reads mon.speed in both singles and
  -- doubles. Supply a temporary copied speed view during planning only;
  -- preserve the original mon pointer as soon as planning returns.
  if type(game.withSpeedPlanning) == "function" then
    for _, method in ipairs({ "planTurnActions", "planTurnFromActions" }) do
      if type(Engine[method]) == "function" then
        wrap(Engine, method, function(next, st, ...)
          if not enabled() then return next(st, ...) end
          return game.withSpeedPlanning(st, function(...)
            return next(st, ...)
          end, ...)
        end)
      end
    end
  end

  wrap(Damage, "base", function(next, attacker, defender, move, opts)
    if not enabled() then return next(attacker, defender, move, opts) end
    local effectiveOpts=opts
    if MegaAbilities and MegaAbilities.baseOptions then
      effectiveOpts=MegaAbilities.baseOptions(game,attacker,move,opts)
    end
    if Specialized and Specialized.baseOptions then
      effectiveOpts=Specialized.baseOptions(game,attacker,move,effectiveOpts,EffectIds)
    end
    local attackView=cloneBattler(attacker, game)
    if Weather and Weather.attackView then
      local st=Battle._st or Ui._st or (opts and opts.st)
      local ad=opts and opts.adapter
      local physical=Types and Types.isPhysical
      attackView=Weather.attackView(game,st,ad,attacker,attackView,
        move,effectiveOpts,physical)
    end
    return next(attackView,cloneBattler(defender, game),move,effectiveOpts)
  end)

  -- Native Damage.calc does STAB, effectiveness, crit and random rolls after
  -- Damage.base. Only end-of-calculation multipliers belong on this seam.
  if type(Damage.calc)=="function" and MegaAbilities
      and MegaAbilities.finalDamage then
    wrap(Damage, "calc", function(next, attacker, defender, move, opts)
      if not enabled() then return next(attacker,defender,move,opts) end
      local effective=opts
      if MegaAbilities.moveOptions then
        effective=MegaAbilities.moveOptions(game,attacker,move,effective)
      end
      if Tactical and Tactical.damageOptions then
        effective=Tactical.damageOptions(game,attacker,effective)
      end
      local amount,info=next(attacker,defender,move,effective)
      amount,info=MegaAbilities.finalDamage(game,attacker,defender,amount,info)
      if Weather and Weather.finalDamage then
        local st=Battle._st or Ui._st or (effective and effective.st)
        local ad=effective and effective.adapter
        amount,info=Weather.finalDamage(game,st,ad,
          attacker,defender,amount,info,Types)
      end
      return amount,info
    end)
  end

  -- Apply Prankster at the official singles/doubles turn ordering hook.
  -- No move database mutation and no reordering of switches/items.
  local turnOrderUnhook
  if mod.hooks and type(mod.hooks.wrap)=="function" and Tactical
      and Tactical.turnOrder and Moves then
    turnOrderUnhook=mod.hooks:wrap("battle.turn_order",
      function(next,a,am,b,bm,ctx)
        local vanilla=next(a,am,b,bm,ctx)
        if not enabled() then return vanilla end
        -- UnifiedCallbacks may supply a read-only, non-native battle
        -- view in ctx.battle. Prefer the live battle for ID resolution.
        local st=Battle._st or Ui._st
          or (type(ctx)=="table" and ctx.battle)
        local function resolve(pub)
          if type(pub)~="table" then return nil end
          local id=tonumber(pub.id)
          if id~=nil then return current(st,id) end
          return pub.mon and pub or nil
        end
        return Tactical.turnOrder(game,Moves,resolve(a),am,
          resolve(b),bm,vanilla)
      end)
  end

  -- Gen 3 publishes an accuracy callback after Protect and the native
  -- semi-invulnerable checks. No Guard controls this roll only; do NOT
  -- overwrite Protect, invulnerability or absorption logic.
  local accuracyUnhook
  if mod.hooks and type(mod.hooks.wrap)=="function"
      and MegaAbilities and MegaAbilities.accuracy then
    accuracyUnhook=mod.hooks:wrap("battle.accuracy",function(next,ctx)
      if not enabled() then return next(ctx) end
      local st=Battle._st or Ui._st
      local function resolve(public)
        if type(public)~="table" then return nil end
        if public.id~=nil then
          local found=current(st,public.id)
          if found then return found end
        end
        return public.mon and public or nil
      end
      if MegaAbilities.accuracy(game,ctx,resolve) then
        ctx.accuracy=100 -- guaranteed to pass the native 1..100 roll
      end
      return next(ctx)
    end)
  end

  -- Ui.draw is the narrowest exported boundary around battle sprite draws.
  -- Any Mega pivot rewrite exists only inside this call, not across frames
  -- or ordinary G9 / HD sprite drawing elsewhere in the engine.
  if type(Ui.draw) == "function" then
    wrap(Ui, "draw", function(next, ...)
      if not enabled() then return next(...) end
      if battleVisual and battleVisual.withTransitionDraw then
        return battleVisual:withTransitionDraw(function(...)
          return game.withBattleDraw(next,...)
        end,...)
      end
      return game.withBattleDraw(next, ...)
    end)
  end

  wrap(Ui, "sidePic", function(next, back, ignoreDeoxys, picSp, form, shiny, personality, mon)
    local ordinary = next(back, ignoreDeoxys, picSp, form, shiny, personality, mon)
    if not enabled() or not mon then return ordinary end
    local st = Ui._st
    if not (st and Battle._active and Battle._st == st) then return ordinary end
    -- The existing Ui.sidePic already receives the real mon pointer. The
    -- original provider is evaluated FIRST (including G9's wrappers), and
    -- non-Mega battlers always keep its result untouched.
    local mega = game.monPicture(st, mon, back, shiny, ordinary)
    if battleVisual and battleVisual.choosePicture then
      return battleVisual:choosePicture(mon,back,ordinary,mega)
    end
    return mega
  end)

  wrap(Battle, "start", function(next, opts)
    if enabled() then
      game.finish()
      if battleVisual and battleVisual.resetTransform then battleVisual:resetTransform() end
    end
    return next(opts)
  end)

  wrap(Battle, "reset", function(next, ...)
    if enabled() then
      game.finish()
      if battleVisual and battleVisual.resetTransform then battleVisual:resetTransform() end
    end
    return next(...)
  end)

  local bridge = {}
  function bridge.uninstall()
    if not active then return end
    active = false
    game.finish()
    if battleVisual and battleVisual.resetTransform then battleVisual:resetTransform() end
    if type(accuracyUnhook)=="function" then accuracyUnhook() end
    if type(turnOrderUnhook)=="function" then turnOrderUnhook() end
    -- Undo only if our wrapper is still on top; later mods must keep the
    -- chain they installed. Otherwise our closure remains a pass-through.
    for i = #wrapped, 1, -1 do
      local w = wrapped[i]
      if w.holder[w.key] == w.ours then w.holder[w.key] = w.old end
    end
  end
  return bridge
end

return Standalone
