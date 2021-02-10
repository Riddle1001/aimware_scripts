-- Download and run the library. Place the download code below in your script.

--[=====[

local notify_lib_installed = false

file.Enumerate(function(filename)
	if filename == "libraries/chickens_notfication.lua" then
		notify_lib_installed = true
	end
end)

if not notify_lib_installed then
	local body = http.Get("https://raw.githubusercontent.com/Aimware0/aimware_scripts/main/libraries/chickens_notfication.lua")
	file.Write("libraries/chickens_notfication.lua", body)
end

RunScript("libraries/chickens_notfication.lua")

--]=====]

notify = {
	notfications = {},
	prefix = '',
	PrefixColor = {255,0,0},
	MessageColor = {255,255,255},
	margin = 10,

	SetPrefix = function(self, prefix) self.prefix = prefix end,
	SetPrefixColor = function(self, color) self.PrefixColor = color end,
	SetMessageColor = function(self, color)	self.MessageColor = color end,
	SetMargin = function(self, margin) self.margin = margin end,

	SetFont = function(self, font) self.font = font end,

	Add = function(self, message, duration, shouldPrint)
		if shouldPrint then
			print(self.prefix .. " " ..  message)
		end
		table.insert(self.notfications, {
			prefix = self.prefix,
			message = message,
			duration = duration,
			PrefixColor = self.PrefixColor,
			MessageColor = self.MessageColor,
			font = self.font,
			init_time = globals.CurTime(),
			margin = self.margin
		})
	end,
}

callbacks.Register("Draw", function()
	if not entities.GetLocalPlayer() then notify.notfications = {} end
	for i, notfication in ipairs(notify.notfications) do
		draw.SetFont(notfication.font)
		local prefix_x, prefix_y = draw.GetTextSize(notfication.prefix .. " ")
		local message_x, message_y = "", ""
		if not notify.notfications[i - 1] then
			message_x, message_y = draw.GetTextSize(notfication.message) -- this should really used the last element's message instead of it's own; don't know how to gracefully do it in lua
		else
			message_x, message_y = draw.GetTextSize(notify.notfications[i - 1].message)
		end
		draw.Color(notfication.PrefixColor[1], notfication.PrefixColor[2], notfication.PrefixColor[3])
		draw.Text(0, (message_y + notfication.margin) * (i - 1), notfication.prefix)

		draw.Color(notfication.MessageColor[1], notfication.MessageColor[2], notfication.MessageColor[3])
		draw.Text(prefix_x, (message_y + notfication.margin) * (i - 1), notfication.message)
	

		if globals.CurTime() >= notfication.init_time + notfication.duration then
			table.remove(notify.notfications, i)
		end
	end
end)

---------- Example

-- local font = draw.CreateFont("Bahnschrift", 25)
-- notify:SetFont(font)

-- notify:SetPrefix("[Profiler]")
-- notify:SetPrefixColor({70, 102, 255})

-- notify:Add("Loaded", 5, true) -- Adds a message to the top left of the screen '[Profiler] Loaded' for 5 seconds then dissapears.
