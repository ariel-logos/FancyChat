-- lib/render.lua — d3d_present + d3d_endscene callbacks.  Per-frame
-- UI plumbing; reads state.* tables and calls helper modules via the
-- _G.* globals each registers.  Exports M.register() and the global
-- ResetAutoHideTimer() (used by every module on user activity).

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
local ffi         = require('ffi')

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

-- Hot stdlib + ImGui locals (upvalue caching for the per-frame loop).
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

-- ImGui flag constants captured once.
local FLAG_HoveredRectOnly       = ImGuiHoveredFlags_RectOnly
local FLAG_MouseLeft             = ImGuiMouseButton_Left
local FLAG_WinNoMove             = ImGuiWindowFlags_NoMove
local FLAG_WinNoDecoration       = ImGuiWindowFlags_NoDecoration
local FLAG_WinNoBackground       = ImGuiWindowFlags_NoBackground
local FLAG_StyleVarFrameBorder   = ImGuiStyleVar_FrameBorderSize

-- Precomputed highlight colour U32s.
local COLOR_HIGHLIGHT_FILL  = imGetColorU32({ 1.0, 1.0, 1.0, 0.3 })
local COLOR_HIGHLIGHT_CLEAR = imGetColorU32({ 1.0, 1.0, 1.0, 0.0 })
local COLOR_BORDER_OVERLAY  = imGetColorU32({ 1.0, 1.0, 1.0, 0.75 })

local M = {}

-- Pokes the auto-hide fade timer; called by every module on activity.
function M.ResetAutoHideTimer()
	fcw[1].autoHideTime = os.time()
end
_G.ResetAutoHideTimer = M.ResetAutoHideTimer

