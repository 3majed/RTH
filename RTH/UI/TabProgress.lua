-- Road to Halion: Progress tab
--   NEXT line  ->  unlock gate as a checklist  ->  bosses grouped by raid and wing, one box per boss
--   (a small skull on a box = that boss's hard mode; hover a box for kills, wipes and the hard mode)
local RTH = RTH
local UI = RTH.UI

local GATE_ROWS = 6
local RAID_ROWS = 12
local BOXES = 5
local BOX_STEP = 38   -- 18px box + 2 + 15px hard mode skull + 3px gap; the last skull ends at x 399 of 452
local viewed   -- phase shown (defaults to the current one)

-- phase1-5.tga (art round 3, 2026-11-21): 128x128, all five share one frame and were cropped with one box, so
-- each fills its file and they line up as they are - no per-icon crop any more.

-- raids and wings per phase, in the order they are usually done (boss names as in Data\Progress.lua)
local LAYOUT = {
  [1] = {
    { title = "Naxxramas", wings = {
      { "Arachnid Quarter", { "Anub'Rekhan", "Grand Widow Faerlina", "Maexxna" } },
      { "Plague Quarter", { "Noth the Plaguebringer", "Heigan the Unclean", "Loatheb" } },
      { "Military Quarter", { "Instructor Razuvious", "Gothik the Harvester", "Four Horsemen" } },
      { "Construct Quarter", { "Patchwerk", "Grobbulus", "Gluth", "Thaddius" } },
      { "Frostwyrm Lair", { "Sapphiron", "Kel'Thuzad" } } } },
    { title = "Eye of Eternity", bosses = { "Malygos" } },
    { title = "Obsidian Sanctum", bosses = { "Sartharion" } },
  },
  [2] = {
    { title = "Ulduar", wings = {
      { "The Siege", { "Flame Leviathan", "Ignis the Furnace Master", "Razorscale", "XT-002 Deconstructor" } },
      { "The Antechamber", { "Assembly of Iron", "Kologarn", "Auriaya" } },
      { "The Keepers", { "Hodir", "Thorim", "Freya", "Mimiron" } },
      { "The Descent", { "General Vezax", "Yogg-Saron" } },
      { "Celestial Planetarium", { "Algalon the Observer" } } } },
  },
  [3] = {
    { title = "Trial of the Grand Crusader", bosses = { "Beasts of Northrend", "Lord Jaraxxus", "Faction Champions", "Val'kyr Twins", "Anub'arak" } },
  },
  [4] = {
    { title = "Icecrown Citadel", wings = {
      { "The Lower Spire", { "Lord Marrowgar", "Lady Deathwhisper", "Gunship Battle", "Deathbringer Saurfang" } },
      { "The Plagueworks", { "Festergut", "Rotface", "Professor Putricide" } },
      { "The Crimson Hall", { "Blood Prince Council", "Blood-Queen Lana'thel" } },
      { "Frostwing Halls", { "Valithria Dreamwalker", "Sindragosa" } },
      { "The Frozen Throne", { "The Lich King" } } } },
  },
  [5] = {
    { title = "The Ruby Sanctum", bosses = { "Halion" } },
  },
}
RTH.PROGRESS_LAYOUT = LAYOUT

-- Phase 1's "hard mode" is 3 drakes on Sartharion; Ulduar's come from the data file
local EXTRA_HM = { [1] = { ["Sartharion"] = 2051 } }
local function hardModeOf(p, bossName)
  if EXTRA_HM[p] and EXTRA_HM[p][bossName] then return EXTRA_HM[p][bossName] end
  for _, hm in ipairs(RTH_Phases[p].hardmodes or {}) do
    if hm.boss == bossName then return hm.achievement end
  end
end

-- boss name -> key ("p:i") and data row, for a phase
local function keyOf(p, bossName)
  for i, b in ipairs(RTH_Phases[p].bosses) do
    if b.name == bossName then return p .. ":" .. i, b end
  end
end

-- killed on the difficulty that counts (heroic where the phase has heroic statistics)
local function bossState(p, bossName)
  local key, b = keyOf(p, bossName)
  if not key then return false, 0, 0, nil end
  local kN = RTH.BossKills(key, false)
  local kH = b.statH and RTH.BossKills(key, true) or 0
  local done = (b.statH and kH > 0) or (not b.statH and kN > 0) or false
  return done, kN, kH, key, b
end

local function wipesOf(key)
  local w = RTH.db.group.wipes
  return (w[key] or 0) + (w[key .. "H"] or 0)
end

local function shortGate(label)
  return (label:gsub(" %(10 player%)", ""):gsub(" %(Vault of Archavon%)", " (VoA)"))
end

-- ---------------------------------------------------------------- build
local function makeBox(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(18); b:SetHeight(18)
  b.check = UI.Texture(b, "check_todo", 18, 18)
  b.check:SetAllPoints(b)
  b.skull = UI.Texture(b, "hardmode_off", 15, 15, "OVERLAY")   -- framed skull: unreadable below ~15px
  b.skull:SetTexCoord(15 / 64, 49 / 64, 15 / 64, 49 / 64)   -- only the skull inside the gold ring: the full badge
                                                          -- (ring + ornaments) left a dot-sized skull at 15px
  b.skull:SetPoint("LEFT", b, "RIGHT", 2, 0)   -- beside the box, never over it or the row above (BOX_STEP leaves room)
  UI.Tip(b, function(tt, self)
    if self.tipText then tt:AddLine(self.tipText, 1, 0.85, 0.4); return end
    local p, name = self.phase, self.boss
    if not name then return end
    local done, kN, kH, key, data = bossState(p, name)
    tt:AddLine(name, 1, 0.85, 0.4)
    if data and data.statH then
      tt:AddLine("Heroic kills: " .. kH .. "   Normal kills: " .. kN, 1, 1, 1)
      if not done then tt:AddLine("Needs a HEROIC kill", 1, 0.5, 0.3) end
    else
      tt:AddLine("Kills: " .. kN, 1, 1, 1)
    end
    local w = key and wipesOf(key) or 0
    if w > 0 then tt:AddLine("Wipes since the last kill: " .. w, 0.8, 0.8, 0.8) end
    local hm = hardModeOf(p, name)
    if hm then
      local _, hmName = GetAchievementInfo(hm)
      tt:AddLine("Hard mode: " .. (hmName or "?") .. (RTH.AchDone(hm) and "  |cff40ff40done|r" or "  |cffff6060todo|r"), 0.9, 0.9, 0.9)
    end
  end)
  return b
end

local function build(f)
  local cw = UI.CONTENT_W
  -- boxed sections (UI.Section): phase icons; next step + gate + guild line; raids. The last two follow the
  -- gate list's length, so refresh() places them.
  f.secIcons = UI.Section(f, -4, 8, 4, nil, 82)   -- starts 8px up: the chosen icon's glow reaches 6px above it
  f.secGate = UI.Section(f, -4, -78, 4, nil, 100, { band = 20 })   -- band: behind the NEXT line
  f.secRaids = UI.Section(f, -4, -182, 4, -4, nil, { band = 26 })   -- band: behind the first raid's header row

  -- phase icons
  f.phaseButtons = {}
  -- 12px in from each side: the labels under the end icons ("Ruby Sanctum") are wider than the icons
  local size, side = 56, 12
  local gap = (cw - 2 * side - 5 * size) / 4
  for p = 1, RTH.MAX_PHASE do
    local b = CreateFrame("Button", nil, f)
    b:SetWidth(size); b:SetHeight(size)
    b:SetPoint("TOPLEFT", f, "TOPLEFT", side + (p - 1) * (size + gap), -2)
    b.icon = UI.Texture(b, "phase" .. p, size, size)
    b.icon:SetAllPoints(b)
    b.lock = UI.Texture(b, "lock", 22, 22, "OVERLAY")
    b.lock:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, -2)
    b.done = UI.Texture(b, "check_done", 22, 22, "OVERLAY")
    b.done:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, -2)
    b.label = UI.Text(b, "small", nil, "CENTER")
    b.label:SetPoint("TOP", b, "BOTTOM", 0, -2)
    b.label:SetText(RTH.PHASE_NAMES[p])
    b.sel = b:CreateTexture(nil, "OVERLAY")   -- art round 5: select_glow.tga, an ice frame around the chosen phase
    b.sel:SetTexture(RTH.TEX .. "select_glow")
    b.sel:SetPoint("TOPLEFT", b, "TOPLEFT", -6, 6); b.sel:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 6, -6)
    b:SetScript("OnClick", function() viewed = p; UI.RefreshCurrent() end)
    UI.Tip(b, function(tt)
      tt:AddLine(RTH.PhaseLabel(p) .. " - patch " .. RTH.PHASE_PATCH[p], 1, 0.85, 0.4)
      if p > RTH.MyPhase() then tt:AddLine("Locked for you - finish the gate before it. Click to see what is in it.", 0.8, 0.8, 0.8, true)
      elseif p > 1 and RTH.char.passed[p - 1] then tt:AddLine("Opened for you " .. RTH.char.passed[p - 1].d, 0.8, 0.8, 0.8) end
      if RTH.db.group.phaseLog[p] and p <= RTH.GetPhase() and p > 1 then
        tt:AddLine("First reached in the guild " .. RTH.db.group.phaseLog[p], 0.72, 0.72, 0.72)
      end
    end)
    f.phaseButtons[p] = b
  end

  -- NEXT line
  f.next = UI.Text(f, nil, { 1, 1, 1 })
  f.next:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -82)
  f.next:SetWidth(cw)

  -- gate: title + bar + checklist
  f.gateTitle = UI.Text(f, nil, UI.GOLD)
  f.gateTitle:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -106)
  f.bar = UI.Bar(f, 178, 26)   -- the bar art's shape (6.8:1); its channel is a third of the height
  f.bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -98)   -- ends at -124, where the gate rows start
  f.gateRows = {}
  for i = 1, GATE_ROWS do
    local r = CreateFrame("Frame", nil, f)
    r:SetWidth(cw); r:SetHeight(16)
    r:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -124 - (i - 1) * 16)
    r.check = UI.Texture(r, "check_todo", 14, 14)
    r.check:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.text = UI.Text(r, "small", { 1, 1, 1 })
    r.text:SetPoint("LEFT", r.check, "RIGHT", 6, 0)
    r.text:SetWidth(cw - 30); r.text:SetHeight(14)   -- one line per gate item
    -- hover: why an achievement the game shows as earned doesn't count (strict gate: clean guild runs only)
    r:EnableMouse(true)
    UI.Tip(r, function(tt, self)
      if not self.item then return end
      tt:AddLine(self.item.label, 1, 0.85, 0.4)
      if self.item.done then tt:AddLine("Counts: earned in a clean guild run", 0.4, 0.9, 0.4)
      elseif self.item.why then
        tt:AddLine("Earned, but it doesn't count:", 1, 0.4, 0.4)
        tt:AddLine(self.item.why, 1, 1, 1, true)
        tt:AddLine("Only the guild master can pass this gate by hand now (/rth gate).", 0.7, 0.7, 0.7, true)
      else tt:AddLine("Not earned yet - it counts when earned at a boss kill RTH logs with no marks", 0.8, 0.8, 0.8, true) end
    end)
    f.gateRows[i] = r
  end
  -- who has finished the viewed gate (1.4.0: each character opens its own next phase; nobody unlocks for the guild)
  f.groupGate = UI.Text(f, "small", { 0.85, 0.85, 0.85 })
  f.groupGate:SetWidth(cw)
  f.sep = UI.Separator(f, cw)
  f.sep:Hide()   -- the boxes separate the parts now

  -- raid / wing rows
  f.raidRows = {}
  for i = 1, RAID_ROWS do
    local r = CreateFrame("Frame", nil, f)
    r:SetWidth(cw); r:SetHeight(20)
    UI.RowLook(r, i)   -- rows are laid out top to bottom in order: stripe every other one + hover glow
    r.title = UI.Text(r, nil, { 1, 1, 1 })
    r.title:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.title:SetWidth(205); r.title:SetHeight(14)
    r.boxes = {}
    for j = 1, BOXES do
      local b = makeBox(r)
      b:SetPoint("LEFT", r, "LEFT", 212 + (j - 1) * BOX_STEP, 0)
      r.boxes[j] = b
    end
    r.count = UI.Text(r, "small", { 0.85, 0.85, 0.85 }, "RIGHT")
    r.count:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    f.raidRows[i] = r
  end
