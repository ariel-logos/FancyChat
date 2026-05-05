# Color Palettes

Fancychat keeps a per-mode color palette covering every chat category (Tell, Party, Linkshell, Shout, Emote, Combat, NPC, etc.) plus auxiliary colors for damage classifications, actor highlights, and special tags.

## Editing colors

Open **Settings → Font Colors**. Each editable color is shown as a small swatch with a label.

1. Click a swatch to bring up the **Color Picker** in the right pane.
2. Adjust the color in the picker.
3. Click the **arrow button** next to a swatch to apply the picker's current color to that swatch.

Hover the small **(i)** icons next to each label for a description of which messages use that color.

The **Reset Colors** button restores the entire palette to the addon defaults.

## Sorting

The left-pane row order is sorted by the human-readable **label** of each color (not the internal key name). Adding a new color slot is automatically picked up at runtime — its label drives its position in the list.

## Sharing palettes

### Export

Click **Export Colors**. Fancychat writes a plain-text file:

```
addons/fancychat/chatcolors/colorset_<your character>
```

The `chatcolors/` subfolder is created automatically the first time you export. The file format is one `key,value` line per color slot, where the value is a hex ARGB number.

Example:
```
tell,0xffd35aff
party,0xff66e7fe
combat,0xffdcf1fc
...
```

Plain text means it can be inspected, version-controlled, or shared.

### Import

Click **Import Colors**. Fancychat reads the file matching your **current character's name**: `chatcolors/colorset_<character>`. Missing values fall through to the addon defaults.

### Sharing across characters or with another player

Because the file is keyed by character name, you have two routes:

1. **Same player, different character** — copy `colorset_OldChar` to `colorset_NewChar` while logged in as `NewChar`, then click Import.
2. **Send to another player** — share the file. The recipient renames it to match their own character name (e.g. `colorset_Friend`) and drops it into their `chatcolors/` folder, then clicks Import.

## See also

- [Settings Reference → Font Colors](Settings-Reference.md#font-colors) — the Settings UI walkthrough
- [Data Storage](Data-Storage.md#color-sets) — where the file lives on disk
- [Compact Combat Log](Compact-Combat-Log.md#actor-name-colouring) — actor-specific color slots
