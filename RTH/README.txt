ROAD TO HALION - addon for the challenge (WoW 3.3.5)
=====================================================

INSTALL
1. Close WoW completely.
2. Put the "RTH" folder in:  World of Warcraft\Interface\AddOns\
3. Start WoW. On the character select screen, click "AddOns" and make sure "Road to Halion" is ticked.
4. In game type  /rth status  - every line should say "yes" (the guild master line is "no" for everyone else).

OPEN IT
Click the purple orb on the minimap, or type  /rth

THE TABS
- Progress     YOUR phase, what you still need for its unlock gate, who else has finished it, and which
               bosses are down. Hover a gate line to see why an achievement doesn't count.
- Raid Check   Everyone's gear. Out of a group it shows the whole guild (everyone with RTH, online or
               offline); in a party or raid it shows your group - the Guild / Group button switches.
               Click "Scan gear" to inspect group members near you. Hover a name for the items and why.
- Professions  Who has which profession, profession cooldowns, and a search:
               who can MAKE something and who HAS it in their bags or bank.
- Journey Log  Every boss kill, and every rule break.
- Rules        Your own switches and your phase. The unlock gates and extra core names can only be
               changed by the guild master.

PHASES - EACH CHARACTER OPENS ITS OWN
- Every character starts in Phase 1 (Naxx). Finish the unlock gate on the Progress tab and the next phase opens
  for THAT character, by itself - nobody has to unlock anything. It stays open for good.
- The gate only counts what you earn in a clean guild run: each gate achievement (and the Vault of Archavon kill)
  must be earned at a boss kill that RTH logged on YOUR character, with no marks on it - no outsiders, not
  25-man, no rule break or gear problem in the raid that night, nobody in the raid behind that raid's phase.
  Earned before you had RTH, with RTH off, or at a marked kill: it doesn't count, and an achievement can't be
  earned twice - so keep RTH on and keep the raid clean.
- The guild's phase (window header, "guild: Ulduar") is just the furthest anyone has reached. Behind it you're
  "catching up": you follow the rules of YOUR phase (no newer gear, recipes or raids yet). Entering a newer raid
  is a rule break for you, and kills of a newer raid with you in it get a mark.
- Someone behind? The others may keep wearing their own phase's gear, go back to the behind player's raid and
  help them finish their gate - nobody gets flagged for that.
- The guild master can still change a gate after people finished it, until someone STARTS the next phase (kills
  one of its bosses, wears its gear at 80, or finishes its gate) - then it's locked. Found a gate too easy? Add a
  requirement: whoever doesn't have it loses the next phase again until they get it (not a rule break).
- Something went wrong (the game bugged an achievement, RTH missed a night)? Only the guild master can pass a
  character's gate by hand: /rth gate Name N (outside a raid). It's written into the Journey Log.

RED MARKS
A red mark on an item (bags, bank, merchant, auction house, mail, trade, loot and Need/Greed rolls...) means you
may not use or buy it in your phase. Hover the item: the tooltip says why and when it opens up. Red marks work
in Blizzard's bags, Bagnon, ElvUI, AdiBags, ArkInventory and any bag addon built on Blizzard's bag buttons.
The light in the window header: green = all your gear is fine, yellow = check, red = not allowed. Hover it for
the slot, the item, why and what to do - click it for the same list in chat.
The rules in plain words: Rules tab > "How the rules work", or /rth rules.
Food, flasks, potions, glyphs, gems and enchants that only a profession can make are only allowed when
someone in the group knows the recipe (nobody has to gather the materials). Things you can buy from a vendor
or that drop are fine.
Gear (what you wear) counts from level 80: while leveling, old and heirloom gear is fine. At 80 take heirlooms
off before the first boss: RTH reminds you (chat + a popup) when you enter a dungeon or raid with one on, and a
dungeon or raid boss kill with an heirloom still on is a rule break.
Reputation enchants (arcanums, shoulder inscriptions): every character must earn the reputation itself.
One bought on another character and used on an alt is flagged - the enchant needs the wearer's own standing.
Tome of Cold Weather Flight: allowed in every phase, but each character (alts too) must buy it from the vendor
itself at level 77 or higher. Taking one from the mail (sent by another character) is a rule break.
Recipes open with the patch that added them - except low-level ones (below skill 350) and recipes for
leveling gear: those are fine from the start (e.g. Spidersilk Drape, Pumpkin Pie).
Gold: sending or getting gold with guild members (mail, COD, trade) and the guild bank is fine.
Gold from or to anyone outside the guild is a rule break - so RTH stops it before it happens:
- Mail: the Send button is greyed out ("Blocked") while a mail to someone outside the guild has gold or COD on
  it (items are fine); taking gold from their mail or paying their COD is stopped too - send it back instead.
- Trading with someone outside the guild: the window opens, but the Trade button is greyed out ("Blocked"),
  because they almost always want a tip. A popup explains it.
In a trade with a guild member, the Trade button is greyed out while their side holds an item you're not allowed
to have (red mark) - ask them to take it out. A vendor item with a red mark asks "Buy it anyway?" first.
A raid set to 25 players shows a warning before anyone zones in (10-man only).
Auction House: selling is always fine. Buying, if it's open in your phase (25-man loot never):
- fine: gear that drops (BoE), raw materials (ore, herbs, cloth, uncut gems...), recipes, pets, mounts,
  and food, drinks and reagents a vendor sells for gold
