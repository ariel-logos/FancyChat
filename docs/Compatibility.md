# Compatibility

> **TL;DR:** Fancychat is **not designed** to run alongside other addons that modify, reformat, or recolour incoming chat messages. Pick one chat addon at a time. Or try your luck by loading FancyChat last and see what happens.

## What does NOT work alongside Fancychat

Combat-log enhancers and chat replacements that intercept or rewrite the chat stream are explicitly **unsupported**:

- `simplelog` — combat-line reformatter
- Alternative chat-replacement add-ons
- Anything else that reformats, colourises, or otherwise rewrites incoming chat messages before you see them (with some exceptions)

Running two chat-handling add-ons at the same time produces visual conflicts:

- Duplicated lines (each addon adds its own copy)
- Broken colours (palette escapes from one addon get overwritten by the other)
- Mangled formatting, missing spaces between coloured segments
- Tabs that don't match the messages they should contain

These are **not configurations Fancychat tries to recover from** — there's no "compatibility mode". Choose one.

## What DOES work alongside Fancychat

Everything that doesn't touch the chat stream is fine — UI overlays, equipment swap addons, stats tracking, mob trackers, music players, etc. Fancychat coexists with anything that doesn't intercept incoming chat.

## How to switch

If you have other chat addons loaded already and want to use Fancychat:

```
/addon unload simplelog
/addon unload <other chat addon>
/addon load fancychat
```

If you want to switch back to a different chat addon:

```
/addon unload fancychat
/addon load simplelog
```

Update your Ashita default-load script accordingly so the change persists across game launches.

## See also

- [Installation](Installation.md) — getting Fancychat loaded in the first place
- [Troubleshooting](Troubleshooting.md) — what to do if things look wrong after load
