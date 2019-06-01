local AutoDisabler = {}

AutoDisabler.Enable = Menu.AddOptionBool({ "NekoScripts", "Auto disabler" }, "Enable", false)


AutoDisabler.OnKeyDisabler = Menu.AddOptionBool({ "NekoScripts", "Auto disabler" }, "Disable enemies only when key pressed", false)
AutoDisabler.OnKeyDisablerToggleMode = Menu.AddOptionBool({ "NekoScripts", "Auto disabler" }, "Toggle mode", false)
AutoDisabler.OnKeyDisablerKey = Menu.AddKeyOption({ "NekoScripts", "Auto disabler" }, "Key for disable enemies", Enum.ButtonCode.KEY_NONE)

AutoDisabler.AggressiveMode = Menu.AddOptionBool({ "NekoScripts", "Auto disabler" }, "Aggressive mode", true)
AutoDisabler.CastTogether = Menu.AddOptionBool({ "NekoScripts", "Auto disabler" }, "Cast all together", false)

AutoDisabler.ShowItemPanel = Menu.AddOptionBool({ "NekoScripts", "Auto disabler" }, "Show item panel", false)
--AutoDisabler.ShowItemPanelKey = Menu.AddKeyOption({ "NekoScripts", "Auto disabler" }, "Show item panel Key", Enum.ButtonCode.KEY_NONE)
AutoDisabler.ItemPanelX = Menu.AddOptionSlider({ "NekoScripts", "Auto disabler" }, "Item panel X position", 0, 1860, 1246)
AutoDisabler.ItemPanelY = Menu.AddOptionSlider({ "NekoScripts", "Auto disabler" }, "Item panel Y position", 0, 1080, 887)
AutoDisabler.ItemPanelSize = Menu.AddOptionSlider({ "NekoScripts", "Auto disabler" }, "Item panel size", 0, 100, 60)

AutoDisabler.TextBoxX = Menu.AddOptionSlider({ "NekoScripts", "Auto disabler" }, "Debug text box X position", 0, 1920, 1353)
AutoDisabler.TextBoxY = Menu.AddOptionSlider({ "NekoScripts", "Auto disabler" }, "Debug text box Y position", 0, 1080, 932)


AutoDisabler.Hero = nil

AutoDisabler.SpellIconPath = "panorama/images/spellicons/"
AutoDisabler.ItemIconPath = "panorama/images/items/"
AutoDisabler.ItemCachedIcons = {}

AutoDisabler.OwnedItems = {}
AutoDisabler.Items = {}
AutoDisabler.ItemsLinken = {}

AutoDisabler.Abilities = {}

ModifierStates = {	Enum.ModifierState.MODIFIER_STATE_ROOTED,
				Enum.ModifierState.MODIFIER_STATE_SILENCED,
				Enum.ModifierState.MODIFIER_STATE_MUTED,
				Enum.ModifierState.MODIFIER_STATE_STUNNED,
				Enum.ModifierState.MODIFIER_STATE_HEXED,
				Enum.ModifierState.MODIFIER_STATE_FROZEN,
				Enum.ModifierState.MODIFIER_STATE_DISARMED,
				Enum.ModifierState.MODIFIER_STATE_BLIND,
				Enum.ModifierState.MODIFIER_STATE_UNSELECTABLE,
				Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE,
				Enum.ModifierState.MODIFIER_STATE_INVULNERABLE
			}
ModifierStatesName = {	"MODIFIER_STATE_ROOTED",
				"MODIFIER_STATE_SILENCED",
				"MODIFIER_STATE_MUTED",
				"MODIFIER_STATE_STUNNED",
				"MODIFIER_STATE_HEXED",
				"MODIFIER_STATE_FROZEN",
				"MODIFIER_STATE_DISARMED",
				"MODIFIER_STATE_BLIND",
				"MODIFIER_STATE_UNSELECTABLE",
				"MODIFIER_STATE_MAGIC_IMMUNE",
				"MODIFIER_STATE_INVULNERABLE"
			}


AutoDisabler.LinkenItemLastClickTime = 0
AutoDisabler.LinkenItemLastClickindex = 0
AutoDisabler.ItemLastClickTime = 0
AutoDisabler.ItemLastClickindex = 0
AutoDisabler.ClickCooldown = 0.3


