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


local notify_lib_installed = false

file.Enumerate(function(filename)
	if filename == "libraries/chickens_notfication.lua" then
		notify_lib_installed = true
	end
end)

if not notify_lib_installed then
	local body = http.Get("https://raw.githubusercontent.com/Aimware0/aimware_scripts/main/libraries/chickens_notfication.lua")
	file.Write("libraries/chickens_notfication.lua", body)
end

RunScript("libraries/chickens_notfication.lua")

function file.Exists(file_name)
  local exists = false
  file.Enumerate(function(_name)
    if file_name == _name then
      exists = true
    end
  end)
  return exists
end

function file.Contents(file_name)
  local f = file.Open(file_name, "r")
  local contents = f:Read()
  f:Close()
  return contents
end

local function replace(str, what, with)
    what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") -- escape pattern
    with = string.gsub(with, "[%%]", "%%%%") -- escape replacement
    return string.gsub(str, what, with)
end

local function tbl_length(tbl)
	local length = 0
	for k, v in pairs(tbl) do
		length = length + 1
	end
	return length
end

function steam_id_32_to_64(id)
  return '765'  .. id + 61197960265728
end


local font = draw.CreateFont("Bahnschrift", 25)
notify:SetFont(font)
notify:SetPrefix("[Profiler]")
notify:SetPrefixColor({70, 102, 255})
notify:Add("Loaded", 5, true)




local profile_window = gui.Tab(gui.Reference("Misc"), "Chicken.profileviewer.window", "Profile collection")

local options_gb = gui.Groupbox(profile_window, "Options", 15, 15, 600, 0)

local api_options = gui.Multibox(options_gb, "API options")
local display_options = gui.Multibox(options_gb, "Display options")
local notfication_options = gui.Multibox(options_gb, "Notfication options")

local api_steamidco = gui.Checkbox(api_options, "Chicken.profileviewer.apisteamidco", "steamid.co", true)
local api_steampowered = gui.Checkbox(api_options, "Chicken.profileviewer.apisteampowered", "api.steampowered.com", true)

local notify_if_anyone_banned = gui.Checkbox(notfication_options, "Chicken.profileviewer.apisteamidco", "Notify if profiles are banned in your game", false)
local notify_if_anyone_banned_with_100 = gui.Checkbox(notfication_options, "Chicken.profileviewer.apisteamidco", "Notify if profiles are banned within 100 days in your game (requires steampowered.com API)", true)
local notify_if_anyone_saved = gui.Checkbox(notfication_options, "Chicken.profileviewer.apisteamidco", "Notify if a saved profile is in your game", true)
local notify_print = gui.Checkbox(notfication_options, "Chicken.profileviewer.notifyprint", "Print notfications to the aimware console", true)

local display_name = gui.Checkbox(display_options, "Chicken.profileviewer.displayname", "Name", true)
local display_profile_status = gui.Checkbox(display_options, "Chicken.profileviewer.profileprivate", "Profile private (requires steamidco API)", false)
local display_steamid = gui.Checkbox(display_options, "Chicken.profileviewer.displaysteamid", "Steam ID64 (requires steamidco API)", false)
local display_account_limited = gui.Checkbox(display_options, "Chicken.profileviewer.displayaccount_limited", "Steam account limited (requires steamidco API)", false)
local display_vacbans = gui.Checkbox(display_options, "Chicken.profileviewer.displayvacbans", "Vacbans (requires steamidco API)", false)

local display_gamebans = gui.Checkbox(display_options, "Chicken.profileviewer.displaygamebans", "Game bans (requires steampowered.com API)", false)
local display_days_since_last_ban = gui.Checkbox(display_options, "Chicken.profileviewer.displaydayssincelastban", "Days since last ban (requires steampowered.com API)", false)

local display_tradebans = gui.Checkbox(display_options, "Chicken.profileviewer.displaytradebans", "Tradebans (requires steamidco API)", false)
local display_custom_url = gui.Checkbox(display_options, "Chicken.profileviewer.displaycustomurl", "Custom URL requires (steamidco API)", false)
local display_account_created = gui.Checkbox(display_options, "Chicken.profileviewer.displayaccountcreation", "Account creation (requires steamidco API)", false)

