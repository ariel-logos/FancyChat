-- lib/state.lua — shared mutable-state tables.  Required by every
-- module; mutations from one are visible to all.  Everything here is
-- a TABLE (not a scalar) so the alias-import pattern works across
-- modules (`local x = state.x` captures the binding, not the value).

require('common')
local defaults = require('lib.defaults')

local M = {}

-- FFXI memory pointers + menu / chat-position tracking.
M.uiw = defaults.default_uiw()

-- Menu-visibility coordination flags for the chat reposition logic.
M.mvc = {
	Menu1 = false, Menu2 = false, Menu3 = false,
	Menu4 = false, Menu5 = false, Menu6 = false,
	targetposY = 0, targetposX = 0,
}

-- The three FancyChat windows.
M.fcw = defaults.default_fcw()

-- Tab navigation.
M.tab = {
	NextTab                   = 'All',
	NextTab2                  = 'All',
	Tabs                      = {'All', 'Combat', 'Linkshell', 'Party', 'Tell', 'Shout', 'Custom'},
	ButtonColorStylesNormal   = defaults.tab_button_styles_normal,
	ButtonColorStylesSelected = defaults.tab_button_styles_selected,
}

-- Settings UI scratch state.
M.set = {
	isCEXI              = true,
	colorTextW          = 1,
	alertList           = {},
	alertBuffer         = T{},
	Popup               = {false},
	PickedColor         = T{1, 1, 1, 1},
	ChatLineMaxL        = 100,
	PlateBGColor        = 0x4D000000,
	FontHeight          = 20,
	ChatLines           = 8,
	CustomTabModes      = T{},
	SecondChat          = T{false},
	AdjWin1             = T{false},
	AdjWin2             = T{false},
	-- Save / Load colorset popups (Settings -> Font Colors).  Mutually
	-- exclusive: opening one closes the other.  Reset to the initial
	-- shape every time the source button is re-clicked.
	colorIO = {
		exportOpen     = false,
		exportName     = T{''},   -- ImGui InputText buffer
		importOpen     = false,
		importFiles    = {},      -- filenames in chatcolors/ (refreshed on open)
		importSelected = 0,       -- index into importFiles; 0 = none picked
	},
	-- Lowercased zone-name -> canonical zone-name lookup; populated at init.
	zoneNames           = {},
	-- CL Filters tab: tracks "active filter file no longer exists on
	-- disk" so the tab can show the red warning banner and the auto-
	-- disable transition only fires once per state-change (not every
	-- frame).  Flipped back to false when the file reappears or the
	-- user picks a different (existing) filter.
	filterFileMissing   = false,
	-- Floating /sea popup state (see render.lua for draw + dismissal).
	zoneTip = {
		visible   = false,
		zones     = {},
		x         = 0,
		y         = 0,
		-- activeSection[zone] = currently-expanded section folder name
		-- (e.g. "Maps", "Treasure"); nil defaults to "Maps".
		activeSection = {},
		-- Per-zone disk-scan cache of maps/<zone>/<section>/<file>.
		-- Reset on each popup open so disk changes take effect.
		localMaps     = {},
		-- Captured at mouse-press: was the cursor over the popup?
		-- Used to suppress the "click twice" dismiss race on buttons.
		pressInside   = false,
		-- One-shot latch set true by the chat handler on Ctrl+L-click
		-- and cleared on the popup's first render frame.  Drives both
		-- the one-time SetNextWindowFocus (so the popup pops on top)
		-- and the open-frame dismissal-skip (so the mouse-release that
		-- triggered the open doesn't immediately close us again).
		justAppeared  = false,
	},
	-- Texture cache, keyed by absolute file path; held for the session.
	zoneMapTextures = {},
	-- Open map windows.  Entry: { title, url, ptr, w, h, opened={true}, uid }.
	-- `uid` (monotonic) gives each window a stable ImGui ID across closes.
	zoneMapWindows = {},
	-- Counter feeding zoneMapWindows[i].uid.
	zoneMapUidCounter = 0,
	CombatSplitCharList = {
		{'Greater >',     0x003E},
		{'Column :',      0x0589},
		{'Tilde ~',       0x007E},
		{'Bullet',        0x2022},
		{'Bullet hypen',  0x2043},
		{'R.Triangle',    0x25B6},
		{'Arrow ->',      0x2192},
		{'Arrow (big) ->', 0x1F81E},
	},
}

-- Debug window state.
M.dw = {
	PLRCount         = 0,
	WindowOpened     = T{false},
	TestMessage      = '',
	TestMessage2     = '',
	ShowMessageMode  = T{false},
	ChannelColorMode = T{false},
	testPTR          = nil,
	frameID          = 1,
	addr             = 0,
}

-- Text-parser working state.
M.par = {
	LoginTime		= 0,
	tabmode         = nil,
	checkAgain      = {0, ''},
	emojiChannels   = {6, 14, 205, 213, 214, 217},
	allowed         = {0, 0},
	dumping         = false,
	LastMsgLength   = 0,
	customFilters   = {},
	timePrinted     = true,
	InEvent         = false,
	LastMsgInConv   = false,
	LastTS          = '',
	CombatCutIdx    = 0,
	FormatTS        = {'[%H:%M:%S]', '[%H:%M]'},
	LastMessage     = '',
	IsInConv        = false,
	DamageDone      = false,
	DamageGot       = false,
	MessageMode     = nil,
	LastMode        = '',
	isCustom        = false,
	LastMessageMode = 0,
	promptEnd       = {},
	actor1          = '',
	actor2          = '',
	actorP          = '',
	actorE          = '',
	action1         = '',
	isDamage        = false,
	handled_actors  = false,
	party_names     = {},
}

-- Chat-buffer state.
M.b = {
	LogBuffer             = T{},                                 -- DELETE FOR RELEASE
	OriginalBuffer        = T{},
	msgID                 = 1,
	ChatBufferMaxSize     = 600,
	CombatBufferMaxSize   = 300,
	ChatBufferN_All       = 0,
	ChatBufferN_AllAlt    = 0,
	ChatBufferN_Linkshell = 0,
	ChatBufferN_Party     = 0,
	ChatBufferN_Tell      = 0,
	ChatBufferN_Combat    = 0,
	ChatBufferN_Shout     = 0,
	ChatBufferN_Custom    = 0,
	CleanupThresh         = 100,
	ChatBufferIdx         = T{0, 0, 0},
	ChatBufferN           = T{0, 0, 0},
	ChatBufferMode        = T{1, 1},                             -- 1=All, 2=Combat, 3=Linkshell, 4=Party, 5=Tell, 6=Shout, 7=Custom
	ChatBuffer            = defaults.default_chat_buffer(),
}

-- GDI font / rect render-object handles per chat window.
M.fo = {
	Fwd     = T{},
	Bkw     = T{},
	Chat    = T{T{}, T{}, T{}},
	Aux     = T{T{}, T{}, T{}},
	BigMode = nil,
}
M.ro = {
	RectBG  = T{},
	Scroll  = T{},
	BigMode = nil,
}

-- Persisted user settings + companion color tables.
M.allSettings        = defaults.default_settings()
M.defaultColors      = defaults.default_colors()
M.allSettings.colors = M.defaultColors
M.colorDesc          = defaults.color_descriptions
M.gamepadButtons     = defaults.default_gamepad()

-- In-place swap of M.allSettings contents; preserves table identity so
-- every module's `local allSettings = state.allSettings` alias keeps
-- working.  Also redirects Ashita's settings.save cache at our table.
function M.replace_allSettings(loaded)
	if loaded == M.allSettings then return end
	for k in pairs(M.allSettings) do M.allSettings[k] = nil end
	for k, v in pairs(loaded) do M.allSettings[k] = v end

	local settingslib = require('settings')
	if settingslib.cache and settingslib.cache['allSettings'] then
		settingslib.cache['allSettings'].settings = M.allSettings
	end
end

return M
