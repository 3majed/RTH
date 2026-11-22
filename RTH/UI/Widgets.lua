-- Road to Halion: small UI building blocks
local RTH = RTH
local UI = {}
RTH.UI = UI

local FONT = "GameFontNormal"
UI.GOLD = { 0.85, 0.64, 0.25 }

-- window_border.tga (256x256, redesign 2026-11-21) cut in 9 pieces so the ice corners stay sharp at any size.
-- The frame band runs 3-11px in and the corner ornaments reach ~27px, so cut at 32 and keep content
-- UI.FRAME_INSET in from the edge. The centre of the file is transparent; a plain gradient fills it.
UI.FRAME_INSET = 16
function UI.NineSlice(frame, file, corner)
  corner = corner or 32
  local tex = RTH.TEX .. file
  local c = corner / 256
  local parts = {
    { "TOPLEFT", 0, c, 0, c }, { "TOPRIGHT", 1 - c, 1, 0, c },
    { "BOTTOMLEFT", 0, c, 1 - c, 1 }, { "BOTTOMRIGHT", 1 - c, 1, 1 - c, 1 },
  }
  local t = {}
  for i, p in ipairs(parts) do
    local x = frame:CreateTexture(nil, "BORDER")
    x:SetTexture(tex); x:SetTexCoord(p[2], p[3], p[4], p[5])
    x:SetWidth(corner); x:SetHeight(corner); x:SetPoint(p[1], frame, p[1])
    t[i] = x
  end
  -- edges and centre stretch between the corners
  local top = frame:CreateTexture(nil, "BORDER")
  top:SetTexture(tex); top:SetTexCoord(c, 1 - c, 0, c)
  top:SetPoint("TOPLEFT", t[1], "TOPRIGHT"); top:SetPoint("BOTTOMRIGHT", t[2], "BOTTOMLEFT")
  local bottom = frame:CreateTexture(nil, "BORDER")
  bottom:SetTexture(tex); bottom:SetTexCoord(c, 1 - c, 1 - c, 1)
  bottom:SetPoint("TOPLEFT", t[3], "TOPRIGHT"); bottom:SetPoint("BOTTOMRIGHT", t[4], "BOTTOMLEFT")
  local left = frame:CreateTexture(nil, "BORDER")
  left:SetTexture(tex); left:SetTexCoord(0, c, c, 1 - c)
  left:SetPoint("TOPLEFT", t[1], "BOTTOMLEFT"); left:SetPoint("BOTTOMRIGHT", t[3], "TOPRIGHT")
  local right = frame:CreateTexture(nil, "BORDER")
  right:SetTexture(tex); right:SetTexCoord(1 - c, 1, c, 1 - c)
  right:SetPoint("TOPLEFT", t[2], "BOTTOMLEFT"); right:SetPoint("BOTTOMRIGHT", t[4], "TOPRIGHT")
  -- plain background (user 2026-11-21: the brushed-steel tile was too busy behind the text): dark navy, a little
  -- lighter at the top. One solid texture under the frame pieces (BORDER), 6px in so the frame band covers its edge.
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(1, 1, 1, 1)
  -- fully opaque: at 0.97 nameplates behind the window still showed through (user screenshot 2026-11-21)
  bg:SetGradientAlpha("VERTICAL", 8 / 255, 14 / 255, 20 / 255, 1, 20 / 255, 33 / 255, 44 / 255, 1)   -- bottom, top
  bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
  bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
end

-- All RTH text is outlined (user 2026-11-21): the same font and size, with a thin black outline instead of the
-- drop shadow. Done per text (FontString / EditBox SetFont), not with CreateFont objects. A later SetFontObject
-- drops the outline again, so call UI.Outline after every SetFontObject.
function UI.Outline(obj)
  local file, size = obj:GetFont()
  if file and size then
    obj:SetFont(file, size, "OUTLINE")
    obj:SetShadowOffset(0, 0)
  end
  return obj
end

