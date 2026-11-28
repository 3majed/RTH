-- Road to Halion: Raid Check tab (each member's legal light, size, faction, roster)
local RTH = RTH
local UI = RTH.UI

local DOT_ON = "|T" .. RTH.TEX .. "dot_online:10:10|t "     -- art round 5: gem lights for the guild view
local DOT_OFF = "|T" .. RTH.TEX .. "dot_offline:10:10|t "
local ROWS = 23   -- fits under the lockout line (a 10-man challenge; more rows would run off the window)

local function build(f)
  local cw = UI.CONTENT_W
  -- boxed sections: header (title, buttons, facts, lockouts) and the player list (rows start at -66)
  UI.Section(f, -4, 4, 4, nil, 62, { band = 28 })   -- band: behind the title + buttons row
  UI.Section(f, -4, -62, 4, -4)
  f.title = UI.Text(f, nil, UI.GOLD)
  f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -4)
  f.summary = UI.Light(f, 22)
  f.summary:SetPoint("LEFT", f.title, "RIGHT", 8, 0)
  f.checkBtn = UI.Button(f, "Check now", 100, 22, function() RTH.RequestStatus() end)
  f.checkBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
  -- inspects everyone in range and checks what they wear (works for players without RTH too)
  f.scanBtn = UI.Button(f, "Scan gear", 110, 22, function() RTH.ScanGroupGear() end)
  f.scanBtn:SetPoint("RIGHT", f.checkBtn, "LEFT", -6, 0)
  -- group view (party/raid, as before) or guild view (everyone in the guild with RTH - no group needed).
  -- Out of a group it starts on the guild view; a click picks one for the rest of the session.
  f.viewBtn = UI.Button(f, "Guild", 70, 22, function()
    f.mode = (f.mode == "guild") and "group" or "guild"
    f.userMode = GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0   -- remembered until you join / leave a group
    f.offset = 0
    RTH.UI.RefreshCurrent()
  end)
  f.viewBtn:SetPoint("RIGHT", f.scanBtn, "LEFT", -6, 0)
  -- a big guild doesn't fit: the mouse wheel scrolls the list
  f.offset = 0
  f:EnableMouseWheel(true)
  f:SetScript("OnMouseWheel", function(self, delta)
    self.offset = math.max(0, math.min((self.listSize or 0) - ROWS, self.offset - delta * 3))
    RTH.UI.RefreshCurrent()
  end)
  f.facts = UI.Text(f, "small", { 0.9, 0.9, 0.9 })
  f.facts:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -12)   -- clear of the title band's underline
  f.facts:SetWidth(cw)
  -- raid lockouts: who is saved where, and a warning when the group is split over different raid IDs
  f.locks = UI.Text(f, "small", { 0.85, 0.85, 0.85 })
  f.locks:SetPoint("TOPLEFT", f.facts, "BOTTOMLEFT", 0, -4)
  f.locks:SetWidth(cw); f.locks:SetHeight(12)   -- one line ("..." if it doesn't fit): the player list starts right below
  f.rows = {}
  for i = 1, ROWS do
    local r = CreateFrame("Frame", nil, f)
    r:SetWidth(cw); r:SetHeight(16)
    r:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -66 - (i - 1) * 16)
    UI.RowLook(r, i)   -- stripe on every other row + hover glow
    r.light = UI.Light(r, 14)
    r.light:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.classIcon = UI.ClassIcon(r, 14)   -- the player's class, before the name
    r.classIcon:SetPoint("LEFT", r.light, "RIGHT", 4, 0)
    r.name = UI.Text(r, "small", { 1, 1, 1 })
    r.name:SetPoint("LEFT", r.light, "RIGHT", 22, 0)
    r.name:SetWidth(94); r.name:SetHeight(14)   -- one line each, so a long reason never runs into the next row
    r.tag = UI.Text(r, "small", { 0.72, 0.72, 0.72 })
    r.tag:SetPoint("LEFT", r, "LEFT", 132, 0)
    r.tag:SetWidth(50)
    r.status = UI.Text(r, "small", { 0.85, 0.85, 0.85 })
    r.status:SetPoint("LEFT", r, "LEFT", 186, 0)
    r.status:SetWidth(cw - 186); r.status:SetHeight(14)
    -- hover: every problem item with its icon and the reason
    r:EnableMouse(true)
    UI.Tip(r, function(tt, self) RTH.UI.MemberGearTip(tt, self.member) end)
    f.rows[i] = r
  end
  f.empty = UI.Text(f, nil, { 0.7, 0.7, 0.7 }, "CENTER")
  f.empty:SetPoint("CENTER", f, "CENTER", 0, 0)
  UI.EmptyEmblem(f.empty, f)
  f.empty:SetText("Join a party or raid to see everyone's check.\nYour own gear is shown by the light at the top.")
