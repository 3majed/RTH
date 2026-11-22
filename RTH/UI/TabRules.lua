-- Road to Halion: Rules tab (switches, your phase, roster, unlock-gate editor)
local RTH = RTH
local UI = RTH.UI

local GATE_ROWS = 9
local GATE_H = 18
local gatePhase = 1

-- only the guild master changes the rules (never a group leader); without a guild nobody can
local function canLead()
  return RTH.IAmRulesKeeper()
end

local function gateHas(p, id)
  for _, x in ipairs(RTH.db.group.gates[p].ids) do if x == id then return true end end
  return false
end

-- a gate can't change once anyone has STARTED the next phase (user rule 2026-11-19): killed its bosses, worn its
-- gear or finished its gate. Before that the guild master may still change it (found it too easy) - whoever no
-- longer meets it loses the next phase again until they do (Core revokeChanged).
local function gateLockedBy(p)
  local who, what = RTH.GateLockedBy(p)
  return who and (RTH.ClassColorName(who) .. " " .. what) or nil
end
local function canEditGate(p)
  if not canLead() then return false end
  local why = gateLockedBy(p)
  if why then
    RTH.Print("the gate of " .. RTH.PhaseLabel(p) .. " is locked - " .. why .. " (the next phase has started)")
    return false
  end
  return true
end
-- someone has finished it but nobody started the next phase: say what an edit does
local function anyonePassed(p)
  if RTH.char.passed[p] then return true end
  for _, m in pairs(RTH.db.group.members) do if type(m) == "table" and m.passes and m.passes[p] then return true end end
  return false
end

-- a gate edit is shared by itself (like the core list), 2 s after the last tick so ten ticks send once:
-- every member's progress report is checked against THEIR copy, so an unshared edit would mislead it
local function gateChanged(p)
  RTH.Fire("GATES_CHANGED")
  RTH.After("shareGate" .. p, 2, function() if canLead() then RTH.BroadcastGate(p) end end)
end

