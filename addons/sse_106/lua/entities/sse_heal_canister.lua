AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Bacta Canister"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true
ENT.Editable = true

function ENT:Initialize()

    self:SetModel( SSE.Config.HealCanister["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox



    self.SSE_HUDName = SSE.Config.HealCanister["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( CONTINUOUS_USE )
    end
    self:PhysWake()
end

function ENT:SetupDataTables()

 
    self:NetworkVar( "Float",	0, "HealContent",	{ KeyName = "healcontent",	Edit = { type = "Float",		order = 1, min = 0, max = 1000000 } } )

    if SERVER then
        self:SetHealContent(SSE.Config.HealCanister["DefaultHealth"])
    end

end

if SERVER then
        

    local lastUseTime = 0

    function ENT:Use( activator, caller )

        if IsValid(activator) and activator:IsPlayer() then
            local currentTime = CurTime()
            if currentTime - lastUseTime >= SSE.Config.HealCanister["Delay"] then
                lastUseTime = currentTime

                local healAmount = SSE.Config.HealCanister["AddHealth"] 
                if self:GetHealContent() > 0 then
                    local maxHealth = activator:GetMaxHealth()
                    local currentHealth = activator:Health()
                    local newHealth = math.min(currentHealth + healAmount, maxHealth)
                    if newHealth > currentHealth then
                        self:SetHealContent(self:GetHealContent() - healAmount)
                        if self:GetHealContent() <= 0 then
                            self:Remove()
                        end
                        activator:SetHealth(newHealth)
                        self:EmitSound(SSE.Config.HealCanister["Sound"] )
                    end
                end
            end
        end
    end



end

