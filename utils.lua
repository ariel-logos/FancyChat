require('common');
require('win32types')
local ffi = require('ffi');
local d3d       = require('d3d8');
local C         = ffi.C;
local d3d8dev   = d3d.get_device();
local user32 = ffi.load("user32");
local kernel32 = ffi.load("kernel32");
local gfxDevice = d3d.get_device()


ffi.cdef[[
    // Exported from Addons.dll
    HRESULT __stdcall D3DXCreateTextureFromFileA(IDirect3DDevice8* pDevice, const char* pSrcFile, IDirect3DTexture8** ppTexture);
	
	typedef void* HANDLE;
    typedef HANDLE HGLOBAL;
    typedef HANDLE HWND;

    int OpenClipboard(HWND hWndNewOwner);
    int EmptyClipboard();
    HANDLE SetClipboardData(unsigned int uFormat, HANDLE hMem);
    int CloseClipboard();

    HGLOBAL GlobalAlloc(unsigned int uFlags, size_t dwBytes);
    void* GlobalLock(HGLOBAL hMem);
    int GlobalUnlock(HGLOBAL hMem);

    size_t strlen(const char* str);
    void memcpy(void* dest, const void* src, size_t n);

    static const unsigned int CF_TEXT = 1;
    static const unsigned int GMEM_MOVEABLE = 0x0002;
    static const unsigned int GMEM_ZEROINIT = 0x0040;
]];


