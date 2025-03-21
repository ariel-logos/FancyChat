require('common');
require('win32types')
local ffi = require('ffi');
local d3d       = require('d3d8');
local C         = ffi.C;
local d3d8dev   = d3d.get_device();
local user32 = ffi.load("user32");
local kernel32 = ffi.load("kernel32");


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
	-- modes = T{
				-- {0,			'zone'		, 0xFFFFFFFF},
				-- {1,			'local'		, 0xFFFFFFFF},
				-- {20,		'combat'	, 0xFFDCF1FC}, --"You" hit "Enemy"
				-- {214,		'linkshell2', 0xFF00FF80},
				-- {213,   	'linkshell2', 0xFF00FF80},
				-- {6,			'linkshell1', 0xFF50FFD0},
				-- {14,		'linkshell1', 0xFF50FFD0},
				-- {4,			'tell_out'	, 0xFFCF56FF},
				-- {5,			'party_out' , 0xFF7BD3FF},
				-- {7,			'emote1'	, 0xFFC797FF},
				-- {9,			'system5_NPC', 0xFFFFFFFF},
				-- {11,		'shout'		, 0xFFFF5E5E},
				-- {12,		'tell_in'	, 0xFFCF56FF},
				-- {13,		'party_in'	, 0xFF7BD3FF},
				-- {15,		'emote2'	, 0xFFC797FF},
				-- {21,		'combat'	, 0xFFDCF1FC}, --"You" miss "Enemy"
				-- {22,		'combat'	, 0xFFDCF1FC}, --"Enemy" uses "aoe"
				-- {24,		'combat'	, 0xFFDCF1FC}, --"Friend" hit "Enemy"
				-- {25,		'combat'	, 0xFFDCF1FC}, --"Friend" hit "Enemy"
				-- {26,		'combat'	, 0xFFDCF1FC}, --"Friend" miss "Enemy"
				-- {27,		'combat'	, 0xFFDCF1FC}, --"Friend" hit by "aoe"
				-- {28,		'combat'	, 0xFFDCF1FC}, --"Enemy" hits "You"
				-- {29,		'combat'	, 0xFFDCF1FC}, --"Enemy" miss "You"
				-- {31,		'combatspell',0xFFDDC9FF}, --"Friend" cast "You"
				-- {32,		'combat'	, 0xFFDCF1FC}, --"Enemy" hit "Friend"
				-- {33,		'combat'	, 0xFFDCF1FC}, --"Enemy" miss "Friend"
				-- {35,		'combatspell'	, 0xFFDDC9FF}, --"Enemy" miss "Friend"
				-- {36,		'combat'	, 0xFFFFFFFF}, 
				-- {37,		'combat'	, 0xFFDCF1FC}, --"Friend" defeats "Enemy"
				-- {39,		'combat'	, 0xFFDCF1FC}, --"Enemy" defeats "Friend"
				-- {50,		'combatspell',0xFFDDC9FF},
				-- {40,		'combat'	, 0xFFDCF1FC}, --"Pet"
				-- {41,		'combat'	, 0xFFDCF1FC}, --"Enemy" misses "Others"
				-- {42,		'combat'	, 0xFFDCF1FC}, --"Pet"
				-- {43,		'combatspell',0xFFDDC9FF}, --spell? "Friend" casting "Friend"
				-- {44,		'combat'	, 0xFFDCF1FC}, --"Pet" defeats
				-- {51,		'combatspell',0xFFDDC9FF}, --spell? "Friend" casting "spell"
				-- {52,		'combatspell',0xFFDDC9FF}, --spell?
				-- {56,		'combatspell',0xFFDDC9FF}, --spell?
				-- {57,		'combatspell',0xFFDDC9FF}, --spell?
				-- {58,		'combatspell',0xFFDDC9FF}, --spell?
				-- {59,		'combatspell',0xFFDDC9FF}, --spell?
				-- {61,		'combatspell',0xFFDDC9FF}, --spell?
				-- {63,		'combat'	 ,0xFFDCF1FC},
				-- {64,		'combatspell',0xFFDDC9FF}, --"Friend" cast "Friend"
				-- {65,		'combatspell',0xFFDDC9FF}, --"Friend" cast "Enemy"
				-- {67,		'combatspell',0xFFDDC9FF}, --"Friend" cast "?"
				-- {68,		'combatspell',0xFFDDC9FF}, --"Friend" cast "?"
				-- {69,		'combatspell',0xFFDDC9FF}, --"Friend" resist "?"
				-- {85,		'item?'		, 0xFFFAFFDB},
				-- {90,		'item?'		, 0xFFFAFFDB},
				-- {100,		'combat'	, 0xFFDCF1FC}, --"Enemy" readies "ability"
				-- {101,		'combat'	, 0xFFDCF1FC}, --"You" uses "ability"
				-- {102,		'combatspell',0xFFDDC9FF}, --spell?
				-- {104,		'combat'	, 0xFFDCF1FC}, --"Enemy" misses "ability"
				-- {105,		'combat'	, 0xFFDCF1FC}, --"Enemy" readies "ability"
				-- {106,		'combat'	, 0xFFDCF1FC}, --"Friend" uses "ability"
				-- {107,		'combatspell',0xFFDDC9FF}, --
				-- {109,		'combat'	, 0xFFDCF1FC},
				-- {110,		'combat'	, 0xFFDCF1FC}, --"You" readies "ability"
				-- {111,		'combat'	, 0xFFDCF1FC}, --"You" readies "ability"
				-- {112,		'combat'	, 0xFFDCF1FC}, --"You" readies "ability"
				-- {114,		'combat'	, 0xFFDCF1FC}, --"You" miss "ability"
				-- {121,		'craft'		, 0xFFFAFFDB},
				-- {122,		'combat'	, 0xFFDCF1FC}, --too far away --enemy can't attack
				-- {123,		'error'		, 0xFFFF0090},
				-- {127,		'system8'	, 0xFFFFF3DA},
				-- {190,		'system8'	, 0xFFFFF3DA}, -- Info
				-- {129,		'combat'	, 0xFFDCF1FC}, -- skillup
				-- {131,		'combat'	, 0xFFDCF1FC}, --exp
				-- {135,		'system8'	, 0xFFFFF3DA}, --party invite
				-- {136,		'system6'	, 0xFFFFED8E},
				-- {141,		'mog'		, 0xFFFFFFFF},
				-- {142,		'system7NPC' ,0xFFFFFFFF},
				-- {146,		'system8'	, 0xFFFFF3DA}, 
				-- {150,		'NPC'		, 0xFFFFFFFF},
				-- {151,		'NPC'		, 0xFFFFFFFF},
				-- {152,		'NPC'		, 0xFFFFFFFF},
				-- --{191,		'combat'	, 0xFFDCF1FC},
				-- {200,   	'servermsg' , 0xFF8E6AFF},
				-- {202,   	'equipset'  , 0xFF8E6AFF},
				-- {209,		'system8'	, 0xFFFFF3DA}, 
				-- {210,		'party_NPC'	, 0xFF7BD3FF},
				-- {212,		'unity'		, 0xFFFFD270},
				-- {662,		'npc3'		, 0xFFFFFFFF},
				-- {654,		'system1'	, 0xFFFFED8E},
				-- {673,		'tlly'		, 0xFFA89DEB},
				-- {889,		'system2'	, 0xFFFFED8E},
				-- {205,   	'linkshell1', 0xFF50FFD0},
				-- {217,   	'linkshell2', 0xFF00FF80},
				-- {162,		'combatspellall', 0xFFDDC9FF}, -- ally casts heal
				-- {163,		'combatall', 0xFFDCF1FC}, -- ally hit enemy
				-- {164,		'combatall', 0xFFDCF1FC}, -- ally miss enemy
				-- {165,		'all',		 0xFFDCF1FC}, -- alliance ???
				-- {166,		'combatall', 0xFFDCF1FC}, -- ally defeat enemy
				-- {167,		'combatall', 0xFFDCF1FC}, -- ally was defeated enemy
				-- {168,		'combatspellall', 0xFFDDC9FF}, -- ally start casting/casts
				-- {169,		'all',		 0xFFDCF1FC}, -- alliance ???
				-- {170,		'all',		 0xFFDCF1FC}, -- alliance ???
				-- {171,		'combatspellall', 0xFFFAFFDB}, -- ally use item
				-- {174,		'combatall', 0xFFDCF1FC}, -- enemy pet use ability/effect
				-- {175,		'combatall', 0xFFDCF1FC}, -- ally use ability
				-- {177,		'combatall', 0xFFDCF1FC}, -- enemy pet
				-- {178,		'all',		 0xFFDCF1FC}, -- alliance ???
				-- {179,		'all',		 0xFFDCF1FC}, -- alliance ???
				-- {180,		'all',		 0xFFDCF1FC}, -- alliance ???
				-- {181,		'combatall', 0xFFDCF1FC}, -- enemy pet
				-- {185,		'combatall', 0xFFDCF1FC}, -- enemy use ability
				-- {186,		'combatall', 0xFFDCF1FC}, -- ally parry
				-- {187,		'combatall', 0xFFDCF1FC}, -- additional effect
				-- {188,		'all',		 0xFFDCF1FC}, -- alliance ???
				-- {189,		'all',		 0xFFDCF1FC}, -- alliance ???
				-- {191,		'combatall', 0xFFDCF1FC}, -- enemy effect wears of
				

		     -- },
					--- fix you cannot perform that action, more unknown channels in debug log, keep hide alliance disabled, fix search not opening tabs when found word is in title in manual
	modesDA = T{
					{0,		'zone',			0xFFFFFFFF},
					{1,		'local',		0xFFFFFFFF},
					{2,		'_?',		0xFFFFFFFF},
					{3,		'_?',		0xFFFFFFFF},
					{4,		'tell_out',		0xFFD35AFF},
					{5,		'party_out',	0xFF7BD3FF},
					{6,		'linkshell1',	0xFF50FFD0},
					{7,		'emote1',		0xFFC797FF},
					{8,		'_?',		0xFFFFFFFF},
					{9,		'system5_NPC',	0xFFFFFFFF},
					{10,	'shout',		0xFFFF5E5E},
					{11,	'shout',		0xFFFF5E5E},
					{12,	'tell_in',		0xFFD35AFF},
					{13,	'party_in',		0xFF7BD3FF},
					{14,	'linkshell1',	0xFF50FFD0},
					{15,	'emote2',		0xFFC797FF},
					{16,	'_?',		0xFFFFFFFF},
					{17,	'_?',		0xFFFFFFFF},
					{18,	'_?',		0xFFFFFFFF},
					{19,	'_?',		0xFFFFFFFF},
					{20,	'combat_y',		0xFFDCF1FC},	--"You" damage "Enemy"
					{21,	'combat_y',		0xFFDCF1FC},	--"You" miss "Enemy"
					{22,	'combat_y',		0xFFDCF1FC},	--"Enemy" uses "ability" "You"
					{23,	'combatspell_y',0xFFDCF1FC},	--"You" cast/heal "Party" recover 
					{24,	'combatspell_p',0xFFDCF1FC},	--"Party"cast/heal "Party/PC?" recover
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
					{40,	'combat_x',		0xFFDCF1FC},	--"PC" Damage "Enemy"/"Enemy" Damage "PC"
					{41,	'combat_x',		0xFFDCF1FC},	--"Enemy" misses "PC"/"PC" misses "Enemy"
					{42,	'combat_x',		0xFFDCF1FC},	--"PC" additional effect
					{43,	'combatspell_x',	0xFFDDC9FF},	-- "PC/Enemy" recovers
					{44,	'combat_x',		0xFFDCF1FC},	--"Pet" defeats "Enemy" but also "Enemy" falls to the ground
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
					{64,	'combatspell_x',	0xFFDDC9FF},	--"You/Party" Cast buff/gain buff effect
					{65,	'combatspell_x',	0xFFDDC9FF},	--"You/Party" cast spell status effect on "Enemy"
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
					{170,	'_a',			0xFFDCF1FC}, --"Alliance" status no effect
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
					{182,	'_a',			0xFFFFFFFF}, --"Alliance" cast status on "Enemy"
					{183,	'combat_a',			0xFFFFFFFF}, --"Alliance" gain buff
					{184,	'_a_?',			0xFFFFFFFF},
					{185,	'combat_a',		0xFFDCF1FC},
					{186,	'combat_a',		0xFFDCF1FC},
					{187,	'combat_a',		0xFFDCF1FC},
					{188,	'combatspell_a',0xFFDCF1FC}, -- "Alliance" cast cure on "Friend" recvery
					{189,	'_a_?',			0xFFDCF1FC},
					{190,	'system8',		0xFFFFF3DA},
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
					{211,	'_?',		0xFFFFFFFF},
					{212,	'unity',		0xFFFFD270},
					{213,	'linkshell2',	0xFF00FF80},
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
	disambYou = T{	'Unable to',
					'You '
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
	badStringsPre = {
						{{253, -1, -1, -1, -1, 253, 32},		{  }},
					},
					--127,|52,4|6,|
	-- badStrings = {
					-- {{2030,1001,1003},		{  }},
					-- {{2030,1005,1008},		{  }},
					-- {{2030,65},				{  }},
					-- {{2030,1067,1069},		{  }},
					-- {{2030,1071,1073},		{  }},
					-- {{2030,1076,1083},		{  }},
					-- {{2030,85},				{  }},
					-- {{2030,1088,1090},		{  }},
					-- {{2030,92},				{  }},
					-- {{2030,96},				{  }},
					-- {{2030,1005,106},			{  }},
					-- {{127, 1049,1055, 1},	{  }},
					-- {{127, 1049,1055, 2},	{  }},
					-- {{127, 1049,1055, 3},	{  }},
					-- {{127, 1049,1055, 4},	{  }},
					-- {{127, 1049,1055, 5},	{  }},
					-- {{127, 1049,1055, 6},	{  }},
				-- --	{{127, -1	},			{ 32,32 }},
				-- ---	{{127,52,1001,1006},	{  }},
				-- --	{{127,54,1001,1006},	{  }},
					-- {{127,49},				{  }},
				-- --	{{30,-1},				{  }},
				-- --	{{31,-1},				{  }},
					-- {{30,110},				{  }},
					-- {{31,146},				{  }},
					-- {{31,80},				{  }},
					-- {{31,1121,1141},		{  }},
					-- ----{{31,127},				{  }},
					-- ----{{31,121},				{  }},
					-- ----{{31,136},				{  }},
					-- ----{{31,138},				{  }},
					-- ----{{31,141},				{  }},
					-- --{{30,81,91,30,-1}, 		{91}},--<
					-- --{{30,81,93,30,1}, 		{93}},--<
					-- {{32,30,106},			{32}},
					-- {{32,30,82},			{32}},
					-- {{32,30,67},			{32}},
					-- {{106, 76},	  			{76}},
					-- --x{{30, 1, 30, -1},	 	{  }},--<
					-- --x{{30, 68, 70},			{70}},
					-- --x{{30, 106, 85},			{85}},
					-- --x{{30, 106},				{  }},
					-- --x{{30, 81},				{  }},
					-- --x{{30, 1001, 1006},		{  }},
					-- --{{30, 2},				{  }},
					-- --{{30, 3},				{  }},
					-- --{{30, 4},				{  }},
					-- --{{30, 5},				{  }},
					-- --{{30, 6},				{  }},
					-- {{32, 30, -1},			{32}},
					-- --{{127, 54, 1},			{  }},
					-- --{{127, -1	},			{  }},
					-- {{239, 40},				{-3}}, --Auto-translate
					-- {{239, 39},				{-2}}, --Auto-translate
					-- {{129, 158},			{-4}}, --CE custom content ◇
					-- {{129, 159},			{-5}}, --CE custom content ◆
					-- {{129, 154},			{-6}},  --CE custom content ★
					-- {{129, 153},			{-7}},  -- empty star 0x2606
					-- {{129, 244},			{-8}},  -- ♪
					-- {{129, 64},				{32}},  -- 
					-- {{129, 96},				{-9}},  -- ~
					-- {{135, 178},			{-10}}, --  \"
					-- {{135, 179},			{-11}}, -- \"
					-- {{136, 105},			{-12}},  -- 'é'
					-- {{133, 112},			{-13}}, -- ° 
					-- {{129, 172},			{-14}}, -- ò
					-- {{129, 168},			{-15}}, -- ->
					-- {{131, 182},			{-16}}, -- ò
					-- {{129, 166},			{-17}}, -- weird X
					-- {{10},					{ }}, -- ò
					-- --{{133, 191},			{-15}}, -- à
					-- --{{133, 200},			{-16}}, -- é
					-- --{{133, 199},			{-17}}, -- è
					-- --{{133, 216},			{-18}}, -- ù
					-- --{{133, 203},			{-19}}, -- ì
					-- {{133, 1159, 1219},		{-1000}},
					-- {{133, 99},				{-20}}, -- £
					-- {{133, 64},				{-21}}, -- € 
					-- {{239, 31},				{91,70,105,114,101,93}},  -- fire
					-- {{239, 32},				{91,105,99,101,93}},  -- ice
					-- {{239, 33},				{91,119,105,110,100,93}},  -- wind
					-- {{239, 34},				{91,101,97,114,116,104,93}},  -- earth
					-- {{239, 35},				{91,108,105,103,104,116,110,105,110,103,93}},  -- lightning
					-- {{239, 36},				{91,119,97,116,101,114,93}},  -- water
					-- {{239, 37},				{91,108,105,103,104,116,93}},  -- light
					-- {{239, 38},				{91,100,97,114,107,93}},  -- dark
					-- {{7},					{32}},
				-- },
				
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
								--{{133, 191},			{-15}}, -- à
								--{{133, 200},			{-16}}, -- é
								--{{133, 199},			{-17}}, -- è
								--{{133, 216},			{-18}}, -- ù
								--{{133, 203},			{-19}}, -- ì
								{{133, 1159, 1219},		{-1000}},
								{{133, 99},				{-20}}, -- £
								{{133, 64},				{-21}}, -- € 
								
							},
					p239 = {
								{{239, 40},				{-3}}, --Auto-translate
								{{239, 39},				{-2}}, --Auto-translate
								
								{{239, 31},				{91,70,105,114,101,93}},  -- fire
								{{239, 32},				{91,105,99,101,93}},  -- ice
								{{239, 33},				{91,119,105,110,100,93}},  -- wind
								{{239, 34},				{91,101,97,114,116,104,93}},  -- earth
								{{239, 35},				{91,108,105,103,104,116,110,105,110,103,93}},  -- lightning
								{{239, 36},				{91,119,97,116,101,114,93}},  -- water
								{{239, 37},				{91,108,105,103,104,116,93}},  -- light
								{{239, 38},				{91,100,97,114,107,93}},  -- dark
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
								
							--	{{127, -1	},			{ 32,32 }},
							---	{{127,52,1001,1006},	{  }},
							--	{{127,54,1001,1006},	{  }},
								
							--	{{30,-1},				{  }},
							--	{{31,-1},				{  }},
								{{30,110},				{  }},
								{{31,146},				{  }},
								{{31,80},				{  }},
								{{31,1121,1141},		{  }},
								----{{31,127},				{  }},
								----{{31,121},				{  }},
								----{{31,136},				{  }},
								----{{31,138},				{  }},
								----{{31,141},				{  }},
								--{{30,81,91,30,-1}, 		{91}},--<
								--{{30,81,93,30,1}, 		{93}},--<
								{{32,30,106},			{32}},
								{{32,30,82},			{32}},
								{{32,30,67},			{32}},
								{{106, 76},	  			{76}},
								--x{{30, 1, 30, -1},	 	{  }},--<
								--x{{30, 68, 70},			{70}},
								--x{{30, 106, 85},			{85}},
								--x{{30, 106},				{  }},
								--x{{30, 81},				{  }},
								--x{{30, 1001, 1006},		{  }},
								--{{30, 2},				{  }},
								--{{30, 3},				{  }},
								--{{30, 4},				{  }},
								--{{30, 5},				{  }},
								--{{30, 6},				{  }},
								{{32, 30, -1},			{32}},
								--{{127, 54, 1},			{  }},
								--{{127, -1	},			{  }},
								{{10},					{ }}, -- ò
								
								{{7},					{32}},
						},
				},
	--badStringsCyrillic = 
	--				{
	--				{{133, 1030, 1062},		{-1000}},
	--				},
	badStringsCombat = {
				----	{{127, 1049,1055, 1},	{  }},
				----	{{127, 1049,1055, 2},	{  }},
				--	{{127, -1	},			{ 32,32 }},
				----	{{127,54,1001,1006},	{  }},
				----	{{127,49},				{  }},
				----	{{30,110},				{  }},
				----	{{31,1121,1141},		{  }},
					----{{31,127},				{  }},
					----{{31,121},				{  }},
					----{{31,136},				{  }},
					----{{31,138},				{  }},
					----{{31,141},				{  }},
					--{{30,81,91,30,-1}, 		{91}},--<
					--{{30,81,93,30,1}, 		{93}},--<
				----	{{32,30,106},			{32}},
				----	{{32,30,82},			{32}},
				----	{{32,30,67},			{32}},
				----	{{106, 76},	  			{76}},
				----	{{30, 1, 30, -1},	 	{  }},--<
				----	{{30, 68, 70},			{70}},
				----	{{30, 106, 85},			{85}},
				----	{{30, 81},				{  }},
				----	{{30, 1001, 1006},		{  }},
					--{{30, 2},				{  }},
					--{{30, 3},				{  }},
					--{{30, 4},				{  }},
					--{{30, 5},				{  }},
					--{{30, 6},				{  }},
				----	{{32, 30, -1},			{32}},
					--{{127, 54, 1},			{  }},
					--{{127, -1	},			{  }},
					--{{239, 40},				{-3}}, --Auto-translate
					--{{239, 39},				{-2}}, --Auto-translate
				----	{{129, 158},			{-4}}, --CE custom content ◇
				----	{{129, 159},			{-5}}, --CE custom content ◆
				----	{{129, 154},			{-6}},  --CE custom content ★
				----	{{129, 153},			{-7}},  -- empty star 0x2606
				----	{{129, 244},			{-8}},  -- ♪
				----	{{129, 64},				{32}},  -- 
				----	{{129, 96},				{-9}},  -- ~
				----	{{135, 178},			{-10}}, --  \"
				----	{{135, 179},			{-11}}, -- \"
				----	{{136, 105},			{-12}},  -- 'é'
				----	{{133, 112},			{-13}}, -- ° 
					--{{133, 209},			{-14}}, -- ò
					--{{133, 191},			{-15}}, -- à
					--{{133, 200},			{-16}}, -- é
					--{{133, 199},			{-17}}, -- è
					--{{133, 216},			{-18}}, -- ù
					--{{133, 203},			{-19}}, -- ì
					--{{133, 1159, 1219},		{-1000}},
					--{{133, 99},				{-20}}, -- £
					--{{133, 64},				{-21}}, -- € 
					--{{239, 31},				{91,70,105,114,101,93}},  -- fire
					--{{239, 32},				{91,105,99,101,93}},  -- ice
					--{{239, 33},				{91,119,105,110,100,93}},  -- wind
					--{{239, 34},				{91,101,97,114,116,104,93}},  -- earth
					--{{239, 35},				{91,108,105,103,104,116,110,105,110,103,93}},  -- lightning
					--{{239, 36},				{91,119,97,116,101,114,93}},  -- water
					--{{239, 37},				{91,108,105,103,104,116,93}},  -- light
					--{{239, 38},				{91,100,97,114,107,93}},  -- dark
				},
	ShiftJITback = {
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
		{0x25B6, '\129\168','->'}, -- -15
		{0x03A9, '\131\182','ò'}, -- -16
		{0x25D9, '\129\166','x'}, -- -17
		{0x25C0, '<','<'},
		{0x0589, ':',':'},
		{0x2022, '-','-'},
		{0x2043, '-','-'},
		{0x2764, '<3','<3'},

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
		--0x279D, -- -15
		0x25B6, -- -15
		0x03A9, -- -16
		0x25D9, -- -17

	},
	subChars = {
				{{239, 40},				{-3}}, --Auto-translate
				{{239, 39},				{-2}}, --Auto-translate
				{{129, 158},			{-4}}, --CE custom content ◇
				{{129, 159},			{-5}}, --CE custom content ◆
				{{129, 154},			{-6}},  --CE custom content ★
				{{129, 153},			{-7}},  -- empty star 0x2606
				{{129, 244},			{-8}},  -- ♪
				{{129, 96},				{-9}},  -- ~
				{{135, 178},			{-10}}, --  \"
				{{135, 179},			{-11}}, -- \"
				{{136, 105},			{-12}},
				},
	crafts = {'cooking','alchemy','fishing','working','smithing','craft','synergy'},
}


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

