-- lib/buffer.lua — chat-buffer plumbing.  Reads/writes fo.Chat[id] /
-- fo.Aux[id] via a circular cursor wrapping at ChatLines, against
-- the per-tab b.ChatBuffer[mode][2] arrays.  fcw[3] is BigMode and
-- shares the buffer with fcw[1].  All 13 functions are exposed as
-- globals for the render loop, BigMode, and the parser pipeline.

require('common')
local imgui = require('imgui')
local utils = require('utils')
local state = require('lib.state')

local fcw         = state.fcw
local fo          = state.fo
local ro          = state.ro
local b           = state.b
local dw          = state.dw
local tab         = state.tab
local allSettings = state.allSettings

-- Localised stdlib references (#12).  These are hot in the layout
-- pass and the per-frame line shifting; LuaJIT inlines them better
-- when they're locals than when they're table accesses.
local math_max     = math.max
local math_min     = math.min
local math_floor   = math.floor
local table_insert = table.insert
local table_remove = table.remove

local M = {}

-- ===================================================================
-- Reset scroll state for a window and repaint its lines.
-- ===================================================================
function M.ResetScrolling(id, ChatLines)
	fcw[id].Scrolling    = false
	fcw[id].ScrolledBack = 0
	if ChatLines then
		ResetLines(id, ChatLines)
	else
		ResetLines(id)
	end
end
_G.ResetScrolling = M.ResetScrolling

-- ===================================================================
-- Switch the active tab for chat window `fo_id`.  Updates allSettings,
-- selects the new buffer mode, rewrites all visible chat lines with
-- fresh content from that buffer, and (when BigMode is open) resets
-- BigMode's view to match.
-- ===================================================================
function M.ChangeTab(fo_id, tabName)
	if fo_id == 1 then
		allSettings.SelectedTab  = tabName
	else
		allSettings.SelectedTab2 = tabName
	end

	b.ChatBufferIdx[fo_id] = (function()
		if tabName == 'All'       then b.ChatBufferMode[fo_id] = 1; return b.ChatBufferN_All       end
		if tabName == 'AllAlt'    then b.ChatBufferMode[fo_id] = 2; return b.ChatBufferN_AllAlt    end
		if tabName == 'Combat'    then b.ChatBufferMode[fo_id] = 3; return b.ChatBufferN_Combat    end
		if tabName == 'Linkshell' then b.ChatBufferMode[fo_id] = 4; return b.ChatBufferN_Linkshell end
		if tabName == 'Party'     then b.ChatBufferMode[fo_id] = 5; return b.ChatBufferN_Party     end
		if tabName == 'Tell'      then b.ChatBufferMode[fo_id] = 6; return b.ChatBufferN_Tell      end
		if tabName == 'Shout'     then b.ChatBufferMode[fo_id] = 7; return b.ChatBufferN_Shout     end
		if tabName == 'Custom'    then b.ChatBufferMode[fo_id] = 8; return b.ChatBufferN_Custom    end
		if tabName == 'L1'        then b.ChatBufferMode[fo_id] = 9; return b.ChatBufferN_L1        end
		if tabName == 'L2'        then b.ChatBufferMode[fo_id] = 10; return b.ChatBufferN_L2       end
		return b.ChatBufferIdx[fo_id]
	end)()

	if #fo.Chat[3] > 0 then
		b.ChatBufferIdx[3] = b.ChatBufferIdx[1]
		ResetScrolling(3, fcw[3].ChatLines)
		ResetLines(3, fcw[3].ChatLines)
	end

	-- Hoist the per-tab buffer once (#2) instead of re-traversing the
	-- 4-deep table chain for every column on every line.
	local buf  = b.ChatBuffer[b.ChatBufferMode[fo_id]][2]
	local last = #buf.text  -- (#1) was utils.GetTableLen, called inside the loop
	local maxL = allSettings.ChatLines
	local L_i  = fcw[fo_id].ChatHead

	for C_i = 1, maxL do
		local idx = last - C_i + 1
		if idx > 0 then
			fo.Chat[fo_id][L_i]:set_text      (buf.text    [idx]:trimex())
			fo.Chat[fo_id][L_i]:set_font_color(buf.color   [idx])
			fo.Aux [fo_id][L_i]:set_text      (buf.auxText [idx]:trimex())
			fo.Aux [fo_id][L_i]:set_font_color(buf.auxColor[idx])
		else
			fo.Chat[fo_id][L_i]:set_text('')
			fo.Chat[fo_id][L_i]:set_font_color(0xFFFFFFFF)
			fo.Aux [fo_id][L_i]:set_text('')
			fo.Aux [fo_id][L_i]:set_visible(false)
			fo.Aux [fo_id][L_i]:set_font_color(0xFFFFFFFF)
		end
		L_i = L_i + 1
		if L_i > maxL then L_i = 1 end
	end
end
_G.ChangeTab = M.ChangeTab

-- ===================================================================
-- Repaint every visible line for window `fo_id` from the head of the
-- current buffer (most-recent line at ChatHead, older lines after).
-- Used after scroll resets, on tab switches, and when the buffer
-- becomes empty.  When ChatLines is passed (BigMode), reads from
-- ===================================================================
function M.ResetLines(fo_id, ChatLines)
	local mode_id = fo_id
	if ChatLines then mode_id = 1 else ChatLines = allSettings.ChatLines end

	-- Hoist the per-tab buffer once (#2).  All four parallel arrays
	-- (.text/.color/.auxText/.auxColor) have the same length so we
	-- only need #buf.text to drive the index (#1).
	local buf  = b.ChatBuffer[b.ChatBufferMode[mode_id]][2]
	local last = #buf.text
	local L_i  = fcw[fo_id].ChatHead

	for C_i = 1, ChatLines do
		local idx = last - C_i + 1
		if idx > 0 then
			fo.Chat[fo_id][L_i]:set_text      (buf.text    [idx]:trimex())
			fo.Chat[fo_id][L_i]:set_font_color(buf.color   [idx])
			fo.Aux [fo_id][L_i]:set_text      (buf.auxText [idx]:trimex())
			fo.Aux [fo_id][L_i]:set_font_color(buf.auxColor[idx])
			fo.Aux [fo_id][L_i]:set_visible(false)
		else
			fo.Chat[fo_id][L_i]:set_text('')
			fo.Chat[fo_id][L_i]:set_font_color(0xFF000000)
			fo.Aux [fo_id][L_i]:set_text('')
			if fo_id ~= 3 then
				fo.Aux[fo_id][L_i]:set_visible(false)
			else
				fo.Aux[fo_id][L_i]:set_visible(true)
			end
			fo.Aux [fo_id][L_i]:set_font_color(0xFF000000)
			fo.Aux [fo_id][L_i]:set_visible(false)
		end

		L_i = L_i + 1
		if L_i > ChatLines then L_i = 1 end
	end

	fcw[fo_id].ChatShift = allSettings.fontSettings.font_height
	if fo_id < 3 then
		b.ChatBufferIdx[fo_id] = b.ChatBufferN[fo_id]
	end
	fcw[fo_id].PositionLinesRequest = {true, true}
end
_G.ResetLines = M.ResetLines

-- ===================================================================
-- Jump-scroll to a specific buffer line.  Used by Shift+wheel for
-- 5-line jumps so we don't animate every intermediate line.
-- ===================================================================
function M.GoToLine(fo_id, line, currentIdx, ChatLines)
	local mode_id = fo_id
	if not ChatLines then ChatLines = allSettings.ChatLines else mode_id = 1 end

	-- Hoist (#2) + #t (#1).
	local buf  = b.ChatBuffer[b.ChatBufferMode[mode_id]][2]
	local last = #buf.text

	if line <= last and line >= ChatLines then
		local sb = currentIdx - line
		fcw[fo_id].Scrolling    = true
		fcw[fo_id].ChatShift    = allSettings.fontSettings.font_height
		fcw[fo_id].ScrolledBack = sb

		local L_i = fcw[fo_id].ChatHead
		for C_i = 1, ChatLines do
			if last - C_i + 1 - line + ChatLines > 0 then
				local idx = last - C_i + 1 - sb
				fo.Chat[fo_id][L_i]:set_text      (buf.text    [idx]:trimex())
				fo.Chat[fo_id][L_i]:set_font_color(buf.color   [idx])
				fo.Aux [fo_id][L_i]:set_text      (buf.auxText [idx]:trimex())
				fo.Aux [fo_id][L_i]:set_visible(false)
				fo.Aux [fo_id][L_i]:set_font_color(buf.auxColor[idx])
			else
				fo.Chat[fo_id][L_i]:set_text('')
				fo.Aux [fo_id][L_i]:set_text('')
				fo.Aux [fo_id][L_i]:set_visible(false)
			end

			L_i = L_i + 1
			if L_i > ChatLines then L_i = 1 end
		end

		fcw[fo_id].PositionLinesRequest = {true, true}
		fcw[fo_id].RequestAuxFix        = true
	end
end
_G.GoToLine = M.GoToLine

-- ===================================================================
-- Animate a single line scrolling in.  mode = 1 reveals an OLDER line
-- at the top (scroll up), mode = 0 reveals a NEWER line at the bottom
-- (scroll down).  Sets BufferBusy so concurrent updates are deferred,
-- and bails when a tab change is queued.
-- ===================================================================
function M.ScrollLines(fo_id, message, color, auxMessage, auxColor, mode, ChatLines)
	if not message then
		if ChatLines then
			ResetLines(fo_id, ChatLines)
		else
			ResetLines(fo_id)
		end
		return
	end
	if fcw[1].BufferBusy or tab.NextTab ~= allSettings.SelectedTab then return end

	fcw[1].BufferBusy = true
	if not ChatLines then ChatLines = allSettings.ChatLines end

	-- Cache (#14): font_height is read 4× per line below.
	local fh     = allSettings.fontSettings.font_height
	local anchor = fcw[fo_id].Anchor_Y

	fcw[fo_id].PositionLinesRequest = {true, true}

	local L_i = fcw[fo_id].ChatHead + mode
	if mode == 1 and L_i > ChatLines then L_i = 1 end

	for C_i = 0, ChatLines - 2 do
		fo.Chat[fo_id][L_i]:set_position_y(anchor - (fh * C_i))
		fo.Aux [fo_id][L_i]:set_position_y(anchor - (fh * C_i))

		L_i = L_i - 1 + (2 * mode)
		if L_i > ChatLines then L_i = 1 end
		if L_i < 1         then L_i = ChatLines end
	end

	local NL_i = fcw[fo_id].ChatHead
	if mode == 0 then
		NL_i = fcw[fo_id].ChatHead - 1
		if NL_i < 1 then NL_i = ChatLines end
	end

	fo.Chat[fo_id][NL_i]:set_font_color(color)
	fo.Chat[fo_id][NL_i]:set_position_y(anchor - (fh * ChatLines * mode))
	fo.Aux [fo_id][NL_i]:set_position_y(anchor - (fh * ChatLines * mode))
	fo.Chat[fo_id][NL_i]:set_text(message:trimex())
	fo.Aux [fo_id][NL_i]:set_font_color(auxColor)
	fo.Aux [fo_id][NL_i]:set_text(auxMessage:trimex())
	fo.Aux [fo_id][NL_i]:set_visible(false)

	fcw[fo_id].ChatHead = fcw[fo_id].ChatHead - 1 + (2 * mode)
	if fcw[fo_id].ChatHead > ChatLines then fcw[fo_id].ChatHead = 1 end
	if fcw[fo_id].ChatHead < 1         then fcw[fo_id].ChatHead = ChatLines end

	fcw[fo_id].RequestAuxFix = true
end
_G.ScrollLines = M.ScrollLines

-- ===================================================================
-- True if the mouse is inside the rect described by `params`
-- (a settings table with .position_x/.position_y/.width/.height).
-- `margin` extends the test area on each side.
-- ===================================================================
function M.IsRectHovered(params, margin)
	local x, y = imgui.GetMousePos()
	return x > params.position_x - margin
		and x < params.position_x + params.width  + margin
		and y > params.position_y - margin
		and y < params.position_y + params.height + margin
end
_G.IsRectHovered = M.IsRectHovered

-- ===================================================================
-- Compute the scrollbar position (0..1) for a chat window based on
-- how far back from the latest message we've scrolled.
-- ===================================================================
function M.GetScrollPoint(fo_id)
	local h    = 1
	local buf  = b.ChatBuffer[b.ChatBufferMode[fo_id]][2]
	local len  = #buf.text  -- (#1) was utils.GetTableLen
	if len > 0 then
		local cl = allSettings.ChatLines
		local total = len - (b.ChatBufferN[fo_id] - b.ChatBufferIdx[fo_id])
		h = (total - (fcw[fo_id].ScrolledBack + cl))
			/ math_max(total - cl - 1, 1)
	end
	return math_max(h, 0)
end
_G.GetScrollPoint = M.GetScrollPoint

-- ===================================================================
-- Layout pass: position every visible chat / aux line, plus the
-- scrollbar and forward / back arrows when PositionLinesRequest[2]
-- is set.  Handles per-line opacity for the bottom-line fade-in
-- animation driven by ChatShift.
-- For BigMode (fo_id == 3, ChatLines passed) the background rect is
-- ro.BigMode and oth_id == 1 (the scrollbar/arrows belong to fcw[1]).
-- ===================================================================
function M.PositionLines(fo_id, ChatLines)
	fcw[1].BufferBusy = true
	local BG     = ro.RectBG[fo_id]
	local oth_id = fo_id
	if not ChatLines then
		ChatLines = allSettings.ChatLines
	else
		BG     = ro.BigMode
		oth_id = 1
	end

	if not fcw[fo_id].PositionLinesRequest[1] then return end

	dw.PLRCount = dw.PLRCount + 1
	local was2requested = fcw[fo_id].PositionLinesRequest[2]

	-- Cache (#14): font_height read up to 4× per line below.
	local fh = allSettings.fontSettings.font_height

	if fcw[fo_id].PositionLinesRequest[2] then
		BG:set_position_x(fcw[fo_id].Anchor_X - fcw[1].RoRectBaseX)
		BG:set_position_y(fcw[fo_id].Anchor_Y - fcw[fo_id].RoRectBaseY)
		if was2requested then
			if fcw[fo_id].ScrollPos then
				ro.Scroll[oth_id]:set_width (BG.settings.width  / 200)
				ro.Scroll[oth_id]:set_height(BG.settings.height / 15)
				local h = BG.settings.position_y
					+ (ro.Scroll[oth_id].settings.height * (1 - fcw[fo_id].ScrollPos)
						+ (fh * 1.15))
					- (1 - (fcw[fo_id].ScrollPos * BG.settings.height
						- ro.Scroll[oth_id].settings.height
						- fh * 1.15))
				ro.Scroll[oth_id]:set_position_y(h + 1)
				ro.Scroll[oth_id]:set_position_x(BG.settings.position_x + BG.settings.width - ro.Scroll[oth_id].settings.width - 1)
			end
			fo.Fwd[oth_id]:set_position_x(BG.settings.position_x + BG.settings.width - fcw[1].FWDBaseX)
			fo.Fwd[oth_id]:set_position_y(fcw[fo_id].Anchor_Y)
			fo.Bkw[oth_id]:set_position_x(fcw[fo_id].Anchor_X - fcw[1].BKWBaseX)
			fo.Bkw[oth_id]:set_position_y(fcw[fo_id].Anchor_Y - fcw[1].BKWBaseY)
		end
	end

	local fcwFoId = fcw[fo_id]
	fcwFoId.PositionLinesRequest = {false, false}

	local anchorX = fcwFoId.Anchor_X
	local anchorY = fcwFoId.Anchor_Y
	local shift   = fcwFoId.ChatShift

	local L_i = fcwFoId.ChatHead
	for C_i = 1, ChatLines do
		local chatLi = fo.Chat[fo_id][L_i]
		local auxLi  = fo.Aux [fo_id][L_i]

		local isLastLine = L_i + 1 == fcwFoId.ChatHead or L_i + 1 - ChatLines == fcwFoId.ChatHead

		if isLastLine and shift > 0 then
			local opacity = shift / fh
			if opacity < 0.1 then opacity = 0.1 end
			chatLi:set_opacity(opacity)
			auxLi:set_opacity (opacity)
		else
			chatLi:set_opacity(1)
			auxLi:set_opacity (1)
		end

		chatLi:set_position_y(shift + anchorY - (fh * C_i))
		chatLi:set_position_x(anchorX)
		auxLi:set_position_y (shift + anchorY - (fh * C_i))

		if #auxLi.settings.text > 0 then
			if chatLi.rect == nil or chatLi.is_dirty then
				fcw[fo_id].RequestAuxFix = true
			else
				auxLi:set_position_x(math_floor(anchorX + chatLi.rect.right + fh / 1.7))
			end
		end

		L_i = L_i + 1
		if L_i > ChatLines then L_i = 1 end
	end

	fo.Chat[fo_id][fcw[fo_id].ChatHead]:set_visible(true)
	fo.Chat[fo_id][fcw[fo_id].ChatHead]:set_opacity(1)
	if not fcw[fo_id].RequestAuxFix then
		fo.Aux[fo_id][fcw[fo_id].ChatHead]:set_visible(true)
		fo.Aux[fo_id][fcw[fo_id].ChatHead]:set_opacity(1)
	end
end
_G.PositionLines = M.PositionLines

-- ===================================================================
-- Set opacity on every chat + aux line in window `fo_id`.  Used for
-- hide-chat and auto-hide fades.
-- ===================================================================
function M.SetChatOpacity(opacity, fo_id)
	for C_i = 1, #fo.Chat[fo_id] do
		fo.Chat[fo_id][C_i]:set_opacity(opacity)
		fo.Aux [fo_id][C_i]:set_opacity(opacity)
	end
end
_G.SetChatOpacity = M.SetChatOpacity

-- ===================================================================
-- After a layout pass, the main text's render rect may not have been
-- ready when PositionLines tried to anchor the aux text to the right
-- of it.  FixAux is called the next frame to fix any pending positions.
-- Bails out of the loop if any chat line is still dirty (so we'll be
-- called again next frame), keeping RequestAuxFix true.
-- ===================================================================
function M.FixAux(fo_id, ChatLines)
	if not ChatLines then ChatLines = allSettings.ChatLines end
	-- Cache (#14): used inside the inner branch.
	local fh      = allSettings.fontSettings.font_height
	local anchorX = fcw[fo_id].Anchor_X
	for C_i = 1, ChatLines do
		if #fo.Aux[fo_id][C_i].settings.text > 0 then
			fo.Chat[fo_id][C_i]:set_visible(true)
			fo.Chat[fo_id][C_i]:set_opacity(1)
			if fo.Chat[fo_id][C_i].rect == nil or fo.Chat[fo_id][C_i].is_dirty then return end
			fo.Aux[fo_id][C_i]:set_position_x(math_floor(anchorX + fo.Chat[fo_id][C_i].rect.right + fh / 1.7))
			fo.Aux[fo_id][C_i]:set_visible(true)
			fo.Aux[fo_id][C_i]:set_opacity(1)
		end
	end
	fcw[fo_id].RequestAuxFix = false
end
_G.FixAux = M.FixAux

-- ===================================================================
-- Append a new line at the bottom WITHOUT animation (instant).  Used
-- the next call's "bottom slot" rotates into the previously-newest
-- slot.  Sets BufferBusy.
-- ===================================================================
function M.UpdateLines(fo_id, message, color, auxMessage, auxColor, ChatLines)
	fcw[1].BufferBusy = true
	if not ChatLines then ChatLines = allSettings.ChatLines end

	-- Cache (#14): font_height + Anchor_Y read 2× per line below.
	local fh      = allSettings.fontSettings.font_height
	local anchorY = fcw[fo_id].Anchor_Y

	local L_i = fcw[fo_id].ChatHead
	for C_i = 1, ChatLines - 1 do
		fo.Chat[fo_id][L_i]:set_position_y(anchorY - (fh * C_i))
		fo.Aux [fo_id][L_i]:set_position_y(anchorY - (fh * C_i))
		L_i = L_i + 1
		if L_i > ChatLines then L_i = 1 end
	end

	if fo.Chat[fo_id][L_i].settings.font_color ~= color then
		fo.Chat[fo_id][L_i]:set_font_color(color)
	end

	fo.Chat[fo_id][L_i]:set_position_y(anchorY)
	fo.Aux [fo_id][L_i]:set_position_y(anchorY)
	fo.Chat[fo_id][L_i]:set_text(message:trimex())
	fo.Aux [fo_id][L_i]:set_font_color(auxColor)
	fo.Aux [fo_id][L_i]:set_text(auxMessage:trimex())
	fo.Aux [fo_id][L_i]:set_visible(false)
	fo.Chat[fo_id][L_i]:set_visible(false)
	fo.Chat[fo_id][L_i]:set_opacity(1)
	fo.Aux [fo_id][L_i]:set_opacity(1)

	fcw[fo_id].ChatHead = fcw[fo_id].ChatHead - 1
	if fcw[fo_id].ChatHead < 1 then fcw[fo_id].ChatHead = ChatLines end
end
_G.UpdateLines = M.UpdateLines

-- ===================================================================
-- Drop the first `count` entries from `buffer`'s parallel arrays.
-- Used to enforce the per-tab buffer size cap.
-- ===================================================================
function M.BulkRemove(buffer, count)
	local hasMode = buffer.mode ~= nil
	local size = #buffer.text
	if count >= size then
		buffer.text     = {}
		buffer.mode     = {}
		buffer.color    = {}
		buffer.auxText  = {}
		buffer.auxColor = {}
		buffer.url      = {}
	else
		local newText, newMode, newColor, newAuxText, newAuxColor, newUrl = {}, {}, {}, {}, {}, {}
		for i = count + 1, size do
			newText    [#newText     + 1] = buffer.text    [i]
			if hasMode then
				newMode[#newMode     + 1] = buffer.mode    [i]
			end
			newColor   [#newColor    + 1] = buffer.color   [i]
			newAuxText [#newAuxText  + 1] = buffer.auxText [i]
			newAuxColor[#newAuxColor + 1] = buffer.auxColor[i]
			newUrl     [#newUrl      + 1] = buffer.url     [i]
		end
		buffer.text = newText
		if hasMode then
			buffer.mode = newMode
		end
		buffer.color    = newColor
		buffer.auxText  = newAuxText
		buffer.auxColor = newAuxColor
		buffer.url      = newUrl
	end
end
_G.BulkRemove = M.BulkRemove

-- ===================================================================
-- Remove specific (sorted ascending) line indices from `buffer`.
-- Used to retroactively drop combat lines when a CL filter rule is
-- enabled after the lines were already added to the buffer.
-- ===================================================================
function M.BulkRemoveCombat(buffer, line)
	local hasMode = buffer.mode ~= nil
	local size = #buffer.text

	local newText, newMode, newColor, newAuxText, newAuxColor, newUrl = {}, {}, {}, {}, {}, {}
	local L_i = 1
	for i = 1, size do
		if L_i > #line or i ~= line[L_i] then
			newText    [#newText     + 1] = buffer.text    [i]
			if hasMode then
				newMode[#newMode     + 1] = buffer.mode    [i]
			end
			newColor   [#newColor    + 1] = buffer.color   [i]
			newAuxText [#newAuxText  + 1] = buffer.auxText [i]
			newAuxColor[#newAuxColor + 1] = buffer.auxColor[i]
			newUrl     [#newUrl      + 1] = buffer.url     [i]
		else
			L_i = L_i + 1
		end
	end
	buffer.text = newText
	if hasMode then
		buffer.mode = newMode
	end
	buffer.color    = newColor
	buffer.auxText  = newAuxText
	buffer.auxColor = newAuxColor
	buffer.url      = newUrl
end
_G.BulkRemoveCombat = M.BulkRemoveCombat

return M
