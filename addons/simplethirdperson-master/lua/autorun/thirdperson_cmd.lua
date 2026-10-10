if ( CLIENT ) then
local on = false 

local function simpletoggle()

	on = !on

	if on == true then

		LocalPlayer():ConCommand( "simple_thirdperson_enabled 1" )

	else

		LocalPlayer():ConCommand( "simple_thirdperson_enabled 0" )

	end

end


concommand.Add( "simple_toggle", simpletoggle )
end

if ( SERVER ) then
hook.Add( "PlayerSay", "PlayerSayExample", function( ply, text, team )
if(string.sub( text, 1, 12) == "!thirdperson" ) then 
ply:ConCommand( "simple_thirdperson_enable_toggle" )
return(false)
end
end)


hook.Add("PlayerButtonDown","IDC",function(ply,key)

if key == KEY_T then
ply:ConCommand( "simple_toggle" )
end

end)

end