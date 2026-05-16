--[[
	lib/parser.lua

	The text-message dispatch pipeline.  Entry point is the
	`text_in` event handler (registered via `M.register()`):

		text_in --> split on newlines --> parseThis(e, segment) for each

	`parseThis` is the heart of the addon.  It:
	  1. Resets per-message parser state on `par`.
	  2. Picks a base color and tab from utils_modesDA[mode+1].
	  3. Filters auto-translate / hidden / blocked messages.
	  4. Calls CleanTextFunctionNew to strip control bytes and re-encode SJIS.
	  5. For combat-mode lines, delegates to CombatText / CombatSpellText
	     (in lib/combat.lua) which return reformatted text with
	     iconography substitutions.
	  6. Optionally splits long lines, applies HandleSpecial / HELMtext
	     colorisation, runs HandleActors to color party / enemy names,
	     and inserts the resulting line(s) into b.ChatBuffer for every
	     tab that should display the message.
	  7. Maintains per-tab line-count counters (b.ChatBufferN_*) and
	     enforces the buffer-size cap via BulkRemove / BulkRemoveCombat
	     from lib/buffer.lua.

	Helper functions kept here because they only make sense in the
	parser context:
	  CleanTextFunctionNew  Byte-pass cleaner: strips colors, FFXI bytes,
	                        SJIS multibytes.
	  HandleSpecial    Find the [prefix..suffix] span in a chat line
	                   and return an MCList tuple to colorize it.
	  CheckSpecial     Mode-specific dispatcher for HandleSpecial
	                   (CE accumulators, You find/obtain/sell/buy,
	                   exp/limit gains, etc.).
	  HandleActors     Wrap actor1 / actorP / actor2 / actorE / action1
	                   substrings of a line in MC color escapes.
	  HELMtext         Locate the harvest/dig/cut yield span.
	  FindHELM         Detect a HELM message and return its delimiters.
	  SetBufferN       Tab name -> b.ChatBufferN_* lookup.  Called from
	                   the render loop when picking which buffer count
	                   to display.
	  SetTargetPosX    Render-loop helper that picks the menu-aware
	                   target X / Y for chat repositioning.  Lives here
	                   only because the original code grouped it with
	                   the other helpers; will move to render module
	                   if/when render is extracted.

	All top-level helpers (CleanTextFunctionNew, HandleSpecial,
	CheckSpecial, HandleActors, HELMtext, FindHELM, SetBufferN,
	SetTargetPosX, parseThis) are exposed as globals via `_G.X = M.X`
	so that other modules and the render loop continue to call them
	by name.
]]

require('common')
local utils   = require('utils')
local targets = require('targets')
local state   = require('lib.state')

local fcw         = state.fcw
local uiw         = state.uiw
local mvc         = state.mvc
local tab         = state.tab
local set         = state.set
local dw          = state.dw
local par         = state.par
local b           = state.b
local fo          = state.fo
local allSettings = state.allSettings

