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
    addNpcs(b.pull, key)   -- NPCs that start the fight but don't end it (Gormok, Fjola): pull detection only
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

-- ---------------------------------------------------------------- backup kill detection (2026-11-28, ideas from DBM)
-- The kill STATISTIC stays the main way. But RTH had never logged a raid kill on this server yet, and some servers
-- don't update every boss statistic - then kills (and gates) would go missing. So RTH also watches the boss DIE
-- (combat log), like DBM ends most fights, and - only when DBM is installed - DBM's own kill event (the bosses that
-- never die: Hodir, Thorim, Freya, Mimiron, Algalon, Faction Champions, Gunship, Valithria). When the statistic
-- hasn't logged that kill 15 s later, RTH logs it itself. One kill is never logged twice.
local KEYINFO = {}     -- boss key -> its STATS info (the normal one; heroic is passed separately)
local DEATH_NPC = {}   -- creature id -> boss key, for the bosses whose fight ends with a death
local MULTI = {}       -- boss key -> { creature ids }: councils, every one must be dead
for p, ph in ipairs(RTH_Phases) do
  for i, b in ipairs(ph.bosses) do
    local key = p .. ":" .. i
    KEYINFO[key] = STATS[b.stat]
    if b.kill == "death" then
      local ids = type(b.npc) == "table" and b.npc or { b.npc }
      if #ids > 1 then MULTI[key] = ids end
      for _, id in ipairs(ids) do DEATH_NPC[id] = key end
    end
  end
  if ph.voa then
    KEYINFO[p .. ":voa"] = STATS[ph.voa.stat]
    DEATH_NPC[ph.voa.npc] = p .. ":voa"
  end
end
KEYINFO["3:ony"] = STATS[ONY_STAT]
DEATH_NPC[10184] = "3:ony"

-- this character's own logged kills of a boss (not other players' copies)
local function ownKills(key, heroic)
  local n, me = 0, RTH.PlayerName()
  for _, k in ipairs(RTH.db.group.kills) do
    if k.key == key and k.by == me and not k.synced and (k.heroic and true or false) == (heroic and true or false) then n = n + 1 end
  end
  return n
end
-- a kill of this boss logged by our own RTH in the last `secs` seconds (how = "seen": only one the backup logged)
local function recentOwnKill(key, secs, how)
  local me, kills = RTH.PlayerName(), RTH.db.group.kills
  for i = #kills, math.max(1, #kills - 30), -1 do
    local k = kills[i]
    if k.key == key and k.by == me and not k.synced and time() - (k.t or 0) < secs and (not how or k.how == how) then
      return true
    end
  end
  return false
end

