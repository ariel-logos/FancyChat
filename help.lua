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
								'FancyChat is a replacement / overlay for FFXI\'s legacy chat window. It taps into the same incoming-message stream the legacy chat uses, formats each line according to its per-channel rules, and renders the result on its own ImGui-driven plate using the gdifont texture pipeline. The legacy chat keeps running underneath unless you tell it not to (Settings → Extra → "Block legacy chat messages") — useful if you want to compare the two side-by-side or fall back to the original layout.',
								'On first load the FancyChat window appears on the top-left of the game window with its default configuration.',
								'The window displays 8 lines of chat text by default, a tab bar to switch between message categories, and a row of small buttons for the GuideMe panel, the Notepad, the Settings cog, and the Compact-Tabs toggle.',
								'Below the chat plate is the live message feed itself, which scrolls upward as new messages arrive.',
								'A second, independently-configured chat window can be enabled in the Settings — useful for separating combat lines from social lines on screen.',
								'Most of the addon\'s state — settings, color palette, custom filters, notepad entries — is keyed by your character name. Switching characters loads a separate set of preferences automatically. See Tips → "Where FancyChat stores its data" for a full map of the on-disk layout.',
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
								'When the "Fast scroll chat history" option is enabled (Settings → Extra), holding Shift while you continue rolling the mouse wheel jumps the view by several lines per tick instead of one.',
								'Right-click while the chat plate is on screen to instantly jump back to the bottom (most recent line).',
								'While in scroll-back mode, new messages are still buffered — they\'ll be there when you return to the bottom.'
						  }
help.chatwindowAutoHide = {
								'Auto-Hide',
								'Auto-Hide makes FancyChat fade out after a configurable period of inactivity. The faded-out window still receives messages — it just isn\'t drawn until activity wakes it up.',
								'Enable it from Settings → Chat Window → "Enable Auto-Hide window". The slider next to the toggle sets the idle delay (5–60 seconds before the fade starts).',
								'The fade resets to fully visible whenever any of these happens: a new message arrives on the currently-selected tab, you scroll the chat with the mouse wheel, you press one of FancyChat\'s configured keyboard shortcuts, you open the chat input box (start typing /), an NPC dialog event begins, or you hover over the GuideMe / Notepad panels.',
								'Note that simply moving the mouse over the chat plate does NOT wake it up — only the actions listed above do. Scrolling is the simplest "wake" gesture if you want to peek without typing or interacting.'
						  }
help.chatwindowBigMode = {
								'BigMode',
								'BigMode is a full-screen, large-text overlay of your chat history — useful for reviewing long announcements, cutscene dialogue, or just reading at a comfortable text size without straining your eyes.',
								'Toggle BigMode with the command "/fancychat bigmode", or by assigning a keyboard shortcut in Settings → Shortcuts (the BigMode shortcut is OFF by default — tick its enable checkbox and pick a key combo such as Shift+G).',
								'While BigMode is active the regular chat window is hidden. Toggle BigMode again (same shortcut or command) to dismiss it and return to the normal layout.'
						  }
help.chatwindowPreview = {
								'Item / Ability / Spell Preview',
								'Hovering an item, ability, or spell name in chat (an "auto-translate" phrase wrapped in <…>) brings up a tooltip showing the corresponding entry from the game\'s resource files: item description and stats, ability cost / type, or spell properties.',
								'Up to four preview tooltips can stack horizontally above the chat window when a single line contains multiple recognised names.',
								'Disable previews from Settings → Extra → "Preview Items/Abilities/Spells on mouse hover" if you find them distracting during combat.'
						  }
help.chatwindowCopying = {
								'Copying & Saving Chat Lines',
								'Hovering a chat line softly highlights it; clicking it once with the left mouse button copies the full text of that line (and any related continuation lines from the same message) to the system clipboard. A confirmation echo appears in chat ("Text successfully copied to clipboard!"). Paste anywhere with Ctrl+V — Discord, browser, in-game /tell, etc.',
								'Hold Shift and click a chat line to save it to the FancyChat Notepad instead of the clipboard. The Notepad keeps up to 10 entries; if the list is full when you try to add another, an "Notepad notes full [10/10]" notice is printed instead of the save.',
								'When a chat line carries an embedded URL, FancyChat shows a small "[link]" marker next to the line\'s aux area. Clicking that marker (not the message text) opens the URL in your default browser via "ashita.misc.open_url"; clicking the message text itself still copies normally.'
						  }
