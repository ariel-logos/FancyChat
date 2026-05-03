require('common');
require('win32types');

local ffi      = require('ffi');
local d3d      = require('d3d8');
local emojis   = require('emojis');

local C        = ffi.C;
local d3d8dev  = d3d.get_device();
local user32   = ffi.load('user32');
local kernel32 = ffi.load('kernel32');

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
]]

local utils = {

	-- ============================================================
	-- Chat-mode descriptor table.  Indexed implicitly by mode value
	-- (0..255).  Each entry: { mode, semantic_name, ARGB color }.
	-- Comments next to each entry document the typical usage.
	-- ============================================================
	modesDA = T{
		{0,   'zone',           0xFFFFFFFF},
		{1,   'local',          0xFFFFFFFF},
		{2,   'shout',          0xFFFF5E5E},
		{3,   'shout',          0xFFFF5E5E},
		{4,   'tell_out',       0xFFD35AFF},
		{5,   'party_out',      0xFF7BD3FF},
		{6,   'linkshell1out',  0xFF50FFD0},
		{7,   'emote1',         0xFFC797FF},
		{8,   'unused?',        0xFFFFFFFF},  -- used by simplelog for crafting results
		{9,   'local',          0xFFFFFFFF},
		{10,  'shout',          0xFFFF5E5E},
		{11,  'shout',          0xFFFF5E5E},
		{12,  'tell_in',        0xFFD35AFF},
		{13,  'party_in',       0xFF7BD3FF},
		{14,  'linkshell1',     0xFF50FFD0},
		{15,  'emote2',         0xFFC797FF},
		{16,  'cfh',            0xFFFF9763},
		{17,  '_?',             0xFFFFFFFF},
		{18,  '_?',             0xFFFFFFFF},
		{19,  '_?',             0xFFFFFFFF},
		{20,  'combat_y',       0xFFDCF1FC},  -- "You" damage "Enemy"
		{21,  'combat_y',       0xFFDCF1FC},  -- "You" miss "Enemy"
		{22,  'combat_y',       0xFFDCF1FC},  -- "Enemy" uses "ability" "You"
		{23,  'combatspell_y',  0xFFDDC9FF},  -- "You" cast/heal "Party" recover
		{24,  'combatspell_p',  0xFFDDC9FF},  -- "Party" cast/heal "Party/PC?" recover
		{25,  'combat_p',       0xFFDCF1FC},  -- "Party" Damage "Enemy"
		{26,  'combat_p',       0xFFDCF1FC},  -- "Party" miss "Enemy"
		{27,  'combat_p',       0xFFDCF1FC},  -- "Friend" hit by "aoe"
		{28,  'combat_y',       0xFFDCF1FC},  -- "Enemy" hits "You"
		{29,  'combat_y',       0xFFDCF1FC},  -- "Enemy" miss "You"
		{30,  'combat_y',       0xFFFFFFFF},  -- "You" additional effect
		{31,  'combatspell_y',  0xFFDDC9FF},  -- "You" recover "You"
		{32,  'combat_p',       0xFFDCF1FC},  -- "Enemy" damage "Party"
		{33,  'combat_p',       0xFFDCF1FC},  -- "Enemy" miss "Party"
		{34,  'combat_y',       0xFFFFFFFF},  -- "You additional effect"
		{35,  'combatspell_n',  0xFFDDC9FF},  -- "Enemy" miss "PC"
		{36,  'combat_y',       0xFFFFFFFF},  -- "You" defeat "Enemy"
		{37,  'combat_p',       0xFFDCF1FC},  -- "Party" defeats "Enemy"
		{38,  'combat_y',       0xFFDCF1FC},  -- "Enemy" defeats "You"
		{39,  'combat_p',       0xFFDCF1FC},  -- "Enemy" defeats "Party"
		{40,  'combat_n',       0xFFDCF1FC},  -- "PC" Damage "Enemy" / "Enemy" Damage "PC"
		{41,  'combat_n',       0xFFDCF1FC},  -- "Enemy" misses "PC" / "PC" misses "Enemy"
		{42,  'combat_n',       0xFFDCF1FC},  -- "PC" additional effect
		{43,  'combatspell_x',  0xFFDDC9FF},  -- "PC/Enemy" recovers
		{44,  'combat_u',       0xFFDCF1FC},  -- "Pet" defeats "Enemy" / "Enemy" falls to the ground
		{45,  '_?',             0xFFFFFFFF},
		{46,  '_?',             0xFFFFFFFF},
		{47,  '_?',             0xFFFFFFFF},
		{48,  '_?',             0xFFFFFFFF},
		{49,  '_?',             0xFFFFFFFF},
		{50,  'combatspell_y',  0xFFDDC9FF},  -- "You" start casting
		{51,  'combatspell_p',  0xFFDDC9FF},  -- "Party" start casting
		{52,  'combatspell_x',  0xFFDDC9FF},  -- "Party/Enemy/PC" starts casting
		{53,  '_?',             0xFFFFFFFF},
		{54,  '_?',             0xFFFFFFFF},
		{55,  '_?',             0xFFFFFFFF},
		{56,  'combatspell_y',  0xFFDDC9FF},  -- "You" cast buff
		{57,  'combatspell_y',  0xFFDDC9FF},  -- "Enemy" cast spell status effect on you
		{58,  'combatspell_?',  0xFFDDC9FF},
		{59,  'combatspell_y',  0xFFDDC9FF},  -- "You" resist/no effect spell
		{60,  'combatspell_p',  0xFFFFFFFF},  -- "Enemy" cast spell status effect on "Party"
		{61,  'combatspell_p',  0xFFDDC9FF},  -- "Enemy" cast spell/ability status effect on "Party"
		{62,  '_?',             0xFFFFFFFF},
		{63,  'combatspell_p',  0xFFDCF1FC},  -- "Party" resist/no effect spell
		{64,  'combatspell_u',  0xFFDDC9FF},  -- "You/Party" cast buff/gain buff effect
		{65,  'combatspell_u',  0xFFDDC9FF},  -- "You/Party" cast spell status effect on "Enemy"
		{66,  '_?',             0xFFFFFFFF},
		{67,  'combatspell_x',  0xFFDDC9FF},  -- "You/Party" cast status effect "No effect" on "Enemy"
		{68,  'combatspell_x',  0xFFDDC9FF},  -- "Party" on "Party" no effect
		{69,  'combatspell_n_e',0xFFDDC9FF},  -- "PC"/"Enemy" resist/no effect
		{70,  '_?',             0xFFFFFFFF},
		{71,  '_?',             0xFFFFFFFF},
		{72,  '_?',             0xFFFFFFFF},
		{73,  '_?',             0xFFFFFFFF},
		{74,  '_?',             0xFFFFFFFF},
		{75,  '_?',             0xFFFFFFFF},
		{76,  '_?',             0xFFFFFFFF},
		{77,  '_?',             0xFFFFFFFF},
		{78,  '_?',             0xFFFFFFFF},
		{79,  '_?',             0xFFFFFFFF},
		{80,  'combat_y',       0xFFDCF1FC},  -- "You/Party?" uses item on "Enemy"
		{81,  'system14',       0xFFFFF3DA},  -- e.g. learn a new spell
		{82,  '_?',             0xFFFFFFFF},
		{83,  '_?',             0xFFFFFFFF},
		{84,  '_?',             0xFFFFFFFF},
		{85,  'item',           0xFFFAFFDB},
		{86,  '_?',             0xFFFFFFFF},
		{87,  '_?',             0xFFFFFFFF},
		{88,  '_?',             0xFFFFFFFF},
		{89,  'system15',       0xFFFAFFDB},
		{90,  'item',           0xFFFAFFDB},  -- "PC" uses item
		{91,  '_?',             0xFFFFFFFF},
		{92,  '_?',             0xFFFFFFFF},
		{93,  '_?',             0xFFFFFFFF},
		{94,  '_?',             0xFFFFFFFF},
		{95,  '_?',             0xFFFFFFFF},
		{96,  '_?',             0xFFFFFFFF},
		{97,  '_?',             0xFFFFFFFF},
		{98,  '_?',             0xFFFFFFFF},
		{99,  '_?',             0xFFFFFFFF},
		{100, 'combat_e',       0xFFDCF1FC},  -- "Enemy" readies "ability"
		{101, 'combat_y',       0xFFDCF1FC},  -- "You" uses "ability"
		{102, 'combatspell_y',  0xFFDDC9FF},  -- "You" status effect (e.g. you is bound)
		{103, '_?',             0xFFFFFFFF},
		{104, 'combat_y',       0xFFDCF1FC},  -- "Enemy" misses "ability" "You" evade
		{105, 'combat_e',       0xFFDCF1FC},  -- "Enemy" readies "ability"
		{106, 'combat_p',       0xFFDCF1FC},  -- "Party" uses "ability"
		{107, 'combatspell_p',  0xFFDDC9FF},  -- "Enemy" uses "ability" - "Party" gets status effect
		{108, '_?',             0xFFFFFFFF},
		{109, 'combat_p',       0xFFDCF1FC},  -- "Party" evades
		{110, 'combat_x',       0xFFDCF1FC},  -- "PC"/"Enemy"/"Pet" readies "Ability"
		{111, 'combat_x',       0xFFDCF1FC},  -- "PC/Enemy" uses "Ability"
		{112, 'combat_x',       0xFFDCF1FC},  -- "Pet" uses "ability" / "PC" status effect
		{113, '_?',             0xFFFFFFFF},
		{114, 'combat_x',       0xFFDCF1FC},  -- "Enemy/You/Party" miss "ability"
		{115, '_?',             0xFFFFFFFF},
		{116, '_?',             0xFFFFFFFF},
		{117, '_?',             0xFFFFFFFF},
		{118, '_?',             0xFFFFFFFF},
		{119, '_?',             0xFFFFFFFF},
		{120, '_?',             0xFFFFFFFF},
		{121, 'craft',          0xFFFAFFDB},  -- Lot here too (same as craft)
		{122, 'combat_x',       0xFFDCF1FC},  -- "You/PC/Enemy" can't attack/cast (e.g. too far away, paralyzed, intimidated, ability CD)
		{123, 'error',          0xFFFF0090},
		{124, '_?',             0xFFFFFFFF},
		{125, '_?',             0xFFFFFFFF},
		{126, '_?',             0xFFFFFFFF},
		{127, 'system8',        0xFFFFF3DA},
		{128, 'system',         0xFFFFFFFF},  -- an addon used this
		{129, 'combat_y',       0xFFDCF1FC},  -- skill up
		{130, '_?',             0xFFFFFFFF},
		{131, 'combat_y',       0xFFDCF1FC},  -- "You" gain exp/limit, exp/limit chain, obtain gil
		{132, 'system8',        0xFFFFF3DA},  -- assigned merit points
		{133, 'system',         0xFFFFF3DA},  -- level down
		{134, '_?',             0xFFFFFFFF},
		{135, 'system8',        0xFFFFF3DA},
		{136, 'system6',        0xFFFFED8E},
		{137, '_?',             0xFFFFFFFF},
		{138, 'trade',          0xFFFFF3DA},
		{139, 'system8',        0xFFFFF3DA},
		{140, 'clock',          0xFFFFF3DA},
		{141, 'mog',            0xFFFFFFFF},
		{142, 'system7NPC',     0xFFFFFFFF},
		{143, '_?',             0xFFFFFFFF},
		{144, 'system7NPC',     0xFFFFFFFF},
		{145, '_?',             0xFFFFFFFF},
		{146, 'system8',        0xFFFFF3DA},
		{147, '_?',             0xFFFFFFFF},
		{148, 'fishing',        0xFFFFFFFF},
		{149, '_?',             0xFFFFFFFF},
		{150, 'NPC',            0xFFFFFFFF},
		{151, 'NPC',            0xFFFFFFFF},
		{152, 'NPC',            0xFFFFFFFF},
		{153, '_?',             0xFFFFFFFF},
		{154, '_?',             0xFFFFFFFF},
		{155, '_?',             0xFFFFFFFF},
		{156, '_?',             0xFFFFFFFF},
		{157, 'error',          0xFFFF44BB},
		{158, '_?',             0xFFFFFFFF},
		{159, '_?',             0xFFFFFFFF},
		{160, '_?',             0xFFFFFFFF},
		{161, 'tlly',           0xFFFFF3DA},
		{162, 'combatspell_a',  0xFFDDC9FF},
		{163, 'combat_a',       0xFFDCF1FC},
		{164, 'combat_a',       0xFFDCF1FC},
		{165, 'combat_a',       0xFFDCF1FC},  -- "Alliance" additional effect
		{166, 'combat_a',       0xFFDCF1FC},  -- "Alliance" defeats "Enemy"
		{167, 'combat_a',       0xFFDCF1FC},  -- "Enemy" defeats "Alliance"
		{168, 'combatspell_a',  0xFFDDC9FF},
		{169, '_a_?',           0xFFDCF1FC},
		{170, 'combatspell_a',  0xFFDCF1FC},  -- "Alliance" status no effect
		{171, 'combatspell_a',  0xFFFAFFDB},
		{172, '_a_?',           0xFFFFFFFF},
		{173, '_a_?',           0xFFFFFFFF},
		{174, 'combat_a',       0xFFDCF1FC},
		{175, 'combat_a',       0xFFDCF1FC},
		{176, '_?',             0xFFFFFFFF},
		{177, 'combat_a',       0xFFDCF1FC},
		{178, '_a_?',           0xFFDCF1FC},
		{179, '_a_?',           0xFFDCF1FC},
		{180, '_a_?',           0xFFDCF1FC},
		{181, 'combat_a',       0xFFDCF1FC},
		{182, 'combatspell_a',  0xFFFFFFFF},  -- "Alliance" cast status on "Enemy"
		{183, 'combat_a',       0xFFFFFFFF},  -- "Alliance" gain buff
		{184, '_a_?',           0xFFFFFFFF},
		{185, 'combat_a',       0xFFDCF1FC},
		{186, 'combat_a',       0xFFDCF1FC},
		{187, 'combat_a',       0xFFDCF1FC},
		{188, 'combatspell_a',  0xFFDCF1FC},  -- "Alliance" cast cure on "Friend" recovery
		{189, '_a_?',           0xFFDCF1FC},
		{190, 'system8',        0xFF000000},
		{191, 'combat_x',       0xFFDCF1FC},  -- "All" effect wears off
		{192, '_?',             0xFFFFFFFF},
		{193, '_?',             0xFFFFFFFF},
		{194, '_?',             0xFFFFFFFF},
		{195, '_?',             0xFFFFFFFF},
		{196, '_?',             0xFFFFFFFF},
		{197, '_?',             0xFFFFFFFF},
		{198, '_?',             0xFFFFFFFF},
		{199, '_?',             0xFFFFFFFF},
		{200, 'servermsg',      0xFF8E6AFF},
		{201, '_?',             0xFFFFFFFF},
		{202, 'equipset',       0xFFFFF3DA},
		{203, '_?',             0xFFFFFFFF},
		{204, 'searchcomment',  0xFFFFF3DA},
		{205, 'linkshell1',     0xFF50FFD0},
		{206, 'echo',           0xFFFFFFFF},
		{207, '_?',             0xFFFFFFFF},
		{208, 'examined',       0xFFC797FF},
		{209, 'system8',        0xFFFFF3DA},  -- Ability CD timer ends here
		{210, 'party_NPC',      0xFF7BD3FF},
		{211, 'unity',          0xFFFFFFFF},
		{212, 'unity',          0xFFFFD270},
		{213, 'linkshell2out',  0xFF00FF80},
		{214, 'linkshell2',     0xFF00FF80},
		{215, '_?',             0xFFFFFFFF},
		{216, '_?',             0xFFFFFFFF},
		{217, 'linkshell2',     0xFF00FF80},
		{218, '_?',             0xFFFFFFFF},
		{219, '_?',             0xFFFFFFFF},
		{220, 'assist',         0xFFFFFFFF},
		{221, '_?',             0xFFFFFFFF},
		{222, 'assist',         0xFFFFFFFF},
		{223, '_?',             0xFFFFFFFF},
		{224, '_?',             0xFFFFFFFF},
		{225, '_?',             0xFFFFFFFF},
		{226, '_?',             0xFFFFFFFF},
		{227, '_?',             0xFFFFFFFF},
		{228, '_?',             0xFFFFFFFF},
		{229, '_?',             0xFFFFFFFF},
		{230, '_?',             0xFFFFFFFF},
		{231, '_?',             0xFFFFFFFF},
		{232, '_?',             0xFFFFFFFF},
		{233, '_?',             0xFFFFFFFF},
		{234, '_?',             0xFFFFFFFF},
		{235, '_?',             0xFFFFFFFF},
		{236, '_?',             0xFFFFFFFF},
		{237, '_?',             0xFFFFFFFF},
		{238, '_?',             0xFFFFFFFF},
		{239, '_?',             0xFFFFFFFF},
		{240, '_?',             0xFFFFFFFF},
		{241, '_?',             0xFFFFFFFF},
		{242, '_?',             0xFFFFFFFF},
		{243, '_?',             0xFFFFFFFF},
		{244, '_?',             0xFFFFFFFF},
		{245, '_?',             0xFFFFFFFF},
		{246, '_?',             0xFFFFFFFF},
		{247, '_?',             0xFFFFFFFF},
		{248, '_?',             0xFFFFFFFF},
		{249, '_?',             0xFFFFFFFF},
		{250, '_?',             0xFFFFFFFF},
		{251, '_?',             0xFFFFFFFF},
		{252, '_?',             0xFFFFFFFF},
		{253, '_?',             0xFFFFFFFF},
		{254, '_?',             0xFFFFFFFF},
		{255, '_?',             0xFFFFFFFF},
	},

	-- Disambiguation hints used to decide whether a combat-line subject
	-- refers to "the enemy" or to "you".
	disambEnemy = T{
		'on the',
		'but misses the',
	},
	disambYou = T{
		'^Unable to',
		'^You ',
		'^Cannot ex',
		'^Your mo',
	},

	-- Keyboard scancode lookups for the shortcut configuration combos.
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
		{'~ (or (`) or (\\) on non-US keyboards)', 41},
	},
	keycodesSpecial = T{
		{'Shift', 42},
		{'Alt',   56},
		{'Ctrl',  29},
	},

	-- Forward-prompt sentinel byte sequences (used to recognise a
	-- "press [BTN] to continue" line in dialog text).
	fwdchars = {
		string.char(0x7F, 0x30),
		string.char(0x7F, 0x31),
		string.char(0x7F, 0x32),
		string.char(0x7F, 0x33),
		string.char(0x7F, 0x34),
		string.char(0x7F, 0x35),
		string.char(0x7F, 0x36),
		string.char(0x7F, 0x37),
	},

	-- ============================================================
	-- Codepoint replacement rule tables consumed by ReplaceCPs.
	-- Each rule:  { match_pattern, replacement_pattern }
	--   - Negative replacement values index into UTF8chars.
	--   - 1000-range pattern values are wildcard ranges.
	-- ============================================================
	badStrings = {
		p127 = {
			{{127, 1049, 1055, 1}, {}},
			{{127, 1049, 1055, 2}, {}},
			{{127, 1049, 1055, 3}, {}},
			{{127, 1049, 1055, 4}, {}},
			{{127, 1049, 1055, 5}, {}},
			{{127, 1049, 1055, 6}, {}},
			{{127, 49},            {}},
		},
		p129136 = {
			{{129, 158},             {-4}},     -- CE custom content ◇
			{{129, 159},             {-5}},     -- CE custom content ◆
			{{129, 154},             {-6}},     -- CE custom content ★
			{{129, 153},             {-7}},     -- empty star 0x2606
			{{129, 244},             {-8}},     -- ♪
			{{129, 64},              {32}},     -- space
			{{129, 96},              {-9}},     -- ~
			{{135, 178},             {-10}},    -- "
			{{135, 179},             {-11}},    -- "
			{{136, 105},             {-12}},    -- é
			{{133, 112},             {-13}},    -- °
			{{129, 172},             {-14}},    -- —
			{{129, 168},             {-15}},    -- →
			{{131, 182},             {-16}},    -- Ω
			{{129, 166},             {-17}},    -- ◙
			{{129, 169},             {-18}},
			{{129, 170},             {-19}},
			{{129, 171},             {-20}},
			{{129, 97},              {-21}},
			{{129, 99},              {-22}},
			{{129, 121},             {-23}},
			{{129, 122},             {-24}},
			{{129, 156},             {-25}},    -- O
			{{129, 126},             {-26}},    -- X
			{{133, 1159, 1219},      {-1000}},
			{{133, 99},              {-27}},    -- £
			{{133, 64},              {-28}},    -- €
		},
		p239 = {
			{{239, 40},  {-3}},   -- Auto-translate
			{{239, 39},  {-2}},   -- Auto-translate
			{{239, 31},  {91, 70, 105, 114, 101, 93}},                       -- [fire]
			{{239, 32},  {91, 105, 99, 101, 93}},                            -- [ice]
			{{239, 33},  {91, 119, 105, 110, 100, 93}},                      -- [wind]
			{{239, 34},  {91, 101, 97, 114, 116, 104, 93}},                  -- [earth]
			{{239, 35},  {91, 108, 105, 103, 104, 116, 110, 105, 110, 103, 93}}, -- [lightning]
			{{239, 36},  {91, 119, 97, 116, 101, 114, 93}},                  -- [water]
			{{239, 37},  {91, 108, 105, 103, 104, 116, 93}},                 -- [light]
			{{239, 38},  {91, 100, 97, 114, 107, 93}},                       -- [dark]
		},
		pOther = {
			{{2030, 1001, 1003}, {}},
			{{2030, 1005, 1008}, {}},
			{{2030, 65},         {}},
			{{2030, 1067, 1069}, {}},
			{{2030, 1071, 1073}, {}},
			{{2030, 1076, 1083}, {}},
			{{2030, 85},         {}},
			{{2030, 1088, 1090}, {}},
			{{2030, 92},         {}},
			{{2030, 96},         {}},
			{{2030, 1005, 106},  {}},
			{{30, 110},          {}},
			{{31, 146},          {}},
			{{31, 80},           {}},
			{{31, 1121, 1141},   {}},
			{{32, 30, 106},      {32}},
			{{32, 30, 82},       {32}},
			{{32, 30, 67},       {32}},
			{{106, 76},          {76}},
			{{32, 30, -1},       {32}},
			{{10},               {}},
			{{7},                {32}},
		},
	},

	-- Shift-JIS to UTF-8 forward map, keyed by raw 2-byte SJIS.
	ShiftJISReps = {
		['\129\158'] = utf8.char(0x25C7),  -- -4
		['\129\159'] = utf8.char(0x25C6),  -- -5
		['\129\154'] = utf8.char(0x2605),  -- -6
		['\129\153'] = utf8.char(0x2606),  -- -7
		['\129\244'] = utf8.char(0x266A),  -- -8
		['\129\96']  = utf8.char(0x007E),  -- -9
		['\135\178'] = utf8.char(0x201C),  -- -10
		['\135\179'] = utf8.char(0x201D),  -- -11
		['\136\105'] = utf8.char(0x00E9),  -- -12
		['\133\112'] = utf8.char(0x00B0),  -- -13
		['\129\172'] = utf8.char(0x2014),  -- -14
		['\129\168'] = utf8.char(0x2192),  -- -15
		['\131\182'] = utf8.char(0x03A9),  -- -16
		['\129\166'] = utf8.char(0x25D9),  -- -17
		['\129\169'] = utf8.char(0x2190),  -- -18
		['\129\170'] = utf8.char(0x2191),  -- -19
		['\129\171'] = utf8.char(0x2193),  -- -20
		['\129\97']  = utf8.char(0x2551),  -- -21
		['\129\99']  = utf8.char(0x22EF),  -- -22
		['\129\121'] = utf8.char(0x3010),  -- -23
		['\129\122'] = utf8.char(0x3011),  -- -24
		['\129\126'] = utf8.char(0x0A66),  -- -25
		['\129\156'] = utf8.char(0x2715),  -- -26
		['\133\99']  = utf8.char(0x00A3),  -- -27
		['\133\64']  = utf8.char(0x20AC),  -- -28
		['\239\31']  = '[fire]',
		['\239\32']  = '[ice]',
		['\239\33']  = '[wind]',
		['\239\34']  = '[earth]',
		['\239\35']  = '[lightn.]',
		['\239\36']  = '[water]',
		['\239\37']  = '[light]',
		['\239\38']  = '[dark]',
	},

	-- Reverse map: { utf8_codepoint, raw_sjis_bytes, plain_ascii_fallback }.
	ShiftJISback = {
		{0x276e, '\239\39',  '<'},
		{0x276f, '\239\40',  '>'},
		{0x25C7, '\129\158', ''},
		{0x25C6, '\129\159', ''},
		{0x2605, '\129\154', ''},
		{0x2606, '\129\153', ''},
		{0x266A, '\129\244', ''},
		{0x007E, '\129\96',  '~'},
		{0x201C, '\135\178', '"'},
		{0x201D, '\135\179', '"'},
		{0x00E9, '\136\105', 'é'},
		{0x00B0, '\133\112', '°'},
		{0x2014, '\129\172', 'ò'},
		{0x2192, '\129\168', '->'},
		{0x03A9, '\131\182', 'ò'},
		{0x25D9, '\129\166', 'x'},
		{0x2190, '\129\169', '<-'},
		{0x2191, '\129\170', '+'},
		{0x2193, '\129\171', '-'},
		{0x2551, '\129\97',  '|'},
		{0x22EF, '\129\99',  '...'},
		{0x3010, '\129\121', '{'},
		{0x3011, '\129\122', '}'},
		{0x0A66, '\129\156', 'O'},
		{0x2715, '\129\126', 'X'},
		{0x00A3, '\133\99',  '£'},
		{0x20AC, '\133\64',  '€'},
		{0x2764, '<3', '<3'},
		{0x25C0, '<',  '<'},
		{0x25B6, '>',  '>'},
		{0x0589, ':',  ':'},
		{0x2022, '-',  '-'},
		{0x2043, '-',  '-'},
	},

	-- Shift-JIS lead-byte ranges used by cleanstr's range filter.
	ShiftJISRanges = T{
		{0x20, 0x7E, -1, -1},
		{0xA1, 0xDF, -1, -1},
		{0x81, 0x9F, -1, -1},
	},

	-- Codepoint table referenced by ReplaceCPs/CPs2text negative indices.
	-- Entry n maps to the symbol replacing rule code -(n+1).
	UTF8chars = {
		0x276e,  -- -2
		0x276f,  -- -3
		0x25C7,  -- -4
		0x25C6,  -- -5
		0x2605,  -- -6
		0x2606,  -- -7
		0x266A,  -- -8
		0x007E,  -- -9
		0x201C,  -- -10
		0x201D,  -- -11
		0x00E9,  -- -12
		0x00B0,  -- -13
		0x2014,  -- -14
		0x2192,  -- -15
		0x03A9,  -- -16
		0x25D9,  -- -17
		0x2190,  -- -18
		0x2191,  -- -19
		0x2193,  -- -20
		0x2551,  -- -21
		0x22EF,  -- -22
		0x3010,  -- -23
		0x3011,  -- -24
		0x0A66,  -- -25
		0x2715,  -- -26
		0x00A3,  -- -27
		0x20AC,  -- -28
	},

	crafts = {'cooking', 'alchemy', 'fishing', 'working', 'smithing', 'craft', 'synergy'},

	equipSlots = {
		[1]     = 'Main',
		[2]     = 'Sub',
		[3]     = 'Weapon',
		[4]     = 'Range',
		[8]     = 'Ammo',
		[16]    = 'Head',
		[32]    = 'Body',
		[64]    = 'Hands',
		[128]   = 'Legs',
		[256]   = 'Feet',
		[512]   = 'Neck',
		[1024]  = 'Waist',
		[2048]  = 'L.Ear',
		[4096]  = 'R.Ear',
		[6144]  = 'Earring',
		[8192]  = 'L.Ring',
		[16384] = 'R.Ring',
		[24576] = 'Ring',
		[32768] = 'Back',
	},
	equipJobs = {
		[1]  = 'WAR', [2]  = 'MNK', [3]  = 'WHM', [4]  = 'BLM',
		[5]  = 'RDM', [6]  = 'THF', [7]  = 'PLD', [8]  = 'DRK',
		[9]  = 'BST', [10] = 'BRD', [11] = 'RNG', [12] = 'SAM',
		[13] = 'NIN', [14] = 'DRG', [15] = 'SMN', [16] = 'BLU',
		[17] = 'COR', [18] = 'PUP', [19] = 'DNC', [20] = 'SCH',
		[21] = 'GEO', [22] = 'RUN',
	},
	equipRaces = {
		[2]   = 'Hum.M',
		[4]   = 'Hum.F',
		[6]   = 'Hume',
		[8]   = 'Elv.M',
		[16]  = 'Elv.F',
		[24]  = 'Elv.',
		[32]  = 'Tar.M',
		[64]  = 'Tar.F',
		[96]  = 'Taru.',
		[128] = 'Mith.',
		[212] = 'All F',
		[256] = 'Galk.',
		[298] = 'All M',
		[510] = '',
	},

	-- Private-use-area glyph aliases supplied by gameicons.ttf.
	icons = {
		ROLL  = utf8.char(0xEAE9),
		CE    = utf8.char(0xEB09),
		LOOT  = utf8.char(0xE95E),
		HEAL  = utf8.char(0xE70B),
		SPELL = utf8.char(0xE36B),
		CAST  = utf8.char(0xECA4),
		ATK   = utf8.char(0xEC64),
		PARR  = utf8.char(0xE3C6),
		PUM   = utf8.char(0xE23D),
		RA    = utf8.char(0xE1FC),
		TEMP  = utf8.char(0xEB26),
		GIL   = utf8.char(0xEE1B),
		EXP   = utf8.char(0xEEC3),
		LVLUP = utf8.char(0xE4DA),
		KEY   = utf8.char(0xE79C),
		UTSU  = utf8.char(0xEE1E),
		SC    = utf8.char(0xE471),
	},
}