local search_box = gui.Editbox(options_gb, "Chicken.profileviewer.searchentry", "Search")

local mode = "current game"
local api_used = "steamidco"
local base_start_y = 340
local start_y = base_start_y


local current_game_btn = gui.Button(options_gb, "Current game", function()
	mode = "current game"
end)
local saved_btn = gui.Button(options_gb, "Saved", function()
	mode = "saved"	
end)

current_game_btn:SetPosY(220)
current_game_btn:SetWidth(275)

saved_btn:SetPosX(292); saved_btn:SetPosY(220)
saved_btn:SetWidth(275)

local function get_real_players()
	local real_players = {}
	
	for k, player in pairs(entities.FindByClass( "CCSPlayer" )) do
		local player_info = client.GetPlayerInfo(player:GetIndex())	
		if player_info and not player_info["IsBot"] and not player_info["IsGOTV"] and player_info["SteamID"] ~= 0 then
			table.insert(real_players, player)
		end
	end	
	return real_players
end


local already_requested = {}
local function get_profile_data(steamid64, fn)
	if already_requested[steamid64] then
		return
	else
		already_requested[steamid64] = true
	end
	local data = {}
	http.Get("https://steamid.co/php/api.php?action=steamID64&id=" .. steamid64, function(content)
		local j = json.decode(content)
		
		data.name = j["steamID"]
		data.custom_url = j["customURL"]
		data.steamID64 = j["steamID64"]
		data.profile_status = j["privacyState"]
		data.vac_banned = j["vacBanned"]
		data.trade_ban = j["tradeBanState"]
		data.limited_account =j["isLimitedAccount"]
		data.account_creation_date = j["memberSince"]
		
		if not api_steampowered:GetValue() then fn(data) return end
		http.Get("https://api.steampowered.com/ISteamUser/GetPlayerBans/v1/?key=8115FC3299296271F04A3274E7AD26E6&steamids=" .. steamid64, function(content)
			local j = json.decode(content)
			data.days_since_last_ban = j["players"][1]["DaysSinceLastBan"]
			data.game_bans = j["players"][1]["NumberOfGameBans"]			
			fn(data)
		end)
	end)
end

local profiles = {current_game = {}, saved = {}}

if not file.Exists("profileviewer-data.txt") then
	file.Write("profileviewer-data.txt", json.encode({current_game = {}, saved = {}}))
elseif string.len(file.Read("profileviewer-data.txt"))  < 29 then
	file.Write("profileviewer-data.txt", json.encode({current_game = {}, saved = {}}))
end

local refresh_btn = gui.Button(options_gb, "Refresh", function()
	for k, v in pairs(profiles.current_game) do
		v.gb:SetInvisible(true)
		-- profile_gb:Remove() -- probably 4th time making a script, not being able to remove gui objects, since it crashes you when you unload in most cases
	end
	profiles.current_game = {}
	already_requested = {}
	start_y = base_start_y
	

end)

refresh_btn:SetWidth(75)
refresh_btn:SetHeight(20)
refresh_btn:SetPosX(500)
refresh_btn:SetPosY(-41)

local function get_text_count() -- returns how many gui.Texts are in each profile-groupbox
	local text_count = 0
	if display_name:GetValue() then
		text_count = text_count + 1
	end
	
	if display_profile_status:GetValue() then
		text_count = text_count + 1
	end
	
	if display_steamid:GetValue() then
		text_count = text_count + 1
	end
	
	if display_account_limited:GetValue() then
		text_count = text_count + 1
	end
	
	if display_vacbans:GetValue() then
		text_count = text_count + 1
	end
	
	if display_gamebans:GetValue() then
		text_count = text_count + 1
	end
	
	if display_days_since_last_ban:GetValue() then
		text_count = text_count + 1
	end
	
	if display_tradebans:GetValue() then
		text_count = text_count + 1
	end
	
	if display_custom_url:GetValue() then
		text_count = text_count + 1
	end
	
	if display_account_created:GetValue() then
		text_count = text_count + 1
	end
	
	
	return text_count
