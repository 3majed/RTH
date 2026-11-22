-- Road to Halion: Journey Log tab (kills newest first, or rule breaks) + Discord summary
local RTH = RTH
local UI = RTH.UI

local ROWS = 21
local ROW_H = 17
local mode = "kills"
-- entry icons, inline so the line measuring/wrapping counts them (user 2026-11-21): a skull per kill, the
-- ready-check cross per rule break
local KILL_ICON = "|T" .. RTH.TEX .. "log_kill:14:14|t "      -- art round 5: frost skull
local BREAK_ICON = "|T" .. RTH.TEX .. "log_break:14:14|t "    -- art round 5: broken red chain

local function entries()
  local g = RTH.db.group
  local list = {}
  if mode == "kills" then
    for i = #g.kills, 1, -1 do
      local k = g.kills[i]
      local stars = k.stars and #k.stars or 0
      if stars == 0 and k.starCount then stars = k.starCount end
      local text = KILL_ICON .. k.d .. "   " .. k.name .. (k.heroic and " |cffff8040(heroic)|r" or "")
      if k.first then text = text .. "  |cff40ff40first kill|r" end
      local right = (k.wipes and k.wipes > 0 and (k.wipes .. " wipes  ") or "") .. (stars > 0 and ("|T" .. RTH.TEX .. "star:14:14|t " .. stars) or "")
      list[#list + 1] = { text = text, right = right, tip = k }
    end
  else
    for i = #g.breaks, 1, -1 do
      local b = g.breaks[i]
      list[#list + 1] = { text = BREAK_ICON .. b.d .. "   " .. RTH.ClassColorName(b.who) .. ": " .. b.text, right = "", brk = b }
      -- the guild master's comment, on its own lines under the break (gold again after the coloured name)
      if b.note then
        list[#list + 1] = { text = (b.noteBy and (RTH.ClassColorName(b.noteBy) .. "|cffffd040") or "|cffffd040Guild master")
          .. ": " .. b.note .. "|r", right = "", brk = b, pad = 24 }
      end
    end
  end
  return list
end

-- A long entry goes on over the next rows instead of ending in "...": the words are measured with a hidden
-- font string and cut into lines of up to `width` pixels. Later lines are indented and keep the same hover.
-- e.pad: the whole entry starts that far in (a comment under its break).
local INDENT = 12
local function wrapped(list, measure, width)
  local out = {}
  for _, e in ipairs(list) do
    local line, first = nil, true
    local pad = e.pad or 0
    local function push()
      out[#out + 1] = { text = line, right = first and e.right or "", tip = e.tip, full = e.text, brk = e.brk,
                        x = first and pad or (pad + INDENT) }
      line, first = nil, false
    end
    local gap = ""
    for word, after in e.text:gmatch("(%S+)(%s*)") do   -- the spaces are kept ("date   name")
      local try = line and (line .. gap .. word) or word
      gap = after
      measure:SetText(try)
      if line and measure:GetStringWidth() > (first and (width - pad) or (width - pad - INDENT)) then
        -- a colour still open at the cut ("|cff40ff40first" | "kill|r") is closed here and opened again below
        local open
        for c, r in line:gmatch("(|c%x%x%x%x%x%x%x%x)()") do open = c; if line:find("|r", r, true) then open = nil end end
        if open then line = line .. "|r" end
        push()
        line = open and (open .. word) or word
      else
        line = try
      end
    end
    if line then push() end
  end
  return out
end

local function discordText()
  local g = RTH.db.group
  local p = RTH.GetPhase()
  -- (1.4.0: the guild's phase is the furthest any character has reached)
  local lines = { "**Road to Halion** - furthest: " .. RTH.PhaseLabel(p) .. " (since " .. (g.phaseLog[p] or "?") .. ", started " .. g.started .. ")" }
  local kills, firsts, wipes, stars = 0, 0, 0, 0
  for _, k in ipairs(g.kills) do
    kills = kills + 1
    if k.first then firsts = firsts + 1 end
    wipes = wipes + (k.wipes or 0)
    if (k.stars and #k.stars > 0) or (k.starCount or 0) > 0 then stars = stars + 1 end
  end
  lines[#lines + 1] = kills .. " kills, " .. firsts .. " first kills, " .. wipes .. " wipes, " .. #g.breaks .. " rule breaks, " .. stars .. " starred kills"
  -- the list follows the view it is copied from (user 2026-11-21: copied on Rule breaks it said "Latest:" and
  -- nothing). Plain text only - Discord shows WoW colour codes as junk.
  if mode == "breaks" then
    lines[#lines + 1] = #g.breaks > 0 and "Latest rule breaks:" or "Latest rule breaks: none"
    for i = #g.breaks, math.max(1, #g.breaks - 9), -1 do
      local b = g.breaks[i]
      lines[#lines + 1] = "- " .. b.d .. " " .. b.who .. ": " .. b.text
      if b.note then lines[#lines + 1] = "    " .. (b.noteBy or "Guild master") .. ": " .. b.note end
    end
  else
    lines[#lines + 1] = #g.kills > 0 and "Latest kills:" or "Latest kills: none yet"
    for i = #g.kills, math.max(1, #g.kills - 9), -1 do
      local k = g.kills[i]
      lines[#lines + 1] = "- " .. k.d .. " " .. k.name .. (k.heroic and " (heroic)" or "") .. ((k.wipes or 0) > 0 and (" - " .. k.wipes .. " wipes") or "")
        .. (((k.stars and #k.stars > 0) or (k.starCount or 0) > 0) and " *" or "")
    end
  end
  return table.concat(lines, "\n")
end
RTH.DiscordText = discordText

-- the guild master's comment box (StaticPopup's wide edit box, 3.3.5 FrameXML). Empty + Save = remove the comment.
local function saveNote(b, text)
  if RTH.SetBreakNote(b, text) then
    RTH.Print(((text or ""):match("%S") and "comment saved" or "comment removed") .. " - everyone with RTH sees it")
  end
end
-- the guild master deletes a break for everyone (user rule 2026-11-22) - asked once more, it can't be undone
function UI.DeleteBreak(b)
  if not (b and RTH.IAmRulesKeeper()) then return end
  StaticPopupDialogs.RTH_BREAK_DELETE = StaticPopupDialogs.RTH_BREAK_DELETE or {
    text = "Delete %s's rule break for everyone?\n\n%s\n\n|cffff4040This can't be undone.|r",
    button1 = DELETE or "Delete", button2 = CANCEL or "Cancel",
    OnAccept = function(self, data)
      if RTH.DeleteBreak(data) then RTH.Print("rule break deleted - it's gone for everyone with RTH") end
    end,
    timeout = 0, whileDead = 1, hideOnEscape = 1, showAlert = 1,
  }
  StaticPopup_Show("RTH_BREAK_DELETE", b.who, RTH.BreakForMessage(b.text, 160), b)
end

function UI.EditBreakNote(b)
  if not (b and RTH.IAmRulesKeeper()) then return end
  StaticPopupDialogs.RTH_BREAK_NOTE = StaticPopupDialogs.RTH_BREAK_NOTE or {
    text = "Your comment on %s's rule break:\n\n%s\n\n(leave it empty to remove the comment)",
    button1 = SAVE or "Save", button2 = CANCEL or "Cancel", button3 = DELETE or "Delete",
    -- Delete: closes this box and asks once more (StaticPopup's third button = OnAlt)
    OnAlt = function(self, data) UI.DeleteBreak(data) end,
    hasEditBox = 1, hasWideEditBox = 1, maxLetters = 120, maxBytes = RTH.NOTE_BYTES,
    OnShow = function(self, data)
      local box = _G[self:GetName() .. "WideEditBox"]
      box:SetText(data and data.note or "")
      box:SetFocus()
    end,
    OnAccept = function(self, data) saveNote(data, _G[self:GetName() .. "WideEditBox"]:GetText()) end,
    EditBoxOnEnterPressed = function(self, data) saveNote(data, self:GetText()); self:GetParent():Hide() end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
  }
  StaticPopup_Show("RTH_BREAK_NOTE", b.who, RTH.BreakForMessage(b.text, 160), b)
end

local function build(f)
  local cw = UI.CONTENT_W
  -- boxed sections: the header (title + buttons on the band, info line under it) and the list (rows from -58).
  -- Fixed positions: the title's icon made it taller and pushed the info line onto the band's underline.
  UI.Section(f, -4, 4, 4, nil, 54, { band = 28 })   -- band ends at -24; the box at -50
  UI.Section(f, -4, -54, 4, -4)
  f.title = UI.Text(f, nil, UI.GOLD)
  f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
  f.toggle = UI.Button(f, "Rule breaks", 110, 22, function()
    mode = (mode == "kills") and "breaks" or "kills"
    FauxScrollFrame_SetOffset(f.scroll, 0)
    f.scroll:SetVerticalScroll(0)
    UI.RefreshCurrent()
  end)
  f.toggle:SetPoint("TOPRIGHT", f, "TOPRIGHT", -126, 0)
  f.copy = UI.Button(f, "Copy for Discord", 120, 22, function() RTH.ShowCopyBox(discordText()) end)
  f.copy:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
  f.info = UI.Text(f, "small", { 0.8, 0.8, 0.8 })
  f.info:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -31)   -- 7px under the band's underline

  f.scroll = UI.StyleScroll(CreateFrame("ScrollFrame", "RTHLogScroll", f, "FauxScrollFrameTemplate"))
  f.scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -58)
  f.scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 0)
  f.scroll:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, function() UI.RefreshCurrent() end)
  end)
  f.rows = {}
  for i = 1, ROWS do
    local r = CreateFrame("Frame", nil, f)
    r:SetWidth(cw - 28); r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -58 - (i - 1) * ROW_H)   -- 4px in from the list box's border
    r:EnableMouse(true)
    UI.RowLook(r, 0)   -- hover glow; the stripe below follows the ENTRY (a wrapped entry + its comment share one)
    r.stripe = r:CreateTexture(nil, "BACKGROUND")
    r.stripe:SetTexture(1, 1, 1, 0.035)
    r.stripe:SetAllPoints(r)
    r.text = UI.Text(r, "small", { 1, 1, 1 })
    r.text:SetHeight(ROW_H - 3)   -- one line per row: long entries are cut into rows by wrapped()
    r.right = UI.Text(r, "small", { 0.75, 0.75, 0.75 }, "RIGHT")
    r.right:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    -- the guild master clicks a rule break (or its comment) to write, change or remove the comment
    r:SetScript("OnMouseUp", function(self, button)
      if button == "LeftButton" and self.brk and RTH.IAmRulesKeeper() then UI.EditBreakNote(self.brk) end
    end)
    UI.Tip(r, function(tt, self)
      local k = self.kill
      if not k then
        local b = self.brk
        if b then
          tt:AddLine(b.d .. "   " .. RTH.ClassColorName(b.who) .. ": " .. b.text, 1, 1, 1, true)
          if b.note then
            tt:AddLine(" ")
            tt:AddLine("Comment from " .. (b.noteBy and RTH.ClassColorName(b.noteBy) or "the guild master") .. (b.noteT and (" (" .. date("%Y-%m-%d %H:%M", b.noteT) .. ")") or "") .. ":", 1, 0.82, 0)
            tt:AddLine(b.note, 1, 0.85, 0.4, true)
          end
          if RTH.IAmRulesKeeper() then
            tt:AddLine(" ")
            tt:AddLine((b.note and "Click to change or remove your comment" or "Click to comment on this rule break")
              .. " - or delete it", 0.25, 1, 0.25)
          end
        else
          tt:AddLine(self.full or self.text:GetText(), 1, 1, 1, true)
        end
        return
      end
      tt:AddLine(k.name .. (k.heroic and " (heroic)" or ""), 1, 0.85, 0.4)
      tt:AddLine(k.d .. (k.synced and ("  - from " .. RTH.ClassColorName(k.by)) or ""), 0.8, 0.8, 0.8)
      if k.roster and #k.roster > 0 then
        tt:AddLine("Raid: " .. RTH.ClassColorNames(k.roster) .. (k.subs and k.subs > 0 and (" (" .. k.subs .. " subs)") or ""), 0.9, 0.9, 0.9, true)
      end
      for _, s in ipairs(k.stars or {}) do tt:AddLine("* " .. s, 1, 0.4, 0.4, true) end
    end)
    f.rows[i] = r
  end
  f.empty = UI.Text(f, nil, { 0.7, 0.7, 0.7 }, "CENTER")
  f.empty:SetPoint("CENTER", f, "CENTER", 0, 0)
  UI.EmptyEmblem(f.empty, f)
  -- measures words for wrapped(): same font as the rows, no width limit, never seen
  f.measure = UI.Text(f, "small")
  f.measure:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  f.measure:SetAlpha(0)
end

local function refresh(f)
  local g = RTH.db.group
  f.title:SetText(UI.TitleIcon("Journey Log") .. (mode == "kills" and "JOURNEY LOG" or "RULE BREAKS"))
  f.toggle:SetText(mode == "kills" and "Rule breaks" or "Kills")
  local p = RTH.GetPhase()
  local days = 0
  if g.phaseLog[p] then
    local y, m, d = g.phaseLog[p]:match("(%d+)-(%d+)-(%d+)")
    if y then days = math.floor((time() - time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0 })) / 86400) end
  end
  f.info:SetText("Started " .. g.started .. "   -   furthest: " .. RTH.PhaseLabel(p) .. " since " .. (g.phaseLog[p] or "?") .. " (day " .. (days + 1) .. ")"
    .. ((mode == "breaks" and RTH.IAmRulesKeeper() and #g.breaks > 0) and "   -   |cff40ff40click a break to comment or delete|r" or ""))
  -- kills keep room on the right for wipes and stars; rule breaks use the whole row
  local width = (mode == "kills") and (UI.CONTENT_W - 130) or (UI.CONTENT_W - 30)
  local list = wrapped(entries(), f.measure, width)
  FauxScrollFrame_Update(f.scroll, #list, ROWS, ROW_H)
  local offset = FauxScrollFrame_GetOffset(f.scroll)
  -- stripe parity per entry: counted from the top of the list, so scrolling never flips the shading
  local shade, lastKey, n = {}, nil, 0
  for i = 1, math.min(#list, offset + ROWS) do
    local e = list[i]
    local key = e.brk or e.tip or e
    if key ~= lastKey then n = n + 1; lastKey = key end
    shade[i] = n % 2 == 0
  end
  for i = 1, ROWS do
    local e = list[offset + i]
    local r = f.rows[i]
    if e then
      r:Show()
      UI.Shown(r.stripe, shade[offset + i])
      local x = e.x or 0
      r.text:ClearAllPoints()
      r.text:SetPoint("LEFT", r, "LEFT", x, 0)
      r.text:SetWidth(width - x + 6)   -- a few px spare: the measured line must never get "..." itself
      r.text:SetText(e.text)
      r.right:SetText(e.right)
      r.kill = e.tip
      r.full = e.full
      r.brk = e.brk
    else
      r:Hide()
    end
  end
  local noKills = p == 1 and "No kills yet - the road starts at Naxxramas."
    or ("No kills logged yet - " .. RTH.PhaseLabel(p) .. " is open.")
  f.empty:SetText(mode == "kills" and noKills or "No rule breaks. Keep it that way!")
  UI.Shown(f.empty, #list == 0)
end

UI.RegisterTab(4, "Journey Log", build, refresh)
