-- Road to Halion: the rules. Every check returns status ("ok" / "bad" / "check" / nil = nothing to say) + a reason.
local RTH = RTH

local PROF_NAME = {
  [164] = "Blacksmithing", [165] = "Leatherworking", [197] = "Tailoring", [202] = "Engineering",
  [755] = "Jewelcrafting", [333] = "Enchanting", [773] = "Inscription", [171] = "Alchemy",
  -- gathering and secondary (tracked and shown; the gear rules only use the crafting ones)
  [186] = "Mining", [182] = "Herbalism", [393] = "Skinning",
  [185] = "Cooking", [129] = "First Aid", [356] = "Fishing",
}
RTH.PROF_NAME = PROF_NAME

-- Some crafted things are ALSO a random result of a profession spell: Northrend Alchemy Research can give a Crazy
-- Alchemist's Potion, Inscription research gives scrolls (RTH_AlsoMadeBy, Data/Extra.lua). Knowing that spell counts
-- as being able to make the item (bug 2026-11-22: a research potion was called "nobody in the group can make this").
-- Added once here to every recipe list the item has, so every check (use, AH, tooltip, marks) sees it.
do
  local function addTo(list, spells)
    if type(list) ~= "table" then return end
    for _, s in ipairs(spells) do
      local have = false
      for _, x in ipairs(list) do if x == s then have = true break end end
      if not have then list[#list + 1] = s end
    end
  end
  for id, spells in pairs(RTH_AlsoMadeBy or {}) do
    local u = RTH_UseItems and RTH_UseItems[id]
    if u then addTo(u[4], spells) end
    local c = RTH_CraftedConsumables and RTH_CraftedConsumables[id]
    if c then addTo(c.spells, spells) end
    local g = RTH_Gems and RTH_Gems[id]
    if g then addTo(g.spells, spells) end
    addTo(RTH_CraftedOnly and RTH_CraftedOnly[id], spells)
    addTo(RTH_CraftedBy and RTH_CraftedBy[id], spells)
    addTo(RTH_EnchantItemBy and RTH_EnchantItemBy[id], spells)
  end
  -- ItemVersion fixes (2026-11-22): items / recipes that came out in a LATER patch than RTH's own data said (epic
  -- gems and Crusader Orbs 3.2, Primordial Saronite 3.3, new glyphs, 3.3.3 Ahune cloaks...). Raised here, once, in
  -- every table that carries a phase, so every check (bags, AH, use, wearing, 'who can make it') waits for it.
  RTH_ItemPatch, RTH_RecipePatch = RTH_ItemPatch or {}, RTH_RecipePatch or {}   -- (never missing - but never crash)
  for id, p in pairs(RTH_PatchFix or {}) do
    if (RTH_ItemPatch[id] or 1) < p and RTH_ItemPatch[id] ~= 0 then RTH_ItemPatch[id] = p end
    local u = RTH_UseItems and RTH_UseItems[id]
    if u and (u[2] or 1) < p then u[2] = p end
    local c = RTH_CraftedConsumables and RTH_CraftedConsumables[id]
    if c and (c.phase or 1) < p then c.phase = p end
    local g = RTH_Gems and RTH_Gems[id]
    if g and (g.phase or 1) < p then g.phase = p end
  end
  for spell, p in pairs(RTH_RecipeFix or {}) do
    if (RTH_RecipePatch[spell] or 1) < p then RTH_RecipePatch[spell] = p end
  end
end

-- Whose rules a check runs for: nil = this character; CheckGear sets it while checking someone else's gear
-- (Raid Check scan), so an alt that's catching up gets ITS personal phase, not yours.
local phaseWho
local function rulePhase() return RTH.PhaseOf(phaseWho) end
RTH.RulePhase = rulePhase

local function phaseText(p)
  -- open for the guild but not yet for this character (catching up on an earlier gate)
  if p <= RTH.GetPhase() then
    return "catching up - not allowed until " .. RTH.PhaseLabel(p) .. (phaseWho and " for them" or " for you")
  end
  return "not allowed until " .. RTH.PhaseLabel(p)
end

-- ---------------------------------------------------------------- Tome of Cold Weather Flight (user rule 2026-11-21)
-- Account-bound, so one bought on a main could be mailed to every alt. Rule: it only counts when THIS character
-- buys it from the vendor at level 77 or higher; one that came in the mail is a rule break. RTH_CharDB.tome =
-- { ok, t, why }: the last way a Tome reached this character (bought / mailed), saved per character.
local TOME, TOME_LEVEL = 49177, 77
RTH.TOME_ID = TOME
-- (open in every phase: the rule is only about how it reached this character)
local function tomeStatus(ctx)
  if phaseWho then return "ok" end   -- someone else's items: their own RTH judges them
  if ctx == "vendor" then   -- the vendor's listing: may you buy it now?
    local lvl = UnitLevel("player") or 0
    if lvl < TOME_LEVEL then return "bad", "buy the Tome on this character at level " .. TOME_LEVEL .. " (you're " .. lvl .. ")" end
    return "ok"
  end
  local t = RTH.char and RTH.char.tome
  if t and t.ok then return "ok" end
  if t then return "bad", "the Tome " .. t.why .. " - it only counts when this character buys it from the vendor at level " .. TOME_LEVEL end
  return "check", "RTH didn't see this character buy the Tome - only one bought from the vendor on this character at level " .. TOME_LEVEL .. " counts"
end

-- The Tome reaching your bags: a buy (BuyMerchantItem, or PickupMerchantItem = left-click and drop it in a bag) or
-- taking it from a mail. Nothing is decided at the click (no gold, bags full...): only when the count in bags + bank
-- actually goes up.
local pendingTome   -- { kind = "buy" / "mail", t, count, level, sender }
local function tomeComing(kind, sender)
  pendingTome = { kind = kind, t = GetTime(), count = GetItemCount(TOME, true) or 0, level = UnitLevel("player") or 0, sender = sender }
end
local function tomeBuy(index)
  local link = index and GetMerchantItemLink(index)
  if link and RTH.ParseLink(link) == TOME then tomeComing("buy") end
end
RTH.Hook("BuyMerchantItem", tomeBuy)
RTH.Hook("PickupMerchantItem", tomeBuy)
-- index = the mail, a = one attachment (TakeInboxItem) or nil = all of them (AutoLootMailItem)
function RTH.TomeFromMail(index, a)
  local _, _, sender, _, _, _, _, _, _, wasReturned = GetInboxHeaderInfo(index)
  if wasReturned then return end   -- your own mail coming back
  for i = a or 1, a or ATTACHMENTS_MAX_RECEIVE or 12 do
    local link = GetInboxItemLink(index, i)
    if link and RTH.ParseLink(link) == TOME then tomeComing("mail", sender) return end
  end
