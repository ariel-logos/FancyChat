-- lib/lifecycle.lua — addon load / unload / Init / SaveSettings /
-- DumpChat + the load and packet event callbacks.

require('common')
local chat     = require('chat')
local imgui    = require('imgui')
local ffi      = require('ffi')
local settings = require('settings')
local utils    = require('utils')
local gdi      = require('gdifonts.include')
local state    = require('lib.state')

local fcw            = state.fcw
local uiw            = state.uiw
local mvc            = state.mvc
local tab            = state.tab
local set            = state.set
local dw             = state.dw
local par            = state.par
local b              = state.b
local fo             = state.fo
local ro             = state.ro
local allSettings    = state.allSettings
local defaultColors  = state.defaultColors
local gamepadButtons = state.gamepadButtons

local M = {}

-- Exposed as a global; callers still reach for SaveSettings() by name.
function M.SaveSettings()
	settings.save('allSettings')
end
_G.SaveSettings = M.SaveSettings

-- Validate that allSettings.SelectedCombatFilter still exists on disk.
-- Sets set.filterFileMissing accordingly so the CL Filters tab can
-- render its red warning, and on the transition  exists -> missing
-- auto-disables allSettings.CustomFilters[1] (the master "Enable
-- Combat Log chat filters" toggle) + prints a one-shot /echo notice.
-- Idempotent: safe to call from any detection point (tab open, Refresh,
-- Reload, master-toggle-on, init).  When the file reappears the flag
-- is cleared on the next call, no notice (only the missing transition
-- is loud).
function M.CheckActiveCombatFilter()
	local fname       = allSettings.SelectedCombatFilter
	local exists      = utils.CombatFilterExists(fname)
	local was_missing = set.filterFileMissing
	set.filterFileMissing = not exists
	if not exists and not was_missing then
		if allSettings.CustomFilters[1] then
			allSettings.CustomFilters[1] = false
			M.SaveSettings()
		end
		print('FancyChat: filter file "'..tostring(fname)..'" no longer exists - chat filtering disabled.')
	end
end
_G.CheckActiveCombatFilter = M.CheckActiveCombatFilter

-- Replay OriginalBuffer back through the chat manager.  Used at
-- unload-time auto-dump and by the `/fchat savelogs` flow.
function M.DumpChat(closingline)
	par.dumping = true
	for i = 1, #b.OriginalBuffer do
		local msg = b.OriginalBuffer[i]:sub(b.OriginalBuffer[i]:find('|') + 1)
		for _, FWDchar in ipairs(utils.fwdchars) do
			if msg:endswith(FWDchar) then
				msg = msg:gsub(FWDchar, '')
				break
			end
		end
		AshitaCore:GetChatManager():AddChatMessage(
			tonumber(b.OriginalBuffer[i]:sub(1, b.OriginalBuffer[i]:find('|') - 1)),
			false,
			msg
		)
	end
	if closingline then
		print(closingline)
	end
	par.dumping = false
end
_G.DumpChat = M.DumpChat

-- Post-login one-shot: build BigMode objects, size chat windows.
function M.Init()
	local dsize = imgui.GetIO().DisplaySize

	fo.BigMode = gdi:create_object(allSettings.fontSettings, false)
	fo.BigMode:set_font_height(allSettings.fontSettings.font_height - 2)
	fo.BigMode:set_text('Big Mode')
	fo.BigMode:set_font_color(0xFAD1F4FF)
	fo.BigMode:set_visible(false)
	ro.BigMode = gdi:create_rect(allSettings.rectSettings, false)
	ro.BigMode:set_fill_color(0x00000000)

	fcw[3].BG_W      = allSettings.chatLineMaxL * allSettings.fontSettings.font_height * 0.58
	fcw[3].BG_H      = math.floor(dsize.y * 0.8)
	fcw[3].ChatLines = math.floor(fcw[3].BG_H / allSettings.fontSettings.font_height)
	fcw[3].HLeft     = fcw[3].BG_H - (fcw[3].ChatLines * allSettings.fontSettings.font_height)
	fcw[3].BG_H      = math.floor(allSettings.fontSettings.font_height * fcw[3].ChatLines * fcw[1].BGScale)

	local last_fo = allSettings.SecondChat[1] and 2 or 1
	if fo.Aux[last_fo] ~= nil then
		fcw[1].InitDone = true
		ChangeTab(1, tab.NextTab)
		if allSettings.SecondChat[1] then ChangeTab(2, tab.NextTab2) end
	end

	fcw[1].BG_W = allSettings.chatLineMaxL * allSettings.fontSettings.font_height * 0.58
	fcw[1].BG_H = math.floor(allSettings.fontSettings.font_height * allSettings.ChatLines * fcw[1].BGScale)
	ro.RectBG[1]:set_fill_color(allSettings.rectSettings.fill_color)
	ro.RectBG[1]:set_width(allSettings.chatLineMaxL * allSettings.fontSettings.font_height * 0.58)
	ro.RectBG[1]:set_height(allSettings.fontSettings.font_height * (allSettings.ChatLines + 1) + (allSettings.fontSettings.font_height / 5))

	if allSettings.SecondChat[1] then
		fcw[2].BG_W = allSettings.chatLineMaxL * allSettings.fontSettings.font_height * 0.58
		fcw[2].BG_H = math.floor(allSettings.fontSettings.font_height * allSettings.ChatLines * fcw[2].BGScale)
		ro.RectBG[2]:set_fill_color(allSettings.rectSettings.fill_color)
		ro.RectBG[2]:set_width(allSettings.chatLineMaxL * allSettings.fontSettings.font_height * 0.58)
		ro.RectBG[2]:set_height(allSettings.fontSettings.font_height * (allSettings.ChatLines + 1) + (allSettings.fontSettings.font_height / 5))
	end

	fcw[1].RoRectBaseX = ((allSettings.fontSettings.font_height * 2.5) / allSettings.fontSettings.font_height)
	fcw[1].RoRectBaseY = (allSettings.ChatLines * allSettings.fontSettings.font_height) + (allSettings.fontSettings.font_height / (allSettings.fontSettings.font_height - 100)) - (allSettings.fontSettings.font_height / 10)
	fcw[2].RoRectBaseY = (allSettings.ChatLines * allSettings.fontSettings.font_height) + (allSettings.fontSettings.font_height / (allSettings.fontSettings.font_height - 100)) - (allSettings.fontSettings.font_height / 10)
	fcw[3].RoRectBaseY = (fcw[3].ChatLines    * allSettings.fontSettings.font_height) + (allSettings.fontSettings.font_height / (allSettings.fontSettings.font_height - 100)) - (allSettings.fontSettings.font_height / 10)
	fcw[1].FWDBaseX    = (allSettings.fontSettings.font_height / 1.35) + (allSettings.chatLineMaxL * allSettings.fontSettings.font_height / 400)
	fcw[1].BKWBaseY    = (allSettings.fontSettings.font_height * allSettings.ChatLines) - ((allSettings.fontSettings.font_height * 5) / allSettings.fontSettings.font_height)
	fcw[1].BKWBaseX    = ((allSettings.fontSettings.font_height * 1.5) / allSettings.fontSettings.font_height)

	-- Build a lowercased zone-name lookup once at init time so the
	-- right-click /sea tooltip in render.lua can scan chat lines
	-- without repeatedly hitting the resource manager.  IDs run
	-- 0..~340 with gaps; skip the empty / "none" rows.  Stored on
	-- set.zoneNames as { [lowercased_name] = canonical_name }.
	if not next(set.zoneNames) then
		local rm = AshitaCore:GetResourceManager()
		for id = 0, 350 do
			local name = rm:GetString('zones.names', id)
			if name and name ~= '' and name:lower() ~= 'none' then
				set.zoneNames[name:lower()] = name
			end
		end
	end
end
_G.Init = M.Init

function M.register()

	-- =====================================================================
	-- Addon load: scan FFXiMain.dll for required pointers, load saved
	-- settings, instantiate GDI font / rect objects for both chat windows.
	-- =====================================================================
	ashita.events.register('load', 'load_cb', function ()

		-- Memory pointer scans -------------------------------------------------
		dw.testPTR        = ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0)
		dw.testPTR        = ashita.memory.read_uint32(dw.testPTR)

		uiw.UpperMenuPTR  = ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0)
		uiw.UpperMenuPTR  = ashita.memory.read_uint32(uiw.UpperMenuPTR)

		local patternAddr        = ashita.memory.find('FFxiMain.dll', 0, '8935????????81C6????????56E8', 0, 0)
		local pGlobalNowZoneAddr = ashita.memory.read_uint32(patternAddr + 0x02)
		local Offset             = ashita.memory.read_uint32(patternAddr + 0x08)
		local pGlobalNowZone     = ashita.memory.read_uint32(pGlobalNowZoneAddr)
		uiw.NetStatObj[1] = pGlobalNowZone + Offset

		uiw.UISizeYPtr = ashita.memory.find('FFXiMain.dll', 0, 'A1????????3BF07E??8BF0', 0, 0)
		uiw.UISizeYPtr = ashita.memory.read_uint32(uiw.UISizeYPtr + 0x01)
		uiw.UISizeY    = ashita.memory.read_uint32(uiw.UISizeYPtr)

		uiw.UISizeXPtr = ashita.memory.find('FFXiMain.dll', 0, 'BF????????F3??0FBF4C24', 0, 0)
		uiw.UISizeXPtr = ashita.memory.read_uint32(uiw.UISizeXPtr + 0x01)
		uiw.UISizeX    = ashita.memory.read_uint32(uiw.UISizeXPtr - 0x10)

		uiw.WinOpenPtr     = ashita.memory.find('FFXiMain.dll', 0, 'E8????????84C075??A1????????85C074??668378', 0, 0)
		uiw.WinOpenPtr2    = ashita.memory.find('FFXiMain.dll', 0, 'BF????????F3??0FBF4C24', 0, 0)
		uiw.RefWinOpenPtr2 = ashita.memory.read_uint32(uiw.WinOpenPtr2 + 0x01)
		uiw.RefWinOpenPtr  = ashita.memory.read_uint32(uiw.WinOpenPtr  + 0x23)

		uiw.DialogPtr   = ashita.memory.find('FFXiMain.dll', 0, 'A0????????53565784C08BF1', 0, 0)
		uiw.DialogPtr   = ashita.memory.read_uint32(uiw.DialogPtr + 0x01)

		uiw.MenuDescPTR = ashita.memory.find('FFxiMain.dll', 0, 'B9????????50E8????????8BF085F674??8B46', 1, 0)

		uiw.UIVisiblePtr = ashita.memory.find('FFXiMain.dll', 0, '8B4424046A016A0050B9????????E8????????F6D81BC040C3', 0, 0)
		uiw.MenuPtr      = ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0)
		uiw.MenuPtr      = ashita.memory.read_uint32(uiw.MenuPtr)

		uiw.EventPtr     = ashita.memory.find('FFXiMain.dll', 0, 'A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3', 0, 0)

		-- Settings load + repair ----------------------------------------------
		-- Snapshot the *defaults* schema (deep copy) BEFORE settings.load
		-- merges user data in-place.  Used below as the reference shape
		-- when RepairSettings prunes obsolete keys after a version bump.
		local allSettingsOG = utils.cloneTable(allSettings)
		allSettings.colors  = utils.cloneTable(defaultColors)

		-- In-place merge so module aliases (lib/state.lua, lib/ui_panels.lua,
		-- ...) continue to see the same table reference.
		state.replace_allSettings(settings.load(allSettings, 'allSettings'))

		-- Safety net: ensure every default-colour key is present in the
		-- loaded allSettings.colors.  This matters when default_colors()
		-- gains a new entry between addon versions (e.g. the new
		-- error1 / error slots for Error (main) / Error (other)).
		-- (Previously this loop had `.k` instead of `[k]`, which wrote
		-- to a literal key called "k" and silently dropped new defaults.)
		local addedAny = false
		for k, v in pairs(defaultColors) do
			if not allSettings.colors[k] then
				allSettings.colors[k] = utils.cloneTable(v)
				addedAny = true
			end
		end
		if addedAny then M.SaveSettings() end

		-- RepairSettings prunes obsolete keys and fixes type
		-- mismatches before Sugar's table.merge runs on logout.
		state.replace_allSettings(utils.RepairSettings(allSettingsOG, allSettings))

		if not allSettings.ver or allSettings.ver ~= addon.version then
			allSettings.ver = addon.version
			M.SaveSettings()
			print('Version change detected('..addon.version..'): Settings table restored')
		end

		-- Refresh the defaults settings file so a future logout's
		-- table.merge sees the current (repaired) schema.  We flip
		-- the settings-lib flags so save() targets the defaults folder.
		do
			local settingslib = require('settings')
			local was_in   = settingslib.logged_in
			local was_name = settingslib.name
			local was_sid  = settingslib.server_id
			settingslib.logged_in = false
			settingslib.name      = ''
			settingslib.server_id = 0
			settings.save('allSettings')
			settingslib.logged_in = was_in
			settingslib.name      = was_name
			settingslib.server_id = was_sid
		end


		ResetAutoHideTimer()
		set.alertList     = utils.stringsplit(allSettings.alertwords, ',')
		set.alertBuffer[1] = allSettings.alertwords
		par.customFilters = utils.LoadCustomFilters(allSettings.SelectedCombatFilter)
		-- Detection point: addon load.  If the persisted active filter
		-- file was deleted while the addon was offline, this raises
		-- set.filterFileMissing and forces the master toggle off so we
		-- don't boot up in the silently-broken "enabled but empty" state.
		M.CheckActiveCombatFilter()

		fcw[1].PlayerName = allSettings.PlayerName

		-- Mirror persisted settings into the live `set.*` working copy used
		-- by the Settings UI's pending-edit fields.
		set.SecondChat[1] = allSettings.SecondChat[1]
		set.ChatLineMaxL  = allSettings.chatLineMaxL
		set.PlateBGColor  = allSettings.rectSettings.fill_color
		set.FontHeight    = allSettings.fontSettings.font_height
		set.ChatLines     = allSettings.ChatLines
		for ct = 1, #allSettings.CustomTabModes do
			set.CustomTabModes[ct] = allSettings.CustomTabModes[ct]
		end

		fcw[1].ChatShift           = allSettings.fontSettings.font_height
		fcw[1].ChatShiftScale      = fcw[1].ChatShiftScale_Min
		fcw[2].ChatShiftScale_Base = allSettings.fontSettings.font_height * 2
		fcw[2].ChatShiftScale_Min  = allSettings.fontSettings.font_height * 2
		fcw[2].ChatShift           = allSettings.fontSettings.font_height
		fcw[2].ChatShiftScale      = fcw[2].ChatShiftScale_Min

		-- Cache D3D8 texture pointers as ImGui-compatible uint32 ids.
		fcw[1].TextureIDBorder   = tonumber(ffi.cast('uint32_t', fcw[1].Textures.border))
		fcw[1].TextureIDSettings = tonumber(ffi.cast('uint32_t', fcw[1].Textures.settings))
		fcw[1].TextureIDGuideMe  = tonumber(ffi.cast('uint32_t', fcw[1].Textures.guideme))
		fcw[1].TextureIDLogs     = tonumber(ffi.cast('uint32_t', fcw[1].Textures.logs))
		fcw[1].TextureIDLoading  = tonumber(ffi.cast('uint32_t', fcw[1].Textures.loading))
		fcw[1].TextureIDFolder   = tonumber(ffi.cast('uint32_t', fcw[1].Textures.folder))
		fcw[1].TextureIDCompact  = tonumber(ffi.cast('uint32_t', fcw[1].Textures.compact))
		fcw[1].TextureIDManual   = tonumber(ffi.cast('uint32_t', fcw[1].Textures.manual))
		fcw[1].TextureIDInfo     = tonumber(ffi.cast('uint32_t', fcw[1].Textures.info))
		fcw[1].TextureIDNotepad  = tonumber(ffi.cast('uint32_t', fcw[1].Textures.notepad))
		fcw[1].TextureIDDumpchat = tonumber(ffi.cast('uint32_t', fcw[1].Textures.dumpchat))
		fcw[1].TextureIDLogo     = tonumber(ffi.cast('uint32_t', fcw[1].Textures.logo))

		-- Locate the legacy chat-window pointers.
		local drawMessageWindowPtr = ashita.memory.find('FFXiMain.dll', 0, 'A1????????C64059018B0D????????C6415901C20800', 0, 0)
		if drawMessageWindowPtr == 0 then
			error(chat.header(addon.name):append(chat.error('Error: Failed to locate a required pointer.')))
		end
		uiw.WinPtr1 = ashita.memory.read_uint32(drawMessageWindowPtr + 0x01)
		uiw.WinPtr2 = ashita.memory.read_uint32(drawMessageWindowPtr + 0x0B)

		-- GDI font/rect object construction ----------------------------------
		local dsize = imgui.GetIO().DisplaySize

		gdi:set_auto_render(false)

		ro.Scroll[1] = gdi:create_rect(allSettings.rectSettings, false)
		ro.Scroll[1]:set_width(10)
		ro.Scroll[1]:set_height(10)
		ro.Scroll[1]:set_fill_color(0x88FFFFFF)
		ro.Scroll[1]:set_z_order(1)
		ro.Scroll[1]:set_visible(false)
		ro.RectBG[1] = gdi:create_rect(allSettings.rectSettings, false)
		fo.Fwd[1]    = gdi:create_object(allSettings.fontSettings, false)
		fo.Fwd[1]:set_text(utf8.char(0x25bc))
		fo.Bkw[1]    = gdi:create_object(allSettings.fontSettings, false)
		fo.Bkw[1]:set_font_height(allSettings.fontSettings.font_height - 2)
		fo.Bkw[1]:set_font_color(0xFAD1F4FF)
		fo.Bkw[1]:get_background():set_fill_color(0x22000000)
		fo.Bkw[1]:set_bg_overlap(0)
		fo.Bkw[1]:set_text(utf8.char(0x2004)..utf8.char(0x25b2)..' Scrolling chat history...')

		local customSettings = allSettings.fontSettings
		customSettings.bg_overlap = 0

		for L_i = 1, allSettings.ChatLines do
			table.insert(fo.Chat[1], gdi:create_object(allSettings.fontSettings, false))
			table.insert(fo.Aux[1],  gdi:create_object(allSettings.fontSettings, false))

			fo.Chat[1][L_i]:set_font_height(allSettings.fontSettings.font_height)
			fo.Aux[1][L_i]:set_font_height(allSettings.fontSettings.font_height)
			fo.Chat[1][L_i]:set_position_x(fcw[1].Anchor_X)
			fo.Chat[1][L_i]:set_position_y(fcw[1].Anchor_Y - (allSettings.fontSettings.font_height * (L_i - 1)))
			if fo.Chat[1][L_i].rect ~= nil then
				fo.Aux[1][L_i]:set_position_x(fcw[1].Anchor_X + fo.Chat[1][L_i].rect.right)
			else
				fo.Aux[1][L_i]:set_position_x(fcw[1].Anchor_X)
				fo.Aux[1][L_i]:set_visible(false)
			end
			fo.Aux[1][L_i]:set_position_y(fcw[1].Anchor_Y - (allSettings.fontSettings.font_height * (L_i - 1)))
		end

		if allSettings.SecondChat[1] then
			ro.Scroll[2] = gdi:create_rect(allSettings.rectSettings, false)
			ro.Scroll[2]:set_width(10)
			ro.Scroll[2]:set_height(10)
			ro.Scroll[2]:set_fill_color(0x88FFFFFF)
			ro.Scroll[2]:set_z_order(1)
			ro.Scroll[2]:set_visible(false)
			ro.RectBG[2] = gdi:create_rect(allSettings.rectSettings, false)
			fo.Fwd[2]    = gdi:create_object(allSettings.fontSettings, false)
			fo.Fwd[2]:set_text(utf8.char(0x25bc))
			fo.Bkw[2]    = gdi:create_object(allSettings.fontSettings, false)
			fo.Bkw[2]:set_font_height(allSettings.fontSettings.font_height - 2)
			fo.Bkw[2]:set_font_color(0xFAD1F4FF)
			fo.Bkw[2]:get_background():set_fill_color(0x22000000)
			fo.Bkw[2]:set_bg_overlap(0)
			fo.Bkw[2]:set_text(utf8.char(0x2004)..utf8.char(0x25b2)..' Scrolling chat history...')

			for L_i = 1, allSettings.ChatLines do
				table.insert(fo.Chat[2], gdi:create_object(allSettings.fontSettings, false))
				table.insert(fo.Aux[2],  gdi:create_object(customSettings, false))
				fo.Chat[2][L_i]:set_font_height(allSettings.fontSettings.font_height)
				fo.Aux[2][L_i]:set_font_height(allSettings.fontSettings.font_height)
				fo.Chat[2][L_i]:set_position_x(fcw[2].Anchor_X)
				fo.Chat[2][L_i]:set_position_y(fcw[2].Anchor_Y - (allSettings.fontSettings.font_height * (L_i - 1)))
				if fo.Chat[2][L_i].rect ~= nil then
					fo.Aux[2][L_i]:set_position_x(fcw[2].Anchor_X + fo.Chat[2][L_i].rect.right)
				else
					fo.Aux[2][L_i]:set_position_x(fcw[2].Anchor_X)
					fo.Aux[1][L_i]:set_visible(false)
				end
				fo.Aux[2][L_i]:set_position_y(fcw[2].Anchor_Y - (allSettings.fontSettings.font_height * (L_i - 1)))
			end
		end

		-- Seed both primary and secondary chat with a welcome line.
		-- Strip the inline color marking when the user has disabled
		-- EnableFCColorMarking — the line stays the same content,
		-- just rendered in the single buffer colour instead.
		local welcome = '--Welcome to \\§FF44CCFFç\\Fancy Chat--\\§--------ç\\'
		if not allSettings.EnableFCColorMarking[1] then
			welcome = utils.cleanMC(welcome)
		end
		for W_i = 1, 2 do
			table.insert(b.ChatBuffer[W_i][2].text,     welcome)
			table.insert(b.ChatBuffer[W_i][2].color,    0xFFFFFFFF)
			table.insert(b.ChatBuffer[W_i][2].auxText,  '')
			table.insert(b.ChatBuffer[W_i][2].auxColor, 0xFF44CCFF)
			table.insert(b.ChatBuffer[W_i][2].url,      0)
		end
		b.ChatBufferN_All    = 1
		b.ChatBufferN_AllAlt = 1

		-- Initial tab selection.
		if allSettings.SelectedTab  ~= 'All' then tab.NextTab  = allSettings.SelectedTab  end
		if allSettings.SelectedTab2 ~= 'All' then tab.NextTab2 = allSettings.SelectedTab2 end
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

		-- Menu-avoidance reposition pixel offsets, scaled for current resolution.
		fcw[1].MoveChatPos1 = (dsize.x * 400) / uiw.UISizeX
		fcw[1].MoveChatPos2 = (dsize.x * 220) / uiw.UISizeX
		fcw[1].MoveChatPos3 = (dsize.x * 260) / uiw.UISizeX
		fcw[1].MoveChatPos4 = (dsize.x * 305) / uiw.UISizeX

		fcw[1].PositionLinesRequest = {true, true}
		PositionLines(1)
		if allSettings.SecondChat[1] then
			fcw[2].PositionLinesRequest = {true, true}
			PositionLines(2)
		end
	end)

	-- =====================================================================
	-- Addon unload: optionally dump the FancyChat backlog into the legacy
	-- chat for the next addon to pick up, then tear down GDI and persist.
	-- =====================================================================
	ashita.events.register('unload', 'unload_cb', function ()
		if allSettings.autoDumpChat[1] then
			M.DumpChat()
		end
		fcw[1].Closing = true
		gdi:destroy_interface()
		M.SaveSettings()
	end)

	-- =====================================================================
	-- Packet 0x052: NPC dialog frame.  Hide forward/back arrows and
	-- record dialog timing.
	-- Packet 0x000B: zone-out begin.  Suspend rendering.
	-- Packet 0x000A: zone-in complete.  Resume.
	-- =====================================================================
	ashita.events.register('packet_in', 'zonename_packet_in', function(e)
		-- "Is the server actually talking to us?" signal for the
		-- /servmes injection in render.lua.  We count non-injected
		-- (i.e., real-from-server) packets up to a cap; once the
		-- counter crosses the threshold render.lua uses (currently
		-- 30), the post-reload settle timer can fire /servmes
		-- knowing the connection is warm.  Capping at 200 keeps
		-- the increment cheap on long sessions.
		--local bit = require('bit')
		--print('in: '..bit.tohex(e.id))
		if e.id == 0x052 then
			if fo.Fwd[1] ~= nil then fo.Fwd[1]:set_visible(false) end
			if fo.Fwd[2] ~= nil then fo.Fwd[2]:set_visible(false) end
			par.IsInConv = false
			par.InEvent  = ashita.memory.read_uint8(ashita.memory.read_uint32(uiw.EventPtr + 1)) == 1
			uiw.DialogCDStart = os.clock()
		elseif e.id == 0x000B then
			fcw[1].Zoning = true
			fcw[1].HasDoneServMes = true
			uiw.MenuList = {}
		elseif e.id == 0x000A then
			fcw[1].Zoning = false
			uiw.DialogShown = false
		elseif e.id == 0x00E0 and not fcw[1].HasDoneServMes and fcw[1].WaitingServMes == 0 then
			fcw[1].WaitingServMes = os.clock()
		end

	end)

	-- =====================================================================
	-- Packet 0x0026: emote.  Reset menu cache.
	-- =====================================================================
	ashita.events.register('packet_out', 'packet_out_callback1', function (e)
		--print('out: '..bit.tohex(e.id))
		if e.id == 0x0026 then
			uiw.MenuList = {}
		end
	end)
end

return M
