#!/usr/bin/env bash
##
##  install.sh -- install claudex-theme and wire it into the shell.
##
##  - installs the "claudex-theme" tool into PREFIX (default /usr/local/bin)
##  - runs it once so the theme is applied immediately
##  - ensures the shell alias:  c = claudex-theme && claudex --tmux --ase --recolor
##
##  Usage:   ./install.sh              # install to /usr/local/bin
##           PREFIX=~/.local/bin ./install.sh
##

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${PREFIX:-/usr/local/bin}"
ALIAS_LINE='alias c="claudex-theme && claudex --tmux --ase --recolor"'
RC="${ZDOTDIR:-$HOME}/.zprofile"

#   ==== 1) install the tool ====
mkdir -p "$PREFIX"
install -m 0755 "$SCRIPT_DIR/claudex-theme" "$PREFIX/claudex-theme"
echo "installed: $PREFIX/claudex-theme"

#   ==== 2) apply the theme now ====
if "$PREFIX/claudex-theme"; then
    echo "applied:   claudeX config patched (monochrome green)"
else
    echo "note:      claudeX not found yet -- theme will apply once installed" >&2
fi

#   ==== 3) ensure the shell alias ====
touch "$RC"
if grep -q 'claudex-theme && claudex' "$RC"; then
    echo "alias:     already present in $RC"
else
    if grep -qE '^[[:space:]]*alias c=.*claudex' "$RC"; then
        #  comment out a previous plain 'c' alias to avoid a duplicate
        sed -i '' -E 's|^([[:space:]]*alias c=.*claudex.*)|#\1|' "$RC"
        echo "alias:     commented out previous 'c' alias in $RC"
    fi
    printf '\n%s\n' "$ALIAS_LINE" >> "$RC"
    echo "alias:     added to $RC"
fi

echo
echo "done. Open a new terminal (or 'source $RC'), then start a fresh session:"
echo "    tmux kill-server   # drop old sessions still using the old colors"
echo "    c                  # = claudex-theme && claudex --tmux --ase --recolor"
