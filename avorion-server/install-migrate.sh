#! /usr/bin/env bash
#
# Avorion Migrator/Service Installer
# IDGAF license -- Do whatever you want with this

AVORIONDIR=''
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
done

# Check if the supplied $AVORIONDIR has a server.ini file present and prompt the
# user for confirmation to proceed if it does NOT
if [[ ! -f "$AVORIONDIR"/server.ini ]]; then
	if ! yesno "The directory $AVORIONDIR does not contain a server.ini file. Is this correct?"; then
		AVORIONDIR=''
	fi
fi

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
if ! grep -q "$GRP" /etc/group >/dev/null; then
	groupadd "$GRP" \
		|| exit 1
fi

if ! grep -q "$USR" /etc/passwd; then
	useradd avorion -d "$INSTALLDIR" --no-create-home -g "$GRP" -r \
		|| exit 1
fi

sudo -u avorion "$STEAMCMD" +login anonymous +force_install_dir "$INSTALLDIR"/server_files +app_update 565060 validate +exit \
	|| exit 1

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
