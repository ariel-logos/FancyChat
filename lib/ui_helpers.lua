--[[
	lib/ui_helpers.lua

	Small ImGui helper functions used across the addon.  All exposed
	as globals via `_G.X = M.X` so existing call sites in
	fancychat.lua's d3d_present render loop, ui_settings, ui_panels,
	bigmode, etc. continue to work without further changes.

	Two flavours:

	  Style-stack helpers
	    PushColorStyles(styles)  /  PopColorStyles(styles)
	      Generic per-element ImGui color push/pop (used by tab buttons).
	    PushWindowStyle()        /  PopWindowStyle()
	      Pushes the 16 fixed colors that give every FancyChat window
	      its translucent dark theme.

	  Widgets / overlays
	    AddTooltip(message, offset, critical)
	      Draws the (i) info icon and shows `message` on hover,
	      wrapped at 40 chars.  `critical` paints the icon red.
	    AddWarning(message, y, flag, x, title)
	      Modal-ish centered popup with an OK button.  Uses
	      `set.Popup` as the close-flag (cleared by parent code).
	    AddSetColor(buttonname, colorhex, tmpcolor)
	      Per-color row in the Settings -> Font Colors tab.  Returns
	      the row's pixel width so the caller can lay out columns.
	    DrawInfoWin(maxh, idx, name, text, icon)
	      Single per-item tooltip pane drawn above the chat.
	    DrawInfo(text)
	      Scans `text` for `<...>` auto-translate name pairs, looks
	      each up via the resource manager (item / ability / spell)
	      and renders up to 4 stacked DrawInfoWin previews.

	The check `if check == false then return end` at the top of
	AddWarning is preserved verbatim from the original; `check` is
	an undefined global so it's always nil and the early-return
	never fires.  Likely a leftover from an older guard.
]]

require('common')
local imgui     = require('imgui')
local imguiWrap = require('imguiWrap')
local ffi       = require('ffi')
local utils     = require('utils')
local state     = require('lib.state')

local fcw         = state.fcw
local ro          = state.ro
local set         = state.set
local allSettings = state.allSettings
local colorDesc   = state.colorDesc

local M = {}

-- ===================================================================
-- Style-stack helpers
-- ===================================================================

function M.PushColorStyles(styles)
	for _, s in pairs(styles) do
		imgui.PushStyleColor(s[1], s[2])
	end
end
_G.PushColorStyles = M.PushColorStyles

function M.PopColorStyles(styles)
	for _ in pairs(styles) do
		imgui.PopStyleColor()
	end
end
_G.PopColorStyles = M.PopColorStyles

function M.PushWindowStyle()
	imgui.PushStyleColor(ImGuiCol_WindowBg,           {0.10, 0.10, 0.10, 0.7})
	imgui.PushStyleColor(ImGuiCol_TitleBg,            {0.10, 0.10, 0.10, 0.7})
	imgui.PushStyleColor(ImGuiCol_TitleBgActive,      {0.10, 0.10, 0.10, 0.7})
	imgui.PushStyleColor(ImGuiCol_TitleBgCollapsed,   {0.10, 0.10, 0.10, 0.7})
	imgui.PushStyleColor(ImGuiCol_ChildBg,            {0.05, 0.05, 0.05, 0.4})
	imgui.PushStyleColor(ImGuiCol_FrameBg,            {0.30, 0.30, 0.30, 0.6})
	imgui.PushStyleColor(ImGuiCol_ButtonHovered,      {0.70, 0.70, 0.70, 0.65})
	imgui.PushStyleColor(ImGuiCol_ScrollbarBg,        {0,    0,    0,    0.3})
	imgui.PushStyleColor(ImGuiCol_Button,             {0.40, 0.40, 0.40, 0.6})
	imgui.PushStyleColor(ImGuiCol_FrameBgHovered,     {0.40, 0.40, 0.40, 0.6})
	imgui.PushStyleColor(ImGuiCol_FrameBgActive,      {0.40, 0.40, 0.40, 0.8})
	imgui.PushStyleColor(ImGuiCol_CheckMark,          {1.000, 0.384, 0.322, 1})
	imgui.PushStyleColor(ImGuiCol_SliderGrab,         {0.937, 0.349, 0.290, 1})
	imgui.PushStyleColor(ImGuiCol_ScrollbarGrab,      {0.70, 0.70, 0.70, 0.3})
	imgui.PushStyleColor(ImGuiCol_ScrollbarGrabHovered,{0.80, 0.80, 0.80, 0.3})
	imgui.PushStyleColor(ImGuiCol_ScrollbarGrabActive, {0.90, 0.90, 0.90, 0.3})
