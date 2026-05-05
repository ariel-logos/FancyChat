# BigMode

BigMode is a full-screen, large-text overlay of your chat history. Useful for reviewing long announcements, reading cutscene dialogue, or just inspecting recent chat without scrolling at the regular plate's font size.

## Toggling BigMode

- Slash command: `/fchat bigmode` — toggles BigMode on / off
- Keyboard shortcut: configurable in **Settings → Shortcuts**, but **disabled by default**

> All four keyboard shortcuts (Hide, BigMode, Tab cycle window 1, Tab cycle window 2) ship with the **Enabled** checkbox unticked. To use a shortcut you have to:
> 1. Open Settings → Shortcuts
> 2. Tick the **Enabled** checkbox for the shortcut
> 3. Pick a modifier key (Shift / Alt / Ctrl) and a main key (letter, `.`, `,`, `Tab`, `~`)
>
> Default key combos preset (but disabled): Hide = Shift+C, BigMode = Shift+G, Tab1 cycle = Shift+X, Tab2 cycle = Shift+B.

## What BigMode shows

- The same chat buffer as the primary chat window (current tab)
- Many more visible lines than the regular plate (sized to ~80% of screen height)
- Independent scroll cursor — switching back to the primary window doesn't disrupt your scroll position there

While BigMode is active the regular chat window is hidden. Toggle BigMode again to dismiss it and return to the normal layout.

## See also

- [The Chat Window](The-Chat-Window.md) — the regular plate that BigMode overlays
- [Commands & Shortcuts](Commands-and-Shortcuts.md) — full list of slash commands
- [Settings Reference → Shortcuts tab](Settings-Reference.md#shortcuts) — configuring keyboard shortcuts
