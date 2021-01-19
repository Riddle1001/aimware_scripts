local match = string.match
local function valid_filename(filename)
	return not match(filename, "<") and
	not match(filename, ">")  and
	not match(filename, ":")  and
	not match(filename, "\"") and
	not match(filename, "/")  and
	not match(filename, "\\") and
	not match(filename, "|")  and
	not match(filename, "?") 
end


function is_downloaded(filename)
	local downloaded = false
	file.Enumerate(function(fname)
		if filename == fname then
			
			downloaded = true
			return
		end
	end)
	return downloaded
end

local lua_downloader_tab = gui.Tab(gui.Reference("Settings"), "Chicken.luadownloader.tab", "Lua downloader")

local script_name_entry = gui.Editbox(lua_downloader_tab, "luadownload.script_name_entry", "Script name");
local url_entry = gui.Editbox(lua_downloader_tab, "luadownload.url_entry", "*RAW* Script URL");
local status_text =  gui.Text(lua_downloader_tab, "Status: Ready")
local strict_checks = gui.Checkbox(lua_downloader_tab, "luadownload.strict_check", "Strict check", true)

local download_btn = gui.Button(lua_downloader_tab, "Download", function()

	local script_name = string.gsub(script_name_entry:GetValue(), ".lua", "")
	script_name = script_name .. ".lua"
	
	local url = url_entry:GetValue()
	
	if string.len(script_name) == 0 then
		status_text:SetText("Status: Error. Script name entry box is empty.")
		return
	end
	
	if string.len(url) == 0 then
		status_text:SetText("Status: Error. Url entry box is empty.")
		return
	end
	
	if is_downloaded(script_name) then
		status_text:SetText("Status: Error. Scriptname '" .. script_name .. "' already exists.")
		return
	end
	
	if not match(string.lower(url), "http://") and not match(string.lower(url), "https://") then
		status_text:SetText("Status: Error. Invalid protocal, make sure http:// or https:// is in the script url.")
		return
	end
	
	if strict_checks:GetValue() then		
		if match(string.lower(url), "github.com") then
			status_text:SetText("Status: Error. Detected non raw github link.")
			return
		end
		
		if match(string.lower(url), "pastebin.com") and not match(string.lower(url), "/raw/") then
			status_text:SetText("Status: Error. Detected non raw pastebin link.")
			return
		end			
	end
	
	status_text:SetText("Status: Downloading...")

	http.Get(url, function(content)
		if strict_checks:GetValue() and (match(content, "</html>") or match(content, "</body")) then
			status_text:SetText("Status: Error. Detected HTMLcode from URL.")
			return
		end
		file.Write(script_name, content)
		status_text:SetText("Status: Downloaded!")
		
		script_name_entry:SetValue("")
		url_entry:SetValue("")
	end)
	
end)
