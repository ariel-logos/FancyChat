require('common');
local imgui = require('imgui');
local imguiWrap = require('imguiWrap')

help = {
		opened = T{false},
		overviewSize = 1,
		searchBuff = T{''},
		longestword = '',
		collapseAll = false,
		foundParent = T{},
		foundAnything = false,
		};

--help.overviewText = 'This is a built-in manul for this addon.\nHere you can find most of the info you need to take advantage of all the addon features.\nThe manual is split in different sections to help you find what you are looking for.';
help.overviewText = {
						{
							'Intro',
							'This is a built-in manual for this addon.',
							'Here you can find most of the info you need to take advantage of all the addon features.',
							'The manual is split in different sections to help you find what you are looking for.'
						}
					};
help.loremText=		{
						{
							'Disclaimer',
							'This project is the result of a hobby, a hobby in which I ended up throwing dozens of hundred of hours. While it was my goal to get close as perfection as I could, in the end, I had to decide a development state that was good enough. If you are reading this, this is such state.',
							'While I\'ll do my best to maintain this addon to fix bugs, here\'s a list of the things you should not expect:',
							'- Compatibility with other addons.\nWhat works works.\nI have no intention on reviewing over and over my text handling function to make every addon\'s type of message compatible.',
							'- Compatibility with handheld devices and unusual screen sizes and ratios.\nI tried my best to take into account these factors and adjusted my code to \'predict\' its behaviour on screen\\window sizes too different from the usual 16:9 ratio and 1080p/1440p/2160p sizes. Sadly, I don\'t have a bank account big enough to invest in all possible device for testing nor the time to invest into making this add-on omni-compatible. Sorry if it doesn\'t work on your device. :(',
							'- All the features marked as \'beta\' or \'experimental\' have no guarantees of ever being fixed, completed and/or improved. This is not due to my lack of good will but because the reason why they are marked with such labels is that their development ran into some technical limitations.',
						}
					};

help.chatwindowOverview = {
								'Overview',
								'On first load the FancyChat window appears on the top-left of the game window with its default configuration.',
								'The window displays 8 lines of chat text by default, a tab bar to switch between message categories, and a row of small buttons for the GuideMe panel, the Notepad, the Settings cog, and the Compact-Tabs toggle.',
								'Below the chat plate is the live message feed itself, which scrolls upward as new messages arrive.',
								'A second, independently-configured chat window can be enabled in the Settings — useful for separating combat lines from social lines on screen.'
						  }
help.chatwindowPosition = {
								'Positioning',
								'Drag the FancyChat window with the left mouse button to reposition it. Pull from the dark chat plate (not the tab bar or the side icons) to start the drag.',
								'If the window doesn\'t react when you try to drag, it\'s most likely locked. Settings → Chat Window → uncheck "Lock Windows Positions".',
								'When "Prevent obstructing FFXI UI" is enabled, FancyChat automatically slides itself out of the way when an FFXI menu (inventory, magic, mog house, etc.) opens, then returns to its anchor when the menu closes.',
								'You can fine-tune each chat window\'s X/Y offset relative to its anchor in Settings → Chat Window → Position Offsets.'
						  }
help.chatwindowHistory = {
								'Scrolling Chat History',
								'Use the mouse wheel while hovering the chat window to scroll up through past messages. Each tick scrolls one line at a time.',
								'For larger jumps, hold Shift and tap [←] or [→] to scroll multiple lines at once. Shift-scrolling is enabled by Settings → Extra → "Fast scroll chat history".',
								'Right-click anywhere in the chat window to instantly jump back to the bottom (live messages).',
								'While in scroll-back mode, new messages are still buffered — they appear when you return to the bottom.'
						  }
help.chatwindowAutoHide = {
								'Auto-Hide',
								'Auto-Hide makes FancyChat fade out after a configurable period of inactivity (no incoming messages, no typing, no mouse hover). When something happens — a new message arrives, you start typing, or you mouse over the chat — it fades back in immediately.',
								'Enable it from Settings → Chat Window → "Enable Auto-Hide window". Adjust the delay with the slider that appears next to the toggle.',
								'While the chat is faded out it still receives messages in the background; they just aren\'t drawn until the next activity wakes the window up.'
						  }
