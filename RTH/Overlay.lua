-- Road to Halion: red / yellow overlays on item icons that are not allowed in the current phase.
-- Drawn as our own layer above the button (never by tinting the icon: !Beautycase and others recolour icons).
local RTH = RTH

local marked = setmetatable({}, { __mode = "k" })   -- button -> { link, ctx, slot } (for refreshing on phase change)

local function overlayFor(obj)
  if obj.rthOverlay then return obj.rthOverlay end
  local host = obj.CreateTexture and obj or obj:GetParent()
  local f = CreateFrame("Frame", nil, host)
  f:SetPoint("TOPLEFT", obj, "TOPLEFT", 1, -1)
  f:SetPoint("BOTTOMRIGHT", obj, "BOTTOMRIGHT", -1, 1)
  f:SetFrameLevel((host:GetFrameLevel() or 1) + 8)
  -- a flat tint goes under the overlay art so it shows on red/orange icons too. Art round 2 (2026-11-21): the
  -- centres are now ~23% (red) / ~39% (amber) opaque, so the tints are lighter (item still visible)
  f.tint = f:CreateTexture(nil, "ARTWORK")
  f.tint:SetAllPoints(f)
  f.tex = f:CreateTexture(nil, "OVERLAY")
  f.tex:SetAllPoints(f)
  f.badge = f:CreateTexture(nil, "OVERLAY", nil, 1)
  f.badge:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
  f:Hide()
  obj.rthOverlay = f
  return f
end

-- status: "bad" / "check" / anything else hides it. badge: "never" (25-man), "lock" (opens later)
function RTH.SetOverlay(obj, status, badge)
  if not obj then return end
  if status ~= "bad" and status ~= "check" or not RTH.db or not RTH.db.ui.overlays or not RTH.Active() then
    if obj.rthOverlay then obj.rthOverlay:Hide() end
    return
  end
  local f = overlayFor(obj)
  f.tex:SetTexture(RTH.TEX .. (status == "bad" and "overlay_red" or "overlay_yellow"))
  if status == "bad" then f.tint:SetTexture(1, 0, 0, 0.25) else f.tint:SetTexture(1, 0.8, 0, 0.08) end
  local size = math.max(10, math.floor((obj:GetWidth() or 37) * 0.42))
  f.badge:SetWidth(size); f.badge:SetHeight(size)
  if status == "bad" and badge then
    f.badge:SetTexture(RTH.TEX .. (badge == "never" and "badge_never" or "lock"))
    f.badge:Show()
  else
    f.badge:Hide()
  end
  f:Show()
end

-- full verdict for an item in a context, the same one the tooltip shows
function RTH.ItemVerdict(link, ctx, slot)
  if not link then return nil end
  if ctx == "equip" and not RTH.GearCounts("player") then return nil end   -- leveling: what you wear counts from 80
  if ctx == "ah" then
    local s, r = RTH.ItemStatus(link, "bag")
    if s == "bad" or s == "check" then return s, r end
    -- the listing shows the BUYING rule (RTH.AHStatus): crafted-only things need a crafter in the group, dropped
    -- gear and raw materials are fine in their phase - the same check that logs a break when you buy
    return RTH.AHStatus(link)
  end
  local s, r, p = RTH.ItemStatus(link, ctx)
  if s == "bad" or s == "check" then return s, r, p end
  -- crafted-only food, flask, potion, glyph...: needs a crafter in the group
  local us, ur = RTH.UseStatus(link)
  if us == "bad" then return us, ur end
  -- an arcanum / inscription sold for reputation this character doesn't have (yet)
  local rs, rr = RTH.RepItemStatus(link)
  if rs == "bad" then return rs, rr end
  -- a cut gem in bags / a trade: may it go into your gear? (a cutter in the group)
  local gs, gr = RTH.GemStatus((RTH.ParseLink(link)))   -- (( )): only the item ID, not ParseLink's other returns
  if gs == "bad" then return gs, gr end
  if ctx == "equip" then
    local id = RTH.ParseLink(link)
    if RTH_CraftedBy[id] and slot then
      local cs, cr = RTH.CraftedStatus(id, RTH.MakerOfSlot(slot))
      if cs == "bad" or cs == "check" then return cs, cr end
    end
    local extras = RTH.LinkExtras(link)
    if extras[1] then return "bad", extras[1] end
  end
  return s, r
