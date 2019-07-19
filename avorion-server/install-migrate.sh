#! /usr/bin/env bash
#
# Avorion Migrator/Service Installer
# IDGAF license -- Do whatever you want with this

AVORIONDIR=''
AVORIONPRF='/etc/profile.d/zzz-avorionservercommands.sh'
INSTALLDIR='/srv/avorion'
USR=avorion
GRP=dsnineadm
STEAMCMD=''
UNITDIR='/etc/systemd/system'
SERVERGIT='arcturus615/avorion-ds978'
FAILED=0

# void seperate (void)
#    Print 4 newlines, a seperator and return
function seperate() {
	print '\n\n----------\n\n'
}

# boolean yesno (_prompt)
#	Loop until the user supplies a yes/no answer
#   If $_prompt is given, output string as a
#	a prompt
function yesno() {
	local _prompt="$1"
	local _answer=''

	while true; do
		printf '%s\n[y/n]> ' "$_prompt"
		read _answer
		case "$_answer" in
			[yY][eE][sS] | [yY])
				return 0
				;;
			[nN][oO] | [nN])
				return 1
				;;
			?)
				echo "Please answer <yes/Y> or <no/N>"
				;;
		esac
	done
}

################
# Initialization
################

# Check if $STEAMCMD is set. If not, we need to know where steam is currently
# stored, or alternatively, what to use as the steamcmd command for this script
#
# NOTE: This will NOT update the steamcmd.service file! That should be done manually
# if it is necessary 
if [[ -z "$STEAMCMD"  ]]; then
	command -v steamcmd || {
		echo "Steamcmd does not appear to be installed in the default PATH:"
		echo "PATH: <$PATH>"
		echo "Please modify the \$STEAMCMD variable to point to the correct location of steamcmd"
		exit 1
	}

	STEAMCMD="$(which steamcmd)"
fi

# If $AVORIONDIR is unset, prompt the user for it's location and loop until a 
# valid one is supplied
while [[ -z "$AVORIONDIR" ]]; do
	read -p "Where is the current galaxy stored?> " AVORIONDIR
	if [[ ! -f "$AVORIONDIR" ]]; then
		AVORIONDIR=''
		echo "That directory does not exist"
		continue
	fi
	
	# Check if the supplied $AVORIONDIR has a server.ini file present and prompt the
	# user for confirmation to proceed if it does NOT
	if [[ ! -f "$AVORIONDIR"/server.ini ]]; then
		if ! yesno "The directory $AVORIONDIR does not contain a server.ini file. Is this correct?"; then
			AVORIONDIR=''
		fi
	fi
done

# Prep the server installation directory
if [[ ! -d "$INSTALLDIR" ]]; then
	mkdir -p "$INSTALLDIR"/server_files >/dev/null \
		|| exit 1
fi

# Prep the server socket directory
if [[ ! -d /srv/avorion/sockets ]]; then
	mkdir -p /srv/avorion/sockets \
		|| exit 1
fi

# Prep the admin command bash profile
touch "${AVORPROFILE}"

##############
# Installation
##############

########
seperate
########

echo "Copying <$AVORIONDIR> to ${INSTALLDIR}/$(basename "$AVORIONDIR")"
echo "(This may take some time)"
cp -rf "$AVORIONDIR" "$INSTALLDIR"/"$(basename "$AVORIONDIR")" \
	|| exit 1

########
seperate
########

echo "Installing Avorion Server and setting ownership to $USR:$GRP"
echo "(This may take some time)"

# If the the admin group as defined in $GRP does not exist, create it
if ! grep -q "$GRP" /etc/group >/dev/null; then
	groupadd "$GRP" \
		|| exit 1
fi

# Same with the user
if ! grep -q "$USR" /etc/passwd; then
	useradd avorion -d "$INSTALLDIR" --no-create-home -g "$GRP" -r \
		|| exit 1
fi

# Install a fresh instance of Avorion in installation directory under the
# subdirectory server_files
sudo -u avorion "$STEAMCMD" +login anonymous +force_install_dir "$INSTALLDIR"/server_files +app_update 565060 validate +exit \
	|| exit 1

# Recursively set *all* permissions to $USR:$GRP in $INSTALLDIR
chown -R "$USR":"$GRP" "$INSTALLDIR" \
	|| exit 1

########
seperate
########

echo "Installing Server repo to /opt/avorion-server-repo and unit files to <$UNITDIR>"
mkdir -p /opt/avorion-server-repo \
	|| exit 1

git clone "$SERVERGIT" /opt/avorion-server-repo >/dev/null 2>&1 || {
	echo "Failed to clone $SERVERGIT to </opt/avorion-server-repo>. Error:"
	git clone "$SERVERGIT" /opt/avorion-server-repo
	exit 1
}

cp -ft "$UNITDIR" /opt/avorion-server-repo/avorion@.service /opt/avorion-server-repo/steamcmd.service \
	|| exit 1

