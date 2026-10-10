/*--------
 _
| |          
| |          
| |          
| |____      
|______|     
 _   _
| | | |  
| | | |  
| | | |  
| |_| |  
 \___/  
 _   _
\ \ / /
 \ V / 
  > <  
 / ^ \
/_/ \_\

*/--------------

if (SERVER) then



	if (bKeycardScanner) then bKeycardScanner:print("Du hat schon bKeycards...","Scheisse") return end



	util.AddNetworkString("zeige_id")



	CreateConVar("id_command","/id",{FCAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE})

	CreateConVar("id_entfernung",100,{FCAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE})



	hook.Add("PlayerSay","zeige_id",function(ply,txt)

		if (txt:lower() == GetConVar("id_command"):GetString()) then

			for _,v in pairs(player.GetHumans()) do

				if (v == ply or v:GetPos():Distance(ply:GetPos()) <= GetConVar("id_entfernung"):GetInt()) then

					net.Start("zeige_id")

						net.WriteEntity(ply)

					net.Send(v)

				end

			end

			return ""

		end

	end)



else



	net.Receive("zeige_id",function()

		local ply      = net.ReadEntity()

		local t_name   = team.GetName(ply:Team())

		local t_color  = team.GetColor(ply:Team())

		local override = hook.Run("bkeycardscanner_get_presentation_message",ply)

		if (not override) then

			local msg = {}

			local msg_str_i = 1

			local white_needed = true

			local s = GetConVar("id_message"):GetString()

			local i = 0

			while (i < #s) do

				i = i + 1

				local v = s[i]

				if (v == "%" and s[i + 1] == "n" and s[i + 2] == "a" and s[i + 3] == "m" and s[i + 4] == "e" and s[i + 5] == "%") then

					msg[#msg + 1] = t_color

					msg[#msg + 1] = ply:Nick()

					msg_str_i = msg_str_i + 1

					i = i + 5

					white_needed = true

				elseif (v == "%" and s[i + 1] == "t" and s[i + 2] == "e" and s[i + 3] == "a" and s[i + 4] == "m" and s[i + 5] == "%") then

					msg[#msg + 1] = t_color

					msg[#msg + 1] = t_name

					msg_str_i = msg_str_i + 1

					i = i + 5 --Der Col. Spectre hat hier einen Kackhaufen hinterlassen, es ist jetzt "Geoelt" XDDD

					white_needed = true

				else

					if (white_needed) then

						msg[#msg + 1] = Color(255,255,255)

						msg_str_i = msg_str_i + 1

						white_needed = false

					end

					while (msg[msg_str_i] ~= nil and type(msg[msg_str_i]) ~= "string") do

						msg_str_i = msg_str_i + 1

					end

					if (not msg[msg_str_i]) then

						msg[msg_str_i] = ""

					end

					msg[msg_str_i] = msg[msg_str_i] .. v

				end

			end

			chat.AddText(unpack(msg))

		else

			chat.AddText(unpack(override))

		end

	end)



end



CreateConVar("id_message","Zeigt seine ID vor: %name%",{FCVAR_REPLICATED,FCAR_ARCHIVE,FCVAR_SERVER_CAN_EXECUTE})