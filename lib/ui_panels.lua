--[[
	lib/ui_panels.lua

	Two of FancyChat's secondary ImGui panels:

	  draw_guideme() - The GuideMe walkthrough viewer.  Fetches a
	                   ffxiclopedia / bg-wiki page, extracts the
	                   walkthrough section and renders it as plain
	                   wrapped text with a font-size slider.

	  draw_notepad() - A simple per-character note keeper (max 10
	                   notes), persisted via SaveSettings.

	Each function is a no-op when its corresponding *Opened flag is
	false, so the call sites in fancychat.lua's d3d_present loop just
	invoke them unconditionally each frame.

	Both rely on a handful of GLOBAL helpers still defined in
	fancychat.lua: PushWindowStyle/PopWindowStyle, ResetAutoHideTimer,
	AddTooltip, SaveSettings.  When those move out into their own
	modules this file will not need to change — Lua's global lookup
	resolves them at call time.
]]

require('common')
local imgui     = require('imgui')
local imguiWrap = require('imguiWrap')
local http      = require('socket.http')
local utils     = require('utils')
local help      = require('help')
local state     = require('lib.state')

local fcw         = state.fcw
local ro          = state.ro
local allSettings = state.allSettings

local M = {}

-- Detect Cloudflare anti-bot interstitials by ANY of several markers.
-- Each is independently sufficient, so a future change to one still
-- leaves the others tripping the check.
--   cdn-cgi/challenge   : the URL prefix Cloudflare reserves for
--                         bot-mitigation pages and scripts; not used
--   _cf_chl_ / cf-chl   : challenge-state JS variables/cookies.
--                         Present in every challenge variant
--                         regardless of which UI they show.
--   challenges.cloudflare.com : domain of the challenge iframe widget.
--   "Just a moment"     : legacy interstitial title.
--   "Checking your browser" / "Verifying you are human" :
--                         human-facing text from older / newer
--                         challenge pages.
local function is_cloudflare_challenge(body)
	return body:find('cdn-cgi/challenge',         1, true) ~= nil
		or body:find('_cf_chl_',                  1, true) ~= nil
		or body:find('cf-chl',                    1, true) ~= nil
		or body:find('challenges.cloudflare.com', 1, true) ~= nil
		or body:find('Just a moment',             1, true) ~= nil
		or body:find('Checking your browser',     1, true) ~= nil
		or body:find('Verifying you are human',   1, true) ~= nil
end

