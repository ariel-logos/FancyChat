addon.name      = 'fancychat';
addon.author    = 'Arielfy';
--addon.version   = '0.9';
addon.desc      = 'Fancy Chat!';
addon.link      = '';

local ver = '0.9.260228'
addon.version = ver

--[[
	FancyChat entry point.

	All addon logic lives under lib/.  This file does three things:

	  1. Sets the addon descriptor (name/author/desc/version) so
	     Ashita can list and load the addon.
	  2. require()s every lib/* module.  Module load order matters
	     only insofar as the helpers each module exposes via
	     `_G.<Name>` (DrawInfo, ResetLines, parseThis, etc.) need to
	     be installed before any per-frame callback fires.  That's
	     guaranteed automatically: `require()` runs synchronously
	     and the callbacks don't fire until the next D3D frame,
	     after this file finishes loading.
	  3. Calls each module's `register()` to install the Ashita
	     event handlers (load/unload, text_in, key_state, mouse,
	     d3d_present, d3d_endscene, /fancychat command, ...).

	Shared mutable state (chat buffer, font objects, window
	geometry, parser cursor, etc.) lives in lib/state.lua.  Every
	module aliases the same tables via `local x = state.x`, so a
	mutation in one module is visible in every other.

	The two backup files next to this one — fancychat.lua.bak_*
	and fancychat.lua.preMod_* — are pre-modularisation snapshots
	kept for reference; they're not loaded by Ashita.
]]

require('common')

require('lib.defaults')
require('lib.state')
require('lib.ui_helpers')
require('lib.buffer')
require('lib.combat')
local parser    = require('lib.parser')
require('lib.ui_panels')
require('lib.ui_settings')
local lifecycle = require('lib.lifecycle')
local input     = require('lib.input')
require('lib.bigmode')
require('lib.debug_window')
local render    = require('lib.render')

lifecycle.register()
input.register()
parser.register()
render.register()
require('lib.commands').register()