AutoDisabler.Font = Renderer.LoadFont("Tahoma", 16, Enum.FontWeight.BOLD)
--NPC.IsLinkensProtected(npc)

--help functions
function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function AutoDisabler.HeroesInRadius(entity, radius, team)
	local tbl = Entity.GetHeroesInRadius(entity,  math.floor(radius), team)
	if tbl ~= nil then
		return tbl
	else
		return {}
	end
end

function AutoDisabler.GetModifiers(entity)
	local tbl = NPC.GetModifiers(entity)
	if tbl ~= nil then
		return tbl
	else
		return {}
	end
end

function AutoDisabler.GetState(entity)
	tbl = {}
	for _, q in ipairs(ModifierStates) do
		if NPC.HasState(entity, q) then
			table.insert(tbl, q)
		end
	end
	return tbl
end

function AutoDisabler.GetStateName(state)
	for i = 1, tablelength(ModifierStates) do
		if state == ModifierStates[i] then
			return ModifierStatesName[i]
		end
	end
	return "none"
end

function AutoDisabler.AlreadyDisabled(entity)
	for i = 1, 7 do
		if NPC.HasState(entity, ModifierStates[i]) then return true end
	end
	return false
end

function AutoDisabler.IsUnselectable(entity)
	if NPC.HasState(entity, ModifierStates[9]) then
		return true
	else
		return false
	end
end

function AutoDisabler.IsMagicImune(entity)
	if NPC.HasState(entity, ModifierStates[10]) then
		return true
	else
		return false
	end
end

function AutoDisabler.IsInvulerable(entity)
	if NPC.HasState(entity, ModifierStates[11]) then
		return true
	else
		return false
	end
end

function AutoDisabler.GetItem(name)
	for _, v in ipairs(AutoDisabler.Items) do
		if v.name == name then return v end
	end
end

function AutoDisabler.GetLinkenItem(name)
	for _, v in ipairs(AutoDisabler.ItemsLinken) do
		if v.name == name then return v end
	end
end

function AutoDisabler.GetEnabledItems()
	local c = 0
	for _, v in ipairs(AutoDisabler.Items) do
		if v.enable then c = c + 1 end
	end
	return c
end

function AutoDisabler.GetEnabledLinkenItems()
	local c = 0
	for _, v in ipairs(AutoDisabler.ItemsLinken) do
		if v.enable then c = c + 1 end
	end
	return c
end

function AutoDisabler.GetEnabledItem()
	for _, v in ipairs(AutoDisabler.Items) do
		if v.enable then return v end
	end
end

function AutoDisabler.GetEnabledLinkenItem()
	for _, v in ipairs(AutoDisabler.ItemsLinken) do
		if v.enable then return v end
	end
end

function AutoDisabler.Init()
end