function M.draw_guideme()
	if not (fcw[1].GuideMeOpened[1] and not fcw[1].GuideMeClosedTmp) then
		return
	end

	if fcw[1].isHiddenGUI then utils.ImguiVis(true) end

	local GuideMeW = allSettings.UseHalfLength[1] and fcw[1].BG_W / 2 or fcw[1].BG_W
	local GuideMeH = fcw[1].BG_H + 100
	local windowFlags

	if fcw[1].GuideMeDocked then
		windowFlags = fcw[1].windowFlagsGuideMeDocked
		if allSettings.GuideMeSecondWindow[1] then
			imgui.SetNextWindowPos({ro.RectBG[2].settings.position_x, ro.RectBG[2].settings.position_y - GuideMeH})
		else
			imgui.SetNextWindowPos({ro.RectBG[1].settings.position_x, ro.RectBG[1].settings.position_y - GuideMeH})
		end
		imgui.SetNextWindowSize({GuideMeW, GuideMeH})
		imgui.SetNextWindowSizeConstraints({GuideMeW, GuideMeH}, {FLT_MAX, FLT_MAX})
	else
		imgui.SetNextWindowSizeConstraints({400, 200}, {FLT_MAX, FLT_MAX})
		windowFlags = fcw[1].windowFlagsGuideMe
	end

	PushWindowStyle()

	if imgui.Begin('FancyChat - GuideMe (experimental)', fcw[1].GuideMeOpened, windowFlags) then
		if imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly) then ResetAutoHideTimer() end

		imgui.PushItemWidth(imgui.GetWindowWidth() / 2 - 130)
		imgui.InputText('URL', fcw[1].GuideMeURL, 200,
			bit.bor(ImGuiInputTextFlags_CharsNoBlank, ImGuiInputTextFlags_AutoSelectAll))
		imgui.PopItemWidth()
		imgui.SameLine()

		if fcw[1].GuideMeURL[1] == '' then
			fcw[1].ErrorMsg = '> Paste in the URL text box above a ffxiclopedia or bg-wiki\n  mission/quest or object walkthrough page and click [Load]'
		end

		if imgui.Button('Load', {50, 0}) then
			if fcw[1].GuideMeURL[1] ~= '' then
				if fcw[1].GuideMeURL[1]:match('^[a-zA-Z][a-zA-Z%d+.-]*:')
					and (string.find(fcw[1].GuideMeURL[1], 'ffxiclopedia')
						or string.find(fcw[1].GuideMeURL[1], 'bg%-wiki')) then

					local response, status = http.request(fcw[1].GuideMeURL[1])

					if not response then
						fcw[1].ErrorMsg = '> Failed to fetch page. Status:'..tostring(status or 'unknown')
						fcw[1].GuideMeWalkthrough = nil
					elseif is_cloudflare_challenge(response) then
						fcw[1].ErrorMsg = '> Page blocked by Cloudflare bot protection.\n  Try disabling your VPN, or use the equivalent\n  article on bg-wiki.com.'
						fcw[1].GuideMeWalkthrough = nil
					else
						fcw[1].GuideMeWalkthrough = response:match('(<h[1-3]>.-Walkthrough.-</h[1-3]>.-<div class="printfooter">)')

						if not fcw[1].GuideMeWalkthrough then
							fcw[1].GuideMeWalkthrough = response:match('(<h[1-3]>.-Walkthrough.-</h[1-3]>.-<div class="page%-footer">)')
						end

						if not fcw[1].GuideMeWalkthrough then
							fcw[1].GuideMeWalkthrough = response:match('(>Obtained From.-</th>.-<div class="printfooter">)')
							if fcw[1].GuideMeWalkthrough then
								fcw[1].GuideMeWalkthrough = '<h2>How to Obtain</h2>\n<table style="width: 100%; max-width: 788px;" class="sortable item"><tbody><tr>'
									..fcw[1].GuideMeWalkthrough:gsub('>Obtained From.-</tr>', '')
							end
						end

						if not fcw[1].GuideMeWalkthrough then
							fcw[1].GuideMeWalkthrough = response:match('(>Purchased From.-</th>.-<div class="printfooter">)')
							if fcw[1].GuideMeWalkthrough then
								fcw[1].GuideMeWalkthrough = '<h2>How to Obtain</h2>\n<table style="width: 100%; max-width: 788px;" class="sortable item"><tbody><tr>'
									..fcw[1].GuideMeWalkthrough:gsub('>Purchased From.-</tr>', '')
							end
						end

						if not fcw[1].GuideMeWalkthrough then
							fcw[1].GuideMeWalkthrough = response:match('(<h[1-3]>.-How to Obtain.-</h[1-3]>.-<div class="page%-footer">)')
						end

						if not fcw[1].GuideMeWalkthrough then
							fcw[1].ErrorMsg = '> Walkthrough section not found! Guide me only works\n  with missions or quest walkthrough pages.'
							fcw[1].GuideMeWalkthrough = nil
						else
							fcw[1].GuideMeWalkthrough = utils.GetWalkthrough(fcw[1].GuideMeWalkthrough)
							local start = string.find(fcw[1].GuideMeWalkthrough, '%[Walkthrough%]')
							if not start then start = string.find(fcw[1].GuideMeWalkthrough, '%[How to Obtain%]') end
							fcw[1].GuideMeWalkthrough = string.sub(fcw[1].GuideMeWalkthrough, start)
						end
					end
				else
					fcw[1].ErrorMsg = '> Invalid URL. Make sure it is a ffxiclopedia or bg-wiki\n  page starting with https://'
					fcw[1].GuideMeWalkthrough = nil
				end
			else
				fcw[1].ErrorMsg = '> Paste in the URL text box above a ffxiclopedia or bg-wiki\n  mission or quest walkthrough page and click [Load]'
				fcw[1].GuideMeWalkthrough = nil
			end
		end

		imgui.SameLine() imgui.Dummy({10, 0}) imgui.SameLine()
		imgui.Text('Text Size') imgui.SameLine()

		if imgui.ArrowButton('#DecreaseFontScale', ImGuiDir_Down) then
			if allSettings.GuideMeFontScale > 0.5 then
				allSettings.GuideMeFontScale = allSettings.GuideMeFontScale - 0.05
			end
		end
		imgui.SameLine()
		if imgui.ArrowButton('#IncreaseFontScale', ImGuiDir_Up) then
			if allSettings.GuideMeFontScale < 1.5 then
				allSettings.GuideMeFontScale = allSettings.GuideMeFontScale + 0.05
			end
		end

		imgui.SameLine() imgui.Text('[x'..string.format('%.2f', allSettings.GuideMeFontScale)..']')
		imgui.SameLine() imgui.Dummy({10, 0}) imgui.SameLine()

		if fcw[1].GuideMeDocked then
			if imgui.Button('Undock', {70, 0}) then fcw[1].GuideMeDocked = false end
		else
			if imgui.Button('Dock', {70, 0}) then fcw[1].GuideMeDocked = true end
		end

		imguiWrap.BeginChild('GuideMe child',
			{imgui.GetWindowWidth() * 0.983, (imgui.GetWindowHeight() - 70) * 0.983}, true)

		local IWwindowfontG = imguiWrap.SetWindowFontScale(allSettings.GuideMeFontScale)
		imgui.PushTextWrapPos(imgui.GetWindowWidth() * 0.96)
		if fcw[1].GuideMeWalkthrough then
			imgui.TextUnformatted(fcw[1].GuideMeWalkthrough, #fcw[1].GuideMeWalkthrough)
		elseif fcw[1].ErrorMsg then
			imgui.TextUnformatted(fcw[1].ErrorMsg)
		end
		imgui.PopTextWrapPos()
		if IWwindowfontG then imgui.PopFont() end
		imgui.EndChild()
		imgui.End()
	end
	PopWindowStyle()
end

function M.draw_notepad()
	if not (fcw[1].NotepadOpened[1] and not fcw[1].NotepadClosedTmp) then
		return
	end

	if fcw[1].isHiddenGUI then utils.ImguiVis(true) end

	local GuideMeW = allSettings.UseHalfLength[1] and fcw[1].BG_W / 2 or fcw[1].BG_W
	local GuideMeH = fcw[1].BG_H + 100
	local windowFlags

	if fcw[1].NotepadDocked then
		windowFlags = fcw[1].windowFlagsGuideMeDocked
		if allSettings.GuideMeSecondWindow[1] then
			imgui.SetNextWindowPos({ro.RectBG[2].settings.position_x, ro.RectBG[2].settings.position_y - GuideMeH})
		else
			imgui.SetNextWindowPos({ro.RectBG[1].settings.position_x, ro.RectBG[1].settings.position_y - GuideMeH})
		end
		imgui.SetNextWindowSize({GuideMeW, GuideMeH})
		imgui.SetNextWindowSizeConstraints({GuideMeW, GuideMeH}, {FLT_MAX, FLT_MAX})
	else
		imgui.SetNextWindowSizeConstraints({550, 200}, {FLT_MAX, FLT_MAX})
		windowFlags = fcw[1].windowFlagsGuideMe
	end

	PushWindowStyle()

	if imgui.Begin('FancyChat - Notes (experimental)', fcw[1].NotepadOpened, windowFlags) then
		if imguiWrap.IsWindowHovered(ImGuiHoveredFlags_RectOnly) then ResetAutoHideTimer() end

		AddTooltip('Save up to 10 Notes!\n- Use the textbox to manually add a note.\n- Use Shitf+Click on any message in chat to save it directly as a note.', 0)
		imgui.SameLine() imgui.SetCursorPosY(imgui.GetCursorPosY() - 4)

		imgui.PushItemWidth(imgui.GetWindowWidth() - 316)
		imgui.InputText('##NoteInput', fcw[1].Note, 300, bit.bor(ImGuiInputTextFlags_AutoSelectAll))
		imgui.SameLine()

		if imgui.Button('Add Note', {100, 0}) then
			if #allSettings.Notes < 10 and #fcw[1].Note[1] > 0 then
				table.insert(allSettings.Notes, fcw[1].Note[1])
				fcw[1].Note = T{''}
				SaveSettings()
			end
		end
		imgui.SameLine()
		imgui.Text(string.format('[%02d/10]', #allSettings.Notes))
		imgui.SameLine() imgui.Dummy({0, 0}) imgui.SameLine()

		if fcw[1].NotepadDocked then
			if imgui.Button('Undock', {70, 0}) then fcw[1].NotepadDocked = false end
		else
			if imgui.Button('Dock', {70, 0}) then fcw[1].NotepadDocked = true end
		end

		local font = imgui.GetFont()
		local fontSize = font.FontSize or font.LegacySize
		local R = {}

		for i = 1, #allSettings.Notes do
			imguiWrap.BeginChild(
				'##Chat Window Child_'..tostring(i),
				{
					imgui.GetWindowWidth() - 110,
					fontSize + fontSize * math.floor(
						imgui.CalcTextSize(allSettings.Notes[i])
						/ (imgui.GetWindowWidth() - math.min(
							imgui.CalcTextSize(help.GetLongestWord(allSettings.Notes[i])),
							(imgui.GetWindowWidth() - 100) / 2))
					) + 16
				}, true)
			imgui.PushTextWrapPos(imgui.GetWindowWidth())
			imgui.TextWrapped(allSettings.Notes[i])
			imgui.PopTextWrapPos()
			imgui.EndChild()

			imgui.SameLine()
			if imgui.Button('X##Note'..tostring(i), {34, 34}) then
				table.insert(R, i)
			end
			imgui.SameLine()
			if imgui.Button('C##Note'..tostring(i), {34, 34}) then
				utils.SetClipboardText(allSettings.Notes[i])
			end
		end

		for R_i = 1, #R do
			table.remove(allSettings.Notes, R[R_i])
		end
		if #R > 0 then SaveSettings() end

		imgui.PopItemWidth()
		imgui.SameLine()
		imgui.End()
	end
	PopWindowStyle()
end

return M
