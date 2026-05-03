--[[
	lib/render.lua

	The two D3D event callbacks that drive the entire on-screen
	chat: `d3d_present` (per-frame logic + ImGui windows) and
	`d3d_endscene` (GDI font flush after ImGui finishes).

	This is the largest single piece of code in the addon — it
	orchestrates every other module's output: window placement,
	chat-line scrolling, hover/click handling, tab buttons, the
	BigMode overlay, item/spell preview popups, GuideMe / Notepad
	/ Settings panels, and the auto-hide fade.  None of the
	business logic lives here; it's pure UI plumbing that reads
	the shared state tables and calls into the helper modules
	(buffer, ui_helpers, ui_panels, ui_settings, parser, bigmode)
	via the `_G.*` globals each of those modules registers.

	Two exported things:

	  M.register()
	    Installs the d3d_present + d3d_endscene callbacks with
	    Ashita.  Called once from fancychat.lua at addon load.

	  ResetAutoHideTimer()  (also _G.ResetAutoHideTimer)
	    Trivial one-liner that pokes fcw[1].autoHideTime so the
	    chat window stays visible.  Lives here because render is
	    its primary consumer, but every module that registers
	    user activity (input, parser, ui_panels, ui_settings,
	    lifecycle, bigmode) calls it via the global alias.

	The module body is structured so that:
	  - All imports are local upvalues (no dynamic requires).
	  - Every state table read/written goes through `state.*`
	    aliases, which are shared with every other module.
	  - Cross-module calls go through `_G.<Name>` globals
	    (DrawInfo, ResetLines, PositionLines, ChangeTab, etc.).
	    These are wired up by each helper module's own load.
]]

require('common')
local imgui       = require('imgui')
local imguiWrap   = require('imguiWrap')
local gdi         = require('gdifonts.include')
local utils       = require('utils')
local settings    = require('settings')
local help        = require('help')
local state       = require('lib.state')
local ui_panels   = require('lib.ui_panels')
local ui_settings = require('lib.ui_settings')

local uiw            = state.uiw
local mvc            = state.mvc
local fcw            = state.fcw
local tab            = state.tab
local set            = state.set
local dw             = state.dw
local par            = state.par
local b              = state.b
local fo             = state.fo
local ro             = state.ro
local allSettings    = state.allSettings
local gamepadButtons = state.gamepadButtons

-- ----------------------------------------------------------------
-- Localised hot stdlib + ImGui hooks for the per-frame loop.
-- These are upvalues, so each call skips a global-table lookup
-- and is more JIT-friendly than `imgui.X` / `string.X`.
-- ----------------------------------------------------------------
local math_floor   = math.floor
local math_min     = math.min
local math_max     = math.max
local math_abs     = math.abs
local bit_bor      = bit.bor
local bit_band     = bit.band
local table_insert = table.insert
local table_remove = table.remove
local string_find  = string.find

local imGetColorU32     = imgui.GetColorU32
local imIsMouseClicked  = imgui.IsMouseClicked
local imIsMouseReleased = imgui.IsMouseReleased
local imIsMouseDown     = imgui.IsMouseDown
local imIsMouseDragging = imgui.IsMouseDragging
local imGetMousePos     = imgui.GetMousePos
local imGetIO           = imgui.GetIO
local iwIsWindowHovered = imguiWrap.IsWindowHovered

-- ImGui flag constants used per-frame in this file.  Captured once
-- so render doesn't re-resolve them from _G on every Begin / hover
-- check / style push.
local FLAG_HoveredRectOnly       = ImGuiHoveredFlags_RectOnly
local FLAG_MouseLeft             = ImGuiMouseButton_Left
local FLAG_WinNoMove             = ImGuiWindowFlags_NoMove
local FLAG_WinNoDecoration       = ImGuiWindowFlags_NoDecoration
local FLAG_WinNoBackground       = ImGuiWindowFlags_NoBackground
local FLAG_StyleVarFrameBorder   = ImGuiStyleVar_FrameBorderSize

-- Precomputed highlight colours.  Both alpha values are constants
-- (0.0 and 0.3) so the U32 result never changes; the previous code
-- recomputed and reallocated the {r,g,b,a} table per highlighted
-- line per frame.
local COLOR_HIGHLIGHT_FILL  = imGetColorU32({ 1.0, 1.0, 1.0, 0.3 })
local COLOR_HIGHLIGHT_CLEAR = imGetColorU32({ 1.0, 1.0, 1.0, 0.0 })
local COLOR_BORDER_OVERLAY  = imGetColorU32({ 1.0, 1.0, 1.0, 0.75 })

local M = {}

-- One-liner used by every module that wants to keep the chat
-- visible on user activity.  Defined here because render owns the
-- auto-hide fade timeline; exposed as a global so input.lua,
-- parser.lua, ui_panels.lua, etc. can call it without depending on
-- this module.
function M.ResetAutoHideTimer()
	fcw[1].autoHideTime = os.time()
end
_G.ResetAutoHideTimer = M.ResetAutoHideTimer

