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
		local height = y2 - y
		paint(x, y, x2, y2, active, GuiObject, width, height)
	end
	
	
	local custom = gui.Custom(ref, varname, x, y, w, h, _paint, write, read)
	GuiObject.element = custom
	
	return GuiObject
end


function gui.Image(ref, img, x, y, w, h, fn_on_click)
	local function paint(x, y, x2, y2, active, self, width, height)
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
		end
		
		
		draw.SetTexture(self.custom_vars.img_texture)
		draw.FilledRect(x,y,x2,y2)
		draw.Color(255,255,255, 100)
		draw.OutlinedRect( x + 1, y + 1, x2 + 1, y2 + 1)
	end
	
	local rgb, width, height = nil, nil, nil
	
	if type(img) == "string" and (string.match(img, "https://") or  string.match(img, "https://")) then
		local extension = string.sub(img, -4)
		if extension == ".jpg" then
			local img_data = http.Get(img)
			rgb, width, height = common.DecodeJPEG(img_data)
		elseif extension == ".png" then
			local img_data = http.Get(img)
			rgb, width, height = common.DecodePNG(img_data)
		else
			error("No extesion found for the given URL. Suggest uploading the URL on imgur.")
		end
	end
	
	local texture = draw.CreateTexture(rgb, width, height)
	
	local vars = {
		img_data = {rgb, width, height},
		img_texture = draw.CreateTexture(rgb, width, height),
				
		mouse_left_released = true,
		old_mouse_left_released = true,
		
		is_in_rect = function(x, y, x1, y1, x2, y2)
			return x >= x1 and x < x2 and y >= y1 and y < y2;
		end
	}

	gui._Custom(ref, "", "", x, y, w, h, paint, vars)
end


-- Examples
-- local test_tab = gui.Tab(gui.Reference("Misc"), "test.tab", "Test tab")

-- gui.Image

-- local img = gui.Image(test_tab, "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/avatars/e5/e53474dbea973d880cb24e5d7247ad77fbb68721_full.jpg", 60, 60, 400, 400, function()
	-- print("Clicked!!")
-- end)
