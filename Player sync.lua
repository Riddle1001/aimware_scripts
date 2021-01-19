-- Sync a teammates movement, scope, and duck
local PlayerFollow_Window = gui.Window( "PlayerFollow.Window", "Player Follow", 15, 20, 400, 400 )
local PlayerFollow_G_Keybinds = gui.Groupbox(PlayerFollow_Window, "Keybinds", 5, 5, 390, 150);
local PlayerFollow_G_Settings = gui.Groupbox(PlayerFollow_Window, "Settings", 5, 112, 390, 150);

local select_closest_team_key = gui.Keybox( PlayerFollow_G_Keybinds, "select_closest_team.key", "Select closest enemy", 6)
local deselect_closest_team_key = gui.Keybox( PlayerFollow_G_Keybinds, "deselect_closest_team.key", "Deselect closest enemy", 5)
deselect_closest_team_key:SetPosY(0)
deselect_closest_team_key:SetPosX(185)


-- Sync options
local sync_settings = gui.Multibox( PlayerFollow_G_Settings, "Sync settings" )
local PlayerFollow_SyncMovement = gui.Checkbox(sync_settings, "PlayerFollow.movement", "Sync movement", false)
local PlayerFollow_SyncScope = gui.Checkbox(sync_settings, "PlayerFollow.movement", "Sync scope", false)
local PlayerFollow_SyncDuck = gui.Checkbox(sync_settings, "PlayerFollow.movement", "Sync duck", false)
local PlayerFollow_SyncDpeek = gui.Checkbox(sync_settings, "PlayerFollow.movement", "Sync when team mate is very close and shoots (auto doublepeek)", false)

local PlayerFollow_distance = gui.Slider(PlayerFollow_G_Settings, "PlayerFollow.movement", "Stop follow when distance less than", 2, 0, 300)

local PlayerFollow_DrawCircles = gui.Checkbox(PlayerFollow_G_Settings, "PlayerFollow.DrawCircles", "Draw circles above you and target", false)

gui.Text(PlayerFollow_G_Settings, "Teammate circle color")
local PlayerFollow_DrawTargetColor = gui.ColorPicker(PlayerFollow_G_Settings, "PlayerFollow.teammate_color", '', 255, 0, 0, 150)
PlayerFollow_DrawTargetColor:SetPosY(90)
PlayerFollow_DrawTargetColor:SetPosX(-210)


gui.Text(PlayerFollow_G_Settings, "Localplayer circle color")
local PlayerFollow_DrawMyColor = gui.ColorPicker(PlayerFollow_G_Settings, "PlayerFollow.my_color", '', 0, 0, 255, 150)
PlayerFollow_DrawMyColor:SetPosY(122)
PlayerFollow_DrawMyColor:SetPosX(-210)


function colorChannelMixer(colorChannelA, colorChannelB, amountToMix)
    channelA = colorChannelA*amountToMix
    channelB = colorChannelB*(1-amountToMix)
    return tonumber(channelA+channelB)
end

function colorMixer(rgbA, rgbB, amountToMix)
    r = colorChannelMixer(rgbA[1],rgbB[1],amountToMix)
    g = colorChannelMixer(rgbA[2],rgbB[2],amountToMix)
    b = colorChannelMixer(rgbA[3],rgbB[3],amountToMix)
    return draw.Color(r,g,b), {r,g,b}
end


local function DrawCircle(pos, radius, fill_color, outline_color)
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
                    
        if cur_point[1] ~= nil and cur_point[2] ~= nil and old_point[1] ~= nil and old_point[2] ~= nil then        
            -- fill
            if fill_color then
                draw.Color(unpack(fill_color))
            else
                draw.Color(255,0,0)
            end

            
            draw.Triangle(cur_point[1], cur_point[2], old_point[1], old_point[2], center[1], center[2])
            -- outline
            if outline_color then
                draw.Color(unpack(outline_color))
            else
                draw.Color(0,0,0)
            end
             
            draw.Line(cur_point[1], cur_point[2], old_point[1], old_point[2]);        
        end
    end
end

function Distance(ent1, ent2)
	local pos_1 = ent1:GetAbsOrigin()
	local pos_2 = ent2:GetAbsOrigin()
	
	return vector.Distance({pos_1.x, pos_1.y, pos_1.z}, {pos_2.x, pos_2.y, pos_2.z})
end


function is_movement_keys_down()
    return input.IsButtonDown( 87 ) or input.IsButtonDown( 65 ) or input.IsButtonDown( 83 ) or input.IsButtonDown( 68 ) or input.IsButtonDown( 32 ) or input.IsButtonDown( 17 )