end

-- ---------------------------------------------------------------- refresh
local function fillBoxes(r, p, names)
  local done = 0
  for j = 1, BOXES do
    local b = r.boxes[j]
    local name = names[j]
    b.tipText = nil
    if name then
      local d = bossState(p, name)
      if d then done = done + 1 end
      b.phase, b.boss = p, name
      b.check:SetTexture(RTH.TEX .. (d and "stamp_killed" or "check_todo"))   -- killed: the wax seal (art round 5)
      local hm = hardModeOf(p, name)
      if hm then
        b.skull:SetTexture(RTH.TEX .. (RTH.AchDone(hm) and "hardmode_on" or "hardmode_off"))
        b.skull:Show()
      else
        b.skull:Hide()
      end
      b:Show()
    else
      b.boss = nil
      b:Hide()
    end
  end
  return done, #names
end

local function nextStep(p)
  if p > RTH.MyPhase() then
    return "|cffff6060Locked for you|r - finish the gate of " .. RTH.PhaseLabel(RTH.MyPhase()) .. " first"
  end
  -- every boss on normal first, then the heroic kills: the game opens heroic only after a normal clear
  -- (Icecrown after the Lich King, Trial of the Grand Crusader after the Trial), so "Kill Marrowgar on heroic"
  -- as a new phase's first step would be impossible. The boxes still need the heroic kill.
  for _, heroicPass in ipairs({ false, true }) do
    for _, raid in ipairs(LAYOUT[p]) do
      for _, wing in ipairs(raid.wings or { { raid.title, raid.bosses } }) do
        for _, name in ipairs(wing[2]) do
          local done, kN, _, key, data = bossState(p, name)
          local needHeroic = data and data.statH
          -- normal pass: anything not done that has no normal kill yet; heroic pass: anything still not done
          local todo = not done and (heroicPass or not needHeroic or kN == 0)
          if todo then
            local w = key and wipesOf(key) or 0
            return "|cffd9a441NEXT:|r Kill " .. name .. ((needHeroic and heroicPass) and " on heroic" or "")
              .. " |cffb8b8b8(" .. wing[1] .. ")" .. (w > 0 and (" - " .. w .. " wipes so far") or "") .. "|r"
          end
        end
      end
    end
  end
  for _, it in ipairs(RTH.GateItems(p)) do
    if not it.done then return "|cffd9a441NEXT:|r " .. shortGate(it.label) end
  end
  if p == RTH.MAX_PHASE then return "|cff40ff40The road is done. Halion has fallen!|r" end
  if p < RTH.MyPhase() then return "|cff40ff40Gate done - " .. RTH.PhaseLabel(p + 1) .. " is open for you|r" end
  return "|cff40ff40All done here|r - " .. RTH.PhaseLabel(p + 1) .. " opens for you in a moment"