function AutoDisabler.InitItems()
	cfg = Config.ReadInt("AutoDisabler", "item_sheepstick", 0) == 1
	AutoDisabler.Items[1] = {name="item_sheepstick", enable=cfg, tmi=false}
	cfg = Config.ReadInt("AutoDisabler", "item_bloodthorn", 0) == 1
	AutoDisabler.Items[2] = {name="item_bloodthorn", enable=cfg, tmi=false}
	cfg = Config.ReadInt("AutoDisabler", "item_orchid", 0) == 1
	AutoDisabler.Items[3] = {name="item_orchid", enable=cfg, tmi=false}
	cfg = Config.ReadInt("AutoDisabler", "item_cyclone", 0) == 1
	AutoDisabler.Items[4] = {name="item_cyclone", enable=cfg, tmi=false}
	cfg = Config.ReadInt("AutoDisabler", "item_rod_of_atos", 0) == 1
	AutoDisabler.Items[5] = {name="item_rod_of_atos", enable=cfg, tmi=false}
	cfg = Config.ReadInt("AutoDisabler", "item_nullifier", 0) == 1
	AutoDisabler.Items[6] = {name="item_nullifier", enable=cfg, tmi=false}
	cfg = Config.ReadInt("AutoDisabler", "item_abyssal_blade", 0) == 1
	AutoDisabler.Items[7] = {name="item_abyssal_blade", enable=cfg, tmi=true}
	cfg = Config.ReadInt("AutoDisabler", "item_heavens_halberd", 0) == 1
	AutoDisabler.Items[8] = {name="item_heavens_halberd", enable=cfg, tmi=false}

	cfg = Config.ReadInt("AutoDisablerLinken", "item_sheepstick", 0) == 1
	AutoDisabler.ItemsLinken[1] = {name="item_sheepstick", enable=cfg, tmi=false}
	cfg = Config.ReadInt("AutoDisablerLinken", "item_bloodthorn", 0) == 1
	AutoDisabler.ItemsLinken[2] = {name="item_bloodthorn", enable=cfg, tmi=false}
	cfg = Config.ReadInt("AutoDisablerLinken", "item_orchid", 0) == 1
	AutoDisabler.ItemsLinken[3] = {name="item_orchid", enable=cfg, tmi=false}
	cfg = Config.ReadInt("AutoDisablerLinken", "item_cyclone", 0) == 1
	AutoDisabler.ItemsLinken[4] = {name="item_cyclone", enable=cfg, tmi=false}
	cfg = Config.ReadInt("AutoDisablerLinken", "item_rod_of_atos", 0) == 1
	AutoDisabler.ItemsLinken[5] = {name="item_rod_of_atos", enable=cfg, tmi=false}
	cfg = Config.ReadInt("AutoDisablerLinken", "item_nullifier", 0) == 1
	AutoDisabler.ItemsLinken[6] = {name="item_nullifier", enable=cfg, tmi=false}
	cfg = Config.ReadInt("AutoDisablerLinken", "item_abyssal_blade", 0) == 1
	AutoDisabler.ItemsLinken[7] = {name="item_abyssal_blade", enable=cfg, tmi=true}
	cfg = Config.ReadInt("AutoDisablerLinken", "item_heavens_halberd", 0) == 1
	AutoDisabler.ItemsLinken[8] = {name="item_heavens_halberd", enable=cfg, tmi=false}
end

AutoDisabler.InitItems()

function AutoDisabler.OnUpdate()
	if not Menu.IsEnabled(AutoDisabler.Enable) then return end
	if not Engine.IsInGame() then return end

	if Menu.IsEnabled(AutoDisabler.OnKeyDisabler) then
		if Menu.IsKeyDownOnce(AutoDisabler.OnKeyDisablerKey) then
			cfg = Config.ReadInt("AutoDisabler", "OnKeyDisablerToggleMode", 0)
			if cfg == 1 then
				Config.WriteInt("AutoDisabler", "OnKeyDisablerToggleMode", 0)
			else
				Config.WriteInt("AutoDisabler", "OnKeyDisablerToggleMode", 1)
			end
			Log.Write(cfg)
		end

		if Menu.IsEnabled(AutoDisabler.OnKeyDisablerToggleMode) then
			if Config.ReadInt("AutoDisabler", "OnKeyDisablerToggleMode", 0) == 1 then
				AutoDisabler.SearchForEnemies(1500)
			end
		else
			if Menu.IsKeyDown(AutoDisabler.OnKeyDisablerKey) then
				AutoDisabler.SearchForEnemies(1500)
			end
		end
	else
		AutoDisabler.SearchForEnemies(1500)
	end
end

function AutoDisabler.SearchForEnemies(range)
	AutoDisabler.Hero = Heroes.GetLocal()
	if not AutoDisabler.Hero then return end
	local enemies = {}
	for _, v in ipairs(AutoDisabler.HeroesInRadius(AutoDisabler.Hero, range, Enum.TeamType.TEAM_ENEMY)) do
		if v and Entity.IsHero(v) and not Entity.IsDormant(v) and not NPC.IsIllusion(v) then
			table.insert(enemies, v)
		end
	end
    table.sort(enemies, function(a, b) return Entity.GetAbsOrigin(a):Distance(Entity.GetAbsOrigin(AutoDisabler.Hero)):Length2D() < Entity.GetAbsOrigin(b):Distance(Entity.GetAbsOrigin(AutoDisabler.Hero)):Length2D() end)
	if Menu.IsEnabled(AutoDisabler.AggressiveMode) then
		AutoDisabler.DisableEnemy(enemies[1])
	else
		--not aggressive mode
	end
end

