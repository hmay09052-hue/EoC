hradio = hradio or {}

function hradio.RemoveOriginalVCHud(ply) -- Just a workaround until there's a ShouldDraw hook (merge request waiting)

	if !IsValid(g_VoicePanelList) then return false end

	local panels = g_VoicePanelList:GetChildren()

	if #panels < 1 then
		return false
	end

	for _,pnl in ipairs(panels) do
		if ply == pnl.ply then
			pnl:Remove()
			return true
		end
	end

	return false

end