local utils = 
{

	modesDA = T{
					{0,		'zone',			0xFFFFFFFF},
					{1,		'local',		0xFFFFFFFF},
					{2,		'shout',		0xFFFF5E5E},
					{3,		'shout',		0xFFFF5E5E},
					{4,		'tell_out',		0xFFD35AFF},
					{5,		'party_out',	0xFF7BD3FF},
					{6,		'linkshell1out',0xFF50FFD0},
					{7,		'emote1',		0xFFC797FF},
					{8,		'_?',		0xFFFFFFFF},
					{9,		'local',	0xFFFFFFFF},
					{10,	'shout',		0xFFFF5E5E},
					{11,	'shout',		0xFFFF5E5E},
					{12,	'tell_in',		0xFFD35AFF},
					{13,	'party_in',		0xFF7BD3FF},
					{14,	'linkshell1',	0xFF50FFD0},
					{15,	'emote2',		0xFFC797FF},
					{16,	'cfh',		0xFFFF9763},
					{17,	'_?',		0xFFFFFFFF},
					{18,	'_?',		0xFFFFFFFF},
					{19,	'_?',		0xFFFFFFFF},
					{20,	'combat_y',		0xFFDCF1FC},	--"You" damage "Enemy"
					{21,	'combat_y',		0xFFDCF1FC},	--"You" miss "Enemy"
					{22,	'combat_y',		0xFFDCF1FC},	--"Enemy" uses "ability" "You"
					{23,	'combatspell_y',0xFFDDC9FF},	--"You" cast/heal "Party" recover 
					{24,	'combatspell_p',0xFFDDC9FF},	--"Party"cast/heal "Party/PC?" recover
					{25,	'combat_p',		0xFFDCF1FC},	--"Party" Damage "Enemy"
					{26,	'combat_p',		0xFFDCF1FC},	--"Party" miss "Enemy"
					{27,	'combat_p',		0xFFDCF1FC},	--"Friend"hitby"aoe"
					{28,	'combat_y',		0xFFDCF1FC},	--"Enemy"hits"You"
					{29,	'combat_y',		0xFFDCF1FC},	--"Enemy"miss"You"
					{30,	'combat_y',		0xFFFFFFFF},    --"You" additional effect
					{31,	'combatspell_y',0xFFDDC9FF},	--"You" recover "You"
					{32,	'combat_p',		0xFFDCF1FC},	--"Enemy" damage "Party"
					{33,	'combat_p',		0xFFDCF1FC},	--"Enemy" miss "Party"
					{34,	'combat_y',		0xFFFFFFFF},    --"You additional effect"
					{35,	'combatspell_n',0xFFDDC9FF},	--"Enemy"miss"PC"
					{36,	'combat_y',		0xFFFFFFFF},	-- "You" defeat "Enemy"
					{37,	'combat_p',		0xFFDCF1FC},	--"Party" defeats "Enemy"
					{38,	'combat_y',		0xFFDCF1FC},	--"Enemy" defeats"You"
					{39,	'combat_p',		0xFFDCF1FC},	--"Enemy"defeats"Party"
					--{40,	'combat_x',		0xFFDCF1FC},	--"PC" Damage "Enemy"/"Enemy" Damage "PC"
					--{41,	'combat_x',		0xFFDCF1FC},	--"Enemy" misses "PC"/"PC" misses "Enemy"
					--{42,	'combat_x',		0xFFDCF1FC},	--"PC" additional effect
					{40,	'combat_n',		0xFFDCF1FC},	--"PC" Damage "Enemy"/"Enemy" Damage "PC"
					{41,	'combat_n',		0xFFDCF1FC},	--"Enemy" misses "PC"/"PC" misses "Enemy"
					{42,	'combat_n',		0xFFDCF1FC},	--"PC" additional effect
					{43,	'combatspell_x',	0xFFDDC9FF},	-- "PC/Enemy" recovers
					{44,	'combat_u',		0xFFDCF1FC},	--"Pet" defeats "Enemy" but also "Enemy" falls to the ground
					{45,	'_?',		0xFFFFFFFF},
					{46,	'_?',		0xFFFFFFFF},
					{47,	'_?',		0xFFFFFFFF},
					{48,	'_?',		0xFFFFFFFF},
					{49,	'_?',		0xFFFFFFFF},
					{50,	'combatspell_y',	0xFFDDC9FF},	--"You" start casting
					{51,	'combatspell_p',	0xFFDDC9FF},	--"Party" start casting
					{52,	'combatspell_x',	0xFFDDC9FF},	--"Party/Enemy/PC" starts Casting 
					{53,	'_?',		0xFFFFFFFF},
					{54,	'_?',		0xFFFFFFFF},
					{55,	'_?',		0xFFFFFFFF},
					{56,	'combatspell_y',	0xFFDDC9FF},	--"You" cast buff
					{57,	'combatspell_y',	0xFFDDC9FF},    --"Enemy" Cast spell status effect on you
					{58,	'combatspell_?',	0xFFDDC9FF},
					{59,	'combatspell_y',	0xFFDDC9FF},	--"You" resist/noeffect spell
					{60,	'combatspell_p',		0xFFFFFFFF},--"Enemy" Cast spell status effect on "Party"
					{61,	'combatspell_p',	0xFFDDC9FF},	--"Enemy" Cast spell/ability? status effect on "Party"
					{62,	'_?',		0xFFFFFFFF},
					{63,	'combatspell_p',	0xFFDCF1FC},	--"Party"resist/noeffect spell
					{64,	'combatspell_u',	0xFFDDC9FF},	--"You/Party" Cast buff/gain buff effect
					{65,	'combatspell_u',	0xFFDDC9FF},	--"You/Party" cast spell status effect on "Enemy"
					{66,	'_?',		0xFFFFFFFF},
					{67,	'combatspell_x',	0xFFDDC9FF},	--"You/Party" cast status effect "No effect" on "Enemy"
					{68,	'combatspell_x',	0xFFDDC9FF},	--"Party" on "Party" no effect.
					{69,	'combatspell_n_e',	0xFFDDC9FF},	--"PC"/"Enemy" resist/no effect
					{70,	'_?',		0xFFFFFFFF},
					{71,	'_?',		0xFFFFFFFF},
					{72,	'_?',		0xFFFFFFFF},
					{73,	'_?',		0xFFFFFFFF},
					{74,	'_?',		0xFFFFFFFF},
					{75,	'_?',		0xFFFFFFFF},
					{76,	'_?',		0xFFFFFFFF},
					{77,	'_?',		0xFFFFFFFF},
					{78,	'_?',		0xFFFFFFFF},
					{79,	'_?',		0xFFFFFFFF},
					{80,	'combat_y',	0xFFDCF1FC},  --"You/Party?" uses item on "Enemy"
					{81,	'system14',	0xFFFFF3DA}, --stuff like learn a new spell
					{82,	'_?',		0xFFFFFFFF},
					{83,	'_?',		0xFFFFFFFF},
					{84,	'_?',		0xFFFFFFFF},
					{85,	'item',		0xFFFAFFDB},
					{86,	'_?',		0xFFFFFFFF},
					{87,	'_?',		0xFFFFFFFF},
					{88,	'_?',		0xFFFFFFFF},
					{89,	'_?',		0xFFFFFFFF},
					{90,	'item',			0xFFFAFFDB},	-- "PC" uses item
					{91,	'_?',		0xFFFFFFFF},
					{92,	'_?',		0xFFFFFFFF},
					{93,	'_?',		0xFFFFFFFF},
					{94,	'_?',		0xFFFFFFFF},
					{95,	'_?',		0xFFFFFFFF},
					{96,	'_?',		0xFFFFFFFF},
					{97,	'_?',		0xFFFFFFFF},
					{98,	'_?',		0xFFFFFFFF},
					{99,	'_?',		0xFFFFFFFF},
					{100,	'combat_e',		0xFFDCF1FC},	--"Enemy"readies"ability"
					{101,	'combat_y',		0xFFDCF1FC},	--"You"uses"ability"
					{102,	'combatspell_y',	0xFFDDC9FF}, --"You" status effect (e.g you is bound)
					{103,	'_?',		0xFFFFFFFF},
					{104,	'combat_y',		0xFFDCF1FC},	-- "Enemy" misses " ability" "You" evade
					{105,	'combat_e',		0xFFDCF1FC},	-- "Enemy" readies" ability"
					{106,	'combat_p',		0xFFDCF1FC},	-- "Party" uses "ability"
					{107,	'combatspell_p',	0xFFDDC9FF},	-- "Enemy" uses "ability"-"Party gets status effect"
					{108,	'_?',		0xFFFFFFFF},
					{109,	'combat_p',		0xFFDCF1FC},	-- "Party" evades
					{110,	'combat_x',		0xFFDCF1FC},	--"PC"/"Enemy"/"Pet" readies "Ability"
					{111,	'combat_x',		0xFFDCF1FC},	--"PC/Enemy" uses "Ability"
					{112,	'combat_x',		0xFFDCF1FC},	-- "Pet" uses "ability"/"PC" status effect (eg is weakened""
					{113,	'_?',		0xFFFFFFFF},
					{114,	'combat_x',		0xFFDCF1FC},	--"Enemy/You/Party" miss "ability" 
					{115,	'_?',		0xFFFFFFFF},
					{116,	'_?',		0xFFFFFFFF},
					{117,	'_?',		0xFFFFFFFF},
					{118,	'_?',		0xFFFFFFFF},
					{119,	'_?',		0xFFFFFFFF},
					{120,	'_?',		0xFFFFFFFF},
					{121,	'craft',		0xFFFAFFDB},	-- Lot here too (same as craft)
					{122,	'combat_x',		0xFFDCF1FC},	--"You,PC"/"Enemy"Can't attack/cast" (eg Too Far Away/Enemy paralyzed/intimidated, ability CD) 
					{123,	'error',		0xFFFF0090},
					{124,	'_?',		0xFFFFFFFF},
					{125,	'_?',		0xFFFFFFFF},
					{126,	'_?',		0xFFFFFFFF},
					{127,	'system8',		0xFFFFF3DA},
					{128,	'system',		0xFFFFFFFF}, -- an addon used this
					{129,	'combat_y',		0xFFDCF1FC}, -- skill up
					{130,	'_?',		0xFFFFFFFF},
					{131,	'combat_y',		0xFFDCF1FC},	--"You" gain exp/limit, exp/limit chain, obtain gil
					{132,	'system8',		0xFFFFF3DA}, 	-- assigned merit points
					{133,	'system',		0xFFFFF3DA},		--level down
					{134,	'_?',		0xFFFFFFFF},
					{135,	'system8',		0xFFFFF3DA},
					{136,	'system6',		0xFFFFED8E},
					{137,	'_?',		0xFFFFFFFF},
					{138,	'trade',		0xFFFFF3DA},
					{139,	'system8',		0xFFFFF3DA},
					{140,	'clock',		0xFFFFF3DA},
					{141,	'mog',			0xFFFFFFFF},
					{142,	'system7NPC',	0xFFFFFFFF},
					{143,	'_?',		0xFFFFFFFF},	
					{144,	'system7NPC',	0xFFFFFFFF},	
					{145,	'_?',		0xFFFFFFFF},	
					{146,	'system8',		0xFFFFF3DA},	
					{147,	'_?',		0xFFFFFFFF},	
					{148,	'fishing',		0xFFFFFFFF},	
					{149,	'_?',		0xFFFFFFFF},	
					{150,	'NPC',			0xFFFFFFFF},
					{151,	'NPC',			0xFFFFFFFF},
					{152,	'NPC',			0xFFFFFFFF},
					{153,	'_?',		0xFFFFFFFF},
					{154,	'_?',		0xFFFFFFFF},
					{155,	'_?',		0xFFFFFFFF},
					{156,	'_?',		0xFFFFFFFF},
					{157,	'error',		0xFFFF44BB},
					{158,	'_?',		0xFFFFFFFF},
					{159,	'_?',		0xFFFFFFFF},
					{160,	'_?',		0xFFFFFFFF},
					{161,	'tlly',			0xFFFFF3DA},
					{162,	'combatspell_a',0xFFDDC9FF},
					{163,	'combat_a',		0xFFDCF1FC},
					{164,	'combat_a',		0xFFDCF1FC},
					{165,	'combat_a',		0xFFDCF1FC}, --"Alliance" additional effect
					{166,	'combat_a',		0xFFDCF1FC}, --"Alliance" defeats "Enemy"
					{167,	'combat_a',		0xFFDCF1FC}, --"Enemy" defeats "Alliance"
					{168,	'combatspell_a',0xFFDDC9FF},
					{169,	'_a_?',			0xFFDCF1FC},
					{170,	'combatspell_a',			0xFFDCF1FC}, --"Alliance" status no effect
					{171,	'combatspell_a',0xFFFAFFDB},
					{172,	'_a_?',			0xFFFFFFFF},
					{173,	'_a_?',			0xFFFFFFFF},
					{174,	'combat_a',		0xFFDCF1FC},
					{175,	'combat_a',		0xFFDCF1FC},
					{176,	'_?',		0xFFFFFFFF},
					{177,	'combat_a',		0xFFDCF1FC},
					{178,	'_a_?',			0xFFDCF1FC},
					{179,	'_a_?',			0xFFDCF1FC},
					{180,	'_a_?',			0xFFDCF1FC},
					{181,	'combat_a'	,	0xFFDCF1FC},
					{182,	'combatspell_a',			0xFFFFFFFF}, --"Alliance" cast status on "Enemy"
					{183,	'combat_a',			0xFFFFFFFF}, --"Alliance" gain buff
					{184,	'_a_?',			0xFFFFFFFF},
					{185,	'combat_a',		0xFFDCF1FC},
					{186,	'combat_a',		0xFFDCF1FC},
					{187,	'combat_a',		0xFFDCF1FC},
					{188,	'combatspell_a',0xFFDCF1FC}, -- "Alliance" cast cure on "Friend" recvery
					{189,	'_a_?',			0xFFDCF1FC},
					{190,	'system8',		0xFF000000},--0xFFFFF3DA}, 
					{191,	'combat_x',		0xFFDCF1FC},	--"All" effect wears off
					{192,	'_?',		0xFFFFFFFF},
					{193,	'_?',		0xFFFFFFFF},
					{194,	'_?',		0xFFFFFFFF},
					{195,	'_?',		0xFFFFFFFF},
					{196,	'_?',		0xFFFFFFFF},
					{197,	'_?',		0xFFFFFFFF},
					{198,	'_?',		0xFFFFFFFF},
					{199,	'_?',		0xFFFFFFFF},
					{200,	'servermsg',	0xFF8E6AFF},
					{201,	'_?',		0xFFFFFFFF},
					{202,	'equipset',		0xFFFFF3DA},
					{203,	'_?',		0xFFFFFFFF},
					{204,	'_?',		0xFFFFFFFF},
					{205,	'linkshell1',	0xFF50FFD0},
					{206,	'echo',			0xFFFFFFFF},
					{207,	'_?',		0xFFFFFFFF},
					{208,	'examined',		0xFFC797FF},
					{209,	'system8',		0xFFFFF3DA},	--Ability CD timer ends here
					{210,	'party_NPC',	0xFF7BD3FF},
					{211,	'unity',		0xFFFFFFFF},
					{212,	'unity',		0xFFFFD270},
					{213,	'linkshell2out',0xFF00FF80},
					{214,	'linkshell2',	0xFF00FF80},
					{215,	'_?',		0xFFFFFFFF},
					{216,	'_?',		0xFFFFFFFF},
					{217,	'linkshell2',	0xFF00FF80},
					{218,	'_?',		0xFFFFFFFF},
					{219,	'_?',		0xFFFFFFFF},
					{220,	'assist',	0xFFFFFFFF},
					{221,	'_?',		0xFFFFFFFF},
					{222,	'assist',	0xFFFFFFFF},
					{223,	'_?',		0xFFFFFFFF},
					{224,	'_?',		0xFFFFFFFF},
					{225,	'_?',		0xFFFFFFFF},
					{226,	'_?',		0xFFFFFFFF},
					{227,	'_?',		0xFFFFFFFF},
					{228,	'_?',		0xFFFFFFFF},
					{229,	'_?',		0xFFFFFFFF},
					{230,	'_?',		0xFFFFFFFF},
					{231,	'_?',		0xFFFFFFFF},
					{232,	'_?',		0xFFFFFFFF},
					{233,	'_?',		0xFFFFFFFF},
					{234,	'_?',		0xFFFFFFFF},
					{235,	'_?',		0xFFFFFFFF},
					{236,	'_?',		0xFFFFFFFF},
					{237,	'_?',		0xFFFFFFFF},
					{238,	'_?',		0xFFFFFFFF},
					{239,	'_?',		0xFFFFFFFF},
					{240,	'_?',		0xFFFFFFFF},
					{241,	'_?',		0xFFFFFFFF},
					{242,	'_?',		0xFFFFFFFF},
					{243,	'_?',		0xFFFFFFFF},
					{244,	'_?',		0xFFFFFFFF},
					{245,	'_?',		0xFFFFFFFF},
					{246,	'_?',		0xFFFFFFFF},
					{247,	'_?',		0xFFFFFFFF},
					{248,	'_?',		0xFFFFFFFF},
					{249,	'_?',		0xFFFFFFFF},
					{250,	'_?',		0xFFFFFFFF},
					{251,	'_?',		0xFFFFFFFF},
					{252,	'_?',		0xFFFFFFFF},
					{253,	'_?',		0xFFFFFFFF},
					{254,	'_?',		0xFFFFFFFF},
					{255,	'_?',		0xFFFFFFFF},

	},
	disambEnemy = T{	'on the', 
				'but misses the',
			  },
	disambYou = T{	'^Unable to',
					'^You ',
					'^Cannot ex',
					'^Your mo',
			  },
	keycodes = T{
					{'A', 30},
					{'B', 48},
					{'C', 46},
					{'D', 32},
					{'E', 18},
					{'F', 33},
					{'G', 34},
					{'H', 35},
					{'I', 23},
					{'J', 36},
					{'K', 37},
					{'L', 38},
					{'M', 50},
					{'N', 49},
					{'O', 24},
					{'P', 35},
					{'Q', 16},
					{'R', 19},
					{'S', 31},
					{'T', 20},
					{'U', 22},
					{'V', 47},
					{'W', 17},
					{'X', 45},
					{'Y', 21},
					{'Z', 44},
					{'Tab', 15},
					{'.', 52},
					{',', 51},
					{'~ (or (`) or (\\) on non-US keyboards)', 41}
					
	},
	keycodesSpecial = T{
					{'Shift', 	42},
					{'Alt', 	56},
					{'Ctrl',	29},
					
	},
	
	fwdchars = {
		string.char(0x7F,0x30),
		string.char(0x7F,0x31),
		string.char(0x7F,0x32),
		string.char(0x7F,0x33),
		string.char(0x7F,0x34),
		string.char(0x7F,0x35),
		string.char(0x7F,0x36),
		string.char(0x7F,0x37),
	},

	badStrings = { p127 = {
								{{127, 1049,1055, 1},	{  }},
								{{127, 1049,1055, 2},	{  }},
								{{127, 1049,1055, 3},	{  }},
								{{127, 1049,1055, 4},	{  }},
								{{127, 1049,1055, 5},	{  }},
								{{127, 1049,1055, 6},	{  }},
								{{127,49},				{  }},
						  },
					p129136 = {
								{{129, 158},			{-4}}, --CE custom content ◇
								{{129, 159},			{-5}}, --CE custom content ◆
								{{129, 154},			{-6}},  --CE custom content ★
								{{129, 153},			{-7}},  -- empty star 0x2606
								{{129, 244},			{-8}},  -- ♪
								{{129, 64},				{32}},  -- 
								{{129, 96},				{-9}},  -- ~
								{{135, 178},			{-10}}, --  \"
								{{135, 179},			{-11}}, -- \"
								{{136, 105},			{-12}},  -- 'é'
								{{133, 112},			{-13}}, -- ° 
								{{129, 172},			{-14}}, -- ò
								{{129, 168},			{-15}}, -- ->
								{{131, 182},			{-16}}, -- ò
								{{129, 166},			{-17}}, -- weird X
								{{129, 169},            {-18}},
								{{129, 170},            {-19}},
								{{129, 171},            {-20}},
								{{129, 97},            	{-21}},
								{{129, 99},            	{-22}},
								{{129, 121},            {-23}},
								{{129, 122},            {-24}},
								{{129, 156},            {-25}}, -- O
								{{129, 126},            {-26}}, -- X
								{{133, 1159, 1219},		{-1000}},
								{{133, 99},				{-27}}, -- £
								{{133, 64},				{-28}}, -- € 
								
							},
					p239 = {
								{{239, 40},				{-3}}, --Auto-translate
								{{239, 39},				{-2}}, --Auto-translate
								
								{{239, 31},				{91,70,105,114,101,93}}, 						 -- fire
								{{239, 32},				{91,105,99,101,93}},  							-- ice
								{{239, 33},				{91,119,105,110,100,93}},  						-- wind
								{{239, 34},				{91,101,97,114,116,104,93}}, 					-- earth
								{{239, 35},				{91,108,105,103,104,116,110,105,110,103,93}},   -- lightning
								{{239, 36},				{91,119,97,116,101,114,93}}, 					 -- water
								{{239, 37},				{91,108,105,103,104,116,93}},					  -- light
								{{239, 38},				{91,100,97,114,107,93}},  	 						-- dark
							},
					pOther = {
								{{2030,1001,1003},		{  }},
								{{2030,1005,1008},		{  }},
								{{2030,65},				{  }},
								{{2030,1067,1069},		{  }},
								{{2030,1071,1073},		{  }},
								{{2030,1076,1083},		{  }},
								{{2030,85},				{  }},
								{{2030,1088,1090},		{  }},
								{{2030,92},				{  }},
								{{2030,96},				{  }},
								{{2030,1005,106},			{  }},
								{{30,110},				{  }},
								{{31,146},				{  }},
								{{31,80},				{  }},
								{{31,1121,1141},		{  }},
								{{32,30,106},			{32}},
								{{32,30,82},			{32}},
								{{32,30,67},			{32}},
								{{106, 76},	  			{76}},
								{{32, 30, -1},			{32}},
								{{10},					{ }}, -- ò
								{{7},					{32}},
						},
				},

	ShiftJISReps = {
		-- ['\239\39'	] =	utf8.char(0x276E), -- -2
		-- ['\239\40'	] =	utf8.char(0x276F), -- -3
		['\129\158'] =	utf8.char(0x25C7), -- -4
		['\129\159'] =	utf8.char(0x25C6), -- -5
		['\129\154'] =	utf8.char(0x2605), -- -6
		['\129\153'] =	utf8.char(0x2606), -- -7
		['\129\244'] =	utf8.char(0x266A), -- -8
		['\129\96' ] =	utf8.char(0x007E), -- -9
		['\135\178'] =	utf8.char(0x201C), -- -10
		['\135\179'] =	utf8.char(0x201D), -- -11
		['\136\105'] =	utf8.char(0x00E9), -- -12
		['\133\112'] =	utf8.char(0x00B0), -- -13
		['\129\172'] =	utf8.char(0x2014), -- -14
		['\129\168'] =	utf8.char(0x2192), -- -15
		['\131\182'] =	utf8.char(0x03A9), -- -16
		['\129\166'] =	utf8.char(0x25D9), -- -17
		['\129\169'] =  utf8.char(0x2190), -- 18
		['\129\170'] =  utf8.char(0x2191), -- 19
		['\129\171'] =  utf8.char(0x2193), -- 20
		['\129\97'] =  	utf8.char(0x2551), -- 21
		['\129\99'] = 	utf8.char(0x22EF), -- 22
		['\129\121'] =  utf8.char(0x3010), -- 23
		['\129\122'] =  utf8.char(0x3011), -- 24
		['\129\126'] =  utf8.char(0x0A66), -- 25
		['\129\156'] =  utf8.char(0x2715), -- 26
		['\133\99'] =  	utf8.char(0x00A3), -- 27
		['\133\64'] =  	utf8.char(0x20AC), -- 28
		['\239\31' ] =  '[fire]',  		   -- fire
		['\239\32' ] =  '[ice]', 		   -- ice
		['\239\33' ] =  '[wind]', 	       -- wind
		['\239\34' ] =  '[earth]', 		   -- earth
		['\239\35' ] =  '[lightn.]',       -- lightning
		['\239\36' ] =  '[water]',  	   -- water
		['\239\37' ] =  '[light]',         -- light
		['\239\38' ] =  '[dark]', 	   	   -- dark
				},
				
	ShiftJISback = {
		{0x276e, '\239\39', '<'},
		{0x276f, '\239\40', '>'}, -- -3
		{0x25C7, '\129\158', ''}, -- -4
		{0x25C6, '\129\159', ''}, -- -5
		{0x2605, '\129\154', ''}, -- -6
		{0x2606, '\129\153', ''}, -- -7
		{0x266A, '\129\244', ''}, -- -8
		{0x007E, '\129\96', '~'}, -- -9
		{0x201C, '\135\178','\"'}, -- -10+
		{0x201D, '\135\179','\"'}, -- -11
		{0x00E9, '\136\105','é'},	-- -12
		{0x00B0, '\133\112','°'}, -- -13
		{0x2014, '\129\172','ò'}, -- -14
		{0x2192, '\129\168','->'}, -- -15
		{0x03A9, '\131\182','ò'}, -- -16
		{0x25D9, '\129\166','x'}, -- -17
		{0x2190, '\129\169','<-'}, -- -18
		{0x2191, '\129\170','+'}, -- -19
		{0x2193, '\129\171','-'}, -- -20	
		{0x2551, '\129\97','|'}, -- -21	
		{0x22EF, '\129\99','...'}, -- -22	
		{0x3010, '\129\121','{'}, -- -23	
		{0x3011, '\129\122','}'}, -- -24	
		{0x0A66, '\129\156','O'}, -- -25	
		{0x2715, '\129\126','X'}, -- -26	
		{0x00A3, '\133\99','£'}, -- -27	
		{0x20AC, '\133\64','€'}, -- -28	
		{0x2764, '<3','<3'},
		{0x25C0, '<','<'},
		{0x25B6, '>','>'},
		{0x0589, ':',':'},
		{0x2022, '-','-'},
		{0x2043, '-','-'},
			},

	ShiftJISRanges = T{
		{0x20,0x7E, -1, -1},
		{0xA1,0xDF, -1, -1},
		{0x81 ,0x9F, -1, -1},
		
	},
	UTF8chars = {
		
		0x276e, -- -2
		0x276f, -- -3
		0x25C7, -- -4
		0x25C6, -- -5
		0x2605, -- -6
		0x2606, -- -7
		0x266A, -- -8
		0x007E, -- -9
		0x201C, -- -10
		0x201D, -- -11
		0x00E9,	-- -12
		0x00B0, -- -13
		0x2014, -- -14
		0x2192, -- -15
		0x03A9, -- -16
		0x25D9, -- -17
		0x2190, -- -18
		0x2191, -- -19
		0x2193, -- -20
		0x2551, -- -21
		0x22EF, -- -22
		0x3010, -- -23
		0x3011, -- -24
		0x0A66, -- -25
		0x2715, -- -26
		0x00A3, -- -27
		0x20AC, -- -28
	},

	crafts = {'cooking','alchemy','fishing','working','smithing','craft','synergy'},
	equipSlots = {
		[1] = 'Main',
		[2] = 'Sub',
		[3] = 'Weapon',
		[4] = 'Range',
		[8] = 'Ammo',
		[16] = 'Head',
		[32] = 'Body',
		[64] = 'Hands',
		[128] = 'Legs',
		[256] = 'Feet',
		[512] = 'Neck',
		[1024] = 'Waist',
		[2048] = 'L.Ear',
		[4096] = 'R.Ear',
		[6144] = 'Earring',
		[8192] = 'L.Ring',
		[16384] = 'R.Ring',
		[24576] = 'Ring',
		[32768] = 'Back',
	},
	equipJobs = {
		[ 1] = 'WAR',
		[ 2] = 'MNK',
		[ 3] = 'WHM',
		[ 4] = 'BLM',
		[ 5] = 'RDM',
		[ 6] = 'THF',
		[ 7] = 'PLD',
		[ 8] = 'DRK',
		[ 9] = 'BST',
		[10] = 'BRD',
		[11] = 'RNG',
		[12] = 'SAM',
		[13] = 'NIN',
		[14] = 'DRG',
		[15] = 'SMN',
		[16] = 'BLU',
		[17] = 'COR',
		[18] = 'PUP',
		[19] = 'DNC',
		[20] = 'SCH',
		[21] = 'GEO',
		[22] = 'RUN',
		
	},
	equipRaces = {
		[2]	= 'Hum.M',
		[4]	= 'Hum.F',
		[6]	= 'Hume',
		[8] = 'Elv.M',
		[16] = 'Elv.F',
		[24] = 'Elv.',
		[32] = 'Tar.M',
		[64] = 'Tar.F',
		[96] = 'Taru.',
		[128] = 'Mith.',
		[212] = 'All F',
		[256] = 'Galk.',
		[298] = 'All M',
		[510] = 'All',
		
	},
}

