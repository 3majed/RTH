-- Road to Halion: minimap button, phase unlock banner, night summary, copy box
local RTH = RTH
local UI = RTH.UI

-- ---------------------------------------------------------------- minimap button
local mm
local function placeMinimap()
  local a = math.rad(RTH.db.ui.minimapAngle or 200)
  mm:ClearAllPoints()
  mm:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 80, math.sin(a) * 80)
end

function RTH.UpdateMinimapButton()
  if not RTH.db then return end
  if not mm then
    mm = CreateFrame("Button", "RTHMinimapButton", Minimap)
    mm:SetWidth(31); mm:SetHeight(31)
    mm:SetFrameStrata("MEDIUM")
    mm:SetFrameLevel(8)
    mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mm:RegisterForDrag("LeftButton")
    -- minimap.tga carries its own ring, so it fills the button; minimap_hover is the same orb, brighter ring
    local icon = UI.Texture(mm, "minimap", 31, 31, "ARTWORK")
    icon:SetAllPoints(mm)
    local hover = UI.Texture(mm, "minimap_hover", 31, 31, "HIGHLIGHT")
    hover:SetAllPoints(mm)
    mm:SetScript("OnClick", function(_, button)
      if button == "RightButton" then RTH.RequestStatus(); RTH.Print("asked the group for their status")
      else RTH.ToggleMain() end
    end)
    mm:SetScript("OnDragStart", function(self)
      self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local s = Minimap:GetEffectiveScale()
        RTH.db.ui.minimapAngle = math.deg(math.atan2(cy / s - my, cx / s - mx))
        placeMinimap()
      end)
    end)
    mm:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    UI.Tip(mm, function(tt)
      tt:AddLine("Road to Halion", 0.85, 0.64, 0.25)
      tt:AddLine("You: " .. RTH.PhaseLabel(RTH.MyPhase()), 1, 1, 1)
      if RTH.GetPhase() > RTH.MyPhase() then tt:AddLine("Furthest in the guild: " .. RTH.PhaseLabel(RTH.GetPhase()), 0.8, 0.8, 0.8) end
      tt:AddLine("Left-click: open   Right-click: check the group", 0.7, 0.7, 0.7)
    end)
  end
  placeMinimap()
  UI.Shown(mm, RTH.db.ui.minimap)
end
RTH.Listen("DB_READY", RTH.UpdateMinimapButton)

-- ---------------------------------------------------------------- phase unlock banner
local banner
RTH.Listen("PHASE_UNLOCKED", function(p)
  if not banner then
    banner = CreateFrame("Frame", "RTHBanner", UIParent)
    banner:SetWidth(512); banner:SetHeight(166)   -- banner_unlock art: 512x166 in a 512x256 file (rows 45-211)
    banner:SetPoint("TOP", UIParent, "TOP", 0, -160)
    banner:SetFrameStrata("HIGH")
    local bg = UI.Texture(banner, "banner_unlock", 512, 166, "BACKGROUND")
    bg:SetAllPoints(banner)
    bg:SetTexCoord(0, 1, 45 / 256, 211 / 256)
    banner.text = UI.Text(banner, "large", { 1, 0.85, 0.4 }, "CENTER")
    banner.text:SetPoint("CENTER", banner, "CENTER", 0, 10)
    banner.sub = UI.Text(banner, nil, { 1, 1, 1 }, "CENTER")
    banner.sub:SetPoint("TOP", banner.text, "BOTTOM", 0, -6)
    banner:SetScript("OnUpdate", function(self, elapsed)
      self.age = (self.age or 0) + elapsed
      if self.age > 6 then self:SetAlpha(math.max(0, 1 - (self.age - 6))) end
      if self.age > 7 then self:Hide() end
    end)
  end
  local g = RTH.db.group
  local y, m, d = (g.started or ""):match("(%d+)-(%d+)-(%d+)")
  local day = y and (math.floor((time() - time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0 })) / 86400) + 1) or 1
  banner.text:SetText("PHASE " .. p .. " UNLOCKED")
  banner.sub:SetText(RTH.PHASE_LONG[p] .. "  -  day " .. day)
  banner.age = 0
  banner:SetAlpha(1)
  banner:Show()
  PlaySound("LEVELUPSOUND")
