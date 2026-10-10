if IsValid(bKeypads_Keycards_TextureSkeleton) then
	bKeypads_Keycards_TextureSkeleton:Remove()
end

bKeypads.Keycards.Textures = {}

bKeypads.Keycards.Textures.KeycardImage = {}

bKeypads.Keycards.Textures.TOP    = 1
bKeypads.Keycards.Textures.BOTTOM = 2
bKeypads.Keycards.Textures.BOTH   = bit.bor(bKeypads.Keycards.Textures.TOP, bKeypads.Keycards.Textures.BOTTOM)

function bKeypads.Keycards.Textures:Apply(keycard, orientation, keycardHash)
	if not keycard.m_KeycardTextures then
		keycard.m_KeycardTextures = {}
	end
	if keycard.m_KeycardTextures[orientation] ~= keycardHash then
		keycard.m_KeycardTextures[orientation] = keycardHash

		-- FIXME https://github.com/Facepunch/garrysmod-issues/issues/3362
		if keycard:EntIndex() == -1 then
			keycard:SetSubMaterial(orientation, nil)
			keycard:SetSubMaterial(orientation, "!bKeypads_Keycard_" .. keycardHash .. "_" .. orientation)
		else
			timer.Simple(1, function() bKeypads:nextTick(function()
				if not IsValid(keycard) then return end
				keycard:SetSubMaterial(orientation, nil)
				keycard:SetSubMaterial(orientation, "!bKeypads_Keycard_" .. keycardHash .. "_" .. orientation)
			end) end)
		end
	end
end

local scale = .01
local magstripeHeight = 0.69
local keycardPad = 0.13
local _keycardPad = math.floor(keycardPad / scale)

do
	local keycardMins, keycardMaxs = Vector(-2.573145, -1.541140, -0.028437), Vector(2.573145, 1.541140, 0.028437)

	local keycardW = math.floor((keycardMaxs.x - keycardMins.x) / scale)
	local keycardH = math.floor((keycardMaxs.y - keycardMins.y - magstripeHeight) / scale)

	function bKeypads.Keycards.Textures:GetDimensions(mins, maxs)
		if mins and maxs then
			return math.floor((maxs.x - mins.x) / scale),
			       math.floor((maxs.y - mins.y - magstripeHeight) / scale)
		else
			return keycardW, keycardH
		end
	end

	bKeypads.Keycards.Textures.DimensionsDirty = true
	function bKeypads.Keycards.Textures:UpdateDimensions(mins, maxs)
		keycardW = math.floor((maxs.x - mins.x) / scale)
		keycardH = math.floor((maxs.y - mins.y - magstripeHeight) / scale)
		bKeypads.Keycards.Textures.DimensionsDirty = nil
	end
end

