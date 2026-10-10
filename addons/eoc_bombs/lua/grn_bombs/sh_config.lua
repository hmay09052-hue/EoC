GRN_Bombs = GRN_Bombs or {}

GRN_Bombs.Config = GRN_Bombs.Config or {}
local CFG = GRN_Bombs.Config

CFG.ChatCommands = { '!bombs', '/bombs' }
CFG.AllowedRanks = {
    ['superadmin'] = true,
    ['admin'] = true,
    ['soporte'] = true,
    ['moderator'] = true,
    ['eventmaster'] = true,
}

CFG.DataFile = 'grn_bombs/bombs.json'
CFG.EntityClass = 'grn_bomb_entity'
CFG.DefaultLanguage = 'en'
CFG.MaxBombs = 256
CFG.SpawnDistance = 160
CFG.BeepSound = 'buttons/blip1.wav'
CFG.ExplodeSound = 'BaseExplosionEffect.Sound'
CFG.GasDamageInterval = 1
CFG.GasDuration = 12
CFG.GasRadius = 300
CFG.GlowColorByType = {
    explosive = Color(231, 76, 60),
    training  = Color(58, 143, 223),
    gas       = Color(46, 204, 113),
}
CFG.DefaultTemplates = {
    {
        id = 1,
        name = 'IED Mk.I',
        category = 'Explosive',
        type = 'explosive',
        model = 'models/props_combine/combine_mine01.mdl',
        minigame = 'wirecutting',
        difficulty = 'hard',
        timer = 60,
        radius = 400,
        damage = 600,
        force = 900,
        effects = {'env_explosion','env_fire'},
        particles = 'explosion_huge',
        particleCount = 5,
        rewardMoney = true,
        moneyAmt = 750,
        moneyNotify = 'both',
        reqWeapon = false,
        weaponClass = '',
        weaponMsg = '',
        visible = true,
        beep = true,
        glow = false,
    },
    {
        id = 2,
        name = 'Training Charge',
        category = 'Training',
        type = 'training',
        model = 'models/Gibs/HGIBS.mdl',
        minigame = 'sequence',
        difficulty = 'easy',
        timer = 45,
        radius = 220,
        damage = 25,
        force = 100,
        effects = {'env_smokestack'},
        particles = 'smoke_exhaust',
        particleCount = 3,
        rewardMoney = false,
        moneyAmt = 0,
        moneyNotify = 'chat',
        reqWeapon = false,
        weaponClass = '',
        weaponMsg = '',
        visible = true,
        beep = true,
        glow = true,
    }
}

function GRN_Bombs.HasAccess(ply)
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end
    local group = string.lower(ply:GetUserGroup() or '')
    return CFG.AllowedRanks[group] == true
end

function GRN_Bombs.ChatMessage(ply, msgKey, ...)
    if not IsValid(ply) then return end
    local phrase
    if isfunction(GRN_Bombs.GetPhrase) then
        phrase = GRN_Bombs.GetPhrase(msgKey, CFG.DefaultLanguage, ...)
    else
        local phrases = GRN_Bombs.Phrases or {}
        local tbl = phrases[CFG.DefaultLanguage] or phrases.en or {}
        phrase = tbl[msgKey] or (phrases.en and phrases.en[msgKey]) or tostring(msgKey or '')
        if select('#', ...) > 0 then
            local ok, formatted = pcall(string.format, phrase, ...)
            if ok then phrase = formatted end
        end
    end
    ply:ChatPrint('[grn_bombs] ' .. phrase)
end
