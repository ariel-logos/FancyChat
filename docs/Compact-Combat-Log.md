# Compact Combat Log

When **Settings → Extra → "Compact Combat Log"** is enabled, Fancychat reformats every combat message into a tighter layout that uses custom-font glyphs (rendered via the bundled `gameicons.ttf`) for the action type and a configurable separator between actor and damage.

## Format

The standard `Eleanor hits Treant Sapling for 23 points of damage.` becomes a compact line that visually reads:

```
Eleanor [sword-icon] Treant Sapling > 23 DMG
```

Where:
- `[sword-icon]` is a custom font glyph from `gameicons.ttf` (NOT a Unicode emoji)
- `>` is the configurable separator (Settings → Chat Window → "Combat Split Char" — defaults to `>`)
- `Eleanor` and `Treant Sapling` are coloured according to the actor classification (see below)

## Action icons

Each attack type uses a distinct custom-font glyph:

| Action | Internal name | Notes |
|---|---|---|
| Melee attack | `ATK` | Sword glyph |
| Ranged attack | `RA` | Bow glyph |
| Spell cast | `SPELL` | Magic glyph |
| Cast in progress | `CAST` | Casting indicator |
| Critical hit | `SC` | Critical-hit marker |
| Heal | `HEAL` | Healing indicator |
| Loot / item drop | `LOOT` | Drop marker |
| Gil obtained | `GIL` | Currency marker |
| EXP gained | `EXP` | XP marker |
| Level up | `LVLUP` | Level-up marker |
| Key item | `KEY` | Key-item marker |
| Utsusemi shadow | `UTSU` | Shadow marker |
| Roll (COR) | `ROLL` | Roll indicator |

The glyph codepoints are PUA (private-use area) entries in `gameicons.ttf`; they only render correctly inside Fancychat where the font is loaded. They will appear as boxes / unknown glyphs anywhere outside the addon (legacy chat, copied-to-clipboard text, etc.).

## Actor name colouring

Actor names are coloured by their relationship to you:

- **You** — `you` color (Font Colors tab)
- **Party member** — `actor1` (friend entity)
- **Alliance member** — `actor1` with alliance tint
- **Foe / monster** — `actor2` (foe entity)
- **Unrelated player / pet** — falls back to `combat` base color

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