help.chatwindowCompactCombat = {
								'Compact Combat Log',
								'When Compact Combat Log is enabled (Settings → Extra), FancyChat reformats combat messages into a tighter layout that uses custom-font glyphs (rendered via the bundled gameicons.ttf) for the action type — a sword for melee hits, a bow icon for ranged attacks, a magic glyph for spells, a critical-hit marker, etc. — and highlights the actor names.',
								'A line of the form "Eleanor hits Treant Sapling for 23 points of damage." becomes a compact line that visually reads "Eleanor [sword-icon] Treant Sapling > 23 DMG" with the icon and the separator drawn as glyphs. The separator character is configurable in Settings → Chat Window (defaults to ">"), and the actor name colours come from the Actor 1 / Actor 2 / You entries in Settings → Font Colors.',
								'Actor names are coloured according to who they are: yourself, a party member, an alliance member, or an unrelated player / monster — each gets its own slot in the Font Colors palette.',
								'FancyChat is the only combat-log formatter that should be active — running another chat-modifying addon at the same time is not supported (see Tips → Compatibility with other chat addons).',
								'The "Colorblind mode" option in Extra swaps the damage-done / damage-taken colours to a red-green-friendly palette.'
						  }
help.chatwindowTimestamps = {
								'Timestamps',
								'FancyChat can prepend an [HH:MM:SS] timestamp to every chat line ("Timestamp" checkbox in Settings → Extra), OR insert a periodic horizontal banner — a row of dashes around the current time — at a configurable interval ("Timestamp as a line" checkbox + "Every" dropdown: 1 / 5 / 10 / 30 / 60 minutes). The two options are mutually exclusive — turning one on disables the other.',
								'The per-line timestamp can use the long [HH:MM:SS] format or the short [HH:MM] format, picked from the Format dropdown next to the Timestamp checkbox.',
								'Use "/fancychat ts" to print the current time once as a regular chat line (formatted as the long-format timestamp).',
								'The per-line timestamp prefix is always rendered in white so it stays readable regardless of the rest of the line\'s colour.'
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
	'/fancychat ts — print the current time once to chat (formatted as the long-format timestamp).',
	'/fancychat savelogs — save every tab\'s current chat history to "addons/fancychat/logs/<character>".',
	'/fancychat bigmode — toggle the full-screen BigMode overlay.',
	'/fancychat debug — open the developer diagnostic window. Mostly useful when reporting a bug.',
};

help.commandsMacros = {
	'Using Commands in Macros',
	'Any of the slash commands above can be bound to an FFXI macro for quick access. Open the in-game macro editor and use a line like "/fancychat compact" or "/fchat bigmode" — the addon picks them up exactly like a typed command.',
	'Common useful bindings:\n- One-button BigMode toggle for browsing chat history during a long event.\n- A macro that runs "/fancychat savelogs" before a fight in case you need a chat-log archive afterwards.\n- A "/fchat ts" macro to drop the current time into chat at a specific moment (e.g. when a boss popped).',
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
	'If a particular type of combat message is cluttering your chat (effect-wears-off, no-effect, etc.):\n1. Settings → Extra → enable "Hide alliance combat log" and "Hide non-party combat log" to focus the combat tab on you and your party.\n2. For more surgical filtering, use Settings → CL Filters: pick a filter file in the Active filter file dropdown (or click Open Folder to add a new .txt under combatfilters/), click Edit Selected Filter to add filter words one per line, then click Reload Selected Filter and tick "Enable Combat Log chat filters". Each filter can be scoped to apply to all messages, all-but-you, or all-but-party.',
	'Note that filtering matches against the original FFXI message text exactly as it arrives, before FancyChat\'s own formatting is applied.',
};

help.tipsHidden = {
	'Chat window has disappeared',
	'If the chat window is gone after loading the addon:\n1. Settings → Chat Window → uncheck "Lock Windows Positions" and check whether the chat plate is just behind another UI element you can drag aside.\n2. If Auto-Hide is on, the window may have faded out. Mouse hover does NOT bring it back — type a "/" to open the chat input, scroll the mouse wheel where the chat should be, or press one of your configured FancyChat shortcuts to wake it up. To confirm Auto-Hide is the cause, briefly disable it in Settings → Chat Window.\n3. Use "/fancychat settings" to open the Settings panel even when the chat plate isn\'t visible — the Position Offsets section can move it back to the centre of the screen.\n4. As a last resort, "/addon unload fancychat" then "/addon load fancychat" to fully reset the runtime state.',
};

help.tipsSecondChat = {
	'Using the second chat window',
	'The second chat window is a fully-independent chat plate that can show a different tab from the primary one. Enable it in Settings → Chat Window → "Enable second chat window".',
	'Once enabled, the second window appears and can be dragged, resized via the same Font Size / Chat Width controls (each chat plate has its own settings), and assigned its own active tab via the second tab bar.',
	'Common uses: keep "All" on the primary plate and "Combat" on the secondary, or split tells onto a smaller dedicated plate so you don\'t miss them in busy events.',
	'GuideMe and Notepad can be docked to the second window instead of the primary — Settings → Extra → "Dock GuideMe/Notes on the second chat window".',
};

