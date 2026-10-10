AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Closet"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true

function ENT:Initialize()

    self:SetModel( SSE.Config.Closet["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   
    self:SetSolid( SOLID_VPHYSICS )       



    self.SSE_HUDName = SSE.Config.Closet["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end



if SERVER then
        

        util.AddNetworkString("SSE_ClosetMenu")
        util.AddNetworkString("SSE_Closet_SetModel")
        util.AddNetworkString("SSE_Closet_SetSkin")
        util.AddNetworkString("SSE_Closet_SetBodygroup")
    
        function ENT:Use(activator, caller)
            net.Start("SSE_ClosetMenu")
            net.Send(activator)
        end
    
        local function handleModelChange(len, ply)
            local model = net.ReadString()
            if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
    
            if table.HasValue(SSE.Config.Closet["GetModels"](ply), model) then
                ply:SetModel(model)
            end
        end
        net.Receive("SSE_Closet_SetModel", handleModelChange)
    
        local function handleSkinChange(len, ply)
            local skin = net.ReadInt(8)
            if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
    
            if skin < ply:SkinCount() then
                ply:SetSkin(skin)
            end
        end
        net.Receive("SSE_Closet_SetSkin", handleSkinChange)
    
        local function handleBodygroupChange(len, ply)
            local bodygroup = net.ReadInt(8)
            local submodel = net.ReadInt(8)
            if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
    
            ply:SetBodygroup(bodygroup, submodel)
        end
        net.Receive("SSE_Closet_SetBodygroup", handleBodygroupChange)
    end
    
    if CLIENT then
        local function createClosetSection(name, parent)
            local section = vgui.Create("DPanel", parent)
            section:Dock(TOP)
            section:DockMargin(0, 0, 0, 5)
            section:SetTall(SSEH(80)) -- Default initial height for just the label
            section:SetDrawBackground(false)
        
            -- Abschnittstitel im Server-Design (Linie + Aurebesh rechts)
            local sectionLabel = vgui.Create("DPanel", section)
            sectionLabel:Dock(TOP)
            sectionLabel:SetTall(SSEH(40))
            sectionLabel:DockMargin(0, 0, SSEW(10), SSEH(4))
            function sectionLabel:Paint(w, h)
                SSE.UI.Section(name, 0, 0, w)
            end
        
            local sectionContent = vgui.Create("DIconLayout", section)
            sectionContent:Dock(FILL)
            sectionContent:SetSpaceY(5) -- Reduced spacing to avoid excessive height
            sectionContent:SetSpaceX(5)

        
            -- Adjust the section height based on the number of rows
            function sectionContent:adjustSectionHeight()
                local parentWidth = SSE_ClosetFrame:GetWide() * 0.48
                local totalWidth = 0
                local rows = 0

                for _, child in ipairs(self:GetChildren()) do
                    totalWidth = totalWidth + SSEW(35) + 5

                    if totalWidth > parentWidth then
                        rows = rows + 1
                        totalWidth = SSEW(35) + 5 -- Reset totalWidth for the next row
                    end
                end

                section:SetTall(SSEH(80) + rows * SSEH(45))
            end
        
            return sectionContent
        end
        
        
        function SSE_OpenClosetMenu()
            if SSE_ClosetFrame then SSE_ClosetFrame:Remove() end
            SSE_ClosetFrame = SSE:DefaultFrame(SSE.Config.Closet["FrameTitle"] or "Kleiderschrank")
            SSE_ClosetFrame:SetSize(SSEW(1200), ScrH() * 0.8)
            SSE_ClosetFrame:Center()
    
            local leftPanel = vgui.Create("DPanel", SSE_ClosetFrame)
            leftPanel:Dock(LEFT)
            leftPanel:SetWide(SSE_ClosetFrame:GetWide() * 0.48)
            leftPanel.Paint = nil
    
            local saveBtns = vgui.Create("DPanel", leftPanel)
            saveBtns:Dock(TOP)
            saveBtns:SetTall(SSEH(50))
            saveBtns.Paint = nil
    
            local function saveCurrentState()
                local playerModel = LocalPlayer():GetModel()
                local bodygroups = {}
                for k, v in pairs(LocalPlayer():GetBodyGroups()) do
                    bodygroups[v.id] = LocalPlayer():GetBodygroup(v.id)
                end
                local skin = LocalPlayer():GetSkin()
                local saveData = {bodygroups = bodygroups, skin = skin}
                cookie.Set("SSE-Closet-"..playerModel, util.TableToJSON(saveData))
    
                SSE_OpenClosetMenu()
            end
    
            local function loadSavedState()
                local playerModel = LocalPlayer():GetModel()
                local savedData = cookie.GetString("SSE-Closet-"..playerModel)
                if savedData then
                    savedData = util.JSONToTable(savedData)
    
                    net.Start("SSE_Closet_SetSkin")
                    net.WriteInt(savedData.skin, 8)
                    net.SendToServer()
    
                    SSE_ClosetFrame.modelViewer.Entity:SetSkin(savedData.skin)
                    for id, bodygroup in pairs(savedData.bodygroups) do
                        net.Start("SSE_Closet_SetBodygroup")
                        net.WriteInt(id,8)
                        net.WriteInt(bodygroup,8)
                        net.SendToServer()
    
                        SSE_ClosetFrame.modelViewer.Entity:SetBodygroup(id, bodygroup)
                    end
                end
            end
    
            local saveBtn = SSE:Button(saveBtns, SSE.Config.Closet["Save"], function() saveCurrentState() end, "bc")
            saveBtn:Dock(RIGHT)
            saveBtn:DockMargin(5, 0, 5, 0)
    
            local loadBtn = SSE:Button(saveBtns, SSE.Config.Closet["Load"], function() loadSavedState() end, "bc")
            loadBtn:Dock(RIGHT)
            loadBtn:DockMargin(5, 0, 5, 0)
    
            local playerModel = LocalPlayer():GetModel()
            local savedData = cookie.GetString("SSE-Closet-"..playerModel)
            if not savedData then
                loadBtn:SetVisible(false)
            end
    
            SSE_ClosetFrame.modelViewer = vgui.Create("DModelPanel", leftPanel)
            SSE_ClosetFrame.modelViewer:Dock(FILL)
            SSE_ClosetFrame.modelViewer:SetModel(LocalPlayer():GetModel())
            SSE_ClosetFrame.modelViewer:SetFOV(40)
    
            function SSE_ClosetFrame.modelViewer:UpdateModel()
                self.Entity:SetSkin(LocalPlayer():GetSkin())
                for _, v in pairs(LocalPlayer():GetBodyGroups()) do
                    self.Entity:SetBodygroup(v.id, LocalPlayer():GetBodygroup(v.id))
                end
                for k, v in pairs(LocalPlayer():GetMaterials()) do
                    if LocalPlayer():GetSubMaterial(k) ~= "" then
                        self.Entity:SetSubMaterial(k, LocalPlayer():GetSubMaterial(k))
                    end
                end
            end
    
            SSE_ClosetFrame.modelViewer:UpdateModel()
    
            function SSE_ClosetFrame.modelViewer:LayoutEntity(ent)
                if (self.bAnimated) then self:RunAnimation() end
                if (self.Dragging) then
                    local mx, my = gui.MousePos()
                    self.Angles = self.Angles - Angle(0, (self.Dragging[1] - mx) * 0.5, 0)
                    self.Dragging[1] = mx
                end
    
                if (self.Holding) then
                    local mx, my = gui.MousePos()
                    self.Angles = self.Angles - Angle((self.Holding[2] - my) * 0.5, 0, 0)
                    self.Holding[2] = my
                end
    
                SSE_ClosetFrame.modelViewer:SetLookAt(Vector(0, 0, 50))
                SSE_ClosetFrame.modelViewer:SetCamPos(Vector(64, 0, 50))
                self.Entity:SetAngles(self.Angles)
            end
    
            function SSE_ClosetFrame.modelViewer:OnMousePressed(mousecode)
                if (mousecode == MOUSE_LEFT) then
                    self.Dragging = {gui.MousePos()}
                    self:MouseCapture(true)
                end
            end
    
            function SSE_ClosetFrame.modelViewer:OnMouseReleased(mousecode)
                if (mousecode == MOUSE_LEFT) then
                    self.Dragging = nil
                    self:MouseCapture(false)
                end
            end
    
            function SSE_ClosetFrame.modelViewer:OnMouseWheeled(delta)
                local minZoom, maxZoom = 20, 100
                local zoom = self:GetFOV() - delta * 5
                zoom = math.Clamp(zoom, minZoom, maxZoom)
                self:SetFOV(zoom)
                return true
            end
    
            SSE_ClosetFrame.modelViewer:SetLookAt(Vector(0, 0, 50))
            SSE_ClosetFrame.modelViewer:SetCamPos(Vector(64, 0, 50))
            SSE_ClosetFrame.modelViewer.Angles = Angle(0, 0, 0)
    
            local rightPanel = vgui.Create("DPanel", SSE_ClosetFrame)
            rightPanel:Dock(RIGHT)
            rightPanel:SetWide(SSE_ClosetFrame:GetWide() * 0.48)
            rightPanel.Paint = function(self, w, h)
                SSE.UI.Box(0, 0, 1, h, SSE.UI.col.line2)
                SSE.UI.Box(0, 0, 3, SSEH(60), SSE.UI.Accent())
            end
            rightPanel:DockPadding(SSEW(10), SSEH(10), 0, SSEH(10))
    
            local scrollPanel = SSE:ScrollBar(rightPanel)
            scrollPanel:Dock(FILL)
    
            local modelSection = createClosetSection("Modelle", scrollPanel)
            local models = SSE.Config.Closet["GetModels"](LocalPlayer())
            for name, model in pairs(models) do


   
                    local btn = SSE:Button(modelSection, name, function()
                        net.Start("SSE_Closet_SetModel")
                        net.WriteString(model)
                        net.SendToServer()
                        SSE_ClosetFrame:Remove()
                    end, "bc")
                    btn:SetWide(SSEW(35))  



            end
            modelSection:adjustSectionHeight()
    
            if LocalPlayer():SkinCount() - 1 > 1 then
                local skinSection = createClosetSection("Skins", scrollPanel)
                for i = 0, LocalPlayer():SkinCount() - 1 do
                    local btn = SSE:Button(skinSection, i, function()
                        net.Start("SSE_Closet_SetSkin")
                        net.WriteInt(i, 8)
                        net.SendToServer()
                        SSE_ClosetFrame.modelViewer.Entity:SetSkin(i)
                    end, "bc")
                    btn:SetWide(SSEW(35))
                end
                skinSection:adjustSectionHeight()
            end
    
            local bodygroups = {}
            for _, group in pairs(LocalPlayer():GetBodyGroups()) do
                local groupName = group.name
                bodygroups[groupName] = {}
                for submodel in pairs(group.submodels) do
                    table.insert(bodygroups[groupName], submodel)
                end
            end
    
            for groupName, submodels in pairs(bodygroups) do
                if #submodels < 2 then continue end
                local bodygroupSection = createClosetSection(groupName, scrollPanel)
                for submodelIndex, submodelName in pairs(submodels) do
                    local btn = SSE:Button(bodygroupSection, submodelName, function()
                        net.Start("SSE_Closet_SetBodygroup")
                        net.WriteInt(LocalPlayer():FindBodygroupByName(groupName),8)
                        net.WriteInt(submodelName,8)
                        net.SendToServer()
                        SSE_ClosetFrame.modelViewer.Entity:SetBodygroup(SSE_ClosetFrame.modelViewer.Entity:FindBodygroupByName(groupName), submodelName)
                    end, "bc")
                    btn:SetWide(SSEW(35))
                end
                bodygroupSection:adjustSectionHeight()
            end
        end
    
        net.Receive("SSE_ClosetMenu", function()
            SSE_OpenClosetMenu()
        end)
    end
    

