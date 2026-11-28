-- Road to Halion: Professions tab (who has what, skill / max, cooldowns, locked recipes, recipe search).
-- Click a profession to open a player's recipe list (their shared profession link); shift-click links it in chat.
local RTH = RTH
local UI = RTH.UI

-- sections in display order; a string starts a section, a number is a skill line.
-- "COOLDOWNS" lists RTH_ProfCooldowns, only those someone in the group can craft.
local ORDER = {
  "CRAFTING", 171, 164, 333, 202, 773, 755, 165, 197,
  "GATHERING", 186, 182, 393,
  "SECONDARY", 185, 129, 356,
  "COOLDOWNS",
}
local RESULTS = 6   -- search lines: who can make it (blue) + who has it (gold)
local SEARCH_H = 24 + RESULTS * 14 + 8   -- search box + result lines, fixed under the scrolling list
local SEARCH_ICON = "Interface\\Icons\\INV_Misc_Spyglass_02"   -- inside the search box (checked in the 3.3.5 icon list)
local ROW_GAP = 2

local function lockedCount(recipes)
  local n = 0
  for s in pairs(recipes) do
    if not RTH.RecipeUnlocked(s) then n = n + 1 end
  end
  return n
end

-- the recipes of one profession for one person (others: only what they synced)
local function recipesOf(p, skill)
  if p.me then return RTH.char.recipes[skill] or {} end
  local set = {}
  for s, sk in pairs(p.recipeSkill or {}) do if sk == skill then set[s] = true end end
  return set
end

-- ---------------------------------------------------------------- opening someone's recipe list
local NO_LIST = { [182] = true, [393] = true, [356] = true }   -- Herbalism, Skinning, Fishing: no recipe window
-- Mining has a window (Smelting) but the game can't LINK it (SkillLine.dbc CanLink = 0 for Mining, Herbalism,
-- Skinning, Fishing): its "recipe list" is the smelting recipes RTH read when they opened Smelting, shown in chat.
local MINING = 186
local function smeltWindow() return (GetSpellInfo(2656)) or "Smelting" end
-- does this person's list exist for this profession? (Mining: smelting recipes read; others: a profession link)
local function isShared(p, skill)
  if skill == MINING then return next(recipesOf(p, MINING)) ~= nil end
  return p.tradeLinks[skill] ~= nil
