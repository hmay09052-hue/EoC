if SERVER then
    util.AddNetworkString("CW_MedicLog")
    util.AddNetworkString("CW_UpdateArmor")
    util.AddNetworkString("CW_UpdateInjury")
    util.AddNetworkString("CW_StartTreatment")
    util.AddNetworkString("CW_EndTreatment")
    util.AddNetworkString("CW_CancelTreatment")
    print("[CW-Combat] Netzwerkstrings registriert!")
end

if CLIENT then
    net.Receive("CW_MedicLog", function()
        local message = net.ReadString()
        local color = net.ReadColor()
        chat.AddText(color, "[MEDIC] ", color_white, message)
    end)
end