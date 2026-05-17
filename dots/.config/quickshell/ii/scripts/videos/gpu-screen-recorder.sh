#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Recorder"
CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
GSR_BIN="gpu-screen-recorder"
REPLAY_LOG="/tmp/gpu-screen-recorder-replay.log"

notify() {
    notify-send "$1" "$2" -a "$APP_NAME" & disown
}

get_json() {
    jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null
}

trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

bool_to_yesno() {
    case "$1" in
        true|1|yes|on) printf '%s' "yes" ;;
        *) printf '%s' "no" ;;
    esac
}

is_running() {
    pgrep -f "^${GSR_BIN}" >/dev/null 2>&1
}

require_binary() {
    if ! command -v "$GSR_BIN" >/dev/null 2>&1; then
        notify "Replay buffer unavailable" "gpu-screen-recorder is not installed"
        exit 1
    fi
}

read_config() {
    capture=$(get_json '.recording.gpuScreenRecorder.capture')
    region=$(get_json '.recording.gpuScreenRecorder.region')
    output=$(get_json '.recording.gpuScreenRecorder.output')
    output_recording_dir=$(get_json '.recording.gpuScreenRecorder.outputRecordingDir')
    container=$(get_json '.recording.gpuScreenRecorder.container')
    fps=$(get_json '.recording.gpuScreenRecorder.fps')
    resolution=$(get_json '.recording.gpuScreenRecorder.resolution')
    record_cursor=$(get_json '.recording.gpuScreenRecorder.recordCursor')
    restore_portal=$(get_json '.recording.gpuScreenRecorder.restorePortalSession')
    audio_sources=$(get_json '.recording.gpuScreenRecorder.audioSources')
    audio_codec=$(get_json '.recording.gpuScreenRecorder.audioCodec')
    audio_bitrate=$(get_json '.recording.gpuScreenRecorder.audioBitrate')
    video_codec=$(get_json '.recording.gpuScreenRecorder.videoCodec')
    bit_depth=$(get_json '.recording.gpuScreenRecorder.bitDepth')
    hdr=$(get_json '.recording.gpuScreenRecorder.hdr')
    quality=$(get_json '.recording.gpuScreenRecorder.quality')
    bitrate_mode=$(get_json '.recording.gpuScreenRecorder.bitrateMode')
    frame_rate_mode=$(get_json '.recording.gpuScreenRecorder.frameRateMode')
    color_range=$(get_json '.recording.gpuScreenRecorder.colorRange')
    tune=$(get_json '.recording.gpuScreenRecorder.tune')
    keyint=$(get_json '.recording.gpuScreenRecorder.keyint')
    encoder=$(get_json '.recording.gpuScreenRecorder.encoder')
    fallback_cpu=$(get_json '.recording.gpuScreenRecorder.fallbackCpuEncoding')
    replay_seconds=$(get_json '.recording.gpuScreenRecorder.replaySeconds')
    replay_storage=$(get_json '.recording.gpuScreenRecorder.replayStorage')
    restart_replay_on_save=$(get_json '.recording.gpuScreenRecorder.restartReplayOnSave')
    date_folders=$(get_json '.recording.gpuScreenRecorder.dateFolders')
    plugin_paths=$(get_json '.recording.gpuScreenRecorder.pluginPaths')
    script_path=$(get_json '.recording.gpuScreenRecorder.scriptPath')
    portal_token=$(get_json '.recording.gpuScreenRecorder.portalSessionTokenPath')
    ffmpeg_opts=$(get_json '.recording.gpuScreenRecorder.ffmpegOpts')
    ffmpeg_video_opts=$(get_json '.recording.gpuScreenRecorder.ffmpegVideoOpts')
    ffmpeg_audio_opts=$(get_json '.recording.gpuScreenRecorder.ffmpegAudioOpts')
    gl_debug=$(get_json '.recording.gpuScreenRecorder.glDebug')
    verbose=$(get_json '.recording.gpuScreenRecorder.verbose')
    low_power=$(get_json '.recording.gpuScreenRecorder.lowPower')
    write_first_frame_ts=$(get_json '.recording.gpuScreenRecorder.writeFirstFrameTs')

    if [[ -z "$output" ]]; then
        output=$(get_json '.screenRecord.savePath')
    fi

    if [[ -z "$output" ]]; then
        output="$HOME/Videos"
    fi

    output="${output#file://}"

    capture=${capture:-screen}
    resolution=${resolution:-0x0}
    fps=${fps:-60}
    replay_seconds=${replay_seconds:-60}
    bit_depth=${bit_depth:-8}
    video_codec=${video_codec:-auto}
    quality=${quality:-very_high}
    bitrate_mode=${bitrate_mode:-auto}
    frame_rate_mode=${frame_rate_mode:-vfr}
    color_range=${color_range:-limited}
    tune=${tune:-performance}
    encoder=${encoder:-gpu}
    replay_storage=${replay_storage:-ram}
    audio_codec=${audio_codec:-auto}
    audio_bitrate=${audio_bitrate:-0}
    record_cursor=${record_cursor:-true}
    restore_portal=${restore_portal:-false}
    fallback_cpu=${fallback_cpu:-false}
    restart_replay_on_save=${restart_replay_on_save:-false}
    date_folders=${date_folders:-false}
    gl_debug=${gl_debug:-false}
    verbose=${verbose:-true}
    low_power=${low_power:-false}
    write_first_frame_ts=${write_first_frame_ts:-false}

    if ! [[ "$replay_seconds" =~ ^[0-9]+$ ]]; then
        replay_seconds=60
    fi

    if ! [[ "$fps" =~ ^[0-9]+$ ]]; then
        fps=""
    fi

    if ! [[ "$audio_bitrate" =~ ^[0-9]+$ ]]; then
        audio_bitrate=0
    fi
}