function UI.Text(parent, size, color, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY", size == "large" and "GameFontNormalLarge" or size == "small" and "GameFontHighlightSmall" or FONT)
  UI.Outline(fs)
  if color then fs:SetTextColor(color[1], color[2], color[3]) end
  fs:SetJustifyH(justify or "LEFT")
  return fs
end

function UI.Texture(parent, file, w, h, layer)
  local t = parent:CreateTexture(nil, layer or "ARTWORK")
  t:SetTexture(RTH.TEX .. file)
  t:SetWidth(w); t:SetHeight(h)
  return t
end

-- Button art, cut in 3 so the ends stay sharp at any width (the middle stretches). Two styles:
--   tab    - the main window's tabs: tab.tga / tab_active.tga (256x64; rows 16-48 drawn = rim + some glow;
--            slanted ends with gems 19px)
--   action - every other button (art round 5, 2026-11-21: so "do something" no longer looks like "switch page"):
--            button.tga / button_hover.tga (512x128; art rows 12-116; rounded ends with ice rivets ~42px)
local BUTTON_STYLES = {
  tab = { file = "tab", hot = "tab_active", w = 256, h = 64, cap = 19, y0 = 16, y1 = 48 },
  action = { file = "button", hot = "button_hover", w = 512, h = 128, cap = 42, y0 = 12, y1 = 116 },
}
local function buttonSkin(b, file)
  for i = 1, 3 do b.skin[i]:SetTexture(RTH.TEX .. file) end
end

