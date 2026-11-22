-- Road to Halion: the main window (header bar with the legal light, tabs on top). Tabs register themselves.
-- Layout (redesign 2026-11-21): header.tga bar at the top (its crystal pokes over the frame), phase line,
-- tab row, then the content area. Ctrl + mouse wheel scales the window (70-130%, saved).
local RTH = RTH
local UI = RTH.UI

local W, H = 600, 610   -- 600 wide (2026-11-21): 110px tabs, so icon + label fit between the tab's ornate ends
local HEADER_Y = 6            -- header texture top, above the window's top edge (the crystal overlaps the frame)
local BAR_MID = -41           -- vertical middle of the header bar, from the window top
local TAB_Y, TAB_H = -88, 26
local CONTENT_TOP = -126      -- content area: 610 - 126 - 30 = 454 px tall (Raid Check's 23 rows need 448)
local CONTENT_BOTTOM = 30     -- the panel behind it ends at 28, clear of the bottom corner ornaments
local SCALE_MIN, SCALE_MAX = 0.7, 1.3
-- one icon per tab (all checked to exist in the 3.3.5 client's icon tables)
local TAB_ICONS = {
  ["Progress"] = "Interface\\Icons\\Achievement_Boss_LichKing",
  ["Raid Check"] = "Interface\\Icons\\INV_Shield_06",
  ["Professions"] = "Interface\\Icons\\Trade_BlackSmithing",
  ["Journey Log"] = "Interface\\Icons\\INV_Misc_Book_09",
  ["Rules"] = "Interface\\Icons\\INV_Scroll_03",
}
-- the same icon inline in a tab's title text ("" for a tab without one)
function UI.TitleIcon(tabName)
  local icon = TAB_ICONS[tabName]
  return icon and ("|T" .. icon .. ":15:15:0:0:64:64:5:59:5:59|t ") or ""
end
UI.CONTENT_W = W - 2 * UI.FRAME_INSET
UI.tabs = {}

function UI.RegisterTab(index, name, build, refresh)
  UI.tabs[index] = { name = name, build = build, refresh = refresh }
end

local main
local current = 1

local function legalState()
  local problems, checks = RTH.CheckEquipped()
  if problems[1] then return "bad", "NOT LEGAL" end
  if checks[1] then return "check", "CHECK" end
  return "ok", "LEGAL"
end

local function refreshHeader()
  if not main then return end
  -- your own phase (what you may wear / use / enter); the guild's furthest next to it when someone is ahead
  local p, far = RTH.MyPhase(), RTH.GetPhase()
  main.sub:SetText(RTH.PhaseLabel(p) .. "  |cffb8b8b8patch " .. RTH.PHASE_PATCH[p] .. "|r"
    .. (far > p and ("  |cffffd040guild: " .. RTH.PHASE_NAMES[far] .. "|r") or ""))
  -- versions: someone newer = we should update; someone older = they should (hover for the names)
  local older, newerList = RTH.VersionReport()
  if newerList[1] then main.verWarn:SetText("|cffff4040update RTH!|r")
  elseif older[1] then main.verWarn:SetText("|cffff4040" .. #older .. " outdated|r")
  else main.verWarn:SetText("") end
  main.verTip:SetWidth(math.max(60, main.verWarn:GetStringWidth() or 0, main.ver:GetStringWidth() or 0))
  if not RTH.Active() then
    main.light:SetState(nil); main.lightText:SetText("OFF")
    return
  end
  local s, label = legalState()
  main.light:SetState(s)
  main.lightText:SetText(label)
end

local function selectTab(i)
  current = i
  for idx, t in pairs(UI.tabs) do
    local b = main.tabButtons[idx]
    if idx == i then
      if not t.frame then
        t.frame = CreateFrame("Frame", nil, main.content)
        t.frame:SetAllPoints(main.content)
        t.build(t.frame)
      end
      t.frame:Show()
      b:LockHighlight()     -- UI.Button: glowing tab_active art, white text
      if t.refresh then t.refresh(t.frame) end
    else
      if t.frame then t.frame:Hide() end
      b:UnlockHighlight()
    end
  end
end
UI.SelectTab = function(i) if main then selectTab(i) end end

function UI.RefreshCurrent()
  if not main or not main:IsShown() then return end
  refreshHeader()
  local t = UI.tabs[current]
  if t and t.frame and t.refresh then t.refresh(t.frame) end
end

local function build()
  main = CreateFrame("Frame", "RTHMainFrame", UIParent)
  main:SetWidth(W); main:SetHeight(H)
  main:SetFrameStrata("HIGH")
  main:SetToplevel(true)
  main:SetClampedToScreen(true)
  main:EnableMouse(true)
  main:SetMovable(true)
  main:RegisterForDrag("LeftButton")
  main:SetScript("OnDragStart", main.StartMoving)
  main:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, rel, x, y = self:GetPoint()
    RTH.db.ui.point = { point, rel, x, y }
  end)
  local pos = RTH.db.ui.point
  if pos then main:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else main:SetPoint("CENTER") end
  local scale = tonumber(RTH.db.ui.scale)
  if scale and scale >= SCALE_MIN and scale <= SCALE_MAX then main:SetScale(scale) end
  -- Zoom (user 2026-11-21: "resizable" = the whole window grows/shrinks evenly; the tabs keep their layout).
  -- The top-left corner stays put: it is re-anchored in screen pixels after every scale change.
  local function setZoom(s)
    s = math.max(SCALE_MIN, math.min(SCALE_MAX, s))
    local left, top = main:GetLeft(), main:GetTop()
    if left and top then
      local px = main:GetEffectiveScale()            -- screen pixels per window unit, before the change
      left, top = left * px, top * px
      main:SetScale(s)
      local unit = main:GetEffectiveScale()          -- after
      main:ClearAllPoints()
      main:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left / unit, top / unit)
      RTH.db.ui.point = { "TOPLEFT", "BOTTOMLEFT", left / unit, top / unit }
    else
      main:SetScale(s)
    end
    RTH.db.ui.scale = s
  end
  UI.SetZoom = setZoom
  -- Ctrl + mouse wheel over the window: 5% steps (scroll lists keep their own wheel)
  main:EnableMouseWheel(true)
  main:SetScript("OnMouseWheel", function(self, delta)
    if not IsControlKeyDown() then return end
    setZoom(math.floor(((self:GetScale() or 1) + delta * 0.05) * 20 + 0.5) / 20)
  end)
  -- size grip in the bottom-right corner (the chat frame's grabber art): drag it out = bigger, in = smaller
  local grip = CreateFrame("Button", nil, main)
  grip:SetWidth(16); grip:SetHeight(16)
  grip:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -5, 5)
  grip:SetFrameLevel(main:GetFrameLevel() + 10)
  grip:SetNormalTexture(RTH.TEX .. "grip")                 -- RTH's own art (round 4)
  grip:SetHighlightTexture(RTH.TEX .. "grip", "ADD")
  grip:SetPushedTexture(RTH.TEX .. "grip")
  local hl, pushed = grip:GetHighlightTexture(), grip:GetPushedTexture()   -- (never index a getter's result unguarded)
  if hl then hl:SetAlpha(0.4) end
  if pushed then pushed:SetVertexColor(0.75, 0.75, 0.75) end
  grip:SetScript("OnMouseDown", function(self)
    self:SetScript("OnUpdate", function()
      -- the zoom that puts the window's bottom-right corner under the cursor (average of width and height)
      local cx, cy = GetCursorPosition()
      local eff, cur, l, t = main:GetEffectiveScale(), main:GetScale(), main:GetLeft(), main:GetTop()
      if not (cx and eff and cur and l and t) or cur == 0 then return end   -- not laid out yet: wait a frame
      local px = eff / cur   -- screen pixels per unit at zoom 1
      local left, top = l * eff, t * eff
      local s = ((cx - left) / (W * px) + (top - cy) / (H * px)) / 2
      if math.abs(s - cur) >= 0.005 then setZoom(s) end
    end)
  end)
  grip:SetScript("OnMouseUp", function(self)
    self:SetScript("OnUpdate", nil)
    setZoom(math.floor((main:GetScale() or 1) * 100 + 0.5) / 100)   -- keep a tidy number
  end)
  UI.Tip(grip, function(tt)
    tt:AddLine("Drag to make the window bigger or smaller")
    tt:AddLine("(or hold Ctrl and turn the mouse wheel)", 0.7, 0.7, 0.7)
  end)
  main.grip = grip
  UI.NineSlice(main, "window_border")
  table.insert(UISpecialFrames, "RTHMainFrame")   -- Escape closes it

  -- header bar: header.tga is 512x64, the bar fills rows 30-63 and the crystal (x 226-286) rises above it.
  -- 5 pieces so only the plain stretches between them are stretched: end | plain | crystal | plain | end
  local hx, hw, END, CR0, CR1 = 10, W - 20, 40, 226, 286
  local plain = hw - 2 * END - (CR1 - CR0)
  local pieces = { { 0, END, END }, { END, CR0, math.floor(plain / 2) }, { CR0, CR1, CR1 - CR0 },
    { CR1, 512 - END, plain - math.floor(plain / 2) }, { 512 - END, 512, END } }
  local x = hx
  for _, p in ipairs(pieces) do
    local t = main:CreateTexture(nil, "ARTWORK")   -- above the frame (BORDER): the crystal overlaps it
    t:SetTexture(RTH.TEX .. "header")
    t:SetTexCoord(p[1] / 512, p[2] / 512, 0, 1)
    t:SetWidth(p[3]); t:SetHeight(64)
    t:SetPoint("TOPLEFT", main, "TOPLEFT", x, HEADER_Y)
    x = x + p[3]
  end
  -- title plate (art round 5): its own small frame above the header bar, with the title text on it (a texture on
  -- main would have to sit between the bar and the text, and main has no free layer for that)
  local plate = CreateFrame("Frame", nil, main)
  plate:SetWidth(236); plate:SetHeight(32)
  plate:SetPoint("CENTER", main, "TOP", 0, BAR_MID + 1)
  local pcap, px0 = math.floor(40 * 32 / 123), 40 / 512
  local pl, pm, pr = plate:CreateTexture(nil, "BACKGROUND"), plate:CreateTexture(nil, "BACKGROUND"), plate:CreateTexture(nil, "BACKGROUND")
  for _, t in ipairs({ pl, pm, pr }) do t:SetTexture(RTH.TEX .. "title_plate") end
  pl:SetTexCoord(0, px0, 2 / 128, 125 / 128); pm:SetTexCoord(px0, 1 - px0, 2 / 128, 125 / 128); pr:SetTexCoord(1 - px0, 1, 2 / 128, 125 / 128)
  pl:SetWidth(pcap); pl:SetPoint("TOPLEFT", plate, "TOPLEFT"); pl:SetPoint("BOTTOMLEFT", plate, "BOTTOMLEFT")
  pr:SetWidth(pcap); pr:SetPoint("TOPRIGHT", plate, "TOPRIGHT"); pr:SetPoint("BOTTOMRIGHT", plate, "BOTTOMRIGHT")
  pm:SetPoint("TOPLEFT", pl, "TOPRIGHT"); pm:SetPoint("BOTTOMRIGHT", pr, "BOTTOMLEFT")
  main.title = UI.Text(plate, "large", UI.GOLD, "CENTER")
  main.title:SetPoint("CENTER", plate, "CENTER", 0, 1)
  main.title:SetText("ROAD TO HALION")
  main.sub = UI.Text(main, nil, { 1, 1, 1 }, "CENTER")
  main.sub:SetPoint("TOP", main, "TOP", 0, -66)
  local close = CreateFrame("Button", nil, main, "UIPanelCloseButton")   -- the template keeps its click = hide
  close:SetWidth(22); close:SetHeight(22)
  close:SetPoint("CENTER", main, "TOPRIGHT", -36, BAR_MID)
  -- RTH's own art (round 4): blue X, red X under the mouse / while pressed
  close:SetNormalTexture(RTH.TEX .. "close")
  close:SetPushedTexture(RTH.TEX .. "close_hover")
  close:SetHighlightTexture(RTH.TEX .. "close_hover", "BLEND")
  main.light = UI.Light(main, 26, "OVERLAY")   -- sits on the header bar (ARTWORK)
  main.light:SetPoint("CENTER", main, "TOPRIGHT", -99, BAR_MID)
  main.lightText = UI.Text(main, "small", { 1, 1, 1 }, "LEFT")
  main.lightText:SetPoint("LEFT", main.light, "RIGHT", 3, 0)
  local lightTip = CreateFrame("Frame", nil, main)
  lightTip:SetAllPoints(main.light)
  lightTip:EnableMouse(true)   -- (without it a plain frame gets no hover or click in the game - fixed 2026-11-22)
  main.lightTip = lightTip
  -- "why?": slot, item, reason and what to do, per item (user request 2026-11-22)
  UI.Tip(lightTip, function(tt)
    tt:AddLine("Your gear right now")
    local problems, checks = RTH.CheckEquipped()
    for _, p in ipairs(problems) do
      tt:AddLine(RTH.SlotName(p.slot) .. ": " .. (p.link or "") .. " - " .. p.reason, 1, 0.3, 0.3, true)
      tt:AddLine("   " .. RTH.GearHint(p.reason), 0.85, 0.85, 0.85, true)
    end
    for _, c in ipairs(checks) do
      tt:AddLine(RTH.SlotName(c.slot) .. ": " .. (c.link or "") .. " - " .. c.reason, 1, 0.82, 0.2, true)
      tt:AddLine("   " .. RTH.GearHint(c.reason), 0.85, 0.85, 0.85, true)
    end
    if not problems[1] and not checks[1] then tt:AddLine("Everything you wear is allowed.", 0.3, 0.9, 0.4) end
    if not RTH.GearCounts("player") then tt:AddLine("Leveling: gear rules start at level " .. RTH.GEAR_LEVEL .. ".", 0.7, 0.7, 0.7) end
    if problems[1] or checks[1] then tt:AddLine("Click: the same list in chat", 0.5, 0.8, 1) end
  end)
  lightTip:SetScript("OnMouseUp", function()
    local problems, checks = RTH.CheckEquipped()
    if not problems[1] and not checks[1] then RTH.Print("|cff40ff40everything you wear is allowed|r"); return end
    RTH.Print("your gear - " .. #problems .. " not allowed, " .. #checks .. " to check:")
    for _, p in ipairs(problems) do
      RTH.Print("  |cffff4040" .. RTH.SlotName(p.slot) .. "|r " .. (p.link or "") .. " - " .. p.reason .. " |cffb8b8b8(" .. RTH.GearHint(p.reason) .. ")|r")
    end
    for _, c in ipairs(checks) do
      RTH.Print("  |cffffd040" .. RTH.SlotName(c.slot) .. "|r " .. (c.link or "") .. " - " .. c.reason .. " |cffb8b8b8(" .. RTH.GearHint(c.reason) .. ")|r")
    end
  end)
  -- this copy's version (left end of the bar, across from the light) and who runs another one
  main.ver = UI.Text(main, "small", { 0.72, 0.72, 0.72 }, "LEFT")
  main.ver:SetPoint("LEFT", main, "TOPLEFT", 44, BAR_MID + 6)
  main.ver:SetText("RTH " .. RTH.VERSION)
  main.verWarn = UI.Text(main, "small", nil, "LEFT")
  main.verWarn:SetPoint("TOPLEFT", main.ver, "BOTTOMLEFT", 0, -2)
  main.verTip = CreateFrame("Frame", nil, main)
  main.verTip:SetPoint("TOPLEFT", main.ver, "TOPLEFT", 0, 2)
  main.verTip:SetPoint("BOTTOMLEFT", main.verWarn, "BOTTOMLEFT", 0, -2)   -- left edges agree; width set below
  main.verTip:SetWidth(60)
  main.verTip:EnableMouse(true)
  UI.Tip(main.verTip, function(tt)
    tt:AddLine("Road to Halion " .. RTH.VERSION)
    local older, newerList = RTH.VersionReport()
    if newerList[1] then
      tt:AddLine("A newer version is in the guild - ask the guild master for it:", 1, 0.3, 0.3, true)
      for _, e in ipairs(newerList) do tt:AddLine("  " .. RTH.ClassColorName(e.name) .. " - " .. e.version, 1, 1, 1) end
    end
    if older[1] then
      tt:AddLine("Outdated - they need " .. RTH.VERSION .. ":", 1, 0.3, 0.3, true)
      for _, e in ipairs(older) do tt:AddLine("  " .. RTH.ClassColorName(e.name) .. " - " .. e.version, 1, 1, 1) end
    end
    if not older[1] and not newerList[1] then
      tt:AddLine("Everyone RTH has heard from has the same version.", 0.3, 0.9, 0.4, true)
    end
    tt:AddLine("Players on a very old copy may not be heard at all - check with /rth sync.", 0.7, 0.7, 0.7, true)
  end)
  -- tab row under the phase line: the same tab art as every RTH button (UI.Button), the chosen one locked bright
  main.tabButtons = {}
  local n, gap = #UI.tabs, 4
  local tw = math.floor((W - 2 * UI.FRAME_INSET - (n - 1) * gap) / n)
  for i = 1, n do
    local b = UI.Button(main, UI.tabs[i].name, tw, TAB_H, function() selectTab(i) end, "tab")
    b.text:SetFontObject(GameFontNormal); UI.Outline(b.text)
    local file = b.text:GetFont()
    if file then b.text:SetFont(file, 11, "OUTLINE") end   -- 11px: icon + label fit between the tab's ends
    -- tab icon (user 2026-11-21: find tabs at a glance), left of the label; icon + gap + label centred together
    local icon = TAB_ICONS[UI.tabs[i].name]
    if icon then
      b.icon = b:CreateTexture(nil, "ARTWORK")
      b.icon:SetTexture(icon)
      b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)   -- trim the icon's built-in border
      b.icon:SetWidth(14); b.icon:SetHeight(14)
      b.icon:SetPoint("RIGHT", b.text, "LEFT", -3, 0)
      b.textX = math.floor(17 / 2 + 0.5)
      b.text:ClearAllPoints()
      b.text:SetPoint("CENTER", b, "CENTER", b.textX, 0)
    end
    b:SetPoint("TOPLEFT", main, "TOPLEFT", UI.FRAME_INSET + (i - 1) * (tw + gap), TAB_Y)
    main.tabButtons[i] = b
  end
  -- content (each tab draws its own boxed sections, UI.Section, 4px outside its regions)
  main.content = CreateFrame("Frame", nil, main)
  main.content:SetPoint("TOPLEFT", main, "TOPLEFT", UI.FRAME_INSET, CONTENT_TOP)
  main.content:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -UI.FRAME_INSET, CONTENT_BOTTOM)

  main:SetScript("OnShow", function() refreshHeader(); selectTab(current) end)
  main:Hide()   -- new frames start shown: without this the first /rth or click "toggled" it closed
end

function RTH.ToggleMain()
  if not RTH.db then return end
  if not main then build() end
  if main:IsShown() then main:Hide() else main:Show() end
end

for _, msg in ipairs({ "PHASE_CHANGED", "KILL", "WIPE", "MEMBERS_CHANGED", "PROFESSIONS_CHANGED", "COOLDOWNS_CHANGED", "GATE_STATUS", "INSPECT_DONE", "ITEM_SEARCH", "LOCKOUTS_CHANGED", "BREAKS_CHANGED", "GATES_CHANGED", "ROSTER_CHANGED", "GUILD_LIST", "MY_PHASE_CHANGED", "REP_CHANGED" }) do
  RTH.Listen(msg, function() RTH.After("uiRefresh", 0.2, UI.RefreshCurrent) end)
end
RTH.On("PLAYER_EQUIPMENT_CHANGED", function() RTH.After("uiRefresh", 0.5, UI.RefreshCurrent) end)
RTH.On("ACHIEVEMENT_EARNED", function() RTH.After("uiRefresh", 1, UI.RefreshCurrent) end)