end
_G.PushWindowStyle = M.PushWindowStyle

function M.PopWindowStyle()
	imgui.PopStyleColor(16)
end
_G.PopWindowStyle = M.PopWindowStyle

-- ===================================================================
-- Widgets / overlays
-- ===================================================================

function M.AddTooltip(message, offset, critical)
	if not offset then offset = 0 end
	imgui.SameLine()
	local cursorPosY = imgui.GetCursorPosY()
	imgui.SetCursorPosY(cursorPosY + offset)
	if not critical then
		imguiWrap.Image(fcw[1].TextureIDInfo, {15, 15})
	else
		imguiWrap.Image(fcw[1].TextureIDInfo, {15, 15}, {0, 0}, {1, 1}, {0.937, 0.349, 0.290, 1})
	end
	if imgui.IsItemHovered(0) then
		imgui.BeginTooltip()
		imgui.SetTooltip(utils.breakLine(message, 40))
		imgui.EndTooltip()
	end
end
_G.AddTooltip = M.AddTooltip

function M.AddWarning(message, y, flag, x, title)
	if check == false then return end
	local wx = x or 300
	local wy = y or 300
	if not title then title = 'Warning' end
	local dsize = imgui.GetIO().DisplaySize

	imgui.SetNextWindowSize({wx, wy})
	imgui.SetNextWindowPos({(dsize.x / 2) - (wx / 2), (dsize.y / 2) - (wy / 2)})
	local wFlags = bit.bor(ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_NoMove,
		ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoSavedSettings)
	imgui.PushStyleVar(ImGuiStyleVar_WindowTitleAlign, {0.5, 0.5})
	imgui.PushStyleColor(ImGuiCol_WindowBg,      {0.1, 0.1, 0.1, 1.0})
	imgui.PushStyleColor(ImGuiCol_TitleBg,       {0.1, 0.1, 0.1, 1.0})
	imgui.PushStyleColor(ImGuiCol_TitleBgActive, {0.1, 0.1, 0.1, 1.0})

	if imgui.Begin(title..'##'+fcw[1].PlayerName, set.Popup, wFlags) then
		local winwidth                = imgui.GetWindowWidth()
		local textwidth, textheight   = imgui.CalcTextSize(message)
		local textindentation         = (winwidth - textwidth) * 0.5
		if textindentation <= 20 then textindentation = 20 end

		imgui.SameLine(textindentation)
		imgui.PushTextWrapPos(winwidth - textindentation)
		imgui.TextWrapped(message)

		imgui.SetCursorPosY(wy - 40)
		imgui.SetCursorPosX(wx / 2 - 35)
		if imgui.Button('OK##Warning', {70, 0}) then
			set.Popup[1] = false
			if flag then
				flag[1] = true
				SaveSettings()
			end
		end
		imgui.PopTextWrapPos()
		imgui.End()
	end
	imgui.PopStyleColor(3)
	imgui.PopStyleVar()
end
_G.AddWarning = M.AddWarning