function M.register()
	ashita.events.register('d3d_present', 'present_cb', function ()
		-- Per-frame caches (avoids repeated lookups).
		local fcw1, fcw2, fcw3 = fcw[1], fcw[2], fcw[3]
		local _fh  = allSettings.fontSettings.font_height
		local _now = os.clock()

		-- Hover state for the top-left help (?) button on window 1.
		-- Reset each frame; populated only when the BG window is drawn
		-- AND the mouse is over the button.  Anchor coords are screen-
		-- space top-left of the button, used to position the tooltip.
		local helpHovered                  = false
		local helpAnchorX, helpAnchorY     = 0, 0

		fcw1.LoginStatus = AshitaCore:GetMemoryManager():GetPlayer():GetLoginStatus();
	
		if fcw1.LoginStatus == 2 then
			if not fcw1.InitDone then
				Init();
				-- Captured once per addon load (Init only runs while
				-- InitDone is false).  Used by the /servmes gate below
				-- to skip the auto-fire if 0x00E0 arrives more than
				-- 30s after this addon-load timestamp - relevant when
				-- the user does /addon reload fancychat mid-session.
				-- Logout / login resets this via the /addon reload at
				-- line ~98, so on every fresh login Init() runs again
				-- and LoginTime is re-captured.
				par.LoginTime = os.time()
			end
			local player = GetPlayerEntity();
			if not player or not settings then return end
			fcw1.LoggedIn = true
			
			if fcw1.PlayerName == '' and settings.name ~= '' then
				AshitaCore:GetChatManager():QueueCommand(-1, "/addon reload fancychat")
			else
				fcw1.PlayerName = settings.name
				allSettings.PlayerName = settings.name
			end
		elseif fcw1.LoginStatus == 1 then
			return
		else		
			fcw1.LoggedIn = false
			fcw1.PlayerName = ''
			fcw1.LoggedLobby = 1
			fcw1.WaitingServMes = 0
			par.LoginTime = 0
			return
		end
		
		
		
		if fcw1.LoggedIn and not fcw1.Closing and not fcw1.Zoning then
			

			if fcw1.WaitingServMes > 0 and _now - fcw1.WaitingServMes > 2 and os.time() - par.LoginTime < 30 then
				
				AshitaCore:GetChatManager():QueueCommand(1, "/servmes")
				fcw1.WaitingServMes = -1
				fcw1.HasDoneServMes = true
			end
		
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
			--Debug(MenuName, 2, false);   -- debug_window disabled
			if MenuID == 0 or MenuName:match('menu[%s]+menuwind') or MenuName:match('menu[%s]+playermo') then
				mvc.Menu1 = false;
				mvc.Menu2 = false;
				uiw.MenuList = {}
			else
			
				local MenuExt = ashita.memory.read_uint32(uiw.MenuPtr-0x3C)
				local MenuLabel = {MenuName:gsub('[%s]+',''), MenuExt,''};
				--Debug(MenuLabel[1]..'-'..MenuLabel[2], 2, false);   -- debug_window disabled
		
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
							if imGetIO().KeyCtrl then
								-- Ctrl + left-click: open the /sea zone
								-- popup at the cursor.  Skip the copy /
								-- notepad branches below so the line's
								-- text is NOT placed on the clipboard.
								local zones = utils.FindZonesInText(copyBufferText, set.zoneNames)
								if #zones > 0 then
									local mx, my   = imGetMousePos()
									set.zoneTip.visible = true
									set.zoneTip.zones   = zones
									set.zoneTip.x       = mx
									set.zoneTip.y       = my
									-- One-shot latch consumed on the popup's
									-- first render frame: triggers a single
									-- SetNextWindowFocus (so the popup pops
									-- on top of the chat) and suppresses the
									-- open-frame dismissal race (otherwise
									-- the mouse-release that opened us would
									-- immediately re-close us).
									set.zoneTip.justAppeared  = true
									-- Reset the accordion state so every
									-- popup open starts with Maps expanded
									-- and the local-map directory rescan
									-- happens fresh (so any new files the
									-- user dropped into maps/<zone>/ get
									-- picked up between opens).
									set.zoneTip.activeSection = {}
									set.zoneTip.localMaps     = {}
									set.zoneTip.pressInside   = false
								end
							elseif imGetIO().KeyShift then
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

				-- Help (?) button rendered in its own dedicated 24x24
				-- transparent window so its top-left can be anchored
				-- exactly to the chat plate (ro.RectBG[1]) without
				-- being affected by the BG window's WindowPadding or
				-- content-clip rect.  Drawn AFTER the BG window's End
				-- so it sits on top in stack order.  The button's
				-- background is fully transparent; a faint white tint
				-- is shown on hover / press for feedback.
				--
				-- IsItemHovered() is called with FLAG_HoveredRectOnly
				-- because the chat BG window (NoBringToFrontOnFocus)
				-- occludes us in ImGui's z-order — the rect-only flag
				-- bypasses occlusion-based hover suppression.
				--
				-- Gated by allSettings.HelpButton[1] (Settings -> Chat
				-- Window).  When disabled, the entire button + tooltip
				-- pipeline is skipped (helpHovered stays false).
				if allSettings.HelpButton[1] then
					helpAnchorX = ro.RectBG[1].settings.position_x
					helpAnchorY = ro.RectBG[1].settings.position_y
					imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, {0, 0})
					imgui.SetNextWindowPos({helpAnchorX, helpAnchorY}, ImGuiCond_Always)
					imgui.SetNextWindowSize({24, 24})
					local _helpBtnFlags = bit_bor(
						ImGuiWindowFlags_NoDecoration,
						ImGuiWindowFlags_NoBackground,
						ImGuiWindowFlags_NoMove,
						ImGuiWindowFlags_NoSavedSettings,
						ImGuiWindowFlags_NoBringToFrontOnFocus,
						ImGuiWindowFlags_NoFocusOnAppearing,
						ImGuiWindowFlags_NoNav)
					if imgui.Begin('##fc1_help_button', true, _helpBtnFlags) then
						-- Frame layout: 14x14 image + 5px padding on each
						-- side = 24x24 button = exact window size.  The
						-- FramePadding push applies in the new (>=1.89)
						-- ImGui binding (where the ImageButton call has
						-- no framePadding arg); the framePadding=5 arg
						-- below is what the old binding uses.
						imgui.PushStyleVar(ImGuiStyleVar_FramePadding,    {5, 5})
						-- No frame-border outline around the icon.
						imgui.PushStyleVar(ImGuiStyleVar_FrameBorderSize, 0)
						imgui.PushStyleColor(ImGuiCol_Button,        {0, 0, 0, 0   })
						imgui.PushStyleColor(ImGuiCol_ButtonHovered, {1, 1, 1, 0.15})
						imgui.PushStyleColor(ImGuiCol_ButtonActive,  {1, 1, 1, 0.30})
						-- Same info icon (fcw1.TextureIDInfo) that the
						-- Settings tooltips use via AddTooltip in
						-- ui_helpers.lua - visual consistency.  Tint at
						-- a soft light-gray (~70%) so it reads as a
						-- subtle hover affordance rather than a full-
						-- attention chrome element.
						imguiWrap.ImageButton(
							'fc1_help_imgbtn',
							fcw1.TextureIDInfo,
							{14, 14},          -- image size
							{0, 0}, {1, 1},    -- uv0 / uv1
							5,                 -- frame padding (old binding)
							{0, 0, 0, 0},        -- bg color (transparent)
							{0.85, 0.85, 0.85, 1}) -- tint (between light gray and white)
						imgui.PopStyleColor(3)
						imgui.PopStyleVar(2)
						helpHovered = imgui.IsItemHovered(FLAG_HoveredRectOnly)
					end
					imgui.End()
					imgui.PopStyleVar()
				end

				-- Floating help-tooltip window for the (?) button.
				-- Rendered OUTSIDE the BG window so its own size /
				-- position aren't constrained by the parent.  Pivot
				-- {0, 1} anchors the tooltip's bottom-left corner at
				-- the button's top-left → the tooltip grows up + right.
				--
				-- NoBringToFrontOnFocus is deliberately absent and
				-- SetNextWindowFocus is called each frame the tooltip
				-- is shown: the chat BG window has NoBringToFrontOnFocus
				-- so it never moves out of the way on its own, and
				-- without the explicit focus call the tooltip would
				-- render behind it (same pattern as ZoneSearchPopup).
				if helpHovered then
					imgui.SetNextWindowPos(
						{ helpAnchorX, helpAnchorY },
						ImGuiCond_Always,
						{ 0, 1 })
					imgui.SetNextWindowFocus()
					local _helpFlags = bit_bor(
						ImGuiWindowFlags_NoDecoration,
						ImGuiWindowFlags_NoTitleBar,
						ImGuiWindowFlags_NoFocusOnAppearing,
						ImGuiWindowFlags_NoMove,
						ImGuiWindowFlags_NoSavedSettings,
						ImGuiWindowFlags_NoNav,
						ImGuiWindowFlags_NoResize,
						ImGuiWindowFlags_AlwaysAutoResize)
					if imgui.Begin('##fc1_help_tooltip', true, _helpFlags) then
						imgui.Text('FancyChat - quick reference')
						imgui.Separator()
						imgui.BulletText('L-Click on a chat line          Copy text to clipboard')
						imgui.BulletText('Ctrl + L-Click on a zone name   Open zone search & map popup')
						imgui.BulletText('Shift + L-Click on a chat line  Save line to Notepad (max 10)')
						imgui.BulletText('L-Click on a [link] tag         Open URL in browser')
						imgui.BulletText('R-Click anywhere on the chat    Jump to the latest message')
						imgui.BulletText('L-Click + Drag on chat window   Reposition the chat window')
						imgui.BulletText('Mouse Wheel over the chat       Scroll history')
						imgui.BulletText('Shift + Mouse Wheel             Fast scroll (5 lines / tick)')
						imgui.BulletText('Shift hover compact-tab button  Swap it for the Settings icon')
						imgui.Separator()
						imgui.TextDisabled('Type /fancychat settings for more options')
						imgui.TextDisabled('This (?) button can be disabled under Settings -> Chat Window')
					end
					imgui.End()
				end


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

		--if (dw.WindowOpened[1]) then DebugWindow(); end   -- debug_window disabled

		-- Ctrl+left-click /sea popup.  set.zoneTip is armed by the
		-- click-release handler on the primary chat window.  Dismissed
		-- by clicking outside, pressing Escape, or chat auto-hide.
		if set.zoneTip.visible
			and allSettings.AutoHideWindow[1]
			and (os.time() - fcw1.autoHideTime > allSettings.AutoHideTimeMax)
		then
			set.zoneTip.visible = false
		end
		if set.zoneTip.visible then
			-- NoBringToFrontOnFocus is deliberately absent — without it,
			-- clicks on the popup get stolen by overlapping chat windows.
			local wFlags = bit.bor(
				ImGuiWindowFlags_NoDecoration,
				ImGuiWindowFlags_NoTitleBar,
				ImGuiWindowFlags_NoFocusOnAppearing,
				ImGuiWindowFlags_NoMove,
				ImGuiWindowFlags_NoSavedSettings,
				ImGuiWindowFlags_NoNav,
				ImGuiWindowFlags_NoResize,
				ImGuiWindowFlags_AlwaysAutoResize)

			-- Anchor the popup with pivot {0, 1}: the given screen
			-- position is treated as the BOTTOM-LEFT of the auto-resized
			-- window.  ImGui computes the final top-left as
			-- (pos.x - 0*width, pos.y - 1*height) = (pos.x, pos.y - height),
			-- which is exactly the up-and-right growth we want.  No
			-- separate measure pass needed: ImGui knows the height at
			-- Begin time because AlwaysAutoResize is computed during
			-- layout, then applied to the pivot calculation before the
			-- window renders.  Versioned window name dodges any stale
			-- imgui.ini entry written by an older version of the code.
			imgui.SetNextWindowPos(
				{set.zoneTip.x + 4, set.zoneTip.y - 4},
				ImGuiCond_Always,
				{0, 1})

			-- Capture the just-appeared latch BEFORE Begin so the alpha
			-- Push/Pop below stays balanced.  The flag itself gets
			-- cleared INSIDE the Begin block (after the dismissal-skip
			-- logic), so by the time we'd reach the post-End Pop the
			-- flag would already read false.  Local captures the
			-- value at entry to this block.
			local maskFirstFrame = set.zoneTip.justAppeared

			-- One-shot focus on appearance.  justAppeared is set true
			-- by the chat handler on Ctrl+L-click, consumed below at
			-- end of Begin block so subsequent visible frames don't
			-- keep stealing focus.
			if maskFirstFrame then
				imgui.SetNextWindowFocus()
				-- Near-transparent alpha (1/255) on the first render
				-- frame so the user never sees the popup at the wrong
				-- position before ImGui's AlwaysAutoResize knows the
				-- height.  Pure 0.0 was tried previously and triggered
				-- ImGui's window-skip optimisation on second-show
				-- (broke reopen entirely); a tiny non-zero alpha is
				-- functionally invisible but bypasses that codepath.
				imgui.PushStyleVar(ImGuiStyleVar_Alpha, 1/255)
			end

			if imgui.Begin('##FCZoneSearch_v3', true, wFlags) then
				for zi, zone in ipairs(set.zoneTip.zones or {}) do
					-- Wrap the zone name in double quotes so multi-word
					-- zones (e.g. "Rolanberry Fields", "Ru'Lude Gardens")
					-- are passed as a single argument to /sea instead
					-- of being split on spaces by the chat parser.
					local searchCmd = '/sea "'..zone..'"'
					if imgui.Selectable(searchCmd) then
						AshitaCore:GetChatManager():QueueCommand(-1, searchCmd)
						set.zoneTip.visible = false
					end

					-- Visual separator between the /sea command and the
					-- two browser-link entries below.
					imgui.Separator()

					-- Open the FFXIclopedia wiki page in the user's
					-- default browser.  ashita.misc.open_url is a
					-- one-liner; no in-game image rendering needed.
					if imgui.Selectable('Open '..zone..' on FFXIclopedia') then
						ashita.misc.open_url(utils.GetZoneWikiUrl(zone))
						set.zoneTip.visible = false
					end

					-- bg-wiki page (independent of FFXIclopedia, useful
					-- when Cloudflare blocks Fandom).
					if imgui.Selectable('Open '..zone..' on bg-wiki') then
						ashita.misc.open_url(utils.GetBgWikiZoneUrl(zone))
						set.zoneTip.visible = false
					end

					-- Local map sections.  Lazy-fill the per-zone scan
					-- result the first frame this zone is drawn in the
					-- popup, then reuse for subsequent frames.  The
					-- whole cache is wiped on each popup open so the
					-- accordion always starts with Maps expanded and
					-- any disk changes between opens are visible.
					if set.zoneTip.localMaps[zone] == nil then
						set.zoneTip.localMaps[zone] = utils.GetLocalZoneMaps(zone) or false
					end
					local sections = set.zoneTip.localMaps[zone]
					-- Three valid states for activeSection[zone]:
					--   nil   → never touched on this popup-open  → default to 'Maps' open
					--   false → user explicitly clicked the green '-' to collapse
					--           the open section          → no section open
					--   string → that section is open
					-- We can't use `or 'Maps'` here because Lua treats `false`
					-- as falsy too, so a collapsed state would silently
					-- re-expand Maps the next frame.
					local active = set.zoneTip.activeSection[zone]
					if active == nil then active = 'Maps' end

					if not sections then
						-- Per the chosen UX: zones with no local maps
						-- still show the "Maps" header expanded with a
						-- single greyed-out "(No Map)" placeholder.
						-- No other section headers are drawn for these
						-- zones (none exist on disk).
						imgui.TextDisabled('- Maps -')
						imgui.TextDisabled('  (No Map)')
					else
						-- Each section row is "[+/- button] section name".
						-- Button size is locked to a square scaled by the
						-- current font size so the "+" / "-" label always
						-- fits and the button visually matches the text
						-- next to it (+4 px gives a small breathing
						-- margin around the glyph).
						local fontH    = imgui.GetFontSize()
						local btnSide  = fontH + 4
						local btnSize  = {btnSide, btnSide}
						-- Indent map-entry lines past where the button
						-- ends so the entries hang under the section
						-- name, not under the button column.
						local indentPx = btnSide + 4

						for _, section in ipairs(sections) do
							local isActive = section.folder == active

							-- Green tint when this section is the
							-- expanded one.  Push all three button
							-- state colors so hover / active stay in
							-- the same hue family rather than reverting
							-- to ImGui's default blue on hover.
							if isActive then
								imgui.PushStyleColor(ImGuiCol_Button,        {0.20, 0.65, 0.30, 1.0})
								imgui.PushStyleColor(ImGuiCol_ButtonHovered, {0.30, 0.80, 0.40, 1.0})
								imgui.PushStyleColor(ImGuiCol_ButtonActive,  {0.10, 0.50, 0.20, 1.0})
							end

							-- '##' + per-row suffix gives the button a
							-- stable ImGui ID without putting that text
							-- in the visible label.  Without a unique
							-- suffix, every "+" and "-" button would
							-- collide on the same internal ID.
							local btnLabel = (isActive and '-' or '+')
								..'##sec_'..zone..'_'..section.folder
							if imgui.Button(btnLabel, btnSize) then
								if isActive then
									-- Click on the green '-' button:
									-- collapse this section.  Stored as
									-- `false` rather than nil so the
									-- next-frame "default to Maps"
									-- coalesce doesn't fire.
									set.zoneTip.activeSection[zone] = false
								else
									-- Click on a '+' button: expand
									-- this section, implicitly
									-- collapsing whichever was open.
									set.zoneTip.activeSection[zone] = section.folder
								end
							end

							if isActive then
								imgui.PopStyleColor(3)
							end

							-- Section name, on the same horizontal line
							-- as the button.  AlignTextToFramePadding
							-- bumps the cursor.y by FramePadding.y so
							-- the text baseline lines up with the
							-- button's text baseline instead of
							-- floating at the top of the button frame.
							imgui.SameLine()
							imgui.AlignTextToFramePadding()
							imgui.Text(section.display)

							if isActive then
								-- Bracket the entries with Indent /
								-- Unindent so they hang under the
								-- section name (past the button
								-- column) and the next section row
								-- starts back at column 0.
								imgui.Indent(indentPx)
								for _, entry in ipairs(section.entries) do
									if imgui.Selectable(entry.display) then
										-- Load (or reuse cached) texture
										-- from disk.  Cache key is the
										-- absolute file path so the same
										-- file referenced from different
										-- zones (rare but possible if the
										-- user reorganises maps/) shares
										-- one decoded texture.
										local cached = set.zoneMapTextures[entry.path]
										if not cached then
											local tex, w, h = utils.LoadTextureFromFile(entry.path)
											if tex then
												cached = {
													tex = tex,
													ptr = tonumber(ffi.cast('uint32_t', tex)),
													w   = w,
													h   = h,
												}
												set.zoneMapTextures[entry.path] = cached
											end
										end
										if cached then
											-- `or 0` makes this resilient if
											-- state.lua's default wasn't picked
											-- up by the live `set` table (e.g.
											-- after a partial /addon reload).
											set.zoneMapUidCounter = (set.zoneMapUidCounter or 0) + 1
											table.insert(set.zoneMapWindows, {
												-- Plain ASCII hyphen for
												-- the same font-glyph
												-- reason as elsewhere.
												title  = zone..' - '..entry.display,
												url    = entry.path,
												ptr    = cached.ptr,
												w      = cached.w,
												h      = cached.h,
												opened = {true},
												uid    = set.zoneMapUidCounter,
											})
										end
										set.zoneTip.visible = false
									end
								end
								imgui.Unindent(indentPx)
							end
						end
					end

					-- Double separator between zones to distinguish them
					-- from the single separator drawn within a zone.
					if zi < #set.zoneTip.zones then
						imgui.Separator()
						imgui.Separator()
					end
				end

				-- Press-anchored dismissal: capture pressInside on
				-- press, dismiss on release only if press was outside.
				-- The justAppeared guard suppresses the open-frame
				-- release (the mouse-up that opened us) from being
				-- treated as a dismissal release.
				local hovered = imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly)
				if hovered then ResetAutoHideTimer() end
				if not set.zoneTip.justAppeared then
					if imIsMouseClicked(FLAG_MouseLeft)
						or imIsMouseClicked(ImGuiMouseButton_Right) then
						set.zoneTip.pressInside = hovered
					end
					if not set.zoneTip.pressInside
						and (imIsMouseReleased(FLAG_MouseLeft)
						     or imIsMouseReleased(ImGuiMouseButton_Right)) then
						set.zoneTip.visible = false
					end
				end

				-- Escape dismissal.  GetKeyDown(1) = DI scancode 1 =
				-- Escape; works regardless of popup focus state.
				if imguiWrap.GetKeyDown(1) then
					set.zoneTip.visible = false
				end

				-- Consume the one-shot just-appeared latch AFTER all
				-- the per-frame logic above so the next frame falls
				-- into the normal dismissal path.
				set.zoneTip.justAppeared = false
			end
			imgui.End()
			-- Balance the PushStyleVar(Alpha) above (only pushed on the
			-- first-appearance frame; maskFirstFrame remembers that).
			if maskFirstFrame then
				imgui.PopStyleVar()
			end
		end

		-- Zone-map windows.  Each entry in set.zoneMapWindows was
		-- pushed by the popup's "Show map: …" Selectable above and
		-- carries its own pre-decoded D3D8 texture pointer.  Draw
		-- each in its own draggable, resizable ImGui window with the
		-- close-X enabled — the user dismisses an individual map via
		-- that X.  When opened[1] flips to false (X clicked), drop
		-- the entry from the list; the texture stays cached in
		-- set.zoneMapTextures[url] for instant re-open.
		--
		-- Iterate in reverse so removing entries during the loop
		-- doesn't skip neighbours.
		-- Read the current WindowBg colour from ImGui's style so the
		-- title bar can be tinted to match (rather than the default
		-- distinct title-bar shade).  style.Colors is a 0-indexed
		-- enum exposed as a 1-indexed Lua array, so the index needs
		-- a +1 bump.  The returned value is an ImVec4 with .x/.y/.z/.w
		-- which we unpack into a plain table for PushStyleColor.
		local _bg = imgui.GetStyle().Colors[ImGuiCol_WindowBg + 1]
		local _bgVec = {_bg.x, _bg.y, _bg.z, _bg.w}
		for wi = #set.zoneMapWindows, 1, -1 do
			local mw = set.zoneMapWindows[wi]
			-- Default size: a square at 70% of the current display
			-- height.  ImGuiCond_FirstUseEver applies the size only
			-- on the first frame each window's unique uid is seen,
			-- so subsequent frames respect any user resize done via
			-- the bottom-right grip.  Each new "open" assigns a
			-- fresh uid, so reopening a map after closing it brings
			-- it back at the default size rather than the previously
			-- resized size.
			local dsize = imgui.GetIO().DisplaySize
			local side  = math.floor(dsize.y * 0.7)
			imgui.SetNextWindowSize({side, side}, ImGuiCond_FirstUseEver)
			-- Make the title bar visually merge with the window body
			-- by overriding all three title-bg states (inactive,
			-- focused, collapsed) with the WindowBg colour captured
			-- above.  The title text and close-X stay visible since
			-- those use ImGuiCol_Text / ImGuiCol_CloseButton which we
			-- don't touch.
			imgui.PushStyleColor(ImGuiCol_TitleBg,          _bgVec)
			imgui.PushStyleColor(ImGuiCol_TitleBgActive,    _bgVec)
			imgui.PushStyleColor(ImGuiCol_TitleBgCollapsed, _bgVec)
			-- ID suffix is the per-instance uid (NOT the array index)
			-- so closing an earlier window doesn't reshuffle the IDs
			-- of the remaining ones — without that, ImGui would map
			-- each surviving window onto the previous slot's saved
			-- size, snapping it to a different size on close.
			if imgui.Begin('Map: '..mw.title..'##ZoneMap'..tostring(mw.uid),
				mw.opened, ImGuiWindowFlags_NoSavedSettings) then
				-- Scale the image to fit the content region while
				-- preserving aspect ratio, then centre it both
				-- horizontally and vertically inside the square.
				-- GetContentRegionAvail returns the area inside the
				-- title bar + window padding.
				local availW, availH = imgui.GetContentRegionAvail()
				local scale = math.min(availW / mw.w, availH / mw.h)
				local drawW = mw.w * scale
				local drawH = mw.h * scale
				local cx, cy = imgui.GetCursorPos()
				imgui.SetCursorPos({
					cx + math.max((availW - drawW) * 0.5, 0),
					cy + math.max((availH - drawH) * 0.5, 0),
				})
				imgui.Image(mw.ptr, {drawW, drawH})
			end
			imgui.End()
			imgui.PopStyleColor(3)
			if not mw.opened[1] then
				table.remove(set.zoneMapWindows, wi)
			end
		end

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
