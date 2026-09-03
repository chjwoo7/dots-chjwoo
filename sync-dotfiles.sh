#!/usr/bin/env bash
# Copy the live configuration into dotfiles/ so it can be committed alongside
# the shell. Run this after changing anything under ~/.config, then commit.
#
#   ./sync-dotfiles.sh && git add dotfiles && git commit -m "sync dotfiles"

set -euo pipefail
cd "$(dirname "$0")"
DEST="dotfiles"

# Directories under ~/.config that are configuration (not application data)
DIRS=(
    hypr illogical-impulse fish zshrc.d kitty fuzzel wlogout cava
    matugen Kvantum gtk-3.0 gtk-4.0 kdedefaults mpv micro spicetify
    xsettingsd qalculate xdg-desktop-portal
)
# Files at the top of $HOME
FILES=(.bashrc .zshrc .bash_profile .gtkrc-2.0)

rm -rf "$DEST/config" "$DEST/home"
mkdir -p "$DEST/config" "$DEST/home" "$DEST/system"

for d in "${DIRS[@]}"; do
    src="$HOME/.config/$d"
    [ -d "$src" ] || continue
    # Backups and the installer manifest are noise, not configuration.
    rsync -a --exclude '*.bak' --exclude '*.bak-*' --exclude '*.old' \
             --exclude 'installed_listfile' \
             "$src/" "$DEST/config/$d/"
done

for f in "${FILES[@]}"; do
    [ -f "$HOME/$f" ] && cp "$HOME/$f" "$DEST/home/$f"
done

# Root-owned, so it is kept here as the source to install from.
cp /etc/udev/rules.d/60-ideapad-conservation.rules "$DEST/system/" 2>/dev/null || true

echo "Synced $(find "$DEST" -type f | wc -l) files into $DEST/"