help.chatwindowBigMode = {
								'BigMode',
								'BigMode is a full-screen, large-text overlay of your chat history — useful for reviewing long announcements, cutscene dialogue, or just reading at a comfortable text size without straining your eyes.',
								'Toggle BigMode with the keyboard shortcut configured in Settings → Shortcuts (default Page Down) or with the command "/fancychat bigmode".',
								'While BigMode is active the regular chat window is hidden. Press the same shortcut again to dismiss it and return to the normal layout.'
						  }
help.chatwindowPreview = {
								'Item / Ability / Spell Preview',
								'Hovering an item, ability, or spell name in chat (an "auto-translate" phrase wrapped in <…>) brings up a tooltip showing the corresponding entry from the game\'s resource files: item description and stats, ability cost / type, or spell properties.',
								'Up to four preview tooltips can stack horizontally above the chat window when a single line contains multiple recognised names.',
								'Disable previews from Settings → Extra → "Preview Items/Abilities/Spells on mouse hover" if you find them distracting during combat.'
						  }
help.chatwindowCopying = {
								'Copying & Saving Chat Lines',
								'Click any chat line once to copy its full text to the system clipboard. The line briefly flashes to confirm the action; paste anywhere with Ctrl+V (Discord, browser, in-game /tell, etc.).',
								'Hold Shift and click a chat line to save it directly to the FancyChat Notepad instead of the clipboard. The Notepad keeps up to 10 saved lines for quick reference.',
								'When a line contains an in-game URL marker (link), clicking it opens the URL in your default browser instead of copying.'
						  }
help.chatwindowCompactCombat = {
								'Compact Combat Log',
								'When Compact Combat Log is enabled (Settings → Extra), FancyChat reformats combat messages into a tighter, icon-based layout. The standard "Eleanor hits Treant Sapling for 23 points of damage." becomes something like "Eleanor 🗡 Treant Sapling → 23 DMG".',
								'Each attack type uses a distinct icon (sword for melee, archer for ranged, sparkle for magic, star-burst for criticals, etc.). Actor names are highlighted in different colours depending on whether the actor is you, a party member, an alliance member, or an unrelated player.',
								'Disable this if another combat-log addon (e.g. simplelog) is already formatting combat lines, otherwise the two formatters will conflict.',
								'The "Colorblind mode" option in Extra swaps the damage-done / damage-taken colours to a red-green-friendly palette.'
						  }
help.chatwindowTimestamps = {
								'Timestamps',
								'FancyChat can prepend an [HH:MM:SS] timestamp to every line, or insert a single horizontal "timestamp banner" at a fixed interval (e.g. every 10 minutes). Both are configured in Settings → Extra.',
								'The timestamp can use a long [HH:MM:SS] format or a short [HH:MM] format.',
								'Use the "/fancychat ts" command to print a one-shot timestamp banner manually at any moment.',
								'When FC color marking is disabled, the per-line timestamp is always rendered in white so it stays readable regardless of the rest of the line\'s colour.'
						  }
help.chatwindowTabs = 	{
								'Chat Tabs',
								'The chat window is divided into tabs by message category: All, Combat, Linkshell, Party, Tell, Shout, and Custom. Click a tab heading to view only that category, or use the keyboard shortcut to cycle between them (see the Shortcuts section).',
								'The All tab shows everything by default. If you prefer to keep combat logs out of it, enable "Hide combat and custom logs from \'All\' tab" in the Extra settings — All becomes "AllAlt" and combat lines are routed only to the Combat tab.',
								'The Custom tab is configured in the Chat Window settings: pick which message types (NPC, Tell, Party, Linkshell, Shout) should funnel into it. Useful, for example, to keep tells AND linkshell messages visible in a single place.',
								'Tab buttons can be displayed in expanded form (the default tab bar) or compact form (a single button that cycles through tabs on click). Toggle compact mode with the corresponding button on the chat window or the /fancychat compact command.',
						  }
help.chatwindowSections = {
	help.chatwindowOverview,
	help.chatwindowPosition,
	help.chatwindowHistory,
	help.chatwindowTabs,
	help.chatwindowAutoHide,
	help.chatwindowBigMode,
	help.chatwindowPreview,
	help.chatwindowCopying,
	help.chatwindowCompactCombat,
	help.chatwindowTimestamps,
};

