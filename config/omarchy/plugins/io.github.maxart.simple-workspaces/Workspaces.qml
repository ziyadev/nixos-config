import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.maxart.simple-workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property color dotColor: root.bar ? root.bar.barForeground : Color.foreground
  readonly property real dotSize: Style.spaceReal(8)
  readonly property real clickTargetSize: Style.space(14)
  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: root.vertical ? root.barSize : grid.implicitWidth + root.trailingGap
  implicitHeight: root.vertical ? grid.implicitHeight : root.barSize

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(2)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      Item {
        id: workspaceTarget
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null
          && workspace.toplevels !== null
          && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null
          && Hyprland.focusedWorkspace.id === modelData

        implicitWidth: root.vertical ? root.barSize : root.clickTargetSize
        implicitHeight: root.vertical ? root.clickTargetSize : root.barSize
        Layout.alignment: Qt.AlignCenter

        Rectangle {
          anchors.centerIn: parent
          width: root.dotSize
          height: root.dotSize
          radius: width / 2
          color: root.dotColor
          opacity: workspaceTarget.focused ? 1.0 : (workspaceTarget.occupied ? 0.2 : 0.1)
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.focusWorkspace(workspaceTarget.modelData)
        }
      }
    }
  }
}
