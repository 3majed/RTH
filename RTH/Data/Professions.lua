-- Road to Halion: professions data (generated 2026-11-17 from 3.3.5a DBCs + world DB)
-- phase: 1=3.0 2=3.1 3=3.2 4=3.3 ; prof = skill line that MUST be on the wearer (profession-only bonus), 0 = anyone
-- skill lines: 164 Blacksmithing 165 Leatherworking 197 Tailoring 202 Engineering 755 Jewelcrafting 333 Enchanting 773 Inscription 171 Alchemy

-- recipe spell -> phase it unlocks in. Recipes NOT listed are 3.0 or older (phase 1).
RTH_RecipePatch = {
  [53963]=2,[62948]=2,[62959]=2,[63182]=2,[63187]=2,[63188]=2,[63189]=2,[63190]=2,[63191]=2,[63192]=2,
  [63194]=2,[63195]=2,[63196]=2,[63197]=2,[63198]=2,[63199]=2,[63200]=2,[63201]=2,[63203]=2,[63204]=2,
  [63205]=2,[63206]=2,[63765]=2,[63770]=2,[63924]=2,[64246]=2,[64247]=2,[64248]=2,[64249]=2,[64250]=2,
  [64251]=2,[64252]=2,[64253]=2,[64254]=2,[64255]=2,[64256]=2,[64257]=2,[64268]=2,[64270]=2,[64271]=2,
  [64273]=2,[64274]=2,[64275]=2,[64276]=2,[64277]=2,[64278]=2,[64279]=2,[64280]=2,[64281]=2,[64282]=2,
  [64283]=2,[64284]=2,[64285]=2,[64286]=2,[64287]=2,[64288]=2,[64289]=2,[64291]=2,[64294]=2,[64295]=2,
  [64296]=2,[64297]=2,[64298]=2,[64299]=2,[64300]=2,[64302]=2,[64303]=2,[64304]=2,[64305]=2,[64307]=2,
  [64308]=2,[64309]=2,[64310]=2,[64311]=2,[64312]=2,[64313]=2,[64314]=2,[64315]=2,[64316]=2,[64317]=2,
  [64318]=2,[64358]=2,[64441]=2,[64579]=2,[64661]=2,[64725]=2,[64726]=2,[64727]=2,[64728]=2,[64729]=2,
  [64730]=2,[65245]=2,[66338]=3,[66428]=3,[66429]=3,[66430]=3,[66431]=3,[66432]=3,[66433]=3,[66434]=3,
  [66435]=3,[66436]=3,[66437]=3,[66438]=3,[66439]=3,[66440]=3,[66441]=3,[66442]=3,[66443]=3,[66444]=3,
  [66445]=3,[66446]=3,[66447]=3,[66448]=3,[66449]=3,[66450]=3,[66451]=3,[66452]=3,[66453]=3,[66497]=3,
  [66498]=3,[66499]=3,[66500]=3,[66501]=3,[66502]=3,[66503]=3,[66504]=3,[66505]=3,[66506]=3,[66553]=3,
  [66554]=3,[66555]=3,[66556]=3,[66557]=3,[66558]=3,[66559]=3,[66560]=3,[66561]=3,[66562]=3,[66563]=3,
  [66564]=3,[66565]=3,[66566]=3,[66567]=3,[66568]=3,[66569]=3,[66570]=3,[66571]=3,[66572]=3,[66573]=3,
  [66574]=3,[66575]=3,[66576]=3,[66577]=3,[66578]=3,[66579]=3,[66580]=3,[66581]=3,[66582]=3,[66583]=3,
  [66584]=3,[66585]=3,[66586]=3,[66587]=3,[66658]=3,[66659]=3,[66660]=3,[66662]=3,[66663]=3,[66664]=3,
  [67025]=3,[67064]=3,[67065]=3,[67066]=3,[67079]=3,[67080]=3,[67081]=3,[67082]=3,[67083]=3,[67084]=3,
  [67085]=3,[67086]=3,[67087]=3,[67091]=3,[67092]=3,[67093]=3,[67094]=3,[67095]=3,[67096]=3,[67130]=3,
  [67131]=3,[67132]=3,[67133]=3,[67134]=3,[67135]=3,[67136]=3,[67137]=3,[67138]=3,[67139]=3,[67140]=3,
  [67141]=3,[67142]=3,[67143]=3,[67144]=3,[67145]=3,[67146]=3,[67147]=3,[67326]=3,[67790]=3,[67839]=3,
  [67920]=3,[68067]=3,[68166]=3,[68253]=3,[69385]=3,[69386]=3,[69388]=3,[69412]=3,[70550]=4,[70551]=4,
  [70552]=4,[70553]=4,[70554]=4,[70555]=4,[70556]=4,[70557]=4,[70558]=4,[70559]=4,[70560]=4,[70561]=4,
  [70562]=4,[70563]=4,[70565]=4,[70566]=4,[70567]=4,[70568]=4,[71015]=4,[71102]=4,[71692]=4,[72952]=4,
  [72953]=4,[75597]=4,
}

-- crafted gear item -> recipe spell(s) that make it (for 'made by someone in the group who knows the recipe')
RTH_CraftedBy = {
  [23565]={36256},
  [28427]={36258},
  [28430]={36259},
  [28433]={36260},
  [28436]={36261},
  [28439]={36262},
  [28442]={36263},
  [28485]={36257},
  [32389]={40023},
  [32390]={40024},
  [32391]={40020},
  [32392]={40021},
  [32393]={40006},
  [32394]={40003},
  [32395]={40004},
  [32396]={40005},
  [32397]={40002},
  [32398]={39997},
  [32399]={52733},
  [32400]={40001},
  [32401]={40036},
  [32402]={40033},
  [32403]={40034},
  [32404]={40035},
  [32420]={40060},
  [32568]={41132},
  [32570]={41133},
  [32571]={41134},
  [32573]={41135},
  [32574]={41161},
  [32575]={41162},
  [32577]={41163},
  [32579]={41164},
  [32580]={41158},
  [32581]={41160},
  [32582]={41156},
  [32583]={41157},
  [32584]={41207},
  [32585]={41208},
  [32586]={41205},
  [32587]={41206},
  [34353]={46116},
  [34354]={46114},
  [34355]={46112},
  [34356]={46113},
  [34357]={46115},
  [34358]={46127},
  [34359]={46125},
  [34360]={46126},
  [34361]={46124},
  [34362]={46122},
  [34363]={46123},
  [34364]={46130},
  [34365]={46131},
  [34366]={46128},
  [34367]={46129},
  [34369]={46138},
  [34370]={46134},
  [34371]={46136},
  [34372]={46132},
  [34373]={46137},
  [34374]={46133},
  [34375]={46139},
  [34376]={46135},
  [34377]={46144},
  [34378]={46141},
  [34379]={46142},
  [34380]={46140},
  [34847]={46111},
  [35181]={46108},
  [35182]={46109},
  [35183]={46106},
  [35184]={46110},
  [35185]={46107},
  [38322]={59497},
  [38400]={50944},
  [38401]={50945},
  [38402]={50946},
  [38403]={50947},
  [38404]={50948},
  [38405]={50949},
  [38406]={50943},
  [38407]={50942},
  [38408]={50938},
  [38409]={50941},
  [38410]={50939},
  [38411]={50940},
  [38412]={50955},
  [38413]={50954},
  [38414]={50950},
  [38415]={50953},
  [38416]={50951},
  [38417]={50958},
  [38418]={50961},
  [38419]={50960},
  [38420]={50956},
  [38421]={50959},
  [38422]={50957},
  [38424]={50952},
  [38433]={51571},
  [38434]={60607},
  [38435]={60622},
  [38436]={60599},
  [38437]={51572},
  [38438]={60608},
  [38439]={60624},
  [38440]={60600},
  [38441]={60631},
  [38590]={51568},
  [38591]={51569},
  [38592]={51570},
  [39083]={52572},
  [39084]={52571},
  [39085]={52570},
  [39086]={52567},
  [39087]={52568},
  [39088]={52569},
  [39688]={54353},
  [40668]={54550},
  [40669]={54551},
  [40670]={54557},
  [40671]={54552},
  [40672]={54553},
  [40673]={54555},
  [40674]={54554},
  [40675]={54556},
  [40767]={56466},
  [40865]={56467},
  [40942]={54917},
  [40943]={54947},
  [40949]={54918},
  [40950]={54941},
  [40951]={54944},
  [40952]={54945},
  [40953]={54946},
  [40954]={54948},
  [40955]={54949},
  [40956]={54978},
  [40957]={54979},
  [40958]={54980},
  [40959]={54981},
  [41112]={56465},
  [41113]={55014},
  [41114]={55015},
  [41116]={55017},
  [41117]={55013},
  [41121]={56469},
  [41126]={55055},
  [41127]={55056},
  [41128]={55057},
  [41129]={55058},
  [41168]={56479},
  [41181]={55174},
  [41182]={55177},
  [41183]={55179},
  [41184]={55181},
  [41185]={55182},
  [41186]={55183},
  [41187]={55184},
  [41188]={55185},
  [41189]={55186},
  [41190]={55187},
  [41238]={55199},
  [41239]={55200},
  [41240]={55201},
  [41241]={55202},
  [41242]={55203},
  [41243]={55204},
  [41245]={55206},
  [41257]={55369},
  [41264]={55243},
  [41344]={55302},
  [41345]={55303},
  [41346]={55304},
  [41347]={55310},
  [41348]={55308},
  [41349]={55309},
  [41350]={55312},
  [41351]={55306},
  [41352]={55307},
  [41353]={55311},
  [41354]={55305},
  [41355]={55298},
  [41356]={55300},
  [41357]={55301},
  [41383]={55370},
  [41384]={55371},
  [41386]={55372},
  [41387]={55373},
  [41388]={55374},
  [41391]={55375},
  [41392]={55376},
  [41394]={55377},
  [41512]={56031},
  [41513]={55902},
  [41515]={55903},
  [41516]={59586},
  [41519]={56030},
  [41520]={55906},
  [41521]={55907},
  [41522]={55908},
  [41523]={55910},
  [41525]={55911},
  [41528]={55913},
  [41543]={55914},
  [41544]={55924,56048},
  [41545]={55922},
  [41546]={55919},
  [41548]={55901},
  [41549]={55921},
  [41550]={55923},
  [41551]={55920},
  [41553]={55925},
  [41554]={55941},
  [41555]={55943},
  [41607]={56014},
  [41608]={56015},
  [41609]={56016},
  [41610]={56017},
  [41974]={55834},
  [41975]={55835},
  [41984]={56018},
  [41985]={56019},
  [41986]={56020},
  [42093]={56021},
  [42095]={56022},
  [42096]={56023},
  [42100]={56024},
  [42101]={56026},
  [42102]={56028},
  [42103]={56025},
  [42111]={56027},
  [42113]={56029},
  [42336]={56193},
  [42337]={56194},
  [42338]={56195},
  [42339]={56196},
  [42340]={56197},
  [42341]={56199},
  [42395]={56201},
  [42413]={56202},
  [42418]={56203},
  [42435]={56234},
  [42443]={56280},
  [42508]={56400},
  [42549]={56480},
  [42550]={56481},
  [42551]={56574},
  [42552]={56483},
  [42553]={56484},
  [42554]={56486},
  [42555]={56487},
  [42642]={56496},
  [42643]={56497},
  [42644]={56498},
  [42645]={56499},
  [42646]={56500},
  [42647]={56501},
  [42723]={56549},
  [42724]={56553},
  [42725]={56555},
  [42726]={56554},
  [42727]={56550},
  [42728]={56556},
  [42729]={56551},
  [42730]={56552},
  [42731]={60660},
  [43129]={60649},
  [43130]={60651},
  [43131]={60652},
  [43132]={60655},
  [43133]={60658},
  [43244]={58141},
  [43245]={58142},
  [43246]={58143},
  [43247]={58144},
  [43248]={58145},
  [43249]={58146},
  [43250]={58147},
  [43251]={58148},
  [43252]={58149},
  [43253]={58150},
  [43255]={60665},
  [43256]={60666},
  [43257]={60669},
  [43258]={60671},
  [43260]={60697},
  [43261]={60715},
  [43262]={60716},
  [43263]={60718},
  [43264]={60720},
  [43265]={60721},
  [43266]={60723},
  [43271]={60725},
  [43273]={60727},
  [43433]={60702},
  [43434]={60703},
  [43435]={60704},
  [43436]={60705},
  [43437]={60706},
  [43438]={60711},
  [43439]={60712},
  [43442]={60734},
  [43443]={60737},
  [43444]={60731},
  [43445]={60730},
  [43446]={60732},
  [43447]={60728},
  [43448]={60735},
  [43449]={60729},
  [43450]={60750},
  [43451]={60752},
  [43452]={60748},
  [43453]={60747},
  [43454]={60749},
  [43455]={60743},
  [43456]={60751},
  [43457]={60746},
  [43458]={60754},
  [43459]={60755},
  [43461]={60756},
  [43469]={60757},
  [43481]={60758},
  [43482]={58492},
  [43484]={60759},
  [43495]={60760},
  [43498]={58507},
  [43502]={60761},
  [43565]={60640},
  [43566]={60637},
  [43582]={58954},
  [43583]={60993},
  [43584]={60990},
  [43585]={60994},
  [43586]={61008},
  [43587]={61009},
  [43588]={61010},
  [43590]={60996},
  [43591]={60997},
  [43592]={60998},
  [43593]={60999},
  [43594]={61000},
  [43595]={61002},
  [43860]={59436},
  [43864]={59438},
  [43865]={59440},
  [43870]={59441},
  [43871]={59442},
  [43969]={59582},
  [43970]={59585},
  [43971]={59589},
  [43972]={59587},
  [43973]={59584},
  [43974]={59583},
  [43975]={59588},
  [44063]={59759},
  [44210]={59498},
  [44211]={55904},
  [44436]={60601},
  [44437]={60604},
  [44438]={60605},
  [44440]={60611},
  [44441]={60613},
  [44442]={60620},
  [44443]={60627},
  [44444]={60629},
  [44445]={60630},
  [44504]={60874},
  [44740]={61481},
  [44741]={61482},
  [44742]={61483},
  [44930]={62176},
  [44931]={62177},
  [44949]={62271},
  [45085]={63182},
  [45550]={63187},
  [45551]={63191},
  [45552]={63189},
  [45553]={63194},
  [45554]={63196},
  [45555]={63198},
  [45556]={63200},
  [45557]={63203},
  [45558]={63205},
  [45559]={63188},
  [45560]={63192},
  [45561]={63190},
  [45562]={63195},
  [45563]={63197},
  [45564]={63199},
  [45565]={63201},
  [45566]={63204},
  [45567]={63206},
  [45808]={64727},
  [45809]={64728},
  [45810]={64730},
  [45811]={64729},
  [45812]={64725},
  [45813]={64726},
  [45849]={64053},
  [45854]={64051},
  [47570]={67092},
  [47571]={67131},
  [47572]={67094},
  [47573]={67133},
  [47574]={67096},
  [47575]={67135},
  [47576]={67083},
  [47577]={67143},
  [47579]={67081},
  [47580]={67137},
  [47581]={67087},
  [47582]={67139},
  [47583]={67085},
  [47584]={67141},
  [47585]={67079},
  [47586]={67145},
  [47587]={67065},
  [47588]={67147},
  [47589]={67093},
  [47590]={67132},
  [47591]={67091},
  [47592]={67130},
  [47593]={67095},
  [47594]={67134},
  [47595]={67082},
  [47596]={67138},
  [47597]={67080},
  [47598]={67136},
  [47599]={67086},
  [47600]={67142},
  [47601]={67140},
  [47602]={67084},
  [47603]={67066},
  [47604]={67146},
  [47605]={67064},
  [47606]={67144},
  [49890]={70551},
  [49891]={70550},
  [49892]={70552},
  [49893]={70553},
  [49894]={70555},
  [49895]={70557},
  [49896]={70559},
  [49897]={70561},
  [49898]={70554},
  [49899]={70556},
  [49900]={70558},
  [49901]={70560},
  [49902]={70562},
  [49903]={70565},
  [49904]={70567},
  [49905]={70563},
  [49906]={70566},
  [49907]={70568},
}

-- item that applies an enchant (leg armor, spellthread, scope, kit, scroll...) -> recipe spell(s) that make it
RTH_EnchantItemBy = {
  [2304]={2152},
  [2313]={2165},
  [4265]={3780},
  [4405]={3977},
  [4406]={3978},
  [4407]={3979},
  [6041]={7224},
  [6042]={7221},
  [6043]={7222},
  [7967]={9939},
  [7969]={9964},
  [8173]={10487},
  [10546]={12597},
  [10548]={12620},
  [12645]={16651},
  [15564]={19058},
  [18251]={22727},
  [18283]={22793},
  [23530]={29657},
  [23764]={30329},
  [23765]={30332},
  [23766]={30334},
  [24273]={31430},
  [24274]={31432},
  [24275]={31431},
  [24276]={31433},
  [25650]={32456},
  [25651]={32457},
  [25652]={32458},
  [29483]={35520},
  [29485]={35521},
  [29486]={35522},
  [29487]={35523},
  [29488]={35524},
  [29533]={35549},
  [29534]={35555},
  [29535]={35554},
  [29536]={35557},
  [33185]={42688},
  [34207]={44770},
  [34330]={44970},
  [38371]={50964},
  [38372]={50966},
  [38373]={50965},
  [38374]={50967},
  [38375]={50962},
  [38376]={50963},
  [41146]={56470},
  [41167]={56478},
  [41601]={56008},
  [41602]={56009},
  [41603]={56010},
  [41604]={56011},
  [41611]={55656},
  [41976]={55839},
  [42500]={56357},
  [44739]={61471},
  [44936]={62202},
  [44963]={62448},
}