end

function RTH.MarkItem(button, link, ctx, slot)
  if not button then return end
  if not link then
    marked[button] = nil
    RTH.SetOverlay(button, nil)
    return
  end
  marked[button] = { link = link, ctx = ctx or "bag", slot = slot }
  local s, r = RTH.ItemVerdict(link, ctx or "bag", slot)
  -- corner badge: "never" for 25-man loot, a lock only when it opens in a later phase ("... until Phase N");
  -- nothing for craft reasons (those don't open by waiting)
  local badge = r and (r:find("25%-man") and "never" or (r:find("until Phase") and "lock")) or nil
  RTH.SetOverlay(button, s, badge)
end

function RTH.RefreshOverlays()
  for button, m in pairs(marked) do
    if button:IsVisible() then RTH.MarkItem(button, m.link, m.ctx, m.slot) end
  end
  if TradeSkillFrame and TradeSkillFrame:IsShown() and RTH.TintTradeSkill then
    TradeSkillFrame_Update()
  end
end
for _, msg in ipairs({ "PHASE_CHANGED", "MEMBERS_CHANGED", "PROFESSIONS_CHANGED", "ROSTER_CHANGED", "OVERLAYS_TOGGLED", "MY_PHASE_CHANGED", "REP_CHANGED", "TOME_CHANGED" }) do
  RTH.Listen(msg, function() RTH.After("refreshOverlays", 0.3, RTH.RefreshOverlays) end)
end

-- ---------------------------------------------------------------- default UI
RTH.Hook("ContainerFrame_Update", function(frame)
  local bag, name = frame:GetID(), frame:GetName()
  for i = 1, frame.size or 0 do
    local b = _G[name .. "Item" .. i]
    if b then RTH.MarkItem(b, GetContainerItemLink(bag, b:GetID()), "bag") end
  end
end)

RTH.Hook("BankFrameItemButton_Update", function(button)
  if button.isBag then return end
  RTH.MarkItem(button, GetContainerItemLink(BANK_CONTAINER, button:GetID()), "bag")
end)

RTH.Hook("PaperDollItemSlotButton_Update", function(button)
  local slot = button:GetID()
  if slot and slot >= 1 and slot <= 19 then
    RTH.MarkItem(button, GetInventoryItemLink("player", slot), "equip", slot)
  end
end)

RTH.Hook("LootFrame_Update", function()
  for i = 1, LOOTFRAME_NUMBUTTONS or 4 do
    local b = _G["LootButton" .. i]
    if b and b:IsShown() and b.slot then RTH.MarkItem(b, GetLootSlotLink(b.slot), "bag")
    elseif b then RTH.MarkItem(b, nil) end
  end
end)

-- Any bag addon built on Blizzard's bag buttons (user request 2026-11-22 - Glorify's bags showed no marks): those
-- buttons have "<name>IconQuestTexture" (ContainerFrameItemButtonTemplate / the bank's) and their bag is the
-- parent's ID - Blizzard's own click code depends on that, so it's reliable. They all draw the icon through
-- SetItemButtonTexture, so that's where the mark goes. The addon-specific hooks below still run (same verdict).
-- The bank's own slots sit on BankFrame (bag -1); the bank's bag-slot buttons (isBag) are no items.
RTH.Hook("SetItemButtonTexture", function(button, texture)
  if type(button) ~= "table" or not button.GetName or button.isBag then return end
  local name = button:GetName()
  if not name or not _G[name .. "IconQuestTexture"] then return end
  local parent = button:GetParent()
  local bag = parent and parent.GetID and parent:GetID()
  if parent and parent == _G.BankFrame then bag = BANK_CONTAINER or -1 end
  local slot = button:GetID()
  if not bag or not slot or slot < 1 then return end
  RTH.MarkItem(button, texture and GetContainerItemLink(bag, slot) or nil, "bag")
end)

-- group loot rolls (Need / Greed windows): the item's red mark, so nobody wins what they may not use (user request
-- 2026-11-22). Their OnShow is bound in XML (function="GroupLootFrame_OnShow"): a hook on the global would never
-- run, so each window's own script is hooked. The hover line comes from the tooltip as everywhere.
for i = 1, (NUM_GROUP_LOOT_FRAMES or 4) do
  local f = _G["GroupLootFrame" .. i]
  local icon = _G["GroupLootFrame" .. i .. "IconFrame"]
  if f and icon then
    RTH.HookScript(f, "OnShow", function(self)
      RTH.MarkItem(icon, self.rollID and GetLootRollItemLink(self.rollID) or nil, "bag")
    end)
  end
