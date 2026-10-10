AddCSLuaFile()

ENT.Base      = "garlog_structure"
ENT.PrintName = "Munitionsdepot"
ENT.Category  = "GAR Logistik"
ENT.Spawnable = false
ENT.StructID  = "ammodepot"
ENT.SupplyRes = "ammo"

if SERVER then
    function ENT:OnUse(ply)
        local def = self:GetDef()
        local now = CurTime()
        if (ply.GARLogAmmoCD or 0) > now then return end
        ply.GARLogAmmoCD = now + (def.cooldown or 1.5)

        local locId = self:GetLocId()
        if not locId then return end
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) then
            GARLog.NotifyOnce(ply, "ammo_nowep", "Nimm die Waffe in die Hand, die du aufmunitionieren willst.", "info")
            return
        end

        local types = {}
        local pri, sec = wep:GetPrimaryAmmoType(), wep:GetSecondaryAmmoType()
        if pri and pri >= 0 then types[#types + 1] = { t = pri, clip = wep:GetMaxClip1() } end
        if sec and sec >= 0 and sec ~= pri then types[#types + 1] = { t = sec, clip = wep:GetMaxClip2() } end
        if #types == 0 then
            GARLog.NotifyOnce(ply, "ammo_none", "Diese Waffe braucht keine Munition.", "info")
            return
        end

        local stock = GARLog.Stock(locId, "ammo")
        if stock <= 0 then
            GARLog.NotifyOnce(ply, "ammo_empty", "Munitionsdepot leer – Nachschub anfordern!", "err")
            return
        end

        local perUnit = def.roundsPerUnit or 20
        local budget, given = stock * perUnit, 0
        for _, e in ipairs(types) do
            local target = (e.clip and e.clip > 0) and e.clip * (def.refillClips or 4) or (def.fallbackAmmo or 120)
            local maxCarry = game.GetAmmoMax(e.t)
            if maxCarry and maxCarry > 0 then target = math.min(target, maxCarry) end
            local give = math.min(math.max(0, target - ply:GetAmmoCount(e.t)), budget - given)
            if give > 0 then
                ply:GiveAmmo(give, e.t, false)
                given = given + give
            end
        end

        if given <= 0 then
            GARLog.NotifyOnce(ply, "ammo_full", "Munition bereits aufgefüllt.", "info", 5)
            return
        end
        GARLog.TakeUpTo(locId, "ammo", math.max(1, math.ceil(given / perUnit)), true)
        self:EmitSound(GARLog.Config.Sounds.Ammo, 65)
    end
else
    function ENT:InfoLines()
        local C = GARLog.Col
        return {
            { "MUNITION: " .. GARLog.FmtNum(self:GetSupply()) .. " MUN", C.text, self:GetSupply() / math.max(1, self:GetSupplyCap()), GARLog.Res.ammo.color },
            { "E: AUFMUNITIONIEREN", C.soft },
        }
    end
end
