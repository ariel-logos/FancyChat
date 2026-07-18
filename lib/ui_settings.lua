-- lib/ui_settings.lua — Settings tabbed window.  Six tabs: Chat
-- Window, Font Colors, Shortcuts, Extra, CL Filters, Tools.

require('common')
local imgui     = require('imgui')
local imguiWrap = require('imguiWrap')
local utils     = require('utils')
local help      = require('help')
local state     = require('lib.state')

local fcw            = state.fcw
local tab            = state.tab
local set            = state.set
local par            = state.par
local b              = state.b
local allSettings    = state.allSettings
local defaultColors  = state.defaultColors
local colorDesc      = state.colorDesc
local gamepadButtons = state.gamepadButtons

local M = {}

-- Module-level cache of the filters/<kind>/ directory listing,
-- keyed by kind ('combat' / 'other').  Populated lazily on the first
-- frame each Filters sub-tab is drawn so the dir scan doesn't run
-- every frame.  The "Refresh" button next to each picker re-scans
-- its own kind on demand.
local cachedFilterFiles = { combat = nil, other = nil }

function M.draw_settings_panel()

	-- When the panel is closed, sync the persisted values back into
	-- the `set.*` working copy so the next open shows the current
	-- state and not stale pending edits.
	if not allSettings.settingsOpened[1] then
		set.SecondChat[1]        = allSettings.SecondChat[1]
		set.ChatLineMaxL         = allSettings.chatLineMaxL
		set.PlateBGColor         = allSettings.rectSettings.fill_color
		set.FontHeight           = allSettings.fontSettings.font_height
		set.InstantChatScroll[1] = allSettings.InstantChatScroll[1]
		set.SplitLinkshellTab[1] = allSettings.SplitLinkshellTab[1]
		for ct = 1, #allSettings.CustomTabModes do
			set.CustomTabModes[ct] = allSettings.CustomTabModes[ct]
		end
		set.ChatLines = allSettings.ChatLines
		-- Drop any pending gamepad-binding listen when the panel is
		-- closed - otherwise the user could walk away from Settings
		-- with a listen still armed and accidentally rebind an action
		-- by pressing a controller button.
		gamepadButtons.listenKey = nil
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

			-- Decode the persisted ARGB into a {0..1} alpha float plus
			-- a {r,g,b} float triple so two widgets can edit them
			-- independently.  Both writes flow through `recompose` at
			-- the bottom of the block so the channels they don't own
			-- are preserved.
			local plateBGcolor = set.PlateBGColor
			local plateBGAlpha = T{tonumber(bit.rshift(plateBGcolor, 24)) / 255}
			local plateBGRGB   = T{
				bit.band(bit.rshift(plateBGcolor, 16), 0xFF) / 255,
				bit.band(bit.rshift(plateBGcolor,  8), 0xFF) / 255,
				bit.band(plateBGcolor,                 0xFF) / 255,
			}
			local plateBGchanged = false

			cposY = imgui.GetCursorPosY()
			cposX = imgui.GetCursorPosX()
			imgui.SetCursorPosY(cposY + 10)
			imgui.Text('Plate BG Opacity')
			imgui.SameLine()
			imgui.SetCursorPosY(cposY + 7)
			imgui.SetCursorPosX((dsize.x / 4.3 - dsize.x / 8) * (1920 / dsize.x))
			if imgui.SliderFloat('##plateBGAlphaSlider', plateBGAlpha, 0, 1.0, '%.2f',
				bit.bor(ImGuiSliderFlags_AlwaysClamp, ImGuiSliderFlags_NoRoundToFormat)) then
				plateBGchanged = true
			end

			-- Background colour picker.  ColorButton renders just the
			-- swatch; clicking it opens our own modal-style popup that
			-- holds the full ColorPicker3 + an explicit Done button to
			-- dismiss it (Escape doesn't reliably close ImGui popups on
			-- the Ashita 4.30 binding, so click-outside or Done are the
			-- only ways out).  Alpha is handled by the slider on the
			-- row above, hence NoAlpha on both widgets.
			cposY = imgui.GetCursorPosY()
			imgui.SetCursorPosY(cposY + 10)
			imgui.Text('Plate BG Color')
			imgui.SameLine()
			imgui.SetCursorPosY(cposY + 7)
			imgui.SetCursorPosX((dsize.x / 4.3 - dsize.x / 8) * (1920 / dsize.x))
			local swatchColor = T{plateBGRGB[1], plateBGRGB[2], plateBGRGB[3], 1.0}
			if imgui.ColorButton('##plateBGSwatch', swatchColor,
				ImGuiColorEditFlags_NoAlpha, {dsize.x / 7.5, 20}) then
				imgui.OpenPopup('##plateBGColorPopup')
			end
			if imgui.BeginPopup('##plateBGColorPopup') then
				if imgui.ColorPicker3('##plateBGColorPickerWidget', plateBGRGB,
					bit.bor(ImGuiColorEditFlags_NoLabel,
					        ImGuiColorEditFlags_NoAlpha)) then
					plateBGchanged = true
				end
				imgui.Separator()
				if imgui.Button('Confirm##plateBGColorConfirm', {-1, 0}) then
					imgui.CloseCurrentPopup()
				end
				imgui.EndPopup()
			end

			if plateBGchanged then
				set.PlateBGColor = bit.bor(
					bit.lshift(bit.tobit(plateBGAlpha[1] * 255), 24),
					bit.lshift(bit.tobit(plateBGRGB[1]   * 255), 16),
					bit.lshift(bit.tobit(plateBGRGB[2]   * 255),  8),
					bit.tobit(plateBGRGB[3] * 255))
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
			-- Linkshell row mirrors the tab itself: with split off the
			-- user sees the single LS checkbox driving slot [2]; with
			-- split on they see independent L1 / L2 checkboxes driving
			-- slots [6] / [7].  The parser only consults the slot(s)
			-- relevant to the active split state.
			if set.SplitLinkshellTab[1] then
				if imgui.Checkbox('L1',   {set.CustomTabModes[6]}) then set.CustomTabModes[6] = not set.CustomTabModes[6] end imgui.SameLine()
				if imgui.Checkbox('L2',   {set.CustomTabModes[7]}) then set.CustomTabModes[7] = not set.CustomTabModes[7] end imgui.SameLine()
			else
				if imgui.Checkbox('LS',   {set.CustomTabModes[2]}) then set.CustomTabModes[2] = not set.CustomTabModes[2] end imgui.SameLine()
			end
			if imgui.Checkbox('Shout',{set.CustomTabModes[5]}) then set.CustomTabModes[5] = not set.CustomTabModes[5] end

			imgui.Dummy({0, 10})
			if imgui.Checkbox('Instant new line (skip scroll animation)##InstantChatScroll', {set.InstantChatScroll[1]}) then
				set.InstantChatScroll[1] = not set.InstantChatScroll[1]
			end
			AddTooltip('When on, new chat lines appear immediately at the bottom instead of sliding up. Useful on busy combat logs or low-FPS setups. Applies on next addon restart.', 4)

			imgui.Dummy({0, 5})
			if imgui.Checkbox('Split Linkshell tab into L1 / L2##SplitLinkshellTab', {set.SplitLinkshellTab[1]}) then
				set.SplitLinkshellTab[1] = not set.SplitLinkshellTab[1]
				-- Migrate the Custom-tab LS membership across the
				-- split / no-split transition so the checkboxes the
				-- user is about to see reflect a sensible default:
				--   OFF -> ON : LS=true expands into both L1+L2; LS
				--               slot is cleared.
				--   ON  -> OFF: both L1+L2 collapse into LS=true; if
				--               only one (or neither) was on, LS
				--               defaults to false per spec.  L1/L2
				--               slots are cleared either way.
				if set.SplitLinkshellTab[1] then
					if set.CustomTabModes[2] then
						set.CustomTabModes[6] = true
						set.CustomTabModes[7] = true
					else
						set.CustomTabModes[6] = false
						set.CustomTabModes[7] = false
					end
					set.CustomTabModes[2] = false
				else
					if set.CustomTabModes[6] and set.CustomTabModes[7] then
						set.CustomTabModes[2] = true
					else
						set.CustomTabModes[2] = false
					end
					set.CustomTabModes[6] = false
					set.CustomTabModes[7] = false
				end
			end
			AddTooltip('When on, the Linkshell tab is replaced by two separate L1 / L2 tabs. LS1 traffic routes to L1, LS2 traffic routes to L2. Either tab can be independently selected on each chat window. Applies on next addon restart.', 4)

			imgui.Dummy({0, 5})
			if imgui.Button('Reset default values') then
				set.ChatLineMaxL         = 100
				set.PlateBGColor         = bit.lshift(bit.tobit(0.3 * 255), 24)
				set.FontHeight           = 20
				set.ChatLines            = 8
				set.SecondChat[1]        = false
				set.InstantChatScroll[1] = false
				set.SplitLinkshellTab[1] = false
				set.CustomTabModes       = T{false, false, false, false, false, false, false}
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
				allSettings.InstantChatScroll[1]     = set.InstantChatScroll[1]
				allSettings.SplitLinkshellTab[1]     = set.SplitLinkshellTab[1]
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
			if imgui.Checkbox('Keep FancyChat visible while legacy chat is open##ShowWithLegacy', {allSettings.ShowWithLegacy[1]}) then
				allSettings.ShowWithLegacy[1] = not allSettings.ShowWithLegacy[1]
				SaveSettings()
			end
			AddTooltip('When off (default), FancyChat hides itself the moment you click on the legacy FFXI chat or open the chat input. When on, both windows stay visible side by side.', 4)
			imgui.Dummy({0, 5})
			if imgui.Checkbox('Show help (i) hover button on the first chat window##HelpButton', {allSettings.HelpButton[1]}) then
				allSettings.HelpButton[1] = not allSettings.HelpButton[1]
				SaveSettings()
			end
			AddTooltip('Toggles the small (?) icon at the top-left corner of the first chat window. Hovering it shows a quick reference of built-in mouse / keyboard interactions.', 4)
			imgui.Dummy({0, 5})
			if imgui.Checkbox('Compact tabs in the bottom-left corner##ComapctBL', {allSettings.CompactTabsBL[1]}) then
				allSettings.CompactTabsBL[1] = not allSettings.CompactTabsBL[1]
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
			-- Sort by the human-readable label from colorDesc (the [1]
			-- field of each entry in defaults.color_descriptions) so the
			-- left-pane row order matches what the user actually reads,
			-- not the underlying internal key.  Falls back to the raw key
			-- if a color slot is missing a description entry.
			table.sort(keys, function(a, b)
				local la = colorDesc[a] and colorDesc[a][1] or a
				local lb = colorDesc[b] and colorDesc[b][1] or b
				return la < lb
			end)
			local skip = {'combat', 'combatspell'}
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
				-- Mutex: opening Export closes Import.
				set.colorIO.importOpen      = false
				-- (Re-)open: hard-regenerate the suggested filename.
				set.colorIO.exportOpen      = true
				set.colorIO.exportName[1]   = utils.NextColorsetName(addon.path, fcw[1].PlayerName)
			end
			imgui.SameLine()
			if imgui.Button('Import Colors') then
				set.colorIO.exportOpen      = false
				set.colorIO.importOpen      = true
				set.colorIO.importFiles     = utils.ListColorsetFiles(addon.path)
				set.colorIO.importSelected  = 0
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
				imgui.EndCombo()
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
				{'/fancychat bigmode',  '[Toggles the BigMode overlay]'},
				{'/fancychat tod',      '[Toggles TOD timestamps]'},
				{'/fancychat ts',       '[Prints a timestamp of the current time]'},
				{'/fancychat savelogs', '[Saves chat logs in the addon folder]'},
				--{'/fancychat debug',    '[Opens the developer debug window]'},   -- debug_window disabled
			}
			for _, c in ipairs(cmds) do
				imgui.Dummy({0, 5}) imgui.Dummy({3, 0}) imgui.SameLine()
				imgui.Text(c[1])
				imgui.Dummy({23, 0}) imgui.SameLine()
				imgui.Text(c[2])
			end

			-- Built-in (non-configurable) mouse + keyboard interactions
			-- baked into the chat windows.  Distinct from the
			-- configurable shortcuts above — these are hard-coded
			-- behaviors users may not know exist.  Same [Name]\n* keys
			-- pattern as before for visual consistency.
			imgui.Dummy({0, 20})
			imgui.Text('Other Interactions')
			local interactions = {
				{'Copy chat line to clipboard',         'Left-Click on a chat line'},
				{'Open URL in browser',                 'Left-Click on a [link] tag'},
				{'Open zone map / search popup',        'Ctrl + Left-Click on a chat line containing a zone name'},
				{'Save chat line to Notepad',           'Shift + Left-Click on a chat line  (max 10 notes)'},
				{'Reposition chat window',              'Left-Click + Drag on the chat plate'},
				{'Jump to bottom of chat (reset scroll)', 'Right-Click anywhere'},
				{'Scroll chat history',                 'Mouse Wheel'},
				{'Fast scroll (5 lines per tick)',      'Shift + Mouse Wheel'},
				{'Reveal Settings icon on compact bar', 'Hold Shift while hovering the compact-tab expand icon'},
				{'Dismiss zone map / search popup',     'Click outside the popup, or press Escape'},
			}
			for _, s in ipairs(interactions) do
				imgui.Dummy({0, 8})
				imgui.Dummy({3, 0}) imgui.SameLine()
				imgui.Text('['..s[1]..']')
				imgui.Dummy({0, 4})
				imgui.Dummy({3, 0}) imgui.SameLine()
				imgui.Text('- '..s[2])
			end

			imgui.EndChild()
			imgui.EndTabItem()
		end

		----------------------------------------------------------------
		-- Tab: Gamepad
		----------------------------------------------------------------
		if imgui.BeginTabItem('Gamepad', nil) then
			imguiWrap.BeginChild('##Gamepad Child',
				{(setsizex * 3.8 / 3.9) - (12 * (1 - (setsizex * 3.8 / 1920))) - 3, setsizey * 2.7 / 2.8 - 60}, true)

			-- Resolve an XInput button id (e.g. 12) to a label for the
			-- UI.  In Xbox-controller mode we look up the friendly name
			-- ('A', 'LB', 'RT', ...) from utils.gamepadButtonList; in
			-- generic mode (default) we just show the raw button index,
			-- because non-Xbox pads map physical buttons to different
			-- XInput numbers than an Xbox pad would.
			local function gp_label_for(id)
				if allSettings.XboxController[1] then
					local idx = utils.findIndexOfValue(utils.gamepadButtonList, id)
					if idx then return utils.gamepadButtonList[idx][1] end
				end
				return tostring(id)
			end

			-- Place the info icon at a column past the widest row label,
			-- measured at runtime via CalcTextSize so the position is
			-- correct regardless of the active font (gdifonts, scale,
			-- etc.).  Falls back to a generous fixed minimum if the
			-- measurement returns 0 for any reason.
			local longest_gp_label = 'Modifier (hold to enable navigation)'
			local label_w          = imgui.CalcTextSize(longest_gp_label)
			local GP_TOOLTIP_X     = math.max((label_w or 0) + 20, 320)

			local function gp_inline_tooltip(message)
				imgui.SameLine(GP_TOOLTIP_X)
				imguiWrap.Image(fcw[1].TextureIDInfo, {15, 15})
				if imgui.IsItemHovered(0) then
					imgui.SetTooltip(utils.breakLine(message, 40))
				end
			end

			-- Draw one row: text label + a "listen" button showing the
			-- current binding.  Clicking the button arms a one-shot
			-- gamepad capture (handled in lib/input.lua's xinput_button
			-- callback); the very next button press becomes the new
			-- binding.  Clicking the same button again - or pressing
			-- Escape - cancels.  If the captured button was already
			-- bound to another action, the two actions swap.
			--
			-- color (optional) is an {r,g,b,a} table; when set the
			-- label is drawn via TextColored, used to highlight the
			-- Modifier row (the gate that has to be held for every
			-- other binding to fire).
			local function draw_gp_row(label, key, tooltip, color)
				if color then
					imgui.TextColored(color, label)
				else
					imgui.Text(label)
				end
				if tooltip then gp_inline_tooltip(tooltip) end
				local is_listen = (gamepadButtons.listenKey == key)
				local btn_text  = is_listen
					and '(press a gamepad button - Esc to cancel)'
					or  gp_label_for(allSettings.GamepadBindings[key])
				-- Highlight the active row so it's obvious which one
				-- is waiting for input.
				if is_listen then
					imgui.PushStyleColor(ImGuiCol_Button,        {0.55, 0.35, 0.10, 1.0})
					imgui.PushStyleColor(ImGuiCol_ButtonHovered, {0.65, 0.45, 0.15, 1.0})
					imgui.PushStyleColor(ImGuiCol_ButtonActive,  {0.75, 0.55, 0.20, 1.0})
				end
				if imgui.Button(btn_text..'##GP_'..key, {dsize.x / 6, 0}) then
					if is_listen then
						gamepadButtons.listenKey = nil
					else
						gamepadButtons.listenKey = key
					end
				end
				if is_listen then imgui.PopStyleColor(3) end
				imgui.Dummy({0, 8})
			end

			-- Top-of-tab toggles: master enable + label style.
			if imgui.Checkbox('Enable Gamepad Chat Navigation##GamepadNav', {allSettings.GamepadNav[1]}) then
				allSettings.GamepadNav[1] = not allSettings.GamepadNav[1]
				SaveSettings()
			end
			AddTooltip('Master switch for gamepad input. When off, none of the bindings below fire in-game and the modifier button is ignored.', 4)
			imgui.Dummy({0, 5})
			if imgui.Checkbox('Xbox Controller##XboxLabels', {allSettings.XboxController[1]}) then
				allSettings.XboxController[1] = not allSettings.XboxController[1]
				SaveSettings()
			end
			AddTooltip('When on, buttons are labelled with their Xbox names (A, B, LB, RT, ...). When off, buttons are labelled with their raw XInput index - safer for non-Xbox controllers whose physical layout maps to different XInput numbers.', 4)
			imgui.Dummy({0, 15})

			imgui.Text('Gamepad button bindings')
			AddTooltip('Click a binding to listen for the next gamepad button press. If the chosen button is already used by another action, the two actions swap. Stick scroll axes are not remappable.', 0)
			imgui.Dummy({0, 4})
			imgui.TextColored({0.70, 0.70, 0.70, 1.0},
				'Click a button on the right side of a row, then press the')
			imgui.TextColored({0.70, 0.70, 0.70, 1.0},
				'controller button you want to assign.  Esc cancels.')
			imgui.Dummy({0, 10})

			draw_gp_row('Modifier (hold to enable navigation)', 'modifier',
				'While held, the other gamepad bindings below become active. All other buttons are blocked from the rest of the game during this time.',
				{1.00, 0.65, 0.20, 1.0})
			draw_gp_row('Cycle tabs (window 1)',     'cyclePrimaryTab')
			draw_gp_row('Cycle tabs (window 2)',     'cycleSecondaryTab')
			draw_gp_row('Snap chat to bottom',       'snapToBottom')
			draw_gp_row('Toggle BigMode overlay',    'toggleBigMode')
			draw_gp_row('Open FFXI chat input',      'openChatInput')
			draw_gp_row('Submit input as command',   'submitInput',
				'Sends the line currently in the FFXI chat input box.')
			draw_gp_row('Command history: previous', 'historyPrev')
			draw_gp_row('Command history: next',     'historyNext')
			draw_gp_row('Preset command: previous',  'presetPrev')
			draw_gp_row('Preset command: next',      'presetNext')

			imgui.Dummy({0, 6})
			if imgui.Button('Reset to defaults##GPReset') then
				allSettings.GamepadBindings.modifier          = 8
				allSettings.GamepadBindings.cyclePrimaryTab   = 9
				allSettings.GamepadBindings.cycleSecondaryTab = 17
				allSettings.GamepadBindings.snapToBottom      = 13
				allSettings.GamepadBindings.toggleBigMode     = 15
				allSettings.GamepadBindings.openChatInput     = 14
				allSettings.GamepadBindings.submitInput       = 12
				allSettings.GamepadBindings.historyPrev       = 0
				allSettings.GamepadBindings.historyNext       = 1
				allSettings.GamepadBindings.presetPrev        = 2
				allSettings.GamepadBindings.presetNext        = 3
				SaveSettings()
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
			-- Filter mode selector.  Text-based = the three legacy
			-- boolean toggles that use name-matching in the parser;
			-- Packet-based = the 0x0028-driven hierarchy that's
			-- mutually exclusive with the text-based system.  Picking
			-- one hides the other's controls below.
			imgui.Dummy({0, 8})
			imgui.Dummy({5, 0}) imgui.SameLine()
			-- Align the label with the radio circles by using the same
			-- frame padding ImGui applies to the radio widgets.
			imgui.AlignTextToFramePadding()
			imgui.Text('Filter mode:')
			imgui.SameLine()
			if imgui.RadioButton('Text-based', not allSettings.PacketFilterEnabled2[1]) then
				allSettings.PacketFilterEnabled2[1] = false
				SaveSettings()
			end
			imgui.SameLine()
			local cposY = imgui.GetCursorPosY()
			AddTooltip('Text-based filtering matches by actor name only. Messages from a filtered entity can slip through when another visible entity nearby shares the same name (most common with trusts, pets, and adventuring fellows that multiple players summon). If this happens often, switch to Packet-based mode. It filters by server entity ID, so name collisions never confuse it.', 4, true)
			imgui.SameLine() imgui.SetCursorPosY(cposY)
			if imgui.RadioButton('Packet-based', allSettings.PacketFilterEnabled2[1]) then
				allSettings.PacketFilterEnabled2[1] = true
				SaveSettings()
			end

			if not allSettings.PacketFilterEnabled2[1] then
				-- Text-based system: the original three checkboxes.
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
			else
				-- Packet-based system: a 5-way hierarchy radio.  Each
				-- level subsumes everything stricter (level 1 shows
				-- all, level 5 shows only the player).  TARGET (the
				-- mob you / party are engaged with) is always shown.
				imgui.Dummy({0, 5})
				imgui.Dummy({5, 0}) imgui.SameLine()
				imgui.Text('Show combat from:')
				AddTooltip('The mob you or any of your party members are engaged with is always shown, regardless of which option you pick below.', 0, 1)
				imgui.Dummy({0, 3})
				local levels = {
					{1, 'Everyone (Others + Alliance + Party + You + Pet)'},
					{2, 'Alliance + Party + You + Pet'},
					{3, 'Party + You + Pet'},
					{4, 'You + Pet'},
					{5, 'You only'},
				}
				for _, lv in ipairs(levels) do
					imgui.Dummy({15, 0}) imgui.SameLine()
					if imgui.RadioButton(lv[2]..'##PacketFilterLevel'..tostring(lv[1]),
						allSettings.PacketFilterLevel == lv[1]) then
						allSettings.PacketFilterLevel = lv[1]
						SaveSettings()
					end
				end

				-- Restrict the always-shown TARGET scope to packets
				-- where the player is among the targets.  Useful in
				-- "only show what's happening to me" play.
				imgui.Dummy({0, 5})
				imgui.Dummy({15, 0}) imgui.SameLine()
				if imgui.Checkbox('Only show TARGET actions that involve me##PacketFilterTargetMeOnly',
					{allSettings.PacketFilterTargetMeOnly[1]}) then
					allSettings.PacketFilterTargetMeOnly[1] = not allSettings.PacketFilterTargetMeOnly[1]
					SaveSettings()
				end
				AddTooltip('When checked, the engaged mob\'s actions only show if you are one of its targets. Hits / abilities aimed only at party members get hidden.', 4)
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
			imgui.SameLine()
			if imgui.Checkbox('12-hour clock', {allSettings.TimeStamp12h[1]}) then
				allSettings.TimeStamp12h[1] = not allSettings.TimeStamp12h[1]
				SaveSettings()
			end
			AddTooltip('Hours above 12 get reduced by 12 (e.g. 14:30 becomes 2:30). AM/PM is not shown.', 4)
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
			-- "Enable FC color marking" toggle is hidden for now —
			-- the addon currently relies on FC marking being on for
			-- correct combat / actor highlighting and legacy-escape
			-- handling.  The underlying allSettings.EnableFCColorMarking
			-- flag is still respected throughout the codebase, so this
			-- block can be re-enabled later without other changes.
			--[[
			imgui.Dummy({0, 5})
			imgui.Dummy({5, 0}) imgui.SameLine()
			if imgui.Checkbox('Enable FC color marking', {allSettings.EnableFCColorMarking[1]}) then
				allSettings.EnableFCColorMarking[1] = not allSettings.EnableFCColorMarking[1]
				SaveSettings()
			end
			AddTooltip('Uses and FC color formatting (Recommended). Disable to try use default color markings.', 4)
			]]
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
		-- Tab: Filters  (contains two sub-tabs: Combat / Other)
		----------------------------------------------------------------
		if imgui.BeginTabItem('Filters', nil) then
			imguiWrap.BeginChild('##Filters Child',
				{(setsizex * 3.8 / 3.9) - (12 * (1 - (setsizex * 3.8 / 1920))) - 3, setsizey * 2.7 / 2.8 - 60}, true)

			-- Draw the file-picker + master-toggle + active-filter table
			-- for one filter kind.  Driven by the per-kind table below
			-- so both Combat Filters and Other Filters use identical UI
			-- with only the underlying setting keys + folder path swapped.
			--
			-- kind          : 'combat' / 'other' (passed to utils.* helpers)
			-- masterKey     : key in allSettings holding the master toggle
			-- selectedKey   : key in allSettings holding the active filename
			-- missingKey    : key in `set` holding the file-missing flag
			-- listKey       : key in `par` holding the parsed filter list
			-- folderName    : on-disk subfolder name (for Open Folder button)
			-- introBlurb    : top-of-tab descriptive paragraph
			-- masterLabel   : label on the enable checkbox
			-- tableHeader   : label above the result table
			local function draw_filter_panel(opts)
				imgui.PushTextWrapPos(imgui.GetWindowWidth() * 0.96)
				imgui.TextWrapped(opts.introBlurb)
				imgui.Dummy({0, 5})

				-- Detection point: every frame the sub-tab is open.
				CheckActiveFilter(opts.kind)

				-- File picker.  The list itself is cached in
				-- cachedFilterFiles[kind] to avoid running the dir
				-- scan every frame -- Refresh re-scans on demand.
				if cachedFilterFiles[opts.kind] == nil then
					cachedFilterFiles[opts.kind] = utils.ListFilters(opts.kind)
				end
				local filterFiles = cachedFilterFiles[opts.kind]
				local missing     = set[opts.missingKey]

				imgui.Text('Active filter file:')
				imgui.SameLine()
				imgui.SetNextItemWidth(setsizex * 0.4)
				local comboLabel = allSettings[opts.selectedKey] or ''
				if missing then
					comboLabel = '[missing] '..comboLabel
				end
				if imgui.BeginCombo('##SelectedFilter_'..opts.kind, comboLabel, ImGuiComboFlags_None) then
					if #filterFiles == 0 then
						imgui.TextDisabled('(no .txt files in filters/'..opts.kind..'/)')
					else
						for fi = 1, #filterFiles do
							if imgui.Selectable(filterFiles[fi], filterFiles[fi] == allSettings[opts.selectedKey]) then
								allSettings[opts.selectedKey] = filterFiles[fi]
								par[opts.listKey] = utils.LoadFilters(opts.kind, allSettings[opts.selectedKey])
								SaveSettings()
								CheckActiveFilter(opts.kind)
							end
						end
					end
					imgui.EndCombo()
				end
				imgui.SameLine()
				if imgui.Button('Refresh##FilterFiles_'..opts.kind) then
					cachedFilterFiles[opts.kind] = utils.ListFilters(opts.kind)
					CheckActiveFilter(opts.kind)
				end
				AddTooltip('Pick which file in filters/'..opts.kind..'/ to use as the active filter list.\n\nRefresh re-scans the folder for newly-added or renamed .txt files.', 4)
				imgui.Dummy({0, 5})

				if missing then
					imgui.TextColored({1.0, 0.3, 0.3, 1.0}, '[!] The active filter file no longer exists in the folder.')
					imgui.TextColored({1.0, 0.3, 0.3, 1.0}, '    Click Refresh, then pick another from the dropdown.')
					imgui.Dummy({0, 5})
				end

				if imgui.Button('Edit Selected Filter##'..opts.kind) then
					local filepath = addon.path..'\\filters\\'..opts.kind..'\\'..allSettings[opts.selectedKey]
					os.execute('start "" "'..filepath..'"')
				end
				if missing and imgui.IsItemHovered() then
					imgui.SetTooltip('Active filter file is missing - pick another from the dropdown above.')
				end
				imgui.SameLine()
				if imgui.Button('Reload Selected Filter##'..opts.kind) then
					par[opts.listKey] = utils.LoadFilters(opts.kind, allSettings[opts.selectedKey])
					CheckActiveFilter(opts.kind)
				end
				if missing and imgui.IsItemHovered() then
					imgui.SetTooltip('Active filter file is missing - pick another from the dropdown above.')
				end
				imgui.SameLine()
				if imgui.Button('Open Folder##'..opts.kind) then
					os.execute('start "" "'..addon.path..'\\filters\\'..opts.kind..'\\"')
				end
				AddTooltip('Open the filters/'..opts.kind..'/ folder in Explorer to add or rename filter files.', 4)
				imgui.Separator()
				imgui.Dummy({0, 5})

				if imgui.Checkbox(opts.masterLabel..'##master_'..opts.kind, {allSettings[opts.masterKey][1]}) then
					allSettings[opts.masterKey][1] = not allSettings[opts.masterKey][1]
					SaveSettings()
					if allSettings[opts.masterKey][1] then
						CheckActiveFilter(opts.kind)
					end
				end
				imgui.Dummy({0, 5})

				if allSettings[opts.masterKey][1] then
					imgui.Text(opts.tableHeader)
					-- Scope ('Applied to') only exists for combat
					-- filters - for the 'other' kind every line is
					-- always treated as scope = '_z' (all), so we drop
					-- the column entirely to avoid a useless "All"
					-- repeated down the table.
					local hasScope = opts.kind == 'combat'
					local nCols    = hasScope and 2 or 1
					if imgui.BeginTable('resultTable_'..opts.kind, nCols,
						bit.bor(ImGuiTableFlags_RowBg, ImGuiTableFlags_BordersH, ImGuiTableFlags_BordersV, ImGuiTableFlags_ContextMenuInBody)) then
						if hasScope then
							imgui.TableSetupColumn('Filter',     ImGuiTableColumnFlags_WidthFixed,   imgui.GetWindowWidth() * 0.7, 0)
							imgui.TableSetupColumn('Applied to', ImGuiTableColumnFlags_WidthStretch, 0, 0)
						else
							imgui.TableSetupColumn('Filter', ImGuiTableColumnFlags_WidthStretch, 0, 0)
						end
						imgui.TableHeadersRow()
						local list = par[opts.listKey]
						for cf = 1, #list do
							imgui.TableNextRow()
							imgui.TableSetColumnIndex(0)
							imgui.PushTextWrapPos(imgui.GetWindowWidth() * (hasScope and 0.7 or 0.95))
							imgui.TextWrapped(list[cf][1]:replace('%', '%%'))
							imgui.PopTextWrapPos()
							if hasScope then
								imgui.TableSetColumnIndex(1)
								local cf_scope = ''
								if list[cf][2] then
									if     list[cf][2] == '_z' then cf_scope = cf_scope + 'All'
									elseif list[cf][2] == '_y' then cf_scope = cf_scope + 'All but you'
									elseif list[cf][2] == '_p' then cf_scope = cf_scope + 'All but party' end
								end
								imgui.PushTextWrapPos(imgui.GetWindowWidth() * 0.9)
								imgui.TextWrapped(cf_scope)
								imgui.PopTextWrapPos()
							end
						end
						imgui.PopTextWrapPos()
						imgui.EndTable()
					end
				end
			end

			if imgui.BeginTabBar('##FiltersInnerTabs', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton) then
				if imgui.BeginTabItem('Combat Filters', nil) then
					draw_filter_panel({
						kind        = 'combat',
						masterKey   = 'CustomFilters',
						selectedKey = 'SelectedCombatFilter',
						missingKey  = 'filterFileMissing',
						listKey     = 'customFilters',
						introBlurb  = 'You can filter combat messages by adding words to a filter file in the filters/combat folder. Each filter file is a plain-text list of words that would appear in unwanted messages.\n(e.g. effect wears off)\n\n> Words must be present in the original game combat message\n  (i.e. not words modified by addons)\n> Word matching is non case sensitive\n> More details in each filter file\n\n!!! Very long lists could cause performance issues !!!',
						masterLabel = 'Enable Combat Log chat filters',
						tableHeader = 'Current Combat Log Filters:',
					})
					imgui.EndTabItem()
				end

				if imgui.BeginTabItem('Other Filters', nil) then
					draw_filter_panel({
						kind        = 'other',
						masterKey   = 'OtherFilters',
						selectedKey = 'SelectedOtherFilter',
						missingKey  = 'otherFilterFileMissing',
						listKey     = 'otherFilters',
						introBlurb  = 'You can filter non-combat chat messages (NPC dialog, system, tells, shouts, ...) by adding words to a filter file in the filters/other folder. Each filter file is a plain-text list of words that would appear in unwanted messages.\n\n> Words must be present in the original game message\n  (i.e. not words modified by addons)\n> Word matching is non case sensitive\n> More details in each filter file\n\n!!! Very long lists could cause performance issues !!!',
						masterLabel = 'Enable Other chat filters',
						tableHeader = 'Current Other Filters:',
					})
					imgui.EndTabItem()
				end

				imgui.EndTabBar()
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
					local logsDir = AshitaCore:GetInstallPath()
						..'\\config\\addons\\'..addon.name..'\\logs\\'..fcw[1].PlayerName
					os.execute('mkdir "'..logsDir..'" 2>nul')
					os.execute('start "" "'..logsDir..'"')
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

		----------------------------------------------------------------
		-- Tab: Credits
		----------------------------------------------------------------
		if imgui.BeginTabItem('Credits', nil) then
			imguiWrap.BeginChild('##Credits Child',
				{(setsizex * 3.8 / 3.9) - (12 * (1 - (setsizex * 3.8 / 1920))) - 3, setsizey * 2.7 / 2.8 - 60}, true)

			imgui.Dummy({0, 15})

			-- ----- Centered logo at the top -----
			-- Sized to 35% of the child width (capped at 220 px) so it
			-- scales nicely on different Settings-window widths but never
			-- dominates the tab.  TextureIDLogo is loaded from
			-- images/logo.png in utils.LoadTextures().
			if fcw[1].TextureIDLogo ~= nil then
				local _winW    = imgui.GetWindowWidth()
				local _logoSz  = math.min(_winW * 0.35, 220)
				imgui.SetCursorPosX((_winW - _logoSz) * 0.5)
				-- UV crop: shows the central 80% x 80% of the source
				-- texture (10% trimmed from each side).  The texture
				-- has transparent padding around the visible artwork;
				-- cropping eliminates the dead space so the visible
				-- logo content fills the rect and the version caption
				-- below sits flush against it.
				imgui.Image(fcw[1].TextureIDLogo,
				            {_logoSz, _logoSz*0.8},
				            {0, 0.1},   -- uv0 (top-left)
				            {1, 0.85})   -- uv1 (bottom-right)
				-- Tight to the logo so the version reads as a caption.
				imgui.Dummy({0, 2})
			end

			-- ----- Version + author line, centered, yellow -----
			-- addon.version is of the form "<major>.<minor>.<YYMMDD>";
			-- extract the 6-digit suffix and format it as "DD Month YYYY".
			local _winW       = imgui.GetWindowWidth()
			local _versionStr = tostring(addon.version or '')
			local _datePart   = _versionStr:match('(%d%d%d%d%d%d)$')
			local _dateDisplay = nil
			if _datePart then
				local _months = {'January','February','March','April','May','June',
				                 'July','August','September','October','November','December'}
				local yy = tonumber(_datePart:sub(1, 2))
				local mm = tonumber(_datePart:sub(3, 4))
				local dd = tonumber(_datePart:sub(5, 6))
				if yy and mm and dd and _months[mm] then
					_dateDisplay = string.format('%d %s %d', dd, _months[mm], 2000 + yy)
				end
			end

			local _YELLOW = {1.0, 0.92, 0.16, 1.0}

			local _line1 = 'Version: '..(_versionStr ~= '' and _versionStr or '?')
			local _w1    = imgui.CalcTextSize(_line1)
			imgui.SetCursorPosX((_winW - _w1) * 0.5)
			imgui.TextColored(_YELLOW, _line1)

			if _dateDisplay then
				local _line2 = 'Created by Arielfy on '.._dateDisplay
				local _w2    = imgui.CalcTextSize(_line2)
				imgui.SetCursorPosX((_winW - _w2) * 0.5)
				imgui.TextColored(_YELLOW, _line2)
			end

			imgui.Dummy({0, 15})

			-- Section-header colour, shared by Links / Major Thanks /
			-- Special Thanks for visual consistency.  Light azure.
			local _SECTION = {0.50, 0.78, 0.95, 1.0}

			-- ----- Links -----
			imgui.TextColored(_SECTION, 'Links')
			imgui.Separator()
			imgui.Dummy({0, 8})

			-- Each entry is {label, url}.  Empty url shows "(link coming)"
			-- as a disabled placeholder; otherwise the URL is rendered
			-- as a clickable hyperlink that opens in the default
			-- browser via imguiWrap.TextLinkOpenURL.  Labels (and the
			-- matching bullet) are in a light-purple hue distinct from
			-- the Major Thanks green / light-red.
			local _LIGHT_PURPLE = {0.80, 0.65, 0.95, 1.0}
			local _links = {
				{'FancyChat GitHub Repo:', 'https://github.com/ariel-logos/Fancychat'},
				{'Arielfy GitHub:',        'https://github.com/ariel-logos'},
				{'ElfyLab:',               'http://ariel-logos.github.io/ElfyLab'},
			}
			for _, _link in ipairs(_links) do
				imgui.Dummy({30, 0}) imgui.SameLine()
				-- Color-matched bullet (same trick as the Major-Thanks
				-- helper: push ImGuiCol_Text just for the bullet glyph,
				-- then restore).
				imgui.PushStyleColor(ImGuiCol_Text, _LIGHT_PURPLE)
				imgui.Bullet()
				imgui.PopStyleColor()
				imgui.TextColored(_LIGHT_PURPLE, _link[1])
				imgui.SameLine()
				if _link[2] ~= '' then
					-- Strip the scheme AND leading "www." from the
					-- displayed URL so it reads cleanly ("github.com/foo"
					-- rather than "https://www.github.com/foo"); the
					-- click target still uses the full URL so the
					-- browser launches correctly.
					local _display = _link[2]
						:gsub('^https?://', '')
						:gsub('^www%.', '')
					imguiWrap.TextLinkOpenURL(_display, _link[2])
				else
					imgui.TextDisabled('(link coming)')
				end
			end

			imgui.Dummy({0, 25})

			-- ----- Major Thanks -----
			-- Two colour-coded subsections under one header: the Ashita
			-- platform contributors (green) and the testers (light red
			-- - kept distinctly red rather than pink by keeping the
			-- green channel noticeably higher than blue).  Each name
			-- can carry an optional URL; when set, it renders as
			-- "Name(<clickable url>)" with no space before the parens.
			imgui.TextColored(_SECTION, 'Major Thanks')
			imgui.Separator()
			imgui.Dummy({0, 8})

			local _GREEN     = {0.45, 0.85, 0.55, 1.0}  -- soft light green
			local _LIGHT_RED = {0.95, 0.45, 0.35, 1.0}  -- #F27359, red-orange (NOT pink)

			local function _credit(name, url, color)
				imgui.Dummy({30, 0}) imgui.SameLine()
				-- Bullet tinted to match the name's color: temporarily
				-- override ImGuiCol_Text so the bullet glyph picks up
				-- our hue, then restore.  Bullet() finishes with an
				-- internal SameLine so the name lands on the same row.
				imgui.PushStyleColor(ImGuiCol_Text, color)
				imgui.Bullet()
				imgui.PopStyleColor()
				imgui.TextColored(color, name)
				if url and url ~= '' then
					local _href = url:find('://') and url or ('https://'..url)
					-- Display-only: scheme + leading "www." stripped so
					-- "https://www.foo.com" reads as "foo.com".  Click
					-- target keeps the full URL.
					local _display = url
						:gsub('^https?://', '')
						:gsub('^www%.', '')
					imgui.SameLine(0, 0)
					imgui.Text('  (')
					imgui.SameLine(0, 0)
					imguiWrap.TextLinkOpenURL(_display, _href)
					imgui.SameLine(0, 0)
					imgui.Text(')')
				end
			end

			-- Subsection 1: Ashita platform + key devs (green)
			imgui.Dummy({10, 0}) imgui.SameLine()
			imgui.Text('For the invaluable addon dev tools, help and patience:')
			imgui.Dummy({0, 4})
			-- TODO: fill optional URLs.  Empty string = no link.
			local _ashita = {
				{'The Ashita Team', ''},
				{'atom0s',          ''},
				{'Thorny',          ''},
			}
			for _, _e in ipairs(_ashita) do
				_credit(_e[1], _e[2], _GREEN)
			end

			-- Visual break between the two subsections; the colour
			-- shift carries most of the separation.
			imgui.Dummy({0, 12})

			-- Subsection 2: Testers (light red)
			imgui.Dummy({10, 0}) imgui.SameLine()
			imgui.Text('For their time spent catching bugs and providing feedback:')
			imgui.Dummy({0, 4})
			-- TODO: fill optional URLs.  Empty string = no link.
			local _testers = {
				{'Zeratia', ''},
				{'Mod',     ''},
				{'Carver',  'www.catseyexi.com'},
				{'Emy',     ''},
				{'Sky',     ''},
			}
			for _, _e in ipairs(_testers) do
				_credit(_e[1], _e[2], _LIGHT_RED)
			end

			imgui.Dummy({0, 25})

			-- ----- Special Thanks -----
			-- Free-form section at the bottom for shoutouts, dedications,
			-- inside jokes, whatever you want.  Edit the lines below.
			-- TextWrapped honors the child's content width so long lines
			-- wrap to fit the panel.
			imgui.TextColored(_SECTION, 'Special Thanks')
			imgui.Separator()
			imgui.Dummy({0, 8})

			imgui.PushTextWrapPos(imgui.GetWindowWidth() * 0.95)
			imgui.Dummy({10, 0}) imgui.SameLine()
			imgui.TextWrapped('Thanks to my family and all my friends who, for the past year, watched me disappear into my room to push this project forward. Even through the countless hours I spent buried in code, you stayed close to me, checking in, dragging me out for a meal, putting up with the late nights and the monologues about chat windows.')

			imgui.Dummy({0, 12})

			imgui.Dummy({10, 0}) imgui.SameLine()
			imgui.TextWrapped('A final thanks to my dad, I am sorry I could not show you the final result; you would have been happy and proud, as you always were with everything I did. I miss you.')
			imgui.PopTextWrapPos()
			
			imgui.Dummy({0, 24})
			imgui.EndChild()
			imgui.EndTabItem()
		end

		imgui.EndTabBar()
	end

	imgui.End()
	PopWindowStyle()

	-- ----------------------------------------------------------------
	-- Colorset Save / Load popups.  Centered on screen, fixed size,
	-- no title bar, opaque black background, ImGui-orange buttons.
	-- The Load popup's file list lives in a scrollable child so a
	-- long folder doesn't push the buttons off-screen.  Dismissed
	-- only via the Save / Load action, Cancel, or Escape — clicking
	-- outside is intentionally a no-op.
	-- ----------------------------------------------------------------
	local popupFlags = bit.bor(
		ImGuiWindowFlags_NoDecoration,
		ImGuiWindowFlags_NoTitleBar,
		ImGuiWindowFlags_NoMove,
		ImGuiWindowFlags_NoSavedSettings)

	-- Opaque-black bg + coral buttons (#D45447 = 0.831,0.329,0.278).
	local function pushPopupStyle()
		imgui.PushStyleColor(ImGuiCol_WindowBg,      {0,     0,     0,     1.0})
		imgui.PushStyleColor(ImGuiCol_ChildBg,       {0,     0,     0,     1.0})
		imgui.PushStyleColor(ImGuiCol_Button,        {0.831, 0.329, 0.278, 1.0})
		imgui.PushStyleColor(ImGuiCol_ButtonHovered, {0.929, 0.420, 0.353, 1.0})
		imgui.PushStyleColor(ImGuiCol_ButtonActive,  {0.700, 0.250, 0.200, 1.0})
	end
	local function popPopupStyle() imgui.PopStyleColor(5) end

	local _disp   = imgui.GetIO().DisplaySize
	local _cx, _cy = _disp.x * 0.5, _disp.y * 0.5

	if set.colorIO.exportOpen then
		imgui.SetNextWindowPos({_cx, _cy}, ImGuiCond_Always, {0.5, 0.5})
		imgui.SetNextWindowSize({440, 130}, ImGuiCond_Always)
		pushPopupStyle()
		if imgui.Begin('##fc_export', true, popupFlags) then
			imgui.Text('Filename:')
			imgui.PushItemWidth(-1)                      -- fill the popup width
			imgui.InputText('##fc_export_name', set.colorIO.exportName, 64)
			imgui.PopItemWidth()
			imgui.Spacing()
			if imgui.Button('Save##fc_export_save', {80, 0}) then
				local skipKeys = {'combat', 'combatspell'}
				local payload  = {}
				for k, v in pairs(allSettings.colors) do
					if not utils.FindInStringTable(k, skipKeys, 0) then
						payload[k] = v
					end
				end
				utils.ExportColors(addon.path, set.colorIO.exportName[1], payload)
				set.colorIO.exportOpen = false
			end
			imgui.SameLine()
			if imgui.Button('Cancel##fc_export_cancel', {80, 0}) then
				set.colorIO.exportOpen = false
			end
			if imguiWrap.GetKeyDown(1) then     -- Escape
				set.colorIO.exportOpen = false
			end
		end
		imgui.End()
		popPopupStyle()
	end

	if set.colorIO.importOpen then
		imgui.SetNextWindowPos({_cx, _cy}, ImGuiCond_Always, {0.5, 0.5})
		imgui.SetNextWindowSize({440, 400}, ImGuiCond_Always)
		pushPopupStyle()
		if imgui.Begin('##fc_import', true, popupFlags) then
			local files = set.colorIO.importFiles
			imgui.Text('Select a colorset file:')
			-- Reserve the bottom row of the popup for the buttons:
			-- list height = (whatever vertical space is left) - one row
			-- for the buttons - a small spacing gap.  Negative Y in
			-- BeginChild's size means "fill remaining minus -Y px"; we
			-- compute the explicit amount so the buttons always fit.
			local _, availY = imgui.GetContentRegionAvail()
			local listH     = math.max(80, availY - 40)  -- 40 = one button row + gap
			imguiWrap.BeginChild('##fc_import_list', {0, listH}, true)
			if #files == 0 then
				imgui.TextDisabled('(no files in chatcolors/)')
			else
				for i, name in ipairs(files) do
					if imgui.Selectable(name, set.colorIO.importSelected == i) then
						set.colorIO.importSelected = i
					end
				end
			end
			imgui.EndChild()
			local hasSel = set.colorIO.importSelected > 0 and #files > 0
			if not hasSel then
				imgui.PushStyleColor(ImGuiCol_Button,        {0.35, 0.35, 0.35, 0.5})
				imgui.PushStyleColor(ImGuiCol_ButtonHovered, {0.35, 0.35, 0.35, 0.5})
				imgui.PushStyleColor(ImGuiCol_ButtonActive,  {0.35, 0.35, 0.35, 0.5})
			end
			if imgui.Button('Load##fc_import_load', {80, 0}) and hasSel then
				local fname = files[set.colorIO.importSelected]
				allSettings.colors = utils.ImportColors(addon.path, fname, allSettings.colors)
				SaveSettings()
				set.colorIO.importOpen = false
			end
			if not hasSel then imgui.PopStyleColor(3) end
			imgui.SameLine()
			if imgui.Button('Cancel##fc_import_cancel', {80, 0}) then
				set.colorIO.importOpen = false
			end
			if imguiWrap.GetKeyDown(1) then     -- Escape
				set.colorIO.importOpen = false
			end
		end
		imgui.End()
		popPopupStyle()
	end
end

return M
