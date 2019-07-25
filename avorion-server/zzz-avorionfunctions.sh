source /etc/avorionsettings.conf

if [[ "$(groups)" =~ (^$AVORION_ADMIN_GRP | $AVORION_ADMIN_GRP | $AVORION_ADMIN_GRP$) ]] || [[ "$(id -u)" == 0 ]]; then
	printf '%s\n' "$(tput bold)$(tput setaf 7)DeepSpace 9.875 -- Service Instances:$(tput sgr0)"

	function showinstances() {
		find "${AVORION_SERVICEDIR}/sockets" -name '*.sock' -printf '%f\n' | sort | while read -r _sock; do
			local _instance="${_sock%%.sock*}"
			local _cmd="$(which tmux) -S ${AVORION_SERVICEDIR}/sockets/${_sock} attach -t ${_a}"
		
			if systemctl list-units avorion@* 2>&1 | grep -q "^avorion@${_instance}.service " >/dev/null 2>&1 ; then
				systemctl status avorion@"${_instance}" >/dev/null 2>&1 \
					&& echo "${_instance} (Avorion) -- $(tput setaf 2)Online$(tput sgr0)" \
					|| echo "${_instance} (Avorion) -- $(tput setaf 1)Offline$(tput sgr0)"

			elif [[ "$_instance" =~ ^steam(cmd|cli)$ ]]; then
				systemctl status "${_instance}" >/dev/null 2>&1 \
					&& echo "${_instance} -- $(tput setaf 2)Online$(tput sgr0)" \
					|| echo "${_instance} -- $(tput setaf 1)Offline$(tput sgr0)"

			else
				systemctl status "${_instance}" >/dev/null 2>&1 \
					&& echo "${_instance} -- $(tput setaf 2)Online$(tput sgr0)" \
					|| echo "${_instance} -- $(tput setaf 1)Offline$(tput sgr0)"
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

		if [[ ! "$2" =~ (update|validate) ]]; then
			_tmuxsess="$2"
			_tmuxsess="${_tmuxsess//[ _]/\-}"
			_tmuxsess="${_tmuxsess//[^a-zA-Z0-9\-]/}"

			systemctl status avorion@"$_tmuxsess".service >/dev/null 2>&1 || {
				echo "$_tmuxsess is not a valid Avorion instance."
				return 1
			}
		else
			_tmuxsess=steamcli
			systemctl status steamcmd.service >/dev/null 2>&1 || {
				echo "Steam is currently down!"
				return 1
			}
		fi

		_tmuxcmd="$(which tmux) -S ${INSTALLDIR}/sockets/${_tmuxsess}.sock"
		
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
				systemctl stop avorion@*
				echo "Updating Avorion"
				"$_tmuxcmd" send-keys "+force_install_dir ${AVORION_SERVICEDIR}/${AVORION_BINDIR} +app_update $AVORION_STEAMID validate" ENTER \; pipe-pane "cat > '${AVORION_SERVICEDIR}/${AVORION_BINDIR}/steamupdate.log'"
				( tail -f -n0 "${AVORION_SERVICEDIR}/${AVORION_BINDIR}/steamupdate.log" & ) | tee | grep -q Completed
				systemctl start avorion@*
				;;
			
			backup)
				echo "TODO: Unimplemented"
				;;

			resetsector)
				echo "TODO: Unimplemented"
				;;

			?)
				printf '%s\n' "Invalid argument passed: <$(printf '%q' "$1")>"
				exit
				;;
		esac
	}

	showinstances
fi

