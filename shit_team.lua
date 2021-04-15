-- give your teammates motivation

local start_time = 0
callbacks.Register("FireGameEvent", function(e)
	if e then
		if e:GetName() == "round_start" then
			start_time = globals.CurTime() + tonumber(client.GetConVar("mp_freezetime"))
		elseif e:GetName() == "player_death" then
			local local_index = client.GetLocalPlayerIndex()
			local victim_index = client.GetPlayerIndexByUserID(e:GetInt( "userid" ))
			local victim_uid = e:GetInt( "userid" )
			
			local victim = entities.GetByUserID(victim_uid)

			if victim:GetTeamNumber() == entities.GetLocalPlayer():GetTeamNumber() then
				if victim_index == local_index then client.ChatSay("luck") return end
				local seconds_when_died = globals.CurTime() - start_time 
				if seconds_when_died < 25 and seconds_when_died > 1 then
				client.ChatSay("[shit_team.lua] " .. victim:GetName() .. " died in " .. math.floor(globals.CurTime() - start_time) .. " seconds, aim for " .. math.floor(globals.CurTime() - start_time) + 1 ..  " next time retard")
				end
			end
		end
	end
end)

client.AllowListener("round_start")
client.AllowListener("player_death")
