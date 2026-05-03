--[[
	lib/debug_window.lua

	The `/fchat debug` window and its sibling helpers.  This is the
	developer-facing diagnostic UI that's NOT meant for end users —
	it's only opened explicitly via the `debug` subcommand or the
	checkbox bound to dw.WindowOpened.

	Three exported functions, all also installed as globals so the
	render loop and command handler can reach them by name:

	  updateCommandList(text)
	    Per-character chat-input history maintenance.  Pushes `text`
	    to the front of fcw[1].LastCommands[1] and trims to a 20-entry
	    sliding window.

	  DebugWindow()
	    The main diagnostic ImGui window.  Walks dw.testPTR through a
	    chain of memory pointers (revealing FFXI's internal menu/dialog
	    state), shows live buffer counts, parser state, scroll position,
	    and the dw.TestMessage / dw.TestMessage2 staging strings.  Also
	    exposes the Show-Message-Mode / Show-Channel-Color toggles
	    that paint debug colors over the live chat.

	  Debug(msg, target, chained)
	    Append a string to one of the two staging text buffers
	    (dw.TestMessage / dw.TestMessage2) shown by DebugWindow.
	    target=1 picks the first buffer, target=2 the second.
	    chained=true appends a newline + prefix; otherwise overwrites.

	The implicit-global variables `dw_WindowW`, `dw_WindowH`,
	`dw_testPTR2`..`dw_testPTR5`, `dw_testString` are LEFT AS GLOBALS
	(not declared local) — they're scratch debug storage that nothing
	else in the codebase reads, and inadvertently localising them
	would change the semantics of the existing code that assigns them
	in DebugWindow's body and re-reads them from `imgui.SetNextWindowSize`
	the following frame.
]]

require('common')
local imgui     = require('imgui')
local imguiWrap = require('imguiWrap')
local utils     = require('utils')
local state     = require('lib.state')

local fcw = state.fcw
local uiw = state.uiw
local par = state.par
local b   = state.b
local dw  = state.dw

local M = {}