-- ================================================================
-- Equipment helpers
-- ================================================================

utils.GetEquipJobs = function(jobsbytes)
	local jobs = {}
	if jobsbytes == 8388606 then
		table.insert(jobs, 'All Jobs')
	else
		for i = 1, 23 do
			if bit.band(1, bit.rshift(jobsbytes, i)) == 1 then
				table.insert(jobs, utils.equipJobs[i])
			end
		end
	end

	if #jobs == 0 then return '' end
	local out = jobs[1]
	for j = 2, #jobs do
		out = out .. '/' .. jobs[j]
	end
	return out
end

-- ================================================================
-- Win32 clipboard
-- ================================================================

utils.SetClipboardText = function(text)
	if user32.OpenClipboard(nil) == 0 then return end
	if user32.EmptyClipboard() == 0 then
		user32.CloseClipboard()
		return
	end

	local size = ffi.C.strlen(text) + 1
	local hGlobal = kernel32.GlobalAlloc(ffi.C.GMEM_MOVEABLE, size)
	if hGlobal == nil then
		user32.CloseClipboard()
		return
	end

	local pGlobal = kernel32.GlobalLock(hGlobal)
	if pGlobal == nil then
		kernel32.GlobalUnlock(hGlobal)
		user32.CloseClipboard()
		return
	end

	ffi.C.memcpy(pGlobal, text, size)
	kernel32.GlobalUnlock(hGlobal)

	if user32.SetClipboardData(ffi.C.CF_TEXT, hGlobal) == nil then
		user32.CloseClipboard()
		return
	end

	user32.CloseClipboard()
