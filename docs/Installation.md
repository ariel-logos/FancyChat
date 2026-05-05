# Installation

## Requirements

- A working [Ashita v4](https://www.ashitaxi.com/) installation pointed at your FFXI client.
- Windows (the addon ships a Windows-only `gdifonttexture.dll` for its custom font rendering).

## Steps

1. Grab the latest archive from the [Releases page](https://github.com/ariel-logos/Fancychat/releases).
2. Extract the contents into your Ashita install's `Ashita/addons/` folder. After extraction you should see a `fancychat/` subfolder next to your other addons.
3. Launch FFXI through Ashita as you normally would.
4. In game, type:
   ```
   /addon load fancychat
   ```
   The Fancychat plate will appear in the top-left of the screen. From there, type `/fchat manual` to open the in-game manual or `/fchat settings` to configure.

## Auto-loading on every launch

If you want Fancychat to load automatically at every game launch, add `/addon load fancychat` to your Ashita default script. In Ashita Boot's profile editor, that's the **Default Script** field.

## Updating

Replace the contents of the `fancychat/` folder with the new release. Your settings, palette, notepad, and combat-filter files live in subfolders that the new version preserves — see [Data Storage](Data-Storage.md).

## Uninstall

Delete the `fancychat/` folder from `Ashita/addons/`. Your per-character settings persist under `Ashita/config/addons/fancychat/<character>/` until you remove that folder too.

## See also

- [Compatibility](Compatibility.md) — which addons can NOT be loaded alongside Fancychat
- [Troubleshooting](Troubleshooting.md) — what to do if the chat plate doesn't appear
