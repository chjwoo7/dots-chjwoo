#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

term_alpha=100 #Set this to < 100 make all your terminals transparent
# sleep 0 # idk i wanted some delay or colors dont get applied properly
if [ ! -d "$STATE_DIR"/user/generated ]; then
  mkdir -p "$STATE_DIR"/user/generated
fi
cd "$CONFIG_DIR" || exit

colornames=''
colorstrings=''
colorlist=()
colorvalues=()

colornames=$(cat $STATE_DIR/user/generated/material_colors.scss | cut -d: -f1)
colorstrings=$(cat $STATE_DIR/user/generated/material_colors.scss | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
IFS=$'\n'
colorlist=($colornames)     # Array of color names
colorvalues=($colorstrings) # Array of color values

# One sed program for every colour, instead of one whole-file rewrite each.
# The " #" the patterns end on is what keeps $term1 from matching $term10.
build_color_sed_script() {
  local script=""
  for i in "${!colorlist[@]}"; do
    script+="s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g;"
  done
  printf '%s' "$script"
}

# Render a template into place without the result ever being observable
# half-finished. Substituting into the live file left it holding raw
# placeholders for the length of the run, so a second colour change reloading
# a terminal at the wrong moment handed it a file full of "$term0 #". Writing
# to a temporary and renaming is atomic: a reader gets the old file or the new
# one, never something in between.
render_template() {
  local template="$1" target="$2" extra_sed="${3:-}"
  local tmp script
  tmp=$(mktemp "$target.XXXXXX") || return 1
  # Built as one string rather than conditional -e arguments: IFS is a newline
  # here, so an unquoted expansion holding a space would not split the way it
  # reads like it should.
  script="$(build_color_sed_script)"
  [ -n "$extra_sed" ] && script="$script$extra_sed;"
  if ! sed -e "$script" "$template" > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  chmod 0644 "$tmp"        # mktemp makes it 0600; keep what cp used to leave
  mv -f "$tmp" "$target" || { rm -f "$tmp"; return 1; }
}

apply_kitty() {  
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/kitty-theme.conf" ]; then
    echo "Template file not found for Kitty theme. Skipping that."
    return
  fi
  mkdir -p "$STATE_DIR"/user/generated/terminal
  render_template "$SCRIPT_DIR/terminal/kitty-theme.conf" \
                  "$STATE_DIR/user/generated/terminal/kitty-theme.conf" || return

  # Reload. pidof separates pids with spaces, but IFS is a newline here for the
  # colour arrays, so word splitting cannot be relied on -- and with no kitty
  # running the old form called kill with no arguments at all.
  pidof kitty 2>/dev/null | xargs -r kill -SIGUSR1 2>/dev/null
}

apply_anyterm() {
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/sequences.txt" ]; then
    echo "Template file not found for Terminal. Skipping that."
    return
  fi
  mkdir -p "$STATE_DIR"/user/generated/terminal
  # Same atomic rename as the kitty theme, and it matters more here: this file
  # is written straight into every pty, so a half-substituted one would spray
  # literal "$term0 #" into the user's terminals.
  render_template "$SCRIPT_DIR/terminal/sequences.txt" \
                  "$STATE_DIR/user/generated/terminal/sequences.txt" \
                  "s/\$alpha/$term_alpha/g" || return

  for file in /dev/pts/*; do
    if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
      {
      cat "$STATE_DIR"/user/generated/terminal/sequences.txt >"$file"
      } & disown || true
    fi
  done
}

apply_term() {
  apply_kitty
  apply_anyterm
}

apply_qt() {
  sh "$CONFIG_DIR/scripts/kvantum/materialQT.sh"          # generate kvantum theme
  python "$CONFIG_DIR/scripts/kvantum/changeAdwColors.py" # apply config colors
}

# Check if terminal theming is enabled in config
CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
if [ -f "$CONFIG_FILE" ]; then
  enable_terminal=$(jq -r '.appearance.wallpaperTheming.enableTerminal' "$CONFIG_FILE")
  if [ "$enable_terminal" = "true" ]; then
    apply_term &
  fi
else
  echo "Config file not found at $CONFIG_FILE. Applying terminal theming by default."
  apply_term &
fi

# apply_qt & # Qt theming is already handled by kde-material-colors
