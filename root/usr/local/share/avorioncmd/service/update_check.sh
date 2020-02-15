#! /usr/bin/env bash
#
#
#
#

# shellcheck disable=SC1091
source /usr/local/share/avorioncmd/common/common.sh

__AVORION_CMD='/usr/local/bin/avorion-cmd'
__NOTIF_PREFIX='[NOTIFICATION]'
__UPDATE_LOG="${AVORION_SERVICEDIR}/autoupdate.log"

function main() {    
	if checkLock update; then
		exit 0
	fi

    if ! printf '\n\nLog opened @%s\n' "$EDATE" >> "$__UPDATE_LOG"; then
        die "Unable to write to logfile"
    fi

    if ! __check_update_status; then
        case "$?" in
            200 | 203 ) exit 0 ;;
        esac
    fi

    __check_for_steam_update

    if __check_update_status; then 
        echo "Update failed!" >&2
    fi
    exit "$?"
}

function __send_update_notification () {
	local __new_version
	__new_version="$( "${AVORION_SERVICEDIR}/${AVORION_BINDIR}".updatefiles/bin/AvorionServer --version)"
	$__AVORION_CMD exec +all "/say ${__NOTIF_PREFIX} New update downloaded! New version: ${__new_version}"
}

#
#
#
#
#
function __enqueue_restart() {
    return 0
}

function __check_for_steam_update () {
    local __appdata __oldusr __oldgrp __oldhome
	local -a __get_info_command

    ## Command array used to update and output the steam app data cache
    __get_info_command=(
		'+@ShutdownOnFailedCommand' 1 
		'+@NoPromptForPassword' 1
		'+login' anonymous 
		'+force_install_dir' "${AVORION_SERVICEDIR}/${AVORION_BINDIR}"
		'+app_info_update' 1
		'+app_status' "${AVORION_STEAMID}"
		'+quit'
	)

	## Overwrite default environment to fix steamcmd using bash environment data
    __oldusr="$USER"; __oldgrp="$GROUP"; __oldhome="$HOME"
	export USER="$AVORION_USER"; export GROUP="$AVORION_ADMIN_GRP"; export HOME="$AVORION_SERVICEDIR"

    if __appdata="$($SUDOPREFIX "$STEAMCMD_BIN" "${__get_info_command[@]}" 2>&1)"; then
        echo "SteamCMD failed to download update! Please review: <$__UPDATE_LOG>"
        echo "$__appdata" >> "$__UPDATE_LOG"
        return 1
    fi

	## Revert
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

    __status="$(< "${AVORION_SERVICEDIR}/${AVORION_BINDIR}".updatefiles/avorion.updatestatus tr -d '\n')"
    if ! [[ "$__status" =~ ^[[^:]][[^:]]*:[[^:]][[^:]]*:[[^:]][[^:]]*$ ]]; then
        echo "Invalid update status: <${__status}>" >&2
        return 0
    fi

    local __job_status="${BASH_REMATCH[1]}"
    local __job_inform="${BASH_REMATCH[2]}"
    local __job_reason="${BASH_REMATCH[3]}"

    case "${__job_status}:${__job_inform}" in
        complete:success)
            echo "Update has been downloaded and is ready for installation."
        	__send_update_notification
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
                return 203
            fi

            echo "Updates were halted before they could finish on the last run! Requiring updates."
            return 204
            ;;
    esac
}


function __is_locked() {
    [[ -f /tmp/avorion/updatingavorion.lock ]] &&\
        return 0 ||\
    	return 1
}
