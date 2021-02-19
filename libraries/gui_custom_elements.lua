function gui._Custom(ref, varname, name, x, y, w, h, paint, custom_vars)
	local tbl = {val = 0}

	local function read(v)
		tbl.val = v
	end

	local function write()
		return tbl.val
	end
	
	local GuiObject = {
		element = nil,
		custom_vars = custom_vars or {},
		name = name,
		
		GetValue = function(self)
			return self.element:GetValue()
		end,
		
		SetValue = function(self, value)
			return self.element:SetValue(value)
		end,
		
		GetName = function(self)
			return self.name
		end,
		
		SetName = function(self, name)
			self.name = name
		end,
		
		SetPosX = function(self, x)
			self.element:SetPosX(x)
		end,
		
		SetPosY = function(self, y)
			self.element:SetPosY(y)
		end,
		
		SetPos = function(self, x, y)
			self.element:SetPosX(x)
			self.element:SetPosY(y)
		end,
		
		SetWidth = function(self, width)
			self.element:SetWidth(width)
		end,
		
		SetHeight = function(self, height)
			self.element:SetHeight(height)
		end,
		
		SetSize = function(self, w, h)
			self.element:SetWidth(w)
			self.element:SetHeight(h)
		end,
		
		SetVisible = function(self, b)
			self.element:SetInvisible(not b)
		end,
		
		SetInvisible = function(self, b)
			self.element:SetInvisible(b)
		end,
	}
	
	local function _paint(x, y, x2, y2, active)
		local width = x2 - x
		local height = y2 - y
		paint(x, y, x2, y2, active, GuiObject, width, height)
	end
	
	local custom = gui.Custom(ref, varname, x, y, w, h, _paint, write, read)
	GuiObject.element = custom
	
	return GuiObject
end


function gui.Image(ref, img_texture_params, x, y, w, h, fn_on_click)
	local function paint(x, y, x2, y2, active, self, width, height)
		if not self.custom_vars.texture then return end

		local mx, my = input.GetMousePos()
		local hovering = self.custom_vars.is_in_rect(mx, my, x,y, x2, y2)


		if hovering then
			if fn_on_click then
				if input.IsButtonReleased(1) then
					self.custom_vars.mouse_left_released = true
				end
				
				if input.IsButtonDown(1) then
					self.custom_vars.mouse_left_released = false
				end
				
				if self.custom_vars.mouse_left_released ~= self.custom_vars.old_mouse_left_released then
					if not self.custom_vars.mouse_left_released then -- Clicked
						fn_on_click()
					end
					self.custom_vars.old_mouse_left_released = self.custom_vars.mouse_left_released
				end

			end
			
			if input.IsButtonDown(1) then
				y = y + height / 20
				x = x + width / 20
				
				x2 = x2 - height / 20
				y2 = y2 - width / 20
			end
			draw.Color(255,255,255, 240)
		else
			draw.Color(255,255,255, 200)
		end
		
		draw.OutlinedRect( x - 1, y - 1, x2 + 1, y2 + 1)
		draw.SetTexture(self.custom_vars.texture)
		draw.Color(255,255,255,255)
		draw.FilledRect(x,y,x2,y2)
	end

	
	local texture = draw.CreateTexture(img_texture_params[1], img_texture_params[2], img_texture_params[3])
	local vars = {
		texture = texture,
				
		mouse_left_released = true,
		old_mouse_left_released = true,
		
		is_in_rect = function(x, y, x1, y1, x2, y2)
			return x >= x1 and x < x2 and y >= y1 and y < y2;
		end
	}
	
	local custom = 	gui._Custom(ref, "", "", x, y, w, h, paint, vars)
	local funcs = {}

	local meta = {__index = custom}
	setmetatable(funcs, meta) -- Allows funcs to have gui._Custom's functions
	
	return funcs
end



function gui.ColoredText(ref, text, x, y, options)
	local function paint(x, y, x2, y2, active, self, width, height)
		local options = self.custom_vars
		
		draw.Color(options.color[1], options.color[2], options.color[3])
		draw.SetFont(options.Font)
		draw.Text(x, y, options.text)
	end
	
	
	

	local vars = {
		text = text,
		color = options.color or {255,255,255},
		
		font_name = options.font or "Verdana",
		size = options.size or 14,
		weight = options.weight or 500
	}
	
	
	vars.Font = draw.CreateFont(vars.font_name, vars.size, vars.weight)
	
	local custom = gui._Custom(ref, "", "", x, y, 100, 100, paint, vars)

	local funcs = {
		SetOptions = function(self, options)
			vars.text = options.text or vars.text
			vars.font_name = options.font_name or vars.font_name
			vars.size = options.size or vars.size
			vars.weight = options.text or vars.weight
		end
	}
	
	local meta = {__index = custom}
	setmetatable(funcs, meta) -- Allows funcs to have gui._Custom's functions
	
	return funcs
end

-- Examples
-- local test_tab = gui.Tab(gui.Reference("Misc"), "test.tab", "Test tab")


-- gui.Image(ref, img_texture_params, x, y, w, h, fn_on_click)
-- local img_data = http.Get("https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/avatars/e5/e53474dbea973d880cb24e5d7247ad77fbb68721_full.jpg")
-- local decoded_image = {common.DecodeJPEG(img_data)}

-- local img = gui.Image(test_tab, decoded_image, 10, 10, 50,50, function()
	-- print("Clicked!")
-- end)


-- gui.ColoredText(ref, text, x, y, options)
-- local text = gui.ColoredText(test_tab, "Hello world", 200, 200, {
	-- color = {255, 0,0},
	-- size = 20,
	-- font = "Bahnschrift",
	-- weight = 600	
-- })

-- text:SetOptions({text = "Hi"}) -- Sets text to hi
-- text:SetOptions({text = "Epic", size = 30}) -- Sets text to high and font size to 30
-- text:SetOptions({
	-- color = {255, 255,255},
	-- size = 20,
	-- font = "Bahnschrift",
	-- weight = 600
-- })
