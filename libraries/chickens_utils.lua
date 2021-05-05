-- Just random functions I find useful that I could copy and paste out of here
-- (a lot of these are probably not mine!)

-- File stuff

function file.Exists(filename)
	local exists = false
	file.Enumerate(function(name)
		if filename == name then
		  exists = true
		end
	end)
	return exists
end


function file.Append(filename, append_text)
	local contents = file.Read(filename)
	file.Write(filename, filename .. contents)
end


-- Entity stuff
function EyePos(entity)
    return entity:GetAbsOrigin() + Vector3(0,0, entity:GetPropFloat("localdata", "m_vecViewOffset[2]"))
end

function EyeAngles(entity)
    local e_angles = engine.GetViewAngles()
    return EulerAngles(e_angles.x, e_angles.y, e_angles.z)
end

function EyeTrace(entity)
    return engine.TraceLine(EyePos(entity), EyePos(entity) + EyeAngles(entity):Forward() * 100000)
end


function GetVelocity(entity)
	local VelocityX = entity:GetPropFloat( "localdata", "m_vecVelocity[0]" )
	local VelocityY = entity:GetPropFloat( "localdata", "m_vecVelocity[1]" )
	local VelocityZ = entity:GetPropFloat( "localdata", "m_vecVelocity[2]" )
	
	return math.sqrt(VelocityX^2 + VelocityY^2)
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

function IsValid(entity)
	return entity:GetIndex()
end

function closest_to_crosshair()
	local lowest = math.huge			
	local x, y = draw.GetScreenSize()
	local mid_x = x / 2
	local mid_y = y / 2
	
	local closest = nil
	
	for k, v in pairs(entities.FindByClass("CCSPlayer")) do
		if v:GetIndex() ~= entities.GetLocalPlayer():GetIndex() and v:GetTeamNumber() ~= entities.GetLocalPlayer():GetTeamNumber() and v:IsAlive() then
			local p_x, p_y = client.WorldToScreen(v:GetAbsOrigin())
			if  p_x and p_y then
				local dist = math.pow(mid_x - p_x, 2) + math.pow(mid_y - p_y, 2)
				if dist < lowest then
					closest = v
					lowest = dist
				end
			end
		end
	end
	return closest
end


local function quick_stop(cmd, desired_velocity)
	local VelocityX = entities.GetLocalPlayer():GetPropFloat( "localdata", "m_vecVelocity[0]" );
	local VelocityY = entities.GetLocalPlayer():GetPropFloat( "localdata", "m_vecVelocity[1]" );
	local VelocityZ = entities.GetLocalPlayer():GetPropFloat( "localdata", "m_vecVelocity[2]" );
	local speed = math.sqrt(VelocityX^2 + VelocityY^2);
	
	if speed <= desired_velocity then return end

	local velocity = {x = VelocityX, y = VelocityY, z = VelocityZ}
	local directionX, directionY, directionZ = vector.Angles( {velocity.x,velocity.y,velocity.z} )

	viewanglesX, viewanglesY = engine.GetViewAngles().x, engine.GetViewAngles().y

	directionY = viewanglesY - directionY
	dirForwardX, dirForwardY, dirForwardZ = vector.AngleForward({directionX, directionY, directionZ})

	negated_directionX, negated_directionY, negated_directionZ = vector.Multiply({dirForwardX, dirForwardY, dirForwardZ}, -speed)

	cmd.forwardmove = negated_directionX
	cmd.sidemove = negated_directionY 
end

function is_movement_keys_down()
    return input.IsButtonDown( 87 ) or input.IsButtonDown( 65 ) or input.IsButtonDown( 83 ) or input.IsButtonDown( 68 ) or input.IsButtonDown( 32 ) or input.IsButtonDown( 17 )
end


local function is_vis(LocalPlayerPos)
    local is_vis = false
    local players = entities.FindByClass("CCSPlayer")
    local fps = 1
    for i, player in pairs(players) do
        if player:GetTeamNumber() ~= entities.GetLocalPlayer():GetTeamNumber() and player:IsPlayer() and player:IsAlive() then
            for i = 0, 18 do
				if   i == 0 and debug_hitbox_head:GetValue() or
					 i == 6 and debug_hitbox_chest:GetValue() or
					 i == 3 and debug_hitbox_pelvis:GetValue() or
					 
					 i == 18 and debug_hitbox_leftarm:GetValue() or
					 i == 16 and debug_hitbox_rightarm:GetValue() or
					 
					 i == 7 and debug_hitbox_leftleg:GetValue() or
					 i == 8 and debug_hitbox_rightleg:GetValue() then
			
					for x = 0, debug_point_scale_amount:GetValue() do
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
						
						
						if c == 0 then draw.Color(0,255,0) else draw.Color(225,0,0) end
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
    end
    return is_vis
end

