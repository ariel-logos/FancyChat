-- lib/commands.lua — /fancychat (alias /fchat) slash-command handler.

require('common')
local utils = require('utils')
local help  = require('help')
local state = require('lib.state')

local fcw         = state.fcw
local dw          = state.dw
local b           = state.b
local par         = state.par
local uiw         = state.uiw
local allSettings = state.allSettings

local M = {}

function M.register()
	ashita.events.register('command', 'command_cb', function (e)
		local args = e.command:args()
		if (#args == 0 or (not args[1]:any('/fancychat') and not args[1]:any('/fchat'))) then
			return
		end

		e.blocked = true

		--[[  debug_window disabled
		if (#args == 2 and args[2] == 'debug') then
			dw.WindowOpened[1] = not dw.WindowOpened[1]
			return
		end
		--]]
		if (#args == 2 and args[2] == 'bigmode') then
			fcw[3].BigMode = not fcw[3].BigMode
			return
		end
		--[[  Commented out: action-packet debug commands.  Re-enable
		      together with the matching block in lib/combat_packets.lua
		      when investigating packet capture / classification issues.
		if (#args == 3 and args[2] == 'actionlog' and args[3] == 'clear') then
			local path = addon.path..'/action_log.log'
			local f = io.open(path, 'w')
			if f then f:close() end
			print('FancyChat: cleared '..path)
			return
		end
		if (#args == 2 and args[2] == 'actiondebug') then
			local cp = require('lib.combat_packets')
			local SCOPE_NAME = {
				[cp.SCOPE_YOU]      = 'YOU',
				[cp.SCOPE_PET]      = 'PET',
				[cp.SCOPE_PARTY]    = 'PARTY',
				[cp.SCOPE_ALLIANCE] = 'ALLIANCE',
				[cp.SCOPE_TARGET]   = 'TARGET',
				[cp.SCOPE_OTHERS]   = 'OTHERS',
			}
			local path = addon.path..'/actiondebug.log'
			local f = io.open(path, 'a')
			if not f then
				print('FancyChat: could not open '..path)
				return
			end
			f:write(('---- %s ----\n'):format(os.date('%Y-%m-%d %H:%M:%S')))
			f:write(('stats packets_seen=%d parsed_ok=%d parse_errors=%d\n')
				:format(cp.stats.packets_seen, cp.stats.parsed_ok, cp.stats.parse_errors))
			if cp.stats.last_err then
				f:write('last parse error: '..cp.stats.last_err..'\n')
			end
			f:write(('buffer: %d recent action(s)\n'):format(#cp.recent))
			local now = os.clock()
			for i = #cp.recent, 1, -1 do
				local e   = cp.recent[i]
				local age = now - e.t_clock
				f:write(('  [%5.2fs ago] %-10s actor=%s (id=%u) cmd=%d targets=%d\n')
					:format(age, SCOPE_NAME[e.scope] or '?',
					        e.actor_name or '?', e.actor_id,
					        e.cmd_no, #e.target_ids))
			end
			f:write('\n')
			f:close()
			print('FancyChat: actiondebug dumped to '..path)
			return
		end
		--]]
		if (#args == 2 and args[2] == 'savelogs') then
			local ts = os.date('[%Y_%m_%d-%H_%M_%S]', os.time())
			utils.SaveLogs(b.ChatBuffer[1][2].text, b.ChatBuffer[1][2].auxText, 'All',       fcw[1].PlayerName, addon.path, ts); coroutine.sleep(0.5)
			utils.SaveLogs(b.ChatBuffer[3][2].text, b.ChatBuffer[3][2].auxText, 'Combat',    fcw[1].PlayerName, addon.path, ts); coroutine.sleep(0.5)
			utils.SaveLogs(b.ChatBuffer[4][2].text, b.ChatBuffer[4][2].auxText, 'Linkshell', fcw[1].PlayerName, addon.path, ts); coroutine.sleep(0.5)
			utils.SaveLogs(b.ChatBuffer[5][2].text, b.ChatBuffer[5][2].auxText, 'Party',     fcw[1].PlayerName, addon.path, ts); coroutine.sleep(0.5)
			utils.SaveLogs(b.ChatBuffer[6][2].text, b.ChatBuffer[6][2].auxText, 'Tell',      fcw[1].PlayerName, addon.path, ts); coroutine.sleep(0.5)
			utils.SaveLogs(b.ChatBuffer[7][2].text, b.ChatBuffer[7][2].auxText, 'Shout',     fcw[1].PlayerName, addon.path, ts); coroutine.sleep(0.5)
			utils.SaveLogs(b.ChatBuffer[8][2].text, b.ChatBuffer[8][2].auxText, 'Custom',    fcw[1].PlayerName, addon.path, ts); coroutine.sleep(0.5)
			return
		end

		--[[  debug_window disabled
		if (#args == 2 and args[2] == 'savedebug') then
			local ts = os.date('[%Y_%m_%d-%H_%M_%S]', os.time())
			if utils.SaveLogs(b.LogBuffer, nil, 'DEBUG', fcw[1].PlayerName, addon.path, ts) then
				b.LogBuffer = {}
			end
			return
		end
		--]]

		
		-- if (#args > 3 and args[2] == 'test' and tonumber(args[3]) >= 0 and tonumber(args[3]) <= 255) then
			-- local test_string = ''
			-- local test_i = 4
			-- while args[test_i] ~= nil do
				-- test_string = test_string..args[test_i]..' '
				-- test_i = test_i + 1
			-- end
			-- AshitaCore:GetChatManager():AddChatMessage(tonumber(args[3]), false, test_string:trimex()..'\127\49')
			-- return
		-- end
		

		if (#args == 2 and args[2] == 'printdebug') then
			--print(string.char(0x81, 0xC0))
			-- Dump every legacy palette slot to chat with its index as
			-- the visible label.  Each label is wrapped in its own
			-- colour escape so FFXI's native chat renderer paints it
			-- in that palette colour - letting us read the actual RGB
			-- off a screenshot for any slot the chat.colors table
			-- doesn't document.
			--
			-- Output format (16 labels per AddChatMessage call):
			--   Header: "== Table 1 (\x1E\NN) ==" / "== Table 2 (\x1F\NN) =="
			--   Body:   \x1F\NN<NN> repeated, with trailing reset.
			--
			-- View in the LEGACY FFXI chat (set blockAll OFF in
			-- Settings -> Extra) - that's where FFXI itself renders
			-- the colours; FancyChat's own renderer doesn't speak the
			-- legacy palette.
			-- local function dump_palette(lead_byte, label)
				-- AshitaCore:GetChatManager():AddChatMessage(122, false,
					-- '== Palette Table '..label..' ('..string.format('\\x%02X', lead_byte)..'\\NN) ==')
				-- local line = ''
				-- local count = 0
				-- for n = 1, 255 do
					-- local color  = string.char(lead_byte, n)
					-- local reset  = string.char(0x1E, 0x01)
					-- line = line..color..string.format('%03d', n)..reset..' '
					-- count = count + 1
					-- if count == 16 or n == 255 then
						-- AshitaCore:GetChatManager():AddChatMessage(6, false, line)
						-- line = ''
						-- count = 0
					-- end
				-- end
			-- end
			-- dump_palette(0x1E, '1')
			-- dump_palette(0x1F, '2')
			-- AshitaCore:GetChatManager():AddChatMessage(122, false,
				-- '== Palette dump complete.  View in legacy chat (blockAll OFF). ==')
		end

		-- if (#args == 2 and args[2] == 'helpdebug') then
			-- print(#help.foundParent)
			-- print(tostring(help.foundAnything))
			-- print(table.concat(help.foundParent, ','))
		-- end
		

		if not fcw[1].Closing and fcw[1].InitDone and fcw[1].LoggedIn then
			if (#args == 2 and args[2] == 'guideme') then
				fcw[1].GuideMeOpened[1] = not fcw[1].GuideMeOpened[1]
				if fcw[1].GuideMeOpened[1] then
					fcw[1].NotepadOpened[1] = false
				end
				return
			end
			if (#args == 2 and args[2] == 'settings') then
				allSettings.settingsOpened[1] = not allSettings.settingsOpened[1]
				SaveSettings()
				return
			end
			if (#args == 2 and args[2] == 'compact') then
				allSettings.CompactTabs = not allSettings.CompactTabs
				-- Invalidate the cached tab-bar positions so the next
				-- render frame recomputes them from the current anchor.
				-- Setting only PosChanged=true is not enough because
				-- render.lua resets PosChanged at the top of every frame
				-- (right after re-deriving the anchor) so a toggle made
				-- between frames loses the signal.  Clearing the cache
				-- entries directly triggers the "or not fcw.TabsPos"
				-- branch and forces a recompute regardless.
				fcw[1].TabsPos     = nil
				fcw[1].compactPos  = nil
				fcw[1].compactSize = nil
				fcw[2].TabsPos     = nil
				fcw[2].compactPos  = nil
				fcw[2].compactSize = nil
				fcw[1].PosChanged = true
				fcw[2].PosChanged = true
				SaveSettings()
				return
			end
			if (#args == 2 and args[2] == 'manual') then
				help.opened[1] = not help.opened[1]
				return
			end
			if (#args == 2 and args[2] == 'notes') then
				fcw[1].NotepadOpened[1] = not fcw[1].NotepadOpened[1]
				if fcw[1].NotepadOpened[1] then
					fcw[1].GuideMeOpened[1] = false
				end
				return
			end
			if (#args == 2 and args[2] == 'tod') then
				allSettings.PreciseTS[1] = not allSettings.PreciseTS[1]
				SaveSettings()
				return
			end
			if (#args == 2 and args[2] == 'ts') then
				local ts_str = os.date(par.FormatTS[1], os.time())
				if allSettings.TimeStamp12h[1] then ts_str = utils.fmt_ts_12h(ts_str) end
				print('Current Time: '..ts_str)
				return
			end
			-- /fchat menuname: dev-only diagnostic for capturing the
			-- canonical FFXI menu identifier currently on top of the
			-- addon's menu-stack.  Disabled for now; re-enable when
			-- next investigating a new menu type that needs to be
			-- wired into the chat-shift OR-chain in render.lua.
			-- [[
			--if (#args == 2 and args[2] == 'menuname') then
			--	print(dw.menuname)
			--end
			-- ]]
		end
	end)
end

return M
