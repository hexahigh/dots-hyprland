pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    minimumWidth: 340
    minimumHeight: 180

    property int replayBufferSeconds: Config.options.recording.gpuScreenRecorder.replaySeconds

    Component.onCompleted: {
        GpuScreenRecorder.refreshAll();
    }

    contentItem: OverlayBackground {
        id: contentItem
        radius: root.contentRadius
        property real padding: 8
        ColumnLayout {
            id: contentColumn
            anchors.centerIn: parent
            spacing: 10

            Row {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                spacing: 10

                BigRecorderButton {
                    materialSymbol: "screenshot_region"
                    name: "Screenshot region"
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"]);
                    }
                }

                BigRecorderButton {
                    materialSymbol: "photo_camera"
                    name: "Screenshot"
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached(["bash", "-c", "grim - | wl-copy"]);
                    }
                }

                BigRecorderButton {
                    materialSymbol: "screen_record"
                    name: "Record region"
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "recordWithSound"]);
                    }
                }

                BigRecorderButton {
                    materialSymbol: "capture"
                    name: "Record screen"
                    onClicked: {
                        GlobalStates.overlayOpen = false;
                        Quickshell.execDetached([Directories.recordScriptPath, "--fullscreen", "--sound"]);
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                spacing: 8

                BigRecorderButton {
                    materialSymbol: GpuScreenRecorder.replayActive ? "stop_circle" : "replay"
                    name: GpuScreenRecorder.replayActive ? "Disable replay buffer" : "Enable replay buffer"
                    toggled: GpuScreenRecorder.replayActive
                    enabled: GpuScreenRecorder.available && root.replayBufferSeconds >= 2
                    onClicked: {
                        GpuScreenRecorder.toggleReplay();
                    }
                }

                ReplaySaveButton {
                    label: "10s"
                    seconds: 10
                    tooltipText: "Save last 10 seconds"
                }
                ReplaySaveButton {
                    label: "30s"
                    seconds: 30
                    tooltipText: "Save last 30 seconds"
                }
                ReplaySaveButton {
                    label: "60s"
                    seconds: 60
                    tooltipText: "Save last 60 seconds"
                }
                ReplaySaveButton {
                    label: "5m"
                    seconds: 300
                    tooltipText: "Save last 5 minutes"
                }
            }

            RippleButton {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.fillWidth: false
                buttonRadius: height / 2
                colBackground: Appearance.colors.colLayer3
                colBackgroundHover: Appearance.colors.colLayer3Hover
                colRipple: Appearance.colors.colLayer3Active
                onClicked: {
                    GlobalStates.overlayOpen = false;
                    const replayPath = Config.options.recording.gpuScreenRecorder.output;
                    const targetPath = replayPath.length > 0 ? replayPath : Config.options.screenRecord.savePath;
                    Qt.openUrlExternally(`file://${targetPath}`);
                }
                contentItem: Row {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "animated_images"
                        iconSize: 20
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Open recordings folder")
                    }
                }
            }
        }
    }

    component BigRecorderButton: RippleButton {
        id: bigButton
        required property string materialSymbol
        required property string name
        implicitHeight: 66
        implicitWidth: 66
        buttonRadius: height / 2

        colBackground: Appearance.colors.colLayer3
        colBackgroundHover: Appearance.colors.colLayer3Hover
        colRipple: Appearance.colors.colLayer3Active

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: bigButton.materialSymbol
            iconSize: 28
        }

        StyledToolTip {
            text: bigButton.name
        }
    }

    component ReplaySaveButton: RippleButton {
        id: replayButton
        required property string label
        required property int seconds
        required property string tooltipText
        implicitHeight: 40
        implicitWidth: 52
        buttonRadius: height / 2

        enabled: GpuScreenRecorder.available && GpuScreenRecorder.replayActive && root.replayBufferSeconds >= replayButton.seconds

        colBackground: Appearance.colors.colLayer3
        colBackgroundHover: Appearance.colors.colLayer3Hover
        colRipple: Appearance.colors.colLayer3Active

        contentItem: StyledText {
            anchors.fill: parent
            text: replayButton.label
            color: Appearance.colors.colOnLayer3
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: {
            GlobalStates.overlayOpen = false;
            GpuScreenRecorder.saveReplay(replayButton.seconds);
        }

        StyledToolTip {
            text: replayButton.tooltipText
        }
    }
}
