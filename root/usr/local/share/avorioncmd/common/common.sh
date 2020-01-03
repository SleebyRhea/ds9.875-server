#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
	echo 'common.sh should *only* be sourced from a bash shell/script'
	exit 1
fi

## Script Vars
readonly CMDNAME="$(basename "$0")"
readonly CMDVERS='2.0-testing rev17'
readonly EDATE="$(date +%s)"

## Color Codes
readonly __t_clear='\033[0m'      ## Clear Text Props
readonly __f_bold='\033[1m'       ## Bold Coloring
readonly __f_dgray='\033[1;30m'   ## Dark Gray
readonly __f_lred='\033[1;31m'    ## Light Red
readonly __f_lgreen='\033[1;32m'  ## Light Green
readonly __f_yellow='\033[1;33m'  ## Yellow
readonly __f_lblue='\033[1;34m'   ## Light Blue
readonly __f_lpurple='\033[1;35m' ## Light Purple
readonly __f_lcyan='\033[1;36m'   ## Light Cyan readonly 
readonly __f_white='\033[1;37m'   ## White
readonly __f_black='\033[0;30m'   ## Black
readonly __f_red='\033[0;31m'     ## Red
readonly __f_green='\033[0;32m'   ## Green
readonly __f_orange='\033[0;33m'  ## Brown/Orange
readonly __f_blue='\033[0;34m'    ## Blue
readonly __f_purple='\033[0;35m'  ## Purple
readonly __f_cyan='\033[0;36m'    ## Cyan
readonly __f_lgray='\033[0;37m'   ## Light Gray
readonly __b_white='\u001b[47m'   ## White

## Regex Matches
readonly __unit_string='^[[:space:]]*avorion@[^[:space:]][^[:space:]]*.service[[:space:]][[:space:]]*loaded[[:space:]][[:space:]]*active[[:space:]][[:space:]]*running'

## Flags and Misc
declare FORCE=0
declare CRON=0
declare VERBOSE=0
declare NOSCREENCHECK=0

# void say <string, ...>
#	Ouput the strings passed to stdout and return
function say () {
	for _l; do printf '%s\n' "${_l}"; done
	return 0
} 

# bool dbssay <string, ...>
#	If the script is currently in debug mode, `say`
#	the arguments passed to this function. Otherwise,
#	return code 1
function dbgsay () {
	if (( "${VERBOSE}" > 0 )); then
		for __arg; do
			printf "${__f_yellow}%s${__t_clear}\n" "$__arg"
		done
	fi
}

# int die <options> <string>
#	Output the strings passed to stdout then exit
#	with status code 1 (or the code given with -c)
function die () {
	local _code=1
	if [[ "$1" == '-c' ]] && [[ "$2" =~ ^[0-9][0-9]*$ ]]; then
		_code="$2"
		shift; shift
	fi

	say "Error: $1"
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
				say "Please enter yes or no."
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

# int __validate_setting_conf <void>
#	Run validation checks on the configuration file.
#	This function checks all of the non-blank lines
#	present in the conf file and ensures that they
#	are both valid configs, and that the settings
#	provided are valid.
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

	source /etc/avorionsettings.conf
	
	return 0
}

# bool __check_requirements <void>
#	Checks required software versions and exits if either
#	the required software is not present in $PATH or if it
#	does not meet the minimum version requirements.
function __check_requirements () {
	local -A _requires
	local _prog _arg _string
	
	# Required version strings, prepended with the argument
	# that will invoke them.
	_requires[sed]='--version=^sed \(GNU sed\) [0-9]{0,1}[4-9].*'
	_requires[bash]='--version=^GNU bash, version [0-9]{0,1}[4-9].*'
	_requires[tmux]='skip'
	_requires[mktemp]='skip'

	for _prog in "${!_requires[@]}"; do
		_arg="${_requires["$_prog"]%%=*}"
		_string="${_requires["$_prog"]##*=}"

		command -v "$_prog" >/dev/null 2>&1 ||\
			die "${_prog} is required but is either not installed, or not in the execution PATH"

		[[ "${_requires[$_prog]}" == 'skip' ]] &&\
			continue

		[[ "$("$_prog" "$_arg")" =~ $_string ]] ||\
			die "${_prog} doesnt meet the minimum version requirements"
	done
}

# int __validate_process_exec <ARGV>
#	Run various pre-checks prior to running the main
#	script body to ensure that the process execution
#	is both valid, and that all of the required pkgs
#	have been installed. If any of these pre-checks
#	fail, exit the script with error code 1 and give
#	an explanation.
function __assert_valid_execution () {
	__check_requirements

	# Make sure the user is part of the admin group or is root. The 
	# regex is used here to prevent unintentionally matching groups
	# that contain the group string but dont exactly match it. Since
	# root should be able to do anything, we also check for id 0
	if [[ ! "$(groups)" =~ (^$AVORION_ADMIN_GRP | $AVORION_ADMIN_GRP | $AVORION_ADMIN_GRP$) ]] && [[ "$(id -u)" != 0 ]]; then
		die "This command can only be run by a user with the group <${AVORION_ADMIN_GRP}> or by root."
	fi
}

function getactive () {
	systemctl list-units 'avorion@*' |\
	   	grep "$__unit_string" |\
	   	awk '{print $1}' 2>/dev/null |\
	   	sed 's,^avorion@,,; s,\.service$,,'
}

## Prechecks before returning to the primary point of execution
__check_requirements
__assert_valid_execution
__validate_setting_conf

## Done last, and declared so that this can be overidden if need be
declare TMP_FILE="$(mktemp)"
if [[ -z "$TMP_FILE" ]]; then
	echo "Cannot generate tmpfile! Check tmp usage."
	exit 1
elif [[ ! -w "$TMP_FILE" ]]; then
	echo "Cannot write to tmpfile <$TMP_FILE>. Check tmp permissions."
	exit 1
fi

