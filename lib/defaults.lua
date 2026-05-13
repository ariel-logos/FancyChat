-- lib/defaults.lua — initial-state factories (default_*) and styling
-- constants.  Pure data; sole side effect is utils.LoadTextures().

require('common')
require('imgui')  -- populates ImGuiWindowFlags_* globals used in default_fcw
local gdi   = require('gdifonts.include')
local utils = require('utils')

local M = {}

-- ================================================================
-- UIWindow state — memory pointers, FFXI-side menu/window tracking.
-- ================================================================
function M.default_uiw()
	return T{
		NetStatObj         = T{0, 1},
		UpperMenuPTR       = nil,
		MenuDescPTR        = nil,
		MenuDesc           = nil,
		LegacyChatOpen     = false,
		LastMenu           = {'', 0},
		MenuCD             = 0,
		InvIdx             = 0,
		NoShiftIdx         = 0,
		MenuExt            = 0,
		MenuList           = {},
		WasInEquip         = false,
		WasInInv           = false,
		DialogPromptStart  = 0,
		DialogCDStart      = 0,
		DialogShown        = false,
		RefWinOpenPtr      = nil,
		RefWinOpenPtr2     = nil,
		DialogPtr          = nil,
		WinOpenPtr         = nil,
		WinOpenPtr2        = nil,
		UISizeYPtr         = nil,
		UISizeXPtr         = nil,
		EventPtr           = nil,
		UISizeX            = nil,
		UISizeY            = nil,
		WinPtr1            = nil,
		WinPtr2            = nil,
		InputWinOpen       = nil,
		MemValue           = nil,
		LastMemValue       = -1,
	}
end