-- enchant ID (as in item links) -> phase, recipe spells that apply it, items that apply it, buyable (no profession needed), profession-only
RTH_Enchants = {
  [15]={phase=1, spells={}, items={2304}, buy=false, prof=0}, -- Reinforced (+8 Armor)
  [16]={phase=1, spells={}, items={2313}, buy=false, prof=0}, -- Reinforced (+16 Armor)
  [17]={phase=1, spells={}, items={4265}, buy=false, prof=0}, -- Reinforced (+24 Armor)
  [18]={phase=1, spells={}, items={8173}, buy=false, prof=0}, -- Reinforced (+32 Armor)
  [24]={phase=1, spells={7443}, items={38769}, buy=false, prof=0}, -- +5 Mana
  [30]={phase=1, spells={}, items={4405}, buy=false, prof=0}, -- Scope (+1 Damage)
  [32]={phase=1, spells={}, items={4406}, buy=false, prof=0}, -- Scope (+2 Damage)
  [33]={phase=1, spells={}, items={4407}, buy=false, prof=0}, -- Scope (+3 Damage)
  [34]={phase=1, spells={}, items={6043}, buy=false, prof=0}, -- Counterweight (+20 Haste Rating)
  [36]={phase=1, spells={}, items={5421}, buy=false, prof=0}, -- Enchant: Fiery Blaze
  [37]={phase=1, spells={}, items={6041}, buy=false, prof=0}, -- Steel Weapon Chain
  [41]={phase=1, spells={7418,7420}, items={38679,38766}, buy=false, prof=0}, -- +5 Health
  [43]={phase=1, spells={}, items={6042}, buy=false, prof=0}, -- Iron Spike (8-12)
  [44]={phase=1, spells={7426}, items={38767}, buy=false, prof=0}, -- Absorption (10)
  [63]={phase=1, spells={13538}, items={38798}, buy=false, prof=0}, -- Absorption (25)
  [65]={phase=1, spells={7454}, items={38770}, buy=false, prof=0}, -- +1 All Resistances
  [66]={phase=1, spells={7457,7863,13378}, items={38771,38785,38787}, buy=false, prof=0}, -- +1 Stamina
  [76]={phase=1, spells={}, items={22584}, buy=false, prof=0}, -- +3 Agility
  [241]={phase=1, spells={7745,13503}, items={38772,38794}, buy=false, prof=0}, -- +2 Weapon Damage
  [242]={phase=1, spells={7748}, items={38773}, buy=false, prof=0}, -- +15 Health
  [243]={phase=1, spells={7766}, items={38774}, buy=false, prof=0}, -- +1 Spirit
  [246]={phase=1, spells={7776}, items={38776}, buy=false, prof=0}, -- +20 Mana
  [247]={phase=1, spells={7779,7867,13419}, items={38777,38786,38789}, buy=false, prof=0}, -- +1 Agility
  [248]={phase=1, spells={7782}, items={38778}, buy=false, prof=0}, -- +1 Strength
  [249]={phase=1, spells={7786}, items={38779}, buy=false, prof=0}, -- +2 Beastslaying
  [250]={phase=1, spells={7788}, items={38780}, buy=false, prof=0}, -- +1  Weapon Damage
  [254]={phase=1, spells={7857}, items={38782}, buy=false, prof=0}, -- +25 Health
  [255]={phase=1, spells={7859,13380,13485,13687}, items={38783,38788,38792,38819}, buy=false, prof=0}, -- +3 Spirit
  [256]={phase=1, spells={7861}, items={38784}, buy=false, prof=0}, -- +5 Fire Resistance
  [368]={phase=1, spells={34004}, items={29860,38940}, buy=false, prof=0}, -- +12 Agility
  [369]={phase=1, spells={34001}, items={38937}, buy=false, prof=0}, -- +12 Intellect
  [463]={phase=1, spells={}, items={7967}, buy=false, prof=0}, -- Mithril Spike (16-20)
  [464]={phase=1, spells={}, items={7969}, buy=false, prof=0}, -- +4% Mount Speed
  [663]={phase=1, spells={}, items={10546}, buy=false, prof=0}, -- Scope (+5 Damage)
  [664]={phase=1, spells={}, items={10548}, buy=false, prof=0}, -- Scope (+7 Damage)
  [684]={phase=1, spells={33995}, items={38933}, buy=false, prof=0}, -- +15 Strength
  [723]={phase=1, spells={7793,13622}, items={38781,38803}, buy=false, prof=0}, -- +3 Intellect
  [724]={phase=1, spells={13501,13631,13644}, items={38793,38805,38810}, buy=false, prof=0}, -- +3 Stamina
  [744]={phase=1, spells={13421}, items={38790}, buy=false, prof=0}, -- +20 Armor
  [783]={phase=1, spells={7771}, items={38775}, buy=false, prof=0}, -- +10 Armor
  [803]={phase=1, spells={13898}, items={38838}, buy=false, prof=0}, -- Fiery Weapon
  [804]={phase=1, spells={13522}, items={38795}, buy=false, prof=0}, -- +10 Shadow Resistance
  [805]={phase=1, spells={13943}, items={38848}, buy=false, prof=0}, -- +4 Weapon Damage
  [823]={phase=1, spells={13536}, items={38797}, buy=false, prof=0}, -- +3 Strength
  [843]={phase=1, spells={13607}, items={38799}, buy=false, prof=0}, -- +30 Mana
  [844]={phase=1, spells={13612}, items={38800}, buy=false, prof=0}, -- +2 Mining
  [845]={phase=1, spells={13617}, items={38801}, buy=false, prof=0}, -- +2 Herbalism
  [846]={phase=4, spells={71692}, items={19971,50816}, buy=false, prof=0}, -- +5 Fishing
  [847]={phase=1, spells={13626}, items={38804}, buy=false, prof=0}, -- +1 All Stats
  [848]={phase=1, spells={13464,13635}, items={38791,38806}, buy=false, prof=0}, -- +30 Armor
  [849]={phase=1, spells={13637,13882}, items={38807,38835}, buy=false, prof=0}, -- +3 Agility
  [850]={phase=1, spells={13640}, items={38808}, buy=false, prof=0}, -- +35 Health
  [851]={phase=1, spells={13642,13659,20024}, items={38809,38816,38864}, buy=false, prof=0}, -- +5 Spirit
  [852]={phase=1, spells={13648,13817,13836}, items={38812,38828,38830}, buy=false, prof=0}, -- +5 Stamina
  [853]={phase=1, spells={13653}, items={38813}, buy=false, prof=0}, -- +6 Beastslaying
  [854]={phase=1, spells={13655}, items={38814}, buy=false, prof=0}, -- +6 Elemental Slayer
  [856]={phase=1, spells={13661,13887}, items={38817,38836}, buy=false, prof=0}, -- +5 Strength
  [857]={phase=1, spells={13663}, items={38818}, buy=false, prof=0}, -- +50 Mana
  [863]={phase=1, spells={13689}, items={38820}, buy=false, prof=0}, -- +10 Shield Block Rating
  [865]={phase=1, spells={13698}, items={38823}, buy=false, prof=0}, -- +5 Skinning
  [866]={phase=1, spells={13700}, items={38824}, buy=false, prof=0}, -- +2 All Stats
  [884]={phase=1, spells={13746}, items={38825}, buy=false, prof=0}, -- +50 Armor
  [903]={phase=1, spells={13794}, items={38826}, buy=false, prof=0}, -- +3 All Resistances
  [904]={phase=1, spells={13815,13935}, items={38827,38844}, buy=false, prof=0}, -- +5 Agility
  [905]={phase=1, spells={13822}, items={38829}, buy=false, prof=0}, -- +5 Intellect
  [906]={phase=1, spells={13841}, items={38831}, buy=false, prof=0}, -- +5 Mining
  [907]={phase=1, spells={13846,13905}, items={38832,38839}, buy=false, prof=0}, -- +7 Spirit
  [908]={phase=1, spells={13858}, items={38833}, buy=false, prof=0}, -- +50 Health
  [909]={phase=1, spells={13868}, items={38834}, buy=false, prof=0}, -- +5 Herbalism
  [910]={phase=1, spells={25083}, items={38893}, buy=false, prof=0}, -- Increased Stealth
  [911]={phase=1, spells={13890}, items={38837}, buy=false, prof=0}, -- Minor Speed Increase
  [912]={phase=1, spells={13915}, items={38840}, buy=false, prof=0}, -- Demonslaying
  [913]={phase=1, spells={13917}, items={38841}, buy=false, prof=0}, -- +65 Mana
  [923]={phase=1, spells={13931}, items={38842}, buy=false, prof=0}, -- +5 Defense Rating
  [924]={phase=1, spells={7428}, items={38768}, buy=false, prof=0}, -- +2 Defense Rating
  [925]={phase=1, spells={13646}, items={38811}, buy=false, prof=0}, -- +3 Defense Rating
  [926]={phase=1, spells={13933}, items={38843}, buy=false, prof=0}, -- +8 Frost Resistance
  [927]={phase=1, spells={13939,20013}, items={38846,38857}, buy=false, prof=0}, -- +7 Strength
  [928]={phase=1, spells={13941}, items={38847}, buy=false, prof=0}, -- +3 All Stats
  [929]={phase=1, spells={13945,20017,20020}, items={38849,38861,38862}, buy=false, prof=0}, -- +7 Stamina
  [930]={phase=1, spells={13947}, items={38850}, buy=false, prof=0}, -- +2% Mount Speed
  [931]={phase=1, spells={13948}, items={38851}, buy=false, prof=0}, -- +10 Haste Rating
  [943]={phase=1, spells={13529,13693}, items={38796,38821}, buy=false, prof=0}, -- +3 Weapon Damage
  [963]={phase=1, spells={13937,27967}, items={38845,38917}, buy=false, prof=0}, -- +7 Weapon Damage
  [983]={phase=1, spells={44500,44589}, items={38959,38976}, buy=false, prof=0}, -- +16 Agility
  [1071]={phase=1, spells={34009}, items={38945}, buy=false, prof=0}, -- +18 Stamina
  [1075]={phase=1, spells={44528}, items={38966}, buy=false, prof=0}, -- +22 Stamina
  [1099]={phase=1, spells={60663}, items={44457}, buy=false, prof=0}, -- +22 Agility
  [1103]={phase=1, spells={44633}, items={38995}, buy=false, prof=0}, -- +26 Agility
  [1119]={phase=1, spells={44555}, items={38968}, buy=false, prof=0}, -- +16 Intellect
  [1128]={phase=1, spells={60653}, items={44455}, buy=false, prof=0}, -- +25 Intellect
  [1144]={phase=1, spells={33990}, items={29871,38928}, buy=false, prof=0}, -- +15 Spirit
  [1147]={phase=1, spells={44508,44593}, items={38961,38980}, buy=false, prof=0}, -- +18 Spirit
  [1257]={phase=1, spells={34005}, items={38941}, buy=false, prof=0}, -- +15 Arcane Resistance
  [1262]={phase=1, spells={44596}, items={38982}, buy=false, prof=0}, -- +20 Arcane Resistance
  [1354]={phase=1, spells={44556}, items={38969}, buy=false, prof=0}, -- +20 Fire Resistance
  [1400]={phase=1, spells={44494}, items={38956}, buy=false, prof=0}, -- +20 Nature Resistance
  [1441]={phase=1, spells={34006}, items={38942}, buy=false, prof=0}, -- +15 Shadow Resistance
  [1446]={phase=1, spells={44590}, items={38977}, buy=false, prof=0}, -- +20 Shadow Resistance
  [1483]={phase=1, spells={}, items={11622}, buy=false, prof=0}, -- +150 Mana
  [1503]={phase=1, spells={}, items={11642}, buy=false, prof=0}, -- +100 Health
  [1504]={phase=1, spells={}, items={11643}, buy=false, prof=0}, -- +125 Armor
  [1505]={phase=1, spells={}, items={11644}, buy=false, prof=0}, -- +20 Fire Resistance
  [1506]={phase=1, spells={}, items={11645}, buy=false, prof=0}, -- +8 Strength
  [1507]={phase=1, spells={}, items={11646}, buy=false, prof=0}, -- +8 Stamina
  [1508]={phase=1, spells={}, items={11647}, buy=false, prof=0}, -- +8 Agility
  [1509]={phase=1, spells={}, items={11648}, buy=false, prof=0}, -- +8 Intellect
  [1510]={phase=1, spells={}, items={11649}, buy=false, prof=0}, -- +8 Spirit
  [1528]={phase=1, spells={}, items={11671}, buy=false, prof=0}, -- +10/14 AGI/FR
  [1530]={phase=1, spells={}, items={11672}, buy=false, prof=0}, -- +10/14 SPI/FR
  [1593]={phase=1, spells={34002}, items={31843,38938}, buy=false, prof=0}, -- +24 Attack Power
  [1594]={phase=1, spells={33996}, items={29868,38934}, buy=false, prof=0}, -- +26 Attack Power
  [1597]={phase=1, spells={60763}, items={44469}, buy=false, prof=0}, -- +32 Attack Power
  [1600]={phase=1, spells={60616}, items={38971}, buy=false, prof=0}, -- +38 Attack Power
  [1603]={phase=1, spells={60668}, items={44458}, buy=false, prof=0}, -- +44 Attack Power
  [1606]={phase=1, spells={60621}, items={44453}, buy=false, prof=0}, -- +50 Attack Power
  [1704]={phase=1, spells={}, items={12645}, buy=false, prof=0}, -- Thorium Spike (20-30)
  [1843]={phase=1, spells={}, items={15564}, buy=false, prof=0}, -- Reinforced (+40 Armor)
  [1883]={phase=1, spells={20008}, items={38852}, buy=false, prof=0}, -- +7 Intellect
  [1884]={phase=1, spells={20009}, items={38853}, buy=false, prof=0}, -- +9 Spirit
  [1885]={phase=1, spells={20010}, items={38854}, buy=false, prof=0}, -- +9 Strength
  [1886]={phase=1, spells={20011}, items={38855}, buy=false, prof=0}, -- +9 Stamina
  [1887]={phase=1, spells={20012,20023}, items={38856,38863}, buy=false, prof=0}, -- +7 Agility
  [1888]={phase=1, spells={20014,27947}, items={38858,38907}, buy=false, prof=0}, -- +5 All Resistances
  [1889]={phase=1, spells={20015}, items={38859}, buy=false, prof=0}, -- +70 Armor
  [1890]={phase=1, spells={20016}, items={38860}, buy=false, prof=0}, -- +4 Mana and Health every 5 sec
  [1891]={phase=1, spells={20025,27905}, items={38865,38898}, buy=false, prof=0}, -- +4 All Stats
  [1892]={phase=1, spells={20026}, items={17882,38866}, buy=false, prof=0}, -- +100 Health
  [1893]={phase=1, spells={20028}, items={38867}, buy=false, prof=0}, -- +100 Mana
  [1894]={phase=1, spells={20029}, items={38868}, buy=false, prof=0}, -- Icy Weapon
  [1896]={phase=1, spells={20030}, items={17887,38869}, buy=false, prof=0}, -- +9 Weapon Damage
  [1897]={phase=1, spells={13695,20031}, items={38822,38870}, buy=false, prof=0}, -- +5 Weapon Damage
  [1898]={phase=1, spells={20032}, items={38871,38916}, buy=false, prof=0}, -- Lifestealing
  [1899]={phase=1, spells={20033}, items={22024,38872}, buy=false, prof=0}, -- Unholy Weapon
  [1900]={phase=1, spells={20034}, items={38873}, buy=false, prof=0}, -- Crusader
  [1903]={phase=1, spells={20035}, items={38874}, buy=false, prof=0}, -- +9 Spirit
  [1904]={phase=1, spells={20036}, items={38875}, buy=false, prof=0}, -- +9 Intellect
  [1951]={phase=1, spells={44591,46594}, items={38978,38999}, buy=false, prof=0}, -- +16 Defense Rating
  [1952]={phase=1, spells={44489}, items={38954}, buy=false, prof=0}, -- +20 Defense Rating
  [1953]={phase=1, spells={47766}, items={39002}, buy=false, prof=0}, -- +22 Defense Rating
  [2322]={phase=1, spells={33999}, items={38936}, buy=false, prof=0}, -- +19 Spell Power
  [2326]={phase=1, spells={44635}, items={38997}, buy=false, prof=0}, -- +23 Spell Power
  [2332]={phase=1, spells={60767}, items={44470}, buy=false, prof=0}, -- +30 Spell Power
  [2381]={phase=1, spells={44509}, items={38962}, buy=false, prof=0}, -- +10 mana every 5 sec.
  [2443]={phase=1, spells={21931}, items={38876}, buy=false, prof=0}, -- +7 Frost Spell Damage
  [2463]={phase=1, spells={13657}, items={38815}, buy=false, prof=0}, -- +7 Fire Resistance
  [2483]={phase=1, spells={}, items={18169}, buy=true, prof=0}, -- +5 Fire Resistance
  [2484]={phase=1, spells={}, items={18170}, buy=true, prof=0}, -- +5 Frost Resistance
  [2485]={phase=1, spells={}, items={18171}, buy=true, prof=0}, -- +5 Arcane Resistance
  [2486]={phase=1, spells={}, items={18172}, buy=true, prof=0}, -- +5 Nature Resistance
  [2487]={phase=1, spells={}, items={18173}, buy=true, prof=0}, -- +5 Shadow Resistance
  [2488]={phase=1, spells={}, items={18182}, buy=true, prof=0}, -- +5 All Resistances
  [2503]={phase=1, spells={}, items={18251}, buy=false, prof=0}, -- +5 Defense Rating
  [2504]={phase=1, spells={22749}, items={38877}, buy=false, prof=0}, -- +30 Spell Power
  [2505]={phase=1, spells={22750}, items={38878}, buy=false, prof=0}, -- +29 Spell Power
  [2523]={phase=1, spells={}, items={18283}, buy=false, prof=0}, -- +30 Ranged Hit Rating
  [2543]={phase=1, spells={}, items={18329}, buy=false, prof=0}, -- +10 Haste Rating
  [2544]={phase=1, spells={}, items={18330}, buy=false, prof=0}, -- +8 Spell Power
  [2545]={phase=1, spells={}, items={18331}, buy=false, prof=0}, -- +12 Dodge Rating
  [2563]={phase=1, spells={23799}, items={38879}, buy=false, prof=0}, -- +15 Strength
  [2564]={phase=1, spells={23800,25080}, items={22020,38880,38890}, buy=false, prof=0}, -- +15 Agility
  [2565]={phase=1, spells={23801}, items={38881}, buy=false, prof=0}, -- Mana Regen 5 per 5 sec.
  [2567]={phase=1, spells={23803}, items={22023,38883}, buy=false, prof=0}, -- +20 Spirit
  [2568]={phase=1, spells={23804}, items={38884}, buy=false, prof=0}, -- +22 Intellect
  [2583]={phase=1, spells={}, items={19782}, buy=false, prof=0}, -- +10 Defense Rating +10 Stamina +30 Block Value
  [2584]={phase=1, spells={}, items={19783}, buy=false, prof=0}, -- +10 Defense +10 Stamina and +12 Spell Power
  [2587]={phase=1, spells={}, items={19786}, buy=false, prof=0}, -- +13 Spell Power and +15 Intellect
  [2588]={phase=1, spells={}, items={19787}, buy=false, prof=0}, -- +18 Spell Power and +8 Hit Rating
  [2589]={phase=1, spells={}, items={19788}, buy=false, prof=0}, -- +18 Spell Power and +10 Stamina
  [2590]={phase=1, spells={}, items={19789}, buy=false, prof=0}, -- +13 Spell Power +10 Stamina and +5 Mana every 5 seconds
  [2591]={phase=1, spells={}, items={19790}, buy=false, prof=0}, -- +10 Intellect +10 Stamina +12 Spell Power
  [2603]={phase=1, spells={13620}, items={38802}, buy=false, prof=0}, -- +2 Fishing
  [2604]={phase=1, spells={}, items={20078}, buy=false, prof=0}, -- +18 Spell Power
  [2605]={phase=1, spells={}, items={20076}, buy=false, prof=0}, -- +18 Spell Power
  [2606]={phase=1, spells={}, items={20077}, buy=false, prof=0}, -- +30 Attack Power
  [2613]={phase=1, spells={25072}, items={38885}, buy=false, prof=0}, -- +2% Threat
  [2614]={phase=1, spells={25073}, items={38886}, buy=false, prof=0}, -- +20 Shadow Spell Power
  [2615]={phase=1, spells={25074}, items={38887}, buy=false, prof=0}, -- +20 Frost Spell Power
  [2616]={phase=1, spells={25078}, items={38888}, buy=false, prof=0}, -- +20 Fire Spell Power
  [2617]={phase=1, spells={25079}, items={38889}, buy=false, prof=0}, -- +16 Spell Power
  [2619]={phase=1, spells={25081}, items={38891}, buy=false, prof=0}, -- +15 Fire Resistance
  [2620]={phase=1, spells={25082}, items={38892}, buy=false, prof=0}, -- +15 Nature Resistance
  [2621]={phase=1, spells={25084}, items={22042,38894}, buy=false, prof=0}, -- 2% Reduced Threat
  [2622]={phase=1, spells={25086}, items={38895}, buy=false, prof=0}, -- +12 Dodge Rating
  [2646]={phase=1, spells={27837}, items={38896}, buy=false, prof=0}, -- +25 Agility
  [2647]={phase=1, spells={27899}, items={31849,38897}, buy=false, prof=0}, -- +12 Strength
  [2648]={phase=1, spells={27906,47051}, items={38899,39000}, buy=false, prof=0}, -- +12 Defense Rating
  [2649]={phase=1, spells={27914,27950}, items={29857,38902,38909}, buy=false, prof=0}, -- +12 Stamina
  [2650]={phase=1, spells={23802,27911,27917}, items={31845,38882,38900,38903}, buy=false, prof=0}, -- +15 Spell Power
  [2653]={phase=1, spells={27944}, items={38904}, buy=false, prof=0}, -- +36 Block Value
  [2654]={phase=1, spells={27945}, items={38905}, buy=false, prof=0}, -- +12 Intellect
  [2655]={phase=1, spells={27946}, items={38906}, buy=false, prof=0}, -- +15 Shield Block Rating
  [2656]={phase=1, spells={27948}, items={38908}, buy=false, prof=0}, -- +5 Health and Mana every 5 sec
  [2657]={phase=1, spells={27951}, items={29856,37603}, buy=false, prof=0}, -- +12 Agility
  [2658]={phase=1, spells={27954}, items={38910}, buy=false, prof=0}, -- +10 Hit Rating and +10 Critical Strike Rating
  [2659]={phase=1, spells={27957}, items={29874,38911}, buy=false, prof=0}, -- +150 Health
  [2661]={phase=1, spells={27960,44616}, items={29872,38913,38987}, buy=false, prof=0}, -- +6 All Stats
  [2662]={phase=1, spells={27961}, items={38914}, buy=false, prof=0}, -- +120 Armor
  [2664]={phase=1, spells={27962}, items={38915}, buy=false, prof=0}, -- +7 Resist All
  [2666]={phase=1, spells={27968}, items={38918}, buy=false, prof=0}, -- +30 Intellect
  [2667]={phase=1, spells={27971}, items={38919}, buy=false, prof=0}, -- +70 Attack Power
  [2668]={phase=1, spells={27972}, items={38920}, buy=false, prof=0}, -- +20 Strength
  [2669]={phase=1, spells={27975}, items={29842,38921}, buy=false, prof=0}, -- +40 Spell Power
  [2670]={phase=1, spells={27977}, items={38922}, buy=false, prof=0}, -- +35 Agility
  [2671]={phase=1, spells={27981}, items={29841,38923}, buy=false, prof=0}, -- +50 Arcane and Fire Spell Power
  [2672]={phase=1, spells={27982}, items={29840,38924}, buy=false, prof=0}, -- +54 Shadow and Frost Spell Power
  [2673]={phase=1, spells={27984}, items={29839,38925}, buy=false, prof=0}, -- Mongoose
  [2674]={phase=1, spells={28003}, items={38926}, buy=false, prof=0}, -- Spellsurge
  [2675]={phase=1, spells={28004}, items={38927}, buy=false, prof=0}, -- Battlemaster
  [2679]={phase=1, spells={27913}, items={38901}, buy=false, prof=0}, -- 8 Mana per 5 Sec.
  [2681]={phase=1, spells={}, items={22635}, buy=false, prof=0}, -- +10 Nature Resistance
  [2682]={phase=1, spells={}, items={22636}, buy=false, prof=0}, -- +10 Frost Resistance
  [2683]={phase=1, spells={}, items={22638}, buy=false, prof=0}, -- +10 Shadow Resistance
  [2714]={phase=1, spells={}, items={23530}, buy=false, prof=0}, -- Felsteel Spike (26-38)
  [2715]={phase=1, spells={}, items={23547}, buy=false, prof=0}, -- +16 Spell Power and 6 Mana every 5 seconds
  [2716]={phase=1, spells={}, items={23549}, buy=false, prof=0}, -- +16 Stamina and +100 Armor
  [2717]={phase=1, spells={}, items={23548}, buy=false, prof=0}, -- +26 Attack Power and +14 Critical Strike Rating
  [2721]={phase=1, spells={}, items={23545}, buy=false, prof=0}, -- +15 Spell Power and +14 Critical Strike Rating
  [2722]={phase=1, spells={}, items={23764}, buy=false, prof=0}, -- Scope (+10 Damage)
  [2723]={phase=1, spells={}, items={23765}, buy=false, prof=0}, -- Scope (+12 Damage)
  [2724]={phase=1, spells={}, items={23766}, buy=false, prof=0}, -- Scope (+28 Critical Strike Rating)
  [2745]={phase=1, spells={}, items={24275}, buy=false, prof=0}, -- +25 Spell Power and +15 Stamina
  [2746]={phase=1, spells={}, items={24276}, buy=false, prof=0}, -- +35 Spell Power and +20 Stamina
  [2747]={phase=1, spells={}, items={24273}, buy=false, prof=0}, -- +25 Spell Power and +15 Stamina
  [2748]={phase=1, spells={}, items={24274}, buy=false, prof=0}, -- +35 Spell Power and +20 Stamina
  [2792]={phase=1, spells={}, items={25650}, buy=false, prof=0}, -- +8 Stamina
  [2793]={phase=1, spells={}, items={25651}, buy=false, prof=0}, -- +8 Defense Rating
  [2794]={phase=1, spells={}, items={25652}, buy=false, prof=0}, -- +4 Mana restored per 5 seconds
  [2841]={phase=1, spells={}, items={34330}, buy=false, prof=0}, -- +10 Stamina
  [2928]={phase=1, spells={27924}, items={30193}, buy=false, prof=333}, -- +12 Spell Power
  [2929]={phase=1, spells={27920}, items={}, buy=false, prof=333}, -- +2 Weapon Damage
  [2930]={phase=1, spells={27926}, items={}, buy=false, prof=333}, -- +12 Spell Power
  [2931]={phase=1, spells={27927}, items={}, buy=false, prof=333}, -- +4 All Stats
  [2933]={phase=1, spells={33992}, items={38930}, buy=false, prof=0}, -- +15 Resilience Rating
  [2934]={phase=1, spells={33993}, items={38931}, buy=false, prof=0}, -- +10 Critical Strike Rating
  [2935]={phase=1, spells={33994}, items={38932}, buy=false, prof=0}, -- +15 Hit Rating
  [2937]={phase=1, spells={33997}, items={29863,38935}, buy=false, prof=0}, -- +20 Spell Power
  [2938]={phase=1, spells={34003}, items={29861,38939}, buy=false, prof=0}, -- +20 Spell Penetration
  [2939]={phase=1, spells={34007}, items={38943}, buy=false, prof=0}, -- Minor Speed and +6 Agility
  [2940]={phase=1, spells={34008}, items={29852,38944}, buy=false, prof=0}, -- Minor Speed and +9 Stamina
  [2977]={phase=1, spells={}, items={28882}, buy=true, prof=0}, -- +13 Dodge Rating
  [2978]={phase=1, spells={}, items={28889}, buy=true, prof=0}, -- +15 Dodge Rating and +10 Defense Rating
  [2979]={phase=1, spells={}, items={28878}, buy=true, prof=0}, -- +15 Spell Power
  [2980]={phase=1, spells={}, items={28887}, buy=true, prof=0}, -- +18 Spell Power and +5 Mana every 5 seconds
  [2981]={phase=1, spells={}, items={28881}, buy=true, prof=0}, -- +15 Spell Power
  [2982]={phase=1, spells={}, items={28886}, buy=true, prof=0}, -- +18 Spell Power and +10 Critical Strike Rating
  [2983]={phase=1, spells={}, items={28885}, buy=true, prof=0}, -- +26 Attack Power
  [2984]={phase=1, spells={}, items={29483}, buy=false, prof=0}, -- +8 Shadow Resist
  [2985]={phase=1, spells={}, items={29485}, buy=false, prof=0}, -- +8 Fire Resist
  [2986]={phase=1, spells={}, items={28888}, buy=true, prof=0}, -- +30 Attack Power and +10 Critical Strike Rating
  [2987]={phase=1, spells={}, items={29486}, buy=false, prof=0}, -- +8 Frost Resist
  [2988]={phase=1, spells={}, items={29487}, buy=false, prof=0}, -- +8 Nature Resist
  [2989]={phase=1, spells={}, items={29488}, buy=false, prof=0}, -- +8 Arcane Resist
  [2990]={phase=1, spells={}, items={28908}, buy=true, prof=0}, -- +13 Defense Rating
  [2991]={phase=1, spells={}, items={28911,35729}, buy=true, prof=0}, -- +15 Defense Rating and +10 Dodge Rating
  [2992]={phase=1, spells={}, items={28904}, buy=true, prof=0}, -- +6 Mana Regen
  [2993]={phase=1, spells={}, items={28912,35730}, buy=true, prof=0}, -- +12 Spell Power and 8 Mana every 5 seconds
  [2994]={phase=1, spells={}, items={28903}, buy=true, prof=0}, -- +13 Critical Strike Rating
  [2995]={phase=1, spells={}, items={28909,35731}, buy=true, prof=0}, -- +15 Critical Strike Rating and +12 Spell Power
  [2996]={phase=1, spells={}, items={28907}, buy=true, prof=0}, -- +13 Critical Strike Rating
  [2997]={phase=1, spells={}, items={28910,35728}, buy=true, prof=0}, -- +15 Critical Strike Rating and +20 Attack Power
  [2998]={phase=1, spells={}, items={29187}, buy=true, prof=0}, -- +7 All Resistances
  [2999]={phase=1, spells={}, items={29186}, buy=true, prof=0}, -- +16 Defense Rating and +17 Dodge Rating
  [3001]={phase=1, spells={}, items={29189,29190}, buy=true, prof=0}, -- +19 Spell Power and +9 Mana every 5 seconds
  [3002]={phase=1, spells={}, items={29191}, buy=true, prof=0}, -- +22 Spell Power and +14 Hit Rating
  [3003]={phase=1, spells={}, items={29192}, buy=true, prof=0}, -- +34 Attack Power and +16 Hit Rating
  [3004]={phase=1, spells={}, items={29193}, buy=true, prof=0}, -- +18 Stamina and +20 Resilience Rating
  [3005]={phase=1, spells={}, items={29194}, buy=true, prof=0}, -- +20 Nature Resistance
  [3006]={phase=1, spells={}, items={29195}, buy=true, prof=0}, -- +20 Arcane Resistance
  [3007]={phase=1, spells={}, items={29196,29197}, buy=true, prof=0}, -- +20 Fire Resistance
  [3008]={phase=1, spells={}, items={29198}, buy=true, prof=0}, -- +20 Frost Resistance
  [3009]={phase=1, spells={}, items={29199}, buy=true, prof=0}, -- +20 Shadow Resistance
  [3010]={phase=1, spells={}, items={29533}, buy=false, prof=0}, -- +40 Attack Power and +10 Critical Strike Rating
  [3011]={phase=1, spells={}, items={29534}, buy=false, prof=0}, -- +30 Stamina and +10 Agility
  [3012]={phase=1, spells={}, items={29535}, buy=false, prof=0}, -- +50 Attack Power and +12 Critical Strike Rating
  [3013]={phase=1, spells={}, items={29536}, buy=false, prof=0}, -- +40 Stamina and +12 Agility
  [3095]={phase=1, spells={}, items={30845}, buy=false, prof=0}, -- +8 Resist All
  [3096]={phase=1, spells={}, items={30846}, buy=true, prof=0}, -- +17 Strength and +16 Intellect
  [3150]={phase=1, spells={33991}, items={38929}, buy=false, prof=0}, -- +7 mana every 5 sec.
  [3222]={phase=1, spells={42620,44529}, items={38947,38967}, buy=false, prof=0}, -- +20 Agility
  [3223]={phase=1, spells={}, items={33185}, buy=false, prof=0}, -- Adamantite Weapon Chain
  [3225]={phase=1, spells={42974}, items={33315,38948}, buy=false, prof=0}, -- Executioner
  [3229]={phase=1, spells={44383}, items={38949}, buy=false, prof=0}, -- +12 Resilience Rating
  [3230]={phase=1, spells={44483}, items={38950}, buy=false, prof=0}, -- +20 Frost Resistance
  [3231]={phase=1, spells={44484,44598}, items={38951,38984}, buy=false, prof=0}, -- +15 Expertise Rating
  [3232]={phase=1, spells={47901}, items={39006}, buy=false, prof=0}, -- +15 Stamina and Minor Speed Increase
  [3233]={phase=1, spells={27958}, items={38912}, buy=false, prof=0}, -- +250 Mana
  [3234]={phase=1, spells={44488}, items={38953}, buy=false, prof=0}, -- +20 Hit Rating
  [3236]={phase=1, spells={44492}, items={38955}, buy=false, prof=0}, -- +200 Health
  [3238]={phase=1, spells={44506}, items={38960}, buy=false, prof=0}, -- Gatherer
  [3239]={phase=1, spells={44524}, items={38965}, buy=false, prof=0}, -- Icebreaker Weapon
  [3241]={phase=1, spells={44576}, items={38972}, buy=false, prof=0}, -- Lifeward
  [3243]={phase=1, spells={44582}, items={38973}, buy=false, prof=0}, -- +35 Spell Penetration
  [3244]={phase=1, spells={44584}, items={38974}, buy=false, prof=0}, -- +7 Health and Mana every 5 sec
  [3245]={phase=1, spells={44588}, items={38975}, buy=false, prof=0}, -- +20 Resilience Rating
  [3246]={phase=1, spells={44592}, items={38979}, buy=false, prof=0}, -- +28 Spell Power
  [3247]={phase=1, spells={44595}, items={38981}, buy=false, prof=0}, -- +140 Attack Power versus Undead
  [3249]={phase=1, spells={44612}, items={38985}, buy=false, prof=0}, -- +16 Critical Strike Rating
  [3251]={phase=1, spells={44621}, items={38988}, buy=false, prof=0}, -- Giantslaying
  [3252]={phase=1, spells={44623}, items={38989}, buy=false, prof=0}, -- +8 All Stats
  [3253]={phase=1, spells={44625}, items={38990}, buy=false, prof=0}, -- +2% Threat and 10 Parry Rating
  [3256]={phase=1, spells={44631}, items={38993}, buy=false, prof=0}, -- Increased Stealth and +10 Agility
  [3260]={phase=1, spells={}, items={34207}, buy=false, prof=0}, -- +240 Armor
  [3269]={phase=1, spells={}, items={34836}, buy=false, prof=0}, -- +3 Fishing
  [3273]={phase=1, spells={46578}, items={38998}, buy=false, prof=0}, -- Deathfrost
  [3294]={phase=1, spells={47672}, items={39001}, buy=false, prof=0}, -- +225 Armor
  [3296]={phase=1, spells={47899}, items={39004}, buy=false, prof=0}, -- +10 Spirit and 2% Reduced Threat
  [3297]={phase=1, spells={47900}, items={39005}, buy=false, prof=0}, -- +275 Health
  [3315]={phase=1, spells={}, items={37312}, buy=false, prof=0}, -- +3% Mount Speed
  [3325]={phase=1, spells={}, items={38371}, buy=false, prof=0}, -- +45 Stamina and +15 Agility
  [3326]={phase=1, spells={}, items={38372}, buy=false, prof=0}, -- +55 Attack Power and +15 Critical Strike Rating
  [3327]={phase=1, spells={60583}, items={}, buy=false, prof=0}, -- +55 Stamina and +22 Agility
  [3328]={phase=1, spells={60584}, items={}, buy=false, prof=0}, -- +75 Attack Power and +22 Critical Strike Rating
  [3329]={phase=1, spells={}, items={38375}, buy=false, prof=0}, -- +12 Stamina
  [3330]={phase=1, spells={}, items={38376}, buy=false, prof=0}, -- +18 Stamina
  [3331]={phase=1, spells={}, items={38377}, buy=false, prof=0}, -- +72 Stamina and +35 Agility
  [3332]={phase=1, spells={}, items={38378}, buy=false, prof=0}, -- +100 Attack Power and +36 Critical Strike Rating
  [3599]={phase=1, spells={54736}, items={40776}, buy=false, prof=202}, -- Electromagnetic Pulse Generator
  [3601]={phase=1, spells={54793}, items={}, buy=false, prof=202}, -- Frag Belt
  [3603]={phase=1, spells={54998}, items={41091}, buy=false, prof=202}, -- Hand-Mounted Pyro Rocket
  [3604]={phase=1, spells={54999}, items={}, buy=false, prof=202}, -- Hyperspeed Accelerators
  [3605]={phase=1, spells={55002}, items={41111}, buy=false, prof=202}, -- Flexweave Underlay
  [3606]={phase=1, spells={55016}, items={41118}, buy=false, prof=202}, -- +24 Critical Strike Rating
  [3607]={phase=1, spells={}, items={41146}, buy=false, prof=0}, -- +40 Ranged Haste Rating
  [3608]={phase=1, spells={}, items={41167}, buy=false, prof=0}, -- +40 Ranged Critical Strike
  [3717]={phase=1, spells={55628}, items={}, buy=false, prof=164}, -- Socket Bracer
  [3718]={phase=1, spells={}, items={41601}, buy=false, prof=0}, -- +35 Spell Power and +12 Spirit
  [3719]={phase=1, spells={}, items={41602,41605}, buy=false, prof=0}, -- +50 Spell Power and +20 Spirit
  [3720]={phase=1, spells={}, items={41603}, buy=false, prof=0}, -- +35 Spell Power and +20 Stamina
  [3721]={phase=1, spells={}, items={41604,41606}, buy=false, prof=0}, -- +50 Spell Power and +30 Stamina
  [3722]={phase=1, spells={55642}, items={}, buy=false, prof=197}, -- Lightweave Embroidery
  [3723]={phase=1, spells={55641}, items={}, buy=false, prof=164}, -- Socket Gloves
  [3728]={phase=1, spells={55769}, items={}, buy=false, prof=197}, -- Darkglow Embroidery
  [3729]={phase=1, spells={}, items={41611}, buy=false, prof=0}, -- Socket Belt
  [3730]={phase=1, spells={55777}, items={}, buy=false, prof=197}, -- Swordguard Embroidery
  [3731]={phase=1, spells={}, items={41976}, buy=false, prof=0}, -- Titanium Weapon Chain
  [3748]={phase=1, spells={}, items={42500}, buy=false, prof=0}, -- Titanium Spike (45-67)
  [3754]={phase=1, spells={}, items={19785}, buy=false, prof=0}, -- +24 Attack Power +10 Stamina +10 Hit Rating
  [3755]={phase=1, spells={}, items={19784}, buy=false, prof=0}, -- +28 Attack Power +12 Dodge Rating
  [3756]={phase=1, spells={57683}, items={43097}, buy=false, prof=165}, -- +130 Attack Power
  [3757]={phase=1, spells={57690}, items={}, buy=false, prof=165}, -- +102 Stamina
  [3758]={phase=1, spells={57691}, items={}, buy=false, prof=165}, -- +76 Spell Power
  [3759]={phase=1, spells={57692}, items={}, buy=false, prof=165}, -- +70 Fire Resistance
  [3760]={phase=1, spells={57694}, items={}, buy=false, prof=165}, -- +70 Frost Resistance
  [3761]={phase=1, spells={57696}, items={}, buy=false, prof=165}, -- +70 Shadow Resistance
  [3762]={phase=1, spells={57699}, items={}, buy=false, prof=165}, -- +70 Nature Resistance
  [3763]={phase=1, spells={57701}, items={}, buy=false, prof=165}, -- +70 Arcane Resistance
  [3775]={phase=1, spells={}, items={43302}, buy=false, prof=0}, -- +30 Spell Power and +15 Critical Strike Rating
  [3776]={phase=1, spells={}, items={43303}, buy=false, prof=0}, -- +45 Attack Power and +15 Critical Strike Rating
  [3777]={phase=1, spells={}, items={43304}, buy=false, prof=0}, -- +20 Defense and +15 Dodge Rating
  [3788]={phase=1, spells={59619}, items={44497}, buy=false, prof=0}, -- +25 Hit Rating and +25 Critical Strike Rating
  [3789]={phase=1, spells={59621}, items={44493}, buy=false, prof=0}, -- Berserking
  [3790]={phase=1, spells={59625}, items={43987}, buy=false, prof=0}, -- Black Magic
  [3791]={phase=1, spells={59636}, items={}, buy=false, prof=333}, -- +30 Stamina
  [3793]={phase=1, spells={}, items={44067}, buy=true, prof=0}, -- +40 Attack Power and +15 Resilience Rating
  [3794]={phase=1, spells={}, items={44068}, buy=true, prof=0}, -- +23 Spell Power and +15 Resilience Rating
  [3795]={phase=1, spells={}, items={44069}, buy=true, prof=0}, -- +50 Attack Power and +20 Resilience Rating
  [3797]={phase=1, spells={}, items={44075}, buy=true, prof=0}, -- +29 Spell Power and +20 Resilience Rating
  [3806]={phase=1, spells={}, items={44129}, buy=true, prof=0}, -- +18 Spell Power and +10 Critical Strike Rating
  [3807]={phase=1, spells={}, items={44130}, buy=true, prof=0}, -- +18 Spell Power and +5 Mana per 5 sec
  [3808]={phase=1, spells={}, items={44133,44871,50335}, buy=true, prof=0}, -- +40 Attack Power and +15 Crit Rating
  [3809]={phase=1, spells={}, items={44134,44872,50336}, buy=true, prof=0}, -- +24 Spell Power and +8 Mana per 5 sec
  [3810]={phase=1, spells={}, items={44135,44874,50338}, buy=true, prof=0}, -- +24 Spell Power and +15 Critical Strike Rating
  [3811]={phase=1, spells={}, items={44136,44873,50337}, buy=true, prof=0}, -- +20 Dodge Rating and +15 Defense Rating
  [3812]={phase=1, spells={}, items={44137,44884}, buy=true, prof=0}, -- +25 Frost Resistance and +30 Stamina
  [3813]={phase=1, spells={}, items={44138,44883}, buy=true, prof=0}, -- +25 Nature Resistance and +30 Stamina
  [3814]={phase=1, spells={}, items={44139,44882}, buy=true, prof=0}, -- +25 Shadow Resistance and +30 Stamina
  [3815]={phase=1, spells={}, items={44140,44881}, buy=true, prof=0}, -- +25 Arcane Resistance and +30 Stamina
  [3816]={phase=1, spells={}, items={44141,44880}, buy=true, prof=0}, -- +25 Fire Resistance and +30 Stamina
  [3817]={phase=1, spells={}, items={44149,44879,50367}, buy=true, prof=0}, -- +50 Attack Power and +20 Critical Strike Rating
  [3818]={phase=1, spells={}, items={44150,44878,50369}, buy=true, prof=0}, -- +37 Stamina and +20 Defense Rating
  [3819]={phase=1, spells={}, items={44152,44876,50370}, buy=true, prof=0}, -- +30 Spell Power and 10 mana per 5 seconds.
  [3820]={phase=1, spells={}, items={44159,44877,50368}, buy=true, prof=0}, -- +30 Spell Power and 20 Critical strike rating.
  [3822]={phase=1, spells={}, items={38373}, buy=false, prof=0}, -- +55 Stamina and +22 Agility
  [3823]={phase=1, spells={}, items={38374}, buy=false, prof=0}, -- +75 Attack Power and +22 Critical Strike Rating
  [3824]={phase=1, spells={60606}, items={44449}, buy=false, prof=0}, -- +24 Attack Power
  [3825]={phase=1, spells={60609}, items={44456}, buy=false, prof=0}, -- +15 Haste Rating
  [3826]={phase=1, spells={60623}, items={38986}, buy=false, prof=0}, -- +12 Hit Rating and +12 Critical Strike Rating
  [3827]={phase=1, spells={60691}, items={44463}, buy=false, prof=0}, -- +110 Attack Power
  [3828]={phase=1, spells={44630}, items={38992}, buy=false, prof=0}, -- +85 Attack Power
  [3829]={phase=1, spells={44513}, items={38964}, buy=false, prof=0}, -- +35 Attack Power
  [3830]={phase=1, spells={44629}, items={38991}, buy=false, prof=0}, -- +50 Spell Power
  [3831]={phase=1, spells={47898}, items={39003}, buy=false, prof=0}, -- +23 Haste Rating
  [3832]={phase=1, spells={60692}, items={44465}, buy=false, prof=0}, -- +10 All Stats
  [3833]={phase=1, spells={60707}, items={44466}, buy=false, prof=0}, -- +65 Attack Power
  [3834]={phase=1, spells={60714}, items={44467}, buy=false, prof=0}, -- +63 Spell Power
  [3835]={phase=1, spells={61117}, items={}, buy=false, prof=773}, -- +120 Attack Power and +15 Crit Rating
  [3836]={phase=1, spells={61118}, items={}, buy=false, prof=773}, -- +70 Spell Power and +8 Mana/5 seconds
  [3837]={phase=1, spells={61119}, items={}, buy=false, prof=773}, -- +60 Dodge Rating and +15 Defense Rating
  [3838]={phase=1, spells={61120}, items={}, buy=false, prof=773}, -- +70 Spell Power and +15 Crit Rating
  [3839]={phase=1, spells={44645}, items={}, buy=false, prof=333}, -- +40 Attack Power
  [3840]={phase=1, spells={44636}, items={}, buy=false, prof=333}, -- +23 Spell Power
  [3842]={phase=1, spells={}, items={44701,44702,44875,50372,50373}, buy=true, prof=0}, -- +30 Stamina and +25 Resilience Rating
  [3843]={phase=1, spells={}, items={44739}, buy=false, prof=0}, -- Scope (+15 Damage)
  [3844]={phase=1, spells={44510}, items={38963}, buy=false, prof=0}, -- +45 Spirit
  [3845]={phase=1, spells={44575}, items={44815}, buy=false, prof=0}, -- +50 Attack Power
  [3846]={phase=1, spells={34010}, items={38946}, buy=false, prof=0}, -- +40 Spell Power
  [3849]={phase=1, spells={}, items={44936}, buy=false, prof=0}, -- Titanium Plating
  [3850]={phase=1, spells={62256}, items={44947}, buy=false, prof=0}, -- +40 Stamina
  [3851]={phase=1, spells={62257}, items={44946}, buy=false, prof=0}, -- +50 Stamina
  [3852]={phase=1, spells={}, items={44957}, buy=true, prof=0}, -- +30 Stamina and +15 Resilience Rating
  [3853]={phase=1, spells={}, items={44963}, buy=false, prof=0}, -- +40 Resilience Rating and +28 Stamina
  [3854]={phase=2, spells={62948}, items={45056}, buy=false, prof=0}, -- +81 Spell Power
  [3855]={phase=2, spells={62959}, items={45060}, buy=false, prof=0}, -- +69 Spell Power
  [3858]={phase=1, spells={63746}, items={45628}, buy=false, prof=0}, -- +5 Hit Rating
  [3859]={phase=2, spells={63765}, items={}, buy=false, prof=202}, -- +27 Spell Power
  [3860]={phase=2, spells={63770}, items={}, buy=false, prof=202}, -- +885 Armor
  [3869]={phase=2, spells={64441}, items={46026}, buy=false, prof=0}, -- Blade Ward
  [3870]={phase=2, spells={64579}, items={46098}, buy=false, prof=0}, -- Blood Draining
  [3872]={phase=1, spells={56039}, items={}, buy=false, prof=0}, -- +50 Spell Power and +20 Spirit
  [3873]={phase=1, spells={56034}, items={}, buy=false, prof=0}, -- +50 Spell Power and +30 Stamina
  [3875]={phase=1, spells={}, items={44131}, buy=true, prof=0}, -- +30 Attack Power and +10 Critical Strike Rating
  [3876]={phase=1, spells={}, items={44132}, buy=true, prof=0}, -- +15 Dodge Rating and +10 Defense Rating
  [3878]={phase=3, spells={67839}, items={}, buy=false, prof=202}, -- Mind Amplification Dish
}