utils.RGBAToHex = function(T)
    -- Ensure r, g, b, a are integers between 0 and 1
    r = math.max(0, math.min(255, math.floor(T[1]*255)))
    g = math.max(0, math.min(255, math.floor(T[2]*255)))
    b = math.max(0, math.min(255, math.floor(T[3]*255)))
    a = a and math.max(0, math.min(255, math.floor(T[4]*255))) or 255 -- Default alpha is 1 (fully opaque)
	
    return string.format("0x%02X%02X%02X%02X", a, r, g, b)
end

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
			if l == 0 and (string.find(t,f)) then return idx 
			elseif l > 0 and (string.find(t[l],f)) then return idx end
		end
	end
	return nil
end

utils.FindInStringTable = function(f, sometable, l)
	local idx = 0;
	if (sometable ~= nil) then
		for _, t in pairs(sometable) do
			idx=idx+1;
			if l == 0 and (string.find(f,t)) then return idx 
			elseif l > 0 and (string.find(f,t[l])) then return idx end
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
			if t[2] == '_z' or t[2] ~= scope then
				--Debug(t[2],1,true);
				if string.find(lowerf,string.lower(t[1]),1,true) then return idx end
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

utils.FindLastOfMB = function(str, chr)
    local strlen = #str
    local chr_byte = chr:byte() -- Get the first byte of 'chr'

    -- Start scanning backwards
    for i = strlen, 1, -1 do
        if str:byte(i) == chr_byte then
            -- Backtrack to find the start of the multi-byte character
            local start = i
            while start > 1 and str:byte(start - 1) >= 0x80 and str:byte(start - 1) < 0xC0 do
                start = start - 1
            end
            return start
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
--[[
utils.FormatNotepadString = function(input, n)
    local output = ""
    local count = 0

    for i = 1, #input do
        local char = input:sub(i, i)
        count = count + 1
        output = output .. char

        -- Reset count and skip adding a newline if we encounter an existing \n
        if char == "\n" then
            count = 0 -- Reset because \n is already present
        elseif count == n then
            -- Add a newline at every nth character unless there's already a newline
            if input:sub(i + 1, i + 1) ~= "\n" then
                output = output .. "\n"
            end
            count = 0
        end
    end

    return output
end
]]--
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
			file:write(row1 .. ' '.. row2 .. "\n") -- Concatenate the rows and write to the file
		end
		io.close(file);
		return true;
	else
		local max_rows = math.max(#ChatBuffer1) -- Get the largest number of rows
		for i = 1, max_rows do
			local row1 = ChatBuffer1[i] or "" -- If table1 doesn't have this row, use an empty string
			--local row2 = ChatBuffer2[i] or "" -- If table2 doesn't have this row, use an empty string
			file:write(row1.."\n") -- Concatenate the rows and write to the file
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
    for _, value in ipairs(input_table) do
        if value >= 32 and value <= 126 then
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
	

    -- Iterate through main_table
    while i <= #main_table do
        local value = main_table[i]

        if value >= 0  then
            if is_ascii(value) then
                i = i + 1
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

utils.StringFindTable = function(s, t)
	if #t == 0 then return nil; end
	for i = 1, #t do
		local f = string.find(s, t[i]);
		if f then return f end
	end
	return nil;
end

utils.Utf8Len = function(s)
    local length = 0
    for _ in s:gmatch("[\x00-\x7F\xC2-\xF4][\x80-\xBF]*") do
        length = length + 1
    end
    return length
end

utils.Utf8SpaceSavings = function(s)
    local byte_length = #s  -- Total bytes in the original string
    local char_length = 0   -- Counted UTF-8 characters

    for _ in s:gmatch("[\x00-\x7F\xC2-\xF4][\x80-\xBF]*") do
        char_length = char_length + 1
    end

    local saved_spaces = byte_length - char_length
    return saved_spaces
end


utils.CountMultiByteChars = function(s)
    local count = 0      -- Number of multi-byte characters
    local byte_total = 0 -- Total bytes used by multi-byte characters

    for match in s:gmatch("[\xC2-\xDF][\x80-\xBF]"    -- 2-byte characters
                         .. "|[\xE0-\xEF][\x80-\xBF]{2}" -- 3-byte characters
                         .. "|[\xF0-\xF4][\x80-\xBF]{3}") -- 4-byte characters
    do
        count = count + 1
        byte_total = byte_total + #match -- Add the byte length of this character
    end

    return byte_total - count
end

utils.CountExtraBytes = function(s)
    local i = 1
    local extra_bytes = 0
    local len = #s

    while i <= len do
        local b = s:byte(i)

        if b < 0x80 then
            -- ASCII (single byte), no extra bytes
            i = i + 1
        elseif b >= 0xC2 and b <= 0xDF then
            -- 2-byte sequence (0xC2–0xDF)
            if i + 1 <= len and s:byte(i + 1) >= 0x80 and s:byte(i + 1) <= 0xBF then
                extra_bytes = extra_bytes +1
                i = i + 2
            else
                -- Invalid sequence, skip
                i = i + 1
            end
        elseif b >= 0xE0 and b <= 0xEF then
            -- 3-byte sequence (0xE0–0xEF)226,157,175
            if i + 2 <= len and
               s:byte(i + 1) >= 0x80 and s:byte(i + 1) <= 0xBF and
               s:byte(i + 2) >= 0x80 and s:byte(i + 2) <= 0xBF then
                extra_bytes = extra_bytes + 2
                i = i + 3
            else
                -- Invalid sequence, skip
                i = i + 1
            end
        elseif b >= 0xF0 and b <= 0xF4 then
            -- 4-byte sequence (0xF0–0xF4)
            if i + 3 <= len and
               s:byte(i + 1) >= 0x80 and s:byte(i + 1) <= 0xBF and
               s:byte(i + 2) >= 0x80 and s:byte(i + 2) <= 0xBF and
               s:byte(i + 3) >= 0x80 and s:byte(i + 3) <= 0xBF then
                extra_bytes = extra_bytes + 3
                i = i + 4
            else
                -- Invalid sequence, skip
                i = i + 1
            end
        else
            -- Garbage byte, skip
            i = i + 1
        end
    end

    return extra_bytes 
end

utils.CountExtraBytesT = function(s)
    local i = 1
    local extra_bytes = 0
	local ebTable = {}
    local len = #s

    while i <= len do
        local b = s:byte(i)

        if b < 0x80 then
            -- ASCII (single byte), no extra bytes
            i = i + 1
			table.insert(ebTable, extra_bytes)
        elseif b >= 0xC2 and b <= 0xDF then
            -- 2-byte sequence (0xC2–0xDF)
            if i + 1 <= len and s:byte(i + 1) >= 0x80 and s:byte(i + 1) <= 0xBF then
                extra_bytes = extra_bytes +1
                i = i + 2
				table.insert(ebTable, extra_bytes)
            else
                -- Invalid sequence, skip
                i = i + 1
				table.insert(ebTable, extra_bytes)
            end
        elseif b >= 0xE0 and b <= 0xEF then
            -- 3-byte sequence (0xE0–0xEF)226,157,175
            if i + 2 <= len and
               s:byte(i + 1) >= 0x80 and s:byte(i + 1) <= 0xBF and
               s:byte(i + 2) >= 0x80 and s:byte(i + 2) <= 0xBF then
                extra_bytes = extra_bytes + 2
                i = i + 3
				table.insert(ebTable, extra_bytes)

            else
                -- Invalid sequence, skip
                i = i + 1
				table.insert(ebTable, extra_bytes)
            end
        elseif b >= 0xF0 and b <= 0xF4 then
            -- 4-byte sequence (0xF0–0xF4)
            if i + 3 <= len and
               s:byte(i + 1) >= 0x80 and s:byte(i + 1) <= 0xBF and
               s:byte(i + 2) >= 0x80 and s:byte(i + 2) <= 0xBF and
               s:byte(i + 3) >= 0x80 and s:byte(i + 3) <= 0xBF then
                extra_bytes = extra_bytes + 3
                i = i + 4
				table.insert(ebTable, extra_bytes)

            else
                -- Invalid sequence, skip
                i = i + 1
				table.insert(ebTable, extra_bytes)
            end
        else
            -- Garbage byte, skip
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

--[[
utils.HandleNewLines = function(text)
    local bytes = {text:byte(1, #text)}  -- Convert string to byte sequence
    local cleaned_bytes = {}
    local removed_indices = {}
    local i = 1

    while i <= #bytes do
        -- Check if we find the pattern 220, 140
        if bytes[i] == 220 and bytes[i + 1] == 140 then
            if #cleaned_bytes > 0 then
                table.insert(removed_indices, #cleaned_bytes)  -- Store last valid index before 220
            end
            i = i + 2  -- Skip both bytes
        else
            table.insert(cleaned_bytes, bytes[i])
            i = i + 1
        end
    end

    -- Convert back to string
    local cleaned_text = string.char(table.unpack(cleaned_bytes))

    return cleaned_text, removed_indices
end
]]--

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

utils.RevertShiftJIT = function(text)
	for i = 1, #utils.ShiftJITback do
		local char = utf8.char(utils.ShiftJITback[i][1])
		local bytes = {char:byte(1, #char)}
		local chars = ''
		for b = 1, #bytes do
			chars = chars..string.char(bytes[b])
		end		
		text = text:gsub(chars,utils.ShiftJITback[i][3])
	end
	return text
end

return utils;