-- ================================================================
-- FancyChat windows — three indexed entries:
--   [1] primary chat (full state)
--   [2] secondary chat (subset)
--   [3] BigMode overlay (subset)
-- ================================================================
function M.default_fcw()
	return T{
		T{
			-- cexi
			LastCommands = T{
				{}, 0,
				{'/fish','/sit','/heal','/invite','/decline','/join','/follow','/map','/logout','/shutdown'},
				1
			},
			HasDoneServMes		  = false,
			WaitingServMes 		  = 0,
			BufferBusy            = false,
			WasRendered           = false,
			itemInfo              = {},
			itemIcons             = T{{}, {}, {}, {}},
			itemTexture           = T{{}, {}, {}, {}},
			autoHideCheckCD       = 0,
			autoHideFadeTime      = 0,
			autoHideFade          = 0,
			autoHideTime          = 0,
			isHiddenGUI           = false,
			LoginStatus           = nil,
			Zoning                = false,
			ProcessingText        = false,
			ErrorMsg              = '',
			GuideMeDocked         = true,
			NotepadDocked         = true,
			GuideMeClosedTmp      = false,
			NotepadClosedTmp      = false,
			GuideMeURL            = T{''},
			Note                  = T{''},
			GuideMeWalkthrough    = nil,
			PrevKeyptr            = T{0, 0, 0, 0},
			DraggingScroll        = false,
			ScrollPos             = 0,
			PrevMousePos          = T{0, 0},
			MoveChatPos1          = 0,
			MoveChatPos2          = 0,
			MoveChatPos3          = 0,
			MoveChatPos4          = 0,
			MoveChat              = false,
			PrevMoveChat          = false,
			InitDone              = false,
			Closing               = false,
			LoggedIn              = false,
			LoggedLobby           = 0,
			FirstLogin			  = 1,
			SaveStart             = 0,
			SaveCD                = 5,
			ReLogStart            = 0,
			ServMesCD             = 8,
			PlayerName            = '---',
			RoRectBaseX           = 0,
			RoRectBaseY           = 0,
			FWDBaseX              = 0,
			BKWBaseX              = 0,
			BKWBaseY              = 0,
			PositionLinesRequest  = {false, false},
			RequestAuxFix         = false,
			GuideMeOpened         = T{false},
			NotepadOpened         = T{false},
			Textures              = utils.LoadTextures(),
			HideChat              = false,
			PrevHideChat          = false,
			PrevAnchor_X          = -1,
			PrevAnchor_Y          = -1,
			Anchor_X              = 0,
			Anchor_Y              = 0,
			BGScale               = 1.25,
			BG_W                  = 0,
			BG_H                  = 0,
			TextureIDBorder       = nil,
			TextureIDSettings     = nil,
			TextureIDGuideMe      = nil,
			TextureIDLogs         = nil,
			TextureIDLoading      = nil,
			TextureIDFolder       = nil,
			TextureIDCompact      = nil,
			TextureIDManual       = nil,
			TextureIDInfo         = nil,
			TextureIDNotepad      = nil,
			TextureIDDumpchat     = nil,
			TextureIDLogo         = nil,
			HoverLine             = -1,
			Keydown               = false,
			Keydown2              = false,
			Keydown3              = false,
			Clicking              = false,
			Dragging              = false,
			Scrolling             = false,
			ScrollUpRequest       = false,
			ScrollDownRequest     = false,
			ScrolledBack          = 0,
			ScrollDelta           = 0,
			ChatShiftScale        = 0,
			ChatShiftScale_Min    = 50,
			ChatShiftScale_Base   = 50,
			ChatShiftScale_Target = 0,
			OsClockLast           = 0,
			OsClockLastFade       = 0,
			ChatShift             = 0,
			ChatHead              = 1,
			RenderFOs             = false,
			PosChanged            = true,
			TabsPos               = nil,
			compactPos            = nil,
			compactSize           = nil,
			windowFlagsChatBG = bit.bor(
				ImGuiWindowFlags_NoDecoration,
				ImGuiWindowFlags_NoResize,
				ImGuiWindowFlags_NoBringToFrontOnFocus,
				ImGuiWindowFlags_NoFocusOnAppearing,
				ImGuiWindowFlags_NoBackground
			),
			windowFlagsGuideMeDocked = bit.bor(
				ImGuiWindowFlags_NoResize,
				ImGuiWindowFlags_NoBringToFrontOnFocus,
				ImGuiWindowFlags_NoCollapse,
				ImGuiWindowFlags_NoMove,
				ImGuiWindowFlags_NoSavedSettings,
				ImGuiWindowFlags_NoNav
			),
			windowFlagsGuideMe = bit.bor(
				ImGuiWindowFlags_NoBringToFrontOnFocus,
				ImGuiWindowFlags_NoSavedSettings,
				ImGuiWindowFlags_NoNav
			),
		},
		T{
			RoRectBaseY           = 0,
			RequestAuxFix         = false,
			PositionLinesRequest  = {false, false},
			PrevAnchor_X          = -1,
			PrevAnchor_Y          = -1,
			Anchor_X              = 0,
			Anchor_Y              = 0,
			BGScale               = 1.25,
			BG_W                  = 0,
			BG_H                  = 0,
			HoverLine             = -1,
			Keydown               = false,
			Keydown2              = false,
			Clicking              = false,
			Dragging              = false,
			Scrolling             = false,
			ScrollUpRequest       = false,
			ScrollDownRequest     = false,
			ScrolledBack          = 0,
			ScrollDelta           = 0,
			ScrollPos             = 0,
			ChatShiftScale        = 0,
			ChatShiftScale_Min    = 50,
			ChatShiftScale_Base   = 50,
			ChatShiftScale_Target = 0,
			OsClockLast           = 0,
			OsClockLastFade       = 0,
			ChatShift             = 0,
			ChatHead              = 1,
			RenderFOs             = false,
			TabsPos               = nil,
			PosChanged            = true,
			compactPos            = nil,
			compactSize           = nil,
		},
		{
			HLeft                = 0,
			BigModePrev          = false,
			BigMode              = false,
			Clicking             = false,
			RoRectBaseY          = 0,
			ScrollPos            = 0,
			ChatLines            = 0,
			RequestAuxFix        = false,
			HoverLine            = -1,
			Keydown              = false,
			Keydown2             = false,
			Scrolling            = false,
			ScrollUpRequest      = false,
			ScrollDownRequest    = false,
			ScrolledBack         = 0,
			ScrollDelta          = 0,
			RenderFOs            = false,
			ChatShift            = 0,
			PositionLinesRequest = {false, false},
			ChatHead             = 1,
			PrevAnchor_X         = -1,
			PrevAnchor_Y         = -1,
			Anchor_X             = 0,
			Anchor_Y             = 0,
			BGScale              = 1.25,
			BG_W                 = 0,
			BG_H                 = 0,
		}
	}