utils.GetEquipJobs = function (jobsbytes)
	local Jobs = {}
	local jobsstring = ''
    if jobsbytes == 8388606 then
		table.insert(Jobs, 'All Jobs')
	else
		for i = 1, 23 do
			if bit.band(1, bit.rshift(jobsbytes, i)) == 1 then
				table.insert(Jobs, utils.equipJobs[i])
			end
		end
    end
	if #Jobs > 0 then
		jobsstring = Jobs[1]
		for j = 2,#Jobs do
			jobsstring=jobsstring..'/'..Jobs[j]
		end
	end
    return jobsstring
end

utils.SetClipboardText = function(text)
    if user32.OpenClipboard(nil) == 0 then
        --error("Failed to open clipboard")
    end

    -- Empty the clipboard
    if user32.EmptyClipboard() == 0 then
        user32.CloseClipboard()
        --error("Failed to empty clipboard")
    end

    -- Allocate global memory for the string
    local size = ffi.C.strlen(text) + 1
    local hGlobal = kernel32.GlobalAlloc(ffi.C.GMEM_MOVEABLE, size)
    if hGlobal == nil then
        user32.CloseClipboard()
        --error("Failed to allocate global memory")
    end

    -- Lock the global memory and copy the string into it
    local pGlobal = kernel32.GlobalLock(hGlobal)
    if pGlobal == nil then
        kernel32.GlobalUnlock(hGlobal)
        user32.CloseClipboard()
        --error("Failed to lock global memory")
    end

    ffi.C.memcpy(pGlobal, text, size)
    kernel32.GlobalUnlock(hGlobal)

    -- Set the clipboard data
    if user32.SetClipboardData(ffi.C.CF_TEXT, hGlobal) == nil then
        user32.CloseClipboard()
        --error("Failed to set clipboard data")
    end

    -- Close the clipboard
    if user32.CloseClipboard() == 0 then
        --error("Failed to close clipboard")
    end

    --print("Text successfully copied to clipboard!")
