# Fancychat

### What is it?
Fancychat is an add-on for FFXI's third-party loader and hook Ashita (https://www.ashitaxi.com/).

It replaces FFXI's native chat with a customizable in-game chat overlay: messages are sorted into tabs, combat lines can be compacted into icon-based rows, emojis and timestamps are supported, links are clickable, and the whole thing can be themed and resized to taste.
<br></br>

### Main features
- **7 chat tabs** to organize messages: All (renamed AllAlt if combat is hidden from it), Combat, Linkshell, Party, Tell, Shout, Custom
- **Compact combat log** — rewrites combat messages into tight icon-based lines (icons are drawn from the bundled `gameicons.ttf` font, so they always render in-game even when the equivalent emoji wouldn't)
- **Actor name coloring** — you, party members, alliance, enemies, and NPCs each get a distinct color
- **Emoji support** — ~2000+ emoji available via `:name:` substitution (`:grinning:` → 😀)
- **Timestamps** — per-line `[HH:MM:SS]`, `[HH:MM]`, or periodic hourly dividers
- **Auto-hide** — chat fades out on inactivity and wakes back up on new messages on the active tab, mouse-wheel scrolling, a configured keyboard shortcut, opening the chat input, or NPC dialog events (mouse hover alone does **not** wake it — that's intentional)
- ${\textsf{\color{cyan}{BigMode}}}$ — full-screen chat history overlay showing 30+ lines at once
- **Hover previews** — hovering an auto-translate item, ability, or spell name shows a tooltip with its description / cost / properties
- **Click to copy** — click any line to copy it to clipboard; Shift+click saves it to the Notepad panel
- **Clickable URLs** — links in chat open in your default browser
- **Chat logging** — save every tab to disk, organized by character and timestamp
- **Custom combat filters** — hide combat lines by keyword
- **Gamepad navigation** — optional controller support for switching tabs and scrolling
- **In-game manual** — built-in searchable help covering every feature (`/fchat manual`)
<br></br>

### Installation
Open the <a href="https://github.com/ariel-logos/Fancychat/releases" target="_blank">Releases</a> page, download the latest version, and unpack it into the `addons/` folder of your Ashita installation. You should end up with a `fancychat/` folder next to your other add-ons.

In game, type `/addon load fancychat` to start it, then `/fchat manual` for the built-in guide or `/fchat settings` to configure it.
<br></br>

### Disclaimer
The current release is compatible with **both ${\textsf{\color{orange}{Ashita 4.30}}}$ and earlier versions** of Ashita. Going forward, however, future releases of Fancychat are likely to target **${\textsf{\color{orange}{Ashita 4.30}}}$ only** — meaning users on older Ashita versions may need to update their Ashita install to keep receiving updates. If you'd rather stay on a stable build, pin to the most recent release that explicitly notes Ashita-pre-4.30 support in the release notes.
<br></br>

### 📖 Documentation
For longer reference docs see the [`docs/` folder](docs/Home.md). Every Settings tab, command, and customisation option has its own page. The in-game equivalent is `/fchat manual`.
<br></br>

### Compatibility
Fancychat is **not designed** to run alongside other add-ons that modify, reformat, or recolour incoming chat messages. Combat-log enhancers such as `simplelog`, alternative chat replacements, or anything that rewrites the chat stream are **not supported**. Running two chat-handling add-ons at the same time will produce visual conflicts (duplicated lines, broken colours, mangled formatting, missing spaces) that Fancychat will not try to recover from.

If you want to use Fancychat, unload other chat-modifying add-ons first (`/addon unload <name>`). If you prefer a different chat add-on, unload Fancychat instead.

### Functionalities

#### Commands
```/addon load fancychat``` Loads the add-on in Ashita.

```/addon unload fancychat``` Unloads the add-on.

```/fancychat``` or ```/fchat``` Base command; use with one of the subcommands below.

```/fchat settings``` Opens or closes the Settings panel.

```/fchat manual``` Opens or closes the in-game manual.

```/fchat notes``` Opens or closes the Notepad panel.

```/fchat guideme``` Opens or closes the GuideMe panel (FFXICLOPEDIA / BG-Wiki viewer).

```/fchat bigmode``` Toggles the BigMode full-screen overlay.

```/fchat savelogs``` Saves every chat tab to the `logs/` folder.

```/fchat compact``` Toggles compact tab mode (single cycle button vs. full tab bar).

```/fchat tod``` Toggles precise time-of-death timestamps on combat-kill lines.

```/fchat ts``` Prints the current time using the active timestamp format.
<br></br>

#### Chat Tabs
The tab bar at the top of the chat window lets you switch between up to 7 tabs:

- **All** — every message (renamed **AllAlt** if you tell Fancychat to drop combat and custom lines from it in **Settings → Extra**)
- **Combat** — melee hits, spells, abilities, and status effects
- **Linkshell** — linkshell messages
- **Party** — party chat
- **Tell** — tells sent and received
- **Shout** — shout and yell messages
- **Custom** — configurable tab that can include any combination of: NPC dialogue, tells, party, linkshell, and shout

Tabs can be shown as a full tab bar or switched to compact mode (`/fchat compact`), where a single button cycles through them. Keyboard shortcuts for cycling tabs on both the primary and secondary windows can be configured in **Settings → Shortcuts**.
<br></br>

#### Compact Combat Log
When enabled, incoming combat messages are rewritten into a condensed, icon-based format to reduce visual noise while keeping every relevant detail visible at a glance. Actor names are coloured by role and damage numbers are highlighted.

Icons used in compact mode (the emoji below are GitHub-rendered approximations; in-game they are drawn as custom glyphs from the bundled `gameicons.ttf`):
<ul>
  <li>${\textsf{\color{white}{⚔}}}$ — melee attack</li>
  <li>${\textsf{\color{white}{🏹}}}$ — ranged attack</li>
  <li>${\textsf{\color{white}{✨}}}$ — magic / spell</li>
  <li>${\textsf{\color{white}{⭐}}}$ — critical hit</li>
  <li>${\textsf{\color{white}{→}}}$ — action result / damage</li>
  <li>${\textsf{\color{white}{✗}}}$ — miss / resist</li>
</ul>

A ${\textsf{\color{orange}{colorblind mode}}}$ is available in **Settings → Extra**, which swaps the red-green colour palette used for actor names.

Custom combat filters live in the `combatfilters/` subfolder of the addon as plain-text `.txt` files. You can keep multiple filter files there (e.g. one for raids, one for solo play) and switch between them using the **Active filter file** dropdown in the **CL Filters** tab. The selected file is remembered between sessions. Each line is a word or phrase that, if found in a message, hides that message. Adding ` _y` to a line means "filter everyone EXCEPT me" — your own actions still show. Adding ` _p` means "filter everyone EXCEPT me and my party". Use the **Edit Selected Filter** button to open the active file in your default text editor, **Reload Selected Filter** to pick up edits without restarting, and **Open Folder** to manage the files in Explorer.
<br></br>

#### BigMode
BigMode is a full-screen overlay that shows the same chat buffer as the primary window but with many more visible lines (30+). Useful for reviewing recent chat history without scrolling.

Toggle BigMode with `/fchat bigmode` or by configuring a keyboard shortcut in **Settings → Shortcuts**. All four shortcuts (Hide, BigMode, Tab cycle window 1, Tab cycle window 2) are **disabled by default** — tick the Enabled checkbox and pick a key combo (e.g. Shift+G) to activate them. BigMode uses its own independent scroll cursor so switching back to the primary window does not disrupt your scroll position there.
<br></br>

#### Settings Panel
Open the Settings panel with `/fchat settings`. It contains six tabs:

<ol>
  <li><b>Chat Window</b>: font size, chat width, line count, plate background alpha, second chat window, custom-tab message types, position offsets, window locks, compact mode, half-length toggle, anti-obstruction (auto-slide when an FFXI menu opens), auto-hide delay, gamepad navigation.</li>
  <li><b>Font Colors</b>: per-message-mode colour editor. Colour picker UI plus Import / Export — exported colour schemes are written to <code>chatcolors/colorset_&lt;character&gt;</code> as plain-text key,value files (folder is auto-created on first export). One file per character; copy and rename to share a palette across characters or with another player.</li>
  <li><b>Shortcuts</b>: configure 2-key combos (modifier + main key) for: hide chat, BigMode, tab cycle (primary window), tab cycle (secondary window). All four default to disabled — tick the <b>Enabled</b> checkbox per row to activate one.</li>
  <li><b>Extra</b>: legacy-chat blocking toggles, combat-log filtering toggles, timestamp format and timestamp-as-line interval, precise timestamp mode, tell alert sounds, item/ability/spell hover previews, auto-restore on reload, colorblind mode, fast scroll (Shift + mouse wheel), docked second window, heart emoji toggle.</li>
  <li><b>CL Filters</b>: <b>Active filter file</b> dropdown to pick which <code>.txt</code> in the <code>combatfilters/</code> folder is used as the active filter list, with <b>Refresh</b> / <b>Edit Selected Filter</b> / <b>Reload Selected Filter</b> / <b>Open Folder</b> buttons. Supports keywords with <code>_y</code> / <code>_p</code> scope modifiers.</li>
  <li><b>Tools</b>: save chat logs, open the logs folder, open the in-game manual, restore legacy chat (DumpChat).</li>
</ol>
<br></br>

#### GuideMe & Notepad
The **GuideMe** panel (`/fchat guideme`) is a built-in viewer for FFXICLOPEDIA and BG-Wiki pages, displayed as wrapped text directly in-game — no alt-tabbing required.

The **Notepad** panel (`/fchat notes`) is a per-character note keeper. Shift-clicking any chat line saves it to the Notepad (up to 10 entries). Notes persist between sessions.
<br></br>

#### Chat Logging
Chat logs are saved to the `logs/` folder inside the add-on directory, organized by character name and session timestamp:

```
logs/
└── CharacterName/
    └── ChatLogs_YYYY_MM_DD-HH_MM_SS/
        ├── All.txt
        ├── Combat.txt
        ├── Linkshell.txt
        ├── Party.txt
        ├── Tell.txt
        ├── Shout.txt
        └── Custom.txt
```

Logs are written to disk **on demand** — either via `/fchat savelogs` or the **Save Chat Logs** button in the Tools tab. They are *not* auto-saved when the add-on unloads (the unload handler only persists settings and, if **Auto-Dump Chat** is enabled, re-injects the buffer into the legacy chat).
<br></br>

### Credits

A heartfelt thank you to:

- The **[Ashita](https://www.ashitaxi.com/) team** — for all the help and patience answering my questions while building this add-on, and for the framework that makes it possible in the first place.
- **atom0s** — for the `targets.lua` script that powers Fancychat's actor / target resolution and the infinite patience to guide me through all the RE nuances.
- **Thorny** — for the gdifonts library that powers the custom-font texture rendering pipeline and the invaluable help I received despite all my dull moments.
