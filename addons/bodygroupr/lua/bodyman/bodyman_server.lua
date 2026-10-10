-- Server: Netzwerk, Prüfungen und Speichern des Aussehens.

util.AddNetworkString("bodyman_chatprint")
util.AddNetworkString("bodyman_openmenu")
util.AddNetworkString("bodyman_model_change")
util.AddNetworkString("bodyman_skin_change")
util.AddNetworkString("bodyman_bodygroup_change")

function BODYMAN:Log(msg)
	MsgC(self.Theme.Yellow, "[" .. self.ServerName .. "] ", Color(220, 220, 220), os.date("%H:%M:%S "), tostring(msg), "\n")
end

-- Alter globaler Name
function BodygroupManagerLog(text) BODYMAN:Log(text) end

function BODYMAN:ChatPrint(ply, msg)
	if IsValid(ply) then
		net.Start("bodyman_chatprint")
		net.WriteString(msg)
		net.Send(ply)
	else
		self:Log(msg)
	end
end

function BODYMAN:HasAdmin(ply) return self:IsAdmin(ply) end

local function RateLimited(ply, key, delay)
	ply.BodymanCooldowns = ply.BodymanCooldowns or {}
	local now = CurTime()
	if (ply.BodymanCooldowns[key] or 0) > now then return true end
	ply.BodymanCooldowns[key] = now + delay
	return false
end

local function CanEdit(ply)
	if not IsValid(ply) or not ply:Alive() then return false end
	if not BODYMAN:CanUseMenu(ply) then return false end
	if hook.Run("BodymanCanEdit", ply) == false then return false end
	return true
end

local function LogChange(ply, what)
	if BODYMAN.LogChanges then
		BODYMAN:Log(ply:Nick() .. " (" .. ply:SteamID() .. ") " .. what)
	end
end

-- Gedächtnis pro Spieler und Job ------------------------------------------------

local function GetMemory(ply, create)
	if not BODYMAN.RememberAppearance then return nil end

	ply.BodymanMemory = ply.BodymanMemory or {}
	local team = ply:Team()
	local mem = ply.BodymanMemory[team]

	if not mem and create then
		mem = { looks = {} }
		ply.BodymanMemory[team] = mem
	end
	return mem
end

local function GetLook(ply, create)
	local mem = GetMemory(ply, create)
	if not mem then return nil end

	local mdl = string.lower(ply:GetModel() or "")
	local look = mem.looks[mdl]

	if not look and create then
		look = { bodygroups = {} }
		mem.looks[mdl] = look
	end
	return look
end

-- Anwenden / Erzwingen ---------------------------------------------------------

-- Setzt alles zurück, was der Job nicht erlaubt.
function BODYMAN:EnforceAppearance(ply)
	if not IsValid(ply) then return end
	local job = self:GetJob(ply)

	if istable(job.skins) then
		local skins = self:GetAllowedSkins(ply, job)
		if #skins > 0 and not table.HasValue(skins, ply:GetSkin()) then
			ply:SetSkin(skins[1])
		end
	end

	if istable(job.bodygroups) then
		for _, g in ipairs(self:GetAllowedBodygroups(ply, job, true)) do
			if not table.HasValue(g.options, ply:GetBodygroup(g.id)) then
				ply:SetBodygroup(g.id, g.options[1])
			end
		end
	end
end

-- Stellt Skin + Bodygroups für das aktuelle Modell wieder her.
function BODYMAN:RestoreLook(ply)
	if not IsValid(ply) then return end

	local look = GetLook(ply, false)
	if look then
		local job = self:GetJob(ply)
		if look.skin and self:IsSkinAllowed(ply, job, look.skin) then
			ply:SetSkin(look.skin)
		end
		for id, v in pairs(look.bodygroups) do
			if self:IsBodygroupAllowed(ply, job, id, v) then
				ply:SetBodygroup(id, v)
			end
		end
	end

	self:EnforceAppearance(ply)
end

-- Stellt Modell + Look wieder her (nach Spawn/Jobwechsel).
function BODYMAN:RestoreAppearance(ply)
	if not IsValid(ply) or not ply:Alive() then return end

	local mem = GetMemory(ply, false)
	if mem and mem.model and string.lower(ply:GetModel() or "") ~= string.lower(mem.model) then
		local ok, _, path = self:IsJobModel(ply, mem.model)
		if ok then
			ply:SetModel(path)
			ply:SetupHands()
		end
	end

	self:RestoreLook(ply)
end

-- Netzwerk --------------------------------------------------------------------

net.Receive("bodyman_model_change", function(_, ply)
	if not CanEdit(ply) or RateLimited(ply, "model", 1) then return end

	local idx = net.ReadUInt(8)
	local path = BODYMAN:GetJobModels(ply)[idx]
	if not path then return end
	if string.lower(ply:GetModel() or "") == string.lower(path) then return end

	ply:SetModel(path)
	ply:SetupHands()

	local mem = GetMemory(ply, true)
	if mem then mem.model = path end

	BODYMAN:RestoreLook(ply)
	LogChange(ply, "hat das Modell gewechselt: " .. path)
end)

net.Receive("bodyman_skin_change", function(_, ply)
	if not CanEdit(ply) or RateLimited(ply, "skin", 0.1) then return end

	local skin = net.ReadUInt(8)
	if not BODYMAN:IsSkinAllowed(ply, BODYMAN:GetJob(ply), skin) then return end

	ply:SetSkin(skin)

	local look = GetLook(ply, true)
	if look then look.skin = skin end

	LogChange(ply, "hat den Skin gewechselt: " .. skin)
end)

net.Receive("bodyman_bodygroup_change", function(_, ply)
	if not CanEdit(ply) or RateLimited(ply, "bodygroup", 0.06) then return end

	local id = net.ReadUInt(8)
	local value = net.ReadUInt(8)
	if not BODYMAN:IsBodygroupAllowed(ply, BODYMAN:GetJob(ply), id, value) then return end

	ply:SetBodygroup(id, value)

	local look = GetLook(ply, true)
	if look then look.bodygroups[id] = value end

	LogChange(ply, "hat eine Bodygroup gewechselt: " .. (ply:GetBodygroupName(id) or id) .. " = " .. value)
end)
