-- Road to Halion: core (saved data, events, timers, roster, phases and unlock gates)
RTH = RTH or {}
local RTH = RTH

RTH.VERSION = (GetAddOnMetadata and GetAddOnMetadata("RTH", "Version")) or "1.0.0"   -- from RTH.toc: bump it there
RTH.TEX = "Interface\\AddOns\\RTH\\Textures\\"
RTH.MAX_PHASE = 5
-- gear (item phase, enchants, gems, crafted-by) is judged from this level on (user rule 2026-11-18):
-- leveling characters in old or heirloom gear aren't "not legal". Gold, AH and consumable rules count at every level.
RTH.GEAR_LEVEL = 80
function RTH.GearCounts(unit)   -- unknown level (-1 = "??", 0 = not known yet) counts as max level
  local l = UnitLevel(unit or "player")
  return not (l and l > 0 and l < RTH.GEAR_LEVEL)
end
RTH.PHASE_NAMES = { "Naxx", "Ulduar", "Trial", "ICC", "Ruby Sanctum" }
RTH.PHASE_LONG = { "Naxxramas tier", "Ulduar", "Trial of the Crusader", "Icecrown Citadel", "Ruby Sanctum" }
RTH.PHASE_PATCH = { "3.0", "3.1", "3.2", "3.3", "3.3.5" }

-- Data files added to the .toc after the game started are NOT loaded by /reload (WoW reads the file list
-- only at startup). Keep working without them, and say a full restart is needed.
if RTH_RecipeItems == nil or RTH_ProfCooldowns == nil or RTH_CraftGather == nil or RTH_UseItems == nil then
  RTH_RecipeItems, RTH_ProfCooldowns = RTH_RecipeItems or {}, RTH_ProfCooldowns or {}
  RTH_CraftGather, RTH_UseItems, RTH_UseSpell = RTH_CraftGather or {}, RTH_UseItems or {}, RTH_UseSpell or {}
  RTH.needsRestart = true
end

-- raid instances by their (enUS) instance name -> phase they open in. Vault of Archavon is open in every
-- phase, but only one boss per phase is allowed (checked on kill).
RTH.RAIDS = {
  ["Naxxramas"] = 1, ["The Obsidian Sanctum"] = 1, ["The Eye of Eternity"] = 1,
  ["Ulduar"] = 2, ["Trial of the Crusader"] = 3, ["Onyxia's Lair"] = 3,
  ["Icecrown Citadel"] = 4, ["The Ruby Sanctum"] = 5, ["Vault of Archavon"] = 1,
}

