--[[
	lib/combat.lua

	Combat- and spell-line transformers.  Pure-ish functions: each
	takes a raw FFXI combat message string and returns a reformatted
	one with FancyChat's iconography (arrows, swords, sparkles,
	utsusemi marker, etc.) substituted in.  They DO mutate parser
	state (`par.actor1/2/P/E`, `par.action1`, `par.DamageDone/Got`,
	`par.isDamage`, `par.CombatCutIdx`, `par.LastMode`) so the
	post-transform colorisation pass in parseThis can pick up which
	parts of the line refer to whom, but they touch nothing else.

	Two functions, both exposed as globals so parseThis (still in
	fancychat.lua, soon to move to lib/parser.lua) can keep calling
	them by name:

	  CombatText(msg, chn)       Melee, ranged, item-use, parry,
	                             counter, miss, defeat, additional-
	                             effect, ability-ready, skillchain,
	                             plain "X takes N damage", utsusemi
	                             shadow absorption.

	  CombatSpellText(msg, chn)  Spell-cast, drain, recovery, status
	                             effect application, generic
	                             ability-on-target.

	`combatCP` is the per-iconography character map used by both
	functions — entirely private to this module.
]]

require('common')
local utils = require('utils')
local state = require('lib.state')

local par         = state.par
local fcw         = state.fcw
local allSettings = state.allSettings

-- Action / ability names get wrapped in delimiters that HandleActors
-- later converts to "[ ]" while colourising.  When the user has FC
-- colour marking off, HandleActors doesn't run, so emit "[ ]" up
-- front instead of the raw "\ /" — otherwise the user sees the
-- delimiter characters in the chat line.
local function wrap_action(s)
	if allSettings.EnableFCColorMarking[1] then
		return '\\'..s..'/'
	else
		return '['..s..']'
	end
end