end

local function get_closest_teammate()
	local me = entities.GetLocalPlayer()
	local closest = nil
	local lowest_dist = math.huge
	local players = entities.FindByClass( "CCSPlayer" );
	for k, v in pairs(players) do
		local distance = Distance(v, me)
		if distance < lowest_dist and v:IsAlive() and v:GetIndex() ~= me:GetIndex() and v:GetTeamNumber() == me:GetTeamNumber() then
			lowest_dist = distance
			closest = v
		end
	end
	return closest
end

function is_crouching(player)
	return player:GetProp('m_flDuckAmount') > 0.1
end

function is_scoped(player)
	return player:GetProp("m_bIsScoped") ~= 0
end


function move_to_pos(pos, cmd, speed)
	local LocalPlayer = entities.GetLocalPlayer()
	local angle_to_target = (pos - entities.GetLocalPlayer():GetAbsOrigin()):Angles()
	
    cmd.forwardmove = math.cos(math.rad((engine:GetViewAngles() - angle_to_target).y)) * speed
    cmd.sidemove = math.sin(math.rad((engine:GetViewAngles() - angle_to_target).y)) * speed
end

local Target = false
local AimbotTarget = nil
callbacks.Register("AimbotTarget", function(t)
	if t and t:GetIndex() then
		AimbotTarget = t
	else
		AimbotTarget = nil
	end
end)

callbacks.Register("CreateMove", function(cmd)
	if is_movement_keys_down() or not Target then return end

	if PlayerFollow_SyncMovement:GetValue() then
		local distance = Distance(Target, entities.GetLocalPlayer())
		if distance > PlayerFollow_distance:GetValue() then
			if not AimbotTarget then
				local VelocityX = Target:GetPropFloat( "localdata", "m_vecVelocity[0]" );
				local VelocityY = Target:GetPropFloat( "localdata", "m_vecVelocity[1]" );
				local VelocityZ = Target:GetPropFloat( "localdata", "m_vecVelocity[2]" );
				local speed = math.sqrt(VelocityX^2 + VelocityY^2);
				if distance > 10 then
					move_to_pos(Target:GetAbsOrigin(), cmd, 255)
					return
				end
				move_to_pos(Target:GetAbsOrigin(), cmd, speed)
			else
				move_to_pos(Target:GetAbsOrigin(), cmd, 36)
			end
		end
	end

	if PlayerFollow_SyncDuck:GetValue() and is_crouching(Target) then
		cmd.buttons = bit.bor(cmd.buttons, 4)
	end
	
	if PlayerFollow_SyncScope:GetValue() and is_scoped(Target) ~= is_scoped(entities.GetLocalPlayer()) then
		cmd.buttons = bit.bor(cmd.buttons, 2048)
	end
end)

callbacks.Register("Draw", function()
	local localplayer = entities.GetLocalPlayer()
	if not localplayer then return end
	
	if input.IsButtonPressed(gui.GetValue("adv.menukey")) then
		PlayerFollow_Window:SetActive(not PlayerFollow_Window:IsActive())
	end

	if input.IsButtonDown(select_closest_team_key:GetValue()) then
		Target = get_closest_teammate()
	elseif input.IsButtonDown(deselect_closest_team_key:GetValue()) then
		Target = false
	end

	if not Target or not PlayerFollow_DrawCircles:GetValue() then return end

	local r1, g1, b1, a1 = PlayerFollow_DrawTargetColor:GetValue()
	local r2, g2, b2, a2 = PlayerFollow_DrawMyColor:GetValue()

	local alpha = 255
	if a1 == a2 then
		alpha = a1
	elseif a1 < a2 then
		alpha = a1
	elseif a2 < a1 then
		alpha = a2
	end
	
	


	if Target:GetIndex() and localplayer:GetIndex() then 
		local distance = Distance(Target, localplayer)
		if distance <= PlayerFollow_distance:GetValue() then
			local x, y = client.WorldToScreen(Target:GetAbsOrigin())
			if x and y then
				draw.Color(127, 0, 127)
				draw.Text(x, y + 10, "Synced")
			end
		else
			local x, y = client.WorldToScreen(Target:GetAbsOrigin())
			draw.Color(255, 0, 0)
			draw.Text(x, y, "Unsynced")
			
			local x2, y2 = client.WorldToScreen(localplayer:GetAbsOrigin())
			draw.Color(0, 0, 255)
			draw.Text(x2, y2 + 10, "Unsynced")			
		end
	end
end)
