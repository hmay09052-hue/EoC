AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = (BattleGrid and BattleGrid.L and BattleGrid:L("ENTITY_JAMMER")) or "Signal Jammer"
ENT.Author = "Kraken"
ENT.Category = "Battle Grid"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "JamRadius", { KeyName = "jam_radius", Edit = { type = "Float", order = 1, min = 100, max = 10000, title = "Jam Radius" } })
    self:NetworkVar("Float", 1, "JamMaxHealth", { KeyName = "jam_max_health", Edit = { type = "Float", order = 2, min = 100, max = 50000, title = "Health" } })
    self:NetworkVar("Bool", 0, "JamHackable", { KeyName = "jam_hackable", Edit = { type = "Boolean", order = 3, title = "Hackable" } })
    self:NetworkVar("Bool", 1, "JamBeingHacked")
    self:NetworkVar("Float", 2, "JamHackProgress")
    self:NetworkVar("Entity", 0, "JamHacker")
    self:NetworkVar("Bool", 2, "JamDestroyed")
    self:NetworkVar("Int", 0, "JamDifficulty", { KeyName = "jam_difficulty", Edit = { type = "Int", order = 4, min = 1, max = 4, title = "Difficulty (1-4)" } })
    self:NetworkVar("Float", 3, "JamHackTime", { KeyName = "jam_hack_time", Edit = { type = "Float", order = 5, min = 1, max = 120, title = "Hack Time (seconds)" } })
end