build_args() {
    args=()

    args+=("-w" "$capture")

    if [[ -n "$region" ]]; then
        args+=("-region" "$region")
    fi

    if [[ -n "$container" && "$container" != "auto" ]]; then
        args+=("-c" "$container")
    fi

    if [[ -n "$resolution" ]]; then
        args+=("-s" "$resolution")
    fi

    if [[ -n "$fps" ]]; then
        args+=("-f" "$fps")
    fi

    args+=("-cursor" "$(bool_to_yesno "$record_cursor")")
    args+=("-restore-portal-session" "$(bool_to_yesno "$restore_portal")")

    if [[ -n "$audio_sources" ]]; then
        IFS=$',;|\n' read -r -a audio_source_list <<< "$audio_sources"
        for source in "${audio_source_list[@]}"; do
            source="$(trim "$source")"
            [[ -n "$source" ]] && args+=("-a" "$source")
        done
    fi

    if [[ -n "$audio_codec" && "$audio_codec" != "auto" ]]; then
        args+=("-ac" "$audio_codec")
    fi

    if [[ -n "$audio_bitrate" && "$audio_bitrate" != "0" ]]; then
        args+=("-ab" "$audio_bitrate")
    fi

    local selected_codec="$video_codec"

    if [[ "$hdr" == "true" ]]; then
        case "$selected_codec" in
            hevc) selected_codec="hevc_hdr" ;;
            av1) selected_codec="av1_hdr" ;;
            hevc_vulkan) selected_codec="hevc_hdr_vulkan" ;;
            av1_vulkan) selected_codec="av1_hdr_vulkan" ;;
        esac
    elif [[ "$bit_depth" == "10" ]]; then
        case "$selected_codec" in
            hevc) selected_codec="hevc_10bit" ;;
            av1) selected_codec="av1_10bit" ;;
            hevc_vulkan) selected_codec="hevc_10bit_vulkan" ;;
            av1_vulkan) selected_codec="av1_10bit_vulkan" ;;
        esac
    fi

    if [[ -n "$selected_codec" ]]; then
        args+=("-k" "$selected_codec")
    fi

    if [[ -n "$quality" ]]; then
        args+=("-q" "$quality")
    fi

    if [[ -n "$bitrate_mode" ]]; then
        args+=("-bm" "$bitrate_mode")
    fi

    if [[ -n "$frame_rate_mode" ]]; then
        args+=("-fm" "$frame_rate_mode")
    fi

    if [[ -n "$color_range" ]]; then
        args+=("-cr" "$color_range")
    fi

    if [[ -n "$tune" ]]; then
        args+=("-tune" "$tune")
    fi

    if [[ -n "$keyint" ]]; then
        args+=("-keyint" "$keyint")
    fi

    if [[ -n "$encoder" ]]; then
        args+=("-encoder" "$encoder")
    fi

    args+=("-fallback-cpu-encoding" "$(bool_to_yesno "$fallback_cpu")")

    args+=("-r" "$replay_seconds")

    if [[ -n "$replay_storage" ]]; then
        args+=("-replay-storage" "$replay_storage")
    fi

    args+=("-restart-replay-on-save" "$(bool_to_yesno "$restart_replay_on_save")")
    args+=("-df" "$(bool_to_yesno "$date_folders")")

    if [[ -n "$output_recording_dir" ]]; then
        args+=("-ro" "$output_recording_dir")
    fi

    if [[ -n "$plugin_paths" ]]; then
        while IFS= read -r plugin_path; do
            plugin_path="$(trim "$plugin_path")"
            [[ -n "$plugin_path" ]] && args+=("-p" "$plugin_path")
        done < <(printf '%s' "$plugin_paths" | tr ';' '\n')
    fi

    if [[ -n "$script_path" ]]; then
        args+=("-sc" "$script_path")
    fi

    if [[ -n "$portal_token" ]]; then
        args+=("-portal-session-token-filepath" "$portal_token")
    fi

    if [[ -n "$ffmpeg_opts" ]]; then
        args+=("-ffmpeg-opts" "$ffmpeg_opts")
    fi

    if [[ -n "$ffmpeg_video_opts" ]]; then
        args+=("-ffmpeg-video-opts" "$ffmpeg_video_opts")
    fi

    if [[ -n "$ffmpeg_audio_opts" ]]; then
        args+=("-ffmpeg-audio-opts" "$ffmpeg_audio_opts")
    fi

    args+=("-gl-debug" "$(bool_to_yesno "$gl_debug")")
    args+=("-v" "$(bool_to_yesno "$verbose")")
    args+=("-low-power" "$(bool_to_yesno "$low_power")")
    args+=("-write-first-frame-ts" "$(bool_to_yesno "$write_first_frame_ts")")

    args+=("-o" "$output")
}

