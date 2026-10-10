include("shared.lua")

local font = (BODYMAN and BODYMAN.Font) or "Lato"
surface.CreateFont("Bodyman.3D.Brand", { font = font, size = 40, weight = 800, extended = true, antialias = true })
surface.CreateFont("Bodyman.3D.Title", { font = font, size = 110, weight = 900, extended = true, antialias = true })
surface.CreateFont("Bodyman.3D.Body", { font = font, size = 60, weight = 700, extended = true, antialias = true })

local function A(col, alpha)
	return Color(col.r, col.g, col.b, (col.a or 255) * alpha)
end

function ENT:Draw()
	self:DrawModel()

	local ply = LocalPlayer()
	if not IsValid(ply) or not BODYMAN then return end

	local viewdist = BODYMAN.ClosetViewDistance or 256
	local dist = ply:EyePos():Distance(self:GetPos())
	if dist > viewdist then return end

	local alpha = math.Clamp(BODYMAN.InverseLerp(dist, viewdist, viewdist * 0.75), 0, 1)
	if alpha <= 0 then return end

	local oang = self:GetAngles()
	local ang = self:GetAngles()
	ang:RotateAroundAxis(oang:Up(), 90)
	ang:RotateAroundAxis(oang:Right(), -90)
	ang:RotateAroundAxis(oang:Up(), -4)

	local pos = self:GetPos() + oang:Forward() * 14 + oang:Up() * 20 + oang:Right() * 20

	local th = BODYMAN.Theme
	local brand = string.upper(BODYMAN.ServerName)
	local title = string.upper(BODYMAN:L("ClosetName"))
	local lines = string.Explode("\n", BODYMAN:L("ClosetHelp"))

	surface.SetFont("Bodyman.3D.Title")
	local tw, tth = surface.GetTextSize(title)

	surface.SetFont("Bodyman.3D.Body")
	local lw, lh = 0, 0
	for _, line in ipairs(lines) do
		local w, h = surface.GetTextSize(line)
		lw = math.max(lw, w)
		lh = math.max(lh, h)
	end

	local pad = 48
	local brandH = 52
	local w = math.max(tw, lw) + pad * 2
	local h = pad + brandH + tth + 12 + #lines * lh + pad

	cam.Start3D2D(pos, ang, 0.025)
		surface.SetDrawColor(A(th.Panel, alpha * 0.92))
		surface.DrawRect(-pad, -pad, w, h)

		surface.SetDrawColor(A(th.LineStrong, alpha))
		surface.DrawOutlinedRect(-pad, -pad, w, h, 3)

		surface.SetDrawColor(A(th.Yellow, alpha))
		surface.DrawRect(-pad, -pad, w, 10)
		surface.DrawRect(-pad, -pad, 10, h)

		draw.SimpleText(brand, "Bodyman.3D.Brand", 0, 0, A(th.Yellow, alpha))
		draw.SimpleText(title, "Bodyman.3D.Title", 0, brandH, A(th.White, alpha))

		local y = brandH + tth + 12
		for i, line in ipairs(lines) do
			draw.SimpleText(line, "Bodyman.3D.Body", 0, y + (i - 1) * lh, A(th.Text, alpha))
		end
	cam.End3D2D()
end