function AutoDisabler.DisableEnemy(enemy)
	if not AutoDisabler.AlreadyDisabled(enemy) then
		if not AutoDisabler.IsUnselectable(enemy) and not AutoDisabler.IsInvulerable(enemy) then
			if NPC.IsLinkensProtected(enemy) then
				if AutoDisabler.GetEnabledItems() == 1 and AutoDisabler.GetEnabledLinkenItems() == 1 then
					if AutoDisabler.GetEnabledItem().name == AutoDisabler.GetEnabledLinkenItem().name then
						return
					end
				end
				if AutoDisabler.GetEnabledItems() >= 1 and AutoDisabler.GetEnabledLinkenItems() >= 1 then
					local mana = NPC.GetMana(AutoDisabler.Hero)
					for i = 1, tablelength(AutoDisabler.Items) do
						if AutoDisabler.ItemsLinken[i].enable then
							local item = NPC.GetItem(AutoDisabler.Hero, AutoDisabler.ItemsLinken[i].name, true)
							if item then
								if NPC.IsEntityInRange(AutoDisabler.Hero, enemy, Ability.GetCastRange(item) + 100) then
									if Ability.IsCastable(item, mana) then
										if not AutoDisabler.IsMagicImune(enemy) or (AutoDisabler.IsMagicImune(enemy) and AutoDisabler.ItemsLinken[i].tmi) then
											Ability.CastTarget(item, enemy)
											return
										end
									end
								end
							end
						end
					end
				end
			else
				local mana = NPC.GetMana(AutoDisabler.Hero)
				for i = 1, tablelength(AutoDisabler.Items) do
					if AutoDisabler.Items[i].enable then
						local item = NPC.GetItem(AutoDisabler.Hero, AutoDisabler.Items[i].name, true)
						if item then
							if NPC.IsEntityInRange(AutoDisabler.Hero, enemy, Ability.GetCastRange(item) + 100) then
								if Ability.IsCastable(item, mana) then
									if not AutoDisabler.IsMagicImune(enemy) or (AutoDisabler.IsMagicImune(enemy) and AutoDisabler.Items[i].tmi) then
										Ability.CastTarget(item, enemy)
										if not Menu.IsEnabled(AutoDisabler.CastTogether) then return end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function AutoDisabler.OnMenuOptionChange(option, old, new)
	if not Menu.IsEnabled(AutoDisabler.Enable) then return end
end

function AutoDisabler.OnDraw()
	if not Menu.IsEnabled(AutoDisabler.Enable) then return end
	if not Engine.IsInGame() then return end
	AutoDisabler.Hero = Heroes.GetLocal()
	AutoDisabler.DrawDebugText()
	if Menu.IsEnabled(AutoDisabler.ShowItemPanel) then
		AutoDisabler.DrawItemPanel()
	end
end