-- how often this character killed a boss: the statistic, or - when the server never updates it - our own log
function RTH.BossKills(key, heroic)
  local b = RTH.BOSS[key]
  if not b then return 0 end
  local s = RTH.StatCount(heroic and b.statH or b.stat)
  if s > 0 then return s end
  return ownKills(key, heroic)
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
        -- (a guild member with RTH isn't outside - also in the seconds before the guild list loads: Core HasRTH)
        elseif not RTH.InGroup(n) then outsiders[#outsiders + 1] = n end
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
    elseif m and (m.gearCheck or 0) > 0 then
      -- an heirloom worn at 80 (rule 13) is only a yellow "check" on their gear, and their own rule break for the
      -- kill reaches us a moment AFTER our RTH logged the same kill - so our copy stayed clean and counted for our
      -- gate (found 2026-11-28). Their gear report (S reason, Q list) already says so: star it here too.
      local heir = type(m.gearReason) == "string" and m.gearReason:find("^heirloom")
      for _, gi in pairs(type(m.gearList) == "table" and m.gearList or {}) do
        if type(gi) == "table" and type(gi.reason) == "string" and gi.reason:find("^heirloom") then heir = true end
      end
      if heir then out[#out + 1] = n .. ": heirloom on at level 80" end
    end
  end
  return out
end

-- ---------------------------------------------------------------- kills
-- count: the statistic's new value (1 = a first kill); nil when the backup detection logs it (how = "seen")
local function recordKill(info, heroic, count, how)
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
    -- (someone behind in the raid - catching up on an earlier gate - is NOT a mark any more: user 2026-11-28 "keep it
    -- simple, each character follows its own gate". The group is told on entering - catchUpWarning - and a
    -- character's next phase only ever opens through its OWN gate, so being carried through newer bosses gains it
    -- nothing for its gate.)
    -- the Vault boss of someone's own phase (1.4.0: each character has its own): a newer one than the guild has
    -- opened is caught by "belongs to" below; an older one nobody here is on anymore gets a mark
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
    roster = names, subs = subs, stars = stars, by = RTH.PlayerName(),
    first = (count == 1) or (count == nil and ownKills(info.key, heroic) == 0), how = how,
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
      -- (the backup detection may have logged this kill already - the statistic came late: one kill, not two. Only a
      -- backup kill is skipped: two statistic rises are two real kills.)
      if not skip and info.kind ~= "dungeon" and recentOwnKill(info.key, 600, "seen") then skip = true end
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
  return guid and tonumber(guid:sub(8, 12), 16)   -- (the same as DBM's GetCIDFromGUID on 3.3.5)
end

-- the backup kill (see "backup kill detection" at the top): the boss was seen dying - or DBM said "kill". 15 s later,
-- when the statistic still hasn't logged it, RTH logs it itself (how = "seen").
local deadAt = {}       -- boss key -> when its death was seen (that pull is no wipe)
local councilDead = {}  -- boss key -> { creature id -> time }: councils end when every member is dead
local function backupKill(key)
  if not KEYINFO[key] then return end
  deadAt[key] = time()
  RTH.After("backupKill" .. key, 15, function()
    if not RTH.Active() or recentOwnKill(key, 120) then return end
    scanStats(false)   -- one more look at the statistics first: they normally log it themselves
    if recentOwnKill(key, 120) then return end
    local info, st = KEYINFO[key], RTH.InstanceState()
    -- (25-man: not logged, like the statistic path - it reads the 10-player statistics; entering was the rule break)
    if st.is25 then return end
    recordKill(info, st.heroic and true or false, nil, "seen")
  end)
end
local function bossDied(key, npc)
  local need = MULTI[key]
  if need then
    councilDead[key] = councilDead[key] or {}
    councilDead[key][npc] = time()
    for _, id in ipairs(need) do
      local t = councilDead[key][id]
      if not t or time() - t > 600 then return end
    end
    councilDead[key] = nil
  end
  backupKill(key)
end
-- DBM's kill event, only when DBM is installed (RTH never needs it): its boss mod knows the creature id
RTH.On("PLAYER_LOGIN", function()
  if type(DBM) ~= "table" or type(DBM.RegisterCallback) ~= "function" then return end
  pcall(DBM.RegisterCallback, DBM, "DBM_Kill", function(_, mod)
    if not session or type(mod) ~= "table" then return end
    local id = mod.creatureId or (type(mod.combatInfo) == "table" and mod.combatInfo.mob)
    local key = type(id) == "number" and NPCS[id]
    if key then backupKill(key) end
  end)
end)

RTH.On("COMBAT_LOG_EVENT_UNFILTERED", function(_, event, srcGUID, _, _, dstGUID, dstName, dstFlags)
  if not session then return end
  if event == "UNIT_DIED" then
    -- a group member died
    if dstName and bit.band(dstFlags or 0, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 and (UnitInRaid(dstName) or UnitInParty(dstName) or dstName == RTH.PlayerName()) then
      session.deaths[dstName] = (session.deaths[dstName] or 0) + 1
      session.totalDeaths = session.totalDeaths + 1
    else
      -- a boss whose fight ends with its death (backup kill detection)
      local npc = npcFromGUID(dstGUID)
      local key = npc and DEATH_NPC[npc]
      if key then bossDied(key, npc) end
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
  -- (2026-11-28, like DBM's checkWipe) keep waiting while anyone in the group still fights: you dying early in a long
  -- fight leaves combat for YOU only - it used to give up after 30 s and count a wipe the raid went on to kill.
  -- (A safety stop after 15 min, for someone stuck "in combat".)
  if groupInCombat() and tries < 450 then
    RTH.After("endPull", 2, function() endPull(tries + 1) end)
    return
  end
  local key = pull
  pull = nil
  scanStats(not RTH.Active())
  if not RTH.Active() then return end   -- switched off mid-raid: no wipe counted
  -- killed? logged in the last minute (statistic or backup), or the boss was seen dying (the backup logs it soon)
  if recentOwnKill(key, 60) or (deadAt[key] and time() - deadAt[key] < 120) then return end
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

-- someone behind (user rule 2026-11-28, "keep it simple"): in a raid or dungeon of a newer phase than someone in
-- the group has finished, tell everyone who is behind and that their gate comes first. Only a message (once per
-- visit and person): no rule break, no mark on the kills - each character opens its next phase through its own gate.
local function catchUpWarning(st)
  if not (RTH.Active() and (st.type == "raid" or st.type == "party") and st.phase) then return end
  local visit = currentVisit(st)
  local me = RTH.PlayerName()
  for _, n in ipairs((rosterSnapshot())) do
    local q, h, need = RTH.CatchUpOf(n)
    if q and st.phase > q and not visit.logged["catchup:" .. n] then
      visit.logged["catchup:" .. n] = true
      RTH.Print("|cffffd040" .. (n == me and "you are" or (n .. " is")) .. " behind:|r " .. RTH.CatchUpText(q, h, need)
        .. " - finish " .. (n == me and "your" or "their") .. " gate first before going on with " .. tostring(st.name) .. ".")
    end
  end
end
-- someone joins the group inside, or their gate report arrives a moment later
local function catchUpLater()
  RTH.After("catchUp", 3, function()
    local st = RTH.InstanceState()
    if st.type == "raid" or st.type == "party" then catchUpWarning(st) end
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
  -- A rule break only for content NOBODY in the guild has opened yet (the guild's furthest phase). Being behind -
  -- the guild has it open, you haven't finished your earlier gate - is only the group message (catchUpWarning),
  -- user rule 2026-11-28 "keep it simple".
  local open = RTH.GetPhase()
  local visit = (st.type == "raid" or st.type == "party") and currentVisit(st)
  local function opensText(p)
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
    if st.phase and st.phase > open and st.map ~= RTH.VOA_MAP then   -- (by map ID: any game language)
      once("entered " .. st.name .. " " .. opensText(st.phase))
    end
    catchUpWarning(st)
    heirloomWarning(visit)
  elseif st.type == "party" then
    if session then endSession() end   -- straight from a raid into a dungeon
    heirloomWarning(visit)
    -- (heroic dungeons: no "clear it on normal first" rule any more - guild master 2026-11-19)
    if st.phase and st.phase > open then
      once("entered " .. st.name .. " " .. opensText(st.phase))
    end
    catchUpWarning(st)
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
    -- (only what nobody in the guild has opened yet: being behind is just the group message - 2026-11-28)
    if d.phase > RTH.GetPhase() then
      RTH.Alert(name .. " opens in " .. RTH.PhaseLabel(d.phase) .. " - decline it: going in is a rule break")
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
  -- (the guild's furthest phase, like entering: being behind isn't a rule break - 2026-11-28)
  if d and d.phase > RTH.GetPhase() then return d.phase end
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
    -- (the guild's furthest phase, like entering and the list: being behind isn't a rule break - 2026-11-28)
    if d.phase > RTH.GetPhase() then return false end
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

-- ---------------------------------------------------------------- warnings BEFORE a mistake (user 2026-11-28)
-- "pop ups when a player is about to break something, but not too many - just when it matters". Each one is shown
-- once per situation and says nothing when all is fine.

-- "Bob (not in the guild), Ann (no RTH, not on the core list)": why each one counts as outside the group
local function outsiderText(list)
  local out = {}
  for _, n in ipairs(list) do
    out[#out + 1] = n .. (RTH.IsGuildMember(n) and " (in the guild, but no RTH and not on the core list)" or " (not in the guild)")
  end
  return table.concat(out, ", ")
end

-- 1. Ready check in a raid: everything that would put a mark on the next boss kill (the same checks recordKill uses)
RTH.On("READY_CHECK", function()
  if not RTH.Active() or GetNumRaidMembers() == 0 then return end
  local st = RTH.InstanceState()
  if st.type ~= "raid" then return end
  local names, _, outsiders = rosterSnapshot()
  local why = {}
  if st.is25 then why[#why + 1] = "the raid is set to 25 players" end
  if #names > 10 then why[#why + 1] = #names .. " players in the raid (10 at most)" end
  if outsiders[1] then why[#why + 1] = "not in the group: " .. outsiderText(outsiders) end
  for _, s in ipairs(raidGearBreaks()) do why[#why + 1] = s end
  local heir = RTH.WornHeirlooms()
  if heir[1] then why[#why + 1] = "you're wearing an heirloom at level 80: " .. heir[1] end
  local done = sessionBreaks()
  if done[1] then why[#why + 1] = "already tonight (marks every kill): " .. done[1] .. (done[2] and (" (+" .. (#done - 1) .. " more)") or "") end
  if not why[1] then return end
  RTH.Alert("the next boss kill will be marked: " .. why[1] .. (why[2] and (" (+" .. (#why - 1) .. " more, see chat)") or ""))
  for i = 2, #why do RTH.Print("  - " .. why[i]) end
end)

-- 2. Someone joins the raid who would mark every kill: a player outside the group, or an 11th player. Once per name
-- (and once per going over 10) while you stay in the raid. Waits for the game's guild list after a login / reload:
-- before it arrives every guild member without RTH would look like an outsider.
local warnedOut, warnedBig = {}, false
local function groupWarn()
  if GetNumRaidMembers() == 0 then warnedOut, warnedBig = {}, false; return end
  if not RTH.Active() then return end
  if IsInGuild() and RTH.GuildRosterKnown and not RTH.GuildRosterKnown() then
    RTH.After("groupWarn", 5, groupWarn); return
  end
  local names, _, outsiders = rosterSnapshot()
  local new = {}
  for _, n in ipairs(outsiders) do
    if not warnedOut[n] then warnedOut[n] = true; new[#new + 1] = n end
  end
  if new[1] then
    RTH.Alert("not in the group: " .. outsiderText(new) .. " - boss kills with "
      .. (new[2] and "them" or "this player") .. " in the raid get marked")
  end
  if #names > 10 then
    if not warnedBig then
      warnedBig = true
      RTH.Alert(#names .. " players in the raid - Road to Halion is 10-man: boss kills with more get marked")
    end
  else
    warnedBig = false
  end
end
RTH.On("RAID_ROSTER_UPDATE", function() RTH.After("groupWarn", 2, groupWarn) end)

-- 3. Walking up to the entrance of a raid nobody in the guild has opened yet (entering is the rule break, so after
-- zoning in is too late). Entrances: Map.dbc's ghost entrance (corpse X/Y) turned into zone map positions with
-- WorldMapArea.dbc (area = GetCurrentMapAreaID(), which is the DBC's ID + 1 - the default UI's Wintergrasp is 502,
-- the DBC's 501; w/h = the zone's size in yards). Checked every 2 s, only while
-- in one of these three zones; once per entrance until you leave the zone. (Naxx, OS, EoE and the Vault are open
-- from the start; the Ruby Sanctum's portal sits next to OS in Wyrmrest Temple, so a warning there would go off on
-- every OS run - entering it is still logged.)
local ENTRANCES = {
  { area = 496, w = 7112.5, h = 4741.7, x = 0.4157, y = 0.1768, map = 603 },   -- Ulduar (The Storm Peaks)
  { area = 493, w = 6270.9, h = 4181.3, x = 0.7507, y = 0.2181, map = 649 },   -- Trial of the Crusader (Icecrown)
  { area = 493, w = 6270.9, h = 4181.3, x = 0.5387, y = 0.8730, map = 631 },   -- Icecrown Citadel (Icecrown)
  { area = 142, w = 5250.0, h = 3500.0, x = 0.5290, y = 0.7771, map = 249 },   -- Onyxia's Lair (Dustwallow Marsh)
}
local NEAR = 60   -- yards (the Argent Tournament grounds are close to the Trial's door)
local entranceArea, warnedDoor = nil, {}
local function mapShown() return WorldMapFrame and WorldMapFrame:IsShown() end
local function checkEntrance()
  if not entranceArea or not RTH.Active() then return end
  RTH.After("entrance", 2, checkEntrance)
  if IsInInstance and IsInInstance() then return end
  if GetCurrentMapAreaID() ~= entranceArea then   -- someone moved the world map elsewhere
    if mapShown() then return end
    SetMapToCurrentZone()
    if GetCurrentMapAreaID() ~= entranceArea then return end
  end
  local px, py = GetPlayerMapPosition("player")
  if not px or (px == 0 and py == 0) then return end
  for i, e in ipairs(ENTRANCES) do
    if e.area == entranceArea and not warnedDoor[i] then
      local dx, dy = (px - e.x) * e.w, (py - e.y) * e.h
      local en = RTH.RAID_MAPS[e.map]
      local p = RTH.RAIDS[en]
      if dx * dx + dy * dy <= NEAR * NEAR and p and p > RTH.GetPhase() then
        warnedDoor[i] = true
        local name = RTH.RaidDisplayName and RTH.RaidDisplayName(en) or en
        RTH.Alert(name .. " opens in " .. RTH.PhaseLabel(p) .. " - don't go in: entering it is a rule break",
          name .. " opens in " .. RTH.PhaseLabel(p) .. ".\n\nDon't go in - entering it is a rule break for you (and a mark on the group's kills).")
      end
    end
  end
end
local function zoneForEntrances()
  if not (GetCurrentMapAreaID and SetMapToCurrentZone and GetPlayerMapPosition) then return end
  if mapShown() then RTH.After("entranceZone", 5, zoneForEntrances); return end   -- it may show another zone
  SetMapToCurrentZone()
  local area = GetCurrentMapAreaID()
  local known = false
  for _, e in ipairs(ENTRANCES) do if e.area == area then known = true end end
  if area ~= entranceArea then warnedDoor = {} end   -- left the zone: warn again next time
  if known then
    local start = not entranceArea
    entranceArea = area
    if start then RTH.After("entrance", 2, checkEntrance) end
  else
    entranceArea = nil   -- the loop stops by itself
  end
end
RTH.On("ZONE_CHANGED_NEW_AREA", function() RTH.After("entranceZone", 1, zoneForEntrances) end)
RTH.Listen("LOGIN", function() RTH.After("entranceZone", 5, zoneForEntrances) end)

-- 4. An old RTH in the raid (user 2026-11-28): an old copy can miss rules the newer ones check. Compared with the
-- newest version anyone in the raid runs (synced "V"; heard in the last 14 days): the ones behind are named, once
-- per name and version while you stay in the raid; if it's YOU, a popup (only you can fix it).
local verTold = {}
local function versionWarn()
  if GetNumRaidMembers() == 0 then verTold = {}; return end
  if not (RTH.Active() and RTH.VersionNewer) then return end
  local me, best, list = RTH.PlayerName(), RTH.VERSION, {}
  for _, n in ipairs((rosterSnapshot())) do
    local m = n ~= me and RTH.db.group.members[n]
    local v = m and m.version
    if type(v) == "string" and v:match("^%d+[%.%d]*$") and type(m.seen) == "number" and time() - m.seen < 14 * 86400 then
      list[#list + 1] = { n = n, v = v }
      if RTH.VersionNewer(v, best) then best = v end
    end
  end
  local old = {}
  for _, e in ipairs(list) do
    if RTH.VersionNewer(best, e.v) and not verTold[e.n .. "|" .. e.v] then
      verTold[e.n .. "|" .. e.v] = true
      old[#old + 1] = e.n .. " (" .. e.v .. ")"
    end
  end
  if RTH.VersionNewer(best, RTH.VERSION) and not verTold["|me|" .. best] then
    verTold["|me|" .. best] = true
    RTH.Alert("your Road to Halion is out of date (" .. RTH.VERSION .. ", the raid has " .. best .. ") - update it",
      "Your Road to Halion is out of date: you have " .. RTH.VERSION .. ", others in the raid have " .. best
      .. ".\n\nAn old copy can miss rules. Update it (log out, replace the RTH folder) before the first boss.")
  end
  if old[1] then
    RTH.Alert("old Road to Halion in the raid: " .. table.concat(old, ", ") .. " - the newest is " .. best
      .. ": ask them to update (an old copy can miss rules)")
  end
end
RTH.On("RAID_ROSTER_UPDATE", function() RTH.After("verWarn", 5, versionWarn) end)
RTH.Listen("MEMBERS_CHANGED", function()   -- a version report arrived
  if GetNumRaidMembers() > 0 then RTH.After("verWarn", 5, versionWarn) end
end)