end


function Create_Saved_Profile_GB(data) -- Creates a groupbox for a saved profile.
	profiles.saved[data.steamID64] = {gb = gui.Groupbox(profile_window, data.name, 15, start_y, 600, 0), invis = false, children_text = {}}
	
	profiles.saved[data.steamID64].children_text.name_text = gui.Text(profiles.saved[data.steamID64].gb, "Name: " .. data.name)
	profiles.saved[data.steamID64].children_text.profile_status_text = gui.Text(profiles.saved[data.steamID64].gb, "Profile status: " .. data.profile_status)
	profiles.saved[data.steamID64].children_text.steamid_text = gui.Text(profiles.saved[data.steamID64].gb, "SteamID64: ".. data.steamID64)
	profiles.saved[data.steamID64].children_text.account_limited_text = gui.Text(profiles.saved[data.steamID64].gb, "Account limited (no purchases): " .. (data.limited_account == "1" and "true" or "false"))
	profiles.saved[data.steamID64].children_text.vacbans_text = gui.Text(profiles.saved[data.steamID64].gb, "Vac bans: " .. (data.vac_banned == '0' and "None" or data.vac_banned))
	
	if api_steampowered:GetValue() then
		profiles.saved[data.steamID64].children_text.gamebans_text = gui.Text(profiles.saved[data.steamID64].gb, "Game bans: " .. (data.game_bans == '0' and "None" or data.game_bans))
		profiles.saved[data.steamID64].children_text.days_since_last_ban_text = gui.Text(profiles.saved[data.steamID64].gb, "Days since last ban: " .. (data.days_since_last_ban))
	end
	
	profiles.saved[data.steamID64].children_text.tradebans_text = gui.Text(profiles.saved[data.steamID64].gb, "Trade bans: " .. data.trade_ban)
	profiles.saved[data.steamID64].children_text.customurl_text = gui.Text(profiles.saved[data.steamID64].gb, "URL: " .. (type(data.custom_url) ~= "table" and data.custom_url or "N/A"))
	profiles.saved[data.steamID64].children_text.account_creation_date_text = gui.Text(profiles.saved[data.steamID64].gb, "Account creation: " .. (data.account_creation_date or "N/A"))

	local view_profile_btn = gui.Button(profiles.saved[data.steamID64].gb, "Open profile in browser", function()
		panorama.RunScript('SteamOverlayAPI.OpenExternalBrowserURL("' .. "https://steamcommunity.com/profiles/" .. data.steamID64 .. '")')
	end)
	
	profiles.saved[data.steamID64].btn = gui.Button(profiles.saved[data.steamID64].gb, "Remove profile", function()
		local content = json.decode(file.Contents("profileviewer-data.txt"))	
		for k, v in pairs(content.saved) do
			if v.steamID64 == data.steamID64 then
				profiles.saved[data.steamID64].gb:SetInvisible(true)
				profiles.saved[data.steamID64] = nil
			end
		end
		-- print(tbl_length(profiles.saved))
		if tbl_length(profiles.saved) == 0 then
			file.Write("profileviewer-data.txt", json.encode({current_game = {}, saved = {}}))
			return 
		end
		file.Write("profileviewer-data.txt", json.encode(profiles.saved))
	end)
		
	view_profile_btn:SetWidth(280)
	profiles.saved[data.steamID64].btn:SetWidth(280)
	profiles.saved[data.steamID64].btn:SetPosX(290)
end

