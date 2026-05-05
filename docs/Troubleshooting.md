# Troubleshooting

## The chat plate has disappeared

If the chat plate is gone after loading the addon:

1. **Unlock window positions** in **Settings → Chat Window** (uncheck "Lock Windows Positions"). Check whether the plate is just behind another UI element you can drag aside.
2. **If Auto-Hide is on**, the plate may have faded out. **Mouse hover does NOT bring it back.** To wake it up, do any of:
   - Type `/` to open the chat input
   - Roll the mouse wheel where the chat should be
   - Press one of your configured Fancychat keyboard shortcuts
   - To confirm Auto-Hide is the cause, briefly disable it via **Settings → Chat Window → "Enable Auto-Hide window"**.
3. Use `/fchat settings` to open the Settings panel even when the chat plate isn't visible — the **Position Offsets** section can move the plate back to the centre of the screen.
4. As a last resort, fully reset the runtime state:
   ```
   /addon unload fancychat
   /addon load fancychat
   ```

## Combat log is unreadable / spam-heavy

Two complementary controls:

1. **Settings → Extra → Hide alliance combat log** + **Hide non-party combat log** — focus the combat tab on you and your party.
2. **Settings → CL Filters** — pick a filter file in the **Active filter file** dropdown (or click **Open Folder** to add a new `.txt` under `combatfilters/`), click **Edit Selected Filter** to add filter words one per line, then click **Reload Selected Filter** and tick **Enable Combat Log chat filters**.

See [Combat Filters](Combat-Filters.md) for the `_y` / `_p` scope suffixes.

## Need to capture a screenshot of the legacy chat (e.g. for a support ticket)

For bug reports or support tickets where the legacy FFXI chat layout is needed:

1. Click **Restore Legacy Chat Logs** in **Settings → Tools**.
2. Fancychat re-injects every message it has buffered back into the FFXI legacy chat.
3. Take a Print Screen / clipboard capture — the original-format chat now reflects the same content Fancychat was showing.

You can also enable **Settings → Extra → "Auto-restore logs when opening Legacy Chat"** to do this automatically every time you open the legacy chat window.

## Second chat window is not appearing

1. Tick **Settings → Chat Window → Enable second chat window**.
2. Click **Restart & apply** — the second-window initialisation runs only on addon (re)load.
3. Drag it from its anchor position. If you can't see it, it may be stacked on top of the primary plate — uncheck "Lock Windows Positions" first.
4. The second window has its own tab selection (`SelectedTab2`) — click its tab bar to assign a tab.

GuideMe and Notepad can be docked to the second window instead of the primary via **Settings → Extra → "Dock GuideMe/Notes on the second chat window"**.

## Custom font glyphs render as boxes / unknown characters

The compact combat log uses custom glyphs from the bundled `gameicons.ttf`. If you see boxes:

1. Make sure `addons/fancychat/gdifonts/gameicons.ttf` exists — it ships with the addon.
2. Make sure `addons/fancychat/gdifonts/gdifonttexture.dll` exists.
3. If you copied the addon manually, ensure both files copied — they're tracked in the repo.

## Visual conflicts (duplicated lines, broken colours, missing spaces)

Almost always caused by **another chat-modifying addon** loaded at the same time. See [Compatibility](Compatibility.md) — Fancychat is not designed to coexist with other chat handlers.

```
/addon unload simplelog
```

(or whichever other chat addon you have loaded)

## "GuideMe" can't load a wiki page

If the URL is from `ffxiclopedia.fandom.com` and the page fails to load with a Cloudflare error:

- Some VPN providers trigger Cloudflare's bot challenge. Try disabling your VPN.
- Or use the equivalent article on `bg-wiki.com`.

GuideMe is marked **experimental** — if a specific page renders strangely (broken tables, missing sections), it's a parser limitation rather than a fetch problem.

## Settings file got corrupted

If Fancychat misbehaves on load and you suspect the settings file:

1. Close FFXI.
2. Delete `Ashita/config/addons/fancychat/<your character>/settings.json`.
3. Re-launch — Fancychat falls back to defaults.
4. Reconfigure via the Settings panel.

You'll lose Notepad contents and your dropdown selections (active filter file, notification, etc.) but **not** your color palette (which lives in `addons/fancychat/chatcolors/colorset_<character>` — a separate file).

## See also

- [Installation](Installation.md)
- [Compatibility](Compatibility.md)
- [Settings Reference](Settings-Reference.md)
- [Data Storage](Data-Storage.md) — file map and recovery paths
