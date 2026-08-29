import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "propsuite.dell-input"
  ipcTarget: "propsuite.dell-input"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property string currentSource: ""
  property var displayOptions: [{ value: "auto", label: "Auto detect" }]
  property bool switching: false

  readonly property string helperPath: Qt.resolvedUrl("ddc-input").toString().replace("file://", "")
  readonly property string displayId: setting("displayId", "auto")
  readonly property string sourceA: setting("sourceA", "HDMI-1")
  readonly property string sourceB: setting("sourceB", "HDMI-2")
  readonly property string hotkey: setting("hotkey", "Disabled")
  readonly property var sourceOptions: ["HDMI-1", "HDMI-2", "DisplayPort"]
  readonly property var hotkeyOptions: ["SUPER + SHIFT + I", "SUPER + ALT + I", "CTRL + ALT + I", "Disabled"]
  readonly property var barIdentity: hostWidget || root

  function codeFor(name) {
    if (name === "DisplayPort") return "0f"
    if (name === "HDMI-1") return "11"
    if (name === "HDMI-2") return "12"
    return ""
  }

  function nameFor(code) {
    if (code === "0f") return "DisplayPort"
    if (code === "11") return "HDMI-1"
    if (code === "12") return "HDMI-2"
    return "Unavailable"
  }

  function open() {
    refresh()
    root.controller.show()
  }

  function refresh() {
    if (!readProc.running) readProc.running = true
    if (!displaysProc.running) displaysProc.running = true
  }

  function persistSettings(values) {
    var entry = { id: root.moduleName }
    for (var key in root.settings) if (key !== "id") entry[key] = root.settings[key]
    for (var changed in values) entry[changed] = values[changed]
    root.settings = entry
    if (root.hostWidget) root.hostWidget.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function setSourceA(value) {
    if (value === sourceB) persistSettings({ sourceA: value, sourceB: sourceA })
    else persistSettings({ sourceA: value })
  }

  function setSourceB(value) {
    if (value === sourceA) persistSettings({ sourceA: sourceB, sourceB: value })
    else persistSettings({ sourceB: value })
  }

  function toggleInput() {
    if (switching) return
    switching = true
    switchProc.running = true
  }

  Process {
    id: readProc
    command: [root.helperPath, "get"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const code = String(text || "").trim().toLowerCase()
        root.currentSource = /^(0f|11|12)$/.test(code) ? code : ""
        if (root.hostWidget) {
          root.hostWidget.sourceCode = root.currentSource
          root.hostWidget.sourceLabel = root.hostWidget.labelFor(root.currentSource)
        }
      }
    }
  }

  Process {
    id: displaysProc
    command: [root.helperPath, "displays"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var options = [{ value: "auto", label: "Auto detect" }]
        var lines = String(text || "").trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split("\t")
          if (parts.length >= 2) options.push({ value: parts[0], label: "Display " + parts[0] + " · " + parts.slice(1).join(" ") })
        }
        root.displayOptions = options
      }
    }
  }

  Process {
    id: switchProc
    command: [root.helperPath, "toggle"]
    onExited: function() {
      root.switching = false
      refreshDelay.restart()
    }
  }

  Timer { id: refreshDelay; interval: 900; onTriggered: root.refresh() }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: displayDropdown.popupOpen || sourceADropdown.popupOpen || sourceBDropdown.popupOpen || hotkeyDropdown.popupOpen
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      ScrollView {
        id: scrollArea
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: content.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

        Binding {
          target: scrollArea.contentItem
          property: "interactive"
          value: content.implicitHeight > scrollArea.height
        }

        Column {
          id: content
          width: scrollArea.availableWidth
          spacing: Style.space(12)

          Item {
            width: parent.width
            implicitHeight: Math.max(heroIcon.implicitHeight, heroText.implicitHeight)

            Text {
              id: heroIcon
              text: "󰍺"
              color: root.bar ? root.bar.foreground : Color.foreground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.display
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              id: heroText
              anchors.left: heroIcon.right
              anchors.leftMargin: Style.space(14)
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter

              Text {
                text: "Input Switcher"
                color: root.bar ? root.bar.foreground : Color.foreground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
              }
              Text {
                text: "CURRENT · " + root.nameFor(root.currentSource).toUpperCase()
                color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.1
              }
            }
          }

          Toggle {
            width: parent.width
            label: root.sourceA + "  ⇄  " + root.sourceB
            description: root.switching ? "Switching input…" : "Click anywhere on this row to switch"
            checked: root.currentSource === root.codeFor(root.sourceB)
            foreground: root.bar ? root.bar.foreground : Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onClicked: root.toggleInput()
          }

          PanelSeparator { width: parent.width; foreground: root.bar ? root.bar.foreground : Color.foreground }
          PanelSectionHeader { text: "SETTINGS"; foreground: root.bar ? root.bar.foreground : Color.foreground; fontFamily: root.bar ? root.bar.fontFamily : Style.font.family }

          Dropdown {
            id: displayDropdown
            width: parent.width
            label: "Monitor"
            value: root.displayId
            options: root.displayOptions
            foreground: root.bar ? root.bar.foreground : Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onChanged: function(value) { root.persistSettings({ displayId: value }); root.refresh() }
          }

          Row {
            width: parent.width
            spacing: Style.space(10)

            Dropdown {
              id: sourceADropdown
              width: (parent.width - parent.spacing) / 2
              label: "Source A"
              value: root.sourceA
              options: root.sourceOptions
              foreground: root.bar ? root.bar.foreground : Color.foreground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
              onChanged: function(value) { root.setSourceA(value) }
            }

            Dropdown {
              id: sourceBDropdown
              width: (parent.width - parent.spacing) / 2
              label: "Source B"
              value: root.sourceB
              options: root.sourceOptions
              foreground: root.bar ? root.bar.foreground : Color.foreground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
              onChanged: function(value) { root.setSourceB(value) }
            }
          }

          Dropdown {
            id: hotkeyDropdown
            width: parent.width
            label: "Global hotkey"
            value: root.hotkey
            options: root.hotkeyOptions
            foreground: root.bar ? root.bar.foreground : Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            onChanged: function(value) { root.persistSettings({ hotkey: value }) }
          }

          Text {
            width: parent.width
            text: "Settings save instantly. DDC/CI must be enabled in your monitor's on-screen menu."
            color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.5)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }
}
