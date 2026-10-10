if CLIENT then
    matproxy.Add( {
        name = "ArcCW_GALAMMO",
        init = function( self, mat, values )
            self.ResultTo = values.resultvar
            self.Prefix = values.prefixstring
        end,
        bind = function( self, mat, ent )
                local Place = self.ResultTo
                local texture

                if LocalPlayer():GetActiveWeapon() then
                    local OurWeapon = LocalPlayer():GetActiveWeapon()
                    if OurWeapon.ArcCW then
                        local KnowYourPlace = string.sub(string.reverse(OurWeapon:Clip1()), Place, Place)

                        if OurWeapon.BottomlessClip == true then
                            KnowYourPlace = string.sub(string.reverse(OurWeapon:Ammo1()), Place, Place)
                        end

                        if (OurWeapon:GetClass() == "arccw_apex_eva" and OurWeapon:GetMaxClip1() == 16) or (OurWeapon:GetClass() == "arccw_apex_mozambique" and OurWeapon:GetMaxClip1() == 12) then
                            KnowYourPlace = string.sub(string.reverse(math.ceil(OurWeapon:Clip1() / 2)), Place, Place)
                        end

                        local digits = string.format( tonumber(KnowYourPlace) or 0 )


                        texture = self.Prefix .. digits
                    end
                end

                if texture then
                    mat:SetTexture( "$basetexture", texture )
                end
        end
    } )
    -- DC-15 / DC-17m (aus Republic Essentials). Alle drei ArcCW-Packs hatten eine Datei mit diesem Namen,
    -- dadurch ging je nach Ladereihenfolge ein Teil der Munitionsanzeigen verloren. Jetzt eine gemeinsame Datei.
    matproxy.Add( {
        name = "ArcCW_DC15AMMO",
        init = function( self, mat, values )
            self.ResultTo = values.resultvar
            self.Prefix = values.prefixstring
        end,
        bind = function( self, mat, ent )
                local Place = self.ResultTo
                local texture

                if LocalPlayer():GetActiveWeapon() then
                    local OurWeapon = LocalPlayer():GetActiveWeapon()
                    local KnowYourPlace = string.sub(string.reverse(OurWeapon:Clip1()), Place, Place)
                    local digits = string.format( tonumber(KnowYourPlace) or 0 )

                    texture = self.Prefix .. digits
                end

                if texture then
                    mat:SetTexture( "$basetexture", texture )
                else end
        end
    } )
    matproxy.Add( {
        name = "ArcCW_DC17MAMMO",
        init = function( self, mat, values )
            self.ResultTo = values.resultvar
            self.Prefix = values.prefixstring
        end,
        bind = function( self, mat, ent )
                local Place = self.ResultTo
                local texture

                if LocalPlayer():GetActiveWeapon() then
                    local OurWeapon = LocalPlayer():GetActiveWeapon()
                    local KnowYourPlace = string.sub(string.reverse(OurWeapon:Clip1()), Place, Place)
                    local digits = string.format( tonumber(KnowYourPlace) or 0 )

                    texture = self.Prefix .. digits
                end

                if texture then
                    mat:SetTexture( "$basetexture", texture )
                else end
        end
    } )
end
