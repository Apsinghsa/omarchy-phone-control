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

To remove it:

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

## Known limitation: the start script

The widget's **Start** / **Stop** buttons shell out to a helper script:

```
/home/apsingh/Documents/Hermes/scrcpy-phone-control.sh
```

That path is hardcoded and is specific to the machine this was developed on. If you
clone this repo, either create that script at that path or edit the `startService()`
function in `Widget.qml` to point at your own. The bar icon, status polling and panel
work without it — only the Start/Stop buttons depend on it.

## Files

| File | Role |
| --- | --- |
| `manifest.json` | Plugin manifest — id, entry points, bar widget metadata |
| `Widget.qml` | Bar button, 3s status poll, start/stop service control |
| `Panel.qml` | Drawer panel — status line, Start/Stop buttons, usage hint |

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
