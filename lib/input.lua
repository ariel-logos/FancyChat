-- lib/input.lua — xinput_button / key_state / mouse callbacks.

require('common')
local ffi   = require('ffi')
local utils = require('utils')
local state = require('lib.state')

local fcw            = state.fcw
local tab            = state.tab
local gamepadButtons = state.gamepadButtons
local allSettings    = state.allSettings
local set            = state.set

local M = {}

function M.register()

	ashita.events.register('xinput_button', 'xinput_button_callback1', function (e)
		-- Listen-for-rebind path.  Activated from the Settings -> Gamepad
		-- tab; captures the very next non-axis button press and writes it
		-- into the corresponding GamepadBindings entry, then exits listen
		-- mode.  Runs BEFORE the GamepadNav gate so users can configure
		-- bindings without first enabling navigation.
		if gamepadButtons.listenKey ~= nil then
			e.blocked = true             -- swallow all gamepad input while listening
			if e.state ~= 1 then return end   -- only react to the press, not the release
			local btn = e.button
			-- Reject analog stick axes (not user-remappable).  In
			-- Xbox-controller mode, also reject buttons that aren't
			-- in the documented friendly-name list so the captured
			-- value always renders to a known label; in generic mode
			-- (the default) accept any digital button so users on
			-- non-Xbox pads can bind whatever indexes their hardware
			-- emits.
			if btn == 18 or btn == 19 or btn == 20 or btn == 21 then return end
			if allSettings.XboxController[1]
			   and not utils.findIndexOfValue(utils.gamepadButtonList, btn) then
				return
			end
			local target_key = gamepadButtons.listenKey
			local old_id     = allSettings.GamepadBindings[target_key]
			-- If the captured button is already bound to some OTHER
			-- action, swap them - no orphan slots, no need to manually
			-- un-bind first.
			for k, v in pairs(allSettings.GamepadBindings) do
				if k ~= target_key and v == btn then
					allSettings.GamepadBindings[k] = old_id
					break
				end
			end
			allSettings.GamepadBindings[target_key] = btn
			SaveSettings()
			gamepadButtons.listenKey = nil
			return
		end

		if not allSettings.GamepadNav[1] then return end

		gamepadButtons.buttonsCDready = os.clock() - gamepadButtons.buttonsCD > 0.15
		gamepadButtons.analogCDready  = os.clock() - gamepadButtons.analogCD  > 0.02

		if gamepadButtons.pressedEnter and gamepadButtons.buttonsCDready then
			gamepadButtons.pressedEnter = false
			AshitaCore:GetChatManager():QueueCommand(1, '/sendkey enter up')
		end

		-- Snapshot bindings once per event so each `e.button == X` test
		-- uses a stable value (and one fewer table lookup per branch).
		local GB = allSettings.GamepadBindings

		-- Modifier button (default LB) hold enables gamepad navigation
		-- mode.  All other bindings only fire while the modifier is held.
		if e.button == GB.modifier then
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

		-- Cycle primary chat's tab.
		if e.button == GB.cyclePrimaryTab and not fcw[1].BufferBusy and gamepadButtons.buttonsCDready then
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

		-- Cycle secondary chat's tab.
		if allSettings.SecondChat[1] and e.button == GB.cycleSecondaryTab and not fcw[1].BufferBusy and gamepadButtons.buttonsCDready then
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
		-- (Not user-remappable - these are stick axes, not digital buttons.)
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

		-- Snap-to-bottom on every visible chat.
		if e.button == GB.snapToBottom and e.state == 1 then
			if fcw[1].ScrolledBack > 0 then ResetScrolling(1) end
			if fcw[2].ScrolledBack > 0 then ResetScrolling(2) end
			if fcw[3].ScrolledBack > 0 then ResetScrolling(3, fcw[3].ChatLines) end
			return
		end

		-- Toggle BigMode.
		if e.button == GB.toggleBigMode and e.state == 1 and gamepadButtons.buttonsCDready then
			fcw[3].BigMode = not fcw[3].BigMode
			gamepadButtons.buttonsCD = os.clock()
			return
		end

		-- Open the FFXI chat input box.
		if e.button == GB.openChatInput and e.state == 1
			and AshitaCore:GetChatManager():IsInputOpen() == 0x00
			and gamepadButtons.buttonsCDready then
			AshitaCore:GetChatManager():QueueCommand(-1, '/sendkey space down')
			AshitaCore:GetChatManager():QueueCommand(-1, '/sendkey space up')
			gamepadButtons.buttonsCD = os.clock()
			return
		end

		-- Submit current input as a command.
		if e.button == GB.submitInput and e.state == 1
			and AshitaCore:GetChatManager():IsInputOpen() == 0x11
			and gamepadButtons.buttonsCDready then
			AshitaCore:GetChatManager():QueueCommand(-1, '/sendkey enter down')
			local cmd = AshitaCore:GetChatManager():GetInputTextRaw()
			if #cmd > 0 and not cmd:find('^%s*$') then
				-- Push the submitted command to typed-history slot [1].
				-- (Replaces the old updateCommandList() call from the
				-- now-removed debug window.)  Prepend so the most
				-- recent entry is at index 1, matching the cycling code
				-- which steps idx 0 -> 1 -> 2 ... for "Prev".  Skip if
				-- identical to the current head (debounces the case
				-- where the keyboard path also fires for the same line).
				local hist = fcw[1].LastCommands[1]
				if hist[1] ~= cmd then
					table.insert(hist, 1, cmd)
					while #hist > 30 do hist[#hist] = nil end
				end
			end
			gamepadButtons.pressedEnter = true
			gamepadButtons.buttonsCD = os.clock()
			return
		end

		-- Cycle through user-typed command history.
		if #fcw[1].LastCommands[1] > 0 then
			if e.button == GB.historyPrev and e.state == 1
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
			if e.button == GB.historyNext and e.state == 1
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

		-- Cycle through preset (`!mog`, `!chef`, ...) commands.
		if e.button == GB.presetNext and e.state == 1
			and AshitaCore:GetChatManager():IsInputOpen() == 0x11
			and gamepadButtons.buttonsCDready then
			local nextCommandIdx = fcw[1].LastCommands[4] + 1
			if nextCommandIdx > #fcw[1].LastCommands[3] then nextCommandIdx = 1 end
			AshitaCore:GetChatManager():SetInputText(fcw[1].LastCommands[3][nextCommandIdx])
			fcw[1].LastCommands[4] = nextCommandIdx
			gamepadButtons.buttonsCD = os.clock()
			return
		end
		if e.button == GB.presetPrev and e.state == 1
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

		-- Escape closes the zone-search popup.  Done in this callback
		-- (rather than only via imgui.GetIO().KeysDown inside the popup
		-- draw block) because the popup can be dismissed even when
		-- it doesn't currently have ImGui keyboard focus — DI scancode
		-- 1 is Escape and is read directly out of the raw key-state
		-- buffer, bypassing ImGui's input routing entirely.
		if set.zoneTip.visible and keyptr[1] ~= 0 then
			set.zoneTip.visible = false
		end

		-- Escape also cancels an in-progress gamepad-binding listen
		-- (Settings -> Gamepad tab).  Same raw-scancode read for the
		-- same reason: the user may not have ImGui focus on the
		-- Settings window when they hit Esc to bail out.
		if gamepadButtons.listenKey ~= nil and keyptr[1] ~= 0 then
			gamepadButtons.listenKey = nil
		end

		-- Pressing Enter while typing in the chat input commits the line
		-- to the per-character command history.  Block runs every frame
		-- Enter is held, so the de-dup (hist[1] ~= cmd) keeps the list
		-- clean of repeated pushes for a single key-down.
		if AshitaCore:GetChatManager():IsInputOpen() == 0x11
			and (keyptr[28] ~= 0 or keyptr[156] ~= 0) then
			local cmd = AshitaCore:GetChatManager():GetInputTextRaw()
			if #cmd > 0 and not cmd:find('^%s*$') then
				local hist = fcw[1].LastCommands[1]
				if hist[1] ~= cmd then
					table.insert(hist, 1, cmd)
					while #hist > 30 do hist[#hist] = nil end
				end
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