cat >> /etc/profile.d/"${AVORPROFILE}" << _EOF_
if [[ ! "\$(groups)" =~ (^$GRP | $GRP | $GRP\$) ]] && [[ ! "\$(id -u)" == 0 ]]; then
	printf '%s\\n' '$(tput bold)$(tput setaf 7)DeepSpace 9.875 -- Service Instances:$(tput sgr0)'
	function showinstances() {
		find '${INSTALLDIR}/sockets' -name '*.sock' -printf '%f\\n' | sort | while read -r _sock; do
			local _instance="\${_sock%%.sock*}"
			local _cmd="$(which tmux) -S ${INSTALLDIR}/sockets/\${_sock} attach -t \${_a}"
		
			if systemctl list-units avorion@* 2>&1 | grep -q "^avorion@\${_instance}.service " >/dev/null 2>&1 ; then
				systemctl status avorion@\${_instance} >/dev/null 2>&1 \
					&& echo "\${_instance} (Avorion) -- $(tput setaf 2)Online$(tput sgr0)" \
					|| echo "\${_instance} (Avorion) -- $(tput setaf 1)Offline$(tput sgr0)"

			elif [[ "\$_instance" =~ ^steam(cmd|cli)$ ]]; then
				systemctl status "\${_instance}" >/dev/null 2>&1 \
					&& echo "\${_instance} -- $(tput setaf 2)Online$(tput sgr0)" \
					|| echo "\${_instance} -- $(tput setaf 1)Offline$(tput sgr0)"

			else
				systemctl status "\${_instance}" >/dev/null 2>&1 \
					&& echo "\${_instance} -- $(tput setaf 2)Online$(tput sgr0)" \
					|| echo "\${_instance} -- $(tput setaf 1)Offline$(tput sgr0)"
			fi
		done
	}

	function avorion-cmd () {
		command -v tmux >/dev/null 2>&1 \\ {
			echo "avorion-cmd requires tmux to function! Please run apt install -y tmux"
			return 1
		}
		
		if ! { [[ -z "\$TMUX" ]] && [[ ! "\$TERM" =~ ^(screen|tmux) ]] && [[ -z "\$TMUX_PANE" ]]; }; then
			echo "This command should not be run from within a Screen/Tmux session"
		fi

		#####

		local _tmuxsess _tmuxcmd

		if [[ ! "\$2" =~ (update|validate) ]]; then
			_tmuxsess="\$2"
			_tmuxsess="\${_tmuxsess//[ _]/\\-}"
			_tmuxsess="\${_tmuxsess//[^a-zA-Z0-9\\-]/}"

			systemctl status avorion@"\$_tmuxsess".service >/dev/null 2>&1 || {
				echo "\$_tmuxsess is not a valid Avorion instance."
				return 1
			}
		else
			_tmuxsess=steamcli
			systemctl status steamcmd.service >/dev/null 2>&1 || {
				echo "Steam is currently down!"
				return 1
			}
		fi

		_tmuxcmd="\$(which tmux) -S ${INSTALLDIR}/sockets/\${_tmuxsess}.sock"
		
		case "\$1" in 
			attach)
				"\$_tmuxcmd" attach-session -t "\$_tmuxsess" -s "\$(whoami)"
				;;
			
			view)
				"\$_tmuxcmd" attach-session -t "\$_tmuxsess" -s "\$(whoami)" -r
				;;
			
			exec)
				shift; shift
				"\$_tmuxcmd" send-keys "\$(printf '%q' "\$@")" ENTER \\; pipe-pane 'cat > /dev/stdout'
				;;
			
			update)
				systemctl stop avorion@*
				echo "Updating Avorion"
				"\$_tmuxcmd" send-keys "+force_install_dir ${INSTALLDIR}/server_files +app_update \$AVORIONSTEAMID validate" ENTER \\; pipe-pane 'cat > ${INSTALLDIR}/server_files/steamupdate.log'
				( tail -f -n0 '${INSTALLDIR}/server_files/steamupdate.log' & ) | tee | grep -q Completed
				systemctl start avorion@*
				;;
			
			?)
				printf '%s\\n' "Invalid argument passed: <\$(printf '%q' "\$1")>"
				exit
				;;
		esac
	}

	showinstances
fi
_EOF_


##############
# Service Init
##############

########
seperate
########

echo "Starting and enabling services."
echo "(This may take some time)"
systemctl start steamcmd
systemctl start avorion@"$(basename $AVORIONDIR)"
systemctl enable steamcmd
systemctl enable avorion@"$(basename $AVORIONDIR)"

systemctl status steamcmd >/dev/null || {
	echo 'Steam failed to start properly'
	echo "Please run: systemctl status steamcmd"
	((FAILED+=1))
}

systemctl status avorion@"$(basename "$AVORIONDIR")" >/dev/null || {
	echo 'Avorion failed to start'
	echo "Please run: systemctl status avorion@$(basename "$AVORIONDIR")"
	((FAILED+=1))
}

if (( "$FAILED" > 0 )); then
	echo "Installation was a failure, or services did not start correctly. Service failures: $FAILED"
	exit 1
else
	echo "Installation successful."
	exit 0
fi
