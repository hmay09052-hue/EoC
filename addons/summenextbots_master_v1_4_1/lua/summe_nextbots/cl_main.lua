--[[
   _____ _    _ __  __ __  __ ______                   
  / ____| |  | |  \/  |  \/  |  ____|                  
 | (___ | |  | | \  / | \  / | |__                     
  \___ \| |  | | |\/| | |\/| |  __|                    
  ____) | |__| | |  | | |  | | |____                   
 |_____/_\____/|_| _|_|_|__|_|______|___ _______ _____ 
 | \ | |  ____\ \ / /__   __|  _ \ / __ \__   __/ ____|
 |  \| | |__   \ V /   | |  | |_) | |  | | | | | (___  
 | . ` |  __|   > <    | |  |  _ <| |  | | | |  \___ \ 
 | |\  | |____ / . \   | |  | |_) | |__| | | |  ____) |
 |_| \_|______/_/ \_\  |_|  |____/ \____/  |_| |_____/ 
                                                       
    Created by Summe: https://steamcommunity.com/id/DerSumme/ 
    Purchased content: https://discord.gg/k6YdMwj9w2
]]--

surface.CreateFont( "SummeNB.Title", {
	font = SYMUI and SYMUI.FontFace("body") or "Roboto",
	extended = false,
	size = 30,
	weight = 599,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = true,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
})

surface.CreateFont( "SummeNB.Debug", {
	font = SYMUI and SYMUI.FontFace("body") or "Roboto",
	extended = false,
	size = 40,
	weight = 200,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = true,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
})

concommand.Add("summenextbots_debug", function(ply, cmd, args, str)
	if not LocalPlayer():IsAdmin() then print("You need to be an admin!") return end

	SummeNextbots.Config.Debug = not SummeNextbots.Config.Debug
	if SummeNextbots.Config.Debug then
		SummeLibrary:Notify("success", "Summe Nextbots", "You have activated the debug mode for yourself.")
	else
		SummeLibrary:Notify("warning", "Summe Nextbots", "You have deactivated the debug mode for yourself.")
	end
end)