function M.register()
	ashita.events.register('d3d_present', 'present_cb', function ()
		-- Per-frame caches: avoid hundreds of repeated lookups for
		-- references that don't change inside a single frame.
		--   fcw1/2/3 — never reassigned; just mutated in place.
		--   _fh — font height; only changes between frames via the settings UI.
		--   _now — single "now" timestamp; the frame logic treats every
		--   call to os.clock() within it as the same instant anyway.
		local fcw1, fcw2, fcw3 = fcw[1], fcw[2], fcw[3]
		local _fh  = allSettings.fontSettings.font_height
		local _now = os.clock()

		fcw1.LoginStatus = AshitaCore:GetMemoryManager():GetPlayer():GetLoginStatus();
	
		if not fcw1.InitDone then
			Init();
		end
		if fcw1.LoginStatus == 2 then
			fcw1.LoggedIn = true
			local player = GetPlayerEntity();
			if fcw1.PlayerName ~= '---' then
				fcw1.PlayerName = settings.name
				allSettings.PlayerName = settings.name
			end
		elseif fcw1.LoginStatus == 0 then
			fcw1.LoggedIn = false
			fcw1.LoggedLobby = 1
		end
			-- --if settings.name ~= fcw1.PlayerName then  fcw1.LoggedLobby = 0 end
		
		if fcw1.LoggedIn and not fcw1.Closing and not fcw1.Zoning then
			if (fcw1.LoggedLobby == 1 or (fcw1.PlayerName == '---')) then
				if fcw1.ReLogStart == 0 then
					fcw1.ReLogStart = _now
				else
					if (_now - fcw1.ReLogStart > fcw1.ReLogCD) then	
						allSettings.PlayerName = settings.name;
						SaveSettings();
						fcw1.Closing = true;
						AshitaCore:GetChatManager():QueueCommand(-1, "/addon reload fancychat")
					end
				end
				return
			end;
		
			if AshitaCore:GetChatManager():IsInputOpen() ~= 0x11 then
				fcw1.LastCommands[2] = 0
				fcw1.LastCommands[4] = 0
			end
			local imIO = imGetIO()
			local dsize = imIO.DisplaySize;
		
			if allSettings.timeStampLine[1] then
				local secondsTime = os.time() % allSettings.timeStampLineFreq[2]
				if secondsTime == 0 then
					if par.timePrinted == false then
							-- stringWrap = stringWrap..'\x81\xAC'
						-- AshitaCore:GetChatManager():QueueCommand(1, '/echo '..stringWrap..os.date(par.FormatTS[2], os.time())..stringWrap);
						local tsline = string.rep('\x81\xAC',math_floor((allSettings.chatLineMaxL)/2) - 5)
						print(tsline..os.date(par.FormatTS[2], os.time())..tsline);
						par.timePrinted = true;
					end
				else
					par.timePrinted = false
				end;
			else
				par.timePrinted = true
			end
		
			if allSettings.R0warning[1] and uiw.NetStatObj[1] > 0 and ashita.memory.read_uint32(uiw.NetStatObj[1]) == 0 and uiw.NetStatObj[2] > 0 then	
				AshitaCore:GetChatManager():AddChatMessage(123, false, '[Warning] R0 detected.')
				AshitaCore:GetChatManager():AddChatMessage(123, false, 'Use /fchat savelogs to save chat logs.')
				--CEXI extra message
				AshitaCore:GetChatManager():AddChatMessage(123, false, 'If this is a server crash and you used a pop item, take a FULL screenshot as proof.')
			end
		
			uiw.NetStatObj[2] = ashita.memory.read_uint32(uiw.NetStatObj[1])
	
			fcw1.PlayerName = settings.name;
		
			par.InEvent = ashita.memory.read_uint8(ashita.memory.read_uint32(uiw.EventPtr + 1)) == 1
			if par.InEvent then ResetAutoHideTimer() end

			uiw.MemValue = bit_band(ashita.memory.read_uint32(ashita.memory.read_uint32(uiw.WinPtr1)+0x42),0x0000FFFF);
			if (uiw.MemValue ~= 0) then
				local margin = 15;
				if (uiw.LastMemValue ~= -1 and uiw.LastMemValue >= uiw.MemValue and uiw.MemValue < uiw.UISizeY-19-margin) then
					if not uiw.LegacyChatOpen then
						if allSettings.autoDumpChat[1] then
							DumpChat()
						end
						b.OriginalBuffer = T{}
					end
					uiw.LegacyChatOpen = true;
				else
					if (uiw.LastMemValue ~= -1 and uiw.LastMemValue < uiw.MemValue) then
						uiw.LegacyChatOpen = false;
					end
				end
			end
			uiw.LastMemValue = uiw.MemValue;
		
		
			if (not fcw1.HideChat) then
			
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
				MenuName = ashita.memory.read_string(ashita.memory.read_uint32(MenuID + 4) + 0x46, 16);
				MenuName = string.gsub(MenuName, '\x00', ''):trimex()
			
				--uiw.MenuExt = ashita.memory.read_uint32(uiw.MenuPtr-0x40)
				if allSettings.EnabledChatMove[1] and allSettings.MoveChatATMenu[1] and (MenuName:match('menu[%s]+fep')) then mvc.Menu6 = true; else mvc.Menu6 = false; end
				if not MenuName:match('menu[%s]+inline') and not mvc.Menu6 then
					mvc.Menu1 = false;  mvc.Menu2 = false;  mvc.Menu3 = false;  mvc.Menu4 = false; mvc.Menu5 = false; mvc.Menu6 = false;
					if (MenuName:match('menu[%s]+inventor')) or (MenuName:match('menu[%s]+loot')) or (MenuName:match('menu[%s]+comyn')) or (MenuName:match('menu[%s]+comment')) then mvc.Menu1 = true; 
					elseif (MenuName:match('menu[%s]+magic')) or (MenuName:match('menu[%s]+ability'))  or (MenuName:match('menu[%s]+mount')) or (MenuName:match('menu[%s]+emote')) then mvc.Menu2 = true; 
					elseif (MenuName:match('menu[%s]+magselec')) then mvc.Menu3 = true; 
					elseif  (MenuName:match('menu[%s]+jobcselu')) then mvc.Menu4 = true;
					elseif (MenuName:match('menu[%s]+mogdoor')) or (MenuName:match('menu[%s]+arealist')) or (MenuName:match('menu[%s]+maplist')) or MenuName:match('menu[%s]+gmtell')  or MenuName:match('menu[%s]+merityn') then mvc.Menu5 = true;
					end
				--elseif mvc.Menu6 then
					--mvc.Menu6 = false
				end
			
			else
				mvc.Menu1 = false;  mvc.Menu2 = false;  mvc.Menu3 = false;  mvc.Menu4 = false; mvc.Menu5 =false; mvc.Menu6 =false;
				if imguiWrap.GetKeyDown(28) then ResetAutoHideTimer() end
			end
			if MenuName:find('auc1') and #uiw.MenuList > 0 and uiw.MenuList[#uiw.MenuList][1]=='menucomyn' then uiw.MenuList = {{'menuauc1',0}} end
			Debug(MenuName, 2, false);	
			if MenuID == 0 or MenuName:match('menu[%s]+menuwind') or MenuName:match('menu[%s]+playermo') then
				mvc.Menu1 = false;
				mvc.Menu2 = false;
				uiw.MenuList = {}
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
				end
			
				if MenuID ~= 0 and MenuLabel[1]~='menuinline' and MenuLabel[1]~='menumcr1pall' and MenuLabel[1]~= 'menumcr2pall' then
					for M_i = #uiw.MenuList-1, 1, -1 do
						if 	((MenuLabel[1]==uiw.MenuList[M_i][1] and	MenuLabel[1]~='menuinventor')
							or
							--(MenuLabel[1]=='menuinventor'and MenuLabel[1]==uiw.MenuList[M_i][1] and uiw.MenuList[#uiw.MenuList][1]~='menuinventor') and MenuLabel[2] >= uiw.MenuList[M_i][2]
							(MenuLabel[1]=='menuinventor' and MenuLabel[1]==uiw.MenuList[M_i][1] and MenuLabel[3] == uiw.MenuList[M_i][3] and MenuLabel[2] >= uiw.MenuList[M_i][2])) and (LastMenu==nil or uiw.LastMenu[2] == MenuLabel[2] and uiw.LastMenu[1] == MenuLabel[1]		)				--change the uiw.MenuList[][2] at the first inventor+iuse				
						
						then
								-- table_insert(uiw.MenuList, 1, {'menudummy2',0})
								-- --print('hello')
							for R_i = M_i+1, #uiw.MenuList do
								table_remove(uiw.MenuList, #uiw.MenuList)
							end
							if #uiw.MenuList > 0 and string_find(uiw.MenuList[1][1],'menuauc1') then
								table_insert(uiw.MenuList, 1, {'menudummy',0})
							end
						end
					end
					if #uiw.MenuList == 0 or uiw.MenuList[#uiw.MenuList][1]~= MenuLabel[1] then 
						table_insert(uiw.MenuList, MenuLabel) 
					end;
				end
			
			
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
			
			
				if uiw.InvIdx >0 then mvc.Menu1 = true; end
				if uiw.NoShiftIdx > 0 then mvc.Menu1 = false end
				if MenuLabel and (
					(MenuLabel[1] == 'menutrddummy') or
					(MenuLabel[1] == 'menucomyn')
					)
				then mvc.Menu1 = true end
			
				if #uiw.MenuList > 1 then
					if
						string_find(uiw.MenuList[#uiw.MenuList][1], 'sortw') and (
						string_find(uiw.MenuList[#uiw.MenuList-1][1], 'menumagic') or
						string_find(uiw.MenuList[#uiw.MenuList-1][1], 'menuability') or
						string_find(uiw.MenuList[#uiw.MenuList-1][1], 'menumount') or
						string_find(uiw.MenuList[#uiw.MenuList-1][1], 'menuemote') )
					then
						mvc.Menu2 = true;
						if #uiw.MenuList < 4 or uiw.MenuList[#uiw.MenuList-2][1] ~= uiw.MenuList[#uiw.MenuList-1][1] then table_insert(uiw.MenuList, #uiw.MenuList-1, uiw.MenuList[#uiw.MenuList-1]) end
					elseif 
						string_find(uiw.MenuList[#uiw.MenuList][1], 'sortyn') and (
						string_find(uiw.MenuList[#uiw.MenuList-2][1], 'menumagic') or
						string_find(uiw.MenuList[#uiw.MenuList-2][1], 'menuability') or
						string_find(uiw.MenuList[#uiw.MenuList-2][1], 'menumount') or
						string_find(uiw.MenuList[#uiw.MenuList-2][1], 'menuemote') )
					then 
						mvc.Menu2 = true;
					elseif
						(string_find(uiw.MenuList[#uiw.MenuList][1], 'menulootope') or				
						string_find(uiw.MenuList[#uiw.MenuList][1], 'menulnowin')) and
						string_find(uiw.MenuList[#uiw.MenuList-1][1], 'menuloot')
					then
						mvc.Menu1 = true;
					end
				end
			
			end
			uiw.LastMenu = MenuLabel;
			local list = '';
			for i = 1, #uiw.MenuList do
				list = list..','..uiw.MenuList[i][1]..'-'..tostring(uiw.MenuList[i][2])..'-'..tostring(uiw.MenuList[i][3])
			end
			--menu list
				
		
			if (par.InEvent or MenuName:match('menu[%s]+query'))  or uiw.DialogCDStart ~= 0 or uiw.DialogPromptStart ~= 0 then
				if 	ashita.memory.read_uint32(uiw.DialogPtr) == 1
				then
					par.LastMsgInConv = false;
					uiw.DialogShown = true;
					uiw.DialogCDStart = _now;
				else
				
					-- _now - uiw.DialogCDStart > 0.1
				end
			
				if _now - uiw.DialogCDStart > 0.2 then
					uiw.DialogShown = false;
					uiw.DialogCDStart = 0;
				elseif par.InEvent then
					uiw.DialogCDStart = _now;
				
				end
			
				if not par.InEvent then
					uiw.DialogPromptStart = _now
					par.LastMsgInConv = false;
					uiw.DialogShown = false;
				end
			
				if uiw.DialogPromptStart > 0 then
					if _now - uiw.DialogPromptStart > 0.2 then
					
						uiw.DialogPromptStart = 0;
						uiw.DialogShown = false;
					else
						if ashita.memory.read_uint32(uiw.DialogPtr) == 1 then
						uiw.DialogPromptStart = 0;end
					end
				end
			end
		
		
			local chat2moved = false;
			if not fcw1.MoveChat or not allSettings.SecondChat[1] then
				fcw1.MoveChat = (mvc.Menu1 or mvc.Menu2 or mvc.Menu3 or mvc.Menu4 or mvc.Menu5 or mvc.Menu6 or uiw.DialogShown) and allSettings.LockWindowPos[1] and allSettings.EnabledChatMove[1];
			else
				chat2moved = true;
			end
		
		-- Settings FOs rendering flags --	
			if (uiw.LegacyChatOpen or fcw1.HideChat) then
				fcw1.RenderFOs = false;
			else
				fcw1.RenderFOs = true;
			end

		-- Settings chat buffers according to the active tab --
			if (tab.NextTab ~= allSettings.SelectedTab) then
				fcw1.BufferBusy = true;
				if #fo.Chat[3] > 0 then ResetScrolling(3, fcw3.ChatLines) end
				ChangeTab(1, tab.NextTab);
				b.ChatBufferN[1] = SetBufferN(allSettings.SelectedTab);
				ResetScrolling(1);
			
			else
				b.ChatBufferN[1] = SetBufferN(allSettings.SelectedTab);
			end
		
		
		
		
		

		
		
		
		-- Render All FancyChat windows --
			local windowFlags = 0
		
		
			if AshitaCore:GetChatManager():IsInputOpen() ~= 0x00 then ResetAutoHideTimer() end
			if allSettings.AutoHideWindow[1] and _now - fcw1.autoHideCheckCD > 0.02 then
				fcw1.autoHideCheckCD = _now
				if (os.time() - fcw1.autoHideTime > allSettings.AutoHideTimeMax) then
					if fcw1.autoHideFadeTime == 0 then fcw1.autoHideFadeTime = _now end
					fcw1.autoHideFade = (_now-fcw1.autoHideFadeTime)/0.35
					if fcw1.autoHideFade > 1 then fcw1.autoHideFade = 10 end
				elseif fcw1.autoHideFade > 0 then
					if fcw1.autoHideFade == 10 then
						fcw1.autoHideFadeTime = _now
						fcw1.autoHideFade = 1
					
					else
					
						fcw1.autoHideFade = 1-((_now-fcw1.autoHideFadeTime)/0.1)
						if fcw1.autoHideFade <= 0 then
							fcw1.autoHideFade = 0
							fcw1.autoHideFadeTime = 0
							fcw1.autoHideFade = 0
						
						end
					end
				end
			end
			if fcw3.BigMode then
				ro.RectBG[1]:set_fill_color(0);
				if allSettings.SecondChat[1] then ro.RectBG[2]:set_fill_color(0); end
				for C_i = 1, allSettings.ChatLines do
					SetChatOpacity(0,1)
					if allSettings.SecondChat[1] then
						SetChatOpacity(0,2)
					end
				end
				ShowBigMode(true)
				ResetScrolling(1)
				ro.Scroll[1]:set_visible(false)
				fo.Bkw[1]:set_visible(false)
				if allSettings.SecondChat[1] then
					ResetScrolling(2)
					fo.Bkw[2]:set_visible(false)
					ro.Scroll[2]:set_visible(false)
				end
				if #fo.Chat[3]>0 and not fcw3.BigModePrev then ResetScrolling(3, fcw3.ChatLines);  end
				if not fcw3.BigModePrev then b.ChatBufferIdx[3] = b.ChatBufferIdx[1] end
				DrawBigMode()
				fcw3.BigModePrev = true
			elseif fcw3.BigModePrev then
				ShowBigMode(false)
				ro.RectBG[1]:set_fill_color(allSettings.rectSettings.fill_color);
				if allSettings.SecondChat[1] then ro.RectBG[2]:set_fill_color(allSettings.rectSettings.fill_color); end
				for C_i = 1, allSettings.ChatLines do
					fo.Chat[1][C_i]:set_visible(true)
					fo.Aux[1][C_i]:set_visible(true)
					fo.Chat[1][C_i]:set_opacity(1)
					fo.Aux[1][C_i]:set_opacity(1)
					if allSettings.SecondChat[1] then
						fo.Chat[2][C_i]:set_visible(true)
						fo.Aux[2][C_i]:set_visible(true)
						fo.Chat[2][C_i]:set_opacity(1)
						fo.Aux[2][C_i]:set_opacity(1)
					end
				end
				ResetLines(1)
				fcw1.RequestAuxFix = true
				if allSettings.SecondChat[1] then
					ResetLines(2)
					fcw2.RequestAuxFix = true
				end
				fcw3.BigModePrev = false
			end

			if (not uiw.LegacyChatOpen and not fcw1.HideChat and not fcw1.Closing and fcw1.autoHideFade < 1 and not fcw3.BigMode) then
			
				
				
				-- else
			
			
			
				imgui.SetNextWindowSize({ fcw1.BG_W, ro.RectBG[1].settings.height+16 });
				imgui.SetNextWindowSizeConstraints({ fcw1.BG_W, ro.RectBG[1].settings.height+16 }, { FLT_MAX, FLT_MAX, });
			
				imgui.Begin('FancyChat_ChatBG_'+fcw1.PlayerName, true, bit_bor(fcw1.windowFlagsChatBG, allSettings.LockWindowPos[1] and FLAG_WinNoMove or 0));
			-- Setting variables to position the chat window elements --
			
			
			
		
				local positionStartX, positionStartY = imgui.GetCursorScreenPos();
				positionStartX = positionStartX + allSettings.WindowPosOffset[1];
				positionStartY = positionStartY + allSettings.WindowPosOffset[2];
			
				mvc.targetposY = 0;
				mvc.targetposX = 0;
				if fcw1.MoveChat then
					mvc.targetposX = SetTargetPosX(dsize.x,dsize.y,positionStartX);
				end
			
				if not chat2moved then
					if not allSettings.GuideMeSecondWindow[1] then fcw1.GuideMeClosedTmp = false; end
					if fcw1.MoveChat and mvc.Menu6 and positionStartY+fcw1.BG_H > mvc.targetposY then
						positionStartY = mvc.targetposY-fcw1.BG_H
					
					elseif fcw1.MoveChat and positionStartX < mvc.targetposX
					and fcw1.Anchor_Y > mvc.targetposY
					then
						positionStartX = mvc.targetposX;
				
					else
						fcw1.MoveChat = false;
					end
				else
					if allSettings.CSMode[2] == 2 then
						positionStartY = dsize.y;
					
					elseif allSettings.CSMode[2] == 3 then
						positionStartX = mvc.targetposX + math_floor(fcw2.BG_W)
					end
					fcw1.MoveChat = false;
				end
			
				local centerPosX = (fcw1.BG_W/2 + positionStartX-3);
				local centerPosY = (ro.RectBG[1].settings.height/2 + positionStartY)+3;
				local imageSizeX = (fcw1.BG_W/2);
				local imageSizeY = ro.RectBG[1].settings.height/2;
			
			
				fcw1.Anchor_X = positionStartX;--+(fcw1.BG_W/(_fh*10));--60);
				fcw1.Anchor_Y = positionStartY+(fcw1.BG_H*0.8);
				fcw1.PosChanged = false;
				if fcw1.Anchor_X == 0 or math_abs(fcw1.Anchor_X - fcw1.PrevAnchor_X) >0.1  or
				fcw1.Anchor_Y == 0 or math_abs(fcw1.Anchor_Y - fcw1.PrevAnchor_Y) >0.1 
				then
					fcw1.PosChanged = true;
					fcw1.PositionLinesRequest = {true, true};
				end
				fcw1.PrevAnchor_X = fcw1.Anchor_X;
				fcw1.PrevAnchor_Y = fcw1.Anchor_Y;
			
			
				if fcw1.Scrolling then
					if fcw1.ScrollPos ~= GetScrollPoint(1) then fcw1.PositionLinesRequest = {true,true}; end
					fcw1.ScrollPos = GetScrollPoint(1);
					ro.Scroll[1]:set_visible(true);
				
				else
					fcw1.ScrollPos = 1;
					ro.Scroll[1]:set_visible(false);
				end
		
			
			-- Checking if the border texture should be displayed --
				local mouseX, mouseY = imGetMousePos();
				if (
					mouseX > centerPosX - fcw1.BG_W and mouseX < centerPosX + fcw1.BG_W
					and mouseY > centerPosY - fcw1.BG_H/2 and mouseY < centerPosY + fcw1.BG_H/2
					and imIsMouseDragging(FLAG_MouseLeft) and not fcw1.DraggingScroll
					and iwIsWindowHovered(FLAG_HoveredRectOnly)
					)
				then
					fcw1.Dragging = true;
					if (fcw1.TextureIDBorder ~= nil ) then
						imgui.GetWindowDrawList():AddImage(fcw1.TextureIDBorder, {centerPosX-imageSizeX, centerPosY-imageSizeY}, {centerPosX+imageSizeY, centerPosY+imageSizeY}, {0,0}, {1,1}, COLOR_BORDER_OVERLAY);
					end
				end
			
				if fcw1.Dragging and imIsMouseReleased then fcw1.Dragging = false end;
			
			
			
			-- Setting up line highlighting --
				if IsRectHovered(ro.RectBG[1].settings,0) then
					fcw1.HoverLine = -1;
					local parsedUrl = '';
					local lineOffsetBase = (fcw1.BG_H/120)+(_fh)
					for HL_i = 0, allSettings.ChatLines-1 do
						local lineOffset= lineOffsetBase+HL_i*_fh;
						local highlight_alpha = 0;
						local targetLine = allSettings.ChatLines-HL_i+fcw1.ChatHead-1; if targetLine > allSettings.ChatLines then targetLine = targetLine -allSettings.ChatLines end
						if (fo.Aux[1][targetLine].settings.visible and fo.Aux[1][targetLine].settings.text == '[link]' and
							fo.Chat[1][targetLine].rect ~= nil and fo.Aux[1][targetLine].rect~= nil and 
							mouseX >  fo.Aux[1][targetLine].settings.position_x and mouseX < fo.Aux[1][targetLine].settings.position_x + fo.Aux[1][targetLine].rect.right and
							mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+_fh
							and not fcw1.Dragging
							)
						then --b.msgID
							if (fo.Aux[1][targetLine] ~= nil) then
								fo.Aux[1][targetLine]:set_font_color(0xFFCCEEFF);
								fcw1.HoverLine = allSettings.ChatLines-HL_i;
								local ChatHoverIdx = #b.ChatBuffer[b.ChatBufferMode[1]][2].url-fcw1.HoverLine-fcw1.ScrolledBack-(b.ChatBufferN[1]-b.ChatBufferIdx[1])+1;
								if ChatHoverIdx > 0 then
									--parsedUrl = utils.ParseUrlLink(b.ChatBuffer[b.ChatBufferMode][2].text[ChatHoverIdx]);
								
									if imIsMouseClicked(FLAG_MouseLeft) then
										local urlText = utils.stringsplit(b.ChatBuffer[b.ChatBufferMode[1]][2].url[ChatHoverIdx],'|')
										ashita.misc.open_url((string_find(urlText[2], 'https://') or string_find(urlText[2], 'http://localhost:')) and urlText[2] or 'https://'..urlText[2]);
									end
								end
								fcw1.HoverLine = -1;
							end
								--break
						else
							if (fo.Aux[1][targetLine]~= nil and fo.Aux[1][targetLine].settings.text == '[link]') then
								fo.Aux[1][targetLine]:set_font_color(0xFF44CCFF);
							end
							if (mouseX > fcw1.Anchor_X and mouseX < fcw1.Anchor_X+fcw1.BG_W and
							mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+_fh and
							(iwIsWindowHovered(FLAG_HoveredRectOnly) or (fcw1.MoveChat and IsRectHovered(ro.RectBG[1].settings,0)))
							)
							then
								--dw.TestMessage = tostring(targetLine)..'-'..tostring(fo.Chat[1][targetLine] ~= nil);
							
								fcw1.HoverLine = allSettings.ChatLines-HL_i;
								highlight_alpha = 0.3;
								imgui.GetWindowDrawList():AddRectFilledMultiColor({fcw1.Anchor_X, positionStartY+lineOffset}, {fcw1.Anchor_X+imageSizeX, (positionStartY+lineOffset+_fh)},
								COLOR_HIGHLIGHT_FILL,
								COLOR_HIGHLIGHT_CLEAR,
								COLOR_HIGHLIGHT_CLEAR,
								COLOR_HIGHLIGHT_FILL
								);
								--break
							end
						end
					
					end
				
				end 
			
				if (fcw1.HoverLine > 0 and imIsMouseClicked(FLAG_MouseLeft)) then fcw1.Clicking = true; end
			
				if (fcw1.HoverLine > 0  and iwIsWindowHovered(FLAG_HoveredRectOnly)) then
				
					local copyBufferIdx = #b.ChatBuffer[b.ChatBufferMode[1]][2].text-fcw1.HoverLine-fcw1.ScrolledBack-(b.ChatBufferN[1]-b.ChatBufferIdx[1])+1;
					local copyBufferText = '';
					if (copyBufferIdx > 0 ) then
					local ID = b.ChatBuffer[b.ChatBufferMode[1]][2].url[copyBufferIdx]
					local IDs = 0
					local IDe = 0
					while b.ChatBuffer[b.ChatBufferMode[1]][2].url[copyBufferIdx+IDs] and
						--type(b.ChatBuffer[b.ChatBufferMode[1]][2].url[copyBufferIdx+IDs])=="number" and
						b.ChatBuffer[b.ChatBufferMode[1]][2].url[copyBufferIdx+IDs] == ID do
						IDs = IDs - 1
					end
					while b.ChatBuffer[b.ChatBufferMode[1]][2].url[copyBufferIdx+IDe] and
						--type(b.ChatBuffer[b.ChatBufferMode[1]][2].url[copyBufferIdx+IDe])=="number" and
						b.ChatBuffer[b.ChatBufferMode[1]][2].url[copyBufferIdx+IDe]	== ID do
						IDe = IDe + 1
					end
					local IDi = math_min(IDs+1,0)
					while IDi <= math_max(IDe-1,0) do
						--copyBufferText = b.ChatBuffer[b.ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] ~= '[link]' and copyBufferText..b.ChatBuffer[b.ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] or copyBufferText..b.ChatBuffer[b.ChatBufferMode[1]][2].text[copyBufferIdx+IDi]
						if copyBufferText..b.ChatBuffer[b.ChatBufferMode[1]][2].text[copyBufferIdx+IDi] then
							copyBufferText = (' '..copyBufferText..b.ChatBuffer[b.ChatBufferMode[1]][2].text[copyBufferIdx+IDi]):trimex()
							if b.ChatBuffer[b.ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] ~= '[link]' then
								copyBufferText = copyBufferText..' '..b.ChatBuffer[b.ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi]
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
					if (fcw1.Clicking and imIsMouseReleased(FLAG_MouseLeft)) then
					fcw1.Clicking = false;
						if(copyBufferText ~=nil) then
							if imGetIO().KeyShift then
								if #allSettings.Notes < 10 and #copyBufferText > 0 then
									table_insert(allSettings.Notes, copyBufferText)
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
		
				if (fcw1.Clicking and (imIsMouseDragging(FLAG_MouseLeft) or not imIsMouseDown(FLAG_MouseLeft) )) then fcw1.Clicking = false; end
		

			-- Setting up line scrolling --
				local scrollOffset= (fcw1.BG_H/120);

				if (iwIsWindowHovered(FLAG_HoveredRectOnly) or gamepadButtons.enabled) and not fcw1.BufferBusy
			
				then
					if (
						fcw1.ScrollDelta > 0
					
						and #b.ChatBuffer[b.ChatBufferMode[1]][2].text - fcw1.ScrolledBack - (b.ChatBufferN[1]-b.ChatBufferIdx[1]) > allSettings.ChatLines
					)
					then
						if not imGetIO().KeyShift or not fcw1.Scrolling then
							fcw1.ScrollDelta = 0;
							fcw2.ScrollDelta = 0;
							fcw1.Scrolling = true;
							fcw1.ChatShift = _fh
							fcw1.ScrollUpRequest = true;
						elseif fcw1.Scrolling then
							local currentIdx = #b.ChatBuffer[b.ChatBufferMode[1]][2].text - (b.ChatBufferN[1]-b.ChatBufferIdx[1]) - 1
							GoToLine(1,math_max(currentIdx-(fcw1.ScrolledBack+5), allSettings.ChatLines), currentIdx);
						end
					else
						if ( fcw1.ScrollDelta < 0 and fcw1.ScrolledBack > 0 ) 
						then
							if  not imGetIO().KeyShift or not fcw1.Scrolling then
								fcw1.ScrollDelta = 0;
								fcw2.ScrollDelta = 0;
								fcw1.Scrolling = true;
								fcw1.ChatShift = _fh
								fcw1.ScrollDownRequest = true;
							elseif fcw1.Scrolling then
								local currentIdx = #b.ChatBuffer[b.ChatBufferMode[1]][2].text - (b.ChatBufferN[1]-b.ChatBufferIdx[1]) - 1
								GoToLine(1,math_min(currentIdx-(fcw1.ScrolledBack-5), currentIdx-1), currentIdx);
							end
						end
					end
					ResetAutoHideTimer()
				end
				fcw1.ScrollDelta=0;
			
				if (fcw1.ScrolledBack > 0) then
					fo.Bkw[1]:set_visible(true);
				else

					fo.Bkw[1]:set_visible(false);
				end
			
			
				if (imIsMouseClicked(ImGuiMouseButton_Right)) then
					if fcw1.ScrolledBack > 0 then
						ResetScrolling(1);
					end
					if fcw2.ScrolledBack > 0 then
						ResetScrolling(2);
					end
				end
		
		
			-- Preparing some variables for the Tabs window --
				imgui.End();
		
		
			
			-- Setting up the Tabs window elements --
				local tabsW = ro.RectBG[1].settings.width;
				local tabsH = fcw1.BG_H/(allSettings.ChatLines)+2;
				if fcw1.PosChanged or not fcw1.compactPos or not fcw1.compactSize then
					fcw1.compactPos = {fcw1.Anchor_X+(ro.RectBG[1].settings.width-(tabsW/#tab.Tabs))*0.994-9, fcw1.Anchor_Y - ro.RectBG[1].settings.height+(_fh*2/_fh)+_fh*1.3-1}
					fcw1.compactSize = { tabsW/#tab.Tabs+(tabsH-(_fh/1.2)+3), ro.RectBG[1].settings.height/8 }
				end
				if not allSettings.CompactTabs then
					if fcw1.PosChanged or not fcw1.TabsPos then
						fcw1.TabsPos = {math_floor(fcw1.Anchor_X-(_fh*2/_fh)-((_fh*5)/_fh)),math_floor(fcw1.Anchor_Y+tabsH-2)+math_floor(_fh/25)}
					end
				
					imgui.SetNextWindowPos(fcw1.TabsPos);
				
					imgui.SetNextWindowSize({ tabsW+8, ro.RectBG[1].settings.height/(allSettings.ChatLines*0.7) });
				
				else
					if not allSettings.CompactTabsBL[1] then
						imgui.SetNextWindowPos(fcw1.compactPos);
					else
						if fcw1.PosChanged or not fcw1.TabsPos then
							fcw1.TabsPos = {math_floor(fcw1.Anchor_X-(_fh*2/_fh)-((_fh*5)/_fh)),math_floor(fcw1.Anchor_Y+tabsH-2)+math_floor(_fh/25)}
						end
						imgui.SetNextWindowPos(fcw1.TabsPos);
					end
					imgui.SetNextWindowSize(fcw1.compactSize);
				end
			
				windowFlags = bit_bor( FLAG_WinNoDecoration, FLAG_WinNoBackground);
			
				imgui.Begin('FancyChat_ChatTabs_'+fcw1.PlayerName, true, windowFlags);
				--font.FontSize = 450/_fh;
					-- function() imgui.SetWindowFontScale(_fh/25) end,
					-- function() end
					-- )
			
				local IWwindowfont = imguiWrap.SetWindowFontScale(_fh/25)
				PushColorStyles(tab.ButtonColorStylesNormal);
			
			
			
				if not allSettings.CompactTabs then
					local reserved = tabsW - ((tabsH*4)-8)-8.3
					local cursY = imgui.GetCursorPosY()-7
					local cursx = imgui.GetCursorPosX()-4
					for T_i = 1, #tab.Tabs do
						imgui.SetCursorPos({cursx+(reserved/#tab.Tabs)*(T_i-1),cursY});
						if (tab.Tabs[T_i] == allSettings.SelectedTab) then
							PushColorStyles(tab.ButtonColorStylesSelected);
							imgui.Button(tab.Tabs[T_i]:gsub('Alt','##Alt'),{reserved/#tab.Tabs,tabsH-2});
							PopColorStyles(tab.ButtonColorStylesSelected);
						else
							if (imgui.Button(tab.Tabs[T_i]:gsub('Alt','##Alt'),{reserved/#tab.Tabs,tabsH-2})) then
								tab.NextTab = tab.Tabs[T_i]; 
							end
						end
					end
				
					imgui.SetCursorPos({reserved+4,imgui.GetCursorPosY()-(tabsH+1.6)});
			
					if(fcw1.TextureIDGuideMe ~= nil) then
						if (imguiWrap.ImageButton('TextureIDGuideMe',fcw1.TextureIDGuideMe,{tabsH-8,tabsH-8},{0,0},{1,1},-1,{0,0,0,0},{1,1,1,0.7})) then
						
							fcw1.GuideMeOpened[1] = not fcw1.GuideMeOpened[1];
							if fcw1.GuideMeOpened[1] then	fcw1.NotepadOpened[1]  = false end
						end
						if (imgui.IsItemHovered(0)) then
							imgui.BeginTooltip()
							message = 'Open GuideMe'
							imgui.SetTooltip(message)
							imgui.EndTooltip()
						end
					end
					imgui.SetCursorPos({imgui.GetCursorPosX()+reserved+4+(tabsH-8),imgui.GetCursorPosY()-(tabsH+1.6)});
			
					if(fcw1.TextureIDNotepad ~= nil) then
						if (imguiWrap.ImageButton('TextureIDNotepad',fcw1.TextureIDNotepad,{tabsH-8,tabsH-8},{0,0},{1,1},-1,{0,0,0,0},{1,1,1,0.7})) then
							fcw1.NotepadOpened[1] = not fcw1.NotepadOpened[1]
							if fcw1.NotepadOpened[1] then	fcw1.GuideMeOpened[1] = false end
						end
						if (imgui.IsItemHovered(0)) then
							imgui.BeginTooltip()
							message = 'Open Notepad'
							imgui.SetTooltip(message)
							imgui.EndTooltip()
						end
					end
				
					imgui.SetCursorPos({imgui.GetCursorPosX()+reserved+4+(tabsH*2-8),imgui.GetCursorPosY()-(tabsH+1.6)});
					if(fcw1.TextureIDSettings ~= nil) then
						if (imguiWrap.ImageButton('TextureIDSettings',fcw1.TextureIDSettings,{tabsH-8,tabsH-8},{0,0},{1,1},-1,{0,0,0,0},{1,1,1,0.7})) then
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
					if(fcw1.TextureIDCompact ~= nil) then
						if (imguiWrap.ImageButton('TextureIDCompact',fcw1.TextureIDCompact,{tabsH-8,tabsH-8},{0,0},{1,1},-1,{0,0,0,0},{1,1,1,0.7})) then
							allSettings.CompactTabs = true;
							fcw1.PosChanged = true
							fcw2.PosChanged = true
							SaveSettings();
						end
						if (imgui.IsItemHovered(0)) then
							imgui.BeginTooltip()
							message = 'Compact TabBar Mode'
							imgui.SetTooltip(message)
							imgui.EndTooltip()
						end
					end
				
			
				
					-- if(fcw1.TextureIDCompact ~= nil) then
							-- SaveSettings();
				
				else
					imgui.PushStyleVar(FLAG_StyleVarFrameBorder, 0);
				
					local button_length = {tabsW/#tab.Tabs-(tabsH-8), 0}
					local length_ref = _fh*6
					if button_length[1] > length_ref then button_length[1] = length_ref; button_length[2] = tabsW/#tab.Tabs-(tabsH-8) - length_ref end
				
					for T_i = 1, #tab.Tabs do
					if (tab.Tabs[T_i] == allSettings.SelectedTab) then
							if allSettings.CompactTabsBL[1] then
								imgui.SetCursorPos({0,0});
							else
								imgui.SetCursorPos({button_length[2],0});
							end
							if imgui.Button(tab.Tabs[T_i]:gsub('Alt','##Alt'),{button_length[1],tabsH-6}) then
								if T_i+1 <= #tab.Tabs then tab.NextTab = tab.Tabs[T_i+1]; else  tab.NextTab = tab.Tabs[1] end
							end
						end
					end
				
					if allSettings.CompactTabsBL[1] then
						imgui.SetCursorPos({button_length[1],0});
					else
						imgui.SetCursorPos({(tabsW/#tab.Tabs)-(tabsH-8),0});
					end
				
				
					if imGetIO().KeyShift then
						if(fcw1.TextureIDSettings ~= nil) then
							if imguiWrap.ImageButton('TextureIDSettings',fcw1.TextureIDSettings, {tabsH-8,tabsH-12},{1.05,1.0},{-0.05,-0.0},-1,{0,0,0,0},{1,1,1,0.5}) then
								allSettings.settingsOpened[1] = not allSettings.settingsOpened[1];
							end
						end
					else
						if(fcw1.TextureIDCompact ~= nil) then
							if imguiWrap.ImageButton('TextureIDCompact', fcw1.TextureIDCompact, {tabsH-8,tabsH-12},{1.05,1.05},{-0.05,-0.05},-1,{0,0,0,0},{1,1,1,0.5}) then
								allSettings.CompactTabs = false;
								fcw1.PosChanged = true
								fcw2.PosChanged = true
								SaveSettings();
							end
						end
					end
					imgui.PopStyleVar(1);
			
				end
				PopColorStyles(tab.ButtonColorStylesNormal);
				--font.FontSize = prevFontSize;
				if IWwindowfont then imgui.PopFont(); end
				imgui.End();
			
				fcw1.isHiddenGUI = not AshitaCore:GetGuiManager():GetVisible()
				ui_panels.draw_guideme()
				ui_panels.draw_notepad()
			
		
			end
		
		
		
		
			-- Setting up the Settings window elements --
		
			ui_settings.draw_settings_panel()
		
			if not fcw1.HideChat and not fcw1.Closing and not fcw1.ProcessingText and fcw1.autoHideFade < 1 then 
			-- Updating chat lines status (must be done even if chat is not displayed) ?? --and b.ChatBufferIdx[1] < b.ChatBufferN[1]
				if fcw1.PrevHideChat ~= fcw1.HideChat and fcw1.PrevHideChat  then  ResetScrolling(1) fcw1.RequestAuxFix = true end;
			
				fcw1.ChatShiftScale_Target = fcw1.ChatShiftScale_Base * ( ( 1.2^( b.ChatBufferN[1]-b.ChatBufferIdx[1] ) )-1)+fcw1.ChatShiftScale_Min;
				if (b.ChatBufferN[1]>0) then
					if (b.ChatBufferIdx[1] < b.ChatBufferN[1] and not fcw1.Scrolling and not fcw1.Dragging and not fcw3.Scrolling) then
						fcw1.PositionLinesRequest[1] = true;
					
						if fcw1.ChatShiftScale < fcw1.ChatShiftScale_Target then
							fcw1.ChatShiftScale = fcw1.ChatShiftScale +1;		
						else
							fcw1.ChatShiftScale =fcw1.ChatShiftScale_Target
						end
					
					
						local doupdate = false;
						if(fcw1.ChatShift >= 0 ) then
						
							fcw1.ChatShift = fcw1.ChatShift - ((_now-fcw1.OsClockLast))*(fcw1.ChatShiftScale);
							if fcw1.ChatShift <= 0 then
								doupdate = true;
								if  b.ChatBufferN[1] - b.ChatBufferIdx[1] > 1 then
									fcw1.ChatShift = _fh - math_min(-1*fcw1.ChatShift, _fh);
								--else
								end
							end
							--PrepareLines(1);
						end
						
						
						if doupdate then 
							local bufferIdx = #b.ChatBuffer[b.ChatBufferMode[1]][2].text -(b.ChatBufferN[1]-b.ChatBufferIdx[1]-1);
							if bufferIdx > #b.ChatBuffer[b.ChatBufferMode[1]][2].text or b.ChatBuffer[b.ChatBufferMode[1]][2].text[bufferIdx] == nil then
								ResetLines(1);
							else
								UpdateLines(1,
										b.ChatBuffer[b.ChatBufferMode[1]][2].text[bufferIdx],
										b.ChatBuffer[b.ChatBufferMode[1]][2].color[bufferIdx],
										b.ChatBuffer[b.ChatBufferMode[1]][2].auxText[bufferIdx],
										b.ChatBuffer[b.ChatBufferMode[1]][2].auxColor[bufferIdx]
										);
								b.ChatBufferIdx[1] = b.ChatBufferIdx[1]+1;
							end
							fo.Aux[1][fcw1.ChatHead]:set_opacity(1)
							fo.Chat[1][fcw1.ChatHead]:set_opacity(1)
							if b.ChatBufferIdx[1] == b.ChatBufferN[1] then
								fcw1.ChatShift = _fh;
							end
						end
					
					else
						if fcw1.ChatShiftScale > fcw1.ChatShiftScale_Target then
							fcw1.ChatShiftScale = fcw1.ChatShiftScale - 2;
							if (fcw1.ChatShiftScale_Target == fcw1.ChatShiftScale_Base+fcw1.ChatShiftScale_Min) then
								fcw1.ChatShiftScale = fcw1.ChatShiftScale - 1;
							end
						end
					
						if (fcw1.ChatShiftScale < fcw1.ChatShiftScale_Min) then
							fcw1.ChatShiftScale = fcw1.ChatShiftScale_Min;
						end
					
						if (fcw1.Scrolling and fcw1.ScrollUpRequest)
						then
							fcw1.ScrollUpRequest = false;
							ScrollLines(1,
								b.ChatBuffer[b.ChatBufferMode[1]][2].text[#b.ChatBuffer[b.ChatBufferMode[1]][2].text-allSettings.ChatLines-fcw1.ScrolledBack-(b.ChatBufferN[1]-b.ChatBufferIdx[1])],
								b.ChatBuffer[b.ChatBufferMode[1]][2].color[#b.ChatBuffer[b.ChatBufferMode[1]][2].text-allSettings.ChatLines-fcw1.ScrolledBack-(b.ChatBufferN[1]-b.ChatBufferIdx[1])],
								b.ChatBuffer[b.ChatBufferMode[1]][2].auxText[#b.ChatBuffer[b.ChatBufferMode[1]][2].text-allSettings.ChatLines-fcw1.ScrolledBack-(b.ChatBufferN[1]-b.ChatBufferIdx[1])],
								b.ChatBuffer[b.ChatBufferMode[1]][2].auxColor[#b.ChatBuffer[b.ChatBufferMode[1]][2].text-allSettings.ChatLines-fcw1.ScrolledBack-(b.ChatBufferN[1]-b.ChatBufferIdx[1])],
								1
							);
							
							fcw1.ScrolledBack = fcw1.ScrolledBack +1;

						else
							if (fcw1.Scrolling and fcw1.ScrollDownRequest) then
								fcw1.ScrollDownRequest = false;
								ScrollLines(1,
									b.ChatBuffer[b.ChatBufferMode[1]][2].text[#b.ChatBuffer[b.ChatBufferMode[1]][2].text+1-fcw1.ScrolledBack-(b.ChatBufferN[1]-b.ChatBufferIdx[1])],
									b.ChatBuffer[b.ChatBufferMode[1]][2].color[#b.ChatBuffer[b.ChatBufferMode[1]][2].color+1-fcw1.ScrolledBack-(b.ChatBufferN[1]-b.ChatBufferIdx[1])],
									b.ChatBuffer[b.ChatBufferMode[1]][2].auxText[#b.ChatBuffer[b.ChatBufferMode[1]][2].auxText+1-fcw1.ScrolledBack-(b.ChatBufferN[1]-b.ChatBufferIdx[1])],
									b.ChatBuffer[b.ChatBufferMode[1]][2].auxColor[#b.ChatBuffer[b.ChatBufferMode[1]][2].auxColor+1-fcw1.ScrolledBack-(b.ChatBufferN[1]-b.ChatBufferIdx[1])],
									0
								);
								fcw1.ScrolledBack = fcw1.ScrolledBack -1;
								if fcw1.ScrolledBack == 0 then
									fcw1.Scrolling = false;
									ResetLines(1);
								end
							end
						end
					
					end
				end	
				fcw1.OsClockLast = _now;
				fcw1.PrevMoveChat = fcw1.MoveChat;
			end
	------------------------------------------------------------------------------
			if allSettings.SecondChat[1] then
			
				if (tab.NextTab2 ~= allSettings.SelectedTab2 ) then
					fcw1.BufferBusy = true;
					ChangeTab(2, tab.NextTab2);
					b.ChatBufferN[2] = SetBufferN(allSettings.SelectedTab2);
					ResetScrolling(2);
				else
					b.ChatBufferN[2] = SetBufferN(allSettings.SelectedTab2);
				end
			
			
				if allSettings.SelectedTab2 == 'All' and allSettings.HideCombatFromAll[1] then b.ChatBufferN[2]=b.ChatBufferN_AllAlt;  end
			
				if (not uiw.LegacyChatOpen and not fcw1.HideChat and not fcw1.Closing and fcw1.autoHideFade < 1 and not fcw3.BigMode) then
				
				
					imgui.SetNextWindowSize({ fcw2.BG_W, ro.RectBG[2].settings.height+16 } );
					imgui.SetNextWindowSizeConstraints({ fcw2.BG_W, ro.RectBG[2].settings.height+16 }, { FLT_MAX, FLT_MAX, } );
				
					imgui.Begin('FancyChat_ChatBG2_'+fcw1.PlayerName, true, bit_bor(fcw1.windowFlagsChatBG, allSettings.LockWindowPos[1] and FLAG_WinNoMove or 0));
				
				-- Setting variables to position the chat window elements --
					local positionStartX, positionStartY = imgui.GetCursorScreenPos();
					positionStartX = positionStartX + allSettings.WindowPosOffset[3];
					positionStartY = positionStartY + allSettings.WindowPosOffset[4];
					if fcw1.MoveChat and not mvc.Menu6 then
						if allSettings.CSMode[2] == 2 then
							positionStartY = dsize.y;
							if fcw1.GuideMeDocked and allSettings.GuideMeSecondWindow[1] then fcw1.GuideMeClosedTmp = true; end
							if fcw1.NotepadDocked and allSettings.GuideMeSecondWindow[1] then fcw1.NotepadClosedTmp = true; end
						elseif allSettings.CSMode[2] == 3 then
							positionStartX = mvc.targetposX + math_floor(fcw1.BG_W)
					
						end
						fcw1.MoveChat = false;
					else
						fcw1.NotepadClosedTmp = false
						fcw1.GuideMeClosedTmp = false
						if allSettings.GuideMeSecondWindow[1] then fcw1.GuideMeClosedTmp = false; end
						fcw1.MoveChat = (mvc.Menu1 or mvc.Menu2 or mvc.Menu3 or mvc.Menu4 or mvc.Menu5 or mvc.Menu6 or uiw.DialogShown) and allSettings.LockWindowPos[1] and allSettings.EnabledChatMove[1];
						if fcw1.MoveChat and positionStartX < mvc.targetposX
						and fcw2.Anchor_Y > mvc.targetposY then
							positionStartX = mvc.targetposX;
							fcw1.MoveChat = true;
						elseif fcw1.MoveChat and mvc.Menu6 and positionStartY+fcw1.BG_H > mvc.targetposY then
							positionStartY = mvc.targetposY-fcw1.BG_H
							fcw1.MoveChat = false;
						else
							fcw1.MoveChat = false;
						end
					
					end
				
					local centerPosX = (fcw2.BG_W/2 + positionStartX-3);
					local centerPosY = (ro.RectBG[2].settings.height/2 + positionStartY)+3;
					local imageSizeX = (fcw2.BG_W/2);
					local imageSizeY = ro.RectBG[2].settings.height/2;
				
				
				
					fcw2.Anchor_X = positionStartX;--+(fcw1.BG_W/(_fh*10));--60);
					fcw2.Anchor_Y = positionStartY+(fcw2.BG_H*0.8);
					fcw2.PosChanged = false;
					if fcw2.Anchor_X == 0 or math_abs(fcw2.Anchor_X - fcw2.PrevAnchor_X) > 0.1 or
					fcw2.Anchor_Y == 0 or math_abs(fcw2.Anchor_Y - fcw2.PrevAnchor_Y) > 0.1 
					then
						fcw2.PosChanged = true;
						fcw2.PositionLinesRequest = {true,true};
					end
					fcw2.PrevAnchor_X = fcw2.Anchor_X;
					fcw2.PrevAnchor_Y = fcw2.Anchor_Y;
				
				
					if fcw2.Scrolling then
						if fcw2.ScrollPos ~= GetScrollPoint(2) then fcw2.PositionLinesRequest = {true,true}; end
						fcw2.ScrollPos = GetScrollPoint(2);
						ro.Scroll[2]:set_visible(true);
					else
						fcw2.ScrollPos = 1;
						ro.Scroll[2]:set_visible(false);
					end
				
					local mouseX, mouseY = imGetMousePos();
					if (
						mouseX > centerPosX - fcw2.BG_W and mouseX < centerPosX + fcw2.BG_W
						and mouseY > centerPosY - fcw2.BG_H/2 and mouseY < centerPosY + fcw2.BG_H/2
						and imIsMouseDragging(FLAG_MouseLeft)
						and iwIsWindowHovered(FLAG_HoveredRectOnly)
						)
					then
						fcw2.Dragging = true;
						if (fcw1.TextureIDBorder ~= nil ) then
							imgui.GetWindowDrawList():AddImage(fcw1.TextureIDBorder, {centerPosX-imageSizeX, centerPosY-imageSizeY}, {centerPosX+imageSizeY, centerPosY+imageSizeY}, {0,0}, {1,1}, COLOR_BORDER_OVERLAY);
						end
					end
				
					if fcw2.Dragging and imIsMouseReleased then fcw2.Dragging = false end;

				-- Setting up line highlighting --
					if IsRectHovered(ro.RectBG[2].settings,0) then
						fcw2.HoverLine = -1;
						local parsedUrl = '';
						local lineOffsetBase = (fcw2.BG_H/120)+(_fh)
						for HL_i = 0, allSettings.ChatLines-1 do
							local lineOffset= lineOffsetBase+HL_i*_fh;
							local highlight_alpha = 0;
							local targetLine = allSettings.ChatLines-HL_i+fcw2.ChatHead-1; if targetLine > allSettings.ChatLines then targetLine = targetLine -allSettings.ChatLines end
							if (fo.Aux[2][targetLine].settings.visible and fo.Aux[2][targetLine].settings.text == '[link]' and
								fo.Chat[2][targetLine].rect ~= nil and fo.Aux[2][targetLine].rect~= nil and 
								mouseX >  fo.Aux[2][targetLine].settings.position_x and mouseX < fo.Aux[2][targetLine].settings.position_x + fo.Aux[2][targetLine].rect.right and
								mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+_fh and not fcw2.Dragging
								)
							then
								if (fo.Aux[2][targetLine] ~= nil) then
									fo.Aux[2][targetLine]:set_font_color(0xFFCCEEFF);
									fcw2.HoverLine = allSettings.ChatLines-HL_i;
									local ChatHoverIdx = #b.ChatBuffer[b.ChatBufferMode[2]][2].url-fcw2.HoverLine-fcw2.ScrolledBack-(b.ChatBufferN[2]-b.ChatBufferIdx[2])+1;
									if ChatHoverIdx > 0 then
										--parsedUrl = utils.ParseUrlLink(b.ChatBuffer[b.ChatBufferMode][2].text[ChatHoverIdx]);
										if imIsMouseClicked(FLAG_MouseLeft) then
										local urlText = utils.stringsplit(b.ChatBuffer[b.ChatBufferMode[2]][2].url[ChatHoverIdx],'|')
										ashita.misc.open_url((string_find(urlText[2], 'https://') or string_find(urlText[2], 'http://localhost:')) and urlText[2] or 'https://'..urlText[2]);
									end
									end
									fcw2.HoverLine = -1;
								end
								--break
							else
								if (fo.Aux[2][targetLine]~= nil and fo.Aux[2][targetLine].settings.text == '[link]') then
									fo.Aux[2][targetLine]:set_font_color(0xFF44CCFF);
								end
								if (mouseX > fcw2.Anchor_X and mouseX < fcw2.Anchor_X+fcw2.BG_W and
								mouseY > positionStartY+lineOffset and mouseY < positionStartY+lineOffset+_fh and
								iwIsWindowHovered(FLAG_HoveredRectOnly)
								)
								then
									--dw.TestMessage = tostring(targetLine)..'-'..tostring(fo.Chat[1][targetLine] ~= nil);
									fcw2.HoverLine = allSettings.ChatLines-HL_i;
									highlight_alpha = 0.3;
									imgui.GetWindowDrawList():AddRectFilledMultiColor({fcw2.Anchor_X, positionStartY+lineOffset}, {fcw2.Anchor_X+imageSizeX, (positionStartY+lineOffset+_fh)},
									COLOR_HIGHLIGHT_FILL,
									COLOR_HIGHLIGHT_CLEAR,
									COLOR_HIGHLIGHT_CLEAR,
									COLOR_HIGHLIGHT_FILL
									);
									--break
								end
							
							end
						end
					end
				
					if (fcw2.HoverLine > 0 and imIsMouseClicked(FLAG_MouseLeft)) then fcw2.Clicking = true; end
				
					if (fcw2.HoverLine > 0 and iwIsWindowHovered(FLAG_HoveredRectOnly)) then
					
						local copyBufferIdx = #b.ChatBuffer[b.ChatBufferMode[2]][2].text-fcw2.HoverLine-fcw2.ScrolledBack-(b.ChatBufferN[2]-b.ChatBufferIdx[2])+1;
						local copyBufferText = '';
						if (copyBufferIdx > 0 ) then
						local ID = b.ChatBuffer[b.ChatBufferMode[2]][2].url[copyBufferIdx]
						local IDs = 0
						local IDe = 0
						while b.ChatBuffer[b.ChatBufferMode[2]][2].url[copyBufferIdx+IDs] and
						    --type(b.ChatBuffer[b.ChatBufferMode[2]][2].url[copyBufferIdx+IDs])=="number" and
							b.ChatBuffer[b.ChatBufferMode[2]][2].url[copyBufferIdx+IDs] == ID do
							IDs = IDs - 1
						end
						while b.ChatBuffer[b.ChatBufferMode[2]][2].url[copyBufferIdx+IDe] and
							--type(b.ChatBuffer[b.ChatBufferMode[2]][2].url[copyBufferIdx+IDe])=="number" and
							b.ChatBuffer[b.ChatBufferMode[2]][2].url[copyBufferIdx+IDe]	== ID do
							IDe = IDe + 1
						end
					
						local IDi = math_min(IDs+1,0)
						while IDi <= math_max(IDe-1,0) do
						--copyBufferText = b.ChatBuffer[b.ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] ~= '[link]' and copyBufferText..b.ChatBuffer[b.ChatBufferMode[1]][2].auxText[copyBufferIdx+IDi] or copyBufferText..b.ChatBuffer[b.ChatBufferMode[1]][2].text[copyBufferIdx+IDi]
					
						if b.ChatBuffer[b.ChatBufferMode[2]][2].text[copyBufferIdx+IDi] then
							copyBufferText = (' '..copyBufferText..b.ChatBuffer[b.ChatBufferMode[2]][2].text[copyBufferIdx+IDi]):trimex()
							if b.ChatBuffer[b.ChatBufferMode[2]][2].auxText[copyBufferIdx+IDi] ~= '[link]' then
								copyBufferText = copyBufferText..' '..b.ChatBuffer[b.ChatBufferMode[2]][2].auxText[copyBufferIdx+IDi]
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
						if (fcw2.Clicking and imIsMouseReleased(FLAG_MouseLeft)) then
							fcw2.Clicking = false;
							if(copyBufferText ~=nil) then
								if imGetIO().KeyShift then
									if #allSettings.Notes < 10 and #copyBufferText > 0 then
										table_insert(allSettings.Notes, copyBufferText)
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
			
					if (fcw2.Clicking and (imIsMouseDragging(FLAG_MouseLeft) or not imIsMouseDown(FLAG_MouseLeft) )) then fcw2.Clicking = false; end
				
					local scrollOffset= (fcw2.BG_H/120);

					if (iwIsWindowHovered(FLAG_HoveredRectOnly) or gamepadButtons.enabled) and not fcw1.BufferBusy
				
					then
						if (
							fcw2.ScrollDelta > 0
							and #b.ChatBuffer[b.ChatBufferMode[2]][2].text - fcw2.ScrolledBack - (b.ChatBufferN[2]-b.ChatBufferIdx[2]) > allSettings.ChatLines
						)
						then
							if not imGetIO().KeyShift or not fcw2.Scrolling then
								fcw2.ScrollDelta = 0;
								fcw1.ScrollDelta = 0;
								fcw2.Scrolling = true;
								fcw2.ChatShift = _fh
								fcw2.ScrollUpRequest = true;
							elseif fcw2.Scrolling then
								local currentIdx = #b.ChatBuffer[b.ChatBufferMode[2]][2].text - (b.ChatBufferN[2]-b.ChatBufferIdx[2]) - 1
								GoToLine(2,math_max(currentIdx-(fcw2.ScrolledBack+5), allSettings.ChatLines), currentIdx);
							end
						else
							if ( fcw2.ScrollDelta < 0 and fcw2.ScrolledBack > 0 ) then
								if not imGetIO().KeyShift or not fcw2.Scrolling then
									fcw2.ScrollDelta = 0;
									fcw1.ScrollDelta = 0;
									fcw2.Scrolling = true;
									fcw2.ChatShift = _fh
									fcw2.ScrollDownRequest = true;
								elseif fcw2.Scrolling then
									local currentIdx = #b.ChatBuffer[b.ChatBufferMode[2]][2].text - (b.ChatBufferN[2]-b.ChatBufferIdx[2]) - 1
									GoToLine(2,math_min(currentIdx-(fcw2.ScrolledBack-5), currentIdx-1), currentIdx);
								end
							end
						end
						ResetAutoHideTimer()
					end
					fcw2.ScrollDelta=0;
				
					if (fcw2.ScrolledBack > 0) then
						fo.Bkw[2]:set_visible(true);
					else

						fo.Bkw[2]:set_visible(false);
					end
				
					imgui.End();
				
				-- Preparing some variables for the Tabs window --
		
	
					local tabsW = ro.RectBG[2].settings.width;
					local tabsH = fcw2.BG_H/(allSettings.ChatLines)+2;
					if not allSettings.CompactTabs then
						if fcw2.PosChanged or not fcw2.TabsPos then
							fcw2.TabsPos = {math_floor(fcw2.Anchor_X-(_fh*2/_fh)-((_fh*5)/_fh)),math_floor(fcw2.Anchor_Y+tabsH-2)+math_floor(_fh/25)}
						end
						imgui.SetNextWindowPos(fcw2.TabsPos);
				
						imgui.SetNextWindowSize({ tabsW+8, ro.RectBG[2].settings.height/(allSettings.ChatLines*0.7) });
					else
						if fcw2.PosChanged or not fcw2.compactPos or not fcw2.compactSize then
							fcw2.compactPos = {fcw2.Anchor_X+(ro.RectBG[2].settings.width-(tabsW/#tab.Tabs))*0.995-1, fcw2.Anchor_Y - ro.RectBG[2].settings.height+(_fh*2/_fh)+_fh*1.3-1}; 
				
							fcw2.compactSize = { tabsW/#tab.Tabs+(tabsH-(_fh/1.2)+3), ro.RectBG[2].settings.height/8 };
						end
						if not allSettings.CompactTabsBL[1] then
							imgui.SetNextWindowPos(fcw2.compactPos);
						else
							if fcw2.PosChanged or not fcw2.TabsPos then
								fcw2.TabsPos = {math_floor(fcw2.Anchor_X-(_fh*2/_fh)-((_fh*5)/_fh)),math_floor(fcw2.Anchor_Y+tabsH-2)+math_floor(_fh/25)}
							end
							imgui.SetNextWindowPos(fcw2.TabsPos);
						end
						imgui.SetNextWindowSize(fcw2.compactSize)
						
					end
				
					windowFlags = bit_bor(FLAG_WinNoDecoration, FLAG_WinNoBackground);
				
					imgui.Begin('FancyChat_ChatTabs2_'+fcw1.PlayerName, true, windowFlags);
					--font.FontSize = 450/_fh;
				
					local IWwindowfont2 = imguiWrap.SetWindowFontScale(_fh/25)
					PushColorStyles(tab.ButtonColorStylesNormal);

					if not allSettings.CompactTabs then
						local reserved = tabsW -1.5
						local cursY = imgui.GetCursorPosY()-7
						local cursx = imgui.GetCursorPosX()-4
						for T_i = 1, #tab.Tabs do
							imgui.SetCursorPos({cursx+(reserved/#tab.Tabs)*(T_i-1),cursY});
							if (tab.Tabs[T_i] == allSettings.SelectedTab2) then
								PushColorStyles(tab.ButtonColorStylesSelected);
								imgui.Button(tab.Tabs[T_i]:gsub('Alt','##Alt'),{reserved/#tab.Tabs,tabsH-2});
								PopColorStyles(tab.ButtonColorStylesSelected);
							else
								if (imgui.Button(tab.Tabs[T_i]:gsub('Alt','##Alt'),{reserved/#tab.Tabs,tabsH-2})) then
									tab.NextTab2 = tab.Tabs[T_i]; 
								end
							end
						end
				
					else
						imgui.PushStyleVar(FLAG_StyleVarFrameBorder, 0);
				
						button_length = {tabsW/#tab.Tabs, 0}
						length_ref = _fh*4.5
						if button_length[1] > length_ref then button_length[1] = length_ref; button_length[2] = tabsW/#tab.Tabs - length_ref end
					
						for T_i = 1, #tab.Tabs do
						if (tab.Tabs[T_i] == allSettings.SelectedTab2) then
								if allSettings.CompactTabsBL[1] then
									imgui.SetCursorPos({0,0});
								else
									imgui.SetCursorPos({button_length[2],0});
								end
								if imgui.Button(tab.Tabs[T_i]:gsub('Alt','##Alt'),{button_length[1],tabsH-6}) then
									if T_i+1 <= #tab.Tabs then tab.NextTab2 = tab.Tabs[T_i+1]; else  tab.NextTab2 = tab.Tabs[1] end
								end
							end
						end
						
						
						imgui.PopStyleVar(1);
					end
					PopColorStyles(tab.ButtonColorStylesNormal);
					--font.FontSize = prevFontSize;
					if IWwindowfont2 then imgui.PopFont() end
					imgui.End();
				end
				if not fcw1.HideChat and not fcw1.Closing and not fcw1.ProcessingText and (not allSettings.AutoHideWindow[1] or os.time() - fcw1.autoHideTime < allSettings.AutoHideTimeMax) then 	
				
					if fcw1.PrevHideChat ~= fcw1.HideChat and fcw1.PrevHideChat then ResetScrolling(2) fcw2.RequestAuxFix = true end;
				
					fcw2.ChatShiftScale_Target = fcw2.ChatShiftScale_Base * ( ( 1.2^( b.ChatBufferN[2]-b.ChatBufferIdx[2] ) )-1)+fcw2.ChatShiftScale_Min;
				
					if (b.ChatBufferN[2]>0) then

						if (b.ChatBufferIdx[2] < b.ChatBufferN[2] and not fcw2.Scrolling and not fcw2.Dragging and not fcw3.Scrolling) then
							fcw2.PositionLinesRequest[1] = true;
						
							if fcw2.ChatShiftScale < fcw2.ChatShiftScale_Target then
								fcw2.ChatShiftScale = fcw2.ChatShiftScale +1;
							else
								fcw2.ChatShiftScale =fcw2.ChatShiftScale_Target
							end
						
							local doupdate = false;
							if(fcw2.ChatShift >= 0 ) then
								fcw2.ChatShift = fcw2.ChatShift - ((_now-fcw2.OsClockLast))*(fcw2.ChatShiftScale);
							--	else
									if fcw2.ChatShift <= 0 then 
										doupdate = true;
										if  b.ChatBufferN[2] - b.ChatBufferIdx[2] > 1 then
									
											fcw2.ChatShift = _fh - math_min(-1*fcw2.ChatShift, _fh);
										--else
										end
						--			else
									
									end
								--PrepareLines(2);
							end	
							if doupdate then
								local bufferIdx = #b.ChatBuffer[b.ChatBufferMode[2]][2].text -(b.ChatBufferN[2]-b.ChatBufferIdx[2]-1);
								if bufferIdx > #b.ChatBuffer[b.ChatBufferMode[2]][2].text or b.ChatBuffer[b.ChatBufferMode[2]][2].text[bufferIdx] == nil then
									ResetLines(2);
								else
									UpdateLines(2,
												b.ChatBuffer[b.ChatBufferMode[2]][2].text[bufferIdx],
												b.ChatBuffer[b.ChatBufferMode[2]][2].color[bufferIdx],
												b.ChatBuffer[b.ChatBufferMode[2]][2].auxText[bufferIdx],
												b.ChatBuffer[b.ChatBufferMode[2]][2].auxColor[bufferIdx]
												);
								
									b.ChatBufferIdx[2] = b.ChatBufferIdx[2]+1;
								end
								fo.Aux[2][fcw2.ChatHead]:set_opacity(1)
								fo.Chat[2][fcw2.ChatHead]:set_opacity(1)
								if b.ChatBufferIdx[2] == b.ChatBufferN[2] then
									 fcw2.ChatShift = _fh
								end
								--else
							end
						else
						
							if fcw2.ChatShiftScale > fcw2.ChatShiftScale_Target then
								fcw2.ChatShiftScale = fcw2.ChatShiftScale - 2;
								if (fcw2.ChatShiftScale_Target == fcw2.ChatShiftScale_Base+fcw2.ChatShiftScale_Min) then
									fcw2.ChatShiftScale = fcw2.ChatShiftScale - 1;
								end
							end
						
							if (fcw2.ChatShiftScale < fcw2.ChatShiftScale_Min) then
								fcw2.ChatShiftScale = fcw2.ChatShiftScale_Min;
							end
							fcw2.ChatShift = _fh;
						
							if (fcw2.Scrolling and fcw2.ScrollUpRequest)
							then
								fcw2.ScrollUpRequest = false;
								ScrollLines(2,
									b.ChatBuffer[b.ChatBufferMode[2]][2].text[#b.ChatBuffer[b.ChatBufferMode[2]][2].text-allSettings.ChatLines-fcw2.ScrolledBack-(b.ChatBufferN[2]-b.ChatBufferIdx[2])],
									b.ChatBuffer[b.ChatBufferMode[2]][2].color[#b.ChatBuffer[b.ChatBufferMode[2]][2].text-allSettings.ChatLines-fcw2.ScrolledBack-(b.ChatBufferN[2]-b.ChatBufferIdx[2])],
									b.ChatBuffer[b.ChatBufferMode[2]][2].auxText[#b.ChatBuffer[b.ChatBufferMode[2]][2].text-allSettings.ChatLines-fcw2.ScrolledBack-(b.ChatBufferN[2]-b.ChatBufferIdx[2])],
									b.ChatBuffer[b.ChatBufferMode[2]][2].auxColor[#b.ChatBuffer[b.ChatBufferMode[2]][2].text-allSettings.ChatLines-fcw2.ScrolledBack-(b.ChatBufferN[2]-b.ChatBufferIdx[2])],
									1
								);
							
								fcw2.ScrolledBack = fcw2.ScrolledBack +1;

							else
								if (fcw2.Scrolling and fcw2.ScrollDownRequest) then
									fcw2.ScrollDownRequest = false;
									ScrollLines(2,
										b.ChatBuffer[b.ChatBufferMode[2]][2].text[#b.ChatBuffer[b.ChatBufferMode[2]][2].text+1-fcw2.ScrolledBack-(b.ChatBufferN[2]-b.ChatBufferIdx[2])],
										b.ChatBuffer[b.ChatBufferMode[2]][2].color[#b.ChatBuffer[b.ChatBufferMode[2]][2].color+1-fcw2.ScrolledBack-(b.ChatBufferN[2]-b.ChatBufferIdx[2])],
										b.ChatBuffer[b.ChatBufferMode[2]][2].auxText[#b.ChatBuffer[b.ChatBufferMode[2]][2].auxText+1-fcw2.ScrolledBack-(b.ChatBufferN[2]-b.ChatBufferIdx[2])],
										b.ChatBuffer[b.ChatBufferMode[2]][2].auxColor[#b.ChatBuffer[b.ChatBufferMode[2]][2].auxColor+1-fcw2.ScrolledBack-(b.ChatBufferN[2]-b.ChatBufferIdx[2])],
										0
									);
									fcw2.ScrolledBack = fcw2.ScrolledBack -1;
									if fcw2.ScrolledBack == 0 then
										fcw2.Scrolling = false;
										ResetLines(2);
									end
								end
							end
					
						end
					end
				
					fcw2.OsClockLast = _now;
				end
			end
			fcw1.PrevHideChat = fcw1.HideChat
		
			if not allSettings.firstLoadMessage[1] then
				AddWarning(
				'Please Read!\n\nWelcome to FancyChat addon!\n\nThis is addon provides a highly customizable and interactive chat replacemante for Final Fantasy XI.\nPlease take your time to check all the settings by either clicking the cog wheel icon at the bottom of the chat window or by typing the command \"/fancychat settings\".\n\nYou can hover with your mouse over the (i) icons to learn more about each functionality. This addon features some advanced options that can include unwanted behaviors for certain players. Therefore, please pay extra attention to the (i) marked in red to learn about important critical information about such features.\n\nFor further help you can check the addon manual accessible from the settings menu or through the command \"/fancychat manual\".\n\nHave fun!'
				,
				dsize.y/2, allSettings.firstLoadMessage, dsize.x/2, 'Welcome to FancyChat')
			end
		end
	
		if help.opened[1] then
			PushWindowStyle()
			help.ShowManual(fcw1.PlayerName);
			PopWindowStyle()
		end
	
	
	
	------------------------------------------
		
		-- Render Debug Window if opened --
	
		if (dw.WindowOpened[1]) then DebugWindow(); end
	
	end);

	ashita.events.register('d3d_endscene', 'd3d_endscene_callback1', function (isRenderingBackBuffer)

		if (not isRenderingBackBuffer) then return; end

		-- Per-frame caches (same rationale as d3d_present).
		local fcw1, fcw2, fcw3 = fcw[1], fcw[2], fcw[3]

	    -- isRenderingBackBuffer is a flag that will be true when the game is currently rendering to the back buffer.
		--and fcw1.LoggedLobby ~= 1
		if (fcw1.PlayerName ~= '---' and fcw1.LoggedLobby ~= 1 and not fcw1.Zoning and fcw1.LoggedIn and #settings.name > 0 and fcw1.RenderFOs and not fcw1.HideChat and not uiw.LegacyChatOpen and not fcw1.Closing and fcw1.autoHideFade < 1) then
			if not fcw1.WasRendered then
				for C_i = 1, allSettings.ChatLines do
					fo.Chat[1][C_i]:set_visible(true)
					fo.Aux[1][C_i]:set_visible(true)
					if allSettings.SecondChat[1] then
						fo.Chat[2][C_i]:set_visible(true)
						fo.Aux[2][C_i]:set_visible(true)
					end
				end
				SetChatOpacity(1,1)
				SetChatOpacity(1,2)
				SetChatOpacity(1,3)
			
			end
			if not fcw3.BigMode then
				PositionLines(1);
				if fcw1.RequestAuxFix then FixAux(1) end
				if allSettings.SecondChat[1] then PositionLines(2); if fcw2.RequestAuxFix then FixAux(2) end end
				local updateColor = bit_band(allSettings.rectSettings.fill_color -(fcw1.autoHideFade * allSettings.rectSettings.fill_color), 0xFF000000)
				if ro.RectBG[1].settings.fill_color ~= updateColor then
					ro.RectBG[1]:set_fill_color(math_min(math_max(updateColor,0x00000000)),0xFF000000);
					SetChatOpacity(math_max(1-fcw1.autoHideFade,0),1)
				end
				if allSettings.SecondChat[1] and ro.RectBG[2].settings.fill_color ~= updateColor then
					ro.RectBG[2]:set_fill_color(math_min(math_max(updateColor,0x00000000)),0xFF000000);
					SetChatOpacity(math_max(1-fcw1.autoHideFade,0),2)
				end
			else
				if fcw3.RequestAuxFix then FixAux(3, fcw3.ChatLines) end
				PositionLines(3, fcw3.ChatLines)
			end
		
		
		

			--L_i+1-allSettings.ChatLines == fcwFoId.ChatHead  and not (fcw1.ChatHead == 1 and C_i == allSettings.ChatLines)
		
		
		
				-- --SetLinesVisible(1, true)
				-- --SetLinesVisible(2, true)
		
			gdi:render();
			fcw1.WasRendered = true
			--gdi:set_auto_render(true);
		else
			--gdi:set_auto_render(false);
			fcw1.WasRendered = false
		end;
	
	
		-- fpsCount = fpsCount + 1;
	        -- fpsFrame = fpsCount;
	        -- fpsCount = 0;
	        -- fpsTimer = os.time();
			-- testResult = testResult+ (_now-timeStart)*(fpsFrame/60)
		-- timeMax = (_now-timeStart)*(fpsFrame/60) > timeMax and (_now-timeStart)*(fpsFrame/60) or timeMax
		fcw1.BufferBusy = false;
	end);
end

return M
