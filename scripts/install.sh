#!/usr/bin/env bash
# Link this plugin's helper scripts into ~/.local/bin so the bar widget can find
# them. Safe to re-run.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="$HOME/.local/bin"

mkdir -p "$target"
for s in scrcpy-phone-control.sh; do
  ln -sf "$here/$s" "$target/${s%.sh}"
  echo "linked $target/${s%.sh} -> $here/$s"
done

echo
echo "Done. Restart the shell for the bar widget to pick up changes:"
echo "  omarchy restart shell"
echo
echo "Optional — hide the (empty) scrcpy window, add to your Hyprland config:"
echo "  source = ~/.config/omarchy/plugins/apsingh.phone/hypr/scrcpy-control.conf"
