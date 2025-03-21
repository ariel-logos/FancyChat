addon.name      = 'fancychat';
addon.author    = 'Arielfy';
addon.version   = '0.4';
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

local timeStart = 0;
local timeMax = 0;
local fpsTimer = 0
local fpsCount = 0
local fpsFrame = 0
local testWindow = 0
local testResult = 0
-- Legacy chat window variables --

local uiw = T{
		MenuDescPTR,
		MenuDesc,
		LegacyChatOpen = false,
		LastMenu = {'',0},
		MenuCD = 0,
		InvIdx = 0,
		NoShiftIdx = 0,
		InvType = 0,
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
		DisplayItemPtr,
		WinOpenPtr,
		WinOpenPtr2,
		UISizeYPtr,
		UISizeXPtr,
		EventPtr,
		--MaxWinSizeY,
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
local mvc_targetposY = 0;
local mvc_targetposX = 0;

-- Fancy chat window variables --

local fcw = T{
	T{	
		LoginStatus,
		Zoning = false,
		ProcessingText = false,
		OutlineColor = 0xFF000000,
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
		Chat1WindowPosX = 0,
		Chat1WindowPosY = 0, 
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
		OutlineColor = 0xFF000000,
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
	}
}

-- Tabs window variables --

local tab_NextTab = 'All';
local tab_NextTab2 = 'All';
local tab_Tabs = {'All','Combat','Linkshell','Party','Tell','Shout','NPC'};
--local tab_Tabs_Alt = {'All','Combat','Linkshell','Party','Tell','Shout','NPC'};
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
local set_Popup = {false}
local set_PickedColor = T{1,1,1,1}
local set_ChatLineMaxL = 100
local set_PlateBGColor = 0x4D000000
local set_FontHeight = 20;
local set_ChatLines = 8;
local set_SecondChat = T{false}
local set_AdjWin1 = T{false};
local set_AdjWin2 = T{false};
local set_CombatSplitCharList = {{'Greater >',0x003E}, {'Column :',0x003A}, {'Tilde ~',0x007E}, {'Bullet',0x2022}, {'Bullet hypen',0x2043}, {'R.Triangle',0x25B6}};

-- Debug window variables --
local dw_PLRCount = 0;
local dw_WindowOpened = T{false};
local dw_Window_W = 600;
local dw_Window_H = 400;
local dw_TestMessage = '';
local dw_TestMessage2 = '';
local dw_ShowMessageMode = T{false};
local dw_ChannelColorMode = T{false};
local dw_testPTR;

-- Text parsing variables --

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
local par_LastMessageMode = 0;
local par_promptEnd = {};

-- Chat buffers variables --
local b_LogBuffer = T{}; --<<<--------------------DELETE FOR RELEASE----------------
local b_OriginalBuffer = T{}; --<<<--------------------DELETE FOR RELEASE----------------
local b_msgID = 1;
local b_ChatBufferMaxSize = 800;
local b_ChatBufferN_All = 0;
local b_ChatBufferN_AllAlt = 0;
local b_ChatBufferN_Linkshell = 0;
local b_ChatBufferN_Party = 0;
local b_ChatBufferN_Tell = 0;
local b_ChatBufferN_Combat = 0;
local b_ChatBufferN_Shout = 0;
local b_ChatBufferN_NPC = 0;
local b_CleanupThresh = 100;
local b_ChatBufferIdx = T{0, 0};
local b_ChatBufferN = T{0, 0};
local b_ChatBufferMode = T{1, 1}; -- 1=All, 2=combat, 3=Linkshell, 4=Party, 5= tell,  6=shout, 7 = npc
local b_ChatBuffer = T{
	{	'All',		T{ text = T{};	mode = T{}; color = T{}; auxText = T{}; auxColor = T{}; url = T{};} },
	{	'AllAlt',	T{ text = T{};	mode = T{}; color = T{}; auxText = T{}; auxColor = T{}; url = T{};}	},
	{	'Combat',	T{ text = T{};	mode = T{}; color = T{}; auxText = T{}; auxColor = T{}; url = T{};}	},
	{	'Linkshell',T{ text = T{};	mode = T{}; color = T{}; auxText = T{}; auxColor = T{};	url = T{};}	},
	{	'Party',	T{ text = T{};	mode = T{}; color = T{}; auxText = T{}; auxColor = T{};	url = T{};}	},
	{	'Tell',		T{ text = T{};	mode = T{}; color = T{}; auxText = T{}; auxColor = T{};	url = T{};}	},
	{	'Shout',	T{ text = T{};	mode = T{}; color = T{}; auxText = T{}; auxColor = T{};	url = T{};}	},
	{	'NPC',		T{ text = T{};	mode = T{}; color = T{}; auxText = T{}; auxColor = T{};	url = T{};}	}
};

-- Font/Rect objects --

local fo_Fwd = T{};
local fo_Bkw = T{};
local fo_Chat = T{T{}, T{}};
local fo_Aux =  T{T{}, T{}};
local ro_RectBG = T{};
local ro_Scroll = T{};

local allSettings = T{
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
	defaultColor = 		T{1,1,1,1},
	linkshellColor = 	T{1,1,1,1},
	linkshell2Color = 	T{1,1,1,1},
	partyColor = 		T{1,1,1,1},
	tellColor = 		T{1,1,1,1},
	shoutColor = 		T{1,1,1,1},
	emoteColor = 		T{1,1,1,1},
	combatColor = 		T{1,1,1,1},
	combatspellColor = 	T{1,1,1,1},
	dmgColor = 			T{1,1,1,1},
	dmgDoneColor = 		T{1,1,1,1},
	dmgGotColor = 		T{1,1,1,1},
	spelldmgColor = 	T{1,1,1,1},
	spelldmgDoneColor = T{1,1,1,1},
	spelldmgGotColor = 	T{1,1,1,1},
	ColorBlind = 		T{false},
	shortcutHide = 	46,
	shortcutTab = 	45,
	shortcutTab2 = 	48,
	shortcutHideS = 42,
	shortcutTabS = 	42,
	shortcutTab2S = 42,
	shortcutHideEnabled = T{false},
	shortcutTabEnabled = T{false},
	shortcutTab2Enabled = T{false},
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

ashita.events.register('d3d_present', 'present_cb', function ()

	timeStart = os.clock()
	--print('hello'..tostring(os.clock()))
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
					Debug('restarting', 1, false)
					--if fcw[1].LoggedLobby == 1 then fcw[1].LoggedLobby = 0; end
					allSettings.PlayerName = settings.name;
					SaveSettings();
					fcw[1].Closing = true;
					AshitaCore:GetChatManager():QueueCommand(-1, "/addon reload fancychat")
				end
			end
			return
		end;
	
		if allSettings.timeStampLine[1] then
			local secondsTime = os.time() % allSettings.timeStampLineFreq[2]
			--Debug(tostring(allSettings.timeStampLineFreq[2]), 1, false);
			if secondsTime == 0 then
				if par_timePrinted == false then
					local stringWrap = '';
					for _ = 1, math.floor((allSettings.chatLineMaxL)/2) - 5 do
						stringWrap = stringWrap..'\x81\xAC'
					end
					AshitaCore:GetChatManager():QueueCommand(1, '/echo '..stringWrap..os.date(par_FormatTS[2], os.time())..stringWrap);
					par_timePrinted = true;
				end
			else
				par_timePrinted = false
			end;
		else
			par_timePrinted = true
		end
	
		fcw[1].PlayerName = settings.name;
		
		par_InEvent = ashita.memory.read_uint8(ashita.memory.read_uint32(uiw.EventPtr + 1)) == 1
	

		uiw.MemValue = bit.band(ashita.memory.read_uint32(ashita.memory.read_uint32(uiw.WinPtr1)+0x42),0x0000FFFF);
		if (uiw.MemValue ~= 0) then
			local margin = 15;
			if (uiw.LastMemValue ~= -1 and uiw.LastMemValue >= uiw.MemValue and uiw.MemValue < uiw.UISizeY-19-margin) then
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
			if not MenuName:match('menu[%s]+inline') then
				mvc_Menu1 = false;  mvc_Menu2 = false;  mvc_Menu3 = false;  mvc_Menu4 = false; mvc_Menu5 =false;
				if (MenuName:match('menu[%s]+inventor')) or (MenuName:match('menu[%s]+loot')) or (MenuName:match('menu[%s]+comyn')) or (MenuName:match('menu[%s]+comment')) then mvc_Menu1 = true; 
				elseif (MenuName:match('menu[%s]+magic')) or (MenuName:match('menu[%s]+ability'))  or (MenuName:match('menu[%s]+mount')) or (MenuName:match('menu[%s]+emote')) then mvc_Menu2 = true; 
				elseif (MenuName:match('menu[%s]+magselec')) then mvc_Menu3 = true; 
				elseif  (MenuName:match('menu[%s]+jobcselu')) then mvc_Menu4 = true;
				elseif (MenuName:match('menu[%s]+mogdoor')) or (MenuName:match('menu[%s]+arealist')) or (MenuName:match('menu[%s]+maplist')) or MenuName:match('menu[%s]+gmtell')  or MenuName:match('menu[%s]+merityn') then mvc_Menu5 = true;
				end
			end
		else
			mvc_Menu1 = false;  mvc_Menu2 = false;  mvc_Menu3 = false;  mvc_Menu4 = false; mvc_Menu5 =false;
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
				uiw.MenuDescPTR2 = ashita.memory.read_uint32(uiw.MenuDescPTR+0x54);
				uiw.MenuDescPTR2 = ashita.memory.read_uint32(uiw.MenuDescPTR2+0x0C);
			
				uiw.MenuDescPTR2 = ashita.memory.read_uint32(uiw.MenuDescPTR2+0x40);
				uiw.MenuDesc =  ashita.memory.read_string(uiw.MenuDescPTR2,64);
				MenuLabel[3] = uiw.MenuDesc;
			end
			
			if MenuID ~= 0 and MenuLabel[1]~='menuinline' and MenuLabel[1]~='menumcr1pall' and MenuLabel[1]~= 'menumcr2pall' then
				for M_i = #uiw.MenuList-1, 1, -1 do
					--Debug(M_i,2,true);
					--print((MenuLabel[2] == 11));
					if 	((MenuLabel[1]==uiw.MenuList[M_i][1] and	MenuLabel[1]~='menuinventor')
						or
						--(MenuLabel[1]=='menuinventor'and MenuLabel[1]==uiw.MenuList[M_i][1] and uiw.MenuList[#uiw.MenuList][1]~='menuinventor')
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
				elseif uiw.MenuList[i][1]:find('menubank') then uiw.NoShiftIdx = i 
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
			list = list..','..uiw.MenuList[i][1]..'-'..tostring(uiw.MenuList[i][2])
		end
		--menu list
		--Debug(tostring(list),1,false);
				
		
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
			fcw[1].MoveChat = (mvc_Menu1 or mvc_Menu2 or mvc_Menu3 or mvc_Menu4 or mvc_Menu5 or uiw.DialogShown) and allSettings.LockWindowPos[1] and allSettings.EnabledChatMove[1];
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
			
			ChangeTab(1, tab_NextTab);
			b_ChatBufferN[1] = SetBufferN(allSettings.SelectedTab);
			ResetScrolling(1);
		else
			b_ChatBufferN[1] = SetBufferN(allSettings.SelectedTab);
		end
		
		
		
		
		if allSettings.SelectedTab == 'All' and allSettings.HideCombatFromAll[1] then b_ChatBufferN[1]=b_ChatBufferN_AllAlt;  end
		

		local dsize = imgui.GetIO().DisplaySize;
		
		
		--Debug(tors(not LegacyChatOpen and not fcw[1].HideChat and not fcw[1].Closing)), 1, true);
	-- Render All FancyChat windows --
		local windowFlags = 0
	
		if (not uiw.LegacyChatOpen and not fcw[1].HideChat and not fcw[1].Closing) then
			
			
			--fcw[1].BG_W = allSettings.fontSettings.font_height*allSettings.ChatLines*fcw[1].BGScale*2;
			
			
			imgui.SetNextWindowSize({ fcw[1].BG_W, ro_RectBG[1].settings.height+16 }, ImGuiCond_Once);
			imgui.SetNextWindowSizeConstraints({ fcw[1].BG_W, ro_RectBG[1].settings.height+16 }, { FLT_MAX, FLT_MAX, }, ImGuiCond_Once);
			
			--local extraFlags = 0
			--if allSettings.LockWindowPos[1] then extraFlags = (ImGuiWindowFlags_NoMove); end
			--imgui.SetNextWindowPos({100,100});
			imgui.Begin('FancyChat_ChatBG_'+fcw[1].PlayerName, true, bit.bor(fcw[1].windowFlagsChatBG, allSettings.LockWindowPos[1] and ImGuiWindowFlags_NoMove or 0));
		-- Setting variables to position the chat window elements --
			
			
			fcw[1].Chat1WindowPosX, fcw[1].Chat1WindowPosY = imgui.GetWindowPos();
			
		
			local positionStartX, positionStartY = imgui.GetCursorScreenPos();
			positionStartX = positionStartX + allSettings.WindowPosOffset[1];
			positionStartY = positionStartY + allSettings.WindowPosOffset[2];
			
			--Debug(tostring(dsize.y/uiw.UISizeY*uiw.UISizeY),2, false)
			--print(tostring(mvc_Menu1));
			mvc_targetposY = 0;
			mvc_targetposX = 0;
			if fcw[1].MoveChat then
				mvc_targetposX = SetTargetPosX(dsize.x,dsize.y);
			end
			
			if not chat2moved then
				if not allSettings.GuideMeSecondWindow[1] then fcw[1].GuideMeClosedTmp = false; end
				if fcw[1].MoveChat and positionStartX < mvc_targetposX
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
				and imgui.IsWindowHovered(ImGuiHoveredFlags_RectOnly)
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
						mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+allSettings.fontSettings.font_height and not fcw[1].Dragging
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
								 ashita.misc.open_url(string.find(b_ChatBuffer[b_ChatBufferMode[1]][2].url[ChatHoverIdx], 'https://')and b_ChatBuffer[b_ChatBufferMode[1]][2].url[ChatHoverIdx] or 'https://'..b_ChatBuffer[b_ChatBufferMode[1]][2].url[ChatHoverIdx]); end
								
								end
								fcw[1].HoverLine = -1;
							end
							break
						else
							if (fo_Aux[1][targetLine]~= nil and fo_Aux[1][targetLine].settings.text == '[link]') then
								fo_Aux[1][targetLine]:set_font_color(0xFF44CCFF);
							end
							if (mouseX > fcw[1].Anchor_X and mouseX < fcw[1].Anchor_X+fcw[1].BG_W and
							mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+allSettings.fontSettings.font_height and
							(imgui.IsWindowHovered(ImGuiHoveredFlags_RectOnly) or (fcw[1].MoveChat and IsRectHovered(ro_RectBG[1].settings,0)))
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
							break
						end
						
					end
					
				end
				
			end 
			
			if (fcw[1].HoverLine > 0 and imgui.IsMouseClicked(ImGuiMouseButton_Left)) then fcw[1].Clicking = true; end
			
			if (fcw[1].HoverLine > 0 and fcw[1].Clicking and imgui.IsMouseReleased(ImGuiMouseButton_Left) and imgui.IsWindowHovered(ImGuiHoveredFlags_RectOnly)) then
				fcw[1].Clicking = false;
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
					copyBufferText = (' '..copyBufferText..b_ChatBuffer[b_ChatBufferMode[1]][2].text[copyBufferIdx+IDi]):trimex()
					if b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] ~= '[link]' then
						copyBufferText = copyBufferText..' '..b_ChatBuffer[b_ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi]
					end
					IDi = IDi + 1;
				end
				end
				--print(copyBufferText)
				if(copyBufferText ~=nil) then
					if imgui.GetIO().KeyShift then
						if #allSettings.Notes < 10 and #copyBufferText > 0 then
							table.insert(allSettings.Notes, copyBufferText)
							SaveSettings();
						end
					else
						utils.SetClipboardText(utils.RevertShiftJIT(copyBufferText))
						AshitaCore:GetChatManager():QueueCommand(1, "/echo Text successfully copied to clipboard!");
					end
				end
			end
		
			if (fcw[1].Clicking and (imgui.IsMouseDragging(ImGuiMouseButton_Left) or not imgui.IsMouseDown(ImGuiMouseButton_Left) )) then fcw[1].Clicking = false; end
		

		-- Setting up line scrolling --
			local scrollOffset= (fcw[1].BG_H/120);

			if (mouseX > fcw[1].Anchor_X and mouseX < fcw[1].Anchor_X+fcw[1].BG_W and
			mouseY > positionStartY+scrollOffset and mouseY < positionStartY+scrollOffset+allSettings.fontSettings.font_height*(allSettings.ChatLines+1)
			and imgui.IsWindowHovered(ImGuiHoveredFlags_RectOnly)
			)
			then
				if (
					fcw[1].ScrollDelta > 0
					
					and utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[1]][2].text) - fcw[1].ScrolledBack - (b_ChatBufferN[1]-b_ChatBufferIdx[1]) > allSettings.ChatLines
				)
				then
					fcw[1].ScrollDelta = 0;
					fcw[2].ScrollDelta = 0;
					fcw[1].Scrolling = true;
					fcw[1].ChatShift = allSettings.fontSettings.font_height
					fcw[1].ScrollUpRequest = true;
				else
					if ( fcw[1].ScrollDelta < 0 and fcw[1].ScrolledBack > 0 ) then
						fcw[1].ScrollDelta = 0;
						fcw[2].ScrollDelta = 0;
						fcw[1].Scrolling = true;
						fcw[1].ChatShift = allSettings.fontSettings.font_height
						fcw[1].ScrollDownRequest = true;

					end
				end
			
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
				fcw[1].compactPos = {fcw[1].Anchor_X+(ro_RectBG[1].settings.width-(tabsW/#tab_Tabs))*0.994-9, fcw[1].Anchor_Y - ro_RectBG[1].settings.height+(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)+allSettings.fontSettings.font_height*1.3}
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
				imgui.SetNextWindowPos(fcw[1].compactPos); 
				imgui.SetNextWindowSize(fcw[1].compactSize);
			end
			
			--imgui.SetNextWindowSizeConstraints({ tabsW+tabsH*2, tabsH }, { FLT_MAX, FLT_MAX, });
			windowFlags = bit.bor( ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_NoBackground);
			
			imgui.Begin('FancyChat_ChatTabs_'+fcw[1].PlayerName, true, windowFlags);
			--local font = imgui.GetFont();
			--local prevFontSize = font.FontSize;
			--font.FontSize = 450/allSettings.fontSettings.font_height;
			imgui.SetWindowFontScale(allSettings.fontSettings.font_height/25);
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
						imgui.Button(tab_Tabs[T_i],{reserved/#tab_Tabs,tabsH-2});
						PopColorStyles(tab_ButtonColorStylesSelected);
					else
						if (imgui.Button(tab_Tabs[T_i],{reserved/#tab_Tabs,tabsH-2})) then
							tab_NextTab = tab_Tabs[T_i]; 
						end
					end
				end
				
				imgui.SetCursorPos({reserved+4,imgui.GetCursorPosY()-(tabsH+1.6)});
			
				if(fcw[1].TextureIDGuideMe ~= nil) then
					if (imgui.ImageButton(fcw[1].TextureIDGuideMe,{tabsH-8,tabsH-8},{0,0},{1,1},-1,{0,0,0,0},{1,1,1,0.7})) then
						fcw[1].GuideMeOpened[1] = not fcw[1].GuideMeOpened[1];
						if fcw[1].GuideMeOpened[1] then	fcw[1].NotepadOpened[1]  = false end
					end
				end
				imgui.SetCursorPos({imgui.GetCursorPosX()+reserved+4+(tabsH-8),imgui.GetCursorPosY()-(tabsH+1.6)});
			
				if(fcw[1].TextureIDNotepad ~= nil) then
					if (imgui.ImageButton(fcw[1].TextureIDNotepad,{tabsH-8,tabsH-8},{0,0},{1,1},-1,{0,0,0,0},{1,1,1,0.7})) then
						fcw[1].NotepadOpened[1] = not fcw[1].NotepadOpened[1]
						if fcw[1].NotepadOpened[1] then	fcw[1].GuideMeOpened[1] = false end
					end
				end
				
				imgui.SetCursorPos({imgui.GetCursorPosX()+reserved+4+(tabsH*2-8),imgui.GetCursorPosY()-(tabsH+1.6)});
				if(fcw[1].TextureIDSettings ~= nil) then
					if (imgui.ImageButton(fcw[1].TextureIDSettings,{tabsH-8,tabsH-8},{0,0},{1,1},-1,{0,0,0,0},{1,1,1,0.7})) then
						allSettings.settingsOpened[1] = not allSettings.settingsOpened[1];
					end
				end
				
				imgui.SetCursorPos({imgui.GetCursorPosX()+reserved+4+(tabsH*3-8),imgui.GetCursorPosY()-(tabsH+1.6)});
				if(fcw[1].TextureIDCompact ~= nil) then
					if (imgui.ImageButton(fcw[1].TextureIDCompact,{tabsH-8,tabsH-8},{0,0},{1,1},-1,{0,0,0,0},{1,1,1,0.7})) then
						allSettings.CompactTabs = true;
						fcw[1].PosChanged = true
						fcw[2].PosChanged = true
						SaveSettings();
					end
				end
				
				-- imgui.SetNextWindowPos({compactPos[1],compactPos[2]}); 
				-- imgui.SetNextWindowSize(compactSize);
				-- imgui.Begin('FancyChat_ChatTabs_Compactbutton', true, bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_NoBackground, ImGuiWindowFlags_NoSavedSettings));
				-- imgui.SetCursorPos({(tabsW/#tab_Tabs)-(tabsH-8),0});
			
				-- imgui.PushStyleVar(ImGuiStyleVar_FrameBorderSize, 0);
				
				-- if(fcw[1].TextureIDCompact ~= nil) then
					-- if (imgui.ImageButton(fcw[1].TextureIDCompact,{tabsH-8,tabsH-12},{-0.05,-0.05},{1.05,1.05},-1,{0,0,0,0},{1,1,1,0.5})) then
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
				
				for T_i = 1, utils.GetTableLen(tab_Tabs) do
				if (tab_Tabs[T_i] == allSettings.SelectedTab) then
						imgui.SetCursorPos({0,0});
						if imgui.Button(tab_Tabs[T_i],{tabsW/#tab_Tabs-(tabsH-8),tabsH-6}) then
							if T_i+1 <= #tab_Tabs then tab_NextTab = tab_Tabs[T_i+1]; else  tab_NextTab = tab_Tabs[1] end
						end
					end
				end
				
				imgui.SetCursorPos({(tabsW/#tab_Tabs)-(tabsH-8),0});
			
				if(fcw[1].TextureIDCompact ~= nil) then
					if (imgui.ImageButton(fcw[1].TextureIDCompact,{tabsH-8,tabsH-12},{1.05,1.05},{-0.05,-0.05},-1,{0,0,0,0},{1,1,1,0.5})) then
						allSettings.CompactTabs = false;
						fcw[1].PosChanged = true
						fcw[2].PosChanged = true
						SaveSettings();
					end
				end
				imgui.PopStyleVar(1);
			
			end
			PopColorStyles(tab_ButtonColorStylesNormal);
			--font.FontSize = prevFontSize;
			--imgui.PopFont();
			imgui.End();
			
			
			if fcw[1].GuideMeOpened[1] and not fcw[1].GuideMeClosedTmp then
				
				local GuideMeW = fcw[1].BG_W;
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
								
				if imgui.Begin('FancyChat - GuideMe (beta)', fcw[1].GuideMeOpened, windowFlags) then
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
					
					imgui.SameLine(); imgui.Text('%[x'..string.format("%.2f", allSettings.GuideMeFontScale)..'%]');
					
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
					
					imgui.BeginChild('GuideMe child', {imgui.GetWindowWidth()*0.983,(imgui.GetWindowHeight()-70)*0.983}, true)

					--imgui.PushFont(fontBox)
					imgui.SetWindowFontScale(allSettings.GuideMeFontScale);
					imgui.PushTextWrapPos(imgui.GetWindowWidth()*0.96);
					if fcw[1].GuideMeWalkthrough then
						imgui.TextUnformatted(fcw[1].GuideMeWalkthrough, #fcw[1].GuideMeWalkthrough)
					elseif fcw[1].ErrorMsg then
						
						imgui.TextUnformatted(fcw[1].ErrorMsg);
					end;
					imgui.PopTextWrapPos()
					--imgui.PopFont()
					imgui.EndChild()
					imgui.End();
				end
				PopWindowStyle();
			end
		
		
			if fcw[1].NotepadOpened[1] and not fcw[1].NotepadClosedTmp then
				
				local GuideMeW = fcw[1].BG_W;
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
								
				if imgui.Begin('FancyChat - Notes (beta)', fcw[1].NotepadOpened, windowFlags) then
					imgui.PushItemWidth(imgui.GetWindowWidth()-290);
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
					local fontSize = font.FontSize;
					local R = {};
					for i = 1, #allSettings.Notes do
					
					
					imgui.BeginChild('##Chat Window Child_'..tostring(i), {imgui.GetWindowWidth()-110,fontSize+fontSize*math.floor(imgui.CalcTextSize(allSettings.Notes[i])/(imgui.GetWindowWidth()-math.min(imgui.CalcTextSize(help.GetLongestWord(allSettings.Notes[i])),(imgui.GetWindowWidth()-100)/2)))+16}, true);
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
			PushWindowStyle()
			--print('hello')
			imgui.SetNextWindowSize({ dsize.x/3.8, dsize.y/2.7 });
			--imgui.SetNextWindowSize({400, 400 });ImGuiWindowFlags_NoResize,
			--imgui.SetWindowPos({100,100});
			imgui.SetNextWindowSizeConstraints({ 550,300 }, { FLT_MAX, FLT_MAX, });
			imgui.Begin('FancyChat Settings##_'+fcw[1].PlayerName, allSettings.settingsOpened, bit.bor( ImGuiWindowFlags_NoResize,ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_NoNav) );
			--if imgui.IsWindowHovered(ImGuiHoveredFlags_RectOnly) then set_WinHovered = true; else set_WinHovered = false; end
			local setsizex, setsizey = imgui.GetWindowSize();--
			--if (wposx > dsize.x or wposy > dsize.y or wposx <0 or wposy <0) then  end
			
			
			if (imgui.BeginTabBar('##fancychat_tabbar', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton))	then
				
				if (imgui.BeginTabItem('Chat Window', nil)) then
					imgui.BeginChild('##Chat Window Child', {(setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3,setsizey*2.7/2.8-60}, true);
					--imgui.BeginChild('##Chat Window Child', {300,300}, true);
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
						SaveSettings();
					end
					imgui.Dummy({0,5});
					if imgui.Button('Reset default values') then
						set_ChatLineMaxL = 100;
						set_PlateBGColor = bit.lshift(bit.tobit(0.3*255),24);
						set_FontHeight = 20;
						set_ChatLines = 8;
						set_SecondChat[1] = false;
						--SaveSettings();
					end
					imgui.Dummy({0,5});
					imgui.Text('^');
					cposY = imgui.GetCursorPosY();
					imgui.SetCursorPosY(cposY-20);
					
					imgui.Text('|');
					cposY = imgui.GetCursorPosY();
					imgui.SetCursorPosY(cposY-20);
					cposX = imgui.GetCursorPosX();
					imgui.SetCursorPosX(cposX+15);
					imgui.Text('These changes require an addon restart');
					-- if (fcw[1].TextureIDInfo ~= nil ) then
						-- imgui.GetWindowDrawList():AddImage(fcw[1].TextureIDInfo, {0,0},{10,10}, {0,0}, {1,1}, imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.75 }));
					-- end
					AddTooltip('The changes to options above won\'t take effect until the addon is restarted',1);
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
					end
					imgui.Dummy({0,5});
					if (imgui.Checkbox('Prevent Obstructing FFXI UI',{allSettings.EnabledChatMove[1]})) then 
						allSettings.EnabledChatMove[1] = not allSettings.EnabledChatMove[1];
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
					imgui.Dummy({3,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					imgui.Dummy({27,0}); imgui.SameLine();
					imgui.Text('[ BETA ]\n[ Reposition chats if FFXI UI elements overlap ]\n[ Works with the most common game UI elements ]\n[ Only works with chat positions locked ]');
					--imgui.Text('Lock manual\npositioning');
					imgui.EndChild();
				imgui.EndTabItem();
				end
				
				
				if (imgui.BeginTabItem('Font Colors', nil)) then
					imgui.BeginChild('leftpane', { ((setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3)*0.4,setsizey*2.7/3-60 }, true);
				
					AddSetColor('Default', allSettings.defaultColor)
					AddSetColor('Linkshell 1', allSettings.linkshellColor)
					AddSetColor('Linkshell 2', allSettings.linkshell2Color)
					AddSetColor('Party', allSettings.partyColor)
					AddSetColor('Tell', allSettings.tellColor)
					AddSetColor('Shout', allSettings.shoutColor)
					AddSetColor('Emote', allSettings.emoteColor)
					AddSetColor('Combat', allSettings.combatColor)
					AddSetColor('Damage', allSettings.dmgColor)
					AddSetColor('Combat Spell', allSettings.combatspellColor)
					AddSetColor('Spell Damage', allSettings.spelldmgColor)

					imgui.EndChild();

					imgui.SameLine();
					
					imgui.BeginChild('righttpane', { ((setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3)*0.59, setsizey*2.7/3-60 }, true);
					--imgui.BeginChild('righttpane', { 100, 100}, true);
					
					imgui.Text('Color Picker');
					if imgui.ColorPicker3('Preview', set_PickedColor) then
					end
				
					imgui.EndChild();
					
					if imgui.Button('Reset Colors') then
						ResetColors();
						SaveSettings();
					end
					imgui.EndTabItem();
				end
				
				if (imgui.BeginTabItem('Shortcuts', nil)) then
					imgui.BeginChild('##Shortcuts Child', {(setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3,setsizey*2.7/2.8-60}, true);
					--imgui.BeginChild('##Shortcuts Child', {300,300}, true);
					local letter = utils.keycodes[utils.findIndexOfValue(utils.keycodes, allSettings.shortcutHide)][1];
					local letterS = utils.keycodesSpecial[utils.findIndexOfValue(utils.keycodesSpecial, allSettings.shortcutHideS)][1];
					local letter2 = utils.keycodes[utils.findIndexOfValue(utils.keycodes, allSettings.shortcutTab)][1];
					local letterS2 = utils.keycodesSpecial[utils.findIndexOfValue(utils.keycodesSpecial, allSettings.shortcutTabS)][1];
					local letter3 = utils.keycodes[utils.findIndexOfValue(utils.keycodes, allSettings.shortcutTab2)][1];
					local letterS3 = utils.keycodesSpecial[utils.findIndexOfValue(utils.keycodesSpecial, allSettings.shortcutTab2S)][1];
		
					imgui.Text('Hide FancyChat Addon');
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
							if (utils.keycodes[KC_i][1] ~= letter2  and utils.keycodes[KC_i][1] ~= letter3 ) then
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
							if (utils.keycodes[KC_i][1] ~= letter and utils.keycodes[KC_i][1] ~= letter3) then
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
							if (utils.keycodes[KC_i][1] ~= letter and utils.keycodes[KC_i][1] ~= letter2) then
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
						allSettings.shortcutHideS = 42;
						allSettings.shortcutTabS = 42;
						allSettings.shortcutTab2S = 42;
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
					imgui.Text('/fancychat dumpchat');
					imgui.Dummy({23,0}); imgui.SameLine();
					imgui.Text('[Dumps FancyChat text in the legacy chat]');
					
					imgui.EndChild();
				imgui.EndTabItem();
				end
				if (imgui.BeginTabItem('Extra', nil)) then
					imgui.BeginChild('##Extra Child', {(setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3,setsizey*2.7/2.8-60}, true);
					--imgui.BeginChild('##Extra Child', {300,300}, true);
				
					imgui.Text('Block legacy chat messages'); 
					imgui.Text('[Blocks legacy chat resize animation]');
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('All',{allSettings.blockAll[1]})) then 
						allSettings.blockAll[1] = not allSettings.blockAll[1];
						if allSettings.blockAll[1] then
							if not set_Popup[1] then set_Popup[1] = true; end
						else
							set_Popup[1] = false;
						end
						SaveSettings();
					end
					if set_Popup[1] then
						AddWarning('While this option has been tested throughfully, it might lead to getting stuck in dialgoues in untested scenarios.\n\nDisable it if you experience such issues.')
					end
					AddTooltip('Disable this if you are experiencing getting stuck in conversations with NPCs',4,1)
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Combat (recommended)',{allSettings.blockCombat[1]})) then 
						allSettings.blockCombat[1] = not allSettings.blockCombat[1];
						SaveSettings();
					end
					imgui.Dummy({0,15});
					imgui.Text('Chat message filtering'); 
					imgui.Text('[These are meant for quick changes on the fly]\n[Use the in-game filter system first!]');
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Hide combat log from \'All\' tab.',{allSettings.HideCombatFromAll[1]})) then 
						allSettings.HideCombatFromAll[1] = not allSettings.HideCombatFromAll[1];
						ChangeTab(1, 'All');
						ResetScrolling(1);
						if allSettings.SecondChat[1] then
							ChangeTab(2, 'All');
							ResetScrolling(2);
						end
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
					imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					imgui.Dummy({27,0}); imgui.SameLine();
					imgui.Text('[ Experimental. Blocks most non-party log. ]');
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
					imgui.Text('[Read the manual for more detailed info]');
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Compact Combat Log',{allSettings.CompactCombat[1]})) then 
						allSettings.CompactCombat[1] = not allSettings.CompactCombat[1];
						SaveSettings();
					end		
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
					if (imgui.Checkbox('Incoming /tell notifications',{allSettings.tellNotification[1]})) then 
						allSettings.tellNotification[1] = not allSettings.tellNotification[1];
						SaveSettings();
					end
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
					imgui.PushItemWidth(dsize.x/10);
					--imgui.PushItemWidth(100);
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					imgui.Text('Colored-line splitting character')
					imgui.Dummy({5,0}); imgui.SameLine();
					imgui.Text('[ Combat log character before the colored part ]')
					imgui.Dummy({5,0}); imgui.SameLine();
					if imgui.BeginCombo('##SplittingChar', allSettings.CombatSplitChar[1] , ImGuiComboFlags_None) then
						for SC_i = 1, #set_CombatSplitCharList do
							if imgui.Selectable(set_CombatSplitCharList[SC_i][1]) then
								allSettings.CombatSplitChar = set_CombatSplitCharList[SC_i];
								SaveSettings();
							end
						end
					imgui.EndCombo();
					end
					imgui.PopItemWidth();
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Colorblind mode for damage text',{allSettings.ColorBlind[1]})) then 
						allSettings.ColorBlind[1] = not allSettings.ColorBlind[1];
						a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(allSettings.ColorBlind[1] and 0xFF91FFF0 or 0xFF91FF47)));
						allSettings.dmgDoneColor = T{r/255,g/255,b/255,a/255};						
						a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(allSettings.ColorBlind[1] and 0xFFFFA269 or 0xFFFA4343)));
						allSettings.dmgGotColor = T{r/255,g/255,b/255,a/255};		
						a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(allSettings.ColorBlind[1] and 0xFF5EE0DE or 0xFFADFF33)));
						allSettings.spelldmgDoneColor = T{r/255,g/255,b/255,a/255};						
						a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(allSettings.ColorBlind[1] and 0xFFE6874C or 0xFFFC2B43)));
						allSettings.spelldmgGotColor = T{r/255,g/255,b/255,a/255};
						SaveSettings();
					end
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Fast scroll chat history',{allSettings.EnableFastScroll[1]})) then 
						allSettings.EnableFastScroll[1] = not allSettings.EnableFastScroll[1];
						SaveSettings();
					end
					imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					imgui.Dummy({27,0}); imgui.SameLine();
					imgui.Text('[ Use [Shift] + [<] or [>] ]');
					imgui.Dummy({27,0}); imgui.SameLine();
					imgui.Text('[ Only while already scrolling chat ]');
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox('Dock GuideMe/Notes on the second chat window',{allSettings.GuideMeSecondWindow[1]})) then 
						if allSettings.SecondChat[1] then
							allSettings.GuideMeSecondWindow[1] = not allSettings.GuideMeSecondWindow[1];
							SaveSettings();
						end
					end
					imgui.Dummy({15,0}); imgui.SameLine(); imgui.Text('L');
					imgui.SetCursorPosY(imgui.GetCursorPosY()-18);
					imgui.Dummy({27,0}); imgui.SameLine();
					imgui.Text('[ Requires second chat window enabled ]');
					imgui.Dummy({0,5});
					imgui.Dummy({5,0}); imgui.SameLine();
					if (imgui.Checkbox(allSettings.heartEmoji[1] and ' <3' or ' ',{allSettings.heartEmoji[1]})) then 
						allSettings.heartEmoji[1] = not allSettings.heartEmoji[1];
						SaveSettings();
					end
					imgui.EndChild();
					imgui.EndTabItem();
				end
				if imgui.BeginTabItem('Tools', nil) then
					imgui.BeginChild('##Tools Child', {(setsizex*3.8/3.9)-(12*(1-(setsizex*3.8/1920)))-3,setsizey*2.7/2.8-60}, true);
					--imgui.BeginChild('##Extra Child', {300,300}, true);
					imgui.Dummy({0,5});
					imgui.Dummy({5,0});  imgui.SameLine();
					if(fcw[1].TextureIDLogs ~= nil and fcw[1].TextureIDLoading ~= nil) then
						if (imgui.ImageButton(fcw[1].SaveStart == 0 and fcw[1].TextureIDLogs or fcw[1].TextureIDLoading,{dsize.x/100,dsize.x/100},{-0.01,-0.01},{1.01,1.01},-1,{0,0,0,0},{1,1,1,1})) then
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
						if (imgui.ImageButton(fcw[1].TextureIDFolder,{dsize.x/100,dsize.x/100},{-0.01,-0.01},{1.01,1.01},-1,{0,0,0,0},{1,1,1,1})) then
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
						if (imgui.ImageButton(fcw[1].TextureIDManual,{dsize.x/100,dsize.x/100},{0.01,0.01},{0.99,0.99},-1,{0,0,0,0},{1,1,1,1})) then
							help.opened[1] = not help.opened[1];
						end
					end
					imgui.SameLine();
					imgui.SetCursorPosY(imgui.GetCursorPosY()+dsize.x/300);
					imgui.Text('Open Manual');
					imgui.Dummy({0,5});
					imgui.Dummy({5,0});  imgui.SameLine();
					if(fcw[1].TextureIDDumpchat ~= nil) then
						if (imgui.ImageButton(fcw[1].TextureIDDumpchat,{dsize.x/100,dsize.x/100},{0.05,0.01},{0.98,1.0},-1,{0,0,0,0},{1,1,1,1})) then
							DumpChat(1)
						end
					end
					imgui.SameLine();
					imgui.SetCursorPosY(imgui.GetCursorPosY()+dsize.x/300);
					imgui.Text('Restore Legacy Chat Logs');
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
			set_ChatLines = allSettings.ChatLines;
		end
		
		if not fcw[1].HideChat and not fcw[1].Closing and not fcw[1].ProcessingText then 
		-- Updating chat lines status (must be done even if chat is not displayed) ?? --and b_ChatBufferIdx[1] < b_ChatBufferN[1]
			if fcw[1].PrevHideChat ~= fcw[1].HideChat and fcw[1].PrevHideChat  then  ResetScrolling(1) end;
			
			fcw[1].ChatShiftScale_Target = fcw[1].ChatShiftScale_Base * ( ( 1.2^( b_ChatBufferN[1]-b_ChatBufferIdx[1] ) )-1)+fcw[1].ChatShiftScale_Min;
			--print(tostring(b_ChatBufferN[1]))
			if (b_ChatBufferN[1]>0) then
				--print('hello')
				if (b_ChatBufferIdx[1] < b_ChatBufferN[1] and not fcw[1].Scrolling and not fcw[1].Dragging) then
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
						fcw[1].OutlineColor = 0xFF000000;
						fo_Aux[1][fcw[1].ChatHead]:set_outline_color(0xFF000000);
						fo_Chat[1][fcw[1].ChatHead]:set_outline_color(0xFF000000);
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
				ChangeTab(2, tab_NextTab2);
				b_ChatBufferN[2] = SetBufferN(allSettings.SelectedTab2);
				ResetScrolling(2);
			else
				b_ChatBufferN[2] = SetBufferN(allSettings.SelectedTab2);
			end
			
			
			--end
			if allSettings.SelectedTab2 == 'All' and allSettings.HideCombatFromAll[1] then b_ChatBufferN[2]=b_ChatBufferN_AllAlt;  end
			
			
			if (not uiw.LegacyChatOpen and not fcw[1].HideChat and not fcw[1].Closing ) then
				
				imgui.SetNextWindowSize({ fcw[2].BG_W, ro_RectBG[2].settings.height+16 }, ImGuiCond_Once);
				imgui.SetNextWindowSizeConstraints({ fcw[2].BG_W, ro_RectBG[2].settings.height+16 }, { FLT_MAX, FLT_MAX, }, ImGuiCond_Once);
				
				--if allSettings.LockWindowPos[1] then fcw[1].windowFlagsChatBG = bit.bor(fcw[1].windowFlagsChatBG,ImGuiWindowFlags_NoMove); end
				imgui.Begin('FancyChat_ChatBG2_'+fcw[1].PlayerName, true, bit.bor(fcw[1].windowFlagsChatBG, allSettings.LockWindowPos[1] and ImGuiWindowFlags_NoMove or 0));
				
			-- Setting variables to position the chat window elements --
				local positionStartX, positionStartY = imgui.GetCursorScreenPos();
				positionStartX = positionStartX + allSettings.WindowPosOffset[3];
				positionStartY = positionStartY + allSettings.WindowPosOffset[4];
				if fcw[1].MoveChat then
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
					fcw[1].MoveChat = (mvc_Menu1 or mvc_Menu2 or mvc_Menu3 or mvc_Menu4 or mvc_Menu5 or uiw.DialogShown) and allSettings.LockWindowPos[1] and allSettings.EnabledChatMove[1];
					if fcw[1].MoveChat and positionStartX < mvc_targetposX
					and fcw[2].Anchor_Y > mvc_targetposY then
						positionStartX = mvc_targetposX;
						fcw[1].MoveChat = true;
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
					and (imgui.IsWindowHovered(ImGuiHoveredFlags_RectOnly))
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
									if imgui.IsMouseClicked(ImGuiMouseButton_Left) then ashita.misc.open_url(b_ChatBuffer[b_ChatBufferMode[2]][2].url[ChatHoverIdx]); end
									
								end
								fcw[2].HoverLine = -1;
							end
							break
						else
							if (fo_Aux[2][targetLine]~= nil and fo_Aux[2][targetLine].settings.text == '[link]') then
								fo_Aux[2][targetLine]:set_font_color(0xFF44CCFF);
							end
							if (mouseX > fcw[2].Anchor_X and mouseX < fcw[2].Anchor_X+fcw[2].BG_W and
							mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+allSettings.fontSettings.font_height and
							imgui.IsWindowHovered(ImGuiHoveredFlags_RectOnly)
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
								break
							end
							
						end
					end
				end
				
				if (fcw[2].HoverLine > 0 and imgui.IsMouseClicked(ImGuiMouseButton_Left)) then fcw[2].Clicking = true; end
				
				if (fcw[2].HoverLine > 0 and fcw[2].Clicking and imgui.IsMouseReleased(ImGuiMouseButton_Left) and imgui.IsWindowHovered(ImGuiHoveredFlags_RectOnly)) then
					fcw[2].Clicking = false;
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
					
					copyBufferText = (' '..copyBufferText..b_ChatBuffer[b_ChatBufferMode[2]][2].text[copyBufferIdx+IDi]):trimex()
					if b_ChatBuffer[b_ChatBufferMode[2]][2].auxText[copyBufferIdx+IDi] ~= '[link]' then
						copyBufferText = copyBufferText..' '..b_ChatBuffer[b_ChatBufferMode[2]][2].auxText[copyBufferIdx+IDi]
					end
					IDi = IDi + 1;
					end
					end
					if(copyBufferText ~=nil) then
						if imgui.GetIO().KeyShift then
							if #allSettings.Notes < 10 and #copyBufferText > 0 then
								table.insert(allSettings.Notes, copyBufferText)
								SaveSettings()
							end
						else
							utils.SetClipboardText(utils.RevertShiftJIT(copyBufferText))
							AshitaCore:GetChatManager():QueueCommand(1, "/echo Text successfully copied to clipboard!");
						end
					end
				end
			
				if (fcw[2].Clicking and (imgui.IsMouseDragging(ImGuiMouseButton_Left) or not imgui.IsMouseDown(ImGuiMouseButton_Left) )) then fcw[2].Clicking = false; end
				
				local scrollOffset= (fcw[2].BG_H/120);

				--if (mouseX > fcw[1].Anchor_X and mouseX < fcw[1].Anchor_X+fcw[1].BG_W and
				if (mouseX > fcw[2].Anchor_X and mouseX < fcw[2].Anchor_X+fcw[2].BG_W and
				mouseY > positionStartY+scrollOffset and mouseY < positionStartY+scrollOffset+allSettings.fontSettings.font_height*(allSettings.ChatLines+1)
				and imgui.IsWindowHovered(ImGuiHoveredFlags_RectOnly)
				)
				then
					if (
						fcw[2].ScrollDelta > 0
						and utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[2]][2].text) - fcw[2].ScrolledBack - (b_ChatBufferN[2]-b_ChatBufferIdx[2]) > allSettings.ChatLines
					)
					then
						fcw[2].ScrollDelta = 0;
						fcw[1].ScrollDelta = 0;
						fcw[2].Scrolling = true;
						fcw[2].ChatShift = allSettings.fontSettings.font_height
						fcw[2].ScrollUpRequest = true;
					else
						if ( fcw[2].ScrollDelta < 0 and fcw[2].ScrolledBack > 0 ) then
							fcw[2].ScrollDelta = 0;
							fcw[1].ScrollDelta = 0;
							fcw[2].Scrolling = true;
							fcw[2].ChatShift = allSettings.fontSettings.font_height
							fcw[2].ScrollDownRequest = true;
						end
					end
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
						fcw[2].compactPos= {fcw[2].Anchor_X+(ro_RectBG[2].settings.width-(tabsW/#tab_Tabs))*0.995-1, fcw[2].Anchor_Y - ro_RectBG[2].settings.height+(allSettings.fontSettings.font_height*2/allSettings.fontSettings.font_height)+allSettings.fontSettings.font_height*1.3}; 
				
						fcw[2].compactSize = { tabsW/#tab_Tabs+(tabsH-(allSettings.fontSettings.font_height/1.2)+3), ro_RectBG[2].settings.height/8 };
					end
					imgui.SetNextWindowPos(fcw[2].compactPos)
					imgui.SetNextWindowSize(fcw[2].compactSize)
						
				end
				--imgui.SetNextWindowSizeConstraints({ tabsW, tabsH }, { FLT_MAX, FLT_MAX, });
				
				windowFlags = bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_NoBackground);
				
				imgui.Begin('FancyChat_ChatTabs2_'+fcw[1].PlayerName, true, windowFlags);
				--local font = imgui.GetFont();
				--local prevFontSize = font.FontSize;
				--font.FontSize = 450/allSettings.fontSettings.font_height;
				imgui.SetWindowFontScale(allSettings.fontSettings.font_height/25);
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
							imgui.Button(tab_Tabs[T_i],{reserved/#tab_Tabs,tabsH-2});
							PopColorStyles(tab_ButtonColorStylesSelected);
						else
							if (imgui.Button(tab_Tabs[T_i],{reserved/#tab_Tabs,tabsH-2})) then
								tab_NextTab2 = tab_Tabs[T_i]; 
							end
						end
					end
				
				else
					imgui.PushStyleVar(ImGuiStyleVar_FrameBorderSize, 0);
				
					for T_i = 1, utils.GetTableLen(tab_Tabs) do
						if (tab_Tabs[T_i] == allSettings.SelectedTab2) then
							imgui.SetCursorPos({0,0});
							if imgui.Button(tab_Tabs[T_i],{tabsW/#tab_Tabs,tabsH-6}) then
								if T_i+1 <= #tab_Tabs then tab_NextTab2 = tab_Tabs[T_i+1]; else  tab_NextTab2 = tab_Tabs[1] end
							end
						end
					end
						
						
					imgui.PopStyleVar(1);
				end
				PopColorStyles(tab_ButtonColorStylesNormal);
				--font.FontSize = prevFontSize;
				imgui.End();
			end
			--print(tostring(b_ChatBufferN[2]))
			if not fcw[1].HideChat and not fcw[1].Closing and not fcw[1].ProcessingText then 	
				
				if fcw[1].PrevHideChat ~= fcw[1].HideChat and fcw[1].PrevHideChat then ResetScrolling(2) end;
				
				--print(tostring(b_ChatBufferN[2]));
				fcw[2].ChatShiftScale_Target = fcw[2].ChatShiftScale_Base * ( ( 1.2^( b_ChatBufferN[2]-b_ChatBufferIdx[2] ) )-1)+fcw[2].ChatShiftScale_Min;
				
				if (b_ChatBufferN[2]>0) then

					if (b_ChatBufferIdx[2] < b_ChatBufferN[2] and not fcw[2].Scrolling and not fcw[2].Dragging) then
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
							fcw[2].OutlineColor = 0xFF000000;
							fo_Aux[2][fcw[2].ChatHead]:set_outline_color(0xFF000000);
							fo_Chat[2][fcw[2].ChatHead]:set_outline_color(0xFF000000);
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
	if (fcw[1].PlayerName ~= '---' and fcw[1].LoggedLobby ~= 1 and not fcw[1].Zoning and fcw[1].LoggedIn and #settings.name > 0 and fcw[1].RenderFOs and not fcw[1].HideChat and not uiw.LegacyChatOpen and not fcw[1].Closing) then
		PositionLines(1);
		if allSettings.SecondChat[1] then PositionLines(2); end
		-- if fcw[1].ResetCD ~= 0 and os.clock()-fcw[1].ResetCD > 0.2 then
			-- fcw[1].ResetCD = 0
			-- --SetLinesVisible(1, true)
			-- --SetLinesVisible(2, true)
		-- end
		
		--print('hello'..tostring(os.clock()))
		gdi:render();
		--gdi:set_auto_render(true);
	else
		--gdi:set_auto_render(false);
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
	
	
end);

--ashita.events.register('d3d_beginscene', 'd3d_beginscene_callback1', function (isRenderingBackBuffer)

    -- isRenderingBackBuffer is a flag that will be true when the game is currently rendering to the back buffer.
	
--end);

ashita.events.register('text_in', 'text_in_cb', function (e)
	
	if par_dumping then return end
	
	
	
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
	
	local e_message;
	
	local mode_pre = bit.band(e.mode,  0x000000FF);--(mode_pre == 190 and e.message:find('__')) or
	if (mode_pre == 190 and #e.message == par_LastMsgLength) or mode_pre == 152 or e.blocked then e.blocked = true; return; end
	if (mode_pre == 191 and string.find(e.message, 'version')) then AshitaCore:GetChatManager():AddChatMessage(0, false, e.message) return end
	table.insert(b_OriginalBuffer,  tostring(bit.band(e.mode,  0x000000FF))..'|'..os.date('[%H:%M:%S]', os.time())..' '..e.message)
	if #b_OriginalBuffer > 400 then
		for _ = 1, 100 do
			table.remove(b_OriginalBuffer,1)
		end
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

	dw_testPTR = ashita.memory.find('FFxiMain.dll', 0, 'B9????????50E8????????8BF085F674??8B46',0,0);

	
	--print(bit.tohex(dw_testPTR+0x54));
	
	
	
	
	
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

	ResetColors();
	
	--local dsize = imgui.GetIO().DisplaySize
	--fcw[1].Anchor_X = dsize.x/2;
	--fcw[1].Anchor_X = dsize.y/2;
	
	allSettings = settings.load(allSettings, 'allSettings');
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

		table.insert(b_ChatBuffer[W_i][2].text, '-- Welcome to ');
		table.insert(b_ChatBuffer[W_i][2].mode, '0|welcome');
		table.insert(b_ChatBuffer[W_i][2].color, 0xFFFFFFFF);
		table.insert(b_ChatBuffer[W_i][2].auxText,  'FancyChat --');
		table.insert(b_ChatBuffer[W_i][2].auxColor, 0xFF44CCFF);
		table.insert(b_ChatBuffer[W_i][2].url, 0);
	end
	
	b_ChatBufferN_All = 1;
	b_ChatBufferN_AllAlt = 1;
		
	if allSettings.SelectedTab ~= 'All' then tab_NextTab = allSettings.SelectedTab end
	if allSettings.SelectedTab2 ~= 'All' then tab_NextTab2 = allSettings.SelectedTab2 end

	
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
	testWindow = os.clock()
end);

ashita.events.register('unload', 'unload_cb', function ()
	fcw[1].Closing = true;
	SaveSettings();
	gdi:destroy_interface();
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
    if (#args == 0 or not args[1]:any('/fancychat')) then
        return;
    end
	
	e.blocked = true;
	
	if (#args == 2 and args[2] == 'debug') then
		dw_WindowOpened[1] = not dw_WindowOpened[1];			
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
		utils.SaveLogs(b_ChatBuffer[8][2].text, b_ChatBuffer[8][2].auxText, 'NPC', fcw[1].PlayerName, addon.path, ts)
		coroutine.sleep(0.5);			
		
		return;
	end
	if (#args == 2 and args[2] == 'dumpchat') then
		DumpChat(2)
		return
	end
	if (#args == 2 and args[2] == 'savedebug') then
		
		local ts = os.date('[%Y_%m_%d-%H_%M_%S]', os.time());
		if utils.SaveLogs(b_LogBuffer, nil, 'DEBUG', fcw[1].PlayerName, addon.path, ts) then
			b_LogBuffer = {};
		end
		return;
	end
	if (#args == 3 and args[2] == 'goto') then
		GoToLine(1, tonumber(args[3]));
		return;
	end
	if (#args > 3 and args[2] == 'test' and tonumber(args[3]) >= 0 and tonumber(args[3]) <= 255) then
		local test_string = ''
		local test_i = 4
		while args[test_i] ~= nil do
			test_string = test_string..args[test_i]..' '
			test_i = test_i + 1
		end
		AshitaCore:GetChatManager():AddChatMessage(tonumber(args[3]), false, test_string)
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
		
		print('\73\110\32\116\104\101\32\71\117\115\116\97\98\101\114\103\32\77\111\117\110\116\97\105\110\115\32\111\102\32\83\111\117\116\104\101\114\110\32\81\117\111\110\32\108\105\101\115\32\116\104\101\32\105\110\100\117\115\116\114\105\97\108\32\110\97\116\105\111\110\32\107\110\111\119\110\32\97\115\32\116\104\101\32\82\101\112\117\98\108\105\99\32\111\102\32\66\97\115\116\111\107\46\127\52\6')
		return;
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
		
	end
	
end);



ashita.events.register('key_state', 'key_state_callback1', function (e)

    local keyptr = ffi.cast('uint8_t*', e.data_raw);
	
	--print(tostring(keyptr[30]));
	--local uiw.RefInputWinOpenPtr = ashita.memory.read_uint32(uiw.InputWinOpenPtr+0x01);
	--uiw.InputWinOpen = ashita.memory.read_uint32(uiw.InputWinOpenPtr+0x74) == 1 and true or false;
	--print(keyptr[42]);
	if allSettings.EnableFastScroll[1] and keyptr[42]~= 0 then 
		if (fcw[1].PrevKeyptr[1] == 0 or os.clock()-fcw[1].PrevKeyptr[3] > 0.8) and keyptr[203] ~= 0 and fcw[1].Scrolling and IsRectHovered(ro_RectBG[1].settings, 0) then
			GoToLine(1,math.max(b_ChatBufferIdx[1]-(fcw[1].ScrolledBack+5), allSettings.ChatLines));
			if fcw[1].PrevKeyptr[1] == 0 then fcw[1].PrevKeyptr[3] = os.clock(); else fcw[1].PrevKeyptr[3] = os.clock()-0.7; end
		elseif (fcw[1].PrevKeyptr[2] == 0 or os.clock()-fcw[1].PrevKeyptr[3] > 0.8) and keyptr[205] ~= 0 and fcw[1].Scrolling and IsRectHovered(ro_RectBG[1].settings, 0) then
			GoToLine(1,math.min(b_ChatBufferIdx[1]-(fcw[1].ScrolledBack-5), b_ChatBufferIdx[1]-1));
			if fcw[1].PrevKeyptr[2] == 0 then fcw[1].PrevKeyptr[3] = os.clock(); else fcw[1].PrevKeyptr[3] = os.clock()-0.7; end
		elseif (fcw[1].PrevKeyptr[1] == 0 or os.clock()-fcw[1].PrevKeyptr[3] > 0.8) and keyptr[203] ~= 0 and fcw[2].Scrolling and IsRectHovered(ro_RectBG[2].settings, 0) then
			GoToLine(2,math.max(b_ChatBufferIdx[2]-(fcw[2].ScrolledBack+5), allSettings.ChatLines));
			if fcw[1].PrevKeyptr[1] == 0 then fcw[1].PrevKeyptr[3] = os.clock(); else fcw[1].PrevKeyptr[3] = os.clock()-0.7; end
		elseif (fcw[1].PrevKeyptr[2] == 0 or os.clock()-fcw[1].PrevKeyptr[3] > 0.8) and keyptr[205] ~= 0 and fcw[2].Scrolling and IsRectHovered(ro_RectBG[2].settings, 0) then
			GoToLine(2,math.min(b_ChatBufferIdx[2]-(fcw[2].ScrolledBack-5), b_ChatBufferIdx[2]-1));
			if fcw[1].PrevKeyptr[2] == 0 then fcw[1].PrevKeyptr[3] = os.clock(); else fcw[1].PrevKeyptr[3] = os.clock()-0.7; end
		end
		fcw[1].PrevKeyptr[1] = keyptr[203];
		fcw[1].PrevKeyptr[2] = keyptr[205];
	end
	
    if (allSettings.shortcutHideEnabled[1] and keyptr[allSettings.shortcutHide] ~= 0 and keyptr[allSettings.shortcutHideS] ~= 0 and not fcw[1].Keydown and AshitaCore:GetChatManager():IsInputOpen() == 0x00) then
		fcw[1].HideChat = not fcw[1].HideChat;
		fcw[1].Keydown = true;
	else if (keyptr[allSettings.shortcutHide] == 0) then
			fcw[1].Keydown = false;
		end
    end
	
	if (allSettings.shortcutTabEnabled[1] and keyptr[allSettings.shortcutTab] ~= 0 and keyptr[allSettings.shortcutTabS] ~= 0 and not fcw[1].Keydown2 and AshitaCore:GetChatManager():IsInputOpen() == 0x00) then
		local tab_id = utils.FindInTable(tab_Tabs, allSettings.SelectedTab);
		fcw[1].Keydown2 = true;
		if (tab_id) then
			if (tab_id == utils.GetTableLen(tab_Tabs)) then
				tab_NextTab = tab_Tabs[1];
			else
				tab_NextTab = tab_Tabs[tab_id+1];
			end
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
			end
		else if (keyptr[allSettings.shortcutTab2] == 0) then
				fcw[1].Keydown3 = false;
			end
		end
	end
	
end);

ashita.events.register('mouse', 'mouse_callback1', function (e)
    if (e.delta ~= 0) then
        fcw[1].ScrollDelta = e.delta;
		fcw[2].ScrollDelta = e.delta;
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
		imgui.Text('buff_All '..tostring(#b_ChatBuffer[1][2].text)..',N: '..tostring(b_ChatBufferN_All));
		imgui.Text('buff_AA '..tostring(#b_ChatBuffer[2][2].text)..',N: '..tostring(b_ChatBufferN_AllAlt));
		imgui.Text('buff_C '..tostring(#b_ChatBuffer[3][2].text)..',N: '..tostring(b_ChatBufferN_Combat));
		imgui.Text('buff_LS '..tostring(#b_ChatBuffer[4][2].text)..',N: '..tostring(b_ChatBufferN_Linkshell));
		imgui.Text('buff_PT '..tostring(#b_ChatBuffer[5][2].text)..',N: '..tostring(b_ChatBufferN_Party));
		imgui.Text('buff_SH '..tostring(#b_ChatBuffer[7][2].text)..',N: '..tostring(b_ChatBufferN_Shout));
		imgui.Text('buff_NPC '..tostring(#b_ChatBuffer[6][2].text)..',N: '..tostring(b_ChatBufferN_NPC));
		local buffsum = 0;
		for i = 3, 7 do
			buffsum = buffsum + #b_ChatBuffer[i][2].text;
		end
		imgui.Text('buff_Sum '..tostring(buffsum));
		imgui.Text('buff_AA+C '..tostring(#b_ChatBuffer[2][2].text+#b_ChatBuffer[3][2].text));
		local MBcheck = false;
		if
			#b_ChatBuffer[1][2].text == #b_ChatBuffer[1][2].mode and
			#b_ChatBuffer[1][2].mode == #b_ChatBuffer[1][2].color and
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

		--imgui.Text();
	--	imgui.BeginChild('DebugPrints',{ dw_WindowW*0.9, dw_WindowH*0.9 }, true)
		imgui.BeginChild('Debugchild',{imgui.GetWindowWidth()*0.8, imgui.GetWindowHeight()*0.8,true})
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
	fcw[1].FWDBaseX = (allSettings.fontSettings.font_height/1.35)+(allSettings.chatLineMaxL*allSettings.fontSettings.font_height/400)
	fcw[1].BKWBaseY = (allSettings.fontSettings.font_height*allSettings.ChatLines)+((allSettings.fontSettings.font_height*5)/allSettings.fontSettings.font_height)
	fcw[1].BKWBaseX = ((allSettings.fontSettings.font_height*1.5)/allSettings.fontSettings.font_height)

end

function ResetScrolling(id)
	fcw[id].Scrolling = false;
	fcw[id].ScrolledBack = 0;
	--fcw[2].ChatShiftScale_CarryOver = 0;
	--fcw[id].ScrollDelta = 0;
	ResetLines(id);
end

function ChangeTab(fo_id, tabName)

	if fo_id == 1 then
		allSettings.SelectedTab = tabName;
		--if tabName == 'AllAlt' then selectedTab = 'All'; end
	else
		allSettings.SelectedTab2 = tabName;
		--if tabName == 'AllAlt' then selectedTab2 = 'All'; end
	end
	b_ChatBufferIdx[fo_id] = (function()
		if (tabName == 'All') then			b_ChatBufferMode[fo_id] = 1; return b_ChatBufferN_All; 			end
		if (tabName == 'Combat') then 		b_ChatBufferMode[fo_id] = 3; return b_ChatBufferN_Combat; 		end
		if (tabName == 'Linkshell') then	b_ChatBufferMode[fo_id] = 4; return b_ChatBufferN_Linkshell; 	end
		if (tabName == 'Party') then 		b_ChatBufferMode[fo_id] = 5; return b_ChatBufferN_Party; 		end
		if (tabName == 'Tell') then 		b_ChatBufferMode[fo_id] = 6; return b_ChatBufferN_Tell; 		end
		if (tabName == 'Shout') then 		b_ChatBufferMode[fo_id] = 7; return b_ChatBufferN_Shout;		end
		if (tabName == 'NPC') then			b_ChatBufferMode[fo_id] = 8; return b_ChatBufferN_NPC;			end
		return b_ChatBufferIdx[fo_id];
	end)();
	
	if tabName == 'All' and allSettings.HideCombatFromAll[1] then  b_ChatBufferMode[fo_id] = 2; b_ChatBufferIdx[fo_id] = b_ChatBufferN_AllAlt end

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
			fo_Aux[fo_id][L_i]:set_font_color(0xFFFFFFFF);
		end
		L_i = L_i +1;
		if (L_i > allSettings.ChatLines) then L_i = 1; end 
	end 


end

function ResetLines(fo_id)
	--fcw[fo_id].ScrolledBack = 0;
	local L_i = fcw[fo_id].ChatHead;
	--print(tostring(L_i));
	for C_i = 1, allSettings.ChatLines do
		if(utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].text)-C_i+1 > 0) then
			fo_Chat[fo_id][L_i]:set_text(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].text[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].text)-C_i+1]:trimex());
			fo_Chat[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].color)-C_i+1]);
			fo_Aux[fo_id][L_i]:set_text(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxText[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxText)-C_i+1]:trimex());
			fo_Aux[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxColor)-C_i+1]);
			fo_Chat[fo_id][L_i]:set_outline_color(0xFF000000);
			fo_Aux[fo_id][L_i]:set_outline_color(0xFF000000);
			--fo_Chat[fo_id][L_i]:set_visible(false);
			fo_Aux[fo_id][L_i]:set_visible(false);
		else
			fo_Chat[fo_id][L_i]:set_text(' ');
			fo_Chat[fo_id][L_i]:set_font_color(0xFF000000);
			fo_Aux[fo_id][L_i]:set_text(' ');
			fo_Aux[fo_id][L_i]:set_font_color(0xFF000000);
			fo_Chat[fo_id][L_i]:set_outline_color(0xFF000000);
			fo_Aux[fo_id][L_i]:set_outline_color(0xFF000000);
			--fo_Chat[fo_id][L_i]:set_visible(false);
			fo_Aux[fo_id][L_i]:set_visible(false);
		end

		L_i = L_i +1;
		if (L_i > allSettings.ChatLines) then L_i = 1; end 
	end
	--if allSettings.SelectedTab == 'All' and allSettings.HideCombatFromAll[1] then b_ChatBufferN[fo_id]=b_ChatBufferN_AllAlt;  end
	fcw[fo_id].ChatShift = allSettings.fontSettings.font_height
	b_ChatBufferIdx[fo_id] = b_ChatBufferN[fo_id];
	fcw[fo_id].PositionLinesRequest = {true,true};
	--fcw[1].ResetCD = os.clock();
	--SetLinesVisible(fo_id, false)
end

function GoToLine(fo_id, line)
	--fcw[fo_id].ScrolledBack = 0;
	--print(line);
	if line <= utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].text)
	and line >= allSettings.ChatLines
	then
		--
		fcw[fo_id].Scrolling = true;
		fcw[fo_id].ChatShift = allSettings.fontSettings.font_height
		fcw[fo_id].ScrolledBack = b_ChatBufferIdx[fo_id]-line;
		local L_i = fcw[fo_id].ChatHead;
	--print(tostring(L_i));
		for C_i = 1, allSettings.ChatLines do
			if(utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].text)-C_i+1-line +allSettings.ChatLines > 0) then
				fo_Chat[fo_id][L_i]:set_text(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].text[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].text)-C_i+1-fcw[fo_id].ScrolledBack]:trimex());
				fo_Chat[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].color)-C_i+1-fcw[fo_id].ScrolledBack]);
				fo_Aux[fo_id][L_i]:set_text(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxText[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxText)-C_i+1-fcw[fo_id].ScrolledBack]:trimex());
				--fo_Chat[fo_id][L_i]:set_visible(false);
				fo_Aux[fo_id][L_i]:set_visible(false);
				fo_Aux[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxColor)-C_i+1-fcw[fo_id].ScrolledBack]);
				fo_Chat[fo_id][L_i]:set_outline_color(0xFF000000);
				fo_Aux[fo_id][L_i]:set_outline_color(0xFF000000);
			else
				fo_Chat[fo_id][L_i]:set_text(' ');
				--fo_Chat[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].color[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].color)-C_i+1-line]);
				fo_Aux[fo_id][L_i]:set_text(' ');
				--fo_Aux[fo_id][L_i]:set_font_color(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxColor[utils.GetTableLen(b_ChatBuffer[b_ChatBufferMode[fo_id]][2].auxColor)-C_i+1-line]);
			end

			L_i = L_i +1;
			if (L_i > allSettings.ChatLines) then L_i = 1; end 
		end 
		--b_ChatBufferIdx[fo_id] = line;
		fcw[fo_id].PositionLinesRequest = {true,true};
	end
end

function ScrollLines(fo_id, message, color, auxMessage, auxColor, mode)

    -- scrollback > 1
	-- scrollfwd > 0
	fcw[fo_id].PositionLinesRequest = {true,true};
	local L_i = fcw[fo_id].ChatHead+mode;
	if (mode == 1 and L_i > allSettings.ChatLines) then L_i = 1; end 
	for C_i = 0, allSettings.ChatLines-2 do
		fo_Chat[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*(C_i)));
		fo_Aux[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*(C_i)));
		
		L_i = L_i - 1 + (2*mode);
		if (L_i > allSettings.ChatLines) then L_i = 1; end
		if (L_i < 1) then L_i = allSettings.ChatLines; end
	end
	local NL_i = fcw[fo_id].ChatHead; local NL_ii = NL_i-1; if NL_ii < 1 then NL_ii =  allSettings.ChatLines;end
	if mode == 0 then NL_i = fcw[fo_id].ChatHead-1; if (NL_i < 1) then NL_i = allSettings.ChatLines; end end
	
	if mode == 1 then
		fo_Chat[fo_id][NL_ii]:set_font_color(bit.bor(0xFF000000,bit.band(fo_Chat[fo_id][NL_ii].settings.font_color,0x00FFFFFF)))
		fo_Aux[fo_id][NL_ii]:set_font_color(bit.bor(0xFF000000,bit.band(fo_Aux[fo_id][NL_ii].settings.font_color,0x00FFFFFF)))
		fo_Chat[fo_id][NL_ii]:set_outline_color(0xFF000000);
		fo_Aux[fo_id][NL_ii]:set_outline_color(0xFF000000);
	end
--	if fo_Chat[fo_id][NL_i].settings.font_color ~= color then
	fo_Chat[fo_id][NL_i]:set_font_color(color);
--	end
	fo_Chat[fo_id][NL_i]:set_position_y(fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*allSettings.ChatLines*mode));
	fo_Aux[fo_id][NL_i]:set_position_y(fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*allSettings.ChatLines*mode));
	fo_Chat[fo_id][NL_i]:set_text(message:trimex());
	fo_Aux[fo_id][NL_i]:set_font_color(auxColor);
	fo_Aux[fo_id][NL_i]:set_text(auxMessage:trimex());
	
	fo_Chat[fo_id][NL_i]:set_outline_color(0xFF000000);
	fo_Aux[fo_id][NL_i]:set_outline_color(0xFF000000);
	--fo_Chat[fo_id][L_i]:set_visible(false);
	fo_Aux[fo_id][NL_i]:set_visible(false);
	
	fcw[fo_id].ChatHead = fcw[fo_id].ChatHead-1+(2*mode);
	if (fcw[fo_id].ChatHead > allSettings.ChatLines) then fcw[fo_id].ChatHead = 1; end 
	if (fcw[fo_id].ChatHead < 1) then fcw[fo_id].ChatHead = allSettings.ChatLines; end
	return
end

function PrepareLines(fo_id)
	local L_i = fcw[fo_id].ChatHead;
	for C_i = 1, allSettings.ChatLines do
		fo_Chat[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*(C_i)) + fcw[fo_id].ChatShift);
		fo_Chat[fo_id][L_i]:set_position_x(fcw[fo_id].Anchor_X);
		fo_Aux[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*(C_i)) + fcw[fo_id].ChatShift);
		if fo_Chat[fo_id][L_i].rect then
			fo_Aux[fo_id][L_i]:set_position_x(math.floor(fcw[fo_id].Anchor_X+fo_Chat[fo_id][L_i].rect.right+allSettings.fontSettings.font_height/1.75));
		end
		L_i = L_i +1;
		if (L_i > allSettings.ChatLines) then L_i = 1; end 
	end
end

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

function PositionLines(fo_id)
	--if fcw[2].PositionLinesRequest then Debug('poslinereq1 '..tostring(fcw[1].PositionLinesRequest), 1, true) end
	if fcw[fo_id].PositionLinesRequest[1] then
		dw_PLRCount = dw_PLRCount+1;
		local was2requested = fcw[fo_id].PositionLinesRequest[2];
		--ro_Scroll[fo_id]:set_visible(true);
		if fcw[fo_id].PositionLinesRequest[2] then
			
			
			ro_RectBG[fo_id]:set_position_x(fcw[fo_id].Anchor_X-fcw[1].RoRectBaseX);
			--ro_RectBG[fo_id]:set_position_y(fcw[fo_id].Anchor_Y-fcw[fo_id].RoRectBaseY);
			ro_RectBG[fo_id]:set_position_y(fcw[fo_id].Anchor_Y- fcw[1].RoRectBaseY);
			if not fcw[fo_id].PLFast or was2requested then
			if fcw[fo_id].ScrollPos then
				ro_Scroll[fo_id]:set_width(ro_RectBG[fo_id].settings.width/200);	
				ro_Scroll[fo_id]:set_height(ro_RectBG[fo_id].settings.height/15);
				local h = ro_RectBG[fo_id].settings.position_y+(ro_Scroll[fo_id].settings.height*(1-fcw[fo_id].ScrollPos)+(allSettings.fontSettings.font_height*1.15))-(1-(fcw[fo_id].ScrollPos*ro_RectBG[fo_id].settings.height-ro_Scroll[fo_id].settings.height-allSettings.fontSettings.font_height*1.15));
				ro_Scroll[fo_id]:set_position_y(h+1);
				ro_Scroll[fo_id]:set_position_x(ro_RectBG[fo_id].settings.position_x+ro_RectBG[fo_id].settings.width-ro_Scroll[fo_id].settings.width-1);
			end	
			fo_Fwd[fo_id]:set_position_x(ro_RectBG[fo_id].settings.position_x+ro_RectBG[fo_id].settings.width-fcw[1].FWDBaseX);
			fo_Fwd[fo_id]:set_position_y(fcw[fo_id].Anchor_Y);
			fo_Bkw[fo_id]:set_position_x(fcw[fo_id].Anchor_X - fcw[1].BKWBaseX);
			fo_Bkw[fo_id]:set_position_y(fcw[fo_id].Anchor_Y - fcw[1].BKWBaseY);
			end
			
		end
		
		local fcwFoId = fcw[fo_id]
		fcwFoId.PositionLinesRequest = {false, false};
		local L_i = fcw[fo_id].ChatHead;
		for C_i = 1, allSettings.ChatLines do
			local chatLi = fo_Chat[fo_id][L_i]
			local auxLi = fo_Aux[fo_id][L_i]
				--fo_Chat[fo_id][L_i]:set_font_height(allSettings.fontSettings.font_height);
				--fo_Chat[fo_id][L_i]:get_background():set_fill_color(allSettings.fontSettings.background.fill_color);
			
				--fo_Aux[fo_id][L_i]:set_font_height(allSettings.fontSettings.font_height);
			
			local isLastLine = L_i+1 == fcwFoId.ChatHead or L_i+1-allSettings.ChatLines == fcwFoId.ChatHead;
			
			--
			if 	isLastLine and fcwFoId.ChatShift < allSettings.fontSettings.font_height
				--and fcw[fo_id].ChatShift > 0
				--- move this below vvv
				--and bit.rshift(fo_Chat[fo_id][L_i].settings.font_color, 24) > (bit.rshift(decr*bit.tobit(multi),24)+thresh
			then
			------------------------------------------------------------------------
				-- if (os.clock()-fcw[fo_id].OsClockLastFade > 0.04) then
					-- local decr = (fcw[fo_id].ChatShiftScale-(30*(fcw[fo_id].ChatShiftScale/fcw[fo_id].ChatShiftScale_Min-1)))/fcw[fo_id].ChatShiftScale_Min*0x1D;
					-- if fo_Chat[fo_id][L_i].settings.font_color~= nil then
						-- local alpha = math.max(bit.rshift(fo_Chat[fo_id][L_i].settings.font_color, 24)-decr,0x00)
						-- fo_Chat[fo_id][L_i]:set_font_color(bit.bor(bit.lshift(alpha, 24),bit.band(fo_Chat[fo_id][L_i].settings.font_color,0x00FFFFFF)));
						-- fo_id][L_i].settings.font_color,0x00FFFFFF)));
						-- alpha = math.max(bit.rshift(fcw[fo_id].OutlineColor, 24)-decr,0x02)
						-- fcw[fo_id].OutlineColor = bit.lshift(alpha, 24)
						-- fo_Chat[fo_id][L_i]:set_outline_color(fcw[fo_id].OutlineColor);
						-- fo_Aux[fo_id][L_i]:set_outline_color(fcw[fo_id].OutlineColor);
					-- end
					-- fcw[fo_id].OsClockLastFade = os.clock();
				-- end
				
				 -- Cache fcw[fo_id] to avoid repeated table lookup
				  -- Cache fo_Chat[fo_id][L_i] to avoid repeated table lookup
				
				-- Check if the clock difference is greater than 0.04
				if (os.clock() - fcwFoId.OsClockLastFade > 0.04) then
					
					-- Cache values to simplify the formula
					local scale = fcwFoId.ChatShiftScale
					local scaleMin = fcwFoId.ChatShiftScale_Min
					local decr = (scale - (30 * ((scale / scaleMin) - 1))) / scaleMin * 0x1D

					-- Check if font color is not nil
					if chatLi.settings.font_color ~= nil then
						local alpha = bit.lshift(math.max(bit.rshift(chatLi.settings.font_color, 24)-decr,0x00), 24)
						chatLi:set_font_color(bit.bor(alpha,bit.band(chatLi.settings.font_color,0x00FFFFFF)));
						auxLi:set_font_color(bit.bor(alpha,bit.band(auxLi.settings.font_color,0x00FFFFFF)));
						alpha = math.max(bit.rshift(fcwFoId.OutlineColor, 24)-decr,0x02)
						fcwFoId.OutlineColor = bit.lshift(alpha, 24)
						chatLi:set_outline_color(fcwFoId.OutlineColor);
						auxLi:set_outline_color(fcwFoId.OutlineColor);
					end

					-- Update the OsClockLastFade to the current time
					fcwFoId.OsClockLastFade = os.clock()
				end
			end
			
			
			
			chatLi:set_position_y( fcwFoId.ChatShift + fcwFoId.Anchor_Y - (allSettings.fontSettings.font_height*(C_i)));
			chatLi:set_position_x(fcw[fo_id].Anchor_X);
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
			fcw[fo_id].PLFast = false
			if ((L_i == fcwFoId.ChatHead or was2requested)) then
				
				--fo_Chat[fo_id][L_i]:set_outline_color(0xFF000000);
				--fo_Aux[fo_id][L_i]:set_outline_color(0xFF000000);
				
	
				if (chatLi.rect ~= nil and not chatLi.is_dirty ) then 
					
					auxLi:set_position_x(math.floor(fcwFoId.Anchor_X+chatLi.rect.right+allSettings.fontSettings.font_height/1.75));
					auxLi:set_visible(true)
					
				elseif chatLi.is_dirty then
					chatLi:set_visible(true)
					fcwFoId.PositionLinesRequest = {true, true};
					fcw[fo_id].PLFast = true
				end
			end
			
			auxLi:set_position_y( fcwFoId.ChatShift + fcwFoId.Anchor_Y - (allSettings.fontSettings.font_height*(C_i)));
			L_i = L_i +1;
			if (L_i > allSettings.ChatLines) then L_i = 1; end 
		end
		
	end
end

function UpdateLines(fo_id, message, color, auxMessage, auxColor)
	
	local L_i = fcw[fo_id].ChatHead;
	for C_i = 1, allSettings.ChatLines-1 do
		fo_Chat[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*(C_i)));
		fo_Aux[fo_id][L_i]:set_position_y( fcw[fo_id].Anchor_Y - (allSettings.fontSettings.font_height*(C_i)));
		L_i = L_i +1;
		if (L_i > allSettings.ChatLines) then L_i = 1; end 
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
	fcw[fo_id].ChatHead = fcw[fo_id].ChatHead-1;
	if (fcw[fo_id].ChatHead < 1) then fcw[fo_id].ChatHead = allSettings.ChatLines; end 
	return
end

function CleanText(text, mode)
	--text = AshitaCore:GetChatManager():ParseAutoTranslate(text, true);
	--text = utils.processMsg(text, mode);
	local systemChannel = false;
	local cleantext = '';
	local idx = 1;
	local testString = '';
	
	local intString = {};
	local addLog = true;
	if not string.find(mode, 'combat') and not string.find(mode,'combatspell') and not string.find(mode,'shout') and not string.find(mode,'unity') and par_MessageMode ~= 152 and not string.find(mode, 'linkshell') then addLog = true; end
	
	
	
	--1
	--if addLog then table.insert(b_LogBuffer,  'Mode: '..mode..' Channel:'..tostring(par_MessageMode)); end
	
	--2
	--if addLog then table.insert(b_LogBuffer,  'Dirty text: '..text); end
	
	for idx = 1, string.len(text) do
		table.insert(intString, string.byte(string.sub(text,idx,idx)));
	end
	
	-- and os.clock()-uiw.DialogCDStart > 0.02
	if (par_MessageMode == 150 or par_MessageMode == 151) and par_LastMsgInConv then uiw.DialogPromptStart = os.clock(); end 
	if (par_MessageMode == 150 or par_MessageMode == 151)	then 
		if par_InEvent then
			--Debug(text..tostring(par_MessageMode), 1, true);
			--if ashita.memory.read_uint32(uiw.DialogPtr) ~= 1 and not par_LastMsgInConv then
				par_LastMsgInConv = true;
			--end
		else
			par_LastMsgInConv = false;
		end
	end

	--3
	--if addLog then table.insert(b_LogBuffer,  'Test string: \\'..table.concat(intString, '\\')); end
	
	local dtest = '';
	for d = 1, #text do
		
		dtest = dtest..tostring(intString[d])..','..string.sub(text,d,d)..'|'
		--Debug(tostring(intString[d])..' '..string.sub(text,d,d)..',', 1 , true);
		--Debug(text, 1 , true );
		
	end
	
	--4
	if addLog then table.insert(b_LogBuffer, 'Char-Int match: '..dtest); end
	--[[
	
	then
		par_promptEnd = {intString[#intString-1], intString[#intString]};
		table.remove(intString, #intString);
		table.remove(intString, #intString);
	end
	]]--
	--Debug(text, 1 , table.concat(par_promptEnd, ',') );
	
	
	if not string.find(mode, 'combat') or par_MessageMode == 80 or not allSettings.CompactCombat[1] then
		-----intString = utils.ReplaceInts(intString, utils.badStringsCombat);
	----else
		intString = utils.ReplaceInts(intString);
		intString = utils.CleanInts(intString);
	else
		table.remove(intString,#intString)
		---intString = utils.ReplaceInts(intString, utils.badStringsCyrillic);
	end
	
	---Debug(table.concat(intString, ','),1, true);
	--intString = utils.ReplaceInts(intString, utils.badStrings);
	
	--5
	--if addLog then table.insert(b_LogBuffer, 'After ReplaceInts: '..table.concat(intString, ',')); end
	
	--Debug(table.concat(intString, ','), 1 , true);
	
	
	--6
	--if addLog then table.insert(b_LogBuffer, 'After CleanInts: '..table.concat(intString, ',')); end
	
	
	--Debug(table.concat(intString, ','), 1 , true);
	--Debug(table.concat(intString, ','), 1 , true);
	
	--if #par_promptEnd > 0 then
	--	table.insert(intString, par_promptEnd[#par_promptEnd-1])
	--	table.insert(intString, par_promptEnd[#par_promptEnd])
	--end
	--intString = utils.ReplaceInts(intString, utils.badStrings);
	
	--Debug(table.concat(intString, ','), 1 , true);
	
	if intString[#intString] == 10 then table.remove(intString, #intString); end

	
	--local utf8count = 0;
	if (#intString) > 0 then
		cleanInts = {}
		cleantext = utils.int2text(intString, utils.UTF8chars)
		for a = 1, #cleantext do
		
		table.insert(cleanInts, string.byte(cleantext[a]));
		--Debug(tostring(intString[d])..' '..string.sub(text,d,d)..',', 1 , true);
		--Debug(text, 1 , true );
		
		end
		if addLog then table.insert(b_LogBuffer, table.concat(cleanInts,',')); end
		--  7/8
		--if addLog then table.insert(b_LogBuffer, 'After int2text: '..cleantext); end
		if addLog then table.insert(b_LogBuffer, 'Mode: '..mode..' Channel:'..tostring(par_MessageMode)..'Msg: '..cleantext); end
		if addLog then table.insert(b_LogBuffer, '----------'); end
		--Debug(cleantext, 1 , true);
		if allSettings.heartEmoji[1] then cleantext = string.gsub(cleantext, '<3', utf8.char(0x2764)); end

	end
	
	-- Cleanup 10--
	if #b_LogBuffer > 1000 then
		for _ = 1, 4 do
			table.remove(b_LogBuffer,1);
		end
	end
	
	--if #promptEnd > 0 then cleantext = cleantext..'\\'..tostring(promptEnd[1])..'\\'..tostring(promptEnd[2]) end;
	
	return cleantext:trimex();
end

function ResetColors()
	allSettings.defaultColor = T{1,1,1,1};
	local a, r, g, b;
	local done = 0x00000000;
	local i = 1;
	while bit.bxor(done,0xFFFFFFFF) ~= 0 and i <= #utils.modesDA do
		if bit.band(0x0000000F, done) == 0 and string.find(utils.modesDA[i][2], 'linkshell1') then
			a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			allSettings.linkshellColor = T{r/255,g/255,b/255,a/255};
			done = bit.bor(0x0000000F, done)
		end
		if bit.band(0x000000F0, done) == 0 and string.find(utils.modesDA[i][2], 'linkshell2') then
			a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			allSettings.linkshell2Color = T{r/255,g/255,b/255,a/255};
			done = bit.bor(0x000000F0, done)
		end
		if bit.band(0x00000F00, done) == 0 and string.find(utils.modesDA[i][2], 'party') then
			a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			allSettings.partyColor = T{r/255,g/255,b/255,a/255};
			done = bit.bor(0x00000F00, done)
		end
		if bit.band(0x0000F000, done) == 0 and string.find(utils.modesDA[i][2], 'tell') then
			a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			allSettings.tellColor = T{r/255,g/255,b/255,a/255};
			done = bit.bor(0x0000F000, done)
		end
		if bit.band(0x000F0000, done) == 0 and string.find(utils.modesDA[i][2], 'shout') then
			a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			allSettings.shoutColor = T{r/255,g/255,b/255,a/255};
			done = bit.bor(0x000F0000, done)
		end
		if bit.band(0x00F00000, done) == 0 and string.find(utils.modesDA[i][2], 'emote') then
			a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			allSettings.emoteColor = T{r/255,g/255,b/255,a/255};
			done = bit.bor(0x00F00000, done)
		end
		if bit.band(0x0F000000, done) == 0 and string.find(utils.modesDA[i][2],'combat_') then
			a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			allSettings.combatColor = T{r/255,g/255,b/255,a/255};
			done = bit.bor(0x0F000000, done)
		end
		if bit.band(0xF0000000, done) == 0 and string.find(utils.modesDA[i][2], 'combatspell_') then
			--print(tostring(i)..'.'..tostring(bit.tohex(utils.modesDA[i][3])))
			a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(utils.modesDA[i][3])));
			allSettings.combatspellColor = T{r/255,g/255,b/255,a/255};
			done = bit.bor(0xF0000000, done)
		end
		i = i+1;
	end
		a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(0xFFF7CF05)));
		allSettings.dmgColor = T{r/255,g/255,b/255,a/255};
		
		a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(allSettings.ColorBlind[1] and 0xFF91FFF0 or 0xFF91FF47)));
		allSettings.dmgDoneColor = T{r/255,g/255,b/255,a/255};
		
		a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(allSettings.ColorBlind[1] and 0xFFFFA269 or 0xFFFA4343)));
		allSettings.dmgGotColor = T{r/255,g/255,b/255,a/255};
		
		a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(0xFFFF9C17)));
		allSettings.spelldmgColor = T{r/255,g/255,b/255,a/255};
		
		a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(allSettings.ColorBlind[1] and 0xFF5EE0DE or 0xFFADFF33)));
		allSettings.spelldmgDoneColor = T{r/255,g/255,b/255,a/255};
		
		a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(allSettings.ColorBlind[1] and 0xFFE6874C or 0xFFFC2B43)));
		allSettings.spelldmgGotColor = T{r/255,g/255,b/255,a/255};
	
end

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

function CombatText(msg, chn)
	
	local A = '';
	local B = '';
	local DMG = '';
	local S = '';
		
	if msg:find('hit') then
		A, B, DMG = msg:match("^(.*) hits? (.*) for (%d*) points? of damage%.$")
		--Debug(tostring(A)..'-'..tostring(B)..'-'..tostring(DMG),1,true)
		if A and B and DMG then
		
			if not A:find('^[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			if not B:find('^[Tt]he') then B = '['..B..']' else
			B = B:gsub('[Tt]he ', '');
			end
			
			msg = A..' '..utf8.char(0x25B6)..' '..B..' '..utf8.char(allSettings.CombatSplitChar[2])..' '..DMG..' DMG';
			if (A:find(fcw[1].PlayerName)) then par_DamageDone = true; end;
			if (B:find(fcw[1].PlayerName)) then par_DamageGot = true; end;
			
			msg = msg:gsub('ranged attack', 'RA');
			par_CombatCutIdx = utils.FindLastOfMB(msg, utf8.char(allSettings.CombatSplitChar[2]))+string.len(utf8.char(allSettings.CombatSplitChar[2]))-1;
			
			return msg
		end
	end

	if msg:find('score') then
		A, B, DMG = msg:match("^(.*) scores? a critical hit! (.*) takes? (%d*) points? of damage%.$")
		if A and B and DMG then
		
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if not A:find('^[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			if not B:find('^[Tt]he') then B = '['..B..']' else
			B = B:gsub('[Tt]he ', '');
			end

			msg = A..' '..utf8.char(0x25B6)..' '..B..' '..utf8.char(allSettings.CombatSplitChar[2])..' '..DMG..' crit DMG!';
			
			msg = msg:gsub('ranged attack', 'RA');
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(allSettings.CombatSplitChar[2]))+string.len(utf8.char(allSettings.CombatSplitChar[2]))-1;
			return msg;
		end
	end
	
	if msg:find('use') then
		A, S, B, DMG = msg:match("^(.*) uses? (.*)%.%s*(.*) takes? (%d*) points? of damage%.$")
		if A and B and S and DMG then
		
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if not A:find('^[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			if not B:find('^[Tt]he') then B = '['..B..']' else
			B = B:gsub('[Tt]he ', '');
			end
			
			msg = A..' '..utf8.char(0x25B6)..' '..B..' '..utf8.char(allSettings.CombatSplitChar[2])..' ['..S..']'..utf8.char(0x589)..' '..DMG..' DMG';
			
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(allSettings.CombatSplitChar[2]))+string.len(utf8.char(allSettings.CombatSplitChar[2]))-1;
			return msg;
		end


		A, S, Ext = msg:match("^(.*) uses? ([^%.]*)%.%s*(.*)$")
		if A and S and not msg:find('damage')then
			
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			-- --if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if Ext and Ext:trimex() ~= '' then

				Ext = Ext:gsub('receives the effect of', utf8.char(0x25C0))
				Ext = Ext:gsub('gains the effect of', utf8.char(0x25C0))
				Ext = Ext:gsub('is afflicted with', utf8.char(0x25C0))
				Ext = Ext:gsub('successfully (.)', function(c) return utf8.char(0x25B6)..' '..c:upper() end)
				Ext = Ext..' '
			else
				Ext = ''
			end
			if not A:find('^[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			msg = Ext..A..' '..utf8.char(0x25B6)..' ['..S..']';
					
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(0x25B6))+string.len(utf8.char(0x25B6))-1;
			return msg;
		end
	end
	
	if msg:find('Skillchain') then
		S, A, DMG = msg:match("^(Skillchain: [^%.]*)%.%s(.*) takes? (%d*) points? of damage%.$")
		if S and A and DMG then
			
			A = A:gsub('[Tt]he ', '');
			msg = A..' '..utf8.char(0x25C0)..' ['..S:gsub('Skillchain:','SC -')..']'..utf8.char(0x589)..' '..DMG..' DMG';
			
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(0x25C0))+string.len(utf8.char(0x25C0))-1;
			return msg;
		end
	end
	-- [00:27:39] Eleanor takes 175 points of damage.â¯28
	--[00:29:08] Zeid takes 161 points of damage.â¯32
	--[00:31:31] yYou do not meet the requirements to obtain the monk's testimony. Monk's testimony lost.â¯121
	
	if msg:find('take') then
		A, DMG = msg:match("^([^%p]*) takes? (%d*) points? of damage%.$")
		if A and DMG then
			if A:find('^[Tt]he ') then A = A:gsub('[Tt]he ',' ') else A = '['..A..']' end
			msg = utf8.char(0x2514)..utf8.char(0x2500)..A..' '..utf8.char(0x25C0)..' '..DMG..' DMG';
			if (A == fcw[1].PlayerName) then par_DamageGot = true; end;
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(0x25C0))+string.len(utf8.char(0x25C0))-1;
			return msg;
		end
	end

	if msg:find('Additional') then
		S = msg:match("^Additional effect: (.*)$")
		if S then
			msg = '[Add.Eff.] '..utf8.char(allSettings.CombatSplitChar[2])..' '..S:gsub('points of damage.','DMG')..' ';
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(allSettings.CombatSplitChar[2]))+string.len(utf8.char(allSettings.CombatSplitChar[2]))-1;
			return msg;
		end
	end

	if msg:find('read') then
		A, S = msg:match("^(.*) read[%a]* (.*)%.$")
		if A and S then
			if not A:find('^[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			msg = A..' '..utf8.char(allSettings.CombatSplitChar[2])..' readies...'..'['..S..']';
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(allSettings.CombatSplitChar[2]))+string.len(utf8.char(allSettings.CombatSplitChar[2]))-1;
			return msg;
		end
	end	
	
	if msg:find('parr') then
		--[18:25] Eleanor parries the Drachenlizard's attack with her weapon. 
		A, B = msg:match("^(.*) parr[%a]* ([^%p]*)%p?s?.*%.$")
		if A and B then
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if not A:find('[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			if not B:find('[Tt]he') then B = '['..B..']' else
			B = B:gsub('[Tt]he ', '');
			end
			msg = A..' '..utf8.char(0x25C0)..' '..B..' '..utf8.char(allSettings.CombatSplitChar[2])..' Parry';
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(allSettings.CombatSplitChar[2]))+string.len(utf8.char(allSettings.CombatSplitChar[2]))-1;
			return msg;
		end
	end

	if msg:find('miss') then
		--Tenzen uses Amatsu: Tsukioboro, but misses the Drachenlizard.
		--Tenzen misses the Drachenlizard...' '..B..' '
		A, B = msg:match("^(.*) miss[%a]* (.*)%.$")
		if A and B then
			local F = A:find(' use')
			local Ext = ''
			if F then Ext = A:sub(F,#A); A = A:sub(1,F-1); end
			if (B == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (A == fcw[1].PlayerName) then par_DamageGot = true; end;
			if not A:find('[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			if not B:find('[Tt]he') then B = '['..B..']' else
			B = B:gsub('[Tt]he ', '');
			end--utf8.char(0x25B6)' ['..c2..']. '
			--Ext = Ext:gsub('^( uses? )([^,]*)(.*)$', function(c1,c2,c3) return ' '..utf8.char(0x25B6)..' '..B end) 
			Ext = Ext:gsub('^( uses? )([^,]*)(.*)$', function(c1,c2,c3) return '['..c2..']'..utf8.char(0x589) end) 
			msg = A..' '..utf8.char(0x25B6)..' '..B..' '..utf8.char(allSettings.CombatSplitChar[2])..Ext..' Miss';
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(allSettings.CombatSplitChar[2]))+string.len(utf8.char(allSettings.CombatSplitChar[2]))-1;
			return msg;
		end
	end	
		--[16:27] Halver defeats the Drachenlizard. 
	
	if msg:find('defeat') then
		A, B = msg:match("^(.*) defeats? (.*)%.$")
		if A and B then
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if not A:find('^[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			if not B:find('^[Tt]he') then B = '['..B..']' else
			B = B:gsub('[Tt]he ', '');
			end
			msg = A..' '..utf8.char(0x25B6)..' '..B..' '..utf8.char(allSettings.CombatSplitChar[2])..' Defeat';
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(allSettings.CombatSplitChar[2]))+string.len(utf8.char(allSettings.CombatSplitChar[2]))-1;
			return msg;
		end
	end
	
	local c = 0
	msg, c = msg:gsub('(receives the effect of )([^%.]*)(%.)', function(c1, c2, c3) return utf8.char(0x25C0)..' ['..c2..']' end)
	if c < 1 then
		msg, c = msg:gsub('(gains the effect of )([^%.]*)(%.)', function(c1, c2, c3) return utf8.char(0x25C0)..' ['..c2..']' end)
	end
	if c < 1 then
		msg, c = msg:gsub('(is afflicted with )([^%.]*)(%.)', function(c1, c2, c3) return utf8.char(0x25C0)..' ['..c2..']' end)
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

function CombatSpellText(msg, chn)

	local A = '';
	local B = '';
	local DMG = '';
	local S = '';
	local T = '';
	
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

			if not A:find('^[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			
			if B ~= '?' then
				if not B:find('^[Tt]he') then B = '['..B..']' else
				B = B:gsub('[Tt]he ', '');
				end
				msg = A..' '..utf8.char(0x25B6)..' '..B..' '..utf8.char(allSettings.CombatSplitChar[2])..' casting...['..S..']';
				
			else
				msg = A..' '..utf8.char(allSettings.CombatSplitChar[2])..' casting...['..S..']';
			end
			
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(allSettings.CombatSplitChar[2]))+string.len(utf8.char(allSettings.CombatSplitChar[2]))-1;
			return msg;
		end
	end

	if msg:find('cast') then
		A, S, B, DMG = msg:match("^(.*) casts? ([^%.]*)%. (.*) takes? (%d*) points? of damage%.$")
		--Debug(tostring(A)..'-'..tostring(S)..'-'..tostring(B)..'-'..tostring(DMG),1,true)
		if A and S and B and DMG then
		

			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if not A:find('^[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			if not B:find('^[Tt]he') then B = '['..B..']' else
			B = B:gsub('[Tt]he ', '');
			end
			msg = A..' '..utf8.char(0x25B6)..' '..B..' '..utf8.char(allSettings.CombatSplitChar[2])..' ['..S..']'..utf8.char(0x589)..' '..DMG..' DMG';
			
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(allSettings.CombatSplitChar[2]))+string.len(utf8.char(allSettings.CombatSplitChar[2]))-1;
			return msg;
		end
		
		--Mode: combat_p Channel:27Msg: The Thaumaturge casts Aspir. 0 MP drained from NanaaMihgo.
		--Mode: combat_p Channel:27Msg: TheThaumaturge casts Drain. 0 HP drained from NanaaMihgo.
		
		A, S, DMG, T, B = msg:match("^(.*) casts? ([^%.]*)%. (%d*) (.*) drained from (.*)%.$")
		--Debug(tostring(A)..'-'..tostring(S)..'-'..tostring(B)..'-'..tostring(DMG),1,true)
		if A and S and B and DMG and T then
		
			
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if not A:find('^[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			if not B:find('^[Tt]he') then B = '['..B..']' else
			B = B:gsub('[Tt]he ', '');
			end
			msg = A..' '..utf8.char(0x25B6)..' '..B..' '..utf8.char(allSettings.CombatSplitChar[2])..' ['..S..']'..utf8.char(0x589)..' '..DMG..' '..T..' drained';
			
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(allSettings.CombatSplitChar[2]))+string.len(utf8.char(allSettings.CombatSplitChar[2]))-1;
			return msg;
		end
		
		--Mode: combatspell Channel:31Msg: Eleanor casts Cure IV. Eleanor recovers 398 HP.


		A, S, B, DMG, T = msg:match("^(.*) casts? ([^%.]*)%. (.*) recovers? (%d*) ([^%.]*)%.$")
		--Debug(tostring(A)..'-'..tostring(S)..'-'..tostring(B)..'-'..tostring(DMG),1,true)
		if A and S and B and DMG and T then
		
			if A == fcw[1].PlayerName or B == fcw[1].PlayerName then par_DamageDone = true; end;
			if not A:find('^[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			if not B:find('^[Tt]he') then B = '['..B..']' else
			B = B:gsub('[Tt]he ', '');
			end
			msg = A..' '..utf8.char(0x25B6)..' '..B..' '..utf8.char(allSettings.CombatSplitChar[2])..' ['..S..']'..utf8.char(0x589)..' +'..DMG..' '..T;

			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(allSettings.CombatSplitChar[2]))+string.len(utf8.char(allSettings.CombatSplitChar[2]))-1;
			return msg;
		end
		
		--[15:41] Joachim casts Poisona. Joachim successfully removes Halver's poison. 
		--Eleanor casts Monomi: Ichi. Eleanor gains the effect of Sneak.
		A, S, Ext = msg:match("^(.*) casts? ([^%.]*)%.%s*(.*)$")
		if A and S and not msg:find('damage') then
			
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			-- --if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if Ext and Ext:trimex() ~= '' then
				--Ext = Ext:gsub(A..' ', '')..' '
				--Ext = Ext:gsub('^.', string.upper(Ext:sub(1,1)))
				Ext = Ext:gsub('receives the effect of', utf8.char(0x25C0))
				Ext = Ext:gsub('gains the effect of', utf8.char(0x25C0))
				Ext = Ext:gsub('is afflicted with', utf8.char(0x25C0))
				Ext = Ext:gsub('successfully (.)', function(c) return utf8.char(0x25B6)..' '..c:upper() end)
				Ext = Ext..' '
			else
				Ext = ''
			end
			if not A:find('^[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			msg = Ext..A..' '..utf8.char(0x25B6)..' ['..S..']';
					
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(0x25B6))+string.len(utf8.char(0x25B6))-1;
			return msg;
		end
	end
	
	if msg:find('use') then
		A, S, Ext = msg:match("^(.*) uses? ([^%.]*)%.%s*(.*)$")
		if A and S and not msg:find('damage') then
			
			if (A == fcw[1].PlayerName) then par_DamageDone = true; end;
			-- --if (B == fcw[1].PlayerName) then par_DamageGot = true; end;
			if Ext and Ext:trimex() ~= '' then
				--Ext = Ext:gsub(A..' ', '')..' '
				--Ext = Ext:gsub('^.', string.upper(Ext:sub(1,1)))
				Ext = Ext:gsub('receives the effect of', utf8.char(0x25C0))
				Ext = Ext:gsub('gains the effect of', utf8.char(0x25C0))
				Ext = Ext:gsub('is afflicted with', utf8.char(0x25C0))
				Ext = Ext:gsub('successfully (.)', function(c) return utf8.char(0x25B6)..' '..c:upper() end)
				Ext = Ext..' '
			else
				Ext = ''
			end
			if not A:find('^[Tt]he') then A = '['..A..']' else
			A = A:gsub('[Tt]he ', ''); end
			msg = Ext..A..' '..utf8.char(0x25B6)..' ['..S..']';
					
			par_CombatCutIdx =  utils.FindLastOfMB(msg, utf8.char(0x25B6))+string.len(utf8.char(0x25B6))-1;
			return msg;
		end
	end	
		
	
	local c = 0
	msg, c = msg:gsub('(receives the effect of )([^%.]*)(%.)', function(c1, c2, c3) return utf8.char(0x25C0)..' ['..c2..']' end)
	if c < 1 then
		msg, c = msg:gsub('(gains the effect of )([^%.]*)(%.)', function(c1, c2, c3) return utf8.char(0x25C0)..' ['..c2..']' end)
	end
	if c < 1 then
		msg, c = msg:gsub('(is afflicted with )([^%.]*)(%.)', function(c1, c2, c3) return utf8.char(0x25C0)..' ['..c2..']' end)
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
	if not critical then imgui.Image(fcw[1].TextureIDInfo,{15,15})
	else imgui.Image(fcw[1].TextureIDInfo,{15,15},{0,0},{1,1},{0.937, 0.349, 0.290 ,1}) end
	if (imgui.IsItemHovered(0)) then
		imgui.BeginTooltip()
		message = utils.breakLine(message, imgui.GetWindowWidth()*2.5)
		imgui.SetTooltip(message)
		imgui.EndTooltip()
		
	end
end

function AddWarning(message)
	if check == false then return end
	local wx = 300
	local wy = 300
	local dsize = imgui.GetIO().DisplaySize;
	imgui.SetNextWindowSize({wx,wy});
	imgui.SetNextWindowPos({(dsize.x/2)-(wx/2),(dsize.y/2)-(wy/2)})
	local wFlags = bit.bor(ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_NoMove, ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoSavedSettings);
	imgui.PushStyleVar(ImGuiStyleVar_WindowTitleAlign, {0.5,0.5})
	imgui.PushStyleColor(ImGuiCol_WindowBg, {0.1,0.1,0.1,1.0});
	imgui.PushStyleColor(ImGuiCol_TitleBg, {0.1,0.1,0.1,1.0});
	imgui.PushStyleColor(ImGuiCol_TitleBgActive, {0.1,0.1,0.1,1.0});
	if imgui.Begin('Warning##'+fcw[1].PlayerName, set_Popup, wFlags) then
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
		imgui.Dummy({(imgui.CalcItemWidth())*0.5,0}) imgui.SameLine()
		imgui.SetCursorPosY(wy-40)
		if imgui.Button('OK##Warning',{70,0}) then
			set_Popup[1] = false;
		end
		imgui.PopTextWrapPos();
		--imgui.Text(message)
		imgui.End();
	end
	imgui.PopStyleColor(3)
	imgui.PopStyleVar();
end

function AddSetColor(buttonname,colortable)
	imgui.ColorButton(buttonname, colortable,ImGuiColorEditFlags_NoAlpha,{49,49})			
	imgui.SameLine();
	imgui.Text(buttonname);
	imgui.SameLine();
	cposX = imgui.GetCursorPosX();
	cposY = imgui.GetCursorPosY();
	imgui.SetCursorPosX(cposX-imgui.CalcTextSize(buttonname)-8);
	imgui.SetCursorPosY(cposY+25);
	if imgui.ArrowButton('Set'..buttonname, ImGuiDir_Left) then
		colortable[1] = set_PickedColor[1]
		colortable[2] = set_PickedColor[2]
		colortable[3] = set_PickedColor[3]
		colortable[4] = 1
		SaveSettings()
	end
	cposY = imgui.GetCursorPosY();
	imgui.SetCursorPosY(cposY-20);
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
	par_DamageDone = false;
	par_DamageGot = false;
	local original_msg = '';
	par_LastMode = 'unknown';

	--local msg = AshitaCore:GetChatManager():ParseAutoTranslate(e_message, true)
			
	 msg = msg:gsub('[^\x1E\x1F][\x07]', function (s)
		local spacing = ' ';
		return s:sub(1, 1):append(spacing);
	 end);

	local ts = '';
	if (allSettings.timeStamp[1]) then ts = os.date(par_FormatTS[allSettings.FormatTSMode], os.time())..' '; end
	original_msg = msg;

	
	par_MessageMode = bit.band(e.mode,  0x000000FF);

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
	
	local colstring = utils.RGBAToHex(allSettings.defaultColor);
	local col = bit.tobit(colstring);
	
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
	
	
	par_LastMode = utils.modesDA[par_MessageMode+1][2];
	col = utils.modesDA[par_MessageMode+1][3];
	
	-- col = (function()
		-- if string.find(par_LastMode, 'combat_') then return bit.tobit(utils.RGBAToHex(allSettings.combatColor));
		-- end
		-- if string.find(par_LastMode, 'combatspell_') then return bit.tobit(utils.RGBAToHex(allSettings.combatspellColor));end
		-- if (par_LastMode=='linkshell1') then return bit.tobit(utils.RGBAToHex(allSettings.linkshellColor)); end
		-- if (par_LastMode=='linkshell2') then return bit.tobit(utils.RGBAToHex(allSettings.linkshell2Color)); end
		-- if (string.find(par_LastMode,'party')) then return bit.tobit(utils.RGBAToHex(allSettings.partyColor)); end
		-- if (string.find(par_LastMode,'tell')) then return bit.tobit(utils.RGBAToHex(allSettings.tellColor)); end
		-- if (string.find(par_LastMode,'shout')) then return bit.tobit(utils.RGBAToHex(allSettings.shoutColor)); end
		-- if (string.find(par_LastMode,'emote')) then return bit.tobit(utils.RGBAToHex(allSettings.emoteColor)); end
		-- return col;
	-- end)();
	
	
	if string.find(par_LastMode, 'combat_') then col = bit.tobit(utils.RGBAToHex(allSettings.combatColor));
	elseif string.find(par_LastMode, 'combatspell_') then col =  bit.tobit(utils.RGBAToHex(allSettings.combatspellColor));
	elseif (par_LastMode=='linkshell1') then col =  bit.tobit(utils.RGBAToHex(allSettings.linkshellColor)); 
	elseif (par_LastMode=='linkshell2') then col =  bit.tobit(utils.RGBAToHex(allSettings.linkshell2Color)); 
	elseif (string.find(par_LastMode,'party')) then col =  bit.tobit(utils.RGBAToHex(allSettings.partyColor)); 
	elseif (string.find(par_LastMode,'tell')) then col =  bit.tobit(utils.RGBAToHex(allSettings.tellColor)); 
	elseif (string.find(par_LastMode,'shout')) then col =  bit.tobit(utils.RGBAToHex(allSettings.shoutColor)); 
	elseif (string.find(par_LastMode,'emote')) then col =  bit.tobit(utils.RGBAToHex(allSettings.emoteColor));
	end
	
	
	if par_LastMode == 'tell_in' and allSettings.tellNotification[1] then ashita.misc.play_sound(string.format('%s\\notifications\\%s%s.wav', addon.path, allSettings.selectedNotification,allSettings.boostNotification[1] and 'B' or '')); end;
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
	
	

	
	--if ( allSettings.hideAlliance[1] and string.find(par_LastMode, '_a') ) then
	--	par_LastMode = 'filtered'; return;
	--end;
	
	--[[
	local isParty = true;
	local isYou = true;
	local isYourPet = true;
	if allSettings.hideNonParty[1]  then
		isParty = false;
		if allSettings.hideNonYou[1] then 
			isYou = false;
			isYourPet = false;
		end
		local party = AshitaCore:GetMemoryManager():GetParty();
		local entity = AshitaCore:GetMemoryManager():GetEntity();
		local bt = targets.get_bt();
		local bt_name;
		local t = targets.get_t();
		local t_name;
		local player_index = party:GetMemberTargetIndex(0);
		if entity ~= nil and party ~= nil then
			if t ~= nil and player_index ~= nil and entity:GetStatus(player_index) == 1 then
				t_name = t.Name;
			end
		end
		if bt~= nil then
			bt_name = bt.Name;
		end
		
		if party:GetMemberIsActive(0) ~= 0 then
			local pet = targets.get_pet();
			local pet_name;
			if pet ~= nil then
				pet_name = pet.Name;
				if string.find(msg, pet_name) then
					isParty = true;
					isYourPet = true;
				end
			end
			if  string.find(msg, party:GetMemberName(0)) ~= nil then
				isParty = true;
				isYou = true;
			end
		end
		if (t_name ~= nil and string.find(msg, t_name)) then
				isParty = true;
			if par_MessageMode ~= 40 then 
				isYou = true;
			end
		else
			if (bt_name ~= nil and string.find(msg, bt_name)) then
				isParty = true;
				if par_MessageMode ~= 40 then 
					isYou = true;
				end
			end
		end
		--if isParty then isYou = true; end
		if not isParty or allSettings.hideNonYou[1] then
			for P_i = 1, 5 do
				if party:GetMemberIsActive(P_i) ~= 0 then
					if  string.find(msg, party:GetMemberName(P_i)) ~= nil then
						isParty = true;
						isYou = false;	
						
					end;
				end
			end
		end
	end
	]]--
	--Debug(tostring(isParty), 1, false)
	--Debug(tostring(isYou), 2, false)

	--[[
	if ( not isParty or not (isYou or isYourPet)) and (par_LastMode == 'combat' or par_LastMode == 'combatspell') then
		--Debug(tostring('hello'), 2, false)
		par_LastMode = 'filtered'; return;
	end;
	]]--
	
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
	
	--par_promptEnd = {};
	
	local newText = CleanText(msg, par_LastMode);
	
			
	
	if newText:match('^%s*\n?$') then par_LastMode = 'empty' return end
	
	--if #par_promptEnd > 0 then AshitaCore:GetChatManager():AddChatMessage(1, false, '\\'..tostring(par_promptEnd[1])..'\\'..tostring(par_promptEnd[2])); end
	
	
	--e.blocked = false;
	
	--local openedUI = false;
	--local openedMenu = false;
	
	
   -- if ashita.memory.read_uint8(ashita.memory.read_uint32(uiw.UIVisiblePtr + 10)+ 0xB4) == 1 then openedUI = true; end
	
  --  local ptr = ashita.memory.read_uint32(uiw.UIVisiblePtr + 10)
--	openedUI = ashita.memory.read_uint8(ptr + 0xB4) == 1
	
	--local MenuName = '';
	--local MenuPtr = ashita.memory.read_uint32(uiw.MenuPtr)
	--local MenuID = ashita.memory.read_uint32(MenuPtr)
   -- if MenuID ~= 0 then
	--	MenuName = ashita.memory.read_string(ashita.memory.read_uint32(MenuID + 4) + 0x46, 16);
	--	MenuName = string.gsub(MenuName, '\x00', ''):trimex()
	--	if ( )) then openedMenu = true; end
	--end
	
	--local menu_pointer = ashita.memory.read_uint32(pGameMenu)
	--local menu_val = ashita.memory.read_uint32(menu_pointer)
	--if menu_val == 0 then
	 --   return ''
	--end
	--local menu_header = ashita.memory.read_uint32(menu_val + 4)
	--local menu_name = ashita.memory.read_string(menu_header + 0x46, 16)
	--return string.gsub(menu_name, '\x00', ''):trimex()
--end
	
--	Debug(tostring(eventSystem), 1, true);
--	Debug(tostring(string.byte(string.sub(original_msg,#original_msg,#original_msg))), 1, true);
--	Debug(tostring(MenuName), 1, true);
--	Debug(tostring(openedMenu), 1, true);

	
	--Debug(tostring(ashita.memory.read_uint8(ashita.memory.read_uint32(uiw.UIVisiblePtr + 10)+ 0xB4)), 1, true);
	--Debug(tostring(MenuName), 1, true);
	
	--if (not openedUI and not openedDialog and not par_IsInConv and not fcw[1].HideChat and not LegacyChatOpen) then

	
	--newText = ts..newText;
	local urlText = ''
	if not par_LastMode:find('combat') then urlText =  utils.ParseUrlLink(newText); end
	--Debug('>'..tostring(urlText), 1, true);
		
	if (par_MessageMode == 123 and string.find(newText, '{')~= nil) then
		newText = string.sub(newText,1,string.find(newText, '{')-1)..string.sub(newText,string.find(newText, '{')+1,string.len(newText));
	end
	

	
	if par_MessageMode == 129 then
		if utils.FindInStringTable(newText, utils.crafts, 0) then
			par_MessageMode = 121; par_LastMode = 'craft'; col = utils.modesDA[par_MessageMode+1][3];
		end
	end
	
	
	local playerTarget = AshitaCore:GetMemoryManager():GetTarget();
	local party = AshitaCore:GetMemoryManager():GetParty();
	local entity = AshitaCore:GetMemoryManager():GetEntity();
	local bt = targets.get_bt();
	local bt_name = '@';
	if bt~= nil then
		bt_name = bt.Name;
	end
	-- local t = targets.get_t();
	-- local t_name = '@';
	-- local player_index = party:GetMemberTargetIndex(0);
	-- if entity ~= nil and party ~= nil then
		-- if t ~= nil and player_index ~= nil and entity:GetStatus(player_index) == 1 then
			-- t_name = t.Name;
		-- else
			-- local targetIndex;
			-- if (playerTarget ~= nil) then
				-- local targetIndex = playerTarget:GetTargetIndex(0);
				-- local entity = GetEntity(targetIndex);
				-- t_name = entity.Name
			-- end
		-- end
	-- end
	local t_name = '@';
	local targetIndex;
	if (playerTarget ~= nil) then
		local targetIndex = playerTarget:GetTargetIndex(0);
		local targetEntity = GetEntity(targetIndex);
		if targetEntity then
			t_name = targetEntity.Name
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
	
	local isTarget = string.find(newText, t_name) or string.find(newText, bt_name)
	
	local player_name = fcw[1].PlayerName;
	local party_names = T{};
	for P_i = 1, 5 do
		if party:GetMemberIsActive(P_i) ~= 0 then
			table.insert(party_names, party:GetMemberName(P_i))
		end
	end

	
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
	if string.find(par_LastMode, 'combat') then
		if string.find(par_LastMode,'_y',1,true) then isYou = true; col = col_y;
		elseif string.find(par_LastMode,'_p',1,true) then isParty = true; col = col_p;
		elseif string.find(par_LastMode,'_n',1,true) then isOthers = true; col = col_n;
		elseif string.find(par_LastMode,'_t',1,true) then isYou = true;  col = col_t;
		elseif string.find(par_LastMode,'_e',1,true) then isYou = true; col = col_e;
		elseif string.find(par_LastMode,'_a',1,true) then isAlliance = true;  col = col_a;
		elseif string.find(par_LastMode,'_x',1,true) then --isParty = true;  col = col_p;
			--Debug(tostring(string.find(newText, pet_name))..'-'..tostring(par_MessageMode),1,true)
			if string.find(newText, pet_name) and isTarget then isYou = true; col = col_t;
			--Debug('pet',1,true)
			elseif string.find(newText, player_name) or utils.StringFindTable(newText, utils.disambYou) then isYou = true; col = col_y; 
			elseif utils.StringFindTable(newText, party_names) then isParty = true; col = col_p;
			elseif (isTarget and not utils.StringFindTable(newText, utils.disambEnemy)) then isYou = true;  col = col_e;
			else isOthers = true; col = col_n;
				--Debug(e.message..' - '..tostring(isTarget), 1, true)
			end
		else
			if (isTarget and not utils.StringFindTable(newText, utils.disambEnemy)) then
				isOthers = true; col = col_n
			elseif (isTarget and utils.StringFindTable(newText, utils.disambEnemy)) then
				isYou = true; col = col_e
			end
		end
	end
	
	if 	(allSettings.hideAlliance[1] and isAlliance) or
		(allSettings.hideNonParty[1] and isOthers) or
		(allSettings.hideNonYou[1] and not isYou)
	then
		par_LastMode = 'filtered'; return;
	end
	local scope = '_z'
	if isYou then scope = '_y' elseif isYou or isParty then scope = '_p' end
	
	if par_LastMode:find('combat',1,true) and utils.FindInStringTableFilters(newText, par_customFilters, scope) then par_LastMode = 'filtered' return end
	
	--if (par_LastMode == 'combat') then Debug(tostring(isParty), 2, false); end
--	Debug(tostring(par_LastMode), 2, true);
	
	local iscombatspell = string.find(par_LastMode,'combat_') and string.find(newText,' cast')
	iscombatspell = iscombatspell or string.find(par_LastMode, 'combatspell_'); 
	if allSettings.CompactCombat[1] then
		
		if (iscombatspell) then
			newText = CombatSpellText(newText, par_MessageMode); col = bit.tobit(utils.RGBAToHex(allSettings.combatspellColor));
			par_LastMode:gsub('combat_', 'combatspell_');
		end
		
		if string.find(par_LastMode, 'combat_') then
			newText = CombatText(newText, par_MessageMode);
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
	or par_MessageMode == 121;
		
	--local dupedCS = not string.find(par_LastMode,'combat_') and string.find( par_LastMessage,  string.sub(newText,1+offset+(string.len(newText)-offset/5),string.len(newText)-offset-(string.len(newText)/5))) ~= nil;
	
	--if dupedCS then dw_TestMessage = 'Duplicate CS message removed >'..tostring(dupedCS); end
	
	if ( checkMsgOrDate and not dupedCS) then
	
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
			-- if (string.find(par_LastMode, 'NPC')) then return 8; end
			-- return -1;
		-- end)();
		
			--if (string.find(par_LastMode, 'combat') == nil) then return 2; end
		local tabmode;
		if (string.find(par_LastMode, 'combat')) then tabmode = 3; 
		elseif (string.find(par_LastMode, 'linkshell')) then tabmode = 4;
		elseif (string.find(par_LastMode, 'party')) then tabmode = 5; 
		elseif (string.find(par_LastMode, 'tell')) then tabmode = 6; 
		elseif (string.find(par_LastMode, 'shout')) then tabmode = 7; 
		elseif (string.find(par_LastMode, 'NPC')) then tabmode = 8; 
		else tabmode = -1;
		end
		
		local n_lines = math.floor((string.len(newText))/allSettings.chatLineMaxL);
		if math.fmod(string.len(newText), allSettings.chatLineMaxL) ~= 0 then  n_lines = n_lines+1; end
		local check_again = false;
		local check_again_text = ''
		local carry_over_color = nil;
		
		local textLeft = string.len(newText);
		local L_i = 1;
		--for L_i = 1, n_lines do
		local auxURL_text = '';
		local skipped = 0;
		while L_i <= n_lines do
			--if L_i > 1 then newText = newText:trimex(); end
			newText = newText:trimex()
			if (newText:match("^%s$") or newText == '') then  n_lines = L_i-1; break; end;
			if carry_over_color ~= nil then col = carry_over_color; end
			local special_idx = nil;
			local special_text = '';
			local special_color = 0xFFFFFFFF;
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
			local cutIdx =  math.min(allSettings.chatLineMaxL+bytesLine[math.min(allSettings.chatLineMaxL,#bytesLine)],textLeft);
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
					if urlText == '' and newText[cutIdx] ~= ' ' and cutIdx < #newText and newText[cutIdx+1] ~= ' ' then lineBreak = '-';else cutIdx = cutIdx +1 end
					--Debug(tostring(cutIdx)..'-'..tostring(newText[cutIdx])..'-'..tostring(urlText)..'LB:'..lineBreak..'<',1,true)
					if (textLeft > cutIdx and newText[cutIdx] ~= ' ' and newText[cutIdx+1] ~= ' ') then
						local last_space = utils.FindLastOf(string.sub(newText,1,cutIdx),' ');
						if (last_space ~= nil) then
							if (cutIdx-last_space)<12 then cutIdx = last_space-1; lineBreak = '' end
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
					if urlText == '' and newText[cutIdx] ~= ' ' and cutIdx < #newText and newText[cutIdx+1] ~= ' ' then lineBreak = '-';else cutIdx = cutIdx +1 end
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
			
			
			-- if #newLinesIdx > 0 then
			-- Debug(tostring(newLinesIdx[1]-(newLinesIdx[1]-textLeft) ), 1, true)
				-- --for NLI_i = 1, #newLinesIdx do
					-- if newLinesIdx[1]-(newLinesIdx[1]-textLeft) <= cutIdx then
						
						-- cutIdx = newLinesIdx[1];
						-- lineBreak = '';
						-- table.remove(newLinesIdx, 1);
						-- --break;
					-- end
					
			-- --	end
			-- end
			
			--------------------------------------------------------------------------
			if
				par_MessageMode == 9 or
				par_MessageMode == 142 or
				par_MessageMode == 151 or
				par_MessageMode == 121 or
				par_MessageMode == 131 or
				par_MessageMode == 127
			then
				special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color = CheckSpecial(special_idx, special_offset, special_type, special_color, tabmode, L_i, check_again, check_again_text, n_lines, carry_over_color, cutIdx, newText)
			end
			--Debug(tostring(tabmode),1,false);
			if ( special_idx ~= nil) then
				if special_color == 0xFFFFFFFF then special_color = 0xFFA1FF3D; end
				col = 0xFFFFFFFF;
				if special_type == 'prevspecial' then
					table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,special_idx+special_offset));
					special_text = string.sub(newText,special_idx+special_offset+1,cutIdx);
				else
				--CE exclusive!--
					if special_type == 'SOTS' then
						table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,special_idx+special_offset));
						special_text = string.sub(newText,special_idx+special_offset+1,cutIdx)..lineBreak;
					else
						if special_type == 'obtain' then 
							table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,special_idx+special_offset));
							special_text = string.sub(newText,special_idx+special_offset+1,cutIdx)..lineBreak;
						else
							if special_type == 'synth' then
								table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,special_idx+special_offset));
								special_text = string.sub(newText,special_idx+special_offset+1,cutIdx)..lineBreak;
							else
								if special_type == 'lot' then
									table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,special_idx+special_offset));
									special_text = string.sub(newText,special_idx+special_offset+1,cutIdx)..lineBreak;
								else
									if special_type == 'find' then
										local F_start = special_idx+9;
										
										special_idx = string.find(newText, ' on ');
										if special_idx == nil then special_idx = string.find(newText, ' in '); end
										
										local findText = ''
										--print(newText)
										if special_idx then
											local F_end = special_idx-1;
											local F = string.sub(string.sub(newText,1,#newText),F_start,F_end);
											local B_start = special_idx+4;
											local B_end = #string.sub(newText,1,#newText)-1;
											local B = string.sub(string.sub(newText,1,#newText),B_start,B_end);
											--local findText = ts..'Found on '..B;
											findText = ts..'Found on '..B..':';
											--special_text = '> '..F..'.';
											special_text = F..'.';
											newText = findText..special_text;
											textLeft = string.len(newText);
											if n_lines > 1 then --carry_over_color = 0xFFA1FF3D;
												-- there are more lines allocated for this messages --
												if (string.len(findText..special_text)+1 < allSettings.chatLineMaxL) then
													-- modified line fits in 1 line --
													table.insert(b_ChatBuffer[1][2].text, findText);
													n_lines = 1;
												else
													-- modified line doesn't fit in 1 line --
													if string.len(findText) < allSettings.chatLineMaxL then
														-- the findText fits
														carry_over_color = 0xFFA1FF3D;
														table.insert(b_ChatBuffer[1][2].text, findText);
														cutIdx = string.len(newText)-(string.len(newText)-allSettings.chatLineMaxL);
														local ls = utils.FindLastOf(string.sub(newText,1,cutIdx),' ');
														if (ls ~= nil) then if (cutIdx-ls)<4 then cutIdx = ls; end end
														special_text = string.sub(special_text,1, string.len(special_text)-(string.len(newText)-cutIdx));
														--dw_TestMessage = findText..'\n-'..special_text;
														--special_text = string.sub(special_text,1, string.len(findText..special_text) - allSettings.chatLineMaxL);
														--cutIdx = string.len('5'..findText..special_text);
													else
														-- the findText doesn't fit
														cutIdx = #findText-(#findText-allSettings.chatLineMaxL)
														table.insert(b_ChatBuffer[1][2].text, findText:sub(1,cutIdx));
														special_text = ''
														check_again_text = findText:sub(cutIdx+1,#findText)
														check_again = true
														--cutIdx = 
													end
												end
											else
												-- there is 1 line allocated for this message --
												if (string.len(findText..special_text)+1 < allSettings.chatLineMaxL) then
													-- modified line fits in 1 line --
													table.insert(b_ChatBuffer[1][2].text, findText);
												else
													-- modified line doesn't fits in 1 line anymore --
													if string.len(findText) < allSettings.chatLineMaxL then
														-- the findText fits math.min(allSettings.chatLineMaxL,textLeft);
														carry_over_color = 0xFFA1FF3D;
														table.insert(b_ChatBuffer[1][2].text, findText);
														cutIdx = string.len(newText)-(string.len(newText)-allSettings.chatLineMaxL);
														local ls = utils.FindLastOf(string.sub(newText,1,cutIdx),' ');
														if (ls ~= nil) then if (cutIdx-ls)<4 then cutIdx = ls; end end
														special_text = string.sub(special_text,1, string.len(special_text)-(string.len(newText)-cutIdx));
														n_lines = n_lines+1;
													else
														-- the findText doesn't fit
														table.insert(b_ChatBuffer[1][2].text, '[Error] Unexpected long string');
													end
												end
											end
										else
											table.insert(b_ChatBuffer[1][2].text, newText);
										end
										--table.insert(b_ChatBuffer[1][2].text, ts..'You found on '..B);
									else
										table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,cutIdx)..lineBreak);
										special_text = '';
									end
								
								end
							end
						end
					end
				end
			else
				if (par_CombatCutIdx ~= 0) then
					if (par_CombatCutIdx <= cutIdx) then
						if (par_CombatCutIdx > 0) then
							table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,par_CombatCutIdx));
							special_text = string.sub(newText,par_CombatCutIdx+1,cutIdx)..lineBreak;
							if string.find(par_LastMode, 'combat_') then
								special_color = bit.tobit(utils.RGBAToHex(allSettings.dmgColor));
								if par_DamageDone then
									special_color = bit.tobit(utils.RGBAToHex(allSettings.dmgDoneColor));
								end
								if par_DamageGot then
									special_color = bit.tobit(utils.RGBAToHex(allSettings.dmgGotColor));
								end
							else
								if string.find(par_LastMode,'combatspell_') then
									special_color = bit.tobit(utils.RGBAToHex(allSettings.spelldmgColor));
									if par_DamageDone then
										special_color = bit.tobit(utils.RGBAToHex(allSettings.spelldmgDoneColor));
									end
									if par_DamageGot then
									special_color = bit.tobit(utils.RGBAToHex(allSettings.spelldmgGotColor));
									end
								end
							end
							
							par_CombatCutIdx = par_CombatCutIdx - cutIdx;
							if par_CombatCutIdx == 0 then par_CombatCutIdx = -1; end
						else
							table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,cutIdx)..lineBreak);
							if string.find(par_LastMode, 'combat_') then
								col = bit.tobit(utils.RGBAToHex(allSettings.dmgColor));
								if par_DamageDone then col = bit.tobit(utils.RGBAToHex(allSettings.dmgDoneColor)); end
								if par_DamageGot then col = bit.tobit(utils.RGBAToHex(allSettings.dmgGotColor)); end
							else
								if string.find(par_LastMode, 'combatspell_') then
									col = bit.tobit(utils.RGBAToHex(allSettings.spelldmgColor));
									if par_DamageDone then special_color = bit.tobit(utils.RGBAToHex(allSettings.spelldmgDoneColor)); end
									if par_DamageGot then special_color = bit.tobit(utils.RGBAToHex(allSettings.spelldmgGotColor)); end
								end
							end
							special_text = '';	
						end
					else
						table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,cutIdx)..lineBreak);
						par_CombatCutIdx = par_CombatCutIdx - cutIdx;
						special_text = '';
					end
				else
					
					table.insert(b_ChatBuffer[1][2].text, string.sub(newText,1,cutIdx)..lineBreak);
					special_text = '';
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
				table.insert(b_ChatBuffer[1][2].mode, tostring(par_MessageMode)..'|'..par_LastMode);
				table.insert(b_ChatBuffer[1][2].color, col);
				if (special_idx ~= nil or par_CombatCutIdx < 0)	then
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
						table.insert(b_ChatBuffer[1][2].url, urlText);
					end
					table.insert(b_ChatBuffer[1][2].auxColor, 0xFF44CCFF);
				end
				
				if tabmode and tabmode ~= 3 then
					--Debug(tostring(tabmode), 1, true);
					table.insert(b_ChatBuffer[2][2].text,b_ChatBuffer[1][2].text[#b_ChatBuffer[1][2].text]);
					table.insert(b_ChatBuffer[2][2].mode,b_ChatBuffer[1][2].mode[#b_ChatBuffer[1][2].mode]);
					table.insert(b_ChatBuffer[2][2].color,b_ChatBuffer[1][2].color[#b_ChatBuffer[1][2].color]);
					table.insert(b_ChatBuffer[2][2].auxText,b_ChatBuffer[1][2].auxText[#b_ChatBuffer[1][2].auxText]);
					table.insert(b_ChatBuffer[2][2].auxColor,b_ChatBuffer[1][2].auxColor[#b_ChatBuffer[1][2].auxColor]);
					table.insert(b_ChatBuffer[2][2].url,b_ChatBuffer[1][2].url[#b_ChatBuffer[1][2].url]);
				end
				if (utils.GetTableLen(b_ChatBuffer[1][2].text) > b_ChatBufferMaxSize) then
					-- local removeCount = math.min(b_CleanupThresh, #b_ChatBuffer[1][2].text)
					-- local tabremove = ''
					-- local mode1 = b_ChatBuffer[1][2].mode[1]
					-- if string.find(mode1, 'combat') then
						-- tabremove = 3
					-- elseif string.find(mode1, 'linkshell') then
						-- tabremove = 4
					-- elseif string.find(mode1, 'party') then
						-- tabremove = 5
					-- elseif string.find(mode1, 'tell') then
						-- tabremove = 6
					-- elseif string.find(mode1, 'shout') then
						-- tabremove = 7
					-- elseif string.find(mode1, 'NPC') then
						-- tabremove = 8
					-- end

					-- if tabremove ~= '' then
						-- BulkRemove(b_ChatBuffer[tabremove][2], removeCount)
					-- end
					-- BulkRemove(b_ChatBuffer[1][2], removeCount)
					-- if tabremove ~= 3 then
						-- BulkRemove(b_ChatBuffer[2][2], removeCount)
					-- end
					local cleanupRanges = {b_CleanupThresh, 0, 0, 0, 0, 0, 0, 0}
					for tr = 1, b_CleanupThresh do
						local tabremove = 0;
						if (string.find(b_ChatBuffer[1][2].mode[tr], 'combat') ~= nil) then tabremove = 3; 
						elseif (string.find(b_ChatBuffer[1][2].mode[tr], 'linkshell') ~= nil) then tabremove = 4; 
						elseif (string.find(b_ChatBuffer[1][2].mode[tr], 'party') ~= nil) then tabremove = 5; 
						elseif (string.find(b_ChatBuffer[1][2].mode[tr], 'tell') ~= nil) then tabremove = 6; 
						elseif (string.find(b_ChatBuffer[1][2].mode[tr], 'shout') ~= nil) then tabremove = 7; 
						elseif (string.find(b_ChatBuffer[1][2].mode[tr], 'NPC') ~= nil) then tabremove = 8; 
						else tabremove = 0;
						end
						if tabremove > 0 then
							cleanupRanges[tabremove] = cleanupRanges[tabremove] + 1
						end
						if (tabremove ~= 3) then
							cleanupRanges[2] = cleanupRanges[2] + 1
						end
					end
					--Debug(tostring(table.concat(cleanupRanges,',')),1,true)
					for ci = 1, #cleanupRanges do
						BulkRemove(b_ChatBuffer[ci][2], cleanupRanges[ci])
					end
						-- if (tabremove ~= '') then
							-- table.remove(b_ChatBuffer[tabremove][2].text, 1);
							-- table.remove(b_ChatBuffer[tabremove][2].mode, 1);
							-- table.remove(b_ChatBuffer[tabremove][2].color, 1);
							-- table.remove(b_ChatBuffer[tabremove][2].auxText, 1);
							-- table.remove(b_ChatBuffer[tabremove][2].auxColor, 1);
							-- table.remove(b_ChatBuffer[tabremove][2].url, 1);
						-- end
						-- table.remove(b_ChatBuffer[1][2].text, 1);
						-- table.remove(b_ChatBuffer[1][2].mode, 1);
						-- table.remove(b_ChatBuffer[1][2].color, 1);
						-- table.remove(b_ChatBuffer[1][2].auxText, 1);
						-- table.remove(b_ChatBuffer[1][2].auxColor, 1);
						-- table.remove(b_ChatBuffer[1][2].url, 1);
						-- if (tabremove ~= 3) then
							-- table.remove(b_ChatBuffer[2][2].text, 1);
							-- table.remove(b_ChatBuffer[2][2].mode, 1);
							-- table.remove(b_ChatBuffer[2][2].color, 1);
							-- table.remove(b_ChatBuffer[2][2].auxText, 1);
							-- table.remove(b_ChatBuffer[2][2].auxColor, 1);
							-- table.remove(b_ChatBuffer[2][2].url, 1);
						-- end
					
				end
				---
				
				if (tabmode and tabmode > 2) then	
					
					table.insert(b_ChatBuffer[tabmode][2].text,b_ChatBuffer[1][2].text[#b_ChatBuffer[1][2].text]);
					table.insert(b_ChatBuffer[tabmode][2].mode,b_ChatBuffer[1][2].mode[#b_ChatBuffer[1][2].mode]);
					table.insert(b_ChatBuffer[tabmode][2].color,b_ChatBuffer[1][2].color[#b_ChatBuffer[1][2].color]);
					table.insert(b_ChatBuffer[tabmode][2].auxText,b_ChatBuffer[1][2].auxText[#b_ChatBuffer[1][2].auxText]);
					table.insert(b_ChatBuffer[tabmode][2].auxColor,b_ChatBuffer[1][2].auxColor[#b_ChatBuffer[1][2].auxColor]);
					table.insert(b_ChatBuffer[tabmode][2].url,b_ChatBuffer[1][2].url[#b_ChatBuffer[1][2].url]);
				end
				---
			end	
			L_i = L_i +1;
		end
		n_lines = n_lines-skipped;
		b_ChatBufferN_All  = b_ChatBufferN_All+n_lines;
		if (tabmode ~= 3) then b_ChatBufferN_AllAlt = b_ChatBufferN_AllAlt + n_lines; end
		if (string.find(par_LastMode, 'combat')) then b_ChatBufferN_Combat = b_ChatBufferN_Combat + n_lines; end
		if (string.find(par_LastMode, 'linkshell')) then b_ChatBufferN_Linkshell = b_ChatBufferN_Linkshell + n_lines;  end
		if (string.find(par_LastMode, 'party')) then b_ChatBufferN_Party = b_ChatBufferN_Party + n_lines; end
		if (string.find(par_LastMode, 'tell')) then b_ChatBufferN_Tell = b_ChatBufferN_Tell + n_lines; end
		if (string.find(par_LastMode, 'shout')) then b_ChatBufferN_Shout = b_ChatBufferN_Shout + n_lines; end
		if (string.find(par_LastMode, 'NPC')) then b_ChatBufferN_NPC = b_ChatBufferN_NPC + n_lines; end

	end
	par_LastMessageMode = par_MessageMode;
end
	
function CheckSpecial (special_idx, special_offset, special_type, special_color, tabmode, L_i, check_again, check_again_text, n_lines, carry_over_color, cutIdx, newText)
	if (L_i == 1 or check_again) then
		check_again = false;
		
		--CE exclusive!--
		check_mode = par_MessageMode == 9;
		if check_mode then
		
		special_idx, idx_end = string.find(newText, 'Now accumulating linkshell points for ');
		if (special_idx ~= nil) then special_offset = string.find(newText, '%(')-1-special_idx; special_type = 'SOTS';
		special_color = 0xFF00FFB3;
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFF00FFB3; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text,carry_over_color; end
		
		special_idx, idx_end = string.find(newText, 'Activity Points:');
		if (special_idx ~= nil) then special_offset = 15 special_type = 'SOTS';
		special_color = 0xFF00FFB3;
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFF00FFB3; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color; end
		
		special_idx, idx_end = string.find(newText, 'Summit Objective:');
		if (special_idx ~= nil) then special_offset = 16; special_type = 'SOTS';
		special_color = 0xFF00FFB3;
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFF00FFB3; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color; end
		
		special_idx, idx_end = string.find(newText, ' activity points.');
		if (special_idx ~= nil) then special_idx, idx_end = string.find(newText, 'gains'); special_offset = 4; special_type = 'SOTS';
		special_color = 0xFF00FFB3;
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFF00FFB3; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color; end
		
		special_idx, idx_end = string.find(newText, 'Point Accumulation:');
		if (special_idx ~= nil) then special_offset = 19; special_type = 'SOTS';
		special_color = 0xFFFF0055;
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFFFF0055; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color; end
		
		end
		-----------------
		
		check_mode = par_MessageMode == 142 or par_MessageMode == 151;
		if check_mode then
		special_idx = string.find(newText, 'You obtain');
		if (special_idx ~= nil) then special_offset = 9; special_type = 'obtain';
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFFA1FF3D; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color; end
		end
		
		check_mode = par_MessageMode == 142 or par_MessageMode == 151;
		if check_mode then
		special_idx = string.find(newText, 'Obtained:');
		if (special_idx ~= nil) then special_offset = 8; special_type = 'obtain';
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFFA1FF3D; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color; end
		end
		
		check_mode = par_MessageMode == 121 or par_MessageMode == 142 or par_MessageMode == 131 or par_MessageMode == 127;
		if check_mode then
		special_idx = string.find(newText, ' obtains ');
		if (special_idx ~= nil) then	special_offset = 8	;	special_type = 'obtain';
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFFA1FF3D; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color; end
		end
		
		check_mode = par_MessageMode == 142 or par_MessageMode == 151;
		if check_mode then
		special_idx = string.find(newText, 'Obtained key item: ');
		if (special_idx ~= nil) then	special_offset = 18	;	special_type = 'obtain';
		special_color = 0xFFC797FF;
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFFC797FF;  end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color; end
		end
		
		check_mode = par_MessageMode == 121;
		if check_mode then
		special_idx = string.find(newText, ' synthesized ');
		if (special_idx ~= nil and string.find(newText, 'You ')) then	special_offset = 12; special_type = 'synth';
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFFA1FF3D; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color; end
		end
		
		check_mode = par_MessageMode == 121;
		if check_mode then
		special_idx = string.find(newText, ' caught ');
		if (special_idx ~= nil and string.find(newText, fcw[1].PlayerName)) then	special_offset = 7; special_type = 'synth';
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFFA1FF3D; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color; end
		end
		
		check_mode =  par_MessageMode == 131 or par_MessageMode == 121;
		if check_mode then
		special_idx = string.find(newText, ' gains ');
		if (special_idx ~= nil and (string.find(newText, 'experience') or string.find(newText, 'limit')))  then special_offset = 6; special_type = 'obtain'; tabmode = 3; par_LastMode = 'combat';
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFFA1FF3D; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color; end
		end
		
		check_mode = par_MessageMode == 121;
		if check_mode then
		special_idx = string.find(newText, 'You find ');
		if (special_idx ~= nil) then	special_offset = 8;	special_type = 'find';
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFFA1FF3D; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color;
		elseif check_again_text ~= '' then
		special_idx = string.find(newText, check_again_text);
		if special_idx then special_offset = check_again_text:find(':')-special_idx;	special_type = 'prevspecial'; end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color;	
		end
		end
		
		check_mode = par_MessageMode == 121;
		if check_mode then
		special_idx = string.find(newText, ' lot for ');
		if (special_idx ~= nil) then	special_offset = 8;	special_type = 'lot';  tabmode = -1; par_LastMode = 'lot';
		if special_idx+special_offset > cutIdx then check_again = true; else if #newText > cutIdx then carry_over_color = 0xFFA1FF3D; end end
		return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color; end
		end
		
	end
	return special_idx, special_offset, special_type, special_color, tabmode, check_again, check_again_text, carry_over_color;
end

SetBufferN = function(tab)
	if (tab == 'All' and not allSettings.HideCombatFromAll[1]) 
							then return b_ChatBufferN_All; 			end
	if (tab == 'All' and allSettings.HideCombatFromAll[1]) 
							then return b_ChatBufferN_AllAlt; 		end
	if (tab == 'Combat') 	then return b_ChatBufferN_Combat; 		end
	if (tab == 'Linkshell') then return b_ChatBufferN_Linkshell; 	end
	if (tab == 'Party') 	then return b_ChatBufferN_Party; 		end
	if (tab == 'Tell') 		then return b_ChatBufferN_Tell; 		end
	if (tab == 'Shout') 	then return b_ChatBufferN_Shout; 		end
	if (tab == 'NPC') 		then return b_ChatBufferN_NPC; 			end
	return chatBufferN_All;
end

SetTargetPosX = function(x,y)
	if mvc_Menu1 or uiw.DialogShown then mvc_targetposY = (y/uiw.UISizeY*uiw.UISizeY) -((y*128)/uiw.UISizeY);	return fcw[1].MoveChatPos1; end
	if mvc_Menu2 then mvc_targetposY = (y/uiw.UISizeY*uiw.UISizeY)-((y*250)/uiw.UISizeY); return fcw[1].MoveChatPos2; end
	if mvc_Menu3 then mvc_targetposY = (y/uiw.UISizeY*uiw.UISizeY)-(y*250)/uiw.UISizeY; return fcw[1].MoveChatPos3; end
	if mvc_Menu4 then mvc_targetposY = (y/uiw.UISizeY*uiw.UISizeY)-(y*250)/uiw.UISizeY; return fcw[1].MoveChatPos4; end
	if mvc_Menu5 then mvc_targetposY = (y/uiw.UISizeY*uiw.UISizeY)-(y*160)/uiw.UISizeY; return fcw[1].MoveChatPos1; end
	return 0;
end

-- SetLinesVisible = function(fo_id, v)
	-- for i=1, allSettings.ChatLines do
		-- fo_Chat[fo_id][i]:set_visible(v);
		-- fo_Aux[fo_id][i]:set_visible(v);
	-- end
	-- --gdi:render()
-- end

function DumpChat(mode)
	par_dumping = true
	if mode == 2 then
		local i = 1
		while i <= #b_ChatBuffer[1][2].text do
			local j = 1
			local nextLine = b_ChatBuffer[1][2].text[i]..' '..b_ChatBuffer[1][2].auxText[i]
			local ID =  b_ChatBuffer[1][2].url[i]
			while b_ChatBuffer[1][2].url[i+j] == ID and j < 1000 do
				nextLine = nextLine..' '..b_ChatBuffer[1][2].text[i+j]..' '..b_ChatBuffer[1][2].auxText[i+j]
				j = j + 1
			end
			for i = 1, #utils.ShiftJITback do
				local char = utf8.char(utils.ShiftJITback[i][1])
				local bytes = {char:byte(1, #char)}
				local chars = ''
				for b = 1, #bytes do
					chars = chars..string.char(bytes[b])
				end
				--Debug(tostring(string.find(nextLine, chars)),1,true)
				
				nextLine = nextLine:gsub(chars,utils.ShiftJITback[i][2])
			end
			AshitaCore:GetChatManager():AddChatMessage(tonumber(b_ChatBuffer[1][2].mode[i]:sub(1,b_ChatBuffer[1][2].mode[i]:find('|')-1)), false, nextLine)
			coroutine.sleep(1/#b_ChatBuffer[1][2].text)
			i = i + j
		end
	elseif mode == 1 then
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
		print('-------------- Chat restored --------------')
	end
	par_dumping = false
end

function BulkRemove(buffer, count)
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
			newMode[#newMode + 1] = buffer.mode[i]
			newColor[#newColor + 1] = buffer.color[i]
			newAuxText[#newAuxText + 1] = buffer.auxText[i]
			newAuxColor[#newAuxColor + 1] = buffer.auxColor[i]
			newUrl[#newUrl + 1] = buffer.url[i]
		end
		buffer.text = newText
		buffer.mode = newMode
		buffer.color = newColor
		buffer.auxText = newAuxText
		buffer.auxColor = newAuxColor
		buffer.url = newUrl
	end
end