#!/bin/bash
#
# Distributed under the terms of the BSD License
#
# Copyright (c) 2021, Konstantin Nazarov <mail@knazarov.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -e

if [[ -z "$Q_SCRIPT_DIR" ]]; then
	Q_SCRIPT_DIR=~/.config/q.sh
fi

SELF="$0"

INDEX_FILE=~/.q.index
HINT_FILE=~/.q.hints

new_scripts_exist() {
	if [[ ! -d "$Q_SCRIPT_DIR" ]]; then
		return 0
	fi

	if [[ ! -s "$INDEX_FILE" ]]; then
		return 0
	fi

	NEWER_FILES="$(find "$Q_SCRIPT_DIR" -name "q-*" -newer "$INDEX_FILE")"

	if [[ -z "$NEWER_FILES" ]]; then
		return 1
	fi

	return 0
}

rebuild_index() {
	if [[ ! -d "$Q_SCRIPT_DIR" ]]; then
		return
	fi

	pushd "$Q_SCRIPT_DIR" >/dev/null
	find . -type f -name 'q-*' | while read -r FN
	do
		FILENAME="$(echo "$FN" | sed 's/^\.\///g')"

		"$Q_SCRIPT_DIR/$FILENAME" | while read -r line
		do
			echo "/$line/ {print \"$FILENAME\"}"
		done
	done
	popd > /dev/null
}

rebuild_hints() {
	if [[ ! -d "$Q_SCRIPT_DIR" ]]; then
		return
	fi

	pushd "$Q_SCRIPT_DIR" >/dev/null
	find . -type f -name 'q-*' | while read -r FN
	do
		FILENAME="$(echo "$FN" | sed 's/^\.\///g')"

		"$Q_SCRIPT_DIR/$FILENAME" --hint
	done
	popd > /dev/null
}

get_scripts_for_cmd() {
	if [[ ! -f "$INDEX_FILE" ]]; then
		return
	fi

	echo "$1" | awk -f "$INDEX_FILE" | while read -r line
	do
		echo "$line"
	done
}

complete_command() {
	COMMAND="$@"
	SCRIPTS="$(get_scripts_for_cmd "$COMMAND")"
	if [ -z "$SCRIPTS" ] || \
	   [ "$(echo "$SCRIPTS" | wc -w)" -gt "1" ]; then
		cat "$HINT_FILE"
		exit 0
	fi
	"$Q_SCRIPT_DIR/$SCRIPTS" --complete "$@"
}

run_command() {
	COMMAND="$@"
	FIRST=${COMMAND%%" "*}
	REST=${COMMAND#*" "}
	SCRIPTS="$(get_scripts_for_cmd "$REST")"
	if [ -z "$SCRIPTS" ] || \
	   [ "$(echo "$SCRIPTS" | wc -w)" -gt "1" ]; then
		echo "Scripts matched: $SCRIPTS"
		exit 0
	fi
	"$Q_SCRIPT_DIR/$SCRIPTS" --run "$FIRST" "$REST"
}

run_command_cli() {
	COMMAND="$@"
	SCRIPTS="$(get_scripts_for_cmd "$COMMAND")"
	if [ -z "$SCRIPTS" ] || \
	   [ "$(echo "$SCRIPTS" | wc -w)" -gt "1" ]; then
		echo "Scripts matched: $SCRIPTS"
		exit 0
	fi
	"$Q_SCRIPT_DIR/$SCRIPTS" --cli "$COMMAND"
}

preview_command() {
	COMMAND="$@"
	FIRST=${COMMAND%%" "*}
	REST=${COMMAND#*" "}
	SCRIPTS="$(get_scripts_for_cmd "$REST")"
	if [ -z "$SCRIPTS" ] || \
	   [ "$(echo "$SCRIPTS" | wc -w)" -gt "1" ]; then
		echo "Scripts matched: $SCRIPTS"
		exit 0
	fi
	"$Q_SCRIPT_DIR/$SCRIPTS" --preview "$FIRST" "$REST"
}

if [[ ! -f "$INDEX_FILE" ]] || new_scripts_exist; then
	rebuild_index > "$INDEX_FILE"
	rebuild_hints > "$HINT_FILE"
fi

while (( "$#" )); do
	case "$1" in
		-c|--complete)
			shift
			complete_command "$@"
			exit 0
			;;
		-r|--run)
			shift
			if [[ -z "$@" ]]; then
				exit 0
			fi
			run_command "$@"
			exit 0
			;;
		-p|--preview)
			shift
			if [[ -z "$@" ]]; then
				exit 0
			fi
			preview_command "$@"
			exit 0
			;;
		-u|--update)
			shift
			rebuild_index > "$INDEX_FILE"
			rebuild_hints > "$HINT_FILE"
			exit 0
			;;
		*)
			break
			;;
	esac
done


COMMAND="$@"

if [[ -z "$COMMAND" ]] && [[ ! -t 0 ]]; then
	COMMAND="$(cat)"
fi

if [[ -z "$COMMAND" ]]; then
	PREF="$SELF -c"
	INITIAL=""
	FZF_DEFAULT_COMMAND="$PREF '$INITIAL'" fzf \
		--bind "change:reload:$PREF {q} || true" \
		--ansi --query "$INITIAL" \
		--preview "$SELF -p {}" \
		--with-nth="2..-1" \
		--preview-window wrap \
		--tiebreak=index | xargs -o "$SELF" -r
else
	run_command_cli "$COMMAND"
fi
