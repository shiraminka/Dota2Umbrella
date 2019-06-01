local AbilityRange = {}

AbilityRange.Enable = Menu.AddOptionBool({ "NekoScripts", "Ability range" }, "Enable", false)
AbilityRange.HideToggleKey = Menu.AddKeyOption({ "NekoScripts", "Ability range" }, "Show / Hide", Enum.ButtonCode.KEY_NONE)

AbilityRange.boxSizeOption = Menu.AddOptionSlider({ "NekoScripts", "Ability range" }, "Box size", 20, 200, 70)
AbilityRange.boxX = Menu.AddOptionSlider({ "NekoScripts", "Ability range" }, "Box X position", 0, 1920, 835)
AbilityRange.boxY = Menu.AddOptionSlider({ "NekoScripts", "Ability range" }, "Box Y position", 0, 1080, 786)
AbilityRange.needsInit = true
AbilityRange.spellIconPath = "panorama/images/spellicons/"
AbilityRange.cachedIcons = {}
AbilityRange.LastClickTime = 0
AbilityRange.LastClickindex = 0
AbilityRange.ClickCooldown = 0.3

AbilityRange.Range = {}
AbilityRange.Range.Inited = false
AbilityRange.Range.Particles = {}
AbilityRange.Range.Particles.Radius = {}
AbilityRange.Hero = nil


