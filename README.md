# Fancychat

### What is it?
Fancychat is an add-on for FFXI's third-party loader and hook Ashita (https://www.ashitaxi.com/).

The purpose of this add-on is to completely replace FFXI's native chat interface with a fully-featured, customizable chat overlay. It reformats incoming messages, organizes them into tabs, compacts combat logs into icon-based layouts, adds emoji support, timestamps, and much more.
<br></br>

### How does it work?
This add-on hooks into the game's `text_in` event to intercept every incoming chat message before it reaches the native chat box. Each message is processed through a formatting pipeline — cleaned, colorized, split into tabs, and inserted into an internal buffer — then rendered every frame via ImGui windows and a custom GDI font system that outputs directly to the D3D9 surface.
<br></br>

### Main features
- **8 chat tabs** to organize messages: All, AllAlt, Combat, Linkshell, Party, Tell, Shout, Custom
- **Compact combat log** — rewrites combat messages into tight icon-based lines (icons are rendered from the bundled `gameicons.ttf` font, so they'll appear in-game even if the equivalent emoji wouldn't display correctly)
- **Actor name coloring** — you, party members, alliance, enemies, and NPCs each get a distinct color
- **Emoji support** — ~2000+ emoji available via `:name:` substitution (`:grinning:` → 😀)
- **Timestamps** — per-line `[HH:MM:SS]`, `[HH:MM]`, or hourly banner dividers
- **Auto-hide** — chat fades out on inactivity and wakes up on new messages on the active tab, mouse-wheel scrolling, configured keyboard shortcuts, opening the chat input, or NPC dialog events (mouse hover alone does NOT wake it — that's intentional)
- ${\textsf{\color{cyan}{BigMode}}}$ — full-screen chat history overlay showing 30+ lines at once
- **Hover previews** — hovering auto-translate text shows item descriptions, ability costs, and spell properties
- **Click to copy** — click any line to copy it to clipboard; Shift+click to save it to the Notepad panel
- **Clickable URLs** — links in chat open directly in your browser
- **Chat logging** — saves all tabs to disk, organized by character and session timestamp
- **Custom combat filters** — block specific combat lines by keyword or Lua pattern
- **Gamepad navigation** — optional support for navigating tabs and scrolling with a controller
- **In-game manual** — built-in searchable help covering every feature (`/fchat manual`)
<br></br>

### Installation
Go over the <a href="https://github.com/ariel-logos/Fancychat/releases" target="_blank">Releases</a> page, download the latest version and unpack it in the add-on folder in your Ashita installation folder. You should now have among the other add-on folders the "fancychat" one!
<br></br>

### Disclaimer
The current release is compatible with **both Ashita 4.30 and earlier versions** of Ashita. Going forward, however, future releases of Fancychat are likely to target **Ashita 4.30 only** — meaning users on older Ashita versions may need to update their Ashita install to keep receiving updates. If you're running an older Ashita and you'd rather stay on a stable build, pin to the most recent release that explicitly notes Ashita-pre-4.30 support in the release notes.
<br></br>

### 📖 Documentation
For long-form, cross-linked reference docs see the [`docs/` folder](docs/Home.md). Each Settings tab, every command, and every customisation knob has its own page. The in-game equivalent is `/fchat manual`.
<br></br>

### Compatibility
Fancychat is **not designed** to run alongside other addons that modify, reformat, or recolour incoming chat messages. Combat-log enhancers such as `simplelog`, alternative chat replacements, or anything that rewrites the chat stream are **not supported**. Running two chat-handling addons at the same time will produce visual conflicts (duplicated lines, broken colours, mangled formatting, missing spaces) that Fancychat does not try to recover from.

If you want to use Fancychat, unload other chat-modifying addons first (`/addon unload <name>`). If you prefer a different chat addon, unload Fancychat instead.

### Functionalities

#### Commands
```/addon load fancychat``` Loads the add-on in Ashita.

```/addon unload fancychat``` Unloads the add-on from Ashita.

```/fancychat``` or ```/fchat``` Base command. Use with a subcommand listed below.

```/fchat settings``` Opens or closes the Settings panel.

```/fchat bigmode``` Toggles the BigMode full-screen overlay.

```/fchat manual``` Opens or closes the in-game manual.

```/fchat notes``` Opens or closes the Notepad panel.

```/fchat guideme``` Opens or closes the GuideMe panel (FFXICLOPEDIA/BG-Wiki viewer).

```/fchat savelogs``` Saves all chat tabs to the `logs/` folder.

```/fchat compact``` Toggles compact tab mode (single cycle button vs. full tab bar).

```/fchat tod``` Toggles precise timestamp mode.

```/fchat ts``` Prints the current time using the active timestamp format.

```/fchat debug``` Opens or closes the developer diagnostic window.

```/fchat test MODE TEXT``` Injects a synthetic chat message in the specified mode number.
<br></br>

#### Chat Tabs
The tab bar at the top of the chat window lets you switch between 8 tabs:

- **All** — every message (optionally excludes combat and custom messages to create an AllAlt tab)
- **Combat** — melee hits, spells, abilities, and status effects
- **Linkshell** — linkshell messages
- **Party** — party chat
- **Tell** — tells sent and received
- **Shout** — shout and yell messages
- **Custom** — configurable tab that can include any combination of: NPC dialogue, tells, party, linkshell, and shout

Tabs can be used as a full tab bar or switched to compact mode (`/fchat compact`), where a single button cycles through them. Keyboard shortcuts for cycling through tabs on both the primary and secondary windows can be configured in the Settings panel under **Shortcuts**.
<br></br>

#### Compact Combat Log
When enabled, incoming combat messages are rewritten into a condensed, icon-based format to reduce visual noise while keeping all relevant information at a glance. Actor names are colored by role, and damage numbers are highlighted.

Icons used in compact mode (the emoji below are GitHub-rendered approximations; in-game these are drawn as custom glyphs from the bundled `gameicons.ttf`):
<ul>
  <li>${\textsf{\color{white}{⚔}}}$ — melee attack</li>
  <li>${\textsf{\color{white}{🏹}}}$ — ranged attack</li>
  <li>${\textsf{\color{white}{✨}}}$ — magic / spell</li>
  <li>${\textsf{\color{white}{⭐}}}$ — critical hit</li>
  <li>${\textsf{\color{white}{→}}}$ — action result / damage</li>
  <li>${\textsf{\color{white}{✗}}}$ — miss / resist</li>
</ul>

A ${\textsf{\color{orange}{colorblind mode}}}$ is available in Settings under **Extra**, which swaps the red-green color palette used for actor names.

Custom combat filters live in the `combatfilters/` subfolder of the addon as plain-text `.txt` files. You can keep multiple filter files there (e.g. one for raids, one for solo play) and switch between them using the **Active filter file** dropdown in the **CL Filters** tab. The selected file is remembered between sessions. Each line in a filter file is a keyword to match against the original FFXI message text. Appending `_y` to a line restricts it to your own actions only; appending `_p` restricts it to you and your party. Use the **Edit Selected Filter** button to open the active file in your default text editor, **Reload Selected Filter** to pick up edits without restarting, and **Open Folder** to manage the files in Explorer.
<br></br>

#### BigMode
BigMode is a full-screen overlay that displays the same chat buffer as the primary window but with many more visible lines (30+). It is useful for reviewing recent chat history without scrolling.

Toggle BigMode with `/fchat bigmode` or by configuring a keyboard shortcut in **Settings → Shortcuts**. All four shortcuts (Hide, BigMode, Tab cycle window 1, Tab cycle window 2) are **disabled by default** — tick the Enabled checkbox and pick a key combo (e.g. Shift+G) to activate them. BigMode uses its own independent scroll cursor so switching back to the primary window does not disrupt your scroll position there.
<br></br>

#### Settings Panel
Open the Settings panel with `/fchat settings`. It contains six tabs:

<ol>
  <li><b>Chat Window</b>: font size, chat width, line count, plate background alpha, second chat window, custom tab message types, position offsets, window locks, compact mode, half-length toggle, anti-obstruction (auto-slide when FFXI UI opens), auto-hide delay, gamepad navigation.</li>
  <li><b>Font Colors</b>: per-message-mode color editor. Color picker UI plus Import/Export — exported color schemes are written to <code>chatcolors/colorset_&lt;character&gt;</code> as plain-text key,value files (folder is auto-created on first export). One file per character; copy and rename to share a palette across characters or with another player.</li>
  <li><b>Shortcuts</b>: configure 2-key combos (modifier + main key) for: hide chat, BigMode, tab cycle (primary window), tab cycle (secondary window). All four default to disabled — tick the <b>Enabled</b> checkbox per row to activate one.</li>
  <li><b>Extra</b>: legacy-chat blocking toggles, combat-log filtering toggles, timestamp format and timestamp-as-line interval, precise timestamp mode, tell alert sounds, item/ability/spell hover previews, auto-restore on reload, colorblind mode, fast scroll (Shift + mouse wheel), docked second window, heart emoji toggle.</li>
  <li><b>CL Filters</b>: <b>Active filter file</b> dropdown to pick which <code>.txt</code> in the <code>combatfilters/</code> folder is used as the active filter list, with <b>Refresh</b> / <b>Edit Selected Filter</b> / <b>Reload Selected Filter</b> / <b>Open Folder</b> buttons. Supports keywords with <code>_y</code> / <code>_p</code> scope modifiers.</li>
  <li><b>Tools</b>: save chat logs, open the logs folder, open the in-game manual, restore legacy chat (DumpChat).</li>
</ol>
<br></br>

#### GuideMe & Notepad
The **GuideMe** panel (`/fchat guideme`) is a built-in browser for FFXICLOPEDIA and BG-Wiki pages, displayed as wrapped text directly in-game — no alt-tabbing required.

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

Logs are written to disk **on demand** — either via `/fchat savelogs` or the **Save Chat Logs** button in the Tools tab. They are *not* auto-saved on unload (the unload handler only persists settings and optionally re-injects the buffer into the legacy chat if **Auto-Dump Chat** is enabled).
<br></br>

### Credits

A heartfelt thank you to:

- The **[Ashita](https://www.ashitaxi.com/) team** — for all the help and patience answering my questions while building this addon, and for the framework that makes it possible in the first place.
- **atom0s** — for the `targets.lua` script that powers Fancychat's actor / target resolution and the infinite patience to guide me through all the RE nuances.
- **Thorny** — for the gdifonts library that powers the custom-font texture rendering pipeline and the invaluable help I received despite all my dull moments.