-- ----------------------------------------------------------------
-- Companion Panels: GuideMe (wiki viewer) and Notepad.
-- ----------------------------------------------------------------
help.panelGuideMe = {
	'GuideMe',
	'GuideMe is a built-in wiki-page viewer that lives next to your chat. Useful for keeping a quest walkthrough, item guide, or BCNM reference visible while you play, without alt-tabbing out of the game.',
	'Open it via the corresponding button on the chat window (top-right corner, the question-mark / book icon) or with the command "/fancychat guideme".',
	'Paste a URL from ffxiclopedia.fandom.com or bg-wiki.com into the URL field at the top of the panel and press the Load button. GuideMe fetches the page, extracts its Walkthrough section, and displays it as plain text.',
	'If the fetch fails because of a Cloudflare challenge (some VPN providers trigger this), the panel will say so and recommend trying the alternative wiki source.',
	'GuideMe can be docked above the chat (the default) or floated as a free movable window — toggle with the Dock / Undock button at the top of the panel. When the second chat window is enabled, you can also dock GuideMe there instead via Settings → Extra → "Dock GuideMe/Notes on the second chat window".',
	'GuideMe is marked experimental — it may not perfectly handle every wiki page layout.',
};

help.panelNotepad = {
	'Notepad',
	'The Notepad is a tiny per-character pinboard that holds up to 10 lines of free-form text. Use it for quest reminders, party loot rules, frequent macros, item codes, or anything you want at hand without alt-tabbing.',
	'Open it via the Notepad icon button on the chat window or with the command "/fancychat notes".',
	'Add a note in three ways:\n- Type into the input field at the top and click "Add Note".\n- Shift-click any line in the chat to save it directly to the Notepad.\n- The list fills bottom-up; the oldest entry is dropped when a new one would overflow the 10-slot limit.',
	'Each saved note has two buttons next to it: "C" copies the note to the clipboard, "X" deletes it. Notes persist across sessions in your settings file, so they\'ll still be there next time you log in.',
	'Like GuideMe, the Notepad can be docked above the chat or undocked as a movable window. The dock target follows the same Settings → Extra → "Dock GuideMe/Notes on the second chat window" option.',
};

help.panelSections = { help.panelGuideMe, help.panelNotepad };

-- ----------------------------------------------------------------
-- Commands & Macros — slash commands plus a quick-reference layout
-- of in-game macros that map to FancyChat actions.
-- ----------------------------------------------------------------
help.commandsList = {
	'Slash Commands',
	'All commands accept either /fancychat or the shorter alias /fchat as the prefix.',
	'/fancychat settings — open or close the Settings window.',
	'/fancychat manual — open or close this manual.',
	'/fancychat guideme — open or close the GuideMe panel.',
	'/fancychat notes — open or close the Notepad.',
	'/fancychat compact — toggle the tab bar between expanded and compact mode.',
	'/fancychat tod — toggle the Precise Time-Of-Death option for combat-kill messages.',
	'/fancychat ts — print a one-shot timestamp banner to the current chat.',
	'/fancychat savelogs — save every tab\'s current chat history to "addons/fancychat/logs/<character>".',
	'/fancychat bigmode — toggle the full-screen BigMode overlay.',
	'/fancychat debug — open the developer diagnostic window. Mostly useful when reporting a bug.',
};

help.commandsMacros = {
	'Using Commands in Macros',
	'Any of the slash commands above can be bound to an FFXI macro for quick access. Open the in-game macro editor and use a line like "/fancychat compact" or "/fchat bigmode" — the addon picks them up exactly like a typed command.',
	'Common useful bindings:\n- One-button BigMode toggle for browsing chat history during a long event.\n- A macro that runs "/fancychat savelogs" before a fight in case you need a chat-log screenshot afterward.\n- A "/fchat ts" macro to mark a specific moment with a visible timestamp banner (e.g. when a boss popped).',
};

help.commandsSections = { help.commandsList, help.commandsMacros };

-- ----------------------------------------------------------------
-- Tips & troubleshooting — handy when something looks wrong.
-- ----------------------------------------------------------------
help.tipsRestoreLegacy = {
	'Capturing a screenshot for support',
	'For bug reports or support tickets where the legacy FFXI chat layout is needed, click "Restore Legacy Chat Logs" in Settings → Tools (or the equivalent button under the Tools icon). FancyChat re-injects every message it has buffered back into the FFXI legacy chat so a Print Screen / clipboard capture shows the original-format chat.',
	'You can also enable Settings → Extra → "Auto-restore logs when opening Legacy Chat" to do this automatically every time you open the legacy chat window.',
};

