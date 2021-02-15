-- Modified version of https://aimware.net/forum/thread/101070
-- Added localplayer velocity prediction


local ref = gui.Reference("Ragebot", "Accuracy", "Weapon")
local weapon_list = { "asniper", "sniper", "scout", "hpistol", "pistol", "rifle" }

local debug_show_velocity_prediction_text  = gui.Checkbox(ref, "lua.adaptive.damage", "[debug] Show velocity prediction text", false)
local debug_show_tracers = gui.Checkbox(ref, "lua.adaptive.damage", "[debug] Show tracers", false)

local rbot_autosniper_mindamage_2 = gui.Slider(ref, weapon_list[1] .. ".mindmg.2", "Damage Visible", 0, 0, 100);
local rbot_autosniper_mindamage_1 = gui.Slider(ref, weapon_list[1] .. ".mindmg.1", "Damage behind Wall", 0, 0, 100);

local rbot_sniper_mindamage_2 = gui.Slider(ref, weapon_list[2] .. ".mindmg.2", "Damage Visible", 0, 0, 100);
local rbot_sniper_mindamage_1 = gui.Slider(ref, weapon_list[2] .. ".mindmg.1", "Damage behind Wall", 0, 0, 100);

local rbot_scout_mindamage_2 = gui.Slider(ref, weapon_list[3] .. ".mindmg.2", "Damage Visible", 0, 0, 100);
local rbot_scout_mindamage_1 = gui.Slider(ref, weapon_list[3] .. ".mindmg.1", "Damage behind Wall", 0, 0, 100);

local rbot_revolver_mindamage_2 = gui.Slider(ref, weapon_list[4] .. ".mindmg.2", "Damage Visible", 0, 0, 100);
local rbot_revolver_mindamage_1 = gui.Slider(ref, weapon_list[4] .. ".mindmg.1", "Damage behind Wall", 0, 0, 100);

local rbot_pistol_mindamage_2 = gui.Slider(ref, weapon_list[5] .. ".mindmg.2", "Damage Visible", 0, 0, 100);
local rbot_pistol_mindamage_1 = gui.Slider(ref, weapon_list[5] .. ".mindmg.1", "Damage behind Wall", 0, 0, 100);

local rbot_rifle_mindamage_2 = gui.Slider(ref, weapon_list[6] .. ".mindmg.2", "Damage Visible", 0, 0, 100);
local rbot_rifle_mindamage_1 = gui.Slider(ref, weapon_list[6] .. ".mindmg.1", "Damage behind Wall", 0, 0, 100);

local adaptive_weapons = {
    -- see line 219
    ["asniper.mindmg"] = { 11, 38 },
    ["sniper.mindmg"] = { 9 },
    ["scout.mindmg"] = { 40 },
    ["hpistol.mindmg"] = { 64, 1 },
    ["pistol.mindmg"] = { 2, 3, 4, 30, 32, 36, 61, 63 },
    ["rifle.mindmg"] = { 7, 8, 10, 13, 16, 39, 60 },
    ["false"] = {},
}

local vars = {
    -- see line 219
    [rbot_autosniper_mindamage_2] = { 11, 38 },
    [rbot_sniper_mindamage_2] = { 9 },
    [rbot_scout_mindamage_2] = { 40 },
    [rbot_revolver_mindamage_2] = { 64, 1 },
    [rbot_pistol_mindamage_2] = { 2, 3, 4, 30, 32, 36, 61, 63 },
    [rbot_rifle_mindamage_2] = { 7, 8, 10, 13, 16, 39, 60 },
    [false] = {},
}

local vars_2 = {
    -- see line 219
    [rbot_autosniper_mindamage_1] = { 11, 38 },
    [rbot_sniper_mindamage_1] = { 9 },
    [rbot_scout_mindamage_1] = { 40 },
    [rbot_revolver_mindamage_1] = { 64, 1 },
    [rbot_pistol_mindamage_1] = { 2, 3, 4, 30, 32, 36, 61, 63 },
    [rbot_rifle_mindamage_1] = { 7, 8, 10, 13, 16, 39, 60 },
    [false] = {},
}

local function table_contains(table, item)
    for i = 1, #table do
        if table[i] == item then
            return true
        end
    end
    return false
end


local function find_key(value) 
    for k, v in pairs(adaptive_weapons) do
        if table_contains(v, value) then
            return k
        end
    end
end

