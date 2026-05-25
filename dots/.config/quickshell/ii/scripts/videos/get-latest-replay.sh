#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"

get_json() {
	jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null
}

trim() {
	local value="$1"
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	printf '%s' "$value"
}

read_replay_dir() {
	local output
	output=$(get_json '.recording.gpuScreenRecorder.output')

	if [[ -z "$output" ]]; then
		output=$(get_json '.screenRecord.savePath')
	fi

	if [[ -z "$output" ]]; then
		output="$HOME/Videos"
	fi

	# Normalize any file:// prefix and expand a leading ~
	output="${output#file://}"
	if [[ "$output" == "~"* ]]; then
		output="$HOME${output:1}"
	fi

	output="$(realpath -m -- "$output")"

	printf '%s' "$output"
}

replay_dir="$(read_replay_dir)"

if [[ ! -d "$replay_dir" ]]; then
	printf '%s\n' "$replay_dir" >&2
	exit 1
fi

latest_replay="$(find "$replay_dir" -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' \) -printf '%T@\t%p\n' 2>/dev/null | sort -nr | head -n 1 | cut -f2- || true)"

if [[ -z "$latest_replay" ]]; then
	exit 1
fi

printf '%s\n' "$latest_replay"