if SERVER then
    function BattleGrid:BroadcastJammers(ply)
        local out = {}
        for _, ent in ipairs(ents.FindByClass("battlegrid_jammer")) do
            if not ent:GetJamDestroyed() then
                table.insert(out, { pos = ent:GetPos(), radius = ent:GetJamRadius(), entIndex = ent:EntIndex(), hackable = ent:GetJamHackable() })
            end
        end
        self.Net:SendJSON("SyncJammers", out, ply)
    end

    hook.Add("PhysgunDrop", "BattleGrid.JammerPhysgunDrop", function(_, ent)
        if IsValid(ent) and ent:GetClass() == "battlegrid_jammer" then BattleGrid:BroadcastJammers() end
    end)

    function ENT:Initialize()
        self:SetModel(BattleGrid:GetConfig("jammer_model"))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local health = BattleGrid:GetConfigNumber("jammer_default_health")
        self:SetHealth(health)
        self:SetMaxHealth(health)
        self:SetJamMaxHealth(health)

        self:SetJamRadius(BattleGrid:GetConfigNumber("jammer_default_radius"))
        self:SetJamHackable(BattleGrid:GetConfigBool("jammer_hackable"))
        self:SetJamDifficulty(BattleGrid:GetConfigNumber("jammer_default_difficulty"))
        self:SetJamHackTime(BattleGrid:GetConfigNumber("jammer_hack_time"))
        self:SetJamBeingHacked(false)
        self:SetJamHackProgress(0)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end

        timer.Simple(0, function()
            if IsValid(self) then BattleGrid:BroadcastJammers() end
        end)
    end

    function ENT:OnTakeDamage(dmg)
        if self:GetJamDestroyed() then return end
        self:SetHealth(self:Health() - dmg:GetDamage())
        if self:Health() <= 0 then
            self:BeginDestructionSequence()
        end
    end

    function ENT:BeginDestructionSequence()
        if self:GetJamDestroyed() then return end
        self:SetJamDestroyed(true)
        BattleGrid:Warn("Jammer ", self:EntIndex(), " destroyed at ", tostring(self:GetPos()))
        self:CancelHack()
        BattleGrid:BroadcastJammers()

        local boom = ents.Create("env_explosion")
        if IsValid(boom) then
            boom:SetKeyValue("spawnflags", 144)
            boom:SetKeyValue("iMagnitude", 10)
            boom:SetKeyValue("iRadiusOverride", 128)
            boom:SetPos(self:GetPos())
            boom:Spawn()
            boom:Fire("explode", "", 0)
        end

        local spark = ents.Create("env_spark")
        if IsValid(spark) then
            spark:SetKeyValue("spawnflags", 64)
            spark:SetKeyValue("MaxDelay", "0.5")
            spark:SetKeyValue("Magnitude", "2")
            spark:SetPos(self:GetPos() + Vector(0, 0, 10))
            spark:SetParent(self)
            spark:Spawn()
            spark:Activate()
            spark:Fire("StartSpark", "", 0)

            self.SparkEnt = spark
        end
    end

    function ENT:CanPlayerHack(ply)
        if not BattleGrid:IsMapAllowed() or not self:GetJamHackable() then return false end
        if self:GetJamBeingHacked() then return false end
        local whitelist = util.JSONToTable(BattleGrid:GetConfig("jammer_hack_whitelist")) or {}
        if #whitelist == 0 then return true end
        return BattleGrid:PlayerMatchesJobList(ply, whitelist)
    end

    function ENT:StartHack(ply)
        if not self:CanPlayerHack(ply) then return false end
        self:SetJamBeingHacked(true)
        self:SetJamHackProgress(0)
        self:SetJamHacker(ply)
        self._hackStartTime = CurTime()
        self._hackToken = math.random(100000, 999999)
        BattleGrid:Warn("Jammer ", self:EntIndex(), " hack started by ", ply:Nick(), " [", ply:SteamID(), "]")
        BattleGrid.Net:Send("JammerStartHack", function()
            net.WriteEntity(self)
            net.WriteFloat(self:GetJamHackTime())
            net.WriteUInt(math.Clamp(self:GetJamDifficulty(), 1, #BattleGrid.JammerDifficulty), 3)
            net.WriteUInt(self._hackToken, 20)
        end, ply)
        return true
    end

    function ENT:CancelHack(failed)
        local hacker = self:GetJamHacker()
        if IsValid(hacker) then
            BattleGrid.Net:Send("JammerHackClose", function() net.WriteBool(failed == true) end, hacker)
            if failed then self:ShockPlayer(hacker) end
        end
        self:SetJamBeingHacked(false)
        self:SetJamHackProgress(0)
        self:SetJamHacker(NULL)
        BattleGrid:Log("Jammer ", self:EntIndex(), " hack ", failed and "failed" or "cancelled")
    end

    function ENT:CompleteHack()
        self:SetJamBeingHacked(false)
        self:SetJamHackProgress(0)
        self:SetJamHacker(NULL)
        BattleGrid:Warn("Jammer ", self:EntIndex(), " hack completed successfully")
        self:BeginDestructionSequence()
    end

    function ENT:ShockPlayer(ply)
        if not IsValid(ply) then return end
        local dmg = BattleGrid:GetConfigNumber("jammer_shock_damage")
        local info = DamageInfo()
        info:SetDamage(dmg)
        info:SetDamageType(DMG_SHOCK)
        info:SetAttacker(self)
        info:SetInflictor(self)
        ply:TakeDamageInfo(info)

        local sp = EffectData()
        sp:SetOrigin(ply:GetPos() + Vector(0, 0, 40))
        sp:SetMagnitude(1)
        sp:SetScale(0.3)
        util.Effect("ElectricSpark", sp)
        ply:EmitSound("ambient/energy/zap" .. math.random(1, 9) .. ".wav", 65, math.random(90, 120))
    end

    function ENT:Think()
        if self:GetJamDestroyed() then
            self:NextThink(CurTime() + 1)
            return true
        end
        if self:GetJamBeingHacked() then
            local hacker = self:GetJamHacker()
            if not IsValid(hacker) or not hacker:Alive() or hacker:GetPos():DistToSqr(self:GetPos()) > (200 * 200) then
                self:CancelHack()
            end
        end
        self:NextThink(CurTime() + 0.2)
        return true
    end

    function ENT:Use(activator, caller)
        if not IsValid(caller) or not caller:IsPlayer() then return end
        if self:GetJamDestroyed() or not self:GetJamHackable() or self:GetJamBeingHacked() then return end
        if self:CanPlayerHack(caller) then
            self:StartHack(caller)
            return
        end
        caller:ChatPrint(BattleGrid:GetPrefixText() .. BattleGrid:L("ENTITY_JAMMER_NO_ACCESS"))
    end

    function ENT:EditValue(key, val)
        self:SetKeyValue(key, val)
        timer.Simple(0, function()
            if not IsValid(self) then return end
            local health = self:GetJamMaxHealth()
            if key == "jam_max_health" and health > 0 then
                self:SetMaxHealth(health)
                self:SetHealth(health)
            end
            BattleGrid:BroadcastJammers()
        end)
    end

    function ENT:OnRemove()
        if IsValid(self.SparkEnt) then self.SparkEnt:Remove() end
        timer.Simple(0, function() BattleGrid:BroadcastJammers() end)
    end

    BattleGrid.Net:Receive("JammerHackResult", function(_, ply)
        local entIdx = net.ReadUInt(16)
        local success = net.ReadBool()
        local token = net.ReadUInt(20)
        local ent = Entity(entIdx)
        if not IsValid(ent) or ent:GetClass() ~= "battlegrid_jammer" then return end
        if ent:GetJamHacker() ~= ply or not ent._hackToken or token ~= ent._hackToken then return end
        ent._hackToken = nil

        -- A real player needs at least this long to drag every cable; anything faster is a forged result.
        local minTime = BattleGrid:GetJammerDifficulty(ent:GetJamDifficulty()).cables * 0.35
        if success and CurTime() - ent._hackStartTime >= minTime and ply:GetPos():DistToSqr(ent:GetPos()) <= 200 * 200 then
            BattleGrid:Log("Hack result: jammer ", entIdx, " SUCCESS by ", ply:Nick())
            ent:CompleteHack()
        else
            BattleGrid:Log("Hack result: jammer ", entIdx, " FAILED by ", ply:Nick())
            ent:CancelHack(true)
        end
    end, { maxLen = 512, rateLimit = 1 })
end

if CLIENT then
    local S = KF.Scale
    local CABLE_COLORS = BattleGrid.Theme.CableColors

    local HACK_SOUNDS = {
        wire_grab    = "ambient/energy/zap5.wav",
        wire_connect = "ambient/energy/zap1.wav",
        wire_fail    = "ambient/energy/zap9.wav",
        wire_swap    = "buttons/button17.wav",
        complete     = "npc/combine_soldier/gear1.wav",
        timeout      = "buttons/button10.wav",
    }

    local function PlayHackSound(snd, vol)
        LocalPlayer():EmitSound(snd, 0, 100, vol or 0.35, CHAN_STATIC)
    end

    local function ShuffleTable(tbl)
        for i = #tbl, 2, -1 do
            local j = math.random(1, i)
            tbl[i], tbl[j] = tbl[j], tbl[i]
        end
        return tbl
    end

    function BattleGrid:JammerDifficultyChoices()
        local choices = {}
        for level, diff in ipairs(self.JammerDifficulty) do
            choices[level] = { tostring(level), self:L(diff.adminKey) }
        end
        return choices
    end

    local function DrawCableLine(sx, sy, ex, ey, col, thickness)
        local th = thickness or 3
        local dx = ex - sx
        local dy = ey - sy
        local dist = math.sqrt(dx * dx + dy * dy)
        local steps = math.max(1, math.floor(dist / 2))
        surface.SetDrawColor(col)
        for s = 0, steps do
            local t = s / steps
            local sag = math.sin(t * math.pi) * (dist * 0.08)
            local px = sx + dx * t
            local py = sy + dy * t + sag
            surface.DrawRect(px - math.floor(th / 2), py - math.floor(th / 2), th, th)
        end
    end

    local function DrawPort(x, y, r, col, filled, glow)
        if glow then
            draw.RoundedBox(r + 2, x - r - 2, y - r - 2, (r + 2) * 2, (r + 2) * 2, KF.UI.ColorAlpha(col, 30))
        end
        draw.RoundedBox(r, x - r, y - r, r * 2, r * 2, filled and col or KF.UI.ColorAlpha(col, 40))
    end

    function BattleGrid:OpenHackMinigame(jammerEnt, hackTime, diffLevel)
        if IsValid(self._hackPanel) then self._hackPanel:Remove() end

        local diff = BattleGrid:GetJammerDifficulty(diffLevel)
        local cableCount = diff.cables
        local decoyCount = diff.decoys
        local swapInterval = diff.swapInterval

        local sw, sh = ScrW(), ScrH()
        local panelW = S(460)
        local panelH = S(410)

        local frame = vgui.Create("DPanel")
        frame:SetSize(panelW, panelH)
        frame:SetPos(sw / 2 - panelW / 2, sh / 2 - panelH / 2)
        frame:MakePopup()
        frame:SetKeyboardInputEnabled(false)
        self._hackPanel = frame

        local function SendResult(success)
            BattleGrid.Net:SendToServer("JammerHackResult", function()
                net.WriteUInt(IsValid(jammerEnt) and jammerEnt:EntIndex() or 0, 16)
                net.WriteBool(success)
                net.WriteUInt(BattleGrid._hackToken or 0, 20)
            end)
        end

        local headerH = S(48)
        local footerH = S(56)
        local pad = S(12)
        local areaTop = headerH + pad
        local areaBottom = panelH - footerH - pad
        local areaH = areaBottom - areaTop
        local leftX = S(60)
        local rightX = panelW - S(60)
        local totalSlots = cableCount + decoyCount
        local spacing = areaH / (totalSlots + 1)

        local usedColors = {}
        for i = 1, cableCount do usedColors[i] = CABLE_COLORS[i] end

        local leftPorts = {}
        local rightPorts = {}
        local rightOrder = {}

        for i = 1, totalSlots do rightOrder[i] = i end
        ShuffleTable(rightOrder)

        for i = 1, cableCount do
            leftPorts[i] = { x = leftX, y = areaTop + spacing * i, color = usedColors[i], connected = false, target = i }
        end

        for i = 1, totalSlots do
            local idx = rightOrder[i]
            local isDecoy = idx > cableCount
            local col = isDecoy and KF.UI.ColorAlpha(BattleGrid.C("TextMuted"), 120) or usedColors[idx]
            rightPorts[i] = { x = rightX, y = areaTop + spacing * i, color = col, id = idx, decoy = isDecoy }
        end

        local dragging = nil
        local connections = {}
        local completed = false
        local startTime = SysTime()
        local timeLimit = math.max(hackTime or 6, 1)
        local failed = false
        local lastSwap = SysTime()
        local flashAlpha = 0

        local function MaybeSwapPorts()
            if swapInterval <= 0 or completed or failed then return end
            if (SysTime() - lastSwap) < swapInterval then return end
            lastSwap = SysTime()

            local connectedRight = {}
            for _, conn in ipairs(connections) do connectedRight[conn.rightId] = true end

            local freeRight = {}
            for idx, rp in ipairs(rightPorts) do
                if not connectedRight[rp.id] then freeRight[#freeRight + 1] = idx end
            end
            if #freeRight < 2 then return end

            local a = freeRight[math.random(1, #freeRight)]
            local b = a
            while b == a do b = freeRight[math.random(1, #freeRight)] end
            rightPorts[a].y, rightPorts[b].y = rightPorts[b].y, rightPorts[a].y
            flashAlpha = 1
            PlayHackSound(HACK_SOUNDS.wire_swap, 0.25)
        end

        function frame:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("Background"))
            surface.SetDrawColor(BattleGrid.C("Border"))
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            local elapsed = SysTime() - startTime
            local remaining = math.max(0, timeLimit - elapsed)
            local frac = remaining / timeLimit

            local topCol = frac > 0.3 and BattleGrid.C("Accent") or BattleGrid.C("Error")
            surface.SetDrawColor(topCol)
            surface.DrawRect(0, 0, w, 3)

            draw.SimpleText(BattleGrid:L("JAMMER_HACK_TITLE"), BattleGrid.F("section"), w / 2, headerH / 2 - S(2), BattleGrid.C("TextAccent"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(BattleGrid:L(diff.labelKey), BattleGrid.F("tiny"), w / 2, headerH / 2 + S(12), KF.UI.ColorAlpha(topCol, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            surface.SetDrawColor(BattleGrid.C("BorderSubtle"))
            surface.DrawRect(pad, headerH - 1, w - pad * 2, 1)

            local barW = w - pad * 2
            local barH = S(6)
            local barX = pad
            local barY = h - footerH / 2 - barH / 2

            draw.RoundedBox(2, barX, barY, barW, barH, BattleGrid.C("PanelLight"))
            draw.RoundedBox(2, barX, barY, math.max(0, barW * frac), barH, topCol)

            local timerStr = string.format("%.1fs", remaining)
            draw.SimpleText(timerStr, BattleGrid.F("tiny"), w / 2, barY - S(8), frac > 0.3 and BattleGrid.C("TextMuted") or BattleGrid.C("Error"), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

            draw.SimpleText(BattleGrid:L("JAMMER_HACK_CONNECT"), BattleGrid.F("small"), w / 2, barY + barH + S(6), BattleGrid.C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

            if remaining <= 0 and not completed and not failed then
                failed = true
                PlayHackSound(HACK_SOUNDS.timeout, 0.5)
                timer.Simple(0.3, function()
                    if IsValid(self) then self:Remove() end
                    SendResult(false)
                end)
            end

            MaybeSwapPorts()

            if flashAlpha > 0 then
                flashAlpha = math.max(0, flashAlpha - KF.Anim.GetFrameTime() * 3)
                surface.SetDrawColor(KF.UI.ColorAlpha(color_white, math.floor(flashAlpha * 15)))
                surface.DrawRect(0, 0, w, h)
            end

            for _, conn in ipairs(connections) do
                DrawCableLine(conn.sx, conn.sy, conn.ex, conn.ey, conn.color, 3)
            end

            if dragging then
                local mx, my = self:ScreenToLocal(gui.MouseX(), gui.MouseY())
                DrawCableLine(dragging.x, dragging.y, mx, my, dragging.color, 3)
            end

            local portR = S(11)
            for _, p in ipairs(leftPorts) do
                local col = p.connected and KF.UI.ColorAlpha(p.color, 60) or p.color
                DrawPort(p.x, p.y, portR, col, true, not p.connected)
            end

            for _, rp in ipairs(rightPorts) do
                local isFilled = false
                for _, conn in ipairs(connections) do
                    if conn.rightId == rp.id then isFilled = true break end
                end
                local col = isFilled and KF.UI.ColorAlpha(rp.color, 60) or rp.color
                DrawPort(rp.x, rp.y, portR, col, isFilled or not rp.decoy, not isFilled and not rp.decoy)
            end

            draw.SimpleText(BattleGrid:L("JAMMER_HACK_PORT_OUT"), BattleGrid.F("tiny"), leftX, areaTop - S(6), BattleGrid.C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            draw.SimpleText(BattleGrid:L("JAMMER_HACK_PORT_IN"), BattleGrid.F("tiny"), rightX, areaTop - S(6), BattleGrid.C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end

        function frame:OnMousePressed(mc)
            if mc ~= MOUSE_LEFT or completed or failed then return end
            local mx, my = self:ScreenToLocal(gui.MouseX(), gui.MouseY())
            local portR = S(11)
            for _, p in ipairs(leftPorts) do
                if not p.connected and math.abs(mx - p.x) < portR * 1.8 and math.abs(my - p.y) < portR * 1.8 then
                    dragging = p
                    PlayHackSound(HACK_SOUNDS.wire_grab)
                    return
                end
            end
        end

        local function PortAt(mx, my)
            local portR = S(11)
            for _, rp in ipairs(rightPorts) do
                if math.abs(mx - rp.x) < portR * 2.2 and math.abs(my - rp.y) < portR * 2.2 then
                    return rp
                end
            end
        end

        local function IsRightPortFree(rpID)
            for _, conn in ipairs(connections) do
                if conn.rightId == rpID then return false end
            end
            return true
        end

        local function CheckAllDone()
            for _, lp in ipairs(leftPorts) do
                if not lp.connected then return false end
            end
            return true
        end

        function frame:OnMouseReleased(mc)
            if mc ~= MOUSE_LEFT or not dragging or completed or failed then
                dragging = nil
                return
            end

            local mx, my = self:ScreenToLocal(gui.MouseX(), gui.MouseY())
            local rp = PortAt(mx, my)
            local matched = rp and not rp.decoy and rp.id == dragging.target and IsRightPortFree(rp.id)

            if matched then
                dragging.connected = true
                PlayHackSound(HACK_SOUNDS.wire_connect)
                connections[#connections + 1] = {
                    sx = dragging.x, sy = dragging.y,
                    ex = rp.x, ey = rp.y,
                    color = dragging.color,
                    rightId = rp.id,
                }

                if CheckAllDone() then
                    completed = true
                    PlayHackSound(HACK_SOUNDS.complete, 0.5)
                    timer.Simple(0.4, function()
                        if IsValid(self) then self:Remove() end
                        SendResult(true)
                    end)
                end
            else
                PlayHackSound(HACK_SOUNDS.wire_fail)
            end

            dragging = nil
        end

        function frame:Think()
            if input.IsKeyDown(KEY_ESCAPE) and not completed and not failed then
                failed = true
                self:Remove()
                SendResult(false)
            end
        end
    end


    BattleGrid.Net:Receive("JammerStartHack", function()
        local ent = net.ReadEntity()
        local hackTime = net.ReadFloat()
        local diffLevel = net.ReadUInt(3)
        local hackToken = net.ReadUInt(20)
        if not IsValid(ent) then return end
        BattleGrid._hackToken = hackToken
        BattleGrid:OpenHackMinigame(ent, hackTime, diffLevel)
    end)

    BattleGrid.Net:Receive("JammerHackClose", function()
        if IsValid(BattleGrid._hackPanel) then BattleGrid._hackPanel:Remove() end
        if net.ReadBool() then BattleGrid:Toast(BattleGrid:L("JAMMER_HACK_FAIL"), "warning", 3) end
    end)

    BattleGrid.Net:Receive("SyncJammers", function()
        local data = BattleGrid.Net:ReadJSON()
        if not data then return end
        for _, j in ipairs(data) do
            j.pos = BattleGrid:NormalizeVector(j.pos)
            j.radius = tonumber(j.radius) or 0
            j.entIndex = tonumber(j.entIndex) or 0
            j.hackable = j.hackable == true
        end
        BattleGrid.Cache.Jammers = data
        hook.Run("BattleGrid.JammersUpdated")
    end)

    properties.Add("battlegrid_edit_jammer", {
        MenuLabel = "#battlegrid.edit_jammer",
        Order     = 1,
        MenuIcon  = "icon16/cog_edit.png",

        Filter = function(self, ent, ply)
            if not IsValid(ent) then return false end
            if ent:GetClass() ~= "battlegrid_jammer" then return false end
            if not BattleGrid:HasPermission(ply, "BattleGrid.Admin") then return false end
            return true
        end,

        Action = function(self, ent)
            BattleGrid:OpenJammerPropertyEditor(ent)
        end,
    })

    language.Add("battlegrid.edit_jammer", BattleGrid:L("JAMMER_EDIT_PROPERTIES"))

    function BattleGrid:OpenJammerPropertyEditor(ent)
        if IsValid(self._jammerPropEditor) then self._jammerPropEditor:Remove() end

        local width = S(420)
        local height = S(460)

        local frame = self:CreateEditorFrame(BattleGrid:L("JAMMER_EDIT_PROPERTIES"), width, height)
        self._jammerPropEditor = frame

        local scroll = vgui.Create("KF.ScrollPanel", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(S(16), S(6), S(16), S(12))
        scroll:SetAddon(BattleGrid.AID)

        local editRadius = ent:GetJamRadius()
        local editHealth = ent:GetJamMaxHealth()
        local editHackable = ent:GetJamHackable()
        local editDifficulty = tostring(ent:GetJamDifficulty())
        local editHackTime = ent:GetJamHackTime()

        BattleGrid:CreateNumberInput(scroll, BattleGrid:L("ADMIN_JAMMER_RADIUS_PH"), editRadius, function(v) editRadius = v end)
        BattleGrid:CreateNumberInput(scroll, BattleGrid:L("ADMIN_JAMMER_HEALTH_PH"), editHealth, function(v) editHealth = v end)
        BattleGrid:CreateToggle(scroll, BattleGrid:L("ADMIN_JAMMER_HACKABLE_PH"), editHackable, function(v) editHackable = v end)
        BattleGrid:CreateNumberInput(scroll, BattleGrid:L("ADMIN_JAMMER_HACK_TIME_PH"), editHackTime, function(v) editHackTime = v end)
        BattleGrid:CreateDropdown(scroll, BattleGrid:L("ADMIN_JAMMER_DIFF_LABEL"), BattleGrid:JammerDifficultyChoices(), editDifficulty, function(v) editDifficulty = v end)

        local _, saveBtn = BattleGrid:CreateEditorActionPanel(frame, BattleGrid:L("ADMIN_JAMMER_SAVE"), function()
            if not IsValid(ent) then return end
            ent:EditValue("jam_radius", tostring(tonumber(editRadius) or 1000))
            ent:EditValue("jam_max_health", tostring(tonumber(editHealth) or 5000))
            ent:EditValue("jam_hackable", editHackable and "1" or "0")
            ent:EditValue("jam_hack_time", tostring(tonumber(editHackTime) or 6))
            ent:EditValue("jam_difficulty", tostring(tonumber(editDifficulty) or 1))
            if IsValid(frame) then frame:Remove() end
        end)
    end

    local colAccent = BattleGrid.C("Error")
    local colBox = BattleGrid.C("Panel")
    local colWhite = color_white
    local colSub = BattleGrid.C("TextSecondary")
    local colBarBg = BattleGrid.C("SlotHover")
    local colHealth = BattleGrid.C("Success")
    local colHealthLow = BattleGrid.C("Error")
    local colPrompt = BattleGrid.C("AccentHover")
    local colNoAccess = BattleGrid.C("Error")

    local _drawCol = Color(0, 0, 0)
    local function DC(r, g, b, a)
        _drawCol.r = r; _drawCol.g = g; _drawCol.b = b; _drawCol.a = a
        return _drawCol
    end

    function ENT:Draw()
        self:DrawModel()

        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local entPos = self:GetPos()
        local dist = entPos:Distance(ply:GetPos())
        if dist > 300 then return end

        local obbMax = self:OBBMaxs()
        local topZ = obbMax and obbMax.z or 30
        local labelPos = entPos + Vector(0, 0, topZ + 12)
        local ang = Angle(0, ply:EyeAngles().y - 90, 90)
        local alpha = math.Clamp(255 - (dist / 300) * 200, 55, 255)

        local destroyed = self:GetJamDestroyed()
        local health = self:Health()
        local maxHealth = self:GetJamMaxHealth()
        local hackable = self:GetJamHackable()
        local beingHacked = self:GetJamBeingHacked()
        local title = string.upper(BattleGrid:L("ENTITY_JAMMER"))

        local boxH = 50
        if not destroyed then boxH = 70 end
        if not destroyed and hackable and dist < 200 then boxH = 88 end
        if not destroyed and beingHacked then boxH = 88 end

        cam.Start3D2D(labelPos, ang, 0.1)
            draw.RoundedBox(4, -100, -15, 200, boxH, DC(colBox.r, colBox.g, colBox.b, alpha * 0.85))
            surface.SetDrawColor(colAccent.r, colAccent.g, colAccent.b, alpha)
            surface.DrawRect(-100, -15, 3, boxH)

            if destroyed then
                draw.SimpleText(title, "DermaDefaultBold", 0, -2, DC(colSub.r, colSub.g, colSub.b, alpha * 0.6), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                local pulse = 0.5 + math.sin(CurTime() * 3) * 0.5
                draw.SimpleText(BattleGrid:L("ENTITY_JAMMER_DESTROYED"), "DermaDefaultBold", 0, 16, DC(colAccent.r, colAccent.g, colAccent.b, alpha * (0.5 + pulse * 0.5)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                draw.SimpleText(title, "DermaDefaultBold", 0, -2, DC(colWhite.r, colWhite.g, colWhite.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                local hpFrac = maxHealth > 0 and math.Clamp(health / maxHealth, 0, 1) or 0
                local barX, barY, barW, barH = -90, 14, 180, 6
                draw.RoundedBox(2, barX - 1, barY - 1, barW + 2, barH + 2, DC(colBarBg.r, colBarBg.g, colBarBg.b, alpha * 0.9))
                local hpCol = hpFrac > 0.3 and colHealth or colHealthLow
                if hpFrac > 0 then
                    surface.SetDrawColor(hpCol.r, hpCol.g, hpCol.b, alpha * 0.9)
                    surface.DrawRect(barX, barY, barW * hpFrac, barH)
                end
                draw.SimpleText(math.floor(health) .. " / " .. math.floor(maxHealth), "DermaDefault", 0, barY + barH + 4, DC(colSub.r, colSub.g, colSub.b, alpha * 0.7), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

                if beingHacked then
                    local hackProg = self:GetJamHackProgress()
                    local hkY = barY + barH + 22
                    draw.RoundedBox(2, barX - 1, hkY - 1, barW + 2, barH + 2, DC(colBarBg.r, colBarBg.g, colBarBg.b, alpha * 0.9))
                    surface.SetDrawColor(colPrompt.r, colPrompt.g, colPrompt.b, alpha * 0.9)
                    surface.DrawRect(barX, hkY, barW * math.Clamp(hackProg, 0, 1), barH)
                    draw.SimpleText(BattleGrid:L("ENTITY_JAMMER_HACKING"), "DermaDefault", 0, hkY + barH + 3, DC(colPrompt.r, colPrompt.g, colPrompt.b, alpha * (0.6 + math.sin(CurTime() * 6) * 0.4)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                elseif hackable and dist < 200 then
                    local promptAlpha = 0.6 + math.sin(CurTime() * 4) * 0.4
                    draw.SimpleText(BattleGrid:L("ENTITY_JAMMER_HACK_PROMPT"), "DermaDefault", 0, barY + barH + 22, DC(colPrompt.r, colPrompt.g, colPrompt.b, alpha * promptAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
            end
        cam.End3D2D()
    end
end
