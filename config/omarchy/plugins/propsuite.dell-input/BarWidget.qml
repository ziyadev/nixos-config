import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "propsuite.dell-input"

  readonly property string helperPath: Qt.resolvedUrl("ddc-input").toString().replace("file://", "")
  readonly property string displayId: setting("displayId", "auto")
  readonly property string sourceA: setting("sourceA", "HDMI-1")
  readonly property string sourceB: setting("sourceB", "HDMI-2")
  readonly property string hotkey: setting("hotkey", "Disabled")
  property string sourceCode: ""
  property string sourceLabel: "…"

  function labelFor(code) {
    switch (String(code).toLowerCase()) {
      case "0f": return "DP"
      case "11": return "H1"
      case "12": return "H2"
      default: return "?"
    }
  }

  function refresh() {
    if (!readProc.running) readProc.running = true
    if (panelLoader.item && panelLoader.item.refresh) panelLoader.item.refresh()
  }

  function configure() {
    if (configureProc.running) return
    configureProc.command = [helperPath, "configure", displayId, sourceA, sourceB, hotkey]
    configureProc.running = true
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
    target.currentSource = root.sourceCode
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: {
    injectPanel()
    configureDelay.restart()
  }
  onSourceCodeChanged: injectPanel()
  Component.onCompleted: configureDelay.restart()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "propsuite.dell-input"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
    function refresh(): void { root.refresh() }
  }

  Process {
    id: readProc
    command: [root.helperPath, "get"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const code = String(text || "").trim().toLowerCase()
        root.sourceCode = /^(0f|11|12)$/.test(code) ? code : ""
        root.sourceLabel = root.labelFor(root.sourceCode)
      }
    }
  }

  Process { id: configureProc }

  Timer {
    id: configureDelay
    interval: 250
    onTriggered: root.configure()
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍺 " + root.sourceLabel
    fontSize: Style.font.caption
    horizontalMargin: 7
    tooltipText: "Monitor input · click for controls"
    onPressed: function() { root.togglePanel() }
  }
}