end)

-- ---------------------------------------------------------------- night summary (leaving a raid)
local summary
RTH.Listen("SESSION_ENDED", function(s)
  if not summary then
    summary = CreateFrame("Frame", "RTHSummary", UIParent)
    -- inside the frame line (UI.FRAME_INSET) and above the bottom corner ornaments (they reach 52px up)
    local inset = UI.FRAME_INSET
    summary:SetWidth(300); summary:SetHeight(200)
    summary:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    summary:SetFrameStrata("DIALOG")
    summary:EnableMouse(true)
    UI.NineSlice(summary, "window_border")
    summary.title = UI.Text(summary, nil, UI.GOLD, "CENTER")
    summary.title:SetPoint("TOP", summary, "TOP", 0, -inset)
    summary.body = UI.Text(summary, nil, { 1, 1, 1 })
    summary.body:SetPoint("TOPLEFT", summary, "TOPLEFT", inset, -inset - 22)
    summary.body:SetWidth(300 - 2 * inset)
    local ok = UI.Button(summary, "Copy for Discord", 130, 22, function() RTH.ShowCopyBox(summary.copyText) end)
    ok:SetPoint("BOTTOMLEFT", summary, "BOTTOMLEFT", inset, 56)
    local close = UI.Button(summary, "Close", 90, 22, function() summary:Hide() end)
    close:SetPoint("BOTTOMRIGHT", summary, "BOTTOMRIGHT", -inset, 56)
  end
  -- MVP: the raid member with the fewest deaths tonight
  local mvp, best = nil, math.huge
  for _, unit in ipairs(RTH.GroupUnits()) do
    local n = RTH.UnitKey(unit)
    if n then
      local d = s.deaths[n] or 0
      if d < best then mvp, best = n, d end
    end
  end
  -- rule breaks by people who were in tonight's raid (the shared log also has guildies' breaks from elsewhere)
  local breaks = 0
  for _, b in ipairs(RTH.db.group.breaks) do   -- by time (a log catch-up inserts older breaks into the list)
    if b.t >= s.start and (not s.seen or s.seen[b.who]) then breaks = breaks + 1 end
  end
  summary.title:SetText("TONIGHT - " .. (s.name or "raid"))
  summary.body:SetText(s.kills .. " kills    " .. s.wipes .. " wipes    " .. s.totalDeaths .. " deaths\n"
    .. "MVP: " .. (mvp and RTH.ClassColorName(mvp) or "-") .. " (" .. (best == math.huge and 0 or best) .. " deaths)\n"
    .. "Rule breaks: " .. (breaks == 0 and "|cff40ff40none|r" or ("|cffff4040" .. breaks .. "|r")))
  summary.copyText = "Tonight in " .. (s.name or "the raid") .. ": " .. s.kills .. " kills, " .. s.wipes .. " wipes, "
    .. s.totalDeaths .. " deaths. MVP: " .. (mvp or "-") .. ". Rule breaks: " .. breaks .. "."
  summary:Show()
end)