local function toggleGate(p, id, on)
  if not canEditGate(p) then UI.RefreshCurrent(); return end   -- (puts the tick back)
  local ids = RTH.db.group.gates[p].ids
  for i = #ids, 1, -1 do if ids[i] == id then table.remove(ids, i) end end   -- by value, never by index
  if on then ids[#ids + 1] = id end
  gateChanged(p)
end

local function build(f)
  local cw = UI.CONTENT_W
  -- boxed sections: switches, your phase, roster + subs, the unlock-gate editor
  UI.Section(f, -4, 4, 4, nil, 54)
  UI.Section(f, -4, -54, 4, nil, 26)
  UI.Section(f, -4, -84, 4, nil, 76, { band = 20 })   -- band: behind the 'Core group' label
  UI.Section(f, -4, -164, 4, -4, nil, { band = 30 })   -- band: behind 'Unlock gate of phase' + buttons
  -- switches
  f.inChallenge = UI.Check(f, "This character is in the challenge", function(on)
    RTH.SetInChallenge(on)
    StaticPopup_Hide("RTH_ASK_CHALLENGE")   -- answered here: the login question is no longer needed
  end)
  f.inChallenge:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  f.overlays = UI.Check(f, "Red marks on icons", function(on)
    RTH.db.ui.overlays = on
    RTH.Fire("OVERLAYS_TOGGLED")
  end)
  f.overlays:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -24)
  f.minimap = UI.Check(f, "Minimap button", function(on)
    RTH.db.ui.minimap = on
    if RTH.UpdateMinimapButton then RTH.UpdateMinimapButton() end
  end)
  f.minimap:SetPoint("TOPLEFT", f, "TOPLEFT", 250, -24)

  -- your phase (1.4.0: each character opens its own next phase by finishing its gate - no unlock button)
  f.phaseText = UI.Text(f, nil, UI.GOLD)
  f.phaseText:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -60)
  f.phaseText:SetWidth(UI.CONTENT_W)
  f.phaseText:SetHeight(14)

  -- roster
  local rl = UI.Text(f, "small", UI.GOLD)
  rl:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -92)
  rl:SetText("Core group: guild members with RTH are in it already. Extra names (commas):")
  f.names = UI.StyleInput(UI.Outline(CreateFrame("EditBox", "RTHRosterNames", f, "InputBoxTemplate")))
  f.names:SetWidth(cw - 176); f.names:SetHeight(20)
  f.names:SetAutoFocus(false)
  f.names:SetMaxLetters(240)
  f.names:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -108)
  f.names:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  -- the box is the whole list: Save replaces it (so deleting a name removes that player)
  local function saveRoster(text)
    if not canLead() then return end
    local list, seen = {}, {}
    local unknown = {}
    for n in (text or ""):gmatch("[^,%s]+") do
      n = n:sub(1, 1):upper() .. n:sub(2):lower()
      -- the guild's own spelling when someone has this name; a name nobody in the guild has is kept (they may
      -- join later) but named in chat: a typo would make the real player an outsider without anyone noticing
      local exact = RTH.GuildRosterKnown() and RTH.GuildMemberName(n)
      if exact then n = exact elseif RTH.GuildRosterKnown() then unknown[#unknown + 1] = n end
      if not seen[n] then seen[n] = true; list[#list + 1] = n end
    end
    RTH.db.group.roster.names = list
    f.names:ClearFocus()
    RTH.BroadcastRoster()
    RTH.Fire("ROSTER_CHANGED")
    if unknown[1] then
      RTH.Print("|cffffd040not in your guild (a typo?): " .. table.concat(unknown, ", ")
        .. " - they count as outsiders until the name matches someone in the guild|r")
    end
  end
  f.saveNames = UI.Button(f, "Save", 70, 22, function() saveRoster(f.names:GetText()) end)
  f.saveNames:SetPoint("LEFT", f.names, "RIGHT", 8, 0)
  f.names:SetScript("OnEnterPressed", function(self) saveRoster(self:GetText()) end)
  -- add one player at a time: target them, click + Target
  f.addTarget = UI.Button(f, "+ Target", 80, 22, function()
    local name = UnitIsPlayer("target") and RTH.UnitKey("target")
    if not name then RTH.Print("target a player first"); return end
    if name:find("-", 1, true) then RTH.Print(name .. " is from another realm - only your own realm's players can join"); return end
    saveRoster(table.concat(RTH.db.group.roster.names, ",") .. "," .. name)
    RTH.Print(name .. " added to the core group")
  end)
  f.addTarget:SetPoint("LEFT", f.saveNames, "RIGHT", 6, 0)
  local rk = UI.Text(f, "small", UI.GOLD)
  rk:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -136)
  rk:SetText("Subs: guild members of this rank or higher:")
  -- rank picker: RTH's own menu (UI.Menu), not Blizzard's dropdown (that one can taint unit menus)
  local function setRank(r)
    if not canLead() then return end
    RTH.db.group.roster.rank = r; RTH.BroadcastRoster(); RTH.Fire("ROSTER_CHANGED")
  end
  f.rank = UI.Button(f, "no subs", 160, 22, function(self)
    local cur = RTH.db.group.roster.rank
    local items = { { text = "no subs", checked = cur == nil, func = function() setRank(nil) end } }
    if IsInGuild() then
      for i = 1, GuildControlGetNumRanks() do
        items[#items + 1] = { text = GuildControlGetRankName(i), checked = cur == i - 1, func = function() setRank(i - 1) end }
      end
    end
    UI.Menu(items, self)
  end)
  f.rank:SetPoint("LEFT", rk, "RIGHT", 8, 0)

  -- unlock gate editor
  local gl = UI.Text(f, "small", UI.GOLD)
  gl:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -174)
  gl:SetText("Unlock gate of phase:")
  f.gateButtons = {}
  for p = 1, RTH.MAX_PHASE do
    -- square number picks (the tab art looked cramped on them, even 36 wide); hover names the phase
    local b = UI.SquareButton(f, tostring(p), 22, function() gatePhase = p; UI.RefreshCurrent() end)
    b:SetPoint("LEFT", gl, "RIGHT", 10 + (p - 1) * 30, 0)
    UI.Tip(b, function(tt) tt:AddLine(RTH.PhaseLabel(p), 1, 0.85, 0.4); tt:AddLine("Show this phase's unlock gate", 0.72, 0.72, 0.72) end)
    f.gateButtons[p] = b
  end
  f.gateNote = UI.Text(f, "small", { 0.8, 0.8, 0.8 })
  f.gateNote:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -196)
  f.gateNote:SetWidth(cw)
  f.gateScroll = UI.StyleScroll(CreateFrame("ScrollFrame", "RTHGateScroll", f, "FauxScrollFrameTemplate"))
  f.gateScroll:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -214)
  f.gateScroll:SetWidth(cw - 24); f.gateScroll:SetHeight(GATE_ROWS * GATE_H)
  f.gateScroll:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, GATE_H, function() UI.RefreshCurrent() end)
  end)
  f.gateRows = {}
  for i = 1, GATE_ROWS do
    local c = UI.Check(f, "", function(on)
      local self = f.gateRows[i]
      if self.ach then toggleGate(gatePhase, self.ach, on) end
    end)
    c:SetWidth(20); c:SetHeight(20)
    c:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -214 - (i - 1) * GATE_H)
    c.label:SetFontObject(GameFontHighlightSmall); UI.Outline(c.label)
    f.gateRows[i] = c
  end
  f.gateOpt = UI.Check(f, "Optional raids (this phase's VoA boss, Onyxia) also count", function(on)
    if not canEditGate(gatePhase) then UI.RefreshCurrent(); return end
    RTH.db.group.gates[gatePhase].opt = on
    gateChanged(gatePhase)
  end)
  f.gateOpt:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -214 - GATE_ROWS * GATE_H - 4)
  f.gateReset = UI.Button(f, "Group default", 110, 22, function()
    if not canEditGate(gatePhase) then return end
    RTH.db.group.gates[gatePhase] = RTH.DefaultGates()[gatePhase]
    gateChanged(gatePhase)
  end)
  f.gateReset:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -214 - GATE_ROWS * GATE_H - 32)
  f.gateShare = UI.Button(f, "Share with group", 130, 22, function()
    if not canLead() then return end
    RTH.BroadcastGate(gatePhase)
    RTH.Print("unlock gate of " .. RTH.PhaseLabel(gatePhase) .. " shared with the group")
  end)
  f.gateShare:SetPoint("LEFT", f.gateReset, "RIGHT", 8, 0)
