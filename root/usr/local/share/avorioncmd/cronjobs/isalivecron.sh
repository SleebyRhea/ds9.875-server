#! /usr/bin/env bash
declare __RCON='/usr/bin/rcon'
declare __RCONHOSTFILE='/srv/avorion/rconhostfile'
declare __GALAXY='ds9server'
declare __AVORION_CMD='/usr/local/bin/avorion-cmd'
declare __ETIME="$(date +%s)"
declare __DATE="$(date -d "@$__ETIME" +%m-%d-%Y)"
declare __TIMEOUT=60

function main () {
	__validate_setting_conf &&\
		source /etc/avorionsettings.conf

	if [[ -f /tmp/runningavorionbackup ]]; then
		exit 0
	fi

	if [[ -f /tmp/runningavorionbackup ]]; then
		exit 0
	fi

	local __tmpfile="$(mktemp)"
	local __restarted=0
	local __fintime __cronoutput

	touch /tmp/avorion.hangdetector
	trap "rm -v /tmp/avorion.hangdetector ${__tmpfile} >/dev/null 2>>/srv/avorion/serverstatus.log" EXIT

	echo >> /srv/avorion/serverstatus.log
	echo "Log Started @ $__ETIME ($__DATE)" >> /srv/avorion/serverstatus.log
	printf "Testing RCON..." >> /srv/avorion/serverstatus.log

	__cronoutput="$(timeout "$__TIMEOUT" $__RCON -c "$__RCONHOSTFILE" -s "$__GALAXY" status)"
	if (( "$(wc -c "$__cronoutput")" < 200 )) 2>&1; then
		echo "Failed to connect. Restarting Avorion." >>/srv/avorion/serverstatus.log
		$__AVORION_CMD restart "${__GALAXY}" >>/srv/avorion/serverstatus.log 2>&1
		sed 's,.*,\t&,' "$__tmpfile" >>/srv/avorion/serverstatus.log
		__restarted=1
	else
		echo "Connected" >>/srv/avorion/serverstatus.log
	fi

	cat "$__tmpfile" >> /srv/avorion/serverstatus.log
	
	__fintime="$(date +%s)"
	echo "Log Closed @ $__fintime ($(date -d "@$__fintime" +%m-%d-%Y))" >> /srv/avorion/serverstatus.log
	if [[ "$(id -u 2>/dev/null)" == "0" ]]; then
		chown "$AVORION_USER":"$AVORION_ADMIN_GRP" /srv/avorion/serverstatus.log
	fi
	exit 0
}

# bool __validate_setting_conf <void>
#	Validates the avorionsettings configuration, and makes sure that
#	sourcing it will not break anything. If the file passes, return.
#	Otherwise, kill the script.
function __validate_setting_conf () {
	[[ -f /etc/avorionsettings.conf ]] ||\
		die "Avorion configuration file not found"

	local -A __conf_vars
	local __bad_symbols __err
	__bad_symbols="[\\&^s\(\)%\[\]\#@!<>\'\",;:\{\}]"
	__conf_vars[AVORION_ADMIN_GRP]='^[a-z][a-z]*$'
	__conf_vars[AVORION_USER]='^[a-z][a-z]*$'
	__conf_vars[AVORION_SERVICEDIR]='^/[a-zA-Z0-9_\-][a-zA-Z0-9_\-\/]*$'
	__conf_vars[AVORION_BINDIR]='^[a-zA-Z0-9_\-\/][a-zA-Z0-9_\-\/]*$'
	__conf_vars[AVORION_BAKDIR]='^\/[a-zA-Z0-9_\-\/][a-zA-Z0-9_\-\/]*$'
	__conf_vars[AVORION_STEAMID]='^[0-9][0-9]*$'
	__conf_vars[STEAMCMD_BIN]='^(/[a-zA-Z0-9_\-\/][a-zA-Z0-9_\-\/\.]*[a-zA-Z0-9]|steamcmd)$'

	local i=0
	while read -r __l; do
		((i++))
		
		__err="Configuration error on line ${i} of /etc/avorionsettings.conf"
		
		[[ "${__l}" =~ ^[[:space:]]*#*$ ]] &&\
		   	continue
		
		[[ "${__l}" =~ $__bad_symbols ]] &&\
			die "${__err} -- Invalid chars present: <$( printf '%q' "${__l}") >"
		
		[[ "${__l}" =~ ^([^[:space:]][^[:space:]]*)=([^[:space:]][^[:space:]]*)$ ]] ||\
			die "${__err} -- Bad syntax: <$( printf '%q' "${__l}")>"
		
		[[ -z "${__conf_vars[$( printf '%q' "${BASH_REMATCH[1]}" )]}" ]] &&\
			die "${__err} -- Invalid setting: <$( printf '%q' "${BASH_REMATCH[1]}" )>"
		
		[[ "$( printf '%q' "${BASH_REMATCH[2]}" )" =~ ${__conf_vars[$( printf '%q' "${BASH_REMATCH[1]}" )]} ]] ||\
			die "${__err} -- Invalid assignment: <$( printf '%q' "${__l}")>"

	done < /etc/avorionsettings.conf
	
	return 0
}

main "$@"