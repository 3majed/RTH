-- Road to Halion: group sync over addon messages (prefix "RTH").
--   H  hello: please send your status                 S  status: myPhase|gearBad|gearCheck|reason|level
--   P  professions: skill:rank:max,...                R  recipes: skill|part|parts|ids (base 36), ALL known recipes
--   J  gate by hand (GM only): name|phase            G  gate (GM only): phase|opt|batch|part|parts|id,id,...
--   N  roster (GM only): rank|batch|part|parts|name,name,...                  K  kill: key|heroic|wipes|stars
--   (GM = the guild master, RTH.IsRulesKeeper; without a guild nobody can change the rules)
--   B  rule break: text (the WHOLE rest - links have "|" in them)              C  cooldowns: name:secondsLeft,...
--   W  journey log catch-up request (member -> GM): since      X  catch-up entry (GM whisper) - see "catch-up" below
--   Y  the GM asks members for their OWN log entries since: since      Z  a member's own entry (whisper to the GM)
--   T  profession link: skill|trade:... (the link without |H...|h, rebuilt on arrival)
--   D  phase report (1.4.0): myPhase|have|need|gateSig|finished gates "1,2"|worn - this character's own phase and its
--      progress on that phase's gate (gateSig = Core GateSig: which gate it was checked against)
--      (1.3's U - the GM's phase unlock - and A - the old gate report - are gone)
--   L  raid lockouts: part|parts|name:id:secondsLeft:size:heroic(1/0),...   (split at ~200 characters)
--   V  version: the sender's RTH version (a newer one in the guild -> "please update" once)
--   Q  gear problems, one item per message: i|n|slot|item:...|b(ad)/c(heck)|reason   ("0|0" = all gear allowed)
--   F  item search (asker -> group): text          f  answer (whisper): text|itemID:bags:bank,...
--   O  this character switched the challenge off (no payload) - out of the group until it reports again
--   M  the guild master's comment on a rule break (GM only): breakTime|who|breakKey|note   (empty note = removed)
--   E  the guild master deletes a rule break (GM only): breakTime|who|breakKey|deleteTime   (X|d / x|d in catch-ups)
--   k  a kill's new star count, from the player whose RTH recorded it: killTime|bossKey|stars
--   q  "I don't have the guild master's rules" (GUILD)    u  a member's copy of them: G|<G fields> or N|<N fields>
--   W / w may carry "|1": this account never had the full list of deletes - send all of them (90 days)
--   Relay (see "relay" below): what offline players sent, passed on by whoever is online
--   I  login list (GUILD): batch|part|parts|logWindow|name:age,...   o  offer (whisper): logCount|name:age,...
--   g  "send me these players" (whisper): name,...    s  a player's copy (whisper): name|age|kind|<that kind's fields>
--   w  "send me the log since" (whisper): seconds       x  a log entry (whisper), like X but with ages instead of times
--   (older versions ignore these kinds: nobody has to update for the rest to keep working)
-- Bulky messages (R, T) go through a queue, ~4 a second, so a group forming doesn't flood the server.
-- Messages go to the raid/party and to the guild; only senders in the group (core, subs) are trusted.
-- A raid member who is also in the guild gets every message TWICE (raid + guild channel): every handler
-- must be safe to run twice - store by key / part number, never append.
local RTH = RTH
local PREFIX = "RTH"