function M.updateCommandList(text)
	table.insert(fcw[1].LastCommands[1], 1, text)
	if #fcw[1].LastCommands[1] > 20 then
		table.remove(fcw[1].LastCommands[1], #fcw[1].LastCommands[1])
	end
end
_G.updateCommandList = M.updateCommandList

function M.DebugWindow()
	imgui.SetNextWindowSize({dw_WindowW, dw_WindowH})
	imgui.SetNextWindowSizeConstraints({200, 500}, {FLT_MAX, FLT_MAX})
	imgui.Begin('FancyChat_Debug_'+fcw[1].PlayerName, dw.WindowOpened)

	if next(b.ChatBuffer[1][2]) ~= nil then
		-- Memory pointer chase: dw.testPTR -> testPTR2 -> testPTR3 ->
		-- testPTR4 -> testPTR5 -> string.  Reveals the active dialog
		-- /menu name FFXI is rendering.  Each step's offset was
		-- determined empirically from the FFXI client.
		dw_testPTR2 = ashita.memory.read_uint32(dw.testPTR + 0x04)
		imgui.Text('dw_testPTR: '..bit.tohex(dw.testPTR + 0x04))
		imgui.Text('dw_testPTR Value: '..bit.tohex(dw_testPTR2))
		dw_testPTR3 = ashita.memory.read_uint32(dw_testPTR2 + 0x14)
		imgui.Text('dw_testPTR2: '..bit.tohex(dw_testPTR2 + 0x14))
		imgui.Text('dw_testPTR2 Value: '..bit.tohex(dw_testPTR3))
		dw_testPTR4 = ashita.memory.read_uint32(dw_testPTR3 + 0x10)
		imgui.Text('dw_testPTR3: '..bit.tohex(dw_testPTR3 + 0x10))
		imgui.Text('dw_testPTR3 Value: '..bit.tohex(dw_testPTR4))
		dw_testPTR5 = ashita.memory.read_uint32(dw_testPTR4 + 0x2C)
		imgui.Text('dw_testPTR4: '..bit.tohex(dw_testPTR4 + 0x2C))
		imgui.Text('dw_testPTR5 Value: '..bit.tohex(dw_testPTR5))
		dw_testString = ashita.memory.read_string(dw_testPTR5, 16)
		imgui.Text('dw_testPTRString: '..tostring(dw_testString))

		-- Buffer counts: visible-vs-stored line totals per tab.
		imgui.Text('buff_idx '   ..tostring(b.ChatBufferIdx[1]))
		imgui.Text('buff_idx3 '  ..tostring(b.ChatBufferIdx[3]))
		imgui.Text('buff_All '   ..tostring(#b.ChatBuffer[1][2].text)..',N: '..tostring(b.ChatBufferN_All))
		imgui.Text('buff_AA '    ..tostring(#b.ChatBuffer[2][2].text)..',N: '..tostring(b.ChatBufferN_AllAlt))
		imgui.Text('buff_C '     ..tostring(#b.ChatBuffer[3][2].text)..',N: '..tostring(b.ChatBufferN_Combat))
		imgui.Text('buff_LS '    ..tostring(#b.ChatBuffer[4][2].text)..',N: '..tostring(b.ChatBufferN_Linkshell))
		imgui.Text('buff_PT '    ..tostring(#b.ChatBuffer[5][2].text)..',N: '..tostring(b.ChatBufferN_Party))
		imgui.Text('buff_SH '    ..tostring(#b.ChatBuffer[7][2].text)..',N: '..tostring(b.ChatBufferN_Shout))
		imgui.Text('buff_Custom '..tostring(#b.ChatBuffer[6][2].text)..',N: '..tostring(b.ChatBufferN_Custom))

		local buffsum = 0
		for i = 3, 7 do buffsum = buffsum + #b.ChatBuffer[i][2].text end
		imgui.Text('buff_Sum '..tostring(buffsum))
		imgui.Text('buff_AA+C '..tostring(#b.ChatBuffer[2][2].text + #b.ChatBuffer[3][2].text))

		-- Parallel-array sanity check: every per-tab array should have
		-- the same length.  Mismatches mean an insert path got out of
		-- sync (typically a regression in parseThis).
		local MBcheck = false
		if #b.ChatBuffer[1][2].color    == #b.ChatBuffer[1][2].auxText
			and #b.ChatBuffer[1][2].auxText  == #b.ChatBuffer[1][2].auxColor
			and #b.ChatBuffer[1][2].auxColor == #b.ChatBuffer[1][2].url then
			MBcheck = true
		end
		imgui.Text('mb check '..tostring(MBcheck))

		-- Live state dumps.
		imgui.Text('movechat '   ..tostring(fcw[1].MoveChat))
		imgui.Text('invidx '     ..tostring(uiw.InvIdx))
		imgui.Text('noshiftidx ' ..tostring(uiw.NoShiftIdx))
		imgui.Text('menuext '    ..tostring(uiw.MenuExt))
		imgui.Text('wasinequip ' ..tostring(uiw.WasInEquip))
		imgui.Text('wasininv '   ..tostring(uiw.WasInInv))
		imgui.Text('diagshown '  ..tostring(uiw.DialogShown))
		imgui.Text('isinnconv '  ..tostring(par.IsInConv))
		imgui.Text('inevent '    ..tostring(par.InEvent))

		imgui.Text(tostring(fcw[1].ScrollPos))
		imgui.Text(tostring(fcw[1].PrevMousePos[2]))
		imgui.Text(tostring(fcw[1].ChatShift))
		imgui.Text(tostring(fcw[1].Anchor_Y))
		imgui.Text(tostring(b.ChatBufferN[2]))
		imgui.Text(tostring(b.ChatBufferIdx[2]))
		imgui.Text(tostring(dw.PLRCount))
		imgui.Text(tostring(b.ChatBuffer[2][2].url[#b.ChatBuffer[2][2].url]))

		-- Scratch text staging panel populated by Debug(msg, t, c).
		imguiWrap.BeginChild('Debugchild', {imgui.GetWindowWidth() * 0.8, imgui.GetWindowHeight() * 0.8, true})
		imgui.Text(dw.TestMessage)
		imgui.Text(dw.TestMessage2)
		imgui.EndChild()
	end

	if imgui.Checkbox('Show Message Mode', {dw.ShowMessageMode[1]}) then
		dw.ShowMessageMode[1] = not dw.ShowMessageMode[1]
	end
	if imgui.Checkbox('Show Combat Channel Color', {dw.ChannelColorMode[1]}) then
		dw.ChannelColorMode[1] = not dw.ChannelColorMode[1]
	end
	if imgui.Button('Reset Test Messages') then
		dw.TestMessage  = ''
		dw.TestMessage2 = ''
	end
	dw_WindowW, dw_WindowH = imgui.GetWindowSize()
	imgui.End()
end
_G.DebugWindow = M.DebugWindow

function M.Debug(msg, target, chained)
	if target == 1 then
		if chained then
			if #dw.TestMessage < 4000 then
				dw.TestMessage = dw.TestMessage..'\ntm> '..msg
			end
		else
			dw.TestMessage = 'tm> '..msg
		end
	elseif target == 2 then
		if chained then
			if #dw.TestMessage < 4000 then
				dw.TestMessage2 = dw.TestMessage2..'\ntm2> '..msg
			end
		else
			dw.TestMessage2 = 'tm2> '..msg
		end
	end
end
_G.Debug = M.Debug

return M