help.tipsCleanCombat = {
	'Cleaning up combat-log spam',
	'If a particular type of combat message is cluttering your chat (effect-wears-off, no-effect, etc.):\n1. Settings → Extra → enable "Hide alliance combat log" and "Hide non-party combat log" to focus the combat tab on you and your party.\n2. For more surgical filtering, use Settings → CL Filters: edit "custom_combat_filters.txt" with one filter word per line, then click "Reload Custom Filters" and tick "Enable Combat Log chat filters". Each filter can be scoped to apply to all messages, all-but-you, or all-but-party.',
	'Note that filtering matches against the original FFXI message text — words modified by other addons (e.g. simplelog\'s reformatting) won\'t match.',
};

help.tipsHidden = {
	'Chat window has disappeared',
	'If the chat window is gone after loading the addon:\n1. Settings → Chat Window → uncheck "Lock Windows Positions", then drag the window into view.\n2. If Auto-Hide is on, the window may have faded out. Move the mouse over the screen area where it should be, or briefly disable Auto-Hide to confirm.\n3. Use "/fancychat settings" to open the Settings panel even when the chat plate isn\'t visible — the Position Offsets section can move it back to the centre of the screen.\n4. As a last resort, "/addon unload fancychat" then "/addon load fancychat" to fully reset the runtime state.',
};

help.tipsSecondChat = {
	'Using the second chat window',
	'The second chat window is a fully-independent chat plate that can show a different tab from the primary one. Enable it in Settings → Chat Window → "Enable second chat window".',
	'Once enabled, the second window appears and can be dragged, resized via the same Font Size / Chat Width controls (each chat plate has its own settings), and assigned its own active tab via the second tab bar.',
	'Common uses: keep "All" on the primary plate and "Combat" on the secondary, or split tells onto a smaller dedicated plate so you don\'t miss them in busy events.',
	'GuideMe and Notepad can be docked to the second window instead of the primary — Settings → Extra → "Dock GuideMe/Notes on the second chat window".',
};

help.tipsSections = { help.tipsRestoreLegacy, help.tipsCleanCombat, help.tipsHidden, help.tipsSecondChat };

help.settingsChatWindow = {
							'Chat Window',
							'Adjust the visual appearance and behaviour of the chat window itself.',
							'Font Size, Chat Width, Plate BG Alpha and Number of chat lines control the basic dimensions and the dark-background opacity of the chat plate. The "Restart & apply" button applies these — most of these settings require a one-shot restart of the addon to take effect.',
							'Enable second chat window adds a separate, independently configurable chat plate that you can place elsewhere on screen — useful for separating Combat into its own panel.',
							'Custom Tab Modes selects which message categories the Custom tab will collect (NPC / Tell / Party / Linkshell / Shout).',
							'Position Offsets fine-tunes the X/Y position of each chat plate relative to its anchor; useful when the default position overlaps with other UI elements. Save and Reset buttons are provided.',
							'Lock Windows Positions disables drag-to-move so an accidental click won\'t shift your chat.',
							'Compact tabs in the bottom-left corner relocates the tab buttons to a small corner cluster.',
							'Gamepad Chat Navigation enables a controller-friendly way to switch tabs and scroll history.',
							'Enable Auto-Hide window fades the chat out after a configurable idle period and restores it on activity (typing, receiving a message, hovering the window).',
							'Use half window length for docked UI elements makes the GuideMe / Notepad pop-outs use half the chat width instead of the full width.',
							'Prevent obstructing FFXI UI moves the chat window automatically when an FFXI menu (inventory, magic, mog house, etc.) would be covered by it. The companion option for the Auto-Translate menu does the same for that specific UI element.',
						  };