end

local function LoadTexture(textures, name)
    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    local res = C.D3DXCreateTextureFromFileA(d3d8dev, string.format('%s/images/%s.png', addon.path, name), texture_ptr);
    if (res ~= C.S_OK) then
        error(('Failed to load image texture: %08X (%s)'):fmt(res, d3d.get_error(res)));
    end;
	textures[name] = ffi.new('IDirect3DTexture8*', texture_ptr[0]);
    d3d.gc_safe_release(textures[name]);
end

utils.ItemIcon = function(bitmap, size)
    local texturePtr = ffi.new('IDirect3DTexture8*[1]')
	
    local createTexture = C.D3DXCreateTextureFromFileInMemoryEx(
        gfxDevice, bitmap, size, 0xFFFFFFFF, 0xFFFFFFFF, 1, 0, C.D3DFMT_A8R8G8B8, C.D3DPOOL_MANAGED, C.D3DX_DEFAULT, C.D3DX_DEFAULT, 0xFF000000, nil, nil, texturePtr)
    if createTexture == C.S_OK then
        return d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', texturePtr[0]))
    else
        return nil
    end
end

utils.ItemIconRelease = function(ptr)
	if ptr then
		d3d.gc_safe_release(ptr)
	end
end

local function cleanMC(text)
	return text:gsub("\\§........ç\\", "")
