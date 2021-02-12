function hasbit(x, p)
    return x % (p + p) >= p      
end

local native_edgejump_key = gui.Reference("Misc", "Movement", "Jump", "Edge Jump")

local cached_native_edgejump_key =  native_edgejump_key:GetValue()

local edge_stop_key = gui.Keybox(gui.Reference("Misc", "Movement", "Jump"), "Chicken.edgestop.key", "Edge Stop", 5)
edge_stop_key:SetDescription("Stop right before falling of an edge")

local manually_changing = true

callbacks.Register("CreateMove", function(cmd)
	
	if native_edgejump_key:GetValue() ~= cached_native_edgejump_key and manually_changing then
		cached_native_edgejump_key = native_edgejump_key:GetValue()
	end

	if edge_stop_key:GetValue() ~= 0 and input.IsButtonDown(edge_stop_key:GetValue()) then
		manually_changing = false
		native_edgejump_key:SetValue(edge_stop_key:GetValue())
		
		if input.IsButtonDown("W") then -- forwards
			cmd.forwardmove = 7.50
		end
		
		if input.IsButtonDown("S")  then -- backwards
			cmd.forwardmove = -7.50
		end
		
		if input.IsButtonDown("A") then -- move left
			cmd.sidemove = -7.50
		end
		
		if input.IsButtonDown("D")  then -- move right
			cmd.sidemove = 7.50
		end
		
		if hasbit(cmd.buttons, 2) then
			cmd.sidemove = 0
			cmd.forwardmove = 0
			cmd.buttons = 0
		end
	else
		manually_changing = true
		native_edgejump_key:SetValue(cached_native_edgejump_key)
	end
end)