-- ---------------------------------------------------------------- instances on any game language (2026-11-22)
-- The game hands out instance names in the client's language (GetInstanceInfo, raid lockouts, the Dungeon Finder),
-- and 3.3.5 has no instance ID in those APIs. RTH's own names are English. So every instance also carries its
-- language-free map ID (Map.dbc) and its Dungeon Finder IDs (LFGDungeons.dbc, checked in the 3.3.5 data):
-- GetLFGDungeonInfo(id) gives the name in the player's language, and those names point back to the map ID.
-- (Even in English the two differ: "The Ruby Sanctum" is "Ruby Sanctum" in the Dungeon Finder - so a name that
-- contains the other counts too.)
RTH.RAID_MAPS = {
  [533] = "Naxxramas", [615] = "The Obsidian Sanctum", [616] = "The Eye of Eternity", [603] = "Ulduar",
  [649] = "Trial of the Crusader", [249] = "Onyxia's Lair", [631] = "Icecrown Citadel", [724] = "The Ruby Sanctum",
  [624] = "Vault of Archavon",
}
RTH.VOA_MAP = 624
RTH.INSTANCE_LFG = {   -- map ID -> its Dungeon Finder IDs (normal, heroic; raids 10 / 25)
  [574] = { 202, 242 }, [575] = { 203, 205 }, [576] = { 225, 226 }, [578] = { 206, 211 }, [595] = { 209, 210 },
  [599] = { 208, 213 }, [600] = { 214, 215 }, [601] = { 204, 241 }, [602] = { 207, 212 }, [604] = { 216, 217 },
  [608] = { 220, 221 }, [619] = { 218, 219 }, [632] = { 251, 252 }, [650] = { 245, 249 }, [658] = { 253, 254 },
  [668] = { 255, 256 },
  [533] = { 159, 227 }, [615] = { 224, 238 }, [616] = { 223, 237 }, [603] = { 243, 244 }, [649] = { 246, 247, 248, 250 },
  [249] = { 46, 257 }, [631] = { 279, 280 }, [724] = { 293, 294 }, [624] = { 239, 240 },
}
RTH.LFG_TO_MAP = {}
for mapID, ids in pairs(RTH.INSTANCE_LFG) do for _, id in ipairs(ids) do RTH.LFG_TO_MAP[id] = mapID end end
local nameIndex   -- lower-case name -> map ID (English + the client's own language), built on first use
local function normName(s) return (tostring(s or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")) end
local function buildNameIndex()
  nameIndex = {}
  for mapID, name in pairs(RTH.RAID_MAPS) do nameIndex[normName(name)] = mapID end
  for mapID, d in pairs(RTH_Dungeons or {}) do nameIndex[normName(d.name)] = mapID end
  if GetLFGDungeonInfo then
    for mapID, ids in pairs(RTH.INSTANCE_LFG) do
      for _, id in ipairs(ids) do
        local n = GetLFGDungeonInfo(id)
        if type(n) == "string" and n ~= "" then nameIndex[normName(n)] = mapID end
      end
    end
  end
end
function RTH.ResetInstanceNames() nameIndex = nil end   -- (on PLAYER_ENTERING_WORLD, below: the game's data is in)
-- the map ID of an instance name in any language (nil = not one RTH knows)
function RTH.InstanceMap(name)
  if type(name) ~= "string" or name == "" then return nil end
  if not nameIndex then buildNameIndex() end
  local n = normName(name)
  if nameIndex[n] then return nameIndex[n] end
  local best, bestLen
  for k, mapID in pairs(nameIndex) do
    if #k >= 5 and #n >= 5 and (n:find(k, 1, true) or k:find(n, 1, true)) and (not bestLen or #k > bestLen) then
      best, bestLen = mapID, #k
    end
  end
  return best
end
-- a raid's phase by its name in any language -> phase, map ID, RTH's English name
function RTH.RaidByName(name)
  local mapID = RTH.InstanceMap(name)
  local en = mapID and RTH.RAID_MAPS[mapID]
  return en and RTH.RAIDS[en], mapID, en
end
-- an English raid name in the player's language (the Dungeon Finder's), for text shown to them
function RTH.RaidDisplayName(en)
  for mapID, name in pairs(RTH.RAID_MAPS) do
    if name == en then
      local id = RTH.INSTANCE_LFG[mapID] and RTH.INSTANCE_LFG[mapID][1]
      local n = id and GetLFGDungeonInfo and GetLFGDungeonInfo(id)
      if type(n) == "string" and n ~= "" and GetLocale and GetLocale():sub(1, 2) ~= "en" then return n end
    end
  end
  return en
end

local function print_(msg) DEFAULT_CHAT_FRAME:AddMessage("|cffd9a441Road to Halion:|r " .. tostring(msg)) end
RTH.Print = print_

function RTH.PhaseLabel(p)
  return "Phase " .. p .. " (" .. (RTH.PHASE_NAMES[p] or "?") .. ")"
end

-- a warning that matters (a rule break is one step away): red chat line, the raid-warning text in the middle of
-- the screen and its sound; popup = also a box that stays until OK (the text it shows). Callers show each one once.
function RTH.Alert(text, popup)
  print_("|cffff4040" .. text .. "|r")
  if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
    RaidNotice_AddMessage(RaidWarningFrame, "Road to Halion: " .. text, ChatTypeInfo["RAID_WARNING"])
  end
  if PlaySound then PlaySound("RaidWarning") end
  if popup and StaticPopup_Show then
    StaticPopupDialogs.RTH_WARN = StaticPopupDialogs.RTH_WARN or {
      text = "|cffd9a441Road to Halion|r\n\n%s", button1 = OKAY or "OK", timeout = 0, whileDead = 1, hideOnEscape = 1, showAlert = 1,
    }
    StaticPopup_Show("RTH_WARN", popup)
  end
end

-- ---------------------------------------------------------------- events
local eventFrame = CreateFrame("Frame")
local handlers = {}
function RTH.On(event, fn)
  if not handlers[event] then
    handlers[event] = {}
    eventFrame:RegisterEvent(event)
  end
  table.insert(handlers[event], fn)
end
eventFrame:SetScript("OnEvent", function(_, event, ...)
  local list = handlers[event]
  if not list then return end
  for i = 1, #list do
    local ok, err = pcall(list[i], ...)
    if not ok then print_("|cffff4040error in " .. event .. ":|r " .. tostring(err)) end
  end
end)

-- Hooks into Blizzard's or other addons' code must never throw: an error there would also break THEIR
-- code (a bag that stops updating, a tooltip addon after us...). RTH.Hook / RTH.HookScript catch it and
-- report it once per hook (the tooltip one runs every frame).
local function safe(fn, where)
  local told = false
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok and not told then
      told = true
      print_("|cffff4040error in " .. tostring(where) .. " (RTH):|r " .. tostring(err))
    end
  end
end
function RTH.Hook(a, b, c)   -- same arguments as hooksecurefunc: (name, fn) or (table, name, fn)
  if c then hooksecurefunc(a, b, safe(c, b)) else hooksecurefunc(a, safe(b, a)) end
end
function RTH.HookScript(frame, script, fn)
  frame:HookScript(script, safe(fn, (frame.GetName and frame:GetName() or "frame") .. " " .. script))
end

-- internal messages between modules (RTH.Fire("PHASE_CHANGED"))
local listeners = {}
function RTH.Listen(msg, fn)
  listeners[msg] = listeners[msg] or {}
  table.insert(listeners[msg], fn)
end
function RTH.Fire(msg, ...)
  local list = listeners[msg]
  if not list then return end
  for i = 1, #list do
    local ok, err = pcall(list[i], ...)
    if not ok then print_("|cffff4040error in " .. msg .. ":|r " .. tostring(err)) end
  end
end

-- ---------------------------------------------------------------- timers (3.3.5 has no C_Timer)
-- One pending run per key: a newer request replaces the older one (never piles up).
local timerFrame = CreateFrame("Frame")
local timers = {}
local due = {}
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function()
  local now = GetTime()
  -- collect first, run after: a callback may start new timers, which must not change the table mid-loop
  for key, t in pairs(timers) do
    if now >= t.at then due[#due + 1] = key end
  end
  for i = 1, #due do
    local key = due[i]
    local t = timers[key]
    due[i] = nil
    if t and now >= t.at then
      timers[key] = nil
      local ok, err = pcall(t.fn)
      if not ok then print_("|cffff4040timer error:|r " .. tostring(err)) end
    end
  end
  if not next(timers) then timerFrame:Hide() end
end)
function RTH.After(key, delay, fn)
  timers[key] = { at = GetTime() + delay, fn = fn }
  timerFrame:Show()
end

-- ---------------------------------------------------------------- saved data
local function defaultGates()
  local g = {}
  for p = 1, RTH.MAX_PHASE do
    local ph = RTH_Phases[p]
    local ids = {}
    for _, id in ipairs(ph.required or {}) do table.insert(ids, id) end
    g[p] = { ids = ids, opt = ph.gateIncludesOptional and true or false }
  end
  return g
end
RTH.DefaultGates = defaultGates

-- Saved data is checked by shape, not only "is it there": an old version, a crash while saving or a
-- hand edit can leave a wrong type anywhere, and one bad value must not break every screen.
local function tbl(v) return type(v) == "table" and v or {} end
local function records(v, need)   -- keep only whole records (each field in need has its type), in order
  local out = {}
  if type(v) == "table" then
    for _, e in ipairs(v) do
      local ok = type(e) == "table"
      for field, kind in pairs(ok and need or {}) do
        if type(e[field]) ~= kind then ok = false; break end
      end
      if ok then out[#out + 1] = e end
    end
  end
  return out
end
local KILL = { key = "string", name = "string", d = "string", t = "number" }
local BREAK = { who = "string", text = "string", d = "string", t = "number" }
local function map(v, keyType, valType)   -- keep only key -> value pairs of the right types
  local out = {}
  if type(v) == "table" then
    for k, x in pairs(v) do
      if type(k) == keyType and type(x) == valType and x == x then out[k] = x end
    end
  end
  return out
end
local MEMBER_TABLES = { "recipes", "profs", "profMax", "recipeSkill", "cooldowns", "tradeLinks", "lockouts",
                        "lockParts", "gearList", "gate", "behind", "passes" }

-- Saved-data version. 1.0.0 (the test builds) saved version 1: 1.1.0 starts the shared data fresh ONCE, so test
-- kills, test rule breaks and old rules never reach the real challenge's log (nobody has to delete files).
-- Kept: display settings (minimap, red marks) and each character's own data (professions, recipes, Yes/No).
-- Raise DATA_VERSION only for another deliberate fresh start.
local DATA_VERSION = 2
local function initDB()
  if type(RTH_DB) ~= "table" then RTH_DB = {} end
  if type(RTH_DB.version) == "number" and RTH_DB.version < DATA_VERSION then
    RTH_DB = { ui = type(RTH_DB.ui) == "table" and RTH_DB.ui or nil }
    RTH.freshStart = true   -- told in chat at login
  end
  local db = RTH_DB
  db.version = DATA_VERSION
  db.group = tbl(db.group)
  local g = db.group
  if not (type(g.phase) == "number" and g.phase >= 1 and g.phase <= RTH.MAX_PHASE and g.phase == math.floor(g.phase)) then
    g.phase = 1   -- missing or damaged
  end
  -- every phase needs a gate: a missing or broken one goes back to the default
  local gates, default = tbl(g.gates), defaultGates()
  for p = 1, RTH.MAX_PHASE do
    local gp = gates[p]
    if type(gp) == "table" and type(gp.ids) == "table" then
      local ids = {}
      for _, id in ipairs(gp.ids) do if type(id) == "number" then ids[#ids + 1] = id end end
      gates[p] = { ids = ids, opt = gp.opt == true }
    else
      gates[p] = default[p]
    end
  end
  g.gates = gates
  g.roster = tbl(g.roster)
  local names = {}
  for _, n in ipairs(tbl(g.roster.names)) do if type(n) == "string" and n ~= "" then names[#names + 1] = n end end
  g.roster.names = names
  if type(g.roster.rank) ~= "number" then g.roster.rank = nil end
  g.kills = records(g.kills, KILL)
  g.breaks = records(g.breaks, BREAK)
  for _, list in ipairs({ g.kills, g.breaks }) do   -- rt (when it reached this log) is compared: numbers only
    for _, e in ipairs(list) do if e.rt ~= nil and type(e.rt) ~= "number" then e.rt = nil end end
  end
  -- the guild master's comment on a break (Sync.lua RTH.SetBreakNote): note text, noteT = when, noteBy = who
  for _, b in ipairs(g.breaks) do
    if b.note ~= nil and (type(b.note) ~= "string" or b.note == "") then b.note = nil end
    if b.noteT ~= nil and type(b.noteT) ~= "number" then b.noteT = nil end
    if b.noteBy ~= nil and type(b.noteBy) ~= "string" then b.noteBy = nil end
  end
  -- rule breaks the guild master deleted (Sync.lua RTH.DeleteBreak, 2026-11-22): kept so an old copy coming back
  -- through a catch-up or the relay can't bring one back. { t, who, key, delT, by }; dropped after 90 days.
  local deleted = {}
  for _, d in ipairs(tbl(g.deleted)) do
    if type(d) == "table" and type(d.t) == "number" and type(d.who) == "string" and type(d.key) == "string"
      and type(d.delT) == "number" and time() - d.delT < 90 * 86400 then
      deleted[#deleted + 1] = { t = d.t, who = d.who, key = d.key, delT = d.delT, by = type(d.by) == "string" and d.by or nil }
    end
  end
  g.deleted = deleted
  g.wipes = map(g.wipes, "string", "number")   -- boss key (+ "H") -> wipes since the last kill
  g.phaseLog = map(g.phaseLog, "number", "string")
  if not next(g.phaseLog) then g.phaseLog[1] = date("%Y-%m-%d") end
  if type(g.started) ~= "string" then g.started = date("%Y-%m-%d") end
  -- 1.4.0: the guild master's phase when this account first ran 1.4 (characters that had done those gates the
  -- old way keep them - see migrateOldPhase); nil on a fresh install = nothing to carry over
  if g.oldPhase14 == nil then g.oldPhase14 = g.phase end
  if type(g.oldPhase14) ~= "number" then g.oldPhase14 = 1 end
  if type(g.logSyncT) ~= "number" then g.logSyncT = nil end   -- last journey log catch-up from the GM (GM's clock)
  if type(g.keeperSeenT) ~= "number" then g.keeperSeenT = nil end   -- the GM's RTH: when it last ran (Sync.lua)
  if type(g.logPeerT) ~= "number" then g.logPeerT = nil end   -- last journey log catch-up from a member (relay, our clock)
  if g.delSync ~= true then g.delSync = nil end   -- had the full list of the guild master's deletes (Sync.lua AskLog)
  g.gateSynced = map(g.gateSynced, "number", "boolean")   -- phase -> we have the guild master's gate (Sync.lua)
  -- 2026-11-22: a member's copy of the guild master's rules (Sync.lua "u"), until the guild master's own arrive
  g.gateRelayed = map(g.gateRelayed, "number", "string")   -- phase -> who passed the copy on
  if g.rosterSynced ~= true then g.rosterSynced = nil end   -- we have the guild master's own core list
  if type(g.rosterRelayed) ~= "string" then g.rosterRelayed = nil end
  local members = {}
  for name, m in pairs(tbl(g.members)) do
    if type(name) == "string" and type(m) == "table" then
      for _, key in ipairs(MEMBER_TABLES) do
        if m[key] ~= nil and type(m[key]) ~= "table" then m[key] = nil end
      end
      m.recipes, m.profs = m.recipes or {}, m.profs or {}
      if m.behind and (type(m.behind.phase) ~= "number" or type(m.behind.have) ~= "number" or type(m.behind.need) ~= "number") then
        m.behind = nil   -- catching-up report (1.3.3): compared as numbers
      end
      if m.gate and (type(m.gate.have) ~= "number" or type(m.gate.need) ~= "number") then m.gate = nil end
      if m.passes then m.passes = map(m.passes, "number", "boolean") end   -- 1.4.0: gates they've finished
      for _, key in ipairs({ "seen", "statusT", "gearListT", "off", "level", "phase" }) do   -- numbers (times; level; phase)
        if m[key] ~= nil and type(m[key]) ~= "number" then m[key] = nil end
      end
      -- lists of records (Raid Check reads their fields): drop entries that aren't records, keep the indexes
      for _, key in ipairs({ "gearList", "lockouts" }) do
        for i, e in pairs(m[key] or {}) do if type(e) ~= "table" then m[key][i] = nil end end
      end
      members[name] = m
    end
  end
  g.members = members
  -- name -> class file ("PALADIN"), remembered for good so names stay class coloured when the player isn't in
  -- the group or the guild list (left the guild, offline before the list loads, an old log entry)
  db.classes = tbl(db.classes)
  for n, c in pairs(db.classes) do
    if type(n) ~= "string" or type(c) ~= "string" or not (RAID_CLASS_COLORS and RAID_CLASS_COLORS[c]) then db.classes[n] = nil end
  end
  db.ui = tbl(db.ui)
  local ui = db.ui
  if type(ui.minimap) ~= "boolean" then ui.minimap = true end
  if type(ui.overlays) ~= "boolean" then ui.overlays = true end
  if type(ui.minimapAngle) ~= "number" or ui.minimapAngle ~= ui.minimapAngle then ui.minimapAngle = 200 end
  if type(ui.scale) ~= "number" or not (ui.scale >= 0.7 and ui.scale <= 1.3) then ui.scale = nil end   -- window size (Ctrl+wheel)
  local cs = ui.copySize   -- Copy for Discord box size { w, h } (its grip): 340x200 .. 900x700
  if type(cs) ~= "table" or type(cs[1]) ~= "number" or type(cs[2]) ~= "number" or not (cs[1] >= 340 and cs[1] <= 900
    and cs[2] >= 200 and cs[2] <= 700) then ui.copySize = nil end

  if type(RTH_CharDB) ~= "table" then RTH_CharDB = {} end
  local c = RTH_CharDB
  if type(c.inChallenge) ~= "boolean" then c.inChallenge = nil end   -- nil = not answered yet (asked at login)
  c.stats = map(c.stats, "number", "number")
  c.recipes = map(c.recipes, "number", "table")          -- skill line -> { spell = true }
  c.profs = map(c.profs, "number", "number")
  c.profMax = map(c.profMax, "number", "number")         -- skill line -> max rank (training tier: 75/150/.../450)
  c.cooldowns = map(c.cooldowns, "string", "number")     -- cooldown name (RTH_ProfCooldowns) -> time() it is ready again
  c.rep = map(c.rep, "string", "number")   -- faction name -> standing (Rules.lua ScanReputation: reputation enchants)
  -- 1.4.0 personal phases: the gates this character has finished (phase -> { d = date, how = "gate" / "by Name" })
  -- and what RTH saw when a gate achievement / VoA kill happened ("a576" / "v1" -> { t, ok, why })
  local passed = {}
  for q, e in pairs(tbl(c.passed)) do
    if type(q) == "number" and type(e) == "table" and type(e.d) == "string" then
      -- sig: the gate's fingerprint when it was passed - only a REAL change of that gate re-checks it
      passed[q] = { d = e.d, how = tostring(e.how or "gate"), sig = type(e.sig) == "string" and e.sig or nil }
    end
  end
  c.passed = passed
  local legitT = {}
  for k, e in pairs(tbl(c.legit)) do
    if type(k) == "string" and type(e) == "table" and type(e.t) == "number" then
      legitT[k] = { t = e.t, ok = e.ok == true, why = type(e.why) == "string" and e.why or nil }
    end
  end
  c.legit = legitT
  -- the newest phase of gear this character has worn at level 80 (a gate stays editable until someone starts the
  -- next phase - wearing its gear counts as starting it)
  if type(c.wornMax) ~= "number" then c.wornMax = nil end
  -- characters that existed before 1.4 may keep gates they finished the old way (once, at the first gate check)
  if c.phase14 ~= "todo" and c.phase14 ~= "done" then
    c.phase14 = (c.statsSeeded == true and c.inChallenge == true) and "todo" or "done"
  end
  if c.repScanned ~= true then c.repScanned = nil end
  c.tradeLinks = map(c.tradeLinks, "number", "string")   -- skill line -> "trade:..." link body (no |H, so it fits a message)
  if c.bank ~= nil then c.bank = map(c.bank, "number", "number") end
  if c.lockBreaks ~= nil then c.lockBreaks = map(c.lockBreaks, "number", "boolean") end
  if c.lockouts ~= nil then c.lockouts = records(c.lockouts) end
  if c.ahBids ~= nil then   -- AH bids waiting for an "auction won" mail (Rules.lua)
    local bids = {}
    for name, b in pairs(tbl(c.ahBids)) do
      if type(name) == "string" and type(b) == "table" and type(b.t) == "number" and type(b.reason) == "string" then bids[name] = b end
    end
    c.ahBids = bids
  end
  -- how the Tome of Cold Weather Flight last reached this character (Rules.lua): bought at 77+ = ok
  local tm = c.tome
  if tm ~= nil and not (type(tm) == "table" and type(tm.ok) == "boolean" and type(tm.t) == "number" and type(tm.why) == "string") then
    c.tome = nil
  end
  -- the raid / dungeon we're in (Progress.lua): kept over a /reload or a disconnect
  local v = c.visit
  if v ~= nil and not (type(v) == "table" and type(v.name) == "string" and type(v.start) == "number"
      and type(v.logged) == "table" and type(v.deaths) == "table" and type(v.kills) == "number"
      and type(v.wipes) == "number" and type(v.totalDeaths) == "number" and type(v.breakStart) == "number") then
    c.visit = nil
  elseif v and v.seen ~= nil then
    v.seen = map(v.seen, "string", "boolean")   -- who was in the raid tonight
  end
  RTH.db, RTH.char = db, c
end

function RTH.Active() return RTH.char ~= nil and RTH.char.inChallenge == true end

-- ---------------------------------------------------------------- is this character in the challenge?
-- The saved challenge data is shared by every character on the account, so each new character is asked once:
-- an alt that isn't doing the challenge must not put kills or rule breaks into the log. Until the question is
-- answered, RTH logs and sends nothing for this character.
function RTH.SetInChallenge(on)
  local was = RTH.Active()
  -- switching on: kills made while it was off are not challenge kills - take the boss counts as they are now
  if on and not was and RTH.ScanStats and RTH.char.statsSeeded then RTH.ScanStats(true) end
  -- switching off: say so while we still may send - the unlock gate then stops waiting for this character
  if was and not on and RTH.Send then RTH.Send("O") end
  RTH.char.inChallenge = on and true or false
  RTH.Fire("OVERLAYS_TOGGLED"); RTH.Fire("PHASE_CHANGED", RTH.GetPhase())
  RTH.Fire("CHALLENGE_TOGGLED")   -- Rules.lua: greyed-out buttons follow at once (a "No" character is never blocked)
  if on and not was and RTH.SayHello then RTH.SayHello() end   -- the group sees this character right away
end
local function askInChallenge()
  if not RTH.char or RTH.char.inChallenge ~= nil then return end
  StaticPopupDialogs.RTH_ASK_CHALLENGE = StaticPopupDialogs.RTH_ASK_CHALLENGE or {
    text = "Is %s doing the Road to Halion challenge?\n\n(You can change this later on the Rules tab.)",
    button1 = YES or "Yes", button2 = NO or "No",
    OnAccept = function()
      RTH.SetInChallenge(true)
      RTH.Print("this character is in the challenge.")
    end,
    OnCancel = function(_, _, reason)
      if reason ~= "clicked" then return end   -- hidden some other way: ask again next login
      RTH.SetInChallenge(false)
      RTH.Print("this character is not in the challenge - nothing is tracked. Rules tab to switch it on.")
    end,
    noCancelOnEscape = 1,   -- Escape = no answer (asked again next login), not "No"
    timeout = 0, whileDead = 1, hideOnEscape = 1,
  }
  StaticPopup_Show("RTH_ASK_CHALLENGE", RTH.PlayerName())
end
function RTH.GetPhase() return (RTH.db and RTH.db.group.phase) or 1 end
function RTH.PlayerName() return (UnitName("player")) end

-- ---------------------------------------------------------------- roster
-- Core names (exact) + an optional guild rank: guild members at that rank or higher count as subs.
local guildRanks, guildLevels, guildOnline = {}, {}, {}
local guildClasses = {}   -- name -> class file ("PALADIN"): colours names of guild members who aren't in our party
local expectJoin = {}   -- names chat (or a hello) says just joined: "joined" once the list has them
local reading = false
local lastShowOffline = -100
local function rebuildGuild()
  if reading then return end   -- switching "show offline" below can fire GUILD_ROSTER_UPDATE again
  if not IsInGuild() then wipe(guildRanks); wipe(guildLevels); wipe(guildOnline); return end
  -- With "Show Offline Members" unticked in the guild window the game lists only ONLINE members: an offline
  -- friend would drop out of the group and the unlock gate. Read the whole list, then put the setting back.
  -- At most once every 10 s: if the switch fires its update a frame later, that read takes the partial-list path
  -- below instead of switching again (no endless loop).
  reading = true
  local hideOffline = GetGuildRosterShowOffline and SetGuildRosterShowOffline and not GetGuildRosterShowOffline()
    and GetTime() - lastShowOffline > 10
  if hideOffline then lastShowOffline = GetTime(); SetGuildRosterShowOffline(true) end
  local ranks, levels, online, total, got = {}, {}, {}, GetNumGuildMembers(true) or 0, 0
  for i = 1, total do
    local name, _, rankIndex, level, className, _, _, _, isOnline, _, classFile = GetGuildRosterInfo(i)
    if name then
      ranks[name] = rankIndex; levels[name] = tonumber(level); online[name] = isOnline and true or false; got = got + 1
      guildClasses[name] = RTH.ClassFile(classFile, className) or guildClasses[name]
      RTH.LearnClass(name, guildClasses[name])
    end
  end
  if hideOffline then SetGuildRosterShowOffline(false) end
  reading = false
  local before = guildRanks
  local joined, left = {}, {}
  if got > 0 and got >= total then
    -- a complete list: it replaces ours; the difference is who joined / left (not on the first list after login)
    if next(before) then
      for n in pairs(ranks) do if not before[n] then joined[#joined + 1] = n end end
      for n in pairs(before) do if not ranks[n] then left[#left + 1] = n end end
    end
    guildRanks, guildLevels, guildOnline = ranks, levels, online
  else
    -- an incomplete list (still loading): only add to ours - never drop anyone, never guess who's new
    for n, r in pairs(ranks) do
      if not before[n] and expectJoin[n] then joined[#joined + 1] = n end
      guildRanks[n] = r; guildLevels[n] = levels[n]; guildOnline[n] = online[n]
    end
  end
  for _, n in ipairs(joined) do expectJoin[n] = nil end
  if joined[1] or left[1] then RTH.Fire("GUILD_MEMBERS_CHANGED", joined, left) end
  RTH.Fire("GUILD_LIST")   -- online / offline, levels (Raid Check's guild view)
end
RTH.On("GUILD_ROSTER_UPDATE", rebuildGuild)
-- "PALADIN" from the guild list's class file, or from its class name ("Paladin") on clients without one
function RTH.ClassFile(classFile, className)
  if type(classFile) == "string" and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then return classFile end
  if type(className) ~= "string" then return nil end
  for _, names in ipairs({ LOCALIZED_CLASS_NAMES_MALE or {}, LOCALIZED_CLASS_NAMES_FEMALE or {} }) do
    for file, n in pairs(names) do if n == className then return file end end
  end
  local up = className:upper():gsub(" ", "")
  if RAID_CLASS_COLORS and RAID_CLASS_COLORS[up] then return up end   -- "Death Knight" -> "DEATHKNIGHT"
end
function RTH.GuildClass(name) return name and guildClasses[name] end
-- online in the guild list: true / false, nil when the list doesn't know them (not in the guild / not loaded)
function RTH.GuildOnline(name) if name then return guildOnline[name] end end
-- a GUILD hello from a name not on our list (Sync.lua): they probably just joined - fetch the list
function RTH.ExpectGuildJoin(name)
  if type(name) ~= "string" or name == "" or guildRanks[name] then return end
  expectJoin[name] = true
  RTH.After("guildNews", 2, function() GuildRoster() end)
end
-- keep the guild list fresh: it decides whose RTH messages count, so a new member must not wait for a relog.
-- Every 2 minutes, and right away when chat says someone joined, left or was removed.
local function pollGuild()
  if IsInGuild() then GuildRoster() end
  RTH.After("guildPoll", 120, pollGuild)
end
RTH.On("PLAYER_LOGIN", function() RTH.After("guildPoll", 120, pollGuild) end)
-- the game's own lines: "%s has joined the guild." / "%s has left the guild." / "%s has been kicked out of the
-- guild by %s." -> patterns that capture the name (the first %s)
local guildNews = {}
for _, g in ipairs({ { "ERR_GUILD_JOIN_S", "join" }, { "ERR_GUILD_LEAVE_S", "leave" }, { "ERR_GUILD_REMOVE_SS", "leave" } }) do
  local s = _G[g[1]]
  if type(s) == "string" and s:find("%s", 1, true) then
    local pat = s:gsub("[%%%(%)%.%[%]%*%+%-%?%^%$]", "%%%0")   -- every magic character literal ("%s" -> "%%s")
    pat = pat:gsub("%%%%s", "(.+)", 1):gsub("%%%%s", ".+")       -- first name captured, any other matched
    guildNews[#guildNews + 1] = { "^" .. pat .. "$", g[2] }
  end
end
RTH.On("CHAT_MSG_SYSTEM", function(text)
  if type(text) ~= "string" or not IsInGuild() then return end
  for _, e in ipairs(guildNews) do
    local name = text:match(e[1])
    if name then
      if e[2] == "join" then
        expectJoin[name] = true
      elseif guildRanks[name] then   -- left / removed: off our list now (a hidden-offline list can't show it)
        guildRanks[name] = nil; guildLevels[name] = nil; guildOnline[name] = nil
        RTH.Fire("GUILD_MEMBERS_CHANGED", {}, { name })
      end
      RTH.After("guildNews", 2, function() GuildRoster() end)
      return
    end
  end
end)
-- a guild member's level from the guild list (also people without RTH); nil when unknown
function RTH.GuildLevel(name)
  local l = name and guildLevels[name]
  return (l and l > 0) and l or nil
end
-- the guild roster's own spelling of a name ("aria" -> "Aria"), or nil when nobody in the guild has it
function RTH.GuildMemberName(name)
  if not name then return nil end
  if guildRanks[name] then return name end
  local low = name:lower()
  for n in pairs(guildRanks) do if n:lower() == low then return n end end
end
function RTH.GuildRosterKnown() return next(guildRanks) ~= nil end

function RTH.IsCore(name)
  if not name then return false end
  for _, n in ipairs(RTH.db.group.roster.names) do
    if n:lower() == name:lower() then return true end
  end
  return false
end
function RTH.IsSub(name)
  local rank = RTH.db.group.roster.rank
  if not rank or not name then return false end
  local r = guildRanks[name]
  return r ~= nil and r <= rank
end
-- Who may change the rules (phase, unlock gates, roster): ONLY the guild master of your guild - never a
-- party/raid leader (user rule 2026-11-18). Without a guild nobody can; the phase then only rises when a
-- player earns the unlock gate himself. Checked on both sides: the Rules tab only lets the guild master
-- edit, and synced rule changes are only accepted from the guild master.
function RTH.IsRulesKeeper(name)
  if not name or not IsInGuild() then return false end
  if name == RTH.PlayerName() then return select(3, GetGuildInfo("player")) == 0 end
  return guildRanks[name] == 0
end
function RTH.IAmRulesKeeper() return RTH.IsRulesKeeper(RTH.PlayerName()) end
-- the guild master's name from the guild list (nil when the list isn't loaded / no guild)
function RTH.GuildMasterName()
  if not IsInGuild() then return nil end
  for n, r in pairs(guildRanks) do if r == 0 then return n end end
end
function RTH.KeeperLabel() return IsInGuild() and "the guild master" or "the guild master (make the guild first)" end

-- "in the group" for every rule: core, sub, the guild master, or yourself (so a solo test still works).
-- The guild master always counts, even when not on the core list: otherwise every member's RTH would treat
-- them as an outsider (their professions, kills, searches and gear ignored; a star on kills they're in).
function RTH.IsGuildMember(name) return name ~= nil and guildRanks[name] ~= nil end
-- a guild member whose RTH reported in the last 14 days: running RTH and in the challenge ("No" alts send nothing;
-- m.off = they switched the challenge off - an "O" message - until their RTH reports again)
local RTH_RECENT = 14 * 86400
function RTH.HasRTH(name)
  local m = name and RTH.db.group.members[name]
  if not (m ~= nil and not m.off and type(m.seen) == "number" and time() - m.seen < RTH_RECENT) then return false end
  if RTH.IsGuildMember(name) then return true end
  -- (2026-11-28) the game's guild list arrives a few seconds after login or a /reload; until then nobody is "in the
  -- guild". Someone whose RTH reported in the last 14 days still counts in that gap - otherwise a boss dying (or a
  -- flask drunk) right after a /reload made every guildmate an outsider: a star on the kill, "nobody in the guild
  -- can make it". Strangers have no such record.
  return IsInGuild() and not RTH.GuildRosterKnown()
end
-- In the group (user rule 2026-11-18): you, the core list, subs, the guild master - and EVERY guild member who runs
-- RTH in the challenge, no core list or party needed. Guild members without RTH count only through the core list.
function RTH.InGroup(name)
  if not name then return false end
  return name == RTH.PlayerName() or RTH.IsCore(name) or RTH.IsSub(name) or RTH.IsRulesKeeper(name) or RTH.HasRTH(name)
end

-- party/raid units, in order
function RTH.GroupUnits()
  local units = {}
  local n = GetNumRaidMembers()
  if n > 0 then
    for i = 1, n do units[#units + 1] = "raid" .. i end
  else
    units[1] = "player"
    for i = 1, GetNumPartyMembers() do units[#units + 1] = "party" .. i end
  end
  return units
end

-- a group member's name as RTH keys it: "Name", or "Name-Realm" for a player from another realm (Dungeon
-- Finder groups) - a stranger from another realm with a core member's name must never count as them
function RTH.UnitKey(unit)
  local name, realm = UnitName(unit)
  if name and realm and realm ~= "" then return name .. "-" .. realm end
  return name
end

-- the group unit ("player", "party2", "raid7"...) of a player by name, or nil when not in the group
function RTH.UnitByName(name)
  if not name then return nil end
  if UnitName("player") == name then return "player" end
  for _, u in ipairs(RTH.GroupUnits()) do
    if RTH.UnitKey(u) == name then return u end
  end
end

-- remember a player's class for good (RTH_DB.classes, account-wide)
function RTH.LearnClass(name, class)
  if type(name) == "string" and name ~= "" and type(class) == "string" and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    and RTH.db and RTH.db.classes then
    RTH.db.classes[name] = class
  end
end

-- a player's class file: our party/raid (the unit), then the guild list, then what RTH remembered before
function RTH.ClassOf(name)
  if type(name) ~= "string" then return nil end
  local u = RTH.UnitByName(name)
  local class = u and select(2, UnitClass(u))
  if class then RTH.LearnClass(name, class); return class end
  class = RTH.GuildClass and RTH.GuildClass(name)
  if class then return class end
  return RTH.db and RTH.db.classes and RTH.db.classes[name]
end

-- name in its class colour (plain only when RTH has never seen that player's class).
-- Every player name on every RTH tab goes through here (user 2026-11-21: "always class colored").
function RTH.ClassColorName(name)
  if type(name) ~= "string" then return name end
  local class = RTH.ClassOf(name)
  local c = class and RAID_CLASS_COLORS[class]
  if not c then return name end
  return string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, name)
end

-- a list of names, each class coloured, joined with sep (", " by default)
function RTH.ClassColorNames(names, sep)
  local out = {}
  for i, n in ipairs(names or {}) do out[i] = RTH.ClassColorName(n) end
  return table.concat(out, sep or ", ")
end

-- ---------------------------------------------------------------- instance info
-- difficulty (3.3.5): raids 1 = 10, 2 = 25, 3 = 10 heroic, 4 = 25 heroic; ICC/RS keep 1/2 and use dynamicDifficulty.
function RTH.InstanceState()
  local name, itype, diff, _, maxPlayers, dynDiff, isDynamic = GetInstanceInfo()
  local s = { name = name, type = itype, inInstance = (itype == "party" or itype == "raid") }
  if itype == "raid" then
    s.is25 = (diff == 2 or diff == 4)
    s.heroic = (diff == 3 or diff == 4) or (isDynamic and dynDiff == 1) or false
    s.phase, s.map = RTH.RaidByName(name)   -- any game language (2026-11-22)
  elseif itype == "party" then
    s.heroic = (diff == 2)
    local map = RTH.InstanceMap(name)
    local d = map and RTH_Dungeons[map]
    if d then s.dungeon = map; s.phase = d.phase end
  end
  return s
end

-- ---------------------------------------------------------------- rule breaks
-- Nothing is hidden: every break is logged with who, when and why; kills in the same raid get a star.
function RTH.AddBreak(who, text, fromSync)
  if not RTH.Active() then return end   -- not in the challenge (an alt): nothing goes into the shared log
  local g = RTH.db.group
  -- the same break from the same person within 10 minutes is one break
  local now = time()
  for i = #g.breaks, math.max(1, #g.breaks - 30), -1 do
    local b = g.breaks[i]
    if b.who == who and now - b.t < 600 and (b.text == text or (RTH.SameBreakText and RTH.SameBreakText(b.text, text))) then return end
  end
  table.insert(g.breaks, { t = now, rt = now, d = date("%Y-%m-%d %H:%M"), who = who, text = text })   -- rt: when it reached THIS log
  print_("|cffff4040rule break|r - " .. who .. ": " .. text)
  if not fromSync and RTH.Send then RTH.Send("B", RTH.BreakForMessage(text)) end
  RTH.Fire("BREAKS_CHANGED")
end

-- ---------------------------------------------------------------- phases and gates
local function statCount(id)
  if not id then return 0 end
  return tonumber(GetStatistic(id)) or 0
end
RTH.StatCount = statCount

local function achDone(id)
  local _, _, _, done = GetAchievementInfo(id)
  return done and true or false
end
RTH.AchDone = achDone

-- Strict gate (user rule 2026-11-19): a gate achievement (or the VoA kill) counts only when this character's own
-- RTH saw it happen at a CLEAN kill - the kill that earned it was logged by RTH (within 3 minutes) and has no
-- marks: no outsiders, not 25-man, no rule breaks or gear problems in the raid that night. (Someone behind in the
-- raid is no mark since 2026-11-28 - only a message to the group.)
-- Earned before RTH, with RTH off, or at a marked kill: it doesn't count, ever (an achievement can't be earned
-- twice) - only the guild master's /rth gate can then pass that gate by hand.
local function legit(key)
  local l = RTH.char and RTH.char.legit[key]
  return l and l.ok or false, l
end

-- items of the gate for phase p: { label, done, earned, why }  (earned: the game says done; done: it COUNTS)
function RTH.GateItems(p)
  local items = {}
  local gate = RTH.db.group.gates[p]
  if not gate then return items end
  local function ach(id, label)
    local earned = achDone(id)
    local ok, l = legit("a" .. id)
    items[#items + 1] = { label = label, done = earned and ok, earned = earned, ach = id,
      why = earned and not ok and (l and l.why or "earned before RTH could see it") or nil }
  end
  for _, id in ipairs(gate.ids) do
    local _, name = GetAchievementInfo(id)
    ach(id, name or ("Achievement " .. id))
  end
  if gate.opt then
    local ph = RTH_Phases[p]
    if ph.voa then
      local earned = statCount(ph.voa.stat) > 0
      local ok, l = legit("v" .. p)
      items[#items + 1] = { label = ph.voa.name .. " (Vault of Archavon)", done = ok, earned = earned or ok,
        why = (earned or l) and not ok and (l and l.why or "killed before RTH could see it") or nil }
    end
    for _, o in ipairs(ph.optional or {}) do ach(o.achievement, o.name) end
  end
  return items
end

-- the kill this character's own RTH logged closest to time t (within 3 minutes), and whether it was clean
local JUDGE_WINDOW = 180
local function killNear(t)
  local me, best, bestD = RTH.PlayerName(), nil, nil
  local kills = RTH.db.group.kills
  for i = #kills, math.max(1, #kills - 60), -1 do
    local k = kills[i]
    if k.by == me and not k.synced and k.kind ~= "dungeon" then
      local d = math.abs(k.t - t)
      if d <= JUDGE_WINDOW and (not bestD or d < bestD) then best, bestD = k, d end
    end
  end
  return best
end
local NO_KILL = "no boss kill logged by RTH when it was earned"
local function verdict(k)
  if not k then return false, NO_KILL end
  if type(k.stars) == "table" and k.stars[1] then return false, "earned at a marked kill (" .. tostring(k.stars[1]) .. ")" end
  return true
end
RTH.KillVerdict = verdict

-- achievements any gate could use (the guild master's choices, the optional raids): only those are judged
local function gateRelevant(id)
  for p = 1, RTH.MAX_PHASE do
    for _, x in ipairs(RTH_GateOptions[p] or {}) do if x == id then return true end end
    for _, x in ipairs(RTH.db.group.gates[p] and RTH.db.group.gates[p].ids or {}) do if x == id then return true end end
    for _, o in ipairs(RTH_Phases[p] and RTH_Phases[p].optional or {}) do if o.achievement == id then return true end end
  end
  return false
end
local function inAnyGate(id)
  for p = 1, RTH.MAX_PHASE do
    for _, x in ipairs(RTH.db.group.gates[p] and RTH.db.group.gates[p].ids or {}) do if x == id then return true end end
  end
  return false
end
local pendingAch = {}
-- a gate achievement that doesn't count: a popup (2026-11-28, user: easy to miss as one chat line). "No kill logged"
-- waits 20 s more first - the backup kill detection logs a kill 15 s after the boss died, and the KILL listener below
-- then judges it again (no popup that turns out wrong a moment later).
local function tellNotCounted(id)
  local l = RTH.char.legit["a" .. id]
  if not (l and not l.ok and inAnyGate(id)) then return end
  local name = select(2, GetAchievementInfo(id)) or ("Achievement " .. id)
  RTH.Print("|cffffd040" .. name .. " doesn't count for the gate|r - " .. tostring(l.why))
  if StaticPopup_Show then
    StaticPopupDialogs.RTH_ACH_NOT_COUNTED = StaticPopupDialogs.RTH_ACH_NOT_COUNTED or {
      text = "|cffd9a441Road to Halion|r\n\n%s doesn't count for the unlock gate:\n%s\n\nAn achievement can be earned only once. "
        .. "Was the mark a mistake? The guild master can delete that rule break (then it counts) or pass the gate by hand.",
      button1 = OKAY or "OK", timeout = 0, whileDead = 1, hideOnEscape = 1, showAlert = 1,
    }
    StaticPopup_Show("RTH_ACH_NOT_COUNTED", name, tostring(l.why))
  end
end
local function judgeAchievements()
  for id, t in pairs(pendingAch) do
    pendingAch[id] = nil
    local ok, why = verdict(killNear(t))
    RTH.char.legit["a" .. id] = { t = t, ok = ok, why = why }
    if not ok then RTH.After("achTell" .. id, why == NO_KILL and 20 or 0, function() tellNotCounted(id) end) end
  end
  RTH.EvaluateGate()
end
RTH.On("ACHIEVEMENT_EARNED", function(id)
  id = tonumber(id)
  if id and RTH.Active() and RTH.char and not RTH.char.legit["a" .. id] and gateRelevant(id) then
    pendingAch[id] = time()
    RTH.After("judgeAch", 8, judgeAchievements)   -- the kill is logged a moment after the achievement pops
  end
end)
-- The guild master deleted a rule break (Sync.lua, user request 2026-11-22): take its star off the kills THIS RTH
-- recorded (a star is "Who: text", see Progress.lua sessionBreaks), then judge again every gate verdict that said
-- "doesn't count" - a kill whose only star was a false break counts after all. who/key/t as in the delete
-- (key = RTH.BreakKey of the text, t = the break's time). Synced copies of other players' kills only carry a star
-- COUNT and are left alone - each player's own RTH fixes its own kills when the delete reaches it.
function RTH.ForgetBreakStars(who, key, t)
  if not (RTH.char and RTH.BreakKey) or type(who) ~= "string" or type(key) ~= "string" or type(t) ~= "number" then return 0 end
  local prefix, me, removed = who .. ": ", RTH.PlayerName(), 0
  for _, k in ipairs(RTH.db.group.kills) do
    -- a kill after the break (it put the star there), within a day; an hour of slack for clocks
    if type(k.stars) == "table" and k.by == me and not k.synced and k.t >= t - 3600 and k.t <= t + 86400 then
      local before = removed
      for i = #k.stars, 1, -1 do
        local s = k.stars[i]
        if type(s) == "string" and s:sub(1, #prefix) == prefix and RTH.BreakKey(s:sub(#prefix + 1)) == key then
          table.remove(k.stars, i)
          removed = removed + 1
        end
      end
      -- everyone else only has a star COUNT for this kill: tell them the new one (Sync.lua "k", recorder only)
      if removed > before and RTH.Send and type(k.key) == "string" then
        RTH.Send("k", k.t .. "|" .. k.key .. "|" .. #k.stars)
      end
    end
  end
  if removed == 0 then return 0 end
  -- judge again: achievements by the kill nearest to when they were earned, Vault kills by their own kill
  local restored = 0
  for lkey, l in pairs(RTH.char.legit) do
    if type(l) == "table" and not l.ok and type(l.t) == "number" then
      local ok, why
      if lkey:sub(1, 1) == "a" then
        ok, why = verdict(killNear(l.t))
      else
        local kill
        for _, k in ipairs(RTH.db.group.kills) do
          if k.t == l.t and k.by == me and not k.synced then kill = k end
        end
        if kill then ok, why = verdict(kill) end
      end
      if ok then
        RTH.char.legit[lkey] = { t = l.t, ok = true }
        restored = restored + 1
      end
    end
  end
  if restored > 0 then
    RTH.Print("|cff40ff40" .. restored .. " gate kill" .. (restored == 1 and "" or "s")
      .. " count again|r - the guild master deleted the rule break that marked " .. (restored == 1 and "it" or "them"))
  end
  RTH.Fire("KILL")
  RTH.After("gateCheck", 1, RTH.EvaluateGate)
  return removed
end

-- the phase's VoA boss for the gate: this character's own clean kill
RTH.Listen("KILL", function(k)
  if type(k) ~= "table" or k.kind ~= "voa" or k.synced or k.by ~= RTH.PlayerName() then return end
  local key = "v" .. tostring(k.phase)
  if RTH.char.legit[key] and RTH.char.legit[key].ok then return end   -- one clean kill is enough
  local ok, why = verdict(k)
  RTH.char.legit[key] = { t = k.t, ok = ok, why = why }
end)

-- (2026-11-28) a kill our RTH logs LATE - the backup kill detection (Progress.lua) waits 15 s for the statistic - can
-- be the kill that earned an achievement judged 8 s after it popped as "no boss kill logged". Judge those again: the
-- same rule (our own kill within 3 minutes, no stars), just with the kill now in the log.
RTH.Listen("KILL", function(k)
  if type(k) ~= "table" or k.synced or k.by ~= RTH.PlayerName() or k.kind == "dungeon" then return end
  local changed = false
  for lkey, l in pairs(RTH.char.legit) do
    if lkey:sub(1, 1) == "a" and type(l) == "table" and not l.ok and type(l.t) == "number"
        and math.abs(k.t - l.t) <= JUDGE_WINDOW and l.why == NO_KILL then
      local ok, why = verdict(killNear(l.t))
      RTH.char.legit[lkey] = { t = l.t, ok = ok, why = why }
      changed = changed or ok
    end
  end
  if changed then RTH.After("gateCheck", 1, RTH.EvaluateGate) end
end)

local function validPhase(p)   -- a whole number 1..MAX (a synced "1.5" would break every screen)
  return type(p) == "number" and p >= 1 and p <= RTH.MAX_PHASE and p == math.floor(p)
end

-- ---------------------------------------------------------------- phases (1.4.0, user rule 2026-11-19)
-- Nobody unlocks a phase for the guild any more. Each CHARACTER opens the next phase for itself by finishing its
-- gate in clean guild runs (RTH.MyPhase, saved on the character for good). The guild's phase (RTH.GetPhase) is
-- only the furthest any member has reached: the window header, the journey log's "since", and who is "catching
-- up" (behind it). It only ever rises.
function RTH.RaiseGuildPhase(p, who)
  local g = RTH.db.group
  if not validPhase(p) or p <= g.phase then return end
  g.phase = p
  g.phaseLog[p] = g.phaseLog[p] or date("%Y-%m-%d")
  print_("|cff40ff40" .. RTH.PhaseLabel(p) .. " reached|r" .. (who and (" - " .. (who == RTH.PlayerName() and "you're" or (who .. " is"))
    .. " the first in the guild") or ""))
  RTH.Fire("PHASE_CHANGED", p)
end

-- a short fingerprint of phase p's gate (ids + optional raids): every "gate done" report carries the one it
-- was checked against, so a report from before the guild master changed the gate no longer counts
function RTH.GateSig(p)
  local gate = RTH.db.group.gates[p]
  if not gate then return "0" end
  local ids = {}
  for _, id in ipairs(gate.ids) do ids[#ids + 1] = id end
  table.sort(ids)
  local h = gate.opt and 7 or 3
  for _, id in ipairs(ids) do h = (h * 31 + id) % 1000003 end
  return tostring(h)
end

-- the guild master's phase controls need this character in the challenge: otherwise RTH sends nothing, so
-- the group would never hear about the change (and an "unlock anyway" wouldn't be logged)
function RTH.KeeperCanAct()
  if RTH.Active() then return true end
  print_("this character isn't in the challenge - tick 'This character is in the challenge' on the Rules tab first,"
    .. " or the group won't hear about it")
  return false
end

-- this character's progress on phase p's gate: done, have, need (an empty gate opens nothing)
function RTH.MyGateStatus(p)
  if RTH.char and RTH.char.passed[p] then
    local n = #RTH.GateItems(p)
    return true, n, n   -- finished (only a gate change before anyone started the next phase takes it back)
  end
  local items = RTH.GateItems(p)
  local have = 0
  for _, it in ipairs(items) do if it.done then have = have + 1 end end
  return #items > 0 and have == #items, have, #items
end

-- someone's report (1.4.0 "D" message): their phase, the gates they've finished, progress on their current gate
local function reportOf(name)
  local m = RTH.db.group.members[name]
  if m and m.gate and m.gate.v14 then return m end
end

-- who has finished phase p's gate: yourself, EVERY guild member whose RTH reported in the last 14 days
-- (RTH.HasRTH), and the names on the core list. Each: { name, done, have, need, known, phase }
-- (known = false: their RTH hasn't reported yet; phase = theirs, when they haven't reached p yet)
function RTH.GroupGateStatus(p)
  local list, seen = {}, {}
  local me = RTH.PlayerName()
  local function add(name)
    if seen[name:lower()] then return end
    seen[name:lower()] = true
    if name == me then
      local done, have, need = RTH.MyGateStatus(p)
      local mine = RTH.MyPhase()
      list[#list + 1] = { name = name, done = done, have = have, need = need, known = true, phase = mine < p and mine or nil }
    else
      local m = reportOf(name)
      local gt = m and m.gate
      if m and m.passes and m.passes[p] then
        list[#list + 1] = { name = name, done = true, have = gt.need, need = gt.need, known = true }
      elseif m and (m.phase or 1) < p then   -- not there yet
        list[#list + 1] = { name = name, done = false, have = 0, need = 0, known = true, phase = m.phase or 1 }
      elseif m and gt.phase == p and gt.sig == RTH.GateSig(p) then   -- a report on an older gate counts as not reported
        list[#list + 1] = { name = name, done = false, have = gt.have, need = gt.need, known = true }
      else
        list[#list + 1] = { name = name, done = false, have = 0, need = 0, known = false }
      end
    end
  end
  add(me)
  for _, n in ipairs(RTH.db.group.roster.names) do add(n) end
  local guild = {}
  for n in pairs(RTH.db.group.members) do
    if type(n) == "string" and RTH.HasRTH(n) then guild[#guild + 1] = n end
  end
  table.sort(guild)   -- the same order every time (members is keyed by name)
  for _, n in ipairs(guild) do add(n) end
  -- in a RAID, only the people in it are shown (the Progress tab's "Your raid 8/10"); solo or a 5-man party:
  -- the whole list above. Strangers in the raid (no RTH, not on the core list) aren't listed.
  if GetNumRaidMembers() > 0 then
    local inGroup = {}
    for _, u in ipairs(RTH.GroupUnits()) do
      local n = RTH.UnitKey(u)
      if n then inGroup[n:lower()] = true end
    end
    local only = {}
    for _, s in ipairs(list) do
      if s.name == me or inGroup[s.name:lower()] then only[#only + 1] = s end
    end
    return only, true
  end
  return list, false
end

-- "Aria, Bob, Cara and 12 more": a big guild's names must not make a popup or a log line endless

-- ---------------------------------------------------------------- personal phase (1.4.0, user rule 2026-11-19)
-- Everything about ONE character (what it may wear, use, buy, craft, enter) follows its own phase: phase 1 plus
-- every gate it has finished in a row. Saved on the character: a sync hiccup or an old RTH copy can never send it
-- back - only the guild master changing a gate before anyone started the next phase (revokeChanged). Cached: bag
-- marks ask for it hundreds of times.
local myPhase, lastMyPhase
function RTH.MyPhase()
  if not myPhase then
    local passed = RTH.char and RTH.char.passed or {}
    local q = 1
    while q < RTH.MAX_PHASE and passed[q] do q = q + 1 end
    myPhase = q
  end
  return myPhase
end
-- anyone's phase: yours live, others from their RTH's report (no 1.4 report yet = phase 1: nothing proven)
function RTH.PhaseOf(name)
  if not name or name == RTH.PlayerName() then return RTH.MyPhase() end
  local m = reportOf(name)
  return m and m.phase or 1
end

-- catching up = behind the furthest phase in the guild: the first gate this character still has to finish,
-- have, need (nil = not behind). The group is told when someone behind is in a newer raid or dungeon (no mark).
function RTH.MyCatchUp()
  local p = RTH.MyPhase()
  if p < RTH.GetPhase() then
    local _, have, need = RTH.MyGateStatus(p)
    return p, have, need
  end
end
-- the same for anyone: you live, others from their RTH's report (nil = not behind, or no 1.4 report)
function RTH.CatchUpOf(name)
  if name == RTH.PlayerName() then return RTH.MyCatchUp() end
  local m = reportOf(name)
  if m and m.phase and m.phase < RTH.GetPhase() then
    local same = m.gate.phase == m.phase
    return m.phase, same and m.gate.have or 0, same and m.gate.need or 0
  end
end
-- "Phase 1 (Naxx) gate 2/5"
function RTH.CatchUpText(q, have, need)
  return RTH.PhaseLabel(q) .. " gate " .. (have or 0) .. "/" .. (need or 0)
end

-- Phase p's gate is locked once anyone has STARTED the next phase (user rule 2026-11-19): killed one of its
-- bosses (the shared kill log), worn its gear at level 80, or finished its gate. Until then the guild master may
-- still change it - finding a gate too easy after finishing it - and whoever no longer meets it loses the next
-- phase again (see revokeChanged). Returns who and what, or nil (editable).
function RTH.GateLockedBy(p)
  local c, me = RTH.char, RTH.PlayerName()
  local nextLabel = RTH.PHASE_NAMES[p + 1] or "the next phase"
  if c and c.passed[p + 1] then return me, "finished the " .. nextLabel .. " gate" end
  if c and (c.wornMax or 0) > p then return me, "wore " .. RTH.PHASE_NAMES[c.wornMax] .. " gear" end
  local kills = RTH.db.group.kills
  for i = #kills, 1, -1 do
    local k = kills[i]
    if type(k.phase) == "number" and k.phase > p then
      return k.by or (type(k.roster) == "table" and k.roster[1]) or "someone", "killed " .. tostring(k.name)
    end
  end
  local names = {}
  for n in pairs(RTH.db.group.members) do names[#names + 1] = n end
  table.sort(names)   -- the same name every time
  for _, n in ipairs(names) do
    local m = RTH.db.group.members[n]
    if type(m) == "table" and m.passes and m.passes[p + 1] then return n, "finished the " .. nextLabel .. " gate" end
    if type(m) == "table" and type(m.worn) == "number" and m.worn > p then return n, "wore " .. (RTH.PHASE_NAMES[m.worn] or "newer") .. " gear" end
  end
end

-- this character has done something in a phase after p itself (its own kills, gear, a later gate): a gate
-- change can't take that phase back from it, even if the guild master's copy didn't know yet
local function startedAfter(p)
  local c, me = RTH.char, RTH.PlayerName()
  if c.passed[p + 1] or (c.wornMax or 0) > p then return true end
  for _, k in ipairs(RTH.db.group.kills) do
    if k.by == me and not k.synced and type(k.phase) == "number" and k.phase > p then return true end
  end
  return false
end

local function refreshMyPhase()
  myPhase = nil
  local new = RTH.MyPhase()
  local old = lastMyPhase
  lastMyPhase = new
  if old and new ~= old then
    if new > old then
      -- (the guild's furthest is raised AFTER this: equal = someone was already there - you caught up with them)
      RTH.Print("|cff40ff40" .. RTH.PhaseLabel(old) .. " gate done|r - " .. RTH.PhaseLabel(new) .. " is open for you"
        .. (new == RTH.GetPhase() and " - |cff40ff40caught up!|r you're where the guild's furthest are" or ""))
      RTH.Fire("PHASE_UNLOCKED", new)
    end
    RTH.Fire("MY_PHASE_CHANGED", new)
  end
end
RTH.Listen("GATES_CHANGED", function() myPhase = nil end)

-- characters from before 1.4 (once): the gates of the phases the guild master had opened, finished the old way
-- (the achievements, without the clean-kill check), stay finished
local function migrateOldPhase()
  local c, g = RTH.char, RTH.db.group
  if c.phase14 ~= "todo" then return end
  c.phase14 = "done"
  for q = 1, (g.oldPhase14 or 1) - 1 do
    local ids = g.gates[q] and g.gates[q].ids or {}
    local all = ids[1] ~= nil
    for _, id in ipairs(ids) do if not achDone(id) then all = false end end
    if not all then break end
    c.passed[q] = c.passed[q] or { d = date("%Y-%m-%d"), how = "before 1.4", sig = RTH.GateSig(q) }
  end
  myPhase = nil
end

-- this character's report ("D": phase|have|need|gateSig|finished gates "1,2"|newest gear phase worn at 80)
function RTH.GateReport()
  local p = RTH.MyPhase()
  local _, have, need = RTH.MyGateStatus(p)
  local passes = {}
  for q = 1, RTH.MAX_PHASE do if RTH.char.passed[q] then passes[#passes + 1] = q end end
  return p .. "|" .. have .. "|" .. need .. "|" .. RTH.GateSig(p) .. "|" .. table.concat(passes, ",") .. "|" .. (RTH.char.wornMax or 0)
end

-- after kills, achievements, login: a finished gate opens the next phase for this character (for good), then
-- the guild hears about it. reportOnly (a gate edit): just report - a half-finished edit must never pass anyone.
function RTH.EvaluateGate(reportOnly)
  if RTH.Active() then
    migrateOldPhase()
    if reportOnly ~= true then
      local p = RTH.MyPhase()
      while p < RTH.MAX_PHASE and (RTH.MyGateStatus(p)) do
        RTH.char.passed[p] = { d = date("%Y-%m-%d"), how = "gate", sig = RTH.GateSig(p) }
        myPhase = nil
        p = RTH.MyPhase()
      end
    end
  end
  refreshMyPhase()
  if not RTH.Active() then return end
  RTH.RaiseGuildPhase(RTH.MyPhase(), RTH.PlayerName())
  if RTH.Send then RTH.Send("D", RTH.GateReport()) end
  RTH.Fire("GATE_STATUS")
end
-- a member's report: they may be the furthest now - or, after a gate change took a phase back, the guild's
-- furthest may be lower again (lower = worked out from every report we have, never from one message)
function RTH.NoteMemberPhase(name, p, wentDown)
  if p and p > RTH.GetPhase() then RTH.RaiseGuildPhase(p, name)
  elseif wentDown then RTH.RecalcGuildPhase() end
end
function RTH.RecalcGuildPhase()
  local best = RTH.MyPhase()
  for n, m in pairs(RTH.db.group.members) do
    if type(m) == "table" and not m.off and reportOf(n) and type(m.phase) == "number" and m.phase > best then best = m.phase end
  end
  local g = RTH.db.group
  if best > g.phase then RTH.RaiseGuildPhase(best)
  elseif best < g.phase then
    g.phase = best
    print_("|cffffd040the guild's furthest phase is " .. RTH.PhaseLabel(best) .. " again|r (a gate was changed)")
    RTH.Fire("PHASE_CHANGED", best)
  end
end

-- The guild master's way out (/rth gate Name 2): marks that character's gates up to phase 2 as finished - for
-- a gate achievement the game bugged, or one earned on a night RTH missed (it can't be earned again). Written
-- into the journey log. Not inside a raid: the log line would mark the rest of tonight's kills.
function RTH.GrantGate(name, p)
  if not RTH.IAmRulesKeeper() then print_("only " .. RTH.KeeperLabel() .. " can pass a gate by hand"); return end
  if not RTH.KeeperCanAct() then return end
  if not (validPhase(p) and p < RTH.MAX_PHASE) then print_("usage: /rth gate Name 1   (1 to " .. (RTH.MAX_PHASE - 1) .. ": the last gate to mark finished)"); return end
  if select(2, IsInInstance()) == "raid" then print_("leave the raid first - the journey log line would mark the rest of tonight's kills"); return end
  local target = name:sub(1, 1):upper() .. name:sub(2):lower()
  RTH.AddBreak(RTH.PlayerName(), "passed " .. target .. "'s gates up to " .. RTH.PhaseLabel(p) .. " by hand (" .. RTH.PhaseLabel(p + 1) .. " open for them)")
  if target == RTH.PlayerName() then
    RTH.ApplyGrant(p, RTH.PlayerName())
  else
    if RTH.Send then RTH.Send("J", target .. "|" .. p) end
    print_("sent to " .. target .. " - they must be online with RTH now; ask them to check their window")
  end
end
function RTH.ApplyGrant(p, by)
  if not (validPhase(p) and p < RTH.MAX_PHASE) then return end
  local new = false
  for q = 1, p do if not RTH.char.passed[q] then new = true end end
  if not new then return end   -- (already done: the same message arrives twice in a raid - raid + guild)
  for q = 1, p do
    if not RTH.char.passed[q] then RTH.char.passed[q] = { d = date("%Y-%m-%d"), how = "by " .. tostring(by) } end
  end
  myPhase = nil
  RTH.Print("the guild master " .. tostring(by) .. " marked your gates up to " .. RTH.PhaseLabel(p) .. " as finished")
  RTH.EvaluateGate()
end

RTH.Listen("PHASE_CHANGED", function() RTH.After("gateReport", 2, function() RTH.EvaluateGate(true) end) end)

-- The guild master changed a gate that nobody had started the next phase of (user rule 2026-11-19: "we found it
-- too easy"): whoever had finished it but doesn't meet the NEW gate loses the next phase again - and every later
-- one - until they finish it. Not a rule break. Kept: a phase passed by hand (/rth gate), and anything this
-- character already started itself (its own kills / gear there - the GM's copy may not have known).
local function gateMet(p, loose)
  local items = RTH.GateItems(p)
  if not items[1] then return false end
  for _, it in ipairs(items) do
    if not (it.done or (loose and it.earned)) then return false end
  end
  return true
end
local function revokeChanged()
  if not RTH.Active() then return false end
  local c = RTH.char
  for p = 1, RTH.MAX_PHASE - 1 do
    local e = c.passed[p]
    -- only when THAT gate really changed since it was passed (not on every login: achievement data that isn't
    -- loaded yet must never take a phase away). Gates kept from 1.3 are judged the 1.3 way (no clean-run check).
    if e and not tostring(e.how):find("^by ") and e.sig ~= RTH.GateSig(p)
        and (gateMet(p, e.how == "before 1.4") or startedAfter(p)) then
      e.sig = RTH.GateSig(p)   -- still fine under the new gate: remember it, nothing to do
    elseif e and not tostring(e.how):find("^by ") and e.sig ~= RTH.GateSig(p) then
      for q = p, RTH.MAX_PHASE do c.passed[q] = nil end
      myPhase = nil
      local _, have, need = RTH.MyGateStatus(p)
      RTH.Print("|cffffd040the guild master changed the gate of " .. RTH.PhaseLabel(p) .. "|r - " .. RTH.PhaseLabel(p + 1)
        .. " is closed for you again until you finish it (" .. have .. "/" .. need .. ")")
      return true
    end
  end
  return false
end
-- (after the change: report against the NEW gate - only report, never pass, see EvaluateGate)
local function onGateChange()
  local down = revokeChanged()
  RTH.EvaluateGate(true)
  if down then RTH.RecalcGuildPhase() end
end
RTH.Listen("GATES_CHANGED", function() RTH.After("gateChange", 2, onGateChange) end)
-- and at every login: the gates are saved for the whole ACCOUNT, so an alt logging in after the change arrived on
-- another character never sees a "change" message - it checks its finished gates against today's gates here
RTH.Listen("LOGIN", function() RTH.After("gateChange", 6, onGateChange) end)

-- the newest phase of gear worn at level 80, kept for good: wearing it counts as starting that phase (gate lock)
local function noteWorn()
  if not (RTH.Active() and RTH.GearCounts("player")) then return end
  -- (only gear that's allowed for this character: an heirloom at 80 or a piece worn against the rules must not
  -- lock a gate for the whole guild)
  local top = 0
  for slot = 1, 19 do
    local link = GetInventoryItemLink("player", slot)
    local id = RTH.ParseLink(link)
    local p = id and RTH_ItemPatch[id]
    if p and p > top and RTH.ItemStatus(link, "equip") == "ok" then top = p end
  end
  if top > (RTH.char.wornMax or 0) then
    RTH.char.wornMax = top
    RTH.After("wornReport", 1, function() RTH.EvaluateGate(true) end)
  end
end
RTH.On("UNIT_INVENTORY_CHANGED", function(unit) if unit == "player" then RTH.After("wornMax", 2, noteWorn) end end)
RTH.Listen("LOGIN", function() RTH.After("wornMax", 7, noteWorn) end)

-- ---------------------------------------------------------------- start up
RTH.On("PLAYER_ENTERING_WORLD", RTH.ResetInstanceNames)   -- instance names in the client's language (top of file)
RTH.On("ADDON_LOADED", function(name)
  if name ~= "RTH" then return end
  initDB()
  RTH.Fire("DB_READY")
end)

-- joining / creating a guild mid-session: fetch the roster so the guild master is known straight away
local wasInGuild
RTH.On("PLAYER_GUILD_UPDATE", function()
  if IsInGuild() then GuildRoster() end
  RTH.Fire("ROSTER_CHANGED")
  -- we just joined a guild (not the login check): say hello once the new guild's list is in
  local now = IsInGuild() and true or false
  if now and wasInGuild == false then RTH.Fire("JOINED_GUILD") end
  wasInGuild = now
end)
RTH.On("PLAYER_LOGIN", function() wasInGuild = IsInGuild() and true or false end)

-- Since 2026-11-22 raids, dungeons, raid lockouts and Herbalism are read on any game language (instance map IDs +
-- the Dungeon Finder's names, see the top of this file; Professions.lua for Herbalism). Not tested on a real
-- non-English client yet, so the note only asks to report anything RTH doesn't recognise.
local function englishClient() local l = GetLocale(); return l == "enUS" or l == "enGB" end
local LOCALE_NOTE = "not English - supported; if a raid, dungeon or Herbalism isn't recognised, tell the guild master."

RTH.On("PLAYER_LOGIN", function()
  if RTH.freshStart then
    RTH.freshStart = nil
    RTH.Print("|cff40ff40version " .. RTH.VERSION .. ": fresh start|r - the test version's journey log, phase and rules were"
      .. " cleared. Your professions and settings are kept. The guild master's rules arrive when you're both online.")
  end
  if RTH.needsRestart then
    RTH.Print("|cffff8040new data files were added - close WoW completely and start it again (/reload is not enough). "
      .. "Until then recipe marks, recipe tooltips, profession cooldowns and the craft rule are off.|r")
  end
  if IsInGuild() then GuildRoster() end
  RTH.Fire("LOGIN")
  RTH.After("gateCheck", 5, RTH.EvaluateGate)
  RTH.After("askChallenge", 4, askInChallenge)
end)

RTH.On("ACHIEVEMENT_EARNED", function()
  RTH.After("gateCheck", 1, RTH.EvaluateGate)
end)

-- ---------------------------------------------------------------- slash commands
SLASH_ROADTOHALION1 = "/rth"
SLASH_ROADTOHALION2 = "/roadtohalion"
SlashCmdList["ROADTOHALION"] = function(msg)
  msg = (msg or ""):lower()
  local cmd, arg = msg:match("^(%S*)%s*(.-)$")
  local PHASE_HOW = "each character opens the next phase for itself by finishing its gate in clean guild runs (Progress tab)"
  if cmd == "" then
    if RTH.ToggleMain then RTH.ToggleMain() end
  elseif cmd == "unlock" or (cmd == "phase" and arg ~= "") then   -- (1.3 commands: nobody unlocks for the guild now)
    print_("there is no guild unlock any more: " .. PHASE_HOW)
  elseif cmd == "gate" then
    -- the guild master's way out: /rth gate Name 1 = Name's gates up to phase 1 count as finished
    local name, n = arg:match("^(%S+)%s+(%d+)$")
    if not name then print_("usage: /rth gate Name 1   (guild master: mark Name's gates up to that phase as finished)"); return end
    RTH.GrantGate(name, tonumber(n))
  elseif cmd == "rules" then
    if RTH.ShowRules then RTH.ShowRules() end
  elseif cmd == "status" then
    -- quick self-check: is everything loaded and switched on?
    local n = 0
    for _ in pairs(RTH_RecipeItems) do n = n + 1 end
    local yes, no = "|cff40ff40yes|r", "|cffff4040no|r"
    print_("version " .. RTH.VERSION .. "  |  you: " .. RTH.PhaseLabel(RTH.MyPhase()) .. "  |  furthest in the guild: " .. RTH.PhaseLabel(RTH.GetPhase()))
    print_("this character is in the challenge: " .. (RTH.Active() and yes
      or RTH.char.inChallenge == nil and (no .. " (not answered yet - answer the question window, or tick it on the Rules tab)")
      or (no .. " (Rules tab: tick 'This character is in the challenge')")))
    print_("red marks on icons: " .. ((RTH.db.ui.overlays and yes) or (no .. " (Rules tab: tick 'Red marks on icons')")))
    -- which bag addons got the marks (a bag addon not in this list shows no red marks - tell the guild master)
    local addons = {}
    for name in pairs(RTH.MarkedAddons or {}) do
      if not name:find("^Blizzard_") then addons[#addons + 1] = name end
    end
    table.sort(addons)
    print_("red marks added to: Blizzard bags" .. (addons[1] and (", " .. table.concat(addons, ", ")) or "")
      .. " + any bag addon that uses Blizzard's bag buttons (if yours shows no red marks, tell the guild master its name)")
    -- mail / vendor / AH addons whose own buttons RTH also stops (Rules.lua; some only after opening the window once)
    local gi, guards = RTH.AddonGuardsInstalled or {}, {}
    local GUARD_NAMES = { postal = "Postal Open All", tam = "ElvUI Take All", altBuy = "ElvUI alt-click buy",
      split = "ElvUI Extras stack buy", atr = "Auctionator Buy" }
    for k, label in pairs(GUARD_NAMES) do if gi[k] then guards[#guards + 1] = label end end
    table.sort(guards)
    print_("gold and buying stops also cover: " .. (guards[1] and table.concat(guards, ", ") or "Blizzard's windows only")
      .. "  (mail, vendor and AH addons are found when you open their window)")
    print_("recipe data loaded: " .. (n > 0 and (yes .. " (" .. n .. " recipes)")
      or (no .. " - close WoW completely and start it again (/reload is not enough)")))
    print_("you can change the rules (guild master): " .. (RTH.IAmRulesKeeper() and yes or no))
    -- where this account's gates / core list came from (Sync.lua G / N and the "u" copy)
    local g, fromGM, copyBy = RTH.db.group, true, nil
    for p = 1, RTH.MAX_PHASE do
      if not g.gateSynced[p] then fromGM = false end
      copyBy = copyBy or (g.gateRelayed and g.gateRelayed[p])
    end
    print_("rules (gates, core list): " .. (RTH.IAmRulesKeeper() and (yes .. " your own")
      or fromGM and (yes .. " from the guild master")
      or copyBy and ("|cffffd040a copy from " .. copyBy .. "|r (until the guild master is online)")
      or (no .. " - the default gates: the guild master hasn't been online since you installed RTH")))
    print_("game language: " .. (englishClient() and (yes .. " English") or ("|cffffd040" .. tostring(GetLocale()) .. "|r " .. LOCALE_NOTE)))
  elseif cmd == "check" then
    if RTH.RequestStatus then RTH.RequestStatus() end
    print_("asked the group for their status")
  elseif cmd == "ping" then
    if RTH.Ping then RTH.Ping() end
  elseif cmd == "test" and arg == "trade" then
    -- show the outsider-trade popup with a sample name: no trade, nothing sent, nothing logged
    if RTH.ShowTradeWarning then RTH.ShowTradeWarning("Stranger") end
    print_("test: this is the popup a trade with someone outside the guild shows (no trade was opened)")
  elseif cmd == "sync" then
    -- what this RTH knows about the others: where group sync breaks shows up here (run it on two clients)
    local gm
    for n, r in pairs(guildRanks) do if r == 0 then gm = n end end
    local yes, no = "|cff40ff40", "|cffff4040"
    print_("you: " .. RTH.PlayerName() .. " - RTH " .. RTH.VERSION .. " - "
      .. (RTH.Active() and (yes .. "in the challenge|r") or (no .. "NOT in the challenge - nothing is sent or received|r")))
    local mine = {}
    for skill, rank in pairs(RTH.char.profs) do mine[#mine + 1] = (RTH.PROF_NAME[skill] or skill) .. " " .. rank end
    table.sort(mine)
    print_("your professions: " .. (mine[1] and table.concat(mine, ", ")
      or (no .. "none found - open each profession window once (or expand 'Professions' on the Skills tab)|r")))
    print_("guild master: " .. (gm and (gm .. (gm == RTH.PlayerName() and " (you)" or "")) or (no .. "unknown - not in a guild, or the guild list hasn't loaded|r")))
    local names = RTH.db.group.roster.names
    print_("your phase: " .. RTH.PhaseLabel(RTH.MyPhase()) .. " - furthest in the guild: " .. RTH.PhaseLabel(RTH.GetPhase()))
    -- everyone on the core list, plus every guild member whose RTH we've heard from (they're in the group too)
    local list, listed = {}, {}
    for _, n in ipairs(names) do
      if n ~= RTH.PlayerName() and not listed[n] then listed[n] = true; list[#list + 1] = n end
    end
    for n, m in pairs(RTH.db.group.members) do
      if n ~= RTH.PlayerName() and not listed[n] and (RTH.HasRTH(n) or (m.off and RTH.IsGuildMember(n))) then
        listed[n] = true; list[#list + 1] = n
      end
    end
    if not list[1] then print_("players: " .. no .. "nobody heard from yet|r - nobody else online with RTH, or a different RTH copy") end
    for _, n in ipairs(list) do
      local m = RTH.db.group.members[n]
      local onList = RTH.IsCore(n) and "core list" or "guild"
      if m and m.off then
        print_("  " .. n .. " (" .. onList .. "): |cffb8b8b8switched the challenge off|r")
      elseif not (m and m.seen) then
        print_("  " .. n .. " (" .. onList .. "): " .. no .. "nothing heard yet|r (offline, no RTH, a different RTH copy, or not answered Yes)")
      else
        local np = 0
        for _ in pairs(m.profs or {}) do np = np + 1 end
        local v = tostring(m.version or "?")
        local vNote = ""
        if m.version and RTH.VersionNewer then
          if RTH.VersionNewer(RTH.VERSION, v) then vNote = " " .. no .. "(outdated - needs " .. RTH.VERSION .. ")|r"
          elseif RTH.VersionNewer(v, RTH.VERSION) then vNote = " " .. no .. "(newer than yours - update)|r" end
        end
        print_("  " .. n .. " (" .. onList .. "): " .. yes .. "heard " .. math.floor((time() - m.seen) / 60) .. " min ago|r - RTH "
          .. v .. vNote .. " - " .. np .. " profession" .. (np == 1 and "" or "s")
          .. (reportOf(n) and (" - " .. RTH.PHASE_NAMES[RTH.PhaseOf(n)]) or ""))
      end
    end
  else
    print_("commands:")
    print_("  /rth  -  open or close the window")
    print_("  /rth rules  -  how the rules work, in plain words (also a button on the Rules tab)")
    print_("  /rth status  -  check that everything is loaded and switched on")
    print_("  /rth check  -  ask the group for their gear status")
    print_("  /rth sync  -  who RTH has heard from (if the group's data doesn't show up)")
    print_("  /rth ping  -  test the connection: does the guild channel carry RTH, and who answers")
    print_("  /rth test trade  -  show the popup a trade with someone outside the guild shows (nothing is traded)")
    print_("  /rth gate Name N  -  guild master only: mark Name's gates up to phase N as finished (written in the log)")
  end
end