end

-- ================================================================
-- Texture helpers
-- ================================================================

local function LoadTexture(textures, name)
	local texture_ptr = ffi.new('IDirect3DTexture8*[1]')
	local res = C.D3DXCreateTextureFromFileA(d3d8dev, string.format('%s/images/%s.png', addon.path, name), texture_ptr)
	if res ~= C.S_OK then
		error(('Failed to load image texture: %08X (%s)'):fmt(res, d3d.get_error(res)))
	end
	textures[name] = ffi.new('IDirect3DTexture8*', texture_ptr[0])
	d3d.gc_safe_release(textures[name])
end

utils.ItemIcon = function(bitmap, size)
	local texturePtr = ffi.new('IDirect3DTexture8*[1]')
	local createTexture = C.D3DXCreateTextureFromFileInMemoryEx(
		d3d8dev, bitmap, size, 0xFFFFFFFF, 0xFFFFFFFF, 1, 0,
		C.D3DFMT_A8R8G8B8, C.D3DPOOL_MANAGED, C.D3DX_DEFAULT, C.D3DX_DEFAULT,
		0xFF000000, nil, nil, texturePtr)

	if createTexture == C.S_OK then
		return d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', texturePtr[0]))
	end
	return nil
end

utils.ItemIconRelease = function(ptr)
	if ptr then
		d3d.gc_safe_release(ptr)
	end
end

utils.LoadTextures = function()
	local textures = T{}
	LoadTexture(textures, 'border')
	LoadTexture(textures, 'settings')
	LoadTexture(textures, 'guideme')
	LoadTexture(textures, 'logs')
	LoadTexture(textures, 'loading')
	LoadTexture(textures, 'folder')
	LoadTexture(textures, 'compact')
	LoadTexture(textures, 'manual')
	LoadTexture(textures, 'info');
	LoadTexture(textures, 'notepad')
	LoadTexture(textures, 'dumpchat')
	return textures
end

-- ================================================================
-- Color helpers
-- ================================================================

utils.hexToRGBA = function(hex)
	hex = hex:gsub('0x', '')

	local a = tonumber(hex:sub(1, 2), 16)
	local r = tonumber(hex:sub(3, 4), 16)
	local g = tonumber(hex:sub(5, 6), 16)
	local b = tonumber(hex:sub(7, 8), 16)
	return a, r, g, b
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
	return tonumber(ffi.new('uint32_t', packed))
end

-- ================================================================
-- Generic lookup helpers
-- ================================================================

