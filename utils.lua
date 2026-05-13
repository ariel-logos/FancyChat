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

    // D3DXGetImageInfoFromFileInMemory + struct used to read back the
    // decoded image's dimensions when loading a remote image (zone
    // map fetch in lib/render.lua).  D3DXCreateTextureFromFileInMemoryEx
    // accepts a D3DXIMAGE_INFO* in its 14th arg and fills it as a
    // side effect; we use that instead of GetLevelDesc on the
    // resulting texture so we don't need to reach into the
    // IDirect3DTexture8 vtable from Lua.
    typedef struct {
        unsigned int Width;
        unsigned int Height;
        unsigned int Depth;
        unsigned int MipLevels;
        unsigned int Format;
        unsigned int ResourceType;
        unsigned int ImageFileFormat;
    } D3DXIMAGE_INFO;
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
		{123, 'error1',         0xFFFF0090},
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
	
	combatwords = T{'hit', 'damage', 'points', 'readies', 'heal'},

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

-- ================================================================
-- Wiki URL helpers + filename-display utility for the /sea popup.
-- ================================================================
local FFXIC_BASE  = 'https://ffxiclopedia.fandom.com'
local BGWIKI_BASE = 'https://www.bg-wiki.com'

utils.GetZoneWikiUrl = function(zoneName)
	if not zoneName then return nil end
	return FFXIC_BASE..'/wiki/'..zoneName:gsub(' ', '_')
end

utils.GetBgWikiZoneUrl = function(zoneName)
	if not zoneName then return nil end
	return BGWIKI_BASE..'/wiki/'..zoneName:gsub(' ', '_')
end

-- Underscores/hyphens -> spaces; split CamelCase + letter|digit boundaries.
local function prettifyFilenameStem(stem)
	local s = stem:gsub('_', ' '):gsub('%-', ' ')
	s = s:gsub('(%l)(%u)', '%1 %2')
	s = s:gsub('(%a)(%d)', '%1 %2')
	s = s:gsub('%s+', ' ')
	return (s:match('^%s*(.-)%s*$'))
end


-- ----------------------------------------------------------------
-- Local zone-map browser.
--
-- The maps/ folder under the addon root holds one subfolder per zone
-- (built by maps/download_all_maps.py).  Each zone subfolder contains
-- one or more "section" subfolders — Maps, Treasure, Fishing,
-- Weather, Notorious_Monsters — each with PNG/GIF/JPEG image files.
--
--   maps/
--     The Boyahda Tree/
--       Maps/                  Boyahda-tree_1.png  ...  Boyahda-tree_4.png
--       Fishing/               TheBoyahdaTreeFishing1.gif  ...
--       Notorious_Monsters/    Boyahda-tree_1_NM.png  ...
--       Treasure/       BoyahdaTreeCoffers.png
--       Weather/               TheBoyahdaTreeElementals1.png  ...
--
-- The /sea zone-tip popup (lib/render.lua) renders these as a
-- collapsible section list (accordion).
-- ----------------------------------------------------------------

-- Mirror the Python downloader's folder_safe(): only '/' is illegal in
-- a Windows folder name; brackets, parens, apostrophes, '#', spaces
-- etc. are preserved as-is.
local function localMapFolderName(zoneName)
	return (zoneName or ''):gsub('/', '_')
end

-- Section ordering for the popup.  User-specified:
--   Maps -> Treasure -> Fishing -> Mining/Excavating/Logging/Harvesting/
--   Digging/Gathering -> [other unknown sections] -> Weather ->
--   Notorious_Monsters.
-- The 500-gap is for any future section folder we don't know about; it
-- sorts alphabetically among itself between Gathering and Weather.
local LOCAL_SECTION_ORDER = {
	['Maps']              = 1,
	['Treasure']          = 2,
	['Fishing']           = 3,
	['Mining']            = 4,
	['Excavating']        = 5,
	['Logging']           = 6,
	['Harvesting']        = 7,
	['Digging']           = 8,
	['Gathering']         = 9,
	['Weather']           = 1000,
	['Notorious_Monsters']= 1001,
}

-- Folder-name -> human display name for the section header.  Anything
-- not listed here gets its underscores turned into spaces.
local function sectionDisplayName(folder)
	if folder == 'Maps'               then return 'Maps' end
	if folder == 'Treasure'           then return 'Treasure' end
	if folder == 'Fishing'            then return 'Fishing' end
	if folder == 'Weather'            then return 'Weather' end
	if folder == 'Notorious_Monsters' then return 'Notorious Monsters' end
	return (folder:gsub('_', ' '))
end

