att.PrintName = "Anti-Tank Mode"
att.Icon = Material("entities/arccw/kraken/atts/at.png")
att.Description = "Set the weapon mode to anti-tank. It will greatly improve its performance against vehicles"

att.Slot = "sw_mode_rifle"

att.Override_MuzzleEffect = "arccw_kraken_sw_muzzle_red"
att.Override_Tracer = "new_tracer_red"
att.Override_DamageType = DMG_BLAST
att.Mult_RPM = 0.5
att.MuzzleFlashColor = Color(250, 0, 0)

att.Mult_Damage = 0.8
att.Mult_DamageMin = 1.10
att.Mult_Range = 0.3

att.Mult_Recoil = 2.5
att.Mult_RecoilSide = 1.2
att.Mult_VisualRecoilMult = 1.2

att.Desc_Pros = {}
att.Desc_Cons = {}

att.NotForNPCs = true
att.AutoStats = true

att.Hook_GetCapacity = function(wep, cap)
    return math.Clamp(math.Round(wep.RegularClipSize * 1), 1, 15)
end

att.Hook_BulletHit = function(wep, data)
    local ent = data.tr.Entity
    util.BlastDamage(wep, wep:GetOwner(), data.tr.HitPos, 96, wep:GetDamage(data.range))
    if ent:IsValid() and ent:GetClass() == "npc_helicopter" then
        data.dmgtype = DMG_AIRBOAT
    end
end