start_replay() {
    require_binary

    if is_running; then
        notify "Replay buffer" "Already running"
        return 0
    fi

    read_config

    if [[ -z "$capture" ]]; then
        notify "Replay buffer failed" "Capture source is empty"
        return 1
    fi

    if [[ "$replay_seconds" -lt 2 ]]; then
        notify "Replay buffer failed" "Replay duration must be at least 2 seconds"
        return 1
    fi

    mkdir -p "$output"

    if [[ -n "$output_recording_dir" ]]; then
        mkdir -p "$output_recording_dir"
    fi

    build_args

    : > "$REPLAY_LOG"
    setsid -f "$GSR_BIN" "${args[@]}" >"$REPLAY_LOG" 2>&1

    sleep 0.3

    if is_running; then
        notify "Replay buffer enabled" "Duration: ${replay_seconds}s"
    else
        local error_tail
        error_tail=$(tail -n 4 "$REPLAY_LOG" 2>/dev/null | tr '\n' ' ')
        if [[ -n "$error_tail" ]]; then
            notify "Replay buffer failed" "$error_tail"
        else
            notify "Replay buffer failed" "gpu-screen-recorder exited"
        fi
        return 1
    fi
}

stop_replay() {
    if ! is_running; then
        notify "Replay buffer" "Not running"
        return 1
    fi

    pkill -SIGINT -f "^${GSR_BIN}" >/dev/null 2>&1 || true
    notify "Replay buffer stopped" "Stopped"
}

save_replay() {
    require_binary

    local seconds="${1:-}"
    local signal=""
    local label=""

    case "$seconds" in
        10) signal="SIGRTMIN+1"; label="10 seconds" ;;
        30) signal="SIGRTMIN+2"; label="30 seconds" ;;
        60) signal="SIGRTMIN+3"; label="60 seconds" ;;
        300|5m) signal="SIGRTMIN+4"; label="5 minutes" ;;
        "") signal="SIGUSR1"; label="replay" ;;
        *)
            notify "Replay save failed" "Unsupported duration: $seconds"
            return 1
            ;;
    esac

    if pkill -"$signal" -f "^${GSR_BIN}" >/dev/null 2>&1; then
        notify "Replay saved" "Saved last ${label}"
    else
        notify "Replay save failed" "Replay buffer is not running"
        return 1
    fi
}

usage() {
    cat <<EOF
Usage: $0 <toggle|start|stop|save>

Commands:
  toggle  Start or stop replay buffer
  start   Start replay buffer
  stop    Stop replay buffer
  save    Save replay (defaults to full buffer)
EOF
}

command="${1:-}"

case "$command" in
    toggle)
        if is_running; then
            stop_replay
        else
            start_replay
        fi
        ;;
    start)
        start_replay
        ;;
    stop)
        stop_replay
        ;;
    save)
        save_replay "${2:-}"
        ;;
    *)
        usage
        exit 1
        ;;
esac