- anything only a profession makes (potions, glyphs, bars, bolts, crafted gear, bags, Darkmoon cards and
  decks...) only if someone in the group knows the recipe
- everything else: fine from the patch it came out in (nearly all of it is 3.0 or older = phase 1).
Holiday items (Brewfest, Hallow's End, Love is in the Air, Pilgrim's Bounty...): fine to buy and use, even
crafted ones without a crafter in the group - but only from the phase their patch came out (e.g. the 3.3
Love is in the Air perfumes from phase 4, Pilgrim's Bounty food from phase 3). Before that: red mark.
Bid and Buyout are greyed out ("Blocked") for items you may not buy; hover for why.
Mail, vendor and AH addons: all of this works with ElvUI's look too. Also covered:
- Postal: "Open All" and "Open" are greyed out ("Blocked") while a mail from someone outside the guild has gold in
  it - send that mail back first (open it, Return, or Postal's Return), then they work again.
- ElvUI Enhanced "Take All" / "Take Cash": takes everything else and skips that mail (it says so in chat).
- Alt-click (ElvUI Enhanced) and the stack window (ElvUI Extras) don't buy a red-marked vendor item - right-click
  it to buy one (RTH asks first). ElvUI Extras' automatic buying can't be checked: the red mark still shows.
- Auctionator: its Buy button is greyed out for an item you may not buy, and the buy itself is stopped.
/rth status lists which of these RTH found.

GOOD TO KNOW
- The first time you log in on a character, RTH asks if it's doing the challenge. Say No on alts:
  they then track nothing. You can change it any time on the Rules tab.
- Open each of your profession windows once after installing, so the group can see your recipes and cooldowns
  (Mining: open Smelting from the spellbook). RTH reminds you once per login until it's done. Then anyone can
  click your name on the Professions tab to see your recipes (Mining can't be linked in this game version:
  clicking a miner lists what they can smelt in chat).
- Open your bank once, so the item search knows what's in it.
- Nothing has to be reported by hand: kills, rule breaks and gear are tracked and shared automatically.
- RTH refreshes everyone's data by itself, quietly: when you log in (and a minute later), join a group, enter
  a dungeon or raid, level up, change gear or professions, and when someone joins or leaves the guild.
- Missed a raid night? Your Journey Log catches up by itself when you log in: from the guild master when they
  are online, otherwise from any guild member online with RTH.
- Players who are offline: anyone online passes on the last info they heard from them (professions, recipes,
  gear, lockouts, phase), so you don't have to be online at the same time. Their own RTH replaces it when they
  come back. (Needs the newer RTH on both sides; older copies keep working as before.)
- Everyone in the guild who runs RTH (and said Yes) is in the core group automatically - no party or list
  needed. Switching the challenge off on the Rules tab takes you out.
  The names box on the Rules tab is only for extra players (for example someone without RTH).
- New character or alt (alts must be in the guild and answer Yes)? It starts in Phase 1 like everyone and opens
  each phase by finishing that gate itself - achievements from before RTH don't count.
- Dungeon Finder: while leveling, random queues are fine. At 80, only "Specific Dungeons" works until every
  dungeon is open (Phase 4) - a random queue could send you somewhere locked. Dungeons of a later phase are
  greyed out in the list and can't be ticked
  (Trial of the Champion opens in Phase 3; Forge of Souls, Pit of Saron and Halls of Reflection in Phase 4).
  Heroic dungeons are fine whenever their dungeon is open.
- Passing on guild master? The new one keeps all the rules. Everyone keeps their own phase.
- A rule break is never hidden - only the guild master can delete one (e.g. a false break from an RTH bug):
  Journey Log > Rule breaks, click the break, Delete, confirm. It's gone for everyone, also those who were
  offline, and an old copy can't bring it back. Its star comes off the kills too, and a boss kill that only
  missed the phase gate because of that break counts for the gate again.
- Only the guild master can comment on a rule break: Journey Log > Rule breaks, click the break, write the
  comment (an empty box removes it). Everyone sees it under the break, also those who were offline.

COMMANDS
/rth           open or close the window
               (drag it to move it; drag the grip in its bottom-right corner to make it bigger or smaller -
               or hold Ctrl and turn the mouse wheel over it)
/rth status    check that everything is loaded and switched on
/rth check     ask the group for their gear status
/rth sync      show who RTH has heard from (the refresh itself is automatic)
/rth ping      test the connection: does the guild channel carry RTH, and who answers
/rth test trade   show the popup a trade with someone outside the guild shows (nothing is traded)
/rth gate Name N   guild master only: mark Name's gates up to phase N as finished (written in the log)

PROBLEMS?
- "/rth status" says the recipe data isn't loaded: close WoW completely and start it again (/reload is not enough).
- Any game language works. If your game isn't English and a raid, dungeon or your Herbalism isn't recognised,
  tell the guild master (/rth status shows your game language).
- Your version is shown top-left in the RTH window. Under it, a red "N outdated" means guild members run an
  older copy (hover it for the names); "update RTH!" means someone has a newer one - ask the guild master for it.
