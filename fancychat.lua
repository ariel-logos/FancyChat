addon.name      = 'fancychat';
addon.author    = 'Arielfy';
--addon.version   = '0.9';
addon.desc      = 'Fancy Chat!';
addon.link      = '';

require('common');
local imgui = require('imgui');
local fonts = require('fonts');
local settings  = require('settings');
local ffi = require('ffi');
local d3d       = require('d3d8');
local C         = ffi.C;
local d3d8dev   = d3d.get_device();
local user32 = ffi.load("user32");
local kernel32 = ffi.load("kernel32");
local gdi = require('gdifonts.include');
--local encoding = require('gdifonts.encoding');
local utils = require('utils');
local targets = require ('targets');
local help = require('help');
local http = require("socket.http")
local imguiWrap = require('imguiWrap')

local ver = '0.9.260228'
addon.version = ver

local uiw = T{
		NetStatObj = T{0,1},
		UpperMenuPTR,
		MenuDescPTR,
		MenuDesc,
		LegacyChatOpen = false,
		LastMenu = {'',0},
		MenuCD = 0,
		InvIdx = 0,
		NoShiftIdx = 0,
		MenuExt = 0,
		MenuList = {},
		WasInEquip = false,
		WasInInv = false,
		DialogPromptStart = 0,
		DialogCDStart = 0,
		DialogShown = false,
		RefWinOpenPtr,
		RefWinOpenPtr2,
		DialogPtr,
		WinOpenPtr,
		WinOpenPtr2,
		UISizeYPtr,
		UISizeXPtr,
		EventPtr,
		UISizeX,
		UISizeY,
		WinPtr1,
		WinPtr2,
		InputWinOpen,
		MemValue,
		LastMemValue = -1,
};

local mvc_Menu1 = false;
local mvc_Menu2 = false;
local mvc_Menu3 = false;
local mvc_Menu4 = false;
local mvc_Menu5 = false;
local mvc_Menu6 = false;
local mvc_targetposY = 0;
local mvc_targetposX = 0;

-- Fancy chat window variables --

local fcw = T{
	T{	
		--cexi
		LastCommands = T{{}, 0, {'!mog','!chef','!signet','!sanction','!sigil','!ventures','!points','!prestige','!fatigue','!currency','!dailies','!pops'}, 1},
		BufferBusy = false,
		WasRendered = false,
		itemInfo = {},
		itemIcons = T{{},{},{},{}},
		itemTexture = T{{},{},{},{}},
		autoHideCheckCD = 0,
		autoHideFadeTime = 0,
		autoHideFade = 0,
		autoHideTime = 0,
		isHiddenGUI = false,
		LoginStatus,
		Zoning = false,
		ProcessingText = false,
		--OutlineColor = 0xFF000000,
		ErrorMsg = '',
		GuideMeDocked = true,
		NotepadDocked = true,
		GuideMeClosedTmp = false,
		NotepadClosedTmp = false,
		GuideMeURL = T{''},
		Note = T{''},
		GuideMeWalkthrough,
		PrevKeyptr = T{0, 0, 0, 0},
		DraggingScroll = false,
		ScrollPos = 0,
		PrevMousePos = T{0, 0},
		MoveChatPos1 = 0,
		MoveChatPos2 = 0,
		MoveChatPos3 = 0,
		MoveChatPos4 = 0,
		MoveChat = false,
		PrevMoveChat = false,
		InitDone = false,
		Closing = false,
		LoggedIn = false,
		LoggedLobby = 0,
		SaveStart = 0,
		SaveCD = 5,
		ReLogStart = 0,
		ReLogCD = 2,
		PlayerName = '-1',
		RoRectBaseX = 0,
		RoRectBaseY = 0,
		FWDBaseX = 0,
		BKWBaseX = 0,
		BKWBaseY = 0,
		PositionLinesRequest = {false, false},
		RequestAuxFix = false,
		GuideMeOpened = T{false},
		NotepadOpened = T{false},
		Textures = utils.LoadTextures(),
		HideChat = false,
		PrevHideChat = false,
		PrevAnchor_X = -1;
		PrevAnchor_Y = -1,
		Anchor_X = 0,
		Anchor_Y = 0,
		BGScale = 1.25,
		BG_W = 0,
		BG_H = 0,
		TextureIDBorder,
		TextureIDSettings,
		TextureIDGuideMe,
		TextureIDLogs,
		TextureIDLoading,
		TextureIDFolder,
		TextureIDCompact,
		TextureIDManual,
		TextureIDInfo,
		TextureIDNotepad,
		TextureIDDumpchat,
		HoverLine = -1,
		Keydown = false,
		Keydown2 = false,
		Keydown3 = false,
		Clicking = false,
		Dragging = false,
		Scrolling = false,
		ScrollUpRequest = false,
		ScrollDownRequest = false,
		ScrolledBack = 0,
		ScrollDelta = 0,
		ChatShiftScale = 0,
		ChatShiftScale_Min = 50,
		ChatShiftScale_Base = 50,
		ChatShiftScale_Target = 0,
		OsClockLast = 0,
		OsClockLastFade = 0,
		ChatShift = 0,
		ChatHead = 1,
		RenderFOs = false,
		PosChanged = true,
		TabsPos,
		compactPos,
		compactSize,
		windowFlagsChatBG = bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_NoResize , ImGuiWindowFlags_NoBringToFrontOnFocus, ImGuiWindowFlags_NoFocusOnAppearing,ImGuiWindowFlags_NoBackground ),
		windowFlagsGuideMeDocked = bit.bor( ImGuiWindowFlags_NoResize , ImGuiWindowFlags_NoBringToFrontOnFocus,ImGuiWindowFlags_NoCollapse,ImGuiWindowFlags_NoMove, ImGuiWindowFlags_NoSavedSettings, ImGuiWindowFlags_NoNav),
		windowFlagsGuideMe = bit.bor( ImGuiWindowFlags_NoBringToFrontOnFocus, ImGuiWindowFlags_NoSavedSettings, ImGuiWindowFlags_NoNav),
	},
	T{
		--OutlineColor = 0xFF000000,
		RoRectBaseY = 0,
		RequestAuxFix = false,
		PositionLinesRequest = {false,false},
		PrevAnchor_X = -1,
		PrevAnchor_Y = -1,
		Anchor_X = 0,
		Anchor_Y = 0,
		BGScale = 1.25,
		BG_W = 0,
		BG_H = 0,
		HoverLine = -1,
		Keydown = false,
		Keydown2 = false,
		Clicking = false,
		Dragging = false,
		Scrolling = false,
		ScrollUpRequest = false,
		ScrollDownRequest = false,
		ScrolledBack = 0,
		ScrollDelta = 0,
		ScrollPos = 0,
		ChatShiftScale = 0,
		ChatShiftScale_Min = 50,
		ChatShiftScale_Base = 50,
		ChatShiftScale_Target = 0,
		OsClockLast = 0,
		OsClockLastFade = 0,
		ChatShift = 0,
		ChatHead = 1,
		RenderFOs = false,
		TabsPos,
		PosChanged = true,
		compactPos,
		compactSize,
	},
	{
		HLeft = 0,
		BigModePrev = false,
		BigMode = false,
		Clicking = false,
		RoRectBaseY = 0,
		ScrollPos = 0,
		ChatLines = 0,
		RequestAuxFix = false,
		HoverLine = -1,
		Keydown = false,
		Keydown2 = false,
		Clicking = false,
		Scrolling = false,
		ScrollUpRequest = false,
		ScrollDownRequest = false,
		ScrolledBack = 0,
		ScrollDelta = 0,
		RenderFOs = false,
		ChatShift = 0,
		PositionLinesRequest = {false,false},
		ChatHead = 1,
		PrevAnchor_X = -1,
		PrevAnchor_Y = -1,
		Anchor_X = 0,
		Anchor_Y = 0,
		BGScale = 1.25,
		BG_W = 0,
		BG_H = 0,
	}
}

-- Tabs window variables --

local tab_NextTab = 'All';
local tab_NextTab2 = 'All';
local tab_Tabs = {'All','Combat','Linkshell','Party','Tell','Shout','Custom'};
--local tab_Tabs_Alt = {'All','Combat','Linkshell','Party','Tell','Shout','Custom'};
local tab_ButtonColorStylesNormal = {
	T{ImGuiCol_Text,                 {1.0, 1.0, 1.0, 0.8}},  
	T{ImGuiCol_Button,               {0, 0, 0, 0.3}},              
	T{ImGuiCol_ButtonActive,         {0, 0, 0, 1.0}},              
	T{ImGuiCol_ButtonHovered,        {0.5, 0.5, 0.5, 0.7}},
	T{ImGuiCol_FrameBg, 			 {0, 0, 0, 0}}, 
	T{ImGuiCol_FrameBgHovered, 		 {0, 0, 0, 0}}, 
	T{ImGuiCol_FrameBgActive,		 {0, 0, 0, 0}}, 
}
local tab_ButtonColorStylesSelected = {
	T{ImGuiCol_Text,                 {0.1, 0.1, 0.1, 0.9}},  
	T{ImGuiCol_Button,               {0.8, 0.8, 0.8, 0.5}},              
	T{ImGuiCol_ButtonActive,         {1, 1, 1, 1.0}},              
	T{ImGuiCol_ButtonHovered,        {0.7, 0.7, 0.7, 0.7}},
}

-- Settings window variables --
local set_isCEXI = true
local set_colorTextW = 1
local set_alertList = {} 
local set_alertBuffer = T{}
local set_Popup = {false}
local set_PickedColor = T{1,1,1,1}
local set_ChatLineMaxL = 100
local set_PlateBGColor = 0x4D000000
local set_FontHeight = 20;
local set_ChatLines = 8;
local set_CustomTabModes = T{}
local set_SecondChat = T{false}
local set_AdjWin1 = T{false};
local set_AdjWin2 = T{false};
local set_CombatSplitCharList = {{'Greater >',0x003E}, {'Column :',0x0589}, {'Tilde ~',0x007E}, {'Bullet',0x2022}, {'Bullet hypen',0x2043}, {'R.Triangle',0x25B6}, {'Arrow ->',0x2192},{'Arrow (big) ->',0x1F81E}};

-- Debug window variables --
local dw_PLRCount = 0;
local dw_WindowOpened = T{false};
local dw_TestMessage = '';
local dw_TestMessage2 = '';
local dw_ShowMessageMode = T{false};
local dw_ChannelColorMode = T{false};
local dw_testPTR;
local dw_frameID = 1
local dw_addr = 0

-- Text parsing variables --
local par_tabmode
local par_checkAgain = {0, ''}
local par_emojiChannels = {6,14,205,213,214,217};
local par_allowed = {0, 0};
local par_dumping = false;
local par_LastMsgLength = 0;
local par_customFilters = {};
local par_timePrinted = true;
local par_InEvent = false;
local par_LastMsgInConv = false;
local par_LastTS = '';
local par_CombatCutIdx = 0;
local par_FormatTS = {'[%H:%M:%S]', '[%H:%M]'};
local par_LastMessage = '';
local par_IsInConv = false;
local par_DamageDone = false;
local par_DamageGot = false;
local par_MessageMode;
local par_LastMode = '';
local par_isCustom = false;
local par_LastMessageMode = 0;
local par_promptEnd = {};
local par_actor1 = '';
local par_actor2 = '';
local par_actorP = '';
local par_actorE = '';
local par_action1 = '';
local par_isDamage = false;
local par_handled_actors = false;
local par_party_names = {};

-- Chat buffers variables --
local b_LogBuffer = T{}; --<<<--------------------DELETE FOR RELEASE----------------
local b_OriginalBuffer = T{};
local b_msgID = 1;
local b_ChatBufferMaxSize = 600;
local b_CombatBufferMaxSize = 300;
local b_ChatBufferN_All = 0;
local b_ChatBufferN_AllAlt = 0;
local b_ChatBufferN_Linkshell = 0;
local b_ChatBufferN_Party = 0;
local b_ChatBufferN_Tell = 0;
local b_ChatBufferN_Combat = 0;
local b_ChatBufferN_Shout = 0;
local b_ChatBufferN_Custom = 0;
local b_CleanupThresh = 100;
local b_ChatBufferIdx = T{0, 0, 0};
local b_ChatBufferN = T{0, 0, 0};
local b_ChatBufferMode = T{1, 1}; -- 1=All, 2=combat, 3=Linkshell, 4=Party, 5= tell,  6=shout, 7 = Custom
local b_ChatBuffer = T{
	{	'All',		T{ text = T{};	mode = T{}; color = T{}; auxText = T{}; auxColor = T{}; url = T{};} },
	{	'AllAlt',	T{ text = T{};  color = T{}; auxText = T{}; auxColor = T{}; url = T{};}	},
	{	'Combat',	T{ text = T{};  color = T{}; auxText = T{}; auxColor = T{}; url = T{};}	},
	{	'Linkshell',T{ text = T{};  color = T{}; auxText = T{}; auxColor = T{};	url = T{};}	},
	{	'Party',	T{ text = T{};  color = T{}; auxText = T{}; auxColor = T{};	url = T{};}	},
	{	'Tell',		T{ text = T{};  color = T{}; auxText = T{}; auxColor = T{};	url = T{};}	},
	{	'Shout',	T{ text = T{};  color = T{}; auxText = T{}; auxColor = T{};	url = T{};}	},
	{	'Custom',		T{ text = T{};  color = T{}; auxText = T{}; auxColor = T{};	url = T{};}	}
};

-- Font/Rect objects --

local fo_Fwd = T{};
local fo_Bkw = T{};
local fo_Chat = T{T{}, T{}, T{}};
local fo_Aux =  T{T{}, T{}, T{}};
local ro_RectBG = T{};
local ro_Scroll = T{};
local ro_BigMode;
local fo_BigMode;

local allSettings = T{
	ver = '0',
	GamepadNav = T{false},
	CompactTabsBL = T{false},
	R0warning = T{true},
	UseHalfLength = T{false},
	PreciseTS = T{false},
	--BigModeWarning = T{false},
	MoveChatATMenu = T{true},
	CustomFilters = T{false},
	autoDumpChat = T{false},
	CustomTabModes = T{false, false, false, false, false}, --npc, ls, party, tell, shout
	ItemPreview = T{true},
	AutoHideWindow = T{false},
	AutoHideTimeMax = 10,
	Notes = T{},
	CSMode = {'Hide 2nd', 2}, 
	CompactCombat = {true},
	CombatSplitChar = {'Greater >',0x003E},  -- greater 0x3E, tilde 0x7E, bullet 0x2022, hypen bullet 0x2043
	GuideMeSecondWindow = T{false},
	GuideMeFontScale = 1,
	EnableFastScroll = T{true},
	EnabledChatMove = T{false},
	LockWindowPos = T{false},
	CompactTabs = false,
	PlayerName = '---',
	FormatTSMode = 1,
	SelectedTab = 'All',
	SelectedTab2 = 'All',
	HideCombatFromAll = T{false},
	SecondChat = T{false},
	chatLineMaxL = 100,
	ChatLines = 8,
	WindowPosOffset =	T{0,0,0,0},
	defaultColor = 0xFFFFFFFF,
	ColorBlind = 		T{false},
	shortcutHide = 	46,
	shortcutTab = 	45,
	shortcutTab2 = 	48,
	shortcutBig = 	34,
	shortcutHideS = 42,
	shortcutTabS = 	42,
	shortcutTab2S = 42,
	shortcutBigS = 	42,
	shortcutHideEnabled = T{false},
	shortcutTabEnabled = T{false},
	shortcutTab2Enabled = T{false},
	shortcutBigEnabled = T{false},
	blockAll = 		T{false},
	blockCombat = 	T{false},
	timeStamp = 	T{true},
	timeStampLine = {false},
	timeStampLineFreq = {'10 minutes', 600},
	hideNonParty = 	T{true},
	hideNonYou = 	T{false},
	hideAlliance = 	T{true},
	heartEmoji =	T{false},
	selectedNotification = 'notification_1',
	boostNotification =T{false},
	tellNotification = T{false},
	alertwords = '',
	selectedAlert = 'notification_1',
	boostAlert =T{false},
	Alert = T{false},
	alertOptions = {false,true,true,true,true},
	firstLoadMessage = T{false},
	settingsOpened = T{false},
	fontSettings = {    
		bg_overlap = -2,
		box_height = 0,
		box_width = 0,
		font_alignment = 0,
		font_color = 0xFFFFFFFF,
		font_family = 'Consolas',  
		font_flags = gdi.FontFlags.Bold,
		font_height = 20,
		gradient_color = 0x00000000,
		gradient_style = 0,
		opacity = 1,
		outline_color = 0xFF000000,
		outline_width = 2,
		position_x = 0,
		position_y = 0,
		text = '',
		visible = true,
		z_order = 0,
		background = { visible = true, fill_color = 0x00000000 }
	},
	rectSettings = {
		width = 100,
		height = 100,
		corner_rounding = 0,
		outline_color = 0xFF000000,
		outline_width = 0,
		fill_color = 0x4D000000,
		gradient_style = 0,
		gradient_color = 0x00000000,
    	position_x = 0,
		position_y = 0,
		visible = true,
		z_order = -1,
	},
}

local defaultColors = {
	tell 			= {0xFFD35AFF},
	--party 			= {0xFF7BD3FF},
	party 			= {0xFF66E7FE},
	shout			= {0xFFFF5E5E},
	linkshell1		= {0xFF50FFD0},
	linkshell2		= {0xFF00FF80},
	emote			= {0xFFC797FF},
	combat			= {0xFFDCF1FC},
	damage			= {0xFFFFFFFF},
	combatspell		= {0xFFDDC9FF},
	spelldamage		= {0xFFF0FFF0},
	lot				= {0xFFE2FA0C},
	attain			= {0xFFFFE438},
	obtained		= {0xFFA1FF3D},
	keyitem			= {0xFFC797FF},
	learn			= {0xFF5C71FF},
	found			= {0xFFE5FF3D},
	ability			= {0xFFF3A6FF},
	--you				= {0xFF6BD5FF},
	you				= {0xFF00FFC1},
	actor1			= {0xFF6BD5FF},
	actor2			= {0xFFF7CF05},
	helm			= {0xFFE5FF3D},
	useitem			= {0xFFF58FFF},
	negative		= {0xFFFF5640},
	dmgdone			= {0xFF91FF47, 0xFF91FFF0},
	dmggot			= {0xFFFA4343, 0xFFFFA269},
	spelldmgdone 	= {0xFFADFF33, 0xFF5EE0DE},
	spelldmggot		= {0xFFFC2B43, 0xFFE6874C},
	cexi			= {0xFF00FFB3, 0xFFFF0055},
}

allSettings.colors = defaultColors

local colorDesc =
{
	tell 			= {'Tell','/tell messages'},
	party 			= {'Party','/party messages'},
	shout			= {'Shout','/shout messages'},
	linkshell1		= {'Linkshell 1','/linkshell messages'},
	linkshell2		= {'Linkshell 2','/linkshell2 messages'},
	emote			= {'Emotes','/emote messages'},
	combat			= {'Combat','Combat base color'},
	damage			= {'Damage (Default)','Default DMG color'},
	combatspell		= {'Combat Spell','Spell base color'},
	spelldamage		= {'Spell Dmg (Default)','Default spell DMG color'},
	lot				= {'Cast Lot','Casting lot color'},
	attain			= {'Attain','For level up and other character progression messages'},
	obtained		= {'Obtain/Gain', 'For messages such as x obtains/gains y'},
	keyitem			= {'Key Item','Obtained key item messages'},
	learn			= {'Learn','Learning new skills/spells messages'},
	found			= {'Drops','For messages such as Found on x: y'},
	dmgdone			= {'Your Damage Done', 'Highlights damage done by you or enemy missed attacks.'},
	dmggot			= {'Your Damage Taken', 'Highlights damage taken by you or your missed attacks.'},
	spelldmgdone 	= {'Your Spell Dmg Done', 'Highlights spell damage done'},
	spelldmggot		= {'Yor Spell Dmg Taken', 'Highlights spell damage taken'},
	cexi			= {'CEXI', 'CEXI content messages'},
	ability			= {'Ability/Spell', 'Highlights an ability or spell used by an Entity'},
	you				= {'You', 'Color highlighting youin combat text.'},
	actor1			= {'Friend Entity', 'Color highlighting the friendly entity in combat text.\n(i.e. the player, party members, etc.'},
	actor2			= {'Foe Entity', 'Color highlighting the foe entity in combat text.\n(i.e. a monster, boss, etc.'},
	helm			= {'HELM result', 'Color highlighting the yelded item from an HELM action'},
	useitem			= {'Item Use', 'Color highlighting the use of an item'},
	negative		= {'Negative Effect', 'Color that notifies a potential negative action (e.g. throwing items away)'},
}

local gamepadButtons = {
	enabled = false,	
	scroll1 = 0,
	scroll2 = 0,
	buttonsCD = 0,
	buttonsCDready = false,
	analogCD = 0,
	analogCDready = false,
	pressedEnter = false,
}

ashita.events.register('d3d_present', 'present_cb', function ()

	
	--dw_frameID = dw_frameID + 1;
	--AshitaCore:GetChatManager():AddChatMessage(24, false, 'attack')
	
	--timeStart = os.clock()
	
	--	print('hello')--..tostring(os.clock())
	fcw[1].LoginStatus = AshitaCore:GetMemoryManager():GetPlayer():GetLoginStatus();
	--Debug(tostring(fcw[1].LoginStatus)..' - '..tostring(fcw[1].ReLogStart), 1, false)
	
	--local loginStatus = AshitaCore:GetMemoryManager():GetPlayer():GetLoginStatus();
	if not fcw[1].InitDone then
		Init();
	end
	--if GetPlayerEntity() then  fcw[1].LobbyCD = os.clock() fcw[1].LoggedIn = true end
	if fcw[1].LoginStatus == 2 then
		fcw[1].LoggedIn = true 
		local player = GetPlayerEntity();
		if fcw[1].PlayerName ~= '---' then 
			fcw[1].PlayerName = settings.name
			allSettings.PlayerName = settings.name
		end
	elseif fcw[1].LoginStatus == 1 then
		
	elseif fcw[1].LoginStatus == 0 then
		fcw[1].LoggedIn = false
		fcw[1].LoggedLobby = 1
	end
	--print(fcw[1].LoggedIn)
	--print(fcw[1].LobbyCD)
	--if os.clock() - fcw[1].LobbyCD > 10 then fcw[1].LoggedLobby = 1; end
	--if fcw[1].PlayerName == '---' then
	--end
	-- if #settings.name > 0 and fcw[1].PlayerName ~= '---' then
		-- --if settings.name ~= fcw[1].PlayerName then  fcw[1].LoggedLobby = 0 end
		-- fcw[1].PlayerName = settings.name
		-- allSettings.PlayerName = settings.name
		
	-- end
	--fcw[1].LoggedIn = true
	--Debug(tostring(fcw[1].LoggedIn),1,false);
	--if fcw[1].LoggedIn and AshitaCore:GetMemoryManager():GetParty():GetMemberName(0) then
	if fcw[1].LoggedIn and not fcw[1].Closing and not fcw[1].Zoning then
		--print(fcw[1].LoggedLobby)
		if (fcw[1].LoggedLobby == 1 or (fcw[1].PlayerName == '---')) then
			if fcw[1].ReLogStart == 0 then
				fcw[1].ReLogStart = os.clock()
			else
				if (os.clock() - fcw[1].ReLogStart > fcw[1].ReLogCD) then	
					--Debug('restarting', 1, false)
					--if fcw[1].LoggedLobby == 1 then fcw[1].LoggedLobby = 0; end
					allSettings.PlayerName = settings.name;
					SaveSettings();
					fcw[1].Closing = true;
					AshitaCore:GetChatManager():QueueCommand(-1, "/addon reload fancychat")
				end
			end
			return
		end;
		
		if AshitaCore:GetChatManager():IsInputOpen() ~= 0x11 then
			fcw[1].LastCommands[2] = 0
			fcw[1].LastCommands[4] = 0
		end
		local imIO = imgui.GetIO()
		local dsize = imIO.DisplaySize;
		--if imIO.KeysDown[10] then imgui.SetWindowFocus() end
		
		if allSettings.timeStampLine[1] then
			local secondsTime = os.time() % allSettings.timeStampLineFreq[2]
			--Debug(tostring(allSettings.timeStampLineFreq[2]), 1, false);
			if secondsTime == 0 then
				if par_timePrinted == false then
					-- local stringWrap = '';
					-- for _ = 1, math.floor((allSettings.chatLineMaxL)/2) - 5 do
						-- stringWrap = stringWrap..'\x81\xAC'
					-- end
					-- AshitaCore:GetChatManager():QueueCommand(1, '/echo '..stringWrap..os.date(par_FormatTS[2], os.time())..stringWrap);
					local tsline = string.rep('\x81\xAC',math.floor((allSettings.chatLineMaxL)/2) - 5)
					print(tsline..os.date(par_FormatTS[2], os.time())..tsline);
					par_timePrinted = true;
				end
			else
				par_timePrinted = false
			end;
		else
			par_timePrinted = true
		end
		
		if allSettings.R0warning[1] and uiw.NetStatObj[1] > 0 and ashita.memory.read_uint32(uiw.NetStatObj[1]) == 0 and uiw.NetStatObj[2] > 0 then	
			AshitaCore:GetChatManager():AddChatMessage(123, false, '[Warning] R0 detected.')
			AshitaCore:GetChatManager():AddChatMessage(123, false, 'Use /fchat savelogs to save chat logs.')
			--CEXI extra message
			AshitaCore:GetChatManager():AddChatMessage(123, false, 'If this is a server crash and you used a pop item, take a FULL screenshot as proof.')
		end
		
		uiw.NetStatObj[2] = ashita.memory.read_uint32(uiw.NetStatObj[1])
	
		fcw[1].PlayerName = settings.name;
		
		par_InEvent = ashita.memory.read_uint8(ashita.memory.read_uint32(uiw.EventPtr + 1)) == 1
		if par_InEvent then ResetAutoHideTimer() end

		uiw.MemValue = bit.band(ashita.memory.read_uint32(ashita.memory.read_uint32(uiw.WinPtr1)+0x42),0x0000FFFF);
		if (uiw.MemValue ~= 0) then
			local margin = 15;
			if (uiw.LastMemValue ~= -1 and uiw.LastMemValue >= uiw.MemValue and uiw.MemValue < uiw.UISizeY-19-margin) then
				if not uiw.LegacyChatOpen then
					if allSettings.autoDumpChat[1] then
						DumpChat()
					end
					b_OriginalBuffer = T{}
				end
				uiw.LegacyChatOpen = true;
			else
				if (uiw.LastMemValue ~= -1 and uiw.LastMemValue < uiw.MemValue) then
					uiw.LegacyChatOpen = false;
				end
			end
		end
		uiw.LastMemValue = uiw.MemValue;
		
		
		if (not fcw[1].HideChat) then
			--local WinPtr3 = ashita.memory.read_uint32(uiw.WinPtr1);
			--ashita.memory.unprotect(WinPtr3+0x2F,4)
			--ashita.memory.write_uint32(WinPtr3+0x2F,0x0100)
			
			local ptr = ashita.memory.read_uint32(uiw.WinPtr1);
			if (ptr ~= 0) then
				ashita.memory.unprotect(ptr + 0x34, 4);
				ashita.memory.write_uint32(ptr + 0x34, 0x00);
				uiw.Delay1 = ashita.memory.read_uint32(ptr + 0x34);
				
			end
			ptr = ashita.memory.read_uint32(uiw.WinPtr2);
			if (ptr ~= 0) then
				ashita.memory.unprotect(ptr + 0x34, 4);
				ashita.memory.write_uint32(ptr + 0x34, 0x00);
				uiw.Delay2 = ashita.memory.read_uint32(ptr + 0x34);
			end
		end
		

		local MenuName = ''; 
		local MenuID = ashita.memory.read_uint32(uiw.MenuPtr)
		if MenuID ~= 0 then
			---Debug(bit.tohex(ashita.memory.read_uint32(MenuID + 4) + 0x46),1,false)
			MenuName = ashita.memory.read_string(ashita.memory.read_uint32(MenuID + 4) + 0x46, 16);
			MenuName = string.gsub(MenuName, '\x00', ''):trimex()
			
			--uiw.MenuExt = ashita.memory.read_uint32(uiw.MenuPtr-0x40)
			if allSettings.EnabledChatMove[1] and allSettings.MoveChatATMenu[1] and (MenuName:match('menu[%s]+fep')) then mvc_Menu6 = true; else mvc_Menu6 = false; end
			if not MenuName:match('menu[%s]+inline') and not mvc_Menu6 then
				mvc_Menu1 = false;  mvc_Menu2 = false;  mvc_Menu3 = false;  mvc_Menu4 = false; mvc_Menu5 = false; mvc_Menu6 = false;
				if (MenuName:match('menu[%s]+inventor')) or (MenuName:match('menu[%s]+loot')) or (MenuName:match('menu[%s]+comyn')) or (MenuName:match('menu[%s]+comment')) then mvc_Menu1 = true; 
				elseif (MenuName:match('menu[%s]+magic')) or (MenuName:match('menu[%s]+ability'))  or (MenuName:match('menu[%s]+mount')) or (MenuName:match('menu[%s]+emote')) then mvc_Menu2 = true; 
				elseif (MenuName:match('menu[%s]+magselec')) then mvc_Menu3 = true; 
				elseif  (MenuName:match('menu[%s]+jobcselu')) then mvc_Menu4 = true;
				elseif (MenuName:match('menu[%s]+mogdoor')) or (MenuName:match('menu[%s]+arealist')) or (MenuName:match('menu[%s]+maplist')) or MenuName:match('menu[%s]+gmtell')  or MenuName:match('menu[%s]+merityn') then mvc_Menu5 = true;
				end
			--elseif mvc_Menu6 then
				--mvc_Menu6 = false
			end
			
		else
			mvc_Menu1 = false;  mvc_Menu2 = false;  mvc_Menu3 = false;  mvc_Menu4 = false; mvc_Menu5 =false; mvc_Menu6 =false;
			if imguiWrap.GetKeyDown(28) then ResetAutoHideTimer() end
		end
		if MenuName:find('auc1') and #uiw.MenuList > 0 and uiw.MenuList[#uiw.MenuList][1]=='menucomyn' then uiw.MenuList = {{'menuauc1',0}} end
		Debug(MenuName, 2, false);	
		if MenuID == 0 or MenuName:match('menu[%s]+menuwind') or MenuName:match('menu[%s]+playermo') then
			mvc_Menu1 = false;
			mvc_Menu2 = false;
			uiw.MenuList = {}
			--print('hello');
		else
			
			local MenuExt = ashita.memory.read_uint32(uiw.MenuPtr-0x3C)
			local MenuLabel = {MenuName:gsub('[%s]+',''), MenuExt,''};
			Debug(MenuLabel[1]..'-'..MenuLabel[2], 2, false);	
		
			if MenuLabel[1]=='menuinventor' then
				-- uiw.MenuDescPTR2 = ashita.memory.read_uint32(uiw.MenuDescPTR+0x54);
				-- uiw.MenuDescPTR2 = ashita.memory.read_uint32(uiw.MenuDescPTR2+0x0C);

				-- uiw.MenuDescPTR2 = ashita.memory.read_uint32(uiw.MenuDescPTR2+0x40);
				-- uiw.MenuDesc =  ashita.memory.read_string(uiw.MenuDescPTR2,64);
				-- MenuLabel[3] = uiw.MenuDesc;
				local UpperMenuPTR2 = ashita.memory.read_uint32(uiw.UpperMenuPTR+0x04)

				local UpperMenuPTR3 = ashita.memory.read_uint32(UpperMenuPTR2+0x14)

				local UpperMenuPTR4 = ashita.memory.read_uint32(UpperMenuPTR3+0x10)

				local UpperMenuPTR5 = ashita.memory.read_uint32(UpperMenuPTR4+0x2C)

				UpperMenuString = ashita.memory.read_string(UpperMenuPTR5,16)

				MenuLabel[3] = UpperMenuString;
				--if not tostring(uiw.MenuDesc):find('item') and dw_addr < 300  then dw_addr = dw_addr+1 end
				--Debug(tostring(UpperMenuString),1,false)
			end
			
			if MenuID ~= 0 and MenuLabel[1]~='menuinline' and MenuLabel[1]~='menumcr1pall' and MenuLabel[1]~= 'menumcr2pall' then
				for M_i = #uiw.MenuList-1, 1, -1 do
					--Debug(M_i,2,true);
					--print((MenuLabel[2] == 11));
					if 	((MenuLabel[1]==uiw.MenuList[M_i][1] and	MenuLabel[1]~='menuinventor')
						or
						--(MenuLabel[1]=='menuinventor'and MenuLabel[1]==uiw.MenuList[M_i][1] and uiw.MenuList[#uiw.MenuList][1]~='menuinventor') and MenuLabel[2] >= uiw.MenuList[M_i][2]
						(MenuLabel[1]=='menuinventor' and MenuLabel[1]==uiw.MenuList[M_i][1] and MenuLabel[3] == uiw.MenuList[M_i][3] and MenuLabel[2] >= uiw.MenuList[M_i][2])) and (LastMenu==nil or uiw.LastMenu[2] == MenuLabel[2] and uiw.LastMenu[1] == MenuLabel[1]		)				--change the uiw.MenuList[][2] at the first inventor+iuse				
						
					then
						-- if uiw.MenuList[M_i][1]=='menuinventor' and M_i+1 <= #uiw.MenuList and uiw.MenuList[M_i+1][1]=='menumoneyctr' then
							-- table.insert(uiw.MenuList, 1, {'menudummy2',0})
							-- --print('hello')
						-- end
						for R_i = M_i+1, #uiw.MenuList do
							table.remove(uiw.MenuList, #uiw.MenuList)
							--print( #uiw.MenuList);
						end
						if #uiw.MenuList > 0 and string.find(uiw.MenuList[1][1],'menuauc1') then
							table.insert(uiw.MenuList, 1, {'menudummy',0})
						end
					end
				end
				if #uiw.MenuList == 0 or uiw.MenuList[#uiw.MenuList][1]~= MenuLabel[1] then 
					table.insert(uiw.MenuList, MenuLabel) 
				end;
			end
			
			
			--[[
			if #uiw.MenuList == 0 or (#uiw.MenuList >= 1 and uiw.MenuList[#uiw.MenuList][1] ~= MenuLabel[1]) then
				if #uiw.MenuList >= 2 and uiw.MenuList[#uiw.MenuList-1][1] == MenuLabel[1] then
					if MenuLabel[1] == 'menuinventor' then
						if uiw.MenuList[#uiw.MenuList-1][2] ~= MenuLabel[2] then
							table.insert(uiw.MenuList, MenuLabel)
						end
					else
						table.remove(uiw.MenuList, #uiw.MenuList)	
					end
				else
					if MenuLabel[1] == 'menuauc1' and utils.FindInTableFind(uiw.MenuList, 'menuauc1', 1) then
						uiw.MenuList = {};
					end
					table.insert(uiw.MenuList, MenuLabel)
				end
			end
			]]--
			uiw.InvIdx = 0;
			uiw.NoShiftIdx = 0;
			
			for i = 1, #uiw.MenuList do
				if uiw.MenuList[i][1]:find('menuinventor') then uiw.InvIdx = i; 
				elseif uiw.MenuList[i][1]:find('menutskill1') then uiw.NoShiftIdx = i 
				elseif uiw.MenuList[i][1]:find('menuequip') then uiw.NoShiftIdx = i 
				elseif uiw.MenuList[i][1]:find('menudelivery') then uiw.NoShiftIdx = i 
				elseif uiw.MenuList[i][1]:find('menuhandover') then uiw.NoShiftIdx = i 
				elseif uiw.MenuList[i][1]:find('menutrade') then uiw.NoShiftIdx = i 
				elseif uiw.MenuList[i][1]:find('menubank%s*$') then uiw.NoShiftIdx = i 
				elseif uiw.MenuList[i][1]:find('lootope') then uiw.NoShiftIdx = i 
				elseif uiw.MenuList[i][1]:find('lootnowin') then uiw.NoShiftIdx = i 
				elseif uiw.MenuList[i][1]:find('moneyctr') then uiw.NoShiftIdx = i 
				elseif uiw.MenuList[i][1]:find('menushopsell') then uiw.NoShiftIdx = i
				elseif uiw.MenuList[i][1]:find('menudummy') then uiw.NoShiftIdx = i
				elseif uiw.MenuList[i][1]:find('menumcresed') then uiw.NoShiftIdx = i
				end
			end
			
			
			if uiw.InvIdx >0 then mvc_Menu1 = true; end
			if uiw.NoShiftIdx > 0 then mvc_Menu1 = false end
			if MenuLabel and (
				(MenuLabel[1] == 'menutrddummy') or
				(MenuLabel[1] == 'menucomyn')
				)
			then mvc_Menu1 = true end
			--Debug(tostring(uiw.MenuLabel~=nil and (uiw.MenuLabel[1] == 'menutrddummy' or uiw.MenuLabel[1] =='menurem4li2'),1,false))
			
			if #uiw.MenuList > 1 then
				if
					string.find(uiw.MenuList[#uiw.MenuList][1], 'sortw') and (
					string.find(uiw.MenuList[#uiw.MenuList-1][1], 'menumagic') or
					string.find(uiw.MenuList[#uiw.MenuList-1][1], 'menuability') or
					string.find(uiw.MenuList[#uiw.MenuList-1][1], 'menumount') or
					string.find(uiw.MenuList[#uiw.MenuList-1][1], 'menuemote') )
				then
					mvc_Menu2 = true;
					if #uiw.MenuList < 4 or uiw.MenuList[#uiw.MenuList-2][1] ~= uiw.MenuList[#uiw.MenuList-1][1] then table.insert(uiw.MenuList, #uiw.MenuList-1, uiw.MenuList[#uiw.MenuList-1]) end
				elseif 
					string.find(uiw.MenuList[#uiw.MenuList][1], 'sortyn') and (
					string.find(uiw.MenuList[#uiw.MenuList-2][1], 'menumagic') or
					string.find(uiw.MenuList[#uiw.MenuList-2][1], 'menuability') or
					string.find(uiw.MenuList[#uiw.MenuList-2][1], 'menumount') or
					string.find(uiw.MenuList[#uiw.MenuList-2][1], 'menuemote') )
				then 
					mvc_Menu2 = true;
				elseif
					(string.find(uiw.MenuList[#uiw.MenuList][1], 'menulootope') or				
					string.find(uiw.MenuList[#uiw.MenuList][1], 'menulnowin')) and
					string.find(uiw.MenuList[#uiw.MenuList-1][1], 'menuloot')
				then
					mvc_Menu1 = true;
				end
			end
			
			--end
		end
		uiw.LastMenu = MenuLabel;
		local list = '';
		for i = 1, #uiw.MenuList do
			list = list..','..uiw.MenuList[i][1]..'-'..tostring(uiw.MenuList[i][2])..'-'..tostring(uiw.MenuList[i][3])
		end
		--menu list
		--Debug(list,1,false);
				
		
		if (par_InEvent or MenuName:match('menu[%s]+query'))  or uiw.DialogCDStart ~= 0 or uiw.DialogPromptStart ~= 0 then
			if 	ashita.memory.read_uint32(uiw.DialogPtr) == 1
			then
				par_LastMsgInConv = false;
				uiw.DialogShown = true;
				uiw.DialogCDStart = os.clock();
				--uiw.DialogPromptStart = 0;
			else
				
				-- os.clock() - uiw.DialogCDStart > 0.1
			end
			
			if os.clock() - uiw.DialogCDStart > 0.2 then
				--uiw.DialogPromptStart = 0;
				uiw.DialogShown = false;
				uiw.DialogCDStart = 0;
			elseif par_InEvent then
				uiw.DialogCDStart = os.clock();
				
			end
			
			if not par_InEvent then
				uiw.DialogPromptStart = os.clock()
				par_LastMsgInConv = false;
				uiw.DialogShown = false;
			end
			
			if uiw.DialogPromptStart > 0 then
				if os.clock() - uiw.DialogPromptStart > 0.2 then
					
					uiw.DialogPromptStart = 0;
					uiw.DialogShown = false;
				else
					if ashita.memory.read_uint32(uiw.DialogPtr) == 1 then
					uiw.DialogPromptStart = 0;end
				end
			end
		end
		
		
		local chat2moved = false;
		if not fcw[1].MoveChat or not allSettings.SecondChat[1] then
			fcw[1].MoveChat = (mvc_Menu1 or mvc_Menu2 or mvc_Menu3 or mvc_Menu4 or mvc_Menu5 or mvc_Menu6 or uiw.DialogShown) and allSettings.LockWindowPos[1] and allSettings.EnabledChatMove[1];
		else
			chat2moved = true;
		end
		
	-- Settings FOs rendering flags --	
		if (uiw.LegacyChatOpen or fcw[1].HideChat) then
			fcw[1].RenderFOs = false;
		else
			fcw[1].RenderFOs = true;
		end

	-- Settings chat buffers according to the active tab --
		if (tab_NextTab ~= allSettings.SelectedTab) then
			fcw[1].BufferBusy = true;
			if #fo_Chat[3] > 0 then ResetScrolling(3, fcw[3].ChatLines) end
			ChangeTab(1, tab_NextTab);
			b_ChatBufferN[1] = SetBufferN(allSettings.SelectedTab);
			ResetScrolling(1);
			
			--GoToLine()
		else
			b_ChatBufferN[1] = SetBufferN(allSettings.SelectedTab);
		end
		
		
		
		
		-- if allSettings.SelectedTab == 'All' and allSettings.HideCombatFromAll[1] then b_ChatBufferN[1]=b_ChatBufferN_AllAlt;  end
		

		
		
		
		--Debug(tors(not LegacyChatOpen and not fcw[1].HideChat and not fcw[1].Closing)), 1, true);
	-- Render All FancyChat windows --
		local windowFlags = 0
		
		
		if AshitaCore:GetChatManager():IsInputOpen() ~= 0x00 then ResetAutoHideTimer() end
		if allSettings.AutoHideWindow[1] and os.clock() - fcw[1].autoHideCheckCD > 0.02 then
			fcw[1].autoHideCheckCD = os.clock()
			if (os.time() - fcw[1].autoHideTime > allSettings.AutoHideTimeMax) then
				if fcw[1].autoHideFadeTime == 0 then fcw[1].autoHideFadeTime = os.clock() end
				fcw[1].autoHideFade = (os.clock()-fcw[1].autoHideFadeTime)/0.35
				if fcw[1].autoHideFade > 1 then fcw[1].autoHideFade = 10 end
			elseif fcw[1].autoHideFade > 0 then
				if fcw[1].autoHideFade == 10 then
					fcw[1].autoHideFadeTime = os.clock()
					fcw[1].autoHideFade = 1
					
				else
					
					fcw[1].autoHideFade = 1-((os.clock()-fcw[1].autoHideFadeTime)/0.1)
					if fcw[1].autoHideFade <= 0 then
						fcw[1].autoHideFade = 0
						fcw[1].autoHideFadeTime = 0
						fcw[1].autoHideFade = 0
						
					end
				end
			end
		end
		--Debug(tostring(fcw[1].autoHideFade),1,false)
		if fcw[3].BigMode then
			ro_RectBG[1]:set_fill_color(0);
			if allSettings.SecondChat[1] then ro_RectBG[2]:set_fill_color(0); end
			for C_i = 1, allSettings.ChatLines do
				SetChatOpacity(0,1)
				if allSettings.SecondChat[1] then
					SetChatOpacity(0,2)
				end
			end
			ShowBigMode(true)
			--print(fcw[3].BigModePrev)
			ResetScrolling(1)
			ro_Scroll[1]:set_visible(false)
			fo_Bkw[1]:set_visible(false)
			if allSettings.SecondChat[1] then
				ResetScrolling(2)
				fo_Bkw[2]:set_visible(false)
				ro_Scroll[2]:set_visible(false)
			end
			if #fo_Chat[3]>0 and not fcw[3].BigModePrev then ResetScrolling(3, fcw[3].ChatLines);  end
			if not fcw[3].BigModePrev then b_ChatBufferIdx[3] = b_ChatBufferIdx[1] end
			DrawBigMode()
			fcw[3].BigModePrev = true
		elseif fcw[3].BigModePrev then
		--print('hello')
			ShowBigMode(false)
			ro_RectBG[1]:set_fill_color(allSettings.rectSettings.fill_color);
			if allSettings.SecondChat[1] then ro_RectBG[2]:set_fill_color(allSettings.rectSettings.fill_color); end
			for C_i = 1, allSettings.ChatLines do
				fo_Chat[1][C_i]:set_visible(true)
				fo_Aux[1][C_i]:set_visible(true)
				fo_Chat[1][C_i]:set_opacity(1)
				fo_Aux[1][C_i]:set_opacity(1)
				if allSettings.SecondChat[1] then
					fo_Chat[2][C_i]:set_visible(true)
					fo_Aux[2][C_i]:set_visible(true)
					fo_Chat[2][C_i]:set_opacity(1)
					fo_Aux[2][C_i]:set_opacity(1)
				end
			end
			ResetLines(1)
			-- fcw[1].PositionLinesRequest = {true,true}
			fcw[1].RequestAuxFix = true
			if allSettings.SecondChat[1] then
				ResetLines(2)
				fcw[2].RequestAuxFix = true
			end
			fcw[3].BigModePrev = false
			-- fcw[2].PositionLinesRequest = {true,true}
		end

		if (not uiw.LegacyChatOpen and not fcw[1].HideChat and not fcw[1].Closing and fcw[1].autoHideFade < 1 and not fcw[3].BigMode) then
			
			--if fcw[1].autoHideFade > 0 then
				
				
				-- for C_i = 1, allSettings.ChatLines do
					-- fo_Chat[1][C_i]:set_opacity(math.max(1-fcw[1].autoHideFade,0))
					-- fo_Aux[1][C_i]:set_opacity(math.max(1-fcw[1].autoHideFade,0))
				-- end
			-- else
				-- for C_i = 1, allSettings.ChatLines do
					-- fo_Chat[1][C_i]:set_opacity(1)
					-- fo_Aux[1][C_i]:set_opacity(1)
				-- end
			-- end
			
			--fcw[1].BG_W = allSettings.fontSettings.font_height*allSettings.ChatLines*fcw[1].BGScale*2;
			
			
			imgui.SetNextWindowSize({ fcw[1].BG_W, ro_RectBG[1].settings.height+16 });
			imgui.SetNextWindowSizeConstraints({ fcw[1].BG_W, ro_RectBG[1].settings.height+16 }, { FLT_MAX, FLT_MAX, });
			
			--local extraFlags = 0
			--if allSettings.LockWindowPos[1] then extraFlags = (ImGuiWindowFlags_NoMove); end
			--imgui.SetNextWindowPos({100,100});
			imgui.Begin('FancyChat_ChatBG_'+fcw[1].PlayerName, true, bit.bor(fcw[1].windowFlagsChatBG, allSettings.LockWindowPos[1] and ImGuiWindowFlags_NoMove or 0));
			--imgui.Begin('FancyChat_ChatBG_'+fcw[1].PlayerName, true, 0);
		-- Setting variables to position the chat window elements --
			
			
		--	fcw[1].Chat1WindowPosX, fcw[1].Chat1WindowPosY = imgui.GetWindowPos();
			
		
			local positionStartX, positionStartY = imgui.GetCursorScreenPos();
			positionStartX = positionStartX + allSettings.WindowPosOffset[1];
			positionStartY = positionStartY + allSettings.WindowPosOffset[2];
			
			--Debug(tostring(dsize.y/uiw.UISizeY*uiw.UISizeY),2, false)
			--print(tostring(mvc_Menu1));
			mvc_targetposY = 0;
			mvc_targetposX = 0;
			if fcw[1].MoveChat then
				mvc_targetposX = SetTargetPosX(dsize.x,dsize.y,positionStartX);
			end
			
			if not chat2moved then
				if not allSettings.GuideMeSecondWindow[1] then fcw[1].GuideMeClosedTmp = false; end
				if fcw[1].MoveChat and mvc_Menu6 and positionStartY+fcw[1].BG_H > mvc_targetposY then
					--print(positionStartY+fcw[1].BG_H..'-'..mvc_targetposY)
					positionStartY = mvc_targetposY-fcw[1].BG_H
					
				elseif fcw[1].MoveChat and positionStartX < mvc_targetposX
				and fcw[1].Anchor_Y > mvc_targetposY
				then
					positionStartX = mvc_targetposX;
				
				else
					fcw[1].MoveChat = false;
				end
			else
				if allSettings.CSMode[2] == 2 then
					positionStartY = dsize.y;
					
				elseif allSettings.CSMode[2] == 3 then
					positionStartX = mvc_targetposX + math.floor(fcw[2].BG_W)
				end
				fcw[1].MoveChat = false;
			end
			
			local centerPosX = (fcw[1].BG_W/2 + positionStartX-3);
			local centerPosY = (ro_RectBG[1].settings.height/2 + positionStartY)+3;
			--local imageSizeX = fcw[1].BG_W/((allSettings.fontSettings.font_height+0.4)/allSettings.fontSettings.font_height);
			local imageSizeX = (fcw[1].BG_W/2);
			local imageSizeY = ro_RectBG[1].settings.height/2;
			--Debug(tostring(positionStartX+(fcw[1].BG_W/(allSettings.fontSettings.font_height*10))), 1, false);
			
			
			fcw[1].Anchor_X = positionStartX;--+(fcw[1].BG_W/(allSettings.fontSettings.font_height*10));--60);
			fcw[1].Anchor_Y = positionStartY+(fcw[1].BG_H*0.8);
			fcw[1].PosChanged = false;
			if fcw[1].Anchor_X == 0 or math.abs(fcw[1].Anchor_X - fcw[1].PrevAnchor_X) >0.1  or
			fcw[1].Anchor_Y == 0 or math.abs(fcw[1].Anchor_Y - fcw[1].PrevAnchor_Y) >0.1 
			then
				fcw[1].PosChanged = true;
				fcw[1].PositionLinesRequest = {true, true};
			end
			fcw[1].PrevAnchor_X = fcw[1].Anchor_X;
			fcw[1].PrevAnchor_Y = fcw[1].Anchor_Y;
			
			--fcw[1].DraggingScroll = false;
			
			if fcw[1].Scrolling then
				if fcw[1].ScrollPos ~= GetScrollPoint(1) then fcw[1].PositionLinesRequest = {true,true}; end
				fcw[1].ScrollPos = GetScrollPoint(1);
				ro_Scroll[1]:set_visible(true);
				
			else
				fcw[1].ScrollPos = 1;
				--ro_Scroll[1]:set_fill_color(0x88FFFFFF)
				ro_Scroll[1]:set_visible(false);
			end
		
			
		-- Checking if the border texture should be displayed --
			local mouseX, mouseY = imgui.GetMousePos();
			if (
				mouseX > centerPosX - fcw[1].BG_W and mouseX < centerPosX + fcw[1].BG_W
				and mouseY > centerPosY - fcw[1].BG_H/2 and mouseY < centerPosY + fcw[1].BG_H/2
				and imgui.IsMouseDragging(ImGuiMouseButton_Left) and not fcw[1].DraggingScroll
				and imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly)
				)
			then
				fcw[1].Dragging = true;
				if (fcw[1].TextureIDBorder ~= nil ) then
					imgui.GetWindowDrawList():AddImage(fcw[1].TextureIDBorder, {centerPosX-imageSizeX, centerPosY-imageSizeY}, {centerPosX+imageSizeY, centerPosY+imageSizeY}, {0,0}, {1,1}, imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.75 }));
				end
			end
			
			if fcw[1].Dragging and imgui.IsMouseReleased then fcw[1].Dragging = false end;
			
			
			
		-- Setting up line highlighting --
			if IsRectHovered(ro_RectBG[1].settings,0) then
				fcw[1].HoverLine = -1;
				local parsedUrl = '';
				local lineOffsetBase = (fcw[1].BG_H/120)+(allSettings.fontSettings.font_height)
				for HL_i = 0, allSettings.ChatLines-1 do
					local lineOffset= lineOffsetBase+HL_i*allSettings.fontSettings.font_height;
					local highlight_alpha = 0;
					local targetLine = allSettings.ChatLines-HL_i+fcw[1].ChatHead-1; if targetLine > allSettings.ChatLines then targetLine = targetLine -allSettings.ChatLines end
					if (fo_Aux[1][targetLine].settings.visible and fo_Aux[1][targetLine].settings.text == '[link]' and
						fo_Chat[1][targetLine].rect ~= nil and fo_Aux[1][targetLine].rect~= nil and 
						mouseX >  fo_Aux[1][targetLine].settings.position_x and mouseX < fo_Aux[1][targetLine].settings.position_x + fo_Aux[1][targetLine].rect.right and
						mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+allSettings.fontSettings.font_height
						and not fcw[1].Dragging
						)
					then --b_msgID
						if (fo_Aux[1][targetLine] ~= nil) then
							fo_Aux[1][targetLine]:set_font_color(0xFFCCEEFF);
							fcw[1].HoverLine = allSettings.ChatLines-HL_i;
							local ChatHoverIdx = utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].url)-fcw[1].HoverLine-fcw[1].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[1])+1;
							--Debug(tostring(ChatHoverIdx)..'-'..b_ChatBuffer[b_ChatBufferMode][2].text[ChatHoverIdx],2,false);
							if ChatHoverIdx > 0 then
								--parsedUrl = utils.ParseUrlLink(b_ChatBuffer[b_ChatBufferMode][2].text[ChatHoverIdx]);
								--Debug(tostring(b_ChatBuffer[b_ChatBufferMode][2].url[ChatHoverIdx]), 2, false);
								
								if imgui.IsMouseClicked(ImGuiMouseButton_Left) then
									local urlText = utils.stringsplit(b_ChatBuffer[b_ChatBufferMode[1]][2].url[ChatHoverIdx],'|')
									ashita.misc.open_url((string.find(urlText[2], 'https://') or string.find(urlText[2], 'http://localhost:')) and urlText[2] or 'https://'..urlText[2]);
									--print(b_ChatBuffer[b_ChatBufferMode[1]][2].url[ChatHoverIdx])
								end
							end
							fcw[1].HoverLine = -1;
						end
							--break
					else
						--print(fo_Aux[1][targetLine])
						--Debug(tostring(fo_Aux[1][targetLine]),1,false)
						if (fo_Aux[1][targetLine]~= nil and fo_Aux[1][targetLine].settings.text == '[link]') then
							fo_Aux[1][targetLine]:set_font_color(0xFF44CCFF);
						end
						if (mouseX > fcw[1].Anchor_X and mouseX < fcw[1].Anchor_X+fcw[1].BG_W and
						mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+allSettings.fontSettings.font_height and
						(imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly) or (fcw[1].MoveChat and IsRectHovered(ro_RectBG[1].settings,0)))
						)
						then
							--local targetLine = 8-HL_i+fcw[1].ChatHead-1; if targetLine > 8 then targetLine = targetLine -8 end
							--dw_TestMessage = tostring(targetLine)..'-'..tostring(fo_Chat[1][targetLine] ~= nil);
							--if fo_Chat[1][targetLine] ~= nil then Debug(fo_Chat[1][targetLine].settings.text, 1, false); end
							
							fcw[1].HoverLine = allSettings.ChatLines-HL_i;
							highlight_alpha = 0.3;
							imgui.GetWindowDrawList():AddRectFilledMultiColor({fcw[1].Anchor_X, positionStartY+lineOffset}, {fcw[1].Anchor_X+imageSizeX, (positionStartY+lineOffset+allSettings.fontSettings.font_height)},
							imgui.GetColorU32({ 1.0, 1.0, 1.0, highlight_alpha }),
							imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.0 }),
							imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.0 }),
							imgui.GetColorU32({ 1.0, 1.0, 1.0, highlight_alpha })
							);
							--break
						end
					end
					
				end
				
			end 
			
			if (fcw[1].HoverLine > 0 and imgui.IsMouseClicked(ImGuiMouseButton_Left)) then fcw[1].Clicking = true; end
			
			if (fcw[1].HoverLine > 0  and imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly)) then
				
				local copyBufferIdx = utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text)-fcw[1].HoverLine-fcw[1].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[1])+1;
				local copyBufferText = '';
				if (copyBufferIdx > 0 ) then
				local ID = b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx]
				local IDs = 0
				local IDe = 0
				while b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx+IDs] and
					--type(b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx+IDs])=="number" and
					b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx+IDs] == ID do
					IDs = IDs - 1
				end
				while b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx+IDe] and
					--type(b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx+IDe])=="number" and
					b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx+IDe]	== ID do
					IDe = IDe + 1
				end
				--print(IDs+1) print(IDe-1)
				local IDi = math.min(IDs+1,0)
				--print(IDi) print(math.max(IDe-1,0))
				while IDi <= math.max(IDe-1,0) do
					--copyBufferText = b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] ~= '[link]' and copyBufferText..b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] or copyBufferText..b_ChatBuffer[b_ChatBufferMode[1]][2].text[copyBufferIdx+IDi]
					--
					if copyBufferText..b_ChatBuffer[b_ChatBufferMode[1]][2].text[copyBufferIdx+IDi] then
						copyBufferText = (' '..copyBufferText..b_ChatBuffer[b_ChatBufferMode[1]][2].text[copyBufferIdx+IDi]):trimex()
						if b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] ~= '[link]' then
							copyBufferText = copyBufferText..' '..b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi]
						end
					else
						break
					end
					IDi = IDi + 1;
				end
				end
				
				copyBufferText = utils.cleanMC(copyBufferText)
				if allSettings.ItemPreview[1] then
					DrawInfo(copyBufferText)
				end
				--print(copyBufferText)
				if (fcw[1].Clicking and imgui.IsMouseReleased(ImGuiMouseButton_Left)) then
				fcw[1].Clicking = false;
					if(copyBufferText ~=nil) then
						if imgui.GetIO().KeyShift then
							if #allSettings.Notes < 10 and #copyBufferText > 0 then
								table.insert(allSettings.Notes, copyBufferText)
								print('Message saved in the Notepad ['..#allSettings.Notes..'/10]')
								SaveSettings();
							else
								print('Notepad notes full [10/10]')
							end
						else
							utils.SetClipboardText(utils.RevertShiftJIS(copyBufferText))
							AshitaCore:GetChatManager():QueueCommand(1, "/echo Text successfully copied to clipboard!");
						end
					end
				end
			end
		
			if (fcw[1].Clicking and (imgui.IsMouseDragging(ImGuiMouseButton_Left) or not imgui.IsMouseDown(ImGuiMouseButton_Left) )) then fcw[1].Clicking = false; end
		

		-- Setting up line scrolling --
			local scrollOffset= (fcw[1].BG_H/120);

			if (imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly) or gamepadButtons.enabled) and not fcw[1].BufferBusy
			
			then
				if (
					fcw[1].ScrollDelta > 0
					
					and utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text) - fcw[1].ScrolledBack - (b_ChatBufferN[1]-b_ChatBufferIdx[1]) > allSettings.ChatLines
				)
				then
					if not imgui.GetIO().KeyShift or not fcw[1].Scrolling then
						fcw[1].ScrollDelta = 0;
						fcw[2].ScrollDelta = 0;
						fcw[1].Scrolling = true;
						fcw[1].ChatShift = allSettings.fontSettings.font_height
						fcw[1].ScrollUpRequest = true;
					elseif fcw[1].Scrolling then
						local currentIdx = #b_ChatBuffer[b_ChatBufferMode[1]][2].text - (b_ChatBufferN[1]-b_ChatBufferIdx[1]) - 1
						GoToLine(1,math.max(currentIdx-(fcw[1].ScrolledBack+5), allSettings.ChatLines), currentIdx);
					end
				else
					if ( fcw[1].ScrollDelta < 0 and fcw[1].ScrolledBack > 0 ) 
					then
						if  not imgui.GetIO().KeyShift or not fcw[1].Scrolling then
							fcw[1].ScrollDelta = 0;
							fcw[2].ScrollDelta = 0;
							fcw[1].Scrolling = true;
							fcw[1].ChatShift = allSettings.fontSettings.font_height
							fcw[1].ScrollDownRequest = true;
						elseif fcw[1].Scrolling then
							local currentIdx = #b_ChatBuffer[b_ChatBufferMode[1]][2].text - (b_ChatBufferN[1]-b_ChatBufferIdx[1]) - 1
							GoToLine(1,math.min(currentIdx-(fcw[1].ScrolledBack-5), currentIdx-1), currentIdx);
						end
					end
				end
				ResetAutoHideTimer()
			end
			fcw[1].ScrollDelta=0;
			
			if (fcw[1].ScrolledBack > 0) then
				fo_Bkw[1]:set_visible(true);
			else

				fo_Bkw[1]:set_visible(false);
			end
			
			
			if (imgui.IsMouseClicked(ImGuiMouseButton_Right)) then
				if fcw[1].ScrolledBack > 0 then
					ResetScrolling(1);
				end
				if fcw[2].ScrolledBack > 0 then
					ResetScrolling(2);
				end
			end
		
		
		-- Preparing some variables for the Tabs window --
			--local tabsPosX, tabsPosY = imgui.GetWindowPos();
			imgui.End();
		
		
			
		-- Setting up the Tabs window elements --
		--	local allSCompactTabs = true;
			--local tabsW = allSettings.fontSettings.font_height*8*fcw[1].BGScale*3.18;
			local tabsW = ro_RectBG[1].settings.width;
			local tabsH = fcw[1].BG_H/(allSettings.ChatLines)+2;
			--local compactPos, compactSize
			--PositionLines();
			if fcw[1].PosChanged or not fcw[1].compactPos or not fcw[1].compactSize then
				fcw[1].compactPos = {fcw[1].Anchor_X+(ro_RectBG[1].settings.width-(tabsW/#tab_Tabs))*0.994-9, fcw[1].Anchor_Y - ro_RectBG[1].settings.height+(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)+allSettings.fontSettings.font_height*1.3-1}
				fcw[1].compactSize = { tabsW/#tab_Tabs+(tabsH-(allSettings.fontSettings.font_height/1.2)+3), ro_RectBG[1].settings.height/8 }
			end
			if not allSettings.CompactTabs then
				--imgui.SetNextWindowPos({math.floor(fcw[1].Anchor_X-(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)-((allSettings.fontSettings.font_height*5)/allSettings.fontSettings.font_height)),math.floor(fcw[1].Anchor_Y+(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)+allSettings.fontSettings.font_height*1.2+(allSettings.fontSettings.font_height/50))});
				if fcw[1].PosChanged or not fcw[1].TabsPos then
					fcw[1].TabsPos = {math.floor(fcw[1].Anchor_X-(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)-((allSettings.fontSettings.font_height*5)/allSettings.fontSettings.font_height)),math.floor(fcw[1].Anchor_Y+tabsH-2)+math.floor(allSettings.fontSettings.font_height/25)}
				end
				
				imgui.SetNextWindowPos(fcw[1].TabsPos);
				
				imgui.SetNextWindowSize({ tabsW+8, ro_RectBG[1].settings.height/(allSettings.ChatLines*0.7) });
				
			else
				if not allSettings.CompactTabsBL[1] then
					imgui.SetNextWindowPos(fcw[1].compactPos);
				else
					if fcw[1].PosChanged or not fcw[1].TabsPos then
						fcw[1].TabsPos = {math.floor(fcw[1].Anchor_X-(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)-((allSettings.fontSettings.font_height*5)/allSettings.fontSettings.font_height)),math.floor(fcw[1].Anchor_Y+tabsH-2)+math.floor(allSettings.fontSettings.font_height/25)}
					end
					imgui.SetNextWindowPos(fcw[1].TabsPos);
				end
				imgui.SetNextWindowSize(fcw[1].compactSize);
			end
			
			--imgui.SetNextWindowSizeConstraints({ tabsW+tabsH*2, tabsH }, { FLT_MAX, FLT_MAX, });
			windowFlags = bit.bor( ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_NoBackground);
			
			imgui.Begin('FancyChat_ChatTabs_'+fcw[1].PlayerName, true, windowFlags);
			--local font = imgui.GetFont();
			--local prevFontSize = font.FontSize;
			--font.FontSize = 450/allSettings.fontSettings.font_height;
			-- imguiWrap.Branch(
				-- function() imgui.SetWindowFontScale(allSettings.fontSettings.font_height/25) end,
				-- function() end
				-- )
			
			local IWwindowfont = imguiWrap.SetWindowFontScale(allSettings.fontSettings.font_height/25)
			--imgui.SetWindowPos({fcw[1].Anchor_X-(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)-((allSettings.fontSettings.font_height*5)/allSettings.fontSettings.font_height),fcw[1].Anchor_Y+(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)+allSettings.fontSettings.font_height*1.2});
			--imgui.SetWindowSize({ tabsW+tabsH*2, tabsH });
			--imgui.SetWindowSizeConstraints({ tabsW, tabsH }, { FLT_MAX, FLT_MAX, });
			PushColorStyles(tab_ButtonColorStylesNormal);
			
			
			
			if not allSettings.CompactTabs then
				local reserved = tabsW - ((tabsH*4)-8)-8.3
				local cursY = imgui.GetCursorPosY()-7
				local cursx = imgui.GetCursorPosX()-4
				for T_i = 1, utils.GetTableLen(tab_Tabs) do
					imgui.SetCursorPos({cursx+(reserved/#tab_Tabs)*(T_i-1),cursY});
					if (tab_Tabs[T_i] == allSettings.SelectedTab) then
						PushColorStyles(tab_ButtonColorStylesSelected);
						imgui.Button(tab_Tabs[T_i]:gsub('Alt','##Alt'),{reserved/#tab_Tabs,tabsH-2});
						PopColorStyles(tab_ButtonColorStylesSelected);
					else
						if (imgui.Button(tab_Tabs[T_i]:gsub('Alt','##Alt'),{reserved/#tab_Tabs,tabsH-2})) then
							tab_NextTab = tab_Tabs[T_i]; 
						end
					end
				end
				
				imgui.SetCursorPos({reserved+4,imgui.GetCursorPosY()-(tabsH+1.6)});
			
				if(fcw[1].TextureIDGuideMe ~= nil) then
					if (imguiWrap.ImageButton('TextureIDGuideMe',fcw[1].TextureIDGuideMe,{tabsH-8,tabsH-8},{0,0},{1,1},-1,{0,0,0,0},{1,1,1,0.7})) then
						
						fcw[1].GuideMeOpened[1] = not fcw[1].GuideMeOpened[1];
						if fcw[1].GuideMeOpened[1] then	fcw[1].NotepadOpened[1]  = false end
					end
					if (imgui.IsItemHovered(0)) then
						imgui.BeginTooltip()
						message = 'Open GuideMe'
						imgui.SetTooltip(message)
						imgui.EndTooltip()
					end
				end
				imgui.SetCursorPos({imgui.GetCursorPosX()+reserved+4+(tabsH-8),imgui.GetCursorPosY()-(tabsH+1.6)});
			
				if(fcw[1].TextureIDNotepad ~= nil) then
					if (imguiWrap.ImageButton('TextureIDNotepad',fcw[1].TextureIDNotepad,{tabsH-8,tabsH-8},{0,0},{1,1},-1,{0,0,0,0},{1,1,1,0.7})) then
						fcw[1].NotepadOpened[1] = not fcw[1].NotepadOpened[1]
						if fcw[1].NotepadOpened[1] then	fcw[1].GuideMeOpened[1] = false end
					end
					if (imgui.IsItemHovered(0)) then
						imgui.BeginTooltip()
						message = 'Open Notepad'
						imgui.SetTooltip(message)
						imgui.EndTooltip()
					end
				end
				
				imgui.SetCursorPos({imgui.GetCursorPosX()+reserved+4+(tabsH*2-8),imgui.GetCursorPosY()-(tabsH+1.6)});
				if(fcw[1].TextureIDSettings ~= nil) then
					if (imguiWrap.ImageButton('TextureIDSettings',fcw[1].TextureIDSettings,{tabsH-8,tabsH-8},{0,0},{1,1},-1,{0,0,0,0},{1,1,1,0.7})) then
						allSettings.settingsOpened[1] = not allSettings.settingsOpened[1];
					end
					if (imgui.IsItemHovered(0)) then
						imgui.BeginTooltip()
						message = 'Open Settings'
						imgui.SetTooltip(message)
						imgui.EndTooltip()
					end
				end
				
				imgui.SetCursorPos({imgui.GetCursorPosX()+reserved+4+(tabsH*3-8),imgui.GetCursorPosY()-(tabsH+1.6)});
				if(fcw[1].TextureIDCompact ~= nil) then
					if (imguiWrap.ImageButton('TextureIDCompact',fcw[1].TextureIDCompact,{tabsH-8,tabsH-8},{0,0},{1,1},-1,{0,0,0,0},{1,1,1,0.7})) then
						allSettings.CompactTabs = true;
						fcw[1].PosChanged = true
						fcw[2].PosChanged = true
						SaveSettings();
					end
					if (imgui.IsItemHovered(0)) then
						imgui.BeginTooltip()
						message = 'Compact TabBar Mode'
						imgui.SetTooltip(message)
						imgui.EndTooltip()
					end
				end
				
				-- imgui.SetNextWindowPos({compactPos[1],compactPos[2]}); 
				-- imgui.SetNextWindowSize(compactSize);
				-- imgui.Begin('FancyChat_ChatTabs_Compactbutton', true, bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_NoBackground, ImGuiWindowFlags_NoSavedSettings));
				-- imgui.SetCursorPos({(tabsW/#tab_Tabs)-(tabsH-8),0});
			
				-- imgui.PushStyleVar(ImGuiStyleVar_FrameBorderSize, 0);
				
				-- if(fcw[1].TextureIDCompact ~= nil) then
					-- if (imguiWrap.ImageButton(fcw[1].TextureIDCompact,{tabsH-8,tabsH-12},{-0.05,-0.05},{1.05,1.05},-1,{0,0,0,0},{1,1,1,0.5})) then
						-- allSettings.CompactTabs = true;
						-- SaveSettings();
					-- end
				-- end
				-- imgui.PopStyleVar(1);
				-- imgui.End()
				
			else
				--imgui.SetWindowPos({fcw[1].Anchor_X + ro_RectBG[1].settings.position_x, fcw[1].Anchor_Y + ro_RectBG[1].settings.height})
				--imgui.SetWindowPos({fcw[1].Anchor_X-(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)-((allSettings.fontSettings.font_height*5)/allSettings.fontSettings.font_height),fcw[1].Anchor_Y+(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)+allSettings.fontSettings.font_height*1.2});
				--imgui.SetNextWindowSize({ tabsW+tabsH*2, tabsH })
				imgui.PushStyleVar(ImGuiStyleVar_FrameBorderSize, 0);
				
				local button_length = {tabsW/#tab_Tabs-(tabsH-8), 0}
				local length_ref = allSettings.fontSettings.font_height*6
				if button_length[1] > length_ref then button_length[1] = length_ref; button_length[2] = tabsW/#tab_Tabs-(tabsH-8) - length_ref end
				
				for T_i = 1, utils.GetTableLen(tab_Tabs) do
				if (tab_Tabs[T_i] == allSettings.SelectedTab) then
						if allSettings.CompactTabsBL[1] then
							imgui.SetCursorPos({0,0});
						else
							imgui.SetCursorPos({button_length[2],0});
						end
						if imgui.Button(tab_Tabs[T_i]:gsub('Alt','##Alt'),{button_length[1],tabsH-6}) then
							if T_i+1 <= #tab_Tabs then tab_NextTab = tab_Tabs[T_i+1]; else  tab_NextTab = tab_Tabs[1] end
						end
					end
				end
				
				if allSettings.CompactTabsBL[1] then
					imgui.SetCursorPos({button_length[1],0});
				else
					imgui.SetCursorPos({(tabsW/#tab_Tabs)-(tabsH-8),0});
				end
				
				
				if imgui.GetIO().KeyShift then
					if(fcw[1].TextureIDSettings ~= nil) then
						if imguiWrap.ImageButton('TextureIDSettings',fcw[1].TextureIDSettings, {tabsH-8,tabsH-12},{1.05,1.0},{-0.05,-0.0},-1,{0,0,0,0},{1,1,1,0.5}) then
							allSettings.settingsOpened[1] = not allSettings.settingsOpened[1];
						end
					end
				else
					if(fcw[1].TextureIDCompact ~= nil) then
						if imguiWrap.ImageButton('TextureIDCompact', fcw[1].TextureIDCompact, {tabsH-8,tabsH-12},{1.05,1.05},{-0.05,-0.05},-1,{0,0,0,0},{1,1,1,0.5}) then
							allSettings.CompactTabs = false;
							fcw[1].PosChanged = true
							fcw[2].PosChanged = true
							SaveSettings();
						end
					end
				end
				imgui.PopStyleVar(1);
			
			end
			PopColorStyles(tab_ButtonColorStylesNormal);
			--font.FontSize = prevFontSize;
			if IWwindowfont then imgui.PopFont(); end
			imgui.End();
			
			fcw[1].isHiddenGUI = not AshitaCore:GetGuiManager():GetVisible()
			if fcw[1].GuideMeOpened[1] and not fcw[1].GuideMeClosedTmp then
				
				if fcw[1].isHiddenGUI then utils.ImguiVis(true) end
				local GuideMeW = allSettings.UseHalfLength[1] and fcw[1].BG_W/2 or fcw[1].BG_W;
				local GuideMeH = fcw[1].BG_H+100;
				if (fcw[1].GuideMeDocked) then
					windowFlags = fcw[1].windowFlagsGuideMeDocked
					if allSettings.GuideMeSecondWindow[1] then
						imgui.SetNextWindowPos({ro_RectBG[2].settings.position_x,ro_RectBG[2].settings.position_y-GuideMeH});
						imgui.SetNextWindowSize({ GuideMeW, GuideMeH });
						imgui.SetNextWindowSizeConstraints({ GuideMeW, GuideMeH }, { FLT_MAX, FLT_MAX, });
					else
						imgui.SetNextWindowPos({ro_RectBG[1].settings.position_x,ro_RectBG[1].settings.position_y-GuideMeH});
						imgui.SetNextWindowSize({ GuideMeW, GuideMeH });
						imgui.SetNextWindowSizeConstraints({ GuideMeW, GuideMeH }, { FLT_MAX, FLT_MAX, });
					end
				else
					imgui.SetNextWindowSizeConstraints({ 400, 200 }, { FLT_MAX, FLT_MAX, });
					windowFlags = fcw[1].windowFlagsGuideMe
				end
				
				PushWindowStyle()
								
				if imgui.Begin('FancyChat - GuideMe (experimental)', fcw[1].GuideMeOpened, windowFlags) then
				
					if imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly) then ResetAutoHideTimer() end
					local response, status, headers;
					
					--InputText(const char* label, char* buf, size_t buf_size, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = nullptr, void* user_data = nullptr)
					imgui.PushItemWidth(imgui.GetWindowWidth()/2-130);
					if imgui.InputText('URL', fcw[1].GuideMeURL, 200, bit.bor(ImGuiInputTextFlags_CharsNoBlank,ImGuiInputTextFlags_AutoSelectAll)) then
					end 
					imgui.PopItemWidth();
					imgui.SameLine();
					if fcw[1].GuideMeURL[1] == '' then fcw[1].ErrorMsg = '> Paste in the URL text box above a ffxiclopedia or bg-wiki\n  mission/quest or object walkthrough page and click [Load]' end			if imgui.Button('Load', {50,0}) then
						if fcw[1].GuideMeURL[1] ~= '' then
							
							if fcw[1].GuideMeURL[1]:match("^[a-zA-Z][a-zA-Z%d+.-]*:")
							   and (string.find(fcw[1].GuideMeURL[1], 'ffxiclopedia')
							   or string.find(fcw[1].GuideMeURL[1], 'bg%-wiki')
								)
							then

								response, status, headers = http.request(fcw[1].GuideMeURL[1])

								if not response then
									fcw[1].ErrorMsg = "> Failed to fetch page. Status:", status or "unknown";
									fcw[1].GuideMeWalkthrough = nil;
								else --
									fcw[1].GuideMeWalkthrough = response:match("(<h[1-3]>.-Walkthrough.-</h[1-3]>.-<div class=\"printfooter\">)")
									
									if not fcw[1].GuideMeWalkthrough then
									fcw[1].GuideMeWalkthrough = response:match("(<h[1-3]>.-Walkthrough.-</h[1-3]>.-<div class=\"page%-footer\">)")
									end
									
									if not fcw[1].GuideMeWalkthrough then
										fcw[1].GuideMeWalkthrough = response:match("(>Obtained From.-</th>.-<div class=\"printfooter\">)")
										if fcw[1].GuideMeWalkthrough then
											--print('hello')
											fcw[1].GuideMeWalkthrough = "<h2>How to Obtain</h2>\n<table style=\"width: 100%; max-width: 788px;\" class=\"sortable item\"><tbody><tr>"..fcw[1].GuideMeWalkthrough:gsub(">Obtained From.-</tr>","");
										end

										--Debug(tostring(fcw[1].GuideMeWalkthrough), 1, true);
									end
									if not fcw[1].GuideMeWalkthrough then
										fcw[1].GuideMeWalkthrough = response:match("(>Purchased From.-</th>.-<div class=\"printfooter\">)")
										if fcw[1].GuideMeWalkthrough then
											--print('hello')
											fcw[1].GuideMeWalkthrough = "<h2>How to Obtain</h2>\n<table style=\"width: 100%; max-width: 788px;\" class=\"sortable item\"><tbody><tr>"..fcw[1].GuideMeWalkthrough:gsub(">Purchased From.-</tr>","");
										end

										--Debug(tostring(fcw[1].GuideMeWalkthrough), 1, true);
									end
									if not fcw[1].GuideMeWalkthrough then
										fcw[1].GuideMeWalkthrough = response:match("(<h[1-3]>.-How to Obtain.-</h[1-3]>.-<div class=\"page%-footer\">)")
									end
									
									if not fcw[1].GuideMeWalkthrough then
										fcw[1].ErrorMsg = "> Walkthrough section not found! Guide me only works\n  with missions or quest walkthrough pages."
										fcw[1].GuideMeWalkthrough = nil;
									else
										fcw[1].GuideMeWalkthrough = utils.GetWalkthrough(fcw[1].GuideMeWalkthrough)
										local start = string.find(fcw[1].GuideMeWalkthrough,'%[Walkthrough%]');
										if not start then start = string.find(fcw[1].GuideMeWalkthrough,'%[How to Obtain%]'); end
										
										
										--fcw[1].GuideMeWalkthrough = string.sub(string.find(fcw[1].GuideMeWalkthrough,'%[Walkthrough%]'))
										fcw[1].GuideMeWalkthrough =string.sub(fcw[1].GuideMeWalkthrough, start)
										--Debug( string.sub(fcw[1].GuideMeWalkthrough, start),1,false)
									end
								end
							else
								fcw[1].ErrorMsg = "> Invalid URL. Make sure it is a ffxiclopedia or bg-wiki\n  page starting with https://"
								fcw[1].GuideMeWalkthrough = nil;
							end
						else
							fcw[1].ErrorMsg = '> Paste in the URL text box above a ffxiclopedia or bg-wiki\n  mission or quest walkthrough page and click [Load]'
							fcw[1].GuideMeWalkthrough = nil;
						end
					
					end
					
					imgui.SameLine(); imgui.Dummy({10,0}); imgui.SameLine();
					imgui.Text('Text Size') imgui.SameLine();
						
					if imgui.ArrowButton('#DecreaseFontScale', ImGuiDir_Down) then
						if allSettings.GuideMeFontScale > 0.5 then 
							allSettings.GuideMeFontScale = allSettings.GuideMeFontScale - 0.05;
						end
						
					end
					
					imgui.SameLine(); if imgui.ArrowButton('#IncreaseFontScale', ImGuiDir_Up) then
						if allSettings.GuideMeFontScale < 1.5 then 
							allSettings.GuideMeFontScale = allSettings.GuideMeFontScale + 0.05;
						end
					end
					
					imgui.SameLine(); imgui.Text('[x'..string.format("%.2f", allSettings.GuideMeFontScale)..']');
					
					imgui.SameLine(); imgui.Dummy({10,0});
					imgui.SameLine();
					if fcw[1].GuideMeDocked then
						if imgui.Button('Undock',{70,0}) then
							fcw[1].GuideMeDocked = false;
						end
					else
						if imgui.Button('Dock',{70,0}) then
							fcw[1].GuideMeDocked = true;
						end
					end
					
					imguiWrap.BeginChild('GuideMe child', {imgui.GetWindowWidth()*0.983,(imgui.GetWindowHeight()-70)*0.983}, true)

					--imgui.PushFont(fontBox)
					
					--imgui.SetWindowFontScale(allSettings.GuideMeFontScale);
					local IWwindowfontG = imguiWrap.SetWindowFontScale(allSettings.GuideMeFontScale)
					
					imgui.PushTextWrapPos(imgui.GetWindowWidth()*0.96);
					if fcw[1].GuideMeWalkthrough then
						imgui.TextUnformatted(fcw[1].GuideMeWalkthrough, #fcw[1].GuideMeWalkthrough)
					elseif fcw[1].ErrorMsg then
						
						imgui.TextUnformatted(fcw[1].ErrorMsg);
					end;
					imgui.PopTextWrapPos()
					--imgui.PopFont()
					if IWwindowfontG then imgui.PopFont() end
					imgui.EndChild()
					imgui.End();
				end
				PopWindowStyle();
				
			end
		
		
			if fcw[1].NotepadOpened[1] and not fcw[1].NotepadClosedTmp then
				
				if fcw[1].isHiddenGUI then utils.ImguiVis(true) end
				local GuideMeW = allSettings.UseHalfLength[1] and fcw[1].BG_W/2 or fcw[1].BG_W;
				local GuideMeH = fcw[1].BG_H+100;
				if (fcw[1].NotepadDocked) then
					windowFlags = fcw[1].windowFlagsGuideMeDocked
					if allSettings.GuideMeSecondWindow[1] then
						imgui.SetNextWindowPos({ro_RectBG[2].settings.position_x,ro_RectBG[2].settings.position_y-GuideMeH});
						imgui.SetNextWindowSize({ GuideMeW, GuideMeH });
						imgui.SetNextWindowSizeConstraints({ GuideMeW, GuideMeH }, { FLT_MAX, FLT_MAX, });
					else
						imgui.SetNextWindowPos({ro_RectBG[1].settings.position_x,ro_RectBG[1].settings.position_y-GuideMeH});
						imgui.SetNextWindowSize({ GuideMeW, GuideMeH });
						imgui.SetNextWindowSizeConstraints({ GuideMeW, GuideMeH }, { FLT_MAX, FLT_MAX, });
					end
				else
					imgui.SetNextWindowSizeConstraints({ 550, 200 }, { FLT_MAX, FLT_MAX, });
					windowFlags = fcw[1].windowFlagsGuideMe
				end
				
				PushWindowStyle()
								
				if imgui.Begin('FancyChat - Notes (experimental)', fcw[1].NotepadOpened, windowFlags) then
					if imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly) then ResetAutoHideTimer() end
					AddTooltip('Save up to 10 Notes!\n- Use the textbox to manually add a note.\n- Use Shitf+Click on any message in chat to save it directly as a note.',0);	imgui.SameLine() imgui.SetCursorPosY(imgui.GetCursorPosY()-4)
					imgui.PushItemWidth(imgui.GetWindowWidth()-316);
					if imgui.InputText('##NoteInput', fcw[1].Note, 300, bit.bor(ImGuiInputTextFlags_AutoSelectAll)) then
					end imgui.SameLine()
					if imgui.Button('Add Note', {100,0}) then
						if #allSettings.Notes < 10 and #fcw[1].Note[1] > 0 then
							table.insert(allSettings.Notes, fcw[1].Note[1])
							fcw[1].Note = T{''};
							SaveSettings()
						end
					end
					imgui.SameLine()
					imgui.Text(string.format('[%02d/10]',#allSettings.Notes));
					imgui.SameLine()
					imgui.Dummy({0,0})
					imgui.SameLine()
					if fcw[1].NotepadDocked then
						if imgui.Button('Undock',{70,0}) then
							fcw[1].NotepadDocked = false;
						end
					else
						if imgui.Button('Dock',{70,0}) then
							fcw[1].NotepadDocked = true;
						end
					end
					local font = imgui.GetFont();
					local fontSize = font.FontSize or font.LegacySize;
					local R = {};
					for i = 1, #allSettings.Notes do
					
					
					imguiWrap.BeginChild('##Chat Window Child_'..tostring(i), {imgui.GetWindowWidth()-110,fontSize+fontSize*math.floor(imgui.CalcTextSize(allSettings.Notes[i])/(imgui.GetWindowWidth()-math.min(imgui.CalcTextSize(help.GetLongestWord(allSettings.Notes[i])),(imgui.GetWindowWidth()-100)/2)))+16}, true);
					imgui.PushTextWrapPos(imgui.GetWindowWidth())
					imgui.TextWrapped(allSettings.Notes[i])
					imgui.PopTextWrapPos()
					imgui.EndChild()
					imgui.SameLine() 
					if imgui.Button('X##Note'..tostring(i),{34,34}) then
						table.insert(R, i)
					end
					imgui.SameLine() 
					if imgui.Button('C##Note'..tostring(i),{34,34}) then
						utils.SetClipboardText(allSettings.Notes[i])
					end
					end
					for R_i = 1, #R do
						table.remove(allSettings.Notes, R[R_i])
					end
					if #R > 0 then SaveSettings() end
					imgui.PopItemWidth();
					imgui.SameLine();
					imgui.End();
				end
				PopWindowStyle();

			end	
			
		
		end
		
		
		
		
		-- Setting up the Settings window elements --
		
		if (allSettings.settingsOpened[1]) then
			ResetAutoHideTimer()
			PushWindowStyle()
			--print('hello')
			imgui.SetNextWindowSize({ dsize.x/3.8, dsize.y/2.7 });
			--imgui.SetNextWindowSize({400, 400 });ImGuiWindowFlags_NoResize,
			--imgui.SetWindowPos({100,100});
			imgui.SetNextWindowSizeConstraints({ 550,300 }, { FLT_MAX, FLT_MAX, });
			imgui.Begin('FancyChat Settings##_'+fcw[1].PlayerName, allSettings.settingsOpened, bit.bor( ImGuiWindowFlags_NoResize,ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_NoNav) );

			--imgui.SetWindowFocus()
			--if imgui.IsWindowHovered(ImGuiHoveredFlags_RectOnly) then set_WinHovered = true; else set_WinHovered = false; end
			local setsizex, setsizey = imgui.GetWindowSize();--
			--if (wposx > dsize.x or wposy > dsize.y or wposx <0 or wposy <0) then  end
			
			
			if (imgui.BeginTabBar('##fancychat_tabbar', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton))	then
				
				if (imgui.BeginTabItem('Chat Window', nil)) then
					imguiWrap.BeginChild('##Chat Window Child', {(setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3,setsizey*2.7/2.8-60}, true);
					--imguiWrap.BeginChild('##Chat Window Child', {300,300}, true);
					local fontSize = T{set_FontHeight};
					local cposY = imgui.GetCursorPosY();
					local cposX = imgui.GetCursorPosX();
					imgui.Text('Font Size');
					imgui.SameLine();
					imgui.SetCursorPosY(cposY-3);
					imgui.PushItemWidth(dsize.x/7.5);
					imgui.SetCursorPosX((dsize.x/4.3-dsize.x/8)*(1920/dsize.x));
					if (imgui.SliderInt('##FontSizeSlider', fontSize, 14, 50, "%d", ImGuiSliderFlags_AlwaysClamp )) then
						set_FontHeight = fontSize[1];
						--PositionLines();
						--SaveSettings();
					end
					local lineSize = T{set_ChatLineMaxL};
					cposY = imgui.GetCursorPosY();
					cposX = imgui.GetCursorPosX();
					imgui.SetCursorPosY(cposY+10);
					imgui.Text('Chat Width');
					imgui.SameLine();
					imgui.SetCursorPosY(cposY+7);
					imgui.SetCursorPosX((dsize.x/4.3-dsize.x/8)*(1920/dsize.x));
					if (imgui.SliderInt('##ChatWidthSlider', lineSize, 60, 135, "%d", ImGuiSliderFlags_AlwaysClamp )) then
						set_ChatLineMaxL = lineSize[1];
						--PositionLines();
						--SaveSettings();
					end

					local plateBGcolor = set_PlateBGColor;
					local plateBGAlpha = T{tonumber(bit.rshift(plateBGcolor, 24))/255};
					cposY = imgui.GetCursorPosY();
					cposX = imgui.GetCursorPosX();
					imgui.SetCursorPosY(cposY+10);				
					imgui.Text('Plate BG Alpha');
					imgui.SameLine();
					imgui.SetCursorPosY(cposY+7);
					imgui.SetCursorPosX((dsize.x/4.3-dsize.x/8)*(1920/dsize.x));
					if (imgui.SliderFloat('##plateBGAlphaSlider', plateBGAlpha, 0, 0.499, "%.2f", bit.bor(ImGuiSliderFlags_AlwaysClamp,ImGuiSliderFlags_NoRoundToFormat) )) then
						set_PlateBGColor = bit.lshift(bit.tobit(plateBGAlpha[1]*255),24);
						--fcw[1].PositionLinesRequest = true;
						--SaveSettings();
					end
					--lines
					local chatlines = T{set_ChatLines};
					cposY = imgui.GetCursorPosY();
					cposX = imgui.GetCursorPosX();
					imgui.SetCursorPosY(cposY+10);
					imgui.Text('Number of chat lines');
					imgui.SameLine();
					imgui.SetCursorPosY(cposY+7);
					imgui.SetCursorPosX((dsize.x/4.3-dsize.x/8)*(1920/dsize.x));
					
					if (imgui.SliderInt('##ChatLinesSlider', chatlines, 8, 16, "%d", ImGuiSliderFlags_AlwaysClamp )) then
						set_ChatLines = chatlines[1];
						--PositionLines();
						--SaveSettings();
					end
					imgui.PopItemWidth();
					imgui.Dummy({0,5});
					if (imgui.Checkbox('Enable second chat window',{set_SecondChat[1]})) then 
						set_SecondChat[1] = not set_SecondChat[1];
						--SaveSettings();
					end
					imgui.Dummy({0,5});
					imgui.Text('Messages shown in Custom tab') --npc ls party tell shout
					AddTooltip('The messages selected for the custom tab won\'t appear in All if Hide from All is enabled in \'Extra\' settings.',0,true);
					if (imgui.Checkbox('NPC',{set_CustomTabModes[1]})) then 
						set_CustomTabModes[1] = not set_CustomTabModes[1];
					end imgui.SameLine()
					cposY = imgui.GetCursorPosY();
					AddTooltip('Depending on the server settings, this might not catch all NPC messages or catch some /say messages.',4); imgui.SameLine()imgui.SetCursorPosY(cposY);  	  
					if (imgui.Checkbox('Tell',{set_CustomTabModes[4]})) then 
						set_CustomTabModes[4] = not set_CustomTabModes[4];
					end imgui.SameLine()
					if (imgui.Checkbox('Party',{set_CustomTabModes[3]})) then 
						set_CustomTabModes[3] = not set_CustomTabModes[3];
					end imgui.SameLine()
					if (imgui.Checkbox('LS',{set_CustomTabModes[2]})) then 
						set_CustomTabModes[2] = not set_CustomTabModes[2];
					end imgui.SameLine()
					if (imgui.Checkbox('Shout',{set_CustomTabModes[5]})) then 
						set_CustomTabModes[5] = not set_CustomTabModes[5];
					end
					
					imgui.Dummy({0,5});
					if imgui.Button('Reset default values') then
						set_ChatLineMaxL = 100;
						set_PlateBGColor = bit.lshift(bit.tobit(0.3*255),24);
						set_FontHeight = 20;
						set_ChatLines = 8;
						set_SecondChat[1] = false;
						set_CustomTabModes = T{false,false,false,false,false};
						--SaveSettings();
					end
					imgui.Dummy({0,5});
					imgui.TextColored({1.0,0.2,0.2,1.0},'^');
					cposY = imgui.GetCursorPosY();
					imgui.SetCursorPosY(cposY-20);
					
					imgui.TextColored({1.0,0.2,0.2,1.0},'|');
					cposY = imgui.GetCursorPosY();
					imgui.SetCursorPosY(cposY-20);
					cposX = imgui.GetCursorPosX();
					imgui.SetCursorPosX(cposX+15);
					imgui.TextColored({1.0,0.2,0.2,1.0},'Changes to all settings above require an addon restart');
					-- if (fcw[1].TextureIDInfo ~= nil ) then
						-- imgui.GetWindowDrawList():AddImage(fcw[1].TextureIDInfo, {0,0},{10,10}, {0,0}, {1,1}, imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.75 }));
					-- end
					AddTooltip('The changes to options above won\'t take effect until the addon is restarted',1,1);
					if imgui.Button('Restart & apply') then
						fcw[1].Closing = true;
						if not set_SecondChat[1] then
							allSettings.GuideMeSecondWindow[1] = false;
						end
						allSettings.SecondChat[1] = set_SecondChat[1];
						allSettings.ChatLines = set_ChatLines;
						allSettings.fontSettings.font_height = set_FontHeight;
						allSettings.rectSettings.fill_color = set_PlateBGColor;
						allSettings.chatLineMaxL = set_ChatLineMaxL;
						for ct = 1, #set_CustomTabModes do
							allSettings.CustomTabModes[ct] = set_CustomTabModes[ct];
						end
						SaveSettings();
						AshitaCore:GetChatManager():QueueCommand(1, "/addon reload fancychat");
					end
					imgui.Dummy({0,35})
					imgui.Text('Adjust final windows position')
					AddTooltip('After adjusting the chat window positions manually, use this option to make pixel-by-pixel adjustments',0)
					imgui.Dummy({0,25});-- imgui.SameLine();
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('1##Window1',{set_AdjWin1[1]})) then 
						set_AdjWin1[1] = not set_AdjWin1[1];
					end imgui.SameLine();imgui.Dummy({2,0}); imgui.SameLine();
					if (imgui.Checkbox('2##Window2',{set_AdjWin2[1]})) then 
						set_AdjWin2[1] = not set_AdjWin2[1];
					end
					
					imgui.SameLine();imgui.Dummy({10,0}); imgui.SameLine();

					if imgui.ArrowButton('#AnchorL', ImGuiDir_Left) then
						if set_AdjWin1[1] then allSettings.WindowPosOffset[1] = allSettings.WindowPosOffset[1] - 1; end
						if set_AdjWin2[1] then allSettings.WindowPosOffset[3] = allSettings.WindowPosOffset[3] - 1; end
						fcw[1].PositionLinesRequest = {true,true};
						fcw[2].PositionLinesRequest = {true,true};
						
					end
					cposY = imgui.GetCursorPosY();
					imgui.SetCursorPosY(cposY-51);
					cposX = imgui.GetCursorPosX();
					imgui.SetCursorPosX(cposX+154);
					if imgui.ArrowButton('#AnchorU', ImGuiDir_Up) then
						if set_AdjWin1[1] then allSettings.WindowPosOffset[2] = allSettings.WindowPosOffset[2] - 1; end
						if set_AdjWin2[1] then allSettings.WindowPosOffset[4] = allSettings.WindowPosOffset[4] - 1; end
						fcw[1].PositionLinesRequest = {true,true};
						fcw[2].PositionLinesRequest = {true,true};
						
					end
					cposY = imgui.GetCursorPosY();
					imgui.SetCursorPosY(cposY-1);
					cposX = imgui.GetCursorPosX();
					imgui.SetCursorPosX(cposX+161);
					imgui.Text('+')
					cposY = imgui.GetCursorPosY();
					imgui.SetCursorPosY(cposY-3);
					cposX = imgui.GetCursorPosX();
					imgui.SetCursorPosX(cposX+154);
					if imgui.ArrowButton('#AnchorD', ImGuiDir_Down) then
						if set_AdjWin1[1] then allSettings.WindowPosOffset[2] = allSettings.WindowPosOffset[2] + 1; end
						if set_AdjWin2[1] then allSettings.WindowPosOffset[4] = allSettings.WindowPosOffset[4] + 1; end
						fcw[1].PositionLinesRequest = {true,true};
						fcw[2].PositionLinesRequest = {true,true};
						
					end
					cposY = imgui.GetCursorPosY();
					imgui.SetCursorPosY(cposY-51);
					cposX = imgui.GetCursorPosX();
					imgui.SetCursorPosX(cposX+177);
					if imgui.ArrowButton('#AnchorR', ImGuiDir_Right) then
						if set_AdjWin1[1] then allSettings.WindowPosOffset[1] = allSettings.WindowPosOffset[1] + 1; end
						if set_AdjWin2[1] then allSettings.WindowPosOffset[3] = allSettings.WindowPosOffset[3] + 1; end
						fcw[1].PositionLinesRequest = {true,true};
						fcw[2].PositionLinesRequest = {true,true};
						
					end
					cposY = imgui.GetCursorPosY();
					imgui.SetCursorPosY(cposY-53);
					cposX = imgui.GetCursorPosX();
					imgui.SetCursorPosX(cposX+230);
					imgui.Text('W1 [x:'..tostring(allSettings.WindowPosOffset[1])..', y:'..tostring(allSettings.WindowPosOffset[2])..']\nW2 [x:'..tostring(allSettings.WindowPosOffset[3])..', y:'..tostring(allSettings.WindowPosOffset[4])..']')
					cposX = imgui.GetCursorPosX();
					imgui.SetCursorPosX(cposX+230);
					if imgui.Button('Save##Offsets') then
						SaveSettings();
					end imgui.SameLine();
					if imgui.Button('Reset##Offsets') then
						allSettings.WindowPosOffset = {0, 0, 0, 0};
					end
					imgui.Dummy({0,20});
					if (imgui.Checkbox('Lock Windows Positions (disables dragging)##WindowLock',{allSettings.LockWindowPos[1]})) then 
						allSettings.LockWindowPos[1] = not allSettings.LockWindowPos[1];
						SaveSettings();
					end
					imgui.Dummy({0,5});
					if (imgui.Checkbox('Compact tabs in the bottom-left corner##ComapctBL',{allSettings.CompactTabsBL[1]})) then 
						allSettings.CompactTabsBL[1] = not allSettings.CompactTabsBL[1];
						SaveSettings();
					end
					imgui.Dummy({0,5});
					if (imgui.Checkbox('Gampad Chat Navigation##GamepadNav',{allSettings.GamepadNav[1]})) then 
						allSettings.GamepadNav[1] = not allSettings.GamepadNav[1];
						SaveSettings();
					end
					imgui.Dummy({0,5});
					if (imgui.Checkbox('Enable Auto-Hide window',{allSettings.AutoHideWindow[1]})) then 
						allSettings.AutoHideWindow[1] = not allSettings.AutoHideWindow[1];
						SaveSettings();
					end
					imgui.PushItemWidth(dsize.x/10);
					cposY = imgui.GetCursorPosY();
					cposX = imgui.GetCursorPosX();
					imgui.Dummy({3,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					imgui.Dummy({20,0}); imgui.SameLine();
					imgui.Text('Auto-Hide time (seconds) >');
					imgui.SameLine();
					imgui.SetCursorPosY(cposY+0.5);
					imgui.SetCursorPosX((dsize.x/3.7-dsize.x/8)*(1920/dsize.x));
					local ahtime = {allSettings.AutoHideTimeMax}
					if (imgui.SliderInt('##AutoHideSlider', ahtime, 5, 60, "%d", ImGuiSliderFlags_AlwaysClamp )) then
						allSettings.AutoHideTimeMax = ahtime[1];
						--PositionLines();
						SaveSettings();
					end
					imgui.PopItemWidth();
					imgui.Dummy({0,5});
					if (imgui.Checkbox('Use half window length for docked UI elements',{allSettings.UseHalfLength[1]})) then 
						allSettings.UseHalfLength[1] = not allSettings.UseHalfLength[1];
						SaveSettings();
					end
					AddTooltip('Only uses half the length of the chat window as reference for UI elements docked to chat window.',4)
					imgui.Dummy({0,5});
					if (imgui.Checkbox('Prevent obstructing FFXI UI',{allSettings.EnabledChatMove[1]})) then 
						allSettings.EnabledChatMove[1] = not allSettings.EnabledChatMove[1];
						SaveSettings();
					end
					imgui.Dummy({1,0}); imgui.SameLine(); imgui.Text('|  Set what happens to the 2nd chat')
					local csmodes = {{'Nothing', 1},{'Hide 2nd', 2},{'Shift along', 3}}
					imgui.Dummy({1,0}); imgui.SameLine(); imgui.SetCursorPosY(imgui.GetCursorPosY()+4);imgui.Text('| '); imgui.SetCursorPosY(imgui.GetCursorPosY()-4);imgui.SameLine();
					if imgui.BeginCombo('##ChatShiftMode', allSettings.CSMode[1] , ImGuiComboFlags_None) then
						for CS_i = 1, #csmodes do
							if imgui.Selectable(csmodes[CS_i][1]) then
								allSettings.CSMode = csmodes[CS_i];
								SaveSettings();
							end
						end
					imgui.EndCombo();
					end
					imgui.Dummy({1,0}); imgui.SameLine(); imgui.Text('| ');	imgui.SameLine();
					if (imgui.Checkbox('Prevent obstructing Auto-Translate menu as well',{allSettings.MoveChatATMenu[1]})) then 
						allSettings.MoveChatATMenu[1] = not allSettings.MoveChatATMenu[1];
						SaveSettings();
					end
					imgui.Dummy({3,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					imgui.Dummy({27,0}); imgui.SameLine();
					imgui.Text('[ Experimental ]\n[ Reposition chats if FFXI UI elements overlap ]\n[ Works with the most common game UI elements ]\n[ Only works with chat positions locked ]');
					--imgui.Text('Lock manual\npositioning');
					imgui.EndChild();
				imgui.EndTabItem();
				end
				
				
				if (imgui.BeginTabItem('Font Colors', nil)) then
					imguiWrap.BeginChild('leftpane', { ((setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3)*set_colorTextW,setsizey*2.7/3-60 }, true);

					local keys = {}
					local tmpcolor = {}
					for key in pairs(allSettings.colors) do
						table.insert(keys, key)
					end
					table.sort(keys)
					local skip = {'combat','combatspell','cexi'}
					set_colorTextW = 0
					for _, key in ipairs(keys) do
						 
						if not utils.FindInStringTable(key, skip, 0) then
							set_colorTextW = math.max(AddSetColor(key, allSettings.colors[key], tmpcolor), set_colorTextW)
							
						end
					end
					set_colorTextW = set_colorTextW/(setsizex-((12*(1-(setsizex*3.8/1920)))-3*2))
					--print(textW)
			
					imgui.EndChild();

					imgui.SameLine();
					
					imguiWrap.BeginChild('righttpane', { ((setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3)*(1-(set_colorTextW+0.01)), setsizey*2.7/3-60 }, true);
					--imguiWrap.BeginChild('righttpane', { 100, 100}, true);
					
					imgui.Text('Color Picker');
					imgui.Separator();
					--AddTooltip('Pick a color on the color picker, then click the arrow buttons on the left pane to assignt the color to the desired chat mode.',0)
					imgui.TextWrapped('Pick a color and click an arrow button on the left pane to assign it.')
					if tmpcolor[1] then set_PickedColor = utils.cloneTable(tmpcolor[1]) end
					imgui.PushItemWidth(dsize.x/(set_colorTextW*25));
					if imgui.ColorPicker3('Preview', set_PickedColor) then
						
					end
					imgui.PopItemWidth();
					imgui.EndChild();
					
					if imgui.Button('Reset Colors') then
						allSettings.colors = utils.cloneTable(defaultColors)
						SaveSettings();
					end
					imgui.SameLine();
					if imgui.Button('Export Colors') then
						local exportedcolors = {}
						for _, key in ipairs(keys) do
							if not utils.FindInStringTable(key, skip, 0) then
								exportedcolors[key] = allSettings.colors[key]
							end
						end
						utils.ExportColors(addon.path, fcw[1].PlayerName, exportedcolors);
					end
					imgui.SameLine();
					if imgui.Button('Import Colors') then
						allSettings.colors = utils.ImportColors(addon.path, fcw[1].PlayerName ,allSettings.colors);
						SaveSettings();
					end
					imgui.SameLine();
					AddTooltip('Do not alter the files!',3,true)
					imgui.EndTabItem();
				end
				
				if (imgui.BeginTabItem('Shortcuts', nil)) then
					imguiWrap.BeginChild('##Shortcuts Child', {(setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3,setsizey*2.7/2.8-60}, true);
					--imguiWrap.BeginChild('##Shortcuts Child', {300,300}, true);
					local letter = utils.keycodes[utils.findIndexOfValue(utils.keycodes, allSettings.shortcutHide)][1];
					local letterS = utils.keycodesSpecial[utils.findIndexOfValue(utils.keycodesSpecial, allSettings.shortcutHideS)][1];
					local letter2 = utils.keycodes[utils.findIndexOfValue(utils.keycodes, allSettings.shortcutTab)][1];
					local letterS2 = utils.keycodesSpecial[utils.findIndexOfValue(utils.keycodesSpecial, allSettings.shortcutTabS)][1];
					local letter3 = utils.keycodes[utils.findIndexOfValue(utils.keycodes, allSettings.shortcutTab2)][1];
					local letterS3 = utils.keycodesSpecial[utils.findIndexOfValue(utils.keycodesSpecial, allSettings.shortcutTab2S)][1];
					
					local letter4 = utils.keycodes[utils.findIndexOfValue(utils.keycodes, allSettings.shortcutBig)][1];
					local letterS4 = utils.keycodesSpecial[utils.findIndexOfValue(utils.keycodesSpecial, allSettings.shortcutBigS)][1];
		
					imgui.Text('Hide FancyChat Addon');
					AddTooltip('Quickly hide FancyChat temporarily re-enabling the legacy chat.',0)
					local cposY = imgui.GetCursorPosY();

					imgui.SetCursorPosY(cposY+5);
					if (imgui.Checkbox('Enabled##HideShortcut',{allSettings.shortcutHideEnabled[1]})) then 
						allSettings.shortcutHideEnabled[1] = not allSettings.shortcutHideEnabled[1];
						SaveSettings();
					end
					imgui.PushItemWidth(dsize.x/15);
					if imgui.BeginCombo('##HideShortcutComboS', letterS , ImGuiComboFlags_None) then
						for KC_i = 1, #utils.keycodesSpecial do
							if imgui.Selectable(utils.keycodesSpecial[KC_i][1], letterS == utils.keycodesSpecial[KC_i][1]) then
								allSettings.shortcutHideS = utils.keycodesSpecial[KC_i][2];
								SaveSettings();
							end
						end
					end
					imgui.SameLine();
					if imgui.BeginCombo('##HideShortcutCombo', letter , ImGuiComboFlags_None) then
						for KC_i = 1, #utils.keycodes do
							if (utils.keycodes[KC_i][1] ~= letter2 and utils.keycodes[KC_i][1] ~= letter3 and utils.keycodes[KC_i][1] ~= letter4 ) then
								if imgui.Selectable(utils.keycodes[KC_i][1], letter == utils.keycodes[KC_i][1]) then
									allSettings.shortcutHide = utils.keycodes[KC_i][2];
									SaveSettings();
								end
							end
						end
					imgui.EndCombo();
					end
					imgui.PopItemWidth();
					
					imgui.Dummy({0,20});
					--cposY = imgui.GetCursorPosY();

					--imgui.SetCursorPosY(cposY+5);
					imgui.Text('Big Window Mode');
					AddTooltip('Show Window 1 of FancyChat in \"Big Mode\".',0)

					--imgui.SetCursorPosY(cposY+5);
					if (imgui.Checkbox('Enabled##BigShortcut',{allSettings.shortcutBigEnabled[1]})) then 
						allSettings.shortcutBigEnabled[1] = not allSettings.shortcutBigEnabled[1];
						SaveSettings();
					end
					imgui.PushItemWidth(dsize.x/15);
					if imgui.BeginCombo('##BigShortcutComboS', letterS4 , ImGuiComboFlags_None) then
						for KC_i = 1, #utils.keycodesSpecial do
							if imgui.Selectable(utils.keycodesSpecial[KC_i][1], letterS4 == utils.keycodesSpecial[KC_i][1]) then
								allSettings.shortcutBigS = utils.keycodesSpecial[KC_i][2];
								SaveSettings();
							end
						end
						imgui.EndCombo();
					end
					imgui.SameLine();
					if imgui.BeginCombo('##BigShortcutCombo', letter4 , ImGuiComboFlags_None) then
						for KC_i = 1, #utils.keycodes do
							if (utils.keycodes[KC_i][1] ~= letter and utils.keycodes[KC_i][1] ~= letter2 and utils.keycodes[KC_i][1] ~= letter3 ) then
								if imgui.Selectable(utils.keycodes[KC_i][1], letter4 == utils.keycodes[KC_i][1]) then
									allSettings.shortcutBig = utils.keycodes[KC_i][2];
									SaveSettings();
								end
							end
						end
						imgui.EndCombo();
					end
					imgui.PopItemWidth();
					
					imgui.Dummy({0,20});			
					imgui.Text('Scroll Chat Tabs (window 1)');
					cposY = imgui.GetCursorPosY();

					imgui.SetCursorPosY(cposY+5);
					if (imgui.Checkbox('Enabled##TabShortcut',{allSettings.shortcutTabEnabled[1]})) then 
						allSettings.shortcutTabEnabled[1] = not allSettings.shortcutTabEnabled[1];
						SaveSettings();
					end
					imgui.PushItemWidth(dsize.x/15);
					if imgui.BeginCombo('##TabShortcutComboS', letterS2 , ImGuiComboFlags_None) then
						for KC_i = 1, #utils.keycodesSpecial do
							if imgui.Selectable(utils.keycodesSpecial[KC_i][1], letterS2 == utils.keycodesSpecial[KC_i][1]) then
								allSettings.shortcutTabS = utils.keycodesSpecial[KC_i][2];
								SaveSettings();
							end
						end
						imgui.EndCombo();
					end
					imgui.SameLine();
					if imgui.BeginCombo('##TabShortcutCombo', letter2 , ImGuiComboFlags_None) then
						for KC_i = 1, #utils.keycodes do
							if (utils.keycodes[KC_i][1] ~= letter and utils.keycodes[KC_i][1] ~= letter3 and utils.keycodes[KC_i][1] ~= letter4 ) then
								if imgui.Selectable(utils.keycodes[KC_i][1], letter2 == utils.keycodes[KC_i][1]) then
									allSettings.shortcutTab = utils.keycodes[KC_i][2];
									SaveSettings();
								end
							end
						end
						imgui.EndCombo();
					end
					imgui.PopItemWidth();
					imgui.Dummy({0,20});
					imgui.Text('Scroll Chat Tabs (window 2)');
					cposY = imgui.GetCursorPosY();

					imgui.SetCursorPosY(cposY+5);
					if (imgui.Checkbox('Enabled##Tab2Shortcut',{allSettings.shortcutTab2Enabled[1]})) then 
						allSettings.shortcutTab2Enabled[1] = not allSettings.shortcutTab2Enabled[1];
						SaveSettings();
					end
					imgui.PushItemWidth(dsize.x/15);
					if imgui.BeginCombo('##Tab2ShortcutComboS', letterS3 , ImGuiComboFlags_None) then
						for KC_i = 1, #utils.keycodesSpecial do
							if imgui.Selectable(utils.keycodesSpecial[KC_i][1], letterS3 == utils.keycodesSpecial[KC_i][1]) then
								allSettings.shortcutTab2S = utils.keycodesSpecial[KC_i][2];
								SaveSettings();
							end
						end
						imgui.EndCombo();
					end
					imgui.SameLine();
					if imgui.BeginCombo('##TabShortcutCombo2', letter3 , ImGuiComboFlags_None) then
						for KC_i = 1, #utils.keycodes do
							if (utils.keycodes[KC_i][1] ~= letter and utils.keycodes[KC_i][1] ~= letter2 and utils.keycodes[KC_i][1] ~= letter4 ) then
								if imgui.Selectable(utils.keycodes[KC_i][1], letter2 == utils.keycodes[KC_i][1]) then
									allSettings.shortcutTab2 = utils.keycodes[KC_i][2];
									SaveSettings();
								end
							end
						end
						imgui.EndCombo();
					end
					imgui.PopItemWidth();
					imgui.Dummy({0,10});
					if imgui.Button('Reset default keys') then
						allSettings.shortcutHide = 46;
						allSettings.shortcutTab = 45;
						allSettings.shortcutTab2 = 48;
						allSettings.shortcutBig  = 34;
						allSettings.shortcutHideS = 42;
						allSettings.shortcutTabS = 42;
						allSettings.shortcutTab2S = 42;
						allSettings.shortcutBigS = 42;
					end
					imgui.Dummy({0,20});
					imgui.Text('Commands to manually macro features');
					imgui.Dummy({0,5});imgui.Dummy({3,0}); imgui.SameLine();
					imgui.Text('/fancychat settings');
					imgui.Dummy({23,0}); imgui.SameLine();
					imgui.Text('[Opens/Closes Settings window]');
					imgui.Dummy({0,5});imgui.Dummy({3,0}); imgui.SameLine();
					imgui.Text('/fancychat guideme');
					imgui.Dummy({23,0}); imgui.SameLine();
					imgui.Text('[Opens/Closes GuideMe window]');
					imgui.Dummy({0,5});imgui.Dummy({3,0}); imgui.SameLine();
					imgui.Text('/fancychat notes');
					imgui.Dummy({23,0}); imgui.SameLine();
					imgui.Text('[Opens/Closes Notes window]');
					imgui.Dummy({0,5});imgui.Dummy({3,0}); imgui.SameLine();
					imgui.Text('/fancychat compact');
					imgui.Dummy({23,0}); imgui.SameLine();
					imgui.Text('[Toggles Tabs Compact mode]');
					imgui.Dummy({0,5});imgui.Dummy({3,0}); imgui.SameLine();
					imgui.Text('/fancychat manual');
					imgui.Dummy({23,0}); imgui.SameLine();
					imgui.Text('[Opens the addon Manual]');
					imgui.Dummy({0,5});imgui.Dummy({3,0}); imgui.SameLine();
					imgui.Text('/fancychat tod');
					imgui.Dummy({23,0}); imgui.SameLine();
					imgui.Text('[Toggles TOD timestamps]');
					imgui.Dummy({0,5});imgui.Dummy({3,0}); imgui.SameLine();
					imgui.Text('/fancychat ts');
					imgui.Dummy({23,0}); imgui.SameLine();
					imgui.Text('[Prints a timestamp of the current time]');
					imgui.Dummy({0,5});imgui.Dummy({3,0}); imgui.SameLine();
					imgui.Text('/fancychat savelogs');
					imgui.Dummy({23,0}); imgui.SameLine();
					imgui.Text('[Saves chat logs in the addon folder]');
					
					-- imgui.Dummy({0,5});imgui.Dummy({3,0}); imgui.SameLine();
					-- imgui.Text('/fancychat dumpchat');
					-- imgui.Dummy({23,0}); imgui.SameLine();
					-- imgui.Text('[Dumps FancyChat text in the legacy chat]');
					
					imgui.EndChild();
				imgui.EndTabItem();
				end
				if (imgui.BeginTabItem('Extra', nil)) then
					imguiWrap.BeginChild('##Extra Child', {(setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3,setsizey*2.7/2.8-60}, true);
					--imguiWrap.BeginChild('##Extra Child', {300,300}, true);
				
					imgui.Text('Block legacy chat messages');
					AddTooltip('Blocks incoming messages to the legacy chat and only display them on FancyChat. This will block the window resize animation that makes it flicker when new chat messages arrive.',0)
					--imgui.Text('[Blocks legacy chat resize animation]');
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('All',{allSettings.blockAll[1]})) then 
						allSettings.blockAll[1] = not allSettings.blockAll[1];
						if allSettings.blockAll[1] then
							if not set_Popup[1] then set_Popup[1] = true; end
						else
							set_Popup[1] = false;
							allSettings.autoDumpChat[1] = false
						end
						SaveSettings();
					end
					if set_Popup[1] then
						AddWarning('While this option has been tested throughfully, it might lead to getting stuck in dialgoues in untested scenarios.\n\nDisable it if you experience such issues.\n\nTo submit chat logs for support tickets, use the \"Restore Legacy Chat Logs\" function under \"Tools\" and take a screenshot of the legacy chat!',350)
					end
					AddTooltip('Disable this if you are experiencing getting stuck in conversations with NPCs',4,1)
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Combat (recommended)',{allSettings.blockCombat[1]})) then 
						allSettings.blockCombat[1] = not allSettings.blockCombat[1];
						SaveSettings();
					end
					imgui.Dummy({0,15});
					imgui.Text('Chat message filtering (experimental)'); 
					AddTooltip('These are meant for quick changes on the fly. Use the in-game filter system first!',0,1)
					--imgui.Text('[These are meant for quick changes on the fly]\n[Use the in-game filter system first!]');
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Hide combat and custom logs from \'All\' tab.',{allSettings.HideCombatFromAll[1]})) then 
						allSettings.HideCombatFromAll[1] = not allSettings.HideCombatFromAll[1];
						if allSettings.HideCombatFromAll[1] then
							tab_Tabs[1] = 'AllAlt'
							if allSettings.SelectedTab == 'All' then
								tab_NextTab = 'AllAlt'
							end
							if allSettings.SecondChat[1] then
								if allSettings.SelectedTab2 == 'All' then
									tab_NextTab2 = 'AllAlt'
								end
							end
						else
							tab_Tabs[1] = 'All'
							if allSettings.SelectedTab == 'AllAlt' then
								tab_NextTab = 'All'
							end
							if allSettings.SecondChat[1] then
								if allSettings.SelectedTab2 == 'AllAlt' then
									tab_NextTab2 = 'All'
								end
							end
						end
						-- ChangeTab(1, 'All');
						-- ResetScrolling(1);
						-- if allSettings.SecondChat[1] then
							-- ChangeTab(2, 'All');
							-- ResetScrolling(2);
						-- end
						SaveSettings();
					end
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Hide alliance combat log',{allSettings.hideAlliance[1]})) then 
						allSettings.hideAlliance[1] = not allSettings.hideAlliance[1];
						if not allSettings.hideAlliance[1] then allSettings.hideNonYou[1] = false; end
						SaveSettings();
					end
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Hide non-party combat log',{allSettings.hideNonParty[1]})) then 
						allSettings.hideNonParty[1] = not allSettings.hideNonParty[1];
						if not allSettings.hideNonParty[1] then allSettings.hideNonYou[1] = false; end
						SaveSettings();
					end
					--imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					--imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					--imgui.Dummy({27,0}); imgui.SameLine();
					--imgui.Text('[ Experimental. Blocks most non-party log. ]');
					imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-20);
					imgui.Dummy({27,0}); imgui.SameLine();
					if (imgui.Checkbox('Only show you and your pet logs.',{allSettings.hideNonYou[1]})) then 
						allSettings.hideNonYou[1] = not allSettings.hideNonYou[1];
						if allSettings.hideNonYou[1] then allSettings.hideNonParty[1] = true; end
						if allSettings.hideNonYou[1] then allSettings.hideAlliance[1] = true; end
						SaveSettings();
					end
					
					imgui.Dummy({0,5});
					imgui.Text('Other settings'); 
					AddTooltip('Read the manual for more detailed info',0)
					--imgui.Text('[Read the manual for more detailed info]');par_extraspace[1]
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Compact Combat Log',{allSettings.CompactCombat[1]})) then 
						allSettings.CompactCombat[1] = not allSettings.CompactCombat[1];
						SaveSettings();
					end		
					AddTooltip('Disable if you have other addons such as simplelog enabled.',4)
					-- imgui.Dummy({0,5});
					-- imgui.Dummy({5,0}); imgui.SameLine();
					-- if (imgui.Checkbox('Compact party names',{not allSettings.extraspace[1]})) then 
						-- allSettings.extraspace[1] = not allSettings.extraspace[1];
						-- SaveSettings();
					-- end		
					-- AddTooltip('In combat logs\nEnabled:[Name]\nDisabled:[ Name ]',4)
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Timestamp',{allSettings.timeStamp[1]})) then 
						allSettings.timeStamp[1] = not allSettings.timeStamp[1];
						if allSettings.timeStamp[1] then  allSettings.timeStampLine[1] = false end
						SaveSettings();
					end							
					-- imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					-- imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					-- imgui.Dummy({27,0}); imgui.SameLine();
					-- imgui.Text('[ Might conflict with timestamp addon ]');
					imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					imgui.Dummy({30,0}); imgui.SameLine();
					imgui.Text('Format');
					imgui.SameLine();
					local formats = {'[00:00:00]', '[00:00]'};
					local currentFormat = formats[allSettings.FormatTSMode];
					imgui.SetCursorPosY(imgui.GetCursorPosY()-3);
					imgui.PushItemWidth(dsize.x/15);
					if imgui.BeginCombo('##TimestampFormat', currentFormat , ImGuiComboFlags_None) then
						if imgui.Selectable(formats[1], currentFormat == formats[1]) then allSettings.FormatTSMode = 1;	end
						if imgui.Selectable(formats[2], currentFormat == formats[2]) then allSettings.FormatTSMode = 2;	end
						SaveSettings();
					imgui.EndCombo();
					end
					imgui.PopItemWidth();
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Timestamp as a line',{allSettings.timeStampLine[1]})) then 
						allSettings.timeStampLine[1] = not allSettings.timeStampLine[1];
						if allSettings.timeStampLine[1] then allSettings.timeStamp[1] = false; end
						SaveSettings();
					end	
					imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					imgui.Dummy({30,0}); imgui.SameLine();
					imgui.Text('Every');
					imgui.SameLine();--timeStampLineFreq
					local minutes = {{'1 minute', 60},{'5 minutes', 300},{'10 minutes', 600},{'30 minutes', 1800},{'60 minutes', 3600}};
					imgui.SetCursorPosY(imgui.GetCursorPosY()-3);
					imgui.PushItemWidth(dsize.x/15);
					if imgui.BeginCombo('##TimeStampLineFreq', allSettings.timeStampLineFreq[1] , ImGuiComboFlags_None) then
						for TS_i = 1, #minutes do
							if imgui.Selectable(minutes[TS_i][1]) then
								allSettings.timeStampLineFreq = minutes[TS_i];
								SaveSettings();
							end
						end
					imgui.EndCombo();
					end
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Warning messages on R0s',{allSettings.R0warning[1]})) then 
						allSettings.R0warning[1] = not allSettings.R0warning[1];
						SaveSettings();
					end
					AddTooltip('Shows a warning messagee in chat when you R0 (possible disconnection happening).',4)
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Precise TOD Timestamps',{allSettings.PreciseTS[1]})) then 
						allSettings.PreciseTS[1] = not allSettings.PreciseTS[1];
						SaveSettings();
					end
					AddTooltip('Shows timestamps, precise to the second, next to \'defeat mob\' messages.',4)
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Incoming /tell notifications',{allSettings.tellNotification[1]})) then 
						allSettings.tellNotification[1] = not allSettings.tellNotification[1];
						SaveSettings();
					end
					AddTooltip('Plays a notification sound of choice when an incoming Tell message is received.',4)
					imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-20);
					imgui.Dummy({27,0}); imgui.SameLine();
					imgui.PushItemWidth(dsize.x/8);
					--imgui.PushItemWidth(100);
					if imgui.BeginCombo('##NotificationShould', allSettings.selectedNotification , ImGuiComboFlags_None) then
						for NS_i = 1, 6 do
							if imgui.Selectable('notification_'..tostring(NS_i)) then
								allSettings.selectedNotification = 'notification_'..tostring(NS_i);
								SaveSettings();
							end
						end
					imgui.EndCombo();
					end
					imgui.PopItemWidth();
					imgui.SameLine();
					if imgui.ArrowButton('PlayNotification', ImGuiDir_Right) then
						ashita.misc.play_sound(string.format('%s\\notifications\\%s%s.wav', addon.path, allSettings.selectedNotification,allSettings.boostNotification[1] and 'B' or ''));
					end
					imgui.SameLine();
					imgui.Text('Play!');
					imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-20);
					imgui.Dummy({27,0}); imgui.SameLine();
					if (imgui.Checkbox('Volume Boost',{allSettings.boostNotification[1]})) then 
						allSettings.boostNotification[1] = not allSettings.boostNotification[1];
						SaveSettings();
					end
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Chat word alert',{allSettings.Alert[1]})) then 
						allSettings.Alert[1] = not allSettings.Alert[1];
						SaveSettings();
					end
					AddTooltip('Plays a notification sound of choice when one of the alert words appears in a message.',4)
					imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					imgui.Dummy({30,0}); imgui.SameLine();
					imgui.Text('Alert words'); imgui.SameLine()
					imgui.SetCursorPosY(imgui.GetCursorPosY()-2);
					imgui.PushItemWidth(dsize.x/10);--ImGuiInputTextFlags_CharsNoBlank
					imgui.InputText('##AlertWords', set_alertBuffer, 255, bit.bor(ImGuiInputTextFlags_CharsNoBlank, ImGuiInputTextFlags_CallbackAlways), (
					function()
						allSettings.alertwords = set_alertBuffer[1]:gsub('\0','')
						set_alertList = utils.stringsplit(allSettings.alertwords, ',')
						SaveSettings()
					end
					)); imgui.SameLine()
					AddTooltip('Separate words with commas. Case insensitive.',4);
					imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-20);
					imgui.Dummy({27,0}); imgui.SameLine();
					imgui.PushItemWidth(dsize.x/8);
					--imgui.PushItemWidth(100);
					if imgui.BeginCombo('##AlertShould', allSettings.selectedAlert , ImGuiComboFlags_None) then
						for AS_i = 1, 6 do
							if imgui.Selectable('notification_'..tostring(AS_i)) then
								allSettings.selectedAlert = 'notification_'..tostring(AS_i);
								SaveSettings();
							end
						end
					imgui.EndCombo();
					end
					imgui.PopItemWidth();
					imgui.SameLine();
					if imgui.ArrowButton('PlayAlert', ImGuiDir_Right) then
						ashita.misc.play_sound(string.format('%s\\notifications\\%s%s.wav', addon.path, allSettings.selectedAlert, allSettings.boostAlert[1] and 'B' or ''));
					end
					imgui.SameLine();
					imgui.Text('Play!');
					imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-20);
					imgui.Dummy({27,0}); imgui.SameLine();
					if (imgui.Checkbox('Volume Boost##Alert',{allSettings.boostAlert[1]})) then 
						allSettings.boostAlert[1] = not allSettings.boostAlert[1];
						SaveSettings();
					end
					if allSettings.Alert[1] then
						imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
						imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
						imgui.Dummy({30,0}); imgui.SameLine();
						imgui.Text('Checked channels')
						--imgui.Dummy({0,5});
						imgui.Dummy({30,0}); imgui.SameLine();
						if (imgui.Checkbox('Say',{allSettings.alertOptions[1]})) then 
							allSettings.alertOptions[1] = not allSettings.alertOptions[1];
							SaveSettings();
						end
						imgui.Dummy({0,5});
						imgui.Dummy({30,0}); imgui.SameLine();
						if (imgui.Checkbox('Shout',{allSettings.alertOptions[2]})) then 
							allSettings.alertOptions[2] = not allSettings.alertOptions[2];
							SaveSettings();
						end
						imgui.Dummy({0,5});
						imgui.Dummy({30,0}); imgui.SameLine();
						if (imgui.Checkbox('Party',{allSettings.alertOptions[3]})) then 
							allSettings.alertOptions[3] = not allSettings.alertOptions[3];
							SaveSettings();
						end
						imgui.Dummy({0,5});
						imgui.Dummy({30,0}); imgui.SameLine();
						if (imgui.Checkbox('Linkshell',{allSettings.alertOptions[4]})) then 
							allSettings.alertOptions[4] = not allSettings.alertOptions[4];
							SaveSettings();
						end
						imgui.Dummy({0,5});
						imgui.Dummy({30,0}); imgui.SameLine();
						if (imgui.Checkbox('Unity',{allSettings.alertOptions[5]})) then 
							allSettings.alertOptions[5] = not allSettings.alertOptions[5];
							SaveSettings();
						end
					end
					
					--------------------------------------------------------------------------
					-- imgui.PushItemWidth(dsize.x/10);
					-- imgui.Dummy({0,10});
					-- imgui.Dummy({5,0}); imgui.SameLine();
					-- imgui.Text('Combat log separator character')
					-- AddTooltip('Customize the character that, in Combat log, separates the main message from the result (the main and colored parts).',0)
					-- imgui.Dummy({5,0}); imgui.SameLine();
					--imgui.Text('[ Combat log character before the colored part ]')
					--imgui.Dummy({5,0}); imgui.SameLine();
					-- if imgui.BeginCombo('##SplittingChar', allSettings.CombatSplitChar[1] , ImGuiComboFlags_None) then
						-- for SC_i = 1, #set_CombatSplitCharList do
							-- if imgui.Selectable(set_CombatSplitCharList[SC_i][1]) then
								-- allSettings.CombatSplitChar = set_CombatSplitCharList[SC_i];
								-- SaveSettings();
							-- end
						-- end
					-- imgui.EndCombo();
					-- end
					-- imgui.PopItemWidth();
					---------------------------------------------------------------------------------
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Preview Items/Abilities/Spells on mouse hover',{allSettings.ItemPreview[1]})) then 
						allSettings.ItemPreview[1] = not allSettings.ItemPreview[1];
						SaveSettings();
					end
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Auto-restore logs when opening Legacy Chat',{allSettings.autoDumpChat[1]})) then
						if not allSettings.autoDumpChat[1] and allSettings.blockAll[1] then 
							allSettings.autoDumpChat[1] = true;
						elseif allSettings.autoDumpChat[1] then
							allSettings.autoDumpChat[1] = false
						end
						SaveSettings();
					end
					AddTooltip('Available when Block All Messages from Legacy Chat is enabled.\nAutomatically restores chat messages in the Legacy Chat upon opening it.',4)
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Colorblind mode for damage done/taken text',{allSettings.ColorBlind[1]})) then 
						allSettings.ColorBlind[1] = not allSettings.ColorBlind[1];
						SaveSettings();
					end
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Fast scroll chat history',{allSettings.EnableFastScroll[1]})) then 
						allSettings.EnableFastScroll[1] = not allSettings.EnableFastScroll[1];
						SaveSettings();
					end
					AddTooltip('While scrolling the chat and hovering the chat window, use [Shift] + [<] or [>] to quickly scroll the history more than one line at the time.',4)
					-- imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					-- imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					-- imgui.Dummy({27,0}); imgui.SameLine();
					-- imgui.Text('[ Use [Shift] + [<] or [>] ]');
					-- imgui.Dummy({27,0}); imgui.SameLine();
					-- imgui.Text('[ Only while already scrolling chat ]');
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Dock GuideMe/Notes on the second chat window',{allSettings.GuideMeSecondWindow[1]})) then 
						if allSettings.SecondChat[1] then
							allSettings.GuideMeSecondWindow[1] = not allSettings.GuideMeSecondWindow[1];
							SaveSettings();
						end
					end
					AddTooltip('Requires second chat window enabled.',4)
					-- imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					-- imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					-- imgui.Dummy({27,0}); imgui.SameLine();
					-- imgui.Text('[ Requires second chat window enabled ]');
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox(allSettings.heartEmoji[1] and ' <3' or ' ',{allSettings.heartEmoji[1]})) then 
						allSettings.heartEmoji[1] = not allSettings.heartEmoji[1];
						SaveSettings();
					end
					--AddTooltip((allSettings.heartEmoji[1] and '<3' or '?'),4)
					imgui.EndChild();
					imgui.EndTabItem();
				end
				if imgui.BeginTabItem('CL Filters', nil) then
					imguiWrap.BeginChild('##Filters Child', {(setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3,setsizey*2.7/2.8-60}, true);
					imgui.PushTextWrapPos(imgui.GetWindowWidth()*0.96);
					imgui.TextWrapped('You can filter combat messages by editing the custom_combat_filters file and using words that would appear in unwanted messages.\n(e.g. effect wears off)\n\n> Words must be present in the original game combat message\n  (i.e. not words modified by addons)\n> Word matching is non case sensitive\n> More details in the custom_combat_filters file\n\n!!! Very long lists could cause performance issues !!!')
					imgui.Dummy({0,5});
					if imgui.Button('Edit Custom Filters') then
						local filepath = addon.path.."\\custom_combat_filters.txt"
						os.execute('start "" "' .. filepath .. '"')
					end
					if imgui.Button('Reload Custom Filters') then
						par_customFilters = utils.LoadCustomFilters();
					end
					imgui.Separator();
					imgui.Dummy({0,5});
					if (imgui.Checkbox('Enable Combat Log chat filters',{allSettings.CustomFilters[1]})) then 
						allSettings.CustomFilters[1] = not allSettings.CustomFilters[1];
						SaveSettings();
					end
					imgui.Dummy({0,5});
					
					if allSettings.CustomFilters[1] then
						imgui.Text('Current Combat Log Filters:')
						if imgui.BeginTable("resultTable", 2,bit.bor(ImGuiTableFlags_RowBg, ImGuiTableFlags_BordersH, ImGuiTableFlags_BordersV, ImGuiTableFlags_ContextMenuInBody)) then
							imgui.TableSetupColumn('Filter', ImGuiTableColumnFlags_WidthFixed, imgui.GetWindowWidth()*0.7, 0);imgui.TableSetupColumn('Applied to', ImGuiTableColumnFlags_WidthStretch, 0, 0);
							imgui.TableHeadersRow();
							for cf = 1, #par_customFilters do
								imgui.TableNextRow();
								imgui.TableSetColumnIndex(0);
								imgui.PushTextWrapPos(imgui.GetWindowWidth()*0.7);
								imgui.TextWrapped(par_customFilters[cf][1]:replace('%','%%'))
								imgui.PopTextWrapPos();
								imgui.TableSetColumnIndex(1);
								local cf_scope = ''
								if par_customFilters[cf][2] then	
									if par_customFilters[cf][2] == '_z' then cf_scope = cf_scope + 'All'
									elseif par_customFilters[cf][2] == '_y' then cf_scope = cf_scope + 'All but you'
									elseif par_customFilters[cf][2] == '_p' then cf_scope = cf_scope + 'All but party' end
								end
								imgui.PushTextWrapPos(imgui.GetWindowWidth()*0.9);
								imgui.TextWrapped(cf_scope)	
								imgui.PopTextWrapPos();
							end
							imgui.PopTextWrapPos();
							imgui.EndTable();
						end
					end
					
					
					imgui.EndChild();
					imgui.EndTabItem();
				end
				if imgui.BeginTabItem('Tools', nil) then
					imguiWrap.BeginChild('##Tools Child', {(setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3,setsizey*2.7/2.8-60}, true);
					--imguiWrap.BeginChild('##Extra Child', {300,300}, true);
					imgui.Dummy({0,5});
					imgui.Dummy({5,0});  imgui.SameLine();
					if(fcw[1].TextureIDLogs ~= nil and fcw[1].TextureIDLoading ~= nil) then
						if (imguiWrap.ImageButton('TextureIDLogs',fcw[1].SaveStart == 0 and fcw[1].TextureIDLogs or fcw[1].TextureIDLoading,{dsize.x/100,dsize.x/100},{-0.01,-0.01},{1.01,1.01},-1,{0,0,0,0},{1,1,1,1})) then
							if fcw[1].SaveStart == 0 then
								fcw[1].SaveStart = os.clock()-fcw[1].SaveStart
								AshitaCore:GetChatManager():QueueCommand(-1, "/fancychat savelogs");
							end
					
						end
					end
					if os.clock()-fcw[1].SaveStart > fcw[1].SaveCD then
						fcw[1].SaveStart = 0;
					end
					imgui.SameLine();
					imgui.SetCursorPosY(imgui.GetCursorPosY()+dsize.x/300);
					if fcw[1].SaveStart > 0 then
						imgui.Text('Saving...');
					else 
						imgui.Text('Save Chat Logs');
					end
					imgui.Dummy({0,5});
					imgui.Dummy({5,0});  imgui.SameLine();
					if(fcw[1].TextureIDFolder ~= nil) then
						if (imguiWrap.ImageButton('TextureIDFolder',fcw[1].TextureIDFolder,{dsize.x/100,dsize.x/100},{-0.01,-0.01},{1.01,1.01},-1,{0,0,0,0},{1,1,1,1})) then
							os.execute("mkdir "..addon.path .."logs\\"..fcw[1].PlayerName) 
							os.execute('start "" "' .. addon.path .."logs\\"..fcw[1].PlayerName.. '"')
						end
					end
					imgui.SameLine();
					imgui.SetCursorPosY(imgui.GetCursorPosY()+dsize.x/300);
					imgui.Text('Open Logs Folder');
					imgui.Dummy({0,5});
					imgui.Dummy({5,0});  imgui.SameLine();
					if(fcw[1].TextureIDManual ~= nil) then
						if (imguiWrap.ImageButton('TextureIDManual',fcw[1].TextureIDManual,{dsize.x/100,dsize.x/100},{0.01,0.01},{0.99,0.99},-1,{0,0,0,0},{1,1,1,1})) then
							help.opened[1] = not help.opened[1];
						end
					end
					imgui.SameLine();
					imgui.SetCursorPosY(imgui.GetCursorPosY()+dsize.x/300);
					imgui.Text('Open Manual');
					imgui.Dummy({0,5});
					imgui.Dummy({5,0});  imgui.SameLine();
					if(fcw[1].TextureIDDumpchat ~= nil) then
						if (imguiWrap.ImageButton('TextureIDDumpchat',fcw[1].TextureIDDumpchat,{dsize.x/100,dsize.x/100},{0.05,0.01},{0.98,1.0},-1,{0,0,0,0},{1,1,1,1})) then
							DumpChat('-------------- Chat restored --------------')
							b_OriginalBuffer = T{}
						end
					end
					imgui.SameLine();
					imgui.SetCursorPosY(imgui.GetCursorPosY()+dsize.x/300);
					imgui.Text('Restore Legacy Chat Logs');
					AddTooltip('Use this to restore chat logs in the legacy chat window. Use this to take chat log screenshots to submit for support tickets',0,1)
					imgui.EndChild();
					imgui.EndTabItem();
					

				end
				imgui.EndTabBar();
			end
			imgui.End();
			PopWindowStyle();
		else
			set_SecondChat[1] = allSettings.SecondChat[1];
			set_ChatLineMaxL = allSettings.chatLineMaxL;
			set_PlateBGColor = allSettings.rectSettings.fill_color;
			set_FontHeight = allSettings.fontSettings.font_height;
			for ct = 1, #allSettings.CustomTabModes do
				set_CustomTabModes[ct] = allSettings.CustomTabModes[ct];
			end
			set_ChatLines = allSettings.ChatLines;
		end
		
		if not fcw[1].HideChat and not fcw[1].Closing and not fcw[1].ProcessingText and fcw[1].autoHideFade < 1 then 
		-- Updating chat lines status (must be done even if chat is not displayed) ?? --and b_ChatBufferIdx[1] < b_ChatBufferN[1]
			if fcw[1].PrevHideChat ~= fcw[1].HideChat and fcw[1].PrevHideChat  then  ResetScrolling(1) fcw[1].RequestAuxFix = true end;
			
			fcw[1].ChatShiftScale_Target = fcw[1].ChatShiftScale_Base * ( ( 1.2^( b_ChatBufferN[1]-b_ChatBufferIdx[1] ) )-1)+fcw[1].ChatShiftScale_Min;
			--print(tostring(b_ChatBufferN[1]))
			if (b_ChatBufferN[1]>0) then
				--print('hello')
				if (b_ChatBufferIdx[1] < b_ChatBufferN[1] and not fcw[1].Scrolling and not fcw[1].Dragging and not fcw[3].Scrolling) then
					fcw[1].PositionLinesRequest[1] = true;
					
					if fcw[1].ChatShiftScale < fcw[1].ChatShiftScale_Target then
						fcw[1].ChatShiftScale = fcw[1].ChatShiftScale +1;		
					else
						fcw[1].ChatShiftScale =fcw[1].ChatShiftScale_Target
					end
					
					--if (fcw[1].ChatShift == allSettings.fontSettings.font_height) then
					--	fcw[1].ChatShift_Start = os.clock();
						--fcw[1].ChatShift = fcw[1].ChatShift - 0.01;
					--end
					
					local doupdate = false;
					if(fcw[1].ChatShift >= 0 ) then
						
						fcw[1].ChatShift = fcw[1].ChatShift - ((os.clock()-fcw[1].OsClockLast))*(fcw[1].ChatShiftScale);
						if fcw[1].ChatShift <= 0 then
							doupdate = true;
							--fcw[1].ChatShift = 0;
							if  b_ChatBufferN[1] - b_ChatBufferIdx[1] > 1 then
								fcw[1].ChatShift = allSettings.fontSettings.font_height - math.min(-1*fcw[1].ChatShift, allSettings.fontSettings.font_height);
								--if fcw[1].ChatShift == 0 then fcw[1].ChatShift = fcw[1].ChatShift + 0.001; end
							--else
								--fcw[1].ChatShift = 0; 
								--fcw[1].ChatShift = allSettings.fontSettings.font_height
					--			fcw[1].ChatShiftScale_CarryOver = 0;
							end
						end
						--PrepareLines(1);
					end
						
						
					if doupdate then 
						--print(tostring(b_ChatBufferMode[1]))
						local bufferIdx = utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text) -(b_ChatBufferN[1]-b_ChatBufferIdx[1]-1);
						if bufferIdx > #b_ChatBuffer[b_ChatBufferMode[1]][2].text or b_ChatBuffer[b_ChatBufferMode[1]][2].text[bufferIdx] == nil then
							ResetLines(1);
						else
							UpdateLines(1,
									b_ChatBuffer[b_ChatBufferMode[1]][2].text[bufferIdx],
									b_ChatBuffer[b_ChatBufferMode[1]][2].color[bufferIdx],
									b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[bufferIdx],
									b_ChatBuffer[b_ChatBufferMode[1]][2].auxColor[bufferIdx]
									);
							--fcw[1].ChatShift = allSettings.fontSettings.font_height;
							b_ChatBufferIdx[1] = b_ChatBufferIdx[1]+1;
						end
						--fcw[1].OutlineColor = 0xFF000000;
						fo_Aux[1][fcw[1].ChatHead]:set_opacity(1)
						fo_Chat[1][fcw[1].ChatHead]:set_opacity(1)
						--fo_Aux[1][fcw[1].ChatHead]:set_outline_color(0xFF000000);
						--fo_Chat[1][fcw[1].ChatHead]:set_outline_color(0xFF000000);
						if b_ChatBufferIdx[1] == b_ChatBufferN[1] then
							fcw[1].ChatShift = allSettings.fontSettings.font_height;
						end
					end
					
				else
					if fcw[1].ChatShiftScale > fcw[1].ChatShiftScale_Target then
						fcw[1].ChatShiftScale = fcw[1].ChatShiftScale - 2;
						if (fcw[1].ChatShiftScale_Target == fcw[1].ChatShiftScale_Base+fcw[1].ChatShiftScale_Min) then
							fcw[1].ChatShiftScale = fcw[1].ChatShiftScale - 1;
						end
					end
					
					if (fcw[1].ChatShiftScale < fcw[1].ChatShiftScale_Min) then
						fcw[1].ChatShiftScale = fcw[1].ChatShiftScale_Min;
					end
					--fcw[1].ChatShift = allSettings.fontSettings.font_height;
					
					if (fcw[1].Scrolling and fcw[1].ScrollUpRequest)
					then
						fcw[1].ScrollUpRequest = false;
						ScrollLines(1,
							b_ChatBuffer[b_ChatBufferMode[1]][2].text[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text)-allSettings.ChatLines-fcw[1].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[1])],
							b_ChatBuffer[b_ChatBufferMode[1]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text)-allSettings.ChatLines-fcw[1].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[1])],
							b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text)-allSettings.ChatLines-fcw[1].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[1])],
							b_ChatBuffer[b_ChatBufferMode[1]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text)-allSettings.ChatLines-fcw[1].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[1])],
							1
						);
							
						fcw[1].ScrolledBack = fcw[1].ScrolledBack +1;
							--print('hello')
							--if fcw[1].ScrolledBack > utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode][2].text)-allSettings.ChatLines-(b_ChatBufferN-b_ChatBufferIdx) then fcw[1].ScrolledBack = fcw[1].ScrolledBack -1 end

					else
						if (fcw[1].Scrolling and fcw[1].ScrollDownRequest) then
							fcw[1].ScrollDownRequest = false;
							ScrollLines(1,
								b_ChatBuffer[b_ChatBufferMode[1]][2].text[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text)+1-fcw[1].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[1])],
								b_ChatBuffer[b_ChatBufferMode[1]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].color)+1-fcw[1].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[1])],
								b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].auxText)+1-fcw[1].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[1])],
								b_ChatBuffer[b_ChatBufferMode[1]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].auxColor)+1-fcw[1].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[1])],
								0
							);
							fcw[1].ScrolledBack = fcw[1].ScrolledBack -1;
							if fcw[1].ScrolledBack == 0 then
								fcw[1].Scrolling = false;
								ResetLines(1);
							end
						end
					end
					
				end
			end	
			fcw[1].OsClockLast = os.clock();
			fcw[1].PrevMoveChat = fcw[1].MoveChat;
		end
------------------------------------------------------------------------------
		if allSettings.SecondChat[1] then
			
			if (tab_NextTab2 ~= allSettings.SelectedTab2 ) then
				fcw[1].BufferBusy = true;
				ChangeTab(2, tab_NextTab2);
				b_ChatBufferN[2] = SetBufferN(allSettings.SelectedTab2);
				ResetScrolling(2);
			else
				b_ChatBufferN[2] = SetBufferN(allSettings.SelectedTab2);
			end
			
			
			--end
			if allSettings.SelectedTab2 == 'All' and allSettings.HideCombatFromAll[1] then b_ChatBufferN[2]=b_ChatBufferN_AllAlt;  end
			
			if (not uiw.LegacyChatOpen and not fcw[1].HideChat and not fcw[1].Closing and fcw[1].autoHideFade < 1 and not fcw[3].BigMode) then
				
				
				imgui.SetNextWindowSize({ fcw[2].BG_W, ro_RectBG[2].settings.height+16 } );
				imgui.SetNextWindowSizeConstraints({ fcw[2].BG_W, ro_RectBG[2].settings.height+16 }, { FLT_MAX, FLT_MAX, } );
				
				--if allSettings.LockWindowPos[1] then fcw[1].windowFlagsChatBG = bit.bor(fcw[1].windowFlagsChatBG,ImGuiWindowFlags_NoMove); end
				imgui.Begin('FancyChat_ChatBG2_'+fcw[1].PlayerName, true, bit.bor(fcw[1].windowFlagsChatBG, allSettings.LockWindowPos[1] and ImGuiWindowFlags_NoMove or 0));
				
			-- Setting variables to position the chat window elements --
				local positionStartX, positionStartY = imgui.GetCursorScreenPos();
				positionStartX = positionStartX + allSettings.WindowPosOffset[3];
				positionStartY = positionStartY + allSettings.WindowPosOffset[4];
				if fcw[1].MoveChat and not mvc_Menu6 then
					if allSettings.CSMode[2] == 2 then
						positionStartY = dsize.y;
						if fcw[1].GuideMeDocked and allSettings.GuideMeSecondWindow[1] then fcw[1].GuideMeClosedTmp = true; end
						if fcw[1].NotepadDocked and allSettings.GuideMeSecondWindow[1] then fcw[1].NotepadClosedTmp = true; end
					elseif allSettings.CSMode[2] == 3 then
						positionStartX = mvc_targetposX + math.floor(fcw[1].BG_W)
					
					end
					fcw[1].MoveChat = false;
				else
					fcw[1].NotepadClosedTmp = false
					fcw[1].GuideMeClosedTmp = false
					if allSettings.GuideMeSecondWindow[1] then fcw[1].GuideMeClosedTmp = false; end
					fcw[1].MoveChat = (mvc_Menu1 or mvc_Menu2 or mvc_Menu3 or mvc_Menu4 or mvc_Menu5 or mvc_Menu6 or uiw.DialogShown) and allSettings.LockWindowPos[1] and allSettings.EnabledChatMove[1];
					if fcw[1].MoveChat and positionStartX < mvc_targetposX
					and fcw[2].Anchor_Y > mvc_targetposY then
						positionStartX = mvc_targetposX;
						fcw[1].MoveChat = true;
					elseif fcw[1].MoveChat and mvc_Menu6 and positionStartY+fcw[1].BG_H > mvc_targetposY then
						--print(positionStartY+fcw[1].BG_H..'-'..mvc_targetposY)
						positionStartY = mvc_targetposY-fcw[1].BG_H
						fcw[1].MoveChat = false;
					else
						fcw[1].MoveChat = false;
					end
					
				end
				
				local centerPosX = (fcw[2].BG_W/2 + positionStartX-3);
				local centerPosY = (ro_RectBG[2].settings.height/2 + positionStartY)+3;
				--local imageSizeX = fcw[1].BG_W/((allSettings.fontSettings.font_height+0.4)/allSettings.fontSettings.font_height);
				local imageSizeX = (fcw[2].BG_W/2);
				local imageSizeY = ro_RectBG[2].settings.height/2;
				--Debug(tostring(positionStartX+(fcw[1].BG_W/(allSettings.fontSettings.font_height*10))), 1, false);
				
				
				
				fcw[2].Anchor_X = positionStartX;--+(fcw[1].BG_W/(allSettings.fontSettings.font_height*10));--60);
				fcw[2].Anchor_Y = positionStartY+(fcw[2].BG_H*0.8);
				--if fcw[1].Anchor_X == 0 or math.abs(fcw[1].Anchor_X - fcw[1].PrevAnchor_X) >0.1  or
				--fcw[1].Anchor_Y == 0 or math.abs(fcw[1].Anchor_Y - fcw[1].PrevAnchor_Y) >0.1
				fcw[2].PosChanged = false;
				if fcw[2].Anchor_X == 0 or math.abs(fcw[2].Anchor_X - fcw[2].PrevAnchor_X) > 0.1 or
				fcw[2].Anchor_Y == 0 or math.abs(fcw[2].Anchor_Y - fcw[2].PrevAnchor_Y) > 0.1 
				then
					fcw[2].PosChanged = true;
					fcw[2].PositionLinesRequest = {true,true};
				end
				fcw[2].PrevAnchor_X = fcw[2].Anchor_X;
				fcw[2].PrevAnchor_Y = fcw[2].Anchor_Y;
				
				
				if fcw[2].Scrolling then
					if fcw[2].ScrollPos ~= GetScrollPoint(2) then fcw[2].PositionLinesRequest = {true,true}; end
					fcw[2].ScrollPos = GetScrollPoint(2);
					ro_Scroll[2]:set_visible(true);
				else
					fcw[2].ScrollPos = 1;
					ro_Scroll[2]:set_visible(false);
				end
				
				local mouseX, mouseY = imgui.GetMousePos();
				if (
					mouseX > centerPosX - fcw[2].BG_W and mouseX < centerPosX + fcw[2].BG_W
					and mouseY > centerPosY - fcw[2].BG_H/2 and mouseY < centerPosY + fcw[2].BG_H/2
					and imgui.IsMouseDragging(ImGuiMouseButton_Left)
					and imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly)
					)
				then
					fcw[2].Dragging = true;
					if (fcw[1].TextureIDBorder ~= nil ) then
						imgui.GetWindowDrawList():AddImage(fcw[1].TextureIDBorder, {centerPosX-imageSizeX, centerPosY-imageSizeY}, {centerPosX+imageSizeY, centerPosY+imageSizeY}, {0,0}, {1,1}, imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.75 }));
					end
				end
				
				if fcw[2].Dragging and imgui.IsMouseReleased then fcw[2].Dragging = false end;

			-- Setting up line highlighting --
				if IsRectHovered(ro_RectBG[2].settings,0) then
					fcw[2].HoverLine = -1;
					local parsedUrl = '';
					local lineOffsetBase = (fcw[2].BG_H/120)+(allSettings.fontSettings.font_height)
					for HL_i = 0, allSettings.ChatLines-1 do
						local lineOffset= lineOffsetBase+HL_i*allSettings.fontSettings.font_height;
						local highlight_alpha = 0;
						local targetLine = allSettings.ChatLines-HL_i+fcw[2].ChatHead-1; if targetLine > allSettings.ChatLines then targetLine = targetLine -allSettings.ChatLines end
						--print(tostring(targetLine))
						if (fo_Aux[2][targetLine].settings.visible and fo_Aux[2][targetLine].settings.text == '[link]' and
							fo_Chat[2][targetLine].rect ~= nil and fo_Aux[2][targetLine].rect~= nil and 
							mouseX >  fo_Aux[2][targetLine].settings.position_x and mouseX < fo_Aux[2][targetLine].settings.position_x + fo_Aux[2][targetLine].rect.right and
							mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+allSettings.fontSettings.font_height and not fcw[2].Dragging
							)
						then
							if (fo_Aux[2][targetLine] ~= nil) then
								fo_Aux[2][targetLine]:set_font_color(0xFFCCEEFF);
								fcw[2].HoverLine = allSettings.ChatLines-HL_i;
								local ChatHoverIdx = utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].url)-fcw[2].HoverLine-fcw[2].ScrolledBack-(b_ChatBufferN[2]-b_ChatBufferIdx[2])+1;
								--Debug(tostring(ChatHoverIdx)..'-'..b_ChatBuffer[b_ChatBufferMode][2].text[ChatHoverIdx],2,false);
								if ChatHoverIdx > 0 then
									--parsedUrl = utils.ParseUrlLink(b_ChatBuffer[b_ChatBufferMode][2].text[ChatHoverIdx]);
									--Debug(tostring(b_ChatBuffer[b_ChatBufferMode][2].url[ChatHoverIdx]), 2, false);
									if imgui.IsMouseClicked(ImGuiMouseButton_Left) then
									local urlText = utils.stringsplit(b_ChatBuffer[b_ChatBufferMode[2]][2].url[ChatHoverIdx],'|')
									ashita.misc.open_url((string.find(urlText[2], 'https://') or string.find(urlText[2], 'http://localhost:')) and urlText[2] or 'https://'..urlText[2]);
								end
								end
								fcw[2].HoverLine = -1;
							end
							--break
						else
							if (fo_Aux[2][targetLine]~= nil and fo_Aux[2][targetLine].settings.text == '[link]') then
								fo_Aux[2][targetLine]:set_font_color(0xFF44CCFF);
							end
							if (mouseX > fcw[2].Anchor_X and mouseX < fcw[2].Anchor_X+fcw[2].BG_W and
							mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+allSettings.fontSettings.font_height and
							imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly)
							)
							then
								--local targetLine = 8-HL_i+fcw[1].ChatHead-1; if targetLine > 8 then targetLine = targetLine -8 end
								--dw_TestMessage = tostring(targetLine)..'-'..tostring(fo_Chat[1][targetLine] ~= nil);
								--if fo_Chat[1][targetLine] ~= nil then Debug(fo_Chat[1][targetLine].settings.text, 1, false); end
								fcw[2].HoverLine = allSettings.ChatLines-HL_i;
								highlight_alpha = 0.3;
								imgui.GetWindowDrawList():AddRectFilledMultiColor({fcw[2].Anchor_X, positionStartY+lineOffset}, {fcw[2].Anchor_X+imageSizeX, (positionStartY+lineOffset+allSettings.fontSettings.font_height)},
								imgui.GetColorU32({ 1.0, 1.0, 1.0, highlight_alpha }),
								imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.0 }),
								imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.0 }),
								imgui.GetColorU32({ 1.0, 1.0, 1.0, highlight_alpha })
								);
								--break
							end
							
						end
					end
				end
				
				if (fcw[2].HoverLine > 0 and imgui.IsMouseClicked(ImGuiMouseButton_Left)) then fcw[2].Clicking = true; end
				
				if (fcw[2].HoverLine > 0 and imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly)) then
					
					local copyBufferIdx = utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].text)-fcw[2].HoverLine-fcw[2].ScrolledBack-(b_ChatBufferN[2]-b_ChatBufferIdx[2])+1;
					local copyBufferText = '';
					if (copyBufferIdx > 0 ) then
					local ID = b_ChatBuffer[b_ChatBufferMode[2]][2].url[copyBufferIdx]
					local IDs = 0
					local IDe = 0
					while b_ChatBuffer[b_ChatBufferMode[2]][2].url[copyBufferIdx+IDs] and
					    --type(b_ChatBuffer[b_ChatBufferMode[2]][2].url[copyBufferIdx+IDs])=="number" and
						b_ChatBuffer[b_ChatBufferMode[2]][2].url[copyBufferIdx+IDs] == ID do
						IDs = IDs - 1
					end
					while b_ChatBuffer[b_ChatBufferMode[2]][2].url[copyBufferIdx+IDe] and
						--type(b_ChatBuffer[b_ChatBufferMode[2]][2].url[copyBufferIdx+IDe])=="number" and
						b_ChatBuffer[b_ChatBufferMode[2]][2].url[copyBufferIdx+IDe]	== ID do
						IDe = IDe + 1
					end
					
					local IDi = math.min(IDs+1,0)
					--print(IDi) print(math.max(IDe-1,0))
					while IDi <= math.max(IDe-1,0) do
					--copyBufferText = b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] ~= '[link]' and copyBufferText..b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] or copyBufferText..b_ChatBuffer[b_ChatBufferMode[1]][2].text[copyBufferIdx+IDi]
					
					if b_ChatBuffer[b_ChatBufferMode[2]][2].text[copyBufferIdx+IDi] then
						copyBufferText = (' '..copyBufferText..b_ChatBuffer[b_ChatBufferMode[2]][2].text[copyBufferIdx+IDi]):trimex()
						if b_ChatBuffer[b_ChatBufferMode[2]][2].auxText[copyBufferIdx+IDi] ~= '[link]' then
							copyBufferText = copyBufferText..' '..b_ChatBuffer[b_ChatBufferMode[2]][2].auxText[copyBufferIdx+IDi]
						end
					else
						break
					end
					IDi = IDi + 1;
					end
					end
					copyBufferText = utils.cleanMC(copyBufferText)
					if allSettings.ItemPreview[1] then
						DrawInfo(copyBufferText)
					end
					if (fcw[2].Clicking and imgui.IsMouseReleased(ImGuiMouseButton_Left)) then
						fcw[2].Clicking = false;
						if(copyBufferText ~=nil) then
							if imgui.GetIO().KeyShift then
								if #allSettings.Notes < 10 and #copyBufferText > 0 then
									table.insert(allSettings.Notes, copyBufferText)
									print('Message saved in the Notepad ['..#allSettings.Notes..'/10]')
									SaveSettings();
								else
									print('Notepad notes full [10/10]')
								end
							else
								utils.SetClipboardText(utils.RevertShiftJIS(copyBufferText))
								AshitaCore:GetChatManager():QueueCommand(1, "/echo Text successfully copied to clipboard!");
							end
						end
					end
				end
			
				if (fcw[2].Clicking and (imgui.IsMouseDragging(ImGuiMouseButton_Left) or not imgui.IsMouseDown(ImGuiMouseButton_Left) )) then fcw[2].Clicking = false; end
				
				local scrollOffset= (fcw[2].BG_H/120);

				--if (mouseX > fcw[1].Anchor_X and mouseX < fcw[1].Anchor_X+fcw[1].BG_W and
				if (imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly) or gamepadButtons.enabled) and not fcw[1].BufferBusy
				
				then
					if (
						fcw[2].ScrollDelta > 0
						and utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].text) - fcw[2].ScrolledBack - (b_ChatBufferN[2]-b_ChatBufferIdx[2]) > allSettings.ChatLines
					)
					then
						if not imgui.GetIO().KeyShift or not fcw[2].Scrolling then
							fcw[2].ScrollDelta = 0;
							fcw[1].ScrollDelta = 0;
							fcw[2].Scrolling = true;
							fcw[2].ChatShift = allSettings.fontSettings.font_height
							fcw[2].ScrollUpRequest = true;
						elseif fcw[2].Scrolling then
							local currentIdx = #b_ChatBuffer[b_ChatBufferMode[2]][2].text - (b_ChatBufferN[2]-b_ChatBufferIdx[2]) - 1
							GoToLine(2,math.max(currentIdx-(fcw[2].ScrolledBack+5), allSettings.ChatLines), currentIdx);
						end
					else
						if ( fcw[2].ScrollDelta < 0 and fcw[2].ScrolledBack > 0 ) then
							if not imgui.GetIO().KeyShift or not fcw[2].Scrolling then
								fcw[2].ScrollDelta = 0;
								fcw[1].ScrollDelta = 0;
								fcw[2].Scrolling = true;
								fcw[2].ChatShift = allSettings.fontSettings.font_height
								fcw[2].ScrollDownRequest = true;
							elseif fcw[2].Scrolling then
								local currentIdx = #b_ChatBuffer[b_ChatBufferMode[2]][2].text - (b_ChatBufferN[2]-b_ChatBufferIdx[2]) - 1
								GoToLine(2,math.min(currentIdx-(fcw[2].ScrolledBack-5), currentIdx-1), currentIdx);
							end
						end
					end
					ResetAutoHideTimer()
				end
				fcw[2].ScrollDelta=0;
				
				if (fcw[2].ScrolledBack > 0) then
					fo_Bkw[2]:set_visible(true);
				else

					fo_Bkw[2]:set_visible(false);
				end
				
			--	local tabsPosX, tabsPosY = imgui.GetWindowPos();
				imgui.End();
				
			-- Preparing some variables for the Tabs window --
		
	
				local tabsW = ro_RectBG[2].settings.width;
				local tabsH = fcw[2].BG_H/(allSettings.ChatLines)+2;
				--PositionLines();
				if not allSettings.CompactTabs then
					if fcw[2].PosChanged or not fcw[2].TabsPos then
						fcw[2].TabsPos = {math.floor(fcw[2].Anchor_X-(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)-((allSettings.fontSettings.font_height*5)/allSettings.fontSettings.font_height)),math.floor(fcw[2].Anchor_Y+tabsH-2)+math.floor(allSettings.fontSettings.font_height/25)}
					end
					imgui.SetNextWindowPos(fcw[2].TabsPos);
				
					imgui.SetNextWindowSize({ tabsW+8, ro_RectBG[2].settings.height/(allSettings.ChatLines*0.7) });
				else
					if fcw[2].PosChanged or not fcw[2].compactPos or not fcw[2].compactSize then
						fcw[2].compactPos = {fcw[2].Anchor_X+(ro_RectBG[2].settings.width-(tabsW/#tab_Tabs))*0.995-1, fcw[2].Anchor_Y - ro_RectBG[2].settings.height+(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)+allSettings.fontSettings.font_height*1.3-1}; 
				
						fcw[2].compactSize = { tabsW/#tab_Tabs+(tabsH-(allSettings.fontSettings.font_height/1.2)+3), ro_RectBG[2].settings.height/8 };
					end
					if not allSettings.CompactTabsBL[1] then
						imgui.SetNextWindowPos(fcw[2].compactPos);
					else
						if fcw[2].PosChanged or not fcw[2].TabsPos then
							fcw[2].TabsPos = {math.floor(fcw[2].Anchor_X-(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)-((allSettings.fontSettings.font_height*5)/allSettings.fontSettings.font_height)),math.floor(fcw[2].Anchor_Y+tabsH-2)+math.floor(allSettings.fontSettings.font_height/25)}
						end
						imgui.SetNextWindowPos(fcw[2].TabsPos);
					end
					imgui.SetNextWindowSize(fcw[2].compactSize)
						
				end
				--imgui.SetNextWindowSizeConstraints({ tabsW, tabsH }, { FLT_MAX, FLT_MAX, });
				
				windowFlags = bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_NoBackground);
				
				imgui.Begin('FancyChat_ChatTabs2_'+fcw[1].PlayerName, true, windowFlags);
				--local font = imgui.GetFont();
				--local prevFontSize = font.FontSize;
				--font.FontSize = 450/allSettings.fontSettings.font_height;
				
				--imgui.SetWindowFontScale(allSettings.fontSettings.font_height/25);
				local IWwindowfont2 = imguiWrap.SetWindowFontScale(allSettings.fontSettings.font_height/25)
				--imgui.SetWindowPos({fcw[1].Anchor_X-(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)-((allSettings.fontSettings.font_height*5)/allSettings.fontSettings.font_height),fcw[1].Anchor_Y+(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)+allSettings.fontSettings.font_height*1.2});
				--imgui.SetWindowSize({ tabsW+tabsH*2, tabsH });
				--imgui.SetWindowSizeConstraints({ tabsW, tabsH }, { FLT_MAX, FLT_MAX, });
				--print('hello') 
				PushColorStyles(tab_ButtonColorStylesNormal);

				if not allSettings.CompactTabs then
					local reserved = tabsW -1.5
					local cursY = imgui.GetCursorPosY()-7
					local cursx = imgui.GetCursorPosX()-4
					for T_i = 1, utils.GetTableLen(tab_Tabs) do
						imgui.SetCursorPos({cursx+(reserved/#tab_Tabs)*(T_i-1),cursY});
						if (tab_Tabs[T_i] == allSettings.SelectedTab2) then
							PushColorStyles(tab_ButtonColorStylesSelected);
							imgui.Button(tab_Tabs[T_i]:gsub('Alt','##Alt'),{reserved/#tab_Tabs,tabsH-2});
							PopColorStyles(tab_ButtonColorStylesSelected);
						else
							if (imgui.Button(tab_Tabs[T_i]:gsub('Alt','##Alt'),{reserved/#tab_Tabs,tabsH-2})) then
								tab_NextTab2 = tab_Tabs[T_i]; 
							end
						end
					end
				
				else
					imgui.PushStyleVar(ImGuiStyleVar_FrameBorderSize, 0);
				
					button_length = {tabsW/#tab_Tabs, 0}
					length_ref = allSettings.fontSettings.font_height*4.5
					if button_length[1] > length_ref then button_length[1] = length_ref; button_length[2] = tabsW/#tab_Tabs - length_ref end
					
					for T_i = 1, utils.GetTableLen(tab_Tabs) do
					if (tab_Tabs[T_i] == allSettings.SelectedTab2) then
							if allSettings.CompactTabsBL[1] then
								imgui.SetCursorPos({0,0});
							else
								imgui.SetCursorPos({button_length[2],0});
							end
							--imgui.SetCursorPos({button_length[2],0});
							if imgui.Button(tab_Tabs[T_i]:gsub('Alt','##Alt'),{button_length[1],tabsH-6}) then
							--if imgui.Button(tab_Tabs[T_i]:gsub('Alt','##Alt'),{tabsW/#tab_Tabs,tabsH-6}) then
								if T_i+1 <= #tab_Tabs then tab_NextTab2 = tab_Tabs[T_i+1]; else  tab_NextTab2 = tab_Tabs[1] end
							end
						end
					end
						
						
					imgui.PopStyleVar(1);
				end
				PopColorStyles(tab_ButtonColorStylesNormal);
				--font.FontSize = prevFontSize;
				if IWwindowfont2 then imgui.PopFont() end
				imgui.End();
			end
			--print(tostring(b_ChatBufferN[2]))
			if not fcw[1].HideChat and not fcw[1].Closing and not fcw[1].ProcessingText and (not allSettings.AutoHideWindow[1] or os.time() - fcw[1].autoHideTime < allSettings.AutoHideTimeMax) then 	
				
				if fcw[1].PrevHideChat ~= fcw[1].HideChat and fcw[1].PrevHideChat then ResetScrolling(2) fcw[2].RequestAuxFix = true end;
				
				--print(tostring(b_ChatBufferN[2]));
				fcw[2].ChatShiftScale_Target = fcw[2].ChatShiftScale_Base * ( ( 1.2^( b_ChatBufferN[2]-b_ChatBufferIdx[2] ) )-1)+fcw[2].ChatShiftScale_Min;
				
				if (b_ChatBufferN[2]>0) then

					if (b_ChatBufferIdx[2] < b_ChatBufferN[2] and not fcw[2].Scrolling and not fcw[2].Dragging and not fcw[3].Scrolling) then
						fcw[2].PositionLinesRequest[1] = true;
						
						if fcw[2].ChatShiftScale < fcw[2].ChatShiftScale_Target then
							fcw[2].ChatShiftScale = fcw[2].ChatShiftScale +1;
						else
							fcw[2].ChatShiftScale =fcw[2].ChatShiftScale_Target
						end
						
						--if (fcw[2].ChatShift == allSettings.fontSettings.font_height) then
						--	fcw[2].ChatShift_Start = os.clock();
						--	fcw[2].ChatShift = fcw[2].ChatShift - 0.01 
						--end
						local doupdate = false;
						if(fcw[2].ChatShift >= 0 ) then
							fcw[2].ChatShift = fcw[2].ChatShift - ((os.clock()-fcw[2].OsClockLast))*(fcw[2].ChatShiftScale);
						--	if fcw[2].ChatShift == 0 then
								--fcw[2].ChatShift = allSettings.fontSettings.font_height;
						--	else
								if fcw[2].ChatShift <= 0 then 
									doupdate = true;
									--fcw[2].ChatShift = 0; 
									if  b_ChatBufferN[2] - b_ChatBufferIdx[2] > 1 then
									
										fcw[2].ChatShift = allSettings.fontSettings.font_height - math.min(-1*fcw[2].ChatShift, allSettings.fontSettings.font_height);
									--else
										--fcw[2].ChatShift = 0;
										--fcw[2].ChatShift = 0.01;									
						--				fcw[2].ChatShiftScale_CarryOver = 0;
									end
					--			else
									
								end
						--	end
							--PrepareLines(2);
						end	
						if doupdate then
							--print(tostring(b_ChatBuffer[0]));
							local bufferIdx = utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].text) -(b_ChatBufferN[2]-b_ChatBufferIdx[2]-1);
							if bufferIdx > #b_ChatBuffer[b_ChatBufferMode[2]][2].text or b_ChatBuffer[b_ChatBufferMode[2]][2].text[bufferIdx] == nil then
								ResetLines(2);
							else
								UpdateLines(2,
											b_ChatBuffer[b_ChatBufferMode[2]][2].text[bufferIdx],
											b_ChatBuffer[b_ChatBufferMode[2]][2].color[bufferIdx],
											b_ChatBuffer[b_ChatBufferMode[2]][2].auxText[bufferIdx],
											b_ChatBuffer[b_ChatBufferMode[2]][2].auxColor[bufferIdx]
											);
								
								--fcw[2].ChatShiftScale_CarryOver = 0;
								b_ChatBufferIdx[2] = b_ChatBufferIdx[2]+1;
							end
							--fcw[2].OutlineColor = 0xFF000000;
							fo_Aux[2][fcw[2].ChatHead]:set_opacity(1)
							fo_Chat[2][fcw[2].ChatHead]:set_opacity(1)
							--fo_Aux[2][fcw[2].ChatHead]:set_outline_color(0xFF000000);
							--fo_Chat[2][fcw[2].ChatHead]:set_outline_color(0xFF000000);
							if b_ChatBufferIdx[2] == b_ChatBufferN[2] then
								 fcw[2].ChatShift = allSettings.fontSettings.font_height
							end
							--if fcw[2].ChatShift < 0 and b_ChatBufferIdx[2] < b_ChatBufferN[2] then
							--fcw[2].ChatShift = allSettings.fontSettings.font_height + fcw[2].ChatShift;
							--else
								--fcw[2].ChatShift = 0;
							--end
						end
					else
						
						if fcw[2].ChatShiftScale > fcw[2].ChatShiftScale_Target then
							fcw[2].ChatShiftScale = fcw[2].ChatShiftScale - 2;
							if (fcw[2].ChatShiftScale_Target == fcw[2].ChatShiftScale_Base+fcw[2].ChatShiftScale_Min) then
								fcw[2].ChatShiftScale = fcw[2].ChatShiftScale - 1;
							end
						end
						
						if (fcw[2].ChatShiftScale < fcw[2].ChatShiftScale_Min) then
							fcw[2].ChatShiftScale = fcw[2].ChatShiftScale_Min;
						end
						fcw[2].ChatShift = allSettings.fontSettings.font_height;
						
						if (fcw[2].Scrolling and fcw[2].ScrollUpRequest)
						then
							fcw[2].ScrollUpRequest = false;
							ScrollLines(2,
								b_ChatBuffer[b_ChatBufferMode[2]][2].text[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].text)-allSettings.ChatLines-fcw[2].ScrolledBack-(b_ChatBufferN[2]-b_ChatBufferIdx[2])],
								b_ChatBuffer[b_ChatBufferMode[2]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].text)-allSettings.ChatLines-fcw[2].ScrolledBack-(b_ChatBufferN[2]-b_ChatBufferIdx[2])],
								b_ChatBuffer[b_ChatBufferMode[2]][2].auxText[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].text)-allSettings.ChatLines-fcw[2].ScrolledBack-(b_ChatBufferN[2]-b_ChatBufferIdx[2])],
								b_ChatBuffer[b_ChatBufferMode[2]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].text)-allSettings.ChatLines-fcw[2].ScrolledBack-(b_ChatBufferN[2]-b_ChatBufferIdx[2])],
								1
							);
							
							fcw[2].ScrolledBack = fcw[2].ScrolledBack +1;
							--print('hello')
							--if fcw[1].ScrolledBack > utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode][2].text)-allSettings.ChatLines-(b_ChatBufferN-b_ChatBufferIdx) then fcw[1].ScrolledBack = fcw[1].ScrolledBack -1 end

						else
							if (fcw[2].Scrolling and fcw[2].ScrollDownRequest) then
								fcw[2].ScrollDownRequest = false;
								ScrollLines(2,
									b_ChatBuffer[b_ChatBufferMode[2]][2].text[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].text)+1-fcw[2].ScrolledBack-(b_ChatBufferN[2]-b_ChatBufferIdx[2])],
									b_ChatBuffer[b_ChatBufferMode[2]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].color)+1-fcw[2].ScrolledBack-(b_ChatBufferN[2]-b_ChatBufferIdx[2])],
									b_ChatBuffer[b_ChatBufferMode[2]][2].auxText[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].auxText)+1-fcw[2].ScrolledBack-(b_ChatBufferN[2]-b_ChatBufferIdx[2])],
									b_ChatBuffer[b_ChatBufferMode[2]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].auxColor)+1-fcw[2].ScrolledBack-(b_ChatBufferN[2]-b_ChatBufferIdx[2])],
									0
								);
								fcw[2].ScrolledBack = fcw[2].ScrolledBack -1;
								if fcw[2].ScrolledBack == 0 then
									fcw[2].Scrolling = false;
									ResetLines(2);
								end
							end
						end
					
					end
				end
				
				fcw[2].OsClockLast = os.clock();
			end
		end
		fcw[1].PrevHideChat = fcw[1].HideChat
		
		if not allSettings.firstLoadMessage[1] then
			AddWarning(
			'Please Read!\n\nWelcome to FancyChat addon!\n\nThis is addon provides a highly customizable and interactive chat replacemante for Final Fantasy XI.\nPlease take your time to check all the settings by either clicking the cog wheel icon at the bottom of the chat window or by typing the command \"/fancychat settings\".\n\nYou can hover with your mouse over the (i) icons to learn more about each functionality. This addon features some advanced options that can include unwanted behaviors for certain players. Therefore, please pay extra attention to the (i) marked in red to learn about important critical information about such features.\n\nFor further help you can check the addon manual accessible from the settings menu or through the command \"/fancychat manual\".\n\nHave fun!'
			,
			dsize.y/2, allSettings.firstLoadMessage, dsize.x/2, 'Welcome to FancyChat')
		end
	end
	
	--if fcw[1].DisplayManual then
	if help.opened[1] then
		PushWindowStyle()
		help.ShowManual(fcw[1].PlayerName);
		PopWindowStyle()
	end
	
	
	
	--end
	--fcw[1].PrevHideChat = fcw[1].HideChat
------------------------------------------
		
	--if fcw[1].LoggedIn then
	-- Render Debug Window if opened --
	
	if (dw_WindowOpened[1]) then DebugWindow(); end
	
end);

ashita.events.register('d3d_endscene', 'd3d_endscene_callback1', function (isRenderingBackBuffer)

	if (not isRenderingBackBuffer) then return; end

    -- isRenderingBackBuffer is a flag that will be true when the game is currently rendering to the back buffer.
	--and fcw[1].LoggedLobby ~= 1
	if (fcw[1].PlayerName ~= '---' and fcw[1].LoggedLobby ~= 1 and not fcw[1].Zoning and fcw[1].LoggedIn and #settings.name > 0 and fcw[1].RenderFOs and not fcw[1].HideChat and not uiw.LegacyChatOpen and not fcw[1].Closing and fcw[1].autoHideFade < 1) then
		if not fcw[1].WasRendered then
			--print('restored')
			--PositionLines(1);
			for C_i = 1, allSettings.ChatLines do
				fo_Chat[1][C_i]:set_visible(true)
				fo_Aux[1][C_i]:set_visible(true)
				if allSettings.SecondChat[1] then
					fo_Chat[2][C_i]:set_visible(true)
					fo_Aux[2][C_i]:set_visible(true)
				end
			end
			SetChatOpacity(1,1)
			SetChatOpacity(1,2)
			SetChatOpacity(1,3)
			
		end
		if not fcw[3].BigMode then
			PositionLines(1);
		--FixAux(1)
			if fcw[1].RequestAuxFix then FixAux(1) end
			if allSettings.SecondChat[1] then PositionLines(2); if fcw[2].RequestAuxFix then FixAux(2) end end
			local updateColor = bit.band(allSettings.rectSettings.fill_color -(fcw[1].autoHideFade * allSettings.rectSettings.fill_color), 0xFF000000)
			if ro_RectBG[1].settings.fill_color ~= updateColor then
				--Debug(bit.tohex(updateColor),1,true)
				ro_RectBG[1]:set_fill_color(math.min(math.max(updateColor,0x00000000)),0xFF000000);
				SetChatOpacity(math.max(1-fcw[1].autoHideFade,0),1)
			end
			if allSettings.SecondChat[1] and ro_RectBG[2].settings.fill_color ~= updateColor then
				ro_RectBG[2]:set_fill_color(math.min(math.max(updateColor,0x00000000)),0xFF000000);
				SetChatOpacity(math.max(1-fcw[1].autoHideFade,0),2)
			end
		else
			if fcw[3].RequestAuxFix then FixAux(3, fcw[3].ChatLines) end
			PositionLines(3, fcw[3].ChatLines)
		end
		
		
		

		--L_i+1-allSettings.ChatLines == fcwFoId.ChatHead  and not (fcw[1].ChatHead == 1 and C_i == allSettings.ChatLines)
		-- for C_i = 1, allSettings.ChatLines do
			-- if not (C_i == fcw[1].ChatHead - 1) then
				-- fo_Chat[1][C_i]:set_opacity(1)
				-- fo_Aux[1][C_i]:set_opacity(1)
				-- if allSettings.SecondChat[1] then
					-- fo_Chat[2][C_i]:set_opacity(1)
					-- fo_Aux[2][C_i]:set_opacity(1)
				-- end
			-- end
		-- end
		
		--fo_Chat[1][fcw[1].ChatHead]:set_opacity(1)
		--fo_Aux[1][fcw[1].ChatHead]:set_opacity(1)
		
		-- for C_i = 1, allSettings.ChatLines do
			-- if C_i == fcw[1].ChatHead then
				-- fo_Chat[1][C_i]:set_opacity(1)
				-- fo_Aux[1][C_i]:set_opacity(1)
			-- end
		-- end
		
		-- for C_i = 1, allSettings.ChatLines do
			-- if not fo_Chat[1][C_i].is_dirty then fo_Chat[1][C_i]:set_visible(true) end
			-- if not fo_Aux[1][C_i].is_dirty then fo_Chat[1][C_i]:set_visible(true) end
			-- if allSettings.SecondChat[1] then
				-- if not fo_Chat[2][C_i].is_dirty then fo_Chat[1][C_i]:set_visible(true) end
				-- if not fo_Aux[2][C_i].is_dirty then fo_Chat[1][C_i]:set_visible(true) end
			-- end
		-- end
		-- if fcw[1].ResetCD ~= 0 and os.clock()-fcw[1].ResetCD > 0.2 then
			-- fcw[1].ResetCD = 0
			-- --SetLinesVisible(1, true)
			-- --SetLinesVisible(2, true)
		-- end
		
		--print('hello'..tostring(os.clock()))
		gdi:render();
		fcw[1].WasRendered = true
		--gdi:set_auto_render(true);
	else
		--gdi:set_auto_render(false);
		fcw[1].WasRendered = false
	end;
	
	
	-- fpsCount = fpsCount + 1;
    -- if (os.time() >= fpsTimer + 1) then
        -- fpsFrame = fpsCount;
        -- fpsCount = 0;
        -- fpsTimer = os.time();
    -- end
	-- if os.clock() - testWindow < 20 then
		-- testResult = testResult+ (os.clock()-timeStart)*(fpsFrame/60)
	-- end
	-- timeMax = (os.clock()-timeStart)*(fpsFrame/60) > timeMax and (os.clock()-timeStart)*(fpsFrame/60) or timeMax
	-- Debug(tostring((os.clock()-timeStart)*(fpsFrame/60))..'\n'..tostring(testResult)..'\n'..tostring(fpsFrame), 1, false)
	fcw[1].BufferBusy = false;
end);

--ashita.events.register('d3d_beginscene', 'd3d_beginscene_callback1', function (isRenderingBackBuffer)

    -- isRenderingBackBuffer is a flag that will be true when the game is currently rendering to the back buffer.
	
--end);

-- ashita.events.register('text_out', 'text_out_callback1', function (e)

    -- if (not e.injected) then
		-- table.insert(fcw[1].LastCommands[1], 1, e.message)
		-- if #fcw[1].LastCommands[1] > 20 then
			-- table.remove(fcw[1].LastCommands[1], #fcw[1].LastCommands[1])
		-- end		
    -- end

-- end);


ashita.events.register('text_in', 'text_in_cb', function (e)
	
	if par_dumping then return end
	if #e.message > 2048 then return end
	
	
	--local socialChns = {1, 4, 5, 6, 7, 10, 11, 14, 15, 213, 214, 217};
	--local e_message;
	--if not string.find(par_LastMode, 'combat') then
	--if true and utils.FindInTableSorted(socialChns, bit.band(e.mode,  0x000000FF)) then
	
	---------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------
	
	-- -- -- -- -- if false and bit.band(e.mode,  0x000000FF) < 20 or bit.band(e.mode,  0x000000FF) > 212 then
		-- -- -- -- -- local intsPre = {}; 
		-- -- -- -- -- for idx = 1, string.len(e.message) do
			-- -- -- -- -- table.insert(intsPre, string.byte(string.sub(e.message,idx,idx)));
		-- -- -- -- -- end

		-- -- -- -- -- intsPre = utils.ReplaceInts(intsPre, utils.badStringsPre);
		
			
		-- -- -- -- -- local backString = {}
		-- -- -- -- -- for idx = 1, #intsPre do
			-- -- -- -- -- table.insert(backString, string.char(intsPre[idx]))
		-- -- -- -- -- end
		-- -- -- -- -- e_message = table.concat(backString)
	-- -- -- -- -- else
		
	-- -- -- -- -- end
	
	---------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------
	-- and #e.message == par_LastMsgLength
	local e_message;
	
	local mode_pre = bit.band(e.mode,  0x000000FF);--(mode_pre == 190 and e.message:find('__')) or
	if mode_pre == 152 or e.blocked then e.blocked = true; return; end
	if mode_pre == 190 then if allSettings.blockAll[1] and not(fcw[1].HideChat or uiw.LegacyChatOpen) then e.blocked = true; end return end
	if (mode_pre == 191 and string.find(e.message, 'version')) then AshitaCore:GetChatManager():AddChatMessage(0, false, e.message) return end
	table.insert(b_OriginalBuffer,  tostring(bit.band(e.mode,  0x000000FF))..'|'..os.date('[%H:%M:%S]', os.time())..' '..e.message)
	if #b_OriginalBuffer >= 300 then
		local newBuffer = {}
		for i = 51, #b_OriginalBuffer do
			newBuffer[#newBuffer+1] = b_OriginalBuffer[i]
		end
		b_OriginalBuffer = newBuffer
	end
	
	if (mode_pre < 20 or mode_pre > 212) then
		e_message= AshitaCore:GetChatManager():ParseAutoTranslate(e.message, true);
	else
		e_message = e.message;
	end
	
	
	
	local e_messages = {}
	local nextEi = 1;
	for E_i = 1, #e_message do --and E_i>1 and string.byte(string.sub(e_message,E_i-1,E_i-1)) ~= 2 
		if string.byte(string.sub(e_message,E_i,E_i)) == 10 and E_i < #e_message then
			table.insert(e_messages, string.sub(e_message,nextEi,E_i))
			nextEi = E_i+1;
		end
	end
	
	
	table.insert(e_messages, string.sub(e_message,nextEi,#e_message))
	
	for E_i = 1, #e_messages do
		--Debug(tostring(e_messages[E_i]),1,true);
		fcw[1].ProcessingText = true;
		parseThis(e, e_messages[E_i]);
		fcw[1].ProcessingText = false;
	end
	
	
	-- par_CombatCutIdx = 0;
	-- par_DamageDone = false;
	-- par_DamageGot = false;
	-- local original_msg = '';
	-- par_LastMode = 'unknown';
	
	-- local e_message = AshitaCore:GetChatManager():ParseAutoTranslate(e.message, true)
				
		-- e_message = e_message:gsub('[^\x1E\x1F][\x07]', function (s)
		-- local spacing = ' ';
		-- return s:sub(1, 1):append(spacing);
	-- end);

	-- local col = bit.tobit(utils.RGBAToHex(allSettings.defaultColor));
	
	-- par_MessageMode = bit.band(e.mode,  0x000000FF);
	
	-- for i = 1, utils.GetTableLen(utils.modes) do
		-- if utils.modes[i][1] == par_MessageMode then
			-- par_LastMode = utils.modes[i][2];
			-- col = utils.modes[i][3];
			
			-- col = (function()
				-- if (utils.modes[i][2]=='combat') then return bit.tobit(utils.RGBAToHex(allSettings.combatColor));
				-- end
				-- if (utils.modes[i][2]=='combatspell') then return bit.tobit(utils.RGBAToHex(allSettings.combatspellColor));end
				-- if (utils.modes[i][2]=='linkshell1') then return bit.tobit(utils.RGBAToHex(allSettings.linkshellColor)); end
				-- if (utils.modes[i][2]=='linkshell2') then return bit.tobit(utils.RGBAToHex(allSettings.linkshell2Color)); end
				-- if (string.find(utils.modes[i][2],'party')) then return bit.tobit(utils.RGBAToHex(allSettings.partyColor)); end
				-- if (string.find(utils.modes[i][2],'tell')) then return bit.tobit(utils.RGBAToHex(allSettings.tellColor)); end
				-- if (string.find(utils.modes[i][2],'shout')) then return bit.tobit(utils.RGBAToHex(allSettings.shoutColor)); end
				-- if (string.find(utils.modes[i][2],'emote')) then return bit.tobit(utils.RGBAToHex(allSettings.emoteColor)); end
				-- return col;
			-- end)();
		-- end
	-- end
	
	
	-- if par_LastMode == 'tell_in' and allSettings.tellNotification[1] then ashita.misc.play_sound(string.format('%s\\notifications\\%s%s.wav', addon.path, allSettings.selectedNotification,allSettings.boostNotification[1] and 'B' or '')); end;
end);

--settings.register('allSettings', 'allSettings_update', function(s)
--    if s ~= nil then allSettings = s end
--    settings.save('allSettings');
--end)

function SaveSettings()
    settings.save('allSettings');
end

ashita.events.register('load', 'load_cb', function ()


	--dw_testPTR = ashita.memory.find('FFxiMain.dll', 0, 'B9????????50E8????????8BF085F674??8B46',0,0);
	--A1????????3BC374??660FBE56
	dw_testPTR = ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0)
	dw_testPTR = ashita.memory.read_uint32(dw_testPTR)
	
	uiw.UpperMenuPTR = ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0)
	uiw.UpperMenuPTR = ashita.memory.read_uint32(uiw.UpperMenuPTR)
	--print(bit.tohex(dw_testPTR))
	
	--print(bit.tohex(dw_testPTR+0x54));
	
	local patternAddr = ashita.memory.find('FFxiMain.dll', 0, '8935????????81C6????????56E8',0,0);
	local pGlobalNowZoneAddr = ashita.memory.read_uint32(patternAddr+0x02)
	local Offset = ashita.memory.read_uint32(patternAddr+0x08)
	local pGlobalNowZone = ashita.memory.read_uint32(pGlobalNowZoneAddr)
	uiw.NetStatObj[1] = pGlobalNowZone+Offset
	

	--uiw.InputWinOpenPtr = ashita.memory.find('FFXiMain.dll', 0, 'B9????????E9????????909090909090A1????????8B15', 0, 0);
	--local uiw.RefInputWinOpenPtr = ashita.memory.read_uint32(uiw.InputWinOpenPtr+0x01);
	
	--uiw.InputWinOpenPtr = ashita.memory.find('FFXiMain.dll', 0, '8BCFE8????????EB??A1', 0, 0);
	--e8 ? ? ? ? c6 86 ? ? ? ? ? 5e c3 8b 0d
	--8b 0d ? ? ? ? c6 81 ? ? ? ? ? c3
	--c2 ? ? 90 90 90 90 90 90 90 90 90 90 90 90 90 90 c7 41 ? ? ? ? ? c2
	--05 ? ? ? ? 70 ? 2b 05 ? ? ? ? 8a 33
	--75 ? 5f 5e 5d 33 c0 5b 81 c4 ? ? ? ? c2 ? ? 80 bd
	--8b 0d ? ? ? ? e8 ? ? ? ? c6 86 ? ? ? ? ? 5e c3 90 90 90 90 90 90 90 90 90 90 90 90 53
	--b9 ? ? ? ? e8 ? ? ? ? c6 86 ? ? ? ? ? 5f
	--a1 ? ? ? ? 0f bf 48
	--8b15 ? ? ? ? 53 53 2b c8 6a ? 51 66 8b 4a
	--8b 0d ? ? ? ? c6 81 ? ? ? ? ? c3
	-----uiw.InputWinOpenPtr = ashita.memory.find('FFXiMain.dll', 0, '8B0D????????C681??????????C3', 0, 0);
	--uiw.InputWinOpenPtr = ashita.memory.read_uint32(uiw.InputWinOpenPtr-0x0D);
	--uiw.InputWinOpenPtr = ashita.memory.read_uint32(uiw.InputWinOpenPtr);
	--print(tostring(bit.tohex(uiw.InputWinOpenPtr)));
	--local testmem = ashita.memory.read_uint32(uiw.NewInputPtr-0x0D);
	--local testvalue = ashita.memory.read_uint32(testmem);
	--local testvalue2 = ashita.memory.read_uint32(testvalue+0x74);
	--uiw.InitInputWinOpen = ashita.memory.read_uint32(uiw.RefInputWinOpenPtr+0x18);
	--uiw.MaxInputWinOpen = ashita.memory.read_uint32(uiw.RefInputWinOpenPtr+0x18);
	--uiw.MinInputWinOpen = uiw.MaxInputWinOpen - 1;	
	--a1 ? ? ? ? 3b f0 7e ? 8b f0 
	
	uiw.UISizeYPtr = ashita.memory.find('FFXiMain.dll', 0, 'A1????????3BF07E??8BF0', 0, 0)	
	uiw.UISizeYPtr = ashita.memory.read_uint32(uiw.UISizeYPtr+0x01);
	uiw.UISizeY = ashita.memory.read_uint32(uiw.UISizeYPtr);
	--uiw.MaxWinSizeY = uiw.UISizeY-0x16;

	
	uiw.UISizeXPtr = ashita.memory.find('FFXiMain.dll', 0, 'BF????????F3??0FBF4C24', 0, 0)	
	uiw.UISizeXPtr = ashita.memory.read_uint32(uiw.UISizeXPtr+0x01);
	uiw.UISizeX = ashita.memory.read_uint32(uiw.UISizeXPtr-0x10);
	--uiw.WinSizeX = ashita.memory.read_uint32(uiw.WinSizeYPtr);
	uiw.WinOpenPtr = ashita.memory.find('FFXiMain.dll', 0, 'E8????????84C075??A1????????85C074??668378', 0, 0);
	
	
	uiw.WinOpenPtr2 = ashita.memory.find('FFXiMain.dll', 0, 'BF????????F3??0FBF4C24', 0, 0);
	uiw.RefWinOpenPtr2 = ashita.memory.read_uint32(uiw.WinOpenPtr2+0x01);
	--print(bit.tohex(uiw.RefWinOpenPtr2));
	
	uiw.RefWinOpenPtr = ashita.memory.read_uint32(uiw.WinOpenPtr+0x23);
	--print(bit.tohex(uiw.RefWinOpenPtr));
	--local newptr = ashita.memory.read_uint32(uiw.RefWinOpenPtr)+0x84C;
	--print(bit.tohex(ashita.memory.read_uint32(uiw.WinOpenPtr)))
	--a0 ? ? ? ? 53 56 57 84 c0 8b f1 --25425C30
	uiw.DialogPtr = ashita.memory.find('FFXiMain.dll', 0, 'A0????????53565784C08BF1', 0, 0);
	uiw.DialogPtr = ashita.memory.read_uint32(uiw.DialogPtr+0x01);
	
	--uiw.DialogPtr2 = ashita.memory.find('FFXiMain.dll', 0, 'b8????????8d8d????????8b1083c0??891183c1??3d????????7c??b8????????8d8d????????8b1083c0??891183c1??3d????????7c??b8????????8d95', 0, 0);
	--uiw.DialogPtr2 =  ashita.memory.read_uint32(uiw.RefWinOpenPtr)+0x84C;
	--uiw.DialogPtr2 = ashita.memory.read_uint32(uiw.DialogPtr2);
	--print(tostring(bit.tohex(uiw.DialogPtr2)))
	
	--print(bit.tohex(ashita.memory.read_uint32(uiw.DialogPtr)))
	----print(bit.tohex(ashita.memory.read_uint32(uiw.RefWinOpenPtr+0x54)))
	--local uiw.DialogPtr;
	
	uiw.MenuDescPTR = ashita.memory.find('FFxiMain.dll', 0, 'B9????????50E8????????8BF085F674??8B46',1,0);
	
	--uiw.MenuDescPTR = ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0)
	--print(bit.tohex(tostring(uiw.MenuDescPTR)))
	--uiw.MenuDescPTR = ashita.memory.read_uint32(uiw.MenuDescPTR+0x01);
	
	uiw.UIVisiblePtr = ashita.memory.find('FFXiMain.dll', 0, '8B4424046A016A0050B9????????E8????????F6D81BC040C3', 0, 0)
	uiw.MenuPtr = ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0)
	
	
	uiw.MenuPtr = ashita.memory.read_uint32(uiw.MenuPtr);
	
	
	
	
	
	uiw.EventPtr = ashita.memory.find('FFXiMain.dll', 0, 'A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3', 0, 0)
	
	--8b 71 ? 4e 89 44 24
	-- uiw.MenuExtPtr = ashita.memory.find('FFXiMain.dll', 0, '8B71??4E894424', 0, 0)
	-- print(bit.tohex(uiw.MenuExtPtr));
	-- uiw.MenuExtPtr = ashita.memory.read_uint32(uiw.MenuExtPtr+0x3);
	-- print(bit.tohex(uiw.MenuExtPtr));
	
	--local uiw.DialogPtr;
	--uiw.DialogPtr = ashita.memory.find('FFXiMain.dll', 0, 'A0????????84C074??A0????????84C075??A0', 0, 0)
	--uiw.DialogPtr = ashita.memory.read_uint32(uiw.DialogPtr+0x01);
--	uiw.DialogPtr = ashita.memory.read_uint32(uiw.DialogPtr);

	--local test_Ptr = ashita.memory.find('FFXiMain.dll', 0, 'A0????????84C075??A0????????84C074??8B4F', 0, 0)
	--test_Ptr = ashita.memory.read_uint32(test_Ptr+0x01);
	--test_Ptr = ashita.memory.read_uint32(test_Ptr+0x00);
	--print(bit.tohex(test_Ptr));

	--ResetColors();
	--allSettings.colors = defaultColors;
	
	local allSettingsOG = allSettings
	allSettings.colors = utils.cloneTable(defaultColors)
	
	--local dsize = imgui.GetIO().DisplaySize
	--fcw[1].Anchor_X = dsize.x/2;
	--fcw[1].Anchor_X = dsize.y/2;
	
	allSettings = settings.load(allSettings, 'allSettings');
	
	
	
	for k,v in pairs(defaultColors) do
		if not allSettings.colors[k] then
			allSettings.colors.k = utils.cloneTable(v)
			SaveSettings()
		end
	end
	
	if not allSettings.ver or allSettings.ver ~= ver then
		allSettings = utils.RepairSettings(allSettingsOG, allSettings)
		allSettings.ver = ver
		SaveSettings()
		print('Version change detected('..ver..'): Settings table restored')
	end
	
	ResetAutoHideTimer()
	set_alertList = utils.stringsplit(allSettings.alertwords, ',')
	set_alertBuffer[1] = allSettings.alertwords;
	par_customFilters = utils.LoadCustomFilters();
	
	fcw[1].PlayerName = allSettings.PlayerName;
	--print(fcw[1].PlayerName)
	
	--coroutine.sleep(0.2);
	--print(tostring(settings.logged_in))
	--print(tostring(settings.name))
	set_SecondChat[1] = allSettings.SecondChat[1];
	set_ChatLineMaxL = allSettings.chatLineMaxL;
	set_PlateBGColor = allSettings.rectSettings.fill_color;
	set_FontHeight = allSettings.fontSettings.font_height;
	set_ChatLines = allSettings.ChatLines;
	for ct = 1, #allSettings.CustomTabModes do
		set_CustomTabModes[ct] = allSettings.CustomTabModes[ct];
	end
	
	fcw[1].ChatShift = allSettings.fontSettings.font_height;
	fcw[1].ChatShiftScale = fcw[1].ChatShiftScale_Min;
	fcw[2].ChatShiftScale_Base = allSettings.fontSettings.font_height*2;
	fcw[2].ChatShiftScale_Min = allSettings.fontSettings.font_height*2;
	fcw[2].ChatShift = allSettings.fontSettings.font_height;
	fcw[2].ChatShiftScale = fcw[2].ChatShiftScale_Min;

	fcw[1].TextureIDBorder =  tonumber(ffi.cast("uint32_t", fcw[1].Textures.border));
	fcw[1].TextureIDSettings  = tonumber(ffi.cast("uint32_t", fcw[1].Textures.settings));
	fcw[1].TextureIDGuideMe = tonumber(ffi.cast("uint32_t", fcw[1].Textures.guideme));
	fcw[1].TextureIDLogs = tonumber(ffi.cast("uint32_t", fcw[1].Textures.logs));
	fcw[1].TextureIDLoading = tonumber(ffi.cast("uint32_t", fcw[1].Textures.loading));
	fcw[1].TextureIDFolder = tonumber(ffi.cast("uint32_t", fcw[1].Textures.folder));
	fcw[1].TextureIDCompact = tonumber(ffi.cast("uint32_t", fcw[1].Textures.compact));
	fcw[1].TextureIDManual = tonumber(ffi.cast("uint32_t", fcw[1].Textures.manual));
	fcw[1].TextureIDInfo = tonumber(ffi.cast("uint32_t", fcw[1].Textures.info));
	fcw[1].TextureIDNotepad = tonumber(ffi.cast("uint32_t", fcw[1].Textures.notepad));
	fcw[1].TextureIDDumpchat = tonumber(ffi.cast("uint32_t", fcw[1].Textures.dumpchat));

	--uiw.WinOpenPtr = ashita.memory.find('FFXiMain.dll', 0, 'E8????????84C075??A1????????85C074??668378', 0, 0);
	
	local drawMessageWindowPtr = ashita.memory.find('FFXiMain.dll', 0, 'A1????????C64059018B0D????????C6415901C20800', 0, 0);
	if (drawMessageWindowPtr == 0) then
		error(chat.header(addon.name):append(chat.error('Error: Failed to locate a required pointer.')));
	end
	
	
	uiw.WinPtr1 = ashita.memory.read_uint32(drawMessageWindowPtr + 0x01); -- g_pDrawMessageWindow
	uiw.WinPtr2 = ashita.memory.read_uint32(drawMessageWindowPtr + 0x0B); -- g_pDrawMessageWindow2
	
	
	--print(bit.tohex(WinPtr3+0x2F));
	
	local dsize = imgui.GetIO().DisplaySize;
	
	gdi:set_auto_render(false);
	
	ro_Scroll[1] = gdi:create_rect(allSettings.rectSettings, false);
	ro_Scroll[1]:set_width(10);
	ro_Scroll[1]:set_height(10);
	ro_Scroll[1]:set_fill_color(0x88FFFFFF);
	ro_Scroll[1]:set_z_order(1);
	ro_Scroll[1]:set_visible(false);
	ro_RectBG[1] = gdi:create_rect(allSettings.rectSettings, false);
	fo_Fwd[1] = gdi:create_object(allSettings.fontSettings, false);
	fo_Fwd[1]:set_text(utf8.char(0x25bc));
	fo_Bkw[1] = gdi:create_object(allSettings.fontSettings, false);
	fo_Bkw[1]:set_font_height(allSettings.fontSettings.font_height-2);
	fo_Bkw[1]:set_font_color(0xFAD1F4FF);
	fo_Bkw[1]:get_background():set_fill_color(0x22000000);
	fo_Bkw[1]:get_background():set_fill_color(0x22000000);
	fo_Bkw[1]:set_bg_overlap(0);
	fo_Bkw[1]:set_text(utf8.char(0x2004)..utf8.char(0x25b2)..' Scrolling chat history...');
	
	local customSettings = allSettings.fontSettings;
	customSettings.bg_overlap = 0;
	--customSettings.z_order = 1;
	
	for L_i = 1, allSettings.ChatLines do
		
		table.insert(fo_Chat[1], gdi:create_object(allSettings.fontSettings, false));
		table.insert(fo_Aux[1], gdi:create_object(allSettings.fontSettings, false));
		
		--fo_Aux[1][L_i]:set_font_alignment(gdi.Alignment.Right);
		--fo_Aux[1][L_i]:set_box_width(dsize.x);
		--fo_Aux[1][utils.GetTableLen(fo_Aux[1])]:set_visible(true);
		fo_Chat[1][L_i]:set_font_height(allSettings.fontSettings.font_height);
		fo_Aux[1][L_i]:set_font_height(allSettings.fontSettings.font_height);
		fo_Chat[1][L_i]:set_position_x(fcw[1].Anchor_X);
		fo_Chat[1][L_i]:set_position_y( fcw[1].Anchor_Y - (allSettings.fontSettings.font_height * (L_i-1)));
		if (fo_Chat[1][L_i].rect ~= nil) then 
			fo_Aux[1][L_i]:set_position_x(fcw[1].Anchor_X+fo_Chat[1][L_i].rect.right); 
		else
			fo_Aux[1][L_i]:set_position_x(fcw[1].Anchor_X);
			fo_Aux[1][L_i]:set_visible(false)
		end
		fo_Aux[1][L_i]:set_position_y( fcw[1].Anchor_Y - (allSettings.fontSettings.font_height * (L_i-1))); 
		
	end
	--SC--
	
	if allSettings.SecondChat[1] then
		ro_Scroll[2] = gdi:create_rect(allSettings.rectSettings, false);
		ro_Scroll[2]:set_width(10);
		ro_Scroll[2]:set_height(10);
		ro_Scroll[2]:set_fill_color(0x88FFFFFF);
		ro_Scroll[2]:set_z_order(1);
		ro_Scroll[2]:set_visible(false);
		ro_RectBG[2] = gdi:create_rect(allSettings.rectSettings, false);
		fo_Fwd[2] = gdi:create_object(allSettings.fontSettings, false);
		fo_Fwd[2]:set_text(utf8.char(0x25bc));
		fo_Bkw[2] = gdi:create_object(allSettings.fontSettings, false);
		fo_Bkw[2]:set_font_height(allSettings.fontSettings.font_height-2);
		fo_Bkw[2]:set_font_color(0xFAD1F4FF);
		fo_Bkw[2]:get_background():set_fill_color(0x22000000);
		fo_Bkw[2]:set_bg_overlap(0);
		fo_Bkw[2]:set_text(utf8.char(0x2004)..utf8.char(0x25b2)..' Scrolling chat history...');
		for L_i = 1, allSettings.ChatLines do
			table.insert(fo_Chat[2], gdi:create_object(allSettings.fontSettings, false));
			table.insert(fo_Aux[2], gdi:create_object(customSettings, false));
			--fo_Aux[2][utils.GetTableLen(fo_Aux[2])]:set_visible(true);
			fo_Chat[2][L_i]:set_font_height(allSettings.fontSettings.font_height);
			fo_Aux[2][L_i]:set_font_height(allSettings.fontSettings.font_height);
			fo_Chat[2][L_i]:set_position_x(fcw[2].Anchor_X);
			fo_Chat[2][L_i]:set_position_y( fcw[2].Anchor_Y - (allSettings.fontSettings.font_height * (L_i-1)));
			if (fo_Chat[2][L_i].rect ~= nil) then 
				fo_Aux[2][L_i]:set_position_x(fcw[2].Anchor_X+fo_Chat[2][L_i].rect.right); 
			else
				fo_Aux[2][L_i]:set_position_x(fcw[2].Anchor_X);
				fo_Aux[1][L_i]:set_visible(false)
			end
			fo_Aux[2][L_i]:set_position_y( fcw[2].Anchor_Y - (allSettings.fontSettings.font_height * (L_i-1))); 
		end
	end

	for W_i = 1, 2 do 

		--table.insert(b_ChatBuffer[W_i][2].text, '-- We\\!FF0000FF?\\lcom\\!--------?\\e to ');
		--[12:56] Strolling Sapling > [Volker] > 10 DMG 
		--table.insert(b_ChatBuffer[W_i][2].text, '\\!FFFFFFFF?\\Test\\!--------?\\ \\!FFDBF5C9?\\Hello\\!--------?\\ \\!FFDBF510?\\Hello\\!--------?\\ \\!FFDB30C9?\\Hello\\!--------?\\');
		--table.insert(b_ChatBuffer[W_i][2].text, e9d2 eb09 e95e e70b utf8.char(0x22EF)..utf8.char(0x25AE)..utf8.char(0x3010)..utf8.char(0x3011));'..utf8.char(0x2727)..'
		--table.insert(b_ChatBuffer[W_i][2].text, '--WelcomH Ho \\§FF44CCFFç\\HancH Hhat--\\§--------ç\\');
		table.insert(b_ChatBuffer[W_i][2].text, '--Welcome to \\§FF44CCFFç\\Fancy Chat--\\§--------ç\\');
		--table.insert(b_ChatBuffer[W_i][2].text,  utf8.char(0xE2EF)..' '..utf8.char(0xe41d)..' '..utf8.char(0xe4ba)..' '..utf8.char(0xe4d0)..' '..utf8.char(0xe0a2)..' '..utf8.char(0xe5b8)..' '..utf8.char(0xe755)..' '..utf8.char(0xe816)..' '..utf8.char(0xeb3a)..' '..utf8.char(0xe471));
		--table.insert(b_ChatBuffer[W_i][2].mode, '0|welcome');
		table.insert(b_ChatBuffer[W_i][2].color, 0xFFFFFFFF);
		--table.insert(b_ChatBuffer[W_i][2].auxText,  'FancyChat --');
		table.insert(b_ChatBuffer[W_i][2].auxText,  '');
		table.insert(b_ChatBuffer[W_i][2].auxColor, 0xFF44CCFF);
		table.insert(b_ChatBuffer[W_i][2].url, 0);
	end
	
	b_ChatBufferN_All = 1;
	b_ChatBufferN_AllAlt = 1;
		
	if allSettings.SelectedTab ~= 'All' then tab_NextTab = allSettings.SelectedTab end
	if allSettings.SelectedTab2 ~= 'All' then tab_NextTab2 = allSettings.SelectedTab2 end
	if allSettings.HideCombatFromAll[1] then
		tab_Tabs[1] = 'AllAlt'
		if allSettings.SelectedTab == 'All' then
			tab_NextTab = 'AllAlt'
		end
		if allSettings.SecondChat[1] then
			if allSettings.SelectedTab2 == 'All' then
				tab_NextTab2 = 'AllAlt'
			end
		end
	else
		tab_Tabs[1] = 'All'
		if allSettings.SelectedTab == 'AllAlt' then
			tab_NextTab = 'All'
		end
		if allSettings.SecondChat[1] then
			if allSettings.SelectedTab2 == 'AllAlt' then
				tab_NextTab2 = 'All'
			end
		end
	end

	
	--fcw[1].MoveChatPos1 = ((dsize.x/6.5)*dsize.x/uiw.UISizeX)-1;
	fcw[1].MoveChatPos1 = (dsize.x*400)/uiw.UISizeX;
	--fcw[1].MoveChatPos2 = ((dsize.x/12)*dsize.x/uiw.UISizeX)-1;
	fcw[1].MoveChatPos2 = (dsize.x*220)/uiw.UISizeX;
	--fcw[1].MoveChatPos3 = ((dsize.x/10)*dsize.x/uiw.UISizeX)-1;
	fcw[1].MoveChatPos3 = (dsize.x*260)/uiw.UISizeX;
	fcw[1].MoveChatPos4 = (dsize.x*305)/uiw.UISizeX;

	fcw[1].PositionLinesRequest = {true,true};
	PositionLines(1);
	if allSettings.SecondChat[1] then fcw[2].PositionLinesRequest = {true,true}; PositionLines(2); end
	--gdi:render();
	--testWindow = os.clock()
end);

-- local function DestroyAllGDIObjects()
    -- for _, fo in ipairs(fo_Fwd) do
        -- if fo and fo.destroy then
            -- fo:destroy()
        -- end
    -- end
    -- for _, fo in ipairs(fo_Bkw) do
        -- if fo and fo.destroy then
            -- fo:destroy()
        -- end
    -- end
    -- for _, winFonts in ipairs(fo_Chat) do
        -- for _, fo in ipairs(winFonts) do
            -- if fo and fo.destroy then
                -- fo:destroy()
            -- end
        -- end
    -- end
    -- for _, winFonts in ipairs(fo_Aux) do
        -- for _, fo in ipairs(winFonts) do
            -- if fo and fo.destroy then
                -- fo:destroy()
            -- end
        -- end
    -- end
    -- for _, ro in ipairs(ro_RectBG) do
        -- if ro and ro.destroy then
            -- ro:destroy()
        -- end
    -- end
    -- for _, ro in ipairs(ro_Scroll) do
        -- if ro and ro.destroy then
            -- ro:destroy()
        -- end
    -- end
-- end

ashita.events.register('unload', 'unload_cb', function ()
	if allSettings.autoDumpChat[1] then
		DumpChat()
	end
	fcw[1].Closing = true;
	gdi:destroy_interface();
	SaveSettings();
end);

ashita.events.register('packet_in', 'zonename_packet_in', function(e)
	if e.id == 0x052 then
		if (fo_Fwd[1] ~= nil) then fo_Fwd[1]:set_visible(false); end
		if (fo_Fwd[2] ~= nil) then fo_Fwd[2]:set_visible(false); end
		par_IsInConv = false;
		par_InEvent = ashita.memory.read_uint8(ashita.memory.read_uint32(uiw.EventPtr + 1)) == 1
		--uiw.DialogPromptStart = os.clock();
		--Debug('noconv', 1, true);
		--uiw.DialogShown = false;
		uiw.DialogCDStart = os.clock();
		--uiw.DialogPromptStart = 0;
	end
	if e.id == 0x000B then
		fcw[1].Zoning = true
		--Debug('loggedout', 1, true)
		uiw.MenuList = {};
		--fcw[1].LoggedIn = false;
		--Debug(settings.name, 1, true)
	end
	
	if (e.id == 0x000A) then
		fcw[1].Zoning = false
		--Debug('loggedin', 1, true)
		--fcw[1].LoggedIn = true;
		uiw.DialogShown = false;
		--fcw[1].LobbyCD = os.clock()
		--Debug(settings.name, 1, true)
	end
	

	--[[
	if (e.id == 0x000A) then
        if (not settings.logged_in or settings.server_id == 0 or settings.name:empty()) then
            local serverId = struct.unpack('L', e.data, 0x04 + 0x01);
            local name = struct.unpack('c16', e.data, 0x84 + 0x01);

            -- Update the settings for the login event..
            process_character_switch(serverId, name:trim('\0'));
			settingslib.logged_in   = serverId ~= 0;
			settingslib.server_id   = serverId;
			settingslib.name        = name;
        end
        return;
    end

    -- Packet: Zone Exit
    if (e.id == 0x000B) then
        if (struct.unpack('b', e.data, 0x04 + 0x01) == 1 and settings.logged_in) then
            -- Update the settings for the logout event..
            process_character_switch(0, '');
        end
        return;
    end]]--
end);
ashita.events.register('packet_out', 'packet_out_callback1', function (e)
    -- Look for emote packets..
    if (e.id == 0x0026) then
        uiw.MenuList = {}
		--fcw[1].LoggedLobby = 1
    end
end);

ashita.events.register('command', 'command_cb', function (e)

    local args = e.command:args();
    if (#args == 0 or (not args[1]:any('/fancychat') and not args[1]:any('/fchat')) ) then
        return;
    end
	
	e.blocked = true;
	
	if (#args == 2 and args[2] == 'debug') then
		dw_WindowOpened[1] = not dw_WindowOpened[1];			
		return;
	end
	if (#args == 2 and args[2] == 'bigmode') then
		fcw[3].BigMode = not fcw[3].BigMode;			
		return;
	end
	if (#args == 2 and args[2] == 'savelogs') then
		local ts = os.date('[%Y_%m_%d-%H_%M_%S]', os.time());
		utils.SaveLogs(b_ChatBuffer[1][2].text, b_ChatBuffer[1][2].auxText, 'All', fcw[1].PlayerName, addon.path, ts)
		coroutine.sleep(0.5);		
		utils.SaveLogs(b_ChatBuffer[3][2].text, b_ChatBuffer[3][2].auxText, 'Combat', fcw[1].PlayerName, addon.path, ts)
		coroutine.sleep(0.5);	
		utils.SaveLogs(b_ChatBuffer[4][2].text, b_ChatBuffer[4][2].auxText, 'Linkshell', fcw[1].PlayerName, addon.path, ts)
		coroutine.sleep(0.5);	
		utils.SaveLogs(b_ChatBuffer[5][2].text, b_ChatBuffer[5][2].auxText, 'Party', fcw[1].PlayerName, addon.path, ts)
		coroutine.sleep(0.5);	
		utils.SaveLogs(b_ChatBuffer[6][2].text, b_ChatBuffer[6][2].auxText, 'Tell', fcw[1].PlayerName, addon.path, ts)
		coroutine.sleep(0.5);	
		utils.SaveLogs(b_ChatBuffer[7][2].text, b_ChatBuffer[7][2].auxText, 'Shout', fcw[1].PlayerName, addon.path, ts)
		coroutine.sleep(0.5);	
		utils.SaveLogs(b_ChatBuffer[8][2].text, b_ChatBuffer[8][2].auxText, 'Custom', fcw[1].PlayerName, addon.path, ts)
		coroutine.sleep(0.5);			
		
		return;
	end
	-- if (#args == 2 and args[2] == 'dumpchat') then
		-- DumpChat(2)
		-- return
	-- end
	if (#args == 2 and args[2] == 'savedebug') then
		
		local ts = os.date('[%Y_%m_%d-%H_%M_%S]', os.time());
		if utils.SaveLogs(b_LogBuffer, nil, 'DEBUG', fcw[1].PlayerName, addon.path, ts) then
			b_LogBuffer = {};
		end
		return;
	end

	if (#args > 3 and args[2] == 'test' and tonumber(args[3]) >= 0 and tonumber(args[3]) <= 255) then
		local test_string = ''
		local test_i = 4
		while args[test_i] ~= nil do
			test_string = test_string..args[test_i]..' '
			test_i = test_i + 1
		end
		AshitaCore:GetChatManager():AddChatMessage(tonumber(args[3]), false, test_string:trimex()..'\127\49')
		return;
	end
	if (#args == 2 and args[2] == 'printdebug') then
		
		
		--print('\31\121\72\97\104\101\32\115\121\110\116\104\101\115\105\122\101\100\32\54\32\30\2\102\114\105\101\100\32\112\111\112\111\116\111\101\115\30\1\46')
		--print('\131\159\131\160\131\161\131\162\131\163\131\164\131\165\131\166\131\167\131\168\131\169\131\170\131\171\131\172\131\173\131\174\131\175\131\176\131\177\131\178\131\179\131\180\131\181\131\182\131\183\131\184\131\185\131\186\131\187\131\188\131\189\131\190\131\191\131\192\131\193\131\194\131\195\131\196\131\197\131\198\131\199\131\200\131\201\131\202\131\203\131\204\131\205\131\206\131\207\131\208\131\209\131\210\131\211\131\212\131\213\131\214\131\215\131\216\131\217\131\218\131\219')
		--print('\133\159\133\160\133\161\133\162\133\163\133\164\133\165\133\166\133\167\133\168\133\169\133\170\133\171\133\172\133\173\133\174\133\175\133\176\133\177\133\178\133\179\133\180\133\181\133\182\133\183\133\184\133\185\133\186\133\187\133\188\133\189\133\190\133\191')
		--[[
		-----------
		--
		--cyrillic
		\133\1\133\2\133\3\133\4\133\5\133\6\133\7\133\8\133\9\133\10\133\11\133\12\133\13\133\14\133\15\133\16\133\17\133\18\133\19\133\20\133\21\133\22\133\23\133\24\133\25\133\26\133\27\133\28\133\29\133\30\133\31\133\32\133\33\133\34\133\35\133\36\133\37\133\38\133\39\133\40\133\41\133\42\133\43\133\44\133\45\133\46\133\47\133\48\133\49\133\50\133\51\133\52\133\53\133\54\133\55\133\56\133\57\133\58\133\59\133\60\133\61\133\62\133\63\133\64
		
		\133\65\133\66\133\67\133\68\133\69\133\70\133\71\133\72\133\73\133\74\133\75\133\76\133\77\133\78\133\79\133\80\133\81\133\82\133\83\133\84\133\85\133\86\133\87\133\88\133\89\133\90\133\91\133\92\133\93\133\94\133\95\133\96\133\97\133\98\133\99\133\100\133\101\133\102\133\103\133\104\133\105\133\106\133\107\133\108\133\109\133\110\133\111\133\112\133\113\133\114\133\115\133\116\133\117\133\118\133\119\133\120\133\121\133\122\133\123\133\124\133\125\133\126\133\127\133\128
		
		\133\129\133\130\133\131\133\132\133\133\133\134\133\135\133\136\133\137\133\138\133\139\133\140\133\141\133\142\133\143\133\144\133\145\133\146\133\147\133\148\133\149\133\150\133\151\133\152\133\153\133\154\133\155\133\156\133\157\133\158\133\159\133\160\133\161\133\162\133\163\133\164\133\165\133\166\133\167\133\168\133\169\133\170\133\171\133\172\133\173\133\174\133\175\133\176\133\177\133\178\133\179\133\180\133\181\133\182\133\183\133\184\133\185\133\186\133\187\133\188\133\189\133\190\133\191\133\192
		
		\133\193\133\194\133\195\133\196\133\197\133\198\133\199\133\200\133\201\133\202\133\203\133\204\133\205\133\206\133\207\133\208\133\209\133\210\133\211\133\212\133\213\133\214\133\215\133\216\133\217\133\218\133\219\133\220\133\221\133\222\133\223\133\224\133\225\133\226\133\227\133\228\133\229\133\230\133\231\133\232\133\233\133\234\133\235\133\236\133\237\133\238\133\239\133\240\133\241\133\242\133\243\133\244\133\245\133\246\133\247\133\248\133\249\133\250\133\251\133\252\133\253\133\254\133\255
		]]--
		--бвгдеёжзийклмнопрстуфхцчшщъыьэюя
		--print('this\nis\na\nmultiline\nstring\n');
	
		--print('\97\33\127\52\1\127\49');
		--print('hello'..'\253\2\2\2\10\253'..'hello');
		--print('\127\252\66\105\100\97\110\127\251\91\76\111\119\74\101\117\110\111\93\58\32\253\2\2\24\14\253\32\56\54\43\32\253\2\2\24\1\253\32\53\49\43\32\253\2\2\18\1\253\32\253\2\2\31\49\253\10');
		
		--print('Attacks are enhanced but defense weakens. Zeid \129\244 [Last Resort] ')
		
		--AshitaCore:GetChatManager():AddChatMessage(20, false, 'Eleanor\'s ranged attack hits the Volcanic Bomb for 85 points of damage.')
		
		--print(string.find('You find a bronze knife in the Drahbah.',' in '))
		
		-- print('\73\110\32\116\104\101\32\71\117\115\116\97\98\101\114\103\32\77\111\117\110\116\97\105\110\115\32\111\102\32\83\111\117\116\104\101\114\110\32\81\117\111\110\32\108\105\101\115\32\116\104\101\32\105\110\100\117\115\116\114\105\97\108\32\110\97\116\105\111\110\32\107\110\111\119\110\32\97\115\32\116\104\101\32\82\101\112\117\98\108\105\99\32\111\102\32\66\97\115\116\111\107\46\127\52\6')
		--print('\129\153\129\154')
		--AshitaCore:GetChatManager():AddChatMessage(1, false, '\129\168 A new Summit of the Stars perk is now active: Gilfinder\129\169\129\170\129\171')
		-- AshitaCore:GetChatManager():AddChatMessage(36, false, ('\30%c%s\30\01'):fmt(69, 'Eleanor defeats King Behemoth.'))
		-- AshitaCore:GetChatManager():AddChatMessage(121, false, ('\30%c%s\30\01'):fmt(96, 'You find a ')..('\30%c%s\30\01'):fmt(2, 'Defending Ring'..('\30%c%s\30\01'):fmt(96,' on King Behemoth.')))
		-- AshitaCore:GetChatManager():AddChatMessage(121, false, ('\30%c%s\30\01'):fmt(96, 'Eleanor obtains a ')..('\30%c%s\30\01'):fmt(2, 'Defending Ring'..('\30%c%s\30\01'):fmt(96, '.')))
		-- print('\90\101\114\97\116\105\97\32\100\101\102\101\97\116\115\32\116\104\101\32\171\65\119\122\100\101\105\46\127\49')
		--print(bit.tobit(utils.RGBAToHex(allSettings.dmgDoneColor)))
	--	print(string.format("%08X", imgui.GetColorU32(allSettings.dmgDoneColor)))
		--print(bit.tohex(utils.rgbaToHexNum(allSettings.dmgDoneColor)))
		--print(MC(utils.rgbaToHexNum(allSettings.dmgDoneColor)));
		-- local t = '\89\111\117\32\111\98\116\97\105\110\101\100\32\97\32\112\114\101\115\116\105\103\101\32\117\112\103\114\97\100\101\33\32\84\104\105\101\102\58\32\129\154\129\154\129\153\129\153\129\153\32\40\84\72\43\50\32\47\32\69\118\97\115\105\111\110\43\53\41\10'
		-- print(t);
		-- local ct = CleanText(t, 'local')
		-- --print(ct)
		-- ---print('\89\111\117\32\111\98\116\97\105\110\101\100\32\97\32\112\114\101\115\116\105\103\101\32\117\112\103\114\97\100\101\33\32\84\104\105\101\102\58\32\129\154\129\154\129\153\129\153\129\153\32\40\84\72\43\50\32\47\32\69\118\97\115\105\111\110\43\53\41\10')
		-- local bytes = {}
		-- for i = 1, #ct do
        -- bytes[#bytes + 1] = string.byte(ct, i)
		-- end
		--print(table.concat(bytes, " "))

		--print("\129\97 \129\99 \129\121 \129\122")
		--print(utf8.char(0x1F604)..' '..utf8.char(0x1F605)..' '..utf8.char(0x1F606)..' '..utf8.char(0x1F607)..' '..utf8.char(0x1F608))
		
		--local testemoji = ':grinning: :grin: :joy: :smiley: :smile: :sweat_smile: :laughing: :wink: :blush: :yum: :sunglasses: :smirk: :neutral_face: :expressionless: :unamused: :relieved: :pensive: :confused: :confounded: :kissing: :kissing_heart: :kissing_smiling_eyes: :kissing_closed_eyes: :elephant: :mammoth: :mouse: :rat: :hamster: :rabbit: :bear: :polar_bear: :panda_face: :koala: :sloth: :otter: :skunk: :kangaroo: :badger: :eagle: :duck: :owl: :swan: :dove: :bat:';

		--AshitaCore:GetChatManager():AddChatMessage(5, false, testemoji)
		
		print('Please Read!\n\nWelcome to FancyChat addon!\n\nThis is addon provides a highly customizable and interactive chat replacemante for Final Fantasy XI.\nPlease take your time to check all the settings by either clicking the cog wheel icon at the bottom of the chat window or by typing the command \"/fancychat settings\".\n\nYou can hover with your mouse over the (i) icons to learn more about each functionality. This addon features some advanced options that can include unwanted behaviors for certain players. Therefore, please pay extra attention to the (i) marked in red to learn about important critical information about such features.\n\nFor further help you can check the addon manual accessible from the settings menu or through the command \"/fancychat manual\".\n\nHave fun!')
		--AshitaCore:GetChatManager():AddChatMessage(121,false,'\129\159 Quest Completed')
		--AshitaCore:GetChatManager():AddChatMessage(21,false,' earns a merit point (Total: 4).')
		
		--AshitaCore:GetChatManager():AddChatMessage(214, false, '[2]<eleanor> :red_heart:')
		--print('hello'..utf8.char(0x2764))
		--local msg = 'hello'
		-- if AshitaCore:GetChatManager():IsInputOpen() == 0x11 then
		-- AshitaCore:GetChatManager():SetInputText(msg)
		--AshitaCore:GetChatManager():QueueCommand(-1, "/sendkey space down")

	end
	if (#args == 2 and args[2] == 'helpdebug') then
		
		print(#help.foundParent)
		print(tostring(help.foundAnything))
		--Debug(help.searchBuff[1], 1, true);
		print(table.concat(help.foundParent,','))
	end
	if not fcw[1].Closing and fcw[1].InitDone and fcw[1].LoggedIn then
		if (#args == 2 and args[2] == 'guideme') then
			fcw[1].GuideMeOpened[1] = not fcw[1].GuideMeOpened[1];
			if fcw[1].GuideMeOpened[1] then fcw[1].NotepadOpened[1] = false; end
			return;
		end
		if (#args == 2 and args[2] == 'settings') then
			allSettings.settingsOpened[1] = not allSettings.settingsOpened[1];
			SaveSettings();
			return;
		end
		if (#args == 2 and args[2] == 'compact') then
			allSettings.CompactTabs = not allSettings.CompactTabs;
			fcw[1].PosChanged = true
			fcw[2].PosChanged = true
			SaveSettings();
			return;
		end
		if (#args == 2 and args[2] == 'manual') then
			help.opened[1] = not help.opened[1];
			return;
		end
		if (#args == 2 and args[2] == 'notes') then
			fcw[1].NotepadOpened[1] = not fcw[1].NotepadOpened[1];
			if fcw[1].NotepadOpened[1] then fcw[1].GuideMeOpened[1] = false; end
			return;
		end
		if (#args == 2 and args[2] == 'tod') then
			allSettings.PreciseTS[1] = not allSettings.PreciseTS[1];
			SaveSettings();
			return;
		end
		if (#args == 2 and args[2] == 'ts') then
			print('Current Time: '..os.date(par_FormatTS[1], os.time()))
			return;
		end
		
	end
	
end);

ashita.events.register('xinput_button', 'xinput_button_callback1', function (e)
	--print(button8)
	
	if allSettings.GamepadNav[1] then
		
		gamepadButtons.buttonsCDready =  os.clock() - gamepadButtons.buttonsCD > 0.15
		gamepadButtons.analogCDready =  os.clock() - gamepadButtons.analogCD > 0.02
		if gamepadButtons.pressedEnter and gamepadButtons.buttonsCDready then
			gamepadButtons.pressedEnter = false
			AshitaCore:GetChatManager():QueueCommand(1, "/sendkey enter up")
		end
		--print(gamepadButtons.analogCDready)
		if e.button == 8 then
			if e.state == 1 then
				ResetAutoHideTimer()
				gamepadButtons.enabled = true
				e.blocked = true
			else
				gamepadButtons.enabled = false
			end
			
			return
		end
		
		if gamepadButtons.enabled then
			if
				not (e.button == 18 and e.state == 0) and
				not (e.button == 19 and e.state == 0) and
				not (e.button == 20 and e.state == 0) and
				not (e.button == 21 and e.state == 0) 
			then
				e.blocked = true
			end
			
			-- if e.state ~= 0 then
				-- print(e.button)
			-- end
			
			if e.button == 9 and not fcw[1].BufferBusy and gamepadButtons.buttonsCDready then

				local tab_id = utils.FindInTable(tab_Tabs, allSettings.SelectedTab);

				if (tab_id) then
					if (tab_id == utils.GetTableLen(tab_Tabs)) then
						tab_NextTab = tab_Tabs[1];
					else
						tab_NextTab = tab_Tabs[tab_id+1];
					end
				end
				gamepadButtons.buttonsCD = os.clock()
				return
			end
			
			if allSettings.SecondChat[1] and e.button == 17 and not fcw[1].BufferBusy and gamepadButtons.buttonsCDready then
				local tab_id = utils.FindInTable(tab_Tabs, allSettings.SelectedTab2);

				if (tab_id) then
					if (tab_id == utils.GetTableLen(tab_Tabs)) then
						tab_NextTab2 = tab_Tabs[1];
					else
						tab_NextTab2 = tab_Tabs[tab_id+1];
					end
				end
				gamepadButtons.buttonsCD = os.clock()
				return
			end

			
			if e.button == 19 then
				if e.state ~= 0 then
					gamepadButtons.scroll1 = (e.state/math.abs(e.state))
				else
					gamepadButtons.scroll1 = 0
				end
			end
			if e.button == 21 then
				if e.state ~= 0 then
					gamepadButtons.scroll2 = (e.state/math.abs(e.state))
				else
					gamepadButtons.scroll2 = 0
				end
			end
			
			if gamepadButtons.scroll1 ~= 0 and gamepadButtons.analogCDready then--
				--print(gamepadButtons.scroll1)
				--print(gamepadButtons.scroll1)
				fcw[1].ScrollDelta = gamepadButtons.scroll1
				fcw[3].ScrollDelta = gamepadButtons.scroll1
				gamepadButtons.analogCD = os.clock()
				return
			end
			if gamepadButtons.scroll2 ~= 0 and gamepadButtons.analogCDready then
				--print(gamepadButtons.scroll1)
				fcw[2].ScrollDelta = gamepadButtons.scroll2
				gamepadButtons.analogCD = os.clock()
				return
			end
			if e.button == 13 and e.state == 1 then
				if fcw[1].ScrolledBack > 0 then
					ResetScrolling(1);
				end
				if fcw[2].ScrolledBack > 0 then
					ResetScrolling(2);
				end
				if fcw[3].ScrolledBack > 0 then
					ResetScrolling(3, fcw[3].ChatLines);
				end
				return
			end
			if e.button == 15 and e.state == 1 and gamepadButtons.buttonsCDready then
				fcw[3].BigMode = not fcw[3].BigMode;
				gamepadButtons.buttonsCD = os.clock()
				return
			end
			if e.button == 14 and e.state == 1 and AshitaCore:GetChatManager():IsInputOpen() == 0x00 and gamepadButtons.buttonsCDready then
				AshitaCore:GetChatManager():QueueCommand(-1, "/sendkey space down")
				AshitaCore:GetChatManager():QueueCommand(-1, "/sendkey space up")
				gamepadButtons.buttonsCD = os.clock()
				return
			end
			if e.button == 12 and e.state == 1 and AshitaCore:GetChatManager():IsInputOpen() == 0x11 and gamepadButtons.buttonsCDready then
				AshitaCore:GetChatManager():QueueCommand(-1, "/sendkey enter down")
				local cmd = AshitaCore:GetChatManager():GetInputTextRaw()
				if #cmd > 0 and not cmd:find('^%s*$') then 
					updateCommandList(cmd)
				end
				gamepadButtons.pressedEnter = true
				gamepadButtons.buttonsCD = os.clock()
				return
			end
			if #fcw[1].LastCommands[1] > 0 then
				if e.button == 0 and e.state == 1 and AshitaCore:GetChatManager():IsInputOpen() == 0x11 and gamepadButtons.buttonsCDready then
					local nextCommandIdx = fcw[1].LastCommands[2] + 1
					if nextCommandIdx > #fcw[1].LastCommands[1] then nextCommandIdx = 1 end
					if not fcw[1].LastCommands[1][nextCommandIdx] then nextCommandIdx = 1 fcw[1].LastCommands[2] = 1 end
					AshitaCore:GetChatManager():SetInputText(fcw[1].LastCommands[1][nextCommandIdx])
					fcw[1].LastCommands[2] = nextCommandIdx
					gamepadButtons.buttonsCD = os.clock()
					return
				end
				if e.button == 1 and e.state == 1 and AshitaCore:GetChatManager():IsInputOpen() == 0x11 and gamepadButtons.buttonsCDready then
					local nextCommandIdx = fcw[1].LastCommands[2] - 1
					if nextCommandIdx < 1 then nextCommandIdx = #fcw[1].LastCommands[1] end
					if not fcw[1].LastCommands[1][nextCommandIdx] then nextCommandIdx = 1 fcw[1].LastCommands[2] = 1 end
					AshitaCore:GetChatManager():SetInputText(fcw[1].LastCommands[1][nextCommandIdx])
					fcw[1].LastCommands[2] = nextCommandIdx
					gamepadButtons.buttonsCD = os.clock()
					return
				end
			end
			if e.button == 3 and e.state == 1 and AshitaCore:GetChatManager():IsInputOpen() == 0x11 and gamepadButtons.buttonsCDready then
				local nextCommandIdx = fcw[1].LastCommands[4] + 1
				if nextCommandIdx > #fcw[1].LastCommands[3] then nextCommandIdx = 1 end
				--if not fcw[1].LastCommands[1][nextCommandIdx] then nextCommandIdx = 1 fcw[1].LastCommands[2] = 1 end
				AshitaCore:GetChatManager():SetInputText(fcw[1].LastCommands[3][nextCommandIdx])
				fcw[1].LastCommands[4] = nextCommandIdx
				gamepadButtons.buttonsCD = os.clock()
				return
			end
			if e.button == 2 and e.state == 1 and AshitaCore:GetChatManager():IsInputOpen() == 0x11 and gamepadButtons.buttonsCDready then
				local nextCommandIdx = fcw[1].LastCommands[4] - 1
				if nextCommandIdx < 1 then nextCommandIdx = #fcw[1].LastCommands[3] end
				--if not fcw[1].LastCommands[1][nextCommandIdx] then nextCommandIdx = 1 fcw[1].LastCommands[2] = 1 end
				AshitaCore:GetChatManager():SetInputText(fcw[1].LastCommands[3][nextCommandIdx])
				fcw[1].LastCommands[4] = nextCommandIdx
				gamepadButtons.buttonsCD = os.clock()
				return
			end
			-- if AshitaCore:GetChatManager():IsInputOpen() == 0x11 then
			-- AshitaCore:GetChatManager():SetInputText(msg)
			--AshitaCore:GetChatManager():QueueCommand(-1, "/sendkey space down")
		end
	end
end)



ashita.events.register('key_state', 'key_state_callback1', function (e)
	
	if gamepadButtons.enabled then return end
	
	
    local keyptr = ffi.cast('uint8_t*', e.data_raw);
	
	if  AshitaCore:GetChatManager():IsInputOpen() == 0x11 and (keyptr[28] ~= 0 or keyptr[156] ~= 0) then
	--	print(AshitaCore:GetChatManager():GetInputTextRaw())
		local cmd = AshitaCore:GetChatManager():GetInputTextRaw()
		if #cmd > 0 and not cmd:find('^%s*$') then 
			updateCommandList(cmd)
		end
	end
	
    if (allSettings.shortcutHideEnabled[1] and keyptr[allSettings.shortcutHide] ~= 0 and keyptr[allSettings.shortcutHideS] ~= 0 and not fcw[1].Keydown and AshitaCore:GetChatManager():IsInputOpen() == 0x00) then
		fcw[1].HideChat = not fcw[1].HideChat;
		ResetAutoHideTimer()
		SetChatOpacity(1,1)
		if allSettings.SecondChat[1] then SetChatOpacity(1,2) end
		fcw[1].Keydown = true;
	else if (keyptr[allSettings.shortcutHide] == 0) then
			fcw[1].Keydown = false;
		end
    end
	
	if (allSettings.shortcutBigEnabled[1] and keyptr[allSettings.shortcutBig] ~= 0 and keyptr[allSettings.shortcutBigS] ~= 0 and not fcw[3].Keydown and AshitaCore:GetChatManager():IsInputOpen() == 0x00) then
		fcw[3].BigMode = not fcw[3].BigMode;
		ResetAutoHideTimer()
		fcw[3].Keydown = true;
	else if (keyptr[allSettings.shortcutBig] == 0) then
			fcw[3].Keydown = false;
		end
    end
	
	if not fcw[1].BufferBusy then
		if (allSettings.shortcutTabEnabled[1] and keyptr[allSettings.shortcutTab] ~= 0 and keyptr[allSettings.shortcutTabS] ~= 0 and not fcw[1].Keydown2 and AshitaCore:GetChatManager():IsInputOpen() == 0x00) then
			local tab_id = utils.FindInTable(tab_Tabs, allSettings.SelectedTab);
			fcw[1].Keydown2 = true;
			if (tab_id) then
				if (tab_id == utils.GetTableLen(tab_Tabs)) then
					tab_NextTab = tab_Tabs[1];
				else
					tab_NextTab = tab_Tabs[tab_id+1];
				end
				ResetAutoHideTimer()
			end
		else if (keyptr[allSettings.shortcutTab] == 0) then
				fcw[1].Keydown2 = false;
			end
		end 
		
		if allSettings.SecondChat[1] then
			if (allSettings.shortcutTab2Enabled[1] and keyptr[allSettings.shortcutTab2] ~= 0 and keyptr[allSettings.shortcutTab2S] ~= 0 and not fcw[1].Keydown3 and AshitaCore:GetChatManager():IsInputOpen() == 0x00) then
				local tab_id = utils.FindInTable(tab_Tabs, allSettings.SelectedTab2);
				fcw[1].Keydown3 = true;
				if (tab_id) then
					if (tab_id == utils.GetTableLen(tab_Tabs)) then
						tab_NextTab2 = tab_Tabs[1];
					else
						tab_NextTab2 = tab_Tabs[tab_id+1];
					end
					ResetAutoHideTimer()
				end
			else if (keyptr[allSettings.shortcutTab2] == 0) then
					fcw[1].Keydown3 = false;
				end
			end
		end
	end
end);

ashita.events.register('mouse', 'mouse_callback1', function (e)
    if (e.delta ~= 0) then
        fcw[1].ScrollDelta = e.delta;
		fcw[2].ScrollDelta = e.delta;
		fcw[3].ScrollDelta = e.delta;
    end
	--[[
	if IsRectHovered(ro_RectBG[1].settings, allSettings.fontSettings.font_height/2) or IsRectHovered(ro_RectBG[2].settings, allSettings.fontSettings.font_height/2) then
		if (e.message == 513 or e.message == 514) then
			e.blocked = true;
			return;
		end
	end
	]]--
end);

function updateCommandList(text)
	table.insert(fcw[1].LastCommands[1], 1, text)
	if #fcw[1].LastCommands[1] > 20 then
		table.remove(fcw[1].LastCommands[1], #fcw[1].LastCommands[1])
	end
	
	--print(#fcw[1].LastCommands[1])
end

function DebugWindow()
	--dw_WindowW, dw_WindowH = imgui.GetWindowSize();
	
	imgui.SetNextWindowSize({ dw_WindowW, dw_WindowH, });
	imgui.SetNextWindowSizeConstraints({ 200, 500, }, { FLT_MAX, FLT_MAX, });
	imgui.Begin('FancyChat_Debug_'+fcw[1].PlayerName, dw_WindowOpened);
	
	if (utils.GetTableLen(b_ChatBuffer[1][2]) > 0) then
		
		--imgui.Text('poslinereq1 '..tostring(fcw[1].PositionLinesRequest));
		--if fcw[1].PositionLinesRequest then Debug('poslinereq1 '..tostring(fcw[1].PositionLinesRequest), 1, true); end 
		--imgui.Text('poslinereq2 '..tostring(fcw[2].PositionLinesRequest));
		
		--imgui.Text('uiy '..tostring(uiw.UISizeY));
		--local dw_testPTR1 = ashita.memory.read_uint32(dw_testPTR+0x01);
		--local dw_testPTR21 = ashita.memory.read_uint32(dw_testPTR1+0x54);
		--local dw_testPTR2 = dw_testPTR21;
		--local dw_testPTR2_PTR = ashita.memory.read_uint32(dw_testPTR2+0x04);
		--local dw_testPTR2_PTRText = ashita.memory.read_string(dw_testPTR2_PTR,16);
		--local dw_testPTR2_PTRText =ashita.memory.read_string(dw_testPTR2_PTR+0x46,32);
		--local dw_testPTR3 = ashita.memory.read_uint32(dw_testPTR2+0x0C);
		--local dw_MenuDescPTR = ashita.memory.read_uint32(dw_testPTR3+0x40);
		--local dw_MenuDesc =  ashita.memory.read_string(dw_MenuDescPTR,32);
		
		--uiw.MenuDescPTR21 = ashita.memory.read_uint32(uiw.MenuDescPTR+0x54);
		--uiw.MenuDescPTR22 = ashita.memory.read_uint32(uiw.MenuDescPTR+0x58);
		--uiw.MenuDescPTR2 = ashita.memory.read_uint32(math.max(uiw.MenuDescPTR21,uiw.MenuDescPTR22)+0x0C);
		-- uiw.MenuDescPTR2 = ashita.memory.read_uint32(uiw.MenuDescPTR+0x54);
		-- uiw.MenuDescPTR2 = ashita.memory.read_uint32(uiw.MenuDescPTR2+0x0C);
		
		-- uiw.MenuDescPTR2 = ashita.memory.read_uint32(uiw.MenuDescPTR2+0x40);
		-- uiw.MenuDesc =  ashita.memory.read_string(uiw.MenuDescPTR2,64);
		--imgui.Text('testptr: '..tostring(uiw.MenuLabel and (uiw.MenuLabel[1] == 'menutrddummy' or uiw.MenuLabel[1] == 'menurem4li2')));
		--imgui.Text('olcolor: '..(bit.tohex(fcw[2].OutlineColor)));
		--imgui.Text('testptr: '..(bit.tohex(dw_testPTR2_PTR)));
		--imgui.Text('testptr: '..(bit.tohex(dw_testPTR2_PTR+0x44)));
		--imgui.Text('testptr: '..dw_testPTR2_PTRText);
		--imgui.Text('InvMenuDesc: '..(uiw.MenuDesc and uiw.MenuDesc or 'null'));
		--imgui.Text('InvMenuDesc: '..(type(uiw.MenuDesc)=='number' and '-1' or tostring(#uiw.MenuDesc)));
		--imgui.Text('InvMenuDescNIL: '..tostring(uiw.MenuDesc==nil));
		--imgui.Text('dw_menuItem1 '..uiw.MenuDesc);
		--2=combat, 3=Linkshell, 4=Party, 5= tell,  6=shout, 7 = npc
		--imgui.Text(bit.tohex(fcw[2].OutlineColor));
		--imgui.Text(tostring());
		dw_testPTR2 = ashita.memory.read_uint32(dw_testPTR+0x04)
		imgui.Text('dw_testPTR: '..bit.tohex(dw_testPTR+0x04));
		imgui.Text('dw_testPTR Value: '..bit.tohex(dw_testPTR2));
		dw_testPTR3 = ashita.memory.read_uint32(dw_testPTR2+0x14)
		imgui.Text('dw_testPTR2: '..bit.tohex(dw_testPTR2+0x14));
		imgui.Text('dw_testPTR2 Value: '..bit.tohex(dw_testPTR3));
		dw_testPTR4 = ashita.memory.read_uint32(dw_testPTR3+0x10)
		imgui.Text('dw_testPTR3: '..bit.tohex(dw_testPTR3+0x10));
		imgui.Text('dw_testPTR3 Value: '..bit.tohex(dw_testPTR4));
		dw_testPTR5 = ashita.memory.read_uint32(dw_testPTR4+0x2C)
		imgui.Text('dw_testPTR4: '..bit.tohex(dw_testPTR4+0x2C));
		imgui.Text('dw_testPTR5 Value: '..bit.tohex(dw_testPTR5));
		dw_testString = ashita.memory.read_string(dw_testPTR5,16)
		imgui.Text('dw_testPTRString: '..tostring(dw_testString));
;
		
		
		imgui.Text('buff_idx '..tostring(b_ChatBufferIdx[1]));
		imgui.Text('buff_idx3 '..tostring(b_ChatBufferIdx[3]));
		imgui.Text('buff_All '..tostring(#b_ChatBuffer[1][2].text)..',N: '..tostring(b_ChatBufferN_All));
		imgui.Text('buff_AA '..tostring(#b_ChatBuffer[2][2].text)..',N: '..tostring(b_ChatBufferN_AllAlt));
		imgui.Text('buff_C '..tostring(#b_ChatBuffer[3][2].text)..',N: '..tostring(b_ChatBufferN_Combat));
		imgui.Text('buff_LS '..tostring(#b_ChatBuffer[4][2].text)..',N: '..tostring(b_ChatBufferN_Linkshell));
		imgui.Text('buff_PT '..tostring(#b_ChatBuffer[5][2].text)..',N: '..tostring(b_ChatBufferN_Party));
		imgui.Text('buff_SH '..tostring(#b_ChatBuffer[7][2].text)..',N: '..tostring(b_ChatBufferN_Shout));
		imgui.Text('buff_Custom '..tostring(#b_ChatBuffer[6][2].text)..',N: '..tostring(b_ChatBufferN_Custom));
		local buffsum = 0;
		for i = 3, 7 do
			buffsum = buffsum + #b_ChatBuffer[i][2].text;
		end
		imgui.Text('buff_Sum '..tostring(buffsum));
		imgui.Text('buff_AA+C '..tostring(#b_ChatBuffer[2][2].text+#b_ChatBuffer[3][2].text));
		local MBcheck = false;
		if
			--#b_ChatBuffer[1][2].text == #b_ChatBuffer[1][2].mode and
			--#b_ChatBuffer[1][2].mode == #b_ChatBuffer[1][2].color and
			#b_ChatBuffer[1][2].color == #b_ChatBuffer[1][2].auxText and
			#b_ChatBuffer[1][2].auxText == #b_ChatBuffer[1][2].auxColor and
			#b_ChatBuffer[1][2].auxColor == #b_ChatBuffer[1][2].url
		then
			MBcheck = true;
		end
		imgui.Text('mb check '..tostring(MBcheck));
		imgui.Text('movechat '..tostring(fcw[1].MoveChat));
		imgui.Text('invidx '..tostring(uiw.InvIdx));
		imgui.Text('noshiftidx '..tostring(uiw.NoShiftIdx));
		imgui.Text('menuext '..tostring(uiw.MenuExt));
		imgui.Text('wasinequip '..tostring(uiw.WasInEquip));
		imgui.Text('wasininv '..tostring(uiw.WasInInv));
		imgui.Text('diagshown '..tostring(uiw.DialogShown));
		imgui.Text('isinnconv '..tostring(par_IsInConv));
		imgui.Text('inevent '..tostring(par_InEvent));
		--imgui.Text(tostring(os.clock()-uiw.DialogPromptStart));
		--imgui.Text(tostring(os.clock()-uiw.DialogCDStart));
		
		--imgui.Text(tostring(fcw[2].ChatShiftScale_CarryOver));
		imgui.Text(tostring(fcw[1].ScrollPos));
		imgui.Text(tostring(fcw[1].PrevMousePos[2]));
		--imgui.Text(tostring(fo_Chat[1][fcw[1].ChatHead].settings.position_x));


		--imgui.Text(tostring(allSettings.SelectedTab));
		--imgui.Text(tostring(tab_NextTab));
		imgui.Text(tostring(fcw[1].ChatShift));
		--imgui.Text(tostring(fcw[1].Chat1WindowPosX));
		--imgui.Text(tostring(fcw[1].Chat1WindowPosY-fcw[1].Anchor_Y));
		imgui.Text(tostring(fcw[1].Anchor_Y));
		--imgui.Text(tostring(fcw[1].ChatShiftScale));
		--imgui.Text(tostring(fcw[1].ChatShiftScale_Target));
		imgui.Text(tostring(b_ChatBufferN[2]));
		imgui.Text(tostring(b_ChatBufferIdx[2]));
		--imgui.Text(tostring(fcw[1].PrevHideChat));
		imgui.Text(tostring(dw_PLRCount));
		
		--imgui.Text(tostring(par_MessageMode));
		--imgui.Text(bit.tohex(ashita.memory.read_uint32(uiw.WinOpenPtr)))
		imgui.Text(tostring(b_ChatBuffer[2][2].url[utils.GetTableLen(b_ChatBuffer[2][2].url)]));
		--imgui.Text(tostring(fcw[1].PlayerName )); 
		--for cf = 1, #par_customFilters do
		--	imgui.Text(tostring(par_customFilters[cf][1]))
		--	imgui.Text(tostring(par_customFilters[cf][2]))
		--end
		--imgui.Text();
	--	imguiWrap.BeginChild('DebugPrints',{ dw_WindowW*0.9, dw_WindowH*0.9 }, true)
		imguiWrap.BeginChild('Debugchild',{imgui.GetWindowWidth()*0.8, imgui.GetWindowHeight()*0.8,true})
		imgui.Text(dw_TestMessage);
		imgui.Text(dw_TestMessage2);
		imgui.EndChild()
	--	imgui.EndChild()
	end

	if (imgui.Checkbox('Show Message Mode',{dw_ShowMessageMode[1]})) then 
		dw_ShowMessageMode[1] = not dw_ShowMessageMode[1];
	end
	if (imgui.Checkbox('Show Combat Channel Color',{dw_ChannelColorMode[1]})) then 
		dw_ChannelColorMode[1] = not dw_ChannelColorMode[1];
	end
	if imgui.Button('Reset Test Messages') then
		dw_TestMessage = '';
		dw_TestMessage2 = '';
	end
	dw_WindowW, dw_WindowH = imgui.GetWindowSize();
	imgui.End();
end

function Debug(msg, target, chained)
	if target == 1 then
		if chained  then
			if #dw_TestMessage < 4000 then dw_TestMessage = dw_TestMessage..'\ntm> '..msg; end
		else
			dw_TestMessage = 'tm> '..msg;
		end
	else
		if target == 2 then
			if chained  then
				if #dw_TestMessage < 4000 then  dw_TestMessage2 = dw_TestMessage2..'\ntm2> '..msg; end
			else
				dw_TestMessage2 = 'tm2> '..msg;
			end
		end
	end
end

function Init()

	local dsize = imgui.GetIO().DisplaySize;
	fo_BigMode = gdi:create_object(allSettings.fontSettings, false)
	fo_BigMode:set_font_height(allSettings.fontSettings.font_height-2)
	fo_BigMode:set_text('Big Mode')
	fo_BigMode:set_font_color(0xFAD1F4FF)
	fo_BigMode:set_visible(false)
	ro_BigMode = gdi:create_rect(allSettings.rectSettings, false);
	ro_BigMode:set_fill_color(0x00000000)
		
	fcw[3].BG_W = allSettings.chatLineMaxL*allSettings.fontSettings.font_height*0.58;
	fcw[3].BG_H = math.floor(dsize.y*0.8);
	fcw[3].ChatLines = math.floor((fcw[3].BG_H)/allSettings.fontSettings.font_height)
	fcw[3].HLeft = fcw[3].BG_H - (fcw[3].ChatLines*allSettings.fontSettings.font_height)
	fcw[3].BG_H = math.floor(allSettings.fontSettings.font_height*fcw[3].ChatLines*fcw[1].BGScale)
	
	Debug(fcw[3].HLeft,1,true)
	local last_fo = allSettings.SecondChat[1] and 2 or 1;
	if fo_Aux[last_fo] ~= nil then
		fcw[1].InitDone = true;
		ChangeTab(1, tab_NextTab);
		if allSettings.SecondChat[1] then ChangeTab(2, tab_NextTab2); end
	end
	fcw[1].BG_W = allSettings.chatLineMaxL*allSettings.fontSettings.font_height*0.58;
	fcw[1].BG_H = math.floor(allSettings.fontSettings.font_height*allSettings.ChatLines*fcw[1].BGScale);
	ro_RectBG[1]:set_fill_color(allSettings.rectSettings.fill_color);
	ro_RectBG[1]:set_width(allSettings.chatLineMaxL*allSettings.fontSettings.font_height*0.58);
	ro_RectBG[1]:set_height(allSettings.fontSettings.font_height*(allSettings.ChatLines+1) + (allSettings.fontSettings.font_height/5));
	if allSettings.SecondChat[1] then
		fcw[2].BG_W = allSettings.chatLineMaxL*allSettings.fontSettings.font_height*0.58;
		fcw[2].BG_H = math.floor(allSettings.fontSettings.font_height*allSettings.ChatLines*fcw[2].BGScale);
		ro_RectBG[2]:set_fill_color(allSettings.rectSettings.fill_color);
		ro_RectBG[2]:set_width(allSettings.chatLineMaxL*allSettings.fontSettings.font_height*0.58);
		ro_RectBG[2]:set_height(allSettings.fontSettings.font_height*(allSettings.ChatLines+1) + (allSettings.fontSettings.font_height/5));
	end
	
	fcw[1].RoRectBaseX = ((allSettings.fontSettings.font_height*2.5)/allSettings.fontSettings.font_height)
	fcw[1].RoRectBaseY = (allSettings.ChatLines*allSettings.fontSettings.font_height) + (allSettings.fontSettings.font_height/(allSettings.fontSettings.font_height-100))- (allSettings.fontSettings.font_height/10) --+ (allSettings.fontSettings.font_height/10)+(allSettings.fontSettings.font_height/(allSettings.fontSettings.font_height-100))+1
	fcw[2].RoRectBaseY = (allSettings.ChatLines*allSettings.fontSettings.font_height) + (allSettings.fontSettings.font_height/(allSettings.fontSettings.font_height-100))- (allSettings.fontSettings.font_height/10)
	--fcw[3].RoRectBaseY = (fcw[2].RoRectBaseY) + ((fcw[3].ChatLines - allSettings.ChatLines + 1)*allSettings.fontSettings.font_height) - (16*(1080/dsize.y))
	fcw[3].RoRectBaseY = (fcw[3].ChatLines*allSettings.fontSettings.font_height) + (allSettings.fontSettings.font_height/(allSettings.fontSettings.font_height-100))- (allSettings.fontSettings.font_height/10)
	--fcw[3].RoRectBaseY = (fcw[3].ChatLines*allSettings.fontSettings.font_height) + (allSettings.fontSettings.font_height/(allSettings.fontSettings.font_height-100))- (allSettings.fontSettings.font_height/10)
	fcw[1].FWDBaseX = (allSettings.fontSettings.font_height/1.35)+(allSettings.chatLineMaxL*allSettings.fontSettings.font_height/400)
	fcw[1].BKWBaseY = (allSettings.fontSettings.font_height*allSettings.ChatLines)-((allSettings.fontSettings.font_height*5)/allSettings.fontSettings.font_height)
	fcw[1].BKWBaseX = ((allSettings.fontSettings.font_height*1.5)/allSettings.fontSettings.font_height)

end

function ResetScrolling(id, ChatLines)
	fcw[id].Scrolling = false;
	fcw[id].ScrolledBack = 0;
	--fcw[2].ChatShiftScale_CarryOver = 0;
	--fcw[id].ScrollDelta = 0;
	if ChatLines then 
		ResetLines(id, ChatLines);
	else
		ResetLines(id);
	end
end

function ChangeTab(fo_id, tabName)
	--print('---'..tostring(fo_id)..'-'..tostring(dw_frameID))
	if fo_id == 1 then	
		allSettings.SelectedTab = tabName;
		--if tabName == 'AllAlt' then selectedTab = 'All'; end
	else
		allSettings.SelectedTab2 = tabName;
		--if tabName == 'AllAlt' then selectedTab2 = 'All'; end
	end
	b_ChatBufferIdx[fo_id] = (function()
		if (tabName == 'All') then			b_ChatBufferMode[fo_id] = 1; return b_ChatBufferN_All; 			end
		if (tabName == 'AllAlt') then		b_ChatBufferMode[fo_id] = 2; return b_ChatBufferN_AllAlt; 		end
		if (tabName == 'Combat') then 		b_ChatBufferMode[fo_id] = 3; return b_ChatBufferN_Combat; 		end
		if (tabName == 'Linkshell') then	b_ChatBufferMode[fo_id] = 4; return b_ChatBufferN_Linkshell; 	end
		if (tabName == 'Party') then 		b_ChatBufferMode[fo_id] = 5; return b_ChatBufferN_Party; 		end
		if (tabName == 'Tell') then 		b_ChatBufferMode[fo_id] = 6; return b_ChatBufferN_Tell; 		end
		if (tabName == 'Shout') then 		b_ChatBufferMode[fo_id] = 7; return b_ChatBufferN_Shout;		end
		if (tabName == 'Custom') then		b_ChatBufferMode[fo_id] = 8; return b_ChatBufferN_Custom;		end
		return b_ChatBufferIdx[fo_id];
	end)();

	
	--ResetLines(3, fcw[3].ChatLines)
	if #fo_Chat[3] > 0 then
		b_ChatBufferIdx[3] =b_ChatBufferIdx[1]
		ResetScrolling(3, fcw[3].ChatLines)
		ResetLines(3, fcw[3].ChatLines)
		
		--b_ChatBufferN[3] = SetBufferN(allSettings.SelectedTab);
	end
	-- print(b_ChatBufferIdx[fo_id])
	-- if tabName == 'All' and allSettings.HideCombatFromAll[1] then print('hello') b_ChatBufferMode[fo_id] = 2; b_ChatBufferIdx[fo_id] = b_ChatBufferN_AllAlt end

	--if fo_id > 1 then print(tostring(b_ChatBufferMode[fo_id]));end
	local L_i = fcw[fo_id].ChatHead;
	for C_i = 1, allSettings.ChatLines do
		local CB_i = utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].text)-C_i+1;
		if (CB_i > 0) then 
			fo_Chat[fo_id][L_i]:set_text(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].text[CB_i]:trimex());
			fo_Chat[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].color[CB_i]);
			fo_Aux[fo_id][L_i]:set_text(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxText[CB_i]:trimex());
			fo_Aux[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxColor[CB_i]);
		else
			fo_Chat[fo_id][L_i]:set_text('');
			fo_Chat[fo_id][L_i]:set_font_color(0xFFFFFFFF);
			fo_Aux[fo_id][L_i]:set_text('');
			fo_Aux[fo_id][L_i]:set_visible(false);
			fo_Aux[fo_id][L_i]:set_font_color(0xFFFFFFFF);
		end
		L_i = L_i +1;
		if (L_i > allSettings.ChatLines) then L_i = 1; end 
	end 


end

function ResetLines(fo_id, ChatLines)
	local mode_id = fo_id
	if ChatLines then mode_id = 1 else ChatLines = allSettings.ChatLines end
	--fcw[fo_id].ScrolledBack = 0;
	local L_i = fcw[fo_id].ChatHead;
	--print(tostring(L_i));
	for C_i = 1, ChatLines do
		if(utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].text)-C_i+1 > 0) then
			fo_Chat[fo_id][L_i]:set_text(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].text[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].text)-C_i+1]:trimex());
			fo_Chat[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].color)-C_i+1]);
			fo_Aux[fo_id][L_i]:set_text(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].auxText[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].auxText)-C_i+1]:trimex());
			--if fo_Aux[fo_id][L_i].settings.text == '' then fo_Aux[fo_id][L_i]:set_visible(false) end
			fo_Aux[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].auxColor)-C_i+1]);
			--fo_Chat[fo_id][L_i]:set_outline_color(0xFF000000);
			--fo_Aux[fo_id][L_i]:set_outline_color(0xFF000000);
			--fo_Chat[fo_id][L_i]:set_visible(false);
			fo_Aux[fo_id][L_i]:set_visible(false);
		else
			fo_Chat[fo_id][L_i]:set_text('');
			fo_Chat[fo_id][L_i]:set_font_color(0xFF000000);
			fo_Aux[fo_id][L_i]:set_text('');
			if fo_id ~= 3 then
				fo_Aux[fo_id][L_i]:set_visible(false);
			else
				fo_Aux[fo_id][L_i]:set_visible(true);
			end
			fo_Aux[fo_id][L_i]:set_font_color(0xFF000000);
			--fo_Chat[fo_id][L_i]:set_outline_color(0xFF000000);
			--fo_Aux[fo_id][L_i]:set_outline_color(0xFF000000);
			--fo_Chat[fo_id][L_i]:set_visible(false);
			fo_Aux[fo_id][L_i]:set_visible(false);
		end

		L_i = L_i +1;
		if (L_i > ChatLines) then L_i = 1; end 
	end
	--if allSettings.SelectedTab == 'All' and allSettings.HideCombatFromAll[1] then b_ChatBufferN[fo_id]=b_ChatBufferN_AllAlt;  end
	fcw[fo_id].ChatShift = allSettings.fontSettings.font_height
	if fo_id < 3 then
		b_ChatBufferIdx[fo_id] = b_ChatBufferN[fo_id]
	end --b_ChatBufferN[1]
	fcw[fo_id].PositionLinesRequest = {true,true};
	--fcw[1].ResetCD = os.clock();
	--SetLinesVisible(fo_id, false)
end

function GoToLine(fo_id, line, currentIdx, ChatLines)
	local mode_id = fo_id
	if not ChatLines then ChatLines = allSettings.ChatLines else mode_id = 1 end
	
	--LegacyDebug(tostring(line))
	--fcw[fo_id].ScrolledBack = 0;
	--print(line);
	if line <= utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].text)
	and line >= ChatLines
	then
		--
		fcw[fo_id].Scrolling = true;
		fcw[fo_id].ChatShift = allSettings.fontSettings.font_height
	--	fcw[fo_id].ScrolledBack = b_ChatBufferIdx[fo_id]-line;
		fcw[fo_id].ScrolledBack = currentIdx-line;
		local L_i = fcw[fo_id].ChatHead;
	--print(tostring(L_i));
		for C_i = 1, ChatLines do
			if(utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].text)-C_i+1-line + ChatLines > 0) then
				
				fo_Chat[fo_id][L_i]:set_text(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].text[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].text)-C_i+1-fcw[fo_id].ScrolledBack]:trimex());
				
				fo_Chat[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].color)-C_i+1-fcw[fo_id].ScrolledBack]);
				
				fo_Aux[fo_id][L_i]:set_text(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].auxText[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].auxText)-C_i+1-fcw[fo_id].ScrolledBack]:trimex());
				--if fo_Aux[fo_id][L_i].settings.text == '' then fo_Aux[fo_id][L_i]:set_visible(false) end
				--fo_Chat[fo_id][L_i]:set_visible(false);
				fo_Aux[fo_id][L_i]:set_visible(false);
				fo_Aux[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[mode_id]][2].auxColor)-C_i+1-fcw[fo_id].ScrolledBack]);
				--fo_Chat[fo_id][L_i]:set_outline_color(0xFF000000);
				--fo_Aux[fo_id][L_i]:set_outline_color(0xFF000000);
			else
				fo_Chat[fo_id][L_i]:set_text('');
				--fo_Chat[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].color)-C_i+1-line]);
				fo_Aux[fo_id][L_i]:set_text('');
				fo_Aux[fo_id][L_i]:set_visible(false)
				--fo_Aux[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxColor)-C_i+1-line]);
			end

			L_i = L_i +1;
			if (L_i > ChatLines) then L_i = 1; end 
		end 
		--b_ChatBufferIdx[fo_id] = line;
		fcw[fo_id].PositionLinesRequest = {true,true};
		fcw[fo_id].RequestAuxFix = true;
	end
end

function ScrollLines(fo_id, message, color, auxMessage, auxColor, mode, ChatLines)
	if not message then
		if ChatLines then
			ResetLines(fo_id, ChatLines)
		else
			ResetLines(fo_id)
		end
		return
	end
	if fcw[1].BufferBusy or tab_NextTab ~= allSettings.SelectedTab then return end
	fcw[1].BufferBusy = true;
	if not ChatLines then ChatLines = allSettings.ChatLines end
    -- scrollback > 1
	-- scrollfwd > 0
	fcw[fo_id].PositionLinesRequest = {true,true};
	local L_i = fcw[fo_id].ChatHead+mode;
	if (mode == 1 and L_i > ChatLines) then L_i = 1; end 
	for C_i = 0, ChatLines-2 do
		fo_Chat[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*(C_i)));
		fo_Aux[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*(C_i)));
		
		L_i = L_i - 1 + (2*mode);
		if (L_i > ChatLines) then L_i = 1; end
		if (L_i < 1) then L_i = ChatLines; end
	end
	local NL_i = fcw[fo_id].ChatHead; local NL_ii = NL_i-1; if NL_ii < 1 then NL_ii =  ChatLines;end
	if mode == 0 then NL_i = fcw[fo_id].ChatHead-1; if (NL_i < 1) then NL_i = ChatLines; end end
	
	--if mode == 1 then
		--fo_Chat[fo_id][NL_ii]:set_font_color(bit.bor(0xFF000000,bit.band(fo_Chat[fo_id][NL_ii].settings.font_color,0x00FFFFFF)))
		--fo_Aux[fo_id][NL_ii]:set_font_color(bit.bor(0xFF000000,bit.band(fo_Aux[fo_id][NL_ii].settings.font_color,0x00FFFFFF)))
		--fo_Chat[fo_id][NL_ii]:set_outline_color(0xFF000000);
		--fo_Aux[fo_id][NL_ii]:set_outline_color(0xFF000000);
	--end
--	if fo_Chat[fo_id][NL_i].settings.font_color ~= color then
	fo_Chat[fo_id][NL_i]:set_font_color(color);
--	end
	fo_Chat[fo_id][NL_i]:set_position_y(fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*ChatLines*mode));
	fo_Aux[fo_id][NL_i]:set_position_y(fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*ChatLines*mode));
	fo_Chat[fo_id][NL_i]:set_text(message:trimex());
	fo_Aux[fo_id][NL_i]:set_font_color(auxColor);
	fo_Aux[fo_id][NL_i]:set_text(auxMessage:trimex());
	--if fo_Aux[fo_id][NL_i].settings.text == '' then fo_Aux[fo_id][L_i]:set_visible(false) end
	
	--fo_Chat[fo_id][NL_i]:set_outline_color(0xFF000000);
	--fo_Aux[fo_id][NL_i]:set_outline_color(0xFF000000);
	--fo_Chat[fo_id][L_i]:set_visible(false);
	fo_Aux[fo_id][NL_i]:set_visible(false);
	
	fcw[fo_id].ChatHead = fcw[fo_id].ChatHead-1+(2*mode);
	if (fcw[fo_id].ChatHead > ChatLines) then fcw[fo_id].ChatHead = 1; end 
	if (fcw[fo_id].ChatHead < 1) then fcw[fo_id].ChatHead = ChatLines; end
	fcw[fo_id].RequestAuxFix = true;
	
	return
end

-- function PrepareLines(fo_id)
	-- local L_i = fcw[fo_id].ChatHead;
	-- for C_i = 1, allSettings.ChatLines do
		-- fo_Chat[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*(C_i)) + fcw[fo_id].ChatShift);
		-- fo_Chat[fo_id][L_i]:set_position_x(fcw[fo_id].Anchor_X);
		-- fo_Aux[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*(C_i)) + fcw[fo_id].ChatShift);
		-- if fo_Chat[fo_id][L_i].rect then
			-- fo_Aux[fo_id][L_i]:set_position_x(math.floor(fcw[fo_id].Anchor_X+fo_Chat[fo_id][L_i].rect.right+allSettings.fontSettings.font_height/1.75));
		-- end
		-- L_i = L_i +1;
		-- if (L_i > allSettings.ChatLines) then L_i = 1; end 
	-- end
-- end

function IsRectHovered(params, margin)
	local x, y = imgui.GetMousePos();
	if x > params.position_x-margin and x <  params.position_x + params.width+margin
	and y > params.position_y-margin and y < params.position_y + params.height+margin then
		return true
	else
		return false
	end
end

function GetScrollPoint(fo_id)
	local h = 1;
	if utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].text) > 0 then
		--h = (b_ChatBufferIdx[fo_id]-(fcw[fo_id].ScrolledBack + allSettings.ChatLines))/math.max(b_ChatBufferIdx[fo_id] - allSettings.ChatLines-1,1);
		
		h =((#b_ChatBuffer[b_ChatBufferMode[fo_id]][2].text-(b_ChatBufferN[fo_id]-b_ChatBufferIdx[fo_id]))-(fcw[fo_id].ScrolledBack + allSettings.ChatLines))/
		math.max((#b_ChatBuffer[b_ChatBufferMode[fo_id]][2].text-(b_ChatBufferN[fo_id]-b_ChatBufferIdx[fo_id])) - allSettings.ChatLines-1,1);
	end
	return math.max(h,0);
end

function PositionLines(fo_id, ChatLines)
	fcw[1].BufferBusy = true;
	local BG = ro_RectBG[fo_id]
	local oth_id = fo_id
	if not ChatLines then ChatLines = allSettings.ChatLines else BG = ro_BigMode; oth_id = 1 end
	--if fcw[2].PositionLinesRequest then Debug('poslinereq1 '..tostring(fcw[1].PositionLinesRequest), 1, true) end
	if fcw[fo_id].PositionLinesRequest[1] then
		dw_PLRCount = dw_PLRCount+1;
		local was2requested = fcw[fo_id].PositionLinesRequest[2];
		--ro_Scroll[fo_id]:set_visible(true);
		if fcw[fo_id].PositionLinesRequest[2] then
			
			
			BG:set_position_x(fcw[fo_id].Anchor_X-fcw[1].RoRectBaseX);
			--BG:set_position_y(fcw[fo_id].Anchor_Y-fcw[fo_id].RoRectBaseY);
			BG:set_position_y(fcw[fo_id].Anchor_Y- fcw[fo_id].RoRectBaseY);
			if was2requested then --not fcw[fo_id].PLFast or 
			if fcw[fo_id].ScrollPos then
				ro_Scroll[oth_id]:set_width(BG.settings.width/200);	
				ro_Scroll[oth_id]:set_height(BG.settings.height/15);
				local h = BG.settings.position_y+(ro_Scroll[oth_id].settings.height*(1-fcw[fo_id].ScrollPos)+(allSettings.fontSettings.font_height*1.15))-(1-(fcw[fo_id].ScrollPos*BG.settings.height-ro_Scroll[oth_id].settings.height-allSettings.fontSettings.font_height*1.15));
				ro_Scroll[oth_id]:set_position_y(h+1);
				ro_Scroll[oth_id]:set_position_x(BG.settings.position_x+BG.settings.width-ro_Scroll[oth_id].settings.width-1);
			end	
			fo_Fwd[oth_id]:set_position_x(BG.settings.position_x+BG.settings.width-fcw[1].FWDBaseX);
			fo_Fwd[oth_id]:set_position_y(fcw[fo_id].Anchor_Y);
			fo_Bkw[oth_id]:set_position_x(fcw[fo_id].Anchor_X - fcw[1].BKWBaseX);
			fo_Bkw[oth_id]:set_position_y(fcw[fo_id].Anchor_Y - fcw[1].BKWBaseY);
			end
			
		end
		
		local fcwFoId = fcw[fo_id]
		fcwFoId.PositionLinesRequest = {false, false};
		local L_i = fcwFoId.ChatHead;
		for C_i = 1, ChatLines do
			local chatLi = fo_Chat[fo_id][L_i]
			local auxLi = fo_Aux[fo_id][L_i]

			local isLastLine = L_i+1 == fcwFoId.ChatHead or L_i+1-ChatLines == fcwFoId.ChatHead;

			if 	isLastLine and fcwFoId.ChatShift > 0 then
				local opacity = (fcwFoId.ChatShift/allSettings.fontSettings.font_height)
				chatLi:set_opacity(math.max(opacity,0.1))
				auxLi:set_opacity(math.max(opacity,0.1))

			else
				chatLi:set_opacity(1)
				auxLi:set_opacity(1)
			end	
			
			chatLi:set_position_y( fcwFoId.ChatShift + fcwFoId.Anchor_Y - (allSettings.fontSettings.font_height*(C_i)));
			chatLi:set_position_x(fcw[fo_id].Anchor_X);
			auxLi:set_position_y( fcwFoId.ChatShift + fcwFoId.Anchor_Y - (allSettings.fontSettings.font_height*(C_i)));
			if #auxLi.settings.text > 0 then
				if chatLi.rect == nil or chatLi.is_dirty then
					fcw[fo_id].RequestAuxFix = true
				else
					auxLi:set_position_x(math.floor(fcwFoId.Anchor_X+chatLi.rect.right+allSettings.fontSettings.font_height/1.7));
				end
			end
			L_i = L_i +1;
			if (L_i > ChatLines) then L_i = 1; end 
			--fo_Aux[fo_id][L_i]:set_visible(false);
			
			--fo_Aux[fo_id][L_i]:get_background():set_fill_color(allSettings.fontSettings.background.fill_color);
			-- if ((L_i == fcwFoId.ChatHead or was2requested)) then
				
				-- --fo_Chat[fo_id][L_i]:set_outline_color(0xFF000000);
				-- --fo_Aux[fo_id][L_i]:set_outline_color(0xFF000000);
				
	
				-- if (chatLi.rect ~= nil ) then
					-- if not chatLi.is_dirty then
						-- auxLi:set_position_x(math.floor(fcwFoId.Anchor_X+chatLi.rect.right+allSettings.fontSettings.font_height/1.75));
						-- auxLi:set_visible(true)
					-- end
				-- elseif auxLi.settings.visible == false then
				
					-- fcwFoId.PositionLinesRequest = {true, true};
					
				-- end
			-- end
			-- fcw[fo_id].PLFast = false
			-- if ((L_i == fcwFoId.ChatHead or was2requested)) then
				
				-- --fo_Chat[fo_id][L_i]:set_opacity(1)
				-- --fo_Aux[fo_id][L_i]:set_opacity(1)
				
	
				-- if ( #auxLi.settings.text > 0 and chatLi.rect ~= nil and not chatLi.is_dirty ) then 	
					-- auxLi:set_position_x(math.floor(fcwFoId.Anchor_X+chatLi.rect.right+allSettings.fontSettings.font_height/1.75));
					-- auxLi:set_visible(true)
				-- end
				-- if chatLi.is_dirty then
					-- chatLi:set_visible(true)
					-- fcwFoId.PositionLinesRequest = {true, true};
					-- fcw[fo_id].PLFast = true
				-- end
			-- end
		end
		fo_Chat[fo_id][fcw[fo_id].ChatHead]:set_visible(true)
		fo_Chat[fo_id][fcw[fo_id].ChatHead]:set_opacity(1)
		if not fcw[fo_id].RequestAuxFix then
			fo_Aux[fo_id][fcw[fo_id].ChatHead]:set_visible(true)
			fo_Aux[fo_id][fcw[fo_id].ChatHead]:set_opacity(1)
		end
	end
	--fo_Chat[fo_id][fcw[fo_id].ChatHead]:set_visible(true)
	--fo_Aux[fo_id][fcw[fo_id].ChatHead]:set_visible(true)
	-- local prevChatHead = fcw[fo_id].ChatHead + 1
	-- if prevChatHead > allSettings.ChatLines then prevChatHead = 1 end
	-- fo_Chat[fo_id][prevChatHead]:set_opacity(1)
	-- fo_Aux[fo_id][prevChatHead]:set_opacity(1)
	
end

function SetChatOpacity(opacity, fo_id)
--	if callID and callID ~= fcw[fo_id].OpacityBusy then return end
	for C_i = 1, #fo_Chat[fo_id] do
		fo_Chat[fo_id][C_i]:set_opacity(opacity)
		fo_Aux[fo_id][C_i]:set_opacity(opacity)
	end
end

function FixAux(fo_id, ChatLines)
	if not ChatLines then ChatLines = allSettings.ChatLines end
	--Debug('FixAux'..fo_id,1,true)
	--Debug('Redo'..fo_id,1,true) 
	for C_i = 1, ChatLines do
		if #fo_Aux[fo_id][C_i].settings.text > 0 then
			fo_Chat[fo_id][C_i]:set_visible(true);
			fo_Chat[fo_id][C_i]:set_opacity(1);
			if fo_Chat[fo_id][C_i].rect == nil  or fo_Chat[fo_id][C_i].is_dirty then return end
			fo_Aux[fo_id][C_i]:set_position_x(math.floor(fcw[fo_id].Anchor_X+fo_Chat[fo_id][C_i].rect.right+allSettings.fontSettings.font_height/1.7));
			fo_Aux[fo_id][C_i]:set_visible(true)
			fo_Aux[fo_id][C_i]:set_opacity(1);
		end
	end
	--Debug('FixAux Done'..fo_id,1,true)
	fcw[fo_id].RequestAuxFix = false;
end

function UpdateLines(fo_id, message, color, auxMessage, auxColor, ChatLines)
	fcw[1].BufferBusy = true;
	if not ChatLines then ChatLines = allSettings.ChatLines end
	local L_i = fcw[fo_id].ChatHead;
	for C_i = 1, ChatLines-1 do
		fo_Chat[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*(C_i)));
		fo_Aux[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*(C_i)));
		L_i = L_i +1;
		if (L_i > ChatLines) then L_i = 1; end 
	end
	if fo_Chat[fo_id][L_i].settings.font_color ~= color then
		fo_Chat[fo_id][L_i]:set_font_color(color);
	end
	--if fo_Chat[fo_id][L_i].rect ~= nil then fcw[1].LastRectRight = fo_Chat[fo_id][L_i].rect.right end
	fo_Chat[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y );
	fo_Aux[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y );
	fo_Chat[fo_id][L_i]:set_text(message:trimex());
	fo_Aux[fo_id][L_i]:set_font_color(auxColor);
	fo_Aux[fo_id][L_i]:set_text(auxMessage:trimex());--..utf8.char(0x00A0)
	fo_Aux[fo_id][L_i]:set_visible(false);
	fo_Chat[fo_id][L_i]:set_visible(false);
	fo_Chat[fo_id][L_i]:set_opacity(1)
	fo_Aux[fo_id][L_i]:set_opacity(1)
	fcw[fo_id].ChatHead = fcw[fo_id].ChatHead-1;
	if (fcw[fo_id].ChatHead < 1) then fcw[fo_id].ChatHead = ChatLines; end 

	
	return
end

function ShowBigMode(show)
	ro_BigMode:set_visible(show)
	fo_BigMode:set_visible(show)
	for C_i = 1, fcw[3].ChatLines do
		if fo_Chat[3][C_i] then fo_Chat[3][C_i]:set_visible(show) end
		if fo_Aux[3][C_i] then fo_Aux[3][C_i]:set_visible(show) end
	end
end

function DrawBigMode()
		--b_ChatBufferIdx[3] = b_ChatBufferIdx[1]
	-- if not allSettings.BigModeWarning[1] then
		-- AddWarning('This feature is not optimized!\n\nIt should be used mainly to review chat history.\n\nIt will cause stuttering if kept open on combat logs during a fight.',280, allSettings.BigModeWarning)
	-- end
	-- local ostime = tostring(os.time())
	-- print(string.rep('O',tonumber(ostime[#ostime])))
	ResetAutoHideTimer()
	--ro_BigMode:set_visible(true)
	local dsize = imgui.GetIO().DisplaySize;
	
	fcw[3].Anchor_X = fcw[1].Anchor_X
	fcw[3].Anchor_Y = fcw[1].Anchor_Y
	fcw[3].Anchor_X = dsize.x * 0.1
	fcw[3].Anchor_Y = dsize.y * 0.9
	
	---local buff_idx = 1;
	--b_ChatBufferIdx[1] =
	local ChatLines = fcw[3].ChatLines
	--print(fcw[3].Scrolling)and not fcw[3].Scrolling
	if not fcw[3].BigModePrev then
		if #fo_Chat[3] > 0  then
			--ResetLines(3, ChatLines)
			--b_ChatBufferIdx[3] = 0
			--b_ChatBufferIdx[3] = b_ChatBufferN[1]
			--b_ChatBufferIdx[3] = b_ChatBufferIdx[3]-1
		else
			--b_ChatBufferIdx[3] = (b_ChatBufferN[1]-b_ChatBufferIdx[3])
			--print(b_ChatBufferIdx[3])
			
			--print((b_ChatBufferN[1]-b_ChatBufferIdx[3]))
			--b_ChatBufferIdx[3] = b_ChatBufferIdx[1]
		end
	else
		
	end
	
	--Debug(tostring(b_ChatBufferIdx[3]), 1, false)
	if #fo_Chat[3] == 0 then
		
		--print('h')
		for L_i = 1, ChatLines do
			table.insert(fo_Chat[3], gdi:create_object(allSettings.fontSettings, false));
			table.insert(fo_Aux[3], gdi:create_object(allSettings.fontSettings, false));

			fo_Chat[3][L_i]:set_font_height(allSettings.fontSettings.font_height);
			fo_Aux[3][L_i]:set_font_height(allSettings.fontSettings.font_height);
			fo_Chat[3][L_i]:set_position_x(fcw[3].Anchor_X);
			fo_Chat[3][L_i]:set_position_y( fcw[3].Anchor_Y - (allSettings.fontSettings.font_height * (L_i-1)));
			if (fo_Chat[3][L_i].rect ~= nil) then 
				fo_Aux[3][L_i]:set_position_x(fcw[3].Anchor_X+fo_Chat[3][L_i].rect.right); 
			else
				fo_Aux[3][L_i]:set_position_x(fcw[3].Anchor_X);
				fo_Aux[3][L_i]:set_visible(false)
			end
			fo_Aux[3][L_i]:set_position_y( fcw[3].Anchor_Y - (allSettings.fontSettings.font_height * (L_i-1))); 
		end
		
	end
	--fo_Aux[1][L_i]:set_position_y( fcw[1].Anchor_Y - (allSettings.fontSettings.font_height * (L_i-1))); 
	
	
	
	ro_BigMode:set_fill_color(allSettings.rectSettings.fill_color);
	ro_BigMode:set_width(allSettings.chatLineMaxL*allSettings.fontSettings.font_height*0.58);
	--ro_BigMode:set_height(dsize.y*0.8 + allSettings.fontSettings.font_height + (allSettings.fontSettings.font_height/5));
	ro_BigMode:set_height(allSettings.fontSettings.font_height*(ChatLines+1) + (allSettings.fontSettings.font_height/5));
	
	--adjust = 88/dsize.y
	ro_BigMode:set_position_x(fcw[3].Anchor_X)
	ro_BigMode:set_position_y(dsize.y- fcw[3].Anchor_Y + allSettings.fontSettings.font_height-(allSettings.fontSettings.font_height-fcw[3].HLeft))
	
	fo_BigMode:set_position_x(fcw[3].Anchor_X)
	fo_BigMode:set_position_y(dsize.y- fcw[3].Anchor_Y + allSettings.fontSettings.font_height-(allSettings.fontSettings.font_height-fcw[3].HLeft))
	fo_BigMode:set_text('Big Mode: ['..allSettings.SelectedTab:gsub('AllAlt','All')..']')

	imgui.SetNextWindowSize({ fcw[3].BG_W, ro_BigMode.settings.height+16 }, ImGuiCond_None);
	
	--imgui.SetNextWindowPos({ fcw[3].Anchor_X, fcw[3].Anchor_Y-fcw[3].BG_H -16 }, ImGuiCond_None);
	
	--imgui.SetNextWindowPos({ fcw[1].Chat1WindowPosX, fcw[1].Chat1WindowPosY + 16 - ((ChatLines - allSettings.ChatLines+1)*allSettings.fontSettings.font_height) }, ImGuiCond_None);
	local adjust = dsize.y/88
	imgui.SetNextWindowPos({ fcw[3].Anchor_X-2, fcw[3].Anchor_Y - adjust - ((ChatLines )*allSettings.fontSettings.font_height) }, ImGuiCond_None);
	--imgui.SetNextWindowSizeConstraints({ fcw[3].BG_W, ro_BigMode.settings.height+16 }, { FLT_MAX, FLT_MAX, }, ImGuiCond_None);
	
	if imgui.Begin('FancyChat_BigModeBG_'+fcw[1].PlayerName, true, bit.bor(fcw[1].windowFlagsChatBG, ImGuiWindowFlags_NoMove)) then
	--if imgui.Begin('FancyChat_BigModeBG_'+fcw[1].PlayerName, true, 0) then
	-- Setting variables to position the chat window elements --
		
		
		local positionStartX, positionStartY = imgui.GetCursorScreenPos();
		--positionStartX = positionStartX + allSettings.WindowPosOffset[1];
		--positionStartY = positionStartY + allSettings.WindowPosOffset[2];
		
		

		local centerPosX = (fcw[3].BG_W/2 + positionStartX-3);
		local centerPosY = (ro_BigMode.settings.height/2 + positionStartY)+3;
		local imageSizeX = (fcw[3].BG_W/2);
		local imageSizeY = ro_BigMode.settings.height/2;
		
		local scrollOffset= (fcw[3].BG_H/120);

		local mouseX, mouseY = imgui.GetMousePos();
		
		if IsRectHovered(ro_BigMode.settings,0) then
			fcw[3].HoverLine = -1;
			local parsedUrl = '';
			--local lineOffsetBase = (allSettings.fontSettings.font_height)*(2900/dsize.y)
			--local lineOffsetBase = (fcw[3].HLeft)+(allSettings.fontSettings.font_height+10)
			local lineOffsetBase = (fcw[3].BG_H/120)+(allSettings.fontSettings.font_height)
			for HL_i = 0, ChatLines-1 do
				local lineOffset= lineOffsetBase+HL_i*allSettings.fontSettings.font_height;
				local highlight_alpha = 0;
				local targetLine = ChatLines-HL_i+fcw[3].ChatHead-1; if targetLine > ChatLines then targetLine = targetLine - ChatLines end
				--Debug(targetLine,1,false)
				if (fo_Aux[3][targetLine].settings.visible and fo_Aux[3][targetLine].settings.text == '[link]' and
					fo_Chat[3][targetLine].rect ~= nil and fo_Aux[3][targetLine].rect~= nil and 
					mouseX >  fo_Aux[3][targetLine].settings.position_x and mouseX < fo_Aux[3][targetLine].settings.position_x + fo_Aux[3][targetLine].rect.right and
					mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+allSettings.fontSettings.font_height
					and not fcw[1].Dragging
					)
				then --b_msgID
					if (fo_Aux[3][targetLine] ~= nil) then
						fo_Aux[3][targetLine]:set_font_color(0xFFCCEEFF);
						fcw[3].HoverLine = ChatLines-HL_i;
						local ChatHoverIdx = utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].url)-fcw[3].HoverLine-fcw[3].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[3])+1;
						--Debug(tostring(ChatHoverIdx)..'-'..b_ChatBuffer[b_ChatBufferMode][2].text[ChatHoverIdx],2,false);
						if ChatHoverIdx > 0 then
							--parsedUrl = utils.ParseUrlLink(b_ChatBuffer[b_ChatBufferMode][2].text[ChatHoverIdx]);
							--Debug(tostring(b_ChatBuffer[b_ChatBufferMode][2].url[ChatHoverIdx]), 2, false);
							
							if imgui.IsMouseClicked(ImGuiMouseButton_Left) then
								local urlText = utils.stringsplit(b_ChatBuffer[b_ChatBufferMode[1]][2].url[ChatHoverIdx],'|')
								ashita.misc.open_url(string.find(urlText[2], 'https://') and urlText[2] or 'https://'..urlText[2]);
								--print(b_ChatBuffer[b_ChatBufferMode[1]][2].url[ChatHoverIdx])
							end
						end
						fcw[3].HoverLine = -1;
					end
						--break
				else
					--print(fo_Aux[1][targetLine])
					--Debug(tostring(fo_Aux[1][targetLine]),1,false)
					if (fo_Aux[3][targetLine]~= nil and fo_Aux[3][targetLine].settings.text == '[link]') then
						fo_Aux[3][targetLine]:set_font_color(0xFF44CCFF);--0xFF44CCFF
					--	print('h')
					end
					if (mouseX > fcw[3].Anchor_X and mouseX < fcw[3].Anchor_X+fcw[3].BG_W and
					mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+allSettings.fontSettings.font_height and
					imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly)
					)
					then
						--local targetLine = 8-HL_i+fcw[1].ChatHead-1; if targetLine > 8 then targetLine = targetLine -8 end
						--dw_TestMessage = tostring(targetLine)..'-'..tostring(fo_Chat[1][targetLine] ~= nil);
						--if fo_Chat[1][targetLine] ~= nil then Debug(fo_Chat[1][targetLine].settings.text, 1, false); end
						
						fcw[3].HoverLine = ChatLines-HL_i;
						highlight_alpha = 0.3;
						imgui.GetWindowDrawList():AddRectFilledMultiColor({fcw[3].Anchor_X, positionStartY+lineOffset}, {fcw[3].Anchor_X+imageSizeX, (positionStartY+lineOffset+allSettings.fontSettings.font_height)},
						imgui.GetColorU32({ 1.0, 1.0, 1.0, highlight_alpha }),
						imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.0 }),
						imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.0 }),
						imgui.GetColorU32({ 1.0, 1.0, 1.0, highlight_alpha })
						);
						--break
					end
				end
				
			end
			
		end 
		
		if (fcw[3].HoverLine > 0 and imgui.IsMouseClicked(ImGuiMouseButton_Left)) then fcw[3].Clicking = true; end
		
		if (fcw[3].HoverLine > 0  and imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly)) then
			
			local copyBufferIdx = utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text)-fcw[3].HoverLine-fcw[3].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[3])+1;
			--Debug(tostring(copyBufferIdx),1,false) 
			local copyBufferText = '';
			if (copyBufferIdx > 0 ) then
			local ID = b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx]
			local IDs = 0
			local IDe = 0
			while b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx+IDs] and
				--type(b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx+IDs])=="number" and
				b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx+IDs] == ID do
				IDs = IDs - 1
			end
			while b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx+IDe] and
				--type(b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx+IDe])=="number" and
				b_ChatBuffer[b_ChatBufferMode[1]][2].url[copyBufferIdx+IDe]	== ID do
				IDe = IDe + 1
			end
			--print(IDs+1) print(IDe-1)
			local IDi = math.min(IDs+1,0)
			--print(IDi) print(math.max(IDe-1,0))
			while IDi <= math.max(IDe-1,0) do
				--copyBufferText = b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] ~= '[link]' and copyBufferText..b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] or copyBufferText..b_ChatBuffer[b_ChatBufferMode[1]][2].text[copyBufferIdx+IDi]
				--
				if b_ChatBuffer[b_ChatBufferMode[1]][2].text[copyBufferIdx+IDi] then
					copyBufferText = (' '..copyBufferText..b_ChatBuffer[b_ChatBufferMode[1]][2].text[copyBufferIdx+IDi]):trimex()
					if b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] ~= '[link]' then
						copyBufferText = copyBufferText..' '..b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi]
					end
				else
					break
				end
				IDi = IDi + 1;
			end
			end
			
			copyBufferText = utils.cleanMC(copyBufferText)
			--print(copyBufferText)
			if (fcw[3].Clicking and imgui.IsMouseReleased(ImGuiMouseButton_Left)) then
			fcw[3].Clicking = false;
				if(copyBufferText ~=nil) then
					if imgui.GetIO().KeyShift then
						if #allSettings.Notes < 10 and #copyBufferText > 0 then
							table.insert(allSettings.Notes, copyBufferText)
							SaveSettings();
						end
					else
						utils.SetClipboardText(utils.RevertShiftJIS(copyBufferText))
						AshitaCore:GetChatManager():QueueCommand(1, "/echo Text successfully copied to clipboard!");
					end
				end
			end
		end
	
		if (fcw[3].Clicking and (imgui.IsMouseDragging(ImGuiMouseButton_Left) or not imgui.IsMouseDown(ImGuiMouseButton_Left) )) then fcw[3].Clicking = false; end
		
		
		
		
		--LINESCROLLS
		
		
		if (imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly) or gamepadButtons.enabled) and not fcw[1].BufferBusy
		then
			--if fcw[3].ScrollDelta > 0 then print('scroll!') end
			--if fcw[3].ScrollDelta > 0 then print(b_ChatBufferIdx[3]) end
			if (
				fcw[3].ScrollDelta > 0
				
				and utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text) - fcw[3].ScrolledBack - (b_ChatBufferN[1]-b_ChatBufferIdx[3]) > ChatLines
			)
			then
				--print('scroll!')
				if not imgui.GetIO().KeyShift or not fcw[3].Scrolling then
					fcw[1].ScrollDelta = 0;
					fcw[2].ScrollDelta = 0;
					fcw[3].ScrollDelta = 0;
					fcw[3].Scrolling = true;
					--print(fcw[3].Scrolling)
					fcw[3].ChatShift = allSettings.fontSettings.font_height
					fcw[3].ScrollUpRequest = true;
				elseif fcw[3].Scrolling then
					local currentIdx = #b_ChatBuffer[b_ChatBufferMode[1]][2].text - (b_ChatBufferN[1]-b_ChatBufferIdx[3]) - 1
					GoToLine(3,math.max(currentIdx-(fcw[3].ScrolledBack+5), ChatLines), currentIdx, ChatLines);
				end
			else
				if ( fcw[3].ScrollDelta < 0 and fcw[3].ScrolledBack > 0 ) 
				then
					if  not imgui.GetIO().KeyShift or not fcw[3].Scrolling then
						fcw[1].ScrollDelta = 0;
						fcw[2].ScrollDelta = 0;
						fcw[3].ScrollDelta = 0;
						fcw[3].Scrolling = true;
						fcw[3].ChatShift = allSettings.fontSettings.font_height
						fcw[3].ScrollDownRequest = true;
					elseif fcw[3].Scrolling then
						local currentIdx = #b_ChatBuffer[b_ChatBufferMode[1]][2].text - (b_ChatBufferN[1]-b_ChatBufferIdx[3]) - 1
						GoToLine(3,math.min(currentIdx-(fcw[3].ScrolledBack-5), currentIdx-1), currentIdx, ChatLines);
					end
				end
			end
			
		
		end
		fcw[3].ScrollDelta=0;
		
		
		if (imgui.IsMouseClicked(ImGuiMouseButton_Right)) then
			if fcw[1].ScrolledBack > 0 then
				ResetScrolling(1);
			end
			if fcw[2].ScrolledBack > 0 then
				ResetScrolling(2);
			end
			if fcw[3].ScrolledBack > 0 then
				ResetScrolling(3, ChatLines);
			end
		end
		imgui.End()
	end
	
	
	
	if (fcw[3].Scrolling and fcw[3].ScrollUpRequest) and not fcw[1].BufferBusy
	then
		fcw[3].ScrollUpRequest = false;
		ScrollLines(3,
			b_ChatBuffer[b_ChatBufferMode[1]][2].text[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text)-ChatLines-fcw[3].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[3])],
			b_ChatBuffer[b_ChatBufferMode[1]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text)-ChatLines-fcw[3].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[3])],
			b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text)-ChatLines-fcw[3].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[3])],
			b_ChatBuffer[b_ChatBufferMode[1]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text)-ChatLines-fcw[3].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[3])],
			1, ChatLines
		);
			
		fcw[3].ScrolledBack = fcw[3].ScrolledBack +1;
			--print('hello')
			--if fcw[1].ScrolledBack > utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode][2].text)-allSettings.ChatLines-(b_ChatBufferN-b_ChatBufferIdx) then fcw[1].ScrolledBack = fcw[1].ScrolledBack -1 end
		--b_ChatBufferIdx[3] = b_ChatBufferN[1]
	elseif (fcw[3].Scrolling and fcw[3].ScrollDownRequest) and not fcw[1].BufferBusy
	then 
		fcw[3].ScrollDownRequest = false;
		ScrollLines(3,
			b_ChatBuffer[b_ChatBufferMode[1]][2].text[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text)+1-fcw[3].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[3])],
			b_ChatBuffer[b_ChatBufferMode[1]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].color)+1-fcw[3].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[3])],
			b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].auxText)+1-fcw[3].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[3])],
			b_ChatBuffer[b_ChatBufferMode[1]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].auxColor)+1-fcw[3].ScrolledBack-(b_ChatBufferN[1]-b_ChatBufferIdx[3])],
			0, ChatLines
		);
		fcw[3].ScrolledBack = fcw[3].ScrolledBack -1;
		if fcw[3].ScrolledBack == 0 then
			--print('reset')
			fcw[3].Scrolling = false;
			ResetLines(3, ChatLines);
		end
		--b_ChatBufferIdx[3] = b_ChatBufferN[1]
	elseif not fcw[3].BigModePrev or (not fcw[3].Scrolling and b_ChatBufferIdx[3] < b_ChatBufferN[1]) then
		--ResetLines(3, ChatLines)
		--b_ChatBufferIdx[3] = b_ChatBufferN[1]
		--print('hello')
		--print(b_ChatBufferIdx[3])
		--print(fcw[3].BigModePrev)
		if  b_ChatBufferN[1] - b_ChatBufferIdx[3] > 0 then
			UpdateLines(3,
				b_ChatBuffer[b_ChatBufferMode[1]][2].text[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text) -(b_ChatBufferN[1]-b_ChatBufferIdx[3]-1)],
				b_ChatBuffer[b_ChatBufferMode[1]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text) -(b_ChatBufferN[1]-b_ChatBufferIdx[3]-1)],
				b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text) -(b_ChatBufferN[1]-b_ChatBufferIdx[3]-1)],
				b_ChatBuffer[b_ChatBufferMode[1]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text) -(b_ChatBufferN[1]-b_ChatBufferIdx[3]-1)],
				ChatLines
			);
			b_ChatBufferIdx[3] = b_ChatBufferIdx[3]+1
		else
			ResetLines(3, ChatLines)
		end
							--fcw[1].ChatShift = allSettings.fontSettings.font_height;
		--b_ChatBufferIdx[3] = b_ChatBufferIdx[3]+1;
		
	end
	
	fcw[3].RequestAuxFix = true
	--Debug(tostring(b_ChatBufferIdx[3]), 
	
	--ro_BigMode:set_visible(false)

end

function DestroyBigMode()
	
	--ro_BigMode = nil
	if fo_Chat[3] then fo_Chat[3] = T{} end
	if fo_Aux[3] then fo_Aux[3] = T{} end
end

function CleanText(text, mode)
	
	local addLog = true;
	--if not string.find(mode, '^combat') and not string.find(mode,'^combatspell') and
	if not string.find(mode,'^shout') and not string.find(mode,'^unity') and par_MessageMode ~= 152 and not string.find(mode, '^linkshell') then addLog = true; end
	
	if (par_MessageMode == 150 or par_MessageMode == 151) and par_LastMsgInConv then uiw.DialogPromptStart = os.clock(); end 
	if (par_MessageMode == 150 or par_MessageMode == 151)	then 
		if par_InEvent then
		
			par_LastMsgInConv = true;
			
		else
			par_LastMsgInConv = false;
		end
	end
	
	-- local cleantext = '';
	local cpString = {};
	
	for idx = 1, #text do
		table.insert(cpString, string.byte(string.sub(text,idx,idx)));
	end

	local dtest = '';
	for d = 1, #text do
		
		dtest = dtest..tostring(cpString[d])..','..string.sub(text,d,d)..'|';
		
	end

	if addLog then table.insert(b_LogBuffer, 'Char-Int match: '..dtest); end

	-- if not string.find(mode, 'combat') or par_MessageMode == 80 or not allSettings.CompactCombat[1] then

		-- intString = utils.ReplaceInts(intString);
		-- intString = utils.CleanInts(intString);
	-- else
		-- table.remove(intString,#intString)
		
	-- end
	
	-- if intString[#intString] == 10 then table.remove(intString, #intString); end
	
	if (#cpString) > 0 then
		-- cleanInts = {}
		-- cleantext = utils.int2text(intString, utils.UTF8chars)
		-- for a = 1, #cleantext do
		
			-- table.insert(cleanInts, string.byte(cleantext[a]));
	
		-- end
		 if addLog then table.insert(b_LogBuffer, text); end
	
		 if addLog then table.insert(b_LogBuffer, 'Mode: '..mode..' Channel: '..tostring(par_MessageMode)); end
		if addLog then table.insert(b_LogBuffer, '----------'); end
		
		-- if allSettings.heartEmoji[1] then cleantext = string.gsub(cleantext, '<3', utf8.char(0x2764)); end

	end
	
	if #b_LogBuffer > 100 then
		for _ = 1, 4 do
			table.remove(b_LogBuffer,1);
		end
	end
	if not string.find(mode, 'combat') or par_MessageMode == 80 or not allSettings.CompactCombat[1] then
		while (true) do
			local hasN = text:endswith('\n');
			local hasR = text:endswith('\r');

			if (not hasN and not hasR) then
				break;
			end

			if (hasN) then text = text:trimend('\n'); end
			if (hasR) then text = text:trimend('\r'); end
		end
		text = text:strip_colors()
		local cpString = {};
		local cleantext
		for idx = 1, #text do
			table.insert(cpString, string.byte(string.sub(text,idx,idx)));
		end
		--local debugString = ''
		--for ds = 1, #intString do
		--	 debugString = debugString..' 0x'..bit.tohex(intString[ds])
		--end
		--Debug(tostring(#intString),1,true)
		cpString = utils.ReplaceCPs(cpString);
		--Debug(tostring(#intString),1,true)
		cpString = utils.CleanCPs(cpString);
		--Debug(tostring(#intString),1,true)
		cleantext = utils.CPs2text(cpString, utils.UTF8chars)
		--Debug(tostring(#cleantext),1,true)
		text = cleantext:trimex()
		if allSettings.heartEmoji[1] then text = string.gsub(text, '<3', utf8.char(0x2764)); end
	else
		
		if text:sub(-2,-1) == '\127\49' then
			text = text:sub(0, -3)
		end
		--text = AshitaCore:GetChatManager():ParseAutoTranslate(text, true);

		text = text:strip_colors();
		text = text:gsub('\32\171','\32')
		text = text:gsub('\129\168','')
		
	end
	return text
	--return cleantext:trimex();
end

-- function ResetColors()
	-- --allSettings.defaultColor = T{1,1,1,1};
	-- local a, r, g, b;
	-- local done = 0x00000000;
	-- local i = 1;
	-- while bit.bxor(done,0xFFFFFFFF) ~= 0 and i <= #utils.modesDA do
		-- if bit.band(0x0000000F, done) == 0 and string.find(utils.modesDA[i][2], 'linkshell1') then
			-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			-- allSettings.linkshellColor = T{r/255,g/255,b/255,a/255};
			-- done = bit.bor(0x0000000F, done)
		-- end
		-- if bit.band(0x000000F0, done) == 0 and string.find(utils.modesDA[i][2], 'linkshell2') then
			-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			-- allSettings.linkshell2Color = T{r/255,g/255,b/255,a/255};
			-- done = bit.bor(0x000000F0, done)
		-- end
		-- if bit.band(0x00000F00, done) == 0 and string.find(utils.modesDA[i][2], 'party') then
			-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			-- allSettings.partyColor = T{r/255,g/255,b/255,a/255};
			-- done = bit.bor(0x00000F00, done)
		-- end
		-- if bit.band(0x0000F000, done) == 0 and string.find(utils.modesDA[i][2], 'tell') then
			-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			-- allSettings.tellColor = T{r/255,g/255,b/255,a/255};
			-- done = bit.bor(0x0000F000, done)
		-- end
		-- if bit.band(0x000F0000, done) == 0 and string.find(utils.modesDA[i][2], 'shout') then
			-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			-- allSettings.shoutColor = T{r/255,g/255,b/255,a/255};
			-- done = bit.bor(0x000F0000, done)
		-- end
		-- if bit.band(0x00F00000, done) == 0 and string.find(utils.modesDA[i][2], 'emote') then
			-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			-- allSettings.emoteColor = T{r/255,g/255,b/255,a/255};
			-- done = bit.bor(0x00F00000, done)
		-- end
		-- if bit.band(0x0F000000, done) == 0 and string.find(utils.modesDA[i][2],'combat_') then
			-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			-- allSettings.combatColor = T{r/255,g/255,b/255,a/255};
			-- done = bit.bor(0x0F000000, done)
		-- end
		-- if bit.band(0xF0000000, done) == 0 and string.find(utils.modesDA[i][2], 'combatspell_') then
			-- --print(tostring(i)..'.'..tostring(bit.tohex(utils.modesDA[i][3])))
			-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			-- allSettings.combatspellColor = T{r/255,g/255,b/255,a/255};
			-- done = bit.bor(0xF0000000, done)
		-- end
		-- i = i+1;
	-- end
		-- --a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(0xFFF7CF05)));
		-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(0xFFFFFFFF)));
		-- allSettings.dmgColor = T{r/255,g/255,b/255,a/255};
		
		-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(allSettings.ColorBlind[1] and 0xFF91FFF0 or 0xFF91FF47)));
		-- allSettings.dmgDoneColor = T{r/255,g/255,b/255,a/255};
		
		-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(allSettings.ColorBlind[1] and 0xFFFFA269 or 0xFFFA4343)));
		-- allSettings.dmgGotColor = T{r/255,g/255,b/255,a/255};
		
		-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(0xFFF0FFF0)));
		-- allSettings.spelldmgColor = T{r/255,g/255,b/255,a/255};
		
		-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(allSettings.ColorBlind[1] and 0xFF5EE0DE or 0xFFADFF33)));
		-- allSettings.spelldmgDoneColor = T{r/255,g/255,b/255,a/255};
		
		-- a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(allSettings.ColorBlind[1] and 0xFFE6874C or 0xFFFC2B43)));
		-- allSettings.spelldmgGotColor = T{r/255,g/255,b/255,a/255};
	
-- end

function PushColorStyles(styles)
	for _, s in pairs(styles) do
		imgui.PushStyleColor(s[1], s[2]);
	end
end

function PopColorStyles(styles)
    for _ in pairs(styles) do
		imgui.PopStyleColor();
	end
end

local combatCP = 
{
	--RA 		= 	utf8.char(0x27B6),
	RA 		= 	utils.icons.RA,
	COL		= 	utf8.char(0x589),
	--USE		= 	utf8.char(0x1F4A2),
	USE		= 	utf8.char(0x1F4AB),
	--PUM		= 	utf8.char(0x2316),
	PUM		= 	utils.icons.PUM,
	CRIT	= 	utf8.char(0x1F4A5),
	ATK 	=	utf8.char(0x1F5E1),
	SC  	=	utils.icons.SC,
	--ATK 	=	utils.icons.ATK,
	--LEFT	= 	utf8.char(0x25C0),
	LEFT	= 	utf8.char(0x1F81C),
	--RIGHT	= 	utf8.char(0x25B6),
	RIGHT	= 	utf8.char(0x1F81E),
	SPLIT	= 	utf8.char(0x1F81E),
	--PARR	= 	utf8.char(0x2694),
	PARR	= 	utils.icons.PARR,
	CNTR	= 	utf8.char(0x2B8C),
	KILL	= 	utf8.char(0x2717),
	--CAST	= 	utf8.char(0x1F300),
	CAST	= 	utils.icons.CAST,
	--SPELL	= 	utf8.char(0x2727),
	SPELL	= 	utils.icons.SPELL,
	--HEAL	= 	utf8.char(0x2728),
	HEAL	= 	utils.icons.HEAL,
	SUB 	= 	utf8.char(0x2514)..utf8.char(0x2500),
}

--e9d2 dice? 
--eb09 CE?
--e95e treasure
--e70b heal

function CombatText(msg, chn)
	
	--	U+269F 
	
	--local ES = allSettings.extraspace[1] and ' ' or ''
	local A = '';
	local B = '';
	local DMG = '';
	local S = '';
	local T = '';
	local Ext = '';
		
	if msg:find('hit') then
		A, B, DMG = msg:match("^(.*) hits? (.*) for (%d*) points? of damage%.$")
		
		if A and B and DMG then
			local ra = ''
			if msg:find('ranged attack') then
				A = A:gsub('\'s ranged attack','')
				B = B:gsub('\'s ranged attack','')
				--ra = ' [R.Atk]'
				--ra = ' '..utf8.char(0x27B6)
				ra = ' '..combatCP.RA
			end
			-- if not A:find('^[Tt]he') then par_actor1 = A else
				-- A = A:gsub('[Tt]he ', ''); par_actor2 = A;
			-- end
			-- if not B:find('^[Tt]he') then
				
				-- if #par_actor1 == 0 then
					-- par_actor1 = B
				-- else
					-- par_actor2 = B
				-- end
			-- else
				-- B = B:gsub('[Tt]he ', '');
				-- par_actor2 = B
			-- end
			--Debug(tostring(#par_party_names), 1, true)
			
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '')--:gsub('ranged attack', 'RA');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '')--:gsub('ranged attack', 'RA');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			
			
			--msg = A..' '..utf8.char(0x25B6)..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG'..ra;
			--msg = A..' '..(#ra > 0 and ra or combatCP.ATK)..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG';
			msg = A..' '..(#ra > 0 and ra or combatCP.ATK)..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG';
			--msg = A..' '..(#ra > 0 and ra or combatCP.ATK)..' '..DMG..' DMG '..combatCP.SPLIT..' '..B;
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			
			par_isDamage = true;
	--		Debug('par_actor1: '..par_actor1,1,true)
	--		Debug('par_actorP: '..par_actorP,1,true)
	--		Debug('par_actor2: '..par_actor2,1,true)
	--		Debug('par_actorE: '..par_actorE,1,true)
			par_CombatCutIdx = utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			
			return msg
		end
	end

	if msg:find('score') then
		A, B, DMG = msg:match("^(.*) scores? a critical hit! (.*) takes? (%d*) points? of damage%.$")
		if A and B and DMG then
			local ra = ''
			if msg:find('ranged attack') then
				A = A:gsub('\'s ranged attack','')
				B = B:gsub('\'s ranged attack','')
				--ra = ' [R.Atk]'
				ra = combatCP.RA
			end
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			-- if not A:find('^[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			-- if not B:find('^[Tt]he') then B = '['..ES..B..ES..']' else
			-- B = B:gsub('[Tt]he ', '');
			-- end
			
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end

			--msg = A..' '..utf8.char(0x25B6)..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG '..ra..utf8.char(0x23eb);
			msg = A..' '..(#ra > 0 and ra or combatCP.ATK)..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG '..combatCP.CRIT;
			par_isDamage = true;
			--msg = msg:gsub('ranged attack', 'RA');
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg;
		end
	end
	
	if msg:find('ranged attack') then
		A, Ext = msg:match('^(.*)(%\'s.*)$')
		if Ext:find('miss') then
			if (A == fcw[1].PlayerName) then par_DamageGot = true; end;
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			msg = A..' '..combatCP.SPLIT..' Miss '..combatCP.RA--' Miss [R.Atk]';
			par_isDamage = true;
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg;
		elseif Ext:find('pummeling') then
			B, DMG = Ext:match('^.*pummeling (.*) for (.*) points of damage!$')
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '')--:gsub('ranged attack', 'RA');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '')--:gsub('ranged attack', 'RA');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			
			
			--msg = A..' '..utf8.char(0x25B6)..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG '..utf8.char(0x27B6)..utf8.char(0x2316);
			msg = A..' '..combatCP.RA..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG '..combatCP.PUM;
			par_isDamage = true;
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			par_isDamage = true;
			
			par_CombatCutIdx = utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg
		end
	end	
	--Debug(tostring(A)..'-'..tostring(B)..'-'..tostring(DMG),1,true)
		--\Â§FFFFFFFFÃ§\[23:47]\Â§--------Ã§\ Snuggle's ranged attack strikes true, pummeling the Land Crab for 20 points of damage! 
		--\Â§FFFFFFFFÃ§\[23:59]\Â§--------Ã§\ Snuggle's ranged attack misses. 
	
	if msg:find('use') then
		A, S, B, DMG = msg:match("^(.*) uses? (.*)%.%s*(.*) takes? (%d*) points? of damage%.$")
		if A and B and S and DMG then
		
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			-- if not A:find('^[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			-- if not B:find('^[Tt]he') then B = '['..ES..B..ES..']' else
			-- B = B:gsub('[Tt]he ', '');
			-- end
			
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			S = '\\'..S..'/'..combatCP.COL
			par_action1 = S;
			
			--msg = A..' '..utf8.char(0x25B6)..' '..B..' '..combatCP.SPLIT..' ['..S..']'..utf8.char(0x589)..' '..DMG..' DMG';
			msg = A..' '..combatCP.USE..' '..B..' '..combatCP.SPLIT..' '..S..' '..DMG..' DMG';
			par_isDamage = true;
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg;
		end


		A, S, Ext = msg:match("^(.*) uses? ([^%.]*)%.%s*(.*)$")
		if A and S and not msg:find('damage', #A) and not msg:find('miss', #A)  and not msg:find('^You must') and not msg:find('lacks the') and not msg:find('^You are') and not msg:find('Unable to') and not msg:find('cannot') then
			--Debug(A,1,true)
			--if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			-- --if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if Ext and Ext:trimex() ~= '' then
				--Everoth uses Double-Up. The total for Chaos Roll increases to 7! Everoth receives the effect of Chaos Roll
				Ext = Ext:gsub('receives the effect of', combatCP.LEFT)
				Ext = Ext:gsub('gains the effect of', combatCP.LEFT)
				Ext = Ext:gsub('is afflicted with', combatCP.LEFT)
				Ext = Ext:gsub(' increases to', ':')
				Ext = Ext:gsub('The total for ', '')
				Ext = Ext:gsub('Treasure Hunter effectiveness against','TH on')
				Ext = Ext:gsub('successfully (.)', function(c) return combatCP.RIGHT..' '..c:upper() end)
				Ext = ': '..Ext..' '
			else
				Ext = ''
			end
			--Debug(Ext,1,true)
			-- if not A:find('^[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			S = '\\'..S..'/'
			par_action1 = S;
			
			
			--plague
			--msg = Ext..A..' '..utf8.char(0x25B6)..' ['..S..']';
			--The Miter Worm casts Stonega. August takes 23 points of damage.
			--OLD message
			--msg = Ext..A..' '..combatCP.RIGHT..' '..S..' ';
			--par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.RIGHT)+string.len(combatCP.RIGHT)-1;
			
			msg = A..' '..combatCP.RIGHT..' '..S..Ext;	
			
			par_CombatCutIdx =  utils.FindFirstOfMB(msg, combatCP.RIGHT)+string.len(combatCP.RIGHT)-1;
			
			return msg;
		end
	end
	
	if msg:find('Skillchain') then
		S, A, DMG = msg:match("^(Skillchain: [^%.]*)%.%s(.*) takes? (%d*) points? of damage%.$")
		if S and A and DMG then
			-- A = '['..ES..A..ES..']'
			-- A = A:gsub('[Tt]he ', '');
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			S = '\\'..S:gsub('Skillchain:','SC')..'/'--..combatCP.COL
			par_action1 = S;
			--msg = A..' '..utf8.char(0x25C0)..' ['..S:gsub('Skillchain:','SC')..']'..utf8.char(0x589)..' '..DMG..' DMG';
			--msg = A..' '..utf8.char(0x25C0)..' '..S..' '..utf8.char(0x589)..' '..DMG..' DMG';
			--msg = A..' '..combatCP.LEFT..' '..S..' '..DMG..' DMG';
			msg = S..' '..combatCP.SC..' '..A..' '..combatCP.RIGHT..' '..DMG..' DMG';
			par_isDamage = true;
			--par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.LEFT)+string.len(combatCP.LEFT)-1;
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.RIGHT)+string.len(combatCP.RIGHT)-1;
			return msg;
		end
	end
	-- [00:27:39] Eleanor takes 175 points of damage.â¯28
	--[00:29:08] Zeid takes 161 points of damage.â¯32
	--[00:31:31] yYou do not meet the requirements to obtain the monk's testimony. Monk's testimony lost.â¯121
	
	if msg:find('take') then
		A, DMG = msg:match("^([^%.]+) takes? (%d*) points? of damage%.$")
		if A and DMG then
			--if A:find('^[Tt]he ') then A = A:gsub('[Tt]he ',' ') else A = '['..ES..A..ES..']' end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			
			msg = combatCP.SUB..A..' '..combatCP.LEFT..' '..DMG..' DMG';
			par_isDamage = true;
			if (A == fcw[1].PlayerName) then par_DamageGot = true; end;
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.LEFT)+string.len(combatCP.LEFT)-1;
			return msg;
		end
	end

	if msg:find('Additional') then
		S = msg:match("^Additional effect: (.*)%..*$")
		if S then
		--\Â§FFFFFFFFÃ§\[11:05]\Â§--------Ã§\ â””â”€ Add.E. >\Â§FFF0FEFFÃ§\ \Â§FFF3A6FFÃ§\[TH effectiveness against the Strolling Sapling : 2.]\Â§FFF0FEFFÃ§\\Â§--------Ã§\ 
			S = S:gsub('additional ','')
			S = S:gsub('drained from .*','drained')
			S = S:gsub('Treasure Hunter effectiveness against','TH on')
			S = S:gsub(' increases to', combatCP.COL)
			S = S:gsub('[Tt]he ','')
			S = S:gsub('%.','')
			S = S:gsub('points? of damage','DMG')
			S = '\\'..S..'/'
			par_action1 = S;
			msg = combatCP.SUB..'Add.E. '..combatCP.SPLIT..' '..S..' ';
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg;
		end
	end

	if msg:find('read') then
		A, S = msg:match("^(.*) read[%a]* (.*)%.$")
		if A and S then
			-- if not A:find('^[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			S = '\\'..S..'/'
			par_action1 = S;
			--msg = A..' '..combatCP.SPLIT..' readies...'..'['..S..']';
			msg = A..' '..combatCP.SPLIT..' readies...'..S..' ';
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg;
		end
	end	
	
	if msg:find('parr') then
		--[18:25] Eleanor parries the Drachenlizard's attack with her weapon. 
		A, B = msg:match("^(.*) parr[%a]* (.-)%p?s? attack.*%.$")
		if A and B then
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			-- if not A:find('[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			-- if not B:find('[Tt]he') then B = '['..ES..B..ES..']' else
			-- B = B:gsub('[Tt]he ', '');
			-- end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			--msg = B..' '..utf8.char(0x2694)..' '..A..' '..combatCP.SPLIT..' Parry ';
			msg = A..' '..'parry '..combatCP.PARR..' '..B..'\'s attack'--..combatCP.SPLIT..' Parry ';
			--par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			par_isDamage = true;
			par_CombatCutIdx =  utils.FindLastOfMB(msg, 'parry '..combatCP.PARR)-1;
			return msg;
		end
	end

	--Volker's attack is countered by the Sylvestre. Volker takes 17 points of damage.
	if msg:find(' attack is countered ') then
	
		B, A, DMG = msg:match("^(.-)'s%s.-by%s(.-)%..-takes%s(.-)%spoint.*$")
		if A and B and DMG then
			
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '')
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '')
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			
			
			--msg = A..' '..utf8.char(0x25B6)..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG '..utf8.char(0x2B8C);
			msg = A..' '..combatCP.CNTR..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG ';
			par_isDamage = true;
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			
			
			par_CombatCutIdx = utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			
			return msg
		end
	end
	
	if msg:find('miss') then
		--Tenzen uses Amatsu: Tsukioboro, but misses the Drachenlizard.
		--The Colibri uses Snatch Morsel, but misses Halver.
		--Tenzen misses the Drachenlizard...' '..B..' '
		A, B = msg:match("^(.*) miss[%a]* (.*)%.$")
		if A and B then
			local F = A:find(' use')
			local Ext = ''
			if F then Ext = A:sub(F,#A); A = A:sub(1,F-1); end
			if (B == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (A == fcw[1].PlayerName) then par_DamageGot = true; end;
			-- if not A:find('[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			-- if not B:find('[Tt]he') then B = '['..ES..B..ES..']' else
			-- B = B:gsub('[Tt]he ', '');
			-- end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			--utf8.char(0x25B6)' ['..c2..']. '
			--Ext = Ext:gsub('^( uses? )([^,]*)(.*)$', function(c1,c2,c3) return ' '..utf8.char(0x25B6)..' '..B end)
			Ext = Ext:gsub('^( uses? )([^,]*)(.*)$', function(c1,c2,c3) return c2 end) 
			if F then
				Ext = '\\'..Ext..'/'..combatCP.COL
				par_action1 = Ext
				Ext = ' '..Ext
			end
			msg = A..' '..combatCP.ATK..' '..B..' '..combatCP.SPLIT..Ext..' Miss';
			par_isDamage = true;
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg;
		end
	end	
		--Halver defeats the Drachenlizard. 
	    --Eleanor was defeated by the Goblin Tinkerer.
	if msg:find('defeat') then
		A, B = msg:match("^(.*) defeats? (.*)%.$")
		if A and B then
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			
			local defeat = 'defeats'..combatCP.KILL
			msg = A..' '..defeat..' '..B
			par_isDamage = true;
			par_CombatCutIdx =  msg:find(defeat,1,true)-1;
			return msg;
		end
		
		B, A = msg:match("^(.*) was defeated by (.*)%.$")
		if A and B then
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			
			local defeat = 'defeats'..combatCP.KILL
			msg = A..' '..defeat..' '..B
			par_isDamage = true;
			par_CombatCutIdx =  msg:find(defeat,1,true)-1;
			return msg;
		end
	end
	
	if msg:find('shadows') then
		--Rosabelle uses Animated Flourish on the Tchakka.65
		Ext, A = msg:match('^(%d*) of (.+)\'s shadows.*$')
		if A and Ext then
			
			
			Ext = '-'..Ext
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			if Ext == '0' then
				msg = 'None of '..A..'\'s shadows absorbs damage.' 
				par_CombatCutIdx =  utils.FindLastOfMB(msg, '\'')+string.len('\'')-1;
				return msg;
			end

			--msg = A..' '..combatCP.RIGHT..' '..Ext..' '..utils.icons.UTSU
			msg = A..' '..Ext..' '..utils.icons.UTSU
			if (A == fcw[1].PlayerName) then par_DamageGot = true; end;
			par_isDamage = true;		
			par_CombatCutIdx =  utils.FindLastOfMB(msg, '-')-1;
			return msg;
		end
	end	
	
	local c = 0
	msg, c = msg:gsub('(receives the effect of )([^%.]*)(%.)', function(c1, c2, c3) return combatCP.LEFT..' ['..c2..']' end)
	if c < 1 then
		msg, c = msg:gsub('(gains the effect of )([^%.]*)(%.)', function(c1, c2, c3) return combatCP.LEFT..' ['..c2..']' end)
	end
	if c < 1 then
		msg, c = msg:gsub('(is afflicted with )([^%.]*)(%.)', function(c1, c2, c3) return combatCP.LEFT..' ['..c2..']' end)
	end

	if c > 0 then
		if not msg:find('^[Tt]he') then
			msg = '['..msg:sub(1, msg:find(' ') - 1)..']'..msg:sub(msg:find(' '), #msg)
		else
			msg = msg:gsub('^[Tt]he ', '')
		end
	end
	
	if msg[1] == ' ' then msg = msg:replace(' ', '{?} ',1) end
	return msg;
end

function CombatSpellText(msg, chn)

	--local ES = allSettings.extraspace[1] and ' ' or ''
	local A = '';
	local B = '';
	local DMG = '';
	local S = '';
	local T = '';
	local Ext = '';
	
	if msg:find('start') then
		A, S = msg:match("^(.*) starts? casting (.*)%.$")
		if A and S then

			local on = S:find(' on ')
			if (on ~= nil) then
				B = S:sub(on+4, #S)
				S = S:sub(1, on-1)
			else
				B = '?';
			end
			--Debug(B,1,true)
			
			-- if not A:find('^[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			S = '\\'..S..'/'
			par_action1 = S;
			if B ~= '?' then
				-- if not B:find('^[Tt]he') then B = '['..ES..B..ES..']' else
				-- B = B:gsub('[Tt]he ', '');
				-- end
				------
				if utils.StringFindTable(B, par_party_names, nil, true) then
					if #par_actor1 > 0 then
						par_actorP = B;
					else
						par_actor1 = B;
					end
				else
					B = B:gsub('[Tt]he ', '');
					if #par_actor2 > 0 then
						par_actorE = B;
					else
						par_actor2 = B;
					end
				end
		--		Debug('par_actor1: '..par_actor1,1,true)
		--		Debug('par_actorP: '..par_actorP,1,true)
		--		Debug('par_actor2: '..par_actor2,1,true)
		--		Debug('par_actorE: '..par_actorE,1,true)
				--msg = A..' '..utf8.char(0x25B6)..' '..B..' '..combatCP.SPLIT..' casting...['..S..']';
				msg = A..' '..combatCP.CAST..' '..B..' '..combatCP.SPLIT..' casting...'..S..' ';
				
			else
				--msg = A..' '..combatCP.SPLIT..' casting...['..S..']';
				msg = A..' '..combatCP.SPLIT..' casting...'..S..' ';
			end
			
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg;
		end
	end
	
	if msg:find('cast') then
		A, S, B, DMG = msg:match("^(.*) casts? (.*)%. (.*) takes? (%d*) points? of damage%.$")
		--Debug(tostring(A)..'-'..tostring(S)..'-'..tostring(B)..'-'..tostring(DMG),1,true)
		if A and S and B and DMG then
		

			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			-- if not A:find('^[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			-- if not B:find('^[Tt]he') then B = '['..ES..B..ES..']' else
			-- B = B:gsub('[Tt]he ', '');
			-- end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			S = '\\'..S..'/'..combatCP.COL
			par_action1 = S;
			--msg = A..' '..utf8.char(0x25B6)..' '..B..' '..combatCP.SPLIT..' ['..S..']'..utf8.char(0x589)..' '..DMG..' DMG';
			msg = A..' '..combatCP.SPELL..' '..B..' '..combatCP.SPLIT..' '..S..' '..DMG..' DMG';
			par_isDamage = true;
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg;
		end
		
		--Mode: combat_p Channel:27Msg: The Thaumaturge casts Aspir. 0 MP drained from NanaaMihgo.
		--Mode: combat_p Channel:27Msg: TheThaumaturge casts Drain. 0 HP drained from NanaaMihgo.
		
		A, S, DMG, T, B = msg:match("^(.*) casts? ([^%.]*)%. (%d*) (.*) drained from (.*)%.$")
		--Debug(tostring(A)..'-'..tostring(S)..'-'..tostring(B)..'-'..tostring(DMG),1,true)
		if A and S and B and DMG and T then
		
			
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			-- if not A:find('^[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			-- if not B:find('^[Tt]he') then B = '['..ES..B..ES..']' else
			-- B = B:gsub('[Tt]he ', '');
			-- end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			S = '\\'..S..'/'..combatCP.COL
			par_action1 = S;
			--msg = A..' '..utf8.char(0x25B6)..' '..B..' '..combatCP.SPLIT..' ['..S..']'..utf8.char(0x589)..' '..DMG..' '..T..' drained';
			msg = A..' '..combatCP.SPELL..' '..B..' '..combatCP.SPLIT..' '..S..' '..DMG..' '..T..' drained';
			par_isDamage = true;
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg;
		end
		
		--Mode: combatspell Channel:31Msg: Eleanor casts Cure IV. Eleanor recovers 398 HP.


		A, S, B, DMG, T = msg:match("^(.*) casts? ([^%.]*)%. (.*) recovers? (%d*) ([^%.]*)%.$")
		--Debug(tostring(A)..'-'..tostring(S)..'-'..tostring(B)..'-'..tostring(DMG),1,true)
		if A and S and B and DMG and T then
		
			if A == fcw[1].PlayerName or B == fcw[1].PlayerName then par_DamageDone = true; end;
			-- if not A:find('^[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			-- if not B:find('^[Tt]he') then B = '['..ES..B..ES..']' else
			-- B = B:gsub('[Tt]he ', '');
			-- end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			S = '\\'..S..'/'..combatCP.COL
			par_action1 = S;
			--msg = A..' '..utf8.char(0x25B6)..' '..B..' '..combatCP.SPLIT..' ['..S..']'..utf8.char(0x589)..' +'..DMG..' '..T;
			msg = A..' '..combatCP.HEAL..' '..B..' '..combatCP.SPLIT..' '..S..' +'..DMG..' '..T;
			par_isDamage = true;
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg;
		end
		
		--[15:41] Joachim casts Poisona. Joachim successfully removes Halver's poison. 
		--Eleanor casts Monomi: Ichi. Eleanor gains the effect of Sneak.
		--		--Rosabelle casts Raise on Zeratia.122
		if msg:find(' casts? ') and msg:find(' on ') then 
			A, S, B = msg:match('^(.*) casts? ([^%.]*) on (.*)%.%s?$')
			-- if not A:find('^[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			-- if not B:find('^[Tt]he') then B = '['..ES..B..ES..']' else
			-- B = B:gsub('[Tt]he ', ''); end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			S = '\\'..S..'/'
			par_action1 = S;
			--msg = A..' '..utf8.char(0x25B6)..' '..B..' '..combatCP.SPLIT..' ['..S..']';
			msg = A..' '..combatCP.CAST..' '..B..' '..combatCP.SPLIT..' '..S..' ';
					
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg;
		end
		--Joachim casts Carnage Elegy. The Yagudo Prior receives the effect of Elegy.
		A, S, Ext = msg:match("^(.*) casts? ([^%.]*)%.%s*(.*)$")
		if A and S and
			not msg:find('^.- cannot ' ) and
			not msg:find('^.- damage') and
			not msg:find('^.- evade') and
			not msg:find('^.- is una') and
			not msg:find('^.- does not') and
			not msg:find('^.- lacks the') and
			not msg:find('^Unable to')
		then
			
			--if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			-- --if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if Ext and Ext:trimex() ~= '' then
				--Ext = Ext:gsub(A..' ', '')..' '
				--Ext = Ext:gsub('^.', string.upper(Ext:sub(1,1)))
				local c = 0
				Ext, c = Ext:gsub('receives the effect of', combatCP.LEFT)
				if c == 0 then
					Ext, c = Ext:gsub('gains the effect of', combatCP.LEFT)
				end
				if c == 0 then
					Ext, c = Ext:gsub('is afflicted with', combatCP.LEFT)
				end
				Ext = Ext:gsub('successfully (.)', function(c) return combatCP.RIGHT..' '..c:upper() end)
				Ext = ': '..Ext
				if c > 0 then
					B = Ext:match('^(.+) '..combatCP.LEFT..'.*$')
					if B then 
						
						--B = B:gsub('[Tt]he ', '');
						--par_actor2 = B;
						
						if utils.StringFindTable(B, par_party_names, nil, true) then
							if #par_actor1 > 0 then
								par_actorP = B;
							else
								par_actor1 = B;
							end
						else
							B = B:gsub('[Tt]he ', '');
							if #par_actor2 > 0 then
								par_actorE = B;
							else
								par_actor2 = B;
							end
						end
					end
				end
			else
				Ext = ''
			end
			-- if not A:find('^[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			S = '\\'..S..'/'
			par_action1 = S;
			--msg = Ext..A..' '..utf8.char(0x25B6)..' ['..S..']';
			--msg = Ext..A..' '..combatCP.CAST..' '..S..' ';
			msg = A..' '..combatCP.CAST..' '..S..Ext;
					
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.CAST)+string.len(combatCP.CAST)-1;
			
			return msg;
		end
	end

	--msg:find('^'..fcw[1].PlayerName) and
	if  msg:find(' uses? ') and msg:find(' on ') then 
		A, S, B = msg:match('^(.*) uses? ([^%.]*) on (.*)%.%s?$')
		if A and B and S then
			-- if not A:find('^[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			-- if not B:find('^[Tt]he') then B = '['..ES..B..ES..']' else
			-- B = B:gsub('[Tt]he ', ''); end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			------
			if utils.StringFindTable(B, par_party_names, nil, true) then
				if #par_actor1 > 0 then
					par_actorP = B;
				else
					par_actor1 = B;
				end
			else
				B = B:gsub('[Tt]he ', '');
				if #par_actor2 > 0 then
					par_actorE = B;
				else
					par_actor2 = B;
				end
			end
			S = '\\'..S..'/'
			par_action1 = S;
			--msg = A..' '..utf8.char(0x25B6)..' '..B..' '..combatCP.SPLIT..' ['..S..']';
			msg = A..' '..combatCP.RIGHT..' '..B..' '..combatCP.SPLIT..' '..S..' ';
					
			par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.SPLIT)+string.len(combatCP.SPLIT)-1;
			return msg;
		end
	end
	
	if msg:find('use') then
		--Rosabelle uses Animated Flourish on the Tchakka.65
		--Eleanor uses Bounty Shot. No effect on the Ul'yovra. 
		A, S, Ext = msg:match("^(.*) uses? ([^%.]*)%.%s*(.*)$")
		
		if A and S and not msg:find('damage') and not msg:find('^You are') and not msg:find('cannot') then
			
			--if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			-- --if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if Ext and Ext:trimex() ~= '' then
				--Ext = Ext:gsub(A..' ', '')..' '
				--Ext = Ext:gsub('^.', string.upper(Ext:sub(1,1)))
				if Ext:find(' on ') then
					B = Ext:match("^.-on (.-)%.%s?$")
				end
				if not B or B == '' then
					Ext = Ext:gsub('receives the effect of', combatCP.LEFT)
					Ext = Ext:gsub('gains the effect of', combatCP.LEFT)
					Ext = Ext:gsub('is afflicted with', combatCP.LEFT)
					Ext = Ext:gsub('successfully (.)', function(c) return combatCP.RIGHT..' '..c:upper() end)
					--Ext = Ext..' '
					Ext = ': '..Ext..' '
				else
					Ext = Ext:gsub(' on '..B, '')
				end
			else
				Ext = ''
			end
			-- if not A:find('^[Tt]he') then A = '['..ES..A..ES..']' else
			-- A = A:gsub('[Tt]he ', ''); end
			if utils.StringFindTable(A, par_party_names, nil, true) then
				par_actor1 = A;
			else
				A = A:gsub('[Tt]he ', '');
				par_actor2 = A;
			end
			
			if B then
				if utils.StringFindTable(B, par_party_names, nil, true) then
					if #par_actor1 > 0 then
						par_actorP = B;
					else
						par_actor1 = B;
					end
				else
					B = B:gsub('[Tt]he ', '');
					if #par_actor2 > 0 then
						par_actorE = B;
					else
						par_actor2 = B;
					end
				end
			end
			
			S = '\\'..S..'/'
			
			par_action1 = S;
			--msg = Ext..A..' '..utf8.char(0x25B6)..' ['..S..']';
			--msg = Ext..A..' '..combatCP.RIGHT..' '..S..' ';
			msg = A..' '..combatCP.RIGHT..((B and #B > 0) and ' '..B..' '..combatCP.SPLIT..' '..S..': '..Ext or ' '..S..Ext);	

			--par_CombatCutIdx =  utils.FindLastOfMB(msg, combatCP.RIGHT)+string.len(combatCP.RIGHT)-1;
			par_CombatCutIdx =  utils.FindFirstOfMB(msg, combatCP.RIGHT)+string.len(combatCP.RIGHT)-1;
			par_LastMode:replace('combatspell','combat');
			--Debug(msg,1,true)
			return msg;
		end
	end	
	
	--1 of the Yagudo Conquistador's shadows absorbs the damage and disappears. 
	
		
	
	local c = 0
	msg, c = msg:gsub('(receives the effect of )([^%.]*)(%.)', function(c1, c2, c3) return combatCP.LEFT..' ['..c2..']' end)
	if c < 1 then
		msg, c = msg:gsub('(gains the effect of )([^%.]*)(%.)', function(c1, c2, c3) return combatCP.LEFT..' ['..c2..']' end)
	end
	if c < 1 then
		msg, c = msg:gsub('(is afflicted with )([^%.]*)(%.)', function(c1, c2, c3) return combatCP.LEFT..' ['..c2..']' end)
	end

	if c > 0 then
		if not msg:find('^[Tt]he') then
			msg = '['..msg:sub(1, msg:find(' ') - 1)..']'..msg:sub(msg:find(' '), #msg)
		else
			msg = msg:gsub('^[Tt]he ', '')
		end
	end
	
	return msg;

end

function AddTooltip(message, offset, critical)
	if not offset then offset = 0 end
	imgui.SameLine() --imgui.Dummy({1,0}) imgui.SameLine() 
	local cursorPosY = imgui.GetCursorPosY()
	imgui.SetCursorPosY(cursorPosY+offset)
	if not critical then imguiWrap.Image(fcw[1].TextureIDInfo,{15,15})
	else imguiWrap.Image(fcw[1].TextureIDInfo,{15,15},{0,0},{1,1},{0.937, 0.349, 0.290 ,1}) end
	if (imgui.IsItemHovered(0)) then
		imgui.BeginTooltip()
		local text = utils.breakLine(message, 40)
		---message = utils.breakLine(message, imgui.GetWindowWidth()*2.5)
		imgui.SetTooltip(text)
		imgui.EndTooltip()
		
	end
end

function AddWarning(message, y, flag, x, title)
	if check == false then return end
	local wx = 300
	local wy = 300
	if y then wy = y end
	if x then wx = x end
	if not title then title = 'Warning' end
	local dsize = imgui.GetIO().DisplaySize;
	imgui.SetNextWindowSize({wx,wy});
	imgui.SetNextWindowPos({(dsize.x/2)-(wx/2),(dsize.y/2)-(wy/2)})
	local wFlags = bit.bor(ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_NoMove, ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoSavedSettings);
	imgui.PushStyleVar(ImGuiStyleVar_WindowTitleAlign, {0.5,0.5})
	imgui.PushStyleColor(ImGuiCol_WindowBg, {0.1,0.1,0.1,1.0});
	imgui.PushStyleColor(ImGuiCol_TitleBg, {0.1,0.1,0.1,1.0});
	imgui.PushStyleColor(ImGuiCol_TitleBgActive, {0.1,0.1,0.1,1.0});
	if imgui.Begin(title..'##'+fcw[1].PlayerName, set_Popup, wFlags) then
		local winwidth = imgui.GetWindowWidth();
		local textwidth, textheight = imgui.CalcTextSize(message);
		local textindentation = (winwidth - textwidth) * 0.5;
		local minindentation = 20;
		if (textindentation <= minindentation) then
			textindentation = minindentation;
		end
		imgui.SameLine(textindentation);
		imgui.PushTextWrapPos(winwidth - textindentation);
		imgui.TextWrapped(message);
		--imgui.Dummy({(imgui.CalcItemWidth())*0.5,0}) imgui.SameLine()
		imgui.SetCursorPosY(wy-40)
		imgui.SetCursorPosX(wx/2-35)
		if imgui.Button('OK##Warning',{70,0}) then
			set_Popup[1] = false;
			if flag then
				flag[1] = true
				SaveSettings()
			end
		end
		imgui.PopTextWrapPos();
		--imgui.Text(message)
		imgui.End();
	end
	imgui.PopStyleColor(3)
	imgui.PopStyleVar();

end

function AddSetColor(buttonname,colorhex, tmpcolor)
	local a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(colorhex[1])));
	local colortable = T{r/255,g/255,b/255,a/255};
	--utils.rgbaToHexNum
	if imgui.ColorButton(buttonname, colortable,ImGuiColorEditFlags_NoAlpha,{24,24}) then
		tmpcolor[1] = colortable
	end	
	imgui.SameLine();
	if imgui.ArrowButton('Set'..buttonname, ImGuiDir_Left) then
		colortable[1] = set_PickedColor[1]
		colortable[2] = set_PickedColor[2]
		colortable[3] = set_PickedColor[3]
		colortable[4] = 1
		colorhex[1] = utils.rgbaToHexNum(colortable)
		SaveSettings()
	end
	imgui.SameLine();
	imgui.Text(colorDesc[buttonname][1]);
	
	AddTooltip(colorDesc[buttonname][2], 4);
	
	return imgui.CalcTextSize(colorDesc[buttonname][1] )+ 48 + 32 + 32 + 16
end

function PushWindowStyle()
	--local NTa,NTr,NTg,NTb = utils.hexToRGBA(tostring(bit.tohex(allSettings.rectSettings.fill_color)));
	imgui.PushStyleColor(ImGuiCol_WindowBg, {0.1,0.1,0.1,0.7});
	imgui.PushStyleColor(ImGuiCol_TitleBg, {0.1,0.1,0.1,0.7});
	imgui.PushStyleColor(ImGuiCol_TitleBgActive, {0.1,0.1,0.1,0.7});
	imgui.PushStyleColor(ImGuiCol_TitleBgCollapsed, {0.1,0.1,0.1,0.7});
	imgui.PushStyleColor(ImGuiCol_ChildBg, {0.05,0.05,0.05,0.4});
	imgui.PushStyleColor(ImGuiCol_FrameBg, {0.3,0.3,0.3,0.6});
	imgui.PushStyleColor(ImGuiCol_ButtonHovered, {0.7,0.7,0.7,0.65});
	imgui.PushStyleColor(ImGuiCol_ScrollbarBg, {0,0,0,0.3});
	imgui.PushStyleColor(ImGuiCol_Button, {0.4,0.4,0.4,0.6});
	imgui.PushStyleColor(ImGuiCol_FrameBgHovered, {0.4,0.4,0.4,0.6});
	imgui.PushStyleColor( ImGuiCol_FrameBgActive, {0.4,0.4,0.4,0.8});
	imgui.PushStyleColor(ImGuiCol_CheckMark, {1.000, 0.384, 0.322 ,1});
	imgui.PushStyleColor(ImGuiCol_SliderGrab, {0.937, 0.349, 0.290 ,1});
	imgui.PushStyleColor(ImGuiCol_ScrollbarGrab, {0.7,0.7,0.7,0.3});
	imgui.PushStyleColor(ImGuiCol_ScrollbarGrabHovered, {0.8,0.8,0.8,0.3});
	imgui.PushStyleColor(ImGuiCol_ScrollbarGrabActive, {0.9,0.9,0.9,0.3});
end

function PopWindowStyle()
	imgui.PopStyleColor(16);
end

parseThis = function(e, e_message)
	
	local msg = e_message;
	--Debug(tostring(e.message:endswith(string.char(0x7F,0x34,0x01))), 1, true);
	par_CombatCutIdx = 0;
	par_actor1 = '';
	par_actor2 = '';
	par_actorP = '';
	par_actorE = '';
	par_action1 = '';
	par_isDamage = false;
	par_handled_actors = false;
	par_DamageDone = false;
	par_DamageGot = false;
	local original_msg = '';
	par_LastMode = 'unknown';

	--local msg = AshitaCore:GetChatManager():ParseAutoTranslate(e_message, true)
			
	 msg = msg:gsub('[^\x1E\x1F][\x07]', function (s)
		local spacing = ' ';
		return s:sub(1, 1):append(spacing);
	 end);

	par_MessageMode = bit.band(e.mode,  0x000000FF);
	
	local ts = '';
	if allSettings.timeStamp[1] then ts = os.date(par_FormatTS[allSettings.FormatTSMode], os.time())..' '; end
	
	original_msg = msg;

	
	

	local fwdmsg = false;
	if (par_MessageMode == 150 or par_MessageMode == 151) then --or par_MessageMode == 152)
		local waitingFWD = false
		for _, FWDchar in ipairs(utils.fwdchars) do
			waitingFWD = msg:endswith(FWDchar)
			if waitingFWD then
				fo_Fwd[1]:set_visible(true);
				if allSettings.SecondChat[1] then fo_Fwd[2]:set_visible(true); end
				par_IsInConv = true; 
				fwdmsg = true;
				
				--uiw.DialogPromptStart = os.clock()
					
				break;
			end
		end
	else
		if (not par_IsInConv) then fo_Fwd[1]:set_visible(false); if allSettings.SecondChat[1] then fo_Fwd[2]:set_visible(false); end end
	end
	
	local colstring = defaultColor;
	local col = colstring;

	par_LastMode = utils.modesDA[par_MessageMode+1][2];
	col = utils.modesDA[par_MessageMode+1][3];

	if string.find(par_LastMode, '^combat_') then col = allSettings.colors.combat[1]
	elseif string.find(par_LastMode, '^combatspell_') then col =  allSettings.colors.combatspell[1];
	elseif par_LastMode:find('^linkshell1') then col =  allSettings.colors.linkshell1[1]; 
	elseif par_LastMode:find('^linkshell2') then col =  allSettings.colors.linkshell2[1]; 
	elseif string.find(par_LastMode,'^party') then col =  allSettings.colors.party[1]; 
	elseif string.find(par_LastMode,'^tell') then col =  allSettings.colors.tell[1]; 
	elseif string.find(par_LastMode,'^shout') then col =  allSettings.colors.shout[1]; 
	elseif string.find(par_LastMode,'^emote') then col = allSettings.colors.emote[1]; 
	end
	
	
	
	if allSettings.tellNotification[1] and par_LastMode == 'tell_in' then ashita.misc.play_sound(string.format('%s\\notifications\\%s%s.wav', addon.path, allSettings.selectedNotification,allSettings.boostNotification[1] and 'B' or '')); end;

	
	--not fwdmsg and 
	if not fcw[1].HideChat and not uiw.LegacyChatOpen then
		if (par_MessageMode ~= 151 and par_MessageMode ~= 150) then
			if ((string.find(par_LastMode,'combat') or par_LastMode == 'filtered') and allSettings.blockCombat[1] ) then 		
				e.blocked = true	
			else
				if (allSettings.blockAll[1]) then
					e.blocked = true
				end
			end
		else
			if not e.blocked and allSettings.blockAll[1] then
			--	e.message_modified = '__'
			--	local fcIdx = utils.FindInStringTable(e.message,utils.fwdchars,0);
				--Debug(tostring(fcIdx)..'-'..tostring(string.byte(utils.fwdchars[fcIdx][2])),1,true)
			--	if fcIdx then e.message_modified=e.message_modified..utils.fwdchars[fcIdx] end
				--e.message_modified = e.message
				fo_Fwd[1]:set_visible(true);
				if allSettings.SecondChat[1] then fo_Fwd[2]:set_visible(true); end
				--e.message_modified = '';
			end
		end
	end
	
	
	if string.find(par_LastMode,'%_%?') then
		col = 0xFF000FFF -- JUST FOR DEBUG
		local combatWords = {'hit','damage','cast','use','wear','defeat','miss','evade','effect','recover','resist','parr'};
		local CheckIfCombat = function (str, words)
			for _, word in ipairs(words) do
				if string.find(str, word, 1, true) then -- Plain search, no pattern matching
					return true, word -- Return true and the first found word
				end
			end
			return false
		end
		--if CheckIfCombat(msg, combatWords) then par_LastMode = 'combat' end
		-- dw_ChannelColorMode[1] 
		msg = msg..' (chn: '..tostring(par_MessageMode)..')';
		if true then ashita.misc.play_sound(string.format('%s\\notifications\\%s%s.wav', addon.path, 'notification_4', '')) end
	end
	
	
	if
		--par_MessageMode == 152 
		--or 
		original_msg == ''
		or original_msg:match("^%s*$")
		or original_msg:match('^@@%s')
	then
		par_LastMode = 'filtered';
		return;
	end
	
	
	
	local newText = CleanText(msg, par_LastMode);
	
	local isDiscordText = false
	
	if set_isCEXI then
		if utils.IsInTable(par_emojiChannels, par_MessageMode) then
			for i = 1, #newText do
				local first_letter = newText:sub(i, i)
				if first_letter:match("%a") then       -- first letter found
					if first_letter >= "a" and first_letter <= "z" then
						--newText = utils.parseEmoji(newText:gsub('(<)(.-)(>)', '@%2:', 1))
						newText = utils.parseEmoji(newText:gsub('<', '{', 1):gsub('>', '}', 1))
						isDiscordText = true
						break
					else
						break
					end
				end
			end
		end
	end
	
	if newText:match('^%s*\n?$') then par_LastMode = 'empty' return end
	
	if allSettings.Alert[1] and (
		(allSettings.alertOptions[1] and par_LastMode == 'local') or
		(allSettings.alertOptions[2] and par_LastMode == 'shout') or
		(allSettings.alertOptions[3] and par_LastMode == 'party_in') or
		(allSettings.alertOptions[4] and par_LastMode:find('^linkshell%d$')) or
		(allSettings.alertOptions[5] and par_LastMode == 'unity')
		)
	then
		for al_i = 1, #set_alertList do
			if set_alertList[al_i] and set_alertList[al_i] ~= '' and string.lower(newText):find(string.lower(set_alertList[al_i]),1,true) then
				ashita.misc.play_sound(string.format('%s\\notifications\\%s%s.wav', addon.path, allSettings.selectedAlert,allSettings.boostAlert[1] and 'B' or ''));
			end
		end
	end
		
	if (par_MessageMode == 123 and string.find(newText, '{')~= nil) then
		newText = string.sub(newText,1,string.find(newText, '{')-1)..string.sub(newText,string.find(newText, '{')+1,string.len(newText));
	elseif par_MessageMode == 129 then
		if utils.FindInStringTable(newText, utils.crafts, 0) or newText:find('learns') then
			par_MessageMode = 121; par_LastMode = 'craft'; col = utils.modesDA[par_MessageMode+1][3];
		end
	elseif par_MessageMode == 121 and string.find(newText, ' lot for ') then
		newText = newText:gsub('(: )(%d)',utils.icons.ROLL..' %2'):gsub(' points%.','')
	end
	
	
	local playerTarget = AshitaCore:GetMemoryManager():GetTarget();
	local party = AshitaCore:GetMemoryManager():GetParty();
	local entity = AshitaCore:GetMemoryManager():GetEntity();
	local bt = targets.get_bt();
	local bt_name = '@';
	if bt~= nil then
		bt_name = bt.Name:gsub('^\171','')
	end
	local t_name = '@';
	local targetIndex;
	if (playerTarget ~= nil) then
		local targetIndex = playerTarget:GetTargetIndex(0);
		local targetEntity = GetEntity(targetIndex);
		if targetEntity and bit.band(targetEntity.SpawnFlags, 0x10) ~= 0 then
			t_name = targetEntity.Name:gsub('^\171','')
		end
	end
	local pet;
	local pet_name = '@';
	if party:GetMemberIsActive(0) ~= 0 then
		pet = targets.get_pet();
		if pet ~= nil then
			pet_name = pet.Name;
		end
	end
--	Debug(string.byte(t_name[1]),1,false)
	local isTarget = string.find(newText, t_name) or string.find(newText, bt_name)
	
	local player_name = fcw[1].PlayerName;
	par_party_names = T{};
	for P_i = 0, 5 do
		if party:GetMemberIsActive(P_i) ~= 0 then
			table.insert(par_party_names, party:GetMemberName(P_i))
		end
	end
	if pet then table.insert(par_party_names, pet_name) end
	
	local debugclors = dw_ChannelColorMode[1];
	--DEBUG
	local col_y = debugclors and 0xFF03FC39 or col; --green
	local col_p = debugclors and 0xFFFCB503 or col; --yellow
	local col_n = debugclors and 0xFFFC0335 or col; --red
	local col_t = debugclors and 0xFF572A03 or col; --brown
	local col_e = debugclors and 0xFF333333 or col; --grey
	local col_a = debugclors and 0xFFFFCCCC or col; --pink?
	
	local isYou = false;
	local isParty = false;
	local isAlliance = false;
	local isOthers = false;
	if par_LastMode:find('combat',1,true) then
		if string.find(par_LastMode,'_y',1,true) then isYou = true; col = col_y;
		elseif string.find(par_LastMode,'_p',1,true) then isParty = true; col = col_p;
		elseif string.find(par_LastMode,'_n',1,true) then
			if not string.find(newText, pet_name) then
				isOthers = true; col = col_n;
			else
				isYou = true;  col = col_t;
			end
		elseif string.find(par_LastMode,'_t',1,true) then isYou = true;  col = col_t;
		elseif string.find(par_LastMode,'_e',1,true) then isYou = true; col = col_e;
		elseif string.find(par_LastMode,'_a',1,true) then isAlliance = true;  col = col_a;
		elseif string.find(par_LastMode,'_u',1,true) then
			if string.find(newText, player_name) or utils.StringFindTable(newText, utils.disambYou, 1) then
				isYou = true; col = col_y; 
			elseif utils.StringFindTable(newText, par_party_names) then
				isParty = true; col = col_p;
			elseif isTarget and string.find(newText, ' falls ') then
				isYou = true; col = col_y; 
			else
				isOthers = true
			end
		elseif string.find(par_LastMode,'_x',1,true) then --isParty = true;  col = col_p;
			--Debug(tostring(string.find(newText, pet_name))..'-'..tostring(par_MessageMode),1,true)
			if string.find(newText, pet_name) and isTarget then isYou = true; col = col_t;
			--Debug('pet',1,true)
			elseif string.find(newText, player_name) or utils.StringFindTable(newText, utils.disambYou, 1) then isYou = true; col = col_y; if par_MessageMode == 191 and newText[#newText] == ':' then par_allowed = {191, 6} end
			elseif utils.StringFindTable(newText, par_party_names) then isParty = true; col = col_p;
			elseif (isTarget and not utils.StringFindTable(newText, utils.disambEnemy, 1)) then isYou = true;  col = col_e;
			else isOthers = true; col = col_n;
				 
				--Debug(e.message..' - '..tostring(isTarget), 1, true)
			end
		else
			if (isTarget and not utils.StringFindTable(newText, utils.disambEnemy, 1)) then
				isOthers = true; col = col_n
			elseif (isTarget and utils.StringFindTable(newText, utils.disambEnemy, 1)) then
				isYou = true; col = col_e
			end
		end
		if par_MessageMode == par_allowed[1] and par_allowed[2] > 0 then par_allowed[2] = par_allowed[2] - 1; isYou = true; isOthers = false; isAlliance = false end
		if 	(allSettings.hideAlliance[1] and isAlliance) or
			(allSettings.hideNonParty[1] and isOthers) or
			(allSettings.hideNonYou[1] and not isYou)
		then
			par_LastMode = 'filtered'; return;
		end
		local scope = '_z'
		if isYou then scope = '_y' elseif isYou or isParty then scope = '_p' end
		--  elseif isTarget then scope = '_t' and newText == fcw[1].PlayerName 
		
		if allSettings.CustomFilters[1] then
			if utils.FindInStringTableFilters(newText, par_customFilters, scope) then
				par_LastMode = 'filtered'
				return
			end
		end
	end
	
	
	table.insert(par_party_names, player_name)
	--if (par_LastMode == 'combat') then Debug(tostring(isParty), 2, false); end
--	Debug(tostring(par_LastMode), 2, true);
	
	local iscombatspell = string.find(par_LastMode,'combat_') and string.find(newText,' cast')
	iscombatspell = iscombatspell or string.find(par_LastMode, 'combatspell_'); 
	if allSettings.CompactCombat[1] then
		
		if (iscombatspell) then
			newText = CombatSpellText(newText, par_MessageMode); col = allSettings.colors.combatspell[1];
			par_LastMode:gsub('combat_', 'combatspell_');
		end
		
		if string.find(par_LastMode, 'combat_') then
			newText = CombatText(newText, par_MessageMode);
			if allSettings.PreciseTS[1] and utils.IsInTable({36,37,44,166},par_MessageMode) then
				--ts = os.date(par_FormatTS[1], os.time())..' ';
				newText = newText..' '..os.date(par_FormatTS[1], os.time())
			end
		end
	end
	
	if par_CombatCutIdx > 0 then
		par_CombatCutIdx = par_CombatCutIdx + #ts
	end
	--local offset = 0;
	--if ts ~= '' then offset = 11; end
	newText = ts..newText;
	local offset = #ts;
	
	-- check if the messages are different or arrived at a different time --
	local checkMsgOrDate = string.sub(newText,1+offset,string.len(newText)) ~= par_LastMessage
	--and not utils.StringsDifferByOneChar(string.sub(newText,1+offset,string.len(newText)), par_LastMessage)
	or par_LastTS ~= os.date(par_FormatTS[1], os.time())..' '
	or par_MessageMode == 121
	or par_MessageMode == 127
	or par_MessageMode == 131
	or par_MessageMode == 142;
		
	--local dupedCS = not string.find(par_LastMode,'combat_') and string.find( par_LastMessage,  string.sub(newText,1+offset+(string.len(newText)-offset/5),string.len(newText)-offset-(string.len(newText)/5))) ~= nil;
	
	--if dupedCS then dw_TestMessage = 'Duplicate CS message removed >'..tostring(dupedCS); end
	
	if ( checkMsgOrDate ) then
	
		b_msgID = b_msgID + 1;
		par_LastMsgLength = #newText
	
		par_LastTS = os.date(par_FormatTS[1], os.time())..' ';
		par_LastMessage = string.sub(newText,1+offset, string.len(newText));
		
		-- local tabmode = (function()
			-- --if (string.find(par_LastMode, 'combat') == nil) then return 2; end
			-- if (string.find(par_LastMode, 'combat')) then return 3; end
			-- if (string.find(par_LastMode, 'linkshell')) then return 4; end
			-- if (string.find(par_LastMode, 'party')) then return 5; end
			-- if (string.find(par_LastMode, 'tell')) then return 6; end
			-- if (string.find(par_LastMode, 'shout')) then return 7; end
			-- if (string.find(par_LastMode, 'Custom')) then return 8; end
			-- return -1;
		-- end)();
		
			--if (string.find(par_LastMode, 'combat') == nil) then return 2; end
		local isCombatMsg = false
		par_tabmode = nil;
		if (string.find(par_LastMode, '^combat')) then par_tabmode = 3; isCombatMsg = true;
		elseif (string.find(par_LastMode, '^linkshell')) then par_tabmode = 4;
		elseif (string.find(par_LastMode, '^party')) then par_tabmode = 5; 
		elseif (string.find(par_LastMode, '^tell')) then par_tabmode = 6; 
		elseif (string.find(par_LastMode, '^shout')) then par_tabmode = 7; 
		else par_tabmode = -1;
		end
		
		--npc, ls, party, tell, shout
		par_isCustom = false
		--Debug(tostring(par_LastMode),1,true)
		for cmode = 1, #allSettings.CustomTabModes do
			
			if allSettings.CustomTabModes[cmode] then
				if cmode == 1 and string.find(par_LastMode, 'NPC$') or
				par_tabmode == cmode+2				
				then
					par_isCustom = true
					break
				end
			end
		end
		
		--if (string.find(par_LastMode, '^custom')) then tabmode = 8; 
		
		local n_lines = math.floor((string.len(newText))/allSettings.chatLineMaxL);
		if math.fmod(string.len(newText), allSettings.chatLineMaxL) ~= 0 then  n_lines = n_lines+1; end
		
		par_checkAgain = {0, ''}
		
		local check_again = false;
		local check_again_text = ''
		local carry_over = false;
		local carry_over_color = nil;
		
		local textLeft = string.len(newText);
		local L_i = 1;
		--for L_i = 1, n_lines do
		local urlText = ''
		if not isCombatMsg then urlText =  utils.ParseUrlLink(newText); end
		local auxURL_text = '';
		local skipped = 0;
		local HELMfound = FindHELM(newText, par_MessageMode);
		--Debug(tostring(HELMfound), 1, true)
		
		while L_i <= n_lines do
		
			
			--if L_i > 1 then newText = newText:trimex(); end
			newText = newText:trimex()
			if (newText:match("^%s$") or newText == '') then  n_lines = L_i-1; break; end;
			if carry_over_color ~= nil then col = carry_over_color; end
			local special_idx = nil;
			local special_text = '';
			local special_color = '';
			local special_offset = 0;
			local special_type = nil;
			local check_mode = false;
			--Debug(tostring(string.len(newText))..'-'..tostring(utils.CountExtraBytes(newText)),1,true)
			-- local savedBytesLine = utils.CountExtraBytes(newText:sub(1,allSettings.chatLineMaxL))
			-- local lastSBL = 0;
			-- local safe = 1;
			-- while savedBytesLine ~= lastSBL and safe < 100 do
				-- lastSBL = savedBytesLine
				-- savedBytesLine = utils.CountExtraBytes(newText:sub(1,allSettings.chatLineMaxL+savedBytesLine))
				-- safe = safe +1
				-- --Debug(tostring(safe),1,true)
			-- end
			--local cutIdx = math.min(allSettings.chatLineMaxL+savedBytesLine,textLeft);
			local bytesLine = utils.CountExtraBytesT(newText)
			local cutIdx =  math.min(allSettings.chatLineMaxL+bytesLine[math.min(allSettings.chatLineMaxL,#bytesLine)]+1,textLeft);
			--local cutIdx = utils.compute_cut_byte_index(newText, allSettings.chatLineMaxL, textLeft)
			-- local clusters = utils.grapheme_cluster_positions(newText)
			-- local cutIdx = utils.cut_byte_index_from_clusters(clusters, allSettings.chatLineMaxL, textLeft)
			
			--local cutIdx = allSettings.chatLineMaxL+bytesLine[math.min(allSettings.chatLineMaxL,#bytesLine)];
			--Debug(tostring(allSettings.chatLineMaxL+utils.CountExtraBytes(newText))..'-'..tostring(textLeft),1,true)
			--
			--Debug(tostring(cutIdx)..'-'..tostring(textLeft)..'-'..tostring(newText[cutIdx]),1,true)
			local lineBreak = '';
			
			
			--if L_i < n_lines then cutIdx = math.min(allSettings.chatLineMaxL,textLeft);
			if (L_i < n_lines and newText[cutIdx] ~= ' ' and cutIdx ~= textLeft) then
				
					--cutIdx=cutIdx-1;
				--[[
				if string.byte((string.sub(newText,cutIdx,cutIdx))) == 157 or string.byte((string.sub(newText,cutIdx,cutIdx)))==226 then
					cutIdx=cutIdx-1;
					if string.byte((string.sub(newText,cutIdx-1,cutIdx-1))) == 157 or string.byte((string.sub(newText,cutIdx-1,cutIdx-1)))==226 then
						cutIdx=cutIdx-1;
					end
				end
				]]--
					
					cutIdx = utils.utf8split(newText, cutIdx);
					--if #newLinesIdx > 0 then lineBreak = ''else lineBreak = '-'; end
					--urlText ~= '' and 
					if not isCombatMsg and urlText == '' and newText[cutIdx] ~= ' ' and cutIdx < #newText and newText[cutIdx+1] ~= ' ' then lineBreak = '-';else cutIdx = cutIdx +1 end
					if isCombatMsg and #newText-cutIdx < 3 then
						local last_space = utils.FindLastOf(string.sub(newText,1,cutIdx),' ');
						if (last_space ~= nil) and last_space > par_CombatCutIdx then
							if (cutIdx-last_space)<15 then cutIdx = last_space-1; lineBreak = '' end
						end
					end
					--Debug(tostring(cutIdx)..'-'..tostring(newText[cutIdx])..'-'..tostring(urlText)..'LB:'..lineBreak..'<',1,true)F7CF05
					if (textLeft > cutIdx and newText[cutIdx] ~= ' ' and newText[cutIdx+1] ~= ' ') then
						local last_space = utils.FindLastOf(string.sub(newText,1,cutIdx),' ');
						if (last_space ~= nil) then
							if (cutIdx-last_space)<12 then cutIdx = last_space-1; lineBreak = '' end
						end
					end
			end
			if (allSettings.CompactCombat[1]) then
				if isCombatMsg and (par_CombatCutIdx > allSettings.chatLineMaxL)  then
					if #par_actor1 > 0 then
					
						local a = newText:find(par_actor1, 1, true)
						if a and cutIdx >= a and cutIdx - (a-1) < #par_actor1 and a-1 > 1 then cutIdx = a-1; end
						--a = utils.FindLastOfString(newText, par_actor1);
						--if a and cutIdx >= a and cutIdx - (a-1) < #par_actor1 and a-1 > 1 then cutIdx = a-1; end
					end if #par_actor2 > 0 then
						local a = newText:find(par_actor2, 1, true)
						if a and cutIdx >= a and cutIdx - (a-1) < #par_actor2 and a-1 > 1 then cutIdx = a-1; end
					end if #par_actorP > 0 then
						local a = newText:find(par_actorP, 1, true)
						if a and cutIdx >= a and cutIdx - (a-1) < #par_actorP and a-1 > 1 then cutIdx = a-1; end
					end if #par_actorE > 0 then
						local a = newText:find(par_actorE, 1, true)
						if a and cutIdx >= a and cutIdx - (a-1) < #par_actorE and a-1 > 1 then cutIdx = a-1; end
					end
				end
				
				if isCombatMsg and (#par_action1 > 1)  then
					
					if #par_action1 > 0 then
						--par_action1 = par_action1:gsub('%-','%%-');
						--The Lesser Colibri uses Feather Tickle. Forgivnessssssss's TP is reduced to 0.
						local a = newText:find(par_action1, 1, true)
						-- Debug(newText, 1, true)
						-- Debug('cidx: '..cutIdx, 1, true)
						-- Debug('a+pa1: '..(a-1) + #par_action1, 1, true)
						-- Debug('paraction: '..#par_action1, 1, true)
						--if a and cutIdx >= a and (a-1) + #par_action1 < cutIdx and a-1 > 1 then cutIdx = a-1; end
						if a and cutIdx >= a and cutIdx - (a-1) < #par_action1 and a-1 > 1 then cutIdx = a-1; end
						--newText:gsub('%-','%%-');
					end
				end
			end
			
			--if (textLeft > allSettings.chatLineMaxL) then
			-- -- if (textLeft > cutIdx and newText[cutIdx] ~= ' ' and newText[cutIdx+1] ~= ' ') then
				-- -- local last_space = utils.FindLastOf(string.sub(newText,1,cutIdx),' ');
				-- -- if (last_space ~= nil) then
					-- -- if (cutIdx-last_space)<12 then cutIdx = last_space; lineBreak = '' end
				-- -- end
			-- -- end
			--Debug(tostring(string.len(newText)/allSettings.chatLineMaxL)..'\nNT >'..newText..'\nUT >'..urlText..'\nHello1', 1, true);
			if L_i == n_lines then
				
				--if newText[cutIdx] ~= ' ' and cutIdx ~= textLeft then
				--cutIdx = utils.utf8split(newText, cutIdx);
				if newText[cutIdx] ~= ' ' and cutIdx < textLeft then 
					cutIdx = utils.utf8split(newText, cutIdx);
					if not isCombatMsg and urlText == '' and newText[cutIdx] ~= ' ' and cutIdx < #newText and newText[cutIdx+1] ~= ' ' then lineBreak = '-';else cutIdx = cutIdx +1 end
					local last_space = utils.FindLastOf(string.sub(newText,1,cutIdx),' ');
					if (last_space ~= nil) then
						if (cutIdx-last_space)<12 then cutIdx = last_space-1; lineBreak = '' end
					end
					-- Debug(tostring(L_i), 1, true)
					
					n_lines = n_lines +1;
					
				end
				--end
				if  urlText ~= '' then
					if textLeft+6 < allSettings.chatLineMaxL then
						auxURL_text = '[link]';
					else
						--auxURL_text = 'URL';
						cutIdx = math.min(cutIdx,textLeft-1);
						--Debug('Hello2', 1, true);
						local last_space = utils.FindLastOf(string.sub(newText,1,cutIdx),' ');
						if (last_space ~= nil) then
							if (cutIdx-last_space)<12 then cutIdx = last_space-1; lineBreak = '' end
						end
						n_lines = n_lines+1;
					end
				end

			end 
			
			
			
			
			local MCList = {}
			
			if
				par_MessageMode == 9 or
				par_MessageMode == 142 or
				par_MessageMode == 151 or
				par_MessageMode == 121 or
				par_MessageMode == 131 or
				par_MessageMode == 138 or
				par_MessageMode == 127 or
				par_MessageMode == 90 or
				par_MessageMode == 85 
			then
				MCSpecial = CheckSpecial(newText, col, cutIdx)
				if MCSpecial and MCSpecial[2] then
					newText = MCSpecial[1]
					
					table.insert(MCList, MCSpecial[2])
					if MCSpecial[3] then
						cutIdx = MCSpecial [3]
					end
				end
			end
			
			if L_i == 1 and allSettings.timeStamp[1] then
				local e = newText:find(']')
				if e then
					table.insert(MCList, {0, e, 0xFFFFFFFF})
				end
			end
			
			-- local ATchar_1 = newText:find(utf8.char(0x276e), 1, true)
			-- local ATchar_2 = newText:find(utf8.char(0x276f), 1, true)
			-- if ATchar_1 then table.insert(MCList, {ATchar_1-1, ATchar_1+2, 0xFF0D9441}) end
			-- if ATchar_2 then table.insert(MCList, {ATchar_2-1, ATchar_2+2, 0xFFAB1F28}) end
			local ATstart = 1
			while true do
				local s, e = string.find(newText, utf8.char(0x276e), ATstart, true)
				if not s then break end
				if s-2 > 1 and string.find(newText:sub(s-2,s-1), '|', 1, true) then 
					newText = newText:gsub('|','/')
				end
				table.insert(MCList, {s-1, s+2, 0xFF0D9441})
				ATstart = e + 1
			end
			ATstart = 1
			while true do
				local s, e = string.find(newText, utf8.char(0x276f), ATstart, true)
				if not s then break end
				table.insert(MCList, {s-1, s+2, 0xFFBB2F38})
				ATstart = e + 1
				
			end
			
			if (par_CombatCutIdx ~= 0 ) then
				
				
				if (par_CombatCutIdx <= cutIdx) then
					
					if (par_CombatCutIdx > 0) then
						
						--nexText = HandleActors(MCList, newText)
						--Debug(tostring(#MCList),1,true)
						table.insert(b_ChatBuffer[1][2].text,  string.sub(newText,1,cutIdx)..lineBreak);
						
						--special_text = string.sub(newText,par_CombatCutIdx+1,cutIdx)..lineBreak;
						if string.find(par_LastMode, 'combat_') and par_isDamage then
							
							special_color = allSettings.colors.damage[1];
							local cb = allSettings.ColorBlind[1] and 2 or 1;
							if par_DamageDone then
								special_color = allSettings.colors.dmgdone[cb];
							end
							if par_DamageGot then
								special_color = allSettings.colors.dmggot[cb];;
							end
							table.insert(MCList, {par_CombatCutIdx, #newText, special_color})
						else
							if string.find(par_LastMode,'combatspell_') and par_isDamage then
								special_color = allSettings.colors.spelldamage[1];
								local cb = allSettings.ColorBlind[1] and 2 or 1;
								if par_DamageDone then
									special_color = allSettings.colors.spelldmgdone[cb];
								end
								if par_DamageGot then
								special_color = allSettings.colors.spelldmggot[cb];
								end
							end
							table.insert(MCList, {par_CombatCutIdx, #newText, special_color})
						end
						
						par_CombatCutIdx = par_CombatCutIdx - cutIdx;
						if par_CombatCutIdx == 0 then par_CombatCutIdx = -1; end
					else
						table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,cutIdx)..lineBreak);
						if string.find(par_LastMode, 'combat_') and par_isDamage  then
							col = allSettings.colors.damage[1];
							local cb = allSettings.ColorBlind[1] and 2 or 1;
							if par_DamageDone then
								col = allSettings.colors.dmgdone[cb];
							end
							if par_DamageGot then
								col = allSettings.colors.dmggot[cb];;
							end
							if allSettings.PreciseTS[1] and utils.IsInTable({36,36,44,166},par_MessageMode) then
								col = allSettings.colors.combat[1];
							end
							--table.insert(MCList, {par_CombatCutIdx, #newText, col})
						else
							if string.find(par_LastMode,'combatspell_') and par_isDamage then
								col = allSettings.colors.spelldamage[1];
								local cb = allSettings.ColorBlind[1] and 2 or 1;
								if par_DamageDone then
									col = allSettings.colors.spelldmgdone[cb];
								end
								if par_DamageGot then
								col = allSettings.colors.spelldmggot[cb];
								end
							end
							--table.insert(MCList, {par_CombatCutIdx, #newText, col})
						end
						--Debug(tostring(par_action1), 1, true)
						special_text = '';	
					end
				else
					--MCList = HandleActors(MCList, newText)
												
					table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,cutIdx)..lineBreak);
					par_CombatCutIdx = par_CombatCutIdx - cutIdx;
					special_text = '';
				end
			else
				
				table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,cutIdx)..lineBreak);
				special_text = '';
			
			end
			
				--call to HELMtext
			
			if HELMfound then
				local HEMLtable = HELMtext(HELMfound, string.sub(newText,1,cutIdx))
				if HEMLtable then
					fo_Fwd[1]:set_visible(false)
					fo_Fwd[2]:set_visible(false)
					table.insert(MCList,HEMLtable)
				end
			end
			
			if #MCList > 0 or par_handled_actors then
				local mctext = b_ChatBuffer[1][2].text[#b_ChatBuffer[1][2].text]
				
				table.sort(MCList, function(a, b)
					return a[1] < b[1]
				end)
				
				for i = 1, #MCList do
					local mcoff = 28 * (i-1)
					mctext = string.sub(mctext,1,MCList[i][1]+mcoff)..utils.MC(MCList[i][3])..string.sub(mctext,MCList[i][1]+1+mcoff,MCList[i][2]+mcoff)..utils.MC('reset')..string.sub(mctext, MCList[i][2]+1+mcoff,#mctext)
					
				end
				
				if allSettings.CompactCombat[1] then
					--Debug(special_color,1,true)
					mctext = HandleActors(mctext, special_color)
				end
				
				--if MCCheck(mctext) then 
				b_ChatBuffer[1][2].text[#b_ChatBuffer[1][2].text] = utils.MCCheck(mctext)
					--Debug(b_ChatBuffer[1][2].text[#b_ChatBuffer[1][2].text], 1, true)
			end
			
			if set_isCEXI and isDiscordText then
				
				local mctext = b_ChatBuffer[1][2].text[#b_ChatBuffer[1][2].text]
				mctext = utils.emojiCols(mctext)
				if #mctext < 4096 then
					b_ChatBuffer[1][2].text[#b_ChatBuffer[1][2].text] = utils.MCCheck(mctext)
				end
			end
			
			if not b_ChatBuffer[1][2].text[#b_ChatBuffer[1][2].text] then
				skipped = skipped +1;
				table.remove(b_ChatBuffer[1][2].text, #b_ChatBuffer[1][2].text);
			else
				
			--------------------------------------------------------------------------
			
				textLeft = textLeft-cutIdx;
				if (L_i < n_lines) then 
					newText = string.sub(newText,cutIdx+1,string.len(newText));
				end 
				if par_isCustom then par_LastMode = par_LastMode..'C' end
				table.insert(b_ChatBuffer[1][2].mode, tostring(par_MessageMode)..'|'..par_LastMode);
				if type(col) == 'number' then 
					table.insert(b_ChatBuffer[1][2].color, col);
				else
					table.insert(b_ChatBuffer[1][2].color, 0xFFFFFFFF);
				end
				--if (special_idx ~= nil or par_CombatCutIdx < 0)	then
				if (special_idx ~= nil)	then
					table.insert(b_ChatBuffer[1][2].auxText, dw_ShowMessageMode[1] and (special_text..' >'..tostring(par_MessageMode)..(e.injected and '[i]' or '')) or special_text);
					table.insert(b_ChatBuffer[1][2].auxColor, special_color);
					table.insert(b_ChatBuffer[1][2].url, b_msgID)
				else
					--if auxURL_text ~= '[link]' then 
					if urlText == '' then 
						table.insert(b_ChatBuffer[1][2].auxText, dw_ShowMessageMode[1] and ('>'..tostring(par_MessageMode)..(e.injected and '[i]' or '')) or '');
						table.insert(b_ChatBuffer[1][2].url, b_msgID)
					else
						table.insert(b_ChatBuffer[1][2].auxText, dw_ShowMessageMode[1] and (auxURL_text..'>'..tostring(par_MessageMode)) or auxURL_text);
						table.insert(b_ChatBuffer[1][2].url, tostring(b_msgID)..'|'..urlText);
					end
					table.insert(b_ChatBuffer[1][2].auxColor, 0xFF44CCFF);
				end
				
				if par_tabmode and (par_tabmode ~= 3 and not par_isCustom) then
					--Debug(tostring(tabmode), 1, true);
					table.insert(b_ChatBuffer[2][2].text,b_ChatBuffer[1][2].text[#b_ChatBuffer[1][2].text]);
					--table.insert(b_ChatBuffer[2][2].mode,b_ChatBuffer[1][2].mode[#b_ChatBuffer[1][2].mode]);
					table.insert(b_ChatBuffer[2][2].color,b_ChatBuffer[1][2].color[#b_ChatBuffer[1][2].color]);
					table.insert(b_ChatBuffer[2][2].auxText,b_ChatBuffer[1][2].auxText[#b_ChatBuffer[1][2].auxText]);
					table.insert(b_ChatBuffer[2][2].auxColor,b_ChatBuffer[1][2].auxColor[#b_ChatBuffer[1][2].auxColor]);
					table.insert(b_ChatBuffer[2][2].url,b_ChatBuffer[1][2].url[#b_ChatBuffer[1][2].url]);
				end
				if (par_tabmode and par_tabmode > 2) then	
					
					table.insert(b_ChatBuffer[par_tabmode][2].text,b_ChatBuffer[1][2].text[#b_ChatBuffer[1][2].text]);
					--table.insert(b_ChatBuffer[par_tabmode][2].mode,b_ChatBuffer[1][2].mode[#b_ChatBuffer[1][2].mode]);
					table.insert(b_ChatBuffer[par_tabmode][2].color,b_ChatBuffer[1][2].color[#b_ChatBuffer[1][2].color]);
					table.insert(b_ChatBuffer[par_tabmode][2].auxText,b_ChatBuffer[1][2].auxText[#b_ChatBuffer[1][2].auxText]);
					table.insert(b_ChatBuffer[par_tabmode][2].auxColor,b_ChatBuffer[1][2].auxColor[#b_ChatBuffer[1][2].auxColor]);
					table.insert(b_ChatBuffer[par_tabmode][2].url,b_ChatBuffer[1][2].url[#b_ChatBuffer[1][2].url]);
				end
				if (par_isCustom) then	
					
					table.insert(b_ChatBuffer[8][2].text,b_ChatBuffer[1][2].text[#b_ChatBuffer[1][2].text]);
					--table.insert(b_ChatBuffer[par_tabmode][2].mode,b_ChatBuffer[1][2].mode[#b_ChatBuffer[1][2].mode]);
					table.insert(b_ChatBuffer[8][2].color,b_ChatBuffer[1][2].color[#b_ChatBuffer[1][2].color]);
					table.insert(b_ChatBuffer[8][2].auxText,b_ChatBuffer[1][2].auxText[#b_ChatBuffer[1][2].auxText]);
					table.insert(b_ChatBuffer[8][2].auxColor,b_ChatBuffer[1][2].auxColor[#b_ChatBuffer[1][2].auxColor]);
					table.insert(b_ChatBuffer[8][2].url,b_ChatBuffer[1][2].url[#b_ChatBuffer[1][2].url]);
				end
				if (#b_ChatBuffer[1][2].text > b_ChatBufferMaxSize ) then
					
					local cleanupRanges = {b_CleanupThresh, 0, 0, 0, 0, 0, 0, 0}
					for tr = 1, b_CleanupThresh do
						local tabremove = 0;
						local cremove = 0;
						if (string.find(b_ChatBuffer[1][2].mode[tr], 'C$') ~= nil) then cremove = 8; end
						if (string.find(b_ChatBuffer[1][2].mode[tr], '^combat') ~= nil) then tabremove = 3; 
						elseif (string.find(b_ChatBuffer[1][2].mode[tr], '^linkshell') ~= nil) then tabremove = 4; 
						elseif (string.find(b_ChatBuffer[1][2].mode[tr], '^party') ~= nil) then tabremove = 5; 
						elseif (string.find(b_ChatBuffer[1][2].mode[tr], '^tell') ~= nil) then tabremove = 6; 
						elseif (string.find(b_ChatBuffer[1][2].mode[tr], '^shout') ~= nil) then tabremove = 7; 
						else tabremove = 0;
						end
						if tabremove > 0 then
							if (tabremove ~= 3) then
								cleanupRanges[2] = cleanupRanges[2] + 1
							end
							cleanupRanges[tabremove] = cleanupRanges[tabremove] + 1
						end
						if cremove > 0 then
							cleanupRanges[cremove] = cleanupRanges[cremove] + 1
						end
						
					end
					--Debug(tostring(table.concat(cleanupRanges,',')),1,true)
					for ci = 1, #cleanupRanges do
						BulkRemove(b_ChatBuffer[ci][2], cleanupRanges[ci])
					end
					--b_CombatBufferMaxSize
				elseif (#b_ChatBuffer[3][2].text > b_CombatBufferMaxSize ) then
					local line = {}
					--local cleanupRanges = {b_CleanupThresh}
					local tr = 1
					while #line < b_CleanupThresh and tr < #b_ChatBuffer[1][2].text do
					--for tr = 1, b_CleanupThresh do
						--local tabremove = 0;
						if string.find(b_ChatBuffer[1][2].mode[tr], 'combat') then
							--cleanupRanges[2] = cleanupRanges[2] + 1
							table.insert(line, tr)
							
						end
						tr = tr + 1
					end
					--Debug(tostring(table.concat(cleanupRanges,',')),1,true)
					
					BulkRemove(b_ChatBuffer[3][2], b_CleanupThresh)
					BulkRemoveCombat(b_ChatBuffer[1][2], line)
					
					
				end
				---or #b_ChatBuffer[3][2].text > b_CombatBufferMaxSize
				
				
				---
			end	
			L_i = L_i +1;
		end
		n_lines = n_lines-skipped;
		b_ChatBufferN_All  = b_ChatBufferN_All+n_lines;
		if (par_tabmode ~= 3 and not par_isCustom) then b_ChatBufferN_AllAlt = b_ChatBufferN_AllAlt + n_lines; end
		if allSettings.SelectedTab:find('^All') or allSettings.SelectedTab2:find('^All') then ResetAutoHideTimer() end
		
		if (string.find(par_LastMode, '^combat')) then
			b_ChatBufferN_Combat = b_ChatBufferN_Combat + n_lines;
			if allSettings.SelectedTab == 'Combat' or allSettings.SelectedTab2 == 'Combat' then ResetAutoHideTimer() end
		elseif (string.find(par_LastMode, '^linkshell')) then
			b_ChatBufferN_Linkshell = b_ChatBufferN_Linkshell + n_lines;
			if allSettings.SelectedTab == 'Linkshell' or allSettings.SelectedTab2 == 'Linkshell' then ResetAutoHideTimer() end
		elseif (string.find(par_LastMode, '^party')) then
			b_ChatBufferN_Party = b_ChatBufferN_Party + n_lines;
			if allSettings.SelectedTab == 'Party' or allSettings.SelectedTab2 == 'Party' then ResetAutoHideTimer() end
		elseif (string.find(par_LastMode, '^tell')) then
			b_ChatBufferN_Tell = b_ChatBufferN_Tell + n_lines;
			if allSettings.SelectedTab == 'Tell' or allSettings.SelectedTab2 == 'Tell' then ResetAutoHideTimer() end
		elseif (string.find(par_LastMode, '^shout')) then
			b_ChatBufferN_Shout = b_ChatBufferN_Shout + n_lines;
			if allSettings.SelectedTab == 'Shout' or allSettings.SelectedTab2 == 'Shout' then ResetAutoHideTimer() end
		end
		if (string.find(par_LastMode, 'C$')) then
			b_ChatBufferN_Custom = b_ChatBufferN_Custom + n_lines;
			if allSettings.SelectedTab == 'Custom' or allSettings.SelectedTab2 == 'Custom' then ResetAutoHideTimer() end
		end

	end
	par_LastMessageMode = par_MessageMode;
end

function HandleSpecial(newText, category, prefix, suffix, cutIdx, color, replacements)
	local text_b, text_e, color_b, color_e, MCTable

	if prefix then text_b, text_e = string.find(newText, prefix) else text_b = 1 text_e = 1 end
	--Debug(newText, 1, true)
	if text_b then
		color_b = text_e
		if suffix and prefix then
			color_e = utils.FindLastOfString(newText, suffix, color_b)
		elseif not suffix and prefix then
			color_e = #newText+1
		elseif not prefix then
			--Debug(tostring(string.find(newText, suffix,1,true)),1,true)
			color_b = utils.FindLastOfString(newText, suffix)
			if color_b then
				color_b = color_b-1
				color_e = color_b+1+#suffix
			else
				return {newText, nil, cutIdx}
			end
		end
		--Debug(tostring(color_e)..'-'..tostring(cutIdx),1,true)
		if color_e then
			--Debug('hello',1,true)
			color_e = color_e - 1
			if color_b >= cutIdx then
				
				par_checkAgain = {color_b-cutIdx, category}
				MCTable = {0, 0}
				return {newText, nil, cutIdx}
			else --color_b < cutIdx
				if color_e > cutIdx then
					
					--Debug(newText, 1, true)
					par_checkAgain = {0, category}
					MCTable = {color_b, #newText,color}
					return {newText, MCTable, cutIdx}
				else --color_ <= cutIdx
					
					--Debug(newText, 1, true)
					MCTable = {color_b, color_e, color}
					return {newText, MCTable, cutIdx}
				end
			end
		end
		return {newText, nil, cutIdx}
	elseif par_checkAgain[2] == category then
		--Debug('hello',1,true)
		if suffix then
			color_e = utils.FindLastOfString(newText, suffix)
		elseif not suffix and prefix then
			color_e = #newText+1
		elseif not prefix then
			color_b = utils.FindLastOfString(newText, suffix)
			if color_b then
				color_b = color_b-1
				color_e = color_b+1+#suffix
			else
				return {newText, nil, cutIdx}
			end
		end
		if color_e then
			color_e = color_e - 1
		else
			return {newText, nil, cutIdx}
		end
		MCTable = {par_checkAgain[1], color_e, color}
		return {newText, MCTable, cutIdx}
	end
	return {newText, nil, cutIdx}
end

function CheckSpecial(newText, col, cutIdx)
	
	if set_isCEXI and par_MessageMode == 9 then
		if newText:find('Now accumulating linkshell points for ') or par_checkAgain[2] == 'CE-acc' then
			return HandleSpecial(newText, 'CE-acc', 'Now accumulating linkshell points for ', '%.', cutIdx, allSettings.colors.cexi[1])
		end
		if newText:find('Activity Points: ') or par_checkAgain[2] == 'CE-AP' then
			return HandleSpecial(newText, 'CE-AP', 'Activity Points: ', '%.', cutIdx, allSettings.colors.cexi[1])
		end
		if newText:find('Summit Objective:') or par_checkAgain[2] == 'CE-SO' then
			return HandleSpecial(newText, 'CE-SO', 'Summit Objective:', '%.', cutIdx, allSettings.colors.cexi[1])
		end
		if newText:find(' activity points%.') or par_checkAgain[2] == 'CE-AP2' then
			return HandleSpecial(newText, 'CE-AP2', 'gains', '%.', cutIdx, allSettings.colors.cexi[1])
		end
		if newText:find('Point Accumulation:') or par_checkAgain[2] == 'CE-PA' then
			return HandleSpecial(newText, 'CE-PA', 'Point Accumulation:', '%.', cutIdx, allSettings.colors.cexi[1])
		end
	end
	
	
	if par_MessageMode == 121 then
		if newText:find('You find') or par_checkAgain[2] == 'youfind' then
			if par_checkAgain[2] == '' then
				newText = newText:gsub('You find', 'Found'):gsub(' on ', utils.icons.LOOT..' on ')
				if newText:find(' on the %.') then newText = newText:gsub('%.','{?}.'); cutIdx = cutIdx+3 end
			end
			return HandleSpecial(newText, 'youfind', 'Found', ' on ', cutIdx, allSettings.colors.found[1])
		end
		if set_isCEXI then
			if newText:find('Defeat Mobs') or par_checkAgain[2] == 'CE-DM' then
				return HandleSpecial(newText, 'CE-DM', 'Defeat Mobs ', ' %(', cutIdx,allSettings.colors.cexi[1])
			end
			if newText:find('Quest Accepted:') or par_checkAgain[2] == 'CE-QA' then
				return HandleSpecial(newText, 'CE-QA', nil, utf8.char(0x25C7)..' Quest Accepted:', cutIdx,allSettings.colors.cexi[1])
			end
			if newText:find('Quest Completed:') or par_checkAgain[2] == 'CE-QC2' then
				return HandleSpecial(newText, 'CE-QC2', nil, utf8.char(0x25C6)..' Quest Completed:', cutIdx,allSettings.colors.cexi[1])
			end
			if newText:find('Quest Completed') or par_checkAgain[2] == 'CE-QC' then
				return HandleSpecial(newText, 'CE-QC', nil, utf8.char(0x25C6)..' Quest Completed', cutIdx,allSettings.colors.cexi[1])
			end
		end
		if newText:find(' synthesized ') or par_checkAgain[2] == 'synth' then
			return HandleSpecial(newText, 'synth',  'You synthesized ', '%.', cutIdx,allSettings.colors.obtained[1])
		end
		if newText:find('You throw away ') or par_checkAgain[2] == 'throw' then
			return HandleSpecial(newText, 'throw',  'You throw away ', '%.', cutIdx,allSettings.colors.negative[1])
		end
		if newText:find(' attains level [%d]+!') or par_checkAgain[2] == 'attain' then	
			if par_checkAgain[2] == '' then newText = newText:gsub("%sl", string.upper):gsub('!',' '..utils.icons.LVLUP) cutIdx = cutIdx + 3 end
			return HandleSpecial(newText, 'attain',  ' attains ', nil, cutIdx,allSettings.colors.attain[1])
		end
		if newText:find(' caught ') or par_checkAgain[2] == 'caught2' then
			return HandleSpecial(newText, 'caught2',  fcw[1].PlayerName, '%!', cutIdx,allSettings.colors.obtained[1])
		end
		if newText:find(' learns ') or par_checkAgain[2] == 'learn' then
			return HandleSpecial(newText, 'learn',  fcw[1].PlayerName, '%.', cutIdx,allSettings.colors.learn[1])
		end
		if newText:find(' lot for ') or par_checkAgain[2] == 'lot' then
			par_tabmode = -1;
			par_LastMode = 'lot';
			return HandleSpecial(newText, 'lot',  ' lot for ', '%.', cutIdx,allSettings.colors.lot[1])
		end
		if newText:find('You sell ') or par_checkAgain[2] == 'sell' then
			return HandleSpecial(newText, 'sell',  'You sell ', ' to ', cutIdx,allSettings.colors.obtained[1])
		end
		if newText:find('You buy ') or par_checkAgain[2] == 'buy' then
			return HandleSpecial(newText, 'buy',  'You buy ', ' from ', cutIdx,allSettings.colors.obtained[1])
		end
	end
	
	if par_MessageMode == 142 or par_MessageMode == 151 then
		if newText:find('You obtain.*%.') or par_checkAgain[2] == 'obtain1' then
			return HandleSpecial(newText, 'obtain1', 'You obtain', '%.', cutIdx, allSettings.colors.obtained[1])
		end
		if newText:find('Obtained:') or par_checkAgain[2] == 'obtain2' then
			return HandleSpecial(newText, 'obtain2', 'Obtained:', '%.', cutIdx, allSettings.colors.obtained[1])
		end
		if newText:find(fcw[1].PlayerName..' caught') or par_checkAgain[2] == 'caught' then
			return HandleSpecial(newText, 'caught', fcw[1].PlayerName..' caught ', '%!', cutIdx, allSettings.colors.found[1])
		end
		if newText:find(' obtains ') or par_checkAgain[2] == 'obtain3' then
			return HandleSpecial(newText, 'obtain3', ' obtains ', '%.', cutIdx, allSettings.colors.obtained[1])
		end
		if newText:find('Obtained key item: ') or par_checkAgain[2] == 'KI' then
			return HandleSpecial(newText, 'KI', 'Obtained key item: ', '%.', cutIdx, allSettings.colors.keyitem[1])
		end
		
	end
	
	if par_MessageMode == 121 or par_MessageMode == 142 or par_MessageMode == 131 or par_MessageMode == 127 then
		if newText:find(' obtains ') or par_checkAgain[2] == 'obtain4' then
			if newText:find('gil') then
				if par_checkAgain[2] == '' then newText = newText:gsub('gil%.', 'gil'..utils.icons.GIL) cutIdx = cutIdx +2 end
				return HandleSpecial(newText, 'obtain4', ' obtains ', nil, cutIdx, allSettings.colors.obtained[1])
			else
				return HandleSpecial(newText, 'obtain4', ' obtains ', '%.', cutIdx, allSettings.colors.obtained[1])
			end
		end
		if newText:find('You obtain.*!') or par_checkAgain[2] == 'obtain5' then
			return HandleSpecial(newText, 'obtain5', 'You obtain ', '!', cutIdx, allSettings.colors.obtained[1])
		end
	end
	
	if par_MessageMode == 131 or par_MessageMode == 121 then
		if (newText:find(' gains ') and newText:find('experience')) or par_checkAgain[2] == 'exp' then
			if par_checkAgain[2] == '' then newText = newText:gsub('points%.','points'..utils.icons.EXP) cutIdx = cutIdx+2 end
			par_tabmode = 3
			par_LastMode = 'combat'
			return HandleSpecial(newText, 'exp', ' gains ', nil, cutIdx, allSettings.colors.obtained[1])
		end
		if (newText:find(' gains ') and newText:find('lim')) or par_checkAgain[2] == 'limit' then
			if par_checkAgain[2] == '' then newText = newText:gsub('points%.','points'..utils.icons.EXP) cutIdx = cutIdx+2 end
			par_tabmode = 3
			par_LastMode = 'combat'
			return HandleSpecial(newText, 'lim', ' gains ', nil, cutIdx, allSettings.colors.obtained[1])
		end
	end
	
	if par_MessageMode == 90 or par_MessageMode == 85 then
		if newText:find(' uses ') or par_checkAgain[2] == 'use' then
			return HandleSpecial(newText, 'use', ' uses ', '%.', cutIdx, allSettings.colors.useitem[1])
		end
	end

	if par_MessageMode == 138 then
		if newText:find(' bought ') or par_checkAgain[2] == 'bazaar' then
			return HandleSpecial(newText, 'bazaar', ' bought ', '%.', cutIdx, allSettings.colors.obtained[1])
		end
	end

end

SetBufferN = function(tab)
	if (tab == 'All')		then return b_ChatBufferN_All; 			end
	if (tab == 'AllAlt') 	then return b_ChatBufferN_AllAlt; 		end
	if (tab == 'Combat') 	then return b_ChatBufferN_Combat; 		end
	if (tab == 'Linkshell') then return b_ChatBufferN_Linkshell; 	end
	if (tab == 'Party') 	then return b_ChatBufferN_Party; 		end
	if (tab == 'Tell') 		then return b_ChatBufferN_Tell; 		end
	if (tab == 'Shout') 	then return b_ChatBufferN_Shout; 		end
	if (tab == 'Custom') 	then return b_ChatBufferN_Custom; 		end
	return chatBufferN_All;
end

SetTargetPosX = function(x,y,positionStartX)
	if mvc_Menu1 or uiw.DialogShown then mvc_targetposY = (y/uiw.UISizeY*uiw.UISizeY) -((y*128)/uiw.UISizeY);	return fcw[1].MoveChatPos1; end
	if mvc_Menu2 then mvc_targetposY = (y/uiw.UISizeY*uiw.UISizeY)-((y*250)/uiw.UISizeY); return fcw[1].MoveChatPos2; end
	if mvc_Menu3 then mvc_targetposY = (y/uiw.UISizeY*uiw.UISizeY)-(y*250)/uiw.UISizeY; return fcw[1].MoveChatPos3; end
	if mvc_Menu4 then mvc_targetposY = (y/uiw.UISizeY*uiw.UISizeY)-(y*250)/uiw.UISizeY; return fcw[1].MoveChatPos4; end
	if mvc_Menu5 then mvc_targetposY = (y/uiw.UISizeY*uiw.UISizeY)-(y*160)/uiw.UISizeY; return fcw[1].MoveChatPos1; end
	if mvc_Menu6 then mvc_targetposY = (y/uiw.UISizeY*uiw.UISizeY)-(y*180)/uiw.UISizeY; 
		--print(mvc_targetposY..'-'..fcw[1].Anchor_Y)
		return positionStartX;
	end
	return 0;
end

-- SetLinesVisible = function(fo_id, v)
	-- for i=1, allSettings.ChatLines do
		-- fo_Chat[fo_id][i]:set_visible(v);
		-- fo_Aux[fo_id][i]:set_visible(v);
	-- end
	-- --gdi:render()
-- end

function DumpChat(closingline)
--function DumpChat(mode)
	par_dumping = true
	-- if mode == 2 then
		-- local i = 1
		-- while i <= #b_ChatBuffer[1][2].text do
			-- local j = 1
			-- local nextLine = b_ChatBuffer[1][2].text[i]..' '..b_ChatBuffer[1][2].auxText[i]
			-- local ID =  b_ChatBuffer[1][2].url[i]
			-- while b_ChatBuffer[1][2].url[i+j] == ID and j < 1000 do
				-- nextLine = nextLine..' '..b_ChatBuffer[1][2].text[i+j]..' '..b_ChatBuffer[1][2].auxText[i+j]
				-- j = j + 1
			-- end
			-- for i = 1, #utils.ShiftJISback do
				-- local char = utf8.char(utils.ShiftJISback[i][1])
				-- local bytes = {char:byte(1, #char)}
				-- local chars = ''
				-- for b = 1, #bytes do
					-- chars = chars..string.char(bytes[b])
				-- end
				-- --Debug(tostring(string.find(nextLine, chars)),1,true)
				
				-- nextLine = nextLine:gsub(chars,utils.ShiftJISback[i][2])
			-- end
			-- AshitaCore:GetChatManager():AddChatMessage(tonumber(b_ChatBuffer[1][2].mode[i]:sub(1,b_ChatBuffer[1][2].mode[i]:find('|')-1)), false, utils.cleanMC((nextLine))
			-- coroutine.sleep(1/#b_ChatBuffer[1][2].text)
			-- i = i + j
		-- end
	-- elseif mode == 1 then
		--local start = math.max(1,  #b_OriginalBuffer - 299) 

		for i = 1, #b_OriginalBuffer do
			local msg = b_OriginalBuffer[i]:sub(b_OriginalBuffer[i]:find('|')+1), #b_OriginalBuffer[i]
			for _, FWDchar in ipairs(utils.fwdchars) do
				waitingFWD = msg:endswith(FWDchar)
				if waitingFWD then
					msg = msg:gsub(FWDchar,'');
					break;
				end
			end
			AshitaCore:GetChatManager():AddChatMessage(tonumber(b_OriginalBuffer[i]:sub(1,b_OriginalBuffer[i]:find('|')-1)), false, msg)
			--coroutine.sleep(1/(#b_OriginalBuffer))
		end
		if closingline then	
			print(closingline)
		end
	--end
	par_dumping = false
end

function BulkRemove(buffer, count)
	local hasMode = buffer.mode ~= nil
	local size = #buffer.text
	if count >= size then
		buffer.text = {}
		buffer.mode = {}
		buffer.color = {}
		buffer.auxText = {}
		buffer.auxColor = {}
		buffer.url = {}
	else
		local newText, newMode, newColor, newAuxText, newAuxColor, newUrl = {}, {}, {}, {}, {}, {}
		for i = count + 1, size do
			newText[#newText + 1] = buffer.text[i]
			if hasMode then
				newMode[#newMode + 1] = buffer.mode[i]
			end
			newColor[#newColor + 1] = buffer.color[i]
			newAuxText[#newAuxText + 1] = buffer.auxText[i]
			newAuxColor[#newAuxColor + 1] = buffer.auxColor[i]
			newUrl[#newUrl + 1] = buffer.url[i]
		end
		buffer.text = newText
		if hasMode then
			buffer.mode = newMode
		end
		buffer.color = newColor
		buffer.auxText = newAuxText
		buffer.auxColor = newAuxColor
		buffer.url = newUrl
	end
end

function BulkRemoveCombat(buffer, line)
	local hasMode = buffer.mode ~= nil
	local size = #buffer.text
	
	local newText, newMode, newColor, newAuxText, newAuxColor, newUrl = {}, {}, {}, {}, {}, {}
	local L_i = 1;
	for i = 1, size do
		if L_i > #line or i ~= line[L_i] then
			newText[#newText + 1] = buffer.text[i]
			if hasMode then
				newMode[#newMode + 1] = buffer.mode[i]
			end
			newColor[#newColor + 1] = buffer.color[i]
			newAuxText[#newAuxText + 1] = buffer.auxText[i]
			newAuxColor[#newAuxColor + 1] = buffer.auxColor[i]
			newUrl[#newUrl + 1] = buffer.url[i]
		else
			L_i = L_i + 1
		end
	end
	buffer.text = newText
	if hasMode then
		buffer.mode = newMode
	end
	buffer.color = newColor
	buffer.auxText = newAuxText
	buffer.auxColor = newAuxColor
	buffer.url = newUrl
	
end

function HandleActors(text, scol)
	--text = text:gsub("%-", "%-")
	if scol == '' then scol = 'reset' end
	local orig_text = text;	
	local a1 = 1;
	local a2 = 1;
	
	--text = text:gsub(par_actor1:escape() ,utils.MC(allSettings.colors.actor1[1])..par_actor1..utils.MC('reset'):gsub('%%', '%%%%'),1)
	
	if #par_actor1 > 0 then
		par_handled_actors = true
		local color = allSettings.colors.actor1[1]
		if par_actor1 == fcw[1].PlayerName then color = allSettings.colors.you[1] end
		--text = text:replace(par_actor1,utils.MC(allSettings.colors.actor1[1])..par_actor1..utils.MC('reset'),1)	
		text = text:gsub(par_actor1:escape().."([^%a-])", (utils.MC(color)..par_actor1..utils.MC('reset')):gsub('%%', '%%%%').."%1",1)	
		_, a1 = text:find(par_actor1:escape(), 1, false)
		par_actor1 = '';
		--Debug(a1, 1, true)
	end
	
	--if #par_actorP > 0 and #par_actorP ~= #par_actor1 then
	if #par_actorP > 0 then
		par_handled_actors = true
		local color = allSettings.colors.actor1[1]
		if par_actorP == fcw[1].PlayerName then color = allSettings.colors.you[1] end
		text = text:sub(1,a1)..text:sub(a1+1,#text):replace(par_actorP, utils.MC(color)..par_actorP..utils.MC('reset'),1)
		--if a1 then
			--text = text:replace(par_actorP, utils.MC(allSettings.colors.actor1[1])..par_actorP..utils.MC('reset'),1)
		---else
			--text = text:replace(par_actorP, utils.MC(allSettings.colors.actor1[1])..par_actorP..utils.MC('reset'),1)
		--end
		par_actorP = '';		
		--Debug(text, 1, true)
	end
	
	
	if #par_actor2 > 0 then
		par_handled_actors = true
		--text = text:sub(1,a2)..text:sub(a2+1,#text):replace(par_actor2, utils.MC(allSettings.colors.actor2[1])..par_actor2..utils.MC('reset'),1)
		text = text:gsub(par_actor2:escape().."([^%a-])", (utils.MC(allSettings.colors.actor2[1])..par_actor2..utils.MC('reset')):gsub('%%', '%%%%').."%1",1)	
		_, a2 = text:find(par_actor2:escape(), 1, false)
		par_actor2 = '';
		--Debug(text, 1, true)
	end
	
	--if #par_actorE > 0 and #par_actorE ~= #par_actor2 then
	if #par_actorE > 0 then
		par_handled_actors = true
		--Debug(text:sub(a2+1,#text), 1, true)
		--text = text:replace(par_actorE, utils.MC(allSettings.colors.actor2[1])..par_actorE..utils.MC('reset'),1)
		text = text:sub(1,a2)..text:sub(a2+1,#text):replace(par_actorE, utils.MC(allSettings.colors.actor2[1])..par_actorE..utils.MC('reset'),1)
		par_actorE = '';
		
	end

	if #par_action1 > 0 then
		par_handled_actors = true
		text = text:replace(par_action1, utils.MC(allSettings.colors.ability[1])..par_action1:gsub('\\','['):gsub('/',']')..utils.MC(scol),1)
		par_action1 = '';
		
	end
	
	return text
end

function HELMtext(t, text)
	local s = 0
	local e = 0
	local c = allSettings.colors.helm[1]
	if t[1] == 'harvest'
	or t[1] == 'dig up'
	or t[1] == 'cut off'
	then
		
		s = text:find(t[1],1, true)
		if s then
			s = s + #t[1]
			e = text:find(t[2], s, true)
			if not e then e = #text end
			if e then e = e - 1 end
			return {s, e, c}
		else
			s = 0
			e = text:find(t[2], s, true)
			if e then
				e = e - 1
				return {s, e, c}
			end
		end
		
	end
	return false
end 

function FindHELM(text, mode)
	
	if mode ~= 9 and mode ~= 151 then return false end
	if text:find(':', #par_LastTS, true) then return false end
	
	local f = text:find(' harvest ')
	if f then
		local opening = 'harvest'
		local closing = text:find('!', f, true) and '!' or nil
		if not closing then
			closing = text:find(',', f, true) and ',' or nil
		end
		if closing then return {opening, closing} end
	end
	
	f = text:find(' dig up ')
	if f then
		local opening = 'dig up'
		local closing = text:find('!', f, true) and '!' or nil
		if not closing then
			closing = text:find(',', f, true) and ',' or nil
		end
		if closing then return {opening, closing} end
	end
	
	f = text:find(' cut off ')
	if f then
		local opening = 'cut off'
		local closing = text:find('!', f, true) and '!' or nil
		if not closing then
			closing = text:find(',', f, true) and ',' or nil
		end
		if closing then return {opening, closing} end
	end
	
	return false
end

function ResetAutoHideTimer()
	fcw[1].autoHideTime = os.time()
end

function DrawInfoWin(maxh, idx, name, text, icon)
	
	if not maxh then maxh = 0 end
	local font = imgui.GetFont();
	local fontSize = font.FontSize or font.LegacySize;
	local W = (allSettings.UseHalfLength[1] and fcw[1].BG_W/2 or fcw[1].BG_W)/4;
	--local H = (fontSize*16)/((allSettings.chatLineMaxL*allSettings.fontSettings.font_height)/1800);
	--local H = 32 + (3750 * fontSize / W);
	local font = imgui.GetFont()
	--local test = font:FindGlyph(font.EllipsisChar)
	--local textwW, TextwH = font:CalcTextSizeA(imgui.GetFontSize(), FLT_MAX, W-16, text[1])
	--local textW, TextH = imgui.CalcTextSize(text)
	local H = maxh
	--print(H)
	--print(textW..textwW)
	
	imgui.SetNextWindowPos({ro_RectBG[1].settings.position_x+(W*(idx-1)),ro_RectBG[1].settings.position_y-H});
	imgui.SetNextWindowSize({ W, H });
	imgui.SetNextWindowSizeConstraints({ W, H }, { FLT_MAX, FLT_MAX, });
	local wFlags =bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoBringToFrontOnFocus, ImGuiWindowFlags_NoFocusOnAppearing,ImGuiWindowFlags_NoMove,ImGuiWindowFlags_NoSavedSettings)

	PushWindowStyle()
					
	if imgui.Begin('##Info'..tostring(idx), true, wFlags) then
		
		
		
		--imguiWrap.BeginChild('##InfoChild'..tostring(idx), {imgui.GetWindowWidth()-16,fontSize+fontSize*math.floor(imgui.CalcTextSize(text)/(imgui.GetWindowWidth()-math.min(imgui.CalcTextSize(help.GetLongestWord(text)),(imgui.GetWindowWidth()-100)/2)))+16}, true);
		imguiWrap.BeginChild('##InfoChild'..tostring(idx), {imgui.GetWindowWidth()-16,imgui.GetWindowHeight()-16},true,ImGuiWindowFlags_NoScrollbar);
		local cx = imgui.GetCursorPosX()
		if icon then
			imguiWrap.Image(icon, { 32, 32 }); imgui.SameLine();
			imgui.SetCursorPosY(imgui.GetCursorPosY())
		end
		imgui.PushTextWrapPos(imgui.GetWindowWidth()-16)
		imgui.TextWrapped(name)
		imgui.SetCursorPosX(cx)
		if not icon then imgui.Dummy({0,5}) end
		imgui.TextWrapped(text)
		imgui.PopTextWrapPos()
		imgui.EndChild()
		imgui.End();
	end
	PopWindowStyle();

end

function DrawInfo(text)

	local drawcalls = {}
	local H = 0
	
	
	local info = {}
	
	local ATstart = 1
	while ATstart < #text do
		
		local s, e = string.find(text, utf8.char(0x276e), ATstart, true)
		if s and e then
			local s2, e2 = string.find(text, utf8.char(0x276f), e+1, true)
			if s2 and e2 then
				local subtext = text:sub(e+1,s2-1)
				subtext = subtext:gsub("([%l%d%.])(%u)", "%1 %2"):gsub('  ',' ')
				table.insert(info, subtext)
				ATstart = e2 + 1
			end
			ATstart = e + 1
		else
			break
			--ATstart = ATstart + 1
		end
	end
	
	if #info < 1 then
		fcw[1].itemInfo = {}
		return
	end
	
	local updated = false
	local update_idx = 1;
	if #fcw[1].itemInfo ~= #info then
		updated = true
		fcw[1].itemInfo = {}
		
	end
	
	while update_idx <= #info do
		--Debug(tostring(fcw[1].itemInfo[update_idx])..'-'..tostring(info[update_idx]),1,true)
		if fcw[1].itemInfo[update_idx] ~= info[update_idx] then
			
			updated = true
			--info[update_idx] = info[update_idx]
			fcw[1].itemInfo[update_idx] = info[update_idx]
		end
		update_idx = update_idx + 1
	end
	
	--print('updated: '..tostring(updated))
	--Debug('---',1,true)
	--updated = true

	--updated = true
	local idx = 1
	for i = 1, #info do
		
		
		if idx > 4 then break end
		--if info[i] and info[i] then
		if info[i] then
		
			local item
			local ability
			local spell
			--if fcw[1].itemIcons[idx] and fcw[1].itemIcons[idx][3] and info[i] == fcw[1].itemIcons[idx][3] then
			--Debug(tostring(updated),1,true)
			if not updated then
				if info[i] == fcw[1].itemIcons[idx][3] then
					if fcw[1].itemIcons[idx][5] == 1 then
						item = fcw[1].itemIcons[idx][4]
					elseif fcw[1].itemIcons[idx][5] == 2 then
						ability = fcw[1].itemIcons[idx][4]
					elseif fcw[1].itemIcons[idx][5] == 3 then
						spell = fcw[1].itemIcons[idx][4]
					end
				end
			else
				local RM = AshitaCore:GetResourceManager()
				if not item then
					item = RM:GetItemByName(info[i], 0);
					--print('updated item '..tostring(item))
				end
				if not item then
					ability = RM:GetAbilityByName(info[i], 0);
				end 	
				if not ability then
					spell = RM:GetSpellByName(info[i], 0);
				end
			end
			--and (item.Type == 1 or item.Type == 4 or item.Type == 5 or item.Type == 7)
			--print(item.Description)
			if item and item.Description and item.Description[1] then
				
				--idx = idx + 1
				--if fcw[1].itemIcons[idx][1] and item.Id ~= fcw[1].itemIcons[idx][1] then 
				--if not fcw[1].itemTexture[idx] then
				--fcw[1].itemIcons[idx][1] = item.Id
				fcw[1].itemIcons[idx][3] = info[i]
				fcw[1].itemIcons[idx][4] = item
				fcw[1].itemIcons[idx][5] = 1
				--fcw[1].itemTexture[idx] = utils.ItemIcon(item.Bitmap, item.ImageSize)
				fcw[1].itemTexture[idx][1] = utils.ItemIcon(item.Bitmap, item.ImageSize)
				fcw[1].itemTexture[idx][2] = tonumber(ffi.cast('uint32_t', fcw[1].itemTexture[idx][1]))
				--Debug(tostring('loadingtex'),1,true)
				--print('updated icons')
				--end
				
				
				--local iconID = tonumber(ffi.cast('uint32_t', fcw[1].itemTexture[idx]))
				
				local inf = ''

				local flags = ''
				flags = flags..(bit.band(0x8000,item.Flags)~= 0 and '[Rare]' or '' )
				flags = flags..(bit.band(0x6040,item.Flags)~= 0 and '[Ex]' or '' )
				if flags ~= '' then
					inf = inf..flags..'\n'--..string.rep('-',#flags)..'\n'
				end
				--inf = inf..item.Id..'\n'
				--inf = inf..item.Type..'\n'
				-- misc= 1, weapon= 4, armor = 5, consumable = 7
				-- print('idx: '..tostring(i))
				-- print('info: '..tostring(info[i]))
				-- print('desc: '..tostring(item.Description))
				-- print(item.Description[1]) end
				-- print('---')
				local desc = item.Description[1]
				if desc then
					desc = desc:replace('\x81\x60', '~'):replace('\xEF\x1F', 'Fire'):replace('\xEF\x20', 'Ice'):replace('\xEF\x21', 'Wind'):replace('\xEF\x22', 'Earth'):replace('\xEF\x23', 'Lgtn'):replace('\xEF\x24', 'Water'):replace('\xEF\x25', 'Light'):replace('\xEF\x26', 'Dark'):replace('%', '%%'):replace('\n',' ')

					if item.Type == 4 or item.Type == 5 then
						
						--slot,race,desc,lvl,job
						inf = inf..'['..utils.equipSlots[item.Slots]..'] '..utils.equipRaces[item.Races]..'\n'
						inf = inf..desc..'\n'
						inf = inf..'Lv: '..item.Level..' '..utils.GetEquipJobs(item.Jobs)
					else--if item.Type == 1 or item.Type == 7 then
						inf = inf..desc
					end
					--fcw[1].itemIcons[idx][2] = inf
					
					--local textW, TextH = imgui.CalcTextSize(info[i]..fcw[1].itemIcons[idx][2])
					--H = math.max(H, TextH * ((textW/((fcw[1].BG_W/4)-16))+2))
					H = math.max(H, ((imgui.GetFontSize()*1)*(utils.CalcRows(inf, ((allSettings.UseHalfLength[1] and fcw[1].BG_W/2 or fcw[1].BG_W)/4)-32,imgui.CalcTextSize('H'))+1)+28+40))--+(#flags>0 and 1 or 0)
					table.insert(drawcalls, {idx, info[i], inf, fcw[1].itemTexture[idx][2]})
					
					--DrawInfoWin(idx,info[i],fcw[1].itemIcons[idx][2], fcw[1].itemTexture[idx][2])
					idx = idx + 1
				end
				
			elseif ability and ability.Description and ability.Description[1] then
				--idx = idx + 1
				--fcw[1].itemIcons[idx][1] = nil
				if fcw[1].itemTexture[idx] then
					fcw[1].itemTexture[idx][2] = nil
					utils.ItemIconRelease(fcw[1].itemTexture[idx][1])
				end
				utils.ItemIconRelease(fcw[1].itemTexture[idx][1])
				fcw[1].itemIcons[idx][3] = info[i]
				fcw[1].itemIcons[idx][4] = ability
				fcw[1].itemIcons[idx][5] = 2
				local inf = ''
				if ability.Type == 1 then inf = '[Job Ability]\n'
				elseif ability.Type == 2 then inf = '[Pet Command]\n'
				elseif ability.Type == 3 then inf = '[Weaponskill]\n'
				elseif ability.Type == 4 then inf = '[Job Trait]\n' end
				local desc = ability.Description[1]
				if desc then
					desc = desc:replace('\x81\x60', '~'):replace('\xEF\x1F', 'Fire'):replace('\xEF\x20', 'Ice'):replace('\xEF\x21', 'Wind'):replace('\xEF\x22', 'Earth'):replace('\xEF\x23', 'Lgtn'):replace('\xEF\x24', 'Water'):replace('\xEF\x25', 'Light'):replace('\xEF\x26', 'Dark'):replace('%', '%%'):replace('\n',' ')
					if ability.TPCost > 0 then inf = inf..'TP: '..ability.TPCost..'\n' end
					if ability.ManaCost > 0 then inf = inf..'MP: '..ability.ManaCost..'\n' end
					inf = inf..desc
					--local textW, TextH = imgui.CalcTextSize(info[i]..inf)
					--H = math.max(H, TextH * ((textW/((fcw[1].BG_W/4)-16))+3))
					H = math.max(H, ((imgui.GetFontSize()*1)*(utils.CalcRows(inf, ((allSettings.UseHalfLength[1] and fcw[1].BG_W/2 or fcw[1].BG_W)/4)-32,imgui.CalcTextSize('H'))+3)+28))
					table.insert(drawcalls, {idx, info[i], inf, nil})
					--DrawInfoWin(idx,info[i],inf)
					idx = idx + 1
					--idx = idx + 1
				end
			elseif spell and spell.Description and spell.Description[1]then
				--idx = idx + 1
				
				--fcw[1].itemIcons[idx][1] = nil
				if fcw[1].itemTexture[idx] then
					fcw[1].itemTexture[idx][2] = nil
					utils.ItemIconRelease(fcw[1].itemTexture[idx][1])
				end
				fcw[1].itemIcons[idx][3] = info[i]
				fcw[1].itemIcons[idx][4] = spell
				fcw[1].itemIcons[idx][5] = 3
				local inf = '[Spell]\n'
				local desc = spell.Description[1]
				if desc then
					desc = desc:replace('\x81\x60', '~'):replace('\xEF\x1F', 'Fire'):replace('\xEF\x20', 'Ice'):replace('\xEF\x21', 'Wind'):replace('\xEF\x22', 'Earth'):replace('\xEF\x23', 'Lgtn'):replace('\xEF\x24', 'Water'):replace('\xEF\x25', 'Light'):replace('\xEF\x26', 'Dark'):replace('%', '%%'):replace('\n',' ')
					--if spell.TPCost > 0 then inf = inf..'TP: '..spell.TPCost..'\n' end
					if spell.ManaCost > 0 then inf = inf..'MP: '..spell.ManaCost..'\n' end
					inf = inf..desc
					--local textW, TextH = imgui.CalcTextSize(info[i]..inf)
					--H = math.max(H, TextH * ((textW/((fcw[1].BG_W/4)-16))+3))
					H = math.max(H, ((imgui.GetFontSize()*1)*(utils.CalcRows(info[i]..inf,((allSettings.UseHalfLength[1] and fcw[1].BG_W/2 or fcw[1].BG_W)/4)-32,imgui.CalcTextSize('H'))+3)+28))
					table.insert(drawcalls, {idx, info[i], inf, nil})
					--DrawInfoWin(idx,info[i],inf)
					idx = idx + 1
					--idx = idx + 1
				end
			end
		else
			break
		end
	end
	
	for del_i = idx, 4 do
		-- fcw[1].itemIcons[del_i][1] = 0
		-- fcw[1].itemIcons[del_i][2] = ''
		-- fcw[1].itemIcons[del_i][3] = ''
		-- fcw[1].itemIcons[del_i][4] = nil
		-- fcw[1].itemIcons[del_i][5] = 0
		fcw[1].itemIcons[del_i] = {}
		if fcw[1].itemTexture[del_i] then
			fcw[1].itemTexture[del_i][2] = nil
			utils.ItemIconRelease(fcw[1].itemTexture[del_i][1])
		end

	end
	
	for d = 1, #drawcalls do
		--print(d)
		if drawcalls[d][4] then
			DrawInfoWin(H, drawcalls[d][1],drawcalls[d][2],drawcalls[d][3],drawcalls[d][4])
		else
			DrawInfoWin(H, drawcalls[d][1],drawcalls[d][2],drawcalls[d][3])
		end
	end
	--Debug(tostring(fcw[1].itemTexture[idx]),1,true)

end