-- Scan addon.path/maps/<zoneName>/ and return an ordered list of
-- sections, each with its file entries.  Returns nil if the zone has
-- no folder OR every section folder is empty (caller treats either
-- case as "no local maps").
--
-- Return shape:
--   {
--     { folder='Maps', display='Maps', entries={
--       {filename='Boyahda-tree_1.png', path='F:/.../Maps/Boyahda-tree_1.png',
--        display='Boyahda Tree 1'},
--       ...
--     }},
--     { folder='Fishing', display='Fishing', entries={...} },
--     ...
--   }
utils.GetLocalZoneMaps = function(zoneName)
	if not zoneName or zoneName == '' then return nil end
	local folder  = localMapFolderName(zoneName)
	local zoneDir = addon.path..'/maps/'..folder

	-- Enumerate immediate subdirectories.  /b = bare names, /ad =
	-- directories only.  2>nul swallows "file not found" if the
	-- zone folder doesn't exist on disk.
	local sections = {}
	local p = io.popen('dir /b /ad "'..zoneDir..'" 2>nul')
	if not p then return nil end
	for line in p:lines() do
		line = line:gsub('%s+$', '')
		if line ~= '' then sections[#sections+1] = line end
	end
	p:close()
	if #sections == 0 then return nil end

	table.sort(sections, function(a, b)
		local oa = LOCAL_SECTION_ORDER[a] or 500
		local ob = LOCAL_SECTION_ORDER[b] or 500
		if oa ~= ob then return oa < ob end
		return a < b
	end)

	local out = {}
	for _, sec in ipairs(sections) do
		local entries = {}
		local fp = io.popen('dir /b /a-d "'..zoneDir..'/'..sec..'" 2>nul')
		if fp then
			for fname in fp:lines() do
				fname = fname:gsub('%s+$', '')
				local ext = fname:match('%.(%w+)$')
				if ext then
					ext = ext:lower()
					if ext == 'png' or ext == 'gif'
					   or ext == 'jpg' or ext == 'jpeg' then
						local stem = fname:gsub('%.[^.]+$', '')
						entries[#entries+1] = {
							filename = fname,
							path     = zoneDir..'/'..sec..'/'..fname,
							display  = prettifyFilenameStem(stem),
						}
					end
				end
			end
			fp:close()
		end
		if #entries > 0 then
			-- For Notorious_Monsters, look for the sidecar
			-- _nm_index.lua written by the bulk-download script.  When
			-- present, expand each map file into one entry per NM that
			-- spawns on it (some files cover multiple NMs — e.g. on
			-- The Boyahda Tree, Boyahda-tree_1_NM.png is shared by
			-- Aquarius, Ellyllon, and Unut).  The texture-cache key
			-- stays the file path so all three NM entries share one
			-- decoded texture.
			--
			-- Files that don't appear in the manifest fall through to
			-- the default prettified-filename display so a partial
			-- manifest doesn't lose entries.
			if sec == 'Notorious_Monsters' then
				local index_path = zoneDir..'/'..sec..'/_nm_index.lua'
				local f = io.open(index_path, 'r')
				if f then
					f:close()
					local fn, _ = loadfile(index_path)
					if fn then
						local ok, idx = pcall(fn)
						if ok and type(idx) == 'table' then
							-- Case-insensitive key lookup so an
							-- inconsistently-cased wiki entry still
							-- resolves to the on-disk file (the wiki
							-- treats file titles case-insensitively
							-- but stores wikitext verbatim).
							local lower_idx = {}
							for k, v in pairs(idx) do
								lower_idx[k:lower()] = v
							end
							local expanded = {}
							for _, entry in ipairs(entries) do
								local nms = lower_idx[entry.filename:lower()]
								if type(nms) == 'table' and #nms > 0 then
									for _, nm in ipairs(nms) do
										expanded[#expanded+1] = {
											filename = entry.filename,
											path     = entry.path,
											display  = nm,
										}
									end
								else
									expanded[#expanded+1] = entry
								end
							end
							entries = expanded
						end
					end
				end
				-- NM list is sorted alphabetically by display name
				-- (NM name, post-expansion) rather than by filename.
				table.sort(entries, function(a, b)
					return a.display:lower() < b.display:lower()
				end)
			else
				table.sort(entries, function(a, b)
					return a.filename < b.filename
				end)
			end
			out[#out+1] = {
				folder  = sec,
				display = sectionDisplayName(sec),
				entries = entries,
			}
		end
	end
	if #out == 0 then return nil end
	return out
end

-- Mirror of LoadTextureFromUrl that reads from a local file.  Same
-- D3DX entry-point (D3DXCreateTextureFromFileInMemoryEx) so PNG/GIF/
-- JPEG all decode through the same path and the caller treats the
-- resulting texture identically.
utils.LoadTextureFromFile = function(path)
	if not path or path == '' then return nil, 'no path' end
	local f = io.open(path, 'rb')
	if not f then return nil, 'file not found' end
	local body = f:read('*a')
	f:close()
	if not body or #body == 0 then return nil, 'empty file' end

	local size      = #body
	local info      = ffi.new('D3DXIMAGE_INFO[1]')
	local texPtrPtr = ffi.new('IDirect3DTexture8*[1]')
	local hr = C.D3DXCreateTextureFromFileInMemoryEx(
		d3d8dev, body, size,
		0xFFFFFFFF, 0xFFFFFFFF,
		1, 0,
		C.D3DFMT_A8R8G8B8, C.D3DPOOL_MANAGED,
		0xFFFFFFFF, 0xFFFFFFFF,
		0,
		info, nil, texPtrPtr)
	if hr ~= C.S_OK then
		return nil, ('decode failed: %08X'):format(hr)
	end
	local tex = ffi.cast('IDirect3DTexture8*', texPtrPtr[0])
	d3d.gc_safe_release(tex)
	return tex, tonumber(info[0].Width), tonumber(info[0].Height)
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
	LoadTexture(textures, 'logo')
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

-- Scan a chat-line string for ALL FFXI zone names mentioned in it.
-- `zoneNames` is the lookup table built at addon init by
-- lifecycle.M.Init: keys are the lowercased zone names, values are
-- the canonical (display) names.  Returns an array of canonical
-- names in order of first appearance, deduplicated, with any hit
-- that is fully contained within a longer overlapping hit dropped
-- (so "Sky" inside "Sky-Cloud Pyramid" doesn't show twice).  Names
-- shorter than 4 chars are skipped to reduce false positives.
utils.FindZonesInText = function(text, zoneNames)
	if not text or text == '' or not zoneNames then return {} end
	local lower = text:lower()
	local hits = {}
	for lname, cname in pairs(zoneNames) do
		if #lname >= 4 then
			local pos = lower:find(lname, 1, true)
			if pos then
				table.insert(hits, {pos = pos, lname = lname, cname = cname})
			end
		end
	end
	-- Drop hits subsumed by a longer overlapping hit.
	local kept = {}
	for i, h in ipairs(hits) do
		local subsumed = false
		for j, other in ipairs(hits) do
			if i ~= j and #other.lname > #h.lname then
				local oEnd = other.pos + #other.lname
				local hEnd = h.pos + #h.lname
				if other.pos <= h.pos and oEnd >= hEnd then
					subsumed = true
					break
				end
			end
		end
		if not subsumed then
			table.insert(kept, h)
		end
	end
	table.sort(kept, function(a, b) return a.pos < b.pos end)
	-- Dedupe by canonical name (same zone name twice in one line → one row).
	local seen, out = {}, {}
	for _, h in ipairs(kept) do
		if not seen[h.cname] then
			seen[h.cname] = true
			table.insert(out, h.cname)
		end
	end
	return out
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

-- Colorset files live in a `chatcolors/` subfolder.  The Export/Import
-- popups (lib/ui_settings.lua) drive these by explicit filename now;
-- the player chooses the name on Export and picks from a list on Import.

-- Bare-name listing of every regular file in chatcolors/.
utils.ListColorsetFiles = function(addonpath)
	local out = {}
	local p = io.popen('dir /b /a-d "'..addonpath..'\\chatcolors\\" 2>nul')
	if not p then return out end
	for line in p:lines() do
		line = line:gsub('%s+$', '')
		if line ~= '' then out[#out+1] = line end
	end
	p:close()
	table.sort(out)
	return out
end

-- Suggest the next-available colorset filename for the given player:
-- `colorset_<player>_<N>` where N is one more than the largest N
-- already in use (scanning ONLY files of that prefix).
utils.NextColorsetName = function(addonpath, charname)
	local prefix  = 'colorset_'..charname..'_'
	local highest = 0
	for _, name in ipairs(utils.ListColorsetFiles(addonpath)) do
		local n = name:match('^'..prefix:gsub('([%-%.])', '%%%1')..'(%d+)$')
		if n then
			local num = tonumber(n)
			if num and num > highest then highest = num end
		end
	end
	return prefix..(highest + 1)
end

utils.ExportColors = function(addonpath, filename, colors)
	local folder   = addonpath..'\\chatcolors'
	local filepath = folder..'\\'..filename
	os.execute('mkdir "'..folder..'" 2>nul')
	local f = assert(io.open(filepath, 'w'))
	for k, v in pairs(colors) do
		f:write(string.format('%s,%#x\n', k, v[1]))
	end
	f:close()
	print((('Exported colorset to: '..filepath):gsub('\\\\', '\\')))
end

utils.ImportColors = function(addonpath, filename, colors)
	local cols = {}
	for k, v in pairs(colors) do cols[k] = v end
	local filepath = addonpath..'\\chatcolors\\'..filename
	local f = io.open(filepath, 'r')
	if not f then
		print('colorset file not found: '..filepath)
		return cols
	end
	for line in f:lines() do
		local key, val = line:match('([^,]+),([^,]+)')
		if key and val then
			local num = tonumber(val)
			if num and cols[key] then cols[key][1] = num end
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
	-- Logs now live under <install>/config/addons/<addon.name>/logs/<player>/
	-- alongside the per-character settings folders.  AddonPath is kept in
	-- the signature for backward-compat with old callers but is ignored.
	local logs_folder = AshitaCore:GetInstallPath()
		..'\\config\\addons\\'..addon.name..'\\logs\\'..PlayerName
	os.execute('mkdir "'..logs_folder..'" 2>nul')

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
-- Folds the SJIS lead-byte detection, glyph remapping and codepoint
-- replacement into a single byte walk against a flat lookup table.
-- See lib/parser.lua:CleanTextFunctionNew for the call site.
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

-- legacycolors: 38 entries (RESET + 37 real palette slots; slots not listed = uncoloured / channel default)
utils.legacycolors = {
	['\30\01'] = '\\§--------ç\\',  -- (255,255,195)
	['\30\02'] = '\\§FF72FF2Eç\\',  -- (148,255,51)
	['\30\03'] = '\\§FF8A8AFFç\\',  -- (148,147,255)
	['\30\04'] = '\\§FF8A8AFFç\\',  -- (148,147,255)
	['\30\05'] = '\\§FFFA46E8ç\\',  -- (255,88,255)
	['\30\06'] = '\\§FF2EF7FCç\\',  -- (55,255,255)
	['\30\07'] = '\\§FFF9E3B6ç\\',  -- (255,255,237)
	['\30\08'] = '\\§FFFF8767ç\\',  -- (255,148,113)
	['\30\09'] = '\\§--------ç\\',  -- (178,255,237)
	['\30\10'] = '\\§--------ç\\',  -- (179,255,237)
	['\30\11'] = '\\§--------ç\\',  -- (174,255,231)
	['\30\12'] = '\\§--------ç\\',  -- (173,255,231)
	['\30\13'] = '\\§--------ç\\',  -- (173,255,230)
	['\30\14'] = '\\§--------ç\\',  -- (173,255,231)
	['\30\15'] = '\\§--------ç\\',  -- (174,255,232)
	['\30\16'] = '\\§--------ç\\',  -- (170,255,226)
	['\30\17'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\18'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\19'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\20'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\21'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\22'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\23'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\24'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\25'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\26'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\27'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\28'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\29'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\30'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\31'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\32'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\33'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\34'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\35'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\36'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\37'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\38'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\39'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\40'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\41'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\42'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\43'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\44'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\45'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\46'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\47'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\48'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\49'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\50'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\51'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\52'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\53'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\54'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\55'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\56'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\57'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\58'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\59'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\60'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\61'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\62'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\63'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\64'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\65'] = '\\§FF2E2D4Dç\\',  -- (255,255,201)
	['\30\66'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\67'] = '\\§FF8B88A6ç\\',  -- (147,146,178)
	['\30\68'] = '\\§FFFF6390ç\\',  -- (255,108,155)
	['\30\69'] = '\\§FFFCF850ç\\',  -- (255,255,86)
	['\30\70'] = '\\§FF7C93E7ç\\',  -- (148,176,255)
	['\30\71'] = '\\§FF6BA2FFç\\',  -- (117,176,255)
	['\30\72'] = '\\§FFE22DFFç\\',  -- (240,54,255)
	['\30\73'] = '\\§FFFF89FFç\\',  -- (255,145,255)
	['\30\74'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\75'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\76'] = '\\§FFF13F60ç\\',  -- (255,86,115)
	['\30\77'] = '\\§FFE5D9E6ç\\',  -- (255,255,255)
	['\30\78'] = '\\§FFD2CEA6ç\\',  -- (218,222,174)
	['\30\79'] = '\\§FF18FF37ç\\',  -- (24,255,55)
	['\30\80'] = '\\§FFCDFFE7ç\\',  -- (240,255,255)
	['\30\81'] = '\\§FFAD52FFç\\',  -- (255,255,201)
	['\30\82'] = '\\§FF4BFFFFç\\',  -- (85,255,255)
	['\30\83'] = '\\§FF2AFC94ç\\',  -- (55,255,181)
	['\30\84'] = '\\§FFF7959Eç\\',  -- (255,255,255)
	['\30\85'] = '\\§FFF37B89ç\\',  -- (255,177,180)
	['\30\86'] = '\\§FFFF83FFç\\',  -- (255,145,255)
	['\30\87'] = '\\§FF46FFFEç\\',  -- (88,255,255)
	['\30\88'] = '\\§FF91FFC9ç\\',  -- (178,255,242)
	['\30\89'] = '\\§FFB195FFç\\',  -- (203,178,255)
	['\30\90'] = '\\§FFF7FFFFç\\',  -- (255,255,255)
	['\30\91'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\92'] = '\\§FFAFE9FFç\\',  -- (205,255,255)
	['\30\93'] = '\\§FFFB8AAAç\\',  -- (255,148,176)
	['\30\94'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\95'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\96'] = '\\§FFFFFFCEç\\',  -- (255,255,206)
	['\30\97'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\98'] = '\\§FFDFFFFFç\\',  -- (255,255,255)
	['\30\99'] = '\\§FFFFDCEDç\\',  -- (255,255,255)
	['\30\100'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\101'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\102'] = '\\§FFF8F1A5ç\\',  -- (255,255,181)
	['\30\103'] = '\\§FFF2EEFFç\\',  -- (242,238,255)
	['\30\104'] = '\\§FFF8F94Dç\\',  -- (255,255,88)
	['\30\105'] = '\\§FFFA9CFFç\\',  -- (255,206,255)
	['\30\106'] = '\\§FFFAFAA5ç\\',  -- (255,255,212)
	['\30\107'] = '\\§FFFAFAA5ç\\',  -- (255,255,212)
	['\30\108'] = '\\§FFF1757Fç\\',  -- (255,146,151)
	['\30\109'] = '\\§FFFFED86ç\\',  -- (255,255,179)
	['\30\110'] = '\\§FFCEFF55ç\\',  -- (218,255,88)
	['\30\111'] = '\\§FF18FF39ç\\',  -- (25,255,58)
	['\30\112'] = '\\§FF18AEFFç\\',  -- (24,176,255)
	['\30\113'] = '\\§FF13BDFFç\\',  -- (255,255,205)
	['\30\114'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\115'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\116'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\117'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\118'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\119'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\120'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\121'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\122'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\123'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\124'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\125'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\126'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\127'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\128'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\129'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\130'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\131'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\132'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\133'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\134'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\135'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\136'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\137'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\138'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\139'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\140'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\141'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\142'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\143'] = '\\§FFFC4CE4ç\\',  -- (255,85,240)
	['\30\144'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\145'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\146'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\147'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\148'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\149'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\150'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\151'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\152'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\153'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\154'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\155'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\156'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\157'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\158'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\159'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\160'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\161'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\162'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\163'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\164'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\165'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\166'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\167'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\168'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\169'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\170'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\171'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\172'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\173'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\174'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\175'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\176'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\177'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\178'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\179'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\180'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\181'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\182'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\183'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\184'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\185'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\186'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\187'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\188'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\189'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\190'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\191'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\192'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\193'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\194'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\195'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\196'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\197'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\198'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\199'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\200'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\201'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\202'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\203'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\204'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\205'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\206'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\207'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\208'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\209'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\210'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\211'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\212'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\213'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\214'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\215'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\216'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\217'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\218'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\219'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\220'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\221'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\222'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\223'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\224'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\225'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\226'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\227'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\228'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\229'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\230'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\231'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\232'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\233'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\234'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\235'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\236'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\237'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\238'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\239'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\240'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\241'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\242'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\243'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\244'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\245'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\246'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\247'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\248'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\249'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\250'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\251'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\252'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\253'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\254'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\255'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
}
-- legacycolors2: 255 entries
utils.legacycolors2 = {
	['\30\01'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\02'] = '\\§FFF499ABç\\',  -- (255,180,194)
	['\30\03'] = '\\§FFFF8E9Dç\\',  -- (255,150,163)
	['\30\04'] = '\\§FFF07FFCç\\',  -- (255,150,255)
	['\30\05'] = '\\§FF45FFFFç\\',  -- (91,255,255)
	['\30\06'] = '\\§FFA8FFEDç\\',  -- (184,255,255)
	['\30\07'] = '\\§FFBD98F7ç\\',  -- (215,180,255)
	['\30\08'] = '\\§FFFFA5FFç\\',  -- (255,211,255)
	['\30\09'] = '\\§FFE5E3FBç\\',  -- (255,255,255)
	['\30\10'] = '\\§FFFFA1ADç\\',  -- (255,180,194)
	['\30\11'] = '\\§FFFF8693ç\\',  -- (255,148,160)
	['\30\12'] = '\\§FFFF92FFç\\',  -- (255,150,255)
	['\30\13'] = '\\§FF56FDFEç\\',  -- (89,255,255)
	['\30\14'] = '\\§FFAFFFF6ç\\',  -- (179,255,250)
	['\30\15'] = '\\§FFA58CFFç\\',  -- (209,183,255)
	['\30\16'] = '\\§FFFFC2FFç\\',  -- (255,205,255)
	['\30\17'] = '\\§FFD7FAFCç\\',  -- (255,255,255)
	['\30\18'] = '\\§FFE6FFFFç\\',  -- (255,255,255)
	['\30\19'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\20'] = '\\§FFFFF1FCç\\',  -- (255,255,255)
	['\30\21'] = '\\§FFE3E4F8ç\\',  -- (246,242,255)
	['\30\22'] = '\\§FFE8FFFFç\\',  -- (255,255,255)
	['\30\23'] = '\\§FFE8FFFFç\\',  -- (255,255,255)
	['\30\24'] = '\\§FFE8FFFFç\\',  -- (255,255,255)
	['\30\25'] = '\\§FFFFD2F9ç\\',  -- (255,255,255)
	['\30\26'] = '\\§FFEFF2FFç\\',  -- (239,242,255)
	['\30\27'] = '\\§FFE6FFFFç\\',  -- (255,255,255)
	['\30\28'] = '\\§FFFE85B1ç\\',  -- (255,155,194)
	['\30\29'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\30'] = '\\§FFC8FAFFç\\',  -- (215,255,255)
	['\30\31'] = '\\§FFC8FAFFç\\',  -- (209,255,255)
	['\30\32'] = '\\§FFFFD5F0ç\\',  -- (255,255,255)
	['\30\33'] = '\\§FFF7F2FFç\\',  -- (247,242,255)
	['\30\34'] = '\\§FFEAFFFFç\\',  -- (255,255,255)
	['\30\35'] = '\\§FFEAFFFFç\\',  -- (255,255,255)
	['\30\36'] = '\\§FFF2EE57ç\\',  -- (255,255,103)
	['\30\37'] = '\\§FFE7E3C4ç\\',  -- (231,227,196)
	['\30\38'] = '\\§FFFF71ADç\\',  -- (255,113,173)
	['\30\39'] = '\\§FFFF5A86ç\\',  -- (255,90,134)
	['\30\40'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\41'] = '\\§FFF0F2FFç\\',  -- (240,242,255)
	['\30\42'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\43'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\44'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\45'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\46'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\47'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\48'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\49'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\50'] = '\\§FFF2EE57ç\\',  -- (255,255,104)
	['\30\51'] = '\\§FFF2EE57ç\\',  -- (255,255,104)
	['\30\52'] = '\\§FFF2EE57ç\\',  -- (255,255,104)
	['\30\53'] = '\\§FFE7E4C5ç\\',  -- (231,228,197)
	['\30\54'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\55'] = '\\§FFF2EE57ç\\',  -- (255,255,104)
	['\30\56'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\57'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\58'] = '\\§FFF2EE57ç\\',  -- (255,255,104)
	['\30\59'] = '\\§FFFFFFDFç\\',  -- (255,255,223)
	['\30\60'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\61'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\62'] = '\\§FFF2EE57ç\\',  -- (255,255,104)
	['\30\63'] = '\\§FFFFFFC1ç\\',  -- (255,255,193)
	['\30\64'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\65'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\66'] = '\\§FFF2EE57ç\\',  -- (255,255,105)
	['\30\67'] = '\\§FFFAF2B5ç\\',  -- (255,255,198)
	['\30\68'] = '\\§FFFAF2B5ç\\',  -- (255,255,198)
	['\30\69'] = '\\§FFFAF2B5ç\\',  -- (255,255,198)
	['\30\70'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\71'] = '\\§FFFFFFFFç\\',  -- (248,243,255)
	['\30\72'] = '\\§FFFFFFFFç\\',  -- (248,243,255)
	['\30\73'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\74'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\75'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\76'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\77'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\78'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\79'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\80'] = '\\§FFF2EE57ç\\',  -- (255,255,105)
	['\30\81'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\82'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\83'] = '\\§FFF2EE57ç\\',  -- (255,255,107)
	['\30\84'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\85'] = '\\§FFF2EE57ç\\',  -- (255,255,107)
	['\30\86'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\87'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\88'] = '\\§FFF2EE57ç\\',  -- (255,255,107)
	['\30\89'] = '\\§FFFFFFFFç\\',  -- (241,247,255)
	['\30\90'] = '\\§FFF2EE57ç\\',  -- (255,255,107)
	['\30\91'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\92'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\93'] = '\\§FFF2EE57ç\\',  -- (255,255,106)
	['\30\94'] = '\\§FFFFFFFFç\\',  -- (241,247,255)
	['\30\95'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\96'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\97'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\98'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\99'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\100'] = '\\§FFF2EE57ç\\',  -- (255,255,108)
	['\30\101'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\102'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\103'] = '\\§FFF2EE57ç\\',  -- (255,255,108)
	['\30\104'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\105'] = '\\§FFF2EE57ç\\',  -- (255,255,108)
	['\30\106'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\107'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\108'] = '\\§FFF2EE57ç\\',  -- (255,255,108)
	['\30\109'] = '\\§FFFFFFFFç\\',  -- (249,244,255)
	['\30\110'] = '\\§FFF2EE57ç\\',  -- (255,255,108)
	['\30\111'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\112'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\113'] = '\\§FFF2EE57ç\\',  -- (255,255,223)
	['\30\114'] = '\\§FFFFFFFFç\\',  -- (242,241,255)
	['\30\115'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\116'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\117'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\118'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\119'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\120'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\121'] = '\\§FFFEFFD9ç\\',  -- (255,255,228)
	['\30\122'] = '\\§FFF2EE57ç\\',  -- (255,255,108)
	['\30\123'] = '\\§FFFA6DAAç\\',  -- (255,115,174)
	['\30\124'] = '\\§FFFA6DAAç\\',  -- (255,115,175)
	['\30\125'] = '\\§FFFA6DAAç\\',  -- (255,116,175)
	['\30\126'] = '\\§FFFA6DAAç\\',  -- (255,115,174)
	['\30\127'] = '\\§FFFEFFD9ç\\',  -- (255,255,228)
	['\30\128'] = '\\§FFFEFFD9ç\\',  -- (255,255,227)
	['\30\129'] = '\\§FFFEFFD9ç\\',  -- (255,255,229)
	['\30\130'] = '\\§FFFEFFD9ç\\',  -- (255,255,229)
	['\30\131'] = '\\§FFFEFFD9ç\\',  -- (255,255,229)
	['\30\132'] = '\\§FFFEFFD9ç\\',  -- (255,255,229)
	['\30\133'] = '\\§FFFEFFD9ç\\',  -- (255,255,229)
	['\30\134'] = '\\§FFFEFFD9ç\\',  -- (255,255,229)
	['\30\135'] = '\\§FFFEFFD9ç\\',  -- (255,255,229)
	['\30\136'] = '\\§FFFEFFD9ç\\',  -- (255,255,229)
	['\30\137'] = '\\§FFFEFFD9ç\\',  -- (255,255,229)
	['\30\138'] = '\\§FFFEFFD9ç\\',  -- (255,255,230)
	['\30\139'] = '\\§FFFEFFD9ç\\',  -- (255,255,229)
	['\30\140'] = '\\§FFFEFFD9ç\\',  -- (255,255,234)
	['\30\141'] = '\\§FFF2EE57ç\\',  -- (255,255,109)
	['\30\142'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\143'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\144'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\145'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\146'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\147'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\148'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\149'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\150'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\151'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\152'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\153'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\154'] = '\\§FFF2EE57ç\\',  -- (255,255,110)
	['\30\155'] = '\\§FFF2EE57ç\\',  -- (255,255,110)
	['\30\156'] = '\\§FFF2EE57ç\\',  -- (255,255,110)
	['\30\157'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\158'] = '\\§FF16D343ç\\',  -- (33,255,80)
	['\30\159'] = '\\§FFF2EE57ç\\',  -- (255,255,110)
	['\30\160'] = '\\§FF8F8ABDç\\',  -- (157,154,204)
	['\30\161'] = '\\§FF817AAEç\\',  -- (255,255,226)
	['\30\162'] = '\\§FFC4E4FAç\\',  -- (255,255,255)
	['\30\163'] = '\\§FFFFFCFFç\\',  -- (255,255,255)
	['\30\164'] = '\\§FFFFFFFFç\\',  -- (243,243,255)
	['\30\165'] = '\\§FFEDFFFFç\\',  -- (255,255,255)
	['\30\166'] = '\\§FFD8D2BCç\\',  -- (228,228,201)
	['\30\167'] = '\\§FFEB3E72ç\\',  -- (255,93,141)
	['\30\168'] = '\\§FFF2EE57ç\\',  -- (255,255,111)
	['\30\169'] = '\\§FFF2EE57ç\\',  -- (255,255,111)
	['\30\170'] = '\\§FFEBE5B8ç\\',  -- (255,255,205)
	['\30\171'] = '\\§FFF2EE57ç\\',  -- (255,255,111)
	['\30\172'] = '\\§FFF2EE57ç\\',  -- (255,255,111)
	['\30\173'] = '\\§FFFFFFFFç\\',  -- (243,246,255)
	['\30\174'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\175'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\176'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\177'] = '\\§FFF2EE57ç\\',  -- (255,255,227)
	['\30\178'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\179'] = '\\§FFF2EE57ç\\',  -- (255,255,112)
	['\30\180'] = '\\§FFF2EE57ç\\',  -- (255,255,112)
	['\30\181'] = '\\§FFFFFFFFç\\',  -- (244,243,255)
	['\30\182'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\183'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\184'] = '\\§FFFFFFFFç\\',  -- (244,243,255)
	['\30\185'] = '\\§FFFFD3FFç\\',  -- (255,255,255)
	['\30\186'] = '\\§FFFFFFFFç\\',  -- (244,243,255)
	['\30\187'] = '\\§FFE2F0FCç\\',  -- (255,255,255)
	['\30\188'] = '\\§FFE2F0FCç\\',  -- (255,255,255)
	['\30\189'] = '\\§FFFDF7C4ç\\',  -- (255,255,202)
	['\30\190'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\191'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\192'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\193'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\194'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\195'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\196'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\197'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\198'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\199'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\200'] = '\\§FFAB58F0ç\\',  -- (189,95,255)
	['\30\201'] = '\\§FFAB58F0ç\\',  -- (189,95,255)
	['\30\202'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\203'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\204'] = '\\§FF22FF53ç\\',  -- (34,255,83)
	['\30\205'] = '\\§FF79F3BAç\\',  -- (189,255,255)
	['\30\206'] = '\\§FFFFFFC1ç\\',  -- (255,255,238)
	['\30\207'] = '\\§FF6F83D4ç\\',  -- (154,186,255)
	['\30\208'] = '\\§FFC0A5ECç\\',  -- (220,191,255)
	['\30\209'] = '\\§FF9650E0ç\\',  -- (255,255,229)
	['\30\210'] = '\\§FF5EFCFDç\\',  -- (95,255,255)
	['\30\211'] = '\\§FFEED9B1ç\\',  -- (255,255,202)
	['\30\212'] = '\\§FFEED9B1ç\\',  -- (255,255,202)
	['\30\213'] = '\\§FFD7FF70ç\\',  -- (222,255,114)
	['\30\214'] = '\\§FFD7FF70ç\\',  -- (222,255,114)
	['\30\215'] = '\\§FF23FF54ç\\',  -- (35,255,84)
	['\30\216'] = '\\§FF23FF54ç\\',  -- (35,255,84)
	['\30\217'] = '\\§FFCCFE6Fç\\',  -- (222,255,114)
	['\30\218'] = '\\§FF23FF54ç\\',  -- (35,255,84)
	['\30\219'] = '\\§FF1999FDç\\',  -- (35,189,255)
	['\30\220'] = '\\§FF1999FDç\\',  -- (35,186,255)
	['\30\221'] = '\\§FF23E6FDç\\',  -- (35,247,255)
	['\30\222'] = '\\§FF23E6FDç\\',  -- (35,247,255)
	['\30\223'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\224'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\225'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\226'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\227'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\228'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\229'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\230'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\231'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\232'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\233'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\234'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\235'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\236'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\237'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\238'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\239'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\240'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\241'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\242'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\243'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\244'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\245'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\246'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\247'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\248'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\249'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\250'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\251'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\252'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\253'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\254'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
	['\30\255'] = '\\§FFFFFFFFç\\',  -- (255,255,255)
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

-- Enumerate every .txt file in the combatfilters/ subfolder so the
-- Settings UI can offer a picker.  Sorted alphabetically.  Uses
-- `dir /b` which is a Windows built-in — fine here because the addon
-- only ever runs under Ashita / Windows.  Returns an empty table if
-- the folder doesn't exist or has no .txt files.
utils.ListCombatFilters = function()
	local filters = T{}
	local p = io.popen('dir /b /a-d "'..addon.path..'\\combatfilters\\*.txt" 2>nul')
	if p then
		for filename in p:lines() do
			table.insert(filters, filename)
		end
		p:close()
	end
	table.sort(filters)
	return filters
end

-- Cheap existence check for the active filter file.  Used by the CL
-- Filters tab + lifecycle init to detect "active filter was deleted
-- behind our back" and react gracefully (red warning + auto-disable
-- the master toggle so filtering doesn't silently no-op).
utils.CombatFilterExists = function(filename)
	if filename == nil or filename == '' then return false end
	local f = io.open(addon.path..'/combatfilters/'..filename, 'rb')
	if f == nil then return false end
	f:close()
	return true
end

-- Load and parse a single filter file from combatfilters/.  `filename`
-- defaults to the legacy 'custom_combat_filters.txt' so older settings
-- without a SelectedCombatFilter slot still work.  Missing files are
-- non-fatal — return an empty list so the addon keeps running with
-- no custom filters applied (e.g. user deleted/renamed the file via
-- the Settings UI).
utils.LoadCustomFilters = function(filename)
	local custmFilters = T{}
	filename = filename or 'example.txt'

	local f = io.open(addon.path..'/combatfilters/'..filename, 'rb')
	if f == nil then
		return custmFilters
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

	-- Empty-default early-out: when the defaults table for this slot
	-- has no keys (e.g. `Notes = T{}` in defaults.lua), the loaded
	-- table carries no schema to enforce - everything in `t2` is
	-- legitimate user data and must NOT be stripped.  Without this
	-- guard the strip-loop below removes all numbered keys from
	-- list-like slots populated at runtime (Notes was the visible
	-- symptom: every saved note got deleted on next load).
	local t1_has_keys = false
	for _ in pairs(t1) do
		t1_has_keys = true
		break
	end
	if not t1_has_keys then
		return t2
	end

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

	-- Recurse into subtables, AND fix type mismatches.  Without the
	-- mismatch repair, a key that was a plain number/string in an
	-- older version of the addon but is now a table (or vice versa)
	-- in defaults will survive in t2 with its old type.  Sugar's
	-- table.merge then crashes during character-switch with
	-- `rawget(number, k)` because it tries to recurse into the
	-- number expecting a table — see the logout traceback.  Fixing
	-- the mismatch by replacing t2's value with a clone of the
	-- default keeps the file readable by the next merge.
	for k, v1 in pairs(t1) do
		local v2 = t2[k]
		if type(v1) == 'table' then
			if type(v2) == 'table' then
				utils.RepairSettings(v1, v2, seen)
			elseif v2 ~= nil then
				t2[k] = utils.cloneTable(v1)
			end
		elseif v2 ~= nil and type(v2) == 'table' then
			-- Reverse mismatch: defaults expect a plain value but
			-- saved data has a table.  Restore the default.
			t2[k] = v1
		end
	end

	return t2
end

return utils
