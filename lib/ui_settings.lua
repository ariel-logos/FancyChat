--[[
	lib/ui_settings.lua

	The Settings tabbed window invoked from the d3d_present render loop:

	  draw_settings_panel()  Renders the entire settings UI when
	                         allSettings.settingsOpened[1] is true,
	                         otherwise mirrors persisted values into
	                         the live `set.*` working copy so the
	                         pending-edit fields stay in sync the next
	                         time the panel is opened.

	Tabs (in order):
	  Chat Window  Font size, chat width, plate alpha, line count,
	               second-chat toggle, custom tab modes, position
	               offsets, lock/compact/gamepad/auto-hide flags,
	               half-length toggle, anti-obstruction config.
	  Font Colors  Per-mode color editor with import/export and
	               picker pane.
	  Shortcuts    Hide / BigMode / Tab / Tab2 keyboard combos and
	               the inline command reference.
	  Extra        Block-legacy / hide-combat filters, timestamp,
	               R0 warning, precise TS, tell + alert sound config,
	               item preview, autorestore, colorblind, fast scroll,
	               docked-second-window, heart emoji.
	  CL Filters   Custom combat-log filter editor + reload button.
	  Tools        Save logs, open logs folder, open manual, restore
	               legacy chat (DumpChat) buttons.

	Calls a handful of GLOBAL helpers still defined in fancychat.lua:
	AddSetColor, AddTooltip, AddWarning, PushWindowStyle/PopWindowStyle,
	ResetAutoHideTimer, SaveSettings, DumpChat.  Resolved at call time
	via the global namespace.
]]

require('common')
local imgui     = require('imgui')
local imguiWrap = require('imguiWrap')
local utils     = require('utils')
local help      = require('help')
local state     = require('lib.state')

local fcw           = state.fcw
local tab           = state.tab
local set           = state.set
local par           = state.par
local b             = state.b
local allSettings   = state.allSettings
local defaultColors = state.defaultColors

local M = {}

