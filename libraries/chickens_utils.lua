-- Just random functions I find useful that I could copy and paste out of here

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

