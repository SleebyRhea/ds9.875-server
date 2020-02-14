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
	/usr/local/share/avorioncmd

if ! ( cd ./root >/dev/null 2>&1 ); then
	echo "Unable to switch to root. Please make sure to run this from the project root"
	exit 1
fi

source etc/avorionsettings.conf

if [ -z "$AVORION_SERVICEDIR" ] || [ -z "$AVORION_ADMIN_GRP" ] || [ -z "$AVORION_USER" ]; then
	echo "Avorion instance definitions missing"
	exit 1
fi

echo "Ensuring $AVORION_USER user and $AVORION_ADMIN_GRP exist"
useradd "$AVORION_USER" -d "$AVORION_SERVICEDIR" -c "Avorion Service User" -r -s /sbin/nologin
groupadd "$AVORION_ADMIN_GRP"

if ! mkdir -p /usr/local/share/avorioncmd/cronjobs; then
	echo "Failed to create cronjobs directory!"
	exit 1
fi

if ! mkdir -p "$AVORION_SERVICEDIR"/{mods,sockets}; then
	echo "Failed to create service directories!"
	exit 1
fi

install -m 644 ./root/etc/avorioncmd-tmux.conf /etc/avorioncmd-tmux.conf
install -m 644 ./root/etc/avorionsettings.conf /etc/avorionsettings.conf
install -m 644 ./root/etc/systemd/system/avorionservers.target /etc/systemd/system/avorionservers.target
install -m 644 ./root/etc/systemd/system/avorion@.service /etc/systemd/system/avorion@.service
install -m 0440 ./root/etc/sudoers.d/avorion-ds9 /etc/sudoers.d/avorion-ds9
install -m 755 ./root/usr/local/bin/avorion-cmd /usr/local/bin/avorion-cmd
install -m 644 -t usr/local/share/avorioncmd/cronjobs ./root/usr/local/share/avorioncmd/cronjobs/*

\cp -rf "$AVORION_SERVICEDIR"/mods/ ./root/srv/avorion/mods/*

echo "Setting permissions for <${AVORION_SERVICEDIR}>:"

chown -R "$AVORION_USER":"$AVORION_ADMIN_GRP" "$AVORION_SERVICEDIR"
__filesys="$(df "$AVORION_SERVICEDIR" 2>&1 | tail -n 1 | awk '{printf "%s",$1}')"
if { echo "$__filesys" | grep -q -e 'type xfs' -e 'acl' >/dev/null 2>&1; }; then
	setfacl -b "$AVORION_SERVICEDIR"
	chmod g+s "$AVORION_SERVICEDIR"
	setfacl -m -R u:"$AVORION_USER":rwX "$AVORION_SERVICEDIR"
	setfacl -m -R g:"$AVORION_ADMIN_GRP":rwX "$AVORION_SERVICEDIR"
	setfacl -d -m u:"$AVORION_USER":rwX "$AVORION_SERVICEDIR"
	setfacl -d -m g:"$AVORION_ADMIN_GRP":rwX "$AVORION_SERVICEDIR"
fi

systemctl daemon-reload

echo 'Done. Make sure to set the ADMIN value in </etc/systemd/system/avorion@.service> and run sudo systemctl daemon-reload!!'
echo 'Cronjobs are left off for now, configure them via crontab -e'