function M.draw_settings_panel()

	-- When the panel is closed, sync the persisted values back into
	-- the `set.*` working copy so the next open shows the current
	-- state and not stale pending edits.
	if not allSettings.settingsOpened[1] then
		set.SecondChat[1] = allSettings.SecondChat[1]
		set.ChatLineMaxL  = allSettings.chatLineMaxL
		set.PlateBGColor  = allSettings.rectSettings.fill_color
		set.FontHeight    = allSettings.fontSettings.font_height
		for ct = 1, #allSettings.CustomTabModes do
			set.CustomTabModes[ct] = allSettings.CustomTabModes[ct]
		end
		set.ChatLines = allSettings.ChatLines
		return
	end

	ResetAutoHideTimer()
	PushWindowStyle()

	local dsize = imgui.GetIO().DisplaySize

	imgui.SetNextWindowSize({dsize.x / 3.8, dsize.y / 2.7})
	imgui.SetNextWindowSizeConstraints({550, 300}, {FLT_MAX, FLT_MAX})
	imgui.Begin('FancyChat Settings##_'+fcw[1].PlayerName, allSettings.settingsOpened,
		bit.bor(ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_NoNav))

	local setsizex, setsizey = imgui.GetWindowSize()

	if imgui.BeginTabBar('##fancychat_tabbar', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton) then

		----------------------------------------------------------------
		-- Tab: Chat Window
		----------------------------------------------------------------
		if imgui.BeginTabItem('Chat Window', nil) then
			imguiWrap.BeginChild('##Chat Window Child',
				{(setsizex * 3.8 / 3.9) - (12 * (1 - (setsizex * 3.8 / 1920))) - 3, setsizey * 2.7 / 2.8 - 60}, true)

			local fontSize = T{set.FontHeight}
			local cposY = imgui.GetCursorPosY()
			local cposX = imgui.GetCursorPosX()
			imgui.Text('Font Size')
			imgui.SameLine()
			imgui.SetCursorPosY(cposY - 3)
			imgui.PushItemWidth(dsize.x / 7.5)
			imgui.SetCursorPosX((dsize.x / 4.3 - dsize.x / 8) * (1920 / dsize.x))
			if imgui.SliderInt('##FontSizeSlider', fontSize, 14, 50, '%d', ImGuiSliderFlags_AlwaysClamp) then
				set.FontHeight = fontSize[1]
			end

			local lineSize = T{set.ChatLineMaxL}
			cposY = imgui.GetCursorPosY()
			cposX = imgui.GetCursorPosX()
			imgui.SetCursorPosY(cposY + 10)
			imgui.Text('Chat Width')
			imgui.SameLine()
			imgui.SetCursorPosY(cposY + 7)
			imgui.SetCursorPosX((dsize.x / 4.3 - dsize.x / 8) * (1920 / dsize.x))
			if imgui.SliderInt('##ChatWidthSlider', lineSize, 60, 135, '%d', ImGuiSliderFlags_AlwaysClamp) then
				set.ChatLineMaxL = lineSize[1]
			end

			local plateBGcolor = set.PlateBGColor
			local plateBGAlpha = T{tonumber(bit.rshift(plateBGcolor, 24)) / 255}
			cposY = imgui.GetCursorPosY()
			cposX = imgui.GetCursorPosX()
			imgui.SetCursorPosY(cposY + 10)
			imgui.Text('Plate BG Alpha')
			imgui.SameLine()
			imgui.SetCursorPosY(cposY + 7)
			imgui.SetCursorPosX((dsize.x / 4.3 - dsize.x / 8) * (1920 / dsize.x))
			if imgui.SliderFloat('##plateBGAlphaSlider', plateBGAlpha, 0, 0.499, '%.2f',
				bit.bor(ImGuiSliderFlags_AlwaysClamp, ImGuiSliderFlags_NoRoundToFormat)) then
				set.PlateBGColor = bit.lshift(bit.tobit(plateBGAlpha[1] * 255), 24)
			end

			local chatlines = T{set.ChatLines}
			cposY = imgui.GetCursorPosY()
			cposX = imgui.GetCursorPosX()
			imgui.SetCursorPosY(cposY + 10)
			imgui.Text('Number of chat lines')
			imgui.SameLine()
			imgui.SetCursorPosY(cposY + 7)
			imgui.SetCursorPosX((dsize.x / 4.3 - dsize.x / 8) * (1920 / dsize.x))
			if imgui.SliderInt('##ChatLinesSlider', chatlines, 8, 16, '%d', ImGuiSliderFlags_AlwaysClamp) then
				set.ChatLines = chatlines[1]
			end
			imgui.PopItemWidth()

			imgui.Dummy({0, 5})
			if imgui.Checkbox('Enable second chat window', {set.SecondChat[1]}) then
				set.SecondChat[1] = not set.SecondChat[1]
			end

			imgui.Dummy({0, 5})
			imgui.Text('Messages shown in Custom tab')
			AddTooltip('The messages selected for the custom tab won\'t appear in All if Hide from All is enabled in \'Extra\' settings.', 0, true)
			if imgui.Checkbox('NPC',  {set.CustomTabModes[1]}) then set.CustomTabModes[1] = not set.CustomTabModes[1] end imgui.SameLine()
			cposY = imgui.GetCursorPosY()
			AddTooltip('Depending on the server settings, this might not catch all NPC messages or catch some /say messages.', 4) imgui.SameLine() imgui.SetCursorPosY(cposY)
			if imgui.Checkbox('Tell', {set.CustomTabModes[4]}) then set.CustomTabModes[4] = not set.CustomTabModes[4] end imgui.SameLine()
			if imgui.Checkbox('Party',{set.CustomTabModes[3]}) then set.CustomTabModes[3] = not set.CustomTabModes[3] end imgui.SameLine()
			if imgui.Checkbox('LS',   {set.CustomTabModes[2]}) then set.CustomTabModes[2] = not set.CustomTabModes[2] end imgui.SameLine()
			if imgui.Checkbox('Shout',{set.CustomTabModes[5]}) then set.CustomTabModes[5] = not set.CustomTabModes[5] end

			imgui.Dummy({0, 5})
			if imgui.Button('Reset default values') then
				set.ChatLineMaxL    = 100
				set.PlateBGColor    = bit.lshift(bit.tobit(0.3 * 255), 24)
				set.FontHeight      = 20
				set.ChatLines       = 8
				set.SecondChat[1]   = false
				set.CustomTabModes  = T{false, false, false, false, false}
			end

			imgui.Dummy({0, 5})
			imgui.TextColored({1.0, 0.2, 0.2, 1.0}, '^')
			cposY = imgui.GetCursorPosY()
			imgui.SetCursorPosY(cposY - 20)

			imgui.TextColored({1.0, 0.2, 0.2, 1.0}, '|')
			cposY = imgui.GetCursorPosY()
			imgui.SetCursorPosY(cposY - 20)
			cposX = imgui.GetCursorPosX()
			imgui.SetCursorPosX(cposX + 15)
			imgui.TextColored({1.0, 0.2, 0.2, 1.0}, 'Changes to all settings above require an addon restart')
			AddTooltip('The changes to options above won\'t take effect until the addon is restarted', 1, 1)
			if imgui.Button('Restart & apply') then
				fcw[1].Closing = true
				if not set.SecondChat[1] then
					allSettings.GuideMeSecondWindow[1] = false
				end
				allSettings.SecondChat[1]            = set.SecondChat[1]
				allSettings.ChatLines                = set.ChatLines
				allSettings.fontSettings.font_height = set.FontHeight
				allSettings.rectSettings.fill_color  = set.PlateBGColor
				allSettings.chatLineMaxL             = set.ChatLineMaxL
				for ct = 1, #set.CustomTabModes do
					allSettings.CustomTabModes[ct] = set.CustomTabModes[ct]
				end
				SaveSettings()
				AshitaCore:GetChatManager():QueueCommand(1, '/addon reload fancychat')
			end

			imgui.Dummy({0, 35})
			imgui.Text('Adjust final windows position')
			AddTooltip('After adjusting the chat window positions manually, use this option to make pixel-by-pixel adjustments', 0)
			imgui.Dummy({0, 25})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('1##Window1', {set.AdjWin1[1]}) then set.AdjWin1[1] = not set.AdjWin1[1] end imgui.SameLine() imgui.Dummy({2, 0}) imgui.SameLine()
			if imgui.Checkbox('2##Window2', {set.AdjWin2[1]}) then set.AdjWin2[1] = not set.AdjWin2[1] end

			imgui.SameLine() imgui.Dummy({10, 0}) imgui.SameLine()

			if imgui.ArrowButton('#AnchorL', ImGuiDir_Left) then
				if set.AdjWin1[1] then allSettings.WindowPosOffset[1] = allSettings.WindowPosOffset[1] - 1 end
				if set.AdjWin2[1] then allSettings.WindowPosOffset[3] = allSettings.WindowPosOffset[3] - 1 end
				fcw[1].PositionLinesRequest = {true, true}
				fcw[2].PositionLinesRequest = {true, true}
			end
			cposY = imgui.GetCursorPosY()
			imgui.SetCursorPosY(cposY - 51)
			cposX = imgui.GetCursorPosX()
			imgui.SetCursorPosX(cposX + 154)
			if imgui.ArrowButton('#AnchorU', ImGuiDir_Up) then
				if set.AdjWin1[1] then allSettings.WindowPosOffset[2] = allSettings.WindowPosOffset[2] - 1 end
				if set.AdjWin2[1] then allSettings.WindowPosOffset[4] = allSettings.WindowPosOffset[4] - 1 end
				fcw[1].PositionLinesRequest = {true, true}
				fcw[2].PositionLinesRequest = {true, true}
			end
			cposY = imgui.GetCursorPosY()
			imgui.SetCursorPosY(cposY - 1)
			cposX = imgui.GetCursorPosX()
			imgui.SetCursorPosX(cposX + 161)
			imgui.Text('+')
			cposY = imgui.GetCursorPosY()
			imgui.SetCursorPosY(cposY - 3)
			cposX = imgui.GetCursorPosX()
			imgui.SetCursorPosX(cposX + 154)
			if imgui.ArrowButton('#AnchorD', ImGuiDir_Down) then
				if set.AdjWin1[1] then allSettings.WindowPosOffset[2] = allSettings.WindowPosOffset[2] + 1 end
				if set.AdjWin2[1] then allSettings.WindowPosOffset[4] = allSettings.WindowPosOffset[4] + 1 end
				fcw[1].PositionLinesRequest = {true, true}
				fcw[2].PositionLinesRequest = {true, true}
			end
			cposY = imgui.GetCursorPosY()
			imgui.SetCursorPosY(cposY - 51)
			cposX = imgui.GetCursorPosX()
			imgui.SetCursorPosX(cposX + 177)
			if imgui.ArrowButton('#AnchorR', ImGuiDir_Right) then
				if set.AdjWin1[1] then allSettings.WindowPosOffset[1] = allSettings.WindowPosOffset[1] + 1 end
				if set.AdjWin2[1] then allSettings.WindowPosOffset[3] = allSettings.WindowPosOffset[3] + 1 end
				fcw[1].PositionLinesRequest = {true, true}
				fcw[2].PositionLinesRequest = {true, true}
			end
			cposY = imgui.GetCursorPosY()
			imgui.SetCursorPosY(cposY - 53)
			cposX = imgui.GetCursorPosX()
			imgui.SetCursorPosX(cposX + 230)
			imgui.Text('W1 [x:'..tostring(allSettings.WindowPosOffset[1])..', y:'..tostring(allSettings.WindowPosOffset[2])..']\nW2 [x:'..tostring(allSettings.WindowPosOffset[3])..', y:'..tostring(allSettings.WindowPosOffset[4])..']')
			cposX = imgui.GetCursorPosX()
			imgui.SetCursorPosX(cposX + 230)
			if imgui.Button('Save##Offsets') then SaveSettings() end imgui.SameLine()
			if imgui.Button('Reset##Offsets') then allSettings.WindowPosOffset = {0, 0, 0, 0} end

			imgui.Dummy({0, 20})
			if imgui.Checkbox('Lock Windows Positions (disables dragging)##WindowLock', {allSettings.LockWindowPos[1]}) then
				allSettings.LockWindowPos[1] = not allSettings.LockWindowPos[1]
				SaveSettings()
			end
			imgui.Dummy({0, 5})
			if imgui.Checkbox('Compact tabs in the bottom-left corner##ComapctBL', {allSettings.CompactTabsBL[1]}) then
				allSettings.CompactTabsBL[1] = not allSettings.CompactTabsBL[1]
				SaveSettings()
			end
			imgui.Dummy({0, 5})
			if imgui.Checkbox('Gampad Chat Navigation##GamepadNav', {allSettings.GamepadNav[1]}) then
				allSettings.GamepadNav[1] = not allSettings.GamepadNav[1]
				SaveSettings()
			end
			imgui.Dummy({0, 5})
			if imgui.Checkbox('Enable Auto-Hide window', {allSettings.AutoHideWindow[1]}) then
				allSettings.AutoHideWindow[1] = not allSettings.AutoHideWindow[1]
				SaveSettings()
			end
			imgui.PushItemWidth(dsize.x / 10)
			cposY = imgui.GetCursorPosY()
			cposX = imgui.GetCursorPosX()
			imgui.Dummy({3, 0}) imgui.SameLine() imgui.Text('L')
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 18)
			imgui.Dummy({20, 0}) imgui.SameLine()
			imgui.Text('Auto-Hide time (seconds) >')
			imgui.SameLine()
			imgui.SetCursorPosY(cposY + 0.5)
			imgui.SetCursorPosX((dsize.x / 3.7 - dsize.x / 8) * (1920 / dsize.x))
			local ahtime = {allSettings.AutoHideTimeMax}
			if imgui.SliderInt('##AutoHideSlider', ahtime, 5, 60, '%d', ImGuiSliderFlags_AlwaysClamp) then
				allSettings.AutoHideTimeMax = ahtime[1]
				SaveSettings()
			end
			imgui.PopItemWidth()
			imgui.Dummy({0, 5})
			if imgui.Checkbox('Use half window length for docked UI elements', {allSettings.UseHalfLength[1]}) then
				allSettings.UseHalfLength[1] = not allSettings.UseHalfLength[1]
				SaveSettings()
			end
			AddTooltip('Only uses half the length of the chat window as reference for UI elements docked to chat window.', 4)
			imgui.Dummy({0, 5})
			if imgui.Checkbox('Prevent obstructing FFXI UI', {allSettings.EnabledChatMove[1]}) then
				allSettings.EnabledChatMove[1] = not allSettings.EnabledChatMove[1]
				SaveSettings()
			end
			imgui.Dummy({1, 0}) imgui.SameLine() imgui.Text('|  Set what happens to the 2nd chat')
			local csmodes = {{'Nothing', 1}, {'Hide 2nd', 2}, {'Shift along', 3}}
			imgui.Dummy({1, 0}) imgui.SameLine() imgui.SetCursorPosY(imgui.GetCursorPosY() + 4) imgui.Text('| ') imgui.SetCursorPosY(imgui.GetCursorPosY() - 4) imgui.SameLine()
			if imgui.BeginCombo('##ChatShiftMode', allSettings.CSMode[1], ImGuiComboFlags_None) then
				for CS_i = 1, #csmodes do
					if imgui.Selectable(csmodes[CS_i][1]) then
						allSettings.CSMode = csmodes[CS_i]
						SaveSettings()
					end
				end
				imgui.EndCombo()
			end
			imgui.Dummy({1, 0}) imgui.SameLine() imgui.Text('| ') imgui.SameLine()
			if imgui.Checkbox('Prevent obstructing Auto-Translate menu as well', {allSettings.MoveChatATMenu[1]}) then
				allSettings.MoveChatATMenu[1] = not allSettings.MoveChatATMenu[1]
				SaveSettings()
			end
			imgui.Dummy({3, 0}) imgui.SameLine() imgui.Text('L')
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 18)
			imgui.Dummy({27, 0}) imgui.SameLine()
			imgui.Text('[ Experimental ]\n[ Reposition chats if FFXI UI elements overlap ]\n[ Works with the most common game UI elements ]\n[ Only works with chat positions locked ]')

			imgui.EndChild()
			imgui.EndTabItem()
		end

		----------------------------------------------------------------
		-- Tab: Font Colors
		----------------------------------------------------------------
		if imgui.BeginTabItem('Font Colors', nil) then
			imguiWrap.BeginChild('leftpane',
				{((setsizex * 3.8 / 3.9) - (12 * (1 - (setsizex * 3.8 / 1920))) - 3) * set.colorTextW, setsizey * 2.7 / 3 - 60}, true)

			local keys = {}
			local tmpcolor = {}
			for key in pairs(allSettings.colors) do
				table.insert(keys, key)
			end
			table.sort(keys)
			local skip = {'combat', 'combatspell', 'cexi'}
			set.colorTextW = 0
			for _, key in ipairs(keys) do
				if not utils.FindInStringTable(key, skip, 0) then
					set.colorTextW = math.max(AddSetColor(key, allSettings.colors[key], tmpcolor), set.colorTextW)
				end
			end
			set.colorTextW = set.colorTextW / (setsizex - ((12 * (1 - (setsizex * 3.8 / 1920))) - 3 * 2))

			imgui.EndChild()

			imgui.SameLine()

			imguiWrap.BeginChild('righttpane',
				{((setsizex * 3.8 / 3.9) - (12 * (1 - (setsizex * 3.8 / 1920))) - 3) * (1 - (set.colorTextW + 0.01)), setsizey * 2.7 / 3 - 60}, true)

			imgui.Text('Color Picker')
			imgui.Separator()
			imgui.TextWrapped('Pick a color and click an arrow button on the left pane to assign it.')
			if tmpcolor[1] then set.PickedColor = utils.cloneTable(tmpcolor[1]) end
			imgui.PushItemWidth(dsize.x / (set.colorTextW * 25))
			imgui.ColorPicker3('Preview', set.PickedColor)
			imgui.PopItemWidth()
			imgui.EndChild()

			if imgui.Button('Reset Colors') then
				allSettings.colors = utils.cloneTable(defaultColors)
				SaveSettings()
			end
			imgui.SameLine()
			if imgui.Button('Export Colors') then
				local exportedcolors = {}
				for _, key in ipairs(keys) do
					if not utils.FindInStringTable(key, skip, 0) then
						exportedcolors[key] = allSettings.colors[key]
					end
				end
				utils.ExportColors(addon.path, fcw[1].PlayerName, exportedcolors)
			end
			imgui.SameLine()
			if imgui.Button('Import Colors') then
				allSettings.colors = utils.ImportColors(addon.path, fcw[1].PlayerName, allSettings.colors)
				SaveSettings()
			end
			imgui.SameLine()
			AddTooltip('Do not alter the files!', 3, true)
			imgui.EndTabItem()
		end

		----------------------------------------------------------------
		-- Tab: Shortcuts
		----------------------------------------------------------------
		if imgui.BeginTabItem('Shortcuts', nil) then
			imguiWrap.BeginChild('##Shortcuts Child',
				{(setsizex * 3.8 / 3.9) - (12 * (1 - (setsizex * 3.8 / 1920))) - 3, setsizey * 2.7 / 2.8 - 60}, true)

			local letter   = utils.keycodes       [utils.findIndexOfValue(utils.keycodes,        allSettings.shortcutHide ) ][1]
			local letterS  = utils.keycodesSpecial[utils.findIndexOfValue(utils.keycodesSpecial, allSettings.shortcutHideS) ][1]
			local letter2  = utils.keycodes       [utils.findIndexOfValue(utils.keycodes,        allSettings.shortcutTab  ) ][1]
			local letterS2 = utils.keycodesSpecial[utils.findIndexOfValue(utils.keycodesSpecial, allSettings.shortcutTabS ) ][1]
			local letter3  = utils.keycodes       [utils.findIndexOfValue(utils.keycodes,        allSettings.shortcutTab2 ) ][1]
			local letterS3 = utils.keycodesSpecial[utils.findIndexOfValue(utils.keycodesSpecial, allSettings.shortcutTab2S) ][1]
			local letter4  = utils.keycodes       [utils.findIndexOfValue(utils.keycodes,        allSettings.shortcutBig  ) ][1]
			local letterS4 = utils.keycodesSpecial[utils.findIndexOfValue(utils.keycodesSpecial, allSettings.shortcutBigS ) ][1]

			-- Hide shortcut
			imgui.Text('Hide FancyChat Addon')
			AddTooltip('Quickly hide FancyChat temporarily re-enabling the legacy chat.', 0)
			local cposY = imgui.GetCursorPosY()
			imgui.SetCursorPosY(cposY + 5)
			if imgui.Checkbox('Enabled##HideShortcut', {allSettings.shortcutHideEnabled[1]}) then
				allSettings.shortcutHideEnabled[1] = not allSettings.shortcutHideEnabled[1]
				SaveSettings()
			end
			imgui.PushItemWidth(dsize.x / 15)
			if imgui.BeginCombo('##HideShortcutComboS', letterS, ImGuiComboFlags_None) then
				for KC_i = 1, #utils.keycodesSpecial do
					if imgui.Selectable(utils.keycodesSpecial[KC_i][1], letterS == utils.keycodesSpecial[KC_i][1]) then
						allSettings.shortcutHideS = utils.keycodesSpecial[KC_i][2]
						SaveSettings()
					end
				end
			end
			imgui.SameLine()
			if imgui.BeginCombo('##HideShortcutCombo', letter, ImGuiComboFlags_None) then
				for KC_i = 1, #utils.keycodes do
					if utils.keycodes[KC_i][1] ~= letter2 and utils.keycodes[KC_i][1] ~= letter3 and utils.keycodes[KC_i][1] ~= letter4 then
						if imgui.Selectable(utils.keycodes[KC_i][1], letter == utils.keycodes[KC_i][1]) then
							allSettings.shortcutHide = utils.keycodes[KC_i][2]
							SaveSettings()
						end
					end
				end
				imgui.EndCombo()
			end
			imgui.PopItemWidth()

			imgui.Dummy({0, 20})

			-- BigMode shortcut
			imgui.Text('Big Window Mode')
			AddTooltip('Show Window 1 of FancyChat in "Big Mode".', 0)
			if imgui.Checkbox('Enabled##BigShortcut', {allSettings.shortcutBigEnabled[1]}) then
				allSettings.shortcutBigEnabled[1] = not allSettings.shortcutBigEnabled[1]
				SaveSettings()
			end
			imgui.PushItemWidth(dsize.x / 15)
			if imgui.BeginCombo('##BigShortcutComboS', letterS4, ImGuiComboFlags_None) then
				for KC_i = 1, #utils.keycodesSpecial do
					if imgui.Selectable(utils.keycodesSpecial[KC_i][1], letterS4 == utils.keycodesSpecial[KC_i][1]) then
						allSettings.shortcutBigS = utils.keycodesSpecial[KC_i][2]
						SaveSettings()
					end
				end
				imgui.EndCombo()
			end
			imgui.SameLine()
			if imgui.BeginCombo('##BigShortcutCombo', letter4, ImGuiComboFlags_None) then
				for KC_i = 1, #utils.keycodes do
					if utils.keycodes[KC_i][1] ~= letter and utils.keycodes[KC_i][1] ~= letter2 and utils.keycodes[KC_i][1] ~= letter3 then
						if imgui.Selectable(utils.keycodes[KC_i][1], letter4 == utils.keycodes[KC_i][1]) then
							allSettings.shortcutBig = utils.keycodes[KC_i][2]
							SaveSettings()
						end
					end
				end
				imgui.EndCombo()
			end
			imgui.PopItemWidth()

			imgui.Dummy({0, 20})

			-- Tab cycle (window 1) shortcut
			imgui.Text('Scroll Chat Tabs (window 1)')
			cposY = imgui.GetCursorPosY()
			imgui.SetCursorPosY(cposY + 5)
			if imgui.Checkbox('Enabled##TabShortcut', {allSettings.shortcutTabEnabled[1]}) then
				allSettings.shortcutTabEnabled[1] = not allSettings.shortcutTabEnabled[1]
				SaveSettings()
			end
			imgui.PushItemWidth(dsize.x / 15)
			if imgui.BeginCombo('##TabShortcutComboS', letterS2, ImGuiComboFlags_None) then
				for KC_i = 1, #utils.keycodesSpecial do
					if imgui.Selectable(utils.keycodesSpecial[KC_i][1], letterS2 == utils.keycodesSpecial[KC_i][1]) then
						allSettings.shortcutTabS = utils.keycodesSpecial[KC_i][2]
						SaveSettings()
					end
				end
				imgui.EndCombo()
			end
			imgui.SameLine()
			if imgui.BeginCombo('##TabShortcutCombo', letter2, ImGuiComboFlags_None) then
				for KC_i = 1, #utils.keycodes do
					if utils.keycodes[KC_i][1] ~= letter and utils.keycodes[KC_i][1] ~= letter3 and utils.keycodes[KC_i][1] ~= letter4 then
						if imgui.Selectable(utils.keycodes[KC_i][1], letter2 == utils.keycodes[KC_i][1]) then
							allSettings.shortcutTab = utils.keycodes[KC_i][2]
							SaveSettings()
						end
					end
				end
				imgui.EndCombo()
			end
			imgui.PopItemWidth()

			imgui.Dummy({0, 20})

			-- Tab cycle (window 2) shortcut
			imgui.Text('Scroll Chat Tabs (window 2)')
			cposY = imgui.GetCursorPosY()
			imgui.SetCursorPosY(cposY + 5)
			if imgui.Checkbox('Enabled##Tab2Shortcut', {allSettings.shortcutTab2Enabled[1]}) then
				allSettings.shortcutTab2Enabled[1] = not allSettings.shortcutTab2Enabled[1]
				SaveSettings()
			end
			imgui.PushItemWidth(dsize.x / 15)
			if imgui.BeginCombo('##Tab2ShortcutComboS', letterS3, ImGuiComboFlags_None) then
				for KC_i = 1, #utils.keycodesSpecial do
					if imgui.Selectable(utils.keycodesSpecial[KC_i][1], letterS3 == utils.keycodesSpecial[KC_i][1]) then
						allSettings.shortcutTab2S = utils.keycodesSpecial[KC_i][2]
						SaveSettings()
					end
				end
				imgui.EndCombo()
			end
			imgui.SameLine()
			if imgui.BeginCombo('##TabShortcutCombo2', letter3, ImGuiComboFlags_None) then
				for KC_i = 1, #utils.keycodes do
					if utils.keycodes[KC_i][1] ~= letter and utils.keycodes[KC_i][1] ~= letter2 and utils.keycodes[KC_i][1] ~= letter4 then
						if imgui.Selectable(utils.keycodes[KC_i][1], letter2 == utils.keycodes[KC_i][1]) then
							allSettings.shortcutTab2 = utils.keycodes[KC_i][2]
							SaveSettings()
						end
					end
				end
				imgui.EndCombo()
			end
			imgui.PopItemWidth()

			imgui.Dummy({0, 10})
			if imgui.Button('Reset default keys') then
				allSettings.shortcutHide  = 46
				allSettings.shortcutTab   = 45
				allSettings.shortcutTab2  = 48
				allSettings.shortcutBig   = 34
				allSettings.shortcutHideS = 42
				allSettings.shortcutTabS  = 42
				allSettings.shortcutTab2S = 42
				allSettings.shortcutBigS  = 42
			end

			-- Inline command reference
			imgui.Dummy({0, 20})
			imgui.Text('Commands to manually macro features')
			local cmds = {
				{'/fancychat settings', '[Opens/Closes Settings window]'},
				{'/fancychat guideme',  '[Opens/Closes GuideMe window]'},
				{'/fancychat notes',    '[Opens/Closes Notes window]'},
				{'/fancychat compact',  '[Toggles Tabs Compact mode]'},
				{'/fancychat manual',   '[Opens the addon Manual]'},
				{'/fancychat tod',      '[Toggles TOD timestamps]'},
				{'/fancychat ts',       '[Prints a timestamp of the current time]'},
				{'/fancychat savelogs', '[Saves chat logs in the addon folder]'},
			}
			for _, c in ipairs(cmds) do
				imgui.Dummy({0, 5}) imgui.Dummy({3, 0}) imgui.SameLine()
				imgui.Text(c[1])
				imgui.Dummy({23, 0}) imgui.SameLine()
				imgui.Text(c[2])
			end

			imgui.EndChild()
			imgui.EndTabItem()
		end

		----------------------------------------------------------------
		-- Tab: Extra
		----------------------------------------------------------------
		if imgui.BeginTabItem('Extra', nil) then
			imguiWrap.BeginChild('##Extra Child',
				{(setsizex * 3.8 / 3.9) - (12 * (1 - (setsizex * 3.8 / 1920))) - 3, setsizey * 2.7 / 2.8 - 60}, true)

			imgui.Text('Block legacy chat messages')
			AddTooltip('Blocks incoming messages to the legacy chat and only display them on FancyChat. This will block the window resize animation that makes it flicker when new chat messages arrive.', 0)
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('All', {allSettings.blockAll[1]}) then
				allSettings.blockAll[1] = not allSettings.blockAll[1]
				if allSettings.blockAll[1] then
					if not set.Popup[1] then set.Popup[1] = true end
				else
					set.Popup[1] = false
					allSettings.autoDumpChat[1] = false
				end
				SaveSettings()
			end
			if set.Popup[1] then
				AddWarning('While this option has been tested throughfully, it might lead to getting stuck in dialgoues in untested scenarios.\n\nDisable it if you experience such issues.\n\nTo submit chat logs for support tickets, use the "Restore Legacy Chat Logs" function under "Tools" and take a screenshot of the legacy chat!', 350)
			end
			AddTooltip('Disable this if you are experiencing getting stuck in conversations with NPCs', 4, 1)
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Combat (recommended)', {allSettings.blockCombat[1]}) then
				allSettings.blockCombat[1] = not allSettings.blockCombat[1]
				SaveSettings()
			end

			imgui.Dummy({0, 15})
			imgui.Text('Chat message filtering (experimental)')
			AddTooltip('These are meant for quick changes on the fly. Use the in-game filter system first!', 0, 1)
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Hide combat and custom logs from \'All\' tab.', {allSettings.HideCombatFromAll[1]}) then
				allSettings.HideCombatFromAll[1] = not allSettings.HideCombatFromAll[1]
				if allSettings.HideCombatFromAll[1] then
					tab.Tabs[1] = 'AllAlt'
					if allSettings.SelectedTab == 'All' then tab.NextTab = 'AllAlt' end
					if allSettings.SecondChat[1] and allSettings.SelectedTab2 == 'All' then
						tab.NextTab2 = 'AllAlt'
					end
				else
					tab.Tabs[1] = 'All'
					if allSettings.SelectedTab == 'AllAlt' then tab.NextTab = 'All' end
					if allSettings.SecondChat[1] and allSettings.SelectedTab2 == 'AllAlt' then
						tab.NextTab2 = 'All'
					end
				end
				SaveSettings()
			end
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Hide alliance combat log', {allSettings.hideAlliance[1]}) then
				allSettings.hideAlliance[1] = not allSettings.hideAlliance[1]
				if not allSettings.hideAlliance[1] then allSettings.hideNonYou[1] = false end
				SaveSettings()
			end
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Hide non-party combat log', {allSettings.hideNonParty[1]}) then
				allSettings.hideNonParty[1] = not allSettings.hideNonParty[1]
				if not allSettings.hideNonParty[1] then allSettings.hideNonYou[1] = false end
				SaveSettings()
			end
			imgui.Dummy({15, 0}) imgui.SameLine() imgui.Text('L')
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 20)
			imgui.Dummy({27, 0}) imgui.SameLine()
			if imgui.Checkbox('Only show you and your pet logs.', {allSettings.hideNonYou[1]}) then
				allSettings.hideNonYou[1] = not allSettings.hideNonYou[1]
				if allSettings.hideNonYou[1] then allSettings.hideNonParty[1] = true end
				if allSettings.hideNonYou[1] then allSettings.hideAlliance[1] = true end
				SaveSettings()
			end

			imgui.Dummy({0, 5})
			imgui.Text('Other settings')
			AddTooltip('Read the manual for more detailed info', 0)
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Compact Combat Log', {allSettings.CompactCombat[1]}) then
				allSettings.CompactCombat[1] = not allSettings.CompactCombat[1]
				SaveSettings()
			end
			AddTooltip('Disable if you have other addons such as simplelog enabled.', 4)
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Timestamp', {allSettings.timeStamp[1]}) then
				allSettings.timeStamp[1] = not allSettings.timeStamp[1]
				if allSettings.timeStamp[1] then allSettings.timeStampLine[1] = false end
				SaveSettings()
			end
			imgui.Dummy({15, 0}) imgui.SameLine() imgui.Text('L')
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 18)
			imgui.Dummy({30, 0}) imgui.SameLine()
			imgui.Text('Format')
			imgui.SameLine()
			local formats = {'[00:00:00]', '[00:00]'}
			local currentFormat = formats[allSettings.FormatTSMode]
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 3)
			imgui.PushItemWidth(dsize.x / 15)
			if imgui.BeginCombo('##TimestampFormat', currentFormat, ImGuiComboFlags_None) then
				if imgui.Selectable(formats[1], currentFormat == formats[1]) then allSettings.FormatTSMode = 1 end
				if imgui.Selectable(formats[2], currentFormat == formats[2]) then allSettings.FormatTSMode = 2 end
				SaveSettings()
				imgui.EndCombo()
			end
			imgui.PopItemWidth()
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Timestamp as a line', {allSettings.timeStampLine[1]}) then
				allSettings.timeStampLine[1] = not allSettings.timeStampLine[1]
				if allSettings.timeStampLine[1] then allSettings.timeStamp[1] = false end
				SaveSettings()
			end
			imgui.Dummy({15, 0}) imgui.SameLine() imgui.Text('L')
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 18)
			imgui.Dummy({30, 0}) imgui.SameLine()
			imgui.Text('Every')
			imgui.SameLine()
			local minutes = {{'1 minute', 60}, {'5 minutes', 300}, {'10 minutes', 600}, {'30 minutes', 1800}, {'60 minutes', 3600}}
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 3)
			imgui.PushItemWidth(dsize.x / 15)
			if imgui.BeginCombo('##TimeStampLineFreq', allSettings.timeStampLineFreq[1], ImGuiComboFlags_None) then
				for TS_i = 1, #minutes do
					if imgui.Selectable(minutes[TS_i][1]) then
						allSettings.timeStampLineFreq = minutes[TS_i]
						SaveSettings()
					end
				end
				imgui.EndCombo()
			end
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Warning messages on R0s', {allSettings.R0warning[1]}) then
				allSettings.R0warning[1] = not allSettings.R0warning[1]
				SaveSettings()
			end
			AddTooltip('Shows a warning messagee in chat when you R0 (possible disconnection happening).', 4)
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Precise TOD Timestamps', {allSettings.PreciseTS[1]}) then
				allSettings.PreciseTS[1] = not allSettings.PreciseTS[1]
				SaveSettings()
			end
			AddTooltip('Shows timestamps, precise to the second, next to \'defeat mob\' messages.', 4)
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Incoming /tell notifications', {allSettings.tellNotification[1]}) then
				allSettings.tellNotification[1] = not allSettings.tellNotification[1]
				SaveSettings()
			end
			AddTooltip('Plays a notification sound of choice when an incoming Tell message is received.', 4)
			imgui.Dummy({15, 0}) imgui.SameLine() imgui.Text('L')
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 20)
			imgui.Dummy({27, 0}) imgui.SameLine()
			imgui.PushItemWidth(dsize.x / 8)
			if imgui.BeginCombo('##NotificationShould', allSettings.selectedNotification, ImGuiComboFlags_None) then
				for NS_i = 1, 6 do
					if imgui.Selectable('notification_'..tostring(NS_i)) then
						allSettings.selectedNotification = 'notification_'..tostring(NS_i)
						SaveSettings()
					end
				end
				imgui.EndCombo()
			end
			imgui.PopItemWidth()
			imgui.SameLine()
			if imgui.ArrowButton('PlayNotification', ImGuiDir_Right) then
				ashita.misc.play_sound(string.format('%s\\notifications\\%s%s.wav',
					addon.path, allSettings.selectedNotification, allSettings.boostNotification[1] and 'B' or ''))
			end
			imgui.SameLine()
			imgui.Text('Play!')
			imgui.Dummy({15, 0}) imgui.SameLine() imgui.Text('L')
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 20)
			imgui.Dummy({27, 0}) imgui.SameLine()
			if imgui.Checkbox('Volume Boost', {allSettings.boostNotification[1]}) then
				allSettings.boostNotification[1] = not allSettings.boostNotification[1]
				SaveSettings()
			end
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Chat word alert', {allSettings.Alert[1]}) then
				allSettings.Alert[1] = not allSettings.Alert[1]
				SaveSettings()
			end
			AddTooltip('Plays a notification sound of choice when one of the alert words appears in a message.', 4)
			imgui.Dummy({15, 0}) imgui.SameLine() imgui.Text('L')
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 18)
			imgui.Dummy({30, 0}) imgui.SameLine()
			imgui.Text('Alert words') imgui.SameLine()
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 2)
			imgui.PushItemWidth(dsize.x / 10)
			imgui.InputText('##AlertWords', set.alertBuffer, 255,
				bit.bor(ImGuiInputTextFlags_CharsNoBlank, ImGuiInputTextFlags_CallbackAlways),
				function()
					allSettings.alertwords = set.alertBuffer[1]:gsub('\0', '')
					set.alertList = utils.stringsplit(allSettings.alertwords, ',')
					SaveSettings()
				end)
			imgui.SameLine()
			AddTooltip('Separate words with commas. Case insensitive.', 4)
			imgui.Dummy({15, 0}) imgui.SameLine() imgui.Text('L')
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 20)
			imgui.Dummy({27, 0}) imgui.SameLine()
			imgui.PushItemWidth(dsize.x / 8)
			if imgui.BeginCombo('##AlertShould', allSettings.selectedAlert, ImGuiComboFlags_None) then
				for AS_i = 1, 6 do
					if imgui.Selectable('notification_'..tostring(AS_i)) then
						allSettings.selectedAlert = 'notification_'..tostring(AS_i)
						SaveSettings()
					end
				end
				imgui.EndCombo()
			end
			imgui.PopItemWidth()
			imgui.SameLine()
			if imgui.ArrowButton('PlayAlert', ImGuiDir_Right) then
				ashita.misc.play_sound(string.format('%s\\notifications\\%s%s.wav',
					addon.path, allSettings.selectedAlert, allSettings.boostAlert[1] and 'B' or ''))
			end
			imgui.SameLine()
			imgui.Text('Play!')
			imgui.Dummy({15, 0}) imgui.SameLine() imgui.Text('L')
			imgui.SetCursorPosY(imgui.GetCursorPosY() - 20)
			imgui.Dummy({27, 0}) imgui.SameLine()
			if imgui.Checkbox('Volume Boost##Alert', {allSettings.boostAlert[1]}) then
				allSettings.boostAlert[1] = not allSettings.boostAlert[1]
				SaveSettings()
			end
			if allSettings.Alert[1] then
				imgui.Dummy({15, 0}) imgui.SameLine() imgui.Text('L')
				imgui.SetCursorPosY(imgui.GetCursorPosY() - 18)
				imgui.Dummy({30, 0}) imgui.SameLine()
				imgui.Text('Checked channels')
				local channels = {'Say', 'Shout', 'Party', 'Linkshell', 'Unity'}
				for c_i = 1, 5 do
					imgui.Dummy({0, 5})
					imgui.Dummy({30, 0}) imgui.SameLine()
					if imgui.Checkbox(channels[c_i], {allSettings.alertOptions[c_i]}) then
						allSettings.alertOptions[c_i] = not allSettings.alertOptions[c_i]
						SaveSettings()
					end
				end
			end

			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Preview Items/Abilities/Spells on mouse hover', {allSettings.ItemPreview[1]}) then
				allSettings.ItemPreview[1] = not allSettings.ItemPreview[1]
				SaveSettings()
			end
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Auto-restore logs when opening Legacy Chat', {allSettings.autoDumpChat[1]}) then
				if not allSettings.autoDumpChat[1] and allSettings.blockAll[1] then
					allSettings.autoDumpChat[1] = true
				elseif allSettings.autoDumpChat[1] then
					allSettings.autoDumpChat[1] = false
				end
				SaveSettings()
			end
			AddTooltip('Available when Block All Messages from Legacy Chat is enabled.\nAutomatically restores chat messages in the Legacy Chat upon opening it.', 4)
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Colorblind mode for damage done/taken text', {allSettings.ColorBlind[1]}) then
				allSettings.ColorBlind[1] = not allSettings.ColorBlind[1]
				SaveSettings()
			end
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Fast scroll chat history', {allSettings.EnableFastScroll[1]}) then
				allSettings.EnableFastScroll[1] = not allSettings.EnableFastScroll[1]
				SaveSettings()
			end
			AddTooltip('While scrolling the chat and hovering the chat window, use [Shift] + [<] or [>] to quickly scroll the history more than one line at the time.', 4)
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Dock GuideMe/Notes on the second chat window', {allSettings.GuideMeSecondWindow[1]}) then
				if allSettings.SecondChat[1] then
					allSettings.GuideMeSecondWindow[1] = not allSettings.GuideMeSecondWindow[1]
					SaveSettings()
				end
			end
			AddTooltip('Requires second chat window enabled.', 4)
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Enable FC color marking', {allSettings.EnableFCColorMarking[1]}) then
				allSettings.EnableFCColorMarking[1] = not allSettings.EnableFCColorMarking[1]
				SaveSettings()
			end
			AddTooltip('Uses and FC color formatting (Recommended). Disable to try use default color markings.', 4)
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox(allSettings.heartEmoji[1] and ' <3' or ' ', {allSettings.heartEmoji[1]}) then
				allSettings.heartEmoji[1] = not allSettings.heartEmoji[1]
				SaveSettings()
			end

			imgui.EndChild()
			imgui.EndTabItem()
		end

		----------------------------------------------------------------
		-- Tab: CL Filters
		----------------------------------------------------------------
		if imgui.BeginTabItem('CL Filters', nil) then
			imguiWrap.BeginChild('##Filters Child',
				{(setsizex * 3.8 / 3.9) - (12 * (1 - (setsizex * 3.8 / 1920))) - 3, setsizey * 2.7 / 2.8 - 60}, true)
			imgui.PushTextWrapPos(imgui.GetWindowWidth() * 0.96)
			imgui.TextWrapped('You can filter combat messages by editing the custom_combat_filters file and using words that would appear in unwanted messages.\n(e.g. effect wears off)\n\n> Words must be present in the original game combat message\n  (i.e. not words modified by addons)\n> Word matching is non case sensitive\n> More details in the custom_combat_filters file\n\n!!! Very long lists could cause performance issues !!!')
			imgui.Dummy({0, 5})
			if imgui.Button('Edit Custom Filters') then
				local filepath = addon.path..'\\custom_combat_filters.txt'
				os.execute('start "" "'..filepath..'"')
			end
			if imgui.Button('Reload Custom Filters') then
				par.customFilters = utils.LoadCustomFilters()
			end
			imgui.Separator()
			imgui.Dummy({0, 5})
			if imgui.Checkbox('Enable Combat Log chat filters', {allSettings.CustomFilters[1]}) then
				allSettings.CustomFilters[1] = not allSettings.CustomFilters[1]
				SaveSettings()
			end
			imgui.Dummy({0, 5})

			if allSettings.CustomFilters[1] then
				imgui.Text('Current Combat Log Filters:')
				if imgui.BeginTable('resultTable', 2,
					bit.bor(ImGuiTableFlags_RowBg, ImGuiTableFlags_BordersH, ImGuiTableFlags_BordersV, ImGuiTableFlags_ContextMenuInBody)) then
					imgui.TableSetupColumn('Filter',     ImGuiTableColumnFlags_WidthFixed,   imgui.GetWindowWidth() * 0.7, 0)
					imgui.TableSetupColumn('Applied to', ImGuiTableColumnFlags_WidthStretch, 0, 0)
					imgui.TableHeadersRow()
					for cf = 1, #par.customFilters do
						imgui.TableNextRow()
						imgui.TableSetColumnIndex(0)
						imgui.PushTextWrapPos(imgui.GetWindowWidth() * 0.7)
						imgui.TextWrapped(par.customFilters[cf][1]:replace('%', '%%'))
						imgui.PopTextWrapPos()
						imgui.TableSetColumnIndex(1)
						local cf_scope = ''
						if par.customFilters[cf][2] then
							if     par.customFilters[cf][2] == '_z' then cf_scope = cf_scope + 'All'
							elseif par.customFilters[cf][2] == '_y' then cf_scope = cf_scope + 'All but you'
							elseif par.customFilters[cf][2] == '_p' then cf_scope = cf_scope + 'All but party' end
						end
						imgui.PushTextWrapPos(imgui.GetWindowWidth() * 0.9)
						imgui.TextWrapped(cf_scope)
						imgui.PopTextWrapPos()
					end
					imgui.PopTextWrapPos()
					imgui.EndTable()
				end
			end

			imgui.EndChild()
			imgui.EndTabItem()
		end

		----------------------------------------------------------------
		-- Tab: Tools
		----------------------------------------------------------------
		if imgui.BeginTabItem('Tools', nil) then
			imguiWrap.BeginChild('##Tools Child',
				{(setsizex * 3.8 / 3.9) - (12 * (1 - (setsizex * 3.8 / 1920))) - 3, setsizey * 2.7 / 2.8 - 60}, true)

			-- Save Chat Logs
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if fcw[1].TextureIDLogs ~= nil and fcw[1].TextureIDLoading ~= nil then
				if imguiWrap.ImageButton('TextureIDLogs',
					fcw[1].SaveStart == 0 and fcw[1].TextureIDLogs or fcw[1].TextureIDLoading,
					{dsize.x / 100, dsize.x / 100}, {-0.01, -0.01}, {1.01, 1.01},
					-1, {0, 0, 0, 0}, {1, 1, 1, 1}) then
					if fcw[1].SaveStart == 0 then
						fcw[1].SaveStart = os.clock() - fcw[1].SaveStart
						AshitaCore:GetChatManager():QueueCommand(-1, '/fancychat savelogs')
					end
				end
			end
			if os.clock() - fcw[1].SaveStart > fcw[1].SaveCD then
				fcw[1].SaveStart = 0
			end
			imgui.SameLine()
			imgui.SetCursorPosY(imgui.GetCursorPosY() + dsize.x / 300)
			if fcw[1].SaveStart > 0 then imgui.Text('Saving...') else imgui.Text('Save Chat Logs') end

			-- Open Logs Folder
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if fcw[1].TextureIDFolder ~= nil then
				if imguiWrap.ImageButton('TextureIDFolder', fcw[1].TextureIDFolder,
					{dsize.x / 100, dsize.x / 100}, {-0.01, -0.01}, {1.01, 1.01},
					-1, {0, 0, 0, 0}, {1, 1, 1, 1}) then
					os.execute('mkdir '..addon.path..'logs\\'..fcw[1].PlayerName)
					os.execute('start "" "'..addon.path..'logs\\'..fcw[1].PlayerName..'"')
				end
			end
			imgui.SameLine()
			imgui.SetCursorPosY(imgui.GetCursorPosY() + dsize.x / 300)
			imgui.Text('Open Logs Folder')

			-- Open Manual
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if fcw[1].TextureIDManual ~= nil then
				if imguiWrap.ImageButton('TextureIDManual', fcw[1].TextureIDManual,
					{dsize.x / 100, dsize.x / 100}, {0.01, 0.01}, {0.99, 0.99},
					-1, {0, 0, 0, 0}, {1, 1, 1, 1}) then
					help.opened[1] = not help.opened[1]
				end
			end
			imgui.SameLine()
			imgui.SetCursorPosY(imgui.GetCursorPosY() + dsize.x / 300)
			imgui.Text('Open Manual')

			-- Restore Legacy Chat Logs (DumpChat)
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if fcw[1].TextureIDDumpchat ~= nil then
				if imguiWrap.ImageButton('TextureIDDumpchat', fcw[1].TextureIDDumpchat,
					{dsize.x / 100, dsize.x / 100}, {0.05, 0.01}, {0.98, 1.0},
					-1, {0, 0, 0, 0}, {1, 1, 1, 1}) then
					DumpChat('-------------- Chat restored --------------')
					b.OriginalBuffer = T{}
				end
			end
			imgui.SameLine()
			imgui.SetCursorPosY(imgui.GetCursorPosY() + dsize.x / 300)
			imgui.Text('Restore Legacy Chat Logs')
			AddTooltip('Use this to restore chat logs in the legacy chat window. Use this to take chat log screenshots to submit for support tickets', 0, 1)

			imgui.EndChild()
			imgui.EndTabItem()
		end

		imgui.EndTabBar()
	end

	imgui.End()
	PopWindowStyle()
end

return M
