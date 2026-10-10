local Net   = KrakenSquad.Net
local Squad = KrakenSquad.SquadObj

Net.Receive("KS.AdminConfigSync", function()
    local tbl = KF.Net.ReadJSON(65536)
    if not tbl then return end
    for k, v in pairs(tbl) do KrakenSquad.Config[k] = v end
    if tbl.language then KrakenSquad.SetLang(tbl.language) end
    hook.Run("KrakenSquad.ConfigUpdated")
end)

Net.Receive("KS.SquadCreated", function()
    local id = net.ReadUInt(16)
    local s = setmetatable({
        id = id,
        name   = net.ReadString(),
        public = net.ReadBool(),
        preset = net.ReadBool(),
    }, Squad)
    KrakenSquad.Cache[id] = s
    hook.Run("KrakenSquad.SquadCreated", s)
end)

Net.Receive("KS.SquadRemoved", function()
    local id = net.ReadUInt(16)
    if LocalPlayer():KSInSquad(id) then hook.Run("KrakenSquad.LeftSquad") end
    KrakenSquad.Cache[id] = nil
    hook.Run("KrakenSquad.SquadRemoved", id)
end)

Net.Receive("KS.MembersUpdated", function()
    local id = net.ReadUInt(16)
    local count = net.ReadUInt(8)
    local uids = {}
    for i = 1, count do uids[i] = net.ReadUInt(16) end
    local s = KrakenSquad.Cache[id] or setmetatable({ id = id, name = "Squad" }, Squad)
    KrakenSquad.Cache[id] = s
    s._memberUserIDs = uids
    hook.Run("KrakenSquad.MembersUpdated", id)
end)

Net.Receive("KS.InvitePlayer", function()
    hook.Run("KrakenSquad.InviteReceived", net.ReadEntity(), net.ReadString())
end)

Net.Receive("KS.Broadcast", function()
    local id      = net.ReadUInt(16)
    local msg     = net.ReadString()
    local msgType = net.ReadString()
    hook.Run("KrakenSquad.BroadcastReceived", id, msg)
    if msgType == "member_event" and KrakenSquad.GetClientPref("show_squad_events", true) == false then return end
    chat.AddText(KrakenSquad.P("Accent"), KrakenSquad.L("chat_prefix"), color_white, msg)
end)

Net.Receive("KS.Communications", function()
    hook.Run("KrakenSquad.CommReceived", net.ReadString(), net.ReadEntity())
end)

Net.Receive("KS.CommsPing", function()
    hook.Run("KrakenSquad.PingReceived", net.ReadVector(), net.ReadEntity(), net.ReadString())
end)

Net.Receive("KS.RequestCommand", function()
    hook.Run("KrakenSquad.CommandReceived", net.ReadString(), net.ReadEntity())
end)

Net.Receive("KS.RequestSquads", function()
    local data = KF.Net.ReadJSON(65536)
    if not data then return end
    for _, v in ipairs(data) do
        local s = KrakenSquad.Cache[v.id]
        if s then
            s.name, s.public, s.preset = v.name, v.public, v.preset
        else
            KrakenSquad.Cache[v.id] = setmetatable({
                id = v.id, name = v.name, public = v.public, preset = v.preset,
            }, Squad)
        end
    end
    hook.Run("KrakenSquad.SquadListReceived", data)
end)

Net.Receive("KS.LayoutSync", function()
    local layout = KF.Net.ReadJSON(8192)
    if not layout then return end
    KrakenSquad.SetConfig("layout", layout)
    hook.Run("KrakenSquad.LayoutUpdated")
end)

Net.Receive("KS.NPCCreator",     function() KrakenSquad.OpenCreator()    end)
Net.Receive("KS.NPCList",        function() KrakenSquad.OpenPublicList() end)
Net.Receive("KS.OpenPublicList", function() KrakenSquad.OpenPublicList() end)
Net.Receive("KS.OpenAdminMenu",  function() KrakenSquad.OpenAdminMenu()  end)
Net.Receive("KS.NPCTerminal",    function() KrakenSquad.OpenTerminal()   end)

hook.Add("InitPostEntity", "KrakenSquad.ClientInit", function()
    timer.Simple(2, function()
        net.Start("KS.RequestSquads") net.SendToServer()
        net.Start("KS.LayoutSync")    net.SendToServer()
    end)
end)
