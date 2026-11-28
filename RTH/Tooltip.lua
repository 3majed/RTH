-- Road to Halion: tooltip lines saying why something is not allowed and when it opens
local RTH = RTH

-- tip_bad / tip_ok (32x32, art round 2 2026-11-21): the marks fill their files, so no crop is needed.
-- (If new art ever fills only part of the file, crop it: name:w:h:0:0:fileW:fileH:left:right:top:bottom.)
local TIP_BAD = "tip_bad:14:14"
local TIP_OK = "tip_ok:14:14"
local COLORS = {
  bad = { 1, 0.25, 0.25, TIP_BAD },
  check = { 1, 0.82, 0.2, TIP_BAD },
  note = { 1, 0.6, 0.2, TIP_BAD },
  ok = { 0.3, 0.9, 0.4, TIP_OK },
}

function RTH.AddTooltipLine(tt, status, text)
  local c = COLORS[status] or COLORS.note
  tt:AddLine("|T" .. RTH.TEX .. c[4] .. "|t Road to Halion: " .. text, c[1], c[2], c[3], true)
  tt:Show()
end

local function slotOfOwner(owner)
  local name = owner and owner.GetName and owner:GetName()
  if name and name:find("^Character.+Slot$") then return owner:GetID() end
  return nil
end

-- hovering an Auction House listing (Browse / Bids), not your own bags while the AH happens to be open
local function auctionListing(owner)
  local name = owner and owner.GetName and owner:GetName()
  return name ~= nil and (name:find("^BrowseButton%d") or name:find("^BidButton%d")) ~= nil
end

