-- Road to Halion: your professions and recipes (read from the skill list and the profession window)
local RTH = RTH

-- main spell of each profession (skill line -> Apprentice spell, checked in 3.3.5 Spell.dbc):
-- GetSpellInfo gives its name and icon in the client's language. Herbalism's spell is "Herb Gathering",
-- so the skill list's "Herbalism" only matches through the enUS RTH.PROF_NAME fallback below.
local PROF_SPELL = {
  [164] = 2018, [165] = 2108, [197] = 3908, [202] = 4036, [755] = 25229, [333] = 7411, [773] = 45357, [171] = 2259,
  [186] = 2575, [182] = 2366, [393] = 8613,   -- Mining, Herbalism, Skinning
  [185] = 2550, [129] = 3273, [356] = 7620,   -- Cooking, First Aid, Fishing
}
RTH.PROF_SPELL = PROF_SPELL
local nameToSkill
local function skillByName(name)
  if not nameToSkill then
    nameToSkill = {}
    for skill, spell in pairs(PROF_SPELL) do
      local n = GetSpellInfo(spell)
      if n then nameToSkill[n] = skill end
      nameToSkill[RTH.PROF_NAME[skill]] = skill   -- enUS fallback
    end
    -- Mining's recipe window is called Smelting: whichever name the window reports, it's Mining
    nameToSkill[GetSpellInfo(2656) or "Smelting"] = 186
    nameToSkill["Smelting"] = 186
  end
  return name and nameToSkill[name]
end
RTH.SkillByName = skillByName

-- ---------------------------------------------------------------- skill levels
function RTH.ScanSkills()
  -- an empty skill list means "not loaded yet" (every character has weapon skills at least): reading it as
  -- "every profession unlearned" would wipe all recorded recipes and links
  if GetNumSkillLines() == 0 then return end
  local profs, maxes = {}, {}
  local collapsed = false   -- a collapsed header (Skills tab) hides its lines from GetSkillLineInfo
  for i = 1, GetNumSkillLines() do
    local name, isHeader, isExpanded, rank, _, _, maxRank = GetSkillLineInfo(i)
    if isHeader and not isExpanded then collapsed = true end
    local skill = not isHeader and skillByName(name)
    if skill then profs[skill] = rank; maxes[skill] = maxRank end
  end
  local changed = false
  for k, v in pairs(profs) do
    if RTH.char.profs[k] ~= v or RTH.char.profMax[k] ~= maxes[k] then changed = true end
  end
  if collapsed then
    -- only part of the list is visible: update what we see, never treat the hidden ones as unlearned
    for k, v in pairs(RTH.char.profs) do
      if not profs[k] then profs[k], maxes[k] = v, RTH.char.profMax[k] end
    end
  else
    for k in pairs(RTH.char.profs) do
      if not profs[k] then   -- really unlearned: forget its recipes and link
        changed = true; RTH.char.recipes[k] = nil; RTH.char.tradeLinks[k] = nil
      end
    end
  end
  RTH.char.profs, RTH.char.profMax = profs, maxes
  if changed then RTH.Fire("PROFESSIONS_CHANGED") end
end
RTH.On("SKILL_LINES_CHANGED", function() RTH.After("skills", 1, RTH.ScanSkills) end)
RTH.Listen("LOGIN", function() RTH.After("skills", 2, RTH.ScanSkills) end)