local function channels()
  local list = {}
  if GetNumRaidMembers() > 0 then list[#list + 1] = "RAID"
  elseif GetNumPartyMembers() > 0 then list[#list + 1] = "PARTY" end
  if IsInGuild() then list[#list + 1] = "GUILD" end
  return list
end

-- cut to at most n bytes without splitting a letter (accented letters are 2 bytes in UTF-8: half a letter is broken text)
local function cutBytes(s, n)
  if #s <= n then return s end
  local cut = n
  while cut > 0 do
    local b = s:byte(cut + 1)
    if not b or b < 128 or b >= 192 then break end   -- the next byte starts a letter: cutting here is clean
    cut = cut - 1
  end
  return s:sub(1, cut)
end
RTH.CutBytes = cutBytes   -- shared: every text cut for a message must use it (a byte cut can split a letter)

-- a list of words -> comma-joined chunks of at most `size` bytes (each chunk is one message part)
local function chunked(list, size)
  local chunks, cur, len = {}, {}, 0
  for _, s in ipairs(list) do
    if len + #s + 1 > size and cur[1] then chunks[#chunks + 1] = table.concat(cur, ","); cur, len = {}, 0 end
    cur[#cur + 1] = s; len = len + #s + 1
  end
  chunks[#chunks + 1] = table.concat(cur, ",")
  return chunks
end

-- a rule break for the group: a long one (item links are ~80 characters) becomes plain text first
-- ([Name] instead of the whole link), then is shortened with "..." - never cut in the middle of a link
function RTH.BreakForMessage(text, limit)
  limit = limit or 240
  if #text <= limit then return text end
  text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1")
  if #text > limit then text = cutBytes(text, limit - 3) .. "..." end
  return text
end
-- Is this the same rule break text? A break travels shortened (live 240 bytes, catch-up / relay / own reports 200),
-- so one copy can be a cut of another: equal, or one ends in "..." and the other starts with the same plain text.
-- (Plain full-text compare let a long break land twice in a log - fixed 2026-11-22.)
local function plainBreak(s)
  return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"))
end
function RTH.SameBreakText(a, b)
  if a == b then return true end
  a, b = plainBreak(a), plainBreak(b)
  if a == b then return true end
  if #a > #b then a, b = b, a end   -- a = the shorter one
  if a:sub(-3) ~= "..." then return false end
  local stem = a:sub(1, -4)
  return #stem >= 20 and b:sub(1, #stem) == stem
end

-- On the wire every "|" becomes a TAB, and back on arrival. "|" starts colour codes and links in WoW chat, and a
-- message with a stray "|0" or "|S" can be dropped on the way (no addon that works on this server sends one: DBM
-- uses tabs). Item links in a rule break travel as tabs too and come back whole.
local function toWire(msg) return (msg:gsub("|", "\t")) end
local function fromWire(msg) return (msg:gsub("\t", "|")) end

function RTH.Send(kind, payload, whisperTo)
  if not RTH.Active() then return end
  local msg = toWire(cutBytes(kind .. (payload and ("|" .. payload) or ""), 250))
  if whisperTo then
    SendAddonMessage(PREFIX, msg, "WHISPER", whisperTo)
    return
  end
  for _, ch in ipairs(channels()) do SendAddonMessage(PREFIX, msg, ch) end
end

-- queued send: `key` names the message (e.g. "R164.2>Bob"); a newer one with the same key replaces the
-- waiting one, so repeated profession changes or hellos never pile up duplicates.
local queue, queued = {}, {}
local function drain()
  local item = table.remove(queue, 1)
  if item then
    queued[item.key] = nil
    RTH.Send(item.kind, item.payload, item.to)
  end
  if queue[1] then RTH.After("sendQueue", 0.25, drain) end
end
-- drop waiting messages whose key starts with `prefix` (to the same target): a new batch replaces the old one
function RTH.CancelQueued(prefix, to)
  local suffix = ">" .. (to or "*")
  for i = #queue, 1, -1 do
    local k = queue[i].key
    if k:sub(1, #prefix) == prefix and k:sub(-#suffix) == suffix then
      queued[k] = nil
      table.remove(queue, i)
    end
  end
end

function RTH.SendQueued(key, kind, payload, to)
  key = key .. ">" .. (to or "*")
  local item = queued[key]
  if item then item.kind, item.payload = kind, payload; return end
  item = { key = key, kind = kind, payload = payload, to = to }
  queued[key] = item
  queue[#queue + 1] = item
  if #queue == 1 then RTH.After("sendQueue", 0.25, drain) end
end

-- ---------------------------------------------------------------- base 36 numbers
local DIG = "0123456789abcdefghijklmnopqrstuvwxyz"
local function b36(n)
  local s = ""
  repeat
    local d = n % 36
    s = DIG:sub(d + 1, d + 1) .. s
    n = math.floor(n / 36)
  until n == 0
  return s
end

-- ---------------------------------------------------------------- what we send
local function myStatus()
  local problems, checks = RTH.CheckEquipped()
  local reason = problems[1] and problems[1].reason or (checks[1] and checks[1].reason) or ""
  reason = cutBytes((reason:gsub("|", "/")), 150)   -- short (whole letters) so the level after it always fits
  return RTH.MyPhase() .. "|" .. #problems .. "|" .. #checks .. "|" .. reason .. "|" .. (UnitLevel("player") or 0)
end

local function sendCooldowns()
  local parts = {}
  for name, ready in pairs(RTH.char.cooldowns) do
    parts[#parts + 1] = name .. ":" .. math.max(0, ready - time())
  end
  if parts[1] then RTH.SendQueued("C", "C", table.concat(parts, ",")) end   -- queued: a scan asking twice sends once
end

local function sendProfessions()
  local parts = {}
  for skill, rank in pairs(RTH.char.profs) do
    parts[#parts + 1] = skill .. ":" .. rank .. ":" .. (RTH.char.profMax[skill] or 0)
  end
  RTH.Send("P", table.concat(parts, ","))
  for skill, body in pairs(RTH.char.tradeLinks) do
    RTH.SendQueued("T" .. skill, "T", skill .. "|" .. body)
  end
  -- every known recipe (the recipe tooltips say who in the group already knows one)
  for skill, set in pairs(RTH.char.recipes) do
    local ids = {}
    for spell in pairs(set) do ids[#ids + 1] = b36(spell) end
    table.sort(ids)
    local chunks = chunked(ids, 200)
    for i, c in ipairs(chunks) do
      RTH.SendQueued("R" .. skill .. "." .. i, "R", skill .. "|" .. i .. "|" .. #chunks .. "|" .. c)
    end
  end
end

-- raid lockouts (Progress.lua scans them)
local function sendLockouts()
  local entries = {}
  for _, l in ipairs(RTH.char.lockouts or {}) do
    if l.ends > time() then
      entries[#entries + 1] = l.name .. ":" .. tostring(l.id) .. ":" .. (l.ends - time()) .. ":" .. l.size .. ":" .. (l.heroic and 1 or 0)
    end
  end
  -- many lockouts can pass the 250-character limit: send in parts (part 1 replaces the old list)
  local chunks = chunked(entries, 200)
  RTH.CancelQueued("L")
  for i, c in ipairs(chunks) do RTH.SendQueued("L" .. i, "L", i .. "|" .. #chunks .. "|" .. c) end
end

-- every problem / check item on your gear, so Raid Check can list them even when you're out of inspect range
local function sendGear()
  RTH.CancelQueued("Q")
  local problems, checks = RTH.CheckEquipped()
  local list = {}
  for _, p in ipairs(problems) do list[#list + 1] = { p, "b" } end
  for _, p in ipairs(checks) do list[#list + 1] = { p, "c" } end
  if not list[1] then RTH.SendQueued("Q0", "Q", "0|0"); return end
  for i, e in ipairs(list) do
    local item = e[1].link and e[1].link:match("|H(item:[%-%d:]+)|h")
    if item then
      local reason = cutBytes((e[1].reason or ""):gsub("|", "/"), 110)   -- UTF-8 safe (was :sub)
      RTH.SendQueued("Q" .. i, "Q", i .. "|" .. #list .. "|" .. e[1].slot .. "|" .. item .. "|" .. e[2] .. "|" .. reason)
    end
  end
end

local function sendAll()
  RTH.Send("V", RTH.VERSION)
  RTH.Send("S", myStatus())
  -- the guild master's rules, so members who installed RTH later get the custom gates and core list too
  if RTH.IAmRulesKeeper() then
    RTH.BroadcastRoster()
    for p = 1, RTH.MAX_PHASE do RTH.BroadcastGate(p) end
  end
  sendLockouts()
  sendGear()
  RTH.Send("D", RTH.GateReport())
  sendProfessions()
  sendCooldowns()   -- otherwise only on COOLDOWNS_CHANGED, so one scan sends them once
end

-- Hellos are answered with ONE broadcast (raid + guild), 2-5 s later, however many arrive meanwhile. When a raid
-- forms everyone says hello at once: a private answer to each would be ~25 messages x 24 people per client
-- (thousands across the raid - a burst like that can get players disconnected). The random delay keeps
-- 25 clients from all answering in the same moment. Our own hello (login, joining) shares the same answer.
local answerPending = false
local function answerHellos()
  if answerPending then return end
  answerPending = true
  RTH.After("answerHello", 2 + math.random() * 3, function()
    answerPending = false
    sendAll()
  end)
end

-- our hello: ask the group for theirs, and send ours (login, joining a group, switching the challenge on)
function RTH.SayHello()
  RTH.lastHelloT = time()
  RTH.Send("H")
  answerHellos()
  if RTH.AskLog then RTH.AskLog() end   -- and what the journey log got while we were away (from the GM)
  if RTH.AskMembersLog then RTH.AskMembersLog() end   -- the GM: what members logged while the GM was away
end
-- the guild master's RTH remembers when it last ran: members send what they logged after that (handlers.Y)
RTH.On("PLAYER_LOGOUT", function()
  if RTH.db and RTH.IAmRulesKeeper() then RTH.db.group.keeperSeenT = time() end
end)

function RTH.RequestStatus()
  RTH.Send("H")
  RTH.After("sendStatus", 1, function() RTH.Send("S", myStatus()) end)
end


-- The gate (up to 71 achievements) and the core list (accented names are 2 bytes a letter) can pass the
-- 250-character limit, so both go in parts. Every send gets a batch number: the receiver only puts together
-- parts of the same batch, so a lost part can never mix an old list with a new one.
local batchCount = 0
local function newBatch()
  batchCount = batchCount + 1
  return tostring(time() % 100000) .. batchCount
end

-- the fields of a gate / the core list, as message parts (also what a member passes on: "u" below)
local function gateParts(p)
  local gate = RTH.db.group.gates[p]
  local ids = {}
  for _, id in ipairs(gate.ids) do ids[#ids + 1] = tostring(id) end
  local chunks, batch, out = chunked(ids, 200), newBatch(), {}
  for i, c in ipairs(chunks) do
    out[#out + 1] = p .. "|" .. (gate.opt and 1 or 0) .. "|" .. batch .. "|" .. i .. "|" .. #chunks .. "|" .. c
  end
  return out
end
local function rosterParts()
  local r = RTH.db.group.roster
  local chunks, batch, out = chunked(r.names, 200), newBatch(), {}
  for i, c in ipairs(chunks) do
    out[#out + 1] = (r.rank or "-") .. "|" .. batch .. "|" .. i .. "|" .. #chunks .. "|" .. c
  end
  return out
end
function RTH.BroadcastGate(p)
  for _, m in ipairs(gateParts(p)) do RTH.Send("G", m) end
end
function RTH.BroadcastRoster()
  for _, m in ipairs(rosterParts()) do RTH.Send("N", m) end
end

-- ---------------------------------------------------------------- what we receive
local function member(name)
  local m = RTH.db.group.members[name]
  if not m then
    m = { recipes = {}, profs = {} }
    RTH.db.group.members[name] = m
  end
  return m
end

-- every number in a message goes through int(): a whole number of at most 10 digits, inside its limits.
-- (plain tonumber takes "nan", "inf" and "1e309" - a nan table key throws, a huge part count freezes the game)
local function int(s, lo, hi)
  if type(s) ~= "string" or #s > 10 or not s:match("^%-?%d+$") then return nil end
  local n = tonumber(s)
  if (lo and n < lo) or (hi and n > hi) then return nil end
  return n
end
local MAX_PARTS = 50   -- no real message list is anywhere near this long

local handlers = {}
local channelOf   -- the channel of the message being handled (set by the CHAT_MSG_ADDON dispatcher below)
handlers.H = function(sender)
  -- answer the challenge group; the guild master also answers anyone (they need the rules to join)
  if RTH.InGroup(sender) or RTH.IsGuildMember(sender) or RTH.IAmRulesKeeper() then
    answerHellos()
    RTH.lastHelloHeardT = time()   -- everyone answers this one: our automatic hello can wait (autoHello)
  end
  -- a hello on the GUILD channel from a name not on our guild list: they just joined - fetch the list now
  -- (GUILD_MEMBERS_CHANGED then says hello back, and from then on their messages count)
  if channelOf == "GUILD" and IsInGuild() and not RTH.IsGuildMember(sender) then RTH.ExpectGuildJoin(sender) end
  -- the guild master just came online: ask for what the journey log got while one of us was away
  if RTH.IsRulesKeeper(sender) and not RTH.IAmRulesKeeper() then
    RTH.After("askLog", 3 + math.random() * 3, function() RTH.AskLog() end)
  end
end
-- version: "1.2.10" > "1.2.9"
local function newer(a, b)
  local pa, pb = {}, {}
  for n in tostring(a):gmatch("%d+") do pa[#pa + 1] = tonumber(n) end
  for n in tostring(b):gmatch("%d+") do pb[#pb + 1] = tonumber(n) end
  for i = 1, math.max(#pa, #pb) do
    local x, y = pa[i] or 0, pb[i] or 0
    if x ~= y then return x > y end
  end
  return false
end
RTH.VersionNewer = newer
-- guild members heard in the last 14 days with another RTH version than ours (main window header, /rth sync):
-- older = they should update, newer = we should. Each list: { name, version }, sorted by name.
function RTH.VersionReport()
  local older, newerList = {}, {}
  for name, m in pairs(RTH.db.group.members) do
    local v = m.version
    if type(v) == "string" and v:match("^%d+[%.%d]*$") and type(m.seen) == "number" and time() - m.seen < 14 * 86400
      and RTH.IsGuildMember(name) and name ~= RTH.PlayerName() then
      if newer(RTH.VERSION, v) then older[#older + 1] = { name = name, version = v }
      elseif newer(v, RTH.VERSION) then newerList[#newerList + 1] = { name = name, version = v } end
    end
  end
  local byName = function(a, b) return a.name < b.name end
  table.sort(older, byName); table.sort(newerList, byName)
  return older, newerList
end
local updateTold = false
handlers.V = function(sender, version)
  if RTH.InGroup(sender) or RTH.IsGuildMember(sender) then   -- not for strangers
    local m = member(sender)
    if m.version ~= version then m.version = version; RTH.Fire("MEMBERS_CHANGED") end
  end
  if not updateTold and newer(version, RTH.VERSION) then
    updateTold = true
    RTH.Print("|cffffd040a newer Road to Halion (" .. tostring(version) .. ") is used by " .. sender
      .. " - you have " .. RTH.VERSION .. ". Please update.|r")
  end
end
handlers.S = function(sender, phase, bad, check, reason, level)
  local m = member(sender)
  m.level = int(level, 1, 100) or m.level   -- 1.3.0+ sends the character level (older copies: nothing)
  -- (1.4 sends its own phase here: lower than before = a gate change took one back - the furthest may drop)
  local newPhase = int(phase, 1, RTH.MAX_PHASE)
  local wentDown = m.gate and m.gate.v14 and newPhase and type(m.phase) == "number" and newPhase < m.phase
  m.phase, m.gearBad, m.gearCheck, m.gearReason, m.seen = int(phase, 1, RTH.MAX_PHASE), int(bad, 0) or 0, int(check, 0) or 0, reason, time()
  m.statusT = time()   -- when their RTH last reported their gear (Raid Check: the newer of this and a gear scan wins)
  m.off = nil          -- reporting again = back in the challenge
  if wentDown then RTH.NoteMemberPhase(sender, newPhase, true) end
  RTH.Fire("MEMBERS_CHANGED")
end
-- they switched the challenge off on that character: no longer in the group
handlers.O = function(sender)
  local m = RTH.db.group.members[sender]
  if not m then return end
  m.off = time()
  RTH.Fire("MEMBERS_CHANGED")
end
handlers.P = function(sender, list)
  local m = member(sender)
  m.profs, m.profMax = {}, {}
  -- skill:rank:max (older versions send skill:rank)
  for entry in (list or ""):gmatch("[^,]+") do
    local skill, rank, max = entry:match("^(%d+):(%d+):?(%d*)$")
    skill = int(skill, 1)
    if skill then
      m.profs[skill] = int(rank, 0)
      m.profMax[skill] = int(max, 0)
    end
  end
  -- this is their WHOLE profession list: one that's missing was dropped. Forget its recipes and trade link -
  -- their RTH stops sending them, so nothing else would (the craft rule would still say they can make it)
  for spell, skill in pairs(m.recipeSkill or {}) do
    if not m.profs[skill] then m.recipes[spell] = nil; m.recipeSkill[spell] = nil end
  end
  for skill in pairs(m.tradeLinks or {}) do
    if not m.profs[skill] then m.tradeLinks[skill] = nil end
  end
  m.seen = time()
  m.off = nil   -- reporting again = back in the challenge
  RTH.Fire("MEMBERS_CHANGED")
end
handlers.C = function(sender, list)
  local m = member(sender)
  m.cooldowns = {}
  for name, left in (list or ""):gmatch("([^,:]+):(%d+)") do
    left = int(left, 0, 31 * 86400)
    if left then m.cooldowns[name] = left > 0 and (time() + left) or 0 end
  end
  RTH.Fire("MEMBERS_CHANGED")
end
handlers.T = function(sender, skill, body)
  skill = int(skill, 1)
  -- trade:<spell>:<rank>:<max>:<player GUID, hex>:<recipe bits>
  if not skill or not body or not body:match("^trade:%d+:%d+:%d+:%x+:[%w+/=]+$") then return end
  local m = member(sender)
  m.tradeLinks = m.tradeLinks or {}
  m.tradeLinks[skill] = body
end
handlers.R = function(sender, skill, part, parts, ids)
  local m = member(sender)
  skill, part, parts = int(skill, 1), int(part, 1, MAX_PARTS), int(parts, 1, MAX_PARTS)
  if not skill or not part or not parts then return end
  if part == 1 then
    -- drop this profession's old recipes; keep the others
    m.recipeSkill = m.recipeSkill or {}
    for spell, s in pairs(m.recipeSkill) do
      if s == skill then m.recipes[spell] = nil; m.recipeSkill[spell] = nil end
    end
  end
  m.recipeSkill = m.recipeSkill or {}
  for id in (ids or ""):gmatch("[^,]+") do
    local spell = #id <= 6 and tonumber(id, 36)
    if spell then m.recipes[spell] = true; m.recipeSkill[spell] = skill end
  end
  if part == parts then RTH.Fire("MEMBERS_CHANGED") end
end
-- (1.3's "U" - the guild master's phase unlock - is gone: each character opens its own phase, "D" below.)
-- a list sent in parts (G gate, N core list): kept by part number until every part of the batch is here
-- (raid + guild deliver each part twice: the same part again just replaces itself)
local pending = {}
local function collect(key, batch, part, parts, items)
  if type(batch) ~= "string" or not batch:match("^%d+$") or #batch > 12 or not part or not parts or part > parts then
    return nil
  end
  local p = pending[key]
  if not p or p.batch ~= batch then p = { batch = batch, parts = parts, got = {} }; pending[key] = p end
  if p.parts ~= parts then return nil end
  p.got[part] = items
  for i = 1, parts do if not p.got[i] then return nil end end
  pending[key] = nil
  local all = {}
  for i = 1, parts do for _, x in ipairs(p.got[i]) do all[#all + 1] = x end end
  return all
end

-- relayed = a member passing on its copy of the guild master's gate ("u|G|..." below)
local function applyGate(sender, relayed, phase, opt, batch, part, parts, ids)
  local p = int(phase, 1, RTH.MAX_PHASE)
  if not p or not RTH.db.group.gates[p] then return end
  local g = RTH.db.group
  g.gateRelayed = g.gateRelayed or {}
  if relayed and g.gateSynced[p] then return end   -- we have the guild master's own: a copy never replaces it
  local list = {}
  for id in (ids or ""):gmatch("%d+") do
    local n = int(id, 1)
    if n then list[#list + 1] = n end
  end
  list = collect(sender .. (relayed and ">uG" or ">G") .. p, batch, int(part, 1, MAX_PARTS), int(parts, 1, MAX_PARTS), list)
  if not list then return end
  -- the guild master's RTH resends every gate on hello: only say something when it really changed
  local old = g.gates[p]
  local same = old.opt == (opt == "1") and #old.ids == #list
  if same then for i, id in ipairs(list) do if old.ids[i] ~= id then same = false; break end end end
  if relayed then
    g.gateRelayed[p] = sender   -- a copy, until the guild master's own arrives
    if same then return end
    g.gates[p] = { ids = list, opt = opt == "1" }
    RTH.Fire("GATES_CHANGED")
    return
  end
  local known = g.gateSynced[p]
  g.gateSynced[p] = true
  g.gateRelayed[p] = nil
  if same then return end
  g.gates[p] = { ids = list, opt = opt == "1" }
  -- the first copy (a new member joining) is not a change: only say so when an earlier gate was replaced
  if known then RTH.Print(sender .. " changed the unlock gate of " .. RTH.PhaseLabel(p)) end
  RTH.Fire("GATES_CHANGED")
end
handlers.G = function(sender, ...)
  if not RTH.IsRulesKeeper(sender) then return end
  applyGate(sender, false, ...)
end
local function applyRoster(sender, relayed, rank, batch, part, parts, names)
  local g = RTH.db.group
  if relayed and g.rosterSynced then return end   -- we have the guild master's own list
  local list = {}
  for n in (names or ""):gmatch("[^,]+") do list[#list + 1] = n end
  list = collect(sender .. (relayed and ">uN" or ">N"), batch, int(part, 1, MAX_PARTS), int(parts, 1, MAX_PARTS), list)
  if not list then return end
  local r = g.roster
  r.rank = int(rank, 0, 9)
  r.names = list
  if relayed then g.rosterRelayed = sender else g.rosterSynced, g.rosterRelayed = true, nil end
  RTH.Fire("ROSTER_CHANGED")
end
handlers.N = function(sender, ...)
  if not RTH.IsRulesKeeper(sender) then return end
  applyRoster(sender, false, ...)
end

-- ---------------------------------------------------------------- the guild master's rules, passed on (2026-11-22)
-- A member who installs RTH while the guild master is offline has the DEFAULT gates and an empty core list until
-- the guild master logs in. So, ~35 s after login, when some gate (or the core list) never came from the guild
-- master and the guild master is offline: "q" on the guild. Everyone holding the guild master's own rules answers
-- after a random 2-7 s - on the guild channel, so the first answer cancels everybody else's: "u|G|<G fields>" per
-- gate and "u|N|<N fields>" (the same fields as the guild master's own G / N). A copy is used only while that gate
-- or list never came from the guild master (g.gateRelayed / g.rosterRelayed = who passed it on); the guild master's
-- own replaces it when they're online, and a phase passed on a different gate is checked again then
-- (GATES_CHANGED). Trust: guild members, like the rest of the relay (user's choice 2026-11-20).
local rulesAnswerAt, rulesHeard = 0, 0   -- rulesHeard: how many "u" copies we've heard (someone answered)
local function haveGMRules()
  local g = RTH.db.group
  for p = 1, RTH.MAX_PHASE do if not g.gateSynced[p] then return false end end
  return true
end
function RTH.AskRules()
  if not RTH.Active() or not IsInGuild() or RTH.IAmRulesKeeper() or haveGMRules() and RTH.db.group.rosterSynced then return end
  local gm = RTH.GuildMasterName()
  if gm and RTH.GuildOnline(gm) == true then return end   -- the guild master sends the real rules with the hello
  RTH.Send("q", "1")
end
handlers.q = function(sender)
  if not RTH.IsGuildMember(sender) or not haveGMRules() then return end
  if GetTime() - rulesAnswerAt < 60 then return end   -- answered someone a moment ago
  local wait = 2 + math.random() * 5
  local heardBefore = rulesHeard
  RTH.After("rulesAnswer", wait, function()
    if rulesHeard ~= heardBefore then return end   -- someone else answered first
    rulesAnswerAt = GetTime()
    for p = 1, RTH.MAX_PHASE do
      for _, m in ipairs(gateParts(p)) do RTH.Send("u", "G|" .. m) end
    end
    if RTH.db.group.rosterSynced then
      for _, m in ipairs(rosterParts()) do RTH.Send("u", "N|" .. m) end
    end
  end)
end
handlers.u = function(sender, sub, ...)
  rulesHeard = rulesHeard + 1
  if not RTH.IsGuildMember(sender) or RTH.IsRulesKeeper(sender) then return end   -- (the GM sends G / N itself)
  local g = RTH.db.group
  local wasCopy = next(g.gateRelayed or {}) or g.rosterRelayed
  if sub == "G" then applyGate(sender, true, ...) elseif sub == "N" then applyRoster(sender, true, ...) end
  if not wasCopy and (next(g.gateRelayed or {}) or g.rosterRelayed) then
    RTH.Print("using " .. sender .. "'s copy of the guild master's rules (gates, core list) until the guild master is online")
  end
end
RTH.Listen("LOGIN", function() RTH.After("rulesAsk", 35, RTH.AskRules) end)
-- only bosses / dungeons this version knows (a broken key would write a junk kill into the log)
local function bossInfo(key)
  local b = key and RTH.BOSS[key]
  local map = not b and key and tonumber(key:match("^d:(%d+)$"))
  if map and RTH_Dungeons[map] then b = { name = RTH_Dungeons[map].name, phase = RTH_Dungeons[map].phase, dungeon = true } end
  return b
end

handlers.K = function(sender, key, heroic, wipes, stars)
  local b = bossInfo(key)
  if not b then return end
  local name = b.name
  -- the same kill seen by us (we were there) or by someone else in the last 15 minutes is one kill
  for i = #RTH.db.group.kills, math.max(1, #RTH.db.group.kills - 20), -1 do
    local k = RTH.db.group.kills[i]
    if k.key == key and time() - k.t < 900 then return end
  end
  table.insert(RTH.db.group.kills, {
    t = time(), rt = time(), d = date("%Y-%m-%d"), key = key, name = name, heroic = heroic == "1", phase = b.phase, kind = b.dungeon and "dungeon" or nil,
    wipes = int(wipes, 0) or 0, roster = {}, subs = 0, stars = {}, starCount = int(stars, 0) or 0, by = sender, synced = true,
  })
  RTH.Fire("KILL")
end

-- ---------------------------------------------------------------- journey log catch-up (user rule 2026-11-18)
-- The log syncs live (K, B), so what happened while you were offline never reached you. The guild master's log
-- is the record: a member asks ("W|since" = when it last caught up) at login / joining a group / when the GM
-- logs in, and the GM's RTH sends what's newer (max 30 days, 60 entries) as "X" whispers through the queue.
--   X|k|time|key|heroic|wipes|stars|by     X|b|time|who|text     X|e|cursor|count|more (the end of a batch)
--   X|n|breakTime|who|breakKey|noteTime|note   (the GM's comment on a break: see "comments" below)
local CATCHUP_DAYS, CATCHUP_MAX = 30, 60
-- "|1" = this account never had the full list of deletes (fix 2026-11-22): a player still on an old RTH while the
-- guild master deleted a break moved its catch-up past the delete without taking it - after updating it would
-- never come. The first catch-up asks for ALL deletes (90 days); g.delSync is set at the end of that first page.
local function wantAllDeletes() return RTH.db.group.delSync and "" or "|1" end
function RTH.AskLog()
  if RTH.IAmRulesKeeper() then return end   -- the GM's log IS the record
  RTH.Send("W", tostring(RTH.db.group.logSyncT or 0) .. wantAllDeletes())
end
-- Sent in the order entries REACHED this log (rt), oldest first, CATCHUP_MAX at a time. The end message says where
-- the batch stopped and whether there is more: the member asks again from there, so a new member a month into
-- the challenge gets the whole 30 days, not just the newest 60. "since" and the cursor are both the GM's clock.
handlers.W = function(sender, since, allDeletes)
  if not RTH.IAmRulesKeeper() or not (RTH.InGroup(sender) or RTH.IsGuildMember(sender)) then return end
  local g, now = RTH.db.group, time()
  local from = math.max(int(since, 0) or 0, now - CATCHUP_DAYS * 86400)
  local list = {}
  for _, k in ipairs(g.kills) do
    local rt = k.rt or k.t   -- by when it reached OUR log: an old entry that arrived late still goes out
    if rt >= from then
      list[#list + 1] = { rt = rt, msg = "k|" .. k.t .. "|" .. k.key .. "|" .. (k.heroic and 1 or 0) .. "|" .. (k.wipes or 0)
        .. "|" .. ((k.stars and #k.stars > 0) and #k.stars or (k.starCount or 0)) .. "|" .. tostring(k.by or "?") }
    end
  end
  for _, b in ipairs(g.breaks) do
    local rt = b.rt or b.t
    if rt >= from then
      list[#list + 1] = { rt = rt, msg = "b|" .. b.t .. "|" .. b.who .. "|" .. RTH.BreakForMessage(b.text, 200) }
    end
    -- a comment written (or removed) since then, also on an older break - sorted by when it was written, so it
    -- always comes after its break
    if b.noteT and b.noteT >= from then
      list[#list + 1] = { rt = math.max(b.noteT, rt), note = true, msg = "n|" .. b.t .. "|" .. b.who .. "|"
        .. RTH.BreakKey(b.text) .. "|" .. b.noteT .. "|" .. (b.note or "") }
    end
  end
  -- breaks deleted since then (2026-11-22): the member removes its copy (old versions ignore "d"). A member that
  -- never had the full list ("1") gets every delete, put at the start of this first page.
  for _, d in ipairs(g.deleted or {}) do
    if d.delT >= from or allDeletes == "1" then
      list[#list + 1] = { rt = math.max(d.delT, from), note = true, msg = "d|" .. d.t .. "|" .. d.who .. "|" .. d.key .. "|" .. d.delT }
    end
  end
  -- (same second: the break before its comment)
  table.sort(list, function(a, b)
    if a.rt ~= b.rt then return a.rt < b.rt end
    return not a.note and b.note
  end)
  local more = #list > CATCHUP_MAX
  local n = math.min(#list, CATCHUP_MAX)
  RTH.CancelQueued("X", sender)
  for i = 1, n do RTH.SendQueued("X" .. i, "X", list[i].msg, sender) end
  -- the cursor: where the next batch starts (">=": entries at that exact second come again - the dedupe skips them)
  local cursor = more and list[n].rt or now
  RTH.SendQueued("Xe", "X", "e|" .. cursor .. "|" .. n .. "|" .. (more and 1 or 0), sender)
end

local function insertByTime(list, rec)   -- the log is in time order (the Log tab shows it newest first)
  local i = #list
  while i >= 1 and (list[i].t or 0) > rec.t do i = i - 1 end
  table.insert(list, i + 1, rec)
end
-- one log entry from a catch-up (X from the GM, Z from a member): checked, skipped if we have it, put in time order.
-- Returns "k" / "b" when it was added.
local function addEntry(sender, kind, t, ...)
  local g = RTH.db.group
  t = int(t, 1)
  if not t or t > time() + 3600 then return nil end
  if kind == "k" then
    local key, heroic, wipes, stars, by = ...
    local b = bossInfo(key)
    if not b then return nil end
    for _, k in ipairs(g.kills) do
      if k.key == key and math.abs((k.t or 0) - t) < 900 then return nil end   -- already have this kill
    end
    insertByTime(g.kills, {
      t = t, rt = time(), d = date("%Y-%m-%d", t), key = key, name = b.name, heroic = heroic == "1", phase = b.phase,
      kind = b.dungeon and "dungeon" or nil, wipes = int(wipes, 0) or 0, roster = {}, subs = 0, stars = {},
      starCount = int(stars, 0) or 0, by = (by and by ~= "" and by) or sender, synced = true,
    })
    return "k"
  elseif kind == "b" then
    local who = ...
    local text = table.concat({ select(2, ...) }, "|")   -- the text is the whole rest (links have "|" in them)
    if type(who) ~= "string" or who == "" or text == "" then return nil end
    if RTH.IsBreakDeleted(who, text, t) then return nil end   -- the guild master deleted it
    for _, b in ipairs(g.breaks) do
      if b.who == who and math.abs((b.t or 0) - t) < 600 and RTH.SameBreakText(b.text, text) then return nil end   -- already have it
    end
    insertByTime(g.breaks, { t = t, rt = time(), d = date("%Y-%m-%d %H:%M", t), who = who, text = text })
    return "b"
  end
end
-- ---------------------------------------------------------------- the guild master's comments on rule breaks
-- (user rule 2026-11-20) Only the guild master can comment on a rule break; everyone sees the comment under it in
-- the Journey Log. A break has no ID that is the same on every client - its time is when it reached each log, and
-- a long text arrives shortened (BreakForMessage) - so a comment finds its break by who + the first 60 bytes of the
-- plain text (BreakKey) + the closest time within an hour.
local NOTE_BYTES = 130   -- "X|n|time|who|key|noteTime|" + this stays under the 250-byte message limit
RTH.NOTE_BYTES = NOTE_BYTES
function RTH.BreakKey(text)
  local s = tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"):gsub("|", "/")
  return cutBytes(s, 60)
end
local function cleanNote(note)
  note = tostring(note or ""):gsub("[\r\n\t]", " "):gsub("|", "/"):gsub("^%s+", ""):gsub("%s+$", "")
  return cutBytes(note, NOTE_BYTES)
end
local function findBreak(t, who, key)
  local best, bestD
  for _, b in ipairs(RTH.db.group.breaks) do
    if b.who == who and RTH.BreakKey(b.text) == key then
      local d = math.abs((b.t or 0) - t)
      if d < 3600 and (not bestD or d < bestD) then best, bestD = b, d end
    end
  end
  return best
end
-- store a comment from the guild master; noteT = when it was written (the GM's clock). Returns the break.
local function applyNote(sender, t, who, key, noteT, note)
  t = int(t, 1)
  if not t or type(who) ~= "string" or who == "" or type(key) ~= "string" then return nil end
  local b = findBreak(t, who, key)
  if not b then return nil end
  noteT = int(noteT, 1) or time()
  if b.noteT and b.noteT > noteT then return nil end   -- we already have a newer comment
  note = cleanNote(note)
  if (b.note or "") == note then b.noteT = noteT; return nil end   -- nothing new (raid + guild send it twice)
  b.note = note ~= "" and note or nil
  b.noteT, b.noteBy = noteT, sender
  return b
end
-- the guild master writes (or, with an empty text, removes) a comment on a break in their log
function RTH.SetBreakNote(b, note)
  if not (b and RTH.IAmRulesKeeper()) then return false end
  note = cleanNote(note)
  if (b.note or "") == note then return false end
  b.note = note ~= "" and note or nil
  b.noteT, b.noteBy = time(), RTH.PlayerName()
  RTH.Send("M", b.t .. "|" .. b.who .. "|" .. RTH.BreakKey(b.text) .. "|" .. b.noteT .. "|" .. note)
  RTH.Fire("BREAKS_CHANGED")
  return true
end
handlers.M = function(sender, t, who, key, noteT, ...)
  if not RTH.IsRulesKeeper(sender) then return end   -- only the guild master comments
  local b = applyNote(sender, t, who, key, noteT, table.concat({ ... }, "|"))
  if not b then return end
  if b.note then
    RTH.Print(sender .. " commented on " .. (who == RTH.PlayerName() and "your" or (who .. "'s")) .. " rule break: |cffffd040" .. b.note .. "|r")
  end
  RTH.Fire("BREAKS_CHANGED")
end

-- ---------------------------------------------------------------- the guild master deletes a rule break
-- (user rule 2026-11-22) Only the guild master can delete a break; it goes for everyone. Found like a comment (who +
-- BreakKey + the closest time within an hour). A record stays (g.deleted, 90 days) so a copy that comes back later
-- (a catch-up from someone who still has it, the relay, a member's own report to the GM) is dropped - but a NEW
-- break with the same text after the delete still counts.
local function deletedMatch(d, who, key, t)
  return d.who == who and d.key == key and math.abs((d.t or 0) - t) < 3600 and t <= d.delT + 600
end
function RTH.IsBreakDeleted(who, text, t)
  local key = RTH.BreakKey(text)
  for _, d in ipairs(RTH.db.group.deleted or {}) do
    if deletedMatch(d, who, key, t) then return true end
  end
  return false
end
-- remove every copy of the break and remember the delete. Returns true when something changed.
local function applyDelete(sender, t, who, key, delT)
  t, delT = int(t, 1), int(delT, 1)
  if not t or not delT or type(who) ~= "string" or who == "" or type(key) ~= "string" or key == "" then return false end
  local g = RTH.db.group
  g.deleted = g.deleted or {}
  local changed, known = false, false
  for _, d in ipairs(g.deleted) do
    if d.who == who and d.key == key and math.abs(d.t - t) < 3600 then known = true end
  end
  if not known then
    g.deleted[#g.deleted + 1] = { t = t, who = who, key = key, delT = delT, by = sender }
    changed = true
  end
  local removedT
  for i = #g.breaks, 1, -1 do
    local b = g.breaks[i]
    if b.who == who and RTH.BreakKey(b.text) == key and math.abs((b.t or 0) - t) < 3600 then
      removedT = removedT or b.t
      table.remove(g.breaks, i)
      changed = true
    end
  end
  -- the break's star comes off our own kills too, and gate kills it spoiled count again (2026-11-22). Also when
  -- the delete arrives late (catch-up / relay): our copy of the break may already be gone, the stars aren't.
  if RTH.ForgetBreakStars and RTH.ForgetBreakStars(who, key, removedT or t) > 0 then changed = true end
  return changed
end
function RTH.DeleteBreak(b)
  if not (b and RTH.IAmRulesKeeper()) then return false end
  local t, who, key, now = b.t, b.who, RTH.BreakKey(b.text), time()
  applyDelete(RTH.PlayerName(), tostring(t), who, key, tostring(now))
  RTH.Send("E", t .. "|" .. who .. "|" .. key .. "|" .. now)
  RTH.Fire("BREAKS_CHANGED")
  return true
end
handlers.E = function(sender, t, who, key, delT)
  if not RTH.IsRulesKeeper(sender) then return end   -- only the guild master deletes
  if applyDelete(sender, t, who, key, delT) then
    RTH.Print(sender .. " (guild master) deleted " .. (who == RTH.PlayerName() and "your" or (tostring(who) .. "'s"))
      .. " rule break: " .. tostring(key))
    RTH.Fire("BREAKS_CHANGED")
  end
end

-- a kill's new star count (2026-11-22): "k|killTime|bossKey|stars", sent by the player whose RTH RECORDED the kill
-- after a deleted break took one of its stars off. Our copy of their kill (synced: only a count) follows - only
-- from that player, and only for a copy of a kill they recorded (k.by).
handlers.k = function(sender, killT, key, n)
  killT, n = int(killT, 1), int(n, 0, 99)
  if not killT or not n or type(key) ~= "string" then return end
  for _, k in ipairs(RTH.db.group.kills) do
    if k.synced and k.key == key and k.by == sender and math.abs((k.t or 0) - killT) < 900 then
      if k.starCount ~= n then
        k.starCount = n
        RTH.Fire("KILL")
      end
      return
    end
  end
end

local caught = { kills = 0, breaks = 0, notes = 0, pages = 0 }
handlers.X = function(sender, kind, t, ...)
  if not RTH.IsRulesKeeper(sender) then return end   -- only the guild master's log is the record
  local g = RTH.db.group
  if kind == "n" then
    local who, key, noteT = ...
    if applyNote(sender, t, who, key, noteT, table.concat({ select(4, ...) }, "|")) then caught.notes = caught.notes + 1 end
    return
  end
  if kind == "d" then   -- a break the guild master deleted while we were away
    local who, key, delT = ...
    if applyDelete(sender, t, who, key, delT) then caught.deleted = (caught.deleted or 0) + 1 end
    return
  end
  if kind == "e" then
    g.delSync = true   -- the first page carried every delete: later pages (and catch-ups) only ask for new ones
    -- remember the GM's time (not ours: player clocks differ, and "since" is compared with the GM's entries)
    g.logSyncT = int(t, 0) or g.logSyncT
    local _, more = ...
    if more == "1" and caught.pages < 10 then   -- more to come: ask for the next batch (10 batches at most)
      caught.pages = caught.pages + 1
      RTH.After("askLogMore", 1, function() RTH.AskLog() end)
      return
    end
    caught.pages = 0
    if (caught.deleted or 0) > 0 then
      RTH.Print("the guild master deleted " .. caught.deleted .. " rule break" .. (caught.deleted == 1 and "" or "s") .. " while you were away")
      caught.deleted = 0
      RTH.Fire("BREAKS_CHANGED")
    end
    if caught.kills + caught.breaks + caught.notes > 0 then
      RTH.Print("caught up on the journey log: " .. caught.kills .. " kill" .. (caught.kills == 1 and "" or "s") .. " and "
        .. caught.breaks .. " rule break" .. (caught.breaks == 1 and "" or "s")
        .. (caught.notes > 0 and (" (+" .. caught.notes .. " comment" .. (caught.notes == 1 and "" or "s") .. " from the guild master)") or "")
        .. " from while you were away")
      RTH.Fire("KILL"); RTH.Fire("BREAKS_CHANGED")
    end
    caught.kills, caught.breaks, caught.notes = 0, 0, 0
    return
  end
  local added = addEntry(sender, kind, t, ...)
  if added == "k" then caught.kills = caught.kills + 1 elseif added == "b" then caught.breaks = caught.breaks + 1 end
end

-- The other way: the GM's own gaps. What members logged while the GM's RTH was offline (their own breaks,
-- kills their RTH saw) never reached the GM - and the GM's log is the source of every catch-up. So when the GM
-- comes online it asks ("Y|since" = when the GM's RTH last ran, GM's clock); each member whispers back ITS OWN
-- entries newer than that ("Z|k|..." / "Z|b|...", same fields as X). Only your own: a Z break must be the
-- sender's, a Z kill is recorded as theirs - nobody can put someone else's break into the record.
function RTH.AskMembersLog()
  if not RTH.IAmRulesKeeper() then return end
  RTH.Send("Y", tostring(RTH.db.group.keeperSeenT or (time() - CATCHUP_DAYS * 86400)))
end
handlers.Y = function(sender, since)
  if not RTH.IsRulesKeeper(sender) or RTH.IAmRulesKeeper() then return end
  local g, me, now = RTH.db.group, RTH.PlayerName(), time()
  local from = math.max((int(since, 0) or 0) - 600, now - CATCHUP_DAYS * 86400)
  local list = {}
  for _, k in ipairs(g.kills) do
    if k.t > from and not k.synced and k.by == me then   -- kills OUR RTH recorded (not ones others sent us)
      list[#list + 1] = { t = k.t, msg = "k|" .. k.t .. "|" .. k.key .. "|" .. (k.heroic and 1 or 0) .. "|" .. (k.wipes or 0)
        .. "|" .. (k.stars and #k.stars or 0) .. "|" .. me }
    end
  end
  for _, b in ipairs(g.breaks) do
    if b.t > from and b.who == me then
      list[#list + 1] = { t = b.t, msg = "b|" .. b.t .. "|" .. me .. "|" .. RTH.BreakForMessage(b.text, 200) }
    end
  end
  table.sort(list, function(a, b) return a.t < b.t end)
  RTH.CancelQueued("Z", sender)
  for i = math.max(1, #list - CATCHUP_MAX + 1), #list do RTH.SendQueued("Z" .. i, "Z", list[i].msg, sender) end
end
handlers.Z = function(sender, kind, t, ...)
  if not RTH.IAmRulesKeeper() or not (RTH.InGroup(sender) or RTH.IsGuildMember(sender)) then return end
  if kind == "b" and (...) ~= sender then return end                 -- only their own breaks
  if kind == "k" then
    local key, heroic, wipes, stars = ...
    if addEntry(sender, "k", t, key, heroic, wipes, stars, sender) then RTH.After("zFire", 1, function() RTH.Fire("KILL") end) end
  elseif kind == "b" and addEntry(sender, "b", t, ...) then
    RTH.After("zFireB", 1, function() RTH.Fire("BREAKS_CHANGED") end)
  end
end
-- a character's phase report (1.4.0): phase | have | need | gate fingerprint | finished gates "1,2"
-- (1.3's "A" reports are ignored: an outdated RTH shows as "?" until it's updated)
handlers.D = function(sender, phase, have, need, sig, passes, worn)
  local p = int(phase, 1, RTH.MAX_PHASE)
  if not p then return end
  local m = member(sender)
  local wentDown = type(m.phase) == "number" and p < m.phase and m.gate and m.gate.v14   -- a gate change took one back
  m.worn = int(worn, 0, RTH.MAX_PHASE)   -- newest gear phase they've worn at 80 (gate lock)
  local done = {}
  for q in (passes or ""):gmatch("%d+") do
    q = int(q, 1, RTH.MAX_PHASE)
    if q then done[q] = true end
  end
  m.phase, m.passes = p, done
  m.gate = { phase = p, have = int(have, 0, 999) or 0, need = int(need, 0, 999) or 0,
             sig = int(sig, 0) and sig or nil, t = time(), v14 = true }   -- sig: which gate it was checked against
  m.behind = nil
  RTH.NoteMemberPhase(sender, p, wentDown)
  RTH.Fire("MEMBERS_CHANGED")
end
-- the guild master passed someone's gates by hand (/rth gate Name 2): only the named character takes it
handlers.J = function(sender, target, phase)
  if not RTH.IsRulesKeeper(sender) or type(target) ~= "string" or target:lower() ~= RTH.PlayerName():lower() then return end
  local p = int(phase, 1, RTH.MAX_PHASE - 1)
  if p then RTH.ApplyGrant(p, sender) end
end
handlers.L = function(sender, part, parts, list)
  local m = member(sender)
  part, parts = int(part, 1, MAX_PARTS), int(parts, 1, MAX_PARTS)
  if not part or not parts then return end
  -- stored by part number: the same part arriving twice (raid + guild) replaces itself
  if part == 1 or not m.lockParts then m.lockParts = {} end
  local entries = {}
  for name, id, left, size, heroic in (list or ""):gmatch("([^,:]+):(%d+):(%d+):(%d+):(%d)") do
    id, left, size = int(id, 0), int(left, 0, 31 * 86400), int(size, 1, 40)
    if id and left and size then
      entries[#entries + 1] = { name = name, id = id, ends = time() + left, size = size, heroic = heroic == "1" }
    end
  end
  m.lockParts[part] = entries
  m.lockouts = {}
  for i = 1, parts do
    for _, l in ipairs(m.lockParts[i] or {}) do m.lockouts[#m.lockouts + 1] = l end
  end
  RTH.Fire("MEMBERS_CHANGED")
end
handlers.Q = function(sender, i, n, slot, item, s, reason)
  local m = member(sender)
  i, n = int(i, 0, MAX_PARTS), int(n, 0, MAX_PARTS)
  if not i or not n then return end
  if i <= 1 then m.gearList, m.gearListT = {}, time() end
  if i >= 1 and item and item:match("^item:[%-%d:]+$") then
    m.gearList = m.gearList or {}
    m.gearList[i] = { slot = int(slot, 0, 30), item = item, bad = s == "b", reason = reason or "" }   -- by index: a repeat replaces itself
  end
  if i == n then RTH.Fire("MEMBERS_CHANGED") end
end
-- item search: a group member asks, everyone in the group answers with what they hold
handlers.F = function(sender, text)
  if not text or #text < 3 then return end
  text = cutBytes(text, 40)   -- UTF-8 safe (was :sub)
  local found = RTH.FindItems(text)
  local parts = {}
  for _, e in ipairs(found) do
    if #parts >= 12 then break end
    parts[#parts + 1] = e.id .. ":" .. e.bags .. ":" .. e.bank
  end
  RTH.SendQueued("f" .. text, "f", text .. "|" .. table.concat(parts, ","), sender)
end
handlers.f = function(sender, text, list)
  local s = RTH.itemSearch
  if not s or not text or text:lower() ~= s.query:lower() then return end   -- an answer to an older search
  local items = {}
  for id, bags, bank in (list or ""):gmatch("(%d+):(%d+):(%d+)") do
    id, bags, bank = int(id, 1), int(bags, 0), int(bank, 0)
    if id and bags and bank then items[#items + 1] = { id = id, bags = bags, bank = bank } end
  end
  s.results[sender] = items
  RTH.Fire("ITEM_SEARCH")
end
handlers.B = function(sender, ...)
  -- the text is the whole rest of the message: item links and colours have "|" in them, which the
  -- message was split on - put it back together
  local text = table.concat({ ... }, "|")
  RTH.AddBreak(sender, text ~= "" and text or "?", true)
end

-- ---------------------------------------------------------------- relay (user request 2026-11-20)
-- Addon messages only reach players who are online. So A, who heard B, passes B's copy on to C when C logs in after
-- B went offline - and the journey log too, also while the guild master is away (the user picked: trust guild
-- members; when B comes back, B's own messages replace the copy).
--   1. C, ~20 s after login: "I" on GUILD - every player C has a copy of, with how old that copy is.
--   2. Everyone with a NEWER copy of an offline player whispers C a short offer "o" (plus how many log entries
--      they have from the time C was away). Nobody sends the copies yet.
--   3. C waits a few seconds, picks the freshest offer per player and asks only that sender ("g"); the log from
--      the one with the most entries ("w") - unless the guild master is online, who sends it the old way (W/X).
-- Times travel as AGES ("seconds ago"), never clock times: players' PC clocks differ, a duration doesn't.
local RELAY_FRESHER = 60          -- an offer must be at least this much newer than our copy
local RELAY_WAIT = 8              -- how long C collects offers
local RELAY_MAX_NAMES = 40        -- players one "g" request can ask for
local relayAsk                    -- C's side: { offers = { sender = { log = n, names = { name = age } } } }
local relayLog = { peer = nil, kills = 0, breaks = 0, notes = 0, pages = 0 }

-- a player whose copy we may pass on: in the guild (or the core list), not us, not the asker, still in the
-- challenge, heard in the last 14 days, and offline (an online player answers the hello itself)
local function relayable(name, m, asker)
  return type(m) == "table" and name ~= RTH.PlayerName() and name ~= asker and (RTH.IsGuildMember(name) or RTH.IsCore(name))
    and not m.off and type(m.seen) == "number" and time() - m.seen < 14 * 86400 and RTH.GuildOnline(name) ~= true
end

local function logCount(window)
  local from, n = time() - window, 0
  for _, k in ipairs(RTH.db.group.kills) do if (k.rt or k.t) >= from then n = n + 1 end end
  for _, b in ipairs(RTH.db.group.breaks) do
    if (b.rt or b.t) >= from then n = n + 1 end
    if b.noteT and b.noteT >= from then n = n + 1 end
  end
  return n
end

-- 1. C asks (login, joining a guild)
function RTH.RelayAsk()
  if not (RTH.Active() and IsInGuild()) then return end
  local g, now, list = RTH.db.group, time(), {}
  for name, m in pairs(g.members) do
    if type(m) == "table" and type(m.seen) == "number" and now - m.seen < 14 * 86400 then
      list[#list + 1] = name .. ":" .. math.max(0, now - m.seen)
    end
  end
  -- the log: from our last relay catch-up (10 minutes overlap - the dedupe skips repeats), 30 days at most
  local window = math.min(CATCHUP_DAYS * 86400, now - (g.logPeerT or 0) + 600)
  relayAsk = { offers = {}, window = window }
  local chunks, batch = chunked(list, 200), newBatch()
  for i, c in ipairs(chunks) do
    RTH.SendQueued("I" .. i, "I", batch .. "|" .. i .. "|" .. #chunks .. "|" .. window .. "|" .. c)
  end
  RTH.After("relayPick", RELAY_WAIT + #chunks * 0.25, function() RTH.RelayPick() end)
end

-- 2. everyone else: offer what's newer
handlers.I = function(sender, batch, part, parts, window, list)
  if not IsInGuild() or not RTH.IsGuildMember(sender) then return end
  local items = {}
  for e in (list or ""):gmatch("[^,]+") do items[#items + 1] = e end
  items = collect(sender .. ">I", batch, int(part, 1, MAX_PARTS), int(parts, 1, MAX_PARTS), items)
  if not items then return end
  window = int(window, 0, CATCHUP_DAYS * 86400) or 0
  local theirs = {}
  for _, e in ipairs(items) do
    local name, age = e:match("^(.+):(%d+)$")
    age = int(age, 0)
    if name and age then theirs[name] = age end
  end
  local now, offer = time(), {}
  for name, m in pairs(RTH.db.group.members) do
    if relayable(name, m, sender) then
      local mine = now - m.seen
      if not theirs[name] or theirs[name] > mine + RELAY_FRESHER then offer[#offer + 1] = name .. ":" .. mine end
    end
  end
  local n = logCount(window)
  if not offer[1] and n == 0 then return end
  -- a short random wait: 20 players answering one login don't all whisper in the same moment
  RTH.After("relayOffer" .. sender, 0.5 + math.random() * 2.5, function()
    RTH.CancelQueued("o", sender)
    for i, c in ipairs(chunked(offer, 200)) do RTH.SendQueued("o" .. i, "o", n .. "|" .. c, sender) end
  end)
end

-- C: collect the offers
handlers.o = function(sender, n, list)
  if not relayAsk or not RTH.IsGuildMember(sender) then return end
  local o = relayAsk.offers[sender] or { log = 0, names = {} }
  relayAsk.offers[sender] = o
  o.log = math.max(o.log, int(n, 0, 99999) or 0)
  for name, age in (list or ""):gmatch("([^,:]+):(%d+)") do
    age = int(age, 0)
    if age then o.names[name] = age end
  end
end

-- 3. C: the freshest copy of each player from ONE sender; the log from the sender with the most entries
function RTH.RelayPick()
  local ask = relayAsk
  relayAsk = nil
  if not ask then return end
  local now, best = time(), {}
  for sender, o in pairs(ask.offers) do
    for name, age in pairs(o.names) do
      local m = RTH.db.group.members[name]
      local ours = m and type(m.seen) == "number" and (now - m.seen) or math.huge
      if name ~= RTH.PlayerName() and age + RELAY_FRESHER < ours and (not best[name] or age < best[name].age) then
        best[name] = { sender = sender, age = age }
      end
    end
  end
  local per = {}
  for name, b in pairs(best) do
    per[b.sender] = per[b.sender] or {}
    if #per[b.sender] < RELAY_MAX_NAMES then table.insert(per[b.sender], name) end
  end
  for sender, names in pairs(per) do
    table.sort(names)
    for i, c in ipairs(chunked(names, 200)) do RTH.SendQueued("g" .. i, "g", c, sender) end
  end
  -- the log: while the guild master is online their own catch-up (W, sent with the hello) covers it;
  -- otherwise the member with the most entries from the time we were away
  local gm = RTH.GuildMasterName()
  if gm and gm ~= RTH.PlayerName() and RTH.GuildOnline(gm) == true then return end
  local peer, most = nil, 0
  for sender, o in pairs(ask.offers) do
    if o.log > most then peer, most = sender, o.log end
  end
  if peer then
    relayLog.peer, relayLog.pages = peer, 0
    relayLog.kills, relayLog.breaks, relayLog.notes = 0, 0, 0
    RTH.SendQueued("w", "w", tostring(ask.window) .. wantAllDeletes(), peer)
  end
end

-- a stored player -> the same messages their own RTH sends, each wrapped as "s|name|age|kind|..."
local function relaySend(to, name, age, kind, i, payload)
  local msg = name .. "|" .. age .. "|" .. kind .. "|" .. payload
  if #msg + 2 > 250 then return end   -- too long with the name in front: skip it (never send it cut)
  RTH.SendQueued("s" .. name .. kind .. i, "s", msg, to)
end
local function relayMember(to, name)
  local m = RTH.db.group.members[name]
  if not relayable(name, m, to) then return end
  local now = time()
  local age = now - m.seen
  if m.version then relaySend(to, name, age, "V", 1, tostring(m.version)) end
  if next(m.profs or {}) then
    local parts = {}
    for skill, rank in pairs(m.profs) do parts[#parts + 1] = skill .. ":" .. rank .. ":" .. ((m.profMax or {})[skill] or 0) end
    relaySend(to, name, age, "P", 1, table.concat(parts, ","))
    -- recipes per profession, in smaller parts than the player's own (the name goes in front)
    local bySkill = {}
    for spell, skill in pairs(m.recipeSkill or {}) do
      if m.recipes[spell] then bySkill[skill] = bySkill[skill] or {}; table.insert(bySkill[skill], b36(spell)) end
    end
    for skill, ids in pairs(bySkill) do
      table.sort(ids)
      local chunks = chunked(ids, 160)
      for i, c in ipairs(chunks) do relaySend(to, name, age, "R", skill .. "." .. i, skill .. "|" .. i .. "|" .. #chunks .. "|" .. c) end
    end
  end
  for skill, body in pairs(m.tradeLinks or {}) do relaySend(to, name, age, "T", skill, skill .. "|" .. body) end
  if m.cooldowns and next(m.cooldowns) then
    local parts = {}
    for cd, ready in pairs(m.cooldowns) do parts[#parts + 1] = cd .. ":" .. (ready > 0 and math.max(0, ready - now) or 0) end
    relaySend(to, name, age, "C", 1, table.concat(parts, ","))
  end
  if m.statusT then
    relaySend(to, name, age, "S", 1, tostring(m.phase or "") .. "|" .. (m.gearBad or 0) .. "|" .. (m.gearCheck or 0) .. "|"
      .. cutBytes(tostring(m.gearReason or ""):gsub("|", "/"), 150) .. "|" .. (m.level or 0))
  end
  if m.gearListT then
    local list = {}
    for i = 1, MAX_PARTS do if m.gearList and m.gearList[i] then list[#list + 1] = m.gearList[i] end end
    if not list[1] then relaySend(to, name, age, "Q", 0, "0|0") end
    for i, e in ipairs(list) do
      relaySend(to, name, age, "Q", i, i .. "|" .. #list .. "|" .. (e.slot or 0) .. "|" .. e.item .. "|" .. (e.bad and "b" or "c")
        .. "|" .. cutBytes((tostring(e.reason or ""):gsub("|", "/")), 110))   -- UTF-8 safe (was :sub)
    end
  end
  local locks = {}
  for _, l in ipairs(m.lockouts or {}) do
    if l.ends > now then
      locks[#locks + 1] = l.name .. ":" .. tostring(l.id) .. ":" .. (l.ends - now) .. ":" .. l.size .. ":" .. (l.heroic and 1 or 0)
    end
  end
  local lchunks = chunked(locks, 160)
  if locks[1] then
    for i, c in ipairs(lchunks) do relaySend(to, name, age, "L", i, i .. "|" .. #lchunks .. "|" .. c) end
  end
  if m.gate and m.gate.v14 and type(m.phase) == "number" then
    local passes = {}
    for q in pairs(m.passes or {}) do passes[#passes + 1] = q end
    table.sort(passes)
    relaySend(to, name, age, "D", 1, m.phase .. "|" .. m.gate.have .. "|" .. m.gate.need .. "|" .. tostring(m.gate.sig or "")
      .. "|" .. table.concat(passes, ",") .. "|" .. tostring(m.worn or ""))
  end
end

-- A: C picked us for these players
handlers.g = function(sender, list)
  if not RTH.IsGuildMember(sender) then return end
  local n = 0
  for name in (list or ""):gmatch("[^,]+") do
    n = n + 1
    if n > RELAY_MAX_NAMES then break end
    relayMember(sender, name)
  end
end

-- C: a copy of an offline player. Used only when it's newer than ours and the player isn't online right now.
local RELAY_KINDS = { S = true, P = true, R = true, C = true, T = true, L = true, Q = true, D = true }
handlers.s = function(sender, name, age, kind, ...)
  age = int(age, 0, 14 * 86400)
  if not age or type(name) ~= "string" or name == "" or name == RTH.PlayerName() or name == sender then return end
  if not (RTH.IsGuildMember(sender) and (RTH.IsGuildMember(name) or RTH.IsCore(name))) then return end
  if RTH.GuildOnline(name) == true then return end   -- they're here: their own messages count
  local heard = time() - age
  local old = RTH.db.group.members[name]
  local prevSeen = old and type(old.seen) == "number" and old.seen or nil
  if prevSeen and prevSeen > heard + 30 then return end   -- ours is newer
  if kind == "V" then
    local v = ...
    if type(v) == "string" and v:match("^%d+[%.%d]*$") then member(name).version = v end
  elseif RELAY_KINDS[kind] then
    handlers[kind](name, ...)
  else
    return
  end
  -- heard = when the sender last heard THEM, not now (S and P just wrote "now": it's only a copy)
  local m = member(name)
  m.seen = math.max(heard, prevSeen or 0)
  if kind == "S" then m.statusT = heard end
  if kind == "Q" then m.gearListT = heard end
end

-- A: C asks for the log since `window` seconds ago (oldest first, CATCHUP_MAX at a time, like the GM's W)
handlers.w = function(sender, window, allDeletes)
  if not RTH.IsGuildMember(sender) then return end
  window = int(window, 0, CATCHUP_DAYS * 86400)
  if not window then return end
  local g, now = RTH.db.group, time()
  local from = now - window
  local list = {}
  for _, k in ipairs(g.kills) do
    local rt = k.rt or k.t
    if rt >= from then
      list[#list + 1] = { rt = rt, msg = "k|" .. math.max(0, now - k.t) .. "|" .. k.key .. "|" .. (k.heroic and 1 or 0) .. "|" .. (k.wipes or 0)
        .. "|" .. ((k.stars and #k.stars > 0) and #k.stars or (k.starCount or 0)) .. "|" .. tostring(k.by or "?") }
    end
  end
  for _, b in ipairs(g.breaks) do
    local rt = b.rt or b.t
    if rt >= from then
      list[#list + 1] = { rt = rt, msg = "b|" .. math.max(0, now - b.t) .. "|" .. b.who .. "|" .. RTH.BreakForMessage(b.text, 200) }
    end
    if b.noteT and b.noteT >= from and b.noteBy then
      list[#list + 1] = { rt = math.max(b.noteT, rt), note = true, msg = "n|" .. math.max(0, now - b.t) .. "|" .. b.who .. "|"
        .. RTH.BreakKey(b.text) .. "|" .. math.max(0, now - b.noteT) .. "|" .. b.noteBy .. "|" .. (b.note or "") }
    end
  end
  -- the guild master's deletes, passed on (ages, like everything in the relay)
  for _, d in ipairs(g.deleted or {}) do
    if (d.delT >= from or allDeletes == "1") and d.by then   -- "1": the asker never had the full list
      list[#list + 1] = { rt = math.max(d.delT, from), note = true, msg = "d|" .. math.max(0, now - d.t) .. "|" .. d.who .. "|" .. d.key
        .. "|" .. math.max(0, now - d.delT) .. "|" .. d.by }
    end
  end
  table.sort(list, function(a, b)
    if a.rt ~= b.rt then return a.rt < b.rt end
    return not a.note and b.note
  end)
  local more = #list > CATCHUP_MAX
  local n = math.min(#list, CATCHUP_MAX)
  RTH.CancelQueued("x", sender)
  for i = 1, n do RTH.SendQueued("x" .. i, "x", list[i].msg, sender) end
  -- where the next page starts, as an age (">=": entries at that second come again - the dedupe skips them)
  local nextWindow = more and math.max(0, now - list[n].rt) or 0
  RTH.SendQueued("xe", "x", "e|" .. n .. "|" .. (more and 1 or 0) .. "|" .. nextWindow, sender)
end

-- C: a log entry from the member we asked (nobody else's)
handlers.x = function(sender, kind, a, ...)
  if sender ~= relayLog.peer then return end
  local now = time()
  if kind == "e" then
    local more, nextWindow = ...
    nextWindow = int(nextWindow, 0, CATCHUP_DAYS * 86400)
    if more == "1" and nextWindow and relayLog.pages < 10 then
      relayLog.pages = relayLog.pages + 1
      RTH.After("relayLogMore", 1, function() RTH.SendQueued("w", "w", tostring(nextWindow), sender) end)
      return
    end
    RTH.db.group.logPeerT = now
    RTH.db.group.delSync = true   -- that page carried every delete the peer had
    local k, b, n = relayLog.kills, relayLog.breaks, relayLog.notes
    if k + b + n > 0 then
      RTH.Print("caught up on the journey log from " .. sender .. ": " .. k .. " kill" .. (k == 1 and "" or "s") .. " and "
        .. b .. " rule break" .. (b == 1 and "" or "s") .. (n > 0 and (" (+" .. n .. " comment" .. (n == 1 and "" or "s") .. ")") or ""))
      RTH.Fire("KILL"); RTH.Fire("BREAKS_CHANGED")
    end
    relayLog.peer, relayLog.kills, relayLog.breaks, relayLog.notes, relayLog.pages = nil, 0, 0, 0, 0
    return
  end
  local age = int(a, 0, CATCHUP_DAYS * 86400 + 86400)
  if not age then return end
  if kind == "n" then
    local who, key, noteAge, noteBy = ...
    noteAge = int(noteAge, 0, CATCHUP_DAYS * 86400 + 86400)
    if not noteAge or not RTH.IsRulesKeeper(noteBy) then return end   -- only the guild master's comments
    local b = applyNote(noteBy, tostring(now - age), who, key, tostring(now - noteAge), table.concat({ select(5, ...) }, "|"))
    if b then relayLog.notes = relayLog.notes + 1 end
    return
  end
  if kind == "d" then   -- a delete, only when the guild master made it
    local who, key, delAge, by = ...
    delAge = int(delAge, 0, 90 * 86400)
    if not delAge or not RTH.IsRulesKeeper(by) then return end
    if applyDelete(by, tostring(now - age), who, key, tostring(now - delAge)) then RTH.Fire("BREAKS_CHANGED") end
    return
  end
  local added = addEntry(sender, kind, tostring(now - age), ...)
  if added == "k" then relayLog.kills = relayLog.kills + 1 elseif added == "b" then relayLog.breaks = relayLog.breaks + 1 end
end

-- /rth ping: a self-test that needs nobody else. WoW sends your own guild addon messages back to you, so if
-- this one comes back the guild channel carries RTH's messages; every other RTH online answers with its name.
local pingAt
function RTH.Ping()
  if not IsInGuild() then RTH.Print("|cffff4040not in a guild|r - RTH talks over the guild channel"); return end
  pingAt = GetTime()
  SendAddonMessage(PREFIX, toWire("~|ping|" .. RTH.VERSION), "GUILD")
  RTH.Print("ping sent - waiting 5 seconds for answers...")
  RTH.After("pingResult", 5, function()
    if pingAt then
      RTH.Print("|cffff4040your own test message did NOT come back|r - the server isn't passing RTH's guild messages."
        .. " Tell whoever made RTH (send them this line).")
    end
    pingAt = nil
  end)
end

RTH.On("CHAT_MSG_ADDON", function(prefix, msg, channel, sender)
  if prefix ~= PREFIX or not RTH.db then return end
  msg = fromWire(msg)
  local ping, pingVersion = msg:match("^~|(%a+)|(.*)$")
  if ping == "ping" then
    if sender == RTH.PlayerName() then
      if pingAt then RTH.Print("|cff40ff40the guild channel works|r - your own test message came back"); pingAt = nil end
    else
      SendAddonMessage(PREFIX, toWire("~|pong|" .. RTH.VERSION .. (RTH.Active() and "" or " (not in the challenge)")), "WHISPER", sender)
    end
    return
  elseif ping == "pong" then
    RTH.Print("  " .. sender .. " answered - RTH " .. tostring(pingVersion))
    return
  end
  if sender == RTH.PlayerName() then return end
  if not RTH.Active() then return end
  local kind, rest = msg:match("^(%a)|?(.*)$")
  local fn = kind and handlers[kind]
  if not fn then return end
  -- H (anyone may ask); G, N and J only from the guild master (checked inside); the rest only from the group
  -- guild members are always heard (that's how a new one's RTH gets counted - RTH.HasRTH); others only in the group
  if kind ~= "H" and kind ~= "J" and kind ~= "G" and kind ~= "N" and kind ~= "V" and not RTH.InGroup(sender)
    and not RTH.IsGuildMember(sender) then
    return
  end
  local args = {}
  for a in (rest .. "|"):gmatch("([^|]*)|") do args[#args + 1] = a end
  channelOf = channel
  fn(sender, unpack(args))
  channelOf = nil
end)

-- ---------------------------------------------------------------- when to send
RTH.Listen("LOGIN", function() RTH.After("hello", 8, RTH.SayHello) end)
-- automatic refreshes (user request 2026-11-18) - quiet, no chat. A hello makes every RTH in the guild answer, so
-- an automatic one waits at least 45 s after the last hello (a raid zoning in together = one round, not 25).
-- Someone else's hello in that time counts too: it already made everyone answer (to all of us), so five people
-- zoning into a dungeon together cost one round, not five.
local function autoHello()
  if RTH.lastHelloT and time() - RTH.lastHelloT < 45 then return end
  if RTH.lastHelloHeardT and time() - RTH.lastHelloHeardT < 45 then return end
  RTH.SayHello()
end
-- a minute after login: again, for whoever logged in meanwhile and in case the guild list loaded late
RTH.Listen("LOGIN", function() RTH.After("hello2", 60, autoHello) end)
-- after the login hello's answers (online players' own data): copies of the players who are offline (relay)
RTH.Listen("LOGIN", function() RTH.After("relayAsk", 25, RTH.RelayAsk) end)
-- entering a dungeon or raid: everyone's newest gear, professions and lockouts before the first pull
local lastInstance
RTH.On("PLAYER_ENTERING_WORLD", function()
  RTH.After("helloZone", 5, function()
    local inside, kind = IsInInstance()
    local name = inside and (kind == "party" or kind == "raid") and GetInstanceInfo() or nil
    -- no hello yet = we just logged in / reloaded: the login hello covers it (no double round)
    if name and name ~= lastInstance and RTH.lastHelloT then autoHello() end
    lastInstance = name
  end)
end)
-- the guild changed: someone new = say hello so their RTH and ours swap everything (their messages count now
-- that they're on our guild list); someone left = they drop out of the group and the version list
RTH.Listen("GUILD_MEMBERS_CHANGED", function(joined, left)
  -- they said hello when they joined, before our list had them (so we didn't answer): send ours now. No hello of
  -- our own - that would make the whole guild answer again. Joins are rare: no 45 s wait here.
  if joined and joined[1] and RTH.lastHelloT then answerHellos() end
  RTH.Fire("MEMBERS_CHANGED")
end)
-- we joined a guild ourselves: introduce ourselves to it (not the login check - the login hello covers that)
RTH.Listen("JOINED_GUILD", function()
  if RTH.lastHelloT then
    RTH.After("helloGuild", 5, RTH.SayHello)
    RTH.After("relayAskGuild", 25, RTH.RelayAsk)
  end
end)
-- level up: only our own status (level, gear - it counts from 80 - and the phase report); no hello, no answers.
-- Our own marks and gear light change too at 80 (OVERLAYS_TOGGLED / PHASE_CHANGED redraw them).
RTH.On("PLAYER_LEVEL_UP", function()
  RTH.After("sendLevel", 3, function()
    RTH.Send("S", myStatus()); sendGear(); RTH.Send("D", RTH.GateReport())
    RTH.Fire("OVERLAYS_TOGGLED")
    if RTH.UI and RTH.UI.RefreshCurrent then RTH.UI.RefreshCurrent() end
  end)
end)
RTH.Listen("PROFESSIONS_CHANGED", function() RTH.After("sendProfs", 5, function() sendProfessions() end) end)
RTH.Listen("COOLDOWNS_CHANGED", function() RTH.After("sendCds", 3, function() sendCooldowns() end) end)
RTH.On("PLAYER_EQUIPMENT_CHANGED", function() RTH.After("sendStatus", 3, function() RTH.Send("S", myStatus()); sendGear() end) end)
RTH.Listen("LOCKOUTS_CHANGED", function() RTH.After("sendLock", 3, function() sendLockouts() end) end)
RTH.Listen("PHASE_CHANGED", function() RTH.After("sendStatus", 2, function() RTH.Send("S", myStatus()); sendGear() end) end)
-- a new reputation standing can make an arcanum on your gear legal (or show one wasn't): tell the guild
RTH.Listen("REP_CHANGED", function() RTH.After("sendStatus", 2, function() RTH.Send("S", myStatus()); sendGear() end) end)
local lastGroupSize = 0
local function groupChanged()
  local n = math.max(GetNumRaidMembers(), GetNumPartyMembers())
  if n > lastGroupSize then RTH.After("hello", 3, RTH.SayHello) end
  -- the Progress tab's gate line shows only the raid's people when in a raid: redraw it
  if n ~= lastGroupSize and RTH.UI and RTH.UI.RefreshCurrent then RTH.After("uiRefresh", 0.5, RTH.UI.RefreshCurrent) end
  lastGroupSize = n
end
RTH.On("PARTY_MEMBERS_CHANGED", groupChanged)
RTH.On("RAID_ROSTER_UPDATE", groupChanged)
