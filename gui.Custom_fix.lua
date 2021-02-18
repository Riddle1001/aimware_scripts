function gui._Custom(ref, varname, name, x, y, w, h, paint, custom_vars) -- the custom_vars param is very useful, lets you use custom vars for each object,
	--within the paint callback.
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
		
		SetPos = function(x, y)
			self.element:SetPosX(x)
			self.element:SetPosY(y)
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
		paint(x, y, x2, y2, active, GuiObject)
	end
	
	
	local custom = gui.Custom(ref, varname, x, y, w, h, _paint, write, read)
	GuiObject.element = custom
	
	return GuiObject
end



function paint(x,y,x2,y2, active, self)
	--self.custom_vars.has_focus
	if self:GetValue() == "1" then
		draw.Color(255,0,0)
		draw.FilledRect( x, y, x2, y2 )
		draw.Color(0,255,0)
		draw.Text(x, y, self:GetName())
	else
		draw.Color(0,255,0)
		draw.FilledRect( x, y, x2, y2 )
		draw.Color(255,0,0)
		draw.Text(x, y, self:GetName())
	end
	
end


function gui.Example(ref, varname, name, x, y, w, h)
	return gui._Custom(ref, varname, name, x, y, w, h, paint)
end

local example = gui.Example(gui.Reference("Ragebot", "Aimbot", "Toggle"), "var name", "1", 10, 10, 20, 20)

local delay = 0
callbacks.Register("Draw", function()
	if globals.CurTime() > delay then
		delay = globals.CurTime() + 1
		
		local random_value = math.random(1, 2)
		example:SetValue(random_value)
		example:SetName(random_value)
		
	end
end)