utils.FindInTable = function(sometable, f)
	local idx = 0
	if sometable ~= nil then
		for _, t in pairs(sometable) do
			idx = idx + 1
			if t == f then return idx end
		end
	end
	return nil
end

utils.FindInTableSorted = function(sometable, f)
	local idx = 0
	if sometable ~= nil then
		for _, t in pairs(sometable) do
			idx = idx + 1
			if t == f then return idx end
			if f > t then return false end
		end
	end
	return nil
end

utils.FindInTableFind = function(sometable, f, l)
	local idx = 0
	if sometable ~= nil then
		for _, t in pairs(sometable) do
			idx = idx + 1
			if l == 0 and string.find(t, f, 1, true) then
				return idx
			elseif l > 0 and string.find(t[l], f, 1, true) then
				return idx
			end
		end
	end
	return nil
end

utils.FindInStringTable = function(f, sometable, l)
	local idx = 0
	if sometable ~= nil then
		for _, t in pairs(sometable) do
			idx = idx + 1
			if l == 0 and string.find(f, t, 1, true) then
				return idx
			elseif l > 0 and string.find(f, t[l], 1, true) then
				return idx
			end
		end
	end
	return nil
end

utils.FindInStringTableFilters = function(f, sometable, scope)
	local idx = 0
	local lowerf = string.lower(f)
	if sometable ~= nil then
		for _, t in ipairs(sometable) do
			idx = idx + 1
			if t[2] == '_z' or not t[2]:find(scope) then
				if string.find(lowerf, string.lower(t[1]), 1, false) then
					return idx
				end
			end
		end
	end
	return nil
end

utils.FindLastOf = function(str, chr, s)
	local start = s or 1
	if start < 1 then start = 1 end
	if start > #str then return nil end

	for i = #str, start, -1 do
		if str:byte(i) == chr:byte(1) then
			return i
		end
	end
	return nil
end

utils.FindLastOfString = function(str, str2, s)
	local i = s or 1
	if i < 1 then i = 1 end
	if i > #str then return nil end

	local last
	while true do
		local pos = str:find(str2, i)
		if not pos then return last end
		last = pos
		i = pos + 1
	end
end

utils.FindLastOfMB = function(str, chr)
	local chr_bytes = {chr:byte(1, -1)}
	local chr_len   = #chr_bytes
	local strlen    = #str

	for i = strlen - chr_len + 1, 1, -1 do
		local match = true
		for j = 1, chr_len do
			if str:byte(i + j - 1) ~= chr_bytes[j] then
				match = false
				break
			end
		end
		if match then return i end
	end
	return nil
end

utils.FindFirstOfMB = function(str, chr)
	local chr_bytes = {chr:byte(1, -1)}
	local chr_len   = #chr_bytes
	local strlen    = #str

	for i = 1, strlen - chr_len + 1, 1 do
		local match = true
		for j = 1, chr_len do
			if str:byte(i + j - 1) ~= chr_bytes[j] then
				match = false
				break
			end
		end
		if match then return i end
	end
	return nil
end

utils.findIndexOfValue = function(t, targetValue)
	for index, innerTable in ipairs(t) do
		if type(innerTable) == 'table' then
			for _, value in pairs(innerTable) do
				if value == targetValue then
					return index
				end
			end
		end
	end
	return nil
end

utils.IsInTable = function(t, x)
	for i = 1, #t do
		if t[i] == x then return x end
	end
	return nil
end

utils.StringFindTable = function(s, t, m, e)
	if not m then m = true else m = false end
	if #t == 0 then return nil end
	for i = 1, #t do
		if e and s == t[1] then return 1 end
		local f = string.find(s, t[i], 1, m)
		if f then return f end
	end
	return nil
end

-- ================================================================
-- URL parsing
-- ================================================================

utils.ParseUrlLink = function(text)
	local url = ''
	if not text:find('https') and not text:find('www.') and not text:find('localhost') then
		return url
	end

	local P = '!"$%&\'()*+,./;<=>?@%[\\%]^`{|}'
	local url_pattern = '(([/%s]?)([^%s'..P..'][^%s'..P..'][^%s'..P..']*%.)([^%s'..P..'][^%s'..P..'][^%s'..P..']*%.)([^%s][^%s][^%s]*))'

	local matched, leadingspace, part1, part2, part3 = string.match(
		(text:gsub('https://www.', 'www.')):gsub('https://', 'www.'),
		url_pattern
	)

	if matched then
		local hasletters = part1:match('[A-z]') and part2:match('[A-z]') and part3:match('[A-z]')
		if hasletters and (leadingspace ~= '' or string.find(text, tostring(matched:trimex()), 1, true) == 1) then
			return matched:trimex()
		end
	elseif text:find('localhost') then
		matched = text:match('.*(http://localhost:[^%s]*).*')
		if matched then return matched end
	end
	return ''
end

-- ================================================================
-- Color set import / export
-- ================================================================

utils.ExportColors = function(addonpath, charname, colors)
	local f = assert(io.open(addonpath..'\\colorset_'..charname, 'w'))
	for k, v in pairs(colors) do
		f:write(string.format('%s,%#x\n', k, v[1]))
	end
	f:close()
	local msg = 'Exported colorset to: '..addonpath..'\\colorset_'..charname
	print((msg:gsub('\\\\', '\\')))
end

utils.ImportColors = function(addonpath, charname, colors)
	local cols = {}
	for k, v in pairs(colors) do
		cols[k] = v
	end
	local f = io.open(addonpath..'\\colorset_'..charname, 'r')
	if not f then
		print('colorset file not found')
		return cols
	end
	for line in f:lines() do
		local key, val = line:match('([^,]+),([^,]+)')
		if key and val then
			local num = tonumber(val)
			if num and cols[key] then
				cols[key][1] = num
			end
		end
	end
	f:close()
	return cols
end

-- ================================================================
-- Misc helpers
-- ================================================================

utils.cloneTable = function(t)
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == 'table' then
			copy[k] = utils.cloneTable(v)
		else
			copy[k] = v
		end
	end
	return copy
end

-- ================================================================
-- Marked-color (MC) text helpers
-- Text is annotated inline with sequences of the form
--    \§AARRGGBBç\<text>\§--------ç\
-- which the renderer expands into per-segment colored runs.  These
-- helpers produce, validate and strip those sequences.
-- ================================================================

utils.MC = function(color)
	if color == 'reset' or color == '' then
		return '\\§--------ç\\'
	end
	local colortext = string.format('%08X', tonumber(color))
	return '\\§'..colortext..'ç\\'
end

utils.MCCheck = function(text)
	text = text:gsub('(ç\\)(%s+)(\\§........ç\\)', '%1%3%2')
	local idx = 1
	while true do
		local f1 = string.find(text, '\\§', idx, true)
		if not f1 then break end
		if not string.find(text:sub(f1 + 11, f1 + 13), 'ç\\', 1, true) then
			return 'Bad MC format'
		end
		idx = f1 + 4
	end
	return text
end

utils.cleanMC = function(text)
	return text:gsub('\\§........ç\\', '')
end

-- ================================================================
-- Logs
-- ================================================================