end

utils.LoadTextures = function()
    local textures = T{};

    LoadTexture(textures, 'border');
    LoadTexture(textures, 'settings');
    LoadTexture(textures, 'guideme');
	LoadTexture(textures, 'logs');
	LoadTexture(textures, 'loading');
	LoadTexture(textures, 'folder');
	LoadTexture(textures, 'compact');
	LoadTexture(textures, 'manual');
	LoadTexture(textures, 'info');
	LoadTexture(textures, 'notepad');
	LoadTexture(textures, 'dumpchat');

    return textures;
end

-- utils.RGBAToHex = function(T)
    -- -- Ensure r, g, b, a are integers between 0 and 1
    -- r = math.max(0, math.min(255, math.floor(T[1]*255)))
    -- g = math.max(0, math.min(255, math.floor(T[2]*255)))
    -- b = math.max(0, math.min(255, math.floor(T[3]*255)))
    -- a = a and math.max(0, math.min(255, math.floor(T[4]*255))) or 255 -- Default alpha is 1 (fully opaque)
	
    -- return string.format("0x%02X%02X%02X%02X", a, r, g, b)
-- end

utils.hexToRGBA = function(hex)
    
	string.gsub(hex, "0x", "");
    
    local a, r, g, b;

    -- If the input is in RRGGBBAA format (with alpha)
    a = tonumber(hex:sub(1, 2), 16);
    r = tonumber(hex:sub(3, 4), 16);
    g = tonumber(hex:sub(5, 6), 16);
    b = tonumber(hex:sub(7, 8), 16);

    return a, r, g, b;
end

utils.FindInTable = function(sometable, f)
	local idx = 0;
	if (sometable ~= nil) then
		for _, t in pairs(sometable) do
			idx=idx+1;
			if (t == f) then return idx end
		end
	end
	return nil
	
end

utils.FindInTableSorted = function(sometable, f)
	local idx = 0;
	if (sometable ~= nil) then
		for _, t in pairs(sometable) do
			idx=idx+1;
			if (t == f) then return idx end
			if (f > t) then return false end
		end
	end
	return nil
end

utils.FindInTableFind = function(sometable, f, l)
	local idx = 0;
	if (sometable ~= nil) then
		for _, t in pairs(sometable) do
			idx=idx+1;
			if l == 0 and (string.find(t,f,1,true)) then return idx 
			elseif l > 0 and (string.find(t[l],f,1,true)) then return idx end
		end
	end
	return nil
end

utils.FindInStringTable = function(f, sometable, l)
	local idx = 0;
	if (sometable ~= nil) then
		for _, t in pairs(sometable) do
			idx=idx+1;
			if l == 0 and (string.find(f,t,1,true)) then return idx 
			elseif l > 0 and (string.find(f,t[l],1,true)) then return idx end
		end
	end
	return nil
end

utils.FindInStringTableFilters = function(f, sometable, scope)
	local idx = 0;
	local lowerf = string.lower(f)
	if (sometable ~= nil) then
		for _, t in ipairs(sometable) do
			
			idx=idx+1;
			if t[2] == '_z' or not t[2]:find(scope) then
				
				if string.find(lowerf,string.lower(t[1]),1,false) then return idx end
			end
		end
	end
	
	return nil
end

utils.FindLastOf = function(str, chr)
    for i = #str, 1, -1 do
        if str:sub(i, i) == chr then
            return i
        end
    end
    return nil -- Return nil if the character is not found
end

utils.FindLastOfString = function(str, str2)
	local idx = 0
	local last = nil
	local found = true
	while found and idx+1 < #str do
		found, idx = str:find(str2, idx+1, true)
		if idx then last = idx end
	end
	return last
end

utils.FindLastOfMB = function(str, chr)
    local chr_bytes = {chr:byte(1, -1)} -- all bytes of target char
    local chr_len = #chr_bytes
    local strlen = #str

    -- Scan backwards
    for i = strlen - chr_len + 1, 1, -1 do
        local match = true
        for j = 1, chr_len do
            if str:byte(i + j - 1) ~= chr_bytes[j] then
                match = false
                break
            end
        end
        if match then
            return i -- return the byte index of the match
        end
    end
    return nil
end

utils.findIndexOfValue = function(t, targetValue)
    -- Iterate over the outer table
    for index, innerTable in ipairs(t) do
        -- Ensure the entry is a table
        if type(innerTable) == "table" then
            -- Iterate over the inner table
            for _, value in pairs(innerTable) do
                if value == targetValue then
                    return index -- Return the index if the value is found
                end
            end
        end
    end
    return nil -- Return nil if no match is found
end




utils.GetTableLen = function(sometable)
	local count = 0;
	if (sometable ~= nil) then
		for _ in pairs(sometable) do count = count + 1 end		
	end
	return count;
end