end
local function showSmelting(p)
  local names = {}
  for spell in pairs(recipesOf(p, MINING)) do
    local n = GetSpellInfo(spell)
    if n then names[#names + 1] = n:gsub("^Smelt ", "") end
  end
  if not names[1] then
    RTH.Print((p.me and "You haven't" or (RTH.ClassColorName(p.name) .. " hasn't")) .. " opened " .. smeltWindow() .. " yet - "
      .. (p.me and "open" or "they need to open") .. " it once (it's in the spellbook) so RTH can see what "
      .. (p.me and "you" or "they") .. " can smelt.")
    return
  end
  table.sort(names)
  RTH.Print(RTH.ClassColorName(p.name) .. " can smelt: " .. table.concat(names, ", "))
end
local function openLink(p, skill)
  if skill == MINING then showSmelting(p); return end
  local link = RTH.TradeLink(p.tradeLinks[skill], skill)
  if not link then
    local prof = RTH.PROF_NAME[skill] or "that profession"
    if NO_LIST[skill] then
      RTH.Print(prof .. " has no recipe list to show.")
    else
      RTH.Print((p.me and "You haven't" or (RTH.ClassColorName(p.name) .. " hasn't")) .. " shared the " .. prof .. " recipes yet - "
        .. (p.me and "open" or "they need to open") .. " the " .. prof .. " window once.")
    end
    return
  end
  if IsModifiedClick() then
    HandleModifiedItemClick(link)   -- shift-click: put it in the chat box
  else
    SetItemRef(p.tradeLinks[skill], link, "LeftButton")   -- opens Blizzard's window with their recipes
    -- the RTH window sits above normal windows: bring the recipe window in front of it, so it isn't hidden behind
    -- (only while it shows a list opened from here: on close it goes back to its own layer, so your own
    -- profession window later doesn't sit above your bags)
    RTH.After("raiseTrade", 0.3, function()
      local tf = TradeSkillFrame
      if not (tf and tf:IsShown()) then return end
      if not tf.rthStrata then
        tf.rthStrata = tf:GetFrameStrata()
        tf:HookScript("OnHide", function(self)
          if self.rthRaised then self.rthRaised = nil; self:SetFrameStrata(self.rthStrata) end
        end)
      end
      if tf:GetFrameStrata() ~= "HIGH" then tf:SetFrameStrata("HIGH") end
      tf.rthRaised = true
      tf:Raise()
    end)
  end
end

local function onRowClick(row)
  local list = row.crafters or {}
  if #list == 0 then return end
  if #list == 1 or NO_LIST[row.skill] then openLink(list[1], row.skill); return end   -- no list: one line says so
  -- several people: pick one
  local menu = { { text = row.label .. " - whose recipes?", title = true } }
  for _, p in ipairs(list) do
    -- every name can be clicked: one without a shared list says in chat how to share it (a greyed-out line that
    -- does nothing looked broken)
    local shared = isShared(p, row.skill)
    menu[#menu + 1] = {
      text = RTH.ClassColorName(p.name) .. "  " .. RTH.SkillText(p.profs[row.skill], p.profMax[row.skill])
        .. (shared and "" or "  |cffb8b8b8(not shared yet)|r"),
      func = function() openLink(p, row.skill) end,
    }
  end
  UI.Menu(menu)   -- at the cursor
end

-- ---------------------------------------------------------------- build
local function newProfRow(parent, width, skill)
  local r = CreateFrame("Button", nil, parent)
  r:SetWidth(width)
  UI.RowLook(r, 0)   -- hover glow (rows grow with their player list, so no fixed stripes)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetWidth(26); r.icon:SetHeight(26)
  r.icon:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -2)
  r.name = UI.Text(r, nil, { 1, 1, 1 })
  r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, 0)
  r.who = UI.Text(r, "small", { 0.85, 0.85, 0.85 })
  r.who:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -2)
  r.who:SetWidth(width - 40)
  if skill then
    local spell = RTH.PROF_SPELL[skill]
    r.icon:SetTexture(select(3, GetSpellInfo(spell)))
    -- Herbalism's spell is named "Herb Gathering": show the profession's own name for it
    r.label = skill == 182 and RTH.PROF_NAME[skill] or (GetSpellInfo(spell) or RTH.PROF_NAME[skill])
    r.name:SetText(r.label)
    r.skill = skill
    r:RegisterForClicks("LeftButtonUp")
    -- (no SetHighlightTexture: UI.RowLook above already glows on hover; a second glow doubled it)
    r:SetScript("OnClick", onRowClick)
    UI.Tip(r, function(tt, self)
      tt:AddLine(self.label)
      for _, p in ipairs(self.crafters or {}) do
        tt:AddDoubleLine(RTH.ClassColorName(p.name), RTH.SkillText(p.profs[self.skill], p.profMax[self.skill]))
      end
      if self.crafters and self.crafters[1] and not NO_LIST[self.skill] then
        tt:AddLine(self.skill == MINING and "Click: what they can smelt (shown in chat)"
          or "Click: see their recipes    Shift-click: link in chat", 0.6, 0.8, 1)
      end
    end)
  end
  return r
end

