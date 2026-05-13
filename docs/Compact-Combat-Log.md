# Compact Combat Log

When **Settings → Extra → "Compact Combat Log"** is enabled, Fancychat reformats every combat message into a tighter layout that uses custom icons (from the bundled `gameicons.ttf`) for the action type and a configurable separator between actor and damage.

## Format

The standard `Eleanor hits Treant Sapling for 23 points of damage.` becomes a compact line that visually reads:

```
Eleanor [sword-icon] Treant Sapling > 23 DMG
```

Where:
- `[sword-icon]` is a custom icon from the bundled `gameicons.ttf` font (not a regular emoji)
- `>` is the separator between actor and damage (Settings → Chat Window → "Combat Split Char" — defaults to `>`)
- `Eleanor` and `Treant Sapling` are coloured according to who they are (see below)

## Action icons

Each attack type has its own icon:

| Action | Icon |
|---|---|
| Melee attack | Sword |
| Ranged attack | Bow |
| Spell cast | Magic burst |
| Cast in progress | Casting indicator |
| Critical hit | Star |
| Heal | Heart / cross |
| Loot / item drop | Bag |
| Gil obtained | Coin |
| EXP gained | Up arrow |
| Level up | Level-up marker |
| Key item | Key |
| Utsusemi shadow | Shadow |
| Corsair Roll | Die |

The icons come from the bundled `gameicons.ttf`, which is loaded automatically when Fancychat starts. They only render correctly inside Fancychat — they will appear as boxes or unknown characters anywhere else (legacy chat, text you copy out of the addon, etc.).

## Actor name colouring

Actor names are coloured by their relationship to you:

- **You** — your "you" colour (Font Colors tab)
- **Party member** — friend colour
- **Alliance member** — friend colour with an alliance tint
- **Foe / monster** — foe colour
- **Unrelated player / pet** — falls back to the base combat colour

Configure each in Settings → Font Colors. See [Color Palettes](Color-Palettes.md) for managing the full palette.

## Colorblind mode

**Settings → Extra → "Colorblind mode for damage done/taken text"** swaps the damage-done / damage-taken palette to a red-green-friendly alternate. Affects only the damage colours, not actor names.

## Combat filters

Compact combat lines can be filtered to hide noise. See [Combat Filters](Combat-Filters.md) for the `combatfilters/` folder picker, multiple filter files, and the `_y` / `_p` scope syntax.

## Compatibility

Compact Combat Log conflicts with any other addon that reformats combat lines (`simplelog` and similar). See [Compatibility](Compatibility.md) — only one chat-modifying addon can be loaded at a time.

## See also

- [The Chat Window](The-Chat-Window.md#tabs) — combat lines route to the **Combat** tab
- [Color Palettes](Color-Palettes.md) — actor name colors
- [Combat Filters](Combat-Filters.md) — hiding specific combat lines
