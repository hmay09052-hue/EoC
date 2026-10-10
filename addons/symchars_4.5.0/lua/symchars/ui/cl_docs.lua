--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Dokumente (Liste + Live-Editor)
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local S = UI.S
local U = symchars.util
local D = symchars.docs
local F = symchars.factions

local PAPER = Color(231, 225, 213)
local INK = Color(28, 30, 34)
local INK_DIM = Color(92, 96, 104)
local PAPER_LINE = Color(0, 0, 0, 30)

local docState = { list = {}, create = {}, current = nil }
UI.docState = docState

---------------------------------------------------------------------------------------------------------------
-- Rich-Text-Layout
---------------------------------------------------------------------------------------------------------------
local FONT_KEY = { p = "p", ul = "p", ol = "p", todo = "p", quote = "p", callout = "p", h1 = "h1", h2 = "h2", h3 = "h3", code = "code" }

local function RunFont(key, run)
    if run.code then return "symchars.doc.code" end
    local suffix = (run.b and run.i) and ".bi" or (run.b and ".b" or (run.i and ".i" or ""))
    return "symchars.doc." .. key .. suffix
end

-- gibt { lines = { { segs = {}, w, h } }, h } zurück
local function Layout(text, key, width, forceItalic)
    local runs = D.ParseInline(text)
    local lines = {}
    local line = { segs = {}, w = 0, h = 0 }
    local _, baseH = UI.TextSize("Ag", "symchars.doc." .. key)

    local function NewLine()
        if line.h == 0 then line.h = baseH end
        lines[#lines + 1] = line
        line = { segs = {}, w = 0, h = 0 }
    end

    for _, run in ipairs(runs) do
        if forceItalic then run.i = true end
        local font = RunFont(key, run)
        surface.SetFont(font)
        local _, fh = surface.GetTextSize("Ag")
        local pos = 1
        local text = run.text
        while pos <= #text do
            local nl = string.find(text, "\n", pos, true)
            local chunkEnd = nl and nl - 1 or #text
            local chunk = string.sub(text, pos, chunkEnd)
            for token in string.gmatch(chunk, "%s*[^%s]+%s*") do
                local tw = surface.GetTextSize(token)
                if line.w + tw > width and line.w > 0 then
                    NewLine()
                    token = string.gsub(token, "^%s+", "")
                    tw = surface.GetTextSize(token)
                end
                -- sehr lange Wörter hart umbrechen
                while tw > width and #token > 1 do
                    local cut = #token
                    while cut > 1 and surface.GetTextSize(string.sub(token, 1, cut)) > width - line.w do cut = cut - 1 end
                    local part = string.sub(token, 1, cut)
                    line.segs[#line.segs + 1] = { text = part, font = font, x = line.w, w = surface.GetTextSize(part), run = run }
                    line.h = math.max(line.h, fh)
                    NewLine()
                    token = string.sub(token, cut + 1)
                    tw = surface.GetTextSize(token)
                end
                line.segs[#line.segs + 1] = { text = token, font = font, x = line.w, w = tw, run = run }
                line.w = line.w + tw
                line.h = math.max(line.h, fh)
            end
            if string.match(chunk, "^%s+$") then
                local tw = surface.GetTextSize(chunk)
                line.segs[#line.segs + 1] = { text = chunk, font = font, x = line.w, w = tw, run = run }
                line.w = line.w + tw
            end
            if nl then NewLine() pos = nl + 1 else pos = #text + 1 end
        end
    end
    NewLine()
    local total = 0
    for _, l in ipairs(lines) do total = total + l.h end
    return { lines = lines, h = total }
end

local function DrawLayout(layout, x, y, width, align, baseCol, links)
    local cy = y
    for _, l in ipairs(layout.lines) do
        local ox = x
        if align == "c" then ox = x + (width - l.w) / 2 elseif align == "r" then ox = x + width - l.w end
        for _, seg in ipairs(l.segs) do
            local run = seg.run
            local col = run.link and Color(30, 100, 180) or (run.color or baseCol)
            local sx, sy = ox + seg.x, cy + l.h - select(2, UI.TextSize("Ag", seg.font))
            if run.code then
                UI.Box(sx - 1, sy + 1, seg.w + 2, l.h - 2, Color(0, 0, 0, 30))
            end
            draw.SimpleText(seg.text, seg.font, sx, sy, col)
            if run.u then UI.Box(sx, cy + l.h - S(3), seg.w, 1, col) end
            if run.s then UI.Box(sx, cy + l.h * 0.55, seg.w, 1, col) end
            if run.link and links then links[#links + 1] = { x = sx, y = cy, w = seg.w, h = l.h, url = run.link } end
        end
        cy = cy + l.h
    end
    return cy - y
end

---------------------------------------------------------------------------------------------------------------
-- Block-Panel
---------------------------------------------------------------------------------------------------------------
local BLOCK = {}

function BLOCK:Init()
    self._hover = 0
    self:SetCursor("beam")
    self:DockMargin(0, 0, 0, 0)
end

function BLOCK:Setup(editor, block)
    self.editor = editor
    self.block = block
    self._layout = nil
    self:InvalidateLayout(true)
end

function BLOCK:SetBlock(block)
    self.block = block
    self._layout = nil
    if IsValid(self.entry) and not self.entry:HasFocus() then self.entry:SetValue(block.text or "") end
    self:InvalidateLayout(true)
end

function BLOCK:LockedBy()
    local ed = self.editor
    if not ed or not ed.locks then return nil end
    local lock = ed.locks[self.block.id]
    if lock and lock.uid ~= LocalPlayer():UserID() then return lock end
    return nil
end

local INDENT = 0

function BLOCK:Insets()
    local b = self.block
    local left, right, top, bottom = 0, 0, S(4), S(4)
    if b.t == "ul" or b.t == "ol" or b.t == "todo" then left = S(34) + (b.indent or 0) * S(28) end
    if b.t == "quote" then left = S(22) end
    if b.t == "callout" then left, right, top, bottom = S(52), S(16), S(14), S(14) end
    if b.t == "code" then left, right, top, bottom = S(16), S(16), S(12), S(12) end
    if b.t == "h1" then top, bottom = S(16), S(12) end
    if b.t == "h2" then top, bottom = S(12), S(6) end
    if b.t == "h3" then top = S(8) end
    return left, right, top, bottom
end

function BLOCK:PerformLayout(w, h)
    local b = self.block
    if not b then return end
    local left, right, top, bottom = self:Insets()
    local want

    if IsValid(self.entry) then
        self.entry:SetPos(left, top)
        self.entry:SetWide(w - left - right)
        local lines = math.max(1, #string.Explode("\n", self.entry:GetValue()))
        local _, lh = UI.TextSize("Ag", self.entry:GetFont())
        local wrapLines = #UI.Wrap(self.entry:GetValue(), self.entry:GetFont(), w - left - right - S(20))
        local eh = math.max(lines, wrapLines) * (lh + S(2)) + S(12)
        self.entry:SetTall(eh)
        want = eh + top + bottom
    elseif D.TEXT_TYPES[b.t] then
        local key = FONT_KEY[b.t] or "p"
        local width = w - left - right
        if not self._layout or self._layoutW ~= width or self._layoutText ~= b.text then
            local text = b.text or ""
            if text == "" then text = " " end
            self._layout = Layout(text, key, width, b.t == "quote")
            self._layoutW, self._layoutText = width, b.text
        end
        want = self._layout.h + top + bottom
        if b.t == "h1" then want = want + S(6) end
    elseif b.t == "hr" then
        want = S(30)
    elseif b.t == "img" then
        local imgW = (w) * (b.w or 1)
        local mat, entry = UI.Image(b.src)
        local ratio = (entry and entry.w and entry.h and entry.w > 0) and (entry.h / entry.w) or 0.56
        want = imgW * ratio + (b.cap ~= "" and S(30) or S(8)) + S(8)
        if not mat then want = math.max(S(120), want) end
    elseif b.t == "table" then
        local rows = #(b.rows or {})
        want = rows * S(38) + S(16)
    else
        want = S(30)
    end

    if self:GetTall() ~= math.ceil(want) then
        self:SetTall(math.ceil(want))
        self:InvalidateParent()
    end
end

function BLOCK:Think()
    self._hover = UI.Approach(self._hover, (self:IsHovered() or self:IsChildHovered()) and 1 or 0, 14)
    if self.block and self.block.t == "img" and not self._imgReady then
        local mat = UI.Image(self.block.src)
        if mat then self._imgReady = true self:InvalidateLayout() end
    end
end

function BLOCK:Paint(w, h)
    local b = self.block
    if not b then return end
    local ed = self.editor
    local left, right, top = self:Insets()
    local lock = self:LockedBy()

    if lock then
        local c = Color(lock.color.r, lock.color.g, lock.color.b)
        UI.Box(0, 0, S(3), h, c)
        local tw = UI.TextSize(lock.name, "symchars.tiny.bold") + S(12)
        UI.Box(w - tw, -S(2), tw, S(18), c)
        UI.Text(lock.name, "symchars.tiny.bold", w - tw / 2, S(7), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif ed.canWrite and self._hover > 0.01 and not IsValid(self.entry) then
        UI.Box(0, 0, S(3), h, Color(0, 0, 0, 40 * self._hover))
    end

    if b.t == "callout" then
        local col = U.HexToColor(b.color, Color(252, 178, 73))
        UI.Box(0, 0, w, h, Color(col.r, col.g, col.b, 40))
        UI.Box(0, 0, S(4), h, col)
        UI.Icon("info", S(14), S(14), S(26), col)
    elseif b.t == "code" then
        UI.Box(0, 0, w, h, Color(20, 24, 30, 235))
    elseif b.t == "quote" then
        UI.Box(S(4), S(4), S(4), h - S(8), Color(0, 0, 0, 90))
    end

    if IsValid(self.entry) then return end

    local textCol = b.t == "code" and Color(140, 230, 160) or (b.t == "quote" and INK_DIM or INK)

    if b.t == "ul" then
        UI.Circle(left - S(16), top + S(14), S(4), INK, 12)
    elseif b.t == "ol" then
        UI.Text(tostring(self.number or 1) .. ".", "symchars.doc.p", left - S(8), top, INK, TEXT_ALIGN_RIGHT)
    elseif b.t == "todo" then
        local bx, by, bs = left - S(30), top + S(3), S(20)
        UI.Outline(bx, by, bs, bs, INK, S(2))
        if b.checked then
            UI.Box(bx + S(3), by + S(3), bs - S(6), bs - S(6), Color(60, 140, 80))
            textCol = INK_DIM
        end
        self._checkRect = { bx, by, bs }
    end

    if D.TEXT_TYPES[b.t] and self._layout then
        self._links = {}
        if (b.text or "") == "" and ed.canWrite then
            UI.Text(b.t == "h1" and "Überschrift" or "Text eingeben…", "symchars.doc." .. (FONT_KEY[b.t] or "p"), left, top, Color(0, 0, 0, 60))
        else
            DrawLayout(self._layout, left, top, w - left - right, b.align, textCol, self._links)
        end
        if b.t == "todo" and b.checked then UI.Box(left, top + self._layout.h / 2, math.min(self._layout.lines[1].w, w - left), 1, INK_DIM) end
        if b.t == "h1" then UI.Box(0, h - S(6), w, S(2), PAPER_LINE) end
    elseif b.t == "hr" then
        UI.Box(0, h / 2, w, S(2), PAPER_LINE)
        UI.Box(w / 2 - S(30), h / 2 - S(1), S(60), S(4), Color(252, 178, 73))
    elseif b.t == "img" then
        local imgW = w * (b.w or 1)
        local x = b.align == "l" and 0 or (b.align == "r" and w - imgW or (w - imgW) / 2)
        local ih = h - (b.cap ~= "" and S(30) or S(8)) - S(8)
        if b.src == "" or not UI.DrawImage(b.src, x, S(4), imgW, ih, color_white, "contain") then
            UI.Box(x, S(4), imgW, ih, Color(0, 0, 0, 25))
            UI.Text(b.src == "" and "Kein Bild (anklicken zum Einstellen)" or (UI.ImageState(b.src) == "error" and "Bild konnte nicht geladen werden" or "Bild lädt…"), "symchars.small", x + imgW / 2, S(4) + ih / 2, INK_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        if b.cap ~= "" then UI.Text(b.cap, "symchars.doc.small.i", x + imgW / 2, h - S(28), INK_DIM, TEXT_ALIGN_CENTER) end
    elseif b.t == "table" then
        local rows = b.rows or {}
        local cols = rows[1] and #rows[1] or 1
        local cw = w / math.max(cols, 1)
        for r, row in ipairs(rows) do
            local y = S(8) + (r - 1) * S(38)
            local head = b.head and r == 1
            UI.Box(0, y, w, S(38), head and Color(0, 0, 0, 30) or (r % 2 == 0 and Color(0, 0, 0, 10) or Color(0, 0, 0, 0)))
            for c = 1, cols do
                UI.TextFit(row[c] or "", head and "symchars.doc.p.b" or "symchars.doc.p", (c - 1) * cw + S(8), y + S(19), INK, cw - S(14), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if c > 1 then UI.Box((c - 1) * cw, y, 1, S(38), PAPER_LINE) end
            end
            UI.Box(0, y + S(37), w, 1, PAPER_LINE)
        end
        UI.Outline(0, S(8), w, #rows * S(38), PAPER_LINE)
    end
end

function BLOCK:OnMousePressed(code)
    if code ~= MOUSE_LEFT then return end
    local b = self.block
    local mx, my = self:CursorPos()

    for _, link in ipairs(self._links or {}) do
        if mx >= link.x and mx <= link.x + link.w and my >= link.y and my <= link.y + link.h then
            UI.Confirm("Link öffnen", "Diesen Link im Steam-Browser öffnen?\n" .. link.url, function() gui.OpenURL(link.url) end, nil, "Öffnen")
            return
        end
    end

    local ed = self.editor
    if not ed.canWrite then return end
    local lock = self:LockedBy()
    if lock then
        symchars.Notify(lock.name .. " bearbeitet diesen Abschnitt gerade.", "error")
        return
    end

    if b.t == "todo" and self._checkRect then
        local r = self._checkRect
        if mx >= r[1] - S(4) and mx <= r[1] + r[3] + S(4) and my >= r[2] - S(4) and my <= r[2] + r[3] + S(4) then
            b.checked = not b.checked
            ed:SendOp({ k = "set", block = b })
            ed:Release(b.id)
            return
        end
    end

    if D.TEXT_TYPES[b.t] then
        self:StartEdit()
    elseif b.t == "img" then
        ed:EditImage(b)
    elseif b.t == "table" then
        ed:EditTable(b)
    end
end

function BLOCK:StartEdit(caretEnd)
    if IsValid(self.entry) then self.entry:RequestFocus() return end
    local ed = self.editor
    local b = self.block
    ed:Lock(b.id)
    ed.focusBlock = self

    local key = FONT_KEY[b.t] or "p"
    local entry = vgui.Create("DTextEntry", self)
    self.entry = entry
    entry:SetMultiline(true)
    entry:SetFont("symchars.doc." .. key)
    entry:SetTextColor(b.t == "code" and Color(140, 230, 160) or INK)
    entry:SetHighlightColor(Color(252, 178, 73, 120))
    entry:SetCursorColor(INK)
    entry:SetPaintBackground(false)
    entry:SetValue(b.text or "")
    entry:SetUpdateOnType(true)
    entry.Paint = function(s, w, h)
        UI.Box(-S(4), 0, w + S(8), h, Color(252, 178, 73, 26))
        s:DrawTextEntryText(b.t == "code" and Color(140, 230, 160) or INK, Color(252, 178, 73, 120), INK)
    end
    entry.OnValueChange = function(s, value)
        b.text = value
        self._layout = nil
        self:InvalidateLayout()
        ed:QueueSet(b)
    end
    entry.OnKeyCodeTyped = function(s, code)
        local ctrl = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
        local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
        if ctrl and code == KEY_B then ed:Wrap("**", "**") return true end
        if ctrl and code == KEY_I then ed:Wrap("*", "*") return true end
        if ctrl and code == KEY_U then ed:Wrap("__", "__") return true end
        if code == KEY_ENTER and not shift and b.t ~= "code" then
            ed:SplitBlock(self)
            return true
        end
        if code == KEY_BACKSPACE and s:GetValue() == "" then
            ed:RemoveBlock(self, true)
            return true
        end
        if code == KEY_ESCAPE then s:KillFocus() return true end
    end
    entry.OnLoseFocus = function()
        timer.Simple(0, function()
            if not IsValid(self) or not IsValid(self.entry) then return end
            if ed:ToolbarBusy() and ed.focusBlock == self then return end
            self:StopEdit()
        end)
    end
    entry:RequestFocus()
    if caretEnd ~= false then entry:SetCaretPos(utf8.len(entry:GetValue()) or #entry:GetValue()) end
    self:InvalidateLayout(true)
end

function BLOCK:StopEdit()
    if not IsValid(self.entry) then return end
    local ed = self.editor
    self.block.text = self.entry:GetValue()
    self.entry:Remove()
    self.entry = nil
    self._layout = nil
    ed:FlushSet(self.block)
    ed:Release(self.block.id)
    if ed.focusBlock == self then ed.focusBlock = nil end
    ed.lastBlock = self
    self:InvalidateLayout(true)
end

vgui.Register("symchars.DocBlock", BLOCK, "DPanel")

---------------------------------------------------------------------------------------------------------------
-- Editor
---------------------------------------------------------------------------------------------------------------
local EDITOR = {}

-- kein grauer Derma-Hintergrund
function EDITOR:Paint() end

function EDITOR:Init()
    self.panels = {}
    self.locks = {}
    self.users = {}
    self.pending = {}
    self.canWrite = false
    self.canManage = false

    self.toolbar = vgui.Create("DPanel", self)
    self.toolbar:Dock(TOP)
    self.toolbar:SetTall(S(118))
    self.toolbar.Paint = function(_, w, h) self:PaintToolbar(w, h) end

    self.page = UI.Scroll(self)
    self.page:Dock(FILL)
    self.page:DockMargin(0, S(8), 0, 0)
    self.page.Paint = function(_, w, h) UI.Box(0, 0, w, h, Color(5, 7, 9, 160)) end

    self.paper = vgui.Create("DPanel", self.page)
    self.paper:Dock(TOP)
    self.paper.Paint = function(_, w, h)
        local pw = self:PaperWidth()
        local x = (w - pw) / 2
        UI.Box(x + S(6), S(26), pw, h - S(30), Color(0, 0, 0, 120))
        UI.Box(x, S(20), pw, h - S(30), PAPER)
    end
    self.paper.PerformLayout = function(p, w)
        local pw = self:PaperWidth()
        local x = (w - pw) / 2
        local padX = S(70)
        local key = math.floor(x)
        if p._padKey ~= key then
            p._padKey = key
            p:DockPadding(x + padX, S(70), x + padX, S(80))
        end
        local total = S(70) + S(80)
        for _, panel in ipairs(self.panels) do total = total + panel:GetTall() + S(2) end
        if p:GetTall() ~= total then
            p:SetTall(total)
            self.page:InvalidateLayout()
        end
    end

    self:BuildToolbar()

    timer.Create("symchars_doc_heartbeat", 8, 0, function()
        if not IsValid(self) then timer.Remove("symchars_doc_heartbeat") return end
        if IsValid(self.focusBlock) and IsValid(self.focusBlock.entry) then self:Lock(self.focusBlock.block.id) end
    end)
end

function EDITOR:PaperWidth()
    return math.min(S(980), self:GetWide() - S(40))
end

function EDITOR:SetDocument(meta, blocks)
    self.meta = meta
    self.id = meta.id
    self.canWrite = meta.canWrite == true
    self.canManage = meta.canManage == true
    self.blocks = blocks
    self:RebuildBlocks()
    self:UpdateToolbar()
end

function EDITOR:FindIndex(bid)
    for i, b in ipairs(self.blocks) do if b.id == bid then return i end end
end

function EDITOR:PanelFor(bid)
    for _, p in ipairs(self.panels) do if p.block and p.block.id == bid then return p end end
end

function EDITOR:Renumber()
    local n = 0
    for i, p in ipairs(self.panels) do
        p:SetZPos(i)
        if p.block.t == "ol" then n = n + 1 p.number = n else n = 0 end
    end
    self.paper:InvalidateLayout()
end

function EDITOR:RebuildBlocks()
    for _, p in ipairs(self.panels) do if IsValid(p) then p:Remove() end end
    self.panels = {}
    for _, b in ipairs(self.blocks) do
        local p = vgui.Create("symchars.DocBlock", self.paper)
        p:Dock(TOP)
        p:DockMargin(0, 0, 0, S(2))
        p:Setup(self, b)
        self.panels[#self.panels + 1] = p
    end
    self:Renumber()
end

function EDITOR:InsertPanel(index, block)
    local p = vgui.Create("symchars.DocBlock", self.paper)
    p:Dock(TOP)
    p:DockMargin(0, 0, 0, S(2))
    p:Setup(self, block)
    table.insert(self.panels, index, p)
    self:Renumber()
    return p
end

-- Netzwerk
function EDITOR:SendOp(op)
    symchars.net.SendToServer("doc_op", { id = self.id, op = op })
end

function EDITOR:Lock(bid)
    symchars.net.SendToServer("doc_lock", { id = self.id, block = bid })
end

function EDITOR:Release(bid)
    symchars.net.SendToServer("doc_lock", { id = self.id, block = bid, release = true })
end

function EDITOR:QueueSet(block)
    self.pending[block.id] = block
    if self._flushTimer then return end
    self._flushTimer = true
    timer.Simple(0.35, function()
        if not IsValid(self) then return end
        self._flushTimer = nil
        for _, b in pairs(self.pending) do self:SendOp({ k = "set", block = b }) end
        self.pending = {}
    end)
end

function EDITOR:FlushSet(block)
    if self.pending[block.id] then
        self.pending[block.id] = nil
        self:SendOp({ k = "set", block = block })
    end
end

-- Neuer Block nach panel (oder am Ende)
function EDITOR:AddBlock(t, afterPanel, extra)
    if not self.canWrite then return end
    local block = { id = D.NewBlockID(), t = t, text = "" }
    for k, v in pairs(extra or {}) do block[k] = v end
    block = D.SanitizeBlock(block)
    local index = afterPanel and (table.KeyFromValue(self.panels, afterPanel) or #self.panels) or #self.panels
    table.insert(self.blocks, index + 1, block)
    local p = self:InsertPanel(index + 1, block)
    self:SendOp({ k = "insert", after = afterPanel and afterPanel.block.id or (self.blocks[index] and self.blocks[index].id or ""), block = block })
    if D.TEXT_TYPES[t] then
        timer.Simple(0, function() if IsValid(p) then p:StartEdit() end end)
    elseif t == "img" then
        self:EditImage(block)
    elseif t == "table" then
        self:EditTable(block)
    end
    return p
end

function EDITOR:SplitBlock(panel)
    local entry = panel.entry
    if not IsValid(entry) then return end
    local text = entry:GetValue()
    local caret = entry:GetCaretPos()
    local byte = utf8.offset(text, caret + 1) or (#text + 1)
    local before, after = string.sub(text, 1, byte - 1), string.sub(text, byte)
    entry:SetText(before)
    panel.block.text = before
    self:QueueSet(panel.block)
    local nextType = panel.block.t
    if nextType == "h1" or nextType == "h2" or nextType == "h3" or nextType == "quote" or nextType == "callout" then nextType = "p" end
    if (panel.block.t == "ul" or panel.block.t == "ol" or panel.block.t == "todo") and before == "" and after == "" then
        panel.block.t = "p"
        self:SendOp({ k = "set", block = panel.block })
        panel:StopEdit()
        panel:StartEdit()
        return
    end
    panel:StopEdit()
    local p = self:AddBlock(nextType, panel, { text = after, indent = panel.block.indent })
    if p and after ~= "" then
        timer.Simple(0, function()
            if IsValid(p) and IsValid(p.entry) then p.entry:SetCaretPos(0) end
        end)
    end
end

function EDITOR:RemoveBlock(panel, focusPrevious)
    if #self.panels <= 1 then return end
    local index = table.KeyFromValue(self.panels, panel)
    if not index then return end
    local bid = panel.block.id
    if IsValid(panel.entry) then panel.entry:Remove() panel.entry = nil end
    table.remove(self.panels, index)
    table.remove(self.blocks, self:FindIndex(bid) or index)
    panel:Remove()
    self.pending[bid] = nil
    self:SendOp({ k = "remove", id = bid })
    self:Renumber()
    if focusPrevious then
        local prev = self.panels[math.max(1, index - 1)]
        if IsValid(prev) and D.TEXT_TYPES[prev.block.t] then timer.Simple(0, function() if IsValid(prev) then prev:StartEdit() end end) end
    end
end

function EDITOR:MoveBlock(panel, dir)
    local index = table.KeyFromValue(self.panels, panel)
    if not index then return end
    local target = index + dir
    if target < 1 or target > #self.panels then return end
    self.panels[index], self.panels[target] = self.panels[target], self.panels[index]
    local bi = self:FindIndex(panel.block.id)
    if bi and self.blocks[bi + dir] then self.blocks[bi], self.blocks[bi + dir] = self.blocks[bi + dir], self.blocks[bi] end
    self:SendOp({ k = "move", id = panel.block.id, dir = dir })
    self:Renumber()
end

-- Formatierung im fokussierten Block
function EDITOR:Wrap(open, close)
    local panel = self.focusBlock
    if not IsValid(panel) or not IsValid(panel.entry) then
        symchars.Notify("Klicke zuerst in einen Textabschnitt.", "info")
        return
    end
    local entry = panel.entry
    local text = entry:GetValue()
    local s, e = entry:GetSelectedTextRange()
    s, e = tonumber(s) or entry:GetCaretPos(), tonumber(e) or entry:GetCaretPos()
    if s > e then s, e = e, s end
    local bs = utf8.offset(text, s + 1) or (#text + 1)
    local be = utf8.offset(text, e + 1) or (#text + 1)
    local inner = string.sub(text, bs, be - 1)
    local newText = string.sub(text, 1, bs - 1) .. open .. inner .. close .. string.sub(text, be)
    entry:SetText(newText)
    entry:OnValueChange(newText)
    entry:RequestFocus()
    entry:SetCaretPos(s + utf8.len(open) + (utf8.len(inner) or #inner))
end

function EDITOR:SetFocusedType(t)
    local panel = IsValid(self.focusBlock) and self.focusBlock or self.lastBlock
    if not IsValid(panel) then symchars.Notify("Klicke zuerst in einen Textabschnitt.", "info") return end
    panel.block.t = t
    panel.block = D.SanitizeBlock(panel.block)
    local idx = self:FindIndex(panel.block.id)
    if idx then self.blocks[idx] = panel.block end
    self:SendOp({ k = "set", block = panel.block })
    panel:StopEdit()
    self:Renumber()
    if D.TEXT_TYPES[t] then panel:StartEdit() end
end

function EDITOR:EditImage(block)
    local f = UI.Frame("Bild", S(600), S(470))
    local urlField = UI.Field(f, "Bild-Link", "Imgur-Link (z.B. https://i.imgur.com/abc123.png) oder Imgur-ID")
    local url = UI.Entry(urlField, "https://i.imgur.com/…", block.src or "")
    url:Dock(FILL)
    local capField = UI.Field(f, "Bildunterschrift", "")
    local cap = UI.Entry(capField, "optional", block.cap or "")
    cap:Dock(FILL)
    local sizeField = UI.Field(f, "Breite", "")
    local size = UI.Combo(sizeField)
    size:Dock(FILL)
    for _, v in ipairs({ 0.25, 0.4, 0.5, 0.6, 0.75, 1 }) do size:AddChoice(math.floor(v * 100) .. " %", v, math.abs((block.w or 1) - v) < 0.01) end
    local save = UI.Button(f, "Übernehmen", "primary", function()
        block.src = U.ImageURL(url:GetValue())
        block.cap = cap:GetValue()
        block.w = size:GetSelectedData() or block.w or 1
        local panel = self:PanelFor(block.id)
        if IsValid(panel) then panel._imgReady = false panel:SetBlock(block) end
        self:SendOp({ k = "set", block = block })
        self:Release(block.id)
        f:Close()
    end)
    save:Dock(BOTTOM)
    save:SetTall(S(46))
end

function EDITOR:EditTable(block)
    local rows = table.Copy(block.rows or { { "", "" }, { "", "" } })
    local f = UI.Frame("Tabelle", S(900), S(640))
    local controls = vgui.Create("DPanel", f)
    controls:Dock(TOP)
    controls:SetTall(S(46))
    controls.Paint = nil
    local grid = UI.Scroll(f)
    grid:Dock(FILL)
    grid:DockMargin(0, S(8), 0, S(8))
    local entries = {}

    local function Rebuild()
        grid:Clear()
        entries = {}
        local cols = #rows[1]
        for r, row in ipairs(rows) do
            local line = vgui.Create("DPanel", grid)
            line:Dock(TOP)
            line:SetTall(S(42))
            line:DockMargin(0, 0, 0, S(4))
            line.Paint = nil
            entries[r] = {}
            line.PerformLayout = function(_, w)
                local cw = (w - S(4) * (cols - 1)) / cols
                for c, e in ipairs(entries[r]) do e:SetPos((c - 1) * (cw + S(4)), 0) e:SetSize(cw, S(42)) end
            end
            for c = 1, cols do
                local e = UI.Entry(line, r == 1 and "Kopfzeile" or "", row[c] or "")
                e:SetFont("symchars.body")
                e.OnValueChange = function(_, v) rows[r][c] = v end
                entries[r][c] = e
            end
        end
    end

    local function Resize(dr, dc)
        local cols = #rows[1]
        if dc ~= 0 then
            cols = math.Clamp(cols + dc, 1, 8)
            for _, row in ipairs(rows) do
                while #row < cols do row[#row + 1] = "" end
                while #row > cols do table.remove(row) end
            end
        end
        if dr > 0 and #rows < 30 then
            local row = {}
            for c = 1, cols do row[c] = "" end
            rows[#rows + 1] = row
        elseif dr < 0 and #rows > 1 then
            table.remove(rows)
        end
        Rebuild()
    end

    for i, def in ipairs({ { "+ Zeile", 1, 0 }, { "- Zeile", -1, 0 }, { "+ Spalte", 0, 1 }, { "- Spalte", 0, -1 } }) do
        local b = UI.Button(controls, def[1], "default", function() Resize(def[2], def[3]) end)
        b:SetFont("symchars.button.small")
        b:Dock(LEFT)
        b:SetWide(S(140))
        b:DockMargin(0, 0, S(6), 0)
    end

    local save = UI.Button(f, "Übernehmen", "primary", function()
        block.rows = rows
        local panel = self:PanelFor(block.id)
        if IsValid(panel) then panel:SetBlock(block) end
        self:SendOp({ k = "set", block = block })
        self:Release(block.id)
        f:Close()
    end)
    save:Dock(BOTTOM)
    save:SetTall(S(46))
    Rebuild()
end

-- Toolbar
local TOOLS = {
    { "B", function(ed) ed:Wrap("**", "**") end, "Fett (Strg+B)" },
    { "I", function(ed) ed:Wrap("*", "*") end, "Kursiv (Strg+I)" },
    { "U", function(ed) ed:Wrap("__", "__") end, "Unterstrichen (Strg+U)" },
    { "S", function(ed) ed:Wrap("~~", "~~") end, "Durchgestrichen" },
    { "</>", function(ed) ed:Wrap("`", "`") end, "Code" },
}

local COLORS = { "#c0392b", "#d35400", "#e1a800", "#27ae60", "#2980b9", "#8e44ad", "#5d6d7e", "#000000" }

function EDITOR:BuildToolbar()
    local tb = self.toolbar
    self.titleEntry = UI.Entry(tb, "Titel")
    self.titleEntry:SetFont("symchars.h2")
    self.titleEntry.OnEnter = function(s) self:SaveMeta({ title = s:GetValue() }) end
    self.titleEntry.OnLoseFocus = function(s)
        if self.meta and s:GetValue() ~= self.meta.title and self.canManage then self:SaveMeta({ title = s:GetValue() }) end
    end

    self.typeCombo = UI.Combo(tb, "Absatzart")
    self.typeCombo:SetFont("symchars.small")
    for _, t in ipairs(D.TYPES) do self.typeCombo:AddChoice(t.name, t.id) end
    self.typeCombo.OnSelect = function(_, _, _, id)
        if D.TEXT_TYPES[id] and IsValid(self.focusBlock) then
            self:SetFocusedType(id)
        else
            self:AddBlock(id, self.focusBlock or self.panels[#self.panels])
        end
    end

    self.toolButtons = {}
    for _, tool in ipairs(TOOLS) do
        local b = UI.Button(tb, tool[1], "default", function() tool[2](self) end)
        b:SetFont("symchars.h4")
        b:SetTooltip(tool[3])
        self.toolButtons[#self.toolButtons + 1] = b
    end

    self.colorBtn = UI.Button(tb, "Farbe", "default", function()
        local choices = {}
        for _, hex in ipairs(COLORS) do choices[#choices + 1] = { hex, hex } end
        local menu = DermaMenu()
        for _, hex in ipairs(COLORS) do
            local opt = menu:AddOption(hex, function() self:Wrap("{" .. hex .. "|", "}") end)
            opt.PaintOver = function(_, w, h) UI.Box(w - h, S(3), h - S(6), h - S(6), U.HexToColor(hex, color_white)) end
        end
        self._colorMenu = menu
        self.toolbarPopup = true
        menu:Open()
    end)
    self.colorBtn:SetFont("symchars.h4")

    self.linkBtn = UI.Button(tb, "Link", "default", function()
        local panel = self.focusBlock
        if not IsValid(panel) or not IsValid(panel.entry) then symchars.Notify("Klicke zuerst in einen Textabschnitt.", "info") return end
        self.toolbarPopup = true
        self._prompt = UI.Prompt("Link einfügen", "Adresse (https://…)", "https://", function(url)
            if not string.match(url, "^https?://[^%s]+$") then symchars.Notify("Ungültiger Link.", "error") return end
            self:Wrap("[", "](" .. url .. ")")
        end)
    end)
    self.linkBtn:SetFont("symchars.h4")

    self.addBtn = UI.Button(tb, "+ Absatz", "default", function() self:AddBlock("p", self.focusBlock or self.panels[#self.panels]) end)
    self.addBtn:SetFont("symchars.h4")

    self.upBtn = UI.Button(tb, "", "default", function() if IsValid(self.focusBlock) then self:MoveBlock(self.focusBlock, -1) end end)
    self.upBtn:SetIcon("arrow_up")
    self.downBtn = UI.Button(tb, "", "default", function() if IsValid(self.focusBlock) then self:MoveBlock(self.focusBlock, 1) end end)
    self.downBtn:SetIcon("arrow_down")
    self.delBtn = UI.Button(tb, "", "danger", function() if IsValid(self.focusBlock) then self:RemoveBlock(self.focusBlock, true) end end)
    self.delBtn:SetIcon("trash")

    -- Klicks auf die Werkzeugleiste beenden die Bearbeitung nicht
    local holders = { self.colorBtn, self.linkBtn, self.addBtn, self.upBtn, self.downBtn, self.delBtn, self.typeCombo }
    for _, b in ipairs(self.toolButtons) do holders[#holders + 1] = b end
    for _, b in ipairs(holders) do
        local old = b.OnMousePressed
        b.OnMousePressed = function(s, code)
            self.toolbarHold = RealTime() + 0.4
            if s == self.typeCombo then self.toolbarPopup = true end
            if old then return old(s, code) end
        end
    end

    self.shareBtn = UI.Button(tb, "Freigabe", "default", function() self:EditPerms() end)
    self.shareBtn:SetFont("symchars.h4")
    self.shareBtn:SetIcon("user")
    self.deleteBtn = UI.Button(tb, "Löschen", "danger", function()
        UI.Confirm("Dokument löschen", "'" .. (self.meta and self.meta.title or "") .. "' wirklich löschen?", function()
            symchars.net.SendToServer("doc_delete", { id = self.id })
        end, nil, "Löschen")
    end)
    self.deleteBtn:SetFont("symchars.h4")
end

function EDITOR:ToolbarBusy()
    return self.toolbarPopup == true or RealTime() < (self.toolbarHold or 0)
end

function EDITOR:Think()
    if not self.toolbarPopup then return end
    local open = IsValid(self._colorMenu) or IsValid(self._prompt) or IsValid(self.typeCombo._menu)
    if open then return end
    self.toolbarPopup = false
    self.toolbarHold = RealTime() + 0.2
    local panel = self.focusBlock
    if IsValid(panel) and IsValid(panel.entry) and not panel.entry:HasFocus() then
        panel.entry:RequestFocus()
    end
end

function EDITOR:UpdateToolbar()
    local meta = self.meta or {}
    self.titleEntry:SetValue(meta.title or "")
    self.titleEntry:SetEditable(self.canManage)
    for _, b in ipairs(self.toolButtons) do b:SetVisible(self.canWrite) end
    for _, b in ipairs({ self.colorBtn, self.linkBtn, self.addBtn, self.typeCombo, self.upBtn, self.downBtn, self.delBtn }) do b:SetVisible(self.canWrite) end
    self.shareBtn:SetVisible(self.canManage)
    self.deleteBtn:SetVisible(self.canManage)
    self.toolbar:InvalidateLayout(true)
end

function EDITOR:PerformLayout(w, h)
    local tb = self.toolbar
    self.titleEntry:SetPos(0, 0)
    self.titleEntry:SetSize(w - S(420), S(50))
    self.shareBtn:SetSize(S(170), S(46))
    self.shareBtn:SetPos(w - S(170) - S(150), S(2))
    self.deleteBtn:SetSize(S(140), S(46))
    self.deleteBtn:SetPos(w - S(140), S(2))
    local x, y, bh = 0, S(62), S(44)
    self.typeCombo:SetPos(x, y)
    self.typeCombo:SetSize(S(200), bh)
    x = x + S(208)
    for _, b in ipairs(self.toolButtons) do
        b:SetPos(x, y)
        b:SetSize(S(50), bh)
        x = x + S(54)
    end
    for _, b in ipairs({ self.colorBtn, self.linkBtn, self.addBtn }) do
        local bw = UI.TextSize(b:GetText(), "symchars.h4") + S(30)
        b:SetPos(x, y)
        b:SetSize(bw, bh)
        x = x + bw + S(4)
    end
    for _, b in ipairs({ self.upBtn, self.downBtn, self.delBtn }) do
        b:SetPos(x, y)
        b:SetSize(bh, bh)
        x = x + bh + S(4)
    end
end

function EDITOR:PaintToolbar(w, h)
    -- Anwesende (wie bei Google Docs oben rechts)
    local x = w - S(4)
    local y = S(84)
    local users = self.users or {}
    for i = #users, 1, -1 do
        local u = users[i]
        local r = S(16)
        local col = Color(u.color.r, u.color.g, u.color.b)
        UI.Circle(x - r, y, r, col, 24)
        UI.Text(string.upper(string.sub(u.name, 1, 1)), "symchars.small.bold", x - r, y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if u.block then UI.Ring(x - r, y, r + S(3), col, S(2), 24) end
        x = x - r * 2 - S(6)
        if i < #users - 7 then break end
    end
    if #users > 0 then
        UI.Text(#users == 1 and "nur du" or (#users .. " im Dokument"), "symchars.tiny", x - S(6), y, UI.col.dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    if not self.canWrite and self.meta then
        UI.Text("NUR LESEN", "symchars.h4", 0, S(70), UI.col.muted)
    end
    if self.meta then
        UI.Text("Zuletzt bearbeitet " .. U.FormatAgo(self.meta.updatedAt) .. (self.meta.updatedBy ~= "" and (" von " .. self.meta.updatedBy) or ""), "symchars.tiny", self.canWrite and 0 or S(120), h - S(8), UI.col.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end
end

function EDITOR:SaveMeta(changes)
    changes.id = self.id
    symchars.net.SendToServer("doc_meta", changes)
end

function EDITOR:EditPerms()
    local meta = self.meta
    if not meta then return end
    local perms = table.Copy(meta.perms or D.DefaultPerms(meta.folder))
    local f = UI.Frame("Freigabe", S(820), S(820))
    local scroll = UI.Scroll(f)
    scroll:Dock(FILL)

    local folderField = UI.Field(scroll, "Ordner", "In welchem Ordner das Dokument liegt")
    local folder = UI.Combo(folderField)
    folder:Dock(FILL)
    folder:AddChoice("Öffentlich", "public", meta.folder == "public")
    for _, item in ipairs(F.GetHierarchyList()) do folder:AddChoice(item.label, item.id, item.id == meta.folder, item.depth) end

    local function RuleEditor(title, rule, modes)
        local field = UI.Field(scroll, title, "", S(330))
        local mode = UI.Combo(field)
        mode:Dock(TOP)
        mode:SetTall(S(42))
        for _, m in ipairs(modes) do mode:AddChoice(m.name, m.id, m.id == rule.mode) end
        local rank = UI.Entry(field, "Mindestrang (Zahl)", tostring(rule.minRank or 0))
        rank:Dock(TOP)
        rank:SetTall(S(40))
        rank:DockMargin(0, S(6), 0, 0)
        rank:SetNumeric(true)
        local units = vgui.Create("symchars.Picker", field)
        units:Dock(FILL)
        units:DockMargin(0, S(6), 0, 0)
        units:SetItems(UI.UnitItems())
        units:SetSelected(rule.units or {})
        return function()
            return { mode = mode:GetSelectedData() or rule.mode, minRank = tonumber(rank:GetValue()) or 0, units = units:GetSelected() }
        end
    end

    local getRead = RuleEditor("Wer darf lesen?", perms.read, D.READ_MODES)
    local getWrite = RuleEditor("Wer darf bearbeiten?", perms.write, D.WRITE_MODES)

    local info = vgui.Create("DLabel", scroll)
    info:Dock(TOP)
    info:SetTall(S(50))
    info:SetWrap(true)
    info:SetFont("symchars.tiny")
    info:SetTextColor(UI.col.muted)
    info:SetText("Die Einheiten-Liste gilt nur für 'Bestimmte Einheiten'. Ersteller, Ränge mit dem Recht 'Dokumente' und Dokument-Admins dürfen immer bearbeiten.")

    local save = UI.Button(f, "Speichern", "primary", function()
        self:SaveMeta({ perms = { read = getRead(), write = getWrite() }, folder = folder:GetSelectedData() })
        f:Close()
    end)
    save:Dock(BOTTOM)
    save:SetTall(S(48))
    save:DockMargin(0, S(10), 0, 0)
end

function EDITOR:ApplyOps(ops)
    for _, op in ipairs(ops or {}) do
        if op.k == "set" then
            local idx = self:FindIndex(op.block.id)
            if idx then
                self.blocks[idx] = op.block
                local p = self:PanelFor(op.block.id)
                if IsValid(p) and not IsValid(p.entry) then p:SetBlock(op.block) end
            end
        elseif op.k == "insert" then
            local afterIdx = op.after == "" and 0 or (self:FindIndex(op.after) or #self.blocks)
            table.insert(self.blocks, afterIdx + 1, op.block)
            local afterPanel = op.after ~= "" and self:PanelFor(op.after)
            local pIdx = afterPanel and (table.KeyFromValue(self.panels, afterPanel) or #self.panels) or 0
            self:InsertPanel(pIdx + 1, op.block)
        elseif op.k == "remove" then
            local idx = self:FindIndex(op.id)
            if idx then table.remove(self.blocks, idx) end
            local p = self:PanelFor(op.id)
            if IsValid(p) then
                table.RemoveByValue(self.panels, p)
                p:Remove()
                self:Renumber()
            end
        elseif op.k == "move" then
            local idx = self:FindIndex(op.id)
            local target = idx and idx + op.dir
            if idx and self.blocks[target] then self.blocks[idx], self.blocks[target] = self.blocks[target], self.blocks[idx] end
            local p = self:PanelFor(op.id)
            local pi = p and table.KeyFromValue(self.panels, p)
            if pi and self.panels[pi + op.dir] then
                self.panels[pi], self.panels[pi + op.dir] = self.panels[pi + op.dir], self.panels[pi]
                self:Renumber()
            end
        end
    end
end

function EDITOR:SetPresence(users)
    self.users = users or {}
    self.locks = {}
    for _, u in ipairs(self.users) do
        if u.block then self.locks[u.block] = u end
    end
end

function EDITOR:OnRemove()
    if self.id then symchars.net.SendToServer("doc_close", { id = self.id }) end
    timer.Remove("symchars_doc_heartbeat")
    if UI.docEditor == self then UI.docEditor = nil end
end

vgui.Register("symchars.DocEditor", EDITOR, "DPanel")

---------------------------------------------------------------------------------------------------------------
-- Seite
---------------------------------------------------------------------------------------------------------------
local function FolderName(id)
    if id == "public" then return "Öffentlich" end
    local f = F.Get(id)
    return f and f.name or id
end

local function Build(parent, opts)
    local page = vgui.Create("DPanel", parent)
    page:Dock(FILL)
    page.Paint = nil
    local state = { folder = nil, search = "" }

    local left = vgui.Create("DPanel", page)
    left.Paint = function(_, w, h) UI.Panel(0, 0, w, h, { cut = S(14), corners = "tlbr" }) end
    local folderCombo = UI.Combo(left, "Alle Ordner")
    folderCombo:SetFont("symchars.body.bold")
    local search = UI.Entry(left, "Dokument suchen…")
    local list = UI.Scroll(left)
    local newBtn = UI.Button(left, "Neues Dokument", "primary")
    newBtn:SetIcon("plus")
    newBtn:SetFont("symchars.button.small")

    local right = vgui.Create("DPanel", page)
    right.Paint = function(_, w, h)
        if not IsValid(UI.docEditor) then
            UI.Panel(0, 0, w, h, { cut = S(16), corners = "tlbr" })
            UI.Icon("doc", w / 2 - S(40), h / 2 - S(110), S(80), UI.col.faint)
            UI.Text("KEIN DOKUMENT GEÖFFNET", "symchars.h2", w / 2, h / 2, UI.col.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            UI.Text("Wähle links ein Dokument aus.", "symchars.small", w / 2, h / 2 + S(34), UI.col.faint, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local function RebuildList()
        if not IsValid(list) then return end
        list:Clear()
        local q = string.lower(string.Trim(state.search))
        local shown = 0
        for _, doc in ipairs(docState.list) do
            if (not state.folder or doc.folder == state.folder) and (q == "" or string.find(string.lower(doc.title), q, 1, true)) then
                shown = shown + 1
                local row = vgui.Create("DButton", list)
                row:Dock(TOP)
                row:SetTall(S(70))
                row:DockMargin(0, 0, 0, S(4))
                row:SetText("")
                row._hover = 0
                row.Think = function(s) s._hover = UI.Approach(s._hover, s:IsHovered() and 1 or 0, 14) end
                row.Paint = function(s, w, h)
                    local open = IsValid(UI.docEditor) and UI.docEditor.id == doc.id
                    UI.Box(0, 0, w, h, open and Color(30, 26, 18, 235) or UI.Lerp(s._hover, Color(13, 16, 20, 200), Color(22, 26, 32, 230)))
                    if open then UI.Outline(0, 0, w, h, UI.Accent()) end
                    UI.Icon("doc", S(10), S(14), S(30), open and UI.Accent() or UI.col.dim)
                    UI.TextFit(doc.title, "symchars.body.bold", S(50), S(8), UI.col.text, w - S(60))
                    UI.TextFit(FolderName(doc.folder) .. "  ·  " .. U.FormatAgo(doc.updatedAt), "symchars.tiny", S(50), S(34), UI.col.muted, w - S(100))
                    if (doc.editing or 0) > 0 then
                        UI.Chip(doc.editing .. " aktiv", "symchars.tiny.bold", w - S(80), S(36), UI.col.ink, UI.col.green)
                    end
                    if not doc.canWrite then UI.Icon("lock", w - S(30), S(8), S(18), UI.col.faint) end
                    return true
                end
                row.DoClick = function()
                    UI.Sound("click")
                    symchars.net.SendToServer("doc_open", { id = doc.id })
                end
            end
        end
        if shown == 0 then
            local empty = vgui.Create("DLabel", list)
            empty:Dock(TOP)
            empty:SetTall(S(40))
            empty:SetFont("symchars.small")
            empty:SetTextColor(UI.col.muted)
            empty:SetText("  Keine Dokumente.")
        end
    end

    local function RebuildFolders()
        local current = state.folder
        folderCombo:Clear()
        folderCombo:AddChoice("Alle Ordner", nil, current == nil)
        local seen = {}
        for _, doc in ipairs(docState.list) do seen[doc.folder] = true end
        for _, id in ipairs(docState.create) do seen[id] = true end
        if seen.public then folderCombo:AddChoice("Öffentlich", "public", current == "public") end
        for _, item in ipairs(F.GetHierarchyList()) do
            if seen[item.id] then folderCombo:AddChoice(item.label, item.id, current == item.id, item.depth) end
        end
        newBtn:SetVisible(#docState.create > 0)
    end

    folderCombo.OnSelect = function(_, _, _, data)
        state.folder = data
        RebuildList()
    end
    search.OnValueChange = function(_, v) state.search = v or "" RebuildList() end

    newBtn.DoClick = function()
        local choices = {}
        for _, id in ipairs(docState.create) do choices[#choices + 1] = { FolderName(id), id } end
        local function Create(folder)
            UI.Prompt("Neues Dokument", "Titel des Dokuments (Ordner: " .. FolderName(folder) .. ")", "", function(title)
                symchars.net.SendToServer("doc_create", { folder = folder, title = title })
            end)
        end
        if state.folder and table.HasValue(docState.create, state.folder) then
            Create(state.folder)
        elseif #choices == 1 then
            Create(choices[1][2])
        else
            UI.Choose("Ordner wählen", "Wo soll das Dokument liegen?", choices, Create)
        end
    end

    page.PerformLayout = function(_, w, h)
        local leftW = math.min(S(440), w * 0.26)
        left:SetPos(0, 0)
        left:SetSize(leftW, h)
        folderCombo:SetPos(S(14), S(14))
        folderCombo:SetSize(leftW - S(28), S(44))
        search:SetPos(S(14), S(66))
        search:SetSize(leftW - S(28), S(40))
        local bottom = newBtn:IsVisible() and S(66) or S(14)
        list:SetPos(S(14), S(116))
        list:SetSize(leftW - S(28), h - S(116) - bottom)
        newBtn:SetPos(S(14), h - S(58))
        newBtn:SetSize(leftW - S(28), S(46))
        right:SetPos(leftW + S(18), 0)
        right:SetSize(w - leftW - S(18), h)
    end

    page.ListUpdated = function()
        RebuildFolders()
        RebuildList()
    end
    page.OpenEditor = function(meta, blocks)
        if IsValid(UI.docEditor) and UI.docEditor.id == meta.id then
            UI.docEditor:SetDocument(meta, blocks)
            return
        end
        if IsValid(UI.docEditor) then UI.docEditor:Remove() end
        local ed = vgui.Create("symchars.DocEditor", right)
        ed:Dock(FILL)
        ed:SetDocument(meta, blocks)
        UI.docEditor = ed
        RebuildList()
    end
    page.CloseEditor = function()
        if IsValid(UI.docEditor) then
            UI.docEditor.id = nil
            UI.docEditor:Remove()
        end
        RebuildList()
    end

    UI.docPage = page
    symchars.net.SendToServer("doc_list", {})
    if opts.doc then symchars.net.SendToServer("doc_open", { id = opts.doc }) end
    RebuildFolders()
    RebuildList()
end

UI.RegisterPage({ id = "docs", name = "Dokumente", order = 5, needsChar = true, build = Build })

---------------------------------------------------------------------------------------------------------------
-- Netzwerk
---------------------------------------------------------------------------------------------------------------
symchars.net.Receive("doc_list", function(data)
    docState.list = istable(data) and data.docs or {}
    docState.create = istable(data) and data.create or {}
    if IsValid(UI.docPage) then UI.docPage.ListUpdated() end
end)

symchars.net.Receive("doc_full", function(data)
    if not istable(data) or not IsValid(UI.docPage) then return end
    local blocks = {}
    for _, b in ipairs(data.blocks or {}) do
        local clean = D.SanitizeBlock(b)
        if clean then blocks[#blocks + 1] = clean end
    end
    UI.docPage.OpenEditor(data.meta, blocks)
end)

symchars.net.Receive("doc_ops", function(data)
    local ed = UI.docEditor
    if not IsValid(ed) or not istable(data) or data.id ~= ed.id then return end
    ed:ApplyOps(data.ops)
end)

symchars.net.Receive("doc_presence", function(data)
    local ed = UI.docEditor
    if not IsValid(ed) or not istable(data) or data.id ~= ed.id then return end
    ed:SetPresence(data.users)
end)

symchars.net.Receive("doc_meta", function(meta)
    local ed = UI.docEditor
    if not IsValid(ed) or not istable(meta) or meta.id ~= ed.id then return end
    ed.meta = meta
    ed.canWrite, ed.canManage = meta.canWrite == true, meta.canManage == true
    ed:UpdateToolbar()
    symchars.net.SendToServer("doc_list", {})
end)

symchars.net.Receive("doc_lock_denied", function(data)
    local ed = UI.docEditor
    if not IsValid(ed) or not istable(data) then return end
    local p = ed:PanelFor(data.block)
    if IsValid(p) and IsValid(p.entry) then
        p.entry:Remove()
        p.entry = nil
        p:InvalidateLayout(true)
        symchars.Notify("Dieser Abschnitt wird gerade von jemand anderem bearbeitet.", "error")
    end
end)

symchars.net.Receive("doc_closed", function(data)
    if IsValid(UI.docPage) then UI.docPage.CloseEditor() end
    symchars.Notify(istable(data) and data.deleted and "Das Dokument wurde gelöscht." or "Das Dokument wurde geschlossen (keine Berechtigung mehr).", "info")
    symchars.net.SendToServer("doc_list", {})
end)

symchars.net.Receive("doc_created", function(data)
    symchars.net.SendToServer("doc_list", {})
    if istable(data) then symchars.net.SendToServer("doc_open", { id = data.id }) end
end)

symchars.net.Receive("doc_deleted", function()
    if IsValid(UI.docPage) then UI.docPage.CloseEditor() end
    symchars.net.SendToServer("doc_list", {})
end)