utils.ParseUrlLink = function(text)

	local url = '';
	if not text:find('https') and not text:find('www.') then return url end
    --local url_pattern = "https?://?[%w#_/!%?%-\"\'%^%(%);@=%+*%$/%%{}~]+%.[%a]+/?[%w%p]+" -- Matches URLs starting with protocols  --(\S*\s)?((https?:\/\/)?(\S*\.)+(\S*)+)
    ---local url_pattern = '((%s?)([htps:/]*)([^%s%p/]*%.)([A-z://0-9]*%.)([^%s]*))' -- Matches URLs starting with protocols
	
	local P  = '!\"$%&\'()*+,./;<=>?@%[\\%]^`{|}'
    local url_pattern = '(([/%s]?)([^%s'..P..'][^%s'..P..'][^%s'..P..']*%.)([^%s'..P..'][^%s'..P..'][^%s'..P..']*%.)([^%s][^%s][^%s]*))' -- Matches URLs starting with protocols
--	local www_pattern = "[%a]+%.[%w#_/!%?%-\"\'%^%(%);@=%+*%$/%%{}~]+%.[%a][%a]+/?[%w%p]+" -- Matches URLs starting with www.

    --local url = text:match(www_pattern) or text:match(url_pattern) or '';
    --local url = text:gmatch(url_pattern) or '';
    local url, leadingspace, part1, part2, part3  = string.match((text:gsub('https://www.','www.')):gsub('https://','www.'), url_pattern)
    
	if url then
		local hasletters = part1:match('[A-z]') and part2:match('[A-z]') and part3:match('[A-z]')
		if hasletters and (leadingspace ~='' or string.find(text, tostring(url:trimex()), 1, true) == 1) then
			return url:trimex()
		end
	end
	return ''
end

utils.ExportColors = function(addonpath, charname, colors)
    local f = assert(io.open(addonpath..'\\colorset_'..charname, "w"))
    for k,v in pairs(colors) do
		f:write(string.format("%s,%#x\n", k, v[1])) -- %#x = hex like 0xFFD35AFF
    end
    f:close()
	local msg = 'Exported colorsert to: '..addonpath..'\\colorset_'..charname
	print((msg:gsub('\\\\','\\')))
end--

-- Load table from file and merge into colors
utils.ImportColors = function(addonpath, charname, colors)
	local cols = {}
	for k, v in pairs(colors) do
		cols[k] = v
	end
    local f = io.open(addonpath..'\\colorset_'..charname, "r")
    if not f then print('colorset file not found') return cols end
    for line in f:lines() do
        local key, val = line:match("([^,]+),([^,]+)")
        if key and val then
            local num = tonumber(val) -- works with "0x..." hex or decimal
            if num and cols[key] then
                cols[key][1] = num
            end
        end
    end
    f:close()
    return cols
end

