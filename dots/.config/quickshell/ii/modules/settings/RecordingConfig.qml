import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    property bool gsrAvailable: typeof GpuScreenRecorder !== "undefined" && GpuScreenRecorder.available
    property var recording: Config.options.recording

    property string captureValue: recording.gpuScreenRecorder.capture
    property string videoCodecValue: recording.gpuScreenRecorder.videoCodec
    property bool captureIsRegion: (captureValue || "").trim().startsWith("region")
    property bool captureIsPortal: (captureValue || "").trim().startsWith("portal")
    property bool captureIsFocused: (captureValue || "").trim().startsWith("focused")

    property bool codecSupportsHdr: ["hevc", "av1", "hevc_vulkan", "av1_vulkan"].includes(videoCodecValue)
    property bool hdrAllowed: codecSupportsHdr && !captureIsPortal
    property bool tenBitAllowed: codecSupportsHdr && !recording.gpuScreenRecorder.hdr
    property bool audioEnabled: (recording.gpuScreenRecorder.audioSources || "").trim().length > 0

    property var captureOptions: [
        {
            label: Translation.tr("Screen"),
            value: "screen"
        },
        {
            label: Translation.tr("Screen (direct)"),
            value: "screen-direct"
        },
        {
            label: Translation.tr("Focused window"),
            value: "focused"
        },
        {
            label: Translation.tr("Portal"),
            value: "portal"
        },
        {
            label: Translation.tr("Region"),
            value: "region"
        },
        {
            label: Translation.tr("Custom"),
            value: "__custom__"
        }
    ]

    property bool captureCustom: {
        const capture = (captureValue || "").trim();
        if (capture.length === 0)
            return false;
        return !captureOptions.some(option => option.value === capture && option.value !== "__custom__");
    }

    function ensureCaptureDefaults() {
        if ((recording.gpuScreenRecorder.capture || "").trim().length === 0) {
            recording.gpuScreenRecorder.capture = "screen";
        }
        if (!captureIsPortal) {
            recording.gpuScreenRecorder.restorePortalSession = false;
        }
        if (captureIsFocused && (recording.gpuScreenRecorder.resolution || "").trim().length === 0) {
            recording.gpuScreenRecorder.resolution = "0x0";
        }
    }

    function ensureCodecCompatibility() {
        if (!codecSupportsHdr) {
            recording.gpuScreenRecorder.hdr = false;
            recording.gpuScreenRecorder.bitDepth = "8";
            return;
        }
        if (!hdrAllowed) {
            recording.gpuScreenRecorder.hdr = false;
        }
        if (recording.gpuScreenRecorder.hdr) {
            recording.gpuScreenRecorder.bitDepth = "10";
        } else if (!tenBitAllowed) {
            recording.gpuScreenRecorder.bitDepth = "8";
        }
    }

    Component.onCompleted: {
        if (typeof GpuScreenRecorder !== "undefined") {
            GpuScreenRecorder.refreshAll();
        }
        ensureCaptureDefaults();
        ensureCodecCompatibility();
    }

    onCaptureValueChanged: {
        ensureCaptureDefaults();
        ensureCodecCompatibility();
    }

    onVideoCodecValueChanged: {
        ensureCodecCompatibility();
    }

    NoticeBox {
        Layout.fillWidth: true
        visible: !gsrAvailable
        materialIcon: "info"
        text: Translation.tr("gpu-screen-recorder is not installed. Install it to enable recording options.")
    }

    ContentSection {
        icon: "videocam"
        title: Translation.tr("Capture")
        opacity: gsrAvailable ? 1 : 0.5

        ContentSubsection {
            title: Translation.tr("What to record")
            tooltip: Translation.tr("Sets -w. Examples: screen, focused, portal, region, DP-1, /dev/video0, screen|/dev/video0")
            StyledComboBox {
                enabled: gsrAvailable
                textRole: "label"
                model: captureOptions
                currentIndex: {
                    const current = (recording.gpuScreenRecorder.capture || "").trim();
                    const index = model.findIndex(item => item.value === current);
                    return index !== -1 ? index : model.length - 1;
                }
                onActivated: index => {
                    const value = model[index].value;
                    if (value === "__custom__") {
                        return;
                    }
                    recording.gpuScreenRecorder.capture = value;
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable && captureCustom
                visible: captureCustom
                placeholderText: Translation.tr("Custom capture string")
                text: recording.gpuScreenRecorder.capture
                onTextChanged: {
                    if (captureCustom) {
                        recording.gpuScreenRecorder.capture = text;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Region geometry")
            tooltip: Translation.tr("Used with -w region. Format: WxH+X+Y")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable && captureIsRegion
                placeholderText: Translation.tr("1920x1080+0+0")
                text: recording.gpuScreenRecorder.region
                onTextChanged: {
                    recording.gpuScreenRecorder.region = text;
                }
            }
        }

        ConfigSwitch {
            enabled: gsrAvailable
            text: Translation.tr("Record cursor")
            checked: recording.gpuScreenRecorder.recordCursor
            onCheckedChanged: {
                recording.gpuScreenRecorder.recordCursor = checked;
            }
        }

        ConfigSwitch {
            enabled: gsrAvailable && captureIsPortal
            text: Translation.tr("Restore portal session")
            checked: recording.gpuScreenRecorder.restorePortalSession
            onCheckedChanged: {
                recording.gpuScreenRecorder.restorePortalSession = checked;
            }
        }
    }

    ContentSection {
        icon: "replay"
        title: Translation.tr("Replay buffer")
        opacity: gsrAvailable ? 1 : 0.5

        ConfigSpinBox {
            enabled: gsrAvailable
            icon: "timer"
            text: Translation.tr("Replay duration (seconds)")
            value: recording.gpuScreenRecorder.replaySeconds
            from: 2
            to: 86400
            stepSize: 1
            onValueChanged: {
                recording.gpuScreenRecorder.replaySeconds = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("Replay storage")
            tooltip: Translation.tr("Use RAM for fastest saves; disk may reduce SSD lifespan")
            StyledComboBox {
                enabled: gsrAvailable
                textRole: "label"
                model: [
                    {
                        label: Translation.tr("RAM"),
                        value: "ram"
                    },
                    {
                        label: Translation.tr("Disk"),
                        value: "disk"
                    }
                ]
                currentIndex: {
                    const index = model.findIndex(item => item.value === recording.gpuScreenRecorder.replayStorage);
                    return index !== -1 ? index : 0;
                }
                onActivated: index => {
                    recording.gpuScreenRecorder.replayStorage = model[index].value;
                }
            }
        }

        ConfigSwitch {
            enabled: gsrAvailable
            text: Translation.tr("Restart replay buffer after saving")
            checked: recording.gpuScreenRecorder.restartReplayOnSave
            onCheckedChanged: {
                recording.gpuScreenRecorder.restartReplayOnSave = checked;
            }
        }

        ConfigSwitch {
            enabled: gsrAvailable
            text: Translation.tr("Organize replays in date folders")
            checked: recording.gpuScreenRecorder.dateFolders
            onCheckedChanged: {
                recording.gpuScreenRecorder.dateFolders = checked;
            }
        }

        ContentSubsection {
            title: Translation.tr("Replay output path")
            tooltip: Translation.tr("Sets -o. For replay mode this should be a directory")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable
                placeholderText: Translation.tr("~/Videos")
                text: recording.gpuScreenRecorder.output
                onTextChanged: {
                    recording.gpuScreenRecorder.output = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Recording output directory")
            tooltip: Translation.tr("Sets -ro for regular recordings during replay/streaming")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable
                placeholderText: Translation.tr("Optional")
                text: recording.gpuScreenRecorder.outputRecordingDir
                onTextChanged: {
                    recording.gpuScreenRecorder.outputRecordingDir = text;
                }
            }
        }
    }

    ContentSection {
        icon: "movie"
        title: Translation.tr("Video")
        opacity: gsrAvailable ? 1 : 0.5

        ConfigSpinBox {
            enabled: gsrAvailable
            icon: "speed"
            text: Translation.tr("Frame rate (fps)")
            value: recording.gpuScreenRecorder.fps
            from: 1
            to: 240
            stepSize: 1
            onValueChanged: {
                recording.gpuScreenRecorder.fps = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("Frame rate mode")
            tooltip: Translation.tr("cfr: constant, vfr: variable, content: match content")
            StyledComboBox {
                enabled: gsrAvailable
                textRole: "label"
                model: [
                    {
                        label: Translation.tr("Variable (vfr)"),
                        value: "vfr"
                    },
                    {
                        label: Translation.tr("Constant (cfr)"),
                        value: "cfr"
                    },
                    {
                        label: Translation.tr("Content"),
                        value: "content"
                    }
                ]
                currentIndex: {
                    const index = model.findIndex(item => item.value === recording.gpuScreenRecorder.frameRateMode);
                    return index !== -1 ? index : 0;
                }
                onActivated: index => {
                    recording.gpuScreenRecorder.frameRateMode = model[index].value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Video codec")
            tooltip: Translation.tr("Base codec for -k. HDR and 10-bit options apply only to HEVC/AV1")
            StyledComboBox {
                enabled: gsrAvailable
                textRole: "label"
                model: [
                    {
                        label: Translation.tr("Auto"),
                        value: "auto"
                    },
                    {
                        label: "H.264",
                        value: "h264"
                    },
                    {
                        label: "HEVC",
                        value: "hevc"
                    },
                    {
                        label: "AV1",
                        value: "av1"
                    },
                    {
                        label: "VP8",
                        value: "vp8"
                    },
                    {
                        label: "VP9",
                        value: "vp9"
                    },
                    {
                        label: "H.264 (Vulkan)",
                        value: "h264_vulkan"
                    },
                    {
                        label: "HEVC (Vulkan)",
                        value: "hevc_vulkan"
                    },
                    {
                        label: "AV1 (Vulkan)",
                        value: "av1_vulkan"
                    }
                ]
                currentIndex: {
                    const index = model.findIndex(item => item.value === recording.gpuScreenRecorder.videoCodec);
                    return index !== -1 ? index : 0;
                }
                onActivated: index => {
                    recording.gpuScreenRecorder.videoCodec = model[index].value;
                    ensureCodecCompatibility();
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Bit depth")
            tooltip: Translation.tr("10-bit is only available for HEVC/AV1")
            StyledComboBox {
                enabled: gsrAvailable && tenBitAllowed
                textRole: "label"
                model: [
                    {
                        label: Translation.tr("8-bit"),
                        value: "8"
                    },
                    {
                        label: Translation.tr("10-bit"),
                        value: "10"
                    }
                ]
                currentIndex: {
                    const index = model.findIndex(item => item.value === recording.gpuScreenRecorder.bitDepth);
                    return index !== -1 ? index : 0;
                }
                onActivated: index => {
                    recording.gpuScreenRecorder.bitDepth = model[index].value;
                    if (model[index].value === "10" && !codecSupportsHdr) {
                        recording.gpuScreenRecorder.videoCodec = "hevc";
                    }
                    ensureCodecCompatibility();
                }
            }
        }

        ConfigSwitch {
            enabled: gsrAvailable && hdrAllowed
            text: Translation.tr("Enable HDR")
            checked: recording.gpuScreenRecorder.hdr
            onCheckedChanged: {
                if (checked && !codecSupportsHdr) {
                    recording.gpuScreenRecorder.videoCodec = "hevc";
                }
                recording.gpuScreenRecorder.hdr = checked;
                ensureCodecCompatibility();
            }
        }

        ContentSubsection {
            title: Translation.tr("Resolution limit")
            tooltip: Translation.tr("Sets -s. Use 0x0 for original resolution")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable
                placeholderText: Translation.tr("0x0")
                text: recording.gpuScreenRecorder.resolution
                onTextChanged: {
                    recording.gpuScreenRecorder.resolution = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Quality or bitrate")
            tooltip: Translation.tr("Use presets (medium, high, very_high, ultra) or bitrate for CBR")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable
                placeholderText: Translation.tr("very_high")
                text: recording.gpuScreenRecorder.quality
                onTextChanged: {
                    recording.gpuScreenRecorder.quality = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Bitrate mode")
            StyledComboBox {
                enabled: gsrAvailable
                textRole: "label"
                model: [
                    {
                        label: Translation.tr("Auto"),
                        value: "auto"
                    },
                    {
                        label: Translation.tr("QP"),
                        value: "qp"
                    },
                    {
                        label: Translation.tr("VBR"),
                        value: "vbr"
                    },
                    {
                        label: Translation.tr("CBR"),
                        value: "cbr"
                    }
                ]
                currentIndex: {
                    const index = model.findIndex(item => item.value === recording.gpuScreenRecorder.bitrateMode);
                    return index !== -1 ? index : 0;
                }
                onActivated: index => {
                    recording.gpuScreenRecorder.bitrateMode = model[index].value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Color range")
            StyledComboBox {
                enabled: gsrAvailable
                textRole: "label"
                model: [
                    {
                        label: Translation.tr("Limited"),
                        value: "limited"
                    },
                    {
                        label: Translation.tr("Full"),
                        value: "full"
                    }
                ]
                currentIndex: {
                    const index = model.findIndex(item => item.value === recording.gpuScreenRecorder.colorRange);
                    return index !== -1 ? index : 0;
                }
                onActivated: index => {
                    recording.gpuScreenRecorder.colorRange = model[index].value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Encoding tune")
            StyledComboBox {
                enabled: gsrAvailable
                textRole: "label"
                model: [
                    {
                        label: Translation.tr("Performance"),
                        value: "performance"
                    },
                    {
                        label: Translation.tr("Quality"),
                        value: "quality"
                    }
                ]
                currentIndex: {
                    const index = model.findIndex(item => item.value === recording.gpuScreenRecorder.tune);
                    return index !== -1 ? index : 0;
                }
                onActivated: index => {
                    recording.gpuScreenRecorder.tune = model[index].value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Keyframe interval (seconds)")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable
                placeholderText: Translation.tr("2.0")
                text: String(recording.gpuScreenRecorder.keyint)
                onTextChanged: {
                    const parsed = parseFloat(text);
                    if (!Number.isNaN(parsed)) {
                        recording.gpuScreenRecorder.keyint = parsed;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Encoder")
            tooltip: Translation.tr("CPU encoding only for H264")
            StyledComboBox {
                enabled: gsrAvailable
                textRole: "label"
                model: [
                    {
                        label: Translation.tr("GPU"),
                        value: "gpu"
                    },
                    {
                        label: Translation.tr("CPU"),
                        value: "cpu"
                    }
                ]
                currentIndex: {
                    const index = model.findIndex(item => item.value === recording.gpuScreenRecorder.encoder);
                    return index !== -1 ? index : 0;
                }
                onActivated: index => {
                    recording.gpuScreenRecorder.encoder = model[index].value;
                }
            }
        }

        ConfigSwitch {
            enabled: gsrAvailable
            text: Translation.tr("Fallback to CPU encoding")
            checked: recording.gpuScreenRecorder.fallbackCpuEncoding
            onCheckedChanged: {
                recording.gpuScreenRecorder.fallbackCpuEncoding = checked;
            }
        }

        ConfigSwitch {
            enabled: gsrAvailable
            text: Translation.tr("Low power mode")
            checked: recording.gpuScreenRecorder.lowPower
            onCheckedChanged: {
                recording.gpuScreenRecorder.lowPower = checked;
            }
        }

        ConfigSwitch {
            enabled: gsrAvailable
            text: Translation.tr("Write first frame timestamp file")
            checked: recording.gpuScreenRecorder.writeFirstFrameTs
            onCheckedChanged: {
                recording.gpuScreenRecorder.writeFirstFrameTs = checked;
            }
        }
    }

    ContentSection {
        icon: "volume_up"
        title: Translation.tr("Audio")
        opacity: gsrAvailable ? 1 : 0.5

        ContentSubsection {
            title: Translation.tr("Audio sources")
            tooltip: Translation.tr("Comma-separated list. Each entry becomes -a <source>. Leave empty to disable audio")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable
                placeholderText: Translation.tr("default_output,default_input")
                text: recording.gpuScreenRecorder.audioSources
                onTextChanged: {
                    recording.gpuScreenRecorder.audioSources = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Audio codec")
            StyledComboBox {
                enabled: gsrAvailable && audioEnabled
                textRole: "label"
                model: [
                    {
                        label: Translation.tr("Auto"),
                        value: "auto"
                    },
                    {
                        label: "AAC",
                        value: "aac"
                    },
                    {
                        label: "Opus",
                        value: "opus"
                    },
                    {
                        label: "FLAC",
                        value: "flac"
                    }
                ]
                currentIndex: {
                    const index = model.findIndex(item => item.value === recording.gpuScreenRecorder.audioCodec);
                    return index !== -1 ? index : 0;
                }
                onActivated: index => {
                    recording.gpuScreenRecorder.audioCodec = model[index].value;
                }
            }
        }

        ConfigSpinBox {
            enabled: gsrAvailable && audioEnabled
            icon: "graphic_eq"
            text: Translation.tr("Audio bitrate (kbps)")
            value: recording.gpuScreenRecorder.audioBitrate
            from: 0
            to: 1000
            stepSize: 16
            onValueChanged: {
                recording.gpuScreenRecorder.audioBitrate = value;
            }
        }
    }

    ContentSection {
        icon: "tune"
        title: Translation.tr("Advanced")
        opacity: gsrAvailable ? 1 : 0.5

        ContentSubsection {
            title: Translation.tr("Container format")
            StyledComboBox {
                enabled: gsrAvailable
                textRole: "label"
                model: [
                    {
                        label: "MP4",
                        value: "mp4"
                    },
                    {
                        label: "MKV",
                        value: "mkv"
                    },
                    {
                        label: "FLV",
                        value: "flv"
                    },
                    {
                        label: "WebM",
                        value: "webm"
                    }
                ]
                currentIndex: {
                    const index = model.findIndex(item => item.value === recording.gpuScreenRecorder.container);
                    return index !== -1 ? index : 0;
                }
                onActivated: index => {
                    recording.gpuScreenRecorder.container = model[index].value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Plugin paths")
            tooltip: Translation.tr("One path per line for -p")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable
                placeholderText: Translation.tr("/path/to/plugin.so")
                text: recording.gpuScreenRecorder.pluginPaths
                onTextChanged: {
                    recording.gpuScreenRecorder.pluginPaths = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Post-save script")
            tooltip: Translation.tr("Runs after save with filepath and type: regular, replay, screenshot")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable
                placeholderText: Translation.tr("/path/to/script.sh")
                text: recording.gpuScreenRecorder.scriptPath
                onTextChanged: {
                    recording.gpuScreenRecorder.scriptPath = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Portal session token path")
            tooltip: Translation.tr("Overrides the default token file path")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable
                placeholderText: Translation.tr("~/.config/gpu-screen-recorder/restore_token")
                text: recording.gpuScreenRecorder.portalSessionTokenPath
                onTextChanged: {
                    recording.gpuScreenRecorder.portalSessionTokenPath = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("FFmpeg options")
            tooltip: Translation.tr("Key=value;key=value list passed with -ffmpeg-opts")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable
                placeholderText: Translation.tr("hls_list_size=3;hls_time=1")
                text: recording.gpuScreenRecorder.ffmpegOpts
                onTextChanged: {
                    recording.gpuScreenRecorder.ffmpegOpts = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("FFmpeg video options")
            tooltip: Translation.tr("Key=value;key=value list passed with -ffmpeg-video-opts")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable
                placeholderText: Translation.tr("codec=cabac;rc_mode=CQP;qp=16")
                text: recording.gpuScreenRecorder.ffmpegVideoOpts
                onTextChanged: {
                    recording.gpuScreenRecorder.ffmpegVideoOpts = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("FFmpeg audio options")
            tooltip: Translation.tr("Key=value;key=value list passed with -ffmpeg-audio-opts")
            MaterialTextArea {
                Layout.fillWidth: true
                enabled: gsrAvailable
                placeholderText: Translation.tr("aac_coder=fast;aac_pce=true")
                text: recording.gpuScreenRecorder.ffmpegAudioOpts
                onTextChanged: {
                    recording.gpuScreenRecorder.ffmpegAudioOpts = text;
                }
            }
        }

        ConfigSwitch {
            enabled: gsrAvailable
            text: Translation.tr("OpenGL debug output")
            checked: recording.gpuScreenRecorder.glDebug
            onCheckedChanged: {
                recording.gpuScreenRecorder.glDebug = checked;
            }
        }

        ConfigSwitch {
            enabled: gsrAvailable
            text: Translation.tr("Verbose logging")
            checked: recording.gpuScreenRecorder.verbose
            onCheckedChanged: {
                recording.gpuScreenRecorder.verbose = checked;
            }
        }
    }
}
