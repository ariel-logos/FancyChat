# Data Storage

Everything Fancychat saves to disk lives under your Ashita install. All data files are scoped **per character** — each character on your account has its own settings, palette, notes, and saved logs.

## File layout

```
Ashita/
├── addons/fancychat/
│   ├── chatcolors/
│   │   └── colorset_<character>            ← exported color palette, one per character
│   ├── combatfilters/
│   │   ├── example.txt                      ← shipped default filter set
│   │   └── *.txt                            ← user-managed extra filter files
│   ├── logs/
│   │   └── <character>/
│   │       └── ChatLogs_YYYY_MM_DD-HH_MM_SS/
│   │           ├── All.txt
│   │           ├── Combat.txt
│   │           ├── Linkshell.txt
│   │           ├── Party.txt
│   │           ├── Tell.txt
│   │           ├── Shout.txt
│   │           └── Custom.txt
│   ├── notifications/
│   │   ├── notification_1.wav
│   │   ├── notification_2.wav
│   │   └── ...                              ← drop your own .wav files here
│   ├── gdifonts/
│   │   ├── gameicons.ttf                    ← custom-icon font for compact combat log
│   │   └── gdifonttexture.dll               ← icon-rendering helper
│   ├── images/                              ← UI textures
│   └── ...
└── config/addons/fancychat/
    └── <character>/
        └── settings.json                    ← persisted user settings
```

## settings.json

Settings are saved automatically every time you change anything in the Settings panel. The file holds:

- Which tab each chat window is currently showing
- Font size, chat width, number of chat lines
- Plate background opacity, position offsets
- Keyboard shortcut combos and their enabled / disabled state
- Colorblind mode, custom-tab message types, chat-word alert list
- Your Notepad notes
- The currently selected combat-filter file, notification sound, and alert sound
- The on/off state of every checkbox in the Settings panel

If your settings get into a bad state, deleting this file makes Fancychat fall back to defaults on next load. You will not lose any chat history — that lives in memory only — but you will lose your Notepad notes.

## Color sets

Plain-text `key,value` files written by **Settings → Font Colors → Export Colors**. One file per character. See [Color Palettes → Sharing palettes](Color-Palettes.md#sharing-palettes) for sharing across characters or with another player.

## Combat filter files

User-managed `.txt` files in `combatfilters/`. Pick the active one with **Settings → CL Filters → Active filter file** dropdown. See [Combat Filters](Combat-Filters.md) for filter syntax.

## Saved chat logs

Written **on demand** — by the **Save Chat Logs** button in **Settings → Tools** or the `/fchat savelogs` command. **They are NOT auto-saved on unload.** One subfolder per save, one `.txt` per chat tab. The unload handler only persists settings and (if `Auto-Dump Chat` is on) re-injects the buffer into the legacy chat — neither writes log files.

## Notification sounds

`addons/fancychat/notifications/*.wav` — drop your own `.wav` files here to add them to the **Notification** / **Alert** dropdowns. Files named `notification_<n>.wav` are auto-detected on next addon load.

Two volume variants are supported:
- `notification_3.wav` — base volume
- `notification_3B.wav` — boosted volume (used when **Volume Boost** is ticked next to the dropdown)

## Backup / migration

To back up everything, copy these two folders:

- `Ashita/addons/fancychat/` — addon code, color sets, combat filters, log archives, sounds
- `Ashita/config/addons/fancychat/` — per-character settings.json

To migrate to a new install, drop both folders in place. To share with another player, send only the specific files you want them to have (most often: a `chatcolors/colorset_*` or a `combatfilters/*.txt`).

## See also

- [Color Palettes](Color-Palettes.md) — palette file format and sharing
- [Combat Filters](Combat-Filters.md) — filter file format and scope syntax
- [Companion Panels → Notepad](Companion-Panels.md#notepad) — Notepad persistence
