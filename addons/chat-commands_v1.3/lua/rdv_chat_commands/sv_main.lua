util.AddNetworkString("RDV_CHAT_COMMANDS_ADMIN")
util.AddNetworkString("RDV_CHAT_COMMANDS_CREATE")
util.AddNetworkString("RDV_CHAT_COMMANDS_DELETE")
util.AddNetworkString("RDV_CHAT_COMMANDS_NETWORK")
util.AddNetworkString("RDV_CHAT_COMMANDS_SendMSG")

local PATH = "rdv/chat_commands"

local function SAVE()
    local DATA = util.TableToJSON(RDV.CHAT_COMMANDS.LIST)

    file.CreateDir(PATH)

    file.Write(PATH.."/data.json", DATA)
end

local function READ()
    if file.Exists(PATH.."/data.json", "DATA") then
        local DATA = file.Read(PATH.."/data.json", "DATA")

        if !DATA then return end

        RDV.CHAT_COMMANDS.LIST = util.JSONToTable(DATA)
    end
end
READ()

hook.Add("PlayerReadyForNetworking", "RDV_CHAT_COMMANDS_NETWORK", function(P)
    local DATA = RDV.CHAT_COMMANDS.LIST

    if table.Count(DATA) > 0 then
        local COMPRESS = util.Compress(util.TableToJSON(DATA))

        local BYTES = #COMPRESS
        
        net.Start("RDV_CHAT_COMMANDS_NETWORK")
            net.WriteUInt( BYTES, 16 )
            net.WriteData( COMPRESS, BYTES )
        net.Broadcast()
    end
end )

local DELAYS = {}

local function GetRank(P)
    local B, R = nil, nil
            
    if RDV.RANK then
        B = RDV.RANK.GetPlayerRankTree(P)
        R = RDV.RANK.GetPlayerRank(P)
    elseif MRS then
        B = MRS.GetPlayerGroup(P:Team())
        R = MRS.GetPlyRank(P, B)
    end

    return B, R
end

hook.Add("PlayerSay", "RDV_CHAT_COMMANDS_PlayerSay", function(P, TXT)
    if ( TXT == RDV.CHAT_COMMANDS.CFG.COMMAND ) then
        if RDV.CHAT_COMMANDS.CFG.ADMINS[P:GetUserGroup()] or P:IsSuperAdmin() then
            net.Start("RDV_CHAT_COMMANDS_ADMIN")
            net.Send(P)
        else
            RDV.LIBRARY.AddText(P, Color(255,0,0), "[COMMANDS] ", color_white, RDV.LIBRARY.GetLang(nil, "CHAT_noPerms"))
        end

        return ""
    end

    local SUB = string.Explode(" ", TXT)
    local CFG = RDV.CHAT_COMMANDS.LIST

    if SUB[1] and CFG[SUB[1]] then
        DELAYS[P:SteamID64()] = DELAYS[P:SteamID64()] or {}

        if DELAYS[P:SteamID64()][SUB[1]] and DELAYS[P:SteamID64()][SUB[1]] > CurTime() then return "" end

        CFG = CFG[SUB[1]]

        DELAYS[P:SteamID64()][SUB[1]] = CurTime() + ( CFG.DELAY or 1 )

        if !CFG.LINK and #SUB <= 1 then return "" end

        if CFG.ALIVE and !P:Alive() then return "" end

        if CFG.DisWithRelay and RDV.COMMUNICATIONS and !RDV.COMMUNICATIONS.GetCommsEnabled(P) then
            RDV.LIBRARY.AddText(P, Color(255,0,0), "[COMMANDS] ", color_white, RDV.LIBRARY.GetLang(nil, "CHAT_relayDown"))

            return ""
        end

        local T_ENABLED = false
        local R_ENABLED = false

        if CFG.STEAMS and table.Count(CFG.STEAMS) >= 1 then
            T_ENABLED = true
        end

        if CFG.RANKS and table.Count(CFG.RANKS) >= 1 then
            R_ENABLED = true
        end

        if T_ENABLED and !CFG.STEAMS[team.GetName(P:Team())] then return "" end 

        if R_ENABLED then
            local B, R = GetRank(P)
    
            if CFG.RANKS[B] then
                if ( CFG.RANKS[B] > R ) then return "" end
            else
                return ""
            end
        end

        local FILTER = RecipientFilter()

        local MSG = table.concat(SUB, " ", 2)

        if CFG.LINK then
            FILTER:AddPlayer(P)
        else
            for k, v in ipairs(player.GetHumans()) do
                if !CFG.GLOBAL and v:GetPos():DistToSqr(P:GetPos()) > CFG.RADIUS then continue end

                if CFG.NoTeamSee or RDV.CHAT_COMMANDS.CFG.ADMINS[v:GetUserGroup()] then
                    FILTER:AddPlayer(v)
                    continue
                end

                if R_ENABLED then
                    local B, R = GetRank(v)
            
                    if CFG.RANKS[B] then
                        if ( CFG.RANKS[B] > R ) then return "" end
                    else
                        return ""
                    end
                end

                if T_ENABLED then
                    if CFG.STEAMS[team.GetName(v:Team())] then
                        FILTER:AddPlayer(v)
                    end
                else
                    FILTER:AddPlayer(v)
                end
            end
        end

        net.Start("RDV_CHAT_COMMANDS_SendMSG")
            net.WriteString(SUB[1])
            net.WriteString(MSG)
            net.WriteUInt(P:EntIndex(), 8)
        net.Send(FILTER)

        return ""
    end
end )

net.Receive("RDV_CHAT_COMMANDS_DELETE", function(_, P)
    if !RDV.CHAT_COMMANDS.CFG.ADMINS[P:GetUserGroup()] and !P:IsSuperAdmin() then P:Kick() return end

    local UID = net.ReadString()

    if RDV.CHAT_COMMANDS.LIST and RDV.CHAT_COMMANDS.LIST[UID] then
        RDV.CHAT_COMMANDS.LIST[UID] = nil

        net.Start("RDV_CHAT_COMMANDS_DELETE")
            net.WriteString(UID)
        net.Broadcast()

        SAVE()
    end
end )

net.Receive("RDV_CHAT_COMMANDS_CREATE", function(_, P)
    if !RDV.CHAT_COMMANDS.CFG.ADMINS[P:GetUserGroup()] and !P:IsSuperAdmin() then P:Kick() return end

    --[[
    --  Read Data
    --]]

    local BYTES = net.ReadUInt( 16 )
    local DATA = net.ReadData(BYTES)

    local DECOMPRESSED = util.Decompress(DATA)
    local TAB = util.JSONToTable(DECOMPRESSED)

    TAB.CREATOR = P:SteamID64()
    TAB.COMMAND = string.lower(TAB.COMMAND)

    RDV.CHAT_COMMANDS.LIST[TAB.COMMAND] = TAB

    --[[
    --  Send Data
    --]]

    local COMPRESS = util.Compress(util.TableToJSON(TAB))

    local BYTES = #COMPRESS

    net.Start("RDV_CHAT_COMMANDS_CREATE")
        net.WriteUInt( BYTES, 16 )
        net.WriteData( COMPRESS, BYTES )
    net.Broadcast()

    SAVE()
end )