end

local function summary(problems, checks)
  if problems[1] then return "bad", problems[1].reason .. (problems[2] and (" (+" .. (#problems - 1) .. " more)") or "") end
  if checks[1] then return "check", checks[1].reason end
  return "ok", "all gear allowed"
end

local function ago(t)
  local m = math.floor((time() - t) / 60)
  return m < 1 and "just now" or (m .. " min ago")
end

-- a gear scan result to use for this member: only when it is NEWER than their RTH's own report (a scan from
-- an hour ago must not hide that they put something on - or took it off - since)
local function usableScan(name, reportT)
  local ins = RTH.inspect.results[name]
  if not (ins and (ins.status == "ok" or ins.status == "bad" or ins.status == "check")) then return nil end
  if reportT and reportT > ins.t then return nil end
  return ins
end

-- Their report was made by an OLDER RTH than ours: its verdict uses that version's rules (2026-11-28: Glorify on
-- 1.6.1 still showed the old "made by someone in the group" crafted-gear rule as a red line). Said on the row and
-- in the hover, so an outdated verdict isn't read as a real problem.
local function oldVersionNote(m)
  local v = m and m.version
  if type(v) == "string" and RTH.VersionNewer and RTH.VersionNewer(RTH.VERSION, v) then
    return "  |cffffd040(old RTH " .. v .. ")|r", v
  end
  return "", nil
end

-- a member's line: your own gear live; others from the newer of the gear scan and their RTH report
local function memberLine(name)
  local unit = RTH.UnitByName(name)
  if unit and not RTH.GearCounts(unit) then return "ok", "leveling (gear counts from " .. RTH.GEAR_LEVEL .. ")" end
  local m = RTH.db.group.members[name]
  if not unit and name ~= RTH.PlayerName() then
    -- not in our group (guild view): the level their RTH reported, else the guild list's
    local level = (m and m.level) or RTH.GuildLevel(name)
    if level and level < RTH.GEAR_LEVEL then return "ok", "leveling (gear counts from " .. RTH.GEAR_LEVEL .. ")" end
  end
  if name == RTH.PlayerName() then return summary(RTH.CheckEquipped()) end
  local hasAddon = m and m.seen
  local ins = RTH.inspect.results[name]
  local scan = usableScan(name, m and math.max(m.statusT or 0, m.gearListT or 0))
  if scan then
    local s, text = summary(scan.problems, scan.checks)
    local old = time() - scan.t > 600 and ("  |cffb8b8b8(scan " .. ago(scan.t) .. ")|r") or ""
    return s, text .. (hasAddon and "" or "  |cffb8b8b8(no RTH)|r") .. old
  end
  if hasAddon then
    local old = oldVersionNote(m)
    if (m.gearBad or 0) > 0 then return "bad", (m.gearReason or "gear not allowed") .. old end
    if (m.gearCheck or 0) > 0 then return "check", (m.gearReason or "check manually") .. old end
    return "ok", "all gear allowed" .. old
  end
  if ins and ins.status == "offline" then return nil, "offline" end
  if ins and ins.status == "far" then return nil, "out of range - get closer and Scan gear" end
  return nil, "no RTH - click Scan gear"
end

-- a member's live lockouts (yours scanned here, others from their RTH)
local function lockoutsOf(name)
  local list = name == RTH.PlayerName() and RTH.char.lockouts
    or (RTH.db.group.members[name] and RTH.db.group.members[name].lockouts) or {}
  local out = {}
  for _, l in ipairs(list) do if l.ends > time() then out[#out + 1] = l end end
  return out
end

-- one line for the group: "Naxxramas 10: 6 saved, same raid ID" or a red warning when the IDs differ
local function lockoutSummary(names)
  local byRaid, order = {}, {}
  for _, name in ipairs(names) do
    for _, l in ipairs(lockoutsOf(name)) do
      local key = RTH.LockoutLabel(l)
      if not byRaid[key] then byRaid[key] = {}; order[#order + 1] = key end
      byRaid[key][l.id] = byRaid[key][l.id] or {}
      table.insert(byRaid[key][l.id], name)
    end
  end
  if not order[1] then return "|cffb8b8b8raid lockouts: nobody in the group is saved (players with RTH)|r" end
  -- warnings (different raid IDs) first, so they're never the part cut off with "..."
  local function split(key) local n = 0; for _ in pairs(byRaid[key]) do n = n + 1 end; return n > 1 end
  table.sort(order, function(a, b)
    if split(a) ~= split(b) then return split(a) end
    return a < b
  end)
  local parts = {}
  for _, key in ipairs(order) do
    local ids, biggest, total = {}, nil, 0
    for id, who in pairs(byRaid[key]) do
      ids[#ids + 1] = id; total = total + #who
      if not biggest or #who > #byRaid[key][biggest] then biggest = id end
    end
    if #ids == 1 then
      parts[#parts + 1] = "|cff40ff40" .. key .. "|r: " .. total .. " saved, same ID"
    else
      local others = {}
      for id, who in pairs(byRaid[key]) do
        if id ~= biggest then for _, n in ipairs(who) do others[#others + 1] = n end end
      end
      parts[#parts + 1] = "|cffff4040" .. key .. ": " .. #ids .. " raid IDs|r (" .. RTH.ClassColorNames(others) .. " on another)"
    end
  end
  return table.concat(parts, "   ")
end

-- the row tooltip: every problem item with its icon + reason, and where the result comes from
function RTH.UI.MemberGearTip(tt, name)
  -- just the name and the problem items (no source / lockout / "all fine" lines - user, 2026-11-18)
  if not name then return end
  tt:AddLine(RTH.ClassColorName(name))
  local _, oldV = oldVersionNote(name ~= RTH.PlayerName() and RTH.db.group.members[name] or nil)
  if oldV then
    tt:AddLine("uses RTH " .. oldV .. " (you have " .. RTH.VERSION .. "): this result follows that version's rules"
      .. " and may be out of date - ask them to update", 1, 0.82, 0.2, true)
  end
  local problems, checks
  if name == RTH.PlayerName() then
    problems, checks = RTH.CheckEquipped()
  else
    local ins = RTH.inspect.results[name]
    local m = RTH.db.group.members[name]
    local scan = usableScan(name, m and math.max(m.statusT or 0, m.gearListT or 0))
    if scan then   -- the same choice as the row: the newer of the scan and their RTH's list
      problems, checks = scan.problems, scan.checks
    elseif m and m.gearList then
      -- their RTH's own list: works out of range, offline, anywhere
      problems, checks = {}, {}
      for i = 1, table.maxn(m.gearList) do   -- stored by index; a lost message leaves a gap, not an empty list
        local g = m.gearList[i]
        if g then
          local link = select(2, GetItemInfo(g.item)) or ("[" .. g.item .. "]")
          table.insert(g.bad and problems or checks, { link = link, reason = g.reason, item = g.item })
        end
      end
    elseif m and m.seen then
      if (m.gearBad or 0) + (m.gearCheck or 0) > 0 then
        tt:AddLine(m.gearReason or "gear not allowed", 1, 0.4, 0.4, true)
      end
      return
    elseif ins and ins.status == "far" then
      tt:AddLine("out of range at the last scan (" .. ago(ins.t) .. ") - get closer and click Scan gear", 1, 0.82, 0.2, true)
      return
    elseif ins and ins.status == "offline" then
      tt:AddLine("offline at the last scan (" .. ago(ins.t) .. ")", 0.72, 0.72, 0.72, true)
      return
    else
      tt:AddLine("not checked yet - click Scan gear while they're near you", 0.72, 0.72, 0.72, true)
      return
    end
  end
  local function item(list, r, g, b)
    for _, p in ipairs(list) do
      local icon = GetItemIcon(p.item and tonumber(p.item:match("item:(%d+)")) or p.link)
      tt:AddLine((icon and ("|T" .. icon .. ":16|t ") or "") .. p.link .. " - " .. p.reason, r, g, b, true)
    end
  end
  item(problems, 1, 0.4, 0.4)
  item(checks, 1, 0.82, 0.2)
end

-- catching up on an earlier gate (Core RTH.CatchUpOf): shown after the gear status in both views
local function catchNote(name)
  local q, h, need = RTH.CatchUpOf(name)
  if q then return "  |cffffd040(catching up: " .. RTH.CatchUpText(q, h, need) .. ")|r" end
  return ""
end

-- ---------------------------------------------------------------- guild view
-- everyone in the guild whose RTH reported (and the core list's extra names): their own RTH's gear report,
-- so it works offline, far away and without a group. You first, then online, then offline; A-Z.
local function guildNames()
  local list, seen = { RTH.PlayerName() }, { [RTH.PlayerName()] = true }
  local function add(n) if n and not seen[n] then seen[n] = true; list[#list + 1] = n end end
  for n in pairs(RTH.db.group.members) do if RTH.HasRTH(n) then add(n) end end
  for _, n in ipairs(RTH.db.group.roster.names) do add(n) end
  local me = list[1]
  table.remove(list, 1)
  table.sort(list, function(a, b)
    local oa, ob = RTH.GuildOnline(a) and 1 or 0, RTH.GuildOnline(b) and 1 or 0
    if oa ~= ob then return oa > ob end
    return a < b
  end)
  table.insert(list, 1, me)
  return list
end

local function refreshGuild(f)
  f.title:SetText(UI.TitleIcon("Raid Check") .. "GUILD CHECK")
  f.viewBtn:SetText("Group")
  f.scanBtn:Hide()   -- inspecting needs the player near you: the guild view uses their RTH's own report
  local names = guildNames()
  f.listSize = #names
  f.offset = math.max(0, math.min(f.offset or 0, #names - ROWS))
  local legal, bad, leveling, unknown, worst = 0, 0, 0, 0, "ok"
  for _, name in ipairs(names) do
    local s, text = memberLine(name)
    if s == "ok" then
      if text:find("^leveling") then leveling = leveling + 1 else legal = legal + 1 end
    elseif s == "bad" then bad = bad + 1; worst = "bad"
    elseif s == "check" then if worst ~= "bad" then worst = "check" end
    else unknown = unknown + 1 end
  end
  for i = 1, ROWS do
    local r = f.rows[i]
    local name = names[i + f.offset]
    if name then
      local s, text = memberLine(name)
      if s == nil then text = "no RTH - group up with them and Scan gear" end   -- (no scan button in this view)
      text = text .. catchNote(name)
      local m = RTH.db.group.members[name]
      local online = name == RTH.PlayerName() or RTH.GuildOnline(name)
      if not online and m and m.seen then
        local h = math.floor((time() - m.seen) / 3600)
        text = text .. "  |cffb8b8b8(" .. (h < 1 and "<1h" or h < 48 and (h .. "h") or (math.floor(h / 24) .. "d")) .. " ago)|r"
      end
      r.member = name
      r:Show()
      r.light:SetState(s)
      r.name:SetText(RTH.ClassColorName(name)); r.classIcon:SetClass(RTH.ClassOf(name)); r.name:SetTextColor(1, 1, 1)
      r.tag:SetText(name == RTH.PlayerName() and "you" or RTH.IsRulesKeeper(name) and "|cffd9a441GM|r"
        or online and (DOT_ON .. "|cff40ff40online|r") or (DOT_OFF .. "|cffb8b8b8offline|r"))
      r.status:SetText(text)
      if s == "bad" then r.status:SetTextColor(1, 0.4, 0.4)
      elseif s == "check" then r.status:SetTextColor(1, 0.82, 0.2)
      elseif s == "ok" then r.status:SetTextColor(0.5, 0.9, 0.5)
      else r.status:SetTextColor(0.72, 0.72, 0.72) end
    else
      r:Hide()
    end
  end
  f.summary:SetState(worst)
  local facts = { (#names - unknown) .. " with RTH", "|cff40ff40" .. legal .. " legal|r" }
  if bad > 0 then facts[#facts + 1] = "|cffff4040" .. bad .. " not legal|r" end
  if leveling > 0 then facts[#facts + 1] = leveling .. " leveling" end
  if unknown > 0 then facts[#facts + 1] = "|cffb8b8b8" .. unknown .. " not heard yet|r" end
  f.facts:SetText(table.concat(facts, "   "))
  f.locks:SetText(#names > ROWS and ("|cffb8b8b8mouse wheel: more (" .. (f.offset + 1) .. "-" .. math.min(#names, f.offset + ROWS)
    .. " of " .. #names .. ")   hover a name for their gear|r") or "|cffb8b8b8hover a name for their gear|r")
  UI.Shown(f.empty, #names <= 1)
  f.empty:SetText("Nobody else in the guild with RTH has been heard from yet.\n/rth sync shows who RTH knows.")
end

local function refresh(f)
  -- out of a group: the guild view, unless the player picked one with the button
  local grouped = GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0
  if f.userMode ~= nil and f.userMode ~= grouped then f.userMode = nil end   -- joined / left a group: back to auto
  if f.userMode == nil then f.mode = grouped and "group" or "guild" end
  if f.mode == "guild" then refreshGuild(f); return end
  f.viewBtn:SetText("Guild")
  f.scanBtn:Show()
  f.listSize = 0; f.offset = 0
  f.empty:SetText("Join a party or raid to see everyone's check.\nYour own gear is shown by the light at the top.")
  local units = RTH.GroupUnits()
  local inRaid = GetNumRaidMembers() > 0
  f.title:SetText(UI.TitleIcon("Raid Check") .. (inRaid and "RAID CHECK" or "PARTY CHECK"))
  local legal, total, worst = 0, 0, "ok"
  local core, subs, outsiders, horde, withRTH = 0, 0, 0, 0, 0
  for i = 1, ROWS do
    local r = f.rows[i]
    local unit = units[i]
    local name = unit and RTH.UnitKey(unit)
    if name then
      total = total + 1
      local s, text = memberLine(name)
      text = text .. catchNote(name)
      r.member = name
      r:Show()
      r.light:SetState(s)
      r.name:SetText(RTH.ClassColorName(name)); r.classIcon:SetClass(RTH.ClassOf(name)); r.name:SetTextColor(1, 1, 1)
      local tag
      if RTH.IsCore(name) then tag = "core"; core = core + 1
      elseif RTH.IsSub(name) then tag = "sub"; subs = subs + 1
      elseif RTH.IsRulesKeeper(name) then tag = "|cffd9a441GM|r"   -- the guild master always belongs
      elseif name == RTH.PlayerName() then tag = "you"
      elseif RTH.HasRTH(name) then tag = "RTH"; withRTH = withRTH + 1   -- a guild member running RTH: in the group
      else tag = "|cffff6060outside|r"; outsiders = outsiders + 1 end
      r.tag:SetText(tag)
      r.status:SetText(text)
      if s == "bad" then r.status:SetTextColor(1, 0.4, 0.4)
      elseif s == "check" then r.status:SetTextColor(1, 0.82, 0.2)
      elseif s == "ok" then r.status:SetTextColor(0.5, 0.9, 0.5)
      else r.status:SetTextColor(0.72, 0.72, 0.72) end
      if s == "ok" then legal = legal + 1 end
      if s == "bad" then worst = "bad" elseif s ~= "ok" and worst ~= "bad" then worst = "check" end
      if UnitFactionGroup(unit) and UnitFactionGroup(unit) ~= "Alliance" then horde = horde + 1 end
    else
      r:Hide()
    end
  end
  UI.Shown(f.empty, total <= 1 and not inRaid and GetNumPartyMembers() == 0)
  f.summary:SetState(worst)
  local st = RTH.InstanceState()
  local facts = {}
  facts[#facts + 1] = legal .. "/" .. total .. " legal"
  facts[#facts + 1] = (total <= 10 and "|cff40ff40" or "|cffff4040") .. total .. (total == 1 and " player|r" or " players|r")
  if st.type == "raid" then facts[#facts + 1] = st.is25 and "|cffff404025-man|r" or "|cff40ff4010-man|r" end
  facts[#facts + 1] = horde == 0 and "|cff40ff40all Alliance|r" or ("|cffff4040" .. horde .. " not Alliance|r")
  -- guild members with RTH are in the group without a core list, so an empty list is no longer a warning
  local rosterTxt = core .. " core + " .. subs .. " subs" .. (withRTH > 0 and (" + " .. withRTH .. " with RTH") or "")
  if outsiders > 0 then rosterTxt = rosterTxt .. " + |cffff4040" .. outsiders .. " outside|r" end
  facts[#facts + 1] = rosterTxt
  -- catching up on an earlier gate: the group should finish their gate first (a message, no mark - 2026-11-28)
  local behind = {}
  for _, unit in ipairs(units) do
    local n = RTH.UnitKey(unit)
    if n and RTH.CatchUpOf(n) then behind[#behind + 1] = n end
  end
  if behind[1] then facts[#facts + 1] = "|cffffd040catching up: " .. table.concat(behind, ", ") .. "|r" end
  f.facts:SetText(table.concat(facts, "   "))
  local names = {}
  for _, unit in ipairs(units) do local n = RTH.UnitKey(unit); if n then names[#names + 1] = n end end
  f.locks:SetText(lockoutSummary(names))
  -- scan progress on the button
  local ins = RTH.inspect
  if ins.active then f.scanBtn:SetText("Scanning " .. ins.done .. "/" .. ins.total); f.scanBtn:Disable()
  else f.scanBtn:SetText("Scan gear"); f.scanBtn:Enable() end
end

UI.RegisterTab(2, "Raid Check", build, refresh)