function AutoDisabler.DrawDebugText()
	x = Menu.GetValue(AutoDisabler.TextBoxX)
	y = Menu.GetValue(AutoDisabler.TextBoxY)
	if Menu.IsEnabled(AutoDisabler.Enable) then
	    Renderer.SetDrawColor(0, 255, 0, 255)
	    Renderer.DrawText(AutoDisabler.Font, x, y, "AutoDisabler: ON")
	else
	    Renderer.SetDrawColor(255, 0, 0, 255)
	    Renderer.DrawText(AutoDisabler.Font, x, y, "AutoDisabler: OFF")
	end

	y = y + 12

	if Menu.IsEnabled(AutoDisabler.AggressiveMode) then
	    Renderer.SetDrawColor(0, 255, 0, 255)
	    Renderer.DrawText(AutoDisabler.Font, x, y, "AggressiveMode: ON")
	else
	    Renderer.SetDrawColor(255, 0, 0, 255)
	    Renderer.DrawText(AutoDisabler.Font, x, y, "AggressiveMode: OFF")
	end

	y = y + 12

	if Menu.IsEnabled(AutoDisabler.CastTogether) then
	    Renderer.SetDrawColor(0, 255, 0, 255)
	    Renderer.DrawText(AutoDisabler.Font, x, y, "CastAllTogether: ON")
	else
	    Renderer.SetDrawColor(255, 0, 0, 255)
	    Renderer.DrawText(AutoDisabler.Font, x, y, "CastAllTogether: OFF")
	end

	y = y + 12

	if Menu.IsEnabled(AutoDisabler.OnKeyDisabler) then
	    Renderer.SetDrawColor(0, 255, 0, 255)
	    Renderer.DrawText(AutoDisabler.Font, x, y, "OnKeyDisabler: ON")
	else
	    Renderer.SetDrawColor(255, 0, 0, 255)
	    Renderer.DrawText(AutoDisabler.Font, x, y, "OnKeyDisabler: OFF")
	end

	y = y + 12

		if Menu.IsEnabled(AutoDisabler.OnKeyDisablerToggleMode) then
			if Config.ReadInt("AutoDisabler", "OnKeyDisablerToggleMode", 0) == 1 then
				Renderer.SetDrawColor(0, 255, 0, 255)
			    Renderer.DrawText(AutoDisabler.Font, x, y, "OnKeyDisabler toggled: true")
			else
			    Renderer.SetDrawColor(255, 0, 0, 255)
			    Renderer.DrawText(AutoDisabler.Font, x, y, "OnKeyDisabler toggled: false")
			end
		else
			if Menu.IsKeyDown(AutoDisabler.OnKeyDisablerKey) then
			    Renderer.SetDrawColor(0, 255, 0, 255)
			    Renderer.DrawText(AutoDisabler.Font, x, y, "OnKeyDisabler key pressed: true")
			else
			    Renderer.SetDrawColor(255, 0, 0, 255)
			    Renderer.DrawText(AutoDisabler.Font, x, y, "OnKeyDisabler key pressed: false")
			end
		end
end

function AutoDisabler.DrawItemPanel()
 	local pos = Entity.GetAbsOrigin(AutoDisabler.Hero)
    local x, y, vis = Renderer.WorldToScreen(pos)
    local w, h = Renderer.GetScreenSize()
    x = Menu.GetValue(AutoDisabler.ItemPanelX)
    y = Menu.GetValue(AutoDisabler.ItemPanelY)
    for i = 1, tablelength(AutoDisabler.Items) do
    	AutoDisabler.DrawItem(AutoDisabler.Items[i].name, x - 60, y, i - 1)
    end
	Renderer.SetDrawColor(0, 255, 0, 255)
	Renderer.DrawText(AutoDisabler.Font, x + 15, y - 27, "Linken")
	Renderer.DrawText(AutoDisabler.Font, x + 15, y - 15, "break")
    for i = 1, tablelength(AutoDisabler.Items) do
    	AutoDisabler.DrawLinkenItem(AutoDisabler.ItemsLinken[i].name, x, y, i - 1)
    end
	
end