end
RTH.On("BAG_UPDATE", function()
  local p = pendingTome
  if not p then return end
  if GetTime() - p.t > 60 then pendingTome = nil return end
  if (GetItemCount(TOME, true) or 0) <= p.count then return end
  pendingTome = nil
  local me = RTH.PlayerName()
  if p.kind == "mail" then
    RTH.char.tome = { ok = false, t = time(), why = "came in the mail" .. (p.sender and (" from " .. tostring(p.sender)) or "") }
    RTH.AddBreak(me, "got the Tome of Cold Weather Flight in the mail" .. (p.sender and (" from " .. tostring(p.sender)) or "")
      .. " - it must be bought on this character at level " .. TOME_LEVEL)
  elseif p.level < TOME_LEVEL then
    RTH.char.tome = { ok = false, t = time(), why = "was bought at level " .. p.level }
    RTH.AddBreak(me, "bought the Tome of Cold Weather Flight at level " .. p.level .. " (allowed from level " .. TOME_LEVEL .. ")")
  else
    RTH.char.tome = { ok = true, t = time(), why = "bought at level " .. p.level }
  end
  RTH.Fire("TOME_CHANGED")
end)

-- ---------------------------------------------------------------- links
-- 3.3.5 item string: item:itemID:enchantID:gem1:gem2:gem3:gem4:suffixID:uniqueID:level
function RTH.ParseLink(link)
  if type(link) == "number" then return link, 0, {} end
  if not link then return nil end
  local id, ench, g1, g2, g3, g4 = link:match("item:(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+):(%-?%d+)")
  if not id then
    id = link:match("item:(%d+)")
    return id and tonumber(id), 0, {}
  end
  return tonumber(id), tonumber(ench) or 0, { tonumber(g1) or 0, tonumber(g2) or 0, tonumber(g3) or 0, tonumber(g4) or 0 }
end

-- a gem slot value may be a gem item ID or a gem enchant ID; return the gem item ID either way
local function gemItemFromValue(v)
  if not v or v == 0 then return nil end
  if RTH_Gems[v] then return v end
  local list = RTH_GemByEnchant[v]
  return list and list[1] or nil
end

-- ---------------------------------------------------------------- who can make what
-- recipes of a member: yourself from this character's scans, others from sync
local function memberKnows(name, spell)
  if name == RTH.PlayerName() then
    for _, set in pairs(RTH.char.recipes) do
      if set[spell] then return true end
    end
    return false
  end
  local m = RTH.db.group.members[name]
  return m and m.recipes and m.recipes[spell] and true or false
end

function RTH.RecipeUnlocked(spell)
  return (RTH_RecipePatch[spell] or 1) <= rulePhase()
end


function RTH.HasProfession(skillID)
  return RTH.char.profs[skillID] ~= nil
end