local function set_vis(value)
    for k, v in pairs(vars) do
        if table_contains(v, value) then
            if k ~= false then
                k:SetInvisible(false)
            end
        else
            if k ~= false then
                k:SetInvisible(true)
            end
        end
    end
    for k, v in pairs(vars_2) do
        if table_contains(v, value) then
            if k ~= false then
                k:SetInvisible(false)
            end
        else
            if k ~= false then
                k:SetInvisible(true)
            end
        end
    end
end

local function is_vis(LocalPlayerPos)
    local is_vis = false
    local players = entities.FindByClass("CCSPlayer")
    local fps = 1
    for i, player in pairs(players) do
        if player:GetTeamNumber() ~= entities.GetLocalPlayer():GetTeamNumber() and player:IsPlayer() and player:IsAlive() then
            for i = 0, 10 do
                for x = 0, fps do
                    local v = player:GetHitboxPosition(i)

                    if x == 0 then
                        v.x = v.x
                        v.y = v.y
                    elseif x == 1 then
                        v.x = v.x
                        v.y = v.y + 4
                    elseif x == 2 then
                        v.x = v.x
                        v.y = v.y - 4
                    elseif x == 3 then
                        v.x = v.x + 4
                        v.y = v.y
                    elseif x == 4 then
                        v.x = v.x - 4
                        v.y = v.y
                    end

                    local c = (engine.TraceLine(LocalPlayerPos, v, 0x1)).contents
					
					local x,y = client.WorldToScreen(LocalPlayerPos)
					local x2,y2 = client.WorldToScreen(v)
					
					if debug_show_tracers:GetValue() and x and x2 then
						draw.Line(x,y,x2,y2)
					end
					
                    if c == 0 then
                        is_vis = true
                        break
                    end
                end
            end
        end
    end
    return is_vis
end


function predict_velocity(entity, prediction_amount)
	local VelocityX = entity:GetPropFloat( "localdata", "m_vecVelocity[0]" );
	local VelocityY = entity:GetPropFloat( "localdata", "m_vecVelocity[1]" );
	local VelocityZ = entity:GetPropFloat( "localdata", "m_vecVelocity[2]" );
	
	absVelocity = {VelocityX, VelocityY, VelocityZ}
	
	pos_ = {entity:GetAbsOrigin()}
	
	modifed_velocity = {vector.Multiply(absVelocity, prediction_amount)}
	
	
	return {vector.Subtract({vector.Add(pos_, modifed_velocity)}, {0,0,0})}
end

local function GetBot()
	for k,v in pairs(entities.FindByClass("CCSPlayer")) do
		if v:GetIndex() ~= entities.GetLocalPlayer():GetIndex() then
			return v
		end
	end
end


local weapon = nil
callbacks.Register("Draw", function()
	local LocalPlayer = entities.GetLocalPlayer()
	
	if not LocalPlayer then return end
	
	local prediction = predict_velocity(LocalPlayer, 0.2)
	local my_pos = LocalPlayer:GetAbsOrigin()
	
	local x,y,z = vector.Add(
		{my_pos.x, my_pos.y, my_pos.z},
		{prediction[1], prediction[2], prediction[3]}
	)

	local Player = Vector3(x,y,z)
	Player.z = Player.z + LocalPlayer:GetPropVector("localdata", "m_vecViewOffset[0]").z
	local x, y = client.WorldToScreen(Player)
	
	if debug_show_velocity_prediction_text:GetValue() then
		draw.Text(x,y, "Velocity Prediction")
	end
	
	if LocalPlayer then
		if LocalPlayer:GetWeaponID() ~= nil then
			weapon = LocalPlayer:GetWeaponID()
		end
        local slider = find_key(weapon) --finding mindamage var  ["asniper.mindmg"] = { 11, 38 },
        set_vis(weapon)
        if slider ~= nil then
            local slider_invis = ("rbot.accuracy.weapon." .. slider .. ".1") -- getting the var name of the check boxes/sliders
            local slider_vis = ("rbot.accuracy.weapon." .. slider .. ".2")
            if slider ~= false then -- makes sure only support weapon is selected
                if is_vis(Player) then
                    local damage = gui.GetValue(slider_vis) --setting damage
                    gui.SetValue("rbot.accuracy.weapon." .. slider, damage)
                else
                    local damage = gui.GetValue(slider_invis)
                    gui.SetValue("rbot.accuracy.weapon." .. slider, damage)
                end
            end
        end
    end
end)
