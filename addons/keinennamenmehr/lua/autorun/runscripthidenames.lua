--[[
    Echoes of Clones - Namen ausblenden
    Blendet die Standard-Namensanzeige beim Anschauen (TargetID) und die Kill-Meldungen oben rechts aus.
    Namen über den Köpfen zeigt das SymChars-Namensschild.

    Ersetzt das alte Script von le0nid0s: kein SendLua mehr, keine veralteten usermessages und die
    Client-Einstellung hud_deathnotice_time der Spieler wird nicht mehr dauerhaft verstellt.

    Superadmins: Konsole "toggleHideNames" schaltet um.
]]

AddCSLuaFile()

local function Hidden()
    return GetGlobalBool("eoc_hidenames", true)
end

if SERVER then
    concommand.Add("toggleHideNames", function(ply)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        local hide = not Hidden()
        SetGlobalBool("eoc_hidenames", hide)
        PrintMessage(HUD_PRINTTALK, hide and "Names are hidden" or "Names are shown")
    end)
    return
end

hook.Add("HUDDrawTargetID", "eoc_hidenames", function()
    if Hidden() then return false end
end)

hook.Add("DrawDeathNotice", "eoc_hidenames", function()
    if Hidden() then return false end
end)