end

-- ================================================================
-- Chat-message buffers, one per logical tab.
-- ================================================================
function M.default_chat_buffer()
	return T{
		{'All',       T{text = T{}, mode = T{}, color = T{}, auxText = T{}, auxColor = T{}, url = T{}}},
		{'AllAlt',    T{text = T{},             color = T{}, auxText = T{}, auxColor = T{}, url = T{}}},
		{'Combat',    T{text = T{},             color = T{}, auxText = T{}, auxColor = T{}, url = T{}}},
		{'Linkshell', T{text = T{},             color = T{}, auxText = T{}, auxColor = T{}, url = T{}}},
		{'Party',     T{text = T{},             color = T{}, auxText = T{}, auxColor = T{}, url = T{}}},
		{'Tell',      T{text = T{},             color = T{}, auxText = T{}, auxColor = T{}, url = T{}}},
		{'Shout',     T{text = T{},             color = T{}, auxText = T{}, auxColor = T{}, url = T{}}},
		{'Custom',    T{text = T{},             color = T{}, auxText = T{}, auxColor = T{}, url = T{}}},
	}
end

-- ================================================================
-- Persisted user settings (gets handed to Ashita's settings.load,
-- which fills in any missing defaults from this baseline).
-- ================================================================
function M.default_settings()
	return T{
		ver                  = '0',
		GamepadNav           = T{false},
		CompactTabsBL        = T{false},
		R0warning            = T{true},
		UseHalfLength        = T{false},
		PreciseTS            = T{false},
		MoveChatATMenu       = T{true},
		CustomFilters        = T{false},
		SelectedCombatFilter = 'example.txt',
		autoDumpChat         = T{false},
		CustomTabModes       = T{false, false, false, false, false},  -- npc, ls, party, tell, shout
		ItemPreview          = T{true},
		AutoHideWindow       = T{false},
		AutoHideTimeMax      = 10,
		Notes                = T{},
		CSMode               = {'Hide 2nd', 2},
		CompactCombat        = {true},
		CombatSplitChar      = {'Greater >', 0x003E},  -- alternatives: 0x7E ~, 0x2022 •, 0x2043 ⁃
		GuideMeSecondWindow  = T{false},
		GuideMeFontScale     = 1,
		EnableFastScroll     = T{true},
		EnabledChatMove      = T{false},
		LockWindowPos        = T{false},
		HelpButton           = T{true},
		CompactTabs          = false,
		PlayerName           = '---',
		FormatTSMode         = 1,
		SelectedTab          = 'All',
		SelectedTab2         = 'All',
		HideCombatFromAll    = T{false},
		SecondChat           = T{false},
		chatLineMaxL         = 100,
		ChatLines            = 8,
		WindowPosOffset      = T{0, 0, 0, 0},
		defaultColor         = 0xFFFFFFFF,
		ColorBlind           = T{false},
		shortcutHide         = 46,
		shortcutTab          = 45,
		shortcutTab2         = 48,
		shortcutBig          = 34,
		shortcutHideS        = 42,
		shortcutTabS         = 42,
		shortcutTab2S        = 42,
		shortcutBigS         = 42,
		shortcutHideEnabled  = T{false},
		shortcutTabEnabled   = T{false},
		shortcutTab2Enabled  = T{false},
		shortcutBigEnabled   = T{false},
		blockAll             = T{false},
		blockCombat          = T{false},
		timeStamp            = T{true},
		timeStampLine        = {false},
		timeStampLineFreq    = {'10 minutes', 600},
		hideNonParty         = T{true},
		hideNonYou           = T{false},
		hideAlliance         = T{true},
		heartEmoji           = T{false},
		EnableFCColorMarking = T{true},
		selectedNotification = 'notification_1',
		boostNotification    = T{false},
		tellNotification     = T{false},
		alertwords           = '',
		selectedAlert        = 'notification_1',
		boostAlert           = T{false},
		Alert                = T{false},
		alertOptions         = {false, true, true, true, true},
		firstLoadMessage     = T{false},
		settingsOpened       = T{false},
		fontSettings = {
			bg_overlap     = -2,
			box_height     = 0,
			box_width      = 0,
			font_alignment = 0,
			font_color     = 0xFFFFFFFF,
			font_family    = 'Consolas',
			font_flags     = gdi.FontFlags.Bold,
			font_height    = 20,
			gradient_color = 0x00000000,
			gradient_style = 0,
			opacity        = 1,
			outline_color  = 0xFF000000,
			outline_width  = 2,
			position_x     = 0,
			position_y     = 0,
			text           = '',
			visible        = true,
			z_order        = 0,
			background     = {visible = true, fill_color = 0x00000000},
		},
		rectSettings = {
			width           = 100,
			height          = 100,
			corner_rounding = 0,
			outline_color   = 0xFF000000,
			outline_width   = 0,
			fill_color      = 0x4D000000,
			gradient_style  = 0,
			gradient_color  = 0x00000000,
			position_x      = 0,
			position_y      = 0,
			visible         = true,
			z_order         = -1,
		},
	}
