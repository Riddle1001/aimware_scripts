-- https://wiki.facepunch.com/gmod/timer -- Based of the glua timers, somethings changed, and some added, not much though

-- Download and run the library

-- file.Enumerate(function(filename)
	-- if filename == "libraries/chickens_glua_timers.lua" then
		-- notify_lib_installed = true
		-- print(1)
	-- end
-- end)

-- if not notify_lib_installed then
	-- local body = http.Get("https://raw.githubusercontent.com/Aimware0/aimware_scripts/main/libraries/chickens_glua_timers.lua")
	-- file.Write("libraries/chickens_glua_timers.lua", body)
-- end

-- RunScript("libraries/chickens_glua_timers.lua")


timer = timer or {}
timers = timers or {}

function timer.Exists(name)
    for k,v in pairs(timers) do
        if name == v.name then
            return true
        end
    end
    return false
end

function timer.Create(name, delay, repetitions, func)
    if not timer.Exists(name) then
        table.insert(timers, {type = "Create", name = name, delay = delay, repetitions = repetitions, func = func, lastTime = globals.CurTime() + delay, repStartTime = globals.CurTime()})
    end
end

function timer.Simple(name, delay, func)
    if not timer.Exists(name) then
        table.insert(timers, {type = "Simple", name = name, func = func, lastTime = globals.CurTime() + delay, delay = delay})
    end
end


function timer.Spam(name, duration, func)
    if not timer.Exists(name) then
        table.insert(timers, {type = "Spam", name = name, duration = duration, func = func, lastTime = globals.CurTime()})
    end
end

function timer.Remove(name)
    for k,v in pairs(timers or {}) do
        if name == v.name then
            table.remove(timers, k)
            return true
        end
    end
    return false
end



function timer.Pause(name)
    for k, v in pairs(timers) do
        if name == v.name then
            v.pause = true
            return true
        end
    end
    return false
end

function timer.UnPause(name)
    for k, v in pairs(timers) do
        if name == v.name and v.pause then
            v.pause = false
            return true
        end
    end
end

function timer.RepsLeft(name)
    for k,v in pairs(timers) do
        if name == v.name and v.type == "Create" then
            return v.repetitions
        end
    end
    return false
end

function timer.Restart(name)
      for i=1, #timers do
        if name == timers[i].name then
            if timers[i].type == "Simple" then
                timers[i].lastTime = globals.CurTime() + timers[i].delay
            end
        end
    end
end


function timer.Toggle(name)
    for k, v in pairs(timers) do
        if name == v.name then
            if v.pause then
                v.pause = false
            elseif v.pause == false then
                v.pause = true
            end
        end
    end
end

function timer.TimeLeft(name)
    for k, v in pairs(timers) do
        if name == v.name then
            if v.type == "Create" then
                return  v.delay * timer.RepsLeft(name) - (globals.CurTime() - v.repStartTime)
            elseif v.type == "Simple" or v.type == "Spam" then
                return globals.CurTime() - v.lastTime
            end
        end
    end
end


function timer.Adjust(name, delay, repetitions, func)
    for i=1, #timers do
        if name == timers[i].name then
            if timers[i].type == "Create" then
                timers[i] = {type = "Create", name = name, delay = delay, repetitions = repetitions, func = func, lastTime = globals.CurTime() + delay, repStartTime = globals.CurTime()}
            end
        end
    end
end

function timer.Tick(draw)
    return function()
			-- print(1)
		for k, v in pairs(timers or {}) do
			if not v.pause then
				-- timer.Create
				if v.type == "Create" then
					if v.repetitions <= 0 then
						table.remove(timers, k)
					end
					if globals.CurTime() >= v.lastTime then
						v.lastTime = globals.CurTime() + v.delay
						v.repStartTime = globals.CurTime()
						v.func()
						v.repetitions = v.repetitions - 1
					end
				-- timer.Simple
				elseif v.type == "Simple" then
					if globals.CurTime() >= v.lastTime then
						v.func()
						table.remove(timers, k)
					end
				-- timer.Spam
				elseif v.type == "Spam" then
					v.func()
					if globals.CurTime() >= v.lastTime + v.duration then
						table.remove(timers, k)
					end
				end
			end
		end
	end
    
end



callbacks.Register("CreateMove", timer.Tick(false)) -- If you want to switch the timer to ticks instead of of seconds, change this to true and the one in the draw callback to false.
callbacks.Register("Draw", timer.Tick(true))


-- timer.Simple("Test", 1, function() -- Prints test after 1 second
	-- print("Test")
-- end)
