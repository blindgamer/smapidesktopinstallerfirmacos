#!/bin/bash
#
# SMAPI Desktop Launcher - installer for macOS
#
# Creates a double-clickable SMAPI.app on your Desktop that launches
# Stardew Valley with SMAPI, going straight to the game's own SMAPI
# launcher and bypassing Steam.
#

APP_PATH="$HOME/Desktop/SMAPI.app"
MARKER_KEY="SMAPIDesktopLauncher"
GAME_DIR=""

rule() { printf '%s\n' "------------------------------------------------------------"; }
say()  { printf '%s\n' "$*"; }

finish() {
    say ""
    say "Press return to close this window."
    read -r _
    exit "${1:-0}"
}

# ------------------------------------------------------------------
# Find the Stardew Valley game folder
# ------------------------------------------------------------------
find_game_dir() {
    local candidates=() c lib vdf

    candidates+=("$HOME/Library/Application Support/Steam/steamapps/common/Stardew Valley/Contents/MacOS")
    candidates+=("/Applications/Stardew Valley.app/Contents/MacOS")
    candidates+=("$HOME/Applications/Stardew Valley.app/Contents/MacOS")
    candidates+=("$HOME/Library/Application Support/GOG.com/Stardew Valley/Stardew Valley.app/Contents/MacOS")
    candidates+=("/Applications/Stardew Valley/Stardew Valley.app/Contents/MacOS")

    # any extra Steam library folders the user has set up
    vdf="$HOME/Library/Application Support/Steam/steamapps/libraryfolders.vdf"
    if [ -f "$vdf" ]; then
        while IFS= read -r lib; do
            [ -n "$lib" ] && candidates+=("$lib/steamapps/common/Stardew Valley/Contents/MacOS")
        done < <(grep -o '"path"[[:space:]]*"[^"]*"' "$vdf" 2>/dev/null | sed 's/.*"path"[[:space:]]*"//; s/"$//')
    fi

    for c in "${candidates[@]}"; do
        if [ -f "$c/Stardew Valley.dll" ] || [ -f "$c/Stardew Valley" ]; then
            printf '%s' "$c"
            return 0
        fi
    done
    return 1
}

ask_for_game_dir() {
    local input
    say "I couldn't find Stardew Valley automatically."
    say ""
    say "Drag your Stardew Valley folder into this window and press return,"
    say "or just press return to give up."
    say "(In Steam: right-click Stardew Valley > Manage > Browse local files.)"
    say ""
    printf 'Folder: '
    read -r input
    input="${input%\'}"; input="${input#\'}"          # strip quotes Terminal adds when you drag
    input="$(printf '%s' "$input" | sed 's/[[:space:]]*$//')"
    [ -z "$input" ] && return 1

    # accept either the .app itself or the MacOS folder inside it
    if [ -f "$input/Contents/MacOS/Stardew Valley.dll" ]; then
        GAME_DIR="$input/Contents/MacOS"; return 0
    fi
    if [ -f "$input/Stardew Valley.dll" ] || [ -f "$input/Stardew Valley" ]; then
        GAME_DIR="$input"; return 0
    fi
    return 1
}