function UI.Button(parent, text, w, h, onClick, style)
  w, h = w or 100, h or 22
  local st = BUTTON_STYLES[style or "action"]
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(w); b:SetHeight(h)
  local cx, y0, y1 = st.cap / st.w, st.y0 / st.h, st.y1 / st.h
  local cap = math.min(math.floor(st.cap * h / (st.y1 - st.y0)), math.floor(w / 2))   -- the end, scaled to h
  local left = b:CreateTexture(nil, "BACKGROUND")
  left:SetWidth(cap); left:SetPoint("TOPLEFT", b, "TOPLEFT"); left:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT")
  left:SetTexCoord(0, cx, y0, y1)
  local right = b:CreateTexture(nil, "BACKGROUND")
  right:SetWidth(cap); right:SetPoint("TOPRIGHT", b, "TOPRIGHT"); right:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT")
  right:SetTexCoord(1 - cx, 1, y0, y1)
  local mid = b:CreateTexture(nil, "BACKGROUND")
  mid:SetPoint("TOPLEFT", left, "TOPRIGHT"); mid:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
  mid:SetTexCoord(cx, 1 - cx, y0, y1)
  b.skin = { left, mid, right }
  buttonSkin(b, st.file)
  b.text = UI.Outline(b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
  b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
  b:SetFontString(b.text)
  b:SetText(text)
  -- bright art on hover and while "selected" (LockHighlight, e.g. the chosen tab)
  local function look()
    local on = b:IsEnabled() == 1 or b:IsEnabled() == true
    buttonSkin(b, (b.hover or b.locked) and st.hot or st.file)
    for i = 1, 3 do b.skin[i]:SetDesaturated(not on) end
    if not on then b.text:SetTextColor(0.5, 0.5, 0.5)
    elseif b.hover or b.locked then b.text:SetTextColor(1, 1, 1)
    else b.text:SetTextColor(1, 0.85, 0.4) end
  end
  b:SetScript("OnEnter", function() b.hover = true; look() end)
  b:SetScript("OnLeave", function() b.hover = nil; look() end)
  hooksecurefunc(b, "LockHighlight", function() b.locked = true; look() end)
  hooksecurefunc(b, "UnlockHighlight", function() b.locked = nil; look() end)
  -- b.textX: the label's resting x offset (e.g. shifted right to make room for an icon); pressed = 1px right/down
  b:SetScript("OnMouseDown", function() if b.hover then b.text:SetPoint("CENTER", b, "CENTER", (b.textX or 0) + 1, -1) end end)
  b:SetScript("OnMouseUp", function() b.text:SetPoint("CENTER", b, "CENTER", b.textX or 0, 0) end)
  hooksecurefunc(b, "Enable", look)
  hooksecurefunc(b, "Disable", look)
  look()
  if onClick then b:SetScript("OnClick", onClick) end
  return b
end

-- a small square pick button (user 2026-11-21: the tab art looks cramped on tiny number buttons): the
-- check_todo steel frame, the label centred (gold; white while hovered or chosen), a blue glow while chosen
-- (LockHighlight / UnlockHighlight, like UI.Button) and a soft glow on hover.
function UI.SquareButton(parent, text, size, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(size); b:SetHeight(size)
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(RTH.TEX .. "check_todo"); bg:SetAllPoints(b)
  local glow = b:CreateTexture(nil, "OVERLAY")   -- select_glow.tga (art round 5): ice frame, open middle
  glow:SetTexture(RTH.TEX .. "select_glow")
  glow:SetPoint("TOPLEFT", b, "TOPLEFT", -4, 4); glow:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 4, -4)
  glow:Hide()
  local hover = b:CreateTexture(nil, "HIGHLIGHT")
  hover:SetTexture(RTH.TEX .. "check_todo"); hover:SetAllPoints(b); hover:SetBlendMode("ADD"); hover:SetAlpha(0.35)
  b.text = UI.Outline(b:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
  b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.text:SetText(text)
  local function look()
    if b.locked then glow:Show(); b.text:SetTextColor(1, 1, 1)
    elseif b.hover then glow:Hide(); b.text:SetTextColor(1, 1, 1)
    else glow:Hide(); b.text:SetTextColor(1, 0.82, 0.2) end
  end
  b:SetScript("OnEnter", function() b.hover = true; look() end)
  b:SetScript("OnLeave", function() b.hover = nil; look() end)
  hooksecurefunc(b, "LockHighlight", function() b.locked = true; look() end)
  hooksecurefunc(b, "UnlockHighlight", function() b.locked = nil; look() end)
  b:SetScript("OnMouseDown", function() b.text:SetPoint("CENTER", b, "CENTER", 1, -1) end)
  b:SetScript("OnMouseUp", function() b.text:SetPoint("CENTER", b, "CENTER", 0, 0) end)
  if onClick then b:SetScript("OnClick", onClick) end
  look()
  return b
end

-- checkboxes wear the addon's own art (check_todo / check_done, as on the Progress tab): Blizzard's dark box
-- all but disappears on the window's dark background
function UI.Check(parent, label, onClick)
  local c = CreateFrame("CheckButton", nil, parent)
  c:SetWidth(24); c:SetHeight(24)
  c:SetNormalTexture(RTH.TEX .. "check_todo")
  c:SetCheckedTexture(RTH.TEX .. "check_done")
  c:SetHighlightTexture(RTH.TEX .. "check_todo", "ADD")
  local dis = c:CreateTexture(nil, "ARTWORK")
  dis:SetTexture(RTH.TEX .. "check_done"); dis:SetAllPoints(c); dis:SetDesaturated(true)
  c:SetDisabledCheckedTexture(dis)
  -- switched off (e.g. gate ticks for non-leaders): dim it, so it doesn't look clickable
  hooksecurefunc(c, "Disable", function() c:SetAlpha(0.45) end)
  hooksecurefunc(c, "Enable", function() c:SetAlpha(1) end)
  c.label = UI.Text(c, nil, { 1, 1, 1 })
  c.label:SetPoint("LEFT", c, "RIGHT", 2, 1)
  c.label:SetText(label)
  if onClick then c:SetScript("OnClick", function(self) onClick(self:GetChecked() and true or false) end) end
  return c
end

-- the "legal" light: green / yellow / red / grey. light_*.tga (64x64) are gems in an ornate socket; below 20px
-- the socket would swallow the gem, so small lights show only the gem (inside the gold ring, 14-50 of 64).
function UI.Light(parent, size, layer)
  size = size or 20
  local t = UI.Texture(parent, "light_grey", size, size, layer)
  if size < 20 then t:SetTexCoord(14 / 64, 50 / 64, 14 / 64, 50 / 64) end
  function t:SetState(state)
    self:SetTexture(RTH.TEX .. "light_" .. (state == "ok" and "green" or state == "check" and "yellow" or state == "bad" and "red" or "grey"))
  end
  return t
end

-- progress bar (art round 2, 2026-11-21): bar_bg is 512x128 with the bar art in rows 26-101 (only those rows are
-- drawn); its dark channel, inside the gold line, runs x 31-481, y 59-84. bar_fill is 512x64 with the energy strip
-- in rows 17-46; it is drawn inside the channel, cropped (never squashed) as it grows. Keep w:h near 6.8:1.
local BAR_W, BAR_H, BAR_Y0, BAR_Y1 = 512, 128, 26, 101
local CH_X0, CH_X1, CH_Y0, CH_Y1 = 31, 481, 59, 84
local FILL_H, FILL_Y0, FILL_Y1 = 64, 17, 46
function UI.Bar(parent, w, h)
  local f = CreateFrame("Frame", nil, parent)
  f:SetWidth(w); f:SetHeight(h)
  local bg = UI.Texture(f, "bar_bg", w, h, "BACKGROUND")
  bg:SetAllPoints(f)
  bg:SetTexCoord(0, 1, BAR_Y0 / BAR_H, BAR_Y1 / BAR_H)
  local sx, sy = w / BAR_W, h / (BAR_Y1 - BAR_Y0)          -- frame px per texture px
  local chW = (CH_X1 - CH_X0) * sx
  f.fill = UI.Texture(f, "bar_fill", chW, (CH_Y1 - CH_Y0) * sy, "ARTWORK")
  f.fill:SetPoint("TOPLEFT", f, "TOPLEFT", CH_X0 * sx, -(CH_Y0 - BAR_Y0) * sy)
  f.text = UI.Text(f, "small", { 1, 1, 1 }, "CENTER")
  f.text:SetPoint("CENTER", f.fill, "LEFT", chW / 2, 0)   -- centred on the channel, not on the crystal-topped frame
  function f:SetValue(done, total)
    local pct = total > 0 and math.min(1, done / total) or 0
    if pct <= 0 then self.fill:Hide() else
      self.fill:Show()
      self.fill:SetWidth(chW * pct)
      self.fill:SetTexCoord(0, pct, FILL_Y0 / FILL_H, FILL_Y1 / FILL_H)
    end
    self.text:SetText(done .. " / " .. total)
  end
  return f
end

-- simple tooltip on any frame
function UI.Tip(frame, fn)   -- HookScript: keeps a button's own hover look (UI.Button) working
  frame:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    fn(GameTooltip, self)
    GameTooltip:Show()
  end)
  frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- 3.3.5 has no Region:SetShown
function UI.Shown(obj, show)
  if show then obj:Show() else obj:Hide() end
end

-- A boxed section behind a group of content (user 2026-11-21, like their raid-management addon): darker fill,
-- thin gold border, a small gold stud on each corner. Offsets are from frame's TOPLEFT (left, top) and
-- BOTTOMRIGHT (right, bottom); bottom = nil gives a box `height` tall instead; top = nil a box `height` tall
-- whose bottom is `bottom` up from the frame's bottom. opts: { tint = { r, g, b } (coloured fill),
-- band = N (a darker title band over the box's top N px - behind its existing header row - with a gold underline) }. box:Place(...) moves it later
-- (same arguments), for sections whose size depends on the content.
-- Drawn in BACKGROUND/BORDER on the tab's own frame, so it sits under that tab's text.
local function placeSection(box, left, top, right, bottom, height)
  local fill, frame = box.fill, box.frame
  fill:ClearAllPoints()
  if not top then   -- measured from the bottom: `height` tall, its bottom `bottom` up from frame's bottom
    fill:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", left, bottom)
    fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", right, bottom)
    fill:SetHeight(height)
    return
  end
  fill:SetPoint("TOPLEFT", frame, "TOPLEFT", left, top)
  if bottom then fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", right, bottom)
  else fill:SetPoint("TOPRIGHT", frame, "TOPRIGHT", right, top); fill:SetHeight(height) end
end
function UI.Section(frame, left, top, right, bottom, height, opts)
  opts = opts or {}
  local box = { frame = frame, Place = placeSection }
  local fill = frame:CreateTexture(nil, "BACKGROUND")
  local tint = opts.tint
  if tint then fill:SetTexture(tint[1], tint[2], tint[3], 0.22) else fill:SetTexture(0, 0, 0, 0.38) end
  box.fill = fill
  local g = UI.GOLD
  if opts.band then
    -- title band (art round 4): only the frosted-steel rows 12-41 of band.tga, darkened so its bright frost streaks
    -- stay behind the title text (user screenshots 2026-11-21: full brightness fought the text); its own thick gold
    -- line (rows 42-51) is left out - squashed to 20-34px it came out 3-4px - and a crisp 1px gold line is drawn
    local band = frame:CreateTexture(nil, "BORDER")
    band:SetTexture(RTH.TEX .. "band")
    band:SetTexCoord(0, 1, 12 / 64, 41 / 64)
    band:SetVertexColor(0.55, 0.6, 0.66)
    band:SetPoint("TOPLEFT", fill, "TOPLEFT", 1, -1); band:SetPoint("TOPRIGHT", fill, "TOPRIGHT", -1, -1)
    band:SetHeight(opts.band - 1)
    local line = frame:CreateTexture(nil, "BORDER")
    line:SetTexture(g[1], g[2], g[3], 0.6)
    line:SetPoint("TOPLEFT", band, "BOTTOMLEFT"); line:SetPoint("TOPRIGHT", band, "BOTTOMRIGHT")
    line:SetHeight(1)
    box.band = band
  end
  for _, side in ipairs({ { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
                         { "TOPLEFT", "BOTTOMLEFT", false }, { "TOPRIGHT", "BOTTOMRIGHT", false } }) do
    local e = frame:CreateTexture(nil, "BORDER")
    e:SetTexture(g[1], g[2], g[3], 0.45)
    e:SetPoint(side[1], fill, side[1]); e:SetPoint(side[2], fill, side[2])
    if side[3] then e:SetHeight(1) else e:SetWidth(1) end
  end
  for _, corner in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
    -- gem stud (stud.tga, art round 4) on each corner; ARTWORK so it is always drawn over the border lines and band
    local stud = frame:CreateTexture(nil, "ARTWORK")
    stud:SetTexture(RTH.TEX .. "stud")
    stud:SetWidth(9); stud:SetHeight(9)
    stud:SetPoint("CENTER", fill, corner)
  end
  box:Place(left, top, right, bottom, height)
  return box
end

-- list rows (user 2026-11-21: easier to follow long lists): a faint stripe on every other row and a soft glow on
-- the row under the mouse. index = the row's position in the list (stripe on even rows); 0 = no stripe.
function UI.RowLook(r, index)
  if index and index > 0 and index % 2 == 0 then   -- index 0 = no stripe (0 % 2 == 0 striped every such row)
    local s = r:CreateTexture(nil, "BACKGROUND")
    s:SetTexture(1, 1, 1, 0.035)
    s:SetAllPoints(r)
  end
  local hl = r:CreateTexture(nil, "BACKGROUND")
  hl:SetTexture(RTH.TEX .. "row_glow")   -- art round 5: soft ice-blue bar (rows 3-60 of 64)
  hl:SetTexCoord(0, 1, 3 / 64, 60 / 64)
  hl:SetBlendMode("ADD")
  hl:SetAlpha(0.3)   -- soft: the art has a bright core streak (0.6 was "too much" in game)
  hl:SetAllPoints(r)
  hl:Hide()
  r:EnableMouse(true)
  r:HookScript("OnEnter", function() hl:Show() end)
  r:HookScript("OnLeave", function() hl:Hide() end)
  r.hl = hl
end

-- a small class icon; obj:SetClass(classFile or nil) shows / hides it.
-- NOT the class sheet (Glues\CharacterCreate\UI-CharacterCreate-Classes + CLASS_ICON_TCOORDS): HD clients replace
-- that sheet with a different layout, so the cut-outs showed the wrong pictures (user screenshot 2026-11-21).
-- One signature icon per class instead: separate files an HD pack can only sharpen, never rearrange.
-- (All names checked against the 3.3.5 client's icon tables.)
local CLASS_ICONS = {
  WARRIOR = "INV_Sword_27", PALADIN = "Spell_Holy_HolyBolt", HUNTER = "INV_Weapon_Bow_07",
  ROGUE = "INV_ThrowingKnife_04", PRIEST = "Spell_Holy_PowerWordShield", DEATHKNIGHT = "Spell_Deathknight_ClassIcon",
  SHAMAN = "Spell_Nature_BloodLust", MAGE = "Spell_Frost_FrostBolt02", WARLOCK = "Spell_Shadow_DeathCoil",
  DRUID = "Ability_Druid_CatForm",
}
function UI.ClassIcon(parent, size)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetWidth(size); t:SetHeight(size)
  t:SetTexCoord(0.08, 0.92, 0.08, 0.92)   -- trim the icons' built-in border
  function t:SetClass(class)
    local icon = class and CLASS_ICONS[class]
    if icon then self:SetTexture("Interface\\Icons\\" .. icon); self:Show() else self:Hide() end
  end
  t:Hide()
  return t
end

-- RTH's own look for an InputBoxTemplate edit box (user 2026-11-21: the search box was hard to see): the
-- template's dark Common-Input-Border pieces ($parentLeft/Middle/Right) are hidden; a lighter blue-grey fill and a
-- gold 1px border take their place, the border brighter while you type. icon = optional texture at the left.
function UI.StyleInput(edit, icon)
  local name = edit:GetName()
  for _, part in ipairs({ "Left", "Middle", "Right" }) do
    local t = name and _G[name .. part]
    if t then t:Hide() end
  end
  -- art round 5: input_frame.tga (512x64, art rows 7-57, gem ends ~22px), cut in 3; brighter while typing
  -- anchored to the box's top and bottom (styled before the caller sets its height, so no GetHeight here);
  -- the ends are 11px - the gem ends at the ~26px these boxes come out
  local pieces, x0, cap = {}, 22 / 512, 11
  for i, part in ipairs({ { 0, x0 }, { x0, 1 - x0 }, { 1 - x0, 1 } }) do
    local t = edit:CreateTexture(nil, "BACKGROUND")
    t:SetTexture(RTH.TEX .. "input_frame"); t:SetTexCoord(part[1], part[2], 7 / 64, 57 / 64)
    pieces[i] = t
  end
  pieces[1]:SetWidth(cap); pieces[1]:SetPoint("TOPLEFT", edit, "TOPLEFT", -6, 3); pieces[1]:SetPoint("BOTTOMLEFT", edit, "BOTTOMLEFT", -6, -3)
  pieces[3]:SetWidth(cap); pieces[3]:SetPoint("TOPRIGHT", edit, "TOPRIGHT", 4, 3); pieces[3]:SetPoint("BOTTOMRIGHT", edit, "BOTTOMRIGHT", 4, -3)
  pieces[2]:SetPoint("TOPLEFT", pieces[1], "TOPRIGHT"); pieces[2]:SetPoint("BOTTOMRIGHT", pieces[3], "BOTTOMLEFT")
  local function bright(v) for _, t in ipairs(pieces) do t:SetVertexColor(v, v, v) end end
  bright(0.85)
  edit:HookScript("OnEditFocusGained", function() bright(1.1) end)
  edit:HookScript("OnEditFocusLost", function() bright(0.85) end)
  local fill = pieces[1]   -- the icon is placed from the left piece
  local inset = 2
  if icon then
    local i = edit:CreateTexture(nil, "ARTWORK")
    i:SetTexture(icon)
    i:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    i:SetWidth(14); i:SetHeight(14)
    i:SetPoint("LEFT", fill, "LEFT", 6, 0)
    inset = 18
  end
  edit:SetTextInsets(inset, 4, 0, 0)
  return edit
end

-- RTH's scroll bar look (art round 4, 2026-11-21) for a UIPanelScrollFrameTemplate / FauxScrollFrameTemplate frame:
-- its parts are <name>ScrollBar, ...ScrollUpButton, ...ScrollDownButton, ...ThumbTexture (3.3.5 UIPanelTemplates.xml).
-- The template crops its button art to 0.2-0.8 (UIPanelScrollBarButton), so every texture is re-cropped to the
-- whole file. scroll_thumb's art fills x 8-56 of 64; scroll_track's rows 64-447 of 512.
local function skinScrollButton(btn, file)
  if not btn then return end
  btn:SetWidth(16); btn:SetHeight(16)
  btn:SetNormalTexture(RTH.TEX .. file); btn:SetPushedTexture(RTH.TEX .. file)
  btn:SetDisabledTexture(RTH.TEX .. file); btn:SetHighlightTexture(RTH.TEX .. file, "ADD")
  local n, p, d, h = btn:GetNormalTexture(), btn:GetPushedTexture(), btn:GetDisabledTexture(), btn:GetHighlightTexture()
  for _, t in ipairs({ n or false, p or false, d or false, h or false }) do
    if t then t:SetTexCoord(0, 1, 0, 1) end
  end
  if p then p:SetVertexColor(0.75, 0.75, 0.75) end             -- pressed: a little darker
  if d then d:SetDesaturated(true); d:SetAlpha(0.45) end        -- at the end of the list: grey
  if h then h:SetAlpha(0.35) end
end
function UI.StyleScroll(sf)
  local bar = sf and sf:GetName() and _G[sf:GetName() .. "ScrollBar"]
  if not bar then return sf end   -- always hand the frame back: callers write sf = UI.StyleScroll(CreateFrame(...))
  local up, down = _G[bar:GetName() .. "ScrollUpButton"], _G[bar:GetName() .. "ScrollDownButton"]
  skinScrollButton(up, "scroll_up"); skinScrollButton(down, "scroll_down")
  local thumb = _G[bar:GetName() .. "ThumbTexture"] or bar:GetThumbTexture()
  if thumb then
    thumb:SetTexture(RTH.TEX .. "scroll_thumb")
    thumb:SetTexCoord(8 / 64, 56 / 64, 0, 1)
    thumb:SetWidth(12); thumb:SetHeight(32)
  end
  if up and down then
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(RTH.TEX .. "scroll_track")
    track:SetTexCoord(0, 1, 64 / 512, 447 / 512)
    track:SetWidth(8)
    track:SetPoint("TOP", up, "BOTTOM", 0, 2); track:SetPoint("BOTTOM", down, "TOP", 0, -2)
  end
  return sf
end

-- a 9-piece frame from a square texture (art round 5: the pop-up menu): size = texture px, ctex = corner in
-- texture px, cpx = corner on screen. The art's middle is opaque, so it is the background too.
function UI.Frame9(frame, file, size, ctex, cpx)
  local c, tex = ctex / size, RTH.TEX .. file
  local function piece(l, r, t, b) local x = frame:CreateTexture(nil, "BACKGROUND"); x:SetTexture(tex); x:SetTexCoord(l, r, t, b); return x end
  local tl, tr, bl, br = piece(0, c, 0, c), piece(1 - c, 1, 0, c), piece(0, c, 1 - c, 1), piece(1 - c, 1, 1 - c, 1)
  for _, x in ipairs({ tl, tr, bl, br }) do x:SetWidth(cpx); x:SetHeight(cpx) end
  tl:SetPoint("TOPLEFT", frame, "TOPLEFT"); tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
  bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT"); br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
  local top, bottom = piece(c, 1 - c, 0, c), piece(c, 1 - c, 1 - c, 1)
  top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("BOTTOMRIGHT", tr, "BOTTOMLEFT")
  bottom:SetPoint("TOPLEFT", bl, "TOPRIGHT"); bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
  local left, right = piece(0, c, c, 1 - c), piece(1 - c, 1, c, 1 - c)
  left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMRIGHT", bl, "TOPRIGHT")
  right:SetPoint("TOPLEFT", tr, "BOTTOMLEFT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
  local mid = piece(c, 1 - c, c, 1 - c)
  mid:SetPoint("TOPLEFT", tl, "BOTTOMRIGHT"); mid:SetPoint("BOTTOMRIGHT", br, "TOPLEFT")
end

-- a faint emblem behind an "empty list" message (art round 5): shown and hidden together with the text
function UI.EmptyEmblem(fs, parent, size)
  local e = parent:CreateTexture(nil, "BACKGROUND")
  e:SetTexture(RTH.TEX .. "emblem")
  e:SetWidth(size or 190); e:SetHeight(size or 190)
  e:SetPoint("CENTER", fs, "CENTER", 0, 0)
  e:SetAlpha(0.14)
  hooksecurefunc(fs, "Show", function() e:Show() end)
  hooksecurefunc(fs, "Hide", function() e:Hide() end)
  return e
end

function UI.Separator(parent, w)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetTexture(1, 1, 1, 0.12)
  t:SetHeight(1); t:SetWidth(w)
  return t
end

-- RTH's own small pop-up menu. Blizzard's UIDropDownMenu is avoided on purpose: in 3.3.5 an addon that uses
-- it can leave the shared menu state tainted, and later "Set Focus" etc. from a unit menu gets blocked.
-- items: { text =, title = true, disabled = true, checked = true, func = }; anchor: a frame, or nil = cursor.
-- Closes on a pick, on Escape, or on a click anywhere else.
local menu
local MENU_ROW, MENU_PAD = 16, 10
local function menuRow(i)
  local r = menu.rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, menu)
  r:SetHeight(MENU_ROW)
  r:SetPoint("TOPLEFT", menu, "TOPLEFT", MENU_PAD, -MENU_PAD - (i - 1) * MENU_ROW)
  r:SetPoint("RIGHT", menu, "RIGHT", -MENU_PAD, 0)
  r:SetHighlightTexture(RTH.TEX .. "row_glow", "ADD")   -- art round 5
  local rh = r:GetHighlightTexture()
  if rh then rh:SetAlpha(0.3) end   -- as soft as the list rows
  r.check = r:CreateTexture(nil, "ARTWORK")
  r.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  r.check:SetWidth(14); r.check:SetHeight(14)
  r.check:SetPoint("LEFT", r, "LEFT", 0, 0)
  r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.text:SetPoint("LEFT", r, "LEFT", 16, 0)
  r.text:SetJustifyH("LEFT")
  r:SetScript("OnClick", function(self)
    local fn = self.func
    menu:Hide()
    if fn then fn() end
  end)
  menu.rows[i] = r
  return r
end
function UI.Menu(items, anchor)
  if not menu then
    menu = CreateFrame("Frame", "RTHMenu", UIParent)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetClampedToScreen(true)
    menu:EnableMouse(true)
    UI.Frame9(menu, "menu_frame", 128, 12, 10)   -- art round 5: RTH's own small frame (was the tooltip border)
    menu.rows = {}
    menu:SetScript("OnUpdate", function(self)
      if self.anchor and not self.anchor:IsVisible() then self:Hide(); return end   -- its button went away
      if (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")) and not MouseIsOver(self)
        and not (self.anchor and MouseIsOver(self.anchor)) then self:Hide() end   -- the anchor's own click toggles
    end)
    table.insert(UISpecialFrames, "RTHMenu")   -- Escape closes it
  end
  if menu:IsShown() and anchor and menu.anchor == anchor then menu:Hide(); return end   -- second click closes
  menu:Hide()
  menu.anchor = anchor
  local width = 60
  for i, it in ipairs(items) do
    local r = menuRow(i)
    r.text:SetText(it.text or "")
    r.func = (not it.title and not it.disabled) and it.func or nil
    if it.title then r.text:SetFontObject(GameFontNormalSmall)
    elseif it.disabled then r.text:SetFontObject(GameFontDisableSmall)
    else r.text:SetFontObject(GameFontHighlightSmall) end
    UI.Outline(r.text)
    if it.title or it.disabled then r:Disable() else r:Enable() end
    UI.Shown(r.check, it.checked)
    r:Show()
    width = math.max(width, (r.text:GetStringWidth() or 0) + 16)
  end
  for i = #items + 1, #menu.rows do menu.rows[i]:Hide() end
  menu:SetWidth(width + 2 * MENU_PAD)
  menu:SetHeight(#items * MENU_ROW + 2 * MENU_PAD)
  menu:ClearAllPoints()
  if anchor then
    menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
  else
    local x, y = GetCursorPosition()
    local s = UIParent:GetEffectiveScale()
    menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s - 8, y / s + 8)
  end
  menu:Show()
end
