#! /usr/bin/env bash

source /usr/local/share/avorioncmd/common/common.sh

declare __RCON='/usr/bin/rcon'
declare __RCONHOSTFILE='/srv/avorion/rconhostfile'
declare __GALAXY='ds9server'
declare __AVORION_CMD='/usr/local/bin/avorion-cmd'
declare __DATE="$(date -d "@$EDATE" +%m-%d-%Y)"
declare __TIMEOUT=60

function main () {

	if [[ -f /tmp/runningavorionbackup ]]; then
		exit 0
	fi

	if [[ -f /tmp/avorion.hangdetector ]]; then
		exit 0
	fi

	local __tmpfile="$(mktemp)"
	local __restarted=0
	local __fintime __cronoutput

	touch /tmp/avorion.hangdetector
	trap "rm -v /tmp/avorion.hangdetector ${__tmpfile} >/dev/null 2>>/srv/avorion/serverstatus.log" EXIT

	echo >> /srv/avorion/serverstatus.log
	echo "Log Started @ $EDATE ($__DATE)" >> /srv/avorion/serverstatus.log
	printf "Testing RCON..." >> /srv/avorion/serverstatus.log

	__cronoutput="$(timeout "$__TIMEOUT" $__RCON -c "$__RCONHOSTFILE" -s "$__GALAXY" status)"
	if (( "$(wc -c <<< "$__cronoutput")" < 200 )) 2>&1; then
		echo "Failed to connect. Restarting Avorion." >>/srv/avorion/serverstatus.log
		$__AVORION_CMD restart "${__GALAXY}" >>/srv/avorion/serverstatus.log 2>&1
		sed 's,.*,\t&,' <<< "$__cronoutput" >>/srv/avorion/serverstatus.log
		__restarted=1
	else
		echo "Connected" >>/srv/avorion/serverstatus.log
	fi

	echo "$__cronoutput" >> /srv/avorion/serverstatus.log
	
	__fintime="$(date +%s)"
	echo "Log Closed @ $__fintime ($(date -d "@$__fintime" +%m-%d-%Y))" >> /srv/avorion/serverstatus.log
	if [[ "$(id -u 2>/dev/null)" == "0" ]]; then
		chown "$AVORION_USER":"$AVORION_ADMIN_GRP" /srv/avorion/serverstatus.log
	fi
	exit 0
}

main "$@"