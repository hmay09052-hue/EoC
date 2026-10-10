-- Performance: remember the previous hibernate setting so an empty server can sleep again
-- once the status was posted, and retry failed posts every 10s instead of every tick.
local hibernateCvar = GetConVar("sv_hibernate_think")
local oldHibernate = hibernateCvar and hibernateCvar:GetString() or "0"
RunConsoleCommand("sv_hibernate_think", "1")

local posting = false
local nextTry = 0
hook.Add("Think", "crashmenu", function()
    if posting or nextTry > SysTime() then return end
    nextTry = SysTime() + 1
    if game.GetIPAddress():match("^0.0.0.0:%d+$") or game.GetIPAddress():match("loopback") then return end
    posting = true
    HTTP({
        url = ("%s/server/status"):format(crashmenu.Host),
        method = "POST",
        body = util.TableToJSON({
            host = game.GetIPAddress(),
            hostname = GetHostName(),
            chatroomUuid = crashmenu.Config.ChatRoomID
        }),
        type = 'application/json; charset=utf-8',
        success = function(code, res)
            hook.Remove("Think", "crashmenu")
            posting = false
            if not (sam and sam.SQL and sam.SQL.IsMySQL and sam.SQL.IsMySQL()) then RunConsoleCommand("sv_hibernate_think", oldHibernate) end
            Msg(("[crashmenu] %s "):format(code))print("POST: " .. res)
            SetGlobal2String("crashmenu.ServerHost", game.GetIPAddress())
        end,
        failed = function()
            posting = false
            nextTry = SysTime() + 10
        end
    })
end)