function M.AddSetColor(buttonname, colorhex, tmpcolor)
	local a, r, g, b = utils.hexToRGBA(tostring(bit.tohex(colorhex[1])))
	local colortable = T{r / 255, g / 255, b / 255, a / 255}

	if imgui.ColorButton(buttonname, colortable, ImGuiColorEditFlags_NoAlpha, {24, 24}) then
		tmpcolor[1] = colortable
	end
	imgui.SameLine()
	if imgui.ArrowButton('Set'..buttonname, ImGuiDir_Left) then
		colortable[1] = set.PickedColor[1]
		colortable[2] = set.PickedColor[2]
		colortable[3] = set.PickedColor[3]
		colortable[4] = 1
		colorhex[1]   = utils.rgbaToHexNum(colortable)
		SaveSettings()
	end
	imgui.SameLine()
	imgui.Text(colorDesc[buttonname][1])
	M.AddTooltip(colorDesc[buttonname][2], 4)

	return imgui.CalcTextSize(colorDesc[buttonname][1]) + 48 + 32 + 32 + 16
end
_G.AddSetColor = M.AddSetColor

-- ===================================================================
-- DrawInfoWin / DrawInfo: per-item hover preview popups stacked
-- horizontally above the chat window when the user hovers a chat
-- line containing one or more <auto-translate> name tokens.
-- ===================================================================

function M.DrawInfoWin(maxh, idx, name, text, icon)
	if not maxh then maxh = 0 end
	local W = (allSettings.UseHalfLength[1] and fcw[1].BG_W / 2 or fcw[1].BG_W) / 4
	local H = maxh

	imgui.SetNextWindowPos({ro.RectBG[1].settings.position_x + (W * (idx - 1)), ro.RectBG[1].settings.position_y - H})
	imgui.SetNextWindowSize({W, H})
	imgui.SetNextWindowSizeConstraints({W, H}, {FLT_MAX, FLT_MAX})
	local wFlags = bit.bor(
		ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_NoResize,
		ImGuiWindowFlags_NoBringToFrontOnFocus, ImGuiWindowFlags_NoFocusOnAppearing,
		ImGuiWindowFlags_NoMove, ImGuiWindowFlags_NoSavedSettings)

	M.PushWindowStyle()

	if imgui.Begin('##Info'..tostring(idx), true, wFlags) then
		imguiWrap.BeginChild('##InfoChild'..tostring(idx),
			{imgui.GetWindowWidth() - 16, imgui.GetWindowHeight() - 16},
			true, ImGuiWindowFlags_NoScrollbar)
		local cx = imgui.GetCursorPosX()
		if icon then
			imguiWrap.Image(icon, {32, 32})
			imgui.SameLine()
			imgui.SetCursorPosY(imgui.GetCursorPosY())
		end
		imgui.PushTextWrapPos(imgui.GetWindowWidth() - 16)
		imgui.TextWrapped(name)
		imgui.SetCursorPosX(cx)
		if not icon then imgui.Dummy({0, 5}) end
		imgui.TextWrapped(text)
		imgui.PopTextWrapPos()
		imgui.EndChild()
		imgui.End()
	end
	M.PopWindowStyle()
end
_G.DrawInfoWin = M.DrawInfoWin

