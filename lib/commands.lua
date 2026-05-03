--[[
	lib/commands.lua

	Handles the /fancychat (alias /fchat) slash-command surface.
	Subcommands:

	  debug       Toggle debug-window visibility.
	  bigmode     Toggle BigMode chat overlay.
	  savelogs    Snapshot every tab's chat buffer to logs/<player>/.
	  savedebug   Flush the debug LogBuffer to disk and clear it.
	  test M ...  Inject a synthetic message in chat-mode M (0-255).
	  printdebug  Print the welcome blurb.
	  helpdebug   Dump help.foundParent introspection.
	  guideme     Toggle GuideMe panel.
	  settings    Toggle settings panel and persist.
	  compact     Toggle compact tab bar and persist.
	  manual      Toggle the in-game manual window.
	  notes       Toggle Notepad panel.
	  tod         Toggle precise-timestamp mode and persist.
	  ts          Print current time using the active timestamp format.
]]

require('common')
local utils = require('utils')
local help  = require('help')
local state = require('lib.state')

local fcw         = state.fcw
local dw          = state.dw
local b           = state.b
local par         = state.par
local allSettings = state.allSettings

local M = {}

function M.register()
	ashita.events.register('command', 'command_cb', function (e)
		local args = e.command:args()
		if (#args == 0 or (not args[1]:any('/fancychat') and not args[1]:any('/fchat'))) then
			return
		end

		e.blocked = true

		if (#args == 2 and args[2] == 'debug') then
			dw.WindowOpened[1] = not dw.WindowOpened[1]
			return
		end
		if (#args == 2 and args[2] == 'bigmode') then
			fcw[3].BigMode = not fcw[3].BigMode
			return
		end
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

		if (#args == 2 and args[2] == 'savedebug') then
			local ts = os.date('[%Y_%m_%d-%H_%M_%S]', os.time())
			if utils.SaveLogs(b.LogBuffer, nil, 'DEBUG', fcw[1].PlayerName, addon.path, ts) then
				b.LogBuffer = {}
			end
			return
		end

		if (#args > 3 and args[2] == 'test' and tonumber(args[3]) >= 0 and tonumber(args[3]) <= 255) then
			local test_string = ''
			local test_i = 4
			while args[test_i] ~= nil do
				test_string = test_string..args[test_i]..' '
				test_i = test_i + 1
			end
			AshitaCore:GetChatManager():AddChatMessage(tonumber(args[3]), false, test_string:trimex()..'\127\49')
			return
		end

		if (#args == 2 and args[2] == 'printdebug') then
			-- Dump every legacy palette slot to chat with its index as
			-- the visible label.  Each label is wrapped in its own
			-- colour escape so FFXI's native chat renderer paints it
			-- in that palette colour — letting us read the actual RGB
			-- off a screenshot for any slot the chat.colors table
			-- doesn't document.
			--
			-- Output format (16 labels per AddChatMessage call):
			--   Header: "== Table 1 (\x1E\NN) ==" / "== Table 2 (\x1F\NN) =="
			--   Body:   \x1F\NN<NN> repeated, with trailing reset.
			--
			-- View in the LEGACY FFXI chat (set blockAll OFF in
			-- Settings → Extra) — that's where FFXI itself renders
			-- the colours; FancyChat's own renderer doesn't speak the
			-- legacy palette.
			local function dump_palette(lead_byte, label)
				AshitaCore:GetChatManager():AddChatMessage(122, false,
					'== Palette Table '..label..' ('..string.format('\\x%02X', lead_byte)..'\\NN) ==')
				local line = ''
				local count = 0
				for n = 1, 255 do
					local color  = string.char(lead_byte, n)
					local reset  = string.char(0x1E, 0x01)
					line = line..color..string.format('%03d', n)..reset..' '
					count = count + 1
					if count == 16 or n == 255 then
						AshitaCore:GetChatManager():AddChatMessage(6, false, line)
						line = ''
						count = 0
					end
				end
			end
			dump_palette(0x1E, '1')
			dump_palette(0x1F, '2')
			AshitaCore:GetChatManager():AddChatMessage(122, false,
				'== Palette dump complete.  View in legacy chat (blockAll OFF). ==')
		end

		if (#args == 2 and args[2] == 'helpdebug') then
			print(#help.foundParent)
			print(tostring(help.foundAnything))
			print(table.concat(help.foundParent, ','))
		end

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
				print('Current Time: '..os.date(par.FormatTS[1], os.time()))
				return
			end
		end
	end)
end

return M
