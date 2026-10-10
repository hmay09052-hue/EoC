-- SymChars-Design: abgerundete Boxen werden zu abgeschrägten Platten (ohne SymChars wie bisher)
local function SY_RoundedBox(...) if SYMUI then return SYMUI.RoundedBox(...) end return draw.RoundedBox(...) end
local function SY_RoundedBoxEx(...) if SYMUI then return SYMUI.RoundedBoxEx(...) end return draw.RoundedBoxEx(...) end
surface.CreateFont('Jetted',{font=SYMUI and SYMUI.FontFace("body") or 'Trebuchet MS',size=48,weight=400})

surface.CreateFont("jetpack", {
	font = "Aurebesh_english",
	size = ScrH() * 0.008,
	weight = 500,
})

surface.CreateFont("jetpack2", {
	font = "Aurebesh_english",
	size = ScrH() * 0.01,
	weight = 500,
})

local function DrawRoundedBox(radius, col, x, y, w, h)
	surface.SetDrawColor(col.r, col.g, col.b, col.a)
	SY_RoundedBox(radius, x, y, w, h, col)
end

local function DrawText(...)
	local aye = {...}
	surface.SetFont(aye[1])
	local oldx, oldy = 0, 0
	for i = 4, #aye do
		if istable(aye[i]) then
			surface.SetTextColor(aye[i])
		else
			surface.SetTextPos(aye[2]+oldx,aye[3])
			surface.DrawText(tostring(aye[i]))
			local _ox, _oy = surface.GetTextSize(tostring(aye[i]))
			oldx, oldy = oldx+_ox, oldy+_oy
		end
	end
end

local function GetTextSize(...)
	local aye = {...}
	surface.SetFont(aye[1])
	local legx, legy = 0, 0
	for i = 2, #aye do
		if isstring(aye[i]) then
			local xd, yd = surface.GetTextSize(tostring(aye[i]))
			legx = legx + xd
			legy = legy > yd and legy or yd
		end
	end
	return legx, legy
end

local MSW, MSH = ScrW(), ScrH()
local fuelbarwidth, fuelbarheigth = 15, 256
local col_bg = Color(0,0,0,79)
local col_fuel = (SYMUI and SYMUI.Accent() or Color(4,230,247))
local col_txt = Color(255,255,255)
local col_txt_shadow = Color(0, 0, 0, 255)
local jet, cf, mf = NULL, 100, 100

hook.Add('Tick','Jetted',function()
	if !IsValid(LocalPlayer()) then return end
	jet = LocalPlayer():GetNWEntity('Jetted')
	if !IsValid(jet) then return end
	cf, mf = jet:GetFuel(), jet:GetMaxFuel()
end)

hook.Add('HUDPaint','jetted',function()
	if !IsValid(jet) then return end
	local percent = math.floor(cf/mf*100)
	local barX, barY = MSW - fuelbarwidth * 2.5, MSH / 2 - fuelbarheigth / 2 
	DrawRoundedBox(10, col_bg, barX, barY, fuelbarwidth, fuelbarheigth)
	DrawRoundedBox(10, col_fuel, barX + 4, barY + fuelbarheigth - 4 - (fuelbarheigth - 8) * percent / 100, fuelbarwidth - 8, (fuelbarheigth - 8) * percent / 100)
	DrawText('jetpack2', barX - 7, barY - 9, col_txt_shadow, ''..percent..'%')
	DrawText('jetpack2', barX - 6, barY - 10, col_txt, ''..percent..'%')
	DrawText('jetpack', barX - 22, barY + 261, col_txt_shadow, 'jetpack')
	DrawText('jetpack', barX - 23, barY + 260, col_txt, 'jetpack')
end)