end

local function setEnabled(obj, on)
  if on then obj:Enable() else obj:Disable() end
end

local function refresh(f)
  f.inChallenge:SetChecked(RTH.char.inChallenge)
  f.overlays:SetChecked(RTH.db.ui.overlays)
  f.minimap:SetChecked(RTH.db.ui.minimap)
  local lead = canLead()
  local mine, far = RTH.MyPhase(), RTH.GetPhase()
  f.phaseText:SetText("Your phase: " .. RTH.PhaseLabel(mine)
    .. (far > mine and ("  |cffb8b8b8(furthest in the guild: " .. RTH.PHASE_NAMES[far] .. ")|r") or ""))
  if not f.names:HasFocus() then f.names:SetText(table.concat(RTH.db.group.roster.names, ", ")) end
  -- 3.3.5 edit boxes have no Enable/Disable: lock it by ignoring the mouse (no click = no typing) and dimming it
  f.names:EnableMouse(lead)
  f.names:SetAlpha(lead and 1 or 0.5)
  if not lead then f.names:ClearFocus() end
  setEnabled(f.saveNames, lead); setEnabled(f.addTarget, lead)
  setEnabled(f.rank, lead)
  local rank = RTH.db.group.roster.rank
  f.rank:SetText((rank and IsInGuild() and GuildControlGetRankName(rank + 1) or "no subs") .. " |TInterface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up:14:14|t")

  for q, b in ipairs(f.gateButtons) do
    if q == gatePhase then b:LockHighlight() else b:UnlockHighlight() end
  end
  local opts = RTH_GateOptions[gatePhase] or {}
  local lockedBy = gateLockedBy(gatePhase)
  local editable = lead and not lockedBy
  f.gateNote:SetText(not lead and ("|cffb8b8b8Only " .. RTH.KeeperLabel() .. " can change unlock gates.|r")
    or lockedBy and ("|cffffd040Locked|r - " .. lockedBy .. ", so the next phase has started. Ticked: " .. #RTH.db.group.gates[gatePhase].ids)
    or anyonePassed(gatePhase) and ("|cffffd040Careful:|r someone finished this gate. A new tick closes " .. (RTH.PHASE_NAMES[gatePhase + 1] or "the next phase")
      .. " again for whoever doesn't have it. Ticked: " .. #RTH.db.group.gates[gatePhase].ids)
    or ("Tick what opens " .. (gatePhase < RTH.MAX_PHASE and RTH.PhaseLabel(gatePhase + 1) or "the end")
      .. " (it locks once someone starts the next phase). Ticked: " .. #RTH.db.group.gates[gatePhase].ids))
  FauxScrollFrame_Update(f.gateScroll, #opts, GATE_ROWS, GATE_H)
  local offset = FauxScrollFrame_GetOffset(f.gateScroll)
  for i, c in ipairs(f.gateRows) do
    local id = opts[offset + i]
    if id then
      local _, name, _, done = GetAchievementInfo(id)
      c.ach = id
      c.label:SetText((name or ("Achievement " .. id)) .. (done and " |cff40ff40(done)|r" or ""))
      c:SetChecked(gateHas(gatePhase, id))
      setEnabled(c, editable)
      c:Show()
    else
      c.ach = nil
      c:Hide()
    end
  end
  f.gateOpt:SetChecked(RTH.db.group.gates[gatePhase].opt)
  setEnabled(f.gateOpt, editable)
  setEnabled(f.gateReset, editable)
  setEnabled(f.gateShare, lead)
end

UI.RegisterTab(5, "Rules", build, refresh)
