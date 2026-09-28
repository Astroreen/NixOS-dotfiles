import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: shell

    property int rawLevel: 0
    // Ignore the mic's noise floor so the meter only reacts to real voice.
    property int level: Math.max(0, Math.round((rawLevel - 60) * 100 / 40))
    property string state: "idle"
    property bool active: state !== "idle"

    readonly property string statePath: Quickshell.env("XDG_RUNTIME_DIR") + "/dictation.state"

    // Live input level via cava (raw ascii, one bar).
    Process {
        id: cava
        running: shell.active
        command: ["cava", "-p", Quickshell.shellPath("cava.conf")]
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.split(";")[0]);
                if (!isNaN(value))
                    shell.rawLevel = value;
            }
        }
    }

    // Daemon state file (idle / listening / transcribing).
    FileView {
        id: stateView
        path: shell.statePath
        watchChanges: true
        onFileChanged: stateView.reload()
        onTextChanged: {
            const text = stateView.text().trim();
            shell.state = text.length > 0 ? text : "idle";
        }
    }

    PanelWindow {
        id: panel
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        margins.bottom: 64
        implicitHeight: 56
        color: "transparent"
        visible: shell.active

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.centerIn: parent
            width: content.implicitWidth + 40
            height: 44
            radius: 22
            color: "#e61e1e2e"
            border.width: 1
            border.color: "#40c0c0c0"

            RowLayout {
                id: content
                anchors.centerIn: parent
                spacing: 14

                Text {
                    text: shell.state === "transcribing" ? "󰔟" : "󰍬"
                    color: shell.state === "transcribing" ? "#f9e2af" : "#a6e3a1"
                    font.pixelSize: 22
                    font.family: "Material Symbols Outlined"
                }

                // Level meter: 12 bars driven by the single cava value.
                Row {
                    spacing: 3
                    Repeater {
                        model: 12
                        Rectangle {
                            required property int index
                            width: 4
                            height: 6 + Math.max(0, shell.level) * 0.22
                            radius: 2
                            color: shell.level * 12 > index ? "#a6e3a1" : "#45475a"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Text {
                    text: shell.state === "transcribing" ? "Transcribing…" : "Listening…"
                    color: "#cdd6f4"
                    font.pixelSize: 14
                    font.family: "sans-serif"
                }
            }
        }
    }
}