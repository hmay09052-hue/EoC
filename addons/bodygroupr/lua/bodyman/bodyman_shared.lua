-- Gemeinsame Logik für Server und Client. Beide Seiten benutzen exakt dieselben
-- Regeln, damit das Menü nur anzeigt, was der Server auch erlaubt.

-- Alte Config-Option weiter unterstützen
if BODYMAN.French == true then BODYMAN.Language = "fr" end

function BODYMAN:L(key)
	local lang = self.Lang[self.Language] or self.Lang.de
	return lang[key] or self.Lang.de[key] or key
end

function BODYMAN.InverseLerp(pos, p1, p2)
	local range = p2 - p1
	if range == 0 then return 1 end
	return (pos - p1) / range
end

-- Wird von älteren Addons evtl. noch global erwartet
InverseLerp = InverseLerp or BODYMAN.InverseLerp

function BODYMAN:IsAdmin(ply)
	if not IsValid(ply) then return true end -- Server-Konsole
	if ply:IsSuperAdmin() then return true end
	return self.AdminGroups ~= nil and self.AdminGroups[ply:GetUserGroup()] == true
end

-- Job-Daten -------------------------------------------------------------------

function BODYMAN:GetJob(ply)
	if not IsValid(ply) then return {} end

	if ply.getJobTable then
		local job = ply:getJobTable()
		if istable(job) then return job end
	end

	if RPExtraTeams and istable(RPExtraTeams[ply:Team()]) then
		return RPExtraTeams[ply:Team()]
	end

	return {}
end

function BODYMAN:GetJobModels(ply)
	local mdl = self:GetJob(ply).model

	if isstring(mdl) then return { mdl } end

	local out = {}
	if istable(mdl) then
		for _, m in ipairs(mdl) do
			if isstring(m) then out[#out + 1] = m end
		end
	end
	return out
end

function BODYMAN:IsJobModel(ply, path)
	if not isstring(path) then return false end
	path = string.lower(path)

	for i, m in ipairs(self:GetJobModels(ply)) do
		if string.lower(m) == path then return true, i, m end
	end
	return false
end

-- Skins -----------------------------------------------------------------------

-- Liste aller erlaubten Skins für das aktuelle Modell von ent.
function BODYMAN:GetAllowedSkins(ent, job)
	local count = math.max(1, ent:SkinCount() or 1)
	local out = {}

	if istable(job.skins) then
		local seen = {}
		for _, s in ipairs(job.skins) do
			s = tonumber(s)
			if s and s >= 0 and s < count and s == math.floor(s) and not seen[s] then
				seen[s] = true
				out[#out + 1] = s
			end
		end
	else
		for i = 0, count - 1 do out[#out + 1] = i end
	end

	return out
end

function BODYMAN:IsSkinAllowed(ent, job, skin)
	for _, s in ipairs(self:GetAllowedSkins(ent, job)) do
		if s == skin then return true end
	end
	return false
end

-- Bodygroups ------------------------------------------------------------------

-- Gibt eine geordnete Liste zurück: { { id, name, options = {0, 2, ...}, submodels }, ... }
-- includeSingle = auch Gruppen mit nur einer erlaubten Option (für die Server-Prüfung).
function BODYMAN:GetAllowedBodygroups(ent, job, includeSingle)
	local out = {}
	local restricted = istable(job.bodygroups)

	for _, bg in ipairs(ent:GetBodyGroups() or {}) do
		local num = bg.num or table.Count(bg.submodels or {})
		local options

		if restricted then
			local allowed = job.bodygroups[bg.name]
			if istable(allowed) then
				options = {}
				local seen = {}
				for _, v in ipairs(allowed) do
					v = tonumber(v)
					if v and v >= 0 and v < num and v == math.floor(v) and not seen[v] then
						seen[v] = true
						options[#options + 1] = v
					end
				end
			end
		elseif bg.id ~= 0 then -- Gruppe 0 ist meistens der Grundkörper
			options = {}
			for i = 0, num - 1 do options[#options + 1] = i end
		end

		if options and #options > 0 and (includeSingle or #options > 1 or not self.HideSingleOptionGroups) then
			out[#out + 1] = { id = bg.id, name = bg.name, options = options, submodels = bg.submodels or {} }
		end
	end

	return out
end

function BODYMAN:IsBodygroupAllowed(ent, job, id, value)
	for _, g in ipairs(self:GetAllowedBodygroups(ent, job, true)) do
		if g.id == id then
			for _, v in ipairs(g.options) do
				if v == value then return true end
			end
			return false
		end
	end
	return false
end

-- Kleiderschränke ---------------------------------------------------------------

function BODYMAN:IsNearCloset(ply)
	if not IsValid(ply) then return false end

	local range = self.ClosetUseRange or 160
	local eye = ply:EyePos()

	for _, ent in ipairs(ents.FindByClass("bodyman_closet")) do
		if IsValid(ent) and eye:DistToSqr(ent:NearestPoint(eye)) <= range * range then
			return true
		end
	end
	return false
end

function BODYMAN:CanUseMenu(ply)
	if not self.ClosetsOnly then return true end
	return self:IsNearCloset(ply)
end

-- Alter Name, falls andere Addons ihn benutzen
function BODYMAN:CloseEnoughCloset(ply) return self:IsNearCloset(ply) end
