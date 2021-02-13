local json_lib_installed = false
file.Enumerate(function(filename)
	if filename == "libraries/json.lua" then
		json_lib_installed = true
	end
end)

if not json_lib_installed then
	local body = http.Get("https://raw.githubusercontent.com/Aimware0/aimware_scripts/main/libraries/json.lua")
	file.Write("libraries/json.lua", body)
end

RunScript("libraries/json.lua")

function file.Exists(file_name)
  local exists = false
  file.Enumerate(function(_name)
    if file_name == _name then
      exists = true
    end
  end)
  return exists
end


local file_name = "ChickenWalkBot.txt"
if not file.Exists(file_name) or string.len(file.Read(file_name)) <= 1 then
	file.Write(file_name, "[]")
end


local ChickenWalkBot = {}

local wb_tab = gui.Window("Chicken.WalkBot", "Chicken's walk bot", 15, 15, 500, 600 )

local wb_config_gb = gui.Groupbox(wb_tab, "Config", 15, 15, 470, 0)

local function get_saved_walkbot_names()
	local names = {}
	local contents = json.decode(file.Read(file_name))
	
	for k, v in pairs(contents) do
		table.insert(names, k)
	end
	
	return names
end

local function get_saved_walkbot_data(index)
	local contents = json.decode(file.Read(file_name))

	local i = 0
	for k, v in pairs(contents) do
		if i == index then
			return v or {}
		end
		i = i + 1
	end
end


local wb_config_selector = gui.Combobox(wb_config_gb, "Chicken.WalkBot.Config.Selection", "Walkbot config", unpack(get_saved_walkbot_names()) or "")
wb_config_selector:SetOptions(unpack(get_saved_walkbot_names()))
local wb_config_entry = gui.Editbox(wb_config_gb, "Chicken.WalkBot.Config.name", "Config name")


