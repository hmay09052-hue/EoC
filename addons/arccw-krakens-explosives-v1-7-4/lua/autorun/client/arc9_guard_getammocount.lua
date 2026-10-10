if CLIENT then
    local meta = FindMetaTable("Player")
    if meta and not meta._ARC9_Guard_GetAmmoCount then
        meta._ARC9_Guard_GetAmmoCount = meta.GetAmmoCount
        function meta:GetAmmoCount(ammoid)
            if ammoid == nil then return 0 end
            if isstring(ammoid) then ammoid = game.GetAmmoID(ammoid) end
            if not isnumber(ammoid) then return 0 end
            return self:_ARC9_Guard_GetAmmoCount(ammoid)
        end
    end
end