end

-- ================================================================
-- Default per-mode color set (ARGB).  Two-element entries provide
-- a colour-blind alternate in slot [2].
-- ================================================================
function M.default_colors()
	return {
		tell         = {0xFFD35AFF},
		party        = {0xFF66E7FE},
		shout        = {0xFFFF5E5E},
		linkshell1   = {0xFF50FFD0},
		linkshell2   = {0xFF00FF80},
		emote        = {0xFFC797FF},
		combat       = {0xFFDCF1FC},
		damage       = {0xFFFFFFFF},
		combatspell  = {0xFFDDC9FF},
		spelldamage  = {0xFFF0FFF0},
		lot          = {0xFFE2FA0C},
		attain       = {0xFFFFE438},
		obtained     = {0xFFA1FF3D},
		keyitem      = {0xFFC797FF},
		learn        = {0xFF5C71FF},
		found        = {0xFFE5FF3D},
		ability      = {0xFFF3A6FF},
		you          = {0xFF00FFC1},
		actor1       = {0xFF6BD5FF},
		actor2       = {0xFFF7CF05},
		helm         = {0xFFE5FF3D},
		useitem      = {0xFFF58FFF},
		negative     = {0xFFFF5640},
		-- Both error slots default to the colours previously hardcoded
		-- in utils.modesDA for FFXI chat modes 123 and 157.  Customisable
		-- from Settings -> Font Colors as "Error (main)" / "Error (other)".
		error1       = {0xFFFF0090},
		error        = {0xFFFF44BB},
		roe			 = {0xFFF56C42},
		dmgdone      = {0xFF91FF47, 0xFF91FFF0},
		dmggot       = {0xFFFA4343, 0xFFFFA269},
		spelldmgdone = {0xFFADFF33, 0xFF5EE0DE},
		spelldmggot  = {0xFFFC2B43, 0xFFE6874C},
		cexi         = {0xFF00FFB3, 0xFFFF0055},
	}
end