function Create_Profile_GB(data) -- Creates a groupbox for a profile.
	profiles.current_game[data.steamID64] = {gb = gui.Groupbox(profile_window, data.name, 15, 0, 600, 0), invis = false, children_text = {}}
	
	profiles.current_game[data.steamID64].children_text.name_text = gui.Text(profiles.current_game[data.steamID64].gb, "Name: " .. data.name)
	profiles.current_game[data.steamID64].children_text.profile_status_text = gui.Text(profiles.current_game[data.steamID64].gb, "Profile status: " .. data.profile_status)
	profiles.current_game[data.steamID64].children_text.steamid_text = gui.Text(profiles.current_game[data.steamID64].gb, "SteamID64: ".. data.steamID64)
	profiles.current_game[data.steamID64].children_text.account_limited_text = gui.Text(profiles.current_game[data.steamID64].gb, "Account limited (no purcheses): " .. (data.limited_account == "1" and "true" or "false"))
	profiles.current_game[data.steamID64].children_text.vacbans_text = gui.Text(profiles.current_game[data.steamID64].gb, "Vac bans: " .. (data.vac_banned == '0' and "None" or data.vac_banned))
	
	if api_steampowered:GetValue() then
		profiles.current_game[data.steamID64].children_text.gamebans_text = gui.Text(profiles.current_game[data.steamID64].gb, "Game bans: " .. (data.game_bans == '0' and "None" or data.game_bans))
		profiles.current_game[data.steamID64].children_text.days_since_last_ban_text = gui.Text(profiles.current_game[data.steamID64].gb, "Days since last ban: " .. (data.days_since_last_ban))	
	end
	
	profiles.current_game[data.steamID64].children_text.tradebans_text = gui.Text(profiles.current_game[data.steamID64].gb, "Trade bans: " .. data.trade_ban)
	profiles.current_game[data.steamID64].children_text.customurl_text = gui.Text(profiles.current_game[data.steamID64].gb, "URL: " .. (type(data.custom_url) ~= "table" and data.custom_url or "N/A"))
	profiles.current_game[data.steamID64].children_text.account_creation_date_text = gui.Text(profiles.current_game[data.steamID64].gb, "Account creation: " .. (data.account_creation_date or "N/A"))
	
	local view_profile_btn = gui.Button(profiles.current_game[data.steamID64].gb, "Open profile in browser", function()
		panorama.RunScript('SteamOverlayAPI.OpenExternalBrowserURL("' .. "https://steamcommunity.com/profiles/" .. data.steamID64 .. '")')
	end)
	
	profiles.current_game[data.steamID64].btn = gui.Button(profiles.current_game[data.steamID64].gb, "Save profile", function()
		local content = json.decode(file.Contents("profileviewer-data.txt"))
		
		
		for k, v in pairs(content.saved) do
			if v.steamID64 == data.steamID64 then
				content.saved[data.steamID64] = data
				file.Write("profileviewer-data.txt", json.encode(content))
				return
			end
		end
		
		table.insert(content.saved, data)
		file.Write("profileviewer-data.txt", json.encode(content))
		Create_Saved_Profile_GB(data)
	end)
	
	
	view_profile_btn:SetWidth(280)
	
	profiles.current_game[data.steamID64].btn:SetWidth(280)
	profiles.current_game[data.steamID64].btn:SetPosX(290)
end


local function notify_stuff(data)
	if tonumber(data.vac_banned) ~= 0 or data.game_bans and tonumber(data.game_bans) ~= 0 then
		-- print(data.vac_banned, data.game_bans)
		if notify_if_anyone_banned:GetValue() then -- check if vac banned or game banned
			notify:SetPrefixColor({230, 0, 0})
			if api_steampowered:GetValue()  then
				notify:Add(data.name .. " was banned " .. data.days_since_last_ban .. " days ago", 10, notify_print:GetValue())
			else
				notify:Add(data.name .. " is banned", 10)
			end
		elseif notify_if_anyone_banned_with_100:GetValue() then
			if api_steampowered:GetValue() and tonumber(data.days_since_last_ban) <= 100 then
				notify:SetPrefixColor({255, 0, 0})
				notify:Add(data.name .. " was banned " .. data.days_since_last_ban .. " days ago", 10, notify_print:GetValue())
			end
		end
	end
	
	if notify_if_anyone_saved:GetValue() then
		local contents = json.decode(file.Read("profileviewer-data.txt"))		
		for k, v in pairs(contents.saved) do
			if v.steamID64 == data.steamID64 then
				notify:SetPrefixColor({0, 255, 0})
				notify:Add("You have " .. v.name .. " saved", 10, notify_print:GetValue())
			end
		end
	end
