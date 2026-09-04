#!/usr/bin/env bash
# Set this fork up on top of an existing illogical-impulse install.
#
#   ./install.sh                wire up the shell: select it in Hyprland, put the
#                               ChjwooUtils widget in the bar, install the udev
#                               rule if the hardware has conservation mode
#   ./install.sh --full         also restore the rest of the rice from dotfiles/
#                               (kitty, fish, GTK, hypr, ~/.bashrc, ...)
#   ./install.sh --no-restart   leave the running shell alone
#
# Everything here is idempotent: running it twice changes nothing the second
# time. Anything it overwrites is copied to ~/dots-chjwoo-backup-<timestamp>/
# first.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="$(basename "$REPO")"
QS_DIR="$HOME/.config/quickshell"
II_CONFIG="$HOME/.config/illogical-impulse/config.json"
HYPR_CUSTOM="$HOME/.config/hypr/custom"
BACKUP="$HOME/dots-chjwoo-backup-$(date +%Y%m%d-%H%M%S)"
RULE="$REPO/dotfiles/system/60-ideapad-conservation.rules"

FULL=0
RESTART=1
for arg in "$@"; do
    case "$arg" in
        --full)       FULL=1 ;;
        --no-restart) RESTART=0 ;;
        -h|--help)    sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 0 ;;
        *)            echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
    esac
done

step() { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
same() { printf '  \033[90m·\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
die()  { printf '\n\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# Copy a file or directory into the backup tree, keeping its path under $HOME.
backup() {
    [ -e "$1" ] || return 0
    local rel="${1#"$HOME"/}"
    mkdir -p "$BACKUP/$(dirname "$rel")"
    cp -a "$1" "$BACKUP/$(dirname "$rel")/"
}

step "Checking the ground"

[ "$(dirname "$REPO")" = "$QS_DIR" ] || die \
    "this repository has to live in $QS_DIR (it is in $REPO).
    Quickshell resolves a config by folder name, so move or re-clone it there."

command -v qs >/dev/null || die \
    "quickshell (qs) not found. This fork replaces the Quickshell config only —
    install illogical-impulse first: https://github.com/end-4/dots-hyprland"
ok "quickshell found"

command -v jq >/dev/null || die "jq is needed to edit the bar layout. Install it and re-run."

missing=()
for c in satty grim slurp wl-copy; do command -v "$c" >/dev/null || missing+=("$c"); done
if [ ${#missing[@]} -gt 0 ]; then
    warn "missing for the snip button: ${missing[*]}"
    warn "the shell still runs; install them when convenient"
else
    ok "screenshot tools present (satty, grim, slurp, wl-copy)"
fi

step "1. Selecting this config in Hyprland"

mkdir -p "$HYPR_CUSTOM"
vars="$HYPR_CUSTOM/variables.lua"
line="hl.env(\"qsConfig\", \"$NAME\")"

if [ ! -f "$vars" ]; then
    printf '%s\n' \
        '-- Overrides for ~/.config/hypr/hyprland/variables.lua' \
        '-- Sourced by hyprland/keybinds.lua when this file exists.' \
        '' \
        "$line" > "$vars"
    ok "created $vars"
elif grep -q "hl\.env(\"qsConfig\", \"$NAME\")" "$vars"; then
    same "$vars already selects $NAME"
elif grep -q 'hl\.env("qsConfig"' "$vars"; then
    backup "$vars"
    sed -i -E "s|^([[:space:]]*)hl\.env\(\"qsConfig\".*|\1$line|" "$vars"
    ok "repointed $vars to $NAME"
else
    backup "$vars"
    printf '\n%s\n' "$line" >> "$vars"
    ok "appended the qsConfig override to $vars"
fi

step "2. Putting the ChjwooUtils widget in the bar"

filter='.bar.layouts.rightLayout = ((.bar.layouts.rightLayout // ["sysTray","utilButtons","systemIcons","powerButton"])
          | if index("chjwooUtils") then . else
              reduce .[] as $w ([]; . + [$w] + (if $w == "utilButtons" then ["chjwooUtils"] else [] end))
            end)'

if [ ! -f "$II_CONFIG" ]; then
    mkdir -p "$(dirname "$II_CONFIG")"
    echo '{}' | jq "$filter" > "$II_CONFIG"
    ok "created $II_CONFIG with the widget in the bar layout"
elif ! jq -e . "$II_CONFIG" >/dev/null 2>&1; then
    die "could not parse $II_CONFIG as JSON"
elif jq -e '(.bar.layouts.rightLayout // []) | index("chjwooUtils")' "$II_CONFIG" >/dev/null; then
    # Checked semantically rather than by comparing files: jq would reformat the
    # whole config on the way through, which looks like a change and is not one.
    same "chjwooUtils is already in the bar layout"
else
    tmp="$(mktemp)"
    jq "$filter" "$II_CONFIG" > "$tmp"
    backup "$II_CONFIG"
    cat "$tmp" > "$II_CONFIG"   # keep the original inode; the shell watches this file
    rm -f "$tmp"
    ok "added chjwooUtils to bar.layouts.rightLayout"
fi

step "3. Battery conservation mode"

attr="$(ls /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode 2>/dev/null | head -n1 || true)"
if [ -z "$attr" ]; then
    same "no conservation_mode on this machine — the button will hide itself"
elif [ -w "$attr" ]; then
    same "$attr is already writable"
else
    device="$(basename "$(dirname "$attr")")"
    id -nG | tr ' ' '\n' | grep -qx wheel || warn \
        "you are not in the 'wheel' group; the rule grants access to it (usermod -aG wheel $USER, then log back in)"

    tmp_rule="$(mktemp)"
    if [ "$device" != "VPC2004:00" ]; then
        warn "device is $device, not VPC2004:00 — adjusting the rule to match"
        sed "s/VPC2004:00/$device/g" "$RULE" > "$tmp_rule"
        warn "ChjwooUtils.qml hardcodes the same name; edit conservationPath there too"
    else
        cat "$RULE" > "$tmp_rule"
    fi

    echo "  installing the udev rule needs root:"
    sudo install -m 644 "$tmp_rule" /etc/udev/rules.d/60-ideapad-conservation.rules
    rm -f "$tmp_rule"
    sudo udevadm control --reload
    sudo udevadm trigger -c bind -s platform

    if [ -w "$attr" ]; then
        ok "$attr is writable now"
    else
        warn "still not writable. If you were just added to 'wheel', log out and back in."
        warn "until then the button shows a padlock instead of a toggle."
    fi
fi

if [ "$FULL" = 1 ]; then
    step "4. Restoring the rest of the rice from dotfiles/"
    warn "this overwrites live configuration; a copy goes to $BACKUP/"

    for src in "$REPO"/dotfiles/config/*; do
        [ -e "$src" ] || continue
        backup "$HOME/.config/$(basename "$src")"
    done
    cp -r "$REPO"/dotfiles/config/. "$HOME/.config/"
    ok "copied dotfiles/config into ~/.config"

    for src in "$REPO"/dotfiles/home/.[!.]*; do
        [ -f "$src" ] || continue
        backup "$HOME/$(basename "$src")"
    done
    cp -r "$REPO"/dotfiles/home/. "$HOME/"
    ok "copied dotfiles/home into ~"

    warn "some of those files are personal, not portable — see the README:"
    warn "wallpaper, lock screen and recording paths point at /home/chjwoo"
fi

if [ "$RESTART" = 1 ]; then
    step "Restarting the shell"
    killall qs 2>/dev/null || true
    sleep 1
    setsid qs -c "$NAME" >/dev/null 2>&1 < /dev/null &
    disown || true
    ok "running: qs -c $NAME"
fi

step "Done"
if [ -d "$BACKUP" ]; then echo "  replaced files were backed up to $BACKUP/"; fi
cat <<TXT
  Hyprland reads qsConfig at startup, so the selection above becomes permanent
  at your next login. Reload the shell any time with CTRL + SUPER + R.
TXT
