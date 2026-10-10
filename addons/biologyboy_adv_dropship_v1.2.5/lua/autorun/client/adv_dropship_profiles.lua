--[[
_______   ___   ________   ___        ________   ________       ___    ___ 
|\   __  \ |\  \ |\   __  \ |\  \      |\   __  \ |\   ____\     |\  \  /  /|
\ \  \|\ /_\ \  \\ \  \|\  \\ \  \     \ \  \|\  \\ \  \___|     \ \  \/  / /
 \ \   __  \\ \  \\ \  \\\  \\ \  \     \ \  \\\  \\ \  \  ___    \ \    / / 
  \ \  \|\  \\ \  \\ \  \\\  \\ \  \____ \ \  \\\  \\ \  \|\  \    \/  /  /  
   \ \_______\\ \__\\ \_______\\ \_______\\ \_______\\ \_______\ __/  / /    
 ___\|_______|_\|__| \|_______| \|_______| \|_______| \|_______||\___/ /     
|\   __  \ |\   __  \     |\  \  /  /|                          \|___|/      
\ \  \|\ /_\ \  \|\  \    \ \  \/  / /                                       
 \ \   __  \\ \  \\\  \    \ \    / /                                        
  \ \  \|\  \\ \  \\\  \    \/  /  /                                         
   \ \_______\\ \_______\ __/  / /                                           
    \|_______| \|_______||\___/ /                                            
                         \|___|/                                             
    Created by Biology Boy: https://steamcommunity.com/id/ninguemph/ 
    Purchased content: https://discord.gg/UDXKJjdrkT
]]--
ADV_DROPSHIP_PROFILES = ADV_DROPSHIP_PROFILES or {}

local PROFILE_FILE = "adv_dropship_profiles.txt"

local function LoadProfiles()
    if not file.Exists(PROFILE_FILE, "DATA") then return {} end
    local json = file.Read(PROFILE_FILE, "DATA")
    if not json or json == "" then return {} end
    return util.JSONToTable(json) or {}
end

local function SaveProfiles(tbl)
    file.Write(PROFILE_FILE, util.TableToJSON(tbl, true))
end

function ADV_DROPSHIP_PROFILES.Save(name, data)
    local profiles = LoadProfiles()
    profiles[name] = data
    SaveProfiles(profiles)
    return true
end

function ADV_DROPSHIP_PROFILES.Load(name)
    local profiles = LoadProfiles()
    return profiles[name]
end

function ADV_DROPSHIP_PROFILES.Delete(name)
    local profiles = LoadProfiles()
    if not profiles[name] then return false end
    profiles[name] = nil
    SaveProfiles(profiles)
    return true
end

function ADV_DROPSHIP_PROFILES.List()
    local profiles = LoadProfiles()
    local keys = {}
    for k in pairs(profiles) do table.insert(keys, k) end
    table.sort(keys)
    return keys
end
