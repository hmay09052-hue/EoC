-- Server: Spawn-Hooks, Kleiderschränke und Admin-Befehle.

-- Spawn / Jobwechsel ------------------------------------------------------------

local function Apply(ply)
	if not IsValid(ply) then return end

	-- Nach dem Spawn (Modell ist dann gesetzt)
	timer.Simple(0, function()
		if IsValid(ply) then BODYMAN:RestoreAppearance(ply) end
	end)

	-- Zweiter Durchlauf, falls ein anderes Addon (z.B. Charaktersystem) das Modell später setzt
	timer.Simple(1, function()
		if IsValid(ply) and ply:Alive() then BODYMAN:RestoreLook(ply) end
	end)
end

hook.Add("PlayerLoadout", "Bodyman.Apply", Apply)
hook.Add("OnPlayerChangedTeam", "Bodyman.Apply", Apply)

-- Chat-Befehl (/bo) ---------------------------------------------------------------

hook.Add("PlayerSay", "Bodyman.ChatCommand", function(ply, text)
	local cmd = string.lower(string.Trim(text or ""))

	for _, c in ipairs(BODYMAN.ChatCommands or {}) do
		if cmd == string.lower(c) then
			net.Start("bodyman_openmenu")
			net.Send(ply)
			return ""
		end
	end
end)

-- Debug: Bodygroups des eigenen Modells in die Konsole schreiben
concommand.Add("listbodygroups", function(ply)
	if not IsValid(ply) then return end

	ply:PrintMessage(HUD_PRINTCONSOLE, "Modell: " .. ply:GetModel() .. "  |  Skins: " .. ply:SkinCount())
	for _, bg in ipairs(ply:GetBodyGroups() or {}) do
		local names = {}
		for i = 0, (bg.num or 1) - 1 do
			names[#names + 1] = i .. "=" .. tostring(bg.submodels and bg.submodels[i] or "")
		end
		ply:PrintMessage(HUD_PRINTCONSOLE, string.format("  [%d] %s: %s", bg.id, bg.name, table.concat(names, ", ")))
	end
end)

-- Kleiderschränke speichern / laden -----------------------------------------------

local DATA_DIR = "bodyman"
local DATA_FILE = "bodyman/data.txt"

local function ToVector(v)
	if isvector(v) then return v end
	if isstring(v) then return Vector((string.gsub(v, "[%[%]]", ""))) end
	return nil
end

local function ToAngle(v)
	if isangle(v) then return v end
	if isstring(v) then return Angle((string.gsub(v, "[{}%[%]]", ""))) end
	return nil
end

function BODYMAN:LoadData()
	local raw = file.Read(DATA_FILE, "DATA")
	local data = (raw and raw ~= "") and util.JSONToTable(raw) or nil

	self.Data = istable(data) and data or {}
	if not istable(self.Data.Closets) then self.Data.Closets = {} end
end

function BODYMAN:SaveData()
	if not file.IsDir(DATA_DIR, "DATA") then file.CreateDir(DATA_DIR) end
	file.Write(DATA_FILE, util.TableToJSON(self.Data, true))
end

BODYMAN:LoadData()

function BODYMAN:SpawnCloset(pos, ang)
	local ent = ents.Create("bodyman_closet")
	if not IsValid(ent) then return nil end

	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:Spawn()
	ent:Activate()

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end

	return ent
end

-- Speichert die Schränke der aktuellen Karte. Schränke anderer Karten bleiben erhalten.
function BODYMAN:SaveClosets()
	local map = game.GetMap()
	local closets = {}

	for _, v in ipairs(self.Data.Closets) do
		if v.map ~= map then closets[#closets + 1] = v end
	end

	local count = 0
	for _, ent in ipairs(ents.FindByClass("bodyman_closet")) do
		if IsValid(ent) then
			closets[#closets + 1] = { pos = ent:GetPos(), ang = ent:GetAngles(), map = map }
			count = count + 1
		end
	end

	self.Data.Closets = closets
	self:SaveData()
	return count
end

function BODYMAN:RemoveClosets()
	for _, v in ipairs(ents.FindByClass("bodyman_closet")) do
		SafeRemoveEntity(v)
	end
end

function BODYMAN:LoadClosets()
	self:LoadData()
	self:RemoveClosets()

	local map = game.GetMap()
	local count = 0

	for _, v in ipairs(self.Data.Closets) do
		if v.map == map then
			local pos, ang = ToVector(v.pos), ToAngle(v.ang)
			if pos and ang and IsValid(self:SpawnCloset(pos, ang)) then
				count = count + 1
			end
		end
	end

	return count
end

hook.Add("InitPostEntity", "Bodyman.LoadClosets", function() BODYMAN:LoadClosets() end)
hook.Add("PostCleanupMap", "Bodyman.LoadClosets", function() BODYMAN:LoadClosets() end)

-- Admin-Befehle -----------------------------------------------------------------

local function AdminCommand(name, fn)
	concommand.Add(name, function(ply, cmd, args)
		if not BODYMAN:IsAdmin(ply) then
			BODYMAN:ChatPrint(ply, BODYMAN:L("NoPermission"))
			return
		end

		local msg = fn(ply)
		if msg then
			BODYMAN:ChatPrint(ply, msg)
			BODYMAN:Log((IsValid(ply) and ply:Nick() or "SERVER") .. ": " .. msg)
		end
	end)
end

AdminCommand("bodyman_saveclosets", function()
	return string.format(BODYMAN:L("Saved"), BODYMAN:SaveClosets(), game.GetMap())
end)

AdminCommand("bodyman_loadclosets", function()
	return string.format(BODYMAN:L("Loaded"), BODYMAN:LoadClosets())
end)

AdminCommand("bodyman_removeclosets", function()
	BODYMAN:RemoveClosets()
	return BODYMAN:L("Removed")
end)

AdminCommand("bodyman_spawncloset", function(ply)
	if not IsValid(ply) then return nil end -- braucht eine Blickrichtung

	local tr = util.TraceLine({
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:GetAimVector() * 512,
		filter = ply,
	})

	local ang = Angle(0, ply:EyeAngles().y, 0)
	local ent = BODYMAN:SpawnCloset(tr.HitPos, ang)
	if not IsValid(ent) then return nil end

	return BODYMAN:L("Spawned")
end)
