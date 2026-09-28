#!/usr/bin/env bash
# scrcpy-phone-control — control an Android phone from this Linux desktop
# using the phone's real keyboard and mouse (scrcpy UHID mode).
#
# Opens a scrcpy window that is an INPUT SURFACE ONLY: no video is streamed, but
# the window still exists because scrcpy needs it to receive the shortcut-mod
# key that releases the mouse back to the PC. Do NOT pass --no-window here: with
# no window there is nothing to receive that key and the mouse stays trapped on
# the phone.
#
# To keep the (visually empty) window out of your way, add the rule from
# hypr/scrcpy-control.conf to your Hyprland config.
#
# Usage:
#   scrcpy-phone-control.sh            # start control mode
#   scrcpy-phone-control.sh --stop     # stop it
#   scrcpy-phone-control.sh --status   # report state, don't start
#
# Config (all optional):
#   SCRCPY_CONTROL_MOD   shortcut-mod that releases the mouse (default: lalt)
#   SCRCPY_SERIAL        target a specific device serial

set -uo pipefail

MOD="${SCRCPY_CONTROL_MOD:-lalt}"
LOG="${SCRCPY_CONTROL_LOG:-/tmp/scrcpy_controller.log}"

log() { printf '[scrcpy-control] %s\n' "$*"; }

# The bar widget detects a running instance with `pgrep -f '[s]crcpy --no-video'`
# and stops it the same way, so these two flag strings must stay in the cmdline.
running() { pgrep -f '[s]crcpy --no-video' >/dev/null 2>&1; }

case "${1:-}" in
  --stop)
    if running; then
      pkill -f '[s]crcpy --no-video' && log "stopped"
    else
      log "not running"
    fi
    exit 0
    ;;
  --status)
    running && { log "running"; exit 0; } || { log "stopped"; exit 1; }
    ;;
esac

if running; then
  log "already running (stop it first: $0 --stop)"
  exit 0
fi

for cmd in scrcpy adb python3; do
  command -v "$cmd" >/dev/null 2>&1 || { printf '[scrcpy-control] error: missing %s — see README (pacman -S --needed ...)\n' "$cmd" >&2; exit 1; }
done

# --- device must be present AND authorized ----------------------------------
# `unauthorized` means the USB-debugging prompt on the phone was not accepted.
device_line="$(adb devices -l 2>/dev/null | grep -m1 -E 'device( |$)' || true)"
if [ -z "$device_line" ]; then
  state="$(adb devices 2>/dev/null | awk 'NR==2{print $2}')"
  case "$state" in
    unauthorized) printf '[scrcpy-control] error: phone is unauthorized — accept the USB debugging prompt on the phone\n' >&2 ;;
    *)             printf '[scrcpy-control] error: no phone connected over USB\n' >&2 ;;
  esac
  exit 1
fi

model="$(printf '%s' "$device_line" | sed -n 's/.*model:\([^ ]*\).*/\1/p')"
log "device: ${model:-unknown}"

# --- launch -----------------------------------------------------------------
# Control-only: --no-video/--no-audio disable the streams, -K/-M enable UHID
# keyboard + mouse. --shortcut-mod is how you hand the mouse back to the PC.
#
# exec is required: it replaces this shell so the process cmdline becomes
# scrcpy's own, which is what the bar widget's pgrep/pkill matches on.
log "starting control mode (release the mouse with $MOD) — log: $LOG"
exec scrcpy --no-video --no-audio -K -M --shortcut-mod="$MOD" \
  ${SCRCPY_SERIAL:+-s "$SCRCPY_SERIAL"} 2>&1 | tee -a "$LOG"
