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
	}
	
	local function _paint(x, y, x2, y2, active)
		local width = x2 - x
		-- print(1)
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

	gui._Custom(ref, "", "", x, y, w, h, paint, vars)
end


-- Examples
local test_tab = gui.Tab(gui.Reference("Misc"), "test.tab", "Test tab")


local img_data = http.Get("https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/avatars/e5/e53474dbea973d880cb24e5d7247ad77fbb68721_full.jpg")
local decoded_image = {common.DecodeJPEG(img_data)}

gui.Image(test_tab, decoded_image, 10, 10, 50,50, function()
	print("Clicked!")
end)
