# Phone Control — Omarchy bar widget

An [Omarchy](https://omarchy.org/) bar widget that puts your Android phone in the
scratchpad and lets you drive it with the mouse and keyboard, over USB, with no
network involved.

Left-click the bar icon to summon or hide the scrcpy capture window. Open the panel
to start or stop scrcpy. The bar icon reflects live state — phone disconnected,
phone ready, or actively controlling — polled every 3 seconds.

Input is injected via **scrcpy UHID**, so the phone treats the desktop mouse as a real
touchscreen and the desktop keyboard as a real keyboard. Press and hold **Left Alt**
to release the mouse back to the PC without lifting your hand.

![Omarchy bar widget](https://img.shields.io/badge/Omarchy-shell--widget-8250DF)

## Requirements

| Dependency | Arch package | Why |
| --- | --- | --- |
| `scrcpy` | `extra/scrcpy` | Screen capture + UHID input injection |
| `adb` | `extra/android-tools` | USB transport to the phone |
| Android USB debugging | — | Enabled on the phone itself |

Install the dependencies:

```bash
sudo pacman -S scrcpy android-tools
```

On the phone: enable **USB debugging** in Developer Options, plug it in, and accept
the RSA prompt. Confirm the connection with:

```bash
adb devices -l
```

The widget shows the connected model name once `adb` reports `device usb:`.

## Install

```bash
omarchy plugin add https://github.com/Apsinghsa/omarchy-phone-control
```

Then restart the shell so the compiled bar widget is picked up:

```bash
omarchy restart shell
```

A compiled third-party bar widget does **not** hot-reload — `omarchy-shell
rescanPlugins` will not replace already-compiled code, so the restart is required.

### Install the helper scripts

The bar widget's Start/Stop buttons call `~/.local/bin/scrcpy-phone-control`.
Link it from the cloned plugin directory — no path editing needed:

```bash
~/.config/omarchy/plugins/apsingh.phone/scripts/install.sh
```

or by hand:

```bash
mkdir -p ~/.local/bin
ln -sf ~/.config/omarchy/plugins/apsingh.phone/scripts/scrcpy-phone-control.sh \
        ~/.local/bin/scrcpy-phone-control
```

### Optional: hide the control window

Control-only mode leaves an empty window mapped, because scrcpy needs it to
capture the mouse. To shrink it and make it nearly invisible, add to your
Hyprland config (`~/.config/hypr/hyprland.conf`):

```conf
source = ~/.config/omarchy/plugins/apsingh.phone/hypr/scrcpy-control.conf
```

It stays focusable, which it must be.

To remove the plugin:

```bash
omarchy plugin remove apsingh.phone
```

## Usage

1. Click the phone icon in the bar to open the panel.
2. **Start scrcpy** — enabled only when a phone is connected and scrcpy is not already
   running.
3. Press **Super+S** to open the scratchpad and select the scrcpy window.
4. Use the mouse and keyboard on the phone. Hold **Left Alt** to hand the mouse back
   to the PC.
5. **Stop scrcpy** — enabled only while it is running.

## The helper script

Start/Stop shell out to `~/.local/bin/scrcpy-phone-control`, which wraps scrcpy
in control-only mode:

```bash
scrcpy --no-video --no-audio -K -M --shortcut-mod=lalt
```

`--no-video`/`--no-audio` drop the streams, `-K`/`-M` enable UHID keyboard and
mouse. The script `exec`s scrcpy so the process command line becomes scrcpy's
own — that is what the widget's `pgrep`/`pkill` match on.

**It deliberately does not pass `--no-window`.** That flag is not the same as
`--no-video`: it removes the window entirely, and with no window there is
nothing to receive the shortcut-mod key, so the mouse can never be released
back to the PC.

You can also drive it directly:

```bash
scrcpy-phone-control          # start
scrcpy-phone-control --status # is it running?
scrcpy-phone-control --stop   # stop
```

| Variable | Default | Meaning |
| --- | --- | --- |
| `SCRCPY_CONTROL_MOD` | `lalt` | key that releases the mouse (`lalt`, `rsuper`, `lctrl`, …) |
| `SCRCPY_CONTROL_LOG` | `$XDG_RUNTIME_DIR/scrcpy_controller.log` | log file |
| `SCRCPY_SERIAL` | *(auto)* | pin to one device when several are attached |

`Left Alt` avoids colliding with Omarchy's own `SUPER,KEY` bindings. If it
interferes, try `rsuper` or `lctrl`.

### Behaviour notes

- UHID mouse is **relative mode**: the desktop pointer disappears while the
  phone is captured. Expected, not a bug.
- In UHID mode the click bindings are **inverted** versus normal scrcpy —
  right-click sends BACK, middle-click sends HOME. Remap with
  `--mouse-bind=xxxx:xxxx`.
- scrcpy removes its server from the device on exit, so there is nothing to
  clean up between sessions.
- A `WARN: Could not set window icon` line in the log is cosmetic.

## Files

| File | Role |
| --- | --- |
| `manifest.json` | Plugin manifest — id, entry points, bar widget metadata |
| `Widget.qml` | Bar button, 3s status poll, start/stop service control |
| `Panel.qml` | Drawer panel — status line, Start/Stop buttons, usage hint |
| `scripts/scrcpy-phone-control.sh` | Wraps scrcpy in control-only mode |
| `scripts/install.sh` | Links the script into `~/.local/bin` |
| `hypr/scrcpy-control.conf` | Optional rule to shrink/hide the control window |

## How the status probe works

Every 3 seconds the widget runs a single shell command and reads two lines back:

```sh
adb devices -l | grep -m1 'device usb:'   # → connection + model
pgrep -f '[s]crcpy --no-video'           # → is the service alive
```

The `[s]` bracket in the `pgrep` pattern is deliberate — without it the pattern
matches `pgrep`'s own command line and the check always reports true.

## License

MIT — see [LICENSE](LICENSE).
