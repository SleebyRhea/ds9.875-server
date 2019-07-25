#!/bin/bash
source /etc/avorionsettings.conf

if [[ "$(groups)" =~ (^$AVORION_ADMIN_GRP | $AVORION_ADMIN_GRP | $AVORION_ADMIN_GRP$) ]] || [[ "$(id -u)" == 0 ]]; then
	function showinstances() {
		local _bld _clr _grn _red _wht
		_clr="$(tput sgr0)"; _bld="$(tput bold)"
		_wht="$(tput setaf 7)"; _grn="$(tput setaf 2)"; _red="$(tput setaf 1)"

		if (( ! "$(find "${AVORION_SERVICEDIR}/sockets" -name '*.sock' | wc -l)" > 0 )); then
				return 1
		fi

		printf '%s\n' "${_bld}${$_wht}DeepSpace 9.875 -- Service Instances:${_clr}"

		find "${AVORION_SERVICEDIR}/sockets" -name '*.sock' -printf '%f\n' | sort | while read -r _sock; do
			local _instance="${_sock%%.sock*}"
			local _cmd="$(which tmux) -S ${AVORION_SERVICEDIR}/sockets/${_sock} attach -t ${_a}"
		
			if systemctl list-units avorion@* 2>&1 | grep -q "^avorion@${_instance}.service " >/dev/null 2>&1 ; then
				systemctl status avorion@"${_instance}" >/dev/null 2>&1 \
					&& echo "${_instance} (Avorion) -- ${_grn}Online${_clr}" \
					|| echo "${_instance} (Avorion) -- ${_red}Offline${_clr}"

			elif [[ "$_instance" =~ ^steam(cmd|cli)$ ]]; then
				systemctl status "${_instance}" >/dev/null 2>&1 \
					&& echo "${_instance} -- ${_grn}Online${_clr}" \
					|| echo "${_instance} -- ${_red}Offline${_clr}"

			else
				systemctl status "${_instance}" >/dev/null 2>&1 \
					&& echo "${_instance} -- ${_grn}Online${_clr}" \
					|| echo "${_instance} -- ${_red}Offline${_clr}"
			fi
		done
	}

	function avorion-cmd () {
		command -v tmux >/dev/null 2>&1 || {
			echo "avorion-cmd requires tmux to function! Please run apt install -y tmux"
			return 1
		}
		
		if ! { [[ -z "$TMUX" ]] && [[ ! "$TERM" =~ ^(screen|tmux) ]] && [[ -z "$TMUX_PANE" ]]; }; then
			echo "This command should not be run from within a Screen/Tmux session"
		fi

		#####

		local _tmuxsess _tmuxcmd
		local _bld _clr _grn _red _wht
		_clr="$(tput sgr0)"; _bld="$(tput bold)";
		_wht="$(tput setaf 7)"; _grn="$(tput setaf 2)"
		_red="$(tput setaf 1)"; _yel="$(tput setaf 3)"

		if [[ ! "$1" =~ (help|update|validate) ]]; then
				_tmuxsess="$2"
				_tmuxsess="${_tmuxsess//[ _]/\-}"
				_tmuxsess="${_tmuxsess//[^a-zA-Z0-9\-]/}"

				systemctl status avorion@"$_tmuxsess".service >/dev/null 2>&1 || {
					echo "$_tmuxsess is not a valid Avorion instance."
					return 1
				}
			#else
			#	_tmuxsess=steamcli
			#	systemctl status steamcmd.service >/dev/null 2>&1 || {
			#		echo "Steam is currently down!"
			#		return 1
			#	}
			#fi

			_tmuxcmd="$(which tmux) -S ${AVORION_SERVICEDIR}/sockets/${_tmuxsess}.sock"
		fi

		case "$1" in 
			attach)
				"$_tmuxcmd" attach-session -t "$_tmuxsess"
				;;
			
			view)
				"$_tmuxcmd" attach-session -t "$_tmuxsess" -r
				;;
			
			exec)
				shift; shift
				"$_tmuxcmd" send-keys "$(printf '%q' "$@")" ENTER \; pipe-pane 'cat > /dev/stdout'
				;;
			
			update)
				[[ -d "/tmp/avorion/updatingavorion.lock" ]] && {
					echo "Update process already running"
					return 1
				}

				mkdir -p /tmp/avorion/updatingavorion.lock >/dev/null 2>&1 || {
					echo "Unable to create avorion lockfile! Check /tmp usage."
					return 1
				}

				_units="$(systemctl list-units 'avorion@*' | grep 'loaded active running' | awk '{print $1}')"
				
				systemctl stop 'avorion@*'
				systemctl disable 'avorion@*'

				echo "Updating Avorion"
				steamcmd '+force_install_dir' ${AVORION_SERVICEDIR}/${AVORION_BINDIR} '+app_update' $AVORION_STEAMID validate '+exit' \
					| tee "${AVORION_SERVICEDIR}/${AVORION_BINDIR}/steamupdate.log"
				
				while read _inst; do
					systemctl enable avorion@"$_inst"
					systemctl start avorion@"$_inst"
				done <<< "${_units}"

				rm -rf /tmp/avorion/updatingavorion.lock >/dev/null 2>&1 || {
					echo "Unable to remove lockfile. Please ensure that the update was finished successfully."
					return 1
				}

				return 0
				;;
			
			backup)
				echo "TODO: Unimplemented"
				;;

			resetsector)
				echo "TODO: Unimplemented"
				;;

			help)
				echo "Usage: avorioncmd <option> <parameters>"
				echo "Options:"
				printf '\t%s' \
					"attach: Attach to a service instance.\n\t\tExample: ${_grn}avorioncmd attach ds9server${_clr}" \
					"view: Attach to a service instance in read-only mode.\n\t\tExample: ${_grn}avorioncmd view ds9server${_clr}" \
					"exec: Run the specified commands in the service supplied\n\t\tExample: ${_grn}avorioncmd exec ds9server <COMMANDS>\n\t\t${_red}WARNING:${_clr} May be buggy, please dont use this for large Lua scripts commands until further tested." \
					"backup: Force a backup run of the given instance\n\t\tExample: ${_grn}avorioncmd backup ds9server${_clr}\n\t\t${_yel}NOTICE: Unimplemented at this time.${_clr}" \
					"resetsector: Reset the given sector/sectors for a server instance\n\t\tExample: ${_grn}avorioncmd resetsector x y${_clr}\n\t\t${_yel}NOTICE: Unimplemented at this time.${_clr}" \
					"update: Force a full Avorion server update. Note that this brings the server down for the duration." \
					"help: This help text"
					
					return 0
				;;

			?)
				printf '%s\n' "Invalid argument passed: <$(printf '%q' "$1")>"
				exit
				;;
		esac
	}

	showinstances
fi

