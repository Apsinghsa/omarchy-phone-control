import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "apsingh.phone"

  // ---- Status state ----
  property bool phoneConnected: false
  property bool serviceRunning: false
  property string deviceModel: ""

  readonly property int pollIntervalMs: 3000

  readonly property string stateLabel: {
    if (!phoneConnected) return "No phone connected"
    if (!serviceRunning) return deviceModel + " ready"
    return "controlling " + deviceModel
  }

  // md-cellphone (smartphone) when running/connected; md-cellphone_off (crossed) when stopped.
  readonly property string displayText: root.serviceRunning ? "\uDB80\uDD1C" : "\uDB82\uDD50"

  // ---- Status polling ----
  component StatusProc: Process {
    readonly property string module: "apsingh.phone"
    stdout: StdioCollector {
      onStreamFinished: root.onStatusText(text.trim())
    }
  }
  property Component statusFactory: Component { StatusProc {} }

  function probe() {
    var p = statusFactory.createObject(root)
    p.command = ["sh", "-c",
      "dev=$(adb devices -l | grep -m1 'device usb:'); " +
      "if [ -n \"$dev\" ]; then " +
      "  m=$(echo \"$dev\" | sed -n 's/.*model:\\([^ ]*\\).*/\\1/p'); " +
      "  echo \"1|$m\"; " +
      "else echo '0|'; fi; " +
      "if pgrep -f '[s]crcpy --no-video' >/dev/null; then echo 1; else echo 0; fi"]
    p.running = true
  }

  function onStatusText(text) {
    var lines = text.split("\n")
    var dev = (lines.length > 0 ? lines[0] : "0|")
    var idx = dev.indexOf("|")
    phoneConnected = idx >= 0 ? dev.substring(0, idx) === "1" : false
    deviceModel = idx >= 0 ? dev.substring(idx + 1) : ""
    serviceRunning = lines.length > 1 ? lines[1] === "1" : false
    if (panelLoader.item && panelLoader.item.onStatus)
      panelLoader.item.onStatus(phoneConnected, serviceRunning, deviceModel)
  }

  Timer {
    interval: root.pollIntervalMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.probe()
  }

  // ---- Service control (called from the panel buttons) ----
  component ActionProc: Process {
    readonly property string module: "apsingh.phone"
    onExited: function(code) {
      if (code !== 0) console.warn("[phone] action exited", code)
    }
  }
  property Component actionFactory: Component { ActionProc {} }

  function runAction(cmd) {
    var p = actionFactory.createObject(root)
    p.command = ["sh", "-c", cmd]
    p.running = true
  }

  // Scripts are installed to ~/.local/bin by the README's install step and are
  // referenced through $HOME so this works for any user account.
  function startService() {
    runAction("nohup \"$HOME/.local/bin/scrcpy-phone-control\" >> \"${XDG_RUNTIME_DIR:-/tmp}/scrcpy_controller.log\" 2>&1 &")
    Qt.callLater(root.probe)
  }

  function stopService() {
    runAction("pkill -f '[s]crcpy --no-video'")
    Qt.callLater(root.probe)
  }

  // ---- Panel lifecycle (forward from entry point) ----
  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    visible: false
    source: Qt.resolvedUrl("Panel.qml")
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.displayText
    tooltipText: root.stateLabel + "\nClick: open phone control"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }
}