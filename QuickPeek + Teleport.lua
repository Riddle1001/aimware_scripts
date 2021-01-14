--AW AutoUpdate
--version 1.12

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
	-- print(web_content)
	local has_autoupdate_sig = web_content_split[1] == "--AW AutoUpdate"
	
	if has_autoupdate_sig then
		local file_content_split = split(file.Read(GetScriptName()))
		if file_content_split[2] == web_content_split[2] then
			print(string.len(already_updated_text) ~= 0 and already_updated_text)
		else
			print(string.len(downloading_update_text) ~= 0 and downloading_update_text)
			file.Write(GetScriptName(), web_content)
			should_unload = true -- UnloadScript only works within callbacks
		end
	else
		error("Didn't find 'AW AutoUpdate' signature in '" .. link .. "'")
	end
end
AutoUpdate("https://raw.githubusercontent.com/Aimware0/aimware_scripts/main/QuickPeek%20%2B%20Teleport.lua",
	"QuickPeek + Teleport is fully up to date",
	"QuickPeek + Teleport has been updated, reload the lua.")
	
callbacks.Register("Draw", function()
	if should_unload then
		UnloadScript(GetScriptName()) -- UnloadScript only works within callbacks, and can't unregister callbacks from within a callback
	end
end)
	
local function render(pos, radius)
	local center = {client.WorldToScreen(Vector3(pos.x, pos.y, pos.z)) }
	for degrees = 1, 360, 1 do

		local cur_point = nil;
		local old_point = nil;

		if pos.z == nil then
			cur_point = {pos.x + math.sin(math.rad(degrees)) * radius, pos.y + math.cos(math.rad(degrees)) * radius}; 
			old_point = {pos.x + math.sin(math.rad(degrees - 1)) * radius, pos.y + math.cos(math.rad(degrees - 1)) * radius};
		else
			cur_point = {client.WorldToScreen(Vector3(pos.x + math.sin(math.rad(degrees)) * radius, pos.y + math.cos(math.rad(degrees)) * radius, pos.z))};
			old_point = {client.WorldToScreen(Vector3(pos.x + math.sin(math.rad(degrees - 1)) * radius, pos.y + math.cos(math.rad(degrees - 1)) * radius, pos.z))};
		end

		if cur_point[1] and cur_point[2] and old_point[1] and old_point[2] and center[1] and center[2] then 
			-- fill
			draw.Color(255,255,255, 200)

			draw.Triangle(cur_point[1], cur_point[2], old_point[1], old_point[2], center[1], center[2])
			-- outline
			-- draw.Color(255,0,0)
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
local quickpeek_clear_key = gui.Keybox(quickpeek_gb, "Chicken.quickpeek.clear", "Clear quick peek key", 6)
quickpeek_clear_key:SetPosX(290)
quickpeek_clear_key:SetPosY(148)

local quickpeek_teleport = gui.Checkbox(quickpeek_gb, "Chicken.quickpeek.teleport.enable", "Teleport on peek", false)
local quickpeek_teleport_speedburst_quickpeek_key  = gui.Checkbox(quickpeek_gb, "Chicken.quickpeek.teleport.enable", "Only enable speedburst when QuickPeek key is pressed", false)
quickpeek_teleport_speedburst_quickpeek_key:SetDescription("Allows fakelag while QuickPeek key is not pressed.")
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

