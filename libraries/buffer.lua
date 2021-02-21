chicken = chicken or {}
chicken.ui = chicken.ui or {}
function chicken.ui.Create(ref, varname, name, x, y, w, h, paint, custom_vars)
	local tbl = {val = 0}

	local function read(v)
		tbl.val = v
	end

	local function write()
		return tbl.val
	end
	
	local function is_in_rect(x, y, x1, y1, x2, y2)
		return x >= x1 and x < x2 and y >= y1 and y < y2;
	end
	
	local GuiObject = {
		element = nil,
		custom_vars = custom_vars or {},
		name = name,
		
		_element_pos_x = x,
		_element_pos_y = y,
		
		_element_width = w,
		_element_height = h,
		
		-- For drawing children....
		
		
		paint = paint,
		_Children = {},
		
		_new_x = 0,
		_new_y = 0,
		_new_x2 = 0,
		_new_y2 = 0,
		
		_child = false,
		
		addChild = function(self, child)
			self._Children[#self._Children + 1] = child
			self._Children[#self._Children]:SetChild()
			
			self._Children[#self._Children]._parent = self
			
			return self
		
		end,
		
		SetChild = function(self, parent)
			self._child = true
		end,
		
		IsChild = function(self)
			return self._child
		end,
		
		GetChildren = function(self)
			return self._Children
		end,
		-- End children shit
		
		_parent = ref,
		ParentIsChickenUI = false, 
			
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
			self._element_pos_x = x
		end,
		
		SetPosY = function(self, y)
			self.element:SetPosY(y)
			self._element_pos_y = y
		end,
		
		SetPos = function(self, x, y)
			self.element:SetPosX(x)
			self.element:SetPosY(y)
			self._element_pos_x = x
			self._element_pos_y = y
		end,
		
		GetPos = function(self)
			return self._element_pos_x, self._element_pos_y
		end,
		
		SetWidth = function(self, width)
			self.element:SetWidth(width)
			self._element_width = width
		end,
		
		SetHeight = function(self, height)
			self.element:SetHeight(height)
			self._element_height = height
		end,
		
		SetSize = function(self, w, h)
			self.element:SetWidth(w)
			self.element:SetHeight(h)
			self._element_width = width
			self._element_height = height
		end,
		
		GetSize = function(self)
			return self._element_width, self._element_height 
		end,
		
		SetVisible = function(self, b)
			self.element:SetInvisible(not b)
		end,
		
		SetInvisible = function(self, b)
			self.element:SetInvisible(b)
		end,
		
		GetParent = function(self)
			return self._parent
		end,
		
		hovering = function(x, y, x2, y2)
			local mx, my = input.GetMousePos()
			return is_in_rect(mx, my, x, y, x2, y2)
		end,
						
		_mouse_hovering = false,
		_old_mouse_hovering = false,
		
		IsHovering = function(self)
			return self._mouse_hovering
		end,
		
		OnHovered = function(self) -- you rewrite this function when creating elements
			
		end,
		
		_mouse_left_released = true,
		_old_mouse_left_released = true,
		
		OnMousePressed = function(self)
			if self:IsHovering() then
				if input.IsButtonDown(1) then -- left mouse button
					return 1
				elseif input.IsButtonDown(2) then-- right mouse button
					return 2
				end
			end
		end,
		
		OnClick = function(self) -- you rewrite this function when creating elements
			
		end,
	}
	
	
	
	
	local meta = {__index = custom_vars}
	setmetatable(GuiObject, meta)
	
	local function _paint(x, y, x2, y2, active)
		-- hovering / clicking events
		local mx, my = input.GetMousePos()
		
		local hovering = GuiObject.hovering(x, y, x2, y2)	
		
		if hovering then
			GuiObject._mouse_hovering = true		
			if input.IsButtonReleased(1) then
				GuiObject._mouse_left_released = true
			end
		
			if input.IsButtonDown(1) then
				GuiObject._mouse_left_released = false
			end
		
			if GuiObject._mouse_left_released ~= GuiObject._old_mouse_left_released then
				if not GuiObject._mouse_left_released then -- Clicked
					GuiObject:OnClick()
				end
				GuiObject._old_mouse_left_released = GuiObject._mouse_left_released
			end
		else
			GuiObject._mouse_hovering = false
		end

		if GuiObject._old_mouse_hovering ~= GuiObject._mouse_hovering then
			GuiObject:OnHovered(GuiObject._mouse_hovering)
			GuiObject._old_mouse_hovering = GuiObject._mouse_hovering
		end
		
		local width = x2 - x
		local height = y2 - y
		
		if not GuiObject:IsChild() then
			paint(x, y, x2, y2, active, GuiObject, width, height)
		end
		
		--- Draw children objects
		for i, v in pairs(GuiObject:GetChildren()) do
			-- print(i)
			local new_x = x + v._element_pos_x
			local new_y = y2 - GuiObject._element_height + v._element_pos_y  
			
			local new_x2 = x2 - GuiObject._element_width + v._element_width + v._element_pos_x
			local new_y2 = y + v._element_pos_y  + v._element_height
			
			v.paint(new_x, new_y, new_x2, new_y2, _, v, v._element_width, v._element_height)		
		end
	end
	
	local custom = gui.Custom(ref, varname, x, y, w, h, _paint, write, read)
	GuiObject.element = custom
	
	return GuiObject
end


function chicken.ui.ColoredText(ref, text, x, y, options)
	local function paint(x, y, x2, y2, active, self, width, height)
		-- print(1)
		local options = self.custom_vars
	
		-- text
		draw.Color(options.text_color[1], options.text_color[2], options.text_color[3])		
		draw.SetFont(options.font)
		
		-- parse \n 
		-- todo text wrap
		if not self.custom_vars.fixed_text then
			local new_index = 1
			local len = string.len(options.text)
			for i=1, len do
				local current_char = string.sub(options.text, i, i)
				if current_char == "\n" then
					self.custom_vars.lines[#self.custom_vars.lines + 1] = string.sub(options.text, new_index, i - 1)
					new_index = i + 1
				end
			end
			if not string.find(options.text, "\n") then self.custom_vars.lines[#self.custom_vars.lines + 1] = options.text end
			self.custom_vars.fixed_text = true
		end
		
		
		
		for i, line in ipairs(options.lines) do
			local spacer = 3
			-- print(line)
			local text_x, text_y = draw.GetTextSize(line)
			if #options.lines > 1 then
				draw.Text(x, y + i * text_y + i * spacer, line)
			else
				draw.Text(x, y, line)
			end
		end
				
		--underline
		if options.underline then
			local text_x, text_y = draw.GetTextSize(options.text)
			local underline_space = 5
			draw.Color(options.underline_color[1], options.underline_color[2], options.underline_color[3], options.underline_color[4])
			draw.Line(x, y + text_y + underline_space, x + text_x, y + text_y + underline_space)
		end
		
	
	end
	local options = options or {}
	
	local vars = {
		text = text,
		text_color = options.text_color and {options.text_color[1] or 255, options.text_color[2] or 255, options.text_color[3] or 255, options.text_color[4] or 255} or {255,255,255,255},
		font = options.font or draw.CreateFont("Bahnschrift", 14),
		underline = options.underline or false,
		
		lines = {},
		fixed_text = false

	}
	vars.underline_color = options.underline_color and {options.underline_color[1] or 255, options.underline_color[2] or 255, options.underline_color[3] or 255, options.underline_color[4] or 255} or vars.text_color

	

	local text_x, text_y = draw.GetTextSize(text)
	local custom = chicken.ui.Create(ref, "", "", x, y, text_x, text_y, paint, vars)
		
	function custom:SetOptions(options)
		vars.text = options.text or vars.text
		vars.font = options.font or vars.font
		vars.text_color = options.text_color and {options.text_color[1] or 255, options.text_color[2] or 255, options.text_color[3] or 255, options.text_color[4] or 255} or vars.text_color
		vars.underline = options.underline
		vars.underline_color = options.underline_color and {options.underline_color[1] or 255, options.underline_color[2] or 255, options.underline_color[3] or 255, options.underline_color[4] or 255} or vars.underline_color
		
		local text_x, text_y = draw.GetTextSize(vars.text)
		self:SetSize(text_x, text_y)
	end
		
	return custom
end

function chicken.ui.LinkText(ref, text, x, y, options)

	local linked_text = gui.ColoredText(ref, text, x, y, {text_color = {0, 70, 255}})	
	linked_text.OnHovered = function(self, IsHovering)
		self:SetOptions({underline = IsHovering})
	end
	
	linked_text.DoClick = function(self)
		print("Clicked")
	end

	return linked_text
end

function chicken.ui.Image(ref, img_texture_params, x, y, w, h)
	local function paint(x, y, x2, y2, active, self, width, height)
		
		if not self.custom_vars.texture then return end
		draw.Color(255,0,0, 255)
		
		if self:IsHovering() then
			draw.Color(255,255,255, 200)
		end
		
		
		if self:OnMousePressed() == 1 then
			y = y + height / 20
			x = x + width / 20
			
			x2 = x2 - height / 20
			y2 = y2 - width / 20
		end
		
		draw.SetTexture(self.custom_vars.texture)
		
		draw.Color(255,255,255,255)
		draw.FilledRect(x,y,x2,y2)
		
	end

	local texture = draw.CreateTexture(img_texture_params[1], img_texture_params[2], img_texture_params[3])
	
	local vars = {
		texture = texture,
		paint = paint
	}
	
	local custom = 	chicken.ui.Create(ref, "Images", "test2", x, y, w, h, paint, vars)
	
	function custom:SetTexture(img_texture_params)
		vars.texture = draw.CreateTexture(img_texture_params[1], img_texture_params[2], img_texture_params[3])
	end
	
	return custom
end

local test_tab = gui.Tab(gui.Reference("Settings"), "test.tab", "Test tab")

function chicken.ui.GroupBox(ref, x, y, w, h)
	local function paint(x, y, x2, y2, active, self, width, height)
		draw.Color(0,0,0, 100)

		draw.FilledRect(x, y, x2, y2)
		draw.Color(unpack(self.custom_vars.header_bg))
		draw.FilledRect(x, y, x2, y2 - (h / 1.25))
		
		local children_height = 0		
	end
	
	local font = draw.CreateFont("Arial", 18)


	local vars = {
		header_bg = {150,0,0}
	}
	
	local custom = 	chicken.ui.Create(ref, "", "", x, y, w, h, paint, vars)
	custom.header_text = chicken.ui.ColoredText(test_tab, "Lua loader V2 | Made by chicken",5,5, {font = font})
	custom:addChild(custom.header_text)
	
	
	return custom
end


-- Examples
print("Colored text", gui.ColoredText)

local gb = chicken.ui.GroupBox(test_tab, 0, 0, 650, 100)
local font = draw.CreateFont("Arial", 16)
local text = chicken.ui.ColoredText(test_tab, [[This lua is meant to make it easier for aimware users to both run and download script that was made
for Aimware.
Credits for lua loader: Chicken4676 (patient player)
Lua loader last update: 2/19/2021 | Scripts last updated 2/19/2021
]], 5, 20, {font = font})
gb:addChild(text, gb)



-- local img = gui.Image(test_tab, img_data, 0, 0, 25, 25)
-- gb:addChild(img)


