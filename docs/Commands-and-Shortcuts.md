# Commands & Shortcuts

## Slash commands

All commands accept either `/fancychat` or the shorter `/fchat` as the prefix.

| Command | Effect |
|---|---|
| `/fchat settings` | Open / close the Settings panel |
| `/fchat manual` | Open / close the in-game manual |
| `/fchat guideme` | Open / close the [GuideMe](Companion-Panels.md#guideme) panel |
| `/fchat notes` | Open / close the [Notepad](Companion-Panels.md#notepad) |
| `/fchat compact` | Toggle the tab bar between expanded and compact (single-button-cycle) form |
| `/fchat tod` | Toggle Precise Time-of-Death timestamps for combat-kill lines |
| `/fchat ts` | Print the current time once to chat (formatted as the long-format timestamp) |
| `/fchat savelogs` | Save every chat tab's current contents to `addons/fancychat/logs/<character>/ChatLogs_<timestamp>/` |
| `/fchat bigmode` | Toggle the [BigMode](BigMode.md) full-screen overlay |

## Keyboard shortcuts

Configure under **Settings → Shortcuts**. **All four shortcuts default to disabled** — tick the **Enabled** checkbox per row to activate one.

| Action (UI label) | Default key combo (when enabled) |
|---|---|
| Hide FancyChat Addon | Shift + C |
| Big Window Mode | Shift + G |
| Scroll Chat Tabs (window 1) | Shift + X |
| Scroll Chat Tabs (window 2) | Shift + B |

Each row offers a modifier dropdown (Shift / Alt / Ctrl) and a main-key dropdown (A–Z, `.`, `,`, `Tab`, `~`). The **Reset default keys** button restores the original key assignments without changing the **Enabled** flags.

## Using commands in macros

Any of the slash commands above can be bound to an FFXI macro line for quick access. Open the in-game macro editor and use a line like:

```
/fancychat compact
```

or

```
/fchat bigmode
```

— the addon picks up macro-issued commands exactly like typed commands.

### Useful macro bindings

- **One-button BigMode toggle** for browsing chat history during a long event without leaning on an enabled shortcut.
- **`/fancychat savelogs`** before a fight in case you need a chat-log archive afterwards.
- **`/fchat ts`** to drop the current time into chat at a specific moment (e.g. when a boss popped).

## See also

- [Settings Reference → Shortcuts](Settings-Reference.md#shortcuts) — the configuration UI
- [BigMode](BigMode.md) — full-screen chat overlay
- [Combat Filters](Combat-Filters.md) — `_y` / `_p` scope syntax (a different kind of "shortcut" altogether)