local wb_save_btn = gui.Button(wb_config_gb, "Save", function()
	local contents = json.decode(file.Read(file_name))
	if not contents[wb_config_entry:GetValue()] then
		contents[wb_config_entry:GetValue()] = ChickenWalkBot.walk_data
		file.Write(file_name, json.encode(contents))
		
		local saved_walkbot_names = get_saved_walkbot_names()
		wb_config_selector:SetOptions(unpack(saved_walkbot_names))
		wb_config_selector:SetValue(#saved_walkbot_names - 1)
		wb_config_entry:SetValue("")
	end
end)


local wb_settings_gb = gui.Groupbox(wb_tab, "WalkbotShit", 15, 230, 470, 0)
local ui_text = {}

local wb_play_btn = gui.Button(wb_settings_gb, "", function()
	ChickenWalkBot.is_playing = not ChickenWalkBot.is_playing
	ChickenWalkBot.is_recording = false
	
	ui_text.wb_record_text:SetText(ChickenWalkBot.is_recording and "Stop recording" or "Start recording")
	ui_text.wb_play_text:SetText(ChickenWalkBot.is_playing and "Stop playing" or "Start playing")
end)
wb_play_btn:SetPosX(0)

ui_text.wb_play_text = gui.Text(wb_settings_gb, "Start playing")
ui_text.wb_play_text:SetPosY(12)
ui_text.wb_play_text:SetPosX(33)


local wb_record_btn = gui.Button(wb_settings_gb, "", function()
	ChickenWalkBot.is_recording = not ChickenWalkBot.is_recording
	ChickenWalkBot.is_playing = false
	
	if ChickenWalkBot.is_recording then
		ChickenWalkBot.walk_data = {}
	end
	
	ui_text.wb_record_text:SetText(ChickenWalkBot.is_recording and "Stop recording" or "Start recording")
	ui_text.wb_play_text:SetText(ChickenWalkBot.is_playing and "Stop playing" or "Start playing")
end)
wb_record_btn:SetPosX(0)
ui_text.wb_record_text = gui.Text(wb_settings_gb, "Start recording")
ui_text.wb_record_text:SetPosY(53)
ui_text.wb_record_text:SetPosX(29)


local wb_defualt_speed = gui.Slider(wb_settings_gb, "Chicken.Walkbot.defualtspeed", "Default walk speed", 250, 1, 300)
local wb_aimbot_speed = gui.Slider(wb_settings_gb, "Chicken.Walkbot.aimbotspeed", "Walk speed when aimbotting", 36, 1, 300)
local wb_step_size = gui.Slider(wb_settings_gb, "Chicken.Walkbot.stepsize", "Stepsize", 20, 5, 200)
wb_step_size:SetDescription("When recording, this sets the distance you need to be from point 1 from point 2.")

local wb_to_nearest_point_on_death = gui.Checkbox(wb_settings_gb, "Chicken.WalkBot.walk_to_nearest_point_on_death", "Walk to nearest point on respawn.", true)
wb_to_nearest_point_on_death:SetDescription("Walks to the nearest walk bot location when you respawn")


local function table_to_v3(tbl)
	return Vector3(tbl.x, tbl.y, tbl.z)
end

local has_target = false


callbacks.Register("AimbotTarget", function(t)
	has_target = t:GetIndex() or false
end)

ChickenWalkBot = {	
	is_recording = false,
	step_size = 10,

	is_playing = false,
	play_index = 1,
	
	defualt_speed = 255,
	aimbot_speed = 32,
	
	walk_data = {},

	
	record = function(self, pos)
		if self.is_recording and not self.is_playing then
			local my_pos = entities.GetLocalPlayer():GetAbsOrigin()
			if #self.walk_data > 0 then
				local dist = vector.Distance({self.walk_data[#self.walk_data].x, self.walk_data[#self.walk_data].y, self.walk_data[#self.walk_data].z}, {my_pos.x, my_pos.y, my_pos.z})
				if dist >= self.step_size - 2 then
					table.insert(self.walk_data, {x = my_pos.x, y = my_pos.y, z = my_pos.z})
				end
			else
				table.insert(self.walk_data, {x = my_pos.x, y = my_pos.y, z = my_pos.z})
			end
		end
	end,
	
	play = function(self, cmd)
		
		if self.is_playing and not self.is_recording then
			if self.play_index >= #self.walk_data then
				self.play_index = 1
			end
			print(self.play_index)
			local my_pos = entities.GetLocalPlayer():GetAbsOrigin()
			self.move_to_pos(table_to_v3(self.walk_data[self.play_index]), cmd, has_target and self.aimbot_speed or self.defualt_speed)
			local dist = math.sqrt(math.pow(self.walk_data[self.play_index].x - my_pos.x, 2) + math.pow(self.walk_data[self.play_index].y - my_pos.y, 2))
			if dist <= 10 or dist - (self.walk_data[self.play_index].z - my_pos.z) < 5  then
				self.play_index = self.play_index + 1
			end
		end
	end,
		
	get_nearest_point = function(self)
		local closest_dist = math.huge
		local closest_point = nil
		local closest_point_index = 1
		local my_pos = entities.GetLocalPlayer():GetAbsOrigin()
		
		for i, v in ipairs(self.walk_data) do
			-- print(v.x)
			local dist = vector.Distance({v.x, v.y, v.z}, {my_pos.x, my_pos.y, my_pos.z})
			if dist < closest_dist then
				closest_dist = dist
				closest_point_index = i
				closest_point = v
			end
		end
		
		return closest_point, closest_point_index
	end,
	
	open = function() end,
	
	draw = function(self)
		local s_w, s_h = draw.GetScreenSize()
		if #self.walk_data ~= 0 then
			local x,y = client.WorldToScreen(table_to_v3(self.walk_data[1]))
			draw.Color(0,255,0)
			draw.Text(x,y, "Start")
		end
		
		for i=1, #self.walk_data do
			if self.walk_data[i + 1] then
				
				local x,y = client.WorldToScreen(table_to_v3(self.walk_data[i]))
				local x2,y2 = client.WorldToScreen(table_to_v3(self.walk_data[i + 1]))
				
				if x and y and x2 and y2 then
					draw.Color(255,0,0)
					draw.Line(x, y, x2, y2)
				end	
			end
		end
		
		draw.Color(255,255,255)
		if self.is_recording then
			draw.Text(15, s_h / 2, "Recording")
		elseif self.is_playing then
			draw.Text(15, s_h / 2, "Playing")
		else
			draw.Text(15, s_h / 2, "Idle")
		end
	end,
	
	move_to_pos = function(pos, cmd, speed) -- not mine I think shadyretards?
		local LocalPlayer = entities.GetLocalPlayer()
		local angle_to_target = (pos - entities.GetLocalPlayer():GetAbsOrigin()):Angles()
		local my_pos = LocalPlayer:GetAbsOrigin()
		
		cmd.forwardmove = math.cos(math.rad((engine:GetViewAngles() - angle_to_target).y)) * speed
		cmd.sidemove = math.sin(math.rad((engine:GetViewAngles() - angle_to_target).y)) * speed
	end
}
local AW_MENU = gui.Reference("MENU")

local Owb_config_selector = -1
function UI_shit()
	wb_tab:SetActive(AW_MENU:IsActive())
	wb_play_btn:SetDisabled(#ChickenWalkBot.walk_data == 0)
	wb_config_selector:SetDisabled(ChickenWalkBot.is_playing)
	
	if Owb_config_selector ~= wb_config_selector:GetValue() then
		ChickenWalkBot.walk_data = get_saved_walkbot_data(wb_config_selector:GetValue()) or {}

		Owb_config_selector = wb_config_selector:GetValue()
	end
end
local alive_time = 0
local scoped = false
callbacks.Register("Draw", function()
	ChickenWalkBot.defualt_speed = wb_defualt_speed:GetValue()
	ChickenWalkBot.aimbot_speed = wb_aimbot_speed:GetValue()
	ChickenWalkBot.step_size = wb_step_size:GetValue()
	
	ChickenWalkBot:record()
	ChickenWalkBot:draw()
	UI_shit()
	
	
end)

callbacks.Register("CreateMove", function(cmd)
	ChickenWalkBot:play(cmd)
	if globals.CurTime() > alive_time + 1.5 and not scoped then
		cmd.buttons = bit.bor(cmd.buttons, 2048)
		scoped = true
	end
end)

local me_spawned = false
local me_spawned_time = globals.CurTime()
client.AllowListener("player_spawn")
callbacks.Register("FireGameEvent", function(e)
	if e and e:GetName() == "player_spawn" then
		local dead_guy = client.GetPlayerIndexByUserID(e:GetInt("userid"))
		if client.GetLocalPlayerIndex() == dead_guy then 
			alive_time = globals.CurTime()
			scoped = false
			
			if wb_to_nearest_point_on_death:GetValue() then
				me_spawned = true
				me_spawned_time = globals.CurTime()
			else
				ChickenWalkBot.play_index = 1
			end

		end
	end
end)

callbacks.Register("Draw", function()
	if me_spawned and globals.CurTime() > me_spawned_time + 0.5 then
		local _, closest_point_index = ChickenWalkBot:get_nearest_point()
		ChickenWalkBot.play_index = closest_point_index
		me_spawned = false
	end
end)