# ------------------------------------------------------------------
# Icon: use the best square image we can find for this game
# ------------------------------------------------------------------
build_icon() {
    local dest="$1" src="" best=0 cands=() c w app tmp spec px name

    [ -f "$GAME_DIR/../Resources/App.icns" ] && cands+=("$GAME_DIR/../Resources/App.icns")

    # a Steam-created desktop shortcut for Stardew (app 413150) carries a much
    # sharper 256px icon than the one inside the game bundle
    for app in "$HOME/Desktop"/*.app; do
        [ -d "$app" ] || continue
        if grep -qs "steam://run/413150" "$app/Contents/MacOS/run.sh" 2>/dev/null; then
            [ -f "$app/Contents/Resources/shortcut.icns" ] && cands+=("$app/Contents/Resources/shortcut.icns")
        fi
    done

    [ ${#cands[@]} -eq 0 ] && return 1

    for c in "${cands[@]}"; do
        w=$(sips -g pixelWidth "$c" 2>/dev/null | awk '/pixelWidth/{print $2}')
        [ -z "$w" ] && continue
        if [ "$w" -gt "$best" ]; then best="$w"; src="$c"; fi
    done
    [ -z "$src" ] && return 1

    tmp="$(mktemp -d)" || return 1
    if ! sips -s format png "$src" --out "$tmp/base.png" >/dev/null 2>&1; then
        rm -rf "$tmp"; return 1
    fi
    mkdir -p "$tmp/icon.iconset"
    for spec in "16:icon_16x16.png" "32:icon_16x16@2x.png" "32:icon_32x32.png" \
                "64:icon_32x32@2x.png" "128:icon_128x128.png" "256:icon_128x128@2x.png" \
                "256:icon_256x256.png"; do
        px="${spec%%:*}"; name="${spec#*:}"
        sips -z "$px" "$px" "$tmp/base.png" --out "$tmp/icon.iconset/$name" >/dev/null 2>&1
    done
    if ! iconutil -c icns "$tmp/icon.iconset" -o "$dest" >/dev/null 2>&1; then
        cp "$src" "$dest" 2>/dev/null
    fi
    rm -rf "$tmp"
    return 0
}

# ------------------------------------------------------------------
# Install / uninstall
# ------------------------------------------------------------------
do_install() {
    rm -rf "$APP_PATH"
    mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources" || return 1

    cat > "$APP_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>SMAPI</string>
	<key>CFBundleDisplayName</key>
	<string>SMAPI</string>
	<key>CFBundleIdentifier</key>
	<string>local.launcher.smapi</string>
	<key>CFBundleExecutable</key>
	<string>run.sh</string>
	<key>CFBundleIconFile</key>
	<string>SMAPI.icns</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>1.0</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>LSMinimumSystemVersion</key>
	<string>10.13</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>$MARKER_KEY</key>
	<true/>
</dict>
</plist>
PLIST

    {
        printf '%s\n' '#!/bin/bash'
        printf '%s\n' '#'
        printf '%s\n' '# SMAPI desktop launcher for Stardew Valley (macOS).'
        printf '%s\n' '# Created by the SMAPI Desktop Launcher installer.'
        printf '%s\n' '#'
        printf '%s\n' '# Goes straight to the game folder0s own SMAPI launcher, bypassing Steam.'
        printf '%s\n' '#'
        printf '\n'
        printf 'GAME_DIR=%q\n' "$GAME_DIR"
        cat <<'BODY'

die() {
    osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with icon stop with title \"SMAPI Launcher\"" >/dev/null 2>&1
    exit 1
}

# make sure the game folder and SMAPI are still where we left them
[ -d "$GAME_DIR" ] || die "Can't find the Stardew Valley game folder.\n\n$GAME_DIR\n\nIf you moved or reinstalled the game, run the installer again."
[ -x "$GAME_DIR/StardewModdingAPI" ] || die "SMAPI isn't installed in the game folder.\n\nInstall SMAPI from https://smapi.io, then run the installer again."

# hand off to a real Terminal window: SMAPI needs a TTY to show its console
LAUNCHER="/tmp/run-smapi.command"
{
    echo '#!/bin/bash'
    printf 'cd %q || exit 1\n' "$GAME_DIR"
    if [ -x "$GAME_DIR/StardewValley" ]; then
        echo './StardewValley'
    else
        echo './StardewModdingAPI'
    fi
} > "$LAUNCHER"
chmod +x "$LAUNCHER"

open -a Terminal "$LAUNCHER"

# tidy up the scratch file once Terminal has picked it up
( sleep 20; rm -f "$LAUNCHER" ) >/dev/null 2>&1 &

exit 0
BODY
    } > "$APP_PATH/Contents/MacOS/run.sh"

    # the apostrophe can't survive the quoted block above; put it back
    sed -i '' "s/folder0s/folder's/" "$APP_PATH/Contents/MacOS/run.sh"

    chmod +x "$APP_PATH/Contents/MacOS/run.sh" || return 1

    if build_icon "$APP_PATH/Contents/Resources/SMAPI.icns"; then
        :
    else
        # no usable source image; drop the icon key so macOS uses the default
        sed -i '' '/<key>CFBundleIconFile<\/key>/,+1d' "$APP_PATH/Contents/Info.plist"
    fi

    touch "$APP_PATH"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -f "$APP_PATH" >/dev/null 2>&1
    xattr -dr com.apple.quarantine "$APP_PATH" >/dev/null 2>&1
    return 0
}

do_uninstall() {
    if [ ! -d "$APP_PATH" ]; then
        say "There's no SMAPI.app on your Desktop, so there's nothing to remove."
        return 0
    fi
    if ! grep -q "$MARKER_KEY" "$APP_PATH/Contents/Info.plist" 2>/dev/null; then
        say "There's a SMAPI.app on your Desktop, but this installer didn't create it."
        say "Leaving it alone to be safe - delete it yourself if you want it gone."
        return 1
    fi
    rm -rf "$APP_PATH" && say "Removed $APP_PATH" || { say "Couldn't remove it."; return 1; }
    return 0
}

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------
clear 2>/dev/null
rule
say "  SMAPI Desktop Launcher - installer for macOS"
rule
say ""
say "WHAT THIS DOES"
say ""
say "  It puts an app called SMAPI.app on your Desktop. Double-click it"
say "  and Stardew Valley starts with SMAPI and all your mods loaded."
say ""
say "  It opens a Terminal window alongside the game so you can see"
say "  SMAPI's log: which mods loaded, any warnings, and update alerts."
say ""
say "  It launches the game directly and does NOT go through Steam."
say "  If Steam isn't running you won't get Steam achievements, the"
say "  overlay, or playtime tracking for that session."
say ""
say "WHAT IT DOES NOT DO"
say ""
say "  It does not install, change, update or remove SMAPI, your mods,"
say "  your saves, or the game itself. It only adds (or removes) that"
say "  one shortcut app on your Desktop."
say ""
rule
say ""

# --- locate the game ---
say "Looking for Stardew Valley..."
if GAME_DIR="$(find_game_dir)"; then
    say "  Found: $GAME_DIR"
else
    say ""
    if ! ask_for_game_dir; then
        say ""
        say "No Stardew Valley folder, so there's nothing to do."
        finish 1
    fi
    say "  Using: $GAME_DIR"
fi
say ""

# --- check SMAPI ---
SMAPI_OK=0
if [ -x "$GAME_DIR/StardewModdingAPI" ]; then
    SMAPI_OK=1
    say "SMAPI is installed."
else
    say "SMAPI is NOT installed."
    say ""
    say "  This app is only a shortcut - it needs SMAPI to already be set up."
    say "  Install SMAPI first:"
    say ""
    say "      https://smapi.io"
    say ""
    say "  Download it, run the SMAPI installer, then run this installer again."
fi
say ""

if [ -d "$APP_PATH" ] && grep -q "$MARKER_KEY" "$APP_PATH/Contents/Info.plist" 2>/dev/null; then
    say "Current status: SMAPI.app IS on your Desktop."
else
    say "Current status: SMAPI.app is not on your Desktop yet."
fi
say ""
rule
say ""
say "What would you like to do?"
say ""
if [ "$SMAPI_OK" -eq 1 ]; then
    say "   1) Install    - put SMAPI.app on my Desktop"
else
    say "   1) Install    - unavailable until SMAPI is installed"
fi
say "   2) Uninstall  - remove SMAPI.app from my Desktop"
say "   3) Quit       - do nothing"
say ""
printf 'Enter 1, 2 or 3: '
read -r choice
say ""

case "$choice" in
    1)
        if [ "$SMAPI_OK" -ne 1 ]; then
            say "Can't install yet - please install SMAPI from https://smapi.io first,"
            say "then run this installer again. Nothing has been changed."
            finish 1
        fi
        if do_install; then
            say "Done. SMAPI.app is on your Desktop - double-click it to play."
            say ""
            say "If macOS says it can't check the app for malicious software,"
            say "right-click it and choose Open, then click Open again."
        else
            say "Something went wrong while creating the app. Nothing else was changed."
            finish 1
        fi
        ;;
    2)
        do_uninstall || finish 1
        ;;
    *)
        say "Nothing was changed."
        ;;
esac

finish 0
