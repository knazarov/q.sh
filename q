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

INDEX_FILE=~/.q.index

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

get_scripts_for_cmd() {
	if [[ ! -f "$INDEX_FILE" ]]; then
		return
	fi

	echo "$1" | awk -f "$INDEX_FILE" | while read -r line
	do
		echo "$line"
	done
}

if [[ ! -f "$INDEX_FILE" ]] || new_scripts_exist; then
	rebuild_index > "$INDEX_FILE"
fi

LIST=0
if [[ "$1" == "--list" ]] || [[ "$1" == "-l" ]]; then
	shift
	LIST=1
fi

DRYRUN=0
if [[ "$1" == "--dry-run" ]] || [[ "$1" == "-d" ]]; then
	shift
	DRYRUN=1
fi

COMMAND="$@"

if [[ -z "$COMMAND" ]] && [[ ! -t 0 ]]; then
	COMMAND="$(cat)"
fi

if [[ ! -z "$COMMAND" ]]; then
	SCRIPTS="$(get_scripts_for_cmd "$COMMAND")"

	if [[ "$LIST" == "1" ]]; then
		echo "$SCRIPTS"
	else
		if [ "$(echo "$SCRIPTS" | wc -w)" -gt "1" ]; then
			printf "Too many scripts matched:\n$SCRIPTS\n" 1>&2
			exit 1
		elif [[ ! -z "$SCRIPTS" ]]; then
			if [[ "$DRYRUN" == "1" ]]; then
				"$Q_SCRIPT_DIR/$SCRIPTS" --dry-run "$COMMAND"
			else
				echo "$@" >> ~/.q_history
				"$Q_SCRIPT_DIR/$SCRIPTS" "$COMMAND"
			fi
		else
			printf "No scripts matched:\n$SCRIPTS\n" 1>&2
			exit 1
		fi
	fi
fi
