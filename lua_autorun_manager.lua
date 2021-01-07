local lua_gb_ref = gui.Reference("Settings", "Lua scripts", "Manage scripts")
local lua_listbox = gui.Reference("Settings", "Lua scripts", "Manage scripts", "")
lua_listbox:SetHeight(250)

local real_set_as_autorun = gui.Reference("Settings", "Lua scripts", "Manage scripts", "Set As Autorun")
local real_unload_btn = gui.Reference("Settings", "Lua scripts", "Manage scripts", "Unload")
local real_reset_lua_state_btn = gui.Reference("Settings", "Lua scripts", "Manage scripts", "Reset Lua State")
real_unload_btn:SetInvisible(true)
real_set_as_autorun:SetInvisible(true)
real_reset_lua_state_btn:SetDisabled(true)

local function split(inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end


local function get_autorun_scripts()
	local autorun_files = {}
	local contents = file.Read("autorun.lua")
	for k, v in pairs(split(contents, "\n")) do
		table.insert(autorun_files, string.match(v, [['([^']+)]]))
	end
	return autorun_files
end

local function get_all_scripts()
	local all_scripts = {}
	file.Enumerate(function(filename)
		if string.match(filename, ".lua") then
			table.insert(all_scripts, filename)
		end
	end)
	return all_scripts
end

local lua_autorun_scripts = gui.Listbox(gui.Reference("Settings", "Lua scripts", "Manage scripts"), "lua.autorun.scripts", 50, unpack(get_autorun_scripts()))
lua_autorun_scripts:SetPosY(260)
lua_autorun_scripts:SetWidth(280)
lua_autorun_scripts:SetHeight(145)


local function add_to_autorun()
	local all_scripts = get_all_scripts()
	local selected_file = all_scripts[lua_listbox:GetValue() + 1]
	
	local autorun_files = get_autorun_scripts()
	table.insert(autorun_files, selected_file)
	
	local new_autorun_files = ""
	for k, v in pairs(autorun_files) do
		new_autorun_files = new_autorun_files .. "LoadScript('" .. v .. "');\n"
	end
	
	file.Write("autorun.lua", new_autorun_files)
	lua_autorun_scripts:SetOptions(unpack(get_auto_scripts()))
end

local function remove_from_atuorun()
	local autorun_files = get_auto_scripts()
	local selected_file = autorun_files[lua_autorun_scripts:GetValue() + 1]
	
	local new_autorun_files = ''
	for k, v in pairs(autorun_files) do
		if v ~= selected_file then
			new_autorun_files = new_autorun_files .. "LoadScript('" .. v .. "');\n"
		end
	end
	
	file.Write("autorun.lua", new_autorun_files)
	lua_autorun_scripts:SetOptions(unpack(get_autorun_scripts()))
end

local function unload_script()
	-- Have to remake the unload script functionality. If we unload a script that created a gui.Listbox inside the "manage script" groupbox, it will crash CSGO........
	-- so we must remove the listbox before unloading
	local all_scripts = get_all_scripts()
	local selected_file = all_scripts[lua_listbox:GetValue() + 1]
	
	if selected_file == GetScriptName() then
		lua_autorun_scripts:Remove()
		real_unload_btn:SetInvisible(false)
		real_set_as_autorun:SetInvisible(false)
		real_reset_lua_state_btn:SetDisabled(false)
	end
	UnloadScript(selected_file)
end


local add_to_autorun_btn = gui.Button(lua_gb_ref, "Add to autorun", add_to_autorun)
add_to_autorun_btn:SetPosX(297)
add_to_autorun_btn:SetPosY(316)
add_to_autorun_btn:SetWidth(135)
add_to_autorun_btn:SetHeight(28)

local remove_from_autorun_btn = gui.Button(lua_gb_ref, "Remove from autorun", remove_from_atuorun)
remove_from_autorun_btn:SetPosX(440)
remove_from_autorun_btn:SetPosY(316)
remove_from_autorun_btn:SetWidth(135)
remove_from_autorun_btn:SetHeight(28)

local unload_btn = gui.Button(lua_gb_ref, "Unload", unload_script)
unload_btn:SetPosX(440)
unload_btn:SetPosY(160)
unload_btn:SetWidth(136)
unload_btn:SetHeight(28)