-- ================================================================
-- Human-readable labels + tooltips for each color slot, used by the
-- Settings UI's Font Colors tab.  Constant — exported by reference.
-- ================================================================
M.color_descriptions = {
	tell         = {'Tell',                '/tell messages'},
	party        = {'Party',               '/party messages'},
	shout        = {'Shout',               '/shout messages'},
	linkshell1   = {'Linkshell 1',         '/linkshell messages'},
	linkshell2   = {'Linkshell 2',         '/linkshell2 messages'},
	emote        = {'Emotes',              '/emote messages'},
	combat       = {'Combat',              'Combat base color'},
	damage       = {'Combat Damage',       'Default DMG color'},
	combatspell  = {'Combat Spell',        'Spell base color'},
	spelldamage  = {'Spell Dmg (Default)', 'Default spell DMG color'},
	lot          = {'Lot Cast',            'Casting lot color'},
	attain       = {'Attain',              'For level up and other character progression messages'},
	obtained     = {'Obtain/Gain',         'For messages such as x obtains/gains y'},
	keyitem      = {'Key Item',            'Obtained key item messages'},
	learn        = {'Learn',               'Learning new skills/spells messages'},
	found        = {'Drops',               'For messages such as Found on x: y'},
	dmgdone      = {'Damage Done',  	   'Highlights damage done by you or enemy missed attacks.'},
	dmggot       = {'Damage Taken',  	   'Highlights damage taken by you or your missed attacks.'},
	spelldmgdone = {'Spell Dmg Done',      'Highlights spell damage done'},
	spelldmggot  = {'Spell Dmg Taken',     'Highlights spell damage taken'},
	cexi         = {'CEXI',                'CEXI content messages'},
	ability      = {'Ability/Spell',       'Highlights an ability or spell used by an Entity'},
	you          = {'You',                 'Color highlighting youin combat text.'},
	actor1       = {'Friend Entity',       'Color highlighting the friendly entity in combat text.\n(i.e. the player, party members, etc.'},
	actor2       = {'Foe Entity',          'Color highlighting the foe entity in combat text.\n(i.e. a monster, boss, etc.'},
	helm         = {'HELM result',         'Color highlighting the yelded item from an HELM action'},
	useitem      = {'Using Items',            'Color highlighting the use of an item'},
	negative     = {'Negative Effect',     'Color that notifies a potential negative action (e.g. throwing items away)'},
	error1       = {'Error (main)',        'Primary FFXI error / "can\'t do that" messages.'},
	error        = {'Error (other)',       'Secondary FFXI error messages.'},
	roe			 = {'RoE Messages',        'Color of Records of Emenince messages'},
}

-- ================================================================
-- Tab-button color schemes (constant, exported by reference).
-- ================================================================
M.tab_button_styles_normal = {
	T{ImGuiCol_Text,          {1.0, 1.0, 1.0, 0.8}},
	T{ImGuiCol_Button,        {0,   0,   0,   0.3}},
	T{ImGuiCol_ButtonActive,  {0,   0,   0,   1.0}},
	T{ImGuiCol_ButtonHovered, {0.5, 0.5, 0.5, 0.7}},
	T{ImGuiCol_FrameBg,        {0,   0,   0,   0}},
	T{ImGuiCol_FrameBgHovered, {0,   0,   0,   0}},
	T{ImGuiCol_FrameBgActive,  {0,   0,   0,   0}},
}

M.tab_button_styles_selected = {
	T{ImGuiCol_Text,          {0.1, 0.1, 0.1, 0.9}},
	T{ImGuiCol_Button,        {0.8, 0.8, 0.8, 0.5}},
	T{ImGuiCol_ButtonActive,  {1,   1,   1,   1.0}},
	T{ImGuiCol_ButtonHovered, {0.7, 0.7, 0.7, 0.7}},
}

-- ================================================================
-- Initial gamepad-state record.
-- ================================================================
function M.default_gamepad()
	return {
		enabled         = false,
		scroll1         = 0,
		scroll2         = 0,
		buttonsCD       = 0,
		buttonsCDready  = false,
		analogCD        = 0,
		analogCDready   = false,
		pressedEnter    = false,
	}
end

return M
