include("shared.lua")

-- Pfosten an beiden Enden, rein optisch
function ENT:BuildPosts()
    local cfg = EoCSport.Config.PullupBar
    self.Posts = {}
    for i = 1, 2 do
        local post = ClientsideModel(cfg.PostModel, RENDERGROUP_OPAQUE)
        if IsValid(post) then
            post:SetMaterial(cfg.Material)
            post:SetNoDraw(true)
            self.Posts[i] = post
        end
    end
end

function ENT:Draw()
    self:DrawModel()

    if not self.Posts then self:BuildPosts() end

    local cfg = EoCSport.Config.PullupBar
    local height = self:GetNW2Float("EoCSport_PostHeight", cfg.Height)
    local size = 11.86 -- Kantenlänge des PHX-Würfels 0.25
    local scale = Matrix()
    scale:Scale(Vector(0.6, 0.6, (height + 6) / size))

    for i, post in ipairs(self.Posts) do
        if IsValid(post) then
            local side = i == 1 and 1 or -1
            local top = self:LocalToWorld(Vector(0, side * (cfg.Length / 2 + 3), 0))
            post:SetPos(top - Vector(0, 0, height / 2 - 3))
            post:SetAngles(Angle(0, self:GetAngles().y, 0))
            post:EnableMatrix("RenderMultiply", scale)
            post:SetupBones()
            post:DrawModel()
        end
    end
end

function ENT:OnRemove()
    for _, post in ipairs(self.Posts or {}) do
        if IsValid(post) then post:Remove() end
    end
end

function ENT:Initialize()
    -- Pfosten reichen bis zum Boden; sonst wird die Stange zu früh ausgeblendet
    self:SetRenderBounds(Vector(-12, -60, -400), Vector(12, 60, 12))
end