end

local function countColor(fs, d, n)
  if d == n then fs:SetTextColor(0.4, 0.9, 0.4) else fs:SetTextColor(0.85, 0.85, 0.85) end
end

local function refresh(f)
  local cur = RTH.MyPhase()   -- yours: each character opens its own phases (1.4.0)
  viewed = viewed or cur
  if viewed > RTH.MAX_PHASE then viewed = cur end
  for p, b in ipairs(f.phaseButtons) do
    UI.Shown(b.lock, p > cur)
    UI.Shown(b.done, p < cur)
    b.icon:SetDesaturated(p > cur)
    b.icon:SetAlpha(p > cur and 0.6 or 1)
    UI.Shown(b.sel, p == viewed)
    b.label:SetTextColor(p == cur and 1 or 0.7, p == cur and 0.85 or 0.7, p == cur and 0.4 or 0.7)
  end

  f.next:SetText(nextStep(viewed))

  -- gate checklist
  local items = RTH.GateItems(viewed)
  local done = 0
  for _, it in ipairs(items) do if it.done then done = done + 1 end end
  f.gateTitle:SetText(viewed < RTH.MAX_PHASE and ("TO OPEN " .. RTH.PHASE_NAMES[viewed + 1]:upper()) or "FINAL GOAL")
  f.bar:SetValue(done, #items)
  local shown = math.min(#items, GATE_ROWS)
  for i = 1, GATE_ROWS do
    local r, it = f.gateRows[i], items[i]
    if it and i <= shown then
      r:Show()
      r.check:SetTexture(RTH.TEX .. (it.done and "check_done" or "check_todo"))
      local label = shortGate(it.label)
      if i == GATE_ROWS and #items > GATE_ROWS then label = label .. "  |cffb8b8b8(+" .. (#items - GATE_ROWS) .. " more)|r" end
      if it.why then label = label .. "  |cffff6060(doesn't count - hover)|r" end
      r.text:SetText(label)
      r.text:SetTextColor(it.done and 0.5 or 1, it.done and 0.9 or 1, it.done and 0.5 or 1)
      r.item = it
    else
      r.item = nil
      r:Hide()
    end
  end
  local y = -124 - shown * 16 - 6

  -- group line: who has finished the viewed gate (in a raid: only the raid's people)
  if viewed < RTH.MAX_PHASE then
    local parts, ready = {}, 0
    local list, grouped = RTH.GroupGateStatus(viewed)
    -- the whole guild is in it: past 10 people, name only who still needs the gate (max 10), so the line stays short
    local long = #list > 10
    local hidden = 0
    for _, st in ipairs(list) do
      local state
      if st.done then state = "|cff40ff40done|r"; ready = ready + 1
      elseif not st.known then state = "|cffb8b8b8?|r"
      elseif st.phase then state = "|cffb8b8b8on " .. RTH.PHASE_NAMES[st.phase] .. "|r"
      else state = "|cffffd040" .. st.have .. "/" .. st.need .. "|r" end
      if long and (st.done or #parts >= 10) then
        if not st.done then hidden = hidden + 1 end
      else
        parts[#parts + 1] = RTH.ClassColorName(st.name) .. " " .. state
      end
    end
    if hidden > 0 then parts[#parts + 1] = "|cffb8b8b8+" .. hidden .. " more not done|r" end
    if long and not parts[1] then parts[1] = "|cff40ff40everyone done|r" end
    f.groupGate:ClearAllPoints()
    f.groupGate:SetPoint("TOPLEFT", f, "TOPLEFT", 0, y - 4)
    f.groupGate:SetText("|cffd9a441" .. (grouped and "Your raid " or "Guild ") .. ready .. "/" .. #list .. ":|r  " .. table.concat(parts, ",  "))
    f.groupGate:Show()
    y = y - math.max(24, math.ceil(f.groupGate:GetStringHeight() or 12) + 8) - 4
  else
    f.groupGate:Hide()
  end

  f.sep:ClearAllPoints()
  f.sep:SetPoint("TOPLEFT", f, "TOPLEFT", 0, y)
  f.secGate:Place(-4, -78, 4, nil, -78 - y - 2)   -- ends 2px above where the raid box starts
  f.secRaids:Place(-4, y - 2, 4, -4)
  y = y - 8

  -- raids and wings
  local row = 0
  local function nextRow()
    row = row + 1
    local r = f.raidRows[row]
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", f, "TOPLEFT", 0, y - (row - 1) * 20)
    r:Show()
    return r
  end
  for _, raid in ipairs(LAYOUT[viewed]) do
    if raid.wings then
      local header = nextRow()
      fillBoxes(header, viewed, {})
      header.title:SetText(raid.title:upper())
      header.title:SetTextColor(UI.GOLD[1], UI.GOLD[2], UI.GOLD[3])
      local total, killed = 0, 0
      for _, wing in ipairs(raid.wings) do
        local r = nextRow()
        local d, n = fillBoxes(r, viewed, wing[2])
        total, killed = total + n, killed + d
        r.title:SetText("   " .. wing[1])
        r.title:SetTextColor(1, 1, 1)
        r.count:SetText(d .. "/" .. n)
        countColor(r.count, d, n)
      end
      header.count:SetText(killed .. "/" .. total)
      countColor(header.count, killed, total)
    else
      local r = nextRow()
      local d, n = fillBoxes(r, viewed, raid.bosses)
      r.title:SetText(raid.title:upper() .. (n == 1 and ("  |cffcccccc" .. raid.bosses[1] .. "|r") or ""))
      r.title:SetTextColor(UI.GOLD[1], UI.GOLD[2], UI.GOLD[3])
      r.count:SetText(d .. "/" .. n)
      countColor(r.count, d, n)
    end
  end

  -- the phase's Vault boss and Onyxia: part of the gate when the guild master's box is on (the default, user 2026-11-28)
  local ph = RTH_Phases[viewed]
  local optCounts = RTH.db.group.gates[viewed] and RTH.db.group.gates[viewed].opt
  local function optionalRow(label, bossName, killed)
    local r = nextRow()
    fillBoxes(r, viewed, {})
    local b = r.boxes[1]
    b.check:SetTexture(RTH.TEX .. (killed and "stamp_killed" or "check_todo"))
    b.skull:Hide()
    b.tipText = bossName .. (killed and " - killed" or " - not killed yet")
    b:Show()
    r.title:SetText(label)
    r.title:SetTextColor(0.7, 0.8, 1)
    r.count:SetText(optCounts and "|cffd9a441needed for the gate|r" or "|cffb8b8b8optional|r")
  end
  if ph.voa then
    optionalRow("VAULT  |cffcccccc" .. ph.voa.name .. "|r", ph.voa.name, RTH.BossKills(viewed .. ":voa", false) > 0)
  end
  for _, o in ipairs(ph.optional or {}) do optionalRow(o.name:upper(), o.name, RTH.AchDone(o.achievement)) end
  for j = row + 1, RAID_ROWS do f.raidRows[j]:Hide() end
end

UI.RegisterTab(1, "Progress", build, refresh)
-- a new phase opened for you: show it - not the phase you last looked at, whose "gate done" would hide what to
-- do next until you clicked the new icon
RTH.Listen("MY_PHASE_CHANGED", function() viewed = nil end)
