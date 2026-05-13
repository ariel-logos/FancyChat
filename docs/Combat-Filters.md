# Combat Filters

Hide combat-log noise (status-effect spam, "wears off" messages, etc.) by editing a filter file and applying it via **Settings → CL Filters**.

## Filter files live in `combatfilters/`

Filter files are plain `.txt` lists in the addon's `combatfilters/` subfolder. You can keep multiple files there and switch between them — for example one for raids, one for solo play.

```
addons/fancychat/combatfilters/
├── example.txt                 ← shipped default (used if you've never picked one)
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

Each filter is a word or short phrase. If it appears anywhere in the original FFXI message text (case-insensitive), that message is hidden. The match is against the **raw** FFXI message text — *not* against the icon-based Compact Combat Log version of it.

Advanced users can also use Lua pattern syntax (`%s`, `%d`, `.`, `.-`, etc.) — handy for matching variable bits like numbers. If you don't know what that means, just type plain words and it'll work fine.

### Scope suffixes

Add a space and a suffix at the end of a line to control who the filter applies to:

| Suffix | Effect |
|---|---|
| (none) | Filter applies to **everyone**, including you |
| ` _y` | Filter applies to **everyone except you** — your own actions still show |
| ` _p` | Filter applies to **everyone except you and your party** — yours and party show |

So a line like:

```
wears off _y
```

hides "wears off" messages from everyone else but still shows them for your own status effects.

### Examples

```
## Hide effect-wearing-off spam from non-party members
wears off _p

## Hide damage-resist lines from everyone
no effect
hits, but does no damage

## Hide "gains the effect of ..." from non-you actors
gains the effect of _y
```

## Performance note

Every combat line is scanned against every filter in the active file. Very long lists (hundreds of patterns) can affect performance — keep your active file lean.

## Compatibility

Fancychat's combat filters look at the **original** FFXI message text before Fancychat does anything to it. They will not match against text that has already been rewritten by another chat-modifying add-on — but you shouldn't be running another chat-modifying add-on alongside Fancychat anyway. See [Compatibility](Compatibility.md).

## See also

- [Settings Reference → CL Filters](Settings-Reference.md#cl-filters) — the Settings UI walkthrough
- [Data Storage → Combat filter files](Data-Storage.md#combat-filter-files) — file path
- [Compact Combat Log](Compact-Combat-Log.md) — the formatting that filters operate on