-- ---------------------------------------------------------------- copy box
-- (user 2026-11-21: close button, copy button, resizable). WoW 3.3.5 has NO way for an addon to put text on the
-- clipboard, so "Select all" selects the whole text and focuses the box: Ctrl+C then copies it.
-- Layout: title band (title + close X), the text in a framed box, a bottom row (Select all, hint, resize grip).
-- Drag the title to move it, the grip to resize it (340x200 .. 900x700; the text re-wraps); the size is saved.
local COPY_MIN_W, COPY_MIN_H, COPY_MAX_W, COPY_MAX_H = 340, 200, 900, 700
local copy
function RTH.ShowCopyBox(text)
  if not copy then
    local saved = RTH.db and RTH.db.ui.copySize
    local w = saved and saved[1] or 460
    local h = saved and saved[2] or 300
    copy = CreateFrame("Frame", "RTHCopyBox", UIParent)
    copy:SetWidth(w); copy:SetHeight(h)
    copy:SetPoint("CENTER")
    copy:SetFrameStrata("DIALOG")
    copy:SetToplevel(true)
    copy:SetClampedToScreen(true)
    copy:EnableMouse(true)
    copy:SetMovable(true)
    copy:SetResizable(true)
    copy:SetMinResize(COPY_MIN_W, COPY_MIN_H)
    copy:SetMaxResize(COPY_MAX_W, COPY_MAX_H)
    copy:RegisterForDrag("LeftButton")
    copy:SetScript("OnDragStart", copy.StartMoving)
    copy:SetScript("OnDragStop", copy.StopMovingOrSizing)
    UI.NineSlice(copy, "window_border")
    local inset = UI.FRAME_INSET
    -- title band with the title and the close button
    UI.Section(copy, inset - 4, -12, -(inset - 4), nil, 26, { band = 26 })
    local t = UI.Text(copy, nil, UI.GOLD)
    t:SetPoint("LEFT", copy, "TOPLEFT", inset + 2, -25)
    t:SetText(UI.TitleIcon("Journey Log") .. "COPY FOR DISCORD")
    local close = CreateFrame("Button", nil, copy, "UIPanelCloseButton")   -- the template's click hides the box
    close:SetWidth(20); close:SetHeight(20)
    close:SetPoint("CENTER", copy, "TOPRIGHT", -(inset + 8), -25)
    close:SetNormalTexture(RTH.TEX .. "close")
    close:SetPushedTexture(RTH.TEX .. "close_hover")
    close:SetHighlightTexture(RTH.TEX .. "close_hover", "BLEND")
    -- the text, in its own box; the scroll bar hangs ~22px right of the scroll frame, inside the box
    UI.Section(copy, inset - 4, -42, -(inset - 4), 52)
    local sf = UI.StyleScroll(CreateFrame("ScrollFrame", "RTHCopyScroll", copy, "UIPanelScrollFrameTemplate"))
    sf:SetPoint("TOPLEFT", copy, "TOPLEFT", inset + 2, -48)
    sf:SetPoint("BOTTOMRIGHT", copy, "BOTTOMRIGHT", -(inset + 24), 58)
    copy.edit = CreateFrame("EditBox", nil, sf)
    copy.edit:SetMultiLine(true)
    copy.edit:SetFontObject(ChatFontNormal); UI.Outline(copy.edit)
    copy.edit:SetAutoFocus(true)
    copy.edit:SetScript("OnEscapePressed", function() copy:Hide() end)
    sf:SetScrollChild(copy.edit)
    local function fitText() copy.edit:SetWidth(math.max(50, (copy:GetWidth() or w) - 2 * inset - 30)) end
    fitText()
    copy:SetScript("OnSizeChanged", fitText)   -- resizing re-wraps the text
    -- bottom row: Select all + hint, and the resize grip in the corner
    local sel = UI.Button(copy, "Select all", 100, 22, function()
      copy.edit:SetFocus()
      copy.edit:HighlightText()
    end)
    sel:SetPoint("BOTTOMLEFT", copy, "BOTTOMLEFT", inset + 6, 22)
    UI.Tip(sel, function(tt)
      tt:AddLine("Select all")
      tt:AddLine("Then press Ctrl+C to copy (WoW doesn't let addons copy for you).", 0.72, 0.72, 0.72, true)
    end)
    local hint = UI.Text(copy, "small", { 0.72, 0.72, 0.72 })
    hint:SetPoint("LEFT", sel, "RIGHT", 10, 0)
    hint:SetPoint("RIGHT", copy, "RIGHT", -(inset + 20), 0)
    hint:SetText("then Ctrl+C to copy  -  Escape closes")
    local grip = CreateFrame("Button", nil, copy)
    grip:SetWidth(16); grip:SetHeight(16)
    grip:SetPoint("BOTTOMRIGHT", copy, "BOTTOMRIGHT", -5, 5)
    grip:SetFrameLevel(copy:GetFrameLevel() + 10)
    grip:SetNormalTexture(RTH.TEX .. "grip")
    grip:SetHighlightTexture(RTH.TEX .. "grip", "ADD")
    local ghl = grip:GetHighlightTexture()
    if ghl then ghl:SetAlpha(0.4) end
    grip:SetScript("OnMouseDown", function() copy:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
      copy:StopMovingOrSizing()
      if RTH.db then RTH.db.ui.copySize = { math.floor(copy:GetWidth() + 0.5), math.floor(copy:GetHeight() + 0.5) } end
    end)
    UI.Tip(grip, function(tt) tt:AddLine("Drag to resize") end)
    table.insert(UISpecialFrames, "RTHCopyBox")
  end
  copy.edit:SetText(text or "")
  copy:Show()
  copy.edit:SetFocus()
  copy.edit:HighlightText()