help.settingsFontColors = {
							'Font Colors',
							'Customise the colour each chat message category uses for its main text and any auxiliary tags.',
							'Each editable colour is shown as a small swatch labeled with the category it controls. Click the swatch to bring up the colour picker; the arrow button next to it applies the picker\'s current colour to the swatch. Hover the (i) icons next to each label for more information about the corresponding category.',
							'Reset Colors restores the entire palette to the addon defaults. Export Colors writes the current palette to a file in the addon folder so it can be backed up or shared, and Import Colors reads such a file back in.',
						  };
help.settingsShortcuts = {
							'Shortcuts',
							'Configure keyboard combos for the four most-used actions:',
							'- Hide chat: temporarily hides the chat window.\n- BigMode: opens a full-screen overlay that shows the chat history at large size for easy reading.\n- Tab cycle (primary chat): cycles through tabs without using the mouse.\n- Tab2 cycle (second chat): same, but for the second chat window if enabled.',
							'Each shortcut has an enable checkbox, a main key picker, and an optional modifier picker (Shift / Ctrl / Alt). The "Reset default keys" button restores the original assignments.',
							'A list of slash commands is also provided in this tab for users who prefer to bind macros instead of keyboard shortcuts (settings, guideme, notes, compact, manual, tod, ts, savelogs).',
						  };
help.settingsExtra = {
						'Extra',
						'Behaviour toggles that don\'t fit into the other tabs.',
						'Block legacy chat messages: prevents the original FFXI chat window from rendering messages that FancyChat already displays. The "All" option blocks every category and is required for the addon to fully replace the legacy chat. "Combat (recommended)" blocks only combat messages — a safer fallback if you want the legacy chat to remain available.',
						'Chat message filtering: the hide-combat-from-All toggle sends combat and custom logs only to their specific tabs (the All tab is renamed to "AllAlt"). The hide-alliance / hide-non-party / show-only-you-and-pet toggles progressively narrow down the combat log to focus on relevant lines.',
						'Other settings:',
						'- Compact Combat Log: reformats combat messages with FancyChat-specific iconography (sword, ranged-attack, magic, ability, etc.) and highlights actor names. Disable this if another combat-log addon (e.g. simplelog) is already formatting combat lines.',
						'- Timestamp / Timestamp as a line: prepend a [HH:MM:SS] prefix to every line, or insert a single horizontal timestamp banner at a configurable interval. Format and frequency are configurable.',
						'- Warning messages on R0s: prints a chat warning when an R0 connection error is detected.',
						'- Precise TOD Timestamps: appends a precise time-of-death timestamp to enemy-killed lines.',
						'- Incoming /tell notifications: plays a sound when a /tell arrives. The notification sound is selectable, with optional volume boost.',
						'- Chat word alert: plays a sound whenever any of a configurable list of words appears in chat. Per-channel toggles let you choose which channels trigger the alert.',
						'- Preview Items/Abilities/Spells on mouse hover: shows a tooltip when you hover over an item, ability, or spell name in chat.',
						'- Auto-restore logs when opening Legacy Chat: re-injects FancyChat\'s buffered messages into the legacy chat when you open it (useful for taking screenshots).',
						'- Colorblind mode for damage done/taken text: changes the damage-done / damage-taken text colours for users with red-green colour blindness.',
						'- Fast scroll chat history: lets you Shift+Left/Right scroll the chat history multiple lines at a time while hovering the chat window.',
						'- Dock GuideMe/Notes on the second chat window: when the second chat window is enabled, dock the GuideMe and Notepad panels there instead of the main window.',
						'- Enable FC color marking: when ON, FancyChat applies its own per-segment colour marking (actor names, ability names, auto-translate brackets, etc.). When OFF, the addon falls back to whatever colour information the original message carries — including FFXI\'s native palette escapes from other addons such as simplelog.',
					 };
help.settingsCLFilters = {
							'CL Filters',
							'Define a list of custom words that, when found in a combat-log message, will hide that message from the chat. Useful for cleaning up status-effect spam (e.g. "wears off", "no effect").',
							'Edit Custom Filters opens custom_combat_filters.txt in your default text editor. Each line is one filter; comments and per-line scope flags are documented inside the file. Word matching is case-insensitive and the filter must match a word in the original game combat message — not in addon-modified text.',
							'Reload Custom Filters re-reads the file without restarting the addon, so you can tweak filters live.',
							'Enable Combat Log chat filters is the master switch — when off, the file is ignored and no filtering happens. When on, the table at the bottom of the tab shows every active filter and the scope it applies to (All / All but you / All but party).',
							'Note: very long filter lists can affect performance because every combat line is scanned against every filter.',
						 };
