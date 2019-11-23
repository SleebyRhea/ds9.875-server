#! /usr/bin/env bash

declare __AVORIONCMD="/usr/local/bin/avorion-cmd"
declare __LASTBACKUP=''
declare __LOGFILE=''
declare __SKIPBACKUP=0
declare __ETIME="$(date +%s)"
declare __MESSAGE='Server backup starts in'
declare __RETENTION=7

function main() {
	__validate_setting_conf &&\
		source /etc/avorionsettings.conf

	## Prevent backups from being taken if its been less than
	## 24 hours
	if [[ -f "$AVORION_BAKDIR/lastfullbackup" ]]; then
		__LASTBACKUP="$(cat "$AVORION_BAKDIR/lastfullbackup" | tr -d '\n')"
		printf 'Last Backup: %s\n' "$__LASTBACKUP"
		if (( $((__ETIME - __LASTBACKUP)) < 86400 )); then
			__SKIPBACKUP=1
			__MESSAGE='Server restart starts in'
		fi
	fi

	local __active_units=( $(getactive) )
	local __failed=0
	local __incrdir="${AVORION_BAKDIR}/incremental"
	local __backupdir="${AVORION_BAKDIR}/compressed"
	local __logdir="${AVORION_BAKDIR}/logs"
	local __backup_file="${__backupdir}/backup-${__ETIME}.tar.gz"
	local __LOGFILE="$__logdir/backup-${__ETIME}.log"

	echo "Grabbing active instances..."
	for __dir in "$__logdir" "$__backupdir" "$__incrdir"; do
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

	echo "Performing backup rsync..."
	if (( __SKIPBACKUP < 1 )); then
		printf "Syncing contents of $AVORION_SERVICEDIR to ${__incrdir}:\n"
		if ! __perform_rsync "$AVORION_SERVICEDIR" "$__incrdir" >> "$__LOGFILE" 2>&1; then
			echo "Failed to perform rsync!"
			((__failed++))
		fi
		printf -- '- - - - - - - -\n\n' >> "$__LOGFILE"
	fi

	echo "Restarting instances..."
	if (( "${#__active_units[@]}" > 0 )); then
		for __inst in "${__active_units[@]}"; do
			echo "Restarting $__inst"
			$__AVORIONCMD start "$__inst" --cron
		done
	fi
	rm /tmp/runningavorionbackup

	echo "Compressing backups...."
	if (( __SKIPBACKUP < 1 )); then
		printf "Compressing contents of $__incrdir to $__backup_file\n"
		if (( __failed > 0 )); then
			echo "Failed to perform backup rsync. Please check the log at <$__LOGFILE>!"
			exit 1
		fi

		if ! __perform_compression "$__backup_file" "$__incrdir" >> "$__LOGFILE" 2>&1; then
			echo "Compression failed! File: $__backup_file"
			echo "Failed to perform backup compression. Please check the log at <$__LOGFILE>!"
			exit 1
		fi

		if ! echo "$__ETIME" > "$AVORION_BAKDIR/lastfullbackup" 2>>"$__LOGFILE"; then
			echo "Failed to set $AVORION_BAKDIR/lastfullbackup. Please check the log at <$__LOGFILE>"
			exit 1
		fi
	fi

	if ! __perform_backup_rotation "$__backupdir" "$__RETENTION"; then
		echo "Failed to rotate backups" | tee -a $__LOGFILE
		exit 1 
	fi

	exit 1
}

function __perform_rsync () {
	rsync -av --chown="$AVORION_USER":"$AVORION_ADMIN_GRP" "$1/" "$2/"
	return $?
}

function __perform_compression () {
	tar --owner "$AVORION_USER" --group "$AVORION_ADMIN_GRP" -zvcf "$1" -C "$2" .
	return $?
}