end

-- ---------------------------------------------------------------- the rules window (2026-11-22)
-- "How the rules work" (Rules tab): RTH.RulesText() in plain words, read-only and scrollable; it is built again
-- every time it opens, so your phase and the open raids are always the current ones. Escape closes it.
local rulesBox
function RTH.ShowRules()
  if not rulesBox then
    local w, h = 520, 420
    rulesBox = CreateFrame("Frame", "RTHRulesBox", UIParent)
    rulesBox:SetWidth(w); rulesBox:SetHeight(h)
    rulesBox:SetPoint("CENTER")
    rulesBox:SetFrameStrata("DIALOG")
    rulesBox:SetToplevel(true)
    rulesBox:SetClampedToScreen(true)
    rulesBox:EnableMouse(true)
    rulesBox:SetMovable(true)
    rulesBox:RegisterForDrag("LeftButton")
    rulesBox:SetScript("OnDragStart", rulesBox.StartMoving)
    rulesBox:SetScript("OnDragStop", rulesBox.StopMovingOrSizing)
    UI.NineSlice(rulesBox, "window_border")
    local inset = UI.FRAME_INSET
    UI.Section(rulesBox, inset - 4, -12, -(inset - 4), nil, 26, { band = 26 })
    local t = UI.Text(rulesBox, nil, UI.GOLD)
    t:SetPoint("LEFT", rulesBox, "TOPLEFT", inset + 2, -25)
    t:SetText(UI.TitleIcon("Rules") .. "HOW THE RULES WORK")
    local close = CreateFrame("Button", nil, rulesBox, "UIPanelCloseButton")
    close:SetWidth(20); close:SetHeight(20)
    close:SetPoint("CENTER", rulesBox, "TOPRIGHT", -(inset + 8), -25)
    close:SetNormalTexture(RTH.TEX .. "close")
    close:SetPushedTexture(RTH.TEX .. "close_hover")
    close:SetHighlightTexture(RTH.TEX .. "close_hover", "BLEND")
    UI.Section(rulesBox, inset - 4, -42, -(inset - 4), 12)
    local sf = UI.StyleScroll(CreateFrame("ScrollFrame", "RTHRulesScroll", rulesBox, "UIPanelScrollFrameTemplate"))
    sf:SetPoint("TOPLEFT", rulesBox, "TOPLEFT", inset + 4, -48)
    sf:SetPoint("BOTTOMRIGHT", rulesBox, "BOTTOMRIGHT", -(inset + 24), 18)
    local child = CreateFrame("Frame", nil, sf)
    local textW = w - 2 * inset - 34
    child:SetWidth(textW); child:SetHeight(10)
    rulesBox.text = UI.Text(child, nil, { 0.92, 0.92, 0.92 }, "LEFT")
    rulesBox.text:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
    rulesBox.text:SetWidth(textW)
    rulesBox.text:SetJustifyV("TOP")
    rulesBox.child = child
    sf:SetScrollChild(child)
    rulesBox.scroll = sf
    table.insert(UISpecialFrames, "RTHRulesBox")
  end
  rulesBox:Show()   -- (shown first: the text's wrapped height is read right after)
  rulesBox.text:SetText(RTH.RulesText())
  rulesBox.child:SetHeight(math.max(10, (rulesBox.text:GetHeight() or 10) + 8))
  rulesBox.scroll:SetVerticalScroll(0)
  rulesBox:Show()
end