function AutoDisabler.DrawItem(item, x, y, index)
	itemname = item:gsub('item_', '', 1)
	local imageHandle = AutoDisabler.ItemCachedIcons[itemname]
    if imageHandle == nil then
        imageHandle = Renderer.LoadImage(AutoDisabler.ItemIconPath .. itemname .. "_png.vtex_c")
        AutoDisabler.ItemCachedIcons[itemname] = imageHandle
    end

    local realY = y + (index * (Menu.GetValue(AutoDisabler.ItemPanelSize) // 1.38))

    local imageColor = { 255, 255, 255 }
    local outlineColor = { 0, 255 , 0 }
    
	cfg = Config.ReadInt("AutoDisabler", item, 0)
    if cfg == 0 then 
    	outlineColor = { 255, 0, 0}
    end

	Renderer.SetDrawColor(imageColor[1], imageColor[2], imageColor[3], 255)
    Renderer.DrawImage(imageHandle, x, realY, Menu.GetValue(AutoDisabler.ItemPanelSize), Menu.GetValue(AutoDisabler.ItemPanelSize) // 1.38)

    Renderer.SetDrawColor(outlineColor[1], outlineColor[2], outlineColor[3], 255)
    Renderer.DrawOutlineRect(x, realY, Menu.GetValue(AutoDisabler.ItemPanelSize), Menu.GetValue(AutoDisabler.ItemPanelSize) // 1.38)
    Renderer.DrawOutlineRect(x + 1, realY + 1, Menu.GetValue(AutoDisabler.ItemPanelSize) - 2, Menu.GetValue(AutoDisabler.ItemPanelSize) // 1.38 - 2)

    local hoveringOver = Input.IsCursorInRect(x, realY, Menu.GetValue(AutoDisabler.ItemPanelSize), Menu.GetValue(AutoDisabler.ItemPanelSize) // 1.38)
	if hoveringOver and Input.IsKeyDown(Enum.ButtonCode.MOUSE_LEFT) then
		if index == AutoDisabler.ItemLastClickindex then

			if os.clock() - AutoDisabler.ClickCooldown > AutoDisabler.ItemLastClickTime then
				if cfg == 0 then
					Config.WriteInt("AutoDisabler", item, 1)
					AutoDisabler.GetItem(item).enable = true
				else
					Config.WriteInt("AutoDisabler", item, 0)
					AutoDisabler.GetItem(item).enable = false
				end
				AutoDisabler.ItemLastClickTime = os.clock()
			end

		else

			if cfg == 0 then
				Config.WriteInt("AutoDisabler", item, 1)
					AutoDisabler.GetItem(item).enable = true
			else
				Config.WriteInt("AutoDisabler", item, 0)
					AutoDisabler.GetItem(item).enable = false
			end
			AutoDisabler.ItemLastClickindex = index
			AutoDisabler.ItemLastClickTime = os.clock()

		end
	end
end

function AutoDisabler.DrawLinkenItem(item, x, y, index)
	itemname = item:gsub('item_', '', 1)
	local imageHandle = AutoDisabler.ItemCachedIcons[itemname]
    if imageHandle == nil then
        imageHandle = Renderer.LoadImage(AutoDisabler.ItemIconPath .. itemname .. "_png.vtex_c")
        AutoDisabler.ItemCachedIcons[itemname] = imageHandle
    end

    local realY = y + (index * (Menu.GetValue(AutoDisabler.ItemPanelSize) // 1.38))

    local imageColor = { 255, 255, 255 }
    local outlineColor = { 0, 255 , 0 }
    
	cfg = Config.ReadInt("AutoDisablerLinken", item, 0)
    if cfg == 0 then 
    	outlineColor = { 255, 0, 0}
    end

	Renderer.SetDrawColor(imageColor[1], imageColor[2], imageColor[3], 255)
    Renderer.DrawImage(imageHandle, x, realY, Menu.GetValue(AutoDisabler.ItemPanelSize), Menu.GetValue(AutoDisabler.ItemPanelSize) // 1.38)

    Renderer.SetDrawColor(outlineColor[1], outlineColor[2], outlineColor[3], 255)
    Renderer.DrawOutlineRect(x, realY, Menu.GetValue(AutoDisabler.ItemPanelSize), Menu.GetValue(AutoDisabler.ItemPanelSize) // 1.38)
    Renderer.DrawOutlineRect(x + 1, realY + 1, Menu.GetValue(AutoDisabler.ItemPanelSize) - 2, Menu.GetValue(AutoDisabler.ItemPanelSize) // 1.38 - 2)

    local hoveringOver = Input.IsCursorInRect(x, realY, Menu.GetValue(AutoDisabler.ItemPanelSize), Menu.GetValue(AutoDisabler.ItemPanelSize) // 1.38)
	if hoveringOver and Input.IsKeyDown(Enum.ButtonCode.MOUSE_LEFT) then
		if index == AutoDisabler.LinkenItemLastClickindex then

			if os.clock() - AutoDisabler.ClickCooldown > AutoDisabler.LinkenItemLastClickTime then
				if cfg == 0 then
					Config.WriteInt("AutoDisablerLinken", item, 1)
					AutoDisabler.GetLinkenItem(item).enable = true
				else
					Config.WriteInt("AutoDisablerLinken", item, 0)
					AutoDisabler.GetLinkenItem(item).enable = false
				end
				AutoDisabler.LinkenItemLastClickTime = os.clock()
			end

		else

			if cfg == 0 then
				Config.WriteInt("AutoDisablerLinken", item, 1)
					AutoDisabler.GetLinkenItem(item).enable = true
			else
				Config.WriteInt("AutoDisablerLinken", item, 0)
					AutoDisabler.GetLinkenItem(item).enable = false
			end
			AutoDisabler.LinkenItemLastClickindex = index
			AutoDisabler.LinkenItemLastClickTime = os.clock()

		end
	end
end


return AutoDisabler
