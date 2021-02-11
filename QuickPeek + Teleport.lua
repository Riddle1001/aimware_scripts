--AW AutoUpdate
--version 1.164

local function split(s)
    local t = {}
    for chunk in string.gmatch(s, "[^\n\r]+") do
        t[#t+1] = chunk
    end
    return t
end

local should_unload = false

local function AutoUpdate(link, already_updated_text, downloading_update_text)
	local web_content = http.Get(link)
	local web_content_split = split(web_content)
	local has_autoupdate_sig = web_content_split[1] == "--AW AutoUpdate"
	
	if has_autoupdate_sig then
		local file_content_split = split(file.Read(GetScriptName()))
		if file_content_split[2] == web_content_split[2] then
			print(already_updated_text)
		else
			print(downloading_update_text)
			file.Write(GetScriptName(), web_content)
			should_unload = true -- UnloadScript only works within callbacks
		end
	else
		error("Didn't find 'AW AutoUpdate' signature in '" .. link .. "'")
	end
end

	
callbacks.Register("Draw", function()
	if should_unload then
		UnloadScript(GetScriptName()) -- UnloadScript only works within callbacks, and can't unregister callbacks from within a callback
	end
end)

AutoUpdate("https://raw.githubusercontent.com/Aimware0/aimware_scripts/main/QuickPeek%20%2B%20Teleport.lua",
	"QuickPeek + Teleport is fully up to date",
	"QuickPeek + Teleport has been updated, reload the lua.")
	

local function render(pos, radius, color) -- thx Cheeseot for saving everyone using this script 40~ fps!
	local center = {client.WorldToScreen(Vector3(pos.x, pos.y, pos.z)) }
	for degrees = 1, 20, 1 do
        
        local cur_point = nil;
        local old_point = nil;

        if pos.z == nil then
            cur_point = {pos.x + math.sin(math.rad(degrees * 18)) * radius, pos.y + math.cos(math.rad(degrees * 18)) * radius};    
            old_point = {pos.x + math.sin(math.rad(degrees * 18 - 18)) * radius, pos.y + math.cos(math.rad(degrees * 18 - 18)) * radius};
        else
            cur_point = {client.WorldToScreen(Vector3(pos.x + math.sin(math.rad(degrees * 18)) * radius, pos.y + math.cos(math.rad(degrees * 18)) * radius, pos.z))};
            old_point = {client.WorldToScreen(Vector3(pos.x + math.sin(math.rad(degrees * 18 - 18)) * radius, pos.y + math.cos(math.rad(degrees * 18 - 18)) * radius, pos.z))};
        end
                    
        if cur_point[1] ~= nil and cur_point[2] ~= nil and old_point[1] ~= nil and old_point[2] ~= nil and center[1] ~= nil and center [2] ~= nil then        
            -- fill
            draw.Color(color.r, color.g, color.b, color.a)
            draw.Triangle(cur_point[1], cur_point[2], old_point[1], old_point[2], center[1], center[2])
            -- outline
            -- draw.Color(ui_color_picker:GetValue())
            draw.Line(cur_point[1], cur_point[2], old_point[1], old_point[2]);        
        end
       
    end
end

function move_to_pos(pos, cmd, speed)
	local LocalPlayer = entities.GetLocalPlayer()
	local angle_to_target = (pos - entities.GetLocalPlayer():GetAbsOrigin()):Angles()
	
    cmd.forwardmove = math.cos(math.rad((engine:GetViewAngles() - angle_to_target).y)) * speed
    cmd.sidemove = math.sin(math.rad((engine:GetViewAngles() - angle_to_target).y)) * speed
end

local quickpeek_tab = gui.Tab(gui.Reference("Ragebot"), "Chicken.quickpeek.tab", "Quick peek")
local quickpeek_gb = gui.Groupbox(quickpeek_tab, "Quickpeek", 15, 15, 605, 0)

local quickpeek_enable = gui.Checkbox(quickpeek_gb, "Chicken.quickpeek.enable", "Enable", false)

local quickpeek_method = gui.Combobox(quickpeek_gb, "Chicken.quickpeek.method", "Method", "Slower (reliable)", "Faster (unreliable)")
local quickpeek_return_pos = gui.Combobox(quickpeek_gb, "Chicken.quickpeek.toggle", "Return position", "Hold", "Toggle")
local quickpeek_key = gui.Keybox(quickpeek_gb, "Chicken.quickpeek.key", "Quick peek key", 5)
quickpeek_key:SetWidth(1145)
-- local quickpeek_clear_key = gui.Keybox(quickpeek_gb, "Chicken.quickpeek.clear", "Clear quick peek key", 6)
-- quickpeek_clear_key:SetPosX(290)
-- quickpeek_clear_key:SetPosY(148)

local quickpeek_teleport = gui.Checkbox(quickpeek_gb, "Chicken.quickpeek.teleport.enable", "Teleport on peek", false)

local quickpeek_teleport_speedburst_quickpeek_key  = gui.Checkbox(quickpeek_gb, "Chicken.quickpeek.teleport.only_when_peek", "Only enable speedburst when QuickPeek key is pressed", false)
quickpeek_teleport_speedburst_quickpeek_key:SetDescription("Allows fakelag while QuickPeek key is not pressed.")

local quickpeek_teleport_speedburst_disable_on_return = gui.Checkbox(quickpeek_gb, "Chicken.quickpeek.teleport.disable_on_return", "Disable speedburst when returning to peek position", false)
quickpeek_teleport_speedburst_disable_on_return:SetDescription("Disables speedburst when returning to peek position")

local quickpeek_teleport_maxusrcmdprocessticks = gui.Slider(quickpeek_gb, "Chicken.quickpeek.teleport.", "sv_maxusrcmdprocessticks", 16	, 0, 62)
quickpeek_teleport_maxusrcmdprocessticks:SetDescription("Adjusting this value may have different effects on teleporting. I use 13.")

local max_ticks = gui.Reference("Misc", "General", "Server", "sv_maxusrcmdprocessticks")


-- caching to reset settings when unloading
local cached_real_max_ticks = max_ticks:GetValue()
local cached_speedburst_key = gui.GetValue("misc.speedburst.key")

local is_peeking = false
local should_return = false
local return_pos = nil

local target = nil
local speedburst_enable = false
local weapon_fired = false

-- Logic
callbacks.Register("Draw", function()
	local localplayer = entities.GetLocalPlayer()
	
	if not localplayer or not localplayer:IsAlive() then
		is_peeking = false
		should_return = false
		return_pos = nil
		weapon_fired = false
		return
	end
	
	local weapon = localplayer:GetPropEntity("m_hActiveWeapon")
	
	if not quickpeek_enable:GetValue() then -- or (weapon:GetWeaponID() ~= 40 and weapon:GetWeaponID() ~= 9) then
		max_ticks:SetValue(cached_real_max_ticks)
		gui.SetValue("misc.speedburst.key", cached_speedburst_key)
		should_return = false
	end
	

	
	if quickpeek_key:GetValue() and quickpeek_return_pos:GetValue() == 0 and input.IsButtonPressed(quickpeek_key:GetValue()) then
		is_peeking = true
		return_pos = localplayer:GetAbsOrigin()
		weapon_fired = false
	end
	
	if quickpeek_return_pos:GetValue() == 0 and quickpeek_key:GetValue() and input.IsButtonReleased(quickpeek_key:GetValue()) then -- Hold selected and quickpeek key released
		is_peeking = false
		should_return = false
		weapon_fired = false
	end
	
	-- print(quickpeek_return_pos:GetValue(), input.IsButtonPressed(quickpeek_key:GetValue()))
	if quickpeek_return_pos:GetValue() == 1 and input.IsButtonPressed(quickpeek_key:GetValue()) then -- Toggle selected
		print(1)
		if return_pos then
			is_peeking = false
			should_return = false
			return_pos = nil
			weapon_fired = false
		else
			is_peeking = true
			return_pos = localplayer:GetAbsOrigin()
			weapon_fired = false
		end
		
	end
	

	if is_peeking and return_pos then
		if should_return then
			render(return_pos, 12, {r = 200, g = 240, b = 200, a = 200})
		else
			render(return_pos, 12, {r = 240, g = 200, b = 200, a = 200})
		end
	end
	
	if should_return then
		cheat.RequestSpeedBurst()
	end
end)



callbacks.Register("AimbotTarget", function(t)

	local localplayer = entities.GetLocalPlayer()
	local weapon = localplayer:GetPropEntity("m_hActiveWeapon")
	
	if not quickpeek_enable:GetValue() then return end--or (weapon:GetWeaponID() ~= 40 and weapon:GetWeaponID() ~= 9) then return end

	if quickpeek_method:GetValue() == 1 and t:GetIndex() and is_peeking then
		should_return = true
	end
end)

local weapon_fired_at = 0
callbacks.Register("CreateMove", function(cmd)
	local localplayer = entities.GetLocalPlayer()
	local weapon = localplayer:GetPropEntity("m_hActiveWeapon")
	
	if not quickpeek_enable:GetValue() then return end -- or (weapon:GetWeaponID() ~= 40 and weapon:GetWeaponID() ~= 9) then return end
	
	
	if cmd.buttons == 4194305 then
		weapon_fired = true
		if quickpeek_method:GetValue() == 0 and is_peeking then
			should_return = true
			weapon_fired_at = globals.TickCount()
		end

	end
	
	if should_return and return_pos then
		move_to_pos(return_pos, cmd, 1000)
		
		
		local my_pos = localplayer:GetAbsOrigin()
		local dist = vector.Distance({my_pos.x, my_pos.y, my_pos.z}, {return_pos.x, return_pos.y, return_pos.z})
		if dist < 5 then
			should_return = false
			weapon_fired = false
			if quickpeek_return_pos:GetValue() == 0 then
				return_pos = nil
				
			end
		end
	end
end)

-- UI
local menu = gui.Reference("Menu")
callbacks.Register("Draw", function()
	
	if menu:IsActive() then -- thx Cheesot
		-- Set visibility if quickpeek is enabled
		quickpeek_method:SetInvisible(not quickpeek_enable:GetValue())
		quickpeek_return_pos:SetInvisible(not quickpeek_enable:GetValue())
		quickpeek_key:SetInvisible(not quickpeek_enable:GetValue())
		-- quickpeek_clear_key:SetInvisible(not quickpeek_enable:GetValue())
		quickpeek_teleport:SetInvisible(not quickpeek_enable:GetValue())
		quickpeek_teleport_maxusrcmdprocessticks:SetInvisible(not quickpeek_enable:GetValue())
		-- quickpeek_clear_key:SetDisabled(quickpeek_return_pos:GetValue() == 0 and true)
		
		-- Set visibility to maxusrcmdprocessesticks and speedburst on quickpeek key, if teleport on peek enbaled
		quickpeek_teleport_maxusrcmdprocessticks:SetInvisible(not quickpeek_enable:GetValue() or not quickpeek_teleport:GetValue())
		quickpeek_teleport_speedburst_quickpeek_key:SetInvisible(not quickpeek_enable:GetValue() or not quickpeek_teleport:GetValue())
	end
	
	
	-- Enable speedburst if quickpeek teleport is enabled
	-- local enable_speedburst = not weapon_fired and quickpeek_teleport:GetValue() and -- Checks if weapon was fired AND teleport on quickpeek is enabled
	-- (quickpeek_teleport_speedburst_quickpeek_key:GetValue() and input.IsButtonDown(quickpeek_key:GetValue())) or -- Checks if only enable speedburst on quickpeek key check box is enabled AND quickpeek key is down
	-- not should_return and quickpeek_teleport:GetValue() and not quickpeek_teleport_speedburst_quickpeek_key:GetValue() -- Checks if should_return is false and teleport on quick peek is enabled AND 
	
	local enable_speedburst = false -- I can't be arsed trying to make this a ternary operator type thing again, to hard to read
	if quickpeek_teleport:GetValue() then
		enable_speedburst = true
		
		if quickpeek_teleport_speedburst_quickpeek_key:GetValue() then
			enable_speedburst = input.IsButtonDown(quickpeek_key:GetValue())
		end
		
		if quickpeek_teleport_speedburst_disable_on_return:GetValue() and should_return and weapon_fired then
			if globals.TickCount() - weapon_fired_at >= 5 then -- Needs before shutting off speedburst otherwise speedburst wont activate
				enable_speedburst = false
			end
		end
	end
	
	gui.SetValue("misc.speedburst.enable", enable_speedburst)
	gui.SetValue("misc.speedburst.indicator", enable_speedburst)
	
	max_ticks:SetValue(quickpeek_teleport:GetValue() and quickpeek_teleport_maxusrcmdprocessticks:GetValue() or 16)

end)



callbacks.Register("Unload", "Chicken.QuickPeek.Unload", function()
	max_ticks:SetValue(cached_real_max_ticks)
	gui.SetValue("misc.speedburst.key", cached_speedburst_key)
end)
