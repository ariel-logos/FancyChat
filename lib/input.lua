--[[
	lib/input.lua

	All three input event callbacks:

	  xinput_button - Gamepad navigation: tab cycle, scroll, BigMode
	                  toggle, chat-input enter/space, command history.
	                  Active only while allSettings.GamepadNav is true,
	                  and gated by gamepadButtons.enabled (button 8 hold).

	  key_state     - Keyboard shortcuts: Hide, BigMode, primary tab
	                  cycle, secondary tab cycle.  Each is a two-key
	                  combo configured in Settings.

	  mouse         - Wheel scroll routes its delta into all three
	                  chat windows' ScrollDelta.

	Calls a handful of GLOBAL helpers still defined in fancychat.lua:
	ResetAutoHideTimer, SetChatOpacity, ResetScrolling, updateCommandList.
	Resolved at call time via the global namespace.
]]

require('common')
local ffi   = require('ffi')
local utils = require('utils')
local state = require('lib.state')

local fcw            = state.fcw
local tab            = state.tab
local gamepadButtons = state.gamepadButtons
local allSettings    = state.allSettings

local M = {}

function M.register()

	ashita.events.register('xinput_button', 'xinput_button_callback1', function (e)
		if not allSettings.GamepadNav[1] then return end

		gamepadButtons.buttonsCDready = os.clock() - gamepadButtons.buttonsCD > 0.15
		gamepadButtons.analogCDready  = os.clock() - gamepadButtons.analogCD  > 0.02

		if gamepadButtons.pressedEnter and gamepadButtons.buttonsCDready then
			gamepadButtons.pressedEnter = false
			AshitaCore:GetChatManager():QueueCommand(1, '/sendkey enter up')
		end

		-- Button 8 (RT) hold enables gamepad navigation mode.
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

		if not gamepadButtons.enabled then return end

		-- Block all other gamepad input while navigation is active,
		-- except button-up events for the analog scroll buttons
		-- (which we still need to read so scrollN reverts to 0).
		if not (e.button == 18 and e.state == 0)
			and not (e.button == 19 and e.state == 0)
			and not (e.button == 20 and e.state == 0)
			and not (e.button == 21 and e.state == 0) then
			e.blocked = true
		end

		-- Button 9: cycle primary chat's tab.
		if e.button == 9 and not fcw[1].BufferBusy and gamepadButtons.buttonsCDready then
			local tab_id = utils.FindInTable(tab.Tabs, allSettings.SelectedTab)
			if tab_id then
				if tab_id == #tab.Tabs then
					tab.NextTab = tab.Tabs[1]
				else
					tab.NextTab = tab.Tabs[tab_id + 1]
				end
			end
			gamepadButtons.buttonsCD = os.clock()
			return
		end

		-- Button 17: cycle secondary chat's tab.
		if allSettings.SecondChat[1] and e.button == 17 and not fcw[1].BufferBusy and gamepadButtons.buttonsCDready then
			local tab_id = utils.FindInTable(tab.Tabs, allSettings.SelectedTab2)
			if tab_id then
				if tab_id == #tab.Tabs then
					tab.NextTab2 = tab.Tabs[1]
				else
					tab.NextTab2 = tab.Tabs[tab_id + 1]
				end
			end
			gamepadButtons.buttonsCD = os.clock()
			return
		end

		-- Buttons 19 / 21: analog stick scroll for primary / secondary.
		if e.button == 19 then
			gamepadButtons.scroll1 = (e.state ~= 0) and (e.state / math.abs(e.state)) or 0
		end
		if e.button == 21 then
			gamepadButtons.scroll2 = (e.state ~= 0) and (e.state / math.abs(e.state)) or 0
		end

		if gamepadButtons.scroll1 ~= 0 and gamepadButtons.analogCDready then
			fcw[1].ScrollDelta = gamepadButtons.scroll1
			fcw[3].ScrollDelta = gamepadButtons.scroll1
			gamepadButtons.analogCD = os.clock()
			return
		end
		if gamepadButtons.scroll2 ~= 0 and gamepadButtons.analogCDready then
			fcw[2].ScrollDelta = gamepadButtons.scroll2
			gamepadButtons.analogCD = os.clock()
			return
		end

		-- Button 13: snap-to-bottom on every visible chat.
		if e.button == 13 and e.state == 1 then
			if fcw[1].ScrolledBack > 0 then ResetScrolling(1) end
			if fcw[2].ScrolledBack > 0 then ResetScrolling(2) end
			if fcw[3].ScrolledBack > 0 then ResetScrolling(3, fcw[3].ChatLines) end
			return
		end

		-- Button 15: toggle BigMode.
		if e.button == 15 and e.state == 1 and gamepadButtons.buttonsCDready then
			fcw[3].BigMode = not fcw[3].BigMode
			gamepadButtons.buttonsCD = os.clock()
			return
		end

		-- Button 14: open the FFXI chat input box.
		if e.button == 14 and e.state == 1
			and AshitaCore:GetChatManager():IsInputOpen() == 0x00
			and gamepadButtons.buttonsCDready then
			AshitaCore:GetChatManager():QueueCommand(-1, '/sendkey space down')
			AshitaCore:GetChatManager():QueueCommand(-1, '/sendkey space up')
			gamepadButtons.buttonsCD = os.clock()
			return
		end

		-- Button 12: submit current input as a command.
		if e.button == 12 and e.state == 1
			and AshitaCore:GetChatManager():IsInputOpen() == 0x11
			and gamepadButtons.buttonsCDready then
			AshitaCore:GetChatManager():QueueCommand(-1, '/sendkey enter down')
			local cmd = AshitaCore:GetChatManager():GetInputTextRaw()
			if #cmd > 0 and not cmd:find('^%s*$') then
				updateCommandList(cmd)
			end
			gamepadButtons.pressedEnter = true
			gamepadButtons.buttonsCD = os.clock()
			return
		end

		-- Buttons 0 / 1: cycle through user-typed command history.
		if #fcw[1].LastCommands[1] > 0 then
			if e.button == 0 and e.state == 1
				and AshitaCore:GetChatManager():IsInputOpen() == 0x11
				and gamepadButtons.buttonsCDready then
				local nextCommandIdx = fcw[1].LastCommands[2] + 1
				if nextCommandIdx > #fcw[1].LastCommands[1] then nextCommandIdx = 1 end
				if not fcw[1].LastCommands[1][nextCommandIdx] then
					nextCommandIdx = 1
					fcw[1].LastCommands[2] = 1
				end
				AshitaCore:GetChatManager():SetInputText(fcw[1].LastCommands[1][nextCommandIdx])
				fcw[1].LastCommands[2] = nextCommandIdx
				gamepadButtons.buttonsCD = os.clock()
				return
			end
			if e.button == 1 and e.state == 1
				and AshitaCore:GetChatManager():IsInputOpen() == 0x11
				and gamepadButtons.buttonsCDready then
				local nextCommandIdx = fcw[1].LastCommands[2] - 1
				if nextCommandIdx < 1 then nextCommandIdx = #fcw[1].LastCommands[1] end
				if not fcw[1].LastCommands[1][nextCommandIdx] then
					nextCommandIdx = 1
					fcw[1].LastCommands[2] = 1
				end
				AshitaCore:GetChatManager():SetInputText(fcw[1].LastCommands[1][nextCommandIdx])
				fcw[1].LastCommands[2] = nextCommandIdx
				gamepadButtons.buttonsCD = os.clock()
				return
			end
		end

		-- Buttons 2 / 3: cycle through preset (`!mog`, `!chef`, ...) commands.
		if e.button == 3 and e.state == 1
			and AshitaCore:GetChatManager():IsInputOpen() == 0x11
			and gamepadButtons.buttonsCDready then
			local nextCommandIdx = fcw[1].LastCommands[4] + 1
			if nextCommandIdx > #fcw[1].LastCommands[3] then nextCommandIdx = 1 end
			AshitaCore:GetChatManager():SetInputText(fcw[1].LastCommands[3][nextCommandIdx])
			fcw[1].LastCommands[4] = nextCommandIdx
			gamepadButtons.buttonsCD = os.clock()
			return
		end
		if e.button == 2 and e.state == 1
			and AshitaCore:GetChatManager():IsInputOpen() == 0x11
			and gamepadButtons.buttonsCDready then
			local nextCommandIdx = fcw[1].LastCommands[4] - 1
			if nextCommandIdx < 1 then nextCommandIdx = #fcw[1].LastCommands[3] end
			AshitaCore:GetChatManager():SetInputText(fcw[1].LastCommands[3][nextCommandIdx])
			fcw[1].LastCommands[4] = nextCommandIdx
			gamepadButtons.buttonsCD = os.clock()
			return
		end
	end)

	ashita.events.register('key_state', 'key_state_callback1', function (e)
		if gamepadButtons.enabled then return end

		local keyptr = ffi.cast('uint8_t*', e.data_raw)

		-- Pressing Enter while typing in the chat input commits the line
		-- to the per-character command history.
		if AshitaCore:GetChatManager():IsInputOpen() == 0x11
			and (keyptr[28] ~= 0 or keyptr[156] ~= 0) then
			local cmd = AshitaCore:GetChatManager():GetInputTextRaw()
			if #cmd > 0 and not cmd:find('^%s*$') then
				updateCommandList(cmd)
			end
		end

		-- Hide-chat shortcut.
		if allSettings.shortcutHideEnabled[1]
			and keyptr[allSettings.shortcutHide] ~= 0
			and keyptr[allSettings.shortcutHideS] ~= 0
			and not fcw[1].Keydown
			and AshitaCore:GetChatManager():IsInputOpen() == 0x00 then
			fcw[1].HideChat = not fcw[1].HideChat
			ResetAutoHideTimer()
			SetChatOpacity(1, 1)
			if allSettings.SecondChat[1] then SetChatOpacity(1, 2) end
			fcw[1].Keydown = true
		elseif keyptr[allSettings.shortcutHide] == 0 then
			fcw[1].Keydown = false
		end

		-- BigMode shortcut.
		if allSettings.shortcutBigEnabled[1]
			and keyptr[allSettings.shortcutBig] ~= 0
			and keyptr[allSettings.shortcutBigS] ~= 0
			and not fcw[3].Keydown
			and AshitaCore:GetChatManager():IsInputOpen() == 0x00 then
			fcw[3].BigMode = not fcw[3].BigMode
			ResetAutoHideTimer()
			fcw[3].Keydown = true
		elseif keyptr[allSettings.shortcutBig] == 0 then
			fcw[3].Keydown = false
		end

		if fcw[1].BufferBusy then return end

		-- Tab-cycle shortcut for primary chat.
		if allSettings.shortcutTabEnabled[1]
			and keyptr[allSettings.shortcutTab] ~= 0
			and keyptr[allSettings.shortcutTabS] ~= 0
			and not fcw[1].Keydown2
			and AshitaCore:GetChatManager():IsInputOpen() == 0x00 then
			local tab_id = utils.FindInTable(tab.Tabs, allSettings.SelectedTab)
			fcw[1].Keydown2 = true
			if tab_id then
				if tab_id == #tab.Tabs then
					tab.NextTab = tab.Tabs[1]
				else
					tab.NextTab = tab.Tabs[tab_id + 1]
				end
				ResetAutoHideTimer()
			end
		elseif keyptr[allSettings.shortcutTab] == 0 then
			fcw[1].Keydown2 = false
		end

		-- Tab-cycle shortcut for secondary chat.
		if allSettings.SecondChat[1] then
			if allSettings.shortcutTab2Enabled[1]
				and keyptr[allSettings.shortcutTab2] ~= 0
				and keyptr[allSettings.shortcutTab2S] ~= 0
				and not fcw[1].Keydown3
				and AshitaCore:GetChatManager():IsInputOpen() == 0x00 then
				local tab_id = utils.FindInTable(tab.Tabs, allSettings.SelectedTab2)
				fcw[1].Keydown3 = true
				if tab_id then
					if tab_id == #tab.Tabs then
						tab.NextTab2 = tab.Tabs[1]
					else
						tab.NextTab2 = tab.Tabs[tab_id + 1]
					end
					ResetAutoHideTimer()
				end
			elseif keyptr[allSettings.shortcutTab2] == 0 then
				fcw[1].Keydown3 = false
			end
		end
	end)

	ashita.events.register('mouse', 'mouse_callback1', function (e)
		if e.delta ~= 0 then
			fcw[1].ScrollDelta = e.delta
			fcw[2].ScrollDelta = e.delta
			fcw[3].ScrollDelta = e.delta
		end
	end)

end

return M