-- The guild can only open your recipe list after you opened that profession window once (no addon may open it
-- for you). One quiet line per login, ~90 s in, naming the windows still to open; nothing once all are shared.
local NO_WINDOW = { [182] = true, [393] = true, [356] = true }   -- Herbalism, Skinning, Fishing
function RTH.UnsharedWindows()
  local out = {}
  for skill, rank in pairs(RTH.char.profs or {}) do
    -- Mining can't be linked (SkillLine CanLink = 0): "shared" = its smelting recipes were read
    local shared = skill == 186 and next(RTH.char.recipes[186] or {}) ~= nil or RTH.char.tradeLinks[skill] ~= nil
    if rank and rank > 0 and not NO_WINDOW[skill] and not shared and RTH.PROF_NAME[skill] then
      -- Mining's window is Smelting (in the spellbook)
      out[#out + 1] = skill == 186 and ((GetSpellInfo(2656) or "Smelting") .. " (Mining)") or RTH.PROF_NAME[skill]
    end
  end
  table.sort(out)
  return out
end
RTH.Listen("LOGIN", function()
  RTH.After("shareHint", 90, function()
    if not RTH.Active() then return end
    local list = RTH.UnsharedWindows()
    if list[1] then
      RTH.Print("|cffffd040open once so the guild can see your recipes:|r " .. table.concat(list, ", "))
    end
  end)
end)

-- ---------------------------------------------------------------- recipes (profession window)
-- Adds what the window lists (collapsed headers or filters may hide some; nothing is ever removed by a scan).
local function scanTradeSkill()
  if IsTradeSkillLinked and IsTradeSkillLinked() then return end   -- someone else's linked profession
  local lineName, lineRank, lineMax = GetTradeSkillLine()
  local skill = skillByName(lineName)
  if not skill then return end
  local set = RTH.char.recipes[skill] or {}
  RTH.char.recipes[skill] = set
  local added = false
  -- the window itself says you have this profession and at what rank: record it here too, so it reaches the
  -- group even when the Skills tab's "Professions" header is collapsed (ScanSkills can't see hidden lines)
  if type(lineRank) == "number" and lineRank > 0 and (RTH.char.profs[skill] ~= lineRank or RTH.char.profMax[skill] ~= lineMax) then
    RTH.char.profs[skill], RTH.char.profMax[skill] = lineRank, lineMax
    added = true
  end
  local cds = {}   -- cooldown name -> seconds left (0 = ready) for the cooldown crafts in this window
  for i = 1, GetNumTradeSkills() do
    local _, kind = GetTradeSkillInfo(i)
    if kind ~= "header" then
      local link = GetTradeSkillRecipeLink(i)
      local spell = link and tonumber(link:match("enchant:(%d+)"))
      if spell and not set[spell] then set[spell] = true; added = true end
      local cd = spell and RTH.CooldownOfSpell(spell)
      if cd then cds[cd] = math.max(cds[cd] or 0, GetTradeSkillCooldown(i) or 0) end
    end
  end
  -- cooldowns: when each one is ready again (all transmutes share one)
  local cdChanged = false
  for name, left in pairs(cds) do
    local ready = left > 0 and (time() + math.floor(left)) or 0
    local old = RTH.char.cooldowns[name]
    if not old or math.abs(old - ready) > 60 then RTH.char.cooldowns[name] = ready; cdChanged = true end
  end
  -- this profession's link (shift-click / "view recipes" for the group); kept without |H...|h so it fits a message
  local list = GetTradeSkillListLink and GetTradeSkillListLink()
  local body = list and list:match("|H(trade:[^|]+)|h")
  if body and RTH.char.tradeLinks[skill] ~= body then RTH.char.tradeLinks[skill] = body; added = true end
  if added then RTH.Fire("PROFESSIONS_CHANGED") end
  if cdChanged then RTH.Fire("COOLDOWNS_CHANGED") end
end

-- ---------------------------------------------------------------- profession cooldowns (RTH_ProfCooldowns)
local cdBySpell
function RTH.CooldownOfSpell(spell)
  if not cdBySpell then
    cdBySpell = {}
    for _, c in ipairs(RTH_ProfCooldowns) do
      for _, s in ipairs(c[4]) do cdBySpell[s] = c[1] end
    end
  end
  return cdBySpell[spell]
end

-- cooldown names a recipe set gives (the person knows at least one of its crafts)
function RTH.CooldownsKnown(recipes)
  local out = {}
  for spell in pairs(recipes or {}) do
    local cd = RTH.CooldownOfSpell(spell)
    if cd then out[cd] = true end
  end
  return out
end

