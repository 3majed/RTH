-- Road to Halion: progress data (generated from 3.3.5a DBCs 2026-11-17)
-- stat = 10-player kill statistic (GetStatistic), statH = 10-player heroic statistic, npc = creature ID
-- required = default unlock gate (achievements) for the NEXT phase, set by the group 2026-11-18; the addon lets the leader edit it per phase.
-- gateIncludesOptional = the phase's VoA boss (and Onyxia in phase 3) must also be killed before the next phase opens.
RTH_Phases = {
  { id=1, name="Naxx tier", patch="3.0", maps={533,615,616},
    bosses = {
      { name="Anub'Rekhan", stat=1361, statH=nil, npc=15956, kill="death" },
      { name="Grand Widow Faerlina", stat=1362, statH=nil, npc=15953, kill="death" },
      { name="Maexxna", stat=1363, statH=nil, npc=15952, kill="death" },
      { name="Noth the Plaguebringer", stat=1365, statH=nil, npc=15954, kill="death" },
      { name="Heigan the Unclean", stat=1369, statH=nil, npc=15936, kill="death" },
      { name="Loatheb", stat=1370, statH=nil, npc=16011, kill="death" },
      { name="Instructor Razuvious", stat=1374, statH=nil, npc=16061, kill="death" },
      { name="Gothik the Harvester", stat=1366, statH=nil, npc=16060, kill="death" },
      { name="Four Horsemen", stat=1375, statH=nil, npc={16063,16064,16065,30549}, kill="death" },
      { name="Patchwerk", stat=1364, statH=nil, npc=16028, kill="death" },
      { name="Grobbulus", stat=1371, statH=nil, npc=15931, kill="death" },
      { name="Gluth", stat=1372, statH=nil, npc=15932, kill="death" },
      { name="Thaddius", stat=1373, statH=nil, npc=15928, kill="death" },
      { name="Sapphiron", stat=1376, statH=nil, npc=15989, kill="death" },
      { name="Kel'Thuzad", stat=1377, statH=nil, npc=15990, kill="death" },
      { name="Malygos", stat=1391, statH=nil, npc=28859, kill="death" },
      { name="Sartharion", stat=1392, statH=nil, npc=28860, kill="death" },
    },
    required = { 576 --[[The Fall of Naxxramas (10 player)]], 622 --[[The Spellweaver's Downfall (10 player)]], 2051 --[[The Twilight Zone (10 player)]] },
    gateIncludesOptional = true,
    voa = { name="Archavon", stat=1753, npc=31125 },
  },
  { id=2, name="Ulduar", patch="3.1", maps={603},
    bosses = {
      { name="Flame Leviathan", stat=2856, statH=nil, npc=33113, kill="death" },
      { name="Ignis the Furnace Master", stat=2858, statH=nil, npc=33118, kill="death" },
      { name="Razorscale", stat=2857, statH=nil, npc=33186, kill="death" },
      { name="XT-002 Deconstructor", stat=2859, statH=nil, npc=33293, kill="death" },
      { name="Assembly of Iron", stat=2860, statH=nil, npc={32867,32927,32857}, kill="death" },
      { name="Kologarn", stat=2861, statH=nil, npc=32930, kill="death" },
      { name="Auriaya", stat=2868, statH=nil, npc=33515, kill="death" },
      { name="Hodir", stat=2862, statH=nil, npc={32845}, kill="yell" },
      { name="Thorim", stat=2863, statH=nil, npc={32865}, kill="yell" },
      { name="Freya", stat=2864, statH=nil, npc={32906}, kill="yell" },
      { name="Mimiron", stat=2865, statH=nil, npc={33432}, kill="yell" },
      { name="General Vezax", stat=2866, statH=nil, npc=33271, kill="death" },
      { name="Yogg-Saron", stat=2869, statH=nil, npc=33288, kill="death" },
      { name="Algalon the Observer", stat=2867, statH=nil, npc={32871}, kill="spell" },
    },
    required = { 3159 --[[Alone in the Darkness (10 player)]] },
    gateIncludesOptional = true,
    hardmodes = {
      { boss="Flame Leviathan", achievement=3056 }, -- Orbit-uary (10 player)
      { boss="XT-002 Deconstructor", achievement=3058 }, -- Heartbreaker (10 player)
      { boss="Assembly of Iron", achievement=2941 }, -- I Choose You, Steelbreaker (10 player)
      { boss="Hodir", achievement=3182 }, -- I Could Say That This Cache Was Rare (10 player)
      { boss="Thorim", achievement=3176 }, -- Lose Your Illusion (10 player)
      { boss="Freya", achievement=3179 }, -- Knock, Knock, Knock on Wood (10 player)
      { boss="Mimiron", achievement=3180 }, -- Firefighter (10 player)
      { boss="General Vezax", achievement=3181 }, -- I Love the Smell of Saronite in the Morning (10 player)
      { boss="Yogg-Saron", achievement=3159 }, -- Alone in the Darkness (10 player)
    },
    voa = { name="Emalon", stat=2870, npc=33993 },
  },
  { id=3, name="Trial tier", patch="3.2", maps={649,249},
    bosses = {
      { name="Beasts of Northrend", stat=4028, statH=4030, npc=34797, kill="death" },
      { name="Lord Jaraxxus", stat=4032, statH=4033, npc=34780, kill="death" },
      { name="Faction Champions", stat=4036, statH=4037, npc={34458,34451,34459,34448,34449,34445,34456,34447,34441,34454,34444,34455,34450,34453,34461,34460,34469,34467,34468,34471,34465,34466,34473,34472,34470,34463,34474,34475}, kill="yell" },
      { name="Val'kyr Twins", stat=4040, statH=4041, npc=34496, kill="death" },
      { name="Anub'arak", stat=4044, statH=4045, npc=34564, kill="death" },
    },
    required = { 3810 --[[A Tribute to Insanity (10 player)]] },
    gateIncludesOptional = true,
    optional = {
      { name="Onyxia", achievement=4396, npc=10184 }, -- Onyxia's Lair (10 player)
    },
    voa = { name="Koralon", stat=4074, npc=35013 },
  },
  { id=4, name="ICC", patch="3.3", maps={631},
    bosses = {
      { name="Lord Marrowgar", stat=4639, statH=4640, npc=36612, kill="death" },
      { name="Lady Deathwhisper", stat=4643, statH=4654, npc=36855, kill="death" },
      { name="Gunship Battle", stat=4644, statH=4659, npc={36939,37215}, kill="yell" },
      { name="Deathbringer Saurfang", stat=4645, statH=4662, npc={37813}, kill="death" },
      { name="Festergut", stat=4646, statH=4665, npc=36626, kill="death" },
      { name="Rotface", stat=4647, statH=4668, npc=36627, kill="death" },
      { name="Professor Putricide", stat=4650, statH=4677, npc=36678, kill="death" },
      { name="Blood Prince Council", stat=4648, statH=4671, npc={37970,37972,37973}, kill="death" },
      { name="Blood-Queen Lana'thel", stat=4651, statH=4680, npc=37955, kill="death" },
      { name="Valithria Dreamwalker", stat=4649, statH=4674, npc={36789}, kill="spell" },
      { name="Sindragosa", stat=4652, statH=4684, npc=36853, kill="death" },
      { name="The Lich King", stat=4653, statH=4686, npc=36597, kill="death" },
    },
    required = { 4583 --[[Bane of the Fallen King]] },
    gateIncludesOptional = true,
    voa = { name="Toravon", stat=4657, npc=38433 },
  },
  { id=5, name="Ruby Sanctum", patch="3.3.5", maps={724},
    bosses = {
      { name="Halion", stat=4821, statH=4822, npc=39863, kill="death" },
    },
    required = { 4818 --[[Heroic: The Twilight Destroyer (10 player)]] },
  },
}

-- dungeon = map ID, phase it opens in, last-boss statistic on normal / heroic
RTH_Dungeons = {
  [574] = { name="Utgarde Keep", phase=1, stat=1242, statH=1504 },
  [576] = { name="The Nexus", phase=1, stat=1231, statH=1505 },
  [601] = { name="Azjol-Nerub", phase=1, stat=1232, statH=1506 },
  [619] = { name="Ahn'kahet: The Old Kingdom", phase=1, stat=1233, statH=1507 },
  [600] = { name="Drak'Tharon Keep", phase=1, stat=1234, statH=1508 },
  [608] = { name="Violet Hold", phase=1, stat=1235, statH=1509 },
  [604] = { name="Gundrak", phase=1, stat=1236, statH=1510 },
  [599] = { name="Halls of Stone", phase=1, stat=1237, statH=1511 },
  [602] = { name="Halls of Lightning", phase=1, stat=1238, statH=1512 },
  [578] = { name="The Oculus", phase=1, stat=1239, statH=1513 },
  [575] = { name="Utgarde Pinnacle", phase=1, stat=1240, statH=1514 },
  [595] = { name="The Culling of Stratholme", phase=1, stat=1241, statH=1515 },
  [650] = { name="Trial of the Champion", phase=3, stat=4026, statH=4027 },
  [632] = { name="The Forge of Souls", phase=4, stat=4715, statH=4716 },
  [658] = { name="Pit of Saron", phase=4, stat=4720, statH=4721 },
  [668] = { name="Halls of Reflection", phase=4, stat=4726, statH=4727 },
}
