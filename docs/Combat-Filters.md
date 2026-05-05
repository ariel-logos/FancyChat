# Combat Filters

Hide combat-log noise (status-effect spam, "wears off" messages, etc.) by editing a filter file and applying it via **Settings → CL Filters**.

## Filter files live in `combatfilters/`

Filter files are plain `.txt` lists in the addon's `combatfilters/` subfolder. You can keep multiple files there and switch between them — for example one for raids, one for solo play.

```
addons/fancychat/combatfilters/
├── custom_combat_filters.txt   ← shipped default
├── raid_filters.txt
├── solo_filters.txt
└── trial_filters.txt
```

## The Active filter file picker

In **Settings → CL Filters**:

- **Active filter file** dropdown — lists every `.txt` in the folder. Pick one to make it the active filter set.
- **Refresh** button — re-scans the folder for newly added / renamed / deleted files.
- **Edit Selected Filter** — opens the picked file in your default text editor.
- **Reload Selected Filter** — re-reads the file without restarting the addon.
- **Open Folder** — opens `combatfilters/` in Explorer.
- **Enable Combat Log chat filters** — master switch. When off, the file is ignored and no filtering happens.

The active selection persists between sessions in `settings.json`.

## Filter file format

One filter per line. Comments start with `##`. Blank lines are ignored.

A filter is a Lua-pattern fragment matched **case-insensitively** against the original FFXI message text — *not* against any reformatting Fancychat does.

### Scope suffixes

Append an underscore + scope suffix to a filter to restrict where it applies:

| Suffix | Scope |
|---|---|
| (none) or `_z` | All messages |
| `_y` | Apply to all messages **except your own** actions |
| `_p` | Apply to all messages **except you and your party** |

So a line like:

```
wears off_y
```

hides "wears off" messages **unless** they're about your own status effects.

### Examples

```
## Hide common status spam
wears off_p
no effect
hits, but does no damage_z

## Hide alliance-only spam
gains the effect of_y
```

## Performance note

Every combat line is scanned against every filter. Very long lists (hundreds of patterns) can affect performance — keep your active file lean.

## Compatibility

Fancychat's combat filters operate before any other Fancychat formatting. They will *not* match against text rewritten by another chat-modifying addon — but you shouldn't be running another chat-modifying addon anyway. See [Compatibility](Compatibility.md).

## See also

- [Settings Reference → CL Filters](Settings-Reference.md#cl-filters) — the Settings UI walkthrough
- [Data Storage → Combat filter files](Data-Storage.md#combat-filter-files) — file path
- [Compact Combat Log](Compact-Combat-Log.md) — the formatting that filters operate on
