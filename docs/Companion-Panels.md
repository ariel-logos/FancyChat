# Companion Panels

Two side panels live next to your chat: **GuideMe** and **Notepad**. Both can be docked to either chat window or floated as movable windows.

## GuideMe

GuideMe is a built-in wiki-page viewer. Useful for keeping a quest walkthrough, item guide, or BCNM reference visible while you play, without alt-tabbing out of the game.

### Open

- Click the **GuideMe** icon button on the chat window's tab-bar row
- Or use `/fchat guideme` (toggles open/closed)

### Loading a wiki page

1. Paste a URL from `ffxiclopedia.fandom.com` or `bg-wiki.com` into the URL field at the top of the panel.
2. Press the **Load** button.
3. GuideMe fetches the page, extracts its **Walkthrough** section, and displays it as plain wrapped text.

### Cloudflare blocks

Some VPN providers trip Cloudflare's bot challenge on `ffxiclopedia.fandom.com`. If that happens, GuideMe shows:

> Page blocked by Cloudflare bot protection. Try disabling your VPN, or use the equivalent article on bg-wiki.com.

### Docking

- **Docked** (default) — sits above the primary chat window
- **Undocked** — toggle with the Dock / Undock button at the top of the panel; becomes a free movable window
- **Second-window dock** — when the second chat window is enabled, dock GuideMe there instead via Settings → Extra → "Dock GuideMe/Notes on the second chat window"

> GuideMe is marked **experimental**. It may not perfectly handle every wiki page layout — some pages with complex tables or non-standard markup may render imperfectly.

## Notepad

The Notepad is a tiny per-character pinboard that holds up to **10** lines of free-form text. Use it for quest reminders, party loot rules, frequent macros, item codes, or anything you want at hand without alt-tabbing.

### Open

- Click the **Notepad** icon button on the chat window
- Or use `/fchat notes` (toggles open/closed)

### Adding notes

There are three ways to add a note:

- **Type** in the input field at the top of the Notepad and click **Add Note**
- **Shift-click** any line in the chat to save it directly to the Notepad
- The list fills bottom-up; the **oldest entry is dropped** when a new one would overflow the 10-slot limit

### Per-note buttons

Each saved note has two small buttons next to it:

- **C** — copies the note to the clipboard
- **X** — deletes the note

### Persistence

Notes are stored inside `settings.json` under the `Notes` key, scoped per character. They persist across sessions and travel with your settings backup. See [Data Storage](Data-Storage.md).

### Docking

Notepad shares the GuideMe dock target. Toggling Settings → Extra → "Dock GuideMe/Notes on the second chat window" affects both.

## See also

- [The Chat Window](The-Chat-Window.md#copying--saving-lines) — Shift-clicking lines into the Notepad
- [Data Storage](Data-Storage.md#settings-json) — where Notepad entries live on disk
- [Commands & Shortcuts](Commands-and-Shortcuts.md) — `/fchat guideme` and `/fchat notes`
