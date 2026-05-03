--[[
	lib/state.lua

	Owns every shared mutable-state table the addon needs at runtime.
	Required by fancychat.lua at load time AND by every extracted module
	that needs to read or write state.  Because Lua's `require` caches the
	returned value, every module sees the *same* tables and mutations made
	from one module are visible to all others.

	Scalars cannot be shared via the alias-import pattern (a `local x =
	state.x` captures the value, not a binding).  Therefore everything in
	this file is a TABLE — even single-value fields like `dw.testPTR` are
	stored as `dw.testPTR = nil` and reassigned through table-field
	access (`dw.testPTR = ...`), which IS shared across modules.
]]

require('common')
local defaults = require('lib.defaults')

local M = {}

-- ================================================================
-- FFXI-side UI window / menu state.  Memory pointers and tracking
-- flags populated at load time and kept current by the d3d_present
-- callback.
-- ================================================================
M.uiw = defaults.default_uiw()

-- ================================================================
-- "Menu Visibility / Chat-position" coordination flags.  Set by the
-- per-frame menu inspector to decide whether the chat window must
-- shift to avoid overlapping a game UI panel.
-- ================================================================
M.mvc = {
	Menu1 = false, Menu2 = false, Menu3 = false,
	Menu4 = false, Menu5 = false, Menu6 = false,
	targetposY = 0, targetposX = 0,
}

-- ================================================================
-- The three FancyChat windows themselves.
-- ================================================================
M.fcw = defaults.default_fcw()

-- ================================================================
-- Tab navigation.
-- ================================================================
M.tab = {
	NextTab                   = 'All',
	NextTab2                  = 'All',
	Tabs                      = {'All', 'Combat', 'Linkshell', 'Party', 'Tell', 'Shout', 'Custom'},
	ButtonColorStylesNormal   = defaults.tab_button_styles_normal,
	ButtonColorStylesSelected = defaults.tab_button_styles_selected,
}

-- ================================================================
-- Settings UI scratch state (current edits, popup flags, picked
-- color, alert preview buffer, etc.).
-- ================================================================
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

-- ================================================================
-- Debug window state.
-- ================================================================
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

-- ================================================================
-- Text-parser working state.  Updated continuously by parseThis,
-- CombatText, and CombatSpellText as messages flow in.
-- ================================================================
M.par = {
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

-- ================================================================
-- Chat-buffer state.  ChatBuffer is the per-tab message store;
-- everything else tracks indices, sizes, and rotation cursors.
-- ================================================================
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

-- ================================================================
-- GDI font / rect render-object handles, indexed per chat window.
-- ================================================================
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

-- ================================================================
-- Persisted user settings + companion color tables.  `colors` is
-- glued onto allSettings post-construction so the colorset behaves
-- like a settings sub-table.
-- ================================================================
M.allSettings   = defaults.default_settings()
M.defaultColors = defaults.default_colors()
M.allSettings.colors = M.defaultColors

M.colorDesc      = defaults.color_descriptions
M.gamepadButtons = defaults.default_gamepad()

-- Replace contents of `M.allSettings` in-place with the contents of
-- `loaded`, preserving the table identity.  Required because every
-- module that imports state.lua aliases `state.allSettings` once at
-- module-load time; if fancychat.lua reassigned the local with the
-- result of `settings.load(...)` (which returns a new table), all
-- those aliases would silently keep pointing at the pre-load table
-- and never see user-saved values.
-- Ashita's `settings.save(alias)` reads from `settingslib.cache[alias]
-- .settings`, which is set to whatever `settings.load` returned at
-- load time.  Because we discard that returned table here, the cache
-- entry must be redirected at our shared table or future saves would
-- persist whatever empty stub the cache still points at.
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
