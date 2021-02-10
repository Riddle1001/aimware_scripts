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


local hitboxes = {
    'head',
    'chest',
    'stomach',
    'left arm',
    'right arm',
    'left leg',
    'right leg',
    'body'
}

local fonts = {
	"Verdana",
	"Arial Black",
	"Impact",
	"Arial",
	"Calibri",
	"Cambria",
	"Cambria Math",
	"Comic Sans MS",
	"Consolas",
	"Courier New",
	"Georgia",
	"Helvetica",
	"Lucida Console",
	"Lucida Sans Unicode",
	"Microsoft Sans Serif",
	"MS Gothic",
	"MS PGothic",
	"Palatino Linotype",
	"Segoe Print",
	"Segoe Script",
	"Segoe UI",
	"Segoe UI Symbol",
	"Tahoma",
	"Times",
	"Times New Roman",
	"Trebuchet MS",
}


local misc_ref = gui.Reference("Misc")
local extra_logs_tab = gui.Tab(misc_ref, "hitlog_tab", "Extended logs")
local extra_logs_gb = gui.Groupbox(extra_logs_tab, "Extra logs", 10, 15, 600, 0 )

local log_custom_prefix = gui.Editbox(extra_logs_gb, "_log_custom_prefix_", "Prefix")
local font_combobox = gui.Combobox(extra_logs_gb, "_log_font_selector_", "Font", unpack(fonts))
local log_text_size = gui.Slider(extra_logs_gb, "_log_text_size_", "Log text size", 22, 1, 60 )
local log_damage_multibox = gui.Multibox(extra_logs_gb, "Logs")


local log_local_damage = gui.Checkbox(log_damage_multibox, "_log_local_damage_", "damage from localplayer", false)
local log_friendly_damage = gui.Checkbox(log_damage_multibox, "_log_friendly_damage_", "damage from friendly", false)
local log_enemy_damage = gui.Checkbox(log_damage_multibox, "_log_enemy_damage_", "damage from enemy", false)
local log_me = gui.Checkbox(log_damage_multibox, "_log_me_", "Log events that happen to me only", false)
local log_local_miss =  gui.Checkbox(log_damage_multibox, "_log_local_misses", "Log all local misses", false)

local print_log_to_console =  gui.Checkbox(extra_logs_gb, "_log_local_misses", "Print log to aimware's console (DEFAULT KEY F1)", true)

local log_duration = gui.Slider(extra_logs_gb, "_log_duration_", "Log duration", 15, 1, 120 )
log_duration:SetDescription("How long the notfiction in top left will stay")

local font = draw.CreateFont("Bahnschrift", 22)
notify:SetFont(font)

notify:SetMargin(8)
log_custom_prefix:SetValue("Aimware.net")
notify:SetPrefix("[" .. log_custom_prefix:GetValue() .. "]")


local shots_fired = 0
local shots_hit = 0
local accuracy = 0
local Target = nil
function IsValid(entity)
  return pcall(function() tostring(entity:GetAbsOrigin()) end)
end
callbacks.Register("AimbotTarget", function(t) if IsValid(t) then Target = t else Target = nil end end)

callbacks.Register("FireGameEvent", function(e)
	if e then
		if e:GetName() == "player_hurt" then
			local lp_index = entities.GetLocalPlayer():GetIndex()
			local lp_teamnum = entities.GetLocalPlayer():GetTeamNumber()
			local victim = entities.GetByUserID(e:GetInt("userid"));
			local attacker = entities.GetByUserID(e:GetInt("attacker"));
			local dmg_done = e:GetInt("dmg_health")
			local hitbox = e:GetInt("hitgroup")

			local notfication_msg = string.format("%s did %i damage to %s in %s (%i HP)", attacker:GetName(), dmg_done, victim:GetName(), (hitboxes[hitbox] or "generic"), victim:GetHealth())

			if log_me:GetValue() then
				if attacker:GetIndex() == lp_index then
					notify:SetPrefixColor({0,255,0})
					notify:Add(notfication_msg, log_duration:GetValue(), print_log_to_console:GetValue())

				elseif victim:GetIndex() == lp_index then
					notify:SetPrefixColor({255,0,0})
					notify:Add(notfication_msg, log_duration:GetValue(), print_log_to_console:GetValue())

				end
			else
				if attacker:GetIndex() == lp_index and victim:GetIndex() ~= lp_index and log_local_damage:GetValue() then
					notify:SetPrefixColor({0,168,107})
					notify:Add(notfication_msg, log_duration:GetValue(), print_log_to_console:GetValue())
				end

				if attacker:GetTeamNumber() ~= lp_teamnum and log_enemy_damage:GetValue() then
					notify:SetPrefixColor({255,0,0})
					notify:Add(notfication_msg, log_duration:GetValue(), print_log_to_console:GetValue())
				end

				if attacker:GetTeamNumber() == lp_teamnum and attacker:GetIndex() ~= lp_index and log_friendly_damage:GetValue() then
					notify:SetPrefixColor({0,255,0})
					notify:Add(notfication_msg, log_duration:GetValue(), print_log_to_console:GetValue())
				end
			end

			if not log_local_miss:GetValue() then return end
			-- Accuracy
			if attacker:GetIndex() == lp_index then
				shots_hit = shots_hit + 1
				accuracy = shots_fired - shots_hit
			end
		elseif e:GetName() == "weapon_fire" then
			if not log_local_miss:GetValue() then return end
			local shooter = entities.GetByUserID(e:GetInt("userid"));
			if shooter:GetIndex() == entities.GetLocalPlayer():GetIndex() then
				shots_fired = shots_fired + 1
				accuracy = shots_fired - shots_hit
			end
		end
	end
end)

local old_accuracy = 0
callbacks.Register("Draw", function()
	notify:SetPrefix("[" .. log_custom_prefix:GetValue() .. "]")
	font = draw.CreateFont(fonts[font_combobox:GetValue() + 1], log_text_size:GetValue())
	notify:SetFont(font)

	if log_me:GetValue() then
		log_local_damage:SetValue(false)
		log_friendly_damage:SetValue(false)
		log_enemy_damage:SetValue(false)
	end

	if not log_local_miss:GetValue() then return end
	if accuracy ~= old_accuracy and accuracy ~= 0 then
		if accuracy > old_accuracy then
			if Target then
				notify:SetPrefixColor({238,130,238})
				notify:Add(string.format("Missed %s (%i HP)", Target:GetName(), Target:GetHealth()), log_duration:GetValue(), print_log_to_console:GetValue())
			end
		end
		old_accuracy = accuracy
	end


end)

client.AllowListener("player_hurt")
client.AllowListener("player_death")

client.AllowListener("weapon_fire")

notify:SetPrefixColor({238,130,238})
notify:Add("Loaded without errors", 5, true)
