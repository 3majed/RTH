-- Road to Halion: kills, wipes, raid sessions, the journey log and the instance rules.
-- Kills are read from the 10-player kill STATISTICS: they count every boss the game credits, including the
-- ones that never die (Hodir, Thorim, Freya, Mimiron, Algalon, Gunship, Valithria, Faction Champions).
local RTH = RTH

-- ---------------------------------------------------------------- boss index
local STATS = {}     -- statistic id -> { key, name, phase, heroic, kind = "raid"/"voa"/"dungeon"/"ony" }
local NPCS = {}      -- creature id -> boss key (pull detection)
RTH.BOSS = {}        -- key -> { name, phase, stat, statH }

local function addNpcs(npc, key)
  if type(npc) == "table" then
    for _, id in ipairs(npc) do NPCS[id] = key end
  elseif npc then
    NPCS[npc] = key
  end
end

for p, ph in ipairs(RTH_Phases) do
  for i, b in ipairs(ph.bosses) do
    local key = p .. ":" .. i
    RTH.BOSS[key] = { name = b.name, phase = p, stat = b.stat, statH = b.statH }
    STATS[b.stat] = { key = key, name = b.name, phase = p, heroic = false, kind = "raid" }
    if b.statH then STATS[b.statH] = { key = key, name = b.name, phase = p, heroic = true, kind = "raid" } end
    addNpcs(b.npc, key)
  end
  if ph.voa then
    local key = p .. ":voa"
    RTH.BOSS[key] = { name = ph.voa.name, phase = p, stat = ph.voa.stat, voa = true }
    STATS[ph.voa.stat] = { key = key, name = ph.voa.name, phase = p, heroic = false, kind = "voa" }
    addNpcs(ph.voa.npc, key)
  end
end
local ONY_STAT = 1098   -- "Onyxia kills (Onyxia's Lair)": the only Onyxia statistic; 10-man checked on kill
RTH.BOSS["3:ony"] = { name = "Onyxia", phase = 3, stat = ONY_STAT }
STATS[ONY_STAT] = { key = "3:ony", name = "Onyxia", phase = 3, heroic = false, kind = "ony" }
NPCS[10184] = "3:ony"
for mapID, d in pairs(RTH_Dungeons) do
  STATS[d.stat] = { key = "d:" .. mapID, name = d.name, phase = d.phase, heroic = false, kind = "dungeon", map = mapID }
  STATS[d.statH] = { key = "d:" .. mapID, name = d.name, phase = d.phase, heroic = true, kind = "dungeon", map = mapID }
end

function RTH.BossKills(key, heroic)
  local b = RTH.BOSS[key]
  if not b then return 0 end
  return RTH.StatCount(heroic and b.statH or b.stat)
end

-- ---------------------------------------------------------------- raid session (one instance visit)
local session