-- ---------------------------------------------------------------- craft rule
-- An enchant, gem, food, flask, glyph... is only allowed when someone in the challenge group can CRAFT it.
-- (Until 2026-11-19 someone also had to GATHER its materials; the guild master dropped that: "only requires
-- that a person can craft them". RTH_CraftGather stays in the data, unused by the rules.)


-- status, reason for "can someone in the group make one of these recipe spells?"
function RTH.CraftStatus(spells, what)
  what = what or "it"
  if not spells or not spells[1] then return nil end
  local me = RTH.PlayerName()
  for _, s in ipairs(spells) do
    if RTH.RecipeUnlocked(s) then
      if memberKnows(me, s) then return "ok", me .. " can make " .. what end
      for name in pairs(RTH.db.group.members) do
        if name ~= me and RTH.InGroup(name) and memberKnows(name, s) then return "ok", name .. " can make " .. what end
      end
    end
  end
  return "bad", "nobody in the group can make " .. what
end

-- consumables and glyphs that can ONLY be crafted (RTH_UseItems): may this character use one?
function RTH.UseStatus(itemOrLink)
  local id = RTH.ParseLink(itemOrLink)
  -- holiday food and drinks (Pilgrim's Bounty dishes, Egg Nog...): fine to use without a cook in the group,
  -- once their patch is open (user rule 2026-11-22)
  local u = id and RTH_UseItems[id]
  local hp = id and RTH_Holiday and RTH_Holiday[id]
  if hp then
    if hp > rulePhase() then return "bad", "holiday item " .. phaseText(hp) end
    if u then return "ok", "holiday item - fine to use, no crafter needed" end
    return nil
  end
  if not u then return nil end
  if u[2] > rulePhase() then return "bad", u[1] .. " " .. phaseText(u[2]) end
  return RTH.CraftStatus(u[4], "this " .. u[1])
end

-- ---------------------------------------------------------------- items

-- ctx: "equip" (worn), "bag" (anything you hold or see), "ah" (Auction House listing)
function RTH.ItemStatus(itemOrLink, ctx, level)   -- level: the wearer's (heirlooms; default yours)
  local id = RTH.ParseLink(itemOrLink)
  if not id then return nil end
  local phase = rulePhase()

  if RTH_Item25Only[id] then return "bad", "25-man loot - never allowed" end
  if id == TOME then return tomeStatus(ctx) end
  -- holiday items (user rule 2026-11-22): allowed, but only from the phase their patch came out
  local hp = RTH_Holiday and RTH_Holiday[id]
  if hp and hp > phase then return "bad", "holiday item " .. phaseText(hp), hp end

  -- recipe items (patterns, plans, designs...): judged by the recipe they teach (RTH_RecipeItems ->
  -- RTH_RecipePatch). Most recipe items aren't in RTH_ItemPatch, so without this a Trial or ICC
  -- pattern looked allowed in phase 1.
  local rec = RTH_RecipeItems[id]
  if rec then
    local rp = math.max(RTH_RecipePatch[rec[1]] or 1, RTH_ItemPatch[id] or 1)
    if rp > phase then return "bad", "recipe " .. phaseText(rp), rp end
    return "ok"
  end

  local p = RTH_ItemPatch[id]
  if p == 0 then return "check", "no known source - check manually" end
  -- crafted gear is never older than the recipes that make it (low-skill / leveling-gear recipes are phase 1 in the data)
  local made = RTH_CraftedBy and RTH_CraftedBy[id]
  if made then
    local m
    for _, s in ipairs(made) do m = math.min(m or 99, RTH_RecipePatch[s] or 1) end
    if m and m < 99 and m > (p or 1) then p = m end
  end
  if p and p > phase then return "bad", phaseText(p), p end

  local gem = RTH_Gems[id]
  if gem and gem.phase > phase then return "bad", "gem " .. phaseText(gem.phase), gem.phase end

  local _, _, quality, _, _, _, _, _, equipLoc = GetItemInfo(id)
  -- (only heirlooms you can WEAR: the rule is about gear; an account-bound book or the like isn't)
  if quality == 7 and equipLoc and equipLoc ~= "" then
    -- (guild master 2026-11-19) wearing one at 80 is only a warning: the rule break comes when a dungeon or raid
    -- boss dies while it's still on (Progress.lua recordKill)
    if ctx == "equip" and (level or UnitLevel("player")) >= 80 then return "check", "heirloom - take it off before a boss (level 80)" end
    return "note", "heirloom - fine while leveling, take it off at level 80 before a boss"
  end
  return "ok"
end

-- ---------------------------------------------------------------- enchants and gems (on YOUR gear)
-- does `who` (nil = you) have this profession? true / false, or nil when unknown (their RTH never reported)
local function hasProf(who, skill)
  if not who or who == RTH.PlayerName() then return RTH.HasProfession(skill) end
  local m = RTH.db.group.members[who]
  if m and m.seen then return (m.profs or {})[skill] ~= nil end   -- their RTH reported: an empty list means none
  return nil
end

-- who: whose gear it is (nil = yours); only matters for profession-only enchants and gems
-- ---------------------------------------------------------------- reputation enchants (user rule 2026-11-19)
-- Arcanums and shoulder inscriptions sold for reputation: EVERY character earns the standing itself. The enchant
-- on the gear is checked against the wearer's own reputation, however the item got to them (bought on a main and
-- sent over, ...). RTH_RepEnchants (Data/Extra.lua): enchant -> { name, { {factionID, standingID, faction}, ... } }.
-- 3.3.5 has no "standing by faction ID": the reputation list is read by name (collapsed headers are opened for the
-- read and closed again, so the Reputation window looks the same). Saved per character.
local STANDING = { "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }
local function standingLabel(id) return _G["FACTION_STANDING_LABEL" .. id] or STANDING[id] or ("standing " .. id) end
local readingRep = false
local readRepAt = -100   -- when our own read finished: its header open / close fires UPDATE_FACTION too
-- light = only what's listed now, no headers opened (keeps what was read before for the hidden ones): used for an
-- event that may come from our own open / close, so a read can never cause the next one
function RTH.ScanReputation(light)
  if readingRep or not (GetNumFactions and GetFactionInfo and RTH.char) then return end
  readingRep = true
  local rep, opened = {}, {}
  if light then for n, st in pairs(RTH.char.rep or {}) do rep[n] = st end end
  local i = 1
  while i <= GetNumFactions() do
    local name, _, standing, _, _, _, _, _, isHeader, isCollapsed, hasRep = GetFactionInfo(i)
    if not light and name and isHeader and isCollapsed and ExpandFactionHeader then ExpandFactionHeader(i); opened[name] = true end
    -- (a header can have its own reputation too: Alliance Vanguard, Horde Expedition)
    if name and standing and (not isHeader or hasRep) then rep[name] = standing end
    i = i + 1
  end
  if CollapseFactionHeader then   -- close what we opened, from the bottom so the list positions stay right
    for j = GetNumFactions(), 1, -1 do
      local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(j)
      if name and isHeader and not isCollapsed and opened[name] then CollapseFactionHeader(j) end
    end
  end
  local old = RTH.char.rep or {}
  local changed = not RTH.char.repScanned
  for n, s in pairs(rep) do if old[n] ~= s then changed = true end end
  RTH.char.rep, RTH.char.repScanned = rep, true
  readingRep = false
  readRepAt = GetTime()
  if changed then RTH.Fire("REP_CHANGED") end
end
RTH.On("PLAYER_LOGIN", function() RTH.After("repScan", 4, RTH.ScanReputation) end)
-- (RTH.After restarts its timer: while grinding rep, one read once it goes quiet. An event just after our own read
-- - which our header open / close causes, now or a frame later - gets a light read, or every read would start the
-- next one, forever.)
RTH.On("UPDATE_FACTION", function()
  if readingRep then return end
  local light = GetTime() - readRepAt < 1   -- maybe our own open / close: a light read can't start another one
  RTH.After("repScan", 2, function() RTH.ScanReputation(light) end)
end)

-- status for a reputation enchant on `who`'s gear (nil = yours). Someone else's reputation can't be seen - their
-- own RTH checks their gear and reports it. nil = not a reputation enchant.
function RTH.RepEnchantStatus(enchantID, who)
  local re = enchantID and RTH_RepEnchants and RTH_RepEnchants[enchantID]
  if not re then return nil end
  if who and who ~= RTH.PlayerName() then return nil end
  if not RTH.char.repScanned then return "check", re[1] .. " needs reputation - RTH hasn't read yours yet" end
  local first
  for _, need in ipairs(re[2]) do
    if (RTH.char.rep[need[3]] or 0) >= need[2] then return "ok" end
    first = first or need
  end
  return "bad", re[1] .. " needs " .. first[3] .. " " .. standingLabel(first[2]) .. " on this character"
end

-- the arcanum / inscription ITEM itself (bags, mail, trade, AH): red when this character lacks the standing, so
-- an alt sees it before using it. item -> enchant from RTH_Enchants' item lists, built once.
local repItemEnchant
function RTH.RepItemStatus(itemOrLink)
  if not RTH_RepEnchants then return nil end
  if not repItemEnchant then
    repItemEnchant = {}
    for ench in pairs(RTH_RepEnchants) do
      local e = RTH_Enchants[ench]
      for _, item in ipairs(e and e.items or {}) do repItemEnchant[item] = ench end
    end
  end
  local id = RTH.ParseLink(itemOrLink)
  local ench = id and repItemEnchant[id]
  if not ench then return nil end
  return RTH.RepEnchantStatus(ench)
end

function RTH.EnchantStatus(enchantID, who)
  local rs, rr = RTH.RepEnchantStatus(enchantID, who)
  if rs == "bad" or rs == "check" then return rs, rr end
  local e = enchantID and RTH_Enchants[enchantID]
  if not e then return rs end   -- ("ok" for a reputation enchant the wearer has earned, else nothing to say)
  if e.phase > rulePhase() then return "bad", "enchant " .. phaseText(e.phase) end
  if e.prof > 0 then
    local has = hasProf(who, e.prof)
    if has == false then return "bad", "enchant only for " .. (PROF_NAME[e.prof] or "its profession") end
    if has == nil then return "check", "enchant only for " .. (PROF_NAME[e.prof] or "its profession") .. " - their professions are unknown" end
  end
  if e.buy then return "ok" end
  -- made directly (Enchanting) or from an item (leg armor, spellthread, scope...): a crafter in the group
  local s, r = RTH.CraftStatus(e.spells, "this enchant")
  if s == "ok" then return s, "enchant: " .. r end
  local firstBad = r
  for _, item in ipairs(e.items) do
    s, r = RTH.CraftStatus(RTH_EnchantItemBy[item], "this enchant")
    if s == "ok" then return s, "enchant: " .. r end
  end
  return "bad", "enchant: " .. (firstBad or r or "nobody in the group can make it")
end

function RTH.GemStatus(gemItem, who)
  local g = gemItem and RTH_Gems[gemItem]
  if not g then return nil end
  if g.phase > rulePhase() then return "bad", "gem " .. phaseText(g.phase) end
  if g.prof > 0 then
    local has = hasProf(who, g.prof)
    if has == false then return "bad", "gem only for " .. (PROF_NAME[g.prof] or "its profession") end
    if has == nil then return "check", "gem only for " .. (PROF_NAME[g.prof] or "its profession") .. " - their professions are unknown" end
  end
  if #g.spells == 0 or g.buy then return "ok" end
  local s, r = RTH.CraftStatus(g.spells, "this gem")
  return s, "gem: " .. r
end

-- extra lines for enchant + gems on a link (used by tooltips and the gear checks): bad lines, check lines.
-- who: whose gear (nil = yours)
function RTH.LinkExtras(link, who)
  local out, checks = {}, {}
  local _, ench, gems = RTH.ParseLink(link)
  if not ench then return out, checks end
  local s, r = RTH.EnchantStatus(ench, who)
  if s == "bad" then out[#out + 1] = r elseif s == "check" then checks[#checks + 1] = r end
  for i = 1, 4 do
    local gid = gemItemFromValue(gems[i])
    if gid then
      local gs, gr = RTH.GemStatus(gid, who)
      local name = GetItemInfo(gid)
      if gs == "bad" then out[#out + 1] = (name and (name .. ": ") or "") .. gr
      elseif gs == "check" then checks[#checks + 1] = (name and (name .. ": ") or "") .. gr end
    end
  end
  return out, checks
end

-- ---------------------------------------------------------------- crafted gear: "Made by"
local scan = CreateFrame("GameTooltip", "RTHScanTooltip", UIParent, "GameTooltipTemplate")
scan:SetOwner(UIParent, "ANCHOR_NONE")
local MADE_BY = "^" .. ITEM_CREATED_BY:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"):gsub("%%%%s", "(.+)") .. "$"

local function makerOfSlot(slot, unit)
  scan:ClearLines()
  scan:SetOwner(UIParent, "ANCHOR_NONE")
  scan:SetInventoryItem(unit or "player", slot)
  for i = 2, scan:NumLines() do
    local fs = _G["RTHScanTooltipTextLeft" .. i]
    local text = fs and fs:GetText()
    local who = text and text:match(MADE_BY)
    if who then return who end
  end
  return nil
end

RTH.MakerOfSlot = makerOfSlot

function RTH.MakerFromTooltip(tt)
  local name = tt:GetName()
  for i = 2, tt:NumLines() do
    local fs = _G[name .. "TextLeft" .. i]
    local text = fs and fs:GetText()
    local who = text and text:match(MADE_BY)
    if who then return who end
  end
  return nil
end

function RTH.CraftedStatus(itemID, maker)
  if not RTH_CraftedBy[itemID] then return nil end
  if not maker then return "check", "crafted item without a maker - check manually" end
  if RTH.InGroup(maker) then return "ok", "made by " .. maker end
  return "bad", "made by " .. maker .. ", who is not in the group"
end

-- ---------------------------------------------------------------- everything you wear
local SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }   -- no shirt (4) / tabard (19)
-- everything worn by `unit` (default: you) against the gear rules. who = their name (professions, "Made by").
-- Also used for inspected group members (Raid Check scan), so nothing here may assume "player".
local function checkGear(unit, who)
  local problems, checks = {}, {}
  if not RTH.GearCounts(unit) then return problems, checks end   -- leveling: gear counts from level 80
  local level = UnitLevel(unit)
  for _, slot in ipairs(SLOTS) do
    local link = GetInventoryItemLink(unit, slot)
    if link then
      local id = RTH.ParseLink(link)
      local s, r = RTH.ItemStatus(link, "equip", level)
      if s == "bad" then problems[#problems + 1] = { slot = slot, link = link, reason = r }
      elseif s == "check" then checks[#checks + 1] = { slot = slot, link = link, reason = r } end
      local cs, cr = RTH.CraftedStatus(id, RTH_CraftedBy[id] and makerOfSlot(slot, unit) or nil)
      if cs == "bad" then problems[#problems + 1] = { slot = slot, link = link, reason = cr }
      elseif cs == "check" then checks[#checks + 1] = { slot = slot, link = link, reason = cr } end
      local bad, chk = RTH.LinkExtras(link, who)
      for _, extra in ipairs(bad) do problems[#problems + 1] = { slot = slot, link = link, reason = extra } end
      for _, extra in ipairs(chk) do checks[#checks + 1] = { slot = slot, link = link, reason = extra } end
    end
  end
  return problems, checks
end
function RTH.CheckGear(unit, who)
  unit = unit or "player"
  -- someone else's gear: their personal phase (pcall so an error can't leave the rules pointed at them)
  local name = who or (unit ~= "player" and RTH.UnitKey(unit)) or nil
  if name == RTH.PlayerName() then name = nil end
  local prev = phaseWho
  phaseWho = name
  local ok, problems, checks = pcall(checkGear, unit, who)
  phaseWho = prev
  if not ok then error(problems, 0) end
  return problems, checks
end
function RTH.CheckEquipped() return RTH.CheckGear("player") end

-- heirlooms you're wearing at level 80 (links): a boss kill with one on is a rule break (Progress.lua), entering a
-- dungeon or raid with one on gets a warning (Progress.lua checkInstance)
function RTH.WornHeirlooms()
  local out = {}
  if (UnitLevel("player") or 0) < RTH.GEAR_LEVEL then return out end
  for slot = 1, 19 do
    local link = GetInventoryItemLink("player", slot)
    local id = link and RTH.ParseLink(link)
    if id and select(3, GetItemInfo(id)) == 7 then out[#out + 1] = link end
  end
  return out
end

-- ---------------------------------------------------------------- Auction House
-- Selling is free. Buying on the AH (guild master's rules 2026-11-18, widened 2026-11-19):
--   1. anything only a profession makes (consumables, glyphs, cut gems, enchant items, crafted gear, and
--      bars / bolts / inks / bags... RTH_CraftedOnly): only when someone in the group can make it (no gatherer
--      needed - GM 2026-11-19);
--   2. gear nobody crafts (BoEs that drop from mobs): yes, when it's open in this phase (never 25-man loot);
--   3. raw materials (the AH's Trade Goods and uncut gems that aren't crafted-only): yes;
--   4. anything else: no.
local function craftSpellsOf(id)
  local c = RTH_CraftedConsumables[id]
  if c then return c.spells, c.phase, "it" end
  local u = RTH_UseItems[id]
  if u then return u[4], u[2], "this " .. u[1] end
  local g = RTH_Gems[id]
  if g and g.spells[1] then return g.spells, g.phase, "this gem" end
  if RTH_EnchantItemBy[id] then return RTH_EnchantItemBy[id], 1, "it" end
  -- crafted gear (raid level), then anything else only a profession makes: bars, bolts, inks, leveling gear,
  -- bags... (RTH_CraftedOnly, GM rule 2026-11-19); phase = its earliest recipe's
  -- ...and what comes OUT of a profession's work (2026-11-21): Darkmoon cards (a random card from the scribe's
  -- recipe) and the decks made from them, Runic Injectors from the Engineering kits... (RTH_CraftedFrom)
  local made = (RTH_CraftedBy and RTH_CraftedBy[id]) or (RTH_CraftedOnly and RTH_CraftedOnly[id])
    or (RTH_CraftedFrom and RTH_CraftedFrom[id])
  if made then
    local p
    for _, s in ipairs(made) do p = math.min(p or 99, RTH_RecipePatch[s] or 1) end
    return made, p or 1, "this item"
  end
end

-- the item's AH category, by the AH's own (localized) names: 6 = Trade Goods, 10 = Gem
local function ahClass(id, index, english)
  local itype = select(6, GetItemInfo(id))
  if not itype then return false end
  return itype == english or itype == (select(index, GetAuctionItemClasses()))
end

-- allowed to anyone (user rule 2026-11-21), checked before the craft rule: vendor-sold food and reagents (anyone can
-- buy them from an NPC anyway, even the potions a profession can also make), pets and mounts (no help in a fight,
-- crafted ones too). The item's phase and 25-man loot still come first.
local AH_ALLOWED = { v = "sold by a vendor", p = "pet", m = "mount" }

function RTH.AHStatus(itemOrLink)
  local id = RTH.ParseLink(itemOrLink)
  if not id then return nil end
  -- whatever the AH allows waits for the phase of the patch it came out in (RTH_AHPatch: vendor food, pets, mounts,
  -- everything else that came after 3.0 - audit 2026-11-22: a 3.2 mount or a 3.3 Battered Hilt was buyable in phase 1)
  local lockP = RTH_AHPatch and RTH_AHPatch[id]
  if lockP and lockP > rulePhase() then return "bad", "AH: " .. phaseText(lockP) end
  local allowed = RTH_AHAllowed and AH_ALLOWED[RTH_AHAllowed[id]]
  if allowed then
    local s, r = RTH.ItemStatus(id, "bag")
    if s == "bad" or s == "check" then return s, "AH: " .. r end
    return "ok", "AH: OK to buy - " .. allowed
  end
  -- holiday items (2026-11-22): fine to buy, crafted ones too, once their patch is open (ItemStatus checks that)
  if RTH_Holiday and RTH_Holiday[id] then
    local s, r = RTH.ItemStatus(id, "bag")
    if s == "bad" or s == "check" then return s, "AH: " .. r end
    return "ok", "AH: OK to buy - holiday item"
  end
  local spells, phase, what = craftSpellsOf(id)
  if spells then
    if phase > rulePhase() then return "bad", "AH: " .. phaseText(phase) end
    local s, r = RTH.CraftStatus(spells, what)
    if s == "ok" then return "ok", "AH: OK to buy - " .. r end
    return "bad", "AH: " .. r
  end
  -- nobody crafts it: the item's own phase (and 25-man loot) first
  local s, r = RTH.ItemStatus(id, "bag")
  if s == "bad" or s == "check" then return s, "AH: " .. r end
  if IsEquippableItem(id) then return "ok", "AH: OK to buy - gear nobody crafts (a drop)" end
  if ahClass(id, 6, "Trade Goods") or ahClass(id, 10, "Gem") then return "ok", "AH: OK to buy - material" end
  -- recipes (2026-11-21): ItemStatus above already said whether the recipe it teaches is open in your phase
  if ahClass(id, 9, "Recipe") then return "ok", "AH: OK to buy - recipe open in your phase" end
  -- everything else (user rule 2026-11-22): fine from the patch it came out in (RTH_AHPatch, checked at the top)
  return "ok", "AH: OK to buy"
end

-- ---------------------------------------------------------------- blocked buttons (trade, AH bid / buyout)
-- User request 2026-11-21: not a hard block - the window still opens, but the button that would break a rule is
-- greyed out and reads "Blocked"; hovering it says why. Blizzard enables these buttons from many places (money
-- typed, selection, accept state...), so we post-hook the BUTTON's own Enable: whatever turned it on, we turn it
-- back off. Any Disable from Blizzard clears our label (a new selection, the trade closing), and the next
-- Enable decides again. why(btn) returns the tooltip lines, or nil when the button may be used.
local function blockState(btn)
  local st = btn.rthBlock
  if st then return st end
  st = { text = btn:GetText() }
  btn.rthBlock = st
  -- a disabled button may not show a tooltip, so a see-through cover over the button shows the reason
  local cover = CreateFrame("Frame", nil, btn:GetParent())
  cover:SetAllPoints(btn)
  cover:SetFrameLevel(btn:GetFrameLevel() + 2)
  cover:EnableMouse(true)
  cover:Hide()
  cover:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Blocked", 1, 0.25, 0.25)
    for _, line in ipairs(st.lines or {}) do GameTooltip:AddLine(line, 1, 0.82, 0, true) end
    GameTooltip:AddLine("Road to Halion", 0.85, 0.64, 0.25)
    GameTooltip:Show()
  end)
  cover:SetScript("OnLeave", function() GameTooltip:Hide() end)
  st.cover = cover
  return st
end
local function unblock(btn)
  local st = btn.rthBlock
  if not st or not st.on then return end
  st.on, st.lines = false, nil
  btn:SetText(st.text)
  st.cover:Hide()
  if GameTooltip:IsOwned(st.cover) then GameTooltip:Hide() end
end
local function blockButton(btn, why)
  if not btn then return end
  local st = blockState(btn)
  RTH.Hook(btn, "Enable", function(self)
    local lines = RTH.Active() and why(self)
    if not lines then unblock(self); return end
    st.on, st.lines = true, lines
    st.busy = true
    self:Disable()
    st.busy = false
    self:SetText("Blocked")
    st.cover:Show()
  end)
  RTH.Hook(btn, "Disable", function(self) if not st.busy then unblock(self) end end)
end

-- Bid / Buyout on the Browse and Bids tabs: blocked when the selected auction is an item you may not buy
-- (RTH.AHStatus "bad"; a yellow "check" item stays buyable). Called once Blizzard_AuctionUI is loaded (Overlay.lua).
function RTH.BlockAHButtons()
  local function ahWhy(listType)
    return function()
      local i = GetSelectedAuctionItem(listType)
      local link = i and i > 0 and GetAuctionItemLink(listType, i)
      local s, r = RTH.AHStatus(link)
      if s ~= "bad" then return nil end
      return { "You may not buy " .. (link or "this item") .. ".", (r:gsub("^AH: ", "")) }
    end
  end
  blockButton(BrowseBidButton, ahWhy("list"))
  blockButton(BrowseBuyoutButton, ahWhy("list"))
  blockButton(BidBidButton, ahWhy("bidder"))
  blockButton(BidBuyoutButton, ahWhy("bidder"))
end

-- Buying is logged when you really BUY: a buyout buys at once; a plain bid only buys if you WIN it (an outbid
-- one gives the gold back and buys nothing - logging it would put a false break in everyone's log). So a bid
-- is remembered (saved: the auction can end while you're offline, 48 h at most) and logged when the
-- "auction won" mail arrives.
local function pendingBids()
  RTH.char.ahBids = RTH.char.ahBids or {}
  local now = time()
  for name, b in pairs(RTH.char.ahBids) do if now - b.t > 3 * 86400 then RTH.char.ahBids[name] = nil end end
  return RTH.char.ahBids
end
RTH.Hook("PlaceAuctionBid", function(listType, index, bid)
  if not RTH.Active() then return end
  local link = GetAuctionItemLink(listType, index)
  local s, r = RTH.AHStatus(link)
  if s ~= "bad" then return end
  local name, _, _, _, _, _, _, _, buyout = GetAuctionItemInfo(listType, index)
  if buyout and buyout > 0 and bid and bid >= buyout then   -- the Buyout button bids the buyout price
    RTH.AddBreak(RTH.PlayerName(), "bought " .. (link or "an item") .. " on the AH (" .. r .. ")")
  elseif name then
    pendingBids()[name] = { link = link, reason = r, t = time() }
    RTH.Print("|cffffd040bid on " .. (link or name) .. " - if you win it, that's a rule break (" .. r .. ")|r")
  end
end)
local function checkWonMails()
  local bids = RTH.char.ahBids
  if not RTH.Active() or not bids or not next(bids) then return end
  for i = 1, GetInboxNumItems() do
    local invoiceType, itemName = GetInboxInvoiceInfo(i)
    local b = invoiceType == "buyer" and itemName and bids[itemName]
    if b then
      bids[itemName] = nil
      RTH.AddBreak(RTH.PlayerName(), "won " .. (b.link or itemName) .. " on the AH (" .. b.reason .. ")")
    end
  end
end
RTH.On("MAIL_INBOX_UPDATE", function() RTH.After("wonMails", 0.5, checkWonMails) end)

-- ---------------------------------------------------------------- gold: none from or to outside the group
-- Gold with any GUILD MEMBER (and the guild bank, which is never checked) is fine (user rule 2026-11-18). Gold from or
-- to anyone outside the guild is a break - except someone on the core list (the guild master's own choice).
local function money(c) return GetCoinText and GetCoinText(c, " ") or (math.floor(c / 10000) .. "g") end
local function groupMate(name)
  if type(name) ~= "string" or name == "" or name:find("-", 1, true) then return false end   -- "Name-Realm": not ours
  -- guild list not loaded yet (first seconds after login): can't tell - never a false break (audit 2026-11-22)
  if IsInGuild() and RTH.GuildRosterKnown and not RTH.GuildRosterKnown() then
    if GuildRoster then GuildRoster() end
    return true
  end
  local exact = RTH.GuildMemberName(name)   -- the guild's spelling: "glorify" typed in the mail box
  return exact ~= nil or RTH.InGroup(name)
end

-- checked BEFORE sending (like the inbox below): once the mail is on its way the amounts can read 0
local function checkSendMail(recipient)
  if groupMate(recipient) then return end
  local m, cod = GetSendMailMoney(), GetSendMailCOD()
  if m and m > 0 then RTH.AddBreak(RTH.PlayerName(), "mailed " .. money(m) .. " to " .. tostring(recipient)) end
  if cod and cod > 0 then RTH.AddBreak(RTH.PlayerName(), "sent a COD mail (" .. money(cod) .. ") to " .. tostring(recipient)) end
end
do
  local orig = SendMail
  if orig then
    SendMail = function(recipient, ...)
      if RTH.Active() then pcall(checkSendMail, recipient) end
      return orig(recipient, ...)
    end
  end
end

-- Taking money / paying COD empties the mail, so these are checked BEFORE the call (a post-hook reads 0).
-- The mail functions are not protected, so wrapping them is safe.
local function checkMailMoney(index)
  local _, _, sender, subject, m, _, _, _, _, wasReturned, _, canReply = GetInboxHeaderInfo(index)
  if not m or m <= 0 then return end
  if GetInboxInvoiceInfo(index) then return end   -- AH mails (sales, refunds) carry an invoice: selling is free
  -- the rule is about gold between PLAYERS: NPC / system mails (quest or event rewards) can't be replied to,
  -- and a returned mail is your own gold coming back
  if not canReply or wasReturned then return end
  if groupMate(sender) then return end
  RTH.AddBreak(RTH.PlayerName(), "took " .. money(m) .. " from a mail by " .. tostring(sender) .. " (" .. tostring(subject) .. ")")
end
local function checkMailCOD(index)
  local _, _, sender, _, _, cod = GetInboxHeaderInfo(index)   -- COD can only come from a player
  if cod and cod > 0 and not groupMate(sender) then RTH.AddBreak(RTH.PlayerName(), "paid " .. money(cod) .. " COD to " .. tostring(sender)) end
end
local function preHook(name, check)
  local orig = _G[name]
  if not orig then return end
  _G[name] = function(index, ...)
    if RTH.Active() and index then pcall(check, index, ...) end
    return orig(index, ...)
  end
end
preHook("TakeInboxMoney", checkMailMoney)
preHook("TakeInboxItem", function(index, a) checkMailCOD(index); RTH.TomeFromMail(index, a) end)
preHook("AutoLootMailItem", function(index) checkMailMoney(index); checkMailCOD(index); RTH.TomeFromMail(index) end)   -- shift-click takes both

-- trade: remember the gold on the window when both accept; the break is logged when the trade completes
local tradeSnap
RTH.On("TRADE_ACCEPT_UPDATE", function(me, them)
  if me == 1 or them == 1 then
    tradeSnap = { give = GetPlayerTradeMoney() or 0, get = GetTargetTradeMoney() or 0, who = UnitName("NPC") }
  end
end)
RTH.On("TRADE_CLOSED", function()
  RTH.After("tradeSnapClear", 1, function() tradeSnap = nil end)
  if StaticPopup_Hide then StaticPopup_Hide("RTH_TRADE_OUTSIDER") end
  if TradeFrameTradeButton then unblock(TradeFrameTradeButton) end
end)

-- a trade with someone outside the guild: the Trade button is blocked (user request 2026-11-21; the window still
-- opens, so both sides can see why). Guild members and the core list trade as before.
local function tradeOutsider()
  -- the guild list arrives a few seconds after login: until then everyone would look like an outsider and a
  -- guildmate's trade would be blocked (audit 2026-11-22). Ask for it and don't block meanwhile.
  if IsInGuild() and RTH.GuildRosterKnown and not RTH.GuildRosterKnown() then
    if GuildRoster then GuildRoster() end
    return nil
  end
  local who = RTH.UnitKey("NPC")   -- the trade partner ("Name-Realm" from another realm)
  if who and not groupMate(who) then return who end
end
blockButton(TradeFrameTradeButton, function()
  local who = tradeOutsider()
  return who and { "You can't trade with " .. who .. ": not a guild member." }
end)

-- ...and a popup says so in plain words (user request 2026-11-20). Once per person per session.
local tradeWarned = {}
-- the popup itself, shared by a real trade and "/rth test trade" (so the test shows exactly what a trade shows)
function RTH.ShowTradeWarning(who)
  StaticPopupDialogs.RTH_TRADE_OUTSIDER = StaticPopupDialogs.RTH_TRADE_OUTSIDER or {
    text = "|cffd9a441Road to Halion|r\n\n|cffffd040%s|r is not in your guild, so the Trade button is blocked.\n\n"
      .. "|cffff4040Why:|r giving or getting ANY gold from someone outside the guild breaks the rules - "
      .. "even a small tip for an enchant. Players outside the guild almost always want a tip, so trading "
      .. "with them is turned off.\n\n|cff40ff40Trade with guild members instead|r - gold between guild members is fine.",
    button1 = OKAY or "OK",
    timeout = 0, whileDead = 1, hideOnEscape = 1,
  }
  StaticPopup_Show("RTH_TRADE_OUTSIDER", who)
end
RTH.On("TRADE_SHOW", function()
  if not RTH.Active() then return end
  local who = tradeOutsider()
  if not who or tradeWarned[who] then return end
  tradeWarned[who] = true
  RTH.ShowTradeWarning(who)
end)
RTH.On("UI_INFO_MESSAGE", function(msg)
  if msg ~= ERR_TRADE_COMPLETE or not tradeSnap or not RTH.Active() then return end
  local s = tradeSnap
  tradeSnap = nil
  if groupMate(s.who) then return end
  if s.give > 0 then RTH.AddBreak(RTH.PlayerName(), "traded " .. money(s.give) .. " to " .. tostring(s.who)) end
  if s.get > 0 then RTH.AddBreak(RTH.PlayerName(), "got " .. money(s.get) .. " in a trade from " .. tostring(s.who)) end
end)

-- ---------------------------------------------------------------- using what the group can't make: rule break
-- Food, flasks, potions, glyphs... (RTH_UseSpell: the spell an item casts when used, only for spells no
-- other item shares). The 3.3.5 combat log gives the spell ID; UNIT_SPELLCAST_SUCCEEDED does not.
-- Which item: the one you just clicked (bags, action bar, /use) when its use spell goes off within 3 s -
-- exact even when several items share a spell (Fish Feast / Jillian's Gourmet Fish Feast); otherwise the
-- spell alone when only one crafted-only item casts it (RTH_UseSpell).
local lastUse   -- { id, t }
local lastAny   -- { id, t }: ANY item you used - a few untracked items cast a tracked item's spell (RTH_UseSpellShared)
local function clicked(link)
  local id = link and RTH.ParseLink(link)
  if id and RTH_UseItems[id] then lastUse = { id = id, t = GetTime() } end
  if id then lastAny = { id = id, t = GetTime() } end
end
-- you just used an untracked item that casts this same spell (Potion of Water Breathing = Elixir of Greater Water
-- Breathing's spell): it was that item, not the crafted one (audit 2026-11-22)
local function sharedUse(spellId)
  local list = RTH_UseSpellShared and RTH_UseSpellShared[spellId]
  if not list or not lastAny or GetTime() - lastAny.t >= 3 then return false end
  for _, id in ipairs(list) do if id == lastAny.id then return true end end
  return false
end
RTH.Hook("UseContainerItem", function(bag, slot) clicked(GetContainerItemLink(bag, slot)) end)
RTH.Hook("UseItemByName", function(name) clicked(select(2, GetItemInfo(name or ""))) end)
RTH.Hook("UseAction", function(slot)
  local kind, id = GetActionInfo(slot)
  if kind == "item" then clicked("item:" .. tostring(id)) end
end)

-- Crazy Alchemist's Potion "sometimes has the effect of an additional random potion": the server casts that other
-- potion's spell on you (Wild Magic, Speed...). Those casts belong to the Crazy Alchemist's Potion, not to a potion
-- you drank (bug 2026-11-22: "used Wild Magic" logged right after drinking one).
local CRAZY = 40077
local bonusUntil = 0
local function onlyPotions(items)
  for _, id in ipairs(items) do
    local u = RTH_UseItems[id]
    if not u or u[1] ~= "potion" then return false end
  end
  return true
end

local playerGUID   -- cached: this handler sees every cast in the raid
RTH.On("COMBAT_LOG_EVENT_UNFILTERED", function(_, event, srcGUID, _, _, _, _, _, spellId, spellName)
  if event ~= "SPELL_CAST_SUCCESS" and event ~= "SPELL_AURA_APPLIED" then return end
  playerGUID = playerGUID or UnitGUID("player")
  if srcGUID ~= playerGUID or not RTH.Active() then return end
  local items = RTH_UseSpell[spellId]
  local crazy = RTH_UseItems[CRAZY]
  if crazy and spellId == crazy[3] then
    bonusUntil = GetTime() + 2   -- its random extra potion effect lands right after
  elseif items and GetTime() < bonusUntil and onlyPotions(items) then
    return
  end
  if sharedUse(spellId) then return end
  if lastUse and GetTime() - lastUse.t < 3 and RTH_UseItems[lastUse.id][3] == spellId then
    items = { lastUse.id }
    lastUse = nil
  end
  if not items then return end
  local reason
  for _, id in ipairs(items) do
    local s, r = RTH.UseStatus(id)
    if s ~= "bad" then return end   -- one of the items casting this spell is fine
    reason = reason or r
  end
  local name = GetItemInfo(items[1]) or spellName or "an item"
  RTH.AddBreak(RTH.PlayerName(), "used " .. name .. " (" .. reason .. ")")   -- AddBreak ignores repeats for 10 min
end)

-- a NEW enchant or gem on an item you're wearing (same item in the slot, different enchant/gems) that the
-- group can't make: rule break. Equipping an item that already had one is the gear rule's job (the light).
local gearSnap = {}
local function snapGear(log)
  -- what was worn before, in any slot: two identical weapons (or rings, trinkets) swapping slots is a move,
  -- not a new enchant
  local worn = {}
  for _, s in pairs(gearSnap) do worn[s.id .. ":" .. s.key] = true end
  for slot = 1, 19 do
    local link = GetInventoryItemLink("player", slot)
    local id, ench, gems = RTH.ParseLink(link)
    local key = id and (ench .. ":" .. table.concat(gems, ":")) or nil
    local old = gearSnap[slot]
    local bad = {}
    if id then for _, b in ipairs(RTH.LinkExtras(link)) do bad[b] = true end end
    if log and old and id and old.id == id and old.key ~= key and not worn[id .. ":" .. key] and RTH.Active()
      and RTH.GearCounts("player") then
      for b in pairs(bad) do
        if not old.bad[b] then RTH.AddBreak(RTH.PlayerName(), "put on " .. link .. " - " .. b) end
      end
    end
    gearSnap[slot] = id and { id = id, key = key, bad = bad } or nil
  end
end
RTH.Listen("LOGIN", function() RTH.After("gearSnap", 6, function() snapGear(false) end) end)
RTH.On("UNIT_INVENTORY_CHANGED", function(unit)
  if unit == "player" then RTH.After("gearSnap", 1, function() snapGear(true) end) end
end)

-- ---------------------------------------------------------------- Raid Check: inspect scan (idea from FREAK)
-- Inspects every group member in range, one per second, and runs the real gear rules on what they wear,
-- so players WITHOUT RTH are checked too and the RTH reports are double-checked.
-- RTH.inspect.results[name] = { t, status = ok/bad/check/far/offline, problems, checks }
RTH.inspect = { results = {}, active = false, done = 0, total = 0 }
local scanList, scanIndex, pending

local function inspectWindowOpen() return InspectFrame and InspectFrame:IsShown() end

-- Another addon (GearScore inspects whoever is under the mouse) or the player can inspect someone while we
-- wait for our player's gear: the game then has THEIR gear, and we would file it under our player's name.
-- So any inspect that isn't ours, of someone else, makes the wait stale: that player is tried again.
local ourInspect = false
RTH.Hook("NotifyInspect", function(unit)
  if ourInspect or not pending then return end
  if UnitGUID(unit) ~= pending.guid then pending.stale = true end
end)

local function finishScan()
  RTH.inspect.active, pending = false, nil
  if ClearInspectPlayer and not inspectWindowOpen() then ClearInspectPlayer() end   -- not under the player's own window
  local bad, far = 0, 0
  for _, e in ipairs(scanList or {}) do
    local r = RTH.inspect.results[e.name]
    if r and r.status == "bad" then bad = bad + 1 elseif r and (r.status == "far" or r.status == "offline") then far = far + 1 end
  end
  RTH.Print("gear scan done: " .. #(scanList or {}) .. " checked, " .. (bad > 0 and ("|cffff4040" .. bad .. " with gear not allowed|r") or "|cff40ff40nobody with gear not allowed|r")
    .. (far > 0 and (", " .. far .. " out of range/offline") or ""))
  RTH.Fire("INSPECT_DONE")
end

local step
local function readPending()
  local e = pending
  pending = nil
  if not e then return end
  if e.stale or inspectWindowOpen() then
    -- someone else's inspect came in between: what the game holds may not be this player's gear
    e.stale = nil
    e.tries = (e.tries or 0) + 1
    if e.tries < 3 then scanIndex = scanIndex - 1 end   -- try this player again (3 tries, then move on)
    RTH.After("inspectStep", 1, step)
    return
  end
  if UnitGUID(e.unit) == e.guid then
    local any = false
    for slot = 1, 18 do if GetInventoryItemLink(e.unit, slot) then any = true; break end end
    if any then
      local problems, checks = RTH.CheckGear(e.unit, e.name)
      RTH.inspect.results[e.name] = { t = time(), problems = problems, checks = checks,
        status = problems[1] and "bad" or (checks[1] and "check" or "ok") }
    else
      RTH.inspect.results[e.name] = { t = time(), status = "far", problems = {}, checks = {} }   -- no data came back
    end
  end
  RTH.inspect.done = scanIndex
  RTH.Fire("INSPECT_DONE")
  RTH.After("inspectStep", 1, step)   -- one player per second, like FREAK
end

step = function()
  if not RTH.inspect.active then return end
  -- never take over the Inspect window you're looking at: wait until it's closed
  if InspectFrame and InspectFrame:IsShown() then RTH.After("inspectStep", 1, step); return end
  scanIndex = scanIndex + 1
  local e = scanList[scanIndex]
  if not e then finishScan(); return end
  if UnitGUID(e.unit) ~= e.guid then RTH.After("inspectStep", 0.1, step); return end   -- left / moved in the raid
  if not UnitIsConnected(e.unit) then
    RTH.inspect.results[e.name] = { t = time(), status = "offline", problems = {}, checks = {} }
    RTH.inspect.done = scanIndex
    RTH.After("inspectStep", 0.1, step)
    return
  end
  if not (CanInspect(e.unit) and CheckInteractDistance(e.unit, 1)) then
    RTH.inspect.results[e.name] = { t = time(), status = "far", problems = {}, checks = {} }
    RTH.inspect.done = scanIndex
    RTH.Fire("INSPECT_DONE")
    RTH.After("inspectStep", 0.1, step)
    return
  end
  pending = e
  ourInspect = true
  NotifyInspect(e.unit)
  ourInspect = false
  RTH.After("inspectRead", 1.5, readPending)   -- read anyway if the "ready" event doesn't come
end

RTH.On("INSPECT_TALENT_READY", function()
  if pending then RTH.After("inspectRead", 0.2, readPending) end   -- gear data is in: read it
end)

function RTH.ScanGroupGear()
  if RTH.inspect.active then return end
  scanList = {}
  for _, unit in ipairs(RTH.GroupUnits()) do
    local name = RTH.UnitKey(unit)
    if name and not UnitIsUnit(unit, "player") and UnitIsPlayer(unit) then
      scanList[#scanList + 1] = { unit = unit, guid = UnitGUID(unit), name = name }
    end
  end
  if not scanList[1] then RTH.Print("join a party or raid first - your own gear is checked all the time"); return end
  scanIndex, RTH.inspect.active, RTH.inspect.done, RTH.inspect.total = 0, true, 0, #scanList
  RTH.Fire("INSPECT_DONE")
  step()
end