end

RTH.Hook("MerchantFrame_UpdateMerchantInfo", function()
  for i = 1, MERCHANT_ITEMS_PER_PAGE do
    local index = (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i
    local b = _G["MerchantItem" .. i .. "ItemButton"]
    if b then RTH.MarkItem(b, b:IsShown() and GetMerchantItemLink(index) or nil, "vendor") end   -- (the Tome: may you buy it now)
  end
end)
-- the Buyback tab reuses the same buttons (12 of them): without this they kept the sale page's marks
RTH.Hook("MerchantFrame_UpdateBuybackInfo", function()
  for i = 1, BUYBACK_ITEMS_PER_PAGE do
    local b = _G["MerchantItem" .. i .. "ItemButton"]
    if b then RTH.MarkItem(b, b:IsShown() and GetBuybackItemLink(i) or nil, "bag") end
  end
end)

-- a mail shows the worst of its attachments
local ORDER = { bad = 3, check = 2 }
RTH.Hook("InboxFrame_Update", function()
  for i = 1, INBOXITEMS_TO_DISPLAY do
    local b = _G["MailItem" .. i .. "Button"]
    local worst, worstLink
    if b and b:IsShown() and b.index then
      for a = 1, ATTACHMENTS_MAX_RECEIVE do
        local link = GetInboxItemLink(b.index, a)
        if link then
          local s = RTH.ItemVerdict(link, "bag")
          if (ORDER[s] or 0) > (ORDER[worst] or 0) or not worstLink then worst, worstLink = s, link end
        end
      end
    end
    if b then RTH.MarkItem(b, worstLink, "bag") end
  end
end)

RTH.Hook("OpenMail_Update", function()
  if not InboxFrame.openMailID then return end
  for i = 1, ATTACHMENTS_MAX_RECEIVE do
    local b = _G["OpenMailAttachmentButton" .. i]
    if b then RTH.MarkItem(b, b:IsShown() and GetInboxItemLink(InboxFrame.openMailID, i) or nil, "bag") end
  end
end)

RTH.Hook("TradeFrame_UpdatePlayerItem", function(id)
  RTH.MarkItem(_G["TradePlayerItem" .. id .. "ItemButton"], GetTradePlayerItemLink(id), "bag")
end)
RTH.Hook("TradeFrame_UpdateTargetItem", function(id)
  RTH.MarkItem(_G["TradeRecipientItem" .. id .. "ItemButton"], GetTradeTargetItemLink(id), "bag")
end)

-- items you attach to a mail you're sending
RTH.Hook("SendMailFrame_Update", function()
  for i = 1, ATTACHMENTS_MAX_SEND do
    local b = _G["SendMailAttachment" .. i]
    if b then RTH.MarkItem(b, GetSendMailItemLink(i), "bag") end
  end
end)

-- load-on-demand Blizzard windows
local lod = {}
lod.Blizzard_InspectUI = function()
  RTH.Hook("InspectPaperDollItemSlotButton_Update", function(button)
    local unit = InspectFrame and InspectFrame.unit
    RTH.MarkItem(button, unit and GetInventoryItemLink(unit, button:GetID()) or nil, "bag")
  end)
end
lod.Blizzard_AuctionUI = function()
  RTH.BlockAHButtons()   -- Rules.lua: Bid / Buyout greyed out for items you may not buy
  RTH.Hook("AuctionFrameBrowse_Update", function()
    local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)
    for i = 1, NUM_BROWSE_TO_DISPLAY do
      local b = _G["BrowseButton" .. i .. "Item"]
      local row = _G["BrowseButton" .. i]
      if b then RTH.MarkItem(b, row and row:IsShown() and GetAuctionItemLink("list", offset + i) or nil, "ah") end
    end
  end)
  -- Bids tab (what you bid on) and Auctions tab (what you're selling)
  RTH.Hook("AuctionFrameBid_Update", function()
    local offset = FauxScrollFrame_GetOffset(BidScrollFrame)
    for i = 1, NUM_BIDS_TO_DISPLAY do
      local b, row = _G["BidButton" .. i .. "Item"], _G["BidButton" .. i]
      if b then RTH.MarkItem(b, row and row:IsShown() and GetAuctionItemLink("bidder", offset + i) or nil, "ah") end
    end
  end)
  RTH.Hook("AuctionFrameAuctions_Update", function()
    local offset = FauxScrollFrame_GetOffset(AuctionsScrollFrame)
    for i = 1, NUM_AUCTIONS_TO_DISPLAY do
      local b, row = _G["AuctionsButton" .. i .. "Item"], _G["AuctionsButton" .. i]
      if b then RTH.MarkItem(b, row and row:IsShown() and GetAuctionItemLink("owner", offset + i) or nil, "bag") end
    end
  end)
end
lod.Blizzard_GuildBankUI = function()
  RTH.Hook("GuildBankFrame_Update", function()
    if GuildBankFrame.mode ~= "bank" then return end
    local tab = GetCurrentGuildBankTab()
    for i = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
      local index = math.fmod(i, NUM_SLOTS_PER_GUILDBANK_GROUP)
      if index == 0 then index = NUM_SLOTS_PER_GUILDBANK_GROUP end
      local column = math.ceil((i - 0.5) / NUM_SLOTS_PER_GUILDBANK_GROUP)
      RTH.MarkItem(_G["GuildBankColumn" .. column .. "Button" .. index], GetGuildBankItemLink(tab, i), "bag")
    end
  end)
end

-- ---------------------------------------------------------------- bag addons
-- each hook runs once, whether the addon loaded before or after us
lod["!Beautycase"] = function()
  if not (Beautycase and Beautycase.UpdateKnownItemOverlay) then return end
  -- Beautycase sends every item button it draws (bags, bank, AH, loot, mail, merchant, trade, guild bank) through here
  RTH.Hook(Beautycase, "UpdateKnownItemOverlay", function(button, _, link)
    local name = button and button.GetName and button:GetName() or ""
    local ctx = name:find("^BrowseButton") and "ah"
      or (name:find("^MerchantItem%d+ItemButton$") and MerchantFrame and MerchantFrame.selectedTab == 1) and "vendor"
      or "bag"
    RTH.MarkItem(button, link, ctx)
  end)
  if Beautycase.HideKnownItemOverlay then
    RTH.Hook(Beautycase, "HideKnownItemOverlay", function(button)
      -- called for empty slots; a button that still holds an item is re-marked by its next update
      if button and button.rthOverlay and not (marked[button] and button:IsShown()) then RTH.MarkItem(button, nil) end
    end)
  end
end
lod.Bagnon = function()
  local slot = Bagnon and Bagnon.ItemSlot
  if not slot or not slot.Update then return end
  RTH.Hook(slot, "Update", function(self) RTH.MarkItem(self, self:GetItem(), "bag") end)
end
-- Bagnon_GuildBank has its own slot class (Bagnon.GuildItemSlot); GetItem() is the item link there too
lod.Bagnon_GuildBank = function()
  local slot = Bagnon and Bagnon.GuildItemSlot
  if not slot or not slot.Update then return end
  RTH.Hook(slot, "Update", function(self) RTH.MarkItem(self, self:GetItem(), "bag") end)
end
lod.ElvUI = function()
  local E = ElvUI and unpack(ElvUI)
  local B = E and E.GetModule and E:GetModule("Bags", true)
  if B and B.UpdateSlot then   -- ElvUI bags + bank
    RTH.Hook(B, "UpdateSlot", function(_, frame, bagID, slotID)
      local bag = frame and frame.Bags and frame.Bags[bagID]
      local slot = bag and bag[slotID]
      if slot then RTH.MarkItem(slot, GetContainerItemLink(bagID, slotID), "bag") end
    end)
  end
  -- ElvUI's own loot window (when its Loot option replaces Blizzard's): mark each row's icon
  local M = E and E.GetModule and E:GetModule("Misc", true)
  if M and M.LOOT_OPENED then
    RTH.Hook(M, "LOOT_OPENED", function()
      local lf = _G.ElvLootFrame
      for i, slot in pairs(lf and lf.slots or {}) do
        if slot.iconFrame then RTH.MarkItem(slot.iconFrame, slot:IsShown() and GetLootSlotLink(i) or nil, "bag") end
      end
    end)
  end
  -- ElvUI's own Need / Greed bars (M.RollBars; START_LOOT_ROLL fills one with rollID + itemButton) - 2026-11-22
  if M and M.START_LOOT_ROLL then
    RTH.Hook(M, "START_LOOT_ROLL", function(_, _, rollID)
      for _, bar in ipairs(M.RollBars or {}) do
        if bar.rollID == rollID and bar.itemButton then
          RTH.MarkItem(bar.itemButton, GetLootRollItemLink(rollID), "bag")
        end
      end
    end)
  end