local function starts_with(str, start)
   return str:sub(1, #start) == start
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function GetRange(s)
	r = Ability.GetCastRange(s)
	if r ~= 0 then return r end
	r = Ability.GetLevelSpecialValueFor(s, "max_range")
	if r ~= 0 then return r end
	r = Ability.GetLevelSpecialValueFor(s, "radius")
	if r ~= 0 then return r end
	r = Ability.GetLevelSpecialValueFor(s, "cogs_radius")
	if r ~= 0 then return r end
	r = Ability.GetLevelSpecialValueFor(s, "attack_radius")
	if r ~= 0 then return r end
	r = Ability.GetLevelSpecialValueFor(s, "aftershock_range")
	if r ~= 0 then return r end
	r = Ability.GetLevelSpecialValueFor(s, "blade_fury_radius")
	if r ~= 0 then return r end
	r = Ability.GetLevelSpecialValueFor(s, "cleave_distance")
	if r ~= 0 then return r end
	r = Ability.GetLevelSpecialValueFor(s, "echo_slam_damage_range")
	if r ~= 0 then return r end
	r = Ability.GetLevelSpecialValueFor(s, "dash_length")
	if r ~= 0 then return r end
	return r
end

function AbilityRange.isEnabled()
	return Menu.IsEnabled(AbilityRange.Enable)
end

function AbilityRange.CreateRangeParticle(index)
	if (AbilityRange.Hero == nil) then
		return false
	end
	if (AbilityRange.Range.Particles.Radius[index] == nil) then
		AbilityRange.Range.Particles.Radius[index] = {}
		AbilityRange.Range.Particles.Radius[index].ID = Particle.Create("particles/ui_mouseactions/range_display.vpcf", Enum.ParticleAttachment.PATTACH_ABSORIGIN_FOLLOW, AbilityRange.Hero)
		AbilityRange.Range.Particles.Radius[index].Value = 0
		return true
	end
	return false
end

function AbilityRange.ClearRangeParticle(index)
	if AbilityRange.Range.Particles.Radius[index] then
		Particle.Destroy(AbilityRange.Range.Particles.Radius[index].ID)
		AbilityRange.Range.Particles.Radius[index] = nil
	end
end

function AbilityRange.SetRange(index,range)
	if (AbilityRange.Hero == nil) then
		return false
	end
	AbilityRange.CreateRangeParticle(index)

	if (AbilityRange.Range.Particles.Radius[index].ID ~= 0) and (AbilityRange.Range.Particles.Radius[index].Value ~= range) then

		if (AbilityRange.Range.Particles.Radius[index].Value ~= 0) then
			AbilityRange.ClearRangeParticle(index)
			AbilityRange.CreateRangeParticle(index)
		end
		AbilityRange.Range.Particles.Radius[index].Value = range
		Particle.SetControlPoint(AbilityRange.Range.Particles.Radius[index].ID, 1, Vector(tonumber(range),0,0))
		Particle.SetControlPoint(AbilityRange.Range.Particles.Radius[index].ID, 6, Vector(1, 0, 0))
		return true
	end

	return false
end

function AbilityRange.Initialization()
	if AbilityRange.Hero ~= Heroes.GetLocal() then
		AbilityRange.Hero = Heroes.GetLocal()
		for k in pairs(AbilityRange.Range.Particles.Radius) do
			AbilityRange.ClearRangeParticle(k)
		end
	end
	if not AbilityRange.Range.Inited and Engine.IsInGame() then
		AbilityRange.Range.Inited = true
	end
end;
function AbilityRange.Finalization()
	if AbilityRange.Range.Inited then
		AbilityRange.Hero = nil
		for k in pairs(AbilityRange.Range.Particles.Radius) do
			AbilityRange.ClearRangeParticle(k)
		end
		AbilityRange.Range.Inited = false;
	end
end

function AbilityRange.OnUpdate()
	if AbilityRange.isEnabled() then
		AbilityRange.Initialization();
    	local heroname = NPC.GetUnitName(AbilityRange.Hero)
		for i = 0, 21 do
        	local ability = NPC.GetAbilityByIndex(AbilityRange.Hero, i)
        	if ability then
			    local abilityname = Ability.GetName(ability)
				cfg = Config.ReadInt("AbilityRange", abilityname, 0)
				if cfg == 1 then
					if AbilityRange.Range.Particles.Radius[i] == nil then
						AbilityRange.SetRange(i, GetRange(ability))
					else
						if(AbilityRange.Range.Particles.Radius[i].Value ~= GetRange(ability)) then
							AbilityRange.ClearRangeParticle(i)
							AbilityRange.SetRange(i, GetRange(ability))
						end
					end
				else
					if AbilityRange.Range.Particles.Radius[i] ~= nil then
						AbilityRange.ClearRangeParticle(i)
					end
				end
			end
		end
	else
		AbilityRange.Finalization();
	end
	if Menu.IsKeyDownOnce(AbilityRange.HideToggleKey) then
		cfg = Config.ReadInt("AbilityRange", "ShowPanel", 0)
		if cfg == 1 then
			Config.WriteInt("AbilityRange", "ShowPanel", 0)
		else
			Config.WriteInt("AbilityRange", "ShowPanel", 1)
		end
	end
end

function AbilityRange.InitDisplay()
    AbilityRange.boxSize = Menu.GetValue(AbilityRange.boxSizeOption)
end

function AbilityRange.OnMenuOptionChange(option, old, new)
	if option == AbilityRange.boxSizeOption then
        AbilityRange.InitDisplay()
    end
end

function AbilityRange.DrawDisplay(hero)
    local pos = Entity.GetAbsOrigin(hero)
    local x, y, vis = Renderer.WorldToScreen(pos)
    local w, h = Renderer.GetScreenSize()
    x = Menu.GetValue(AbilityRange.boxX)
    y = Menu.GetValue(AbilityRange.boxY)
    local abilities = {}
    heroname = NPC.GetUnitName(hero)
    for i = 0, 21 do
        local ability = NPC.GetAbilityByIndex(hero, i)
        if ability ~= nil and not Ability.IsHidden(ability) then
	        local abilityname = Ability.GetName(ability)
	    	local heroname = NPC.GetUnitName(hero)
	    	local shortheroname = heroname:gsub('npc_dota_hero_', '', 1);
	        if starts_with(abilityname, shortheroname) then
	        	table.insert(abilities, ability)
	        end
	    end
    end
    Renderer.SetDrawColor(255,255,255,255)
    Renderer.DrawFilledRect(x, y, (AbilityRange.boxSize * #abilities), AbilityRange.boxSize)
    for i, ability in ipairs(abilities) do
        AbilityRange.DrawAbilitySquare(hero, ability, x, y, i - 1)
    end
end

function AbilityRange.DrawAbilitySquare(hero, ability, x, y, index)
    local heroname = NPC.GetUnitName(hero)
    local abilityName = Ability.GetName(ability)
    local imageHandle = AbilityRange.cachedIcons[abilityName]
    if imageHandle == nil then
        imageHandle = Renderer.LoadImage(AbilityRange.spellIconPath .. abilityName .. "_png.vtex_c")
        AbilityRange.cachedIcons[abilityName] = imageHandle
    end

    local realX = x + (index * (AbilityRange.boxSize))

    local imageColor = { 255, 255, 255 }
    local outlineColor = { 0, 255 , 0 }
    
	cfg = Config.ReadInt("AbilityRange", abilityName, 0)
    if cfg == 0 then 
    	outlineColor = { 255, 0, 0}
    end


    local boxSize = AbilityRange.boxSize

    Renderer.SetDrawColor(imageColor[1], imageColor[2], imageColor[3], 255)
    Renderer.DrawImage(imageHandle, realX, y, boxSize, boxSize)

    Renderer.SetDrawColor(outlineColor[1], outlineColor[2], outlineColor[3], 255)
    Renderer.DrawOutlineRect(realX, y, boxSize, boxSize)

    local hoveringOver = Input.IsCursorInRect(realX, y, AbilityRange.boxSize, AbilityRange.boxSize)
	if hoveringOver and Input.IsKeyDown(Enum.ButtonCode.MOUSE_LEFT) then
		if index == AbilityRange.LastClickindex then

			if os.clock() - AbilityRange.ClickCooldown > AbilityRange.LastClickTime then
				if cfg == 0 then
					Config.WriteInt("AbilityRange", abilityName, 1)
					AbilityRange.SetRange(index + 1, GetRange(ability))
				else
					Config.WriteInt("AbilityRange", abilityName, 0)
					AbilityRange.ClearRangeParticle(index + 1)
				end
				AbilityRange.LastClickTime = os.clock()
			end

		else

			if cfg == 0 then
				Config.WriteInt("AbilityRange", abilityName, 1)
				AbilityRange.SetRange(index + 1, GetRange(ability))
			else
				Config.WriteInt("AbilityRange", abilityName, 0)
				AbilityRange.ClearRangeParticle(index + 1)
			end
			AbilityRange.LastClickindex = index
			AbilityRange.LastClickTime = os.clock()
			
		end
	end
end

function AbilityRange.OnDraw()
	if not Menu.IsEnabled(AbilityRange.Enable) then return end

    local myHero = Heroes.GetLocal()
    if not myHero then return end

    if AbilityRange.needsInit then
        AbilityRange.InitDisplay()
        AbilityRange.needsInit = false
    end
    if Config.ReadInt("AbilityRange", "ShowPanel", 0) == 1 then
    	AbilityRange.DrawDisplay(myHero)
	end
end

	
return AbilityRange