-- everyone in the group with their professions (yourself first): name, profs, profMax, recipes (spell -> true),
-- recipeSkill (spell -> skill, others only), cooldowns (name -> ready time), tradeLinks (skill -> body)
function RTH.GroupCrafters()
  local list = {}
  local me = RTH.PlayerName()
  local mine = {}
  for _, set in pairs(RTH.char.recipes) do for s in pairs(set) do mine[s] = true end end
  list[1] = { name = me, profs = RTH.char.profs, profMax = RTH.char.profMax, recipes = mine,
              cooldowns = RTH.char.cooldowns, tradeLinks = RTH.char.tradeLinks, me = true }
  for name, m in pairs(RTH.db.group.members) do
    if name ~= me and RTH.InGroup(name) and m.profs then
      list[#list + 1] = { name = name, profs = m.profs, profMax = m.profMax or {}, recipes = m.recipes or {},
                          recipeSkill = m.recipeSkill or {}, cooldowns = m.cooldowns or {}, tradeLinks = m.tradeLinks or {} }
    end
  end
  return list
end

-- skill number coloured by progress toward 450 (grey / red / orange / yellow / green, like Altoholic)
local SKILL_COLORS = { "|cffb8b8b8", "|cffff0000", "|cffff7f00", "|cffffff00", "|cff00ff00" }
function RTH.SkillText(rank, max)
  local c = SKILL_COLORS[math.min(5, math.floor((rank or 0) / (450 / 4)) + 1)]
  return c .. (rank or 0) .. ((max and max > 0) and ("|cffb8b8b8/" .. max) or "") .. "|r"
end

-- "5h 20m" / "2d 4h" / "45m"
function RTH.TimeLeft(sec)
  sec = math.max(0, math.floor(sec))
  if sec >= 86400 then return math.floor(sec / 86400) .. "d " .. math.floor(sec % 86400 / 3600) .. "h" end
  if sec >= 3600 then return math.floor(sec / 3600) .. "h " .. math.floor(sec % 3600 / 60) .. "m" end
  return math.max(1, math.floor(sec / 60)) .. "m"
end

-- a "trade:..." body back into a clickable profession link
function RTH.TradeLink(body, skill)
  if not body then return nil end
  local name = (RTH.PROF_SPELL[skill] and GetSpellInfo(RTH.PROF_SPELL[skill])) or RTH.PROF_NAME[skill] or "Profession"
  return "|cffffd000|H" .. body .. "|h[" .. name .. "]|h|r"
end
RTH.On("TRADE_SKILL_SHOW", function() RTH.After("tradeScan", 0.5, scanTradeSkill) end)
RTH.On("TRADE_SKILL_UPDATE", function() RTH.After("tradeScan", 0.5, scanTradeSkill) end)

-- ---------------------------------------------------------------- red tint on locked recipes
local function recipeSpell(index)
  local link = index and GetTradeSkillRecipeLink(index)
  return link and tonumber(link:match("enchant:(%d+)"))
end

-- The rows are reused: Blizzard's update only swaps font objects, which does NOT undo a SetTextColor. So a row
-- tinted red stayed red after scrolling, collapsing a header or switching profession (Engineering's locked rows
-- showed up red in Mining). Every row we tint is flagged and given its own colour back once it isn't locked.
local function untint(button, text)
  if not text.rthRed then return end
  text.rthRed = nil
  if button.isHighlighted then   -- the selected row: Blizzard shows it white (LockHighlight)
    text:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
  elseif button.r then           -- its difficulty colour, set by TradeSkillFrame_Update on this pass
    text:SetTextColor(button.r, button.g, button.b)
  end
end

local function tintTradeSkill()
  local on = RTH.Active() and RTH.db.ui.overlays
  for i = 1, TRADE_SKILLS_DISPLAYED do
    local button = _G["TradeSkillSkill" .. i]
    local text = _G["TradeSkillSkill" .. i .. "Text"]
    if button and text then
      local spell = on and button:IsShown() and recipeSpell(button:GetID())
      if spell and not RTH.RecipeUnlocked(spell) then
        text:SetTextColor(1, 0.2, 0.2)
        text.rthRed = true
      else
        untint(button, text)
      end
    end
  end
  -- the selected recipe's big icon
  local icon = TradeSkillSkillIcon
  if icon then
    local spell = on and recipeSpell(GetTradeSkillSelectionIndex())
    local locked = spell and not RTH.RecipeUnlocked(spell)
    RTH.SetOverlay(icon, locked and "bad" or nil)
  end
