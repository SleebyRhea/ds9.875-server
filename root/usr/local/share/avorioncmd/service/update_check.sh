#! /usr/bin/env bash

__AVORION_CMD='/usr/local/bin/avorion-cmd'
__NOTIF_PREFIX='[NOTIFICATION]'
__UPDATE_LOG=''
__ETIME="$(date +%s)"

function main() {
    __validate_setting_conf &&\
        source /etc/avorionsettings.conf
    
    __UPDATE_LOG="${AVORION_SERVICEDIR}/autoupdate.log"

    if ! printf "\n\nLog opened @$__ETIME\n" >> "$__updatelog"; then
        die "Unable to write to logfile"
    fi

    if ! __check_update_status; then
        case "$?" in
            200 | 300 ) exit "0" ;;
        esac
    fi

    __check_for_steam_update
}

function __enqueue_restart() {
    return 0
}

function __check_for_steam_update () {
    local __appdata __oldusr __oldgrp __oldhome __steamcmd

    # Quick check to make sure that SteamCMD is present either
    # in steamcmd or steamcmd.sh form
    if [[ -f "$STEAMCMD_BIN" ]] || command -v "$STEAMCMD_BIN" >/dev/null 2>&1; then
        __steamcmd="$STEAMCMD_BIN"
    else 
        __steamcmd="$(command -v steamcmd 2>/dev/null | head -n1 2>/dev/null)"
        if [[ -z "$_steamcmd" ]]; then
            die "SteamCMD definition is undefined, or invalid"
        fi
    fi

    ## Command string used to update and output the steam app data cache
    __get_info_command="+@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir '${AVORION_SERVICEDIR}/${AVORION_BINDIR}' +app_info_update 1 +app_status '$AVORION_STEAMID' +quit"

	## Overwrite default environment to fix sudo+steamcmd stupidity
    __oldusr="$USER"; __oldgrp="$GROUP"; __oldhome="$HOME"
	export USER="$AVORION_USER"; export GROUP="$AVORION_ADMIN_GRP"; export HOME="$AVORION_SERVICEDIR"
    __appdata="$(sudo -n -u avorion -g dsnineadm $__steamcmd $__get_info_command 2>&1)"

    if (( $? > 0 )); then
        echo "SteamCMD failed to download update! Please review "
        echo "$__appdata" >> "$__UPDATE_LOG"
        return 1
    fi

    export USER="$__oldusr"; export GROUP="$__oldgrp"; export HOME="$__oldhome"

    if [[ -z "$__appdata" ]]; then
        die "Failed to update steam data cache for Avorion! Directory: <${AVORION_SERVICEDIR}/${AVORION_BINDIR}>"
    fi

    if ! grep -qm1 '^[[:space:]]*\-[[:space:]]*install state:' <<< "$__appdata" >/dev/null 2>&1; then
        echo "SteamCMD failed to return install state!"
        echo "$__appdata" >> "$__UPDATE_LOG"
        return 1
    fi

    ## Check for an update by grepping out of the update state variable
    __state="$(grep -q '^[[:space:]]*\-[[:space:]]*install state:' | sed -n 's,^.*install state: \(.*\)$,\1,p')"
    if grep -q "[uU]pdate [rR]equired" <<< "$__state" >/dev/null 2>&1; then
        $__AVORION_CMD downloadupdate | tee -a "${AVORION_SERVICEDIR}/autoupdate.log"
    else
        echo "No update required"
        return 0
    fi
}

#
#
#
#
#
function __check_update_status() {
    if ! [[ -f "${AVORION_SERVICEDIR}/${AVORION_BINDIR}".updatefiles/avorion.updatestatus ]]; then
        return 0
    fi

    __status="$(< "${AVORION_SERVICEDIR}/${AVORION_BINDIR}".updatefiles/avorion.updatestatus | tr -d '\n')"
    if ! [[ "$__status" =~ ^[[^:]][[^:]]*:[[^:]][[^:]]*:[[^:]][[^:]]*$ ]]; then
        echo "Invalid update status: <${__status}>" >2
        return 0
    fi

    local __job_status="${BASH_REMATCH[1]}"
    local __job_inform="${BASH_REMATCH[2]}"
    local __job_reason="${BASH_REMATCH[3]}"

    case "${__job_status}:${__job_inform}" in
        complete:success)
            echo "Update has been downloaded and is ready for installation."
            __send_notification "New update downloaded!"
            __enqueue_restart 3600 "Restarting server for updates"
            return 200
            ;;

        complete:failed)
            echo "Download failed, and will be reaquired."
            return 201
            ;;
        
        complete:*)
            echo "Download completed, but with an unknown state. It will be reaquired. Full State: <${__job_status}:${__job_inform}:${__job_reason}>"
            return 202
            ;;
        
        updating:*)
            if __is_locked; then
                echo "Updates are already being processed."
                return 300
            fi

            echo "Updates were halted before they could finish on the last run! Requiring updates."
            return 301
            ;;
    esac
}


function __is_locked() {
    if [[ -f /tmp/avorion/updatingavorion.lock ]]; then
        return 0
    fi

    return 1
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