-- Localised stdlib + utility lookups (#12, #13).  LuaJIT inlines local
-- references far better than table accesses, and these get hit hundreds
-- of times per combat line.
local string_find  = string.find
local string_gsub  = string.gsub
local string_sub   = string.sub
local string_len   = string.len
local string_match = string.match

local utils_StringFindTable = utils.StringFindTable
local utils_FindLastOfMB    = utils.FindLastOfMB
local utils_FindFirstOfMB   = utils.FindFirstOfMB
local icons                 = utils.icons

local M = {}

-- ===================================================================
-- Iconography codepoints used inside reformatted combat lines.
-- Most are from the gameicons.ttf PUA range (icons.*) so they
-- render via the custom font; the remainder are real Unicode.
-- ===================================================================
local combatCP = {
	RA    = icons.RA,
	COL   = utf8.char(0x589),
	USE   = utf8.char(0x1F4AB),
	PUM   = icons.PUM,
	CRIT  = utf8.char(0x1F4A5),
	ATK   = utf8.char(0x1F5E1),
	SC    = icons.SC,
	LEFT  = utf8.char(0x1F81C),
	RIGHT = utf8.char(0x1F81E),
	SPLIT = utf8.char(0x1F81E),
	PARR  = icons.PARR,
	CNTR  = utf8.char(0x2B8C),
	KILL  = utf8.char(0x2717),
	CAST  = icons.CAST,
	SPELL = icons.SPELL,
	HEAL  = icons.HEAL,
	SUB   = utf8.char(0x2514)..utf8.char(0x2500),
}

-- Precomputed byte-lengths of the iconography sequences used in
-- `utils_FindLastOfMB(msg, X) + #X - 1` style expressions (#8).  These
-- are constants that never change after module load.
local LEN_SPLIT = string_len(combatCP.SPLIT)
local LEN_RIGHT = string_len(combatCP.RIGHT)
local LEN_LEFT  = string_len(combatCP.LEFT)
local LEN_CAST  = string_len(combatCP.CAST)

-- ===================================================================
-- Party / foe classification helpers (#9).  These are the duplicated
-- 5-line if/else block that appeared 15+ times across CombatText and
-- CombatSpellText.  Each takes a name and writes par.actorN as a
-- side-effect, returning the (possibly trimmed) name for further use
-- in message rebuilding.
-- ===================================================================
local function classifyA(A)
	if utils_StringFindTable(A, par.party_names, nil, true) then
		par.actor1 = A
		return A
	end
	A = string_gsub(A, '[Tt]he ', '')
	par.actor2 = A
	return A
end

local function classifyB(B)
	if utils_StringFindTable(B, par.party_names, nil, true) then
		if #par.actor1 > 0 then par.actorP = B else par.actor1 = B end
		return B
	end
	B = string_gsub(B, '[Tt]he ', '')
	if #par.actor2 > 0 then par.actorE = B else par.actor2 = B end
	return B
end

-- ===================================================================
-- CombatText - parse a raw combat message and return the formatted
-- version.  Side-effects on `par` are intentional and consumed by
-- parseThis after this returns.
-- ===================================================================
function M.CombatText(msg, chn)
	local A   = ''
	local B   = ''
	local DMG = ''
	local S   = ''
	local T   = ''
	local Ext = ''

	if msg:find('hit') then
		A, B, DMG = msg:match('^(.*) hits? (.*) for (%d*) points? of damage%.$')

		if A and B and DMG then
			local ra = ''
			if msg:find('ranged attack') then
				A = A:gsub('\'s ranged attack', '')
				B = B:gsub('\'s ranged attack', '')
				ra = combatCP.RA
			end

			A = classifyA(A)

			B = classifyB(B)
			
			if allSettings.EnableFCColorMarking[1] then
				msg = A..' '..(#ra > 0 and ra or combatCP.ATK)..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG'
			else
				if #ra > 0 then
					msg = A..' '..ra..B..' '..combatCP.SPLIT..' '..DMG..' DMG'
				else
					msg = A..' '..combatCP.ATK..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG'
				end
			end
			if A == fcw[1].PlayerName then par.DamageDone = true end
			if B == fcw[1].PlayerName then par.DamageGot  = true end

			par.isDamage     = true
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1

			return msg
		end
	end

	if msg:find('score') then
		A, B, DMG = msg:match('^(.*) scores? a critical hit! (.*) takes? (%d*) points? of damage%.$')
		if A and B and DMG then
			local ra = ''
			if msg:find('ranged attack') then
				A = A:gsub('\'s ranged attack', '')
				B = B:gsub('\'s ranged attack', '')
				ra = combatCP.RA
			end
			if A == fcw[1].PlayerName then par.DamageDone = true end
			if B == fcw[1].PlayerName then par.DamageGot  = true end

			A = classifyA(A)

			B = classifyB(B)
			
			if allSettings.EnableFCColorMarking[1] then
				msg = A..' '..(#ra > 0 and ra or combatCP.ATK)..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG '..combatCP.CRIT
			else
				if #ra > 0 then
					msg = A..' '..ra..B..' '..combatCP.SPLIT..' '..DMG..' DMG '..combatCP.CRIT
				else
					msg = A..' '..combatCP.ATK..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG '..combatCP.CRIT
				end
			end
			
			
			par.isDamage     = true
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end
	end

	if msg:find('ranged attack') then
		A, Ext = msg:match('^(.*)(%\'s.*)$')
		if Ext:find('miss') then
			if A == fcw[1].PlayerName then par.DamageGot = true end
			A = classifyA(A)
			msg = A..' '..combatCP.SPLIT..' Miss '..combatCP.RA
			par.isDamage     = true
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		elseif Ext:find('pummeling') then
			B, DMG = Ext:match('^.*pummeling (.*) for (.*) points of damage!$')
			A = classifyA(A)

			B = classifyB(B)
			if allSettings.EnableFCColorMarking[1] then
				msg = A..' '..combatCP.RA..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG '..combatCP.PUM
			else
				msg = A..' '..combatCP.RA..B..' '..combatCP.SPLIT..' '..DMG..' DMG '..combatCP.PUM
			end
			if A == fcw[1].PlayerName then par.DamageDone = true end
			if B == fcw[1].PlayerName then par.DamageGot  = true end
			par.isDamage     = true
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end
	end

	if msg:find('use') then
		A, S, B, DMG = msg:match('^(.*) uses? (.*)%.%s*(.*) takes? (%d*) points? of damage%.$')
		if A and B and S and DMG then
			if A == fcw[1].PlayerName then par.DamageDone = true end
			if B == fcw[1].PlayerName then par.DamageGot  = true end

			A = classifyA(A)

			B = classifyB(B)

			S = wrap_action(S)..combatCP.COL
			par.action1 = S

			msg = A..' '..combatCP.USE..' '..B..' '..combatCP.SPLIT..' '..S..' '..DMG..' DMG'
			par.isDamage     = true
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end

		A, S, Ext = msg:match('^(.*) uses? ([^%.]*)%.%s*(.*)$')
		if A and S
			and not msg:find('damage', #A)
			and not msg:find('miss',   #A)
			and not msg:find('^You must')
			and not msg:find('lacks the')
			and not msg:find('^You are')
			and not msg:find('Unable to')
			and not msg:find('cannot') then

			if Ext and Ext:trimex() ~= '' then
				Ext = Ext:gsub('receives the effect of', combatCP.LEFT)
				Ext = Ext:gsub('gains the effect of',    combatCP.LEFT)
				Ext = Ext:gsub('is afflicted with',      combatCP.LEFT)
				Ext = Ext:gsub(' increases to', ':')
				Ext = Ext:gsub('The total for ', '')
				Ext = Ext:gsub('Treasure Hunter effectiveness against', 'TH on')
				Ext = Ext:gsub('successfully (.)', function(c) return combatCP.RIGHT..' '..c:upper() end)
				Ext = ': '..Ext..' '
			else
				Ext = ''
			end

			A = classifyA(A)

			S = wrap_action(S)
			par.action1 = S

			msg = A..' '..combatCP.RIGHT..' '..S..Ext

			par.CombatCutIdx = utils_FindFirstOfMB(msg, combatCP.RIGHT) + LEN_RIGHT - 1

			return msg
		end
	end

	if msg:find('Skillchain') then
		S, A, DMG = msg:match('^(Skillchain: [^%.]*)%.%s(.*) takes? (%d*) points? of damage%.$')
		if S and A and DMG then
			A = classifyA(A)
			S = wrap_action(S:gsub('Skillchain:', 'SC'))
			par.action1 = S

			msg = S..' '..combatCP.SC..' '..A..' '..combatCP.RIGHT..' '..DMG..' DMG'
			par.isDamage     = true
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.RIGHT) + LEN_RIGHT - 1
			return msg
		end
	end

	if msg:find('take') then
		A, DMG = msg:match('^([^%.]+) takes? (%d*) points? of damage%.$')
		if A and DMG then
			A = classifyA(A)

			msg = combatCP.SUB..A..' '..combatCP.LEFT..' '..DMG..' DMG'
			par.isDamage = true
			if A == fcw[1].PlayerName then par.DamageGot = true end
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.LEFT) + LEN_LEFT - 1
			return msg
		end
	end

	if msg:find('Additional') then
		S = msg:match('^Additional effect: (.*)%..*$')
		if S then
			S = S:gsub('additional ', '')
			S = S:gsub('drained from .*', 'drained')
			S = S:gsub('Treasure Hunter effectiveness against', 'TH on')
			S = S:gsub(' increases to', combatCP.COL)
			S = S:gsub('[Tt]he ', '')
			S = S:gsub('%.', '')
			S = S:gsub('points? of damage', 'DMG')
			S = wrap_action(S)
			par.action1 = S
			msg = combatCP.SUB..'Add.E. '..combatCP.SPLIT..' '..S..' '
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end
	end

	if msg:find('read') then
		A, S = msg:match('^(.*) read[%a]* (.*)%.$')
		if A and S then
			A = classifyA(A)
			S = wrap_action(S)
			par.action1 = S
			msg = A..' '..combatCP.SPLIT..' readies...'..S..' '
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end
	end

	if msg:find('parr') then
		A, B = msg:match('^(.*) parr[%a]* (.-)%p?s? attack.*%.$')
		if A and B then
			if A == fcw[1].PlayerName then par.DamageDone = true end
			if B == fcw[1].PlayerName then par.DamageGot  = true end

			A = classifyA(A)

			B = classifyB(B)

			msg = A..' '..'parry '..combatCP.PARR..' '..B..'\'s attack'
			par.isDamage     = true
			par.CombatCutIdx = utils_FindLastOfMB(msg, 'parry '..combatCP.PARR) - 1
			return msg
		end
	end

	if msg:find(' attack is countered ') then
		B, A, DMG = msg:match('^(.-)\'s%s.-by%s(.-)%..-takes%s(.-)%spoint.*$')
		if A and B and DMG then
			A = classifyA(A)

			B = classifyB(B)

			msg = A..' '..combatCP.CNTR..' '..B..' '..combatCP.SPLIT..' '..DMG..' DMG '
			par.isDamage = true
			if A == fcw[1].PlayerName then par.DamageDone = true end
			if B == fcw[1].PlayerName then par.DamageGot  = true end

			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end
	end

	if msg:find('miss') then
		A, B = msg:match('^(.*) miss[%a]* (.*)%.$')
		if A and B then
			local F = A:find(' use')
			local Ext_local = ''
			if F then Ext_local = A:sub(F, #A); A = A:sub(1, F - 1) end
			if B == fcw[1].PlayerName then par.DamageDone = true end
			if A == fcw[1].PlayerName then par.DamageGot  = true end

			A = classifyA(A)

			B = classifyB(B)

			Ext_local = Ext_local:gsub('^( uses? )([^,]*)(.*)$', function(c1, c2, c3) return c2 end)
			if F then
				Ext_local = wrap_action(Ext_local)..combatCP.COL
				par.action1 = Ext_local
				Ext_local = ' '..Ext_local
			end
			msg = A..' '..combatCP.ATK..' '..B..' '..combatCP.SPLIT..Ext_local..' Miss'
			par.isDamage     = true
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end
	end

	if msg:find('defeat') then
		A, B = msg:match('^(.*) defeats? (.*)%.$')
		if A and B then
			if A == fcw[1].PlayerName then par.DamageDone = true end
			A = classifyA(A)

			B = classifyB(B)

			local defeat = 'defeats'..combatCP.KILL
			msg = A..' '..defeat..' '..B
			par.isDamage     = true
			par.CombatCutIdx = msg:find(defeat, 1, true) - 1
			return msg
		end

		B, A = msg:match('^(.*) was defeated by (.*)%.$')
		if A and B then
			if B == fcw[1].PlayerName then par.DamageGot = true end
			A = classifyA(A)

			B = classifyB(B)

			local defeat = 'defeats'..combatCP.KILL
			msg = A..' '..defeat..' '..B
			par.isDamage     = true
			par.CombatCutIdx = msg:find(defeat, 1, true) - 1
			return msg
		end
	end

	if msg:find('shadows') then
		Ext, A = msg:match('^(%d*) of (.+)\'s shadows.*$')
		if A and Ext then
			Ext = '-'..Ext
			A = classifyA(A)
			if Ext == '0' then
				msg = 'None of '..A..'\'s shadows absorbs damage.'
				par.CombatCutIdx = utils_FindLastOfMB(msg, '\'') + string.len('\'') - 1
				return msg
			end

			msg = A..' '..Ext..' '..icons.UTSU
			if A == fcw[1].PlayerName then par.DamageGot = true end
			par.isDamage     = true
			par.CombatCutIdx = utils_FindLastOfMB(msg, '-') - 1
			return msg
		end
	end

	-- Generic status-effect rewrap.
	local c = 0
	msg, c = msg:gsub('(receives the effect of )([^%.]*)(%.)', function(c1, c2, c3) return combatCP.LEFT..' ['..c2..']' end)
	if c < 1 then
		msg, c = msg:gsub('(gains the effect of )([^%.]*)(%.)', function(c1, c2, c3) return combatCP.LEFT..' ['..c2..']' end)
	end
	if c < 1 then
		msg, c = msg:gsub('(is afflicted with )([^%.]*)(%.)', function(c1, c2, c3) return combatCP.LEFT..' ['..c2..']' end)
	end

	if c > 0 then
		if not msg:find('^[Tt]he') then
			msg = '['..msg:sub(1, msg:find(' ') - 1)..']'..msg:sub(msg:find(' '), #msg)
		else
			msg = msg:gsub('^[Tt]he ', '')
		end
	end

	if msg[1] == ' ' then msg = msg:replace(' ', '{?} ', 1) end
	return msg
end
_G.CombatText = M.CombatText

-- ===================================================================
-- CombatSpellText - parse a raw spell-cast / ability-use message
-- and return the formatted version.  Same side-effect contract as
-- CombatText.  Note: line "par.LastMode:replace('combatspell','combat')"
-- in the use-on-target branch is preserved verbatim from the original;
-- it appears to be a no-op on the immutable string but is kept in
-- case `par.LastMode` is ever a mutable object.
-- ===================================================================
function M.CombatSpellText(msg, chn)
	local A   = ''
	local B   = ''
	local DMG = ''
	local S   = ''
	local T   = ''
	local Ext = ''

	if msg:find('start') then
		A, S = msg:match('^(.*) starts? casting (.*)%.$')
		if A and S then
			local on = S:find(' on ')
			if on ~= nil then
				B = S:sub(on + 4, #S)
				S = S:sub(1, on - 1)
			else
				B = '?'
			end

			A = classifyA(A)
			S = wrap_action(S)
			par.action1 = S
			if B ~= '?' then
				if utils_StringFindTable(B, par.party_names, nil, true) then
					if #par.actor1 > 0 then par.actorP = B else par.actor1 = B end
				else
					B = B:gsub('[Tt]he ', '')
					if #par.actor2 > 0 then par.actorE = B else par.actor2 = B end
				end
				msg = A..' '..combatCP.CAST..' '..B..' '..combatCP.SPLIT..' casting...'..S..' '
			else
				msg = A..' '..combatCP.SPLIT..' casting...'..S..' '
			end

			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end
	end

	if msg:find('cast') then
		A, S, B, DMG = msg:match('^(.*) casts? (.*)%. (.*) takes? (%d*) points? of damage%.$')
		if A and S and B and DMG then
			if A == fcw[1].PlayerName then par.DamageDone = true end
			if B == fcw[1].PlayerName then par.DamageGot  = true end

			A = classifyA(A)

			B = classifyB(B)
			S = wrap_action(S)..combatCP.COL
			par.action1 = S

			msg = A..' '..combatCP.SPELL..' '..B..' '..combatCP.SPLIT..' '..S..' '..DMG..' DMG'
			par.isDamage     = true
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end

		-- Drain spells
		A, S, DMG, T, B = msg:match('^(.*) casts? ([^%.]*)%. (%d*) (.*) drained from (.*)%.$')
		if A and S and B and DMG and T then
			if A == fcw[1].PlayerName then par.DamageDone = true end
			if B == fcw[1].PlayerName then par.DamageGot  = true end

			A = classifyA(A)

			B = classifyB(B)
			S = wrap_action(S)..combatCP.COL
			par.action1 = S

			msg = A..' '..combatCP.SPELL..' '..B..' '..combatCP.SPLIT..' '..S..' '..DMG..' '..T..' drained'
			par.isDamage     = true
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end

		-- Cure / recovery
		A, S, B, DMG, T = msg:match('^(.*) casts? ([^%.]*)%. (.*) recovers? (%d*) ([^%.]*)%.$')
		if A and S and B and DMG and T then
			if A == fcw[1].PlayerName or B == fcw[1].PlayerName then par.DamageDone = true end

			A = classifyA(A)

			B = classifyB(B)
			S = wrap_action(S)..combatCP.COL
			par.action1 = S

			msg = A..' '..combatCP.HEAL..' '..B..' '..combatCP.SPLIT..' '..S..' +'..DMG..' '..T
			par.isDamage     = true
			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end

		-- "X casts Y on Z."
		if msg:find(' casts? ') and msg:find(' on ') then
			A, S, B = msg:match('^(.*) casts? ([^%.]*) on (.*)%.%s?$')
			A = classifyA(A)

			B = classifyB(B)
			S = wrap_action(S)
			par.action1 = S
			msg = A..' '..combatCP.CAST..' '..B..' '..combatCP.SPLIT..' '..S..' '

			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end

		-- Generic "X casts Y." with optional trailing status-effect text.
		A, S, Ext = msg:match('^(.*) casts? ([^%.]*)%.%s*(.*)$')
		if A and S
			and not msg:find('^.- cannot ')
			and not msg:find('^.- damage')
			and not msg:find('^.- evade')
			and not msg:find('^.- is una')
			and not msg:find('^.- does not')
			and not msg:find('^.- lacks the')
			and not msg:find('^Unable to') then

			if Ext and Ext:trimex() ~= '' then
				local c = 0
				Ext, c = Ext:gsub('receives the effect of', combatCP.LEFT)
				if c == 0 then Ext, c = Ext:gsub('gains the effect of', combatCP.LEFT) end
				if c == 0 then Ext, c = Ext:gsub('is afflicted with',   combatCP.LEFT) end
				Ext = Ext:gsub('successfully (.)', function(c) return combatCP.RIGHT..' '..c:upper() end)
				Ext = ': '..Ext
				if c > 0 then
					B = Ext:match('^(.+) '..combatCP.LEFT..'.*$')
					if B then
						if utils_StringFindTable(B, par.party_names, nil, true) then
							if #par.actor1 > 0 then par.actorP = B else par.actor1 = B end
						else
							B = B:gsub('[Tt]he ', '')
							if #par.actor2 > 0 then par.actorE = B else par.actor2 = B end
						end
					end
				end
			else
				Ext = ''
			end

			A = classifyA(A)
			S = wrap_action(S)
			par.action1 = S
			msg = A..' '..combatCP.CAST..' '..S..Ext

			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.CAST) + LEN_CAST - 1

			return msg
		end
	end

	-- "X uses Y on Z."
	if msg:find(' uses? ') and msg:find(' on ') then
		A, S, B = msg:match('^(.*) uses? ([^%.]*) on (.*)%.%s?$')
		if A and B and S then
			A = classifyA(A)

			B = classifyB(B)
			S = wrap_action(S)
			par.action1 = S
			msg = A..' '..combatCP.RIGHT..' '..B..' '..combatCP.SPLIT..' '..S..' '

			par.CombatCutIdx = utils_FindLastOfMB(msg, combatCP.SPLIT) + LEN_SPLIT - 1
			return msg
		end
	end

	-- Generic ability use with optional status text.
	if msg:find('use') then
		A, S, Ext = msg:match('^(.*) uses? ([^%.]*)%.%s*(.*)$')

		if A and S
			and not msg:find('damage')
			and not msg:find('^You are')
			and not msg:find('cannot') then

			if Ext and Ext:trimex() ~= '' then
				if Ext:find(' on ') then
					B = Ext:match('^.-on (.-)%.%s?$')
				end
				if not B or B == '' then
					Ext = Ext:gsub('receives the effect of', combatCP.LEFT)
					Ext = Ext:gsub('gains the effect of',    combatCP.LEFT)
					Ext = Ext:gsub('is afflicted with',      combatCP.LEFT)
					Ext = Ext:gsub('successfully (.)', function(c) return combatCP.RIGHT..' '..c:upper() end)
					Ext = ': '..Ext..' '
				else
					Ext = Ext:gsub(' on '..B, '')
				end
			else
				Ext = ''
			end

			A = classifyA(A)

			if B then
				if utils_StringFindTable(B, par.party_names, nil, true) then
					if #par.actor1 > 0 then par.actorP = B else par.actor1 = B end
				else
					B = B:gsub('[Tt]he ', '')
					if #par.actor2 > 0 then par.actorE = B else par.actor2 = B end
				end
			end

			S = wrap_action(S)

			par.action1 = S
			msg = A..' '..combatCP.RIGHT..((B and #B > 0) and ' '..B..' '..combatCP.SPLIT..' '..S..': '..Ext or ' '..S..Ext)

			par.CombatCutIdx = utils_FindFirstOfMB(msg, combatCP.RIGHT) + LEN_RIGHT - 1
			par.LastMode:replace('combatspell', 'combat')
			return msg
		end
	end

	-- Generic status-effect rewrap.
	local c = 0
	msg, c = msg:gsub('(receives the effect of )([^%.]*)(%.)', function(c1, c2, c3) return combatCP.LEFT..' ['..c2..']' end)
	if c < 1 then
		msg, c = msg:gsub('(gains the effect of )([^%.]*)(%.)', function(c1, c2, c3) return combatCP.LEFT..' ['..c2..']' end)
	end
	if c < 1 then
		msg, c = msg:gsub('(is afflicted with )([^%.]*)(%.)', function(c1, c2, c3) return combatCP.LEFT..' ['..c2..']' end)
	end

	if c > 0 then
		if not msg:find('^[Tt]he') then
			msg = '['..msg:sub(1, msg:find(' ') - 1)..']'..msg:sub(msg:find(' '), #msg)
		else
			msg = msg:gsub('^[Tt]he ', '')
		end
	end

	return msg
end
_G.CombatSpellText = M.CombatSpellText

return M