-- recipe items (RTH_RecipeItems): who in the group knows it, could learn it, or is still too low
local function recipeLines(tt, id)
  local r = RTH_RecipeItems[id]
  if not r then return end
  local spell, skill, need = r[1], r[2], r[3]
  local known, could, low = {}, {}, {}
  for _, p in ipairs(RTH.GroupCrafters()) do
    local rank = p.profs[skill]
    if p.recipes[spell] then known[#known + 1] = RTH.ClassColorName(p.name)
    elseif rank and rank >= need then could[#could + 1] = RTH.ClassColorName(p.name) .. " |cffb8b8b8(" .. rank .. ")|r"
    elseif rank then low[#low + 1] = RTH.ClassColorName(p.name) .. " |cffb8b8b8(" .. rank .. "/" .. need .. ")|r" end
  end
  if known[1] then tt:AddLine("|cff40c0ffKnown by:|r " .. table.concat(known, ", "), 1, 1, 1, true) end
  if could[1] then tt:AddLine("|cff40ff40Could learn:|r " .. table.concat(could, ", "), 1, 1, 1, true) end
  if low[1] then tt:AddLine("|cffffd040Skill too low:|r " .. table.concat(low, ", "), 1, 1, 1, true) end
  if not (known[1] or could[1] or low[1]) then
    tt:AddLine("Nobody in the guild has " .. (RTH.PROF_NAME[skill] or "this profession"), 0.72, 0.72, 0.72)
  end
end

local function lineText(tt, i)
  local fs = _G[tt:GetName() .. "TextLeft" .. i]
  return fs and fs:GetText()
end

-- Our lines for the item in this tooltip. A recipe's tooltip also shows the item it MAKES, and when that
-- item's data arrives the game rebuilds the tooltip; GetItem() can then name the made item. The tooltip's
-- first line is still the recipe's name, so that is how the recipe is recognised again.
local function decorate(tt)
  local _, link = tt:GetItem()
  if not link then return end
  local id = RTH.ParseLink(link)
  if RTH_RecipeItems[id] then
    tt.rthRecipe = { link = link, id = id, title = lineText(tt, 1) }
  elseif tt.rthRecipe and tt.rthRecipe.title and lineText(tt, 1) == tt.rthRecipe.title then
    link, id = tt.rthRecipe.link, tt.rthRecipe.id
  else
    tt.rthRecipe = nil
  end
  local first = tt:NumLines() + 1

  local owner = tt:GetOwner()
  local slot = slotOfOwner(owner)
  local oname = owner and owner.GetName and owner:GetName() or ""
  -- a vendor's sale listing (not the buyback page, which shows what you sold)
  local vendor = oname:find("^MerchantItem%d+ItemButton$") and MerchantFrame and MerchantFrame.selectedTab == 1
  local ctx = slot and "equip" or vendor and "vendor" or "bag"

  -- something you're WEARING while leveling: gear counts from level 80 (an enchanted heirloom is fine) -
  -- one note instead of red lines the light doesn't count
  if slot and not RTH.GearCounts("player") then
    RTH.AddTooltipLine(tt, "note", "leveling - what you wear counts from level " .. RTH.GEAR_LEVEL)
    tt.rthMark = { idx = first, text = lineText(tt, first) }
    return
  end

  -- the item itself (phase, 25-man, heirloom, unknown source; recipes by the recipe they teach)
  local s, r = RTH.ItemStatus(link, ctx)
  if s == "bad" or s == "check" or s == "note" then RTH.AddTooltipLine(tt, s, r)
  else
    -- crafted-only food, flask, potion, glyph...: who can make it, materials included
    local us, ur = RTH.UseStatus(link)
    if us then RTH.AddTooltipLine(tt, us, ur) end
    -- an arcanum / inscription sold for reputation: does THIS character have the standing?
    local rs, rr = RTH.RepItemStatus(link)
    if rs == "bad" or rs == "check" then RTH.AddTooltipLine(tt, rs, rr) end
  end

  -- crafted gear: ONE line everywhere (AH, bags, worn, trade skill window - user 2026-11-27): green "Name can make
  -- it" or red "nobody in the guild knows this recipe". (The rule: fine when someone in the guild knows the recipe,
  -- bought from anyone - or a guild member made it.) A later phase already said so above.
  local crafted = RTH.CraftedGearSpells(id) and s ~= "bad" and s ~= "check"
  if crafted then
    local cs, cr = RTH.CraftedStatus(id, RTH.MakerFromTooltip(tt))
    if cs then RTH.AddTooltipLine(tt, cs, cr) end
  end

  -- a cut gem itself: may it go into your gear? (the bag mark shows this one too - so must the tooltip,
  -- or a red gem would have no reason line)
  local gs, gr = RTH.GemStatus(id)
  if gs == "bad" and s ~= "bad" and s ~= "check" then RTH.AddTooltipLine(tt, gs, gr) end   -- (a later-phase gem: said above)

  -- enchant and gems on it
  for _, extra in ipairs(RTH.LinkExtras(link)) do RTH.AddTooltipLine(tt, "bad", extra) end

  -- buying it on the Auction House (same rule as the listing's mark and the bid check)
  if auctionListing(owner) and not crafted then   -- (crafted gear: its one line above says the same)
    local as, ar = RTH.AHStatus(link)
    if as then RTH.AddTooltipLine(tt, as, ar) end
  end

  -- recipe: who in the group knows it / could learn it
  recipeLines(tt, id)

  -- remember our first line: if the game wipes the tooltip without a "cleared" event, OnUpdate re-adds us
  if tt:NumLines() >= first then
    tt.rthMark = { idx = first, text = lineText(tt, first) }
    tt:Show()   -- resize to fit the new lines
  else
    tt.rthMark = nil
  end
end

local function onItem(tt)
  if not RTH.db or not RTH.Active() or tt.rthDone then return end
  tt.rthDone = true
  decorate(tt)
end

for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
  RTH.HookScript(tt, "OnTooltipSetItem", onItem)
  RTH.HookScript(tt, "OnTooltipCleared", function(self) self.rthDone = nil; self.rthMark = nil end)
  RTH.HookScript(tt, "OnHide", function(self) self.rthRecipe = nil; self.rthMark = nil end)
  -- self-healing: our first line gone (the game rebuilt the tooltip) -> add our lines again
  RTH.HookScript(tt, "OnUpdate", function(self)
    local m = self.rthMark
    if m and lineText(self, m.idx) ~= m.text then
      self.rthMark, self.rthDone = nil, nil
      onItem(self)
    end
  end)
end