-- gem item ID -> phase, JC recipe spells that cut it, buyable, profession-only (Dragon's Eyes)
RTH_Gems = {
  [22459]={phase=1, spells={28028}, buy=false, prof=0}, -- Void Sphere
  [22460]={phase=1, spells={28027}, buy=false, prof=0}, -- Prismatic Sphere
  [23094]={phase=1, spells={28903}, buy=false, prof=0}, -- Teardrop Blood Garnet
  [23095]={phase=1, spells={28905}, buy=true, prof=0}, -- Bold Blood Garnet
  [23096]={phase=1, spells={28906}, buy=true, prof=0}, -- Runed Blood Garnet
  [23097]={phase=1, spells={28907}, buy=false, prof=0}, -- Delicate Blood Garnet
  [23098]={phase=1, spells={28910}, buy=true, prof=0}, -- Inscribed Flame Spessarite
  [23099]={phase=1, spells={28912}, buy=true, prof=0}, -- Luminous Flame Spessarite
  [23100]={phase=1, spells={28914}, buy=true, prof=0}, -- Glinting Flame Spessarite
  [23101]={phase=1, spells={28915}, buy=true, prof=0}, -- Potent Flame Spessarite
  [23103]={phase=1, spells={28916}, buy=false, prof=0}, -- Radiant Deep Peridot
  [23104]={phase=1, spells={28917}, buy=true, prof=0}, -- Jagged Deep Peridot
  [23105]={phase=1, spells={28918}, buy=true, prof=0}, -- Enduring Deep Peridot
  [23106]={phase=1, spells={28924}, buy=true, prof=0}, -- Dazzling Deep Peridot
  [23108]={phase=1, spells={28925}, buy=false, prof=0}, -- Glowing Shadow Draenite
  [23109]={phase=1, spells={28927}, buy=true, prof=0}, -- Royal Shadow Draenite
  [23110]={phase=1, spells={28933}, buy=true, prof=0}, -- Shifting Shadow Draenite
  [23111]={phase=1, spells={28936}, buy=true, prof=0}, -- Sovereign Shadow Draenite
  [23113]={phase=1, spells={28938}, buy=false, prof=0}, -- Brilliant Golden Draenite
  [23114]={phase=1, spells={28944}, buy=false, prof=0}, -- Gleaming Golden Draenite
  [23115]={phase=1, spells={28947}, buy=true, prof=0}, -- Thick Golden Draenite
  [23116]={phase=1, spells={28948}, buy=true, prof=0}, -- Rigid Golden Draenite
  [23118]={phase=1, spells={28950}, buy=true, prof=0}, -- Solid Azure Moonstone
  [23119]={phase=1, spells={28953}, buy=true, prof=0}, -- Sparkling Azure Moonstone
  [23120]={phase=1, spells={28955}, buy=true, prof=0}, -- Stormy Azure Moonstone
  [23121]={phase=1, spells={28957}, buy=true, prof=0}, -- Lustrous Azure Moonstone
  [24027]={phase=1, spells={31084}, buy=false, prof=0}, -- Bold Living Ruby
  [24028]={phase=1, spells={31085}, buy=false, prof=0}, -- Delicate Living Ruby
  [24029]={phase=1, spells={31087}, buy=false, prof=0}, -- Teardrop Living Ruby
  [24030]={phase=1, spells={31088}, buy=false, prof=0}, -- Runed Living Ruby
  [24031]={phase=1, spells={31089}, buy=false, prof=0}, -- Bright Living Ruby
  [24032]={phase=1, spells={31090}, buy=false, prof=0}, -- Subtle Living Ruby
  [24033]={phase=1, spells={31092}, buy=false, prof=0}, -- Solid Star of Elune
  [24035]={phase=1, spells={31149}, buy=false, prof=0}, -- Sparkling Star of Elune
  [24036]={phase=1, spells={31091}, buy=false, prof=0}, -- Flashing Living Ruby
  [24037]={phase=1, spells={31094}, buy=false, prof=0}, -- Lustrous Star of Elune
  [24039]={phase=1, spells={31095}, buy=false, prof=0}, -- Stormy Star of Elune
  [24047]={phase=1, spells={31096}, buy=false, prof=0}, -- Brilliant Dawnstone
  [24048]={phase=1, spells={31097}, buy=false, prof=0}, -- Smooth Dawnstone
  [24050]={phase=1, spells={31099}, buy=false, prof=0}, -- Gleaming Dawnstone
  [24051]={phase=1, spells={31098}, buy=false, prof=0}, -- Rigid Dawnstone
  [24052]={phase=1, spells={31100}, buy=false, prof=0}, -- Thick Dawnstone
  [24053]={phase=1, spells={31101}, buy=false, prof=0}, -- Mystic Dawnstone
  [24054]={phase=1, spells={31102}, buy=false, prof=0}, -- Sovereign Nightseye
  [24055]={phase=1, spells={31103}, buy=false, prof=0}, -- Shifting Nightseye
  [24056]={phase=1, spells={31104}, buy=false, prof=0}, -- Glowing Nightseye
  [24057]={phase=1, spells={31105}, buy=false, prof=0}, -- Royal Nightseye
  [24058]={phase=1, spells={31106}, buy=false, prof=0}, -- Inscribed Noble Topaz
  [24059]={phase=1, spells={31107}, buy=false, prof=0}, -- Potent Noble Topaz
  [24060]={phase=1, spells={31108}, buy=false, prof=0}, -- Luminous Noble Topaz
  [24061]={phase=1, spells={31109}, buy=false, prof=0}, -- Glinting Noble Topaz
  [24062]={phase=1, spells={31110}, buy=false, prof=0}, -- Enduring Talasite
  [24065]={phase=1, spells={31112}, buy=false, prof=0}, -- Dazzling Talasite
  [24066]={phase=1, spells={31111}, buy=false, prof=0}, -- Radiant Talasite
  [24067]={phase=1, spells={31113}, buy=false, prof=0}, -- Jagged Talasite
  [25890]={phase=1, spells={32871}, buy=false, prof=0}, -- Destructive Skyfire Diamond
  [25893]={phase=1, spells={32872}, buy=false, prof=0}, -- Mystical Skyfire Diamond
  [25894]={phase=1, spells={32873}, buy=false, prof=0}, -- Swift Skyfire Diamond
  [25895]={phase=1, spells={32874}, buy=false, prof=0}, -- Enigmatic Skyfire Diamond
  [25896]={phase=1, spells={32866}, buy=false, prof=0}, -- Powerful Earthstorm Diamond
  [25897]={phase=1, spells={32867}, buy=false, prof=0}, -- Bracing Earthstorm Diamond
  [25898]={phase=1, spells={32868}, buy=false, prof=0}, -- Tenacious Earthstorm Diamond
  [25899]={phase=1, spells={32869}, buy=false, prof=0}, -- Brutal Earthstorm Diamond
  [25901]={phase=1, spells={32870}, buy=false, prof=0}, -- Insightful Earthstorm Diamond
  [27679]={phase=1, spells={}, buy=true, prof=0}, -- Sublime Mystic Dawnstone
  [27777]={phase=1, spells={}, buy=true, prof=0}, -- Stark Blood Garnet
  [27785]={phase=1, spells={}, buy=true, prof=0}, -- Notched Deep Peridot
  [27786]={phase=1, spells={}, buy=true, prof=0}, -- Barbed Deep Peridot
  [27809]={phase=1, spells={}, buy=true, prof=0}, -- Barbed Deep Peridot
  [27812]={phase=1, spells={}, buy=true, prof=0}, -- Stark Blood Garnet
  [27820]={phase=1, spells={}, buy=true, prof=0}, -- Notched Deep Peridot
  [28118]={phase=1, spells={}, buy=true, prof=0}, -- Runed Ornate Ruby
  [28119]={phase=1, spells={}, buy=true, prof=0}, -- Smooth Ornate Dawnstone
  [28120]={phase=1, spells={}, buy=true, prof=0}, -- Gleaming Ornate Dawnstone
  [28123]={phase=1, spells={}, buy=true, prof=0}, -- Potent Ornate Topaz
  [28290]={phase=1, spells={34069}, buy=false, prof=0}, -- Smooth Golden Draenite
  [28360]={phase=1, spells={}, buy=true, prof=0}, -- Mighty Blood Garnet
  [28361]={phase=1, spells={}, buy=true, prof=0}, -- Mighty Blood Garnet
  [28362]={phase=1, spells={}, buy=true, prof=0}, -- Bold Ornate Ruby
  [28363]={phase=1, spells={}, buy=true, prof=0}, -- Inscribed Ornate Topaz
  [28458]={phase=1, spells={}, buy=true, prof=0}, -- Bold Tourmaline
  [28459]={phase=1, spells={}, buy=true, prof=0}, -- Delicate Tourmaline
  [28460]={phase=1, spells={}, buy=true, prof=0}, -- Teardrop Tourmaline
  [28461]={phase=1, spells={}, buy=true, prof=0}, -- Runed Tourmaline
  [28462]={phase=1, spells={}, buy=true, prof=0}, -- Bright Tourmaline
  [28463]={phase=1, spells={}, buy=true, prof=0}, -- Solid Zircon
  [28464]={phase=1, spells={}, buy=true, prof=0}, -- Sparkling Zircon
  [28465]={phase=1, spells={}, buy=true, prof=0}, -- Lustrous Zircon
  [28466]={phase=1, spells={}, buy=true, prof=0}, -- Brilliant Amber
  [28467]={phase=1, spells={}, buy=true, prof=0}, -- Smooth Amber
  [28468]={phase=1, spells={}, buy=true, prof=0}, -- Rigid Amber
  [28469]={phase=1, spells={}, buy=true, prof=0}, -- Gleaming Amber
  [28470]={phase=1, spells={}, buy=true, prof=0}, -- Thick Amber
  [28556]={phase=1, spells={}, buy=true, prof=0}, -- Swift Windfire Diamond
  [28557]={phase=1, spells={}, buy=true, prof=0}, -- Swift Starfire Diamond
  [28595]={phase=1, spells={34590}, buy=false, prof=0}, -- Bright Blood Garnet
  [30546]={phase=1, spells={}, buy=false, prof=0}, -- Sovereign Tanzanite
  [30547]={phase=1, spells={}, buy=false, prof=0}, -- Luminous Fire Opal
  [30548]={phase=1, spells={}, buy=false, prof=0}, -- Polished Chrysoprase
  [30549]={phase=1, spells={}, buy=false, prof=0}, -- Shifting Tanzanite
  [30550]={phase=1, spells={}, buy=false, prof=0}, -- Sundered Chrysoprase
  [30551]={phase=1, spells={}, buy=false, prof=0}, -- Infused Fire Opal
  [30552]={phase=1, spells={}, buy=false, prof=0}, -- Blessed Tanzanite
  [30553]={phase=1, spells={}, buy=false, prof=0}, -- Pristine Fire Opal
  [30554]={phase=1, spells={}, buy=false, prof=0}, -- Stalwart Fire Opal
  [30555]={phase=1, spells={}, buy=false, prof=0}, -- Glowing Tanzanite
  [30556]={phase=1, spells={}, buy=false, prof=0}, -- Glinting Fire Opal
  [30558]={phase=1, spells={}, buy=false, prof=0}, -- Glimmering Fire Opal
  [30559]={phase=1, spells={}, buy=false, prof=0}, -- Etched Fire Opal
  [30560]={phase=1, spells={}, buy=false, prof=0}, -- Rune Covered Chrysoprase
  [30563]={phase=1, spells={}, buy=false, prof=0}, -- Regal Tanzanite
  [30564]={phase=1, spells={}, buy=false, prof=0}, -- Shining Fire Opal
  [30565]={phase=1, spells={}, buy=false, prof=0}, -- Assassin's Fire Opal
  [30566]={phase=1, spells={}, buy=false, prof=0}, -- Defender's Tanzanite
  [30571]={phase=1, spells={}, buy=true, prof=0}, -- Don Rodrigo's Heart
  [30572]={phase=1, spells={}, buy=false, prof=0}, -- Imperial Tanzanite
  [30573]={phase=1, spells={}, buy=false, prof=0}, -- Mysterious Fire Opal
  [30574]={phase=1, spells={}, buy=false, prof=0}, -- Brutal Tanzanite
  [30575]={phase=1, spells={}, buy=false, prof=0}, -- Nimble Fire Opal
  [30581]={phase=1, spells={}, buy=false, prof=0}, -- Durable Fire Opal
  [30582]={phase=1, spells={}, buy=false, prof=0}, -- Deadly Fire Opal
  [30583]={phase=1, spells={}, buy=false, prof=0}, -- Timeless Chrysoprase
  [30584]={phase=1, spells={}, buy=false, prof=0}, -- Enscribed Fire Opal
  [30585]={phase=1, spells={}, buy=false, prof=0}, -- Glistening Fire Opal
  [30586]={phase=1, spells={}, buy=false, prof=0}, -- Seer's Chrysoprase
  [30587]={phase=1, spells={}, buy=false, prof=0}, -- Champion's Fire Opal
  [30588]={phase=1, spells={}, buy=false, prof=0}, -- Potent Fire Opal
  [30589]={phase=1, spells={}, buy=false, prof=0}, -- Dazzling Chrysoprase
  [30590]={phase=1, spells={}, buy=false, prof=0}, -- Enduring Chrysoprase
  [30591]={phase=1, spells={}, buy=false, prof=0}, -- Empowered Fire Opal
  [30592]={phase=1, spells={}, buy=false, prof=0}, -- Steady Chrysoprase
  [30593]={phase=1, spells={}, buy=false, prof=0}, -- Iridescent Fire Opal
  [30594]={phase=1, spells={}, buy=false, prof=0}, -- Effulgent Chrysoprase
  [30598]={phase=1, spells={}, buy=true, prof=0}, -- Don Amancio's Heart
  [30600]={phase=1, spells={}, buy=false, prof=0}, -- Fluorescent Tanzanite
  [30601]={phase=1, spells={}, buy=false, prof=0}, -- Beaming Fire Opal
  [30602]={phase=1, spells={}, buy=false, prof=0}, -- Jagged Chrysoprase
  [30603]={phase=1, spells={}, buy=false, prof=0}, -- Royal Tanzanite
  [30604]={phase=1, spells={}, buy=false, prof=0}, -- Resplendent Fire Opal
  [30605]={phase=1, spells={}, buy=false, prof=0}, -- Vivid Chrysoprase
  [30606]={phase=1, spells={}, buy=false, prof=0}, -- Lambent Chrysoprase
  [30607]={phase=1, spells={}, buy=false, prof=0}, -- Splendid Fire Opal
  [30608]={phase=1, spells={}, buy=false, prof=0}, -- Radiant Chrysoprase
  [31116]={phase=1, spells={}, buy=false, prof=0}, -- Infused Amethyst
  [31117]={phase=1, spells={}, buy=false, prof=0}, -- Soothing Amethyst
  [31118]={phase=1, spells={}, buy=false, prof=0}, -- Pulsing Amethyst
  [31860]={phase=1, spells={39451}, buy=false, prof=0}, -- Great Golden Draenite
  [31861]={phase=1, spells={39452}, buy=false, prof=0}, -- Great Dawnstone
  [31862]={phase=1, spells={39455}, buy=false, prof=0}, -- Balanced Shadow Draenite
  [31863]={phase=1, spells={39463}, buy=false, prof=0}, -- Balanced Nightseye
  [31864]={phase=1, spells={39458}, buy=false, prof=0}, -- Infused Shadow Draenite
  [31865]={phase=1, spells={39462}, buy=false, prof=0}, -- Infused Nightseye
  [31866]={phase=1, spells={39466}, buy=false, prof=0}, -- Veiled Flame Spessarite
  [31867]={phase=1, spells={39470}, buy=false, prof=0}, -- Veiled Noble Topaz
  [31868]={phase=1, spells={39471}, buy=false, prof=0}, -- Wicked Noble Topaz
  [31869]={phase=1, spells={39467}, buy=false, prof=0}, -- Wicked Flame Spessarite
  [32193]={phase=1, spells={39705}, buy=false, prof=0}, -- Bold Crimson Spinel
  [32194]={phase=1, spells={39706}, buy=false, prof=0}, -- Delicate Crimson Spinel
  [32195]={phase=1, spells={39710}, buy=false, prof=0}, -- Teardrop Crimson Spinel
  [32196]={phase=1, spells={39711}, buy=false, prof=0}, -- Runed Crimson Spinel
  [32197]={phase=1, spells={39712}, buy=false, prof=0}, -- Bright Crimson Spinel
  [32198]={phase=1, spells={39713}, buy=false, prof=0}, -- Subtle Crimson Spinel
  [32199]={phase=1, spells={39714}, buy=false, prof=0}, -- Flashing Crimson Spinel
  [32200]={phase=1, spells={39715}, buy=false, prof=0}, -- Solid Empyrean Sapphire
  [32201]={phase=1, spells={39716}, buy=false, prof=0}, -- Sparkling Empyrean Sapphire
  [32202]={phase=1, spells={39717}, buy=false, prof=0}, -- Lustrous Empyrean Sapphire
  [32203]={phase=1, spells={39718}, buy=false, prof=0}, -- Stormy Empyrean Sapphire
  [32204]={phase=1, spells={39719}, buy=false, prof=0}, -- Brilliant Lionseye
  [32205]={phase=1, spells={39720}, buy=false, prof=0}, -- Smooth Lionseye
  [32206]={phase=1, spells={39721}, buy=false, prof=0}, -- Rigid Lionseye
  [32207]={phase=1, spells={39722}, buy=false, prof=0}, -- Gleaming Lionseye
  [32208]={phase=1, spells={39723}, buy=false, prof=0}, -- Thick Lionseye
  [32209]={phase=1, spells={39724}, buy=false, prof=0}, -- Mystic Lionseye
  [32210]={phase=1, spells={39725}, buy=false, prof=0}, -- Great Lionseye
  [32211]={phase=1, spells={39727}, buy=false, prof=0}, -- Sovereign Shadowsong Amethyst
  [32212]={phase=1, spells={39728}, buy=false, prof=0}, -- Shifting Shadowsong Amethyst
  [32213]={phase=1, spells={39729}, buy=false, prof=0}, -- Balanced Shadowsong Amethyst
  [32214]={phase=1, spells={39730}, buy=false, prof=0}, -- Infused Shadowsong Amethyst
  [32215]={phase=1, spells={39731}, buy=false, prof=0}, -- Glowing Shadowsong Amethyst
  [32216]={phase=1, spells={39732}, buy=false, prof=0}, -- Royal Shadowsong Amethyst
  [32217]={phase=1, spells={39733}, buy=false, prof=0}, -- Inscribed Pyrestone
  [32218]={phase=1, spells={39734}, buy=false, prof=0}, -- Potent Pyrestone
  [32219]={phase=1, spells={39735}, buy=false, prof=0}, -- Luminous Pyrestone
  [32220]={phase=1, spells={39736}, buy=false, prof=0}, -- Glinting Pyrestone
  [32221]={phase=1, spells={39737}, buy=false, prof=0}, -- Veiled Pyrestone
  [32222]={phase=1, spells={39738}, buy=false, prof=0}, -- Wicked Pyrestone
  [32223]={phase=1, spells={39739}, buy=false, prof=0}, -- Enduring Seaspray Emerald
  [32224]={phase=1, spells={39740}, buy=false, prof=0}, -- Radiant Seaspray Emerald
  [32225]={phase=1, spells={39741}, buy=false, prof=0}, -- Dazzling Seaspray Emerald
  [32226]={phase=1, spells={39742}, buy=false, prof=0}, -- Jagged Seaspray Emerald
  [32409]={phase=1, spells={39961}, buy=false, prof=0}, -- Relentless Earthstorm Diamond
  [32410]={phase=1, spells={39963}, buy=false, prof=0}, -- Thundering Skyfire Diamond
  [32634]={phase=1, spells={}, buy=true, prof=0}, -- Unstable Amethyst
  [32635]={phase=1, spells={}, buy=true, prof=0}, -- Unstable Peridot
  [32636]={phase=1, spells={}, buy=true, prof=0}, -- Unstable Sapphire
  [32637]={phase=1, spells={}, buy=true, prof=0}, -- Unstable Citrine
  [32638]={phase=1, spells={}, buy=true, prof=0}, -- Unstable Topaz
  [32639]={phase=1, spells={}, buy=true, prof=0}, -- Unstable Talasite
  [32640]={phase=1, spells={}, buy=true, prof=0}, -- Potent Unstable Diamond
  [32641]={phase=1, spells={}, buy=true, prof=0}, -- Imbued Unstable Diamond
  [32735]={phase=1, spells={}, buy=false, prof=0}, -- Radiant Spencerite
  [32833]={phase=1, spells={41420}, buy=false, prof=0}, -- Purified Jaggal Pearl
  [32836]={phase=1, spells={41429}, buy=false, prof=0}, -- Purified Shadow Pearl
  [33060]={phase=1, spells={}, buy=false, prof=0}, -- Soulbound Test Gem
  [33131]={phase=1, spells={42589}, buy=false, prof=0}, -- Crimson Sun
  [33132]={phase=1, spells={}, buy=false, prof=0}, -- Delicate Fire Ruby
  [33133]={phase=1, spells={42558}, buy=false, prof=0}, -- Don Julio's Heart
  [33134]={phase=1, spells={42588}, buy=false, prof=0}, -- Kailee's Rose
  [33135]={phase=1, spells={42590}, buy=false, prof=0}, -- Falling Star
  [33137]={phase=1, spells={}, buy=false, prof=0}, -- Sparkling Falling Star
  [33138]={phase=1, spells={}, buy=false, prof=0}, -- Mystic Bladestone
  [33139]={phase=1, spells={}, buy=false, prof=0}, -- Brilliant Bladestone
  [33140]={phase=1, spells={42592}, buy=false, prof=0}, -- Blood of Amber
  [33141]={phase=1, spells={}, buy=false, prof=0}, -- Great Bladestone
  [33142]={phase=1, spells={}, buy=false, prof=0}, -- Rigid Bladestone
  [33143]={phase=1, spells={42591}, buy=false, prof=0}, -- Stone of Blades
  [33144]={phase=1, spells={42593}, buy=false, prof=0}, -- Facet of Eternity
  [33782]={phase=1, spells={43493}, buy=false, prof=0}, -- Steady Talasite
  [34142]={phase=1, spells={}, buy=false, prof=0}, -- Infinite Sphere
  [34143]={phase=1, spells={}, buy=false, prof=0}, -- Chromatic Sphere
  [34220]={phase=1, spells={44794}, buy=false, prof=0}, -- Chaotic Skyfire Diamond
  [34256]={phase=1, spells={}, buy=false, prof=0}, -- Charmed Amani Jewel
  [34627]={phase=1, spells={}, buy=false, prof=0}, -- Heavy Tonk Armor
  [34831]={phase=1, spells={}, buy=false, prof=0}, -- Eye of the Sea
  [34967]={phase=1, spells={}, buy=false, prof=0}, -- Juno's Test Gem
  [35315]={phase=1, spells={46403}, buy=false, prof=0}, -- Quick Dawnstone
  [35316]={phase=1, spells={46404}, buy=false, prof=0}, -- Reckless Noble Topaz
  [35318]={phase=1, spells={46405}, buy=false, prof=0}, -- Forceful Talasite
  [35487]={phase=1, spells={}, buy=false, prof=0}, -- Bright Crimson Spinel
  [35488]={phase=1, spells={}, buy=false, prof=0}, -- Runed Crimson Spinel
  [35489]={phase=1, spells={}, buy=false, prof=0}, -- Teardrop Crimson Spinel
  [35501]={phase=1, spells={46597}, buy=false, prof=0}, -- Eternal Earthstorm Diamond
  [35503]={phase=1, spells={46601}, buy=false, prof=0}, -- Ember Skyfire Diamond
  [35707]={phase=1, spells={46803}, buy=false, prof=0}, -- Regal Nightseye
  [35758]={phase=1, spells={47054}, buy=false, prof=0}, -- Steady Seaspray Emerald
  [35759]={phase=1, spells={47053}, buy=false, prof=0}, -- Forceful Seaspray Emerald
  [35760]={phase=1, spells={47055}, buy=false, prof=0}, -- Reckless Pyrestone
  [35761]={phase=1, spells={47056}, buy=false, prof=0}, -- Quick Lionseye
  [36766]={phase=1, spells={56054}, buy=false, prof=755}, -- Bright Dragon's Eye
  [36767]={phase=1, spells={56086}, buy=false, prof=755}, -- Solid Dragon's Eye
  [37430]={phase=1, spells={}, buy=false, prof=0}, -- Solid Sky Sapphire (Unused)
  [37503]={phase=1, spells={48789}, buy=false, prof=0}, -- Purified Shadowsong Amethyst
  [38292]={phase=1, spells={}, buy=false, prof=0}, -- Test Living Ruby
  [38498]={phase=1, spells={}, buy=false, prof=0}, -- QA Test Blank Purple Gem
  [38538]={phase=1, spells={}, buy=false, prof=0}, -- Riding Crop
  [38545]={phase=1, spells={}, buy=true, prof=0}, -- Bold Ornate Ruby
  [38546]={phase=1, spells={}, buy=true, prof=0}, -- Gleaming Ornate Dawnstone
  [38547]={phase=1, spells={}, buy=true, prof=0}, -- Inscribed Ornate Topaz
  [38548]={phase=1, spells={}, buy=true, prof=0}, -- Potent Ornate Topaz
  [38549]={phase=1, spells={}, buy=true, prof=0}, -- Runed Ornate Ruby
  [38550]={phase=1, spells={}, buy=true, prof=0}, -- Smooth Ornate Dawnstone
  [39900]={phase=1, spells={53831}, buy=false, prof=0}, -- Bold Bloodstone
  [39905]={phase=1, spells={53832}, buy=false, prof=0}, -- Delicate Bloodstone
  [39906]={phase=1, spells={53835}, buy=false, prof=0}, -- Bright Bloodstone
  [39907]={phase=1, spells={53843}, buy=false, prof=0}, -- Subtle Bloodstone
  [39908]={phase=1, spells={53844}, buy=false, prof=0}, -- Flashing Bloodstone
  [39909]={phase=1, spells={53845}, buy=false, prof=0}, -- Fractured Bloodstone
  [39910]={phase=1, spells={54017}, buy=false, prof=0}, -- Precise Bloodstone
  [39911]={phase=1, spells={53834}, buy=false, prof=0}, -- Runed Bloodstone
  [39912]={phase=1, spells={53852}, buy=false, prof=0}, -- Brilliant Sun Crystal
  [39914]={phase=1, spells={53853}, buy=false, prof=0}, -- Smooth Sun Crystal
  [39915]={phase=1, spells={53854}, buy=false, prof=0}, -- Rigid Sun Crystal
  [39916]={phase=1, spells={53855}, buy=false, prof=0}, -- Thick Sun Crystal
  [39917]={phase=1, spells={53857}, buy=false, prof=0}, -- Mystic Sun Crystal
  [39918]={phase=1, spells={53856}, buy=false, prof=0}, -- Quick Sun Crystal
  [39919]={phase=1, spells={53934}, buy=false, prof=0}, -- Solid Chalcedony
  [39920]={phase=1, spells={53940}, buy=false, prof=0}, -- Sparkling Chalcedony
  [39927]={phase=1, spells={53941}, buy=false, prof=0}, -- Lustrous Chalcedony
  [39932]={phase=1, spells={53943}, buy=false, prof=0}, -- Stormy Chalcedony
  [39933]={phase=1, spells={53870}, buy=false, prof=0}, -- Puissant Shadow Crystal
  [39934]={phase=1, spells={53859}, buy=false, prof=0}, -- Sovereign Shadow Crystal
  [39935]={phase=1, spells={53860}, buy=false, prof=0}, -- Shifting Shadow Crystal
  [39936]={phase=1, spells={53862}, buy=false, prof=0}, -- Glowing Shadow Crystal
  [39937]={phase=1, spells={53866}, buy=false, prof=0}, -- Balanced Shadow Crystal
  [39938]={phase=1, spells={53868}, buy=false, prof=0}, -- Regal Shadow Crystal
  [39939]={phase=1, spells={53869}, buy=false, prof=0}, -- Defender's Shadow Crystal
  [39940]={phase=1, spells={53871}, buy=false, prof=0}, -- Guardian's Shadow Crystal
  [39941]={phase=1, spells={53863}, buy=false, prof=0}, -- Purified Shadow Crystal
  [39942]={phase=1, spells={53861}, buy=false, prof=0}, -- Tenuous Shadow Crystal
  [39943]={phase=1, spells={53864}, buy=false, prof=0}, -- Royal Shadow Crystal
  [39944]={phase=1, spells={53867}, buy=false, prof=0}, -- Infused Shadow Crystal
  [39945]={phase=1, spells={53865}, buy=false, prof=0}, -- Mysterious Shadow Crystal
  [39946]={phase=1, spells={53881}, buy=false, prof=0}, -- Luminous Huge Citrine
  [39947]={phase=1, spells={53872}, buy=false, prof=0}, -- Inscribed Huge Citrine
  [39948]={phase=1, spells={53873}, buy=false, prof=0}, -- Etched Huge Citrine
  [39949]={phase=1, spells={53874}, buy=false, prof=0}, -- Champion's Huge Citrine
  [39950]={phase=1, spells={53875}, buy=false, prof=0}, -- Resplendent Huge Citrine
  [39951]={phase=1, spells={53876}, buy=false, prof=0}, -- Fierce Huge Citrine
  [39952]={phase=1, spells={53877}, buy=false, prof=0}, -- Deadly Huge Citrine
  [39953]={phase=1, spells={53878}, buy=false, prof=0}, -- Glinting Huge Citrine
  [39954]={phase=1, spells={53879}, buy=false, prof=0}, -- Lucent Huge Citrine
  [39955]={phase=1, spells={53880}, buy=false, prof=0}, -- Deft Huge Citrine
  [39956]={phase=1, spells={53882}, buy=false, prof=0}, -- Potent Huge Citrine
  [39957]={phase=1, spells={53883}, buy=false, prof=0}, -- Veiled Huge Citrine
  [39958]={phase=1, spells={53884}, buy=false, prof=0}, -- Durable Huge Citrine
  [39959]={phase=1, spells={53885}, buy=false, prof=0}, -- Reckless Huge Citrine
  [39960]={phase=1, spells={53886}, buy=false, prof=0}, -- Wicked Huge Citrine
  [39961]={phase=1, spells={53887}, buy=false, prof=0}, -- Pristine Huge Citrine
  [39962]={phase=1, spells={53888}, buy=false, prof=0}, -- Empowered Huge Citrine
  [39963]={phase=1, spells={53889}, buy=false, prof=0}, -- Stark Huge Citrine
  [39964]={phase=1, spells={53890}, buy=false, prof=0}, -- Stalwart Huge Citrine
  [39965]={phase=1, spells={53891}, buy=false, prof=0}, -- Glimmering Huge Citrine
  [39966]={phase=1, spells={53892}, buy=false, prof=0}, -- Accurate Huge Citrine
  [39967]={phase=1, spells={53893}, buy=false, prof=0}, -- Resolute Huge Citrine
  [39968]={phase=1, spells={53894}, buy=false, prof=0}, -- Timeless Dark Jade
  [39974]={phase=1, spells={53916}, buy=false, prof=0}, -- Jagged Dark Jade
  [39975]={phase=1, spells={53917}, buy=false, prof=0}, -- Vivid Dark Jade
  [39976]={phase=1, spells={53918}, buy=false, prof=0}, -- Enduring Dark Jade
  [39977]={phase=1, spells={53919}, buy=false, prof=0}, -- Steady Dark Jade
  [39978]={phase=1, spells={53920}, buy=false, prof=0}, -- Forceful Dark Jade
  [39979]={phase=1, spells={53921}, buy=false, prof=0}, -- Seer's Dark Jade
  [39980]={phase=1, spells={53922}, buy=false, prof=0}, -- Misty Dark Jade
  [39981]={phase=1, spells={53923}, buy=false, prof=0}, -- Shining Dark Jade
  [39982]={phase=1, spells={53924}, buy=false, prof=0}, -- Turbid Dark Jade
  [39983]={phase=1, spells={53925}, buy=false, prof=0}, -- Intricate Dark Jade
  [39984]={phase=1, spells={53926}, buy=false, prof=0}, -- Dazzling Dark Jade
  [39985]={phase=1, spells={53927}, buy=false, prof=0}, -- Sundered Dark Jade
  [39986]={phase=1, spells={53928}, buy=false, prof=0}, -- Lambent Dark Jade
  [39988]={phase=1, spells={53929}, buy=false, prof=0}, -- Opaque Dark Jade
  [39989]={phase=1, spells={53930}, buy=false, prof=0}, -- Energized Dark Jade
  [39990]={phase=1, spells={53931}, buy=false, prof=0}, -- Radiant Dark Jade
  [39991]={phase=1, spells={53932}, buy=false, prof=0}, -- Tense Dark Jade
  [39992]={phase=1, spells={53933}, buy=false, prof=0}, -- Shattered Dark Jade
  [39996]={phase=1, spells={53830}, buy=false, prof=0}, -- Bold Scarlet Ruby
  [39997]={phase=1, spells={53945}, buy=false, prof=0}, -- Delicate Scarlet Ruby
  [39998]={phase=1, spells={53946}, buy=false, prof=0}, -- Runed Scarlet Ruby
  [39999]={phase=1, spells={53947}, buy=false, prof=0}, -- Bright Scarlet Ruby
  [40000]={phase=1, spells={53948}, buy=false, prof=0}, -- Subtle Scarlet Ruby
  [40001]={phase=1, spells={53949}, buy=false, prof=0}, -- Flashing Scarlet Ruby
  [40002]={phase=1, spells={53950}, buy=false, prof=0}, -- Fractured Scarlet Ruby
  [40003]={phase=1, spells={53951}, buy=false, prof=0}, -- Precise Scarlet Ruby
  [40008]={phase=1, spells={53952}, buy=false, prof=0}, -- Solid Sky Sapphire
  [40009]={phase=1, spells={53953}, buy=false, prof=0}, -- Sparkling Sky Sapphire
  [40010]={phase=1, spells={53954}, buy=false, prof=0}, -- Lustrous Sky Sapphire
  [40011]={phase=1, spells={53955}, buy=false, prof=0}, -- Stormy Sky Sapphire
  [40012]={phase=1, spells={53956}, buy=false, prof=0}, -- Brilliant Autumn's Glow
  [40013]={phase=1, spells={53957}, buy=false, prof=0}, -- Smooth Autumn's Glow
  [40014]={phase=1, spells={53958}, buy=false, prof=0}, -- Rigid Autumn's Glow
  [40015]={phase=1, spells={53959}, buy=false, prof=0}, -- Thick Autumn's Glow
  [40016]={phase=1, spells={53960}, buy=false, prof=0}, -- Mystic Autumn's Glow
  [40017]={phase=1, spells={53961}, buy=false, prof=0}, -- Quick Autumn's Glow
  [40022]={phase=1, spells={53962}, buy=false, prof=0}, -- Sovereign Twilight Opal
  [40023]={phase=2, spells={53963}, buy=false, prof=0}, -- Shifting Twilight Opal
  [40024]={phase=1, spells={53964}, buy=false, prof=0}, -- Tenuous Twilight Opal
  [40025]={phase=1, spells={53965}, buy=false, prof=0}, -- Glowing Twilight Opal
  [40026]={phase=1, spells={53966}, buy=false, prof=0}, -- Purified Twilight Opal
  [40027]={phase=1, spells={53967}, buy=false, prof=0}, -- Royal Twilight Opal
  [40028]={phase=1, spells={53968}, buy=false, prof=0}, -- Mysterious Twilight Opal
  [40029]={phase=1, spells={53969}, buy=false, prof=0}, -- Balanced Twilight Opal
  [40030]={phase=1, spells={53970}, buy=false, prof=0}, -- Infused Twilight Opal
  [40031]={phase=1, spells={53971}, buy=false, prof=0}, -- Regal Twilight Opal
  [40032]={phase=1, spells={53972}, buy=false, prof=0}, -- Defender's Twilight Opal
  [40033]={phase=1, spells={53973}, buy=false, prof=0}, -- Puissant Twilight Opal
  [40034]={phase=1, spells={53974}, buy=false, prof=0}, -- Guardian's Twilight Opal
  [40037]={phase=1, spells={53975}, buy=false, prof=0}, -- Inscribed Monarch Topaz
  [40038]={phase=1, spells={53976}, buy=false, prof=0}, -- Etched Monarch Topaz
  [40039]={phase=1, spells={53977}, buy=false, prof=0}, -- Champion's Monarch Topaz
  [40040]={phase=1, spells={53978}, buy=false, prof=0}, -- Resplendent Monarch Topaz
  [40041]={phase=1, spells={54019}, buy=false, prof=0}, -- Fierce Monarch Topaz
  [40043]={phase=1, spells={53979}, buy=false, prof=0}, -- Deadly Monarch Topaz
  [40044]={phase=1, spells={53980}, buy=false, prof=0}, -- Glinting Monarch Topaz
  [40045]={phase=1, spells={53981}, buy=false, prof=0}, -- Lucent Monarch Topaz
  [40046]={phase=1, spells={53982}, buy=false, prof=0}, -- Deft Monarch Topaz
  [40047]={phase=1, spells={53983}, buy=false, prof=0}, -- Luminous Monarch Topaz
  [40048]={phase=1, spells={53984}, buy=false, prof=0}, -- Potent Monarch Topaz
  [40049]={phase=1, spells={53985}, buy=false, prof=0}, -- Veiled Monarch Topaz
  [40050]={phase=1, spells={53986}, buy=false, prof=0}, -- Durable Monarch Topaz
  [40051]={phase=1, spells={53987}, buy=false, prof=0}, -- Reckless Monarch Topaz
  [40052]={phase=1, spells={53988}, buy=false, prof=0}, -- Wicked Monarch Topaz
  [40053]={phase=1, spells={53989}, buy=false, prof=0}, -- Pristine Monarch Topaz
  [40054]={phase=1, spells={53990}, buy=false, prof=0}, -- Empowered Monarch Topaz
  [40055]={phase=1, spells={53991}, buy=false, prof=0}, -- Stark Monarch Topaz
  [40056]={phase=1, spells={53992}, buy=false, prof=0}, -- Stalwart Monarch Topaz
  [40057]={phase=1, spells={53993}, buy=false, prof=0}, -- Glimmering Monarch Topaz
  [40058]={phase=1, spells={53994}, buy=false, prof=0}, -- Accurate Monarch Topaz
  [40059]={phase=1, spells={54023}, buy=false, prof=0}, -- Resolute Monarch Topaz
  [40085]={phase=1, spells={53995}, buy=false, prof=0}, -- Timeless Forest Emerald
  [40086]={phase=1, spells={53996}, buy=false, prof=0}, -- Jagged Forest Emerald
  [40088]={phase=1, spells={53997}, buy=false, prof=0}, -- Vivid Forest Emerald
  [40089]={phase=1, spells={53998}, buy=false, prof=0}, -- Enduring Forest Emerald
  [40090]={phase=1, spells={54000}, buy=false, prof=0}, -- Steady Forest Emerald
  [40091]={phase=1, spells={54001}, buy=false, prof=0}, -- Forceful Forest Emerald
  [40092]={phase=1, spells={54002}, buy=false, prof=0}, -- Seer's Forest Emerald
  [40094]={phase=1, spells={54007}, buy=false, prof=0}, -- Dazzling Forest Emerald
  [40095]={phase=1, spells={54003}, buy=false, prof=0}, -- Misty Forest Emerald
  [40096]={phase=1, spells={54008}, buy=false, prof=0}, -- Sundered Forest Emerald
  [40098]={phase=1, spells={54012}, buy=false, prof=0}, -- Radiant Forest Emerald
  [40099]={phase=1, spells={54004}, buy=false, prof=0}, -- Shining Forest Emerald
  [40100]={phase=1, spells={54009}, buy=false, prof=0}, -- Lambent Forest Emerald
  [40101]={phase=1, spells={54013}, buy=false, prof=0}, -- Tense Forest Emerald
  [40102]={phase=1, spells={54005}, buy=false, prof=0}, -- Turbid Forest Emerald
  [40103]={phase=1, spells={54010}, buy=false, prof=0}, -- Opaque Forest Emerald
  [40104]={phase=1, spells={54006}, buy=false, prof=0}, -- Intricate Forest Emerald
  [40105]={phase=1, spells={54011}, buy=false, prof=0}, -- Energized Forest Emerald
  [40106]={phase=1, spells={54014}, buy=false, prof=0}, -- Shattered Forest Emerald
  [40111]={phase=3, spells={66447}, buy=false, prof=0}, -- Bold Cardinal Ruby
  [40112]={phase=3, spells={66448}, buy=false, prof=0}, -- Delicate Cardinal Ruby
  [40113]={phase=3, spells={66446}, buy=false, prof=0}, -- Runed Cardinal Ruby
  [40114]={phase=3, spells={66449}, buy=false, prof=0}, -- Bright Cardinal Ruby
  [40115]={phase=3, spells={66452}, buy=false, prof=0}, -- Subtle Cardinal Ruby
  [40116]={phase=3, spells={66453}, buy=false, prof=0}, -- Flashing Cardinal Ruby
  [40117]={phase=3, spells={66451}, buy=false, prof=0}, -- Fractured Cardinal Ruby
  [40118]={phase=3, spells={66450}, buy=false, prof=0}, -- Precise Cardinal Ruby
  [40119]={phase=3, spells={66497}, buy=false, prof=0}, -- Solid Majestic Zircon
  [40120]={phase=3, spells={66498}, buy=false, prof=0}, -- Sparkling Majestic Zircon
  [40121]={phase=3, spells={66500}, buy=false, prof=0}, -- Lustrous Majestic Zircon
  [40122]={phase=3, spells={66499}, buy=false, prof=0}, -- Stormy Majestic Zircon
  [40123]={phase=3, spells={66503}, buy=false, prof=0}, -- Brilliant King's Amber
  [40124]={phase=3, spells={66502}, buy=false, prof=0}, -- Smooth King's Amber
  [40125]={phase=3, spells={66501}, buy=false, prof=0}, -- Rigid King's Amber
  [40126]={phase=3, spells={66504}, buy=false, prof=0}, -- Thick King's Amber
  [40127]={phase=3, spells={66505}, buy=false, prof=0}, -- Mystic King's Amber
  [40128]={phase=3, spells={66506}, buy=false, prof=0}, -- Quick King's Amber
  [40129]={phase=3, spells={66554}, buy=false, prof=0}, -- Sovereign Dreadstone
  [40130]={phase=3, spells={66557}, buy=false, prof=0}, -- Shifting Dreadstone
  [40131]={phase=3, spells={66565}, buy=false, prof=0}, -- Tenuous Dreadstone
  [40132]={phase=3, spells={66555}, buy=false, prof=0}, -- Glowing Dreadstone
  [40133]={phase=3, spells={66556}, buy=false, prof=0}, -- Purified Dreadstone
  [40134]={phase=3, spells={66558}, buy=false, prof=0}, -- Royal Dreadstone
  [40135]={phase=3, spells={66562}, buy=false, prof=0}, -- Mysterious Dreadstone
  [40136]={phase=3, spells={66553}, buy=false, prof=0}, -- Balanced Dreadstone
  [40137]={phase=3, spells={66564}, buy=false, prof=0}, -- Infused Dreadstone
  [40138]={phase=3, spells={66559}, buy=false, prof=0}, -- Regal Dreadstone
  [40139]={phase=3, spells={66560}, buy=false, prof=0}, -- Defender's Dreadstone
  [40140]={phase=3, spells={66563}, buy=false, prof=0}, -- Puissant Dreadstone
  [40141]={phase=3, spells={66561}, buy=false, prof=0}, -- Guardian's Dreadstone
  [40142]={phase=3, spells={66567}, buy=false, prof=0}, -- Inscribed Ametrine
  [40143]={phase=3, spells={66572}, buy=false, prof=0}, -- Etched Ametrine
  [40144]={phase=3, spells={66579}, buy=false, prof=0}, -- Champion's Ametrine
  [40145]={phase=3, spells={66582}, buy=false, prof=0}, -- Resplendent Ametrine
  [40146]={phase=3, spells={66583}, buy=false, prof=0}, -- Fierce Ametrine
  [40147]={phase=3, spells={66568}, buy=false, prof=0}, -- Deadly Ametrine
  [40148]={phase=3, spells={66575}, buy=false, prof=0}, -- Glinting Ametrine
  [40149]={phase=3, spells={66585}, buy=false, prof=0}, -- Lucent Ametrine
  [40150]={phase=3, spells={66584}, buy=false, prof=0}, -- Deft Ametrine
  [40151]={phase=3, spells={66566}, buy=false, prof=0}, -- Luminous Ametrine
  [40152]={phase=3, spells={66569}, buy=false, prof=0}, -- Potent Ametrine
  [40153]={phase=3, spells={66570}, buy=false, prof=0}, -- Veiled Ametrine
  [40154]={phase=3, spells={66571}, buy=false, prof=0}, -- Durable Ametrine
  [40155]={phase=3, spells={66574}, buy=false, prof=0}, -- Reckless Ametrine
  [40156]={phase=3, spells={66577}, buy=false, prof=0}, -- Wicked Ametrine
  [40157]={phase=3, spells={66573}, buy=false, prof=0}, -- Pristine Ametrine
  [40158]={phase=3, spells={66580}, buy=false, prof=0}, -- Empowered Ametrine
  [40159]={phase=3, spells={66587}, buy=false, prof=0}, -- Stark Ametrine
  [40160]={phase=3, spells={66581}, buy=false, prof=0}, -- Stalwart Ametrine
  [40161]={phase=3, spells={66578}, buy=false, prof=0}, -- Glimmering Ametrine
  [40162]={phase=3, spells={66576}, buy=false, prof=0}, -- Accurate Ametrine
  [40163]={phase=3, spells={66586}, buy=false, prof=0}, -- Resolute Ametrine
  [40164]={phase=3, spells={66432}, buy=false, prof=0}, -- Timeless Eye of Zul
  [40165]={phase=3, spells={66431}, buy=false, prof=0}, -- Jagged Eye of Zul
  [40166]={phase=3, spells={66429}, buy=false, prof=0}, -- Vivid Eye of Zul
  [40167]={phase=3, spells={66338}, buy=false, prof=0}, -- Enduring Eye of Zul
  [40168]={phase=3, spells={66428}, buy=false, prof=0}, -- Steady Eye of Zul
  [40169]={phase=3, spells={66434}, buy=false, prof=0}, -- Forceful Eye of Zul
  [40170]={phase=3, spells={66433}, buy=false, prof=0}, -- Seer's Eye of Zul
  [40171]={phase=3, spells={66435}, buy=false, prof=0}, -- Misty Eye of Zul
  [40172]={phase=3, spells={66437}, buy=false, prof=0}, -- Shining Eye of Zul
  [40173]={phase=3, spells={66445}, buy=false, prof=0}, -- Turbid Eye of Zul
  [40174]={phase=3, spells={66440}, buy=false, prof=0}, -- Intricate Eye of Zul
  [40175]={phase=3, spells={66430}, buy=false, prof=0}, -- Dazzling Eye of Zul
  [40176]={phase=3, spells={66436}, buy=false, prof=0}, -- Sundered Eye of Zul
  [40177]={phase=3, spells={66439}, buy=false, prof=0}, -- Lambent Eye of Zul
  [40178]={phase=3, spells={66444}, buy=false, prof=0}, -- Opaque Eye of Zul
  [40179]={phase=3, spells={66442}, buy=false, prof=0}, -- Energized Eye of Zul
  [40180]={phase=3, spells={66441}, buy=false, prof=0}, -- Radiant Eye of Zul
  [40181]={phase=3, spells={66438}, buy=false, prof=0}, -- Tense Eye of Zul
  [40182]={phase=3, spells={66443}, buy=false, prof=0}, -- Shattered Eye of Zul
  [40232]={phase=1, spells={}, buy=false, prof=0}, -- Test Dazzling Talasite
  [41285]={phase=1, spells={55389}, buy=false, prof=0}, -- Chaotic Skyflare Diamond
  [41307]={phase=1, spells={55390}, buy=false, prof=0}, -- Destructive Skyflare Diamond
  [41333]={phase=1, spells={55392}, buy=false, prof=0}, -- Ember Skyflare Diamond
  [41335]={phase=1, spells={55393}, buy=false, prof=0}, -- Enigmatic Skyflare Diamond
  [41339]={phase=1, spells={55394}, buy=false, prof=0}, -- Swift Skyflare Diamond
  [41375]={phase=1, spells={55386}, buy=false, prof=0}, -- Tireless Skyflare Diamond
  [41376]={phase=1, spells={55407}, buy=false, prof=0}, -- Revitalizing Skyflare Diamond
  [41377]={phase=1, spells={55384}, buy=false, prof=0}, -- Effulgent Skyflare Diamond
  [41378]={phase=1, spells={55387}, buy=false, prof=0}, -- Forlorn Skyflare Diamond
  [41379]={phase=1, spells={55388}, buy=false, prof=0}, -- Impassive Skyflare Diamond
  [41380]={phase=1, spells={55401}, buy=false, prof=0}, -- Austere Earthsiege Diamond
  [41381]={phase=1, spells={55402}, buy=false, prof=0}, -- Persistent Earthsiege Diamond
  [41382]={phase=1, spells={55403}, buy=false, prof=0}, -- Trenchant Earthsiege Diamond
  [41385]={phase=1, spells={55404}, buy=false, prof=0}, -- Invigorating Earthsiege Diamond
  [41389]={phase=1, spells={55405}, buy=false, prof=0}, -- Beaming Earthsiege Diamond
  [41395]={phase=1, spells={55397}, buy=false, prof=0}, -- Bracing Earthsiege Diamond
  [41396]={phase=1, spells={55398}, buy=false, prof=0}, -- Eternal Earthsiege Diamond
  [41397]={phase=1, spells={55399}, buy=false, prof=0}, -- Powerful Earthsiege Diamond
  [41398]={phase=1, spells={55400}, buy=false, prof=0}, -- Relentless Earthsiege Diamond
  [41400]={phase=1, spells={55395}, buy=false, prof=0}, -- Thundering Skyflare Diamond
  [41401]={phase=1, spells={55396}, buy=false, prof=0}, -- Insightful Earthsiege Diamond
  [41429]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Wicked Huge Citrine
  [41432]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Bold Bloodstone
  [41433]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Bright Bloodstone
  [41434]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Delicate Bloodstone
  [41435]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Flashing Bloodstone
  [41436]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Fractured Bloodstone
  [41437]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Precise Bloodstone
  [41438]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Runed Bloodstone
  [41439]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Subtle Bloodstone
  [41440]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Lustrous Chalcedony
  [41441]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Solid Chalcedony
  [41442]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Sparkling Chalcedony
  [41443]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Stormy Chalcedony
  [41444]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Brilliant Sun Crystal
  [41445]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Mystic Sun Crystal
  [41446]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Quick Sun Crystal
  [41447]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Rigid Sun Crystal
  [41448]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Smooth Sun Crystal
  [41449]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Thick Sun Crystal
  [41450]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Balanced Shadow Crystal
  [41451]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Defender's Shadow Crystal
  [41452]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Glowing Shadow Crystal
  [41453]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Guardian's Shadow Crystal
  [41454]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Infused Shadow Crystal
  [41455]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Mysterious Shadow Crystal
  [41456]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Puissant Shadow Crystal
  [41457]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Purified Shadow Crystal
  [41458]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Regal Shadow Crystal
  [41459]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Royal Shadow Crystal
  [41460]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Shifting Shadow Crystal
  [41461]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Sovereign Shadow Crystal
  [41462]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Tenuous Shadow Crystal
  [41463]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Dazzling Dark Jade
  [41464]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Enduring Dark Jade
  [41465]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Energized Dark Jade
  [41466]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Forceful Dark Jade
  [41467]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Intricate Dark Jade
  [41468]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Jagged Dark Jade
  [41469]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Lambent Dark Jade
  [41470]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Misty Dark Jade
  [41471]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Opaque Dark Jade
  [41472]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Radiant Dark Jade
  [41473]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Seer's Dark Jade
  [41474]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Shattered Dark Jade
  [41475]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Shining Dark Jade
  [41476]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Steady Dark Jade
  [41477]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Sundered Dark Jade
  [41478]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Tense Dark Jade
  [41479]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Timeless Dark Jade
  [41480]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Turbid Dark Jade
  [41481]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Vivid Dark Jade
  [41482]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Accurate Huge Citrine
  [41483]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Champion's Huge Citrine
  [41484]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Deadly Huge Citrine
  [41485]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Deft Huge Citrine
  [41486]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Durable Huge Citrine
  [41487]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Empowered Huge Citrine
  [41488]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Etched Huge Citrine
  [41489]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Fierce Huge Citrine
  [41490]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Glimmering Huge Citrine
  [41491]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Glinting Huge Citrine
  [41492]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Inscribed Huge Citrine
  [41493]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Lucent Huge Citrine
  [41494]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Luminous Huge Citrine
  [41495]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Potent Huge Citrine
  [41496]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Pristine Huge Citrine
  [41497]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Reckless Huge Citrine
  [41498]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Resolute Huge Citrine
  [41499]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Resplendent Huge Citrine
  [41500]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Stalwart Huge Citrine
  [41501]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Stark Huge Citrine
  [41502]={phase=1, spells={}, buy=false, prof=0}, -- Perfect Veiled Huge Citrine
  [42142]={phase=1, spells={56049}, buy=false, prof=755}, -- Bold Dragon's Eye
  [42143]={phase=1, spells={56052}, buy=false, prof=755}, -- Delicate Dragon's Eye
  [42144]={phase=1, spells={56053}, buy=false, prof=755}, -- Runed Dragon's Eye
  [42145]={phase=1, spells={56087}, buy=false, prof=755}, -- Sparkling Dragon's Eye
  [42146]={phase=1, spells={56077}, buy=false, prof=755}, -- Lustrous Dragon's Eye
  [42148]={phase=1, spells={56074}, buy=false, prof=755}, -- Brilliant Dragon's Eye
  [42149]={phase=1, spells={56085}, buy=false, prof=755}, -- Smooth Dragon's Eye
  [42150]={phase=1, spells={56083}, buy=false, prof=755}, -- Quick Dragon's Eye
  [42151]={phase=1, spells={56055}, buy=false, prof=755}, -- Subtle Dragon's Eye
  [42152]={phase=1, spells={56056}, buy=false, prof=755}, -- Flashing Dragon's Eye
  [42153]={phase=1, spells={56076}, buy=false, prof=755}, -- Fractured Dragon's Eye
  [42154]={phase=1, spells={56081}, buy=false, prof=755}, -- Precise Dragon's Eye
  [42155]={phase=1, spells={56088}, buy=false, prof=755}, -- Stormy Dragon's Eye
  [42156]={phase=1, spells={56084}, buy=false, prof=755}, -- Rigid Dragon's Eye
  [42157]={phase=1, spells={56089}, buy=false, prof=755}, -- Thick Dragon's Eye
  [42158]={phase=1, spells={56079}, buy=false, prof=755}, -- Mystic Dragon's Eye
  [42701]={phase=1, spells={56530}, buy=false, prof=0}, -- Enchanted Pearl
  [42702]={phase=1, spells={56531}, buy=false, prof=0}, -- Enchanted Tear
  [44066]={phase=1, spells={}, buy=true, prof=0}, -- Kharmaa's Grace
  [44076]={phase=1, spells={}, buy=true, prof=0}, -- Swift Starflare Diamond
  [44078]={phase=1, spells={}, buy=true, prof=0}, -- Tireless Starflare Diamond
  [44081]={phase=1, spells={}, buy=true, prof=0}, -- Enigmatic Starflare Diamond
  [44082]={phase=1, spells={}, buy=true, prof=0}, -- Impassive Starflare Diamond
  [44084]={phase=1, spells={}, buy=true, prof=0}, -- Forlorn Starflare Diamond
  [44087]={phase=1, spells={}, buy=true, prof=0}, -- Persistent Earthshatter Diamond
  [44088]={phase=1, spells={}, buy=true, prof=0}, -- Powerful Earthshatter Diamond
  [44089]={phase=1, spells={}, buy=true, prof=0}, -- Trenchant Earthshatter Diamond
  [45862]={phase=2, spells={}, buy=false, prof=0}, -- Bold Stormjewel
  [45879]={phase=2, spells={}, buy=false, prof=0}, -- Delicate Stormjewel
  [45880]={phase=2, spells={}, buy=false, prof=0}, -- Solid Stormjewel
  [45881]={phase=2, spells={}, buy=false, prof=0}, -- Sparkling Stormjewel
  [45882]={phase=2, spells={}, buy=false, prof=0}, -- Brilliant Stormjewel
  [45883]={phase=2, spells={}, buy=false, prof=0}, -- Runed Stormjewel
  [45987]={phase=2, spells={}, buy=false, prof=0}, -- Rigid Stormjewel
  [49110]={phase=3, spells={68253}, buy=false, prof=0}, -- Nightmare Tear
}

-- gem enchant ID -> gem item ID(s), in case an item link carries gem enchant IDs instead of item IDs
RTH_GemByEnchant = {
  [2690]={23094},
  [2691]={23095},
  [2692]={23096},
  [2693]={23097},
  [2694]={23113},
  [2695]={23114},
  [2696]={23115},
  [2697]={23116},
  [2698]={23118},
  [2699]={23119},
  [2700]={23120},
  [2701]={23121},
  [2705]={23099},
  [2706]={23105},
  [2707]={23106},
  [2708]={23108},
  [2709]={23109},
  [2710]={23110},
  [2711]={23111},
  [2725]={24027},
  [2726]={24028},
  [2727]={24029},
  [2728]={24030},
  [2729]={24031},
  [2730]={24032},
  [2731]={24033},
  [2732]={24035},
  [2733]={24037},
  [2734]={24047},
  [2735]={24048},
  [2736]={24050},
  [2737]={24052},
  [2738]={24054},
  [2739]={24055},
  [2740]={24056},
  [2741]={24057},
  [2742]={24060},
  [2743]={24062},
  [2744]={24065},
  [2752]={23098},
  [2753]={24058},
  [2754]={24036},
  [2755]={23100},
  [2756]={24061},
  [2757]={23104},
  [2758]={24067},
  [2759]={24053},
  [2760]={23101},
  [2761]={24059},
  [2762]={23103},
  [2763]={24066},
  [2764]={24051},
  [2765]={24039},
  [2827]={25890},
  [2828]={25893},
  [2829]={25894},
  [2830]={25895},
  [2831]={25896},
  [2832]={25897},
  [2833]={25898},
  [2834]={25899},
  [2835]={25901},
  [2891]={27679},
  [2896]={27777},
  [2898]={27785},
  [2899]={27786},
  [2912]={28118},
  [2913]={28119},
  [2914]={28120},
  [2916]={28123},
  [2921]={27809},
  [2923]={27820},
  [2924]={27812},
  [2942]={28290},
  [2943]={28360},
  [2944]={28361},
  [2945]={28362},
  [2946]={28363},
  [2947]={22460},
  [2948]={22459},
  [2956]={28458},
  [2957]={28459},
  [2958]={28460},
  [2959]={28461},
  [2960]={28462},
  [2961]={28463},
  [2962]={28464},
  [2963]={28465},
  [2964]={28466},
  [2965]={28467},
  [2966]={28468},
  [2967]={28469},
  [2968]={28470},
  [2969]={28556},
  [2970]={28557},
  [2971]={28595},
  [3045]={30546},
  [3046]={30547},
  [3047]={30548},
  [3048]={30549},
  [3049]={30550},
  [3050]={30551},
  [3051]={30552},
  [3052]={30553},
  [3053]={30554},
  [3054]={30555},
  [3055]={30556},
  [3056]={30558},
  [3057]={30559},
  [3058]={30560},
  [3060]={30563},
  [3061]={30564},
  [3062]={30565},
  [3063]={30566},
  [3064]={30572},
  [3065]={30571},
  [3066]={30573},
  [3067]={30574},
  [3068]={30575},
  [3069]={30581},
  [3070]={30582},
  [3071]={30583},
  [3072]={30584},
  [3073]={30585},
  [3074]={30586},
  [3075]={30587},
  [3076]={30588},
  [3077]={30589},
  [3078]={30590},
  [3079]={30591},
  [3080]={30592},
  [3081]={30593},
  [3082]={30594},
  [3083]={30600},
  [3084]={30601},
  [3085]={30602},
  [3086]={30603},
  [3087]={30604},
  [3088]={30605},
  [3089]={30606},
  [3090]={30607},
  [3091]={30608},
  [3099]={31116},
  [3100]={31117},
  [3101]={31118},
  [3103]={30598},
  [3104]={31860},
  [3105]={31861},
  [3106]={31862},
  [3107]={31863},
  [3108]={31864},
  [3109]={31865},
  [3110]={31866},
  [3111]={31867},
  [3112]={31868},
  [3113]={31869},
  [3115]={32193},
  [3116]={32194},
  [3117]={32195},
  [3118]={32196},
  [3119]={32197},
  [3120]={32198},
  [3121]={32199},
  [3122]={32200},
  [3123]={32201},
  [3124]={32202},
  [3125]={32203},
  [3126]={32204},
  [3127]={32205},
  [3128]={32206},
  [3129]={32207},
  [3130]={32208},
  [3131]={32209},
  [3132]={32210},
  [3133]={32211},
  [3134]={32212},
  [3135]={32213},
  [3136]={32214},
  [3137]={32215},
  [3138]={32216},
  [3139]={32217},
  [3140]={32218},
  [3141]={32219},
  [3142]={32220},
  [3143]={32221},
  [3144]={32222},
  [3145]={32223},
  [3146]={32224},
  [3147]={32225},
  [3148]={32226},
  [3154]={32409},
  [3155]={32410},
  [3156]={32634},
  [3157]={32635},
  [3158]={32636},
  [3159]={32637},
  [3160]={32638},
  [3161]={32639},
  [3162]={32640},
  [3163]={32641},
  [3197]={32735},
  [3201]={32833},
  [3202]={32836},
  [3206]={33060},
  [3208]={33131},
  [3209]={33132},
  [3210]={33133},
  [3211]={33134},
  [3212]={33135},
  [3214]={33137},
  [3215]={33138},
  [3216]={33139},
  [3217]={33140},
  [3218]={33141},
  [3219]={33142},
  [3220]={33143},
  [3221]={33144},
  [3226]={33782},
  [3242]={34142},
  [3254]={34143},
  [3261]={34220},
  [3262]={34256},
  [3264]={34627},
  [3268]={34831},
  [3270]={35315},
  [3271]={35316},
  [3272]={35318},
  [3274]={35501},
  [3275]={35503},
  [3280]={35707},
  [3281]={35487},
  [3282]={35488},
  [3283]={35489},
  [3284]={35758},
  [3285]={35759},
  [3286]={35760},
  [3287]={35761},
  [3292]={36766},
  [3293]={36767},
  [3317]={37430},
  [3318]={37503},
  [3321]={38292},
  [3333]={38498},
  [3334]={38538},
  [3335]={38545},
  [3336]={38546},
  [3337]={38547},
  [3338]={38548},
  [3339]={38549},
  [3340]={38550},
  [3371]={39900},
  [3374]={39905},
  [3375]={39906},
  [3376]={39907},
  [3377]={39908},
  [3378]={39909},
  [3379]={39910},
  [3380]={39911},
  [3381]={39912},
  [3382]={39914},
  [3383]={39915},
  [3384]={39916},
  [3385]={39917},
  [3386]={39918},
  [3387]={39919},
  [3388]={39920},
  [3389]={39927},
  [3390]={39932},
  [3391]={39933},
  [3392]={39934},
  [3393]={39935},
  [3394]={39936},
  [3395]={39937},
  [3396]={39938},
  [3397]={39939},
  [3398]={39940},
  [3399]={39941},
  [3400]={39942},
  [3401]={39943},
  [3402]={39944},
  [3403]={39945},
  [3404]={39946},
  [3405]={39947},
  [3406]={39953},
  [3407]={39949},
  [3408]={39950},
  [3409]={39951},
  [3410]={39952},
  [3411]={39948},
  [3412]={39954},
  [3413]={39955},
  [3414]={39956},
  [3415]={39957},
  [3416]={39958},
  [3417]={39959},
  [3418]={39964},
  [3419]={39965},
  [3420]={39966},
  [3421]={39967},
  [3422]={39960},
  [3423]={39961},
  [3424]={39962},
  [3426]={39963},
  [3427]={39968},
  [3428]={39974},
  [3429]={39975},
  [3430]={39976},
  [3431]={39977},
  [3432]={39978},
  [3433]={39979},
  [3434]={39980},
  [3435]={39981},
  [3436]={39982},
  [3437]={39983},
  [3438]={39984},
  [3439]={39985},
  [3440]={39986},
  [3441]={39988},
  [3442]={39989},
  [3443]={39990},
  [3444]={39991},
  [3445]={39992},
  [3446]={39996},
  [3447]={39997},
  [3448]={39998},
  [3449]={39999},
  [3450]={40000},
  [3451]={40001},
  [3452]={40002},
  [3453]={40003},
  [3454]={40008},
  [3455]={40009},
  [3456]={40010},
  [3457]={40011},
  [3458]={40012},
  [3459]={40013},
  [3460]={40014},
  [3461]={40015},
  [3462]={40016},
  [3463]={40017},
  [3464]={40022},
  [3465]={40023},
  [3466]={40025},
  [3467]={40029},
  [3468]={40031},
  [3469]={40032},
  [3470]={40033},
  [3471]={40034},
  [3472]={40026},
  [3473]={40027},
  [3474]={40024},
  [3475]={40030},
  [3476]={40028},
  [3477]={40037},
  [3478]={40038},
  [3479]={40039},
  [3480]={40040},
  [3481]={40041},
  [3482]={40043},
  [3483]={40044},
  [3484]={40045},
  [3485]={40046},
  [3486]={40047},
  [3487]={40048},
  [3488]={40049},
  [3489]={40050},
  [3490]={40051},
  [3491]={40052},
  [3492]={40053},
  [3493]={40054},
  [3494]={40055},
  [3495]={40056},
  [3496]={40057},
  [3497]={40058},
  [3498]={40059},
  [3499]={40085},
  [3500]={40086},
  [3501]={40088},
  [3502]={40089},
  [3503]={40090},
  [3504]={40091},
  [3505]={40092},
  [3506]={40095},
  [3507]={40099},
  [3508]={40102},
  [3509]={40104},
  [3510]={40094},
  [3511]={40096},
  [3512]={40100},
  [3513]={40103},
  [3514]={40105},
  [3515]={40098},
  [3516]={40101},
  [3517]={40106},
  [3518]={40111},
  [3519]={40112},
  [3520]={40113},
  [3521]={40114},
  [3522]={40115},
  [3523]={40116},
  [3524]={40118},
  [3525]={40117},
  [3526]={40123},
  [3527]={40124},
  [3528]={40125},
  [3529]={40126},
  [3530]={40127},
  [3531]={40128},
  [3532]={40119},
  [3533]={40120},
  [3534]={40121},
  [3535]={40122},
  [3536]={40129},
  [3537]={40130},
  [3538]={40132},
  [3539]={40136},
  [3540]={40138},
  [3541]={40139},
  [3542]={40141},
  [3543]={40140},
  [3544]={40131},
  [3545]={40133},
  [3546]={40134},
  [3547]={40137},
  [3548]={40135},
  [3549]={40142},
  [3550]={40143},
  [3551]={40144},
  [3552]={40145},
  [3553]={40146},
  [3554]={40147},
  [3555]={40148},
  [3556]={40149},
  [3557]={40150},
  [3558]={40151},
  [3559]={40152},
  [3560]={40153},
  [3561]={40154},
  [3563]={40155},
  [3564]={40156},
  [3565]={40157},
  [3566]={40158},
  [3567]={40159},
  [3568]={40160},
  [3569]={40161},
  [3570]={40162},
  [3571]={40163},
  [3572]={40164},
  [3573]={40165},
  [3574]={40166},
  [3575]={40167},
  [3576]={40168},
  [3577]={40169},
  [3578]={40170},
  [3579]={40171},
  [3580]={40172},
  [3581]={40173},
  [3582]={40174},
  [3583]={40175},
  [3584]={40176},
  [3585]={40177},
  [3586]={40178},
  [3587]={40179},
  [3588]={40180},
  [3589]={40181},
  [3590]={40182},
  [3591]={40232},
  [3621]={41285},
  [3622]={41307},
  [3623]={41333},
  [3624]={41335},
  [3625]={41339},
  [3626]={41395},
  [3627]={41401},
  [3628]={41398},
  [3631]={41396},
  [3632]={41375},
  [3633]={41376},
  [3634]={41377},
  [3635]={41378},
  [3636]={41379},
  [3637]={41380},
  [3638]={41381},
  [3639]={41382},
  [3640]={41385},
  [3641]={41389},
  [3642]={41397},
  [3643]={41400},
  [3644]={41434},
  [3646]={41439},
  [3647]={41437},
  [3648]={41435},
  [3649]={41432},
  [3650]={41438},
  [3651]={41433},
  [3652]={41436},
  [3653]={41442},
  [3654]={41440},
  [3655]={41441},
  [3656]={41443},
  [3657]={41448},
  [3658]={41449},
  [3659]={41446},
  [3660]={41447},
  [3661]={41444},
  [3662]={41445},
  [3663]={41454},
  [3664]={41450},
  [3665]={41456},
  [3666]={41462},
  [3667]={41460},
  [3668]={41458},
  [3669]={41453},
  [3670]={41451},
  [3671]={41461},
  [3672]={41459},
  [3673]={41457},
  [3674]={41455},
  [3675]={41452},
  [3677]={41485},
  [3678]={41501},
  [3679]={41496},
  [3680]={41487},
  [3681]={41492},
  [3682]={41488},
  [3683]={41483},
  [3684]={41499},
  [3685]={41489},
  [3686]={41484},
  [3687]={41491},
  [3688]={41493},
  [3689]={41494},
  [3690]={41495},
  [3691]={41502},
  [3692]={41486},
  [3693]={41497},
  [3694]={41500},
  [3695]={41490},
  [3696]={41482},
  [3697]={41498},
  [3698]={41470},
  [3699]={41468},
  [3700]={41464},
  [3701]={41467},
  [3702]={41466},
  [3703]={41475},
  [3704]={41481},
  [3705]={41473},
  [3706]={41479},
  [3707]={41480},
  [3708]={41476},
  [3709]={41472},
  [3710]={41477},
  [3711]={41463},
  [3712]={41469},
  [3713]={41471},
  [3714]={41465},
  [3715]={41478},
  [3716]={41474},
  [3732]={42142},
  [3733]={42143},
  [3734]={42144},
  [3735]={42145},
  [3736]={42146},
  [3737]={42148},
  [3738]={42149},
  [3739]={42150},
  [3740]={42151},
  [3741]={42152},
  [3742]={42156},
  [3743]={42157},
  [3744]={42158},
  [3745]={42153},
  [3746]={42154},
  [3747]={42155},
  [3749]={42701},
  [3750]={42702},
  [3767]={41429},
  [3792]={44066},
  [3798]={44076},
  [3799]={44078},
  [3800]={44082},
  [3801]={44081},
  [3802]={44084},
  [3803]={44087},
  [3804]={44088},
  [3805]={44089},
  [3861]={45862},
  [3862]={45879},
  [3863]={45880},
  [3864]={45881},
  [3865]={45882},
  [3866]={45883},
  [3867]={45987},
  [3879]={49110},
}
