local has_target = false

callbacks.Register("AimbotTarget", function(t)
	has_target = t:GetIndex() and true or false
end)

local slow_walk_string = "rbot.accuracy.movement.slowkey"
local auto_stop_string = "rbot.accuracy.wpnmovement.asniper.autostop"

local w,h = draw.GetScreenSize()

callbacks.Register("Draw", function()
	local VelocityX = entities.GetLocalPlayer():GetPropFloat( "localdata", "m_vecVelocity[0]" )
	local VelocityY = entities.GetLocalPlayer():GetPropFloat( "localdata", "m_vecVelocity[1]" )
	local VelocityZ = entities.GetLocalPlayer():GetPropFloat( "localdata", "m_vecVelocity[2]" )
	
	local speed = math.sqrt(VelocityX^2 + VelocityY^2)
	
	local slow_walk_speed = gui.GetValue("rbot.accuracy.movement.slowspeed")
	
	if speed <= slow_walk_speed * 2.25 and has_target then
		gui.SetValue(auto_stop_string, false)
		-- if has_target then
			local movement_key_down = 0
			if input.IsButtonDown(87) then -- w
				movement_key_down = 87
			elseif input.IsButtonDown(65) then  -- a
				movement_key_down = 65
			elseif input.IsButtonDown(83) then  -- s
				movement_key_down = 83
			elseif input.IsButtonDown(68) then -- d
				movement_key_down = 68
			end
			gui.SetValue(slow_walk_string, movement_key_down)
		-- else
			-- gui.SetValue(slow_walk_string, 16)
		-- end
		
	else
		gui.SetValue(auto_stop_string, true)
		gui.SetValue(slow_walk_string, 16)
	end
	
	
	
	if input.IsButtonPressed(39) then
		gui.SetValue("rbot.accuracy.movement.slowspeed", slow_walk_speed + 1)
	end
	
	if input.IsButtonPressed(37) then
		gui.SetValue("rbot.accuracy.movement.slowspeed", slow_walk_speed - 1)
	end
	
	draw.Text(15, h/2, slow_walk_speed)
end)