function __perform_backup_rotation () {
	## Get all of the backup files in the compressed dir
	local -a __backup_files=( $(find "$1" -name 'backup-*.tar.gz') )
	local __failed=0

	## Check if the number of files is greater than our retention. If it is, its
	## to rotate
	if (( "${#__backup_files[@]}" > "$2" )); then

		## Acquire a new list of backups. We need to exclude the last n ($2) backups
		## from the list, as they are the most recent and *must* be kept. So, we reverse
		## the output using tac and delete the first 1 to n lines of output. We then overwrite
		## our previous array with the new files and delete everything left.
		__backup_files=( $(find "$1" -name 'backup-*.tar.gz' -mtime "+$2" | tac | sed "1,${2}d") )
		for __file in "${__backup_files[@]}"; do
			if ! rm -f "$__file" >> "$__LOGFILE"; then
				((__failed++))
			fi
		done
	fi

	return "$__failed"
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

	# Leaving this here for now, but this used to check for invalid options
	# being set in the configuration file
	# grep -qcvE "^(($(printf '%s' "${!__conf_vars[*]}" | tr ' ' '|'))=.*|\\s*)" /etc/avorionsettings.conf >/dev/null \
	#	|| return 1

	local i=0
	while read -r __l; do
		# Set current line count
		((i++))
		
		__err="Configuration error on line ${i} of /etc/avorionsettings.conf"
		
		# We dont care about blank lines and comments, so skip those
		[[ "${__l}" =~ ^[[:space:]]*#*$ ]] && continue

		# Ensure the line contains no invalid symbols
		[[ "${__l}" =~ $__bad_symbols ]] &&\
			die "${__err} -- Invalid chars present: <$( printf '%q' "${__l}") >"
		
		# Ensure that the variable declaration syntax is valid.
		# We also use this to assign the captured strings to the
		# BASH_REMATCH environment variable (bash does this automatically)
		[[ "${__l}" =~ ^([^[:space:]][^[:space:]]*)=([^[:space:]][^[:space:]]*)$ ]] ||\
			die "${__err} -- Bad syntax: <$( printf '%q' "${__l}")>"

		# Ensure that the variable being declared is actually
		# a setting that we will be making use of.
		# 
		# NOTE: About the wierd printf '%q' syntax, %q is an option that
		# can be given to the printf Bash builtin that will automatically
		# escape out any special characters. In this context, it is used
		# to prevent special characters from potentially executing. This
		# is also accomplished above, but I am paranoid
		[[ -z "${__conf_vars[$( printf '%q' "${BASH_REMATCH[1]}" )]}" ]] &&\
			die "${__err} -- Invalid setting: <$( printf '%q' "${BASH_REMATCH[1]}" )>"

		# Make sure that the values given to the variable match a
		# set syntax.
		#
		# TODO: Perform some deeper checks here. IE, we would
		#       want to catch things like having the admin group
		#       set to sudo.
		[[ "$( printf '%q' "${BASH_REMATCH[2]}" )" =~ ${__conf_vars[$( printf '%q' "${BASH_REMATCH[1]}" )]} ]] ||\
			die "${__err} -- Invalid assignment: <$( printf '%q' "${__l}")>"

	done < /etc/avorionsettings.conf
	
	return 0
}

#@@@@@@@@@@@#
# Utilities #
#@@@@@@@@@@@#

# int die <options> <string>
#	Output the strings passed to stdout then exit
#	with status code 1 (or the code given with -c)
function die () {
	local _code=1
	if [[ "$1" == '-c' ]] && [[ "$2" =~ ^[0-9][0-9]*$ ]]; then
		_code="$2"
		shift; shift
	fi

	printf "Error: $1\n"
	exit "$_code"
}

# bool yesno <string>
#	Get a yes or no response from the user and
#	return accordingly (0 for yes, 1 for no).
#	If a string is passed, provide the user with
#	that string as a prompt.
function yesno () {
	local _prompt _answer
	_prompt="${1-Yes/No}"

	while true; do
		printf "[${_prompt}]> "
		read -r _answer
		case "${_answer}" in
			[yY][eE][sS] | [yY] )
				return 0
				;;
			[nN][oO] | [nN] )
				return 1
				;;
			?)
				printf "Please enter yes or no.\n"
				;;
		esac
	done
}

# int plural <int>
#	Given an int, print an s to the caller if said
#	int does not equal 1
function plural () {
	if [[ "$1" =~ ^[0-9]+$ ]]; then
		if (( $1 != 1 )); then
			printf '%s' 's'
			return 0
		fi
		return 0
	fi

	die "Function <plural> recieved <$1> rather than an int"
}

function getactive () {
	local __unit_string='^[[:space:]]*avorion@[^[:space:]][^[:space:]]*.service[[:space:]][[:space:]]*loaded[[:space:]][[:space:]]*active[[:space:]][[:space:]]*running'
	systemctl list-units 'avorion@*' | grep "$__unit_string" | awk '{print $1}' 2>/dev/null | sed 's,^avorion@,,; s,\.service$,,'
}

main "$@"