function M.DrawInfo(text)
	local drawcalls = {}
	local H = 0
	local info = {}

	-- Extract every <name> auto-translate token from the message.
	local ATstart = 1
	while ATstart < #text do
		local s, e = string.find(text, utf8.char(0x276e), ATstart, true)
		if s and e then
			local s2, e2 = string.find(text, utf8.char(0x276f), e + 1, true)
			if s2 and e2 then
				local subtext = text:sub(e + 1, s2 - 1)
				subtext = subtext:gsub('([%l%d%.])(%u)', '%1 %2'):gsub('  ', ' ')
				table.insert(info, subtext)
				ATstart = e2 + 1
			end
			ATstart = e + 1
		else
			break
		end
	end

	if #info < 1 then
		fcw[1].itemInfo = {}
		return
	end

	-- Decide whether the cached item list is still valid.  When the
	-- user hovers a different message, force a re-lookup.
	local updated = false
	if #fcw[1].itemInfo ~= #info then
		updated = true
		fcw[1].itemInfo = {}
	end
	local update_idx = 1
	while update_idx <= #info do
		if fcw[1].itemInfo[update_idx] ~= info[update_idx] then
			updated = true
			fcw[1].itemInfo[update_idx] = info[update_idx]
		end
		update_idx = update_idx + 1
	end

	-- Resolve each token via the resource manager (item / ability /
	-- spell) and build the draw queue.  Cap at 4 entries.
	local idx = 1
	for i = 1, #info do
		if idx > 4 then break end
		if not info[i] then break end

		local item, ability, spell

		if not updated then
			if info[i] == fcw[1].itemIcons[idx][3] then
				if     fcw[1].itemIcons[idx][5] == 1 then item    = fcw[1].itemIcons[idx][4]
				elseif fcw[1].itemIcons[idx][5] == 2 then ability = fcw[1].itemIcons[idx][4]
				elseif fcw[1].itemIcons[idx][5] == 3 then spell   = fcw[1].itemIcons[idx][4]
				end
			end
		else
			local RM = AshitaCore:GetResourceManager()
			if not item    then item    = RM:GetItemByName   (info[i], 0) end
			if not item    then ability = RM:GetAbilityByName(info[i], 0) end
			if not ability then spell   = RM:GetSpellByName  (info[i], 0) end
		end

		local W_quarter = ((allSettings.UseHalfLength[1] and fcw[1].BG_W / 2 or fcw[1].BG_W) / 4) - 32

		if item and item.Description and item.Description[1] then
			fcw[1].itemIcons[idx][3]    = info[i]
			fcw[1].itemIcons[idx][4]    = item
			fcw[1].itemIcons[idx][5]    = 1
			fcw[1].itemTexture[idx][1]  = utils.ItemIcon(item.Bitmap, item.ImageSize)
			fcw[1].itemTexture[idx][2]  = tonumber(ffi.cast('uint32_t', fcw[1].itemTexture[idx][1]))

			local inf   = ''
			local flags = ''
			flags = flags..(bit.band(0x8000, item.Flags) ~= 0 and '[Rare]' or '')
			flags = flags..(bit.band(0x6040, item.Flags) ~= 0 and '[Ex]'   or '')
			if flags ~= '' then inf = inf..flags..'\n' end

			local desc = item.Description[1]
			if desc then
				desc = desc
					:replace('\x81\x60', '~')
					:replace('\xEF\x1F', 'Fire')
					:replace('\xEF\x20', 'Ice')
					:replace('\xEF\x21', 'Wind')
					:replace('\xEF\x22', 'Earth')
					:replace('\xEF\x23', 'Lgtn')
					:replace('\xEF\x24', 'Water')
					:replace('\xEF\x25', 'Light')
					:replace('\xEF\x26', 'Dark')
					:replace('%', '%%')
					:replace('\n', ' ')

				if item.Type == 4 or item.Type == 5 then
					inf = inf..'['..utils.equipSlots[item.Slots]..'] '..utils.equipRaces[item.Races]..'\n'
					inf = inf..desc..'\n'
					inf = inf..'Lv: '..item.Level..' '..utils.GetEquipJobs(item.Jobs)
				else
					inf = inf..desc
				end

				H = math.max(H, ((imgui.GetFontSize() * 1)
					* (utils.CalcRows(inf, W_quarter, imgui.CalcTextSize('H')) + 1) + 28 + 40))
				table.insert(drawcalls, {idx, info[i], inf, fcw[1].itemTexture[idx][2]})
				idx = idx + 1
			end

		elseif ability and ability.Description and ability.Description[1] then
			if fcw[1].itemTexture[idx] then
				fcw[1].itemTexture[idx][2] = nil
				utils.ItemIconRelease(fcw[1].itemTexture[idx][1])
			end
			utils.ItemIconRelease(fcw[1].itemTexture[idx][1])
			fcw[1].itemIcons[idx][3] = info[i]
			fcw[1].itemIcons[idx][4] = ability
			fcw[1].itemIcons[idx][5] = 2

			local inf
			if     ability.Type == 1 then inf = '[Job Ability]\n'
			elseif ability.Type == 2 then inf = '[Pet Command]\n'
			elseif ability.Type == 3 then inf = '[Weaponskill]\n'
			elseif ability.Type == 4 then inf = '[Job Trait]\n'
			else                          inf = ''
			end

			local desc = ability.Description[1]
			if desc then
				desc = desc
					:replace('\x81\x60', '~')
					:replace('\xEF\x1F', 'Fire')
					:replace('\xEF\x20', 'Ice')
					:replace('\xEF\x21', 'Wind')
					:replace('\xEF\x22', 'Earth')
					:replace('\xEF\x23', 'Lgtn')
					:replace('\xEF\x24', 'Water')
					:replace('\xEF\x25', 'Light')
					:replace('\xEF\x26', 'Dark')
					:replace('%', '%%')
					:replace('\n', ' ')

				if ability.TPCost   > 0 then inf = inf..'TP: '..ability.TPCost  ..'\n' end
				if ability.ManaCost > 0 then inf = inf..'MP: '..ability.ManaCost..'\n' end
				inf = inf..desc

				H = math.max(H, ((imgui.GetFontSize() * 1)
					* (utils.CalcRows(inf, W_quarter, imgui.CalcTextSize('H')) + 3) + 28))
				table.insert(drawcalls, {idx, info[i], inf, nil})
				idx = idx + 1
			end

		elseif spell and spell.Description and spell.Description[1] then
			if fcw[1].itemTexture[idx] then
				fcw[1].itemTexture[idx][2] = nil
				utils.ItemIconRelease(fcw[1].itemTexture[idx][1])
			end
			fcw[1].itemIcons[idx][3] = info[i]
			fcw[1].itemIcons[idx][4] = spell
			fcw[1].itemIcons[idx][5] = 3

			local inf  = '[Spell]\n'
			local desc = spell.Description[1]
			if desc then
				desc = desc
					:replace('\x81\x60', '~')
					:replace('\xEF\x1F', 'Fire')
					:replace('\xEF\x20', 'Ice')
					:replace('\xEF\x21', 'Wind')
					:replace('\xEF\x22', 'Earth')
					:replace('\xEF\x23', 'Lgtn')
					:replace('\xEF\x24', 'Water')
					:replace('\xEF\x25', 'Light')
					:replace('\xEF\x26', 'Dark')
					:replace('%', '%%')
					:replace('\n', ' ')

				if spell.ManaCost > 0 then inf = inf..'MP: '..spell.ManaCost..'\n' end
				inf = inf..desc

				H = math.max(H, ((imgui.GetFontSize() * 1)
					* (utils.CalcRows(info[i]..inf, W_quarter, imgui.CalcTextSize('H')) + 3) + 28))
				table.insert(drawcalls, {idx, info[i], inf, nil})
				idx = idx + 1
			end
		end
	end

	-- Clear and free any cached entries past `idx`.
	for del_i = idx, 4 do
		fcw[1].itemIcons[del_i] = {}
		if fcw[1].itemTexture[del_i] then
			fcw[1].itemTexture[del_i][2] = nil
			utils.ItemIconRelease(fcw[1].itemTexture[del_i][1])
		end
	end

	for d = 1, #drawcalls do
		if drawcalls[d][4] then
			M.DrawInfoWin(H, drawcalls[d][1], drawcalls[d][2], drawcalls[d][3], drawcalls[d][4])
		else
			M.DrawInfoWin(H, drawcalls[d][1], drawcalls[d][2], drawcalls[d][3])
		end
	end
end
_G.DrawInfo = M.DrawInfo

return M