end
RTH.TintTradeSkill = tintTradeSkill

-- TradeSkillRankFrame's XML binds <OnEvent function="TradeSkillFrame_Update"/> once at load (a skill-up redraws the
-- list through it), which a hook on the global name never sees: hook that frame's script too
local function hookTradeSkill()
  RTH.Hook("TradeSkillFrame_Update", tintTradeSkill)
  RTH.Hook("TradeSkillFrame_SetSelection", tintTradeSkill)
  if TradeSkillRankFrame then RTH.HookScript(TradeSkillRankFrame, "OnEvent", tintTradeSkill) end
end
RTH.On("ADDON_LOADED", function(name)
  if name == "Blizzard_TradeSkillUI" then hookTradeSkill() end
end)
if IsAddOnLoaded("Blizzard_TradeSkillUI") then hookTradeSkill() end

-- recipe tooltip line (hovering the selected recipe's icon)
RTH.Hook(GameTooltip, "SetTradeSkillItem", function(tt, index, reagent)
  if reagent or not RTH.Active() then return end
  local spell = recipeSpell(index)
  local p = spell and RTH_RecipePatch[spell]
  if p and p > RTH.MyPhase() then   -- your personal phase (catching up = earlier rules)
    RTH.AddTooltipLine(tt, "bad", "recipe locked until " .. RTH.PhaseLabel(p) .. (p <= RTH.GetPhase() and " for you (catching up)" or ""))
  end
end)

-- ---------------------------------------------------------------- group item search (idea from Altoholic)
-- "Who in the group has Frozen Orbs / Eternal Fire...?" Each member's RTH answers from their bags (live)
-- and their bank (remembered from the last time they opened it).
local bankOpen = false
local function scanBank()
  local bank = {}
  local function add(bag)
    for slot = 1, GetContainerNumSlots(bag) or 0 do
      local link = GetContainerItemLink(bag, slot)
      local id = link and RTH.ParseLink(link)
      if id then
        local _, count = GetContainerItemInfo(bag, slot)
        bank[id] = (bank[id] or 0) + (count or 1)
      end
    end
  end
  add(BANK_CONTAINER)
  for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do add(bag) end
  RTH.char.bank = bank
end
RTH.On("BANKFRAME_OPENED", function() bankOpen = true; scanBank() end)
RTH.On("BANKFRAME_CLOSED", function() bankOpen = false end)
RTH.On("PLAYERBANKSLOTS_CHANGED", function() if bankOpen then RTH.After("bankScan", 0.5, scanBank) end end)
RTH.On("BAG_UPDATE", function() if bankOpen then RTH.After("bankScan", 0.5, scanBank) end end)

-- what you hold whose name contains `text`: { { id, bags = n, bank = n }, ... } sorted by name
function RTH.FindItems(text)
  local q = (text or ""):lower()
  local counts = {}
  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) or 0 do
      local link = GetContainerItemLink(bag, slot)
      local id = link and RTH.ParseLink(link)
      if id then
        local _, count = GetContainerItemInfo(bag, slot)
        counts[id] = counts[id] or { bags = 0, bank = 0 }
        counts[id].bags = counts[id].bags + (count or 1)
      end
    end
  end
  for id, n in pairs(RTH.char.bank or {}) do
    counts[id] = counts[id] or { bags = 0, bank = 0 }
    counts[id].bank = counts[id].bank + n
  end
  local out = {}
  for id, c in pairs(counts) do
    local name = GetItemInfo(id)
    if name and name:lower():find(q, 1, true) then out[#out + 1] = { id = id, bags = c.bags, bank = c.bank, name = name } end
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

-- ask the group (RTH.itemSearch.results[name] = items; answers arrive as "f" messages)
function RTH.ItemSearch(text)
  text = RTH.CutBytes and RTH.CutBytes(text or "", 40) or (text or ""):sub(1, 40)   -- UTF-8 safe
  RTH.itemSearch = { query = text, t = time(), results = { [RTH.PlayerName()] = RTH.FindItems(text) } }
  RTH.Send("F", text)
  RTH.Fire("ITEM_SEARCH")
end