local function build(f)
  local cw = UI.CONTENT_W
  -- boxed sections: title + scrolling profession list, and the recipe search under it
  UI.Section(f, -4, 4, 4, SEARCH_H + 2, nil, { band = 26 })   -- band: behind GROUP PROFESSIONS
  UI.Section(f, -4, nil, 4, -4, SEARCH_H + 2, { band = 26 })   -- below the list box; band behind the Search: row
  -- (26: the underline runs just under the search box, ~6px above the hint line - at 28 the outlined hint text
  --  touched it in game, 2026-11-21)
  f.title = UI.Text(f, nil, UI.GOLD)
  f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -4)
  f.title:SetText(UI.TitleIcon("Professions") .. "GROUP PROFESSIONS")
  -- the profession list scrolls (a 10-man has most people on First Aid / Cooking); the search stays below.
  -- refresh() places every row and grows it when its player list wraps, so nothing overlaps.
  local sw = cw - 26   -- the template's scroll bar hangs ~22px right of the scroll frame
  local sf = UI.StyleScroll(CreateFrame("ScrollFrame", "RTHProfScroll", f, "UIPanelScrollFrameTemplate"))
  sf:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -24)
  sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -26, SEARCH_H + 8)
  local list = CreateFrame("Frame", nil, sf)
  list:SetWidth(sw); list:SetHeight(400)
  sf:SetScrollChild(list)
  f.list = list
  f.rows = {}
  for _, entry in ipairs(ORDER) do
    if type(entry) == "string" then
      local r = CreateFrame("Frame", nil, list)
      r:SetWidth(sw); r:SetHeight(18)
      r.header = UI.Text(r, "small", UI.GOLD)
      r.header:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 2)
      -- divider.tga (art round 5): a gold line with a crystal, from the header text to the row's end
      local d = r:CreateTexture(nil, "ARTWORK")
      d:SetTexture(RTH.TEX .. "divider"); d:SetTexCoord(0, 1, 13 / 64, 50 / 64)
      d:SetHeight(8)
      d:SetPoint("LEFT", r.header, "RIGHT", 8, 0); d:SetPoint("RIGHT", r, "RIGHT", -4, 0)
      r.header:SetText(entry)
      f.rows[#f.rows + 1] = r
      if entry == "COOLDOWNS" then
        f.cdHeader = r
        r.empty = UI.Text(list, "small", { 0.72, 0.72, 0.72 })
        r.empty:SetText("nobody in the guild has a profession cooldown")
      end
    else
      f.rows[#f.rows + 1] = newProfRow(list, sw, entry)
    end
  end
  -- one row per cooldown (Transmute, Icy Prism, research...): hidden when nobody can craft it
  for _, c in ipairs(RTH_ProfCooldowns) do
    local r = newProfRow(list, sw, nil)
    r.cd = c
    r.icon:SetTexture(select(3, GetSpellInfo(c[4][#c[4]])))
    r.name:SetText(c[1])
    f.rows[#f.rows + 1] = r
  end

  local sep = UI.Separator(f, cw)   -- invisible anchor for the search part (the boxes separate the parts now)
  sep:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, SEARCH_H)
  sep:SetAlpha(0)
  local label = UI.Text(f, "small", UI.GOLD)
  label:SetPoint("TOPLEFT", sep, "BOTTOMLEFT", 0, -10)
  label:SetText("Search:")
  f.search = UI.StyleInput(UI.Outline(CreateFrame("EditBox", "RTHRecipeSearch", f, "InputBoxTemplate")), SEARCH_ICON)
  f.search:SetWidth(260); f.search:SetHeight(20)   -- a bit wider: the spyglass takes the first 18px
  f.search:SetAutoFocus(false)
  f.search:SetPoint("LEFT", label, "RIGHT", 12, 0)
  f.search:SetScript("OnTextChanged", function(self)
    UI.RefreshCurrent()
    -- ask the group who HAS it, once typing pauses for a second (one message, not one per letter)
    local q = (self:GetText() or ""):lower()
    if #q >= 3 then
      RTH.After("itemSearch", 1, function()
        if not (RTH.itemSearch and RTH.itemSearch.query == q) then RTH.ItemSearch(q) end
      end)
    end
  end)
  f.search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  f.results = {}
  for i = 1, RESULTS do
    local t = UI.Text(f, "small", { 0.9, 0.9, 0.9 })
    t:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 4, -14 - (i - 1) * 14)
    t:SetWidth(cw - 8)
    f.results[i] = t
  end
  -- cooldown times count down while the tab is open (a refresh every 30 seconds)
  f.tick = 0
  f:SetScript("OnUpdate", function(self, elapsed)
    self.tick = self.tick + elapsed
    if self.tick >= 30 then self.tick = 0; UI.RefreshCurrent() end
  end)
end

-- ---------------------------------------------------------------- refresh
-- one person in a profession line: name (class colour) - Skill lvl 375/450 (n locked)
-- (no player level: it made the lines too long - user 2026-11-18)
local function personText(p, skill)
  local locked = lockedCount(recipesOf(p, skill))
  return RTH.ClassColorName(p.name) .. " - Skill lvl " .. RTH.SkillText(p.profs[skill], p.profMax[skill])
    .. (locked > 0 and (" |cffff6060(" .. locked .. " locked)|r") or "")
end

-- one person in a cooldown line: "Majed ready" / "Aria 5h 20m" / "Bob ?" (never opened the window since)
local function cooldownText(p, name)
  local ready = p.cooldowns[name]
  local state
  if not ready then state = "|cffb8b8b8?|r"
  elseif ready <= time() then state = "|cff40ff40ready|r"
  else state = "|cffffd040" .. RTH.TimeLeft(ready - time()) .. "|r" end
  return RTH.ClassColorName(p.name) .. " " .. state
end

local function fitRow(r)
  r:SetHeight(math.max(30, 18 + math.ceil(r.who:GetStringHeight() or 12)))
end

local function refresh(f)
  local list = RTH.GroupCrafters()
  local y, anyCd = 0, false
  for _, r in ipairs(f.rows) do
    local show = true
    if r.skill then
      -- highest skill first, so the best cook / first-aider leads the line
      local have = {}
      for _, p in ipairs(list) do if p.profs[r.skill] then have[#have + 1] = p end end
      table.sort(have, function(a, b) return a.profs[r.skill] > b.profs[r.skill] end)
      r.crafters = have
      local who = {}
      for _, p in ipairs(have) do who[#who + 1] = personText(p, r.skill) end
      -- one person per line: a long list used to wrap in the middle of a name (user 2026-11-19)
      r.who:SetText(#who == 0 and "|cffff6060nobody in the guild|r" or table.concat(who, "\n"))
      r.icon:SetDesaturated(#who == 0)
      fitRow(r)
    elseif r.cd then
      local who = {}
      for _, p in ipairs(list) do
        if RTH.CooldownsKnown(p.recipes)[r.cd[1]] then who[#who + 1] = cooldownText(p, r.cd[1]) end
      end
      show = #who > 0
      if show then
        anyCd = true
        r.who:SetText(table.concat(who, "\n"))
        fitRow(r)
      end
    end
    if show then
      r:ClearAllPoints()
      r:SetPoint("TOPLEFT", f.list, "TOPLEFT", 0, -y)
      r:Show()
      y = y + r:GetHeight() + ROW_GAP
      if r == f.cdHeader then f.cdHeaderBottom = y end
    else
      r:Hide()
    end
  end
  -- "nobody has a cooldown" note under the COOLDOWNS header
  local empty = f.cdHeader.empty
  empty:ClearAllPoints()
  if anyCd then empty:Hide() else
    empty:SetPoint("TOPLEFT", f.list, "TOPLEFT", 4, -(f.cdHeaderBottom or y))
    empty:Show()
    y = y + 16
  end
  f.list:SetHeight(math.max(1, y))

  -- search: who can MAKE it (recipes the group knows) and who HAS it (bags / bank, answers from the group)
  local q = (f.search:GetText() or ""):lower()
  for _, t in ipairs(f.results) do t:SetText("") end
  if #q < 3 then
    f.results[1]:SetText("|cffb8b8b8type 3+ letters, e.g. \"flask\", \"cardinal\" or \"frozen orb\"|r")
    return
  end
  local found, n = {}, 0
  for _, p in ipairs(list) do
    for s in pairs(p.recipes) do
      local name = GetSpellInfo(s)
      if name and name:lower():find(q, 1, true) then
        found[name] = found[name] or { spell = s, who = {} }
        table.insert(found[name].who, RTH.ClassColorName(p.name))
      end
    end
  end
  local names = {}
  for name in pairs(found) do names[#names + 1] = name end
  table.sort(names)
  local makeLines, hasLines = {}, {}
  for _, name in ipairs(names) do
    local e = found[name]
    local lock = not RTH.RecipeUnlocked(e.spell) and (" |cffff6060locked until " .. RTH.PhaseLabel(RTH_RecipePatch[e.spell]) .. "|r") or ""
    makeLines[#makeLines + 1] = "|cff40c0ffmake|r " .. name .. " - " .. table.concat(e.who, ", ") .. lock
  end
  -- who has it: one line per item, everyone who answered
  local s = RTH.itemSearch
  local answered = 0
  if s and s.query == q then
    local byItem, order = {}, {}
    for who, items in pairs(s.results) do
      answered = answered + 1
      for _, it in ipairs(items) do
        if not byItem[it.id] then byItem[it.id] = {}; order[#order + 1] = it.id end
        local where = {}
        if it.bags > 0 then where[#where + 1] = it.bags .. " bags" end
        if it.bank > 0 then where[#where + 1] = it.bank .. " bank" end
        table.insert(byItem[it.id], RTH.ClassColorName(who) .. " " .. table.concat(where, " + "))
      end
    end
    table.sort(order, function(a, b) return (GetItemInfo(a) or "") < (GetItemInfo(b) or "") end)
    for _, id in ipairs(order) do
      hasLines[#hasLines + 1] = "|cffffd040has|r " .. (GetItemInfo(id) or ("item " .. id)) .. " - " .. table.concat(byItem[id], ", ")
    end
  end
  -- up to 3 "make" lines first, then "has", then the rest of "make"
  local lines = {}
  for i = 1, math.min(3, #makeLines) do lines[#lines + 1] = makeLines[i] end
  for _, l in ipairs(hasLines) do lines[#lines + 1] = l end
  for i = 4, #makeLines do lines[#lines + 1] = makeLines[i] end
  for i = 1, math.min(RESULTS, #lines) do f.results[i]:SetText(lines[i]) end
  if #lines == 0 then
    f.results[1]:SetText(s and s.query == q
      and ("|cffff6060nobody in the guild can make or has that|r  |cffb8b8b8(" .. answered .. " answered)|r")
      or "|cffb8b8b8searching...|r")
  elseif #lines > RESULTS then
    f.results[RESULTS]:SetText("|cffb8b8b8+" .. (#lines - RESULTS + 1) .. " more - type more letters|r")
  end
end

UI.RegisterTab(3, "Professions", build, refresh)