utils.SaveLogs = function(ChatBuffer1, ChatBuffer2, ChatName, PlayerName, AddonPath, TimeStamp)
	local logs_folder = AddonPath..'logs\\'..PlayerName
	os.execute('mkdir '..logs_folder)

	local folder_name = logs_folder..'\\ChatLogs_'..TimeStamp
	os.execute('mkdir '..folder_name)

	local file_name = string.format('%s/'..ChatName..'.txt', folder_name)
	local file = io.open(file_name, 'w')
	if not file then return false end

	if ChatBuffer2 ~= nil then
		local max_rows = math.max(#ChatBuffer1, #ChatBuffer2)
		for i = 1, max_rows do
			local row1 = ChatBuffer1[i] or ''
			local row2 = ChatBuffer2[i] or ''
			file:write(utils.cleanMC(row1)..' '..utils.cleanMC(row2)..'\n')
		end
	else
		local max_rows = math.max(#ChatBuffer1)
		for i = 1, max_rows do
			local row1 = ChatBuffer1[i] or ''
			file:write(utils.cleanMC(row1)..'\n')
		end
	end
	io.close(file)
	return true
end

-- ================================================================
-- FFXI Shift-JIS  →  UTF-8 single-pass transcoder
--
-- The legacy ReplaceCPs / CleanCPs / CPs2text pipeline below stays
-- in place for backwards compat, but the live CleanText path uses
-- TranscodeFFXI which folds all four passes into one byte walk
-- against a flat lookup table.  See lib/parser.lua:CleanTextFunctionNew.
-- ================================================================

-- Codepage map: raw 2-byte FFXI sequence  →  pre-encoded UTF-8 string.
-- Pre-encoding avoids per-call utf8.char() allocations.
utils.FFXI_MAP = {
	-- ---- 0x81 lead: SJIS punctuation + game-specific glyphs ----
	['\x81\x40'] = ' ',                 -- ideographic space → ASCII space
	['\x81\x60'] = '~',                 -- full-width tilde
	['\x81\x61'] = utf8.char(0x2551),   -- ║
	['\x81\x63'] = utf8.char(0x22EF),   -- ⋯
	['\x81\x79'] = utf8.char(0x3010),   -- 【
	['\x81\x7A'] = utf8.char(0x3011),   -- 】
	['\x81\x7E'] = utf8.char(0x2715),   -- ✕  (FFXI: red X marker)
	['\x81\xA6'] = utf8.char(0x25D9),   -- ◙  (FFXI: actor highlight bullet)
	['\x81\xA8'] = utf8.char(0x2192),   -- →
	['\x81\xA9'] = utf8.char(0x2190),   -- ←
	['\x81\xAA'] = utf8.char(0x2191),   -- ↑
	['\x81\xAB'] = utf8.char(0x2193),   -- ↓
	['\x81\x99'] = utf8.char(0x2606),   -- ☆
	['\x81\x9A'] = utf8.char(0x2605),   -- ★  (CEXI custom)
	['\x81\x9C'] = utf8.char(0x0A66),   -- ০  (FFXI: drawn as 'O' in client font)
	['\x81\x9E'] = utf8.char(0x25C7),   -- ◇  (CEXI custom)
	['\x81\x9F'] = utf8.char(0x25C6),   -- ◆  (CEXI custom)
	['\x81\xAC'] = utf8.char(0x2014),   -- —
	['\x81\xF4'] = utf8.char(0x266A),   -- ♪
	-- ---- 0x83 lead ----
	['\x83\xB6'] = utf8.char(0x03A9),   -- Ω
	-- ---- 0x85 lead: currency + degree (Latin-1 range filled below) ----
	['\x85\x40'] = utf8.char(0x20AC),   -- €
	['\x85\x63'] = utf8.char(0x00A3),   -- £
	['\x85\x70'] = utf8.char(0x00B0),   -- °
	-- ---- 0x87 lead: smart quotes ----
	['\x87\xB2'] = utf8.char(0x201C),   -- "
	['\x87\xB3'] = utf8.char(0x201D),   -- "
	-- ---- 0x88 lead ----
	['\x88\x69'] = utf8.char(0x00E9),   -- é
	-- ---- 0xEF lead: auto-translate envelope + elemental labels ----
	['\xEF\x27'] = utf8.char(0x276E),   -- ❮ (auto-translate open)
	['\xEF\x28'] = utf8.char(0x276F),   -- ❯ (auto-translate close)
	['\xEF\x1F'] = '[fire]',
	['\xEF\x20'] = '[ice]',
	['\xEF\x21'] = '[wind]',
	['\xEF\x22'] = '[earth]',
	['\xEF\x23'] = '[lightning]',
	['\xEF\x24'] = '[water]',
	['\xEF\x25'] = '[light]',
	['\xEF\x26'] = '[dark]',
}

-- Latin-1 supplement: \x85\xA0..\xC3 → U+00C1..U+00E4 (Á..ä).
-- Used for accented characters in NPC and zone names.
for tail = 0xA0, 0xC3 do
	local key = string.char(0x85, tail)
	if utils.FFXI_MAP[key] == nil then
		utils.FFXI_MAP[key] = utf8.char(0x00C1 + (tail - 0xA0))
	end
end

-- Bytes that ALWAYS introduce a 2-byte SJIS sequence.  A pair
-- starting with one of these but not present in FFXI_MAP is
-- silently dropped (lead+trail consumed, nothing emitted).
utils.SJIS_LEAD = {}
for b = 0x81, 0x9F do utils.SJIS_LEAD[b] = true end
for b = 0xE0, 0xEF do utils.SJIS_LEAD[b] = true end

-- Compact-combat overrides: glyphs to drop instead of emit.  The
-- arrow is hidden on combat lines because actor→target is conveyed
-- visually by the compact-combat formatter.
utils.FFXI_MAP_COMBAT_DROP = {
	['\x81\x68'] = true,   -- →
}

-- ----------------------------------------------------------------
-- Legacy in-band color escapes  →  FancyChat MC tokens.
--
-- FFXI's native chat protocol has TWO palette tables:
--   chat.color1(N, str) → \x1E\NN ... \x1E\01
--   chat.color2(N, str) → \x1F\NN ... \x1E\01
--
-- legacycolorsOLD: the original 29-entry table seeded from
-- chat.colors's CSS-named subset.  Kept as a fallback / reference
-- only — the live transcoder uses legacycolors and legacycolors2,
-- which were extracted from a screenshot of FFXI rendering every
-- slot natively (see _extract_palette.py).
--
-- legacycolors  : table 1 (\x1E\NN), 37 real palette entries.
-- legacycolors2 : table 2 (\x1F\NN), 114 real palette entries —
--                  the dense table FFXI uses for most message-mode
--                  colours and what addons like simplelog reach for
--                  via chat.color2(N, str).
--
-- Slot 01 in either table is the RESET escape (channel default),
-- mapped to '\\§--------ç\\' so the renderer goes back to whatever
-- buf.color[i] is for the line.
-- ----------------------------------------------------------------
utils.legacycolorsOLD = {
	['\30\01']  = '\\§--------ç\\',  -- Reset / Normal / White (channel default)
	['\30\02']  = '\\§FF7CFC00ç\\',  -- LawnGreen
	['\30\03']  = '\\§FF7B68EEç\\',  -- MediumSlateBlue
	['\30\05']  = '\\§FFFF00FFç\\',  -- Magenta
	['\30\06']  = '\\§FF00FFFFç\\',  -- Cyan
	['\30\07']  = '\\§FFFFE4B5ç\\',  -- Moccasin
	['\30\08']  = '\\§FFFF7F50ç\\',  -- Coral
	['\30\65']  = '\\§FF696969ç\\',  -- DimGrey
	['\30\67']  = '\\§FF808080ç\\',  -- Grey
	['\30\68']  = '\\§FFFA8072ç\\',  -- Salmon
	['\30\69']  = '\\§FFFFFF00ç\\',  -- Yellow
	['\30\71']  = '\\§FF4169E1ç\\',  -- RoyalBlue
	['\30\72']  = '\\§FF8B008Bç\\',  -- DarkMagenta
	['\30\73']  = '\\§FFEE82EEç\\',  -- Violet
	['\30\76']  = '\\§FFFF6347ç\\',  -- Tomato
	['\30\77']  = '\\§FFFFE4E1ç\\',  -- MistyRose
	['\30\78']  = '\\§FFEEE8AAç\\',  -- PaleGoldenRod
	['\30\79']  = '\\§FF00FF00ç\\',  -- Lime
	['\30\80']  = '\\§FF98FB98ç\\',  -- PaleGreen
	['\30\81']  = '\\§FF9932CCç\\',  -- DarkOrchid
	['\30\82']  = '\\§FF00FFFFç\\',  -- Aqua  (same RGB as Cyan)
	['\30\83']  = '\\§FF00FF7Fç\\',  -- SpringGreen
	['\30\85']  = '\\§FFE9967Aç\\',  -- DarkSalmon
	['\30\88']  = '\\§FF00FA9Aç\\',  -- MediumSpringGreen
	['\30\89']  = '\\§FF9370DBç\\',  -- MediumPurple
	['\30\90']  = '\\§FFF0FFFFç\\',  -- Azure
	['\30\92']  = '\\§FFE0FFFFç\\',  -- LightCyan
	['\30\96']  = '\\§FFFAFAD2ç\\',  -- LightGoldenRodYellow
	['\30\105'] = '\\§FFDDA0DDç\\',  -- Plum
}

-- legacycolors: 38 entries (RESET + 37 real palette slots; slots not listed = uncoloured / channel default)
utils.legacycolors = {
	['\30\01']  = '\\§--------ç\\',  -- RESET (channel default)
	['\30\02']  = '\\§FF5CFF28ç\\',  -- ( 92,255, 40)
	['\30\03']  = '\\§FF6769FCç\\',  -- (103,105,252)
	['\30\04']  = '\\§FF676AFCç\\',  -- (103,106,252)
	['\30\05']  = '\\§FFFD41E8ç\\',  -- (253, 65,232)
	['\30\06']  = '\\§FF2DEBFFç\\',  -- ( 45,235,255)
	['\30\07']  = '\\§FFFAC29Eç\\',  -- (250,194,158)
	['\30\08']  = '\\§FFFF8666ç\\',  -- (255,134,102)
	['\30\68']  = '\\§FFFF5B88ç\\',  -- (255, 91,136)
	['\30\69']  = '\\§FFFFFF4Bç\\',  -- (255,255, 75)
	['\30\70']  = '\\§FF7F9AFFç\\',  -- (127,154,255)
	['\30\71']  = '\\§FF476CFFç\\',  -- ( 71,108,255)
	['\30\72']  = '\\§FFD328FFç\\',  -- (211, 40,255)
	['\30\73']  = '\\§FFE369FFç\\',  -- (227,105,255)
	['\30\76']  = '\\§FFFF3252ç\\',  -- (255, 50, 82)
	['\30\79']  = '\\§FF10FF2Dç\\',  -- ( 16,255, 45)
	['\30\81']  = '\\§FF6630FFç\\',  -- (102, 48,255)
	['\30\82']  = '\\§FF37FFEFç\\',  -- ( 55,255,239)
	['\30\83']  = '\\§FF24FF7Bç\\',  -- ( 36,255,123)
	['\30\85']  = '\\§FFF37B89ç\\',  -- (243,123,137)
	['\30\86']  = '\\§FFDF63FEç\\',  -- (223, 99,254)
	['\30\87']  = '\\§FF37FFEFç\\',  -- ( 55,255,239)
	['\30\89']  = '\\§FF8C79FDç\\',  -- (140,121,253)
	['\30\92']  = '\\§FF78ACF9ç\\',  -- (120,172,249)
	['\30\93']  = '\\§FFFB6B8Dç\\',  -- (251,107,141)
	['\30\98']  = '\\§FF7B8FDFç\\',  -- (123,143,223)
	['\30\102'] = '\\§FFF5CE8Eç\\',  -- (245,206,142)
	['\30\104'] = '\\§FFFFFC4Dç\\',  -- (255,252, 77)
	['\30\105'] = '\\§FFB962E6ç\\',  -- (185, 98,230)
	['\30\106'] = '\\§FFF8FE8Fç\\',  -- (248,254,143)
	['\30\107'] = '\\§FFFFFF88ç\\',  -- (255,255,136)
	['\30\108'] = '\\§FFF56D76ç\\',  -- (245,109,118)
	['\30\109'] = '\\§FFFFD175ç\\',  -- (255,209,117)
	['\30\110'] = '\\§FF8AFF4Bç\\',  -- (138,255, 75)
	['\30\111'] = '\\§FF10FF2Fç\\',  -- ( 16,255, 47)
	['\30\112'] = '\\§FF10A3FFç\\',  -- ( 16,163,255)
	['\30\113'] = '\\§FF10DFFFç\\',  -- ( 16,223,255)
	['\30\143'] = '\\§FFFF48E5ç\\',  -- (255, 72,229)
}

-- legacycolors2: 115 entries (RESET + 114 real palette slots; slots not listed = uncoloured / channel default)
utils.legacycolors2 = {
	['\31\01']  = '\\§--------ç\\',  -- RESET (channel default)
	['\31\02']  = '\\§FFF98899ç\\',  -- (249,136,153)
	['\31\03']  = '\\§FFF96F82ç\\',  -- (249,111,130)
	['\31\04']  = '\\§FFD75EFEç\\',  -- (215, 94,254)
	['\31\05']  = '\\§FF3AFFFAç\\',  -- ( 58,255,250)
	['\31\07']  = '\\§FF8872FEç\\',  -- (136,114,254)
	['\31\08']  = '\\§FFE07AFFç\\',  -- (224,122,255)
	['\31\10']  = '\\§FFE9778Fç\\',  -- (233,119,143)
	['\31\11']  = '\\§FFF96F82ç\\',  -- (249,111,130)
	['\31\12']  = '\\§FFD75EFEç\\',  -- (215, 94,254)
	['\31\13']  = '\\§FF3AFFFAç\\',  -- ( 58,255,250)
	['\31\15']  = '\\§FF8872FEç\\',  -- (136,114,254)
	['\31\16']  = '\\§FFC166F5ç\\',  -- (193,102,245)
	['\31\17']  = '\\§FFA5C9F6ç\\',  -- (165,201,246)
	['\31\18']  = '\\§FFA5C9F6ç\\',  -- (165,201,246)
	['\31\20']  = '\\§FFFFAFD8ç\\',  -- (255,175,216)
	['\31\22']  = '\\§FF8094EDç\\',  -- (128,148,237)
	['\31\23']  = '\\§FF8094EDç\\',  -- (128,148,237)
	['\31\24']  = '\\§FF8094EDç\\',  -- (128,148,237)
	['\31\25']  = '\\§FFFFAFD8ç\\',  -- (255,175,216)
	['\31\27']  = '\\§FF8094EDç\\',  -- (128,148,237)
	['\31\28']  = '\\§FFF46D98ç\\',  -- (244,109,152)
	['\31\30']  = '\\§FF80B5FFç\\',  -- (128,181,255)
	['\31\31']  = '\\§FF80B5FFç\\',  -- (128,181,255)
	['\31\32']  = '\\§FFFFAFD8ç\\',  -- (255,175,216)
	['\31\34']  = '\\§FF8194EEç\\',  -- (129,148,238)
	['\31\35']  = '\\§FF8194EEç\\',  -- (129,148,238)
	['\31\36']  = '\\§FFFFFB59ç\\',  -- (255,251, 89)
	['\31\38']  = '\\§FFFD528Bç\\',  -- (253, 82,139)
	['\31\39']  = '\\§FFFF2D59ç\\',  -- (255, 45, 89)
	['\31\42']  = '\\§FF8BACFBç\\',  -- (139,172,251)
	['\31\43']  = '\\§FF8194EEç\\',  -- (129,148,238)
	['\31\50']  = '\\§FFFFFB5Aç\\',  -- (255,251, 90)
	['\31\51']  = '\\§FFFFFB5Aç\\',  -- (255,251, 90)
	['\31\52']  = '\\§FFFFFB5Aç\\',  -- (255,251, 90)
	['\31\55']  = '\\§FFFFFB5Aç\\',  -- (255,251, 90)
	['\31\58']  = '\\§FFFFFB5Aç\\',  -- (255,251, 90)
	['\31\62']  = '\\§FFFFFB5Aç\\',  -- (255,251, 90)
	['\31\63']  = '\\§FFF1CA98ç\\',  -- (241,202,152)
	['\31\66']  = '\\§FFFFFB5Bç\\',  -- (255,251, 91)
	['\31\67']  = '\\§FFFFD8A1ç\\',  -- (255,216,161)
	['\31\68']  = '\\§FFFFD8A1ç\\',  -- (255,216,161)
	['\31\69']  = '\\§FFFFCF9Dç\\',  -- (255,207,157)
	['\31\80']  = '\\§FFFDFF5Aç\\',  -- (253,255, 90)
	['\31\83']  = '\\§FFFFFB5Cç\\',  -- (255,251, 92)
	['\31\85']  = '\\§FFFFFB5Cç\\',  -- (255,251, 92)
	['\31\88']  = '\\§FFFFFB5Cç\\',  -- (255,251, 92)
	['\31\90']  = '\\§FFFFFB5Cç\\',  -- (255,251, 92)
	['\31\93']  = '\\§FFFFFB5Cç\\',  -- (255,251, 92)
	['\31\100'] = '\\§FFFFFF5Dç\\',  -- (255,255, 93)
	['\31\103'] = '\\§FFFFFF5Dç\\',  -- (255,255, 93)
	['\31\105'] = '\\§FFFFFF5Dç\\',  -- (255,255, 93)
	['\31\108'] = '\\§FFFFFF5Dç\\',  -- (255,255, 93)
	['\31\110'] = '\\§FFFFFF5Dç\\',  -- (255,255, 93)
	['\31\113'] = '\\§FFFFFF5Eç\\',  -- (255,255, 94)
	['\31\121'] = '\\§FFFEFEA5ç\\',  -- (254,254,165)
	['\31\122'] = '\\§FFFFFF5Eç\\',  -- (255,255, 94)
	['\31\123'] = '\\§FFFB5B98ç\\',  -- (251, 91,152)
	['\31\124'] = '\\§FFFB5B98ç\\',  -- (251, 91,152)
	['\31\125'] = '\\§FFFB5B98ç\\',  -- (251, 91,152)
	['\31\126'] = '\\§FFFB5B98ç\\',  -- (251, 91,152)
	['\31\127'] = '\\§FFFEFEA5ç\\',  -- (254,254,165)
	['\31\128'] = '\\§FFFEFEA5ç\\',  -- (254,254,165)
	['\31\129'] = '\\§FFFFFFA5ç\\',  -- (255,255,165)
	['\31\130'] = '\\§FFFFFFA7ç\\',  -- (255,255,167)
	['\31\131'] = '\\§FFFFFFA7ç\\',  -- (255,255,167)
	['\31\132'] = '\\§FFFFFFA7ç\\',  -- (255,255,167)
	['\31\133'] = '\\§FFFFFFA7ç\\',  -- (255,255,167)
	['\31\134'] = '\\§FFFFFFA7ç\\',  -- (255,255,167)
	['\31\135'] = '\\§FFFFFFA7ç\\',  -- (255,255,167)
	['\31\136'] = '\\§FFFFFFA7ç\\',  -- (255,255,167)
	['\31\137'] = '\\§FFFFFFA7ç\\',  -- (255,255,167)
	['\31\138'] = '\\§FFFFFFA7ç\\',  -- (255,255,167)
	['\31\139'] = '\\§FFFFFFA7ç\\',  -- (255,255,167)
	['\31\140'] = '\\§FFFFFFA5ç\\',  -- (255,255,165)
	['\31\141'] = '\\§FFFFFF5Fç\\',  -- (255,255, 95)
	['\31\154'] = '\\§FFFFFF5Fç\\',  -- (255,255, 95)
	['\31\155'] = '\\§FFFFFF5Fç\\',  -- (255,255, 95)
	['\31\156'] = '\\§FFFFFF5Fç\\',  -- (255,255, 95)
	['\31\158'] = '\\§FF16FF41ç\\',  -- ( 22,255, 65)
	['\31\159'] = '\\§FFFFFF5Fç\\',  -- (255,255, 95)
	['\31\162'] = '\\§FF8196F1ç\\',  -- (129,150,241)
	['\31\165'] = '\\§FF8196F1ç\\',  -- (129,150,241)
	['\31\167'] = '\\§FFFF3667ç\\',  -- (255, 54,103)
	['\31\168'] = '\\§FFFFFF60ç\\',  -- (255,255, 96)
	['\31\169'] = '\\§FFFFFF60ç\\',  -- (255,255, 96)
	['\31\170'] = '\\§FFFACFA6ç\\',  -- (250,207,166)
	['\31\171'] = '\\§FFFFFF60ç\\',  -- (255,255, 96)
	['\31\172'] = '\\§FFFFFF60ç\\',  -- (255,255, 96)
	['\31\177'] = '\\§FFFFF860ç\\',  -- (255,248, 96)
	['\31\179'] = '\\§FFFFF860ç\\',  -- (255,248, 96)
	['\31\180'] = '\\§FFFFFC60ç\\',  -- (255,252, 96)
	['\31\187'] = '\\§FF8296F2ç\\',  -- (130,150,242)
	['\31\188'] = '\\§FF8296F2ç\\',  -- (130,150,242)
	['\31\189'] = '\\§FFFDD2A1ç\\',  -- (253,210,161)
	['\31\200'] = '\\§FF532CF9ç\\',  -- ( 83, 44,249)
	['\31\201'] = '\\§FF532CF9ç\\',  -- ( 83, 44,249)
	['\31\204'] = '\\§FF17FF44ç\\',  -- ( 23,255, 68)
	['\31\206'] = '\\§FFFFFFA1ç\\',  -- (255,255,161)
	['\31\207'] = '\\§FF6C7DEFç\\',  -- (108,125,239)
	['\31\208'] = '\\§FF8C75FFç\\',  -- (140,117,255)
	['\31\209'] = '\\§FF5027F6ç\\',  -- ( 80, 39,246)
	['\31\210'] = '\\§FF40FFFFç\\',  -- ( 64,255,255)
	['\31\211'] = '\\§FFFDB781ç\\',  -- (253,183,129)
	['\31\212'] = '\\§FFFDB781ç\\',  -- (253,183,129)
	['\31\213'] = '\\§FF75FD54ç\\',  -- (117,253, 84)
	['\31\214'] = '\\§FF75FD54ç\\',  -- (117,253, 84)
	['\31\215'] = '\\§FF17FF45ç\\',  -- ( 23,255, 69)
	['\31\216'] = '\\§FF17FF45ç\\',  -- ( 23,255, 69)
	['\31\217'] = '\\§FF75FD54ç\\',  -- (117,253, 84)
	['\31\218'] = '\\§FF17FF45ç\\',  -- ( 23,255, 69)
	['\31\219'] = '\\§FF177DFFç\\',  -- ( 23,125,255)
	['\31\220'] = '\\§FF177DFFç\\',  -- ( 23,125,255)
	['\31\221'] = '\\§FF17A8FFç\\',  -- ( 23,168,255)
	['\31\222'] = '\\§FF17A8FFç\\',  -- ( 23,168,255)
}

-- Single-pass byte walker.  Pure (no state access) so it's safe to
-- call from any context.  Per-byte classification:
--   0x1E / 0x1F     — legacy palette color escape (\x1E\NN /
--                     \x1F\NN, FFXI's two palette tables); drop
--                     the 2 bytes by default, OR PRESERVE them
--                     verbatim when respectLegacyColors=true so a
--                     downstream wrap-aware step can later turn
--                     them into 14-byte MC tokens (see parser.lua).
--   0x7F            — timed-message sentinel, drop 2 or 3 bytes
--   0x20-0x7E       — printable ASCII, emit verbatim
--   SJIS_LEAD       — try FFXI_MAP[lead..trail], drop pair if absent
--   >= 0xF0         — pre-existing UTF-8 (e.g. heart emoji); pass
--                     through with its 3 trail bytes
--   anything else   — drop
--
-- We deliberately do NOT inline the MC translation here even when
-- respectLegacyColors is on.  An MC token is 14 bytes; the chat-line
-- wrap math in parseThis cuts on raw byte indices and would slice
-- right through one if it landed inside.  Keeping the 2-byte legacy
-- escapes intact lets the wrap survive (worst case is a single split
-- escape, recovered by the post-wrap translation step).
utils.TranscodeFFXI = function(text, compactCombat, respectLegacyColors)
	local map      = utils.FFXI_MAP
	local lead_set = utils.SJIS_LEAD
	local drop_set = compactCombat and utils.FFXI_MAP_COMBAT_DROP or nil
	local sbyte    = string.byte
	local ssub     = string.sub
	local schar    = string.char

	local out, n = {}, 0
	local i, len = 1, #text

	while i <= len do
		local b = sbyte(text, i)

		if b == 0x1E or b == 0x1F then
			if respectLegacyColors then
				n = n + 1
				out[n] = ssub(text, i, i + 1)
			end
			i = i + 2

		elseif b == 0x7F then
			local b2 = sbyte(text, i + 1) or 0
			if b2 >= 0x31 and b2 <= 0x37 then
				local b3 = sbyte(text, i + 2) or 0
				if b3 >= 0x01 and b3 <= 0x06 then
					i = i + 3
				else
					i = i + 2
				end
			else
				i = i + 2
			end

		elseif b >= 0x20 and b <= 0x7E then
			n = n + 1
			out[n] = schar(b)
			i = i + 1

		elseif lead_set[b] then
			local pair = ssub(text, i, i + 1)
			if not (drop_set and drop_set[pair]) then
				local mapped = map[pair]
				if mapped then
					n = n + 1
					out[n] = mapped
				end
			end
			i = i + 2

		elseif b >= 0xF0 then
			n = n + 1
			out[n] = ssub(text, i, i + 3)
			i = i + 4

		else
			i = i + 1
		end
	end

	return table.concat(out)
end

-- Translate any preserved 2-byte legacy color escapes (\x1E\NN or
-- \x1F\NN, FFXI's two palette tables) in a single chat line into
-- 14-byte MC tokens.  Caller invokes this AFTER the line has been
-- wrapped/cut to its display width so the MC tokens never end up
-- split across a line boundary.
--
-- Carries colour state across consecutive lines.  When FFXI's
-- protocol opens a colour on line N and the message wraps before
-- a closing escape, line N+1 should still display in that colour.
-- The renderer treats each chat line as an independent draw, so
-- we have to actively re-prepend the opener on every continuation
-- line — that's what active_color is for.
--
-- Args:
--   line          — the wrapped chat line (with \x1E\NN escapes still
--                   embedded as 2 bytes).
--   active_color  — the MC opener that was active at the END of the
--                   previous wrapped line, or nil if none.
--
-- Returns:
--   translated_line  — the line with all escapes converted to MC
--                      tokens, plus a leading opener if a colour
--                      was inherited and a trailing reset so colour
--                      state can't bleed past the line at render time.
--   new_active_color — the MC opener (or nil) to inherit on the
--                      next continuation line.  Reset escapes
--                      (\x1E\01) and resets generally clear it.
utils.translateLegacyColors = function(line, active_color)
	local legacy1 = utils.legacycolors    -- \x1E\NN  (chat.color1)
	local legacy2 = utils.legacycolors2   -- \x1F\NN  (chat.color2)
	local RESET   = '\\§--------ç\\'

	local last_emitted = nil

	-- Translate each \x1E\NN to MC token from table 1.
	line = line:gsub('\30(.)', function(slot)
		local mc = legacy1['\30' .. slot]
		if mc then
			last_emitted = mc
			return mc
		end
		return ''
	end)
	-- Translate each \x1F\NN to MC token from table 2.
	line = line:gsub('\31(.)', function(slot)
		local mc = legacy2['\31' .. slot]
		if mc then
			last_emitted = mc
			return mc
		end
		return ''
	end)
	-- Strip any leftover lone \x1E or \x1F (wrap-split half of an escape).
	line = line:gsub('[\30\31]', '')

	-- Compute the new active colour to carry forward:
	--   • If the line ended on a non-reset opener → that opener.
	--   • If the line ended on the reset token   → no active colour.
	--   • If the line had no escape at all       → inherit from previous.
	local new_active
	if last_emitted then
		if last_emitted == RESET then
			new_active = nil
		else
			new_active = last_emitted
		end
	else
		new_active = active_color
	end

	-- Prepend the inherited opener so this line starts in the
	-- correct colour even though the original opener was on the
	-- previous wrapped line.
	local prepend = active_color or ''

	-- Always close at line end if anything coloured was on this
	-- line (inherited OR newly-opened).  Renderer-side, each line
	-- is a separate draw so colour state would otherwise bleed.
	local close = ''
	if active_color or last_emitted then
		close = RESET
	end

	return prepend .. line .. close, new_active
end

-- ================================================================
-- Legacy codepoint table cleanup / replacement (kept for backwards
-- compatibility; not used by the live CleanText path anymore).
-- ================================================================

utils.ReplaceCPs = function(main_table)
	local i = 1
	local ext = 0
	local replacement_rules = {}

	-- True if the codepoint sequence at 'i' matches 'pattern'.
	-- Side-effect: sets 'ext' for negative-replacement substitutions.
	local function matches_pattern(t, idx, pattern)
		ext = 0
		local adj = 0
		for j = 1, #pattern do
			if pattern[j] ~= -1 and pattern[j] < 1000 then
				if t[idx + j - 1 - adj] ~= pattern[j] then
					return false
				end
			else
				if pattern[j] < 2000 and pattern[j] >= 1000 and pattern[j - 1] < 1000 then
					if t[idx + j - 1 - adj] < pattern[j] - 1000 or t[idx + j - 1 - adj] > pattern[j + 1] - 1000 then
						return false
					else
						ext = -(1000 + t[idx + j - 1 - adj])
					end
				else
					if pattern[j] < 2000 and pattern[j - 1] < 2000 and pattern[j] >= 1000 and pattern[j - 1] >= 1000 then
						adj = adj + 1
					else
						if pattern[j] >= 2000 then
							if t[idx + j - 1 - adj] == nil
								or t[idx + j - 1 - adj] < pattern[j] - (1000 * (math.floor(pattern[j] / 1000)))
								or t[idx + j - 1 - adj] > (pattern[j] - (1000 * (math.floor(pattern[j] / 1000)))) + (math.floor(pattern[j] / 1000) - 1) then
								return false
							end
						else
							-- Wildcard: only matches positive codepoints.
							if t[idx + j - 1 - adj] == nil or t[idx + j - 1 - adj] < 0 then
								return false
							end
						end
					end
				end
			end
		end
		return true
	end

	local function replace_pattern(t, idx, pattern_length, replacement)
		for _ = 1, pattern_length do
			table.remove(t, idx)
		end
		for j = #replacement, 1, -1 do
			if replacement[j] > -1000 then
				table.insert(t, idx, replacement[j])
			else
				table.insert(t, idx, ext)
			end
		end
	end

	while i <= #main_table do
		local matched = false

		if main_table[i] == 127 then
			replacement_rules = utils.badStrings.p127
		elseif main_table[i] >= 129 and main_table[i] <= 136 then
			replacement_rules = utils.badStrings.p129136
		elseif main_table[i] == 239 then
			replacement_rules = utils.badStrings.p239
		else
			replacement_rules = utils.badStrings.pOther
		end
		if not replacement_rules then replacement_rules = {} end

		for _, rule_pair in ipairs(replacement_rules) do
			local pattern = rule_pair[1]
			local replacement = rule_pair[2]

			if matches_pattern(main_table, i, pattern) then
				local p = 0
				for P_i = 1, #pattern do
					if pattern[P_i] < 2000 and pattern[P_i] > p then
						p = pattern[P_i]
					end
				end
				local l
				if p >= 1000 then l = #pattern - 1 else l = #pattern end
				replace_pattern(main_table, i, l, replacement)
				matched = true
			end
		end

		if not matched then
			i = i + 1
		end
	end

	return main_table
end

utils.CPs2text = function(input_table, utf8_list)
	local result = {}
	local extra_bytes = 0
	for _, value in ipairs(input_table) do
		if extra_bytes > 0 then
			extra_bytes = extra_bytes - 1
			table.insert(result, string.char(value))
		elseif value >= 32 and value <= 126 then
			table.insert(result, string.char(value))
		elseif value < -1 and value > -1000 then
			local index = -value - 1
			if utf8_list[index] then
				table.insert(result, utf8.char(utf8_list[index]))
			end
		elseif value < -1000 then
			if value <= -1159 then
				local offset = -1 * (value + 1000) - 160
				table.insert(result, utf8.char(0x00C1 + offset))
			end
		elseif value >= 0xF0 then
			table.insert(result, string.char(value))
			extra_bytes = 3
		end
	end
	return table.concat(result)
end

utils.utf8split = function(input_str, split_index)
	if split_index <= 0 then
		return 0
	elseif split_index > #input_str then
		return #input_str
	end

	local i = split_index
	while i > 0 do
		local b = input_str:byte(i)
		if b < 0x80 then
			return i - 1
		elseif b >= 0xC2 and b <= 0xDF then
			if split_index >= i + 1 then return i - 1 end
		elseif b >= 0xE0 and b <= 0xEF then
			if split_index >= i + 2 then return i - 1 end
		elseif b >= 0xF0 and b <= 0xF4 then
			if split_index >= i + 3 then return i - 1 end
		end
		i = i - 1
	end
	return 0
end

utils.CleanCPs = function(main_table)
	local function is_ascii(cp)
		return cp >= 32 and cp <= 126
	end

	local function is_timed_message(cp1, cp2, cp3)
		return cp1 == 127 and (cp2 >= 49 and cp2 <= 55) and (cp3 >= 1 and cp3 <= 6)
	end

	local function is_shiftjis_multibyte_start(cp)
		return (cp >= 129 and cp <= 159) or (cp >= 224 and cp <= 239) or (cp == 127)
	end

	local function is_shiftjis_multibyte_continuation(cp)
		return cp >= 0 and cp <= 252
	end

	local function is_utf32(cp)
		return cp >= 0xF0
	end

	local i = 1
	while i <= #main_table do
		local value = main_table[i]
		if value >= 0 then
			if is_ascii(value) then
				i = i + 1
			elseif is_utf32(value) then
				i = i + 4
			elseif i < #main_table - 1 and is_timed_message(main_table[i], main_table[i + 1], main_table[i + 2]) then
				table.remove(main_table, i)
				table.remove(main_table, i + 1)
				table.remove(main_table, i + 2)
			elseif is_shiftjis_multibyte_start(value) and i < #main_table and is_shiftjis_multibyte_continuation(main_table[i + 1]) then
				table.remove(main_table, i)
				table.remove(main_table, i)
			else
				table.remove(main_table, i)
			end
		else
			i = i + 1
		end
	end
	return main_table
end

-- ================================================================
-- Walkthrough HTML -> plain text
-- ================================================================

local function processTable(tableContent)
	local rows = {}
	local colWidths = {}

	for row in tableContent:gmatch('<tr.->(.-)</tr>') do
		local cells = {}
		for cell in row:gmatch('<t[dh].->(.-)</t[dh]>') do
			local cleanCell = cell:gsub('<.->', ''):gsub('^%s*(.-)%s*$', '%1')
			table.insert(cells, cleanCell)
			colWidths[#cells] = math.max(colWidths[#cells] or 0, #cleanCell)
		end
		table.insert(rows, cells)
	end

	local output = {}
	for i, row in ipairs(rows) do
		local formattedRow = {}
		for j, cell in ipairs(row) do
			formattedRow[j] = cell..string.rep(' ', colWidths[j] - #cell)
		end
		table.insert(output, '| '..table.concat(formattedRow, ' | ')..' |')

		if i == 1 then
			table.insert(output, '-'..string.rep('-', #output[#output] - 2)..'-')
		end
	end
	return '\n'..table.concat(output, '\n')..'\n'
end

utils.GetWalkthrough = function(str)
	str = str:gsub('<h1>(.-)</h1>', function(text)
		return '\n['..text:upper()..']\n'
	end)

	str = str:gsub('<h2.->(.-)</h2>', function(text)
		return '\n['..text:gsub('<[^>]*>', '')..']\n'
	end)

	str = str:gsub('<h3>(.-)</h3>', function(text)
		return '\n> '..text..'\n'
	end)

	str = str:gsub('<h4>(.-)</h4>', '')
	str = str:gsub('<ul class="gallery mw%-gallery%-traditional">.-</ul>', '')
	str = str:gsub('<p>', '\n\n')
	str = str:gsub('<br%s*/?>', '\n')
	str = str:gsub('<div.->', '\n\n')

	str = str:gsub('<figure.->.-</figure>', '')
	str = str:gsub('<div class="thumbcaption".->.-</div>', '')
	str = str:gsub('<caption.->.-</caption>', '')

	local num = 0
	str = str:gsub('<ol>(.-)</ol>', function(list)
		num = 0
		return list:gsub('<li>(.-)</li>', function(item)
			num = num + 1
			return '\n  '..num..'. '..item
		end)
	end)

	str = str:gsub('<ul>(.-)</ul>', function(list)
		return list:gsub('<li>(.-)</li>', '\n    - %1')
	end)

	str = str:gsub('%[%d+%]', '')
	str = str:gsub('%[citation needed%]', '')
	str = str:gsub('%[edit%]', '')

	str = str:gsub('<a[^>]->(.-)</a>', function(linkText)
		return linkText:gsub('%[.-%]', '')
	end)

	str = str:gsub('<span class="mw-editsection.-</span>', '')
	str = str:gsub('<table.->(.-)</table>', processTable)

	str = str:gsub('<.->', '')
	str = str:gsub('&nbsp;', ' ')
	str = str:gsub('&amp;', '&')
	str = str:gsub('&gt;', '>')
	str = str:gsub('&#.-;', '')

	str = str:gsub('%[%]', '')
	str = str:gsub('\n\n+', '\n\n')

	return str
end

-- ================================================================
-- UTF-8 byte-counting
-- ================================================================

utils.CountExtraBytesT = function(s)
	local i = 1
	local len = #s
	local ebTable = {}
	local extra_bytes = 0

	while i <= len do
		local b = s:byte(i)

		if (b == 0x1E or b == 0x1F) and i + 1 <= len then
			-- Legacy FFXI in-band colour escape \x1E\NN / \x1F\NN:
			-- 2 bytes but 0 visible columns.  The escape's bytes
			-- are charged to extra_bytes so the wrap budget skips
			-- them, but no entry is added to ebTable (it doesn't
			-- occupy a screen position).
			extra_bytes = extra_bytes + 2
			i = i + 2

		elseif b < 0x80 then
			-- ASCII: 1 byte
			table.insert(ebTable, extra_bytes)
			i = i + 1

		elseif b >= 0xC2 and b <= 0xDF then
			-- 2-byte sequence
			if i + 1 <= len and bit.band(s:byte(i + 1), 0xC0) == 0x80 then
				extra_bytes = extra_bytes + 1
				i = i + 2
			else
				i = i + 1
			end
			table.insert(ebTable, extra_bytes)

		elseif b >= 0xE0 and b <= 0xEF then
			-- 3-byte sequence
			if i + 2 <= len
				and bit.band(s:byte(i + 1), 0xC0) == 0x80
				and bit.band(s:byte(i + 2), 0xC0) == 0x80 then
				extra_bytes = extra_bytes + 2
				-- Specific narrow-width emojis are tracked as 1 extra byte,
				-- not 2, so the on-screen column count matches their glyph.
				if b == 0xE2 then
					if (s:byte(i + 1) == 0x98 and (s:byte(i + 2) == 0x85 or s:byte(i + 2) == 0x86))
						or (s:byte(i + 1) == 0x97 and (s:byte(i + 2) == 0x86 or s:byte(i + 2) == 0x87))
						or (s:byte(i + 1) == 0x9D and  s:byte(i + 2) == 0xA4)
						or (s:byte(i + 1) == 0x9C and  s:byte(i + 2) == 0x97) then
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
			if i + 3 <= len
				and bit.band(s:byte(i + 1), 0xC0) == 0x80
				and bit.band(s:byte(i + 2), 0xC0) == 0x80
				and bit.band(s:byte(i + 3), 0xC0) == 0x80 then
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

-- ================================================================
-- Line-wrapping helpers
-- ================================================================

utils.breakLine = function(text, size)
	if not text or #text < 1 then return '' end

	local idx = 1
	local parts = {}
	local guard = 0

	while idx < #text and guard < 100 do
		local chunk = text:sub(idx, idx + size)
		local n = text:find('\n', idx, true)

		if n and n + 1 < idx + size then
			table.insert(parts, chunk:sub(1, n - idx))
			idx = n + 1
		elseif #chunk < size then
			table.insert(parts, chunk)
			idx = idx + size + 1
		else
			local last_space = utils.FindLastOf(chunk, ' ')
			if not last_space then
				table.insert(parts, chunk)
				idx = idx + size + 1
			else
				table.insert(parts, chunk:sub(1, last_space - 1))
				idx = idx + last_space
			end
		end
		guard = guard + 1
	end

	return table.concat(parts, '\n')
end

utils.CalcRows = function(text, line_width, char_size)
	local chars_in_line = math.floor(line_width / char_size + 1e-6)
	local lines_tot = 0

	while #text > chars_in_line do
		local n = text:find('\n')
		if n and n <= chars_in_line then
			lines_tot = lines_tot + 1
			text = text:sub(n + 1, #text)
		else
			local last_space = utils.FindLastOf(text:sub(1, chars_in_line), ' ')
			if not last_space then last_space = chars_in_line end
			lines_tot = lines_tot + 1
			text = text:sub(last_space + 1, #text)
		end
	end

	-- Count an extra line for each remaining \n.
	local idx = 1
	while idx and idx > 0 do
		idx = text:find('\n', idx + 1, true)
		if idx then
			lines_tot = lines_tot + 1
		end
	end

	-- Final remainder.
	lines_tot = lines_tot + 1
	return lines_tot
end

-- LuaJIT 2.1 mis-compiles CalcRows once the trace recorder picks up its
-- while-loop / `text = text:sub(...)` rewriting body: the JIT'd trace
-- returns inconsistent results across consecutive calls with identical
-- inputs (verified — same bytes, same hash, r1 != r2 in the same
-- frame).  That makes item-hover popups resize themselves a few frames
-- after first appearing.  Pinning the function to the interpreter
-- sidesteps the bug; flush evicts any trace the recorder built before
-- this point.  Cost is negligible — only called while a tooltip is up.
if jit and jit.off then
	jit.off(utils.CalcRows, true)
	if jit.flush then jit.flush(utils.CalcRows, true) end
end

-- ================================================================
-- Custom-filter file loader
-- ================================================================

utils.LoadCustomFilters = function()
	local custmFilters = T{}

	local f = io.open(addon.path..'/custom_combat_filters.txt', 'rb')
	if f == nil then
		error('Failed to load abilities list.')
	end
	for line in f:lines() do
		if line:sub(1, 2) ~= '##' and not line:match('^%s*\n?$') then
			local p2 = line:find('%_')
			if p2 then
				local l1 = line:sub(1, p2 - 1)
				local l2 = line:sub(p2, #line)
				table.insert(custmFilters, {l1:trimex(), l2:trimex()})
			else
				table.insert(custmFilters, {line:trimex(), '_z'})
			end
		end
	end
	f:close()
	return custmFilters
end

-- ================================================================
-- Shift-JIS reverse pass
-- ================================================================

utils.RevertShiftJIS = function(text)
	for i = 1, #utils.ShiftJISback do
		local char = utf8.char(utils.ShiftJISback[i][1])
		local bytes = {char:byte(1, #char)}
		local chars = ''
		for b = 1, #bytes do
			chars = chars..string.char(bytes[b])
		end
		text = text:gsub(chars, utils.ShiftJISback[i][3])
	end
	return text
end

-- ================================================================
-- Main string-cleaning pass for chat lines
-- ================================================================

utils.cleanstr = function(str)
	-- Parse the string's auto-translate tags.
	str = AshitaCore:GetChatManager():ParseAutoTranslate(str, true)

	-- Strip FFXI-specific color and translate tags.
	str = str:strip_colors()
	str = str:gsub(string.char(0xEF) .. '[' .. string.char(0x27) .. ']', '£')
	str = str:gsub(string.char(0xEF) .. '[' .. string.char(0x28) .. ']', '£')

	-- Strip trailing line breaks.
	while true do
		local hasN = str:endswith('\n')
		local hasR = str:endswith('\r')
		if not hasN and not hasR then break end
		if hasN then str = str:trimend('\n') end
		if hasR then str = str:trimend('\r') end
	end

	-- Walk the string, replacing recognised SJIS pairs with their
	-- UTF-8 equivalents and dropping unknown high-byte characters.
	local i = 1
	while i <= #str - 1 do
		local pair = str:sub(i, i + 1)

		local found = false
		utils.ShiftJISRanges:each(function(v)
			if (string.byte(pair[1]) >= v[1] and string.byte(pair[1]) <= v[2])
				and (v[3] == -1 or (string.byte(pair[2]) >= v[3] and string.byte(pair[2]) <= v[4])) then
				found = true
			end
		end)

		if found then
			if utils.ShiftJISReps[pair] then
				str = str:sub(1, i - 1) .. utils.ShiftJISReps[pair] .. str:sub(i + 2)
				i = i + 2
			else
				i = i + 1
			end
		else
			str = str:sub(1, i - 1) .. str:sub(i + 1)
		end
	end

	-- Replace mid-line breaks.
	return (str:gsub(string.char(0x07), '\n'))
end

-- ================================================================
-- ImGui visibility toggle
-- ================================================================

utils.ImguiVis = function(visible)
	AshitaCore:GetFontManager():SetVisible(visible)
	AshitaCore:GetPrimitiveManager():SetVisible(visible)
	AshitaCore:GetGuiManager():SetVisible(visible)
end

-- ================================================================
-- Generic string split
-- ================================================================

utils.stringsplit = function(input, sep)
	if sep == nil then sep = '%s' end
	local result = {}
	if not input or #input == 0 then return result end
	for str in string.gmatch(input, '([^'..sep..']+)') do
		table.insert(result, str)
	end
	return result
end

-- ================================================================
-- Emoji-name parsing (":smile:" -> codepoint).  Rewrites the text
-- in-place, leaving emoji-supplemental glyphs surrounded by '*' so
-- they remain visible in fallback fonts.
-- ================================================================

utils.parseEmoji = function(text)
	text = text:gsub(':1st_place_medal:', ':first_place_medal:')
	text = text:gsub(':2nd_place_medal:', ':second_place_medal:')
	text = text:gsub(':3rd_place_medal:', ':third_place_medal:')

	local idx = 1
	while idx < #text or idx < 4092 do
		local b = text:find(':', idx, true)
		if not b then break end

		local e = text:find(':', b + 1, true)
		if not e or e - 1 <= 0 then break end

		local cp = emojis[1][text:sub(b + 1, e - 1)]
		if cp then
			if cp >= 0x1FA70 and cp <= 0x1FAFF then
				text = text:sub(1, b - 1) .. '*' .. text:sub(b + 1, e - 1) .. '*' .. text:sub(e + 1, #text)
			else
				text = text:sub(1, b - 1) .. utf8.char(cp) .. text:sub(e + 1, #text)
			end
			idx = e
		end
		idx = b + 1
	end

	return text
end

-- ================================================================
-- Wrap multi-byte UTF-8 characters in MC color sequences so
-- emojis render in the highlight color used for them.
-- ================================================================

utils.emojiCols = function(text)
	local out = {}
	local idx = 1
	local len = #text

	while idx <= len do
		local b = text:byte(idx)

		-- 4-byte UTF-8 (U+10000..U+10FFFF) - e.g. 😀
		if b >= 0xF0 and b <= 0xF4 and idx + 3 <= len then
			out[#out + 1] = utils.MC(0xFFFBD043)
			out[#out + 1] = text:sub(idx, idx + 3)
			out[#out + 1] = utils.MC('reset')
			idx = idx + 4

		-- 3-byte UTF-8 (U+0800..U+FFFF) - e.g. ❤ ☀ ♻ ✨
		elseif b >= 0xE0 and b <= 0xEF and idx + 2 <= len then
			out[#out + 1] = utils.MC(0xFFFBD043)
			out[#out + 1] = text:sub(idx, idx + 2)
			out[#out + 1] = utils.MC('reset')
			idx = idx + 3

		else
			out[#out + 1] = text:sub(idx, idx)
			idx = idx + 1
		end
	end

	return table.concat(out)
end

-- ================================================================
-- Settings repair: prune keys from t2 that no longer exist in t1
-- (the defaults).  Used after a settings-version bump.
-- ================================================================

utils.RepairSettings = function(t1, t2, seen)
	if type(t1) ~= 'table' or type(t2) ~= 'table' then
		return t2
	end

	seen = seen or {}
	local s = seen[t2]
	if s and s[t1] then
		return t2
	end
	s = s or {}
	s[t1] = true
	seen[t2] = s

	-- Collect keys to remove (safer than deleting during iteration).
	local remove = nil
	for k, _ in pairs(t2) do
		if t1[k] == nil then
			remove = remove or {}
			remove[#remove + 1] = k
		end
	end

	if remove then
		for i = 1, #remove do
			t2[remove[i]] = nil
		end
	end

	-- Recurse into subtables when both sides are tables.
	for k, v1 in pairs(t1) do
		local v2 = t2[k]
		if type(v1) == 'table' and type(v2) == 'table' then
			utils.RepairSettings(v1, v2, seen)
		end
	end

	return t2
end

return utils