help.tipsDataLocation = {
	'Where FancyChat stores its data',
	'Everything FancyChat saves to disk lives under the addon folder ("addons/fancychat/"). All data files are scoped per character — each character on your account has its own settings, palette, notes, and saved logs.',
	'- Settings: "config/addons/fancychat/<character>/settings.json". Persisted automatically every time you change anything in the Settings panel. Holds tab choices, font sizes, shortcut keys, color blind mode, custom-tab modes, alert words, notepad contents, and the SelectedCombatFilter / SelectedNotification / SelectedAlert pickers.',
	'- Color sets: "addons/fancychat/chatcolors/colorset_<character>". One file per character, written by the Font Colors → Export Colors button. Imported back in by Import Colors.',
	'- Combat filter files: "addons/fancychat/combatfilters/*.txt". User-managed plain-text lists of words to hide from the combat log. Multiple files supported — pick the active one in Settings → CL Filters.',
	'- Saved chat logs: "addons/fancychat/logs/<character>/<timestamp>/". Written by the Tools → Save Chat Logs button or the "/fancychat savelogs" command. One subfolder per save, one .txt per chat tab.',
	'- Sound effects: "addons/fancychat/notifications/*.wav". Drop your own .wav files here to add them to the Notification / Alert dropdowns (the addon picks up any "notification_<n>.wav" automatically on next start).',
	'- Notepad entries: stored inside settings.json under the "Notes" key, so they travel with your settings backup.',
	'To back up everything, copy the whole "addons/fancychat/" folder; to migrate to a new install, drop it in place. To share with another player, send them only the chatcolors/ or combatfilters/ files you want to give them.',
};

help.tipsAddonCompatibility = {
	'Compatibility with other chat addons',
	'FancyChat is NOT designed to be used alongside other addons that modify, reformat, or recolour chat messages. Combat-log enhancers such as simplelog, alternative chat replacements, or anything that rewrites incoming chat lines is not supported.',
	'Running two chat-handling addons at the same time will produce visual conflicts (duplicated lines, broken colours, mangled formatting, missing spaces, etc.) and is not a configuration FancyChat tries to recover from.',
	'If you want to use FancyChat, unload other chat-modifying addons first ("/addon unload <name>") or remove them from your default load list. If you prefer a different chat addon, unload FancyChat instead.',
};

help.tipsSections = { help.tipsRestoreLegacy, help.tipsCleanCombat, help.tipsHidden, help.tipsSecondChat, help.tipsDataLocation, help.tipsAddonCompatibility };

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
							'Reset Colors restores the entire palette to the addon defaults.',
							'Export Colors writes the current palette to "addons/fancychat/chatcolors/colorset_<your character>" — one file per character, plain-text key,value lines so it can be inspected, version-controlled, or shared. The chatcolors/ subfolder is created automatically on first export.',
							'Import Colors reads the file with your character\'s name back in. To carry a palette between characters, copy the file and rename the "_<character>" suffix on the copy. To share a palette with another player, send them your colorset file and have them put it under their own character name.',
						  };
help.settingsShortcuts = {
							'Shortcuts',
							'Configure keyboard combos for four actions:',
							'- "Hide FancyChat Addon": temporarily hides FancyChat (the legacy FFXI chat keeps showing in the meantime).\n- "Big Window Mode": toggles the large-text full-screen overlay (BigMode).\n- "Scroll Chat Tabs (window 1)": cycles through tabs on the primary chat plate.\n- "Scroll Chat Tabs (window 2)": same, on the second chat plate (if enabled).',
							'Each row has an "Enabled" checkbox plus two key pickers: a modifier dropdown (Shift / Alt / Ctrl) and a main-key dropdown (letters, ., , Tab, ~, etc.). All four shortcuts default to OFF — tick the Enabled checkbox to activate one. The "Reset default keys" button restores the original key assignments without changing the Enabled flags.',
							'Below the shortcuts a "Commands to manually macro features" reference panel lists the slash commands that can be used as macro lines in place of (or in addition to) keyboard shortcuts.',
						  };
