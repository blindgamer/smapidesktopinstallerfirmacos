# SMAPI Desktop Launcher

A one-click Stardew Valley + SMAPI shortcut for your macOS Desktop.

Double-click `SMAPI.app` and the game starts with SMAPI and all your mods
loaded, with a Terminal window alongside showing the SMAPI log.

> **Windows users:** you don't need this. Windows has it built in — see
> [Windows](#windows) below.

## Requirements

[SMAPI](https://smapi.io) must already be installed. This is only a shortcut;
it does not include SMAPI and cannot install it for you. The installer checks
and will tell you if SMAPI is missing.

## Install (macOS)

1. Download and unzip [`SMAPI-Desktop-Launcher.zip`](SMAPI-Desktop-Launcher.zip).
2. **Right-click** `install.command` and choose **Open**.
   Right-click the first time rather than double-clicking — macOS blocks
   double-clicked files that came from the internet.
3. If macOS warns it can't check the file for malicious software, click **Open**.
4. Read what it says it will do, then type `1` and press return.

`SMAPI.app` appears on your Desktop. Double-click it to play.

The first launch may show the same "unidentified developer" warning — right-click
`SMAPI.app`, choose Open, then Open again. Once only.

## Uninstall

Run `install.command` again and choose `2`. That deletes `SMAPI.app` and nothing
else. You can also just drag it to the Trash; it's only a shortcut.

For safety the uninstaller only removes a `SMAPI.app` that this installer
created — it checks for a marker in the app's `Info.plist`. If you made your own
app with that name, it leaves it alone and says so.

## What it does

- Puts `SMAPI.app` on your Desktop.
- Opens a Terminal window next to the game showing which mods loaded, warnings
  about broken or outdated mods, update notices, and crash details.
- Launches the game **directly, bypassing Steam** — the same as running
  `Contents/MacOS/StardewValley` by hand.

## What it does not do

It does not install, change, update or remove SMAPI, your mods, your saves, or
the game. It only adds or removes that one shortcut app.

## Steam

Because it bypasses Steam, launching with Steam closed means no Steam
achievements, overlay, or playtime tracking for that session. If Steam is
already running, all of that works normally. Launching from Steam also still
loads SMAPI, since SMAPI replaces the game bundle's executable.

## Finding the game

The installer checks the usual Steam and GOG locations and parses
`libraryfolders.vdf` for games kept on another drive. If it still can't find
Stardew Valley it asks you to drag the folder in — it accepts either the `.app`
or the `MacOS` folder inside it.

## Windows

This is a **macOS** installer and will not run on Windows. Windows already has
this built in:

1. Open your Stardew Valley folder — in Steam, right-click Stardew Valley →
   **Manage** → **Browse local files**.
2. Right-click `StardewModdingAPI.exe`.
3. Hover **Send to**.
4. Click **Desktop (create shortcut)**.

On Windows 11, click **Show more options** first if you don't see *Send to*.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| "can't be opened because it is from an unidentified developer" | Right-click → Open instead of double-clicking. |
| Installer can't find Stardew Valley | Drag the game folder into the Terminal window when it asks. |
| Installer says SMAPI is not installed | Install [SMAPI](https://smapi.io) first, then run it again. |
| Nothing happens on double-click | In Terminal: `chmod +x ` then drag `install.command` in, press return. |
| I want Steam achievements | Start Steam and leave it running, then launch `SMAPI.app`. |
