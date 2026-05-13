-- lib/bigmode.lua — full-screen chat-history overlay (fcw[3]).  A
-- second view of b.ChatBuffer for scroll-back review.  Exposes
-- ShowBigMode / DrawBigMode / DestroyBigMode as globals.

require('common')
local imgui     = require('imgui')
local imguiWrap = require('imguiWrap')
local gdi       = require('gdifonts.include')
local utils     = require('utils')
local state     = require('lib.state')

local fcw            = state.fcw
local fo             = state.fo
local ro             = state.ro
local b              = state.b
local allSettings    = state.allSettings
local gamepadButtons = state.gamepadButtons

local M = {}

function M.show(visible)
	ro.BigMode:set_visible(visible)
	fo.BigMode:set_visible(visible)
	for C_i = 1, fcw[3].ChatLines do
		if fo.Chat[3][C_i] then fo.Chat[3][C_i]:set_visible(visible) end
		if fo.Aux[3][C_i]  then fo.Aux[3][C_i]:set_visible(visible)  end
	end
end
_G.ShowBigMode = M.show

function M.draw()
	ResetAutoHideTimer()

	local dsize = imgui.GetIO().DisplaySize

	-- Anchor the overlay at the lower-left quadrant of the screen.
	fcw[3].Anchor_X = dsize.x * 0.1
	fcw[3].Anchor_Y = dsize.y * 0.9

	local ChatLines = fcw[3].ChatLines

	-- Lazy GDI creation: build fcw[3]'s font/aux objects on first call.
	if #fo.Chat[3] == 0 then
		for L_i = 1, ChatLines do
			table.insert(fo.Chat[3], gdi:create_object(allSettings.fontSettings, false))
			table.insert(fo.Aux[3],  gdi:create_object(allSettings.fontSettings, false))

			fo.Chat[3][L_i]:set_font_height(allSettings.fontSettings.font_height)
			fo.Aux[3][L_i]:set_font_height(allSettings.fontSettings.font_height)
			fo.Chat[3][L_i]:set_position_x(fcw[3].Anchor_X)
			fo.Chat[3][L_i]:set_position_y(fcw[3].Anchor_Y - (allSettings.fontSettings.font_height * (L_i - 1)))
			if fo.Chat[3][L_i].rect ~= nil then
				fo.Aux[3][L_i]:set_position_x(fcw[3].Anchor_X + fo.Chat[3][L_i].rect.right)
			else
				fo.Aux[3][L_i]:set_position_x(fcw[3].Anchor_X)
				fo.Aux[3][L_i]:set_visible(false)
			end
			fo.Aux[3][L_i]:set_position_y(fcw[3].Anchor_Y - (allSettings.fontSettings.font_height * (L_i - 1)))
		end
	end

	-- Background rect: full chat width × (ChatLines+1) rows tall.
	ro.BigMode:set_fill_color(allSettings.rectSettings.fill_color)
	ro.BigMode:set_width(allSettings.chatLineMaxL * allSettings.fontSettings.font_height * 0.58)
	ro.BigMode:set_height(allSettings.fontSettings.font_height * (ChatLines + 1) + (allSettings.fontSettings.font_height / 5))
	ro.BigMode:set_position_x(fcw[3].Anchor_X)
	ro.BigMode:set_position_y(dsize.y - fcw[3].Anchor_Y + allSettings.fontSettings.font_height - (allSettings.fontSettings.font_height - fcw[3].HLeft))

	-- Title bar showing which tab is being viewed.
	fo.BigMode:set_position_x(fcw[3].Anchor_X)
	fo.BigMode:set_position_y(dsize.y - fcw[3].Anchor_Y + allSettings.fontSettings.font_height - (allSettings.fontSettings.font_height - fcw[3].HLeft))
	fo.BigMode:set_text('Big Mode: ['..allSettings.SelectedTab:gsub('AllAlt', 'All')..']')

	imgui.SetNextWindowSize({fcw[3].BG_W, ro.BigMode.settings.height + 16}, ImGuiCond_None)

	local adjust = dsize.y / 88
	imgui.SetNextWindowPos(
		{fcw[3].Anchor_X - 2, fcw[3].Anchor_Y - adjust - (ChatLines * allSettings.fontSettings.font_height)},
		ImGuiCond_None)

	if imgui.Begin('FancyChat_BigModeBG_'+fcw[1].PlayerName, true,
		bit.bor(fcw[1].windowFlagsChatBG, ImGuiWindowFlags_NoMove)) then

		local positionStartX, positionStartY = imgui.GetCursorScreenPos()
		local imageSizeX = (fcw[3].BG_W / 2)
		local mouseX, mouseY = imgui.GetMousePos()

		-------------------------------------------------------------
		-- Hover detection: per-line, with two paths
		--   1. Hovering an aux marker '[link]' -> click opens the URL
		--   2. Hovering anywhere else on the line -> highlight bar
		-------------------------------------------------------------
		if IsRectHovered(ro.BigMode.settings, 0) then
			fcw[3].HoverLine = -1
			local lineOffsetBase = (fcw[3].BG_H / 120) + allSettings.fontSettings.font_height
			for HL_i = 0, ChatLines - 1 do
				local lineOffset = lineOffsetBase + HL_i * allSettings.fontSettings.font_height
				local highlight_alpha = 0
				local targetLine = ChatLines - HL_i + fcw[3].ChatHead - 1
				if targetLine > ChatLines then targetLine = targetLine - ChatLines end

				if fo.Aux[3][targetLine].settings.visible
					and fo.Aux[3][targetLine].settings.text == '[link]'
					and fo.Chat[3][targetLine].rect ~= nil
					and fo.Aux[3][targetLine].rect ~= nil
					and mouseX > fo.Aux[3][targetLine].settings.position_x
					and mouseX < fo.Aux[3][targetLine].settings.position_x + fo.Aux[3][targetLine].rect.right
					and mouseY > positionStartY + lineOffset
					and mouseY < positionStartY + lineOffset + allSettings.fontSettings.font_height
					and not fcw[1].Dragging then

					if fo.Aux[3][targetLine] ~= nil then
						fo.Aux[3][targetLine]:set_font_color(0xFFCCEEFF)
						fcw[3].HoverLine = ChatLines - HL_i
						local ChatHoverIdx = #b.ChatBuffer[b.ChatBufferMode[1]][2].url
							- fcw[3].HoverLine - fcw[3].ScrolledBack
							- (b.ChatBufferN[1] - b.ChatBufferIdx[3]) + 1

						if ChatHoverIdx > 0 and imgui.IsMouseClicked(ImGuiMouseButton_Left) then
							local urlText = utils.stringsplit(b.ChatBuffer[b.ChatBufferMode[1]][2].url[ChatHoverIdx], '|')
							ashita.misc.open_url(string.find(urlText[2], 'https://') and urlText[2] or 'https://'..urlText[2])
						end
						fcw[3].HoverLine = -1
					end
				else
					if fo.Aux[3][targetLine] ~= nil and fo.Aux[3][targetLine].settings.text == '[link]' then
						fo.Aux[3][targetLine]:set_font_color(0xFF44CCFF)
					end
					if mouseX > fcw[3].Anchor_X
						and mouseX < fcw[3].Anchor_X + fcw[3].BG_W
						and mouseY > positionStartY + lineOffset
						and mouseY < positionStartY + lineOffset + allSettings.fontSettings.font_height
						and imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly) then

						fcw[3].HoverLine = ChatLines - HL_i
						highlight_alpha = 0.3
						imgui.GetWindowDrawList():AddRectFilledMultiColor(
							{fcw[3].Anchor_X, positionStartY + lineOffset},
							{fcw[3].Anchor_X + imageSizeX, positionStartY + lineOffset + allSettings.fontSettings.font_height},
							imgui.GetColorU32({1.0, 1.0, 1.0, highlight_alpha}),
							imgui.GetColorU32({1.0, 1.0, 1.0, 0.0}),
							imgui.GetColorU32({1.0, 1.0, 1.0, 0.0}),
							imgui.GetColorU32({1.0, 1.0, 1.0, highlight_alpha}))
					end
				end
			end
		end

		if fcw[3].HoverLine > 0 and imgui.IsMouseClicked(ImGuiMouseButton_Left) then
			fcw[3].Clicking = true
		end

		-------------------------------------------------------------
		-- Hover-to-copy: collect the contiguous run of buffer lines
		-- that share the same url id (i.e. the same logical message
		-- before line wrapping) and on click copy / save it.
		-------------------------------------------------------------
		if fcw[3].HoverLine > 0 and imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly) then
			local copyBufferIdx = #b.ChatBuffer[b.ChatBufferMode[1]][2].text
				- fcw[3].HoverLine - fcw[3].ScrolledBack
				- (b.ChatBufferN[1] - b.ChatBufferIdx[3]) + 1
			local copyBufferText = ''

			if copyBufferIdx > 0 then
				local ID  = b.ChatBuffer[b.ChatBufferMode[1]][2].url[copyBufferIdx]
				local IDs = 0
				local IDe = 0
				while b.ChatBuffer[b.ChatBufferMode[1]][2].url[copyBufferIdx + IDs]
					and b.ChatBuffer[b.ChatBufferMode[1]][2].url[copyBufferIdx + IDs] == ID do
					IDs = IDs - 1
				end
				while b.ChatBuffer[b.ChatBufferMode[1]][2].url[copyBufferIdx + IDe]
					and b.ChatBuffer[b.ChatBufferMode[1]][2].url[copyBufferIdx + IDe] == ID do
					IDe = IDe + 1
				end

				local IDi = math.min(IDs + 1, 0)
				while IDi <= math.max(IDe - 1, 0) do
					if b.ChatBuffer[b.ChatBufferMode[1]][2].text[copyBufferIdx + IDi] then
						copyBufferText = (' '..copyBufferText..b.ChatBuffer[b.ChatBufferMode[1]][2].text[copyBufferIdx + IDi]):trimex()
						if b.ChatBuffer[b.ChatBufferMode[1]][2].auxText[copyBufferIdx + IDi] ~= '[link]' then
							copyBufferText = copyBufferText..' '..b.ChatBuffer[b.ChatBufferMode[1]][2].auxText[copyBufferIdx + IDi]
						end
					else
						break
					end
					IDi = IDi + 1
				end
			end

			copyBufferText = utils.cleanMC(copyBufferText)

			if fcw[3].Clicking and imgui.IsMouseReleased(ImGuiMouseButton_Left) then
				fcw[3].Clicking = false
				if copyBufferText ~= nil then
					if imgui.GetIO().KeyShift then
						if #allSettings.Notes < 10 and #copyBufferText > 0 then
							table.insert(allSettings.Notes, copyBufferText)
							SaveSettings()
						end
					else
						utils.SetClipboardText(utils.RevertShiftJIS(copyBufferText))
						AshitaCore:GetChatManager():QueueCommand(1, '/echo Text successfully copied to clipboard!')
					end
				end
			end
		end

		if fcw[3].Clicking
			and (imgui.IsMouseDragging(ImGuiMouseButton_Left) or not imgui.IsMouseDown(ImGuiMouseButton_Left)) then
			fcw[3].Clicking = false
		end

		-------------------------------------------------------------
		-- Mouse-wheel scroll.  Shift held lets one wheel tick jump
		-- 5 lines via GoToLine instead of one-by-one ScrollLines.
		-------------------------------------------------------------
		if (imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly) or gamepadButtons.enabled)
			and not fcw[1].BufferBusy then

			if fcw[3].ScrollDelta > 0
				and #b.ChatBuffer[b.ChatBufferMode[1]][2].text
					- fcw[3].ScrolledBack
					- (b.ChatBufferN[1] - b.ChatBufferIdx[3]) > ChatLines then

				if not imgui.GetIO().KeyShift or not fcw[3].Scrolling then
					fcw[1].ScrollDelta = 0
					fcw[2].ScrollDelta = 0
					fcw[3].ScrollDelta = 0
					fcw[3].Scrolling = true
					fcw[3].ChatShift = allSettings.fontSettings.font_height
					fcw[3].ScrollUpRequest = true
				elseif fcw[3].Scrolling then
					local currentIdx = #b.ChatBuffer[b.ChatBufferMode[1]][2].text - (b.ChatBufferN[1] - b.ChatBufferIdx[3]) - 1
					GoToLine(3, math.max(currentIdx - (fcw[3].ScrolledBack + 5), ChatLines), currentIdx, ChatLines)
				end

			elseif fcw[3].ScrollDelta < 0 and fcw[3].ScrolledBack > 0 then
				if not imgui.GetIO().KeyShift or not fcw[3].Scrolling then
					fcw[1].ScrollDelta = 0
					fcw[2].ScrollDelta = 0
					fcw[3].ScrollDelta = 0
					fcw[3].Scrolling = true
					fcw[3].ChatShift = allSettings.fontSettings.font_height
					fcw[3].ScrollDownRequest = true
				elseif fcw[3].Scrolling then
					local currentIdx = #b.ChatBuffer[b.ChatBufferMode[1]][2].text - (b.ChatBufferN[1] - b.ChatBufferIdx[3]) - 1
					GoToLine(3, math.min(currentIdx - (fcw[3].ScrolledBack - 5), currentIdx - 1), currentIdx, ChatLines)
				end
			end
		end
		fcw[3].ScrollDelta = 0

		-- Right click anywhere: snap every chat back to bottom.
		if imgui.IsMouseClicked(ImGuiMouseButton_Right) then
			if fcw[1].ScrolledBack > 0 then ResetScrolling(1) end
			if fcw[2].ScrolledBack > 0 then ResetScrolling(2) end
			if fcw[3].ScrolledBack > 0 then ResetScrolling(3, ChatLines) end
		end

		imgui.End()
	end

	-------------------------------------------------------------
	-- After hover/scroll handling: dispatch any buffered scroll
	-- request, or step ChatBufferIdx[3] forward when caught up.
	-------------------------------------------------------------
	if fcw[3].Scrolling and fcw[3].ScrollUpRequest and not fcw[1].BufferBusy then
		fcw[3].ScrollUpRequest = false
		local idx = #b.ChatBuffer[b.ChatBufferMode[1]][2].text
			- ChatLines - fcw[3].ScrolledBack
			- (b.ChatBufferN[1] - b.ChatBufferIdx[3])
		ScrollLines(3,
			b.ChatBuffer[b.ChatBufferMode[1]][2].text    [idx],
			b.ChatBuffer[b.ChatBufferMode[1]][2].color   [idx],
			b.ChatBuffer[b.ChatBufferMode[1]][2].auxText [idx],
			b.ChatBuffer[b.ChatBufferMode[1]][2].auxColor[idx],
			1, ChatLines)
		fcw[3].ScrolledBack = fcw[3].ScrolledBack + 1

	elseif fcw[3].Scrolling and fcw[3].ScrollDownRequest and not fcw[1].BufferBusy then
		fcw[3].ScrollDownRequest = false
		local idx = #b.ChatBuffer[b.ChatBufferMode[1]][2].text + 1
			- fcw[3].ScrolledBack
			- (b.ChatBufferN[1] - b.ChatBufferIdx[3])
		ScrollLines(3,
			b.ChatBuffer[b.ChatBufferMode[1]][2].text    [idx],
			b.ChatBuffer[b.ChatBufferMode[1]][2].color   [idx],
			b.ChatBuffer[b.ChatBufferMode[1]][2].auxText [idx],
			b.ChatBuffer[b.ChatBufferMode[1]][2].auxColor[idx],
			0, ChatLines)
		fcw[3].ScrolledBack = fcw[3].ScrolledBack - 1
		if fcw[3].ScrolledBack == 0 then
			fcw[3].Scrolling = false
			ResetLines(3, ChatLines)
		end

	elseif not fcw[3].BigModePrev or (not fcw[3].Scrolling and b.ChatBufferIdx[3] < b.ChatBufferN[1]) then
		if b.ChatBufferN[1] - b.ChatBufferIdx[3] > 0 then
			local idx = #b.ChatBuffer[b.ChatBufferMode[1]][2].text - (b.ChatBufferN[1] - b.ChatBufferIdx[3] - 1)
			UpdateLines(3,
				b.ChatBuffer[b.ChatBufferMode[1]][2].text    [idx],
				b.ChatBuffer[b.ChatBufferMode[1]][2].color   [idx],
				b.ChatBuffer[b.ChatBufferMode[1]][2].auxText [idx],
				b.ChatBuffer[b.ChatBufferMode[1]][2].auxColor[idx],
				ChatLines)
			b.ChatBufferIdx[3] = b.ChatBufferIdx[3] + 1
		else
			ResetLines(3, ChatLines)
		end
	end

	fcw[3].RequestAuxFix = true
end
_G.DrawBigMode = M.draw

-- Currently unreferenced; kept in case a later reset path needs it.
function M.destroy()
	if fo.Chat[3] then fo.Chat[3] = T{} end
	if fo.Aux[3]  then fo.Aux[3]  = T{} end
end
_G.DestroyBigMode = M.destroy

return M