end
lod.AdiBags = function()
  local AceAddon = LibStub and LibStub("AceAddon-3.0", true)
  local A = AceAddon and AceAddon:GetAddon("AdiBags", true)
  if not A or not A.RegisterMessage then return end
  local listener = {}
  A.RegisterMessage(listener, "AdiBags_UpdateButton", function(_, button)
    if button then RTH.MarkItem(button, button.itemLink, "bag") end
  end)
end
lod.ArkInventory = function()
  if not (ArkInventory and ArkInventory.Frame_Item_Update_Texture and ArkInventory.Frame_Item_GetDB) then return end
  RTH.Hook(ArkInventory, "Frame_Item_Update_Texture", function(frame)
    local ok, i = pcall(ArkInventory.Frame_Item_GetDB, frame)
    RTH.MarkItem(frame, ok and i and i.h or nil, "bag")
  end)
end

local done = {}
RTH.MarkedAddons = done   -- /rth status: which bag / UI addons got the red marks
local function tryHook(name)
  if done[name] or not lod[name] then return end
  if name:find("^Blizzard_") then
    if not IsAddOnLoaded(name) then return end
  elseif not IsAddOnLoaded(name) then
    return
  end
  done[name] = true
  local ok, err = pcall(lod[name])
  if not ok then RTH.Print("could not add marks to " .. name .. ": " .. tostring(err)) end
end
RTH.On("ADDON_LOADED", function(name) tryHook(name) end)
RTH.On("PLAYER_LOGIN", function() for name in pairs(lod) do tryHook(name) end end)
