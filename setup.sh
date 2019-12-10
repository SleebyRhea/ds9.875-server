#! /usr/bin/env bash
if ! [ "$(id -u)" = 0 ]; then
	echo "Please run this as root"
	exit 1
fi

if pgrep AvorionServer >/dev/null 2>&1; then
	echo "Please make ensure Avorion is off and disabled"
	exit 2
fi

if ! [ -e working ] && ! [ -d working ]; then
	if ! mkdir working >/dev/null; then
		echo "Failed to create 'working' directory"
		exit 3
	fi
fi

if ! [ -e backup ]; then
	if ! mkdir backup >/dev/null; then
		echo "Failed to create 'working' directory"
		exit 3
	fi
fi

( cd backup || exit 3 )
( cd working || exit 3 )

mv -t backup/ \
	/etc/avorioncmd-tmux.conf \
	/etc/avorionsettings.conf \
	/etc/systemd/system/avorionservers.target \
	/etc/systemd/system/avorion@.service \
	/etc/systemd/system/steamcmd.service \
	/usr/local/bin/avorion-cmd \

if ! ( cd ./root >/dev/null 2>&1 ); then
	echo "Unable to switch to root. Please make sure to run this from the project root"
	exit 1
fi

install -m 644 ./root/etc/avorioncmd-tmux.conf /etc/avorioncmd-tmux.conf
install -m 644 ./root/etc/avorionsettings.conf /etc/avorionsettings.conf
install -m 644 ./root/etc/systemd/system/avorionservers.target /etc/systemd/system/avorionservers.target
install -m 644 ./root/etc/systemd/system/avorion@.service /etc/systemd/system/avorion@.service
install -m 0440 ./root/etc/sudoers.d/avorion-ds9 /etc/sudoers.d/avorion-ds9
install -m 755 ./root/usr/local/bin/avorion-cmd /usr/local/bin/avorion-cmd

source /etc/avorionsettings.conf

echo "Ensuring $AVORION_USER user and $AVORION_ADMIN_GRP exist"
useradd "$AVORION_USER" -d /srv/"$AVORION_USER" -c "Avorion Service User" -r -s /sbin/nologin
groupadd "$AVORION_ADMIN_GRP"

if [ -z "$AVORION_SERVICEDIR" ] || [ -z "$AVORION_ADMIN_GRP" ] || [ -z "$AVORION_USER" ]; then
	echo "Avorion instance definitions missing"
	exit 1
fi

if ! [ -d "$AVORION_SERVICEDIR" ]; then
	mkdir "$AVORION_SERVICEDIR"
fi

if ! [ -d "${AVORION_SERVICEDIR}/sockets" ]; then
	mkdir "$AVORION_SERVICEDIR"
fi


echo "Setting permissions for <${AVORION_SERVICEDIR}>:"

chown -R "$AVORION_USER":"$AVORION_ADMIN_GRP" "$AVORION_SERVICEDIR"
__filesys="$(df "$AVORION_SERVICEDIR" 2>&1 | tail -n 1 | awk '{printf "%s",$1}')"
if { echo "$__filesys" | grep -q 'type xfs' >/dev/null 2>&1; } || { echo "$__filesys" | grep -q acl >/dev/null 2>&1; }; then
	setfacl -b "$AVORION_SERVICEDIR"
	chmod g+s "$AVORION_SERVICEDIR"
	setfacl -d -m u:"$AVORION_USER":rwX "$AVORION_SERVICEDIR"
	setfacl -d -m g:"$AVORION_ADMIN_GRP":rwX "$AVORION_SERVICEDIR"
fi

echo 'Done. Make sure to set the ADMIN value in </etc/systemd/system/avorion@.service>'