-- Logic
callbacks.Register("Draw", function()
	local localplayer = entities.GetLocalPlayer()
	
	if not localplayer or not localplayer:IsAlive() then
		is_peeking = false
		should_return = false
		return_pos = nil
		return
	end
	
	local weapon = localplayer:GetPropEntity("m_hActiveWeapon")
	
	if not quickpeek_enable:GetValue() then -- or (weapon:GetWeaponID() ~= 40 and weapon:GetWeaponID() ~= 9) then
		max_ticks:SetValue(cached_real_max_ticks)
		gui.SetValue("misc.speedburst.key", cached_speedburst_key)
		should_return = false
	end
	

	
	if quickpeek_key:GetValue() and input.IsButtonPressed(quickpeek_key:GetValue()) then
		is_peeking = true
		return_pos = localplayer:GetAbsOrigin()
	end
	
	if quickpeek_return_pos:GetValue() == 0 and input.IsButtonReleased(quickpeek_key:GetValue() or 0) then -- Toggle selected and quickpeek key pressed
		is_peeking = false
	end
	

	if is_peeking and return_pos then
		render(return_pos, 12)
	end
	
	if should_return then
		local mov_key = 0
		if input.IsButtonDown("W") then
		   mov_key = 87
		elseif input.IsButtonDown("A") then
			mov_key = 65
		elseif input.IsButtonDown("S") then
			mov_key = 83
		elseif input.IsButtonDown("D") then
			mov_key = 68
		end
		gui.SetValue("misc.speedburst.key", mov_key)
	else
		gui.SetValue("misc.speedburst.key", cached_speedburst_key)
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


callbacks.Register("CreateMove", function(cmd)
	local localplayer = entities.GetLocalPlayer()
	local weapon = localplayer:GetPropEntity("m_hActiveWeapon")
	
	if not quickpeek_enable:GetValue() then return end -- or (weapon:GetWeaponID() ~= 40 and weapon:GetWeaponID() ~= 9) then return end
	
	
	if quickpeek_method:GetValue() == 0 and cmd.buttons == 4194305 and is_peeking then
		should_return = true
	end
	
	if should_return and return_pos then
		move_to_pos(return_pos, cmd, 1000)
		
		
		local my_pos = localplayer:GetAbsOrigin()
		local dist = vector.Distance({my_pos.x, my_pos.y, my_pos.z}, {return_pos.x, return_pos.y, return_pos.z})
		if dist < 5 then
			should_return = false
			
			if quickpeek_return_pos:GetValue() == 0 then
				return_pos = nil		
			end
		end
	end
end)

-- UI
callbacks.Register("Draw", function()

	-- Set visibility if quickpeek is enabled
	quickpeek_method:SetInvisible(not quickpeek_enable:GetValue())
	quickpeek_return_pos:SetInvisible(not quickpeek_enable:GetValue())
	quickpeek_key:SetInvisible(not quickpeek_enable:GetValue())
	quickpeek_clear_key:SetInvisible(not quickpeek_enable:GetValue())
	quickpeek_teleport:SetInvisible(not quickpeek_enable:GetValue())
	quickpeek_teleport_maxusrcmdprocessticks:SetInvisible(not quickpeek_enable:GetValue())
	quickpeek_clear_key:SetDisabled(quickpeek_return_pos:GetValue() == 0 and true)
	
	-- Set visibility to maxusrcmdprocessesticks and speedburst on quickpeek key, if teleport on peek enbaled
	quickpeek_teleport_maxusrcmdprocessticks:SetInvisible(not quickpeek_enable:GetValue() or not quickpeek_teleport:GetValue())
	quickpeek_teleport_speedburst_quickpeek_key:SetInvisible(not quickpeek_enable:GetValue() or not quickpeek_teleport:GetValue())
	
	-- Enable speedburst if quickpeek teleport is enabled
	
	gui.SetValue("misc.speedburst.enable", quickpeek_teleport:GetValue() and quickpeek_teleport_speedburst_quickpeek_key:GetValue() and input.IsButtonDown(quickpeek_key:GetValue()) or quickpeek_enable:GetValue() and not  quickpeek_teleport_speedburst_quickpeek_key:GetValue())
	gui.SetValue("misc.speedburst.indicator", quickpeek_teleport:GetValue())

	
	quickpeek_method:SetDisabled(quickpeek_teleport:GetValue())
	if quickpeek_teleport:GetValue() then
		quickpeek_method:SetValue(1)
	end
	
	-- if localplayer and localplayer:GetPropEntity("m_hActiveWeapon"):GetWeaponID() == 40 or localplayer:GetPropEntity("m_hActiveWeapon"):GetWeaponID() == 9 then
	-- local localplayer = entities.GetLocalPlayer()
		max_ticks:SetValue(quickpeek_teleport:GetValue() and quickpeek_teleport_maxusrcmdprocessticks:GetValue() or 16)
	-- else
		-- max_ticks:SetValue(cached_real_max_ticks)
	-- end
end)

callbacks.Register("Unload", "Chicken.QuickPeek.Unload", function()
	max_ticks:SetValue(cached_real_max_ticks)
	gui.SetValue("misc.speedburst.key", cached_speedburst_key)
end)