help.settingsTools = {
						'Tools',
						'A small set of one-click utilities:',
						'- Save Chat Logs: writes the current contents of every chat tab (All, Combat, Linkshell, Party, Tell, Shout, Custom) to a timestamped folder under "addons/fancychat/logs/<your character>". Useful for keeping records of an event or for support tickets.',
						'- Open Logs Folder: opens the logs folder above in your file manager.',
						'- Open Manual: opens this manual.',
						'- Restore Legacy Chat Logs: re-injects FancyChat\'s buffered chat history back into the FFXI legacy chat window. Use this to take a chat-log screenshot for support tickets where the legacy chat layout is required.',
					 };
help.settingsSections = {help.settingsChatWindow, help.settingsFontColors, help.settingsShortcuts, help.settingsExtra, help.settingsCLFilters, help.settingsTools};


help.GetLongestWord = function(text)
    local max_word = ""
    for word in text:gmatch("%S+") do
        if #word > #max_word then
            max_word = word
        end
    end
    return max_word
end


help.SetText = function(text)
	imgui.PushTextWrapPos(imgui.GetWindowWidth()-10);
	for i = 2, #text do
		imgui.TextWrapped(text[i]);
		if i < #text then imgui.Dummy({0,5}); end
	end
	imgui.PopTextWrapPos();
end