end


client.AllowListener("player_disconnect")


callbacks.Register("FireGameEvent", function(e)
	if e and e.GetName and e:GetName() == "player_disconnect" then -- attempt to call method 'GetName' (a nil value) if e.GetName is not checked, thought this was a by-product of erroring somewhere else in the code, yet I can't think of where it would be, i given up
		local player = entities.GetByUserID(e:GetInt("userid"))
		if player and player:IsPlayer() then
			local player_info = client.GetPlayerInfo(player:GetIndex())	
			print(player:GetName() .. " left")
			local steam_id_64 = steam_id_32_to_64(player_info["SteamID"])
			if profiles.current_game[steam_id_64] then
				profiles.current_game[steam_id_64].gb:SetInvisible(true)
				profiles.current_game[steam_id_64] = nil
			end
		end
	end
end)

local oMode = mode
callbacks.Register("Draw", function()
	if not entities.GetLocalPlayer() then
		for k, v in pairs(profiles.current_game) do
			v.gb:SetInvisible(true)
		end
		profiles.current_game = {}
		already_requested = {}
		start_y = base_start_y
		return
	end
	
	local text_count = get_text_count()
	local start_y2 = base_start_y

	for k, player in pairs(entities.FindByClass( "CCSPlayer" )) do -- getting data and then creating profile-groupbox, and maybe notifying 
		
		
		local player_info = client.GetPlayerInfo(player:GetIndex())	
		if player_info and not player_info["IsBot"] and not player_info["IsGOTV"] and player_info["SteamID"] ~= 0 then
			local steam_id_64 = steam_id_32_to_64(player_info["SteamID"])
			if not profiles.current_game[steam_id_64] then
				get_profile_data(steam_id_64, function(data)
					Create_Profile_GB(data)
					notify_stuff(data)
				end)
				
				if api_steamidco:GetValue() then
					api_used = "steamidco"
				elseif  api_steampowered:GetValue() then
					api_used = "steampowered"
				end
				
				if api_steamidco:GetValue() and api_steampowered:GetValue() then
					api_used = "both"
				end
			end
		end
	end
		
	-- ui shit
	local relevent_table = mode == "current game" and profiles.current_game or profiles.saved
	
	for k, v in pairs(relevent_table) do
		v.btn:SetPosY(text_count * 29)
		v.children_text.name_text:SetInvisible(not display_name:GetValue())
		v.children_text.profile_status_text:SetInvisible(not display_profile_status:GetValue())
		v.children_text.steamid_text:SetInvisible(not display_steamid:GetValue())
		v.children_text.account_limited_text:SetInvisible(not display_account_limited:GetValue())
		v.children_text.vacbans_text:SetInvisible(not display_vacbans:GetValue())
		
		if api_steampowered:GetValue() and v.children_text.gamebans_text then
			v.children_text.gamebans_text:SetInvisible(not display_gamebans:GetValue())
			v.children_text.days_since_last_ban_text:SetInvisible(not display_days_since_last_ban:GetValue())
		end

		v.children_text.tradebans_text:SetInvisible(not display_tradebans:GetValue())
		v.children_text.customurl_text:SetInvisible(not display_custom_url:GetValue())
		v.children_text.account_creation_date_text:SetInvisible(not display_account_created:GetValue())
	end
	

	
	
	if not api_steamidco:GetValue() and not api_steampowered:GetValue() then
		api_steamidco:SetValue(true)
	end
	
	if not api_steampowered:GetValue() then
		display_gamebans:SetValue(false)
		display_days_since_last_ban:SetValue(false)
	end
	
	if not api_steampowered:GetValue() then
		display_gamebans:SetValue(false)
		display_days_since_last_ban:SetValue(false)
	end
	
	

	refresh_btn:SetDisabled(tbl_length(profiles.current_game) < tbl_length(get_real_players()))
	api_options:SetDisabled(tbl_length(profiles.current_game) < tbl_length(get_real_players()))
	
	
	local i = 1
	if search_box:GetValue() == "" then -- for moving the profile-groupboxes on the y axis correctly
		for k,v in pairs(relevent_table) do
			if i > 1 then
				start_y2 = start_y2 + 140 + text_count * 25
			end
			v.gb:SetPosY(start_y2)
			i = i + 1
		end
	end
	
	
	
	if oEdit ~= search_box:GetValue() or oMode ~= mode then -- for search filter
		local i = 1
		local start_y2 = base_start_y
		for k, v in pairs(relevent_table) do
			if string.match(string.lower(tostring(v.gb)), string.lower(search_box:GetValue())) then
				relevent_table[k].invis = false
				if i > 1 then
					if relevent_table ==  profiles.saved then
						start_y2 = start_y2 + 140 + text_count * 25
					else
						start_y2 = start_y2 + 140 + text_count * 25
						
					end
				end
				v.gb:SetPosY(start_y2)
				i = i + 1
			else
				relevent_table[k].invis = true
			end
			oEdit = search_box:GetValue()
			
		end
		oMode = mode
		start_y2 = 0
	end

		if api_used == "both" then
		display_profile_status:SetDisabled(false)
		display_steamid:SetDisabled(false)
		display_account_limited:SetDisabled(false)
		display_vacbans:SetDisabled(false)
		
		display_gamebans:SetDisabled(false)
		display_days_since_last_ban:SetDisabled(false)
		
		display_tradebans:SetDisabled(false)
		display_custom_url:SetDisabled(false)
		display_account_created:SetDisabled(false)
		
		notify_if_anyone_banned_with_100:SetDisabled(false)
	elseif api_used == "steamidco" then
		display_profile_status:SetDisabled(false)
		display_steamid:SetDisabled(false)
		display_account_limited:SetDisabled(false)
		display_vacbans:SetDisabled(false)
		
		display_gamebans:SetDisabled(true)
		display_days_since_last_ban:SetDisabled(true)
		
		display_gamebans:SetValue(false)
		display_days_since_last_ban:SetValue(false)
		
		display_tradebans:SetDisabled(false)
		display_custom_url:SetDisabled(false)
		display_account_created:SetDisabled(false)
		
		notify_if_anyone_banned_with_100:SetDisabled(true)
	elseif api_used == "steampowered" then
		display_profile_status:SetDisabled(true)
		display_steamid:SetDisabled(true)
		display_account_limited:SetDisabled(true)
		display_vacbans:SetDisabled(true)
		
		display_gamebans:SetDisabled(false)
		display_days_since_last_ban:SetDisabled(false)
		
		display_tradebans:SetDisabled(true)
		display_custom_url:SetDisabled(true)
		display_account_created:SetDisabled(true)
		
		notify_if_anyone_banned_with_100:SetDisabled(false)
		--------------
		display_profile_status:SetValue(false)
		display_steamid:SetValue(false)
		display_account_limited:SetValue(false)
		display_vacbans:SetValue(false)
		
		
		display_tradebans:SetValue(false)
		display_custom_url:SetValue(false)
		display_account_created:SetValue(false)
	end
	
	if notify_if_anyone_banned:GetValue() then
		notify_if_anyone_banned_with_100:SetValue(false)
		notify_if_anyone_banned_with_100:SetDisabled(true)
	elseif api_steampowered:GetValue() then
		notify_if_anyone_banned_with_100:SetDisabled(false)
	end
	
	-- print(mode)
	for k, v in pairs(profiles.current_game) do -- for current game profiles and saved profiles
		if mode == "current game" and not v.invis then
			v.gb:SetInvisible(false)
		else
			v.gb:SetInvisible(true)
		end
	end
	
	for k, v in pairs(profiles.saved) do -- for current game profiles and saved profiles
		if mode == "saved" and not v.invis then
			v.gb:SetInvisible(false)
		else
			v.gb:SetInvisible(true)
		end
	end
	
	
end)

for k, v in pairs(json.decode(file.Read("profileviewer-data.txt")).saved) do
	Create_Saved_Profile_GB(v)
end
