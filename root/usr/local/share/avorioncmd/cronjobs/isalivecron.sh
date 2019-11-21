#! /usr/bin/env bash
declare __RCON='/usr/local/bin/rcon-cli'
declare __AVOORION_CMD='/usr/local/bin/avorion-cmd'

function main () {
	__validate_setting_conf &&\
		source /etc/avorionsettings.conf
	if [[ -f /tmp/runningavorionbackup ]]; then
		exit 0
	fi

	if ! $__RCON --host 173.208.246.242 --port 27015 --password 90210 status; then
		$__AVOORION_CMD restart +all
	fi
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