do
	-- Battlefront Theme (bkeypads/cl_symtheme.lua)
	local T = bKeypads.SymTheme

	local CARD_NAME_SIZES = { 46, 38, 30 }

	local function BlackBackgroundPaint(self, w, h)
		surface.SetDrawColor(T.Color("ink"))
		surface.DrawRect(0, 0, w, h)
	end
	local function ImageContainerPaint(self, w, h)
		surface.SetDrawColor(T.Color("ink"))
		surface.DrawRect(0, 0, w, h)
	end
	local function IdentificationPaintOver(self, w, h)
		T.Outline(0, 0, w, h, T.Alpha(T.Color("ink"), 120), 2)
	end
	local function Identification_PerformLayout(self, w, h)
		self.Model:SetSize(w, w)
		self.ImageContainer:SetSize(w, w)
		self.ImageContainer:AlignBottom(0)
	end

	-- cremeweisse Karte, Akzentleiste an der Bildseite, abgeschraegte Ecken
	local function SkeletonPaint(self, w, h)
		T.Box(0, 0, w, h, T.KeycardColor)

		local left = self.Orientation == bKeypads.Keycards.Textures.TOP
		T.Box(left and 0 or w - 10, 0, 10, h, T.Accent())

		-- feine Linie unten
		T.Box(0, h - 4, w, 4, T.Alpha(T.Color("ink"), 40))
	end
	local function SkeletonPaintOver(self, w, h)
		local bg = T.Color("ink")
		T.CornerCut(w, 0, 22, "tr", bg)
		T.CornerCut(0, h, 22, "bl", bg)
	end

	-- Name + Aurebesh + Rang/Job + Stufe
	local function ContentPaint(self, w, h)
		local skeleton = self:GetParent()
		local left = skeleton.Orientation == bKeypads.Keycards.Textures.TOP
		local ax = left and TEXT_ALIGN_LEFT or TEXT_ALIGN_RIGHT
		local x = left and 0 or w
		local ink = T.Color("ink")

		local y = 2
		y = y + T.Heading(skeleton.CardName or "", "bKeypads.BF.Card.Name.", CARD_NAME_SIZES, x, y, w, ink, 20, ax)

		if skeleton.CardSub and skeleton.CardSub ~= "" then
			draw.SimpleText(T.Trim(skeleton.CardSub, "bKeypads.BF.Card.Sub", w), "bKeypads.BF.Card.Sub", x, y, T.Color("steel"), ax, TEXT_ALIGN_TOP)
		end

		-- Stufe als dunkler Chip mit Bernstein-Schrift (wie die Tags im Menue)
		local chip = string.upper(skeleton.CardLevelName or "")
		local chipH = 40
		local cy = h - chipH - 4
		local cx = left and 0 or w
		if chip ~= "" then
			chip = T.Trim(chip, "bKeypads.BF.Card.Chip", w * 0.6)
			surface.SetFont("bKeypads.BF.Card.Chip")
			local tw = surface.GetTextSize(chip)
			local cw = tw + 24
			local bx = left and cx or cx - cw
			T.Box(bx, cy, cw, chipH, ink)
			draw.SimpleText(chip, "bKeypads.BF.Card.Chip", bx + cw / 2, cy + chipH / 2, T.Accent(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			cx = left and (bx + cw + 8) or (bx - 8)
		end

		-- weitere Stufen als umrandete Kaestchen
		local levels = skeleton.CardLevels
		if levels and #levels > 1 then
			local box = chipH
			for i = 1, math.min(#levels, 6) do
				local bx = left and cx or cx - box
				if (left and bx + box > w) or (not left and bx < 0) then break end
				T.Outline(bx, cy, box, box, T.Alpha(ink, 140), 2)
				draw.SimpleText(tostring(levels[i]), "bKeypads.BF.Card.Level", bx + box / 2, cy + box / 2, ink, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				cx = left and (bx + box + 6) or (bx - 6)
			end
		end
	end

	local function Get3D2DPanel()
		if not IsValid(bKeypads_Keycards_TextureSkeleton) then
			bKeypads_Keycards_TextureSkeleton = vgui.Create("DPanel")

			local skeleton = bKeypads_Keycards_TextureSkeleton
			skeleton.Paint = SkeletonPaint
			skeleton.PaintOver = SkeletonPaintOver
			skeleton:SetPaintedManually(true)
			skeleton:SetRenderInScreenshots(false)
			skeleton:DockPadding(_keycardPad + 10, _keycardPad, _keycardPad + 10, _keycardPad)

				skeleton.Content = vgui.Create("DPanel", skeleton)
				skeleton.Content.Paint = ContentPaint
				skeleton.Content:Dock(FILL)

				skeleton.Identification = vgui.Create("DPanel", skeleton)
				skeleton.Identification.Paint = nil
				skeleton.Identification.PerformLayout = Identification_PerformLayout
				skeleton.Identification.PaintOver = IdentificationPaintOver

					skeleton.Identification.Model = vgui.Create("SpawnIcon", skeleton.Identification)
					skeleton.Identification.Model.PaintOver = skeleton.Identification.Model.Paint
					skeleton.Identification.Model.Paint = BlackBackgroundPaint

					skeleton.Identification.ImageContainer = vgui.Create("DPanel", skeleton.Identification)
					skeleton.Identification.ImageContainer.Paint = ImageContainerPaint

					skeleton.Identification.Image = vgui.Create("DImage", skeleton.Identification.ImageContainer)
					skeleton.Identification.Image:Dock(FILL)
					skeleton.Identification.Image:SetVisible(false)

					skeleton.Identification.Avatar = vgui.Create("AvatarImage", skeleton.Identification.ImageContainer)
					skeleton.Identification.Avatar:Dock(FILL)
					skeleton.Identification.Avatar:SetVisible(false)
		end

		return bKeypads_Keycards_TextureSkeleton
	end

	-- Track each keycard's materials and enforce their $basetexture to be the correct RT
	local RT_ID_Materials = {}

	-- ID of any new RTs
	local RT_Pool_Count = 0

	-- Reserved RTs - these are being used for the next draw operation
	local RT_Pool_Reservations = {}

	-- Spare RTs
	local RT_Pool_Available = {}

	local keycardBaseTexture = CreateMaterial("bKeypads.Keycards.Textures.BaseTexture", "UnlitGeneric", {
		["$basetexture"] = "models/bkeypads/keycard_identification",
		["$surfaceprop"] = "Plastic",
		["$blendtintbybasealpha"] = 1,
		["$blendtintcoloroverbase"] = 0
	})

	local RT_Queue_FrameBudget = 3
	local RT_RotationMatrix = Matrix()
	local RT_RotationMatrixTranslate = Vector()
	RT_RotationMatrix:SetAngles(Angle(0, -90, 0))

	local RT_Queue = {}

	local RT_QUEUE_TEXTURE_ID  = 1
	local RT_QUEUE_ORIENTATION = 2
	local RT_QUEUE_KEYCARD     = 3
	local RT_QUEUE_FRAME       = 4

	local function RT_Queue_Render()
		if not bKeypads.Keycards.Textures.KeycardImage.Loaded then return end

		local RT_ID, data
		while not RT_ID do
			RT_ID, data = next(RT_Queue)
			if not RT_ID then return end

			if IsValid(data[RT_QUEUE_KEYCARD]) then
				-- Increment frame number
				data[RT_QUEUE_FRAME] = data[RT_QUEUE_FRAME] + 1

				-- If we've rendered the needed frames, remove from the queue
				if data[RT_QUEUE_FRAME] == RT_Queue_FrameBudget then
					RT_Queue[RT_ID] = nil
				end
			else
				-- keycard is gone, remove from the queue
				RT_Queue[RT_ID] = nil
				RT_ID = nil
			end
		end

		local textureID, orientation, keycard = unpack(data)

		local keycardW, keycardH = bKeypads.Keycards.Textures:GetDimensions()
		local RT = GetRenderTargetEx("bKeypads_KeycardRT_" .. RT_ID, keycardH, keycardW, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE, 32768, CREATERENDERTARGETFLAGS_HDR, IMAGE_FORMAT_DEFAULT)

		RT_RotationMatrixTranslate.y = keycardW
		RT_RotationMatrix:SetTranslation(RT_RotationMatrixTranslate)

		render.PushRenderTarget(RT, 0, 0, keycardH, keycardW)
		cam.Start2D()
			render.PushFilterMag(TEXFILTER.ANISOTROPIC)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)

			cam.PushModelMatrix(RT_RotationMatrix)

			-- Theme: alle Keycards haben dieselbe Farbe
			keycardBaseTexture:SetVector("$color2", T.KeycardColor:ToVector())
			keycardBaseTexture:Recompute()
			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial(keycardBaseTexture)
			surface.DrawTexturedRect(0, 0, ScrH(), ScrW())

			local skeleton = Get3D2DPanel()

			skeleton:SetPos(0, 0)
			skeleton:SetSize(ScrH(), ScrW())

			skeleton.Orientation = orientation

			if orientation == bKeypads.Keycards.Textures.TOP then
				skeleton.Identification:Dock(LEFT)
				skeleton.Content:DockPadding(_keycardPad + 6, 0, 0, 0)
			else
				skeleton.Identification:Dock(RIGHT)
				skeleton.Content:DockPadding(0, 0, _keycardPad + 6, 0)
			end
			skeleton.Identification:SetWide((keycardH - _keycardPad - _keycardPad - _keycardPad) / 2)

			-- Daten fuer ContentPaint
			local owner = keycard.GetOwner and keycard:GetOwner()
			if not (IsValid(owner) and owner:IsPlayer()) then
				local sid = keycard.GetSteamID and keycard:GetSteamID()
				owner = sid and sid ~= "" and player.GetBySteamID(sid) or nil
			end

			local teamIndex = keycard:GetTeam() ~= 0 and keycard:GetTeam() or nil
			local teamName
			if teamIndex then
				teamName = IsValid(owner) and DarkRP and bKeypads.Config.Keycards.ShowCustomJobName and owner.getDarkRPVar and owner:getDarkRPVar("job") or team.GetName(teamIndex)
			end

			local levels = keycard:GetLevels()
			skeleton.CardName = IsValid(owner) and owner:Nick() or teamName or keycard:GetKeycardName()
			skeleton.CardSub = IsValid(owner) and teamName or nil
			skeleton.CardLevelName = levels and keycard:GetKeycardName() or nil
			skeleton.CardLevels = levels

			local model = keycard:GetPlayerModel() ~= "" and keycard:GetPlayerModel() or "models/player/kleiner.mdl"
			if skeleton.Identification.Model.Model ~= model then
				skeleton.Identification.Model:SetModel(model)
				skeleton.Identification.Model.Model = model
			end

			local steamid = keycard:GetSteamID()
			local showImg = bKeypads.Keycards.Textures.KeycardImage.PrimaryImage
			if showImg == "AVATAR" and (not steamid or #steamid == 0) then
				showImg = bKeypads.Keycards.Textures.KeycardImage.SecondaryImage
			end

			if showImg == "AVATAR" then
				if skeleton.Identification.Avatar.SteamID ~= steamid then
					skeleton.Identification.Avatar.SteamID = steamid
					skeleton.Identification.Avatar:SetSteamID(util.SteamIDTo64(steamid), 184)
				end
				skeleton.Identification.ImageContainer:DockPadding(0, 0, 0, 0)
				skeleton.Identification.Avatar:SetVisible(true)
				skeleton.Identification.Image:SetVisible(false)
			else
				if skeleton.Identification.Image:GetMaterial() ~= showImg then
					skeleton.Identification.Image:SetMaterial(showImg)
				end
				skeleton.Identification.ImageContainer:DockPadding(10, 10, 10, 10)
				skeleton.Identification.Avatar:SetVisible(false)
				skeleton.Identification.Image:SetVisible(true)
			end

			skeleton:InvalidateChildren(true)
			skeleton:PaintManual()

			cam.PopModelMatrix()

			render.PopFilterMag()
			render.PopFilterMin()
		cam.End2D()
		render.PopRenderTarget()

		if not RT_ID_Materials[RT_ID][textureID] then
			RT_ID_Materials[RT_ID][textureID] = true

			local mat = Material("!bKeypads_Keycard_" .. textureID)
			mat:SetTexture("$basetexture", "bKeypads_KeycardRT_" .. RT_ID)
			mat:Recompute()
		end
	end

	local createdKeycardMaterials = {}
	local keycardMaterialData = { ["$surfaceprop"] = "Plastic" }
	function bKeypads.Keycards.Textures:Queue(orientation, dataKeycard, keycard, keycardHash, RT_ID)
		if bKeypads.Keycards.Textures.DimensionsDirty and keycard:GetModelScale() == 1 then
			bKeypads.Keycards.Textures:UpdateDimensions(keycard:GetModelBounds())
		end

		local textureID = keycardHash .. "_" .. orientation
		if not createdKeycardMaterials[textureID] then
			createdKeycardMaterials[textureID] = CreateMaterial("bKeypads_Keycard_" .. textureID, "VertexLitGeneric", keycardMaterialData)
		end

		if not RT_Queue[RT_ID] then
			RT_Queue[RT_ID] = { textureID, orientation, dataKeycard or keycard, 0 }
		elseif RT_Queue[RT_ID][RT_QUEUE_TEXTURE_ID] ~= textureID then
			RT_Queue[RT_ID][RT_QUEUE_TEXTURE_ID] = textureID
			RT_Queue[RT_ID][RT_QUEUE_ORIENTATION] = orientation
			RT_Queue[RT_ID][RT_QUEUE_KEYCARD] = dataKeycard or keycard
			RT_Queue[RT_ID][RT_QUEUE_FRAME] = 0
		end
	end

	local ReserveAvailableRT = {}
	local function ClearRTReservations()
		RT_Queue_Render()

		for textureID in pairs(ReserveAvailableRT) do
			local key, RT_ID = next(RT_Pool_Available)
			if key then
				-- There's a spare RT, let's reserve it
				RT_Pool_Reservations[textureID] = RT_ID
				RT_Pool_Available[key] = nil
				RT_ID_Materials[RT_ID] = {}
			else
				-- No spare RTs, let's create a new one
				RT_Pool_Count = RT_Pool_Count + 1

				RT_Pool_Reservations[textureID] = RT_Pool_Count
				RT_ID_Materials[RT_Pool_Count] = {}
			end

			ReserveAvailableRT[textureID] = nil
		end

		-- New frame, clear any reservations
		table.Merge(RT_Pool_Available, RT_Pool_Reservations)
		RT_Pool_Reservations = {}
	end
	bKeypads:InitPostEntity(function()
		timer.Simple(bKeypads_Keycard_Textures_Delayed and 0 or 10, function()
			bKeypads_Keycard_Textures_Delayed = true
			hook.Add("PreRender", "bKeypads.Keycards.Textures.ClearRTReservations", ClearRTReservations) ClearRTReservations()
		end)
	end)

	local function ReserveRT(orientation, keycard, dataKeycard)
		local keycardHash = (dataKeycard or keycard):GetHash()
		local textureID = keycardHash .. "_" .. orientation

		if ReserveAvailableRT[textureID] then
			if keycard.m_KeycardTextures then
				keycard:SetSubMaterial()
				keycard.m_KeycardTextures = nil
			end
			return
		end

		local RT_ID = RT_Pool_Reservations[textureID]
		if not RT_ID then
			RT_ID = RT_Pool_Available[textureID]
			if RT_ID then
				-- We were using this RT in the last frame, let's reserve it again
				RT_Pool_Available[textureID] = nil
				RT_Pool_Reservations[textureID] = RT_ID
			else
				-- Reserve an available RT after this frame
				ReserveAvailableRT[textureID] = true
				if keycard.m_KeycardTextures then
					keycard:SetSubMaterial()
					keycard.m_KeycardTextures = nil
				end
				return
			end
		end

		if not RT_ID_Materials[RT_ID][textureID] then
			bKeypads.Keycards.Textures:Queue(orientation, dataKeycard, keycard, keycardHash, RT_ID)
		end
		bKeypads.Keycards.Textures:Apply(keycard, orientation, keycardHash)
	end

	function bKeypads.Keycards.Textures:Draw(orientations, keycard, dataKeycard)
		if bKeypads.Settings:Get("optimizations_disable_keycard_textures") then return end
		if bit.band(orientations, bKeypads.Keycards.Textures.TOP) ~= 0 then
			ReserveRT(bKeypads.Keycards.Textures.TOP, keycard, dataKeycard)
		end
		if bit.band(orientations, bKeypads.Keycards.Textures.BOTTOM) ~= 0 then
			ReserveRT(bKeypads.Keycards.Textures.BOTTOM, keycard, dataKeycard)
		end
	end

	function bKeypads.Keycards.Textures:Reset()
		RT_ID_Materials = {}
		RT_Pool_Reservations = {}
		RT_Pool_Available = {}
		RT_Queue = {}

		for _, ent in ipairs(ents.GetAll()) do
			if ent.bKeycard then
				ent:SetSubMaterial(bKeypads.Keycards.Textures.TOP, nil)
				ent:SetSubMaterial(bKeypads.Keycards.Textures.BOTTOM, nil)
			end
		end
	end
end

-- Stupid hack to precache AvatarImage
bKeypads_Keycards_Textures_CacheAvatarImage = bKeypads_Keycards_Textures_CacheAvatarImage or {}
local precache_id = 0
local function PrecacheAvatarImage(ply)
	if not IsValid(ply) or ply:IsBot() or bKeypads_Keycards_Textures_CacheAvatarImage[ply] ~= nil then return end

	local id = precache_id
	precache_id = precache_id + 1

	local function precache()
		if IsValid(ply) then
			if not ply:SteamID64() then return end

			bKeypads_Keycards_Textures_CacheAvatarImage[ply] = os.time()

			local AvatarImage = vgui.Create("AvatarImage")
			AvatarImage:SetSteamID(ply:SteamID64(), 184)
			AvatarImage:SetSize(1, 1)
			AvatarImage:SetPos(-2, -2)
			AvatarImage.PaintOver = function(self) self:Remove() end
		end

		timer.Remove("bKeypads.PrecacheAvatarImage:" .. id)
	end

	timer.Create("bKeypads.PrecacheAvatarImage:" .. id, 1, 0, precache)
	precache()
end
hook.Add("PlayerInitialSpawn", "bKeypads.Keycards.3D2D.CacheAvatarImage", PrecacheAvatarImage)
bKeypads:InitPostEntity(function()
	timer.Create("bKeypads.PrecacheAvatarImage", 1, 0, function()
		local test = vgui.Create("AvatarImage")
		if not IsValid(test) then return end
		test:Remove()

		timer.Remove("bKeypads.PrecacheAvatarImage")

		PrecacheAvatarImage(LocalPlayer())
		for _, ply in ipairs(player.GetHumans()) do
			PrecacheAvatarImage(ply)
		end
	end)
end)

local function GetKeycardImage(_imageChoice, callback)
	local imageChoice = _imageChoice:lower():Trim()
	if imageChoice == "avatar" then
		callback("AVATAR")
		return
	end

	local img = Material("bkeypads/keycard.png", "smooth")

	if imageChoice ~= "keycard" then
		if imageChoice == "scp" then
			img = Material("bkeypads/scp.png", "smooth")

		elseif imageChoice:match("^https?://.-$") then

			bKeypads:print("Loading from: " .. _imageChoice, bKeypads.PRINT_TYPE_INFO, "KeycardImage")
			http.Fetch(_imageChoice, function(body, size, headers, code)
				if size > 0 and code >= 200 and code < 300 then
					file.Write("bkeypads/KeycardImage.png", body)
					local customMat = Material("../data/bkeypads/KeycardImage.png", "smooth")
					if customMat and not customMat:IsError() then
						img = customMat
						bKeypads:print("Loaded successfully", bKeypads.PRINT_TYPE_GOOD, "KeycardImage")
					else
						bKeypads:print("Could not load: " .. _imageChoice, bKeypads.PRINT_TYPE_WARN, "KeycardImage")
						bKeypads:print("Gmod was unable to convert the response into a valid texture", bKeypads.PRINT_TYPE_WARN, "KeycardImage")
					end
				else
					bKeypads:print("Could not load: " .. _imageChoice, bKeypads.PRINT_TYPE_WARN, "KeycardImage")
					bKeypads:print("HTTP " .. code, bKeypads.PRINT_TYPE_WARN, "KeycardImage")
				end
				bKeypads:print("Response: " .. string.NiceSize(size), bKeypads.PRINT_TYPE_GOOD, "KeycardImage")

				callback(img)
			end, function(err)
				bKeypads:print("Could not load: " .. _imageChoice, bKeypads.PRINT_TYPE_WARN, "KeycardImage")
				bKeypads:print("\"" .. err .. "\"", bKeypads.PRINT_TYPE_WARN, "KeycardImage")

				callback(img)
			end)
			return

		elseif isstring(imageChoice) and #imageChoice > 0 then

			local customMat = Material(_imageChoice, "smooth")
			if customMat and not customMat:IsError() then
				img = customMat
			else
				bKeypads:print("Could not load material: \"materials/" .. _imageChoice .. "\"", bKeypads.PRINT_TYPE_WARN, "KeycardImage")
			end

		end
	end

	callback(img)
end

local function CacheKeycardImage()
	bKeypads.Keycards.Textures.KeycardImage.Loaded = false

	local primary = bKeypads.Config.Keycards.KeycardImage.Image
	local backup = bKeypads.Config.Keycards.KeycardImage.Backup:lower():Trim() == "avatar" and "keycard" or bKeypads.Config.Keycards.KeycardImage.Backup

	GetKeycardImage(primary, function(img)
		bKeypads.Keycards.Textures.KeycardImage.PrimaryImage = img

		if backup == primary then
			bKeypads.Keycards.Textures.KeycardImage.SecondaryImage = img
			bKeypads.Keycards.Textures.KeycardImage.Loaded = true
		else
			GetKeycardImage(backup, function(img)
				bKeypads.Keycards.Textures.KeycardImage.SecondaryImage = img
				bKeypads.Keycards.Textures.KeycardImage.Loaded = true
			end)
		end
	end)
end
hook.Add("bKeypads.ConfigUpdated", "bKeypads.Keycards.3D2D.KeycardImage", CacheKeycardImage)
CacheKeycardImage()