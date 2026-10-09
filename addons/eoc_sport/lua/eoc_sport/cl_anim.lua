EoCSport = EoCSport or {}

local C = EoCSport.Config

-- [ply] = Zustand der Übung, wie ihn der Server meldet
EoCSport.States = EoCSport.States or {}
local States = EoCSport.States

---------------------------------------------------------------------------
-- Posen vorbereiten
--
-- Eine Pose hat zwei Arten von Bone-Angaben:
--   aim    Richtung, in die ein Glied zeigen soll (Oberarm, Unterarm,
--          Oberschenkel, Unterschenkel, Wirbelsäule). Der nötige Bone-Winkel
--          wird jedes Bild aus der gemessenen Bone-Lage berechnet, damit
--          hängt nichts von den Achsen der Bones im Model ab.
--   bones  feste Zusatzwinkel (ManipulateBoneAngles) für alles andere.
---------------------------------------------------------------------------
local PREFIX = "ValveBiped.Bip01_"
local ALL_BONES = {}

local function FullBone(name)
    if string.StartWith(name, "ValveBiped.") then return name end
    return PREFIX .. name
end

-- Glied -> Bone am Ende des Glieds (für die gemessene Richtung)
local AIM_CHILD = {
    [PREFIX .. "Spine"] = PREFIX .. "Neck1",
    [PREFIX .. "R_UpperArm"] = PREFIX .. "R_Forearm",
    [PREFIX .. "L_UpperArm"] = PREFIX .. "L_Forearm",
    [PREFIX .. "R_Forearm"] = PREFIX .. "R_Hand",
    [PREFIX .. "L_Forearm"] = PREFIX .. "L_Hand",
    [PREFIX .. "R_Thigh"] = PREFIX .. "R_Calf",
    [PREFIX .. "L_Thigh"] = PREFIX .. "L_Calf",
    [PREFIX .. "R_Calf"] = PREFIX .. "R_Foot",
    [PREFIX .. "L_Calf"] = PREFIX .. "L_Foot",
}
EoCSport.AimBones = AIM_CHILD

-- Reihenfolge: Eltern vor Kindern
local AIM_LEVELS = {
    { PREFIX .. "Spine" },
    { PREFIX .. "R_UpperArm", PREFIX .. "L_UpperArm", PREFIX .. "R_Thigh", PREFIX .. "L_Thigh" },
    { PREFIX .. "R_Forearm", PREFIX .. "L_Forearm", PREFIX .. "R_Calf", PREFIX .. "L_Calf" },
}

local function AddBone(name)
    for _, n in ipairs(ALL_BONES) do
        if n == name then return end
    end
    ALL_BONES[#ALL_BONES + 1] = name
end

local function BuildAimList(pose)
    pose.aimList = {}
    for name, a in pairs(pose.aim) do
        pose.aimList[#pose.aimList + 1] = { bone = name, dir = a.dir, frame = a.frame, w = 1 }
    end
end

function EoCSport.PreparePoses()
    ALL_BONES = {}
    for bone, child in pairs(AIM_CHILD) do
        AddBone(bone)
        AddBone(child)
    end
    for _, pose in pairs(EoCSport.Poses) do
        pose.pitch = pose.pitch or 0
        pose.pivot = pose.pivot or 0
        pose.dz = pose.dz or 0
        pose.dx = pose.dx or 0

        local bones = {}
        for name, ang in pairs(pose.bones or {}) do bones[FullBone(name)] = ang end
        pose.bones = bones
        for name in pairs(bones) do AddBone(name) end

        local aim = {}
        for name, a in pairs(pose.aim or {}) do
            if isvector(a) then a = { dir = a } end
            local full = FullBone(name)
            if AIM_CHILD[full] then
                aim[full] = { dir = a.dir:GetNormalized(), frame = a.frame or "world" }
            end
        end
        pose.aim = aim
        BuildAimList(pose)
    end
end
EoCSport.PreparePoses()

function EoCSport.RegisterBone(name)
    name = FullBone(name)
    AddBone(name)
    return name
end

function EoCSport.RebuildAims(pose)
    BuildAimList(pose)
end

local IDENTITY = { pitch = 0, pivot = 0, dz = 0, dx = 0, bones = {}, aim = {}, aimList = {} }

local function GetPose(name)
    return EoCSport.Poses[name] or IDENTITY
end

local function Ease(t)
    t = math.Clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local function LerpAng(t, a, b)
    return Angle(a.p + (b.p - a.p) * t, a.y + (b.y - a.y) * t, a.r + (b.r - a.r) * t)
end

local function Blend(a, b, t)
    if t <= 0 then return a end
    if t >= 1 then return b end
    local out = {
        pitch = Lerp(t, a.pitch, b.pitch),
        pivot = Lerp(t, a.pivot, b.pivot),
        dz = Lerp(t, a.dz, b.dz),
        dx = Lerp(t, a.dx, b.dx),
        bones = {},
        aimList = {},
    }
    for name, ang in pairs(a.bones) do
        out.bones[name] = LerpAng(t, ang, b.bones[name] or angle_zero)
    end
    for name, ang in pairs(b.bones) do
        if not a.bones[name] then out.bones[name] = LerpAng(t, angle_zero, ang) end
    end
    -- Richtungen werden erst beim Anwenden gemischt (gewichtet)
    for _, e in ipairs(a.aimList) do
        out.aimList[#out.aimList + 1] = { bone = e.bone, dir = e.dir, frame = e.frame, w = e.w * (1 - t) }
    end
    for _, e in ipairs(b.aimList) do
        out.aimList[#out.aimList + 1] = { bone = e.bone, dir = e.dir, frame = e.frame, w = e.w * t }
    end
    return out
end

-- Abfolge { {t, "pose"}, ... } bei Fortschritt f (0-1) abtasten
local function Sample(frames, f)
    f = math.Clamp(f, 0, 1)
    for i = 1, #frames - 1 do
        local a, b = frames[i], frames[i + 1]
        if f <= b[1] then
            local span = b[1] - a[1]
            local u = span > 0 and (f - a[1]) / span or 1
            return Blend(GetPose(a[2]), GetPose(b[2]), Ease(u))
        end
    end
    return GetPose(frames[#frames][2])
end

local function Cycle(ex)
    if ex.cycle then return ex.cycle end
    local poses = ex.poses or {}
    if not poses.low then return nil end
    ex._cycle = ex._cycle or { { 0, poses.start or "stand" }, { 0.5, poses.low }, { 1, poses.start or "stand" } }
    return ex._cycle
end

-- Pose eines Spielers zum Zeitpunkt now
function EoCSport.ComputePose(st, ex, now)
    local pose
    local cycle = Cycle(ex)
    local startPose = GetPose(ex.poses and ex.poses.start or "stand")

    if cycle and st.repStart and now < st.repStart + st.repDur then
        pose = Sample(cycle, (now - st.repStart) / st.repDur)
    elseif ex.loop and st.holding then
        local dur = ex.loop.dur or 1
        pose = Sample(ex.loop.frames, ((now - (st.holdStart or now)) % dur) / dur)
    else
        pose = startPose
    end

    local enter = (now - st.enterStart) / C.EnterTime
    if enter < 1 then pose = Blend(IDENTITY, pose, Ease(enter)) end

    if st.leaving then
        st.leavePose = st.leavePose or st.lastPose or pose
        pose = Blend(st.leavePose, IDENTITY, Ease((now - st.leaveStart) / C.LeaveTime))
    end

    st.lastPose = pose
    return pose
end

---------------------------------------------------------------------------
-- Pose auf das Model anwenden
---------------------------------------------------------------------------
local BoneCache = {}

local function BoneIds(ply)
    local mdl = ply:GetModel() or ""
    local cache = BoneCache[mdl]
    if not cache then
        cache = {}
        BoneCache[mdl] = cache
    end
    for _, name in ipairs(ALL_BONES) do
        if cache[name] == nil then cache[name] = ply:LookupBone(name) or false end
    end
    return cache
end

-- Drehung (als Matrix), die den Einheitsvektor a auf b dreht, ohne Verdrillung
local function RotBetween(a, b)
    local axis = a:Cross(b)
    local s = axis:Length()
    local c = math.Clamp(a:Dot(b), -1, 1)
    if s < 1e-5 then
        if c > 0 then return nil end
        axis = math.abs(a.x) < 0.9 and a:Cross(Vector(1, 0, 0)) or a:Cross(Vector(0, 1, 0))
        axis:Normalize()
        s, c = 0, -1
    else
        axis:Div(s)
    end
    local x, y, z = axis.x, axis.y, axis.z
    local k = 1 - c
    return Matrix({
        { c + x * x * k, x * y * k - z * s, x * z * k + y * s, 0 },
        { y * x * k + z * s, c + y * y * k, y * z * k - x * s, 0 },
        { z * x * k - y * s, z * y * k + x * s, c + z * z * k, 0 },
        { 0, 0, 0, 1 },
    })
end

-- Richtung (x = vorn, y = links, z = oben) in Weltkoordinaten
local function FrameDir(dir, frame, frames)
    local f = frames[frame] or frames.world
    return f.f * dir.x - f.r * dir.y + f.u * dir.z
end

local function MakeFrame(fwd, right, up)
    return { f = fwd, r = right, u = up }
end

local function ApplyAims(ply, pose, ids, yaw)
    if #pose.aimList == 0 then return end

    -- Gewichtete Ziele pro Bone sammeln
    local byBone = {}
    for _, e in ipairs(pose.aimList) do
        if e.w > 0.001 then
            local list = byBone[e.bone]
            if not list then
                list = {}
                byBone[e.bone] = list
            end
            list[#list + 1] = e
        end
    end
    if next(byBone) == nil then return end

    local flat = Angle(0, yaw, 0)
    local bodyAng = Angle(pose.pitch, yaw, 0)
    local frames = {
        world = MakeFrame(flat:Forward(), flat:Right(), flat:Up()),
        body = MakeFrame(bodyAng:Forward(), bodyAng:Right(), bodyAng:Up()),
    }

    for levelIndex, level in ipairs(AIM_LEVELS) do
        local todo = false
        for _, bone in ipairs(level) do
            if byBone[bone] then todo = true break end
        end

        if todo then
            ply:InvalidateBoneCache()
            ply:SetupBones()

            for _, bone in ipairs(level) do
                local list = byBone[bone]
                local id, childId = ids[bone], ids[AIM_CHILD[bone]]
                if list and id and childId then
                    local m, cm = ply:GetBoneMatrix(id), ply:GetBoneMatrix(childId)
                    if m and cm then
                        local cur = cm:GetTranslation() - m:GetTranslation()
                        if cur:LengthSqr() > 0.01 then
                            cur:Normalize()

                            local target, total = Vector(0, 0, 0), 0
                            for _, e in ipairs(list) do
                                target:Add(FrameDir(e.dir, e.frame, frames) * e.w)
                                total = total + e.w
                            end
                            if total < 1 then target:Add(cur * (1 - total)) end

                            if target:LengthSqr() > 0.0001 then
                                target:Normalize()
                                local boneAng = m:GetAngles()
                                local lCur = WorldToLocal(cur, angle_zero, vector_origin, boneAng)
                                local lDes = WorldToLocal(target, angle_zero, vector_origin, boneAng)
                                local rot = RotBetween(lCur:GetNormalized(), lDes:GetNormalized())
                                if rot then ply:ManipulateBoneAngles(id, rot:GetAngles()) end
                            end
                        end
                    end
                end
            end
        end

        -- Oberkörper-Rahmen nach der Wirbelsäule messen (für frame = "torso")
        if levelIndex == 1 then
            ply:InvalidateBoneCache()
            ply:SetupBones()
            local sid, nid = ids[PREFIX .. "Spine"], ids[PREFIX .. "Neck1"]
            local sm = sid and ply:GetBoneMatrix(sid)
            local nm = nid and ply:GetBoneMatrix(nid)
            if sm and nm then
                local up = (nm:GetTranslation() - sm:GetTranslation()):GetNormalized()
                local right = frames.body.r
                local fwd = up:Cross(right):GetNormalized()
                right = fwd:Cross(up):GetNormalized()
                frames.torso = MakeFrame(fwd, right, up)
            else
                frames.torso = frames.body
            end
        end
    end

    ply:InvalidateBoneCache()
end

local function ApplyPose(ply, pose, yaw)
    local ids = BoneIds(ply)
    for _, name in ipairs(ALL_BONES) do
        local id = ids[name]
        if id then ply:ManipulateBoneAngles(id, pose.bones[name] or angle_zero) end
    end

    local ang = Angle(pose.pitch, yaw, 0)
    local pivot = Vector(0, 0, pose.pivot)
    local rotated = Vector(pivot)
    rotated:Rotate(ang)

    local origin = ply:GetPos() + pivot - rotated
        + Angle(0, yaw, 0):Forward() * pose.dx + Vector(0, 0, pose.dz)

    if not ply.EoCSportPosed then ply.EoCSportRA = ply:GetRenderAngles() end
    ply:SetRenderOrigin(origin)
    ply:SetRenderAngles(ang)
    ply:InvalidateBoneCache()

    ApplyAims(ply, pose, ids, yaw)
end

-- SetRenderAngles braucht immer einen Winkel; ohne Argument wirft GMod einen Fehler.
local function RestoreRender(ply)
    ply:SetRenderOrigin(ply:GetPos())
    ply:SetRenderAngles(ply.EoCSportRA or Angle(0, ply:EyeAngles().y, 0))
end

local function ResetPose(ply)
    if not IsValid(ply) then return end
    local ids = BoneIds(ply)
    for _, name in ipairs(ALL_BONES) do
        local id = ids[name]
        if id then ply:ManipulateBoneAngles(id, angle_zero) end
    end
    RestoreRender(ply)
    ply.EoCSportRA = nil
    ply:InvalidateBoneCache()
end
EoCSport.ResetPose = ResetPose

local function SequenceFor(ply, ex)
    if not ex.sequence then return nil end
    local seq = ply:LookupSequence(ex.sequence)
    if seq and seq >= 0 then return seq end
end

-- Vorschau aus dem Posen-Werkzeug (nur lokal sichtbar)
EoCSport.Preview = EoCSport.Preview or nil

hook.Add("PrePlayerDraw", "EoCSport_Pose", function(ply)
    local st = States[ply]
    local now = CurTime()

    if not st and ply == LocalPlayer() and EoCSport.Preview then
        local pv = EoCSport.Preview
        local pose
        local ex = pv.exercise and EoCSport.GetExercise(pv.exercise)
        if ex and Cycle(ex) then
            local dur = ex.duration or 1
            pose = Sample(Cycle(ex), (now % (dur + 0.4)) / dur)
        elseif ex and ex.loop then
            pose = Sample(ex.loop.frames, (now % ex.loop.dur) / ex.loop.dur)
        else
            pose = GetPose(pv.pose)
        end
        ApplyPose(ply, pose, pv.yaw)
        ply.EoCSportPosed = true
        return
    end

    if not st then return end
    local ex = EoCSport.GetExercise(st.id)
    if not ex then return end

    local seq = SequenceFor(ply, ex)
    if seq then
        -- Echte Animation (Weg A): Zyklus 0 -> 1 über die Wiederholung
        local cycle = 0
        if st.repStart and now < st.repStart + st.repDur then
            cycle = (now - st.repStart) / st.repDur
        end
        ply:SetCycle(math.Clamp(cycle, 0, 1))
        ApplyPose(ply, IDENTITY, st.yaw)
    else
        ApplyPose(ply, EoCSport.ComputePose(st, ex, now), st.yaw)
    end
    ply.EoCSportPosed = true
end)

hook.Add("PostPlayerDraw", "EoCSport_Pose", function(ply)
    if not ply.EoCSportPosed then return end
    RestoreRender(ply)
    -- Nächstes Bild die Original-Winkel neu einlesen
    ply.EoCSportPosed = nil
end)

hook.Add("CalcMainActivity", "EoCSport_Activity", function(ply)
    local st = States[ply]
    if not st and not (ply == LocalPlayer() and EoCSport.Preview) then return end

    if st then
        local ex = EoCSport.GetExercise(st.id)
        local seq = ex and SequenceFor(ply, ex)
        if seq then return ACT_HL2MP_IDLE, seq end
    end
    return ACT_HL2MP_IDLE, -1
end)

---------------------------------------------------------------------------
-- Netzwerk
---------------------------------------------------------------------------
local function RemoveState(ply)
    States[ply] = nil
    if IsValid(ply) then
        ResetPose(ply)
        ply.EoCSportPosed = nil
    end
end

net.Receive("EoCSport_State", function()
    local ply = net.ReadEntity()
    local id = net.ReadString()
    local count = net.ReadUInt(16)
    local target = net.ReadUInt(16)
    local yaw = net.ReadFloat()
    local startTime = net.ReadFloat()
    local holding = net.ReadBool()
    local group = net.ReadBool()
    local done = net.ReadBool()
    if not IsValid(ply) then return end

    local st = States[ply]
    if not st or st.id ~= id or st.leaving then
        st = { enterStart = startTime }
        States[ply] = st
    end

    if holding and not st.holding then st.holdStart = CurTime() end

    st.id = id
    st.count = count
    st.target = target
    st.yaw = yaw
    st.holding = holding
    st.group = group
    st.done = done

    hook.Run("EoCSport_ClientState", ply, st)
end)

net.Receive("EoCSport_Rep", function()
    local ply = net.ReadEntity()
    local count = net.ReadUInt(16)
    local start = net.ReadFloat()
    local dur = net.ReadFloat()
    local st = States[ply]
    if not st then return end

    st.count = count
    local ex = EoCSport.GetExercise(st.id)
    if ex and ex.mode ~= "hold" then
        st.repStart = start
        st.repDur = math.max(dur, 0.05)
    end
end)

net.Receive("EoCSport_Stop", function()
    local ply = net.ReadEntity()
    local reason = net.ReadString()
    local count = net.ReadUInt(16)
    local st = States[ply]
    if not st then return end

    st.count = count
    st.leaving = true
    st.leaveStart = CurTime()
    st.leavePose = nil

    if ply == LocalPlayer() then
        hook.Run("EoCSport_LocalStopped", st, reason)
    end

    local ref = st
    timer.Simple(C.LeaveTime + 0.05, function()
        if States[ply] == ref then RemoveState(ply) end
    end)
end)

hook.Add("InitPostEntity", "EoCSport_Sync", function()
    net.Start("EoCSport_Sync")
    net.SendToServer()
end)

-- Aufräumen für Spieler, die verschwunden sind
timer.Create("EoCSport_Prune", 5, 0, function()
    for ply in pairs(States) do
        if not IsValid(ply) then States[ply] = nil end
    end
end)

---------------------------------------------------------------------------
-- Posen-Werkzeug (Admins): Posen im Spiel einstellen
---------------------------------------------------------------------------
local function PoseToLua(name, pose)
    local lines = { "    " .. name .. " = {" }
    lines[#lines + 1] = string.format("        pitch = %g, pivot = %g, dz = %g, dx = %g,", pose.pitch, pose.pivot, pose.dz, pose.dx)
    lines[#lines + 1] = "        bones = {"
    local names = table.GetKeys(pose.bones)
    table.sort(names)
    for _, bone in ipairs(names) do
        local a = pose.bones[bone]
        local short = string.gsub(bone, "^ValveBiped%.Bip01_", "")
        lines[#lines + 1] = string.format("            %s = A(%g, %g, %g),", short, math.Round(a.p), math.Round(a.y), math.Round(a.r))
    end
    lines[#lines + 1] = "        },"
    lines[#lines + 1] = "        aim = {"
    local aimNames = table.GetKeys(pose.aim or {})
    table.sort(aimNames)
    for _, bone in ipairs(aimNames) do
        local a = pose.aim[bone]
        local short = string.gsub(bone, "^ValveBiped%.Bip01_", "")
        local frame = a.frame ~= "world" and (", frame = \"" .. a.frame .. "\"") or ""
        lines[#lines + 1] = string.format("            %s = { dir = V(%.2f, %.2f, %.2f)%s },", short, a.dir.x, a.dir.y, a.dir.z, frame)
    end
    lines[#lines + 1] = "        },"
    lines[#lines + 1] = "    },"
    return table.concat(lines, "\n")
end

local TOOL_BONES = {
    "Pelvis", "Spine", "Spine1", "Spine2", "Spine4", "Neck1", "Head1",
    "R_Clavicle", "R_UpperArm", "R_Forearm", "R_Hand",
    "L_Clavicle", "L_UpperArm", "L_Forearm", "L_Hand",
    "R_Thigh", "R_Calf", "R_Foot", "L_Thigh", "L_Calf", "L_Foot",
}

local toolFrame

local function OpenPoseTool()
    if IsValid(toolFrame) then toolFrame:Remove() end
    local lp = LocalPlayer()
    if States[lp] then
        chat.AddText(Color(255, 190, 50), "[Sport] ", color_white, "Erst die laufende Übung beenden.")
        return
    end

    local names = table.GetKeys(EoCSport.Poses)
    table.sort(names)

    EoCSport.Preview = { pose = names[1], yaw = lp:EyeAngles().y }

    local frame = vgui.Create("DFrame")
    toolFrame = frame
    frame:SetTitle("EoC Sport – Posen-Werkzeug")
    frame:SetSize(380, 760)
    frame:SetPos(20, math.max(10, ScrH() / 2 - 380))
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    frame.OnRemove = function()
        EoCSport.Preview = nil
        ResetPose(LocalPlayer())
        LocalPlayer().EoCSportPosed = nil
    end

    local updating = false
    local currentBone = FullBone(TOOL_BONES[1])

    local poseBox = vgui.Create("DComboBox", frame)
    poseBox:Dock(TOP)
    for _, n in ipairs(names) do poseBox:AddChoice(n, n, n == names[1]) end

    local exBox = vgui.Create("DComboBox", frame)
    exBox:Dock(TOP)
    exBox:DockMargin(0, 4, 0, 0)
    exBox:AddChoice("(Übung abspielen: aus)", false, true)
    for _, ex in ipairs(EoCSport.GetExerciseList()) do exBox:AddChoice("Abspielen: " .. ex.name, ex.id) end
    exBox.OnSelect = function(_, _, _, data)
        EoCSport.Preview.exercise = data or nil
    end

    local function slider(label, min, max)
        local s = vgui.Create("DNumSlider", frame)
        s:Dock(TOP)
        s:DockMargin(0, 2, 0, 0)
        s:SetText(label)
        s:SetMinMax(min, max)
        s:SetDecimals(0)
        s:SetDark(false)
        return s
    end

    local function pose()
        return EoCSport.Poses[EoCSport.Preview.pose]
    end

    local bodySliders = {
        pitch = slider("Körper-Neigung", -120, 120),
        pivot = slider("Drehpunkt-Höhe", 0, 72),
        dz = slider("Höhe", -60, 60),
        dx = slider("Vor/zurück", -60, 60),
    }

    local boneBox = vgui.Create("DComboBox", frame)
    boneBox:Dock(TOP)
    boneBox:DockMargin(0, 8, 0, 0)
    for i, n in ipairs(TOOL_BONES) do boneBox:AddChoice(n, FullBone(n), i == 1) end

    local boneSliders = {
        p = slider("Bone Pitch", -180, 180),
        y = slider("Bone Yaw", -180, 180),
        r = slider("Bone Roll", -180, 180),
    }

    local function slider2(label)
        local s = slider(label, -1, 1)
        s:SetDecimals(2)
        return s
    end

    local aimSliders = {
        x = slider2("Richtung vorn (+) / hinten (-)"),
        y = slider2("Richtung links (+) / rechts (-)"),
        z = slider2("Richtung oben (+) / unten (-)"),
    }

    local frameBox = vgui.Create("DComboBox", frame)
    frameBox:Dock(TOP)
    frameBox:DockMargin(0, 2, 0, 0)
    frameBox:AddChoice("Richtung: Welt (Blickrichtung)", "world", true)
    frameBox:AddChoice("Richtung: Körper (mit Neigung)", "body")
    frameBox:AddChoice("Richtung: Oberkörper", "torso")

    local camSlider = slider("Kamera drehen", -180, 180)
    camSlider:SetValue(160)
    EoCSport.PreviewCamYaw = 160
    camSlider.OnValueChanged = function(_, v) EoCSport.PreviewCamYaw = v end

    local function refresh()
        local p = pose()
        if not p then return end
        updating = true
        for key, s in pairs(bodySliders) do s:SetValue(p[key] or 0) end
        local a = p.bones[currentBone] or angle_zero
        boneSliders.p:SetValue(a.p)
        boneSliders.y:SetValue(a.y)
        boneSliders.r:SetValue(a.r)
        local aim = p.aim and p.aim[currentBone]
        local d = aim and aim.dir or vector_origin
        aimSliders.x:SetValue(d.x)
        aimSliders.y:SetValue(d.y)
        aimSliders.z:SetValue(d.z)
        frameBox:ChooseOptionID(aim and ({ world = 1, body = 2, torso = 3 })[aim.frame] or 1)
        local canAim = EoCSport.AimBones[currentBone] ~= nil
        for _, s2 in pairs(aimSliders) do s2:SetEnabled(canAim) end
        frameBox:SetEnabled(canAim)
        updating = false
    end

    for key, s in pairs(bodySliders) do
        s.OnValueChanged = function(_, v)
            if updating or not pose() then return end
            pose()[key] = math.Round(v)
        end
    end

    for _, s in pairs(boneSliders) do
        s.OnValueChanged = function()
            if updating or not pose() then return end
            EoCSport.RegisterBone(currentBone)
            local a = Angle(math.Round(boneSliders.p:GetValue()), math.Round(boneSliders.y:GetValue()), math.Round(boneSliders.r:GetValue()))
            if a.p == 0 and a.y == 0 and a.r == 0 then
                pose().bones[currentBone] = nil
            else
                pose().bones[currentBone] = a
            end
        end
    end

    local function writeAim()
        if updating or not pose() or not EoCSport.AimBones[currentBone] then return end
        local p = pose()
        p.aim = p.aim or {}
        local d = Vector(aimSliders.x:GetValue(), aimSliders.y:GetValue(), aimSliders.z:GetValue())
        if d:LengthSqr() < 0.01 then
            p.aim[currentBone] = nil
        else
            local _, fr = frameBox:GetSelected()
            p.aim[currentBone] = { dir = d:GetNormalized(), frame = fr or "world" }
        end
        EoCSport.RebuildAims(p)
    end
    for _, s2 in pairs(aimSliders) do s2.OnValueChanged = writeAim end
    frameBox.OnSelect = writeAim

    poseBox.OnSelect = function(_, _, value)
        EoCSport.Preview.pose = value
        refresh()
    end
    boneBox.OnSelect = function(_, _, _, data)
        currentBone = data
        refresh()
    end

    local copy = vgui.Create("DButton", frame)
    copy:Dock(BOTTOM)
    copy:SetTall(30)
    copy:SetText("Als Lua kopieren")
    copy.DoClick = function()
        SetClipboardText(PoseToLua(EoCSport.Preview.pose, pose()))
        chat.AddText(Color(255, 190, 50), "[Sport] ", color_white, "Pose in der Zwischenablage. In cl_poses.lua einfügen.")
    end

    refresh()
end

concommand.Add("eoc_sport_posetool", function()
    if not EoCSport.IsAdmin(LocalPlayer()) then
        chat.AddText(Color(255, 190, 50), "[Sport] ", color_white, "Nur für Admins.")
        return
    end
    OpenPoseTool()
end)