help.AddSection = function(section, indent, parentsearch, parent, parentIdx)

	for s = 1, #section do
		local search = false;
		for f = 1, #section[s] do	
			if help.searchBuff[1] == '' then search = true;
			elseif not search then search = string.find(string.lower(section[s][f]), string.lower(help.searchBuff[1]))end
		end
		if search and help.searchBuff[1] ~= '' then help.foundAnything = true; end
		if search and help.searchBuff[1] ~= '' and parent~= nil and (parentIdx == 0 or parent~= help.foundParent[parentIdx]) and not (function() for i = 1, #help.foundParent do if help.foundParent[i] == section[s][1] then return true end end return false end)() then  table.insert(help.foundParent, parent); elseif help.searchBuff[1] ~= '' then imgui.SetNextItemOpen(false) end
		if search and help.searchBuff[1] ~= '' and not (function() for i = 1, #help.foundParent do if help.foundParent[i] == section[s][1] then return true end end return false end)() then   table.insert(help.foundParent, section[s][1])end
		if (search or parentsearch) and help.searchBuff[1] ~= '' then  imgui.SetNextItemOpen(true) elseif help.collapseAll then imgui.SetNextItemOpen(false) end
		if ( imgui.CollapsingHeader(section[s][1])) then --..'__'
			if (search or parentsearch) then  --ImGuiTreeNodeFlags_DefaultOpen ImGuiTreeNodeFlags_Selected --ImGuiTreeNodeFlags_OpenOnArrow
				local textlines = 0;
				if #help.GetLongestWord(section[s][1]) > #help.longestword then help.longestword = help.GetLongestWord(section[s][1]) end
				for i = 2, #section[s] do			
					if #help.GetLongestWord(section[s][i]) > #help.longestword then help.longestword = help.GetLongestWord(section[s][i]) end
					textlines = textlines + math.floor(imgui.CalcTextSize(section[s][i]..(i==#section[s] and (indent and help.longestword..'___' or help.longestword..'_') or ''), nil, false)/imgui.GetWindowWidth())+2;
				end
				imguiWrap.BeginChild(section[s][1].."Frame", { 0, (textlines)*(imgui.GetFont().FontSize or imgui.GetFont().LegacySize)+((#section[s]-1)*5)+25 }, true );
				help.SetText(section[s]);
				imgui.EndChild();
			end
		end
	end
end

help.AddSubSections = function(name, sections)
	local search = false;
	local foundIdx = 0;
	if help.searchBuff[1] == '' then search = true; 
	elseif not search then search = string.find(string.lower(name), string.lower(help.searchBuff[1]))end
	if search and help.searchBuff[1] ~= '' then help.foundAnything = true; end
	if search and help.searchBuff[1] ~= '' and not (function() for i = 1, #help.foundParent do if help.foundParent[i] == name then return true end end return false end)() then  table.insert(help.foundParent, name); end
	if ( search or (#help.foundParent == 0 or (function() for i = 1, #help.foundParent do if help.foundParent[i] == name then foundIdx = i return true end end return false end)())) and help.searchBuff[1] ~= '' or help.foundAnything then imgui.SetNextItemOpen(true) elseif help.searchBuff[1] ~= '' or #help.foundParent>0 or help.collapseAll then imgui.SetNextItemOpen(false) end
	if imgui.CollapsingHeader(name) then 
		imgui.Indent();
		help.AddSection(sections,true, search, name, foundIdx);
		imgui.Unindent();
	end
	
end


help.ShowManual = function(playerName)
	
	local dsize = imgui.GetIO().DisplaySize;
	imgui.SetNextWindowSize({ dsize.x/5, dsize.y/3 }, ImGuiCond_Once);
	imgui.SetNextWindowSizeConstraints({ dsize.x/5, dsize.y/3 }, { dsize.x, dsize.y });
	if( imgui.Begin('FancyChat Manual##_'..playerName, help.opened, bit.bor(ImGuiWindowFlags_NoCollapse,ImGuiWindowFlags_NoNav))) then
		
		imguiWrap.BeginChild("TitleFrame", { 0, 48 }, true);
		imgui.Dummy({0,1})
		imgui.Dummy({(imgui.GetWindowWidth()/2)-(imgui.CalcItemWidth()/10+75),0}); imgui.SameLine();
		help.SetText({'','Welcome to FancyChat!'});
		imgui.Dummy({0,5})
		imgui.EndChild();
		imguiWrap.BeginChild("SearchFrame", { 0, 42 }, true);
		imgui.PushItemWidth(imgui.GetWindowWidth()/3)
		imgui.SetCursorPosY(imgui.GetCursorPosY()+4);
		imgui.Text('Search');imgui.SameLine();
		imgui.SetCursorPosY(imgui.GetCursorPosY()-3);
		local prevSearchBuff =  help.searchBuff[1];
		imgui.InputText(' ##SearchBox', help.searchBuff, 20, ImGuiInputTextFlags_EnterReturnsTrue);
		if prevSearchBuff ~= help.searchBuff[1] then help.foundParent = {}; help.foundAnything = false; end
		if help.searchBuff[1] == '' then help.foundAnything = false; end
		imgui.PopItemWidth()
		imgui.SameLine();
		if imguiWrap.isNewVer then
			imgui.SetCursorPosX(imgui.GetCursorPosX()-20);
			imgui.SetCursorPosY(imgui.GetCursorPosY()-3);
		else
			imgui.SetCursorPosX(imgui.GetCursorPosX()-20);
		end
		if imgui.Button('x', {25,0}) then
			help.searchBuff[1] = '';
			help.foundParent = {};
			help.foundAnything = false;
		end
		imgui.SameLine();
		imgui.Dummy({5,0});
		imgui.SameLine();
		if imguiWrap.isNewVer then
			imgui.SetCursorPosY(imgui.GetCursorPosY()-3);
		end
		if imgui.ArrowButton('##Collapse all', ImGuiDir_Up) then
			if help.searchBuff[1] == '' then help.collapseAll = true; end
		end
		imgui.SameLine();
		imgui.SetCursorPosX(imgui.GetCursorPosX()-5);
		if imguiWrap.isNewVer then
			imgui.SetCursorPosY(imgui.GetCursorPosY()-3);
		end
		imgui.Text('Fold All');
		imgui.SameLine();
		imgui.EndChild();
		imguiWrap.BeginChild("MainFrame", { 0, imgui.GetWindowHeight()-142 }, true);
		help.AddSection(help.overviewText,false, false, nil, 0);
		help.AddSection(help.loremText,false, false, nil, 0);
		help.AddSubSections('The FancyChat Window', help.chatwindowSections);
		help.AddSubSections('Companion Panels',     help.panelSections);
		help.AddSubSections('Settings',             help.settingsSections);
		help.AddSubSections('Commands & Macros',    help.commandsSections);
		help.AddSubSections('Tips & Troubleshooting', help.tipsSections);
		imgui.Dummy({0,10})
        help.collapseAll = false;
		imgui.EndChild();
	end
	imgui.End();
end

return help;