help.settingsExtra = {
						'Extra',
						'Behaviour toggles that don\'t fit into the other tabs.',
						'Block legacy chat messages: prevents the original FFXI chat window from rendering messages that FancyChat already displays. The "All" option blocks every category and is required for the addon to fully replace the legacy chat. "Combat (recommended)" blocks only combat messages — a safer fallback if you want the legacy chat to remain available.',
						'Chat message filtering: the hide-combat-from-All toggle sends combat and custom logs only to their specific tabs (the All tab is renamed to "AllAlt"). The hide-alliance / hide-non-party / show-only-you-and-pet toggles progressively narrow down the combat log to focus on relevant lines.',
						'Other settings:',
						'- Compact Combat Log: reformats combat messages with FancyChat-specific iconography (sword, ranged-attack, magic, ability, etc.) and highlights actor names.',
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
						'- Heart emoji: replaces the text "<3" with the heart emoji.',
					 };
help.settingsCLFilters = {
							'CL Filters',
							'Define a list of custom words that, when found in a combat-log message, will hide that message from the chat. Useful for cleaning up status-effect spam (e.g. "wears off", "no effect").',
							'Filter files live in the combatfilters/ subfolder of the addon. You can keep multiple .txt files there (e.g. one for raids, one for solo play) and switch between them using the Active filter file dropdown. The selected file is remembered between sessions.',
							'Edit Selected Filter opens the currently picked file in your default text editor. Each line is one filter; comments and per-line scope flags are documented inside the file. Word matching is case-insensitive and the filter is applied against the original FFXI combat message text.',
							'Reload Selected Filter re-reads the active file without restarting the addon, so you can tweak filters live.',
							'Open Folder opens combatfilters/ in Windows Explorer so you can add new filter files, rename existing ones, or copy templates.',
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

-- Pixel-aware row counter that matches ImGui's TextWrapped behaviour.
--
-- utils.CalcRows estimates rows by dividing total text length by an
-- average character width — fast, but inaccurate for proportional
-- fonts because most letters are narrower than the 'H' used as the
-- divisor.  That mismatch caused the help-section child frames to
-- under- or over-shoot the actual rendered height by a couple of rows.
--
-- This version walks the text word by word, calling imgui.CalcTextSize
-- on the running line and committing it when adding the next word
-- would cross wrap_width.  Embedded '\n' characters force a line
-- break.  Single words wider than wrap_width still count as one row
-- (ImGui hard-breaks them, but the row count we want for sizing the
-- child frame is the number of *visual* rows it ends up occupying;
-- this matches what we observe on screen close enough).
help.CalcSectionRows = function(text, wrap_width)
    local rows = 0
    -- Append a sentinel '\n' so gmatch picks up the trailing chunk.
    for hard_line in (text..'\n'):gmatch('([^\n]*)\n') do
        if hard_line == '' then
            -- Blank paragraph still occupies one visual row.
            rows = rows + 1
        else
            local current = nil
            for word in hard_line:gmatch('%S+') do
                local trial = (current == nil) and word or (current..' '..word)
                local w     = imgui.CalcTextSize(trial)
                if w <= wrap_width then
                    current = trial
                else
                    if current ~= nil then
                        rows = rows + 1
                    end
                    current = word
                end
            end
            if current ~= nil then rows = rows + 1 end
        end
    end
    return rows
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
				-- Vertically size the section's child frame to fit the
				-- wrapped paragraphs exactly.  help.CalcSectionRows
				-- simulates ImGui's TextWrapped using actual pixel
				-- widths, and the height formula below mirrors the
				-- exact cursor walk that help.SetText performs:
				--
				--   cursor at y = WindowPadding.y               (~8)
				--   for each of N paragraphs:
				--     TextWrapped → cursor += rows_i * font_h
				--                 + ItemSpacing.y               (~4)
				--     if not last:
				--       Dummy(0,5) → cursor += 5 + ItemSpacing.y (5+4)
				--   bottom padding                              (~8)
				--   border × 2                                  (~2)
				--
				-- Net per-paragraph constant tail = 13*N + 9, where
				-- the per-paragraph 13 = 5 (Dummy) + 2 * ItemSpacing.y.
				-- We add a small +5 safety buffer for style overrides
				-- (different theme padding can shift a couple of px).
				--
				-- Wrap width also accounts for AddSubSections' Indent()
				-- (= GetCursorPosX()) plus the child's WindowPadding
				-- and the 10 px margin help.SetText subtracts inside
				-- PushTextWrapPos.
				local wrap_width = imgui.GetWindowWidth() - imgui.GetCursorPosX() - 16 - 10
				local font_h     = imgui.GetFont().FontSize or imgui.GetFont().LegacySize
				local numparas   = #section[s] - 1
				local textlines  = 0
				for i = 2, #section[s] do
					textlines = textlines + help.CalcSectionRows(section[s][i], wrap_width)
				end
				imguiWrap.BeginChild(section[s][1].."Frame",
					{ 0, textlines * font_h + 13 * numparas + 14 },
					true)
				help.SetText(section[s])
				imgui.EndChild()
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