-- Localised stdlib + utility lookups (#12, #13).  parseThis runs on
-- every chat message and these get hit hundreds of times per call.
local string_find  = string.find
local string_gsub  = string.gsub
local string_sub   = string.sub
local string_match = string.match
local string_byte  = string.byte
local string_len   = string.len
local string_lower = string.lower
local string_upper = string.upper
local table_insert = table.insert
local math_floor   = math.floor
local math_min     = math.min
local math_max     = math.max
local math_fmod    = math.fmod
local bit_band     = bit.band
local os_date      = os.date
local os_time      = os.time

local utils_StringFindTable        = utils.StringFindTable
local utils_FindLastOfMB           = utils.FindLastOfMB
local utils_FindFirstOfMB          = utils.FindFirstOfMB
local utils_FindLastOf             = utils.FindLastOf
local utils_FindLastOfString       = utils.FindLastOfString
local utils_FindInStringTable      = utils.FindInStringTable
local utils_FindInStringTableFilters = utils.FindInStringTableFilters
local utils_IsInTable              = utils.IsInTable
local utils_CountExtraBytesT       = utils.CountExtraBytesT
local utils_utf8split              = utils.utf8split
local utils_ParseUrlLink           = utils.ParseUrlLink
local utils_MC                     = utils.MC
local utils_MCCheck                = utils.MCCheck
local utils_LoadCustomFilters      = utils.LoadCustomFilters
local utils_modesDA                = utils.modesDA
local utils_disambYou              = utils.disambYou
local utils_disambEnemy            = utils.disambEnemy
local utils_fwdchars               = utils.fwdchars
local utils_crafts                 = utils.crafts
local icons                        = utils.icons

-- Pre-allocated `par.party_names` builder (#20).  LuaJIT's table.new
-- skips the array-growth dance for known-size table inits.  Fall back
-- to a plain `T{}` if the helper isn't available (vanilla Lua / older
-- LuaJIT builds).
local table_new = (function()
	local ok, mod = pcall(require, 'table.new')
	if ok and type(mod) == 'function' then return mod end
	return function() return T{} end
end)()

local M = {}

-- ===================================================================
-- CleanTextFunctionNew: byte-level pass over an incoming chat line.
-- Uses the single-pass utils.TranscodeFFXI byte walker for SJIS → UTF-8
-- transcoding, glyph remapping, and codepoint replacement.
--
-- Responsibilities:
--   • Conversation-prompt tracking (uiw.DialogPromptStart on
--     mode-150/151 dialog-end transitions).
--   • Compact-combat fast path: arrow glyph dropped when mode
--     contains 'combat', channel is not 80, and CompactCombat is on.
--     Combat lines skip outer-whitespace trim.
--   • Heart emoji (<3 → ❤) on the full path.
-- ===================================================================
function M.CleanTextFunctionNew(text, mode)
	-- 1. Conversation tracking.
	if (par.MessageMode == 150 or par.MessageMode == 151) and par.LastMsgInConv then
		uiw.DialogPromptStart = os.clock()
	end
	if par.MessageMode == 150 or par.MessageMode == 151 then
		par.LastMsgInConv = par.InEvent and true or false
	end

	-- 2. Decide path.
	local isCombat = string_find(mode, 'combat')
	local compactCombat =
		isCombat
		and par.MessageMode ~= 80
		and allSettings.CompactCombat[1]

	-- FC colour marking is "active" when globally enabled OR when
	-- the line is a combat message handled by compact combat
	-- (which depends on the FC pipeline for actor highlighting).
	-- Mirrors the same flag computed in parseThis.
	local fcMarkingActive = allSettings.EnableFCColorMarking[1]
		or (isCombat and allSettings.CompactCombat[1])

	-- Decide whether the legacy in-band palette escapes
	-- (\x1E\NN, \x1F\NN) should be PRESERVED through CleanTextFunctionNew so
	-- a downstream step can translate them to MC tokens:
	--   • FC marking inactive  → preserve (legacy escapes are the
	--     only colour information left).
	--   • FC marking active + channel-default colour is pure white
	--     → preserve (FC has no opinion about this channel's
	--     colour, so let inline escapes through).
	--   • FC marking active + channel colour non-white
	--     → drop (FC's per-channel colour owns the line).
	local channel_col_default = utils_modesDA[par.MessageMode + 1][3]
	local respectLegacyColors = (not fcMarkingActive)
		or (channel_col_default == 0xFFFFFFFF)

	-- 3. Single-pass transcode.
	local result = utils.TranscodeFFXI(text, compactCombat, respectLegacyColors)

	-- 4. Path-specific tail-end fixups.
	if compactCombat then
		return result
	else
		if allSettings.heartEmoji[1] then
			result = string_gsub(result, '<3', utf8.char(0x2764))
		end
		return result:match('^%s*(.-)%s*$')
	end
end
_G.CleanTextFunctionNew = M.CleanTextFunctionNew

-- ===================================================================
-- HandleSpecial: given a (prefix, suffix) pair and a color, locate
-- the span between them in `newText` and return a {newText, MCTable,
-- cutIdx} triple.  Handles the case where the closing suffix is on a
-- *future* line by stashing the open color in `par.checkAgain` so the
-- next line can finish the span.  Used heavily by CheckSpecial below.
-- ===================================================================
function M.HandleSpecial(newText, category, prefix, suffix, cutIdx, color, replacements)
	local text_b, text_e, color_b, color_e, MCTable

	if not prefix and par.checkAgain[2] == category then
		local span_start = par.checkAgain[1] or 0
		local end_pos
		local re_arm = true
		if suffix then
			local suf_start = utils_FindLastOfString(newText, suffix)
			if suf_start then
				end_pos = suf_start - 1 + #suffix
				re_arm  = false
			else
				end_pos = #newText
			end
		else
			end_pos = #newText
			re_arm  = false
		end
		par.checkAgain = re_arm and {0, category} or {0, ''}
		return {newText, {span_start, end_pos, color}, cutIdx}
	end
	
	if prefix then
		text_b, text_e = string_find(newText, prefix)
	else
		text_b = 1
		text_e = 1
	end

	if text_b then
		color_b = text_e
		if suffix and prefix then
			color_e = utils_FindLastOfString(newText, suffix, color_b)
		elseif not suffix and prefix then
			color_e = #newText + 1
		elseif not prefix then
			color_b = utils_FindLastOfString(newText, suffix)
			if color_b then
				color_b = color_b - 1
				color_e = color_b + 1 + #suffix
			else
				return {newText, nil, cutIdx}
			end
		end
		if color_e then
			color_e = color_e - 1
			if color_b >= cutIdx then
				par.checkAgain = {color_b - cutIdx, category}
				MCTable = {0, 0}
				return {newText, nil, cutIdx}
			else
				if color_e > cutIdx then
					par.checkAgain = {0, category}
					MCTable = {color_b, #newText, color}
					return {newText, MCTable, cutIdx}
				else
					MCTable = {color_b, color_e, color}
					return {newText, MCTable, cutIdx}
				end
			end
		end
		return {newText, nil, cutIdx}
	elseif par.checkAgain[2] == category then
		if suffix then
			color_e = utils_FindLastOfString(newText, suffix)
		elseif not suffix and prefix then
			color_e = #newText + 1
		elseif not prefix then
			color_b = utils_FindLastOfString(newText, suffix)
			if color_b then
				color_b = color_b - 1
				color_e = color_b + 1 + #suffix
			else
				return {newText, nil, cutIdx}
			end
		end
		if color_e then
			color_e = color_e - 1
		else
			return {newText, nil, cutIdx}
		end
		MCTable = {par.checkAgain[1], color_e, color}
		return {newText, MCTable, cutIdx}
	end
	return {newText, nil, cutIdx}
end
_G.HandleSpecial = M.HandleSpecial

-- ===================================================================
-- CheckSpecial: dispatch by MessageMode to the right HandleSpecial
-- pattern.  Recognises:
--   * Loot results: You find / synth / throw / lot / sell / buy
--   * Level attain (with icons.LVLUP), caught/learn
--   * Item obtain / key-item / bazaar / use
--   * Exp / limit gain (with icons.EXP)
-- ===================================================================
function M.CheckSpecial(newText, col, cutIdx)

	

	if par.MessageMode == 121 then
		if newText:find('You find') or par.checkAgain[2] == 'youfind' then
			if par.checkAgain[2] == '' then
				if allSettings.EnableFCColorMarking[1] then
				--	newText = newText:gsub('You find', 'Found'):gsub(' on ', icons.LOOT..' on ')
					newText = newText:gsub(' on ', icons.LOOT..' on ')
				else
				--	newText = newText:gsub('You find', 'Found'):gsub(' on  ', icons.LOOT..' on ')
					newText = newText:gsub(' on  ', icons.LOOT..' on ')
				end
				if newText:find(' on the %.') then newText = newText:gsub('%.', '{?}.'); cutIdx = cutIdx + 3 end
			end
			cutIdx = cutIdx + 3
			return HandleSpecial(newText, 'youfind', 'find ', ' on ', cutIdx, allSettings.colors.found[1])
		elseif newText:find(' synthesized ') or par.checkAgain[2] == 'synth' then
			return HandleSpecial(newText, 'synth', 'You synthesized ', '%.', cutIdx, allSettings.colors.obtained[1])
		elseif newText:find('You throw away ') or par.checkAgain[2] == 'throw' then
			return HandleSpecial(newText, 'throw', 'You throw away ', '%.', cutIdx, allSettings.colors.negative[1])
		elseif newText:find(' attains level [%d]+!') or par.checkAgain[2] == 'attain' then
			if par.checkAgain[2] == '' then
				newText = newText:gsub('%sl', string.upper):gsub('!', ' '..icons.LVLUP)
				cutIdx = cutIdx + 3
			end
			return HandleSpecial(newText, 'attain', ' attains ', nil, cutIdx, allSettings.colors.attain[1])
		
		--if newText:find(' caught ') or par.checkAgain[2] == 'caught2' then
		--	return HandleSpecial(newText, 'caught2', fcw[1].PlayerName, '%!', cutIdx, allSettings.colors.obtained[1])
		--end
		elseif newText:find(' learns ') or par.checkAgain[2] == 'learn' then
			return HandleSpecial(newText, 'learn', fcw[1].PlayerName, '%.', cutIdx, allSettings.colors.learn[1])
		elseif newText:find(' lot for ') or par.checkAgain[2] == 'lot' then
			par.tabmode = -1
			par.LastMode = 'lot'
			return HandleSpecial(newText, 'lot', ' lot for ', '%.', cutIdx, allSettings.colors.lot[1])
		elseif newText:find('You sell ') or par.checkAgain[2] == 'sell' then
			return HandleSpecial(newText, 'sell', 'You sell ', ' to ', cutIdx, allSettings.colors.obtained[1])
		elseif newText:find('You buy ') or par.checkAgain[2] == 'buy' then
			return HandleSpecial(newText, 'buy', 'You buy ', ' from ', cutIdx, allSettings.colors.obtained[1])
		end
	end

	if par.MessageMode == 142 or par.MessageMode == 151 then
		if newText:find('You obtain.*%.') or par.checkAgain[2] == 'obtain1' then
			return HandleSpecial(newText, 'obtain1', 'You obtain', '%.', cutIdx, allSettings.colors.obtained[1])
		elseif newText:find('Obtained:') or par.checkAgain[2] == 'obtain2' then
			return HandleSpecial(newText, 'obtain2', 'Obtained:', '%.', cutIdx, allSettings.colors.obtained[1])
		--if newText:find(fcw[1].PlayerName..' caught') or par.checkAgain[2] == 'caught' then
		--	return HandleSpecial(newText, 'caught', fcw[1].PlayerName..' caught ', '%!', cutIdx, allSettings.colors.found[1])
		--end
		elseif newText:find(' obtains ') or par.checkAgain[2] == 'obtain3' then
			return HandleSpecial(newText, 'obtain3', ' obtains ', '%.', cutIdx, allSettings.colors.obtained[1])
		elseif newText:find('You have a good feeling about') or par.checkAgain[2] == 'fshg' then
			return HandleSpecial(newText, 'fshg', 'You have a ', 'feeling about', cutIdx, 0xFF96FF5C)
		elseif newText:find('something pulling') or par.checkAgain[2] == 'fshi' then
			return HandleSpecial(newText, 'fshi', 'feel ', 'pulling', cutIdx, 0xFFFFCD19)
		elseif newText:find('Something caught the hook') or par.checkAgain[2] == 'fshf' then
			return HandleSpecial(newText, 'fshf', nil, 'Something', cutIdx, 0xFF96FF5C)
		elseif newText:find('have enough skill') or par.checkAgain[2] == 'fshs' then
			return HandleSpecial(newText, 'fshs', 'have', 'to', cutIdx, 0xFFFFCD19)
		elseif newText:find('This strength') or par.checkAgain[2] == 'fshr' then
			return HandleSpecial(newText, 'fshr', nil, 'This', cutIdx, 0xFFFFCD19)
		elseif newText:find('have a bad feeling about') or par.checkAgain[2] == 'fshb' then
			return HandleSpecial(newText, 'fshb', 'have ', 'feeling', cutIdx, 0xFFFF391F)
		elseif newText:find('have a terrible feeling') or par.checkAgain[2] == 'fsht' then
			return HandleSpecial(newText, 'fsht', 'have ', 'feeling', cutIdx,  0xFFFF391F)
		elseif newText:find('your skill level is too low to catch') or par.checkAgain[2] == 'fshl' then
			return HandleSpecial(newText, 'fshl', 'your skill level is ', 'to', cutIdx,  0xFFFF391F)
		elseif newText:find('Something clamps onto your line ferociously') or par.checkAgain[2] == 'fshm' then
			return HandleSpecial(newText, 'fshm', nil, 'Something', cutIdx,  0xFFFF391F)
		elseif newText:find('Obtained key item: ') or par.checkAgain[2] == 'KI' then
			return HandleSpecial(newText, 'KI', 'Obtained key item: ', '%.', cutIdx, allSettings.colors.keyitem[1])
		end
	end

	if par.MessageMode == 121 or par.MessageMode == 142 or par.MessageMode == 131 or par.MessageMode == 127 then
		if newText:find(' obtains ') or par.checkAgain[2] == 'obtain4' then
			if newText:find('gil') then
				if par.checkAgain[2] == '' then
					newText = newText:gsub('gil%.', 'gil'..icons.GIL)
					cutIdx = cutIdx + 2
				end
				return HandleSpecial(newText, 'obtain4', ' obtains ', nil, cutIdx, allSettings.colors.obtained[1])
			else
				return HandleSpecial(newText, 'obtain4', ' obtains ', '%.', cutIdx, allSettings.colors.obtained[1])
			end
		elseif newText:find('You obtain.*!') or par.checkAgain[2] == 'obtain5' then
			return HandleSpecial(newText, 'obtain5', 'You obtain ', '!', cutIdx, allSettings.colors.obtained[1])
		elseif newText:find('Records of Eminence') or par.checkAgain[2] == 'roe' then
			return HandleSpecial(newText, 'roe', 'Records of Eminence: ', '%.', cutIdx, allSettings.colors.roe[1])
		elseif newText:find('Progress: [0-9]*/[0-9]*') or par.checkAgain[2] == 'roep' then
			return HandleSpecial(newText, 'roep', 'Progress: ', '%.', cutIdx, allSettings.colors.roe[1])
		end
	end

	if par.MessageMode == 131 or par.MessageMode == 121 then
		if (newText:find(' gains ') and newText:find('experience')) or par.checkAgain[2] == 'exp' then
			if par.checkAgain[2] == '' then
				newText = newText:gsub('points%.', 'points'..icons.EXP)
				cutIdx = cutIdx + 2
			end
			par.tabmode = 3
			par.LastMode = 'combat'
			return HandleSpecial(newText, 'exp', ' gains ', nil, cutIdx, allSettings.colors.obtained[1])
		elseif (newText:find(' gains ') and newText:find('lim')) or par.checkAgain[2] == 'limit' then
			if par.checkAgain[2] == '' then
				newText = newText:gsub('points%.', 'points'..icons.EXP)
				cutIdx = cutIdx + 2
			end
			par.tabmode = 3
			par.LastMode = 'combat'
			return HandleSpecial(newText, 'lim', ' gains ', nil, cutIdx, allSettings.colors.obtained[1])
		end
	end

	if par.MessageMode == 90 or par.MessageMode == 85 then
		if newText:find(' uses ') or par.checkAgain[2] == 'use' then
			return HandleSpecial(newText, 'use', ' uses ', '%.', cutIdx, allSettings.colors.useitem[1])
		end
	end

	if par.MessageMode == 138 then
		if newText:find(' bought ') or par.checkAgain[2] == 'bazaar' then
			return HandleSpecial(newText, 'bazaar', ' bought ', '%.', cutIdx, allSettings.colors.obtained[1])
		end
	end
	
end
_G.CheckSpecial = M.CheckSpecial

-- ===================================================================
-- SetBufferN: tab-name -> b.ChatBufferN_* lookup.  Called from the
-- render loop after a tab change so the visible-line counter shows
-- the right tab's history depth.  The fallback `chatBufferN_All`
-- on the last line is an undefined global typo in the original; it
-- evaluates to nil and is preserved verbatim to avoid behaviour
-- change in the never-actually-reached default branch.
-- ===================================================================
function M.SetBufferN(tabname)
	if tabname == 'All'       then return b.ChatBufferN_All       end
	if tabname == 'AllAlt'    then return b.ChatBufferN_AllAlt    end
	if tabname == 'Combat'    then return b.ChatBufferN_Combat    end
	if tabname == 'Linkshell' then return b.ChatBufferN_Linkshell end
	if tabname == 'Party'     then return b.ChatBufferN_Party     end
	if tabname == 'Tell'      then return b.ChatBufferN_Tell      end
	if tabname == 'Shout'     then return b.ChatBufferN_Shout     end
	if tabname == 'Custom'    then return b.ChatBufferN_Custom    end
	return chatBufferN_All
end
_G.SetBufferN = M.SetBufferN

-- ===================================================================
-- SetTargetPosX: render-loop helper that picks the menu-aware
-- target X / Y for chat repositioning when an FFXI UI menu is open.
-- The mvc.Menu1..6 flags are set per-frame in d3d_present after
-- inspecting the active menu's name.
-- ===================================================================
function M.SetTargetPosX(x, y, positionStartX)
	if mvc.Menu1 or uiw.DialogShown then
		mvc.targetposY = (y / uiw.UISizeY * uiw.UISizeY) - ((y * 128) / uiw.UISizeY)
		return fcw[1].MoveChatPos1
	end
	if mvc.Menu2 then mvc.targetposY = (y / uiw.UISizeY * uiw.UISizeY) - ((y * 250) / uiw.UISizeY); return fcw[1].MoveChatPos2 end
	if mvc.Menu3 then mvc.targetposY = (y / uiw.UISizeY * uiw.UISizeY) - ((y * 250) / uiw.UISizeY); return fcw[1].MoveChatPos3 end
	if mvc.Menu4 then mvc.targetposY = (y / uiw.UISizeY * uiw.UISizeY) - ((y * 250) / uiw.UISizeY); return fcw[1].MoveChatPos4 end
	if mvc.Menu5 then mvc.targetposY = (y / uiw.UISizeY * uiw.UISizeY) - ((y * 160) / uiw.UISizeY); return fcw[1].MoveChatPos1 end
	if mvc.Menu6 then
		mvc.targetposY = (y / uiw.UISizeY * uiw.UISizeY) - ((y * 180) / uiw.UISizeY)
		return positionStartX
	end
	return 0
end
_G.SetTargetPosX = M.SetTargetPosX

-- ===================================================================
-- HandleActors: takes a chat line that has already had its non-actor
-- spans coloured, and wraps actor1 / actorP / actor2 / actorE /
-- action1 substrings in MC color escapes.  actor1/P are coloured as
-- "friendly" (or "you" if the name matches the player), actor2/E as
-- "foe", action1 as "ability".  Empties each par field after use so
-- the next message starts clean.
-- ===================================================================
function M.HandleActors(text, scol)
	if scol == '' then scol = 'reset' end
	local a1 = 1
	local a2 = 1
	local colors_actor1  = allSettings.colors.actor1[1]
	local colors_actor2  = allSettings.colors.actor2[1]
	local colors_you     = allSettings.colors.you[1]
	local colors_ability = allSettings.colors.ability[1]
	local player_name    = fcw[1].PlayerName

	if #par.actor1 > 0 then
		par.handled_actors = true
		-- (#11) Cache the escaped pattern: it's used 2× (gsub + find).
		local act1     = par.actor1
		local act1_esc = act1:escape()
		local color    = (act1 == player_name) and colors_you or colors_actor1
		text = text:gsub(act1_esc..'([^%a-])',
			(utils_MC(color)..act1..utils_MC('reset')):gsub('%%', '%%%%')..'%1', 1)
		_, a1 = text:find(act1_esc, 1, false)
		par.actor1 = ''
	end

	if #par.actorP > 0 then
		par.handled_actors = true
		local color = (par.actorP == player_name) and colors_you or colors_actor1
		text = text:sub(1, a1)..text:sub(a1 + 1, #text):replace(par.actorP,
			utils_MC(color)..par.actorP..utils_MC('reset'), 1)
		par.actorP = ''
	end

	if #par.actor2 > 0 then
		par.handled_actors = true
		-- (#11) Cache the escaped pattern: used 2×.
		local act2     = par.actor2
		local act2_esc = act2:escape()
		text = text:gsub(act2_esc..'([^%a-])',
			(utils_MC(colors_actor2)..act2..utils_MC('reset')):gsub('%%', '%%%%')..'%1', 1)
		_, a2 = text:find(act2_esc, 1, false)
		par.actor2 = ''
	end

	if #par.actorE > 0 then
		par.handled_actors = true
		text = text:sub(1, a2)..text:sub(a2 + 1, #text):replace(par.actorE,
			utils_MC(colors_actor2)..par.actorE..utils_MC('reset'), 1)
		par.actorE = ''
	end

	if #par.action1 > 0 then
		par.handled_actors = true
		text = text:replace(par.action1,
			utils_MC(colors_ability)..par.action1:gsub('\\', '['):gsub('/', ']')..utils_MC(scol), 1)
		par.action1 = ''
	end

	return text
end
_G.HandleActors = M.HandleActors

-- ===================================================================
-- HELMtext: given a {opening, closing} delimiter pair from FindHELM
-- and the chat line, return an MCList tuple {start, end, color} for
-- the yield span (or false).
-- ===================================================================
-- function M.HELMtext(t, text)
	-- local s = 0
	-- local e = 0
	-- local c = allSettings.colors.helm[1]
	-- if t[1] == 'harvest'
		-- or t[1] == 'dig up'
		-- or t[1] == 'cut off' then

		-- s = text:find(t[1], 1, true)
		-- if s then
			-- s = s + #t[1]
			-- e = text:find(t[2], s, true)
			-- if not e then e = #text end
			-- if e then e = e - 1 end
			-- return {s, e, c}
		-- else
			-- s = 0
			-- e = text:find(t[2], s, true)
			-- if e then
				-- e = e - 1
				-- return {s, e, c}
			-- end
		-- end
	-- end
	-- return false
-- end
-- _G.HELMtext = M.HELMtext

-- ===================================================================
-- FindHELM: detect a Harvesting/Excavation/Logging/Mining yield line
-- and return its {opening, closing} delimiter pair.  Modes 9 and 151
-- only.  Skips lines that contain a `:` past the timestamp (e.g.
-- "<player>: ..." chat lines that happen to mention these verbs).
-- ===================================================================
-- function M.FindHELM(text, mode)
	-- if mode ~= 9 and mode ~= 151 then return false end
	-- if text:find(':', #par.LastTS, true) then return false end

	-- local f = text:find(' harvest ')
	-- if f then
		-- local opening = 'harvest'
		-- local closing = text:find('!', f, true) and '!' or nil
		-- if not closing then
			-- closing = text:find(',', f, true) and ',' or nil
		-- end
		-- if closing then return {opening, closing} end
	-- end

	-- f = text:find(' dig up ')
	-- if f then
		-- local opening = 'dig up'
		-- local closing = text:find('!', f, true) and '!' or nil
		-- if not closing then
			-- closing = text:find(',', f, true) and ',' or nil
		-- end
		-- if closing then return {opening, closing} end
	-- end

	-- f = text:find(' cut off ')
	-- if f then
		-- local opening = 'cut off'
		-- local closing = text:find('!', f, true) and '!' or nil
		-- if not closing then
			-- closing = text:find(',', f, true) and ',' or nil
		-- end
		-- if closing then return {opening, closing} end
	-- end

	-- return false
-- end
-- _G.FindHELM = M.FindHELM

-- ===================================================================
-- parseThis: the dispatcher.  See module-header comment for the full
-- pipeline.  Exposed as a global because the original code declared it
-- without `local` (`parseThis = function(...) end`); preserving that
-- visibility avoids touching anything that may have captured it via
-- the global namespace.
-- ===================================================================
parseThis = function(e, e_message)
	local msg = e_message
	par.CombatCutIdx    = 0
	par.actor1          = ''
	par.actor2          = ''
	par.actorP          = ''
	par.actorE          = ''
	par.action1         = ''
	par.isDamage        = false
	par.handled_actors  = false
	par.DamageDone      = false
	par.DamageGot       = false
	local original_msg  = ''
	par.LastMode        = 'unknown'

	-- Strip stray DC2 (\x07) bytes that follow non-control characters:
	-- replace the (char, \x07) pair with (char, ' ').
	msg = msg:gsub('[^\x1E\x1F][\x07]', function(s)
		return s:sub(1, 1):append(' ')
	end)

	par.MessageMode = bit_band(e.mode, 0x000000FF)

	-- Cache (#6): os.date(par.FormatTS[1], os.time()) is queried in
	-- multiple places below (the de-dup check, the LastTS update,
	-- and PreciseTS).  Compute the timestamp ONCE here.
	local now             = os_time()
	local ts_default      = os_date(par.FormatTS[1], now)..' '
	local ts_user         = allSettings.timeStamp[1]
		and os_date(par.FormatTS[allSettings.FormatTSMode], now)..' '
		or ''
	local ts = ts_user

	original_msg = msg

	-- Forward-prompt detection for NPC dialog (modes 150/151): if the
	-- message ends with one of utils_fwdchars, show the down-arrow
	-- glyph and mark IsInConv so subsequent lines collapse correctly.
	local fwdmsg = false
	if par.MessageMode == 150 or par.MessageMode == 151 then
		for _, FWDchar in ipairs(utils_fwdchars) do
			if msg:endswith(FWDchar) then
				fo.Fwd[1]:set_visible(true)
				if allSettings.SecondChat[1] then fo.Fwd[2]:set_visible(true) end
				par.IsInConv = true
				fwdmsg = true
				break
			end
		end
	else
		if not par.IsInConv then
			fo.Fwd[1]:set_visible(false)
			if allSettings.SecondChat[1] then fo.Fwd[2]:set_visible(false) end
		end
	end

	-- Pick base color from the modesDA descriptor table, then override
	-- `defaultColor` is a pre-existing dead reference (defaultColor is
	-- nil; col is always overwritten on the next line) — preserved
	-- byte-for-byte to avoid behaviour drift.
	local colstring = defaultColor
	local col = colstring

	local mdRow = utils_modesDA[par.MessageMode + 1]
	par.LastMode = mdRow[2]
	col          = mdRow[3]

	-- FC colour marking is "active" for this message when the user
	-- has it globally enabled, OR when the line is a combat-mode
	-- message being reformatted by compact combat (the compact
	-- formatter relies on FC's MC pipeline for actor highlighting,
	-- so we force it ON for combat regardless of the global flag).
	-- Anywhere downstream that previously gated on the raw
	-- allSettings.EnableFCColorMarking[1] should now check
	-- fcMarkingActive instead.
	local fcMarkingActive = allSettings.EnableFCColorMarking[1]
		or (string_find(par.LastMode, 'combat') and allSettings.CompactCombat[1])

	-- Whether to honour legacy in-band palette escapes
	-- (\x1E\NN, \x1F\NN).  TRUE means the wrap-loop will run
	-- translateLegacyColors on each wrapped line.
	--   • Always TRUE when fcMarkingActive is FALSE — legacy
	--     escapes are the only colour info left.
	--   • Also TRUE when fcMarkingActive is TRUE but the channel-
	--     default colour from modesDA is pure white — FC has no
	--     opinion about the channel's colour, so we let inline
	--     escapes through and they coexist with FC's MCList /
	--     HandleActors highlights.
	-- Mirrors the same logic used in CleanTextFunctionNew.
	local respectLegacyColors = (not fcMarkingActive)
		or (mdRow[3] == 0xFFFFFFFF)

	-- (#10) Direct prefix comparison via string_sub is ~3× faster than
	-- pattern :find for fixed prefixes.  Order matters: combatspell_
	-- must be checked before combat_ (the former has the latter as a
	-- substring once the underscore is included).
	local lm     = par.LastMode
	local colors = allSettings.colors
	if     string_sub(lm, 1, 12) == 'combatspell_' then col = colors.combatspell[1]
	elseif string_sub(lm, 1,  7) == 'combat_'      then col = colors.combat[1]
	elseif string_sub(lm, 1, 10) == 'linkshell1'   then col = colors.linkshell1[1]
	elseif string_sub(lm, 1, 10) == 'linkshell2'   then col = colors.linkshell2[1]
	elseif string_sub(lm, 1,  5) == 'party'        then col = colors.party[1]
	elseif string_sub(lm, 1,  4) == 'tell'         then col = colors.tell[1]
	elseif string_sub(lm, 1,  5) == 'shout'        then col = colors.shout[1]
	elseif string_sub(lm, 1,  5) == 'emote'        then col = colors.emote[1]
	-- Longer prefix first: 'error1' must be tested before 'error' or
	-- string_sub(lm, 1, 5) == 'error' would also match mode 123's
	-- 'error1' name and route it to the wrong palette slot.
	elseif string_sub(lm, 1,  6) == 'error1'       then col = colors.error1[1]
	elseif string_sub(lm, 1,  5) == 'error'        then col = colors.error[1]
	end

	if allSettings.tellNotification[1] and par.LastMode == 'tell_in' then
		ashita.misc.play_sound(string.format('%s\\notifications\\%s%s.wav',
			addon.path, allSettings.selectedNotification, allSettings.boostNotification[1] and 'B' or ''))
	end

	-- Block-flagging: hide the message in the legacy chat if requested.
	if not fcw[1].HideChat and not uiw.LegacyChatOpen then
		if par.MessageMode ~= 151 and par.MessageMode ~= 150 then
			if (string_find(par.LastMode, 'combat') or par.LastMode == 'filtered') and allSettings.blockCombat[1] then
				e.blocked = true
			else
				if allSettings.blockAll[1] then
					e.blocked = true
				end
			end
		else
			if not e.blocked and allSettings.blockAll[1] then
				fo.Fwd[1]:set_visible(true)
				if allSettings.SecondChat[1] then fo.Fwd[2]:set_visible(true) end
			end
		end
	end

	-- Unknown channel debug helper: tag the line and play a sound when
	-- the LastMode descriptor is a placeholder ("_?"), so the user
	-- knows to file a bug with the channel number.
	if string_find(par.LastMode, '%_%?') then
		col = 0xFFFFFFFF
		if utils.FindInStringTable(msg, utils.combatwords, 0) then
			par.LastMode = 'combat_y'
		end
		--msg = msg..' (chn: '..tostring(par.MessageMode)..')'
		--if true then
		--	ashita.misc.play_sound(string.format('%s\\notifications\\%s%s.wav', addon.path, 'notification_4', ''))
		--end
	end

	if original_msg == ''
		or original_msg:match('^%s*$')
		or original_msg:match('^@@%s') then
		par.LastMode = 'filtered'
		return
	end

	local newText = CleanTextFunctionNew(msg, par.LastMode)

	if newText:match('^%s*\n?$') then par.LastMode = 'empty' return end

	-- Alert-word match: play a sound if any alert word appears in the
	-- message and the channel is enabled in alertOptions.
	if allSettings.Alert[1] and (
		(allSettings.alertOptions[1] and par.LastMode == 'local')             or
		(allSettings.alertOptions[2] and par.LastMode == 'shout')             or
		(allSettings.alertOptions[3] and par.LastMode == 'party_in')          or
		(allSettings.alertOptions[4] and par.LastMode:find('^linkshell%d$'))  or
		(allSettings.alertOptions[5] and par.LastMode == 'unity')) then
		for al_i = 1, #set.alertList do
			if set.alertList[al_i] and set.alertList[al_i] ~= ''
				and string_lower(newText):find(string_lower(set.alertList[al_i]), 1, true) then
				ashita.misc.play_sound(string.format('%s\\notifications\\%s%s.wav',
					addon.path, allSettings.selectedAlert, allSettings.boostAlert[1] and 'B' or ''))
			end
		end
	end

	if par.MessageMode == 123 and string_find(newText, '{') ~= nil then
		newText = string_sub(newText, 1, string_find(newText, '{') - 1)
			..string_sub(newText, string_find(newText, '{') + 1, string_len(newText))
	elseif par.MessageMode == 129 then
		if utils_FindInStringTable(newText, utils_crafts, 0) or newText:find('learns') then
			par.MessageMode = 121
			par.LastMode    = 'craft'
			col             = utils_modesDA[par.MessageMode + 1][3]
		end
	elseif par.MessageMode == 121 and string_find(newText, ' lot for ') then
		newText = newText:gsub('(: )(%d)', icons.ROLL..' %2'):gsub(' points%.', '')
	end

	-- Resolve current target / battle-target / pet names so we can
	-- decide whether messages refer to "you" or to a foe.
	local playerTarget = AshitaCore:GetMemoryManager():GetTarget()
	local party        = AshitaCore:GetMemoryManager():GetParty()
	local entity       = AshitaCore:GetMemoryManager():GetEntity()
	local bt           = targets.get_bt()
	local bt_name      = '@'
	if bt ~= nil then bt_name = bt.Name:gsub('^\171', '') end
	local t_name = '@'
	if playerTarget ~= nil then
		local targetIndex = playerTarget:GetTargetIndex(0)
		local targetEntity = GetEntity(targetIndex)
		if targetEntity and bit_band(targetEntity.SpawnFlags, 0x10) ~= 0 then
			t_name = targetEntity.Name:gsub('^\171', '')
		end
	end
	local pet
	local pet_name = '@'
	if party:GetMemberIsActive(0) ~= 0 then
		pet = targets.get_pet()
		if pet ~= nil then pet_name = pet.Name end
	end

	local isTarget = string_find(newText, t_name) or string_find(newText, bt_name)

	local player_name = fcw[1].PlayerName
	-- (#20) Pre-allocate slots: up to 6 party members + pet + (later) self.
	par.party_names = table_new(8, 0)
	for P_i = 0, 5 do
		if party:GetMemberIsActive(P_i) ~= 0 then
			table_insert(par.party_names, party:GetMemberName(P_i))
		end
	end
	if pet then table_insert(par.party_names, pet_name) end

	-- Debug colors: when ChannelColorMode is enabled the line gets
	-- painted by classification (you / party / others / target /
	-- enemy / alliance) instead of normal mode color.
	local debugclors = dw.ChannelColorMode[1]
	local col_y = debugclors and 0xFF03FC39 or col
	local col_p = debugclors and 0xFFFCB503 or col
	local col_n = debugclors and 0xFFFC0335 or col
	local col_t = debugclors and 0xFF572A03 or col
	local col_e = debugclors and 0xFF333333 or col
	local col_a = debugclors and 0xFFFFCCCC or col

	local isYou      = false
	local isParty    = false
	local isAlliance = false
	local isOthers   = false
	if par.LastMode:find('combat', 1, true) then
		if string_find(par.LastMode, '_y', 1, true) then
			isYou = true; col = col_y
		elseif string_find(par.LastMode, '_p', 1, true) then
			isParty = true; col = col_p
		elseif string_find(par.LastMode, '_n', 1, true) then
			if not string_find(newText, pet_name) then
				isOthers = true; col = col_n
			else
				isYou = true; col = col_t
			end
		elseif string_find(par.LastMode, '_t', 1, true) then isYou = true;     col = col_t
		elseif string_find(par.LastMode, '_e', 1, true) then isYou = true;     col = col_e
		elseif string_find(par.LastMode, '_a', 1, true) then isAlliance = true; col = col_a
		elseif string_find(par.LastMode, '_u', 1, true) then
			if string_find(newText, player_name) or utils_StringFindTable(newText, utils_disambYou, 1) then
				isYou = true; col = col_y
			elseif utils_StringFindTable(newText, par.party_names) then
				isParty = true; col = col_p
			elseif isTarget and string_find(newText, ' falls ') then
				isYou = true; col = col_y
			else
				isOthers = true
			end
		elseif string_find(par.LastMode, '_x', 1, true) then
			if string_find(newText, pet_name) and isTarget then
				isYou = true; col = col_t
			elseif string_find(newText, player_name) or utils_StringFindTable(newText, utils_disambYou, 1) then
				isYou = true; col = col_y
				if par.MessageMode == 191 and newText[#newText] == ':' then par.allowed = {191, 6} end
			elseif utils_StringFindTable(newText, par.party_names) then
				isParty = true; col = col_p
			elseif isTarget and not utils_StringFindTable(newText, utils_disambEnemy, 1) then
				isYou = true; col = col_e
			else
				isOthers = true; col = col_n
			end
		else
			if isTarget and not utils_StringFindTable(newText, utils_disambEnemy, 1) then
				isOthers = true; col = col_n
			elseif isTarget and utils_StringFindTable(newText, utils_disambEnemy, 1) then
				isYou = true; col = col_e
			end
		end

		if par.MessageMode == par.allowed[1] and par.allowed[2] > 0 then
			par.allowed[2] = par.allowed[2] - 1
			isYou = true; isOthers = false; isAlliance = false
		end

		if (allSettings.hideAlliance[1] and isAlliance)
			or (allSettings.hideNonParty[1] and isOthers)
			or (allSettings.hideNonYou[1]   and not isYou) then
			par.LastMode = 'filtered'
			return
		end

		local scope = '_z'
		if isYou then scope = '_y' elseif isYou or isParty then scope = '_p' end

		if allSettings.CustomFilters[1] then
			if utils_FindInStringTableFilters(newText, par.customFilters, scope) then
				par.LastMode = 'filtered'
				return
			end
		end
	end

	table_insert(par.party_names, player_name)

	-- Combat line transformation: hand off to lib/combat.lua's
	-- CombatText / CombatSpellText (exposed as globals).
	local iscombatspell = string_find(par.LastMode, 'combat_') and string_find(newText, ' cast')
	iscombatspell = iscombatspell or string_find(par.LastMode, 'combatspell_')
	if allSettings.CompactCombat[1] then
		if iscombatspell then
			newText = CombatSpellText(newText, par.MessageMode)
			col = allSettings.colors.combatspell[1]
			par.LastMode:gsub('combat_', 'combatspell_')
		end

		if string_find(par.LastMode, 'combat_') then
			newText = CombatText(newText, par.MessageMode)
			if allSettings.PreciseTS[1] and utils_IsInTable({36, 37, 44, 166}, par.MessageMode) then
				-- Use the once-computed ts_default (#6) without trailing space.
				newText = newText..' '..string_sub(ts_default, 1, -2)
			end
		end
	end

	if par.CombatCutIdx > 0 then
		par.CombatCutIdx = par.CombatCutIdx + #ts
	end
	newText = ts..newText
	local offset = #ts

	-- De-duplicate: same text on the same TS, with exceptions for a
	-- handful of MessageMode that may legitimately repeat.  ts_default
	-- was computed once at the top of parseThis (#6).
	local newText_len = #newText
	local checkMsgOrDate = string_sub(newText, 1 + offset, newText_len) ~= par.LastMessage
		or par.LastTS ~= ts_default
		or par.MessageMode == 121
		or par.MessageMode == 127
		or par.MessageMode == 131
		or par.MessageMode == 142
		or par.MessageMode == 204

	if checkMsgOrDate then
		b.msgID = b.msgID + 1
		par.LastMsgLength = newText_len

		par.LastTS      = ts_default
		par.LastMessage = string_sub(newText, 1 + offset, newText_len)

		-- tab routing: which dedicated tab does this line belong to?
		local isCombatMsg = false
		par.tabmode = nil
		if     string_find(par.LastMode, '^combat')    then par.tabmode = 3; isCombatMsg = true
		elseif string_find(par.LastMode, '^linkshell') then par.tabmode = 4
		elseif string_find(par.LastMode, '^party')     then par.tabmode = 5
		elseif string_find(par.LastMode, '^tell')      then par.tabmode = 6
		elseif string_find(par.LastMode, '^shout')     then par.tabmode = 7
		else par.tabmode = -1
		end

		-- Custom tab membership: the user can opt-in NPC / LS / Party
		-- / Tell / Shout into the Custom tab via Settings.
		par.isCustom = false
		for cmode = 1, #allSettings.CustomTabModes do
			if allSettings.CustomTabModes[cmode] then
				if cmode == 1 and string_find(par.LastMode, 'NPC$') or par.tabmode == cmode + 2 then
					par.isCustom = true
					break
				end
			end
		end
		
		-- Line-wrap and per-line emit loop.
		local n_lines = math_floor(string_len(newText) / allSettings.chatLineMaxL)
		if math_fmod(string_len(newText), allSettings.chatLineMaxL) ~= 0 then n_lines = n_lines + 1 end

		par.checkAgain = {0, ''}

		local textLeft = string_len(newText)
		local L_i = 1
		local urlText = ''
		if not isCombatMsg then urlText = utils_ParseUrlLink(newText) end
		local auxURL_text = ''
		local skipped = 0
		--local HELMfound = FindHELM(newText, par.MessageMode)

		-- (#2) Hoist the primary chat buffer once.  Inside this loop
		-- it gets touched up to 14× per iteration; reading b.ChatBuffer
		-- [1][2] each time would re-traverse the 4-deep table chain.
		local buf1 = b.ChatBuffer[1][2]

		-- Active legacy colour state, carried across the wrap loop so
		-- that a colour opened on line N continues into line N+1 when
		-- the message wraps.  nil = no colour active.
		local active_legacy_color = nil

		while L_i <= n_lines do
			newText = newText:trimex()
			if newText:match('^%s$') or newText == '' then n_lines = L_i - 1; break end

			local special_idx   = nil
			local special_text  = ''
			local special_color = ''

			local bytesLine = utils_CountExtraBytesT(newText)
			local cutIdx = math_min(allSettings.chatLineMaxL + bytesLine[math_min(allSettings.chatLineMaxL, #bytesLine)] + 1, textLeft)

			-- Atomicity for legacy colour escapes: never let a slice
			-- end on the lead byte of \x1E\NN or \x1F\NN with the
			-- trail byte carrying over to the next line.  When
			-- detected, advance cutIdx past the trail so the escape
			-- stays whole.
			while cutIdx >= 1 and cutIdx < textLeft do
				local lb = string_byte(newText, cutIdx)
				if lb == 0x1E or lb == 0x1F then
					cutIdx = cutIdx + 1
				else
					break
				end
			end

			local lineBreak = ''

			if L_i < n_lines and string_byte(newText, cutIdx) ~= 32 and cutIdx ~= textLeft then
				cutIdx = utils_utf8split(newText, cutIdx)
				if not isCombatMsg and urlText == '' and string_byte(newText, cutIdx) ~= 32 and cutIdx < #newText and string_byte(newText, cutIdx + 1) ~= 32 then
					lineBreak = '-'
				else
					cutIdx = cutIdx + 1
				end
				if isCombatMsg and #newText - cutIdx < 3 then
					local last_space = utils_FindLastOf(string_sub(newText, 1, cutIdx), ' ')
					if last_space ~= nil and last_space > par.CombatCutIdx then
						if (cutIdx - last_space) < 15 then cutIdx = last_space - 1; lineBreak = '' end
					end
				end
				if textLeft > cutIdx and string_byte(newText, cutIdx) ~= 32 and string_byte(newText, cutIdx + 1) ~= 32 then
					local last_space = utils_FindLastOf(string_sub(newText, 1, cutIdx), ' ')
					if last_space ~= nil then
						if (cutIdx - last_space) < 12 then cutIdx = last_space - 1; lineBreak = '' end
					end
				end
			end

			-- When CompactCombat splits the line at an actor / action
			-- boundary, prefer breaking BEFORE the actor name so the
			-- coloured span doesn't get cut in half across two lines.
			if allSettings.CompactCombat[1] then
				if isCombatMsg and par.CombatCutIdx > allSettings.chatLineMaxL then
					if #par.actor1 > 0 then
						local a = newText:find(par.actor1, 1, true)
						if a and cutIdx >= a and cutIdx - (a - 1) < #par.actor1 and a - 1 > 1 then cutIdx = a - 1 end
					end
					if #par.actor2 > 0 then
						local a = newText:find(par.actor2, 1, true)
						if a and cutIdx >= a and cutIdx - (a - 1) < #par.actor2 and a - 1 > 1 then cutIdx = a - 1 end
					end
					if #par.actorP > 0 then
						local a = newText:find(par.actorP, 1, true)
						if a and cutIdx >= a and cutIdx - (a - 1) < #par.actorP and a - 1 > 1 then cutIdx = a - 1 end
					end
					if #par.actorE > 0 then
						local a = newText:find(par.actorE, 1, true)
						if a and cutIdx >= a and cutIdx - (a - 1) < #par.actorE and a - 1 > 1 then cutIdx = a - 1 end
					end
				end

				if isCombatMsg and #par.action1 > 1 then
					if #par.action1 > 0 then
						local a = newText:find(par.action1, 1, true)
						if a and cutIdx >= a and cutIdx - (a - 1) < #par.action1 and a - 1 > 1 then cutIdx = a - 1 end
					end
				end
			end

			if L_i == n_lines then
				if string_byte(newText, cutIdx) ~= 32 and cutIdx < textLeft then
					cutIdx = utils_utf8split(newText, cutIdx)
					if not isCombatMsg and urlText == '' and string_byte(newText, cutIdx) ~= 32 and cutIdx < #newText and string_byte(newText, cutIdx + 1) ~= 32 then
						lineBreak = '-'
					else
						cutIdx = cutIdx + 1
					end
					local last_space = utils_FindLastOf(string_sub(newText, 1, cutIdx), ' ')
					if last_space ~= nil then
						if (cutIdx - last_space) < 12 then cutIdx = last_space - 1; lineBreak = '' end
					end
					n_lines = n_lines + 1
				end

				if urlText ~= '' then
					if textLeft + 6 < allSettings.chatLineMaxL then
						auxURL_text = '[link]'
					else
						cutIdx = math_min(cutIdx, textLeft - 1)
						local last_space = utils_FindLastOf(string_sub(newText, 1, cutIdx), ' ')
						if last_space ~= nil then
							if (cutIdx - last_space) < 12 then cutIdx = last_space - 1; lineBreak = '' end
						end
						n_lines = n_lines + 1
					end
				end
			end

			-- MCList accumulates {start, end, color} tuples that
			-- HandleSpecial / FindHELM / CheckSpecial / actor handling
			-- want applied to this line.  Sorted by start before the
			-- final pass-through that writes MC escapes into the text.
			local MCList = {}

			if par.MessageMode == 9
				or par.MessageMode == 142
				or par.MessageMode == 151
				or par.MessageMode == 121
				or par.MessageMode == 131
				or par.MessageMode == 138
				or par.MessageMode == 127
				or par.MessageMode == 90
				or par.MessageMode == 85 then
				local MCSpecial = CheckSpecial(newText, col, cutIdx)
				if MCSpecial and MCSpecial[2] then
					newText = MCSpecial[1]
					table_insert(MCList, MCSpecial[2])
					if MCSpecial[3] then cutIdx = MCSpecial[3] end
				end
			end

			-- Timestamp prefix gets its own white color slot.
			if L_i == 1 and allSettings.timeStamp[1] then
				local e_close = newText:find(']')
				if e_close then table_insert(MCList, {0, e_close, 0xFFFFFFFF}) end
			end

			-- Auto-translate angle brackets: paint the left-quote red
			-- and the right-quote green.  (FFXI uses U+276E / U+276F
			local ATstart = 1
			while true do
				local s, e_pos = string_find(newText, utf8.char(0x276e), ATstart, true)
				if not s then break end
				if s - 2 > 1 and string_find(newText:sub(s - 2, s - 1), '|', 1, true) then
					newText = newText:gsub('|', '/')
				end
				table_insert(MCList, {s - 1, s + 2, 0xFF0D9441})
				ATstart = e_pos + 1
			end
			ATstart = 1
			while true do
				local s, e_pos = string_find(newText, utf8.char(0x276f), ATstart, true)
				if not s then break end
				table_insert(MCList, {s - 1, s + 2, 0xFFBB2F38})
				ATstart = e_pos + 1
			end

			if par.CombatCutIdx ~= 0 then
				if par.CombatCutIdx <= cutIdx then
					if par.CombatCutIdx > 0 then
						table_insert(buf1.text, string_sub(newText, 1, cutIdx)..lineBreak)

						if string_find(par.LastMode, 'combat_') and par.isDamage then
							special_color = allSettings.colors.damage[1]
							local cb = allSettings.ColorBlind[1] and 2 or 1
							if par.DamageDone then special_color = allSettings.colors.dmgdone[cb] end
							if par.DamageGot  then special_color = allSettings.colors.dmggot[cb]  end
							table_insert(MCList, {par.CombatCutIdx, #newText, special_color})
						else
							if string_find(par.LastMode, 'combatspell_') and par.isDamage then
								special_color = allSettings.colors.spelldamage[1]
								local cb = allSettings.ColorBlind[1] and 2 or 1
								if par.DamageDone then special_color = allSettings.colors.spelldmgdone[cb] end
								if par.DamageGot  then special_color = allSettings.colors.spelldmggot[cb]  end
							end
							table_insert(MCList, {par.CombatCutIdx, #newText, special_color})
						end

						par.CombatCutIdx = par.CombatCutIdx - cutIdx
						if par.CombatCutIdx == 0 then par.CombatCutIdx = -1 end
					else
						table_insert(buf1.text, string_sub(newText, 1, cutIdx)..lineBreak)
						if string_find(par.LastMode, 'combat_') and par.isDamage then
							col = allSettings.colors.damage[1]
							local cb = allSettings.ColorBlind[1] and 2 or 1
							if par.DamageDone then col = allSettings.colors.dmgdone[cb] end
							if par.DamageGot  then col = allSettings.colors.dmggot[cb]  end
							if allSettings.PreciseTS[1] and utils_IsInTable({36, 36, 44, 166}, par.MessageMode) then
								col = allSettings.colors.combat[1]
							end
						else
							if string_find(par.LastMode, 'combatspell_') and par.isDamage then
								col = allSettings.colors.spelldamage[1]
								local cb = allSettings.ColorBlind[1] and 2 or 1
								if par.DamageDone then col = allSettings.colors.spelldmgdone[cb] end
								if par.DamageGot  then col = allSettings.colors.spelldmggot[cb]  end
							end
						end
						special_text = ''
					end
				else
					table_insert(buf1.text, string_sub(newText, 1, cutIdx)..lineBreak)
					par.CombatCutIdx = par.CombatCutIdx - cutIdx
					special_text = ''
				end
			else
				table_insert(buf1.text, string_sub(newText, 1, cutIdx)..lineBreak)
				special_text = ''
			end

			-- if HELMfound then
				-- local HEMLtable = HELMtext(HELMfound, string_sub(newText, 1, cutIdx))
				-- if HEMLtable then
					-- fo.Fwd[1]:set_visible(false)
					-- fo.Fwd[2]:set_visible(false)
					-- table_insert(MCList, HEMLtable)
				-- end
			-- end

			-- Apply all accumulated MCList entries: sort by start, then
			-- splice MC escape sequences into the text.  Each escape
			-- adds 28 bytes, so the i-th insertion at index k must be
			-- offset by 28*(i-1).  Then HandleActors paints actor names.
			-- Skipped when fcMarkingActive is false (FC marking off
			-- AND not a combat-with-compact line) — the line stays
			-- as the plain post-CleanTextFunctionNew text the table_insert above
			-- wrote, which the renderer draws in the single
			-- buf1.color[i] colour.
			--
			-- MUST run BEFORE legacy-escape translation: the byte
			-- offsets in MCList reference positions in the cleaned
			-- text where 2-byte \x1E\NN / \x1F\NN escapes are still
			-- present.  If we expanded those to 14-byte MC tokens
			-- first, the MCList offsets would be wrong.
			if fcMarkingActive and (#MCList > 0 or par.handled_actors) then
				local mctext = buf1.text[#buf1.text]
				table.sort(MCList, function(a, b) return a[1] < b[1] end)
				for i = 1, #MCList do
					local mcoff = 28 * (i - 1)
					mctext = string_sub(mctext, 1, MCList[i][1] + mcoff)
						..utils_MC(MCList[i][3])
						..string_sub(mctext, MCList[i][1] + 1 + mcoff, MCList[i][2] + mcoff)
						..utils_MC('reset')
						..string_sub(mctext, MCList[i][2] + 1 + mcoff, #mctext)
				end

				if allSettings.CompactCombat[1] then
					mctext = HandleActors(mctext, special_color)
				end

				buf1.text[#buf1.text] = utils_MCCheck(mctext)
			end


			-- Legacy in-band palette escape translation.  Runs when
			-- respectLegacyColors is TRUE — either FC marking is
			-- inactive (legacy escapes are the only colour info) or
			-- FC marking is active but this channel's default colour
			-- is white (so FC has no opinion on it and we let inline
			-- escapes through, coexisting with FC's MC tokens).
			--
			-- gsub on \x1E and \x1F doesn't touch existing MC tokens
			-- (they contain neither byte), so running this AFTER the
			-- MCList splice is safe.
			--
			-- active_legacy_color carries colour state from the
			-- previous wrapped line into this one so a colour run
			-- begun before a wrap point continues correctly on the
			-- continuation line.
			if respectLegacyColors then
				local mctext = buf1.text[#buf1.text]
				if mctext and (active_legacy_color
					or mctext:find('\30', 1, true)
					or mctext:find('\31', 1, true)) then
					local new_text, new_state = utils.translateLegacyColors(mctext, active_legacy_color)
					buf1.text[#buf1.text] = new_text
					active_legacy_color = new_state
				end
			end

			-- White-paint the FancyChat timestamp prefix on the first
			-- wrapped line of a message — but only when FC marking
			-- is INACTIVE.  When FC marking is active the MCList
			-- block above already inserts a white MC entry for the
			-- timestamp, so doing it here would be redundant.
			if not fcMarkingActive
				and L_i == 1 and allSettings.timeStamp[1] and #ts > 0 then
				local mctext = buf1.text[#buf1.text]
				if mctext and #mctext >= #ts then
					buf1.text[#buf1.text] = '\\§FFFFFFFFç\\'
						..string_sub(mctext, 1, #ts)
						..'\\§--------ç\\'
						..string_sub(mctext, #ts + 1)
				end
			end

			if not buf1.text[#buf1.text] then
				skipped = skipped + 1
				table.remove(buf1.text, #buf1.text)
			else
				textLeft = textLeft - cutIdx
				if L_i < n_lines then
					newText = string_sub(newText, cutIdx + 1, string_len(newText))
				end
				if par.isCustom then par.LastMode = par.LastMode..'C' end
				table_insert(buf1.mode, tostring(par.MessageMode)..'|'..par.LastMode)
				-- Force the combat-line base colour to white when FC
				-- colour marking is globally OFF AND compact combat
				-- is OFF.  In that combination the user wants combat
				-- lines to be plain white text with no per-channel
				-- damage tint.  When compact combat is ON, FC marking
				-- is force-active for combat (see fcMarkingActive
				-- above) so the line keeps its normal channel colour
				-- and the FC pipeline paints actor highlights.
				local force_white = string_find(par.LastMode, 'combat')
					and not allSettings.EnableFCColorMarking[1]
					and not allSettings.CompactCombat[1]
				if force_white then
					table_insert(buf1.color, 0xFFFFFFFF)
				elseif type(col) == 'number' then
					table_insert(buf1.color, col)
				else
					table_insert(buf1.color, 0xFFFFFFFF)
				end

				if special_idx ~= nil then
					table_insert(buf1.auxText,  dw.ShowMessageMode[1] and (special_text..' >'..tostring(par.MessageMode)..(e.injected and '[i]' or '')) or special_text)
					table_insert(buf1.auxColor, special_color)
					table_insert(buf1.url,      b.msgID)
				else
					if urlText == '' then
						table_insert(buf1.auxText, dw.ShowMessageMode[1] and ('>'..tostring(par.MessageMode)..(e.injected and '[i]' or '')) or '')
						table_insert(buf1.url,     b.msgID)
					else
						table_insert(buf1.auxText, dw.ShowMessageMode[1] and (auxURL_text..'>'..tostring(par.MessageMode)) or auxURL_text)
						table_insert(buf1.url,     tostring(b.msgID)..'|'..urlText)
					end
					table_insert(buf1.auxColor, 0xFF44CCFF)
				end

				-- Mirror the same line into the AllAlt buffer when it
				-- isn't combat/custom (so the All-without-combat tab
				-- works), into the per-tab buffer (Combat/LS/Party/...)
				-- and into the Custom buffer when applicable.  Each
				-- branch hoists its target buffer alias once (#2).
				local last_text     = buf1.text    [#buf1.text]
				local last_color    = buf1.color   [#buf1.color]
				local last_auxText  = buf1.auxText [#buf1.auxText]
				local last_auxColor = buf1.auxColor[#buf1.auxColor]
				local last_url      = buf1.url     [#buf1.url]

				if par.tabmode and (par.tabmode ~= 3 and not par.isCustom) then
					local buf2 = b.ChatBuffer[2][2]
					table_insert(buf2.text,     last_text)
					table_insert(buf2.color,    last_color)
					table_insert(buf2.auxText,  last_auxText)
					table_insert(buf2.auxColor, last_auxColor)
					table_insert(buf2.url,      last_url)
				end
				if par.tabmode and par.tabmode > 2 then
					local bufT = b.ChatBuffer[par.tabmode][2]
					table_insert(bufT.text,     last_text)
					table_insert(bufT.color,    last_color)
					table_insert(bufT.auxText,  last_auxText)
					table_insert(bufT.auxColor, last_auxColor)
					table_insert(bufT.url,      last_url)
				end
				if par.isCustom then
					local bufC = b.ChatBuffer[8][2]
					table_insert(bufC.text,     last_text)
					table_insert(bufC.color,    last_color)
					table_insert(bufC.auxText,  last_auxText)
					table_insert(bufC.auxColor, last_auxColor)
					table_insert(bufC.url,      last_url)
				end

				-- Buffer-cap enforcement.
				if #buf1.text > b.ChatBufferMaxSize then
					local cleanupRanges = {b.CleanupThresh, 0, 0, 0, 0, 0, 0, 0}
					for tr = 1, b.CleanupThresh do
						local tabremove = 0
						local cremove   = 0
						if string_find(buf1.mode[tr], 'C$')         ~= nil then cremove = 8 end
						if string_find(buf1.mode[tr], '^combat')    ~= nil then tabremove = 3
						elseif string_find(buf1.mode[tr], '^linkshell') ~= nil then tabremove = 4
						elseif string_find(buf1.mode[tr], '^party')     ~= nil then tabremove = 5
						elseif string_find(buf1.mode[tr], '^tell')      ~= nil then tabremove = 6
						elseif string_find(buf1.mode[tr], '^shout')     ~= nil then tabremove = 7
						else tabremove = 0
						end
						if tabremove > 0 then
							if tabremove ~= 3 then cleanupRanges[2] = cleanupRanges[2] + 1 end
							cleanupRanges[tabremove] = cleanupRanges[tabremove] + 1
						end
						if cremove > 0 then
							cleanupRanges[cremove] = cleanupRanges[cremove] + 1
						end
					end
					for ci = 1, #cleanupRanges do
						BulkRemove(b.ChatBuffer[ci][2], cleanupRanges[ci])
					end
				elseif #b.ChatBuffer[3][2].text > b.CombatBufferMaxSize then
					local line = {}
					local tr = 1
					while #line < b.CleanupThresh and tr < #buf1.text do
						if string_find(buf1.mode[tr], 'combat') then
							table_insert(line, tr)
						end
						tr = tr + 1
					end
					BulkRemove(b.ChatBuffer[3][2], b.CleanupThresh)
					BulkRemoveCombat(buf1, line)
				end
			end
			L_i = L_i + 1
		end
		n_lines = n_lines - skipped
		b.ChatBufferN_All = b.ChatBufferN_All + n_lines
		if par.tabmode ~= 3 and not par.isCustom then b.ChatBufferN_AllAlt = b.ChatBufferN_AllAlt + n_lines end
		if allSettings.SelectedTab:find('^All') or allSettings.SelectedTab2:find('^All') then ResetAutoHideTimer() end

		if string_find(par.LastMode, '^combat') then
			b.ChatBufferN_Combat = b.ChatBufferN_Combat + n_lines
			if allSettings.SelectedTab == 'Combat' or allSettings.SelectedTab2 == 'Combat' then ResetAutoHideTimer() end
		elseif string_find(par.LastMode, '^linkshell') then
			b.ChatBufferN_Linkshell = b.ChatBufferN_Linkshell + n_lines
			if allSettings.SelectedTab == 'Linkshell' or allSettings.SelectedTab2 == 'Linkshell' then ResetAutoHideTimer() end
		elseif string_find(par.LastMode, '^party') then
			b.ChatBufferN_Party = b.ChatBufferN_Party + n_lines
			if allSettings.SelectedTab == 'Party' or allSettings.SelectedTab2 == 'Party' then ResetAutoHideTimer() end
		elseif string_find(par.LastMode, '^tell') then
			b.ChatBufferN_Tell = b.ChatBufferN_Tell + n_lines
			if allSettings.SelectedTab == 'Tell' or allSettings.SelectedTab2 == 'Tell' then ResetAutoHideTimer() end
		elseif string_find(par.LastMode, '^shout') then
			b.ChatBufferN_Shout = b.ChatBufferN_Shout + n_lines
			if allSettings.SelectedTab == 'Shout' or allSettings.SelectedTab2 == 'Shout' then ResetAutoHideTimer() end
		end
		if string_find(par.LastMode, 'C$') then
			b.ChatBufferN_Custom = b.ChatBufferN_Custom + n_lines
			if allSettings.SelectedTab == 'Custom' or allSettings.SelectedTab2 == 'Custom' then ResetAutoHideTimer() end
		end
	end
	par.LastMessageMode = par.MessageMode
end
_G.parseThis = parseThis

function M.register()
	-- =====================================================================
	-- text_in: chat-message intercept.  Filters by mode (suppresses 152
	-- internal-AT, conditionally blocks 190 legacy chat passthrough),
	-- captures every line into b.OriginalBuffer (for DumpChat replay,
	-- capped at 300 with chunk-trim), parses auto-translate inline,
	-- splits multi-line messages on LF, and dispatches each segment
	-- through parseThis.
	-- =====================================================================
	ashita.events.register('text_in', 'text_in_cb', function(e)
		if par.dumping then return end
		if #e.message > 2048 then return end

		-- Cache (#7): bit_band(e.mode, 0xFF) was called twice; once
		-- here as `mode_pre`, again in the OriginalBuffer prefix.
		local mode_pre = bit_band(e.mode, 0x000000FF)
		local mode_str = tostring(mode_pre)

		if mode_pre == 152 or e.blocked then e.blocked = true; return end
		if mode_pre == 190 then
			if allSettings.blockAll[1] and not (fcw[1].HideChat or uiw.LegacyChatOpen) then
				e.blocked = true
			end
			return
		end
		if mode_pre == 191 and string_find(e.message, 'version') then
			-- /servmes injection used to live here, gated on the
			-- "Loaded addon: fancychat" message arriving via mode 191.
			-- Moved to render.lua because the message is too early —
			-- it lands the moment Ashita finishes loading us, while
			-- the server may still be wrapping up its session
			-- handshake and silently drops the command.  render.lua's
			-- gate now waits for 30 non-injected packets (counted by
			-- lifecycle.lua's packet_in handler) PLUS a settle timer
			-- before firing, which is a much more reliable "the
			-- server is ready" signal than this single console line.
			AshitaCore:GetChatManager():AddChatMessage(0, false, e.message)
			return
		end

		table_insert(b.OriginalBuffer,
			mode_str..'|'..os_date('[%H:%M:%S]', os_time())..' '..e.message)
		if #b.OriginalBuffer >= 300 then
			local newBuffer = {}
			for i = 51, #b.OriginalBuffer do
				newBuffer[#newBuffer + 1] = b.OriginalBuffer[i]
			end
			b.OriginalBuffer = newBuffer
		end

		local e_message
		if mode_pre < 20 or mode_pre > 212 then
			e_message = AshitaCore:GetChatManager():ParseAutoTranslate(e.message, true)
		else
			e_message = e.message
		end

		-- (#4) string_byte(s, i) avoids per-byte substring alloc.
		local e_messages = {}
		local nextEi = 1
		local em_len = #e_message
		for E_i = 1, em_len do
			if string_byte(e_message, E_i) == 10 and E_i < em_len then
				table_insert(e_messages, string_sub(e_message, nextEi, E_i))
				nextEi = E_i + 1
			end
		end

		table_insert(e_messages, string_sub(e_message, nextEi, em_len))

		for E_i = 1, #e_messages do
			fcw[1].ProcessingText = true
			parseThis(e, e_messages[E_i])
			fcw[1].ProcessingText = false
		end
	end)
end

return M
