#! /usr/bin/env bash

source /usr/local/share/avorioncmd/common/common.sh

declare __AVORIONCMD="/usr/local/bin/avorion-cmd"
declare __LASTBACKUP=''
declare __LOGFILE=''
declare __SKIPBACKUP=0
declare __ETIME="$(date +%s)"
declare __MESSAGE='[NOTIFICATION] Server backup starts in'
declare __RETENTION=7
declare __BACKUPTIMER=86400 #Seconds

function main() {
	## Prevent backups from being taken if its been less than 24 hours, or if
	## backups have been disabled
	if (( __SKIPBACKUP < 1 )); then
		if [[ -f "$AVORION_BAKDIR/lastfullbackup" ]]; then
			__LASTBACKUP="$(cat "$AVORION_BAKDIR/lastfullbackup" | tr -d '\n')"
			printf 'Last Backup: %s\n' "$__LASTBACKUP"
			if (( $((__ETIME - __LASTBACKUP)) < 86400 )); then
				__SKIPBACKUP=1
				__MESSAGE='[NOTIFICATION] Server restart starts in'
			fi
		fi
	else
		__MESSAGE='[NOTIFICATION] Server restart starts in'
	fi

	local __active_units=( $(getactive) )
	local __failed=0
	local __incrdir="/root/incremental"
	local __backupdir="${AVORION_BAKDIR}/compressed"
	local __logdir="/root/logs"
	local __backup_file="backup-${__ETIME}.tar.gz"
	local __LOGFILE="$__logdir/backup-${__ETIME}.log"

	## Make sure our directories are present
	for __dir in "$__logdir" "$__backupdir" "$__incrdir" "$__WORKING"; do
		if [[ ! -d "$__dir" ]]; then
			mkdir -p "$__dir" || {
				echo "Cannot create $__dir"
				exit 1
			}
		fi
	done

	if [[ "$1" != --skip-notification ]]; then
		echo "Sending restart notifications..."
		$__AVORIONCMD exec +all --cron "/say $__MESSAGE 1 hour"; sleep 15m
		$__AVORIONCMD exec +all --cron "/say $__MESSAGE 45 minutes"; sleep 15m
		$__AVORIONCMD exec +all --cron "/say $__MESSAGE 30 minutes"; sleep 15m
		$__AVORIONCMD exec +all --cron "/say $__MESSAGE 15 minutes"; sleep 5m
		$__AVORIONCMD exec +all --cron "/say $__MESSAGE 10 minutes"; sleep 5m

		for n in {5..2}; do
			$__AVORIONCMD exec +all --cron "/say $__MESSAGE $n minute$(plural $n)"
			sleep 1m
		done

		for n in {60..1}; do
			$__AVORIONCMD exec +all --cron "/say $__MESSAGE $n second$(plural $n)"
			sleep 1
		done
	fi

	echo "Stopping all instances..."
	$__AVORIONCMD stop +all --cron
	touch /tmp/runningavorionbackup

	if (( __SKIPBACKUP < 1 )); then
		echo "Performing backup rsync..."
		printf "Syncing contents of $AVORION_SERVICEDIR to ${__incrdir}...\n"
		if ! __perform_rsync "$AVORION_SERVICEDIR" "$__incrdir" >> "$__LOGFILE" 2>&1; then
			echo "Failed to perform rsync!"
			((__failed++))
		fi
		printf -- '- - - - - - - -\n\n' >> "$__LOGFILE"
	fi

	echo "Restarting instances..."
	if (( "${#__active_units[@]}" > 0 )); then
		for __inst in "${__active_units[@]}"; do
			if [[ -f "${AVORION_SERVICEDIR}/${__inst}/server.ini.replace" ]]; then
				echo "Replacing server.ini"
				cp "${AVORION_SERVICEDIR}/${__inst}/server.ini" "${AVORION_SERVICEDIR}/${__inst}/server.ini.bak-$__ETIME"
				mv "${AVORION_SERVICEDIR}/${__inst}/server.ini.replace"	"${AVORION_SERVICEDIR}/${__inst}/server.ini"
			fi
			echo ">> Restarting $__inst"
			$__AVORIONCMD start "$__inst" --cron
		done
	fi

	## Just set everything to the correct user/dir
	echo "Enforcing user ownership to be <${AVORION_USER}>:${AVORION_ADMIN_GRP}>"
	chown -R "$AVORION_USER":"$AVORION_ADMIN_GRP" /srv/avorion
	if [[ -e /srv/avorion/rconhostfile ]]; then
		chown root:root /srv/avorion/rconhostfile
	fi

	rm /tmp/runningavorionbackup

	if (( __SKIPBACKUP < 1 )); then
		echo "Compressing backups...."
		printf "Compressing contents of $__incrdir to $__backup_file\n"
		if (( __failed > 0 )); then
			echo "Failed to perform backup rsync. Please check the log at <$__LOGFILE>!"
			exit 1
		fi

		if ! __perform_compression "$__backup_file" "$__incrdir" >> "$__LOGFILE" 2>&1; then
			echo "Compression failed! File: $__backup_file"
			echo "Failed to complete compression routine. Please check the log at <$__LOGFILE>!"
			exit 1
		fi

		if ! echo "$__ETIME" > "$AVORION_BAKDIR/lastfullbackup" 2>>"$__LOGFILE"; then
			echo "Failed to set $AVORION_BAKDIR/lastfullbackup. Please check the log at <$__LOGFILE>"
			exit 1
		fi

		## Only rotate if backups were successful
		if ! __perform_backup_rotation "$__backupdir" ; then
			echo "Failed to rotate backups" | tee -a $__LOGFILE
			exit 1 
		fi

	fi

	exit 1
}

function __perform_rsync () {
	rsync -hvrPt --update "$1/" "$2/"
	return $?
}

function __perform_compression () {
	local __finalfile="${AVORION_BAKDIR}/compressed/${1}"
	local __failed=0
	
	tar --owner "$AVORION_USER"\
	   	--group "$AVORION_ADMIN_GRP"\
	   	-zvcf "$__WORKING/$1" -C "$2" .

	__failed="$(( __failed + $? ))"

	if ! mv -v "${__WORKING}/${1}" "$__finalfile"; then
		echo "Failed to move final backup tar to mounted backup!"
		((__failed++))
	fi

	if [[ -e "${__WORKING}" ]]; then
		if ! rm -rf "${__WORKING}"; then
			echo "Unable to remove working dir!"
			((__failed++))
		fi
	fi
	return "$__failed"
}

function __perform_backup_rotation () {
	## Get all of the backup files in the compressed dir
	printf  "Detecting backup count...."
	local -a __backup_files=( $(find "$1" -name 'backup-*.tar.gz') )
	local __failed=0
	echo "Found ${#__backup_files[@]} backups"
	echo "Retention is $__RETENTION"

	## Check if the number of files is greater than our retention. If it is, its
	## time to rotate
	if (( ${#__backup_files[@]} > __RETENTION )); then
		__backup_files=( $(find "$1" -name 'backup-*.tar.gz' -mtime "+$2") )

		echo "The following backups are older than $__RETENTION days old and will be reomved:"
		echo "$__backup_files"

		for __file in "${__backup_files[@]}"; do
			echo "Clearing $__file"
			if ! rm -f "$__file" >> "$__LOGFILE"; then
				((__failed++))
			fi
		done
	fi

	return "$__failed"
}

main "$@"
