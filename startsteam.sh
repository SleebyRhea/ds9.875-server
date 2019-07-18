#! /usr/bin/env bash

TMUX_SOCDIR=/var/steamcmd/tsockets
TMUX_SOCNAM=dsnineadm
TMUX_SESNAM=steamcli
TMUX_CMD="tmux -S '${TMUX_SOCDIR}/${TMUX_SOCNAM}'"
STEAMCMD='/usr/games/steamcmd +login anonymous'

if "$TMUX_CMD" list-sessions 2>/dev/null | grep -q "^${TMUX_SESNAM}:"; then
	tmux kill-session -t "$TMUX_SESNAM" >/dev/null 2>&1 || {
		echo "Unable to kill previous TMUX sessions!"
		"$TMUX_CMD" list-sessions
		exit 1
	}
fi

"$TMUX_CMD" new -s "$TMUX_SESNAM"
