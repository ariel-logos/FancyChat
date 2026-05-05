# The Chat Window

Fancychat replaces FFXI's native chat plate with an ImGui overlay rendered via the bundled GDI-font texture pipeline. The legacy chat keeps running underneath unless you tell it not to (Settings → Extra → "Block legacy chat messages").

## Anatomy

- **Chat plate** — the dark area where messages render
- **Tab bar** — at the top, switches between message categories
- **Side icons** — GuideMe, Notepad, Settings cog, Compact-Tabs toggle
- **Optional second window** — independently configured second plate (Settings → Chat Window → "Enable second chat window")

Most of the addon's state — settings, color palette, custom filters, notepad entries — is keyed by your character name. Switching characters loads a separate set of preferences automatically. See [Data Storage](Data-Storage.md) for the on-disk layout.

## Positioning

- **Drag** the plate by clicking and holding on the dark background area (not the tab bar or the side icons).
- **Lock** the position with Settings → Chat Window → "Lock Windows Positions (disables dragging)".
- **Anti-obstruction** mode (Settings → Chat Window → "Prevent obstructing FFXI UI") slides the plate out of the way when an FFXI menu (inventory, magic, mog house, etc.) opens.
- **Position offsets** (Settings → Chat Window) fine-tune each window's X/Y relative to its anchor.

## Tabs

The tab bar exposes 7 tabs: **All**, **Combat**, **Linkshell**, **Party**, **Tell**, **Shout**, **Custom**. Click a tab heading or use a keyboard shortcut to cycle.

- **All** shows every message by default. Enable Settings → Extra → "Hide combat and custom logs from 'All' tab." to drop combat lines from it — the tab is renamed **AllAlt**.
- **Custom** is configurable. Pick which categories funnel into it from Settings → Chat Window → Custom Tab Modes (NPC, Tell, Party, Linkshell, Shout — any combination).
- **Compact tab mode** collapses the bar into a single button that cycles tabs on click. Toggle with `/fchat compact` or the side icon.

## Scrolling chat history

- **Mouse wheel** while hovering the plate scrolls one line per tick.
- **Shift + mouse wheel** scrolls multiple lines per tick when **Settings → Extra → "Fast scroll chat history"** is enabled.
- **Right-click** while the plate is on screen jumps the scroll back to the bottom (most recent line).
- New messages keep arriving while you're scrolled back — they appear when you return to the bottom.

## Copying & saving lines

- **Click any chat line** to copy its full text to the system clipboard. Multi-line messages copy as one unit. A confirmation echo appears: *"Text successfully copied to clipboard!"*
- **Shift + click** saves the line to the [Notepad](Companion-Panels.md#notepad) instead of the clipboard.
- **Click the `[link]` aux marker** next to a line that contains a URL — opens the URL in your default browser via `ashita.misc.open_url`. (Clicking the message text itself still copies normally.)

## Hover previews

Hovering the in-game name of an item, ability, or spell in chat (an "auto-translate" phrase wrapped in the special `‹...›` brackets) brings up a tooltip showing the corresponding entry from FFXI's resource files: item description and stats, ability cost / type, spell properties.

- Up to **four** preview tooltips can stack horizontally above the chat window when a single line contains multiple recognised names.
- Disable previews from Settings → Extra → "Preview Items/Abilities/Spells on mouse hover".

## Auto-hide

Auto-hide makes Fancychat fade out after a configurable period of inactivity. Enable it in Settings → Chat Window → "Enable Auto-Hide window"; the slider sets the idle delay (5–60 seconds before fade starts).

The faded-out window still receives messages — it just isn't drawn until activity wakes it up. The fade resets to fully visible when:

- A new message arrives on the **currently selected** tab
- You **scroll** the chat with the mouse wheel
- You press one of Fancychat's configured **keyboard shortcuts**
- You **open the chat input box** (start typing `/`)
- An NPC dialog event begins
- You hover over the **GuideMe** or **Notepad** companion panels

> **Mouse hover over the chat plate does NOT wake the auto-hidden window.** Scrolling is the simplest "wake" gesture if you want to peek without typing.

## See also

- [Compact Combat Log](Compact-Combat-Log.md) — combat-message formatting
- [BigMode](BigMode.md) — full-screen chat history overlay
- [Settings Reference](Settings-Reference.md) — every Settings tab walkthrough
