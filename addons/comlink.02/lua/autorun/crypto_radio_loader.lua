-- Militärisches Funksystem
-- Lädt Config, Server- und Client-Dateien

CryptoRadio = CryptoRadio or {}

if SERVER then
    AddCSLuaFile("crypto_radio/sh_config.lua")
    AddCSLuaFile("crypto_radio/cl_crypto.lua")
    AddCSLuaFile("crypto_radio/cl_comlink.lua")

    include("crypto_radio/sh_config.lua")
    include("crypto_radio/sv_crypto.lua")
    include("crypto_radio/sv_commands.lua")
else
    include("crypto_radio/sh_config.lua")
    include("crypto_radio/cl_crypto.lua")
    include("crypto_radio/cl_comlink.lua")
end