local function rosterSnapshot()
  local names, subs, outsiders = {}, 0, {}
  for _, unit in ipairs(RTH.GroupUnits()) do
    local n = RTH.UnitKey(unit)
    if n then
      names[#names + 1] = n
      if not RTH.IsCore(n) and n ~= RTH.PlayerName() and not RTH.IsRulesKeeper(n) then
        if RTH.IsSub(n) then subs = subs + 1
        elseif not RTH.InGroup(n) then outsiders[#outsiders + 1] = n end   -- a guild member with RTH isn't outside
      end
    end
  end
  return names, subs, outsiders
end

-- everyone who was in tonight's raid at some point (saved with the visit, so it survives a /reload): the
-- night summary counts only THEIR rule breaks - the shared log also gets breaks from guildies elsewhere
local function noteRaidMembers()
  if not session then return end
  session.seen = session.seen or {}
  for _, n in ipairs((rosterSnapshot())) do session.seen[n] = true end
end

-- breaks by anyone in this raid since the session began (they put a star on the session's kills)
local function sessionBreaks()
  local out = {}
  if not session then return out end
  local inRaid = {}
  for _, n in ipairs((rosterSnapshot())) do inRaid[n] = true end
  -- by TIME since the session began, not by list position: a journey log catch-up inserts older breaks
  for _, b in ipairs(RTH.db.group.breaks) do
    if b.t >= session.start and inRaid[b.who] then out[#out + 1] = b.who .. ": " .. b.text end
  end
  return out
end

-- gear problems synced by the raid (each member's addon checks its own gear)
local function raidGearBreaks()
  local out = {}
  for _, n in ipairs((rosterSnapshot())) do
    local m = RTH.db.group.members[n]
    if n == RTH.PlayerName() then
      local problems = RTH.CheckEquipped()
      if problems[1] then out[#out + 1] = n .. ": " .. problems[1].reason end
    elseif m and m.gearBad and m.gearBad > 0 then
      out[#out + 1] = n .. ": " .. (m.gearReason or "gear not allowed")
    end
  end
  return out
end

-- ---------------------------------------------------------------- kills
local function recordKill(info, heroic, count)
  if not RTH.Active() then return end   -- not in the challenge (an alt): the shared journey log isn't theirs
  local g = RTH.db.group
  local names, subs, outsiders = rosterSnapshot()
  noteRaidMembers()
  local st = RTH.InstanceState()
  -- an heirloom still on at level 80 when a dungeon or raid boss dies (GM rule 2026-11-19): a rule break on you.
  -- Each player's own RTH checks its own gear, so everyone in the group logs only their own.
  local heir = RTH.WornHeirlooms()
  if heir[1] then
    RTH.AddBreak(RTH.PlayerName(), "killed " .. info.name .. " wearing an heirloom at level 80: " .. heir[1]
      .. (heir[2] and (" (+" .. (#heir - 1) .. " more)") or ""))
  end
  local stars = {}
  for _, s in ipairs(sessionBreaks()) do stars[#stars + 1] = s end   -- (in a raid this includes the heirloom break)
  for _, s in ipairs(raidGearBreaks()) do stars[#stars + 1] = s end
  if heir[1] and info.kind == "dungeon" then stars[#stars + 1] = RTH.PlayerName() .. ": heirloom on at level 80" end
  if info.kind ~= "dungeon" then
    if st.is25 then stars[#stars + 1] = "25-man raid" end
    if #names > 10 then stars[#stars + 1] = #names .. " players in the raid" end
    for _, o in ipairs(outsiders) do stars[#stars + 1] = o .. " is not in the group" end
    -- catching up (user rule 2026-11-19): a newer-phase boss with someone in the raid who hasn't finished an
    -- earlier gate (their own phase's content is fine - that's how they catch up)
    for _, n in ipairs(names) do
      local q, h, need = RTH.CatchUpOf(n)
      if q and info.phase > q then stars[#stars + 1] = n .. " is catching up (" .. RTH.CatchUpText(q, h, need) .. ")" end
    end
    -- the Vault boss of someone's own phase (1.4.0: each character has its own): a newer one is caught above
    -- (catching up / "belongs to"); an older one nobody here is on anymore gets a mark
    if info.kind == "voa" then
      local lowest
      for _, n in ipairs(names) do
        local q = (n == RTH.PlayerName() or RTH.HasRTH(n)) and RTH.PhaseOf(n)
        if q and (not lowest or q < lowest) then lowest = q end
      end
      if lowest and info.phase < lowest then
        stars[#stars + 1] = info.name .. " is not the Vault of Archavon boss of anyone's phase here"
      end
    end
  end
  if info.phase > RTH.GetPhase() then stars[#stars + 1] = info.name .. " belongs to " .. RTH.PhaseLabel(info.phase) end

  local wipeKey = info.key .. (heroic and "H" or "")
  local kill = {
    t = time(), d = date("%Y-%m-%d"), key = info.key, name = info.name, heroic = heroic,
    phase = info.phase, kind = info.kind, wipes = g.wipes[wipeKey] or 0,
    roster = names, subs = subs, stars = stars, by = RTH.PlayerName(), first = (count == 1),
  }
  -- (dungeons: any group is fine, Dungeon Finder strangers included - no "under 5 of the group" note since 2026-11-19)
  -- a raid member's synced copy of this same kill may have arrived first: ours (with roster and stars) replaces it
  for i = #g.kills, math.max(1, #g.kills - 20), -1 do
    local k = g.kills[i]
    if k.synced and k.key == info.key and time() - k.t < 900 then table.remove(g.kills, i) end
  end
  kill.rt = kill.t   -- when it reached this log (the log catch-up sends by this)
  table.insert(g.kills, kill)
  g.wipes[wipeKey] = 0
  if session then
    session.kills = session.kills + 1
  end
  RTH.Print((#stars > 0 and "|cffff4040* |r" or "|cff40ff40") .. info.name .. (heroic and " (heroic)" or "") .. " killed|r"
    .. (kill.wipes > 0 and (" after " .. kill.wipes .. " wipes") or ""))
  if RTH.Send then RTH.Send("K", info.key .. "|" .. (heroic and 1 or 0) .. "|" .. kill.wipes .. "|" .. #stars) end
  RTH.Fire("KILL", kill)
  RTH.After("gateCheck", 2, RTH.EvaluateGate)
end

-- compare every statistic with what we saw last time; a rise is a kill
local function scanStats(silent)
  local seen = RTH.char.stats
  for id, info in pairs(STATS) do
    local n = RTH.StatCount(id)
    local old = seen[id]
    if old == nil or silent then
      seen[id] = n
    elseif n > old then
      seen[id] = n
      local skip = info.kind == "ony" and RTH.InstanceState().is25
      if not skip then recordKill(info, info.heroic, n) end
    end
  end
end
RTH.ScanStats = scanStats

RTH.Listen("LOGIN", function()
  -- first login ever on this character: take the numbers as they are, log nothing
  if not RTH.char.statsSeeded then
    RTH.After("statsSeed", 3, function() scanStats(true); RTH.char.statsSeeded = true end)
  else
    -- not in the challenge (an alt): only keep the numbers current, so nothing is logged now or when it's switched on
    RTH.After("stats", 3, function() scanStats(not RTH.Active()) end)
  end
end)
RTH.On("CRITERIA_UPDATE", function()
  if RTH.char.statsSeeded and RTH.Active() then RTH.After("stats", 1, function() scanStats(false) end) end
end)

-- ---------------------------------------------------------------- pulls and wipes
local pull   -- boss key being fought

local function npcFromGUID(guid)
  return guid and tonumber(guid:sub(8, 12), 16)
end

RTH.On("COMBAT_LOG_EVENT_UNFILTERED", function(_, event, srcGUID, _, _, dstGUID, dstName, dstFlags)
  if not session then return end
  if event == "UNIT_DIED" then
    -- a group member died
    if dstName and bit.band(dstFlags or 0, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 and (UnitInRaid(dstName) or UnitInParty(dstName) or dstName == RTH.PlayerName()) then
      session.deaths[dstName] = (session.deaths[dstName] or 0) + 1
      session.totalDeaths = session.totalDeaths + 1
    end
    return
  end
  if not pull and InCombatLockdown() then
    local key = NPCS[npcFromGUID(dstGUID) or 0] or NPCS[npcFromGUID(srcGUID) or 0]
    if key then pull = key end
  end
end)

local function groupInCombat()
  for _, unit in ipairs(RTH.GroupUnits()) do
    if UnitAffectingCombat(unit) then return true end
  end
  return false
end

local function endPull(tries)
  if not pull then return end
  if groupInCombat() and tries < 15 then
    RTH.After("endPull", 2, function() endPull(tries + 1) end)
    return
  end
  local key = pull
  pull = nil
  scanStats(not RTH.Active())
  if not RTH.Active() then return end   -- switched off mid-raid: no wipe counted
  -- killed? recordKill reset the wipe counter to 0 and logged the kill this second
  local last = RTH.db.group.kills[#RTH.db.group.kills]
  if last and last.key == key and time() - last.t < 30 then return end
  local st = RTH.InstanceState()
  local wipeKey = key .. (st.heroic and "H" or "")
  RTH.db.group.wipes[wipeKey] = (RTH.db.group.wipes[wipeKey] or 0) + 1
  if session then session.wipes = session.wipes + 1 end
  RTH.Fire("WIPE", key)
end
RTH.On("PLAYER_REGEN_ENABLED", function()
  if pull then RTH.After("endPull", 3, function() endPull(0) end) end
end)

-- ---------------------------------------------------------------- instance rules + sessions
-- The visit (raid or dungeon) lives in the character's saved data: a /reload or a disconnect inside doesn't
-- start a new visit (no second "entered ..." break, and the night's summary keeps counting). Leaving ends it;
-- one older than 12 hours (logged out inside, back another day) is a new visit.
local VISIT_MAX = 12 * 3600
local function currentVisit(st)
  local v = RTH.char.visit
  if v and (v.name ~= tostring(st.name) or time() - v.start > VISIT_MAX) then v = nil end
  if not v then
    v = { start = time(), name = tostring(st.name), kills = 0, wipes = 0, totalDeaths = 0, deaths = {},
          breakStart = #RTH.db.group.breaks, logged = {} }
    RTH.char.visit = v
  end
  return v
end

-- tonight's raid is over (left it, or went straight on to a dungeon): show the summary. After a disconnect
-- that put us outside, the raid is only in the saved visit.
local function endSession()
  local v = RTH.char.visit
  local s = session or (v and v.raid and time() - v.start <= VISIT_MAX and v)
  session, pull = nil, nil
  if s and (s.kills > 0 or s.wipes > 0) then RTH.Fire("SESSION_ENDED", s) end
end

-- catching up: in a raid of a newer phase than someone in the raid group has finished, tell the group what
-- they still need (chat, once per visit and person - not a rule break; the kills get the mark)
local function catchUpWarning(st)
  if not (RTH.Active() and st.type == "raid" and st.phase) then return end
  local visit = currentVisit(st)
  local me = RTH.PlayerName()
  for _, n in ipairs((rosterSnapshot())) do
    local q, h, need = RTH.CatchUpOf(n)
    if q and st.phase > q and not visit.logged["catchup:" .. n] then
      visit.logged["catchup:" .. n] = true
      RTH.Print("|cffffd040" .. (n == me and "you are" or (n .. " is")) .. " catching up:|r " .. RTH.CatchUpText(q, h, need)
        .. " - finish it together first. " .. tostring(st.name) .. " kills with " .. (n == me and "you" or "them")
        .. " in the raid get a mark until then.")
    end
  end
end
-- someone joins the raid inside, or their gate report arrives a moment later
local function catchUpLater()
  RTH.After("catchUp", 3, function()
    local st = RTH.InstanceState()
    if st.type == "raid" then catchUpWarning(st) end
  end)
end
RTH.On("RAID_ROSTER_UPDATE", catchUpLater)
RTH.Listen("MEMBERS_CHANGED", catchUpLater)

-- entering a dungeon or raid at level 80 with heirlooms on (GM rule 2026-11-19): chat + a popup to take them off
-- first - a boss kill with one still on is a rule break (recordKill). Once per visit.
local function heirloomWarning(visit)
  local heir = RTH.WornHeirlooms()
  if not heir[1] or visit.logged.heirloom then return end
  visit.logged.heirloom = true
  local list = table.concat(heir, ", ")
  RTH.Print("|cffff4040you're level 80 and wearing heirlooms:|r " .. list
    .. " - take them off before the first boss: a boss kill with one on is a rule break")
  StaticPopupDialogs.RTH_HEIRLOOM = StaticPopupDialogs.RTH_HEIRLOOM or {
    text = "Road to Halion\n\nYou're level 80 and wearing heirlooms:\n%s\n\nTake them off before the first boss - a boss kill with one still on is a rule break.",
    button1 = "Show my gear", button2 = OKAY or "OK",
    OnAccept = function() if ToggleCharacter and not (CharacterFrame and CharacterFrame:IsShown()) then ToggleCharacter("PaperDollFrame") end end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
  }
  StaticPopup_Show("RTH_HEIRLOOM", list)
end

local function checkInstance()
  if not RTH.Active() then return end
  local st = RTH.InstanceState()
  local me = RTH.PlayerName()
  local phase = RTH.MyPhase()   -- your personal phase: catching up = only what you've caught up to
  local visit = (st.type == "raid" or st.type == "party") and currentVisit(st)
  -- "which opens in Phase 3" - or, when the guild has it open but you're still catching up, say that
  local function opensText(p)
    if p <= RTH.GetPhase() then
      local q, h, need = RTH.MyCatchUp()
      return "while catching up (" .. (q and RTH.CatchUpText(q, h, need) or RTH.PhaseLabel(p)) .. " first)"
    end
    return "which opens in " .. RTH.PhaseLabel(p)
  end
  -- once per visit: zone changes inside, a /reload or a reconnect fire this again
  local function once(text)
    if visit.logged[text] then return end
    visit.logged[text] = true
    RTH.AddBreak(me, text)
  end
  if st.type == "raid" then
    visit.raid = true
    if session and session ~= visit then endSession() end   -- straight from one raid into another
    session = visit   -- kills, wipes and deaths of tonight's raid (Extras shows the summary on leaving)
    noteRaidMembers()
    if st.is25 then once("entered a 25-man raid (" .. tostring(st.name) .. ")") end
    if st.phase and st.phase > phase and st.map ~= RTH.VOA_MAP then   -- (by map ID: any game language)
      once("entered " .. st.name .. " " .. opensText(st.phase))
    end
    catchUpWarning(st)
    heirloomWarning(visit)
  elseif st.type == "party" then
    if session then endSession() end   -- straight from a raid into a dungeon
    heirloomWarning(visit)
    -- (heroic dungeons: no "clear it on normal first" rule any more - guild master 2026-11-19)
    if st.phase and st.phase > phase then
      once("entered " .. st.name .. " " .. opensText(st.phase))
    end
  else
    endSession()
    RTH.char.visit = nil   -- left the instance: the next time in is a new visit
  end
end
RTH.On("PLAYER_ENTERING_WORLD", function() RTH.After("instance", 2, checkInstance) end)
RTH.On("ZONE_CHANGED_NEW_AREA", function() RTH.After("instance", 2, checkInstance) end)

-- Dungeon Finder: the random queue can offer a dungeon of a later phase (Trial of the Champion, the ICC
-- 5-mans) that the player didn't pick. Warn while the "dungeon found" window is up, BEFORE accepting:
-- entering it is a rule break (logged by checkInstance, like walking in).
RTH.On("LFG_PROPOSAL_SHOW", function()
  if not RTH.Active() or not GetLFGProposal then return end
  local exists, _, _, name = GetLFGProposal()
  if not exists or not name then return end
  local map = RTH.InstanceMap(name)   -- the Dungeon Finder's name, in any game language (2026-11-22)
  local d = map and RTH_Dungeons[map]
  if d then
    if d.phase > RTH.MyPhase() then
      local text = name .. (d.phase <= RTH.GetPhase() and " isn't open for you yet (catching up)" or (" opens in " .. RTH.PhaseLabel(d.phase)))
        .. " - decline it: going in is a rule break"
      RTH.Print("|cffff4040" .. text .. "|r")
      if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
        RaidNotice_AddMessage(RaidWarningFrame, "Road to Halion: " .. text, ChatTypeInfo["RAID_WARNING"])
      end
      PlaySound("RaidWarning")
      return
    end
  end
end)

-- ---------------------------------------------------------------- Dungeon Finder (user rule 2026-11-19)
-- At 80 while a dungeon is still locked: only "Specific Dungeons" (the random queues are greyed out - they can send
-- you to a dungeon of a later phase); below 80 random is fine (RTH.RandomDungeonSafe),
-- and the later-phase dungeons are greyed out in the list and can't be ticked. The warning above stays as a
-- backup. (Blizzard's own LFDFrame.lua, 3.3.5: the list, the ticks and the queue type are plain Lua - hooked
-- after the fact with hooksecurefunc, never replaced.)
-- the phase a Dungeon Finder entry opens in, when that's later than now (normal and heroic share the name)
local function lfdLockedPhase(dungeonID)
  -- by the Dungeon Finder's own ID (language-free, 2026-11-22); a name only for an ID RTH doesn't list
  local map = RTH.LFG_TO_MAP[dungeonID]
  if not map then
    local name = GetLFGDungeonInfo and GetLFGDungeonInfo(dungeonID)
    map = name and RTH.InstanceMap(name)
  end
  local d = map and RTH_Dungeons[map]
  if d and d.phase > RTH.MyPhase() then return d.phase end
end
RTH.LFDLockedPhase = lfdLockedPhase
-- untick every locked dungeon - also the ones inside collapsed headers, which the list doesn't draw but
-- "Find Group" would still queue for
local sweeping = false
local function sweepLocked()
  if sweeping or not RTH.Active() or not LFGEnabledList or not LFDList_SetDungeonEnabled then return false end
  sweeping = true
  local changed = false
  for _, list in ipairs({ LFDDungeonList or {}, LFDHiddenByCollapseList or {} }) do
    for _, id in pairs(list) do
      if LFGEnabledList[id] and not (LFGIsIDHeader and LFGIsIDHeader(id)) and lfdLockedPhase(id) then
        LFDList_SetDungeonEnabled(id, false)
        changed = true
      end
    end
  end
  if changed and LFGListUpdateHeaderEnabledAndLockedStates then
    LFGListUpdateHeaderEnabledAndLockedStates(LFDDungeonList, LFGEnabledList, LFGLockList, LFDHiddenByCollapseList)
  end
  sweeping = false
  return changed
end
local function sweepAndRedraw()
  if sweepLocked() and LFDQueueFrameSpecificList_Update then LFDQueueFrameSpecificList_Update() end
end
-- Is the random queue safe for you? Every dungeon a phase can lock (Trial of the Champion, the ICC 5-mans) needs
-- level 80 (LFGDungeons.dbc, normal and heroic), so below 80 a random queue can't land in one; at 80 it's safe
-- once nothing is locked any more (Phase 4).
local LOCKED_DUNGEON_LEVEL = 80
function RTH.RandomDungeonSafe()
  if (UnitLevel("player") or 0) < LOCKED_DUNGEON_LEVEL then return true end
  for _, d in pairs(RTH_Dungeons) do
    if d.phase > RTH.MyPhase() then return false end
  end
  return true
end
local function forceSpecific()
  if RTH.Active() and not RTH.RandomDungeonSafe() and LFDQueueFrame and LFDQueueFrame.type ~= "specific"
    and LFDQueueFrame_SetType then
    LFDQueueFrame_SetType("specific")
  end
end
if LFDQueueFrameSpecificListButton_SetDungeon and LFDQueueFrame_SetType then
  -- a locked dungeon's line: grey, its phase after the name, the tick box off and unclickable
  -- (the box is also dimmed: a skin like ElvUI's strips the tick box's textures and has no "disabled" look; the
  -- list reuses its buttons, so every other line gets full alpha back)
  RTH.Hook("LFDQueueFrameSpecificListButton_SetDungeon", function(button, dungeonID)
    local p = RTH.Active() and not (LFGIsIDHeader and LFGIsIDHeader(dungeonID)) and lfdLockedPhase(dungeonID)
    button.enableButton:SetAlpha(p and 0.35 or 1)
    if not p then return end
    button.enableButton:SetChecked(false)
    button.enableButton:Disable()
    button.instanceName:SetText("|cff808080" ..   -- dark grey on purpose: locked = looks unavailable
      tostring((GetLFGDungeonInfo(dungeonID))) .. " - " .. RTH.PhaseLabel(p) .. "|r")
  end)
  -- Opening the Dungeon Finder always ends in LFDQueueFrame_Update (the lock info it asks for arrives ->
  -- LFG_UpdateFramesIfShown), called by NAME - so this works even when a skin re-sets the frame's OnShow script
  -- (ElvUI hooks LFDParentFrame OnShow through AceHook and unhooks it again after the first open)
  RTH.Hook("LFDQueueFrame_Update", function()
    if LFDParentFrame and LFDParentFrame:IsShown() then forceSpecific() end
    sweepAndRedraw()
  end)
  RTH.Hook("LFDList_SetHeaderEnabled", sweepAndRedraw)   -- a header's tick box ticks every dungeon under it
  RTH.Hook("LFDQueueFrame_SetType", function(value) if value ~= "specific" then forceSpecific() end end)
  -- (LFDParentFrame's XML binds <OnShow function="LFDFrame_OnShow"/> at load: a hook on the global name would
  -- never run - hook the frame's own script)
  if LFDParentFrame then RTH.HookScript(LFDParentFrame, "OnShow", function() forceSpecific(); sweepAndRedraw() end) end
  -- the queue type menu: the random entries greyed out (Specific Dungeons stays)
  RTH.Hook("ToggleDropDownMenu", function(level, value, dropDownFrame)
    if not RTH.Active() or dropDownFrame ~= LFDQueueFrameTypeDropDown or not DropDownList1 then return end
    if RTH.RandomDungeonSafe() then return end   -- leveling, or nothing locked any more: random is fine
    for i = 1, DropDownList1.numButtons or 0 do
      local b = _G["DropDownList1Button" .. i]
      if b and b.value and b.value ~= "specific" then
        local text = ((b:GetText() or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
        b:Disable()
        b:SetText("|cff808080" .. text .. " (off - Road to Halion)|r")   -- dark grey on purpose: switched off
      end
    end
  end)
  -- a phase change can lock or unlock dungeons: redraw the list if it's open
  for _, msg in ipairs({ "PHASE_CHANGED", "MY_PHASE_CHANGED" }) do   -- (yours moves up as you catch up)
    RTH.Listen(msg, function()
      if LFDParentFrame and LFDParentFrame:IsShown() and LFDQueueFrame_Update then LFDQueueFrame_Update() end
    end)
  end
  -- reaching 80 with the Dungeon Finder open on a random queue: switch it to Specific Dungeons
  RTH.On("PLAYER_LEVEL_UP", function()
    RTH.After("lfdLevel", 2, function()
      if LFDParentFrame and LFDParentFrame:IsShown() then forceSpecific(); sweepAndRedraw() end
    end)
  end)
end

-- raid size, faction and roster are checked when the raid changes, inside a raid instance
RTH.On("RAID_ROSTER_UPDATE", function()
  if not session or not RTH.Active() then return end
  RTH.After("raidSize", 3, function()
    noteRaidMembers()
    local n = GetNumRaidMembers()
    if n > 10 then RTH.Print("|cffff4040" .. n .. " players in the raid - 10-man only|r") end
    for _, unit in ipairs(RTH.GroupUnits()) do
      if UnitFactionGroup(unit) and UnitFactionGroup(unit) ~= "Alliance" then
        RTH.Print("|cffff4040" .. (UnitName(unit) or "?") .. " is not Alliance|r")
      end
    end
  end)
end)

-- ---------------------------------------------------------------- raid lockouts (idea from Altoholic)
-- This character's saved Wrath raids: { name, id, ends, size, heroic }. Shared with the group ("L"), so
-- Raid Check can show who is saved where and warn about different raid IDs. A lockout on a 25-man raid
-- is a rule break (it catches 25-man runs RTH didn't see, e.g. with RTH off) - logged once per raid ID.
-- The FIRST scan on a character only takes note of what's there: lockouts from before RTH was installed
-- (a main's normal 25-man raid this week) are not breaks.
-- the same 25-man visit already logged as "entered a 25-man raid (X)" in the last 12 hours: one break is enough
local function enteredRecently(name)
  local want, me = "entered a 25-man raid (" .. name .. ")", RTH.PlayerName()
  for i = #RTH.db.group.breaks, math.max(1, #RTH.db.group.breaks - 50), -1 do
    local b = RTH.db.group.breaks[i]
    if time() - b.t > 12 * 3600 then break end
    if b.who == me and b.text == want then return true end
  end
  return false
end

local function scanLockouts()
  if not RTH.char then return end
  RTH.char.lockBreaks = RTH.char.lockBreaks or {}
  local baseline = not RTH.char.lockBaseline
  local list = {}
  for i = 1, GetNumSavedInstances() do
    local name, id, reset, difficulty, _, _, _, isRaid, maxPlayers = GetSavedInstanceInfo(i)
    -- the raid by its name in any game language; kept under RTH's English name, so players with different game
    -- languages still match each other's lockouts in Raid Check (2026-11-22)
    local _, _, en = RTH.RaidByName(name)
    if isRaid and reset and reset > 0 and name and en then
      local size = (maxPlayers and maxPlayers > 0) and maxPlayers or ((difficulty == 2 or difficulty == 4) and 25 or 10)
      list[#list + 1] = { name = en, id = id, ends = time() + reset, size = size, heroic = difficulty == 3 or difficulty == 4 }
      if size == 25 and not RTH.char.lockBreaks[id] then
        RTH.char.lockBreaks[id] = true
        if not baseline and RTH.Active() and not enteredRecently(name) then
          RTH.AddBreak(RTH.PlayerName(), "saved to a 25-man raid: " .. name .. " (raid ID " .. tostring(id) .. ")")
        end
      end
    end
  end
  RTH.char.lockBaseline = true
  RTH.char.lockouts = list
  RTH.Fire("LOCKOUTS_CHANGED")
end
RTH.On("UPDATE_INSTANCE_INFO", scanLockouts)
RTH.Listen("LOGIN", function() RTH.After("raidInfo", 4, RequestRaidInfo) end)
RTH.Listen("KILL", function() RTH.After("raidInfo", 5, RequestRaidInfo) end)   -- a kill can create a lockout

-- "Naxx 10" / "ToC 10 heroic" (short names keep Raid Check's lockout line on one line)
local RAID_SHORT = {
  ["Naxxramas"] = "Naxx", ["The Obsidian Sanctum"] = "OS", ["The Eye of Eternity"] = "EoE", ["Ulduar"] = "Ulduar",
  ["Trial of the Crusader"] = "ToC", ["Onyxia's Lair"] = "Ony", ["Icecrown Citadel"] = "ICC", ["The Ruby Sanctum"] = "RS",
  ["Vault of Archavon"] = "VoA",
}
function RTH.LockoutLabel(l)
  return (RAID_SHORT[l.name] or l.name) .. " " .. l.size .. (l.heroic and " heroic" or "")
end