utils.cloneTable = function(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = utils.cloneTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

utils.SaveLogs = function(ChatBuffer1, ChatBuffer2, ChatName, PlayerName, AddonPath, TimeStamp)

	
	local logs_folder = AddonPath.."logs\\"..PlayerName
    local success = os.execute("mkdir "..logs_folder) 
	if not success then
		--print(tostring("mkdir "..AddonPath..logs_folder))
        --return 0;
    end
	
    local timestamp = TimeStamp
    local folder_name = logs_folder.."\\ChatLogs_".. timestamp

    -- Create the folder (platform-specific)
    success = os.execute("mkdir " .. folder_name) -- For Windows and most Unix-based systems
  
	local file_name = string.format("%s/"..ChatName..".txt", folder_name)
	local file = io.open(file_name, "w")
	if not file then
		return false
	end
	if ChatBuffer2 ~= nil then
		local max_rows = math.max(#ChatBuffer1, #ChatBuffer2) -- Get the largest number of rows
		for i = 1, max_rows do
			local row1 = ChatBuffer1[i] or "" -- If table1 doesn't have this row, use an empty string
			local row2 = ChatBuffer2[i] or "" -- If table2 doesn't have this row, use an empty string
			file:write(cleanMC(row1) .. ' '.. cleanMC(row2) .. "\n") -- Concatenate the rows and write to the file
		end
		io.close(file);
		return true;
	else
		local max_rows = math.max(#ChatBuffer1) -- Get the largest number of rows
		for i = 1, max_rows do
			local row1 = ChatBuffer1[i] or "" -- If table1 doesn't have this row, use an empty string
			--local row2 = ChatBuffer2[i] or "" -- If table2 doesn't have this row, use an empty string
			file:write(cleanMC(row1).."\n") -- Concatenate the rows and write to the file
		end
		io.close(file);
		return true;
	end
end

utils.ReplaceInts = function(main_table)
    local i = 1
	local ext = 0;
	local replacement_rules = {};
    -- Helper function to check if a pattern matches at a specific index
    local function matches_pattern(main_table, i, pattern)
		ext = 0;
		local adj = 0;
        for j = 1, #pattern do
			if pattern[j] ~= -1 and pattern[j] < 1000 then
                if main_table[i + j - 1 - adj] ~= pattern[j] then
                    return false
                end
            else
				if pattern[j] < 2000 and pattern[j] >= 1000 and pattern[j-1] < 1000  then
					
					if main_table[i + j - 1-adj] < pattern[j]-1000 or main_table[i + j - 1 -adj] > pattern[j+1]-1000  then
					
						return false
					else
						ext = -(1000+ main_table[i + j - 1-adj]);
					end
				else
					if pattern[j] < 2000 and pattern[j-1] < 2000 and pattern[j] >= 1000 and pattern[j-1] >= 1000 then 
						
						adj = adj +1;
					else
						if pattern[j] >= 2000 then
							if main_table[i + j - 1-adj] == nil or (main_table[i + j - 1-adj] < pattern[j]-(1000*(math.floor(pattern[j]/1000))) or main_table[i + j - 1-adj] > (pattern[j]-(1000*(math.floor(pattern[j]/1000))))+(math.floor(pattern[j]/1000)-1)) then
								return false;
							end
							
						else
				-- Wildcard matching: only matches positive integers
							if main_table[i + j - 1-adj] == nil or main_table[i + j - 1-adj] < 0 then
								return false
							end
						end
					end
				end
				
            end
        end
		--Debug('here'..tostring(main_table[i]), 1, true);
        return true
    end

    -- Helper function to replace a pattern
    local function replace_pattern(main_table, i, pattern_length, replacement)
        -- Remove matched pattern
        for _ = 1, pattern_length do
            table.remove(main_table, i)
        end
        -- Insert replacement pattern
		
        for j = #replacement, 1, -1 do
			if replacement[j] > -1000 then
				table.insert(main_table, i, replacement[j])
			else
				table.insert(main_table, i, ext)
			end
        end
    end

    -- Iterate through main_table
    while i <= #main_table do
        local matched = false
		
		if main_table[i] == 127 then
			replacement_rules =  utils.badStrings.p127
		elseif main_table[i] >= 129 and main_table[i] <= 136 then
			replacement_rules =  utils.badStrings.p129136
		elseif main_table[i] == 239 then
			replacement_rules =  utils.badStrings.p239
		else
			replacement_rules =  utils.badStrings.pOther
		end
		if not replacement_rules then replacement_rules = {} end
        for _, rule_pair in ipairs(replacement_rules) do
            local pattern = rule_pair[1]
            local replacement = rule_pair[2]

            if matches_pattern(main_table, i, pattern) then
				--if math.max(table.unpack(pattern)) > 1000 then 	
				local p = 0;
				for P_i = 1, #pattern do
					if  pattern[P_i] < 2000 and pattern[P_i] > p then p = pattern[P_i] end;
				end
				local l;
				--if p > 1000 then Debug(p,1,true); end
				if  (p >= 1000) then l = #pattern-1 else l = #pattern end
				replace_pattern(main_table, i, l, replacement)
                matched = true
            end
        end

        if not matched then
            -- Move to the next index if no rule matched
            i = i + 1
        end
    end

    return main_table
end


utils.int2text = function(input_table, utf8_list)
    local result = {}
	local count = 0;
	local extra_bytes = 0
    for _, value in ipairs(input_table) do
		if extra_bytes > 0 then
			table.insert(result, string.char(value))
        elseif value >= 32 and value <= 126 then
            -- Keep integers between 32 and 126
            table.insert(result, string.char(value))
        elseif value < -1 and value > -1000 then
            -- Handle negative integers starting from -2
            local index = -value - 1  -- Calculate the index for utf8_list
            if utf8_list[index] then
                table.insert(result, utf8.char(utf8_list[index]))
				--count = count +1;
            end
		elseif value < -1000 then
			if value <= -1159 then
				local offset = -1*(value + 1000)-160;-- print(offset);
				table.insert(result, utf8.char(0x00C1+offset))
				--count = count +1;
			--elseif value >= -1062 and  value <= -1030 then
			--	local offset = -1*(value + 1000)-30;-- print(offset);
			--	table.insert(result, utf8.char(0x0431+offset))
			end
		elseif value >= 0xF0 then
			table.insert(result, string.char(value))
			extra_bytes = 3
        end
        -- All other values are discarded
    end

    return table.concat(result)
end


utils.utf8split = function(input_str, split_index)
      -- Ensure the split index is within valid bounds
    if split_index <= 0 then
        return 0 -- Start of the string
    elseif split_index > #input_str then
        return #input_str -- End of the string
    end
	--print('#input_str0'..tostring(split_index);
    -- Scan backwards to locate the first UTF-8 character boundary
    local i = split_index

    while i > 0 do
        local b = input_str:byte(i)

		
        -- Check if it's a valid UTF-8 start byte
        if b < 0x80 then
            return i-1 -- ASCII character (1 byte), safe split
        elseif b >= 0xC2 and b <= 0xDF then
            -- 2-byte character start (110xxxxx)
            if split_index >= i + 1 then return i-1 end
        elseif b >= 0xE0 and b <= 0xEF then
            -- 3-byte character start (1110xxxx)
            if split_index >= i + 2 then return i-1 end
        elseif b >= 0xF0 and b <= 0xF4 then
            -- 4-byte character start (11110xxx)
            if split_index >= i + 3 then return i-1 end
        end
		
		

        -- If it's a continuation byte (10xxxxxx), move left
        i = i - 1
    end

    -- If no valid position is found, return 0
    return 0
end

-- Helper function to check if an integer corresponds to an ASCII character
utils.CleanInts = function(main_table)
    local i = 1

    -- Helper function to check if an integer corresponds to an ASCII character
    local function is_ascii(int)
        return (int >= 32 and int <= 126) 
	end

	local function is_timed_message(int1, int2, int3)
        return (int1 == 127) and (int2 >= 49 and int2 <= 55) and (int3 >= 1 and int3 <= 6)
    end


    -- Helper function to check if an integer is part of a Shift-JIS multibyte pattern
    local function is_shiftjis_multibyte_start(int)
        return (int >= 129 and int <= 159) or (int >= 224 and int <= 239) or (int == 127)
    end

    local function is_shiftjis_multibyte_continuation(int)
        return int >= 0 and int <= 252
    end
	
	local function is_utf32(int)
		if int >= 0xF0
		then
			return true
		end
		return false
	end
	

    -- Iterate through main_table
    while i <= #main_table do
        local value = main_table[i]

        if value >= 0  then
            if is_ascii(value) then
                i = i + 1
			elseif is_utf32(value) then
				i = i + 4
			elseif i < #main_table -1 and is_timed_message(main_table[i],main_table[i + 1],main_table[i + 2]) then
				table.remove(main_table, i) -- Remove the start byte
				table.remove(main_table, i + 1) -- Remove the start byte
                table.remove(main_table, i + 2) -- Remove the continuation byte
            elseif is_shiftjis_multibyte_start(value) and i < #main_table and is_shiftjis_multibyte_continuation(main_table[i + 1]) then
                -- Remove both bytes of the multibyte sequence
                table.remove(main_table, i) -- Remove the start byte
                table.remove(main_table, i) -- Remove the continuation byte
            else
                -- Remove invalid or non-ASCII values
                table.remove(main_table, i)
            end
        else
            -- Skip negative integers
            i = i + 1
        end
    end

    return main_table
end

local function processTable(tableContent)
    local rows = {}
    local colWidths = {}
    
    -- Parse rows
    for row in tableContent:gmatch("<tr.->(.-)</tr>") do
        local cells = {}
        for cell in row:gmatch("<t[dh].->(.-)</t[dh]>") do
            local cleanCell = cell:gsub("<.->", ""):gsub("^%s*(.-)%s*$", "%1")
            table.insert(cells, cleanCell)
            colWidths[#cells] = math.max(colWidths[#cells] or 0, #cleanCell)
        end
        table.insert(rows, cells)
    end
    
    -- Format output
    local output = {}
    for i, row in ipairs(rows) do
        local formattedRow = {}
        for j, cell in ipairs(row) do
            formattedRow[j] = cell .. string.rep(" ", colWidths[j] - #cell)
        end
        table.insert(output, "| " .. table.concat(formattedRow, " | ") .. " |")
        
        -- Add separator line after header
        if i == 1 then
            table.insert(output, "-" .. string.rep("-", #output[#output] - 2) .. "-")
        end
    end
    
    return "\n" .. table.concat(output, "\n") .. "\n"
end

utils.GetWalkthrough = function(str)
    -- Format titles according to the rules
    str = str:gsub("<h1>(.-)</h1>", function(text)
        return "\n[" .. text:upper() .. "]\n"
    end)

    str = str:gsub("<h2.->(.-)</h2>", function(text)
        return "\n[" .. text:gsub("<[^>]*>", "") .. "]\n"
    end)

    str = str:gsub("<h3>(.-)</h3>", function(text)
        return "\n> " .. text .. '\n'
    end)
    
    str = str:gsub("<h4>(.-)</h4>", "")
    str = str:gsub("<ul class=\"gallery mw%-gallery%-traditional\">.-</ul>", "")
    str = str:gsub("<p>", "\n\n")
    str = str:gsub("<br%s*/?>", "\n")
    str = str:gsub("<div.->", "\n\n")
    
    str = str:gsub("<figure.->.-</figure>", "")
    str = str:gsub('<div class="thumbcaption".->.-</div>', "")
    str = str:gsub("<caption.->.-</caption>", "")
    
    local num = 0
    str = str:gsub("<ol>(.-)</ol>", function(list)
        num = 0
        return list:gsub("<li>(.-)</li>", function(item)
            num = num + 1
            return "\n  " .. num .. ". " .. item
        end)
    end)
    
    str = str:gsub("<ul>(.-)</ul>", function(list)
        return list:gsub("<li>(.-)</li>", "\n    - %1")
    end)
    
    str = str:gsub("%[%d+%]", "")
    str = str:gsub("%[citation needed%]", "")
    str = str:gsub("%[edit%]", "")
    
    str = str:gsub("<a[^>]->(.-)</a>", function(linkText)
        return linkText:gsub("%[.-%]", "")
    end)
    
    str = str:gsub("<span class=\"mw-editsection.-</span>", "")
    str = str:gsub("<table.->(.-)</table>", processTable)
    
    str = str:gsub("<.->", "")
    str = str:gsub("&nbsp;", " ")
    str = str:gsub("&amp;", "&")
    str = str:gsub("&gt;", ">")
    str = str:gsub("&#.-;", "")
    
    str = str:gsub("%[%]", "")
    str = str:gsub("\n\n+", "\n\n")
    
    return str
end


utils.IsInTable = function(t, x)
	for i = 1, #t do
		if t[i] == x then return x; end
	end
	return nil;
end

utils.StringFindTable = function(s, t, m)
	if not m then m = true else m = false end
	if #t == 0 then return nil; end
	for i = 1, #t do
		local f = string.find(s, t[i], 1, m);
		if f then return f end
	end
	return nil;
end

utils.CountExtraBytesT = function(s)
    local i = 1
    local len = #s
    local ebTable = {}
    local extra_bytes = 0

    while i <= len do
        local b = s:byte(i)

        if b < 0x80 then
            -- ASCII: 1 byte
            table.insert(ebTable, extra_bytes)
            i = i + 1

        elseif b >= 0xC2 and b <= 0xDF then
            -- 2-byte sequence
            if i + 1 <= len and bit.band(s:byte(i+1), 0xC0) == 0x80 then
                extra_bytes = extra_bytes + 1
                i = i + 2
            else
                i = i + 1
            end
            table.insert(ebTable, extra_bytes)

        elseif b >= 0xE0 and b <= 0xEF then
            -- 3-byte sequence
            if i + 2 <= len and
               bit.band(s:byte(i+1), 0xC0) == 0x80 and
               bit.band(s:byte(i+2), 0xC0) == 0x80 then
               extra_bytes = extra_bytes + 2
				if b == 0xE2 then
					if (s:byte(i+1) == 0x98 and (
						s:byte(i+2) == 0x85 or
						s:byte(i+2) == 0x86)
						) or (
						s:byte(i+1) == 0x97 and (
						s:byte(i+2) == 0x86 or
						s:byte(i+2) == 0x87)
						) or (
						s:byte(i+1) == 0x9D and (
						s:byte(i+2) == 0xA4)
						)
					then
						extra_bytes = extra_bytes - 1
					end
				end
               i = i + 3
            else
               i = i + 1
            end
            table.insert(ebTable, extra_bytes)

        elseif b >= 0xF0 and b <= 0xF4 then
            -- 4-byte sequence
            if i + 3 <= len and
               bit.band(s:byte(i+1), 0xC0) == 0x80 and
               bit.band(s:byte(i+2), 0xC0) == 0x80 and
               bit.band(s:byte(i+3), 0xC0) == 0x80 then
                extra_bytes = extra_bytes + 2
                i = i + 4
            else
                i = i + 1
            end
            table.insert(ebTable, extra_bytes)

        else
            -- Invalid byte, skip
            i = i + 1
            table.insert(ebTable, extra_bytes)
        end
    end

    return ebTable
end


utils.breakLine = function(s, breakpoint)
    local pos = 1
    local result = {}

    while pos <= #s do
        local chunk = s:sub(pos, pos + (breakpoint-1)) -- Get 40-character chunk
        if #chunk < breakpoint then
            table.insert(result, chunk) -- Last chunk, no need to break
            break
        end

        local lastSpace = chunk:match(".*() ") -- Find last space position
        if lastSpace then
            table.insert(result, s:sub(pos, pos + lastSpace - 1)) -- Up to the last space
            pos = pos + lastSpace -- Move past the space
        else
            table.insert(result, chunk) -- No space found, force break at 40
            pos = pos + breakpoint
        end
    end

    return table.concat(result, "\n")
end

utils.LoadCustomFilters = function()
	custmFilters = T{};
	
	local f = io.open(addon.path .. '/custom_combat_filters.txt', 'rb');
	if (f == nil) then
		error('Failed to load abilities list.');
	end
	for line in f:lines() do
		if line:sub(1,2) ~= '##' and not line:match('^%s*\n?$') then
			local p2 = line:find('%_')
			if p2 then
				local l1 = line:sub(1,p2-1)
				local l2 = line:sub(p2,#line)
				table.insert (custmFilters, {l1:trimex(),l2:trimex()});
			else
				table.insert (custmFilters, {line:trimex(),'_z'});
			end
			
		end
	end
	f:close();
	
	return custmFilters
end

utils.RevertShiftJIS = function(text)
	for i = 1, #utils.ShiftJISback do
		local char = utf8.char(utils.ShiftJISback[i][1])
		local bytes = {char:byte(1, #char)}
		local chars = ''
		for b = 1, #bytes do
			chars = chars..string.char(bytes[b])
		end		
		text = text:gsub(chars,utils.ShiftJISback[i][3])
	end
	return text
end

local function multi_gsub(text, subs, range)
    -- Escape special characters in patterns and collect them
    local keys = {}
    local replacements = {}

    for i, pair in ipairs(subs) do
		if i >= range[1] and i <= range[2] then
			local pattern, replacement = pair[2], utf8.char(pair[1])
			local escaped_pattern = pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") -- Escape special chars
			table.insert(keys, escaped_pattern)
			replacements[escaped_pattern] = replacement
		end
    end

    -- Create a pattern to match any of the given keys
    local pattern = table.concat(keys, "()") -- No '|' used!

    -- Perform gsub using a lookup function
    return text:gsub(pattern, function(match) return replacements[match] end)
end

utils.cleanstr = function(str)
    -- Parse the strings auto-translate tags..
    str = AshitaCore:GetChatManager():ParseAutoTranslate(str, true);

    -- Strip FFXI-specific color and translate tags..
    str = str:strip_colors();
--	str = (str:gsub(string.char(0xEF) .. '[' .. string.char(0x27) .. ']', utf8.char(0x276E)));
--  str = (str:gsub(string.char(0xEF) .. '[' .. string.char(0x28) .. ']', utf8.char(0x276F)));
	str = (str:gsub(string.char(0xEF) .. '[' .. string.char(0x27) .. ']', '£'));
    str = (str:gsub(string.char(0xEF) .. '[' .. string.char(0x28) .. ']', '£'));

	
    -- Strip line breaks..
    while (true) do
        local hasN = str:endswith('\n');
        local hasR = str:endswith('\r');

        if (not hasN and not hasR) then
            break;
        end

        if (hasN) then str = str:trimend('\n'); end
        if (hasR) then str = str:trimend('\r'); end
    end
	
	local i = 1
    local result = ""

    while i <= #str - 1 do
        -- Get the 2-character substring starting from position i
        local pair = str:sub(i, i + 1)

        -- Check if the 2-character substring is in ShiftJISReps
		local found = false
		utils.ShiftJISRanges:each(function(v)
			if (string.byte(pair[1]) >= v[1] and string.byte(pair[1]) <= v[2]) and
			   (v[3] == -1 or (string.byte(pair[2]) >= v[3] and string.byte(pair[2]) <= v[4]))
			then
				found = true
			end
		end)
		if found then
			if utils.ShiftJISReps[pair] then
				-- Replace with the corresponding value and skip 2 characters
				str = str:sub(1, i - 1) .. utils.ShiftJISReps[pair] .. str:sub(i + 2)
				i = i + 2
			else
				i = i + 1
			end
		else
			str = str:sub(1, i - 1) .. str:sub(i + 1)
		end
    end
	
    -- Replace mid-linebreaks..
    return (str:gsub(string.char(0x07), '\n'));
end

utils.ImguiVis = function(visible)
    AshitaCore:GetFontManager():SetVisible(visible);
    AshitaCore:GetPrimitiveManager():SetVisible(visible);
    AshitaCore:GetGuiManager():SetVisible(visible);
end

utils.rgbaToHexNum = function(t)
    local r = math.floor(t[1] * 255)
	local g = math.floor(t[2] * 255)
	local b = math.floor(t[3] * 255)
	local a = math.floor(t[4] * 255)

	local packed = bit.bor(
        bit.lshift(a, 24),
        bit.lshift(r, 16),
        bit.lshift(g, 8),
        b
    )
	return tonumber(ffi.new("uint32_t", packed))
end

utils.stringsplit = function(input, sep)
    if sep == nil then
        sep = "%s"  -- default: split by whitespace
    end
    local result = {}
	if not input or #input == 0 then return result end
	for str in string.gmatch(input, "([^" .. sep .. "]+)") do
        table.insert(result, str)
    end

    return result
end

return utils;

