#!/bin/bash
#
# common.sh:
#	Common functions used for all bash based scripts for
#	the avorioncmd utility set. Also performs process execution
#	validation checks on sourcing. This script is NOT intended
#	to be run on its own, and should be sourced as early as
#	possible by the calling script.

# shellcheck disable=SC2034
if [ -z "$BASH_VERSION" ]; then
	echo 'common.sh should *only* be sourced from a bash shell/script'
	exit 1
fi

## Script Vars
readonly CMDNAME="$(basename "$0")"
readonly CMDVERS='2.0-testing rev18'
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
readonly REGEX_AVORIONUNIT='^[[:space:]]*avorion@[^[:space:]][^[:space:]]*.service[[:space:]][[:space:]]*loaded[[:space:]][[:space:]]*active[[:space:]][[:space:]]*running'

## Flags and Misc
declare FORCE=0
declare CRON=0
declare VERBOSITY=0
declare NOSCREENCHECK=0
declare TMP_FILE=0
declare ASSUMEANSWER=0
declare SHOWTIMESTAMPS=0


####################################
## Execution Validation Functions ##
####################################

# int __validate_setting_conf <void>
#	Run validation checks on the configuration file.
#	This function checks all of the non-blank lines
#	present in the conf file and ensures that they
#	are both valid configs, and that the settings
#	provided are valid.
function __validate_setting_conf () {
	if ! [[ -f /etc/avorionsettings.conf ]]; then
		die "Avorion configuration file not found"
	fi

	local -A __conf_vars __index
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
		if [[ "${__l}" =~ ^[[:space:]]*#*$ ]]; then
			continue
		fi

		# Ensure the line contains no invalid symbols
		if [[ "${__l}" =~ $__bad_symbols ]]; then
			die "${__err} -- Invalid chars present: <$( printf '%q' "${__l}") >"
		fi
		
		# Ensure that the variable declaration syntax is valid.
		# We also use this to assign the captured strings to the
		# BASH_REMATCH environment variable (bash does this automatically)
		if ! [[ "${__l}" =~ ^([^[:space:]][^[:space:]]*)=([^[:space:]][^[:space:]]*)$ ]]; then
			die "${__err} -- Bad syntax: <$( printf '%q' "${__l}")>"
		fi

		# Ensure that the variable being declared is actually
		# a setting that we will be making use of.
		# 
		# NOTE: About the wierd printf '%q' syntax, %q is an option that
		# can be given to the printf Bash builtin that will automatically
		# escape out any special characters. In this context, it is used
		# to prevent special characters from potentially executing. This
		# is also accomplished above, but I am paranoid
		__index="$(printf '%q' "${BASH_REMATCH[1]}")"
		if [[ -z "${__conf_vars[$__index]}" ]]; then
			die "${__err} -- Invalid setting: <$__index>"
		fi

		# Make sure that the values given to the variable match a
		# set syntax.
		#
		# TODO: Perform some deeper checks here. IE, we would
		#       want to catch things like having the admin group
		#       set to sudo.
		if ! [[ "$( printf '%q' "${BASH_REMATCH[2]}" )" =~ ${__conf_vars[$__index]} ]]; then
			die "${__err} -- Invalid assignment: <$( printf '%q' "${__l}")>"
		fi
	done < /etc/avorionsettings.conf

	# shellcheck disable=SC1091
	source /etc/avorionsettings.conf
}

# bool __check_requirements <void>
#	Checks required software versions and exits if either
#	the required software is not present in $PATH or if it
#	does not meet the minimum version requirements.
#
#	Optional Switches:
#		None
function __check_requirements () {
	local -A __requires
	local __prog __arg __string
	
	# Required version strings, prepended with the argument
	# that will invoke them.
	__requires[sed]='--version=^sed \(GNU sed\) [0-9]{0,1}[4-9].*'
	__requires[bash]='--version=^GNU bash, version [0-9]{0,1}[4-9].*'
	__requires[tmux]='skip'
	__requires[mktemp]='skip'

	for __prog in "${!__requires[@]}"; do
		__arg="${__requires["$__prog"]%%=*}"
		__string="${__requires["$__prog"]##*=}"

		if ! command -v "$__prog" >/dev/null 2>&1; then
			die "${__prog} is required but is either not installed, or not in the execution PATH"
		fi

		if [[ "${__requires[$__prog]}" == 'skip' ]]; then
			continue
		fi

		if ! [[ "$("$__prog" "$__arg")" =~ $__string ]]; then
			die "${__prog} doesnt meet the minimum version requirements"
		fi
	done
 
	if [[ ! -f "$STEAMCMD_BIN" ]] && ! command -v "$STEAMCMD_BIN" >/dev/null 2>&1; then
		die "SteamCMD definition is undefined, or invalid"
    fi 

	return 0
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

	## No point in continuing if the service directory doesnt exist/cant be accessed.
	if ! ( cd "$AVORION_SERVICEDIR" >/dev/null 2>&1 ); then
		die "Failed to cd into service directory <$AVORION_SERVICEDIR>"
	fi
}

# bool __check_screen_tmux (void)
#	Return true if we are in a screen/tmux session, otherwise
#	return false.
function __check_screen_tmux () {
	# Skip this if --no-screen-enforce is passed
	if (( NOSCREENCHECK > 0 )); then
		return 1
	fi

	# Die if we are running in a screen or tmux session.
	if [[ -n "$TMUX" ]] || [[ "$TERM" =~ ^(screen|tmux) ]] || [[ -n "$TMUX_PANE" ]] || [[ -n "$STY" ]]; then
		return 0
	fi

	return 1
}


#####################
## Setup Functions ##
#####################

# void __setup_tmp (void)
#	Creates and sets our global tmpfile for IO manipulation, it also
#	ensures that our templock directory exists, and quits if we cant
#	create it.
#
#	Optional Switches:
#		None
function __setup_tmp () {
	TMP_FILE="$(mktemp)"
	if [[ -z "$TMP_FILE" ]]; then
		echo "Cannot generate tmpfile! Check tmp usage."
		exit 1
	elif [[ ! -w "$TMP_FILE" ]]; then
		echo "Cannot write to tmpfile <$TMP_FILE>. Check tmp permissions."
		exit 1
	fi
}


#####################
## Operation Locks ##
#####################

# bool setlock (str lockname)
#	Creates a lockfile for use with funtions that can
#	only ever have one instance running, or to detect
#	when certain operations are underway
#
#	Returns:
#		0	Successful lock
#		1	Failed lock
#
#	Optional Switches:
#		--clear		Clears the lock specified
function setLock () {
	local __lockname="$1"
	local __clearlock=0
	__lockname="${__lockname//[^a-zA-Z]/}"
	
	for __arg; do
		shift
		if [[ "$__arg" == "--clear" ]]; then
			__clearlock=1
		fi
		set - "$@" "$__arg"
	done

	case "$__clearlock" in
		0 )
			if ! checkLock "$__lockname"; then
				if ! $SUDOPREFIX printf '%s' "$$" > "/tmp/avorion.$__lockname"; then
					echo "Unable to create lock: $__lockname" >&2
					return 1
				fi
				return 0
			fi
			;;
		
		1 )
			if checkLock "$__lockname"; then
				if ! $SUDOPREFIX rm "/tmp/avorion.$__lockname"; then
					echo "Unable to remove old lockfile!" >&2
					return 1
				fi
			fi
			;;
	esac

	return 0
}

# bool checkLock (str lockname)
#	Detects whether a lock is currently
#	in place.
#
#	Returns:
#		0	Lock is in place
#		1	No lock in place
#
#	Optional Switches:
#		None
function checkLock () {
	local __lockname="$1"
	__lockname="${__lockname//[^a-zA-Z]/}"
	
	if [[ -f /tmp/avorion."$__lockname" ]]; then
		return 0
	fi

	return 1
}


########################
## Printing Functions ##
########################

# void message (str ...)
#	Output a message (or messages) with a given formatting.
#
#	Optional Switches:
#		--debug		Specify that the message is to be used when verbosity
#					is higher then 2 (aka, when debug mode is enabled).
#
#		--verbose	Specify that the message should only be output when
#					verbosity is higher than 1 (the default)
#
#		--header	Specify a header-like formatting. Usually used
#					when beginning execution of a function.
#
#		--function	(default) Specify a sub header-like formatting. Usually 
#					used when a function has output that falls under a header.
#
#		--error		Formatting that indicates an error.
function message () {
	local __color="$__f_dgray"
	local __formatting='%b>> %s%b\n'
	for __arg; do 
		shift
		case "$__arg" in
			--debug )
				if (( VERBOSITY < 3 )); then
					return 0
				fi

				__color="$__f_yellow"
				__formatting='%bDBG> %s%b\n'
				;;

			--verbose )
				if (( VERBOSITY < 2 )); then
					return 0
				fi
				;;

			--header )
				__formatting='%b%s\n'
				__color="$__f_white"
				;;
			
			--function )
				__color="$__f_dgray"
				__formatting='%b>> %s%b\n'
				;;
			
			--error )
				__color="$__f_red"
				__formatting='%bERR> %s%b\n'
				;;
		esac
		set -- "$@" "$__arg"
	done
	
	#shellcheck disable=SC2059
	for __arg; do
		if (( SHOWTIMESTAMPS > 0 )); then
			printf '[%s] ' "$(date +'%Y-%m-%d %I:%M%z')"
		fi
		printf "$__formatting" "$__arg"
	done
}

#######################
## Utility Functions ##
#######################

# int die <options> (str)
#	Output the strings passed to stdout then exit
#	with the default status code if 1
#
#	Optional Switches:
#		-c		Set the status code to return on exit (1-255)
function die () {
	local __code=1

	## Catch -c
	if [[ "$1" == '-c' ]] && [[ "$2" =~ ^[0-9][0-9]*$ ]]; then
		__code="$2"
		shift; shift
	fi
	
	## Print the main error, shift, and then print any other
	## positional parameters to stdout normally.
	echo "Error: $1"; shift
	for __arg; do
		echo "$__arg"
	done

	exit "$__code"
}

# bool yesno (str prompt)
#	Get a yes or no response from the user and return accordingly
#	(0 for yes, 1 for no). If a string is passed, provide the user
#	with that string as a prompt.
#
#	If the environmental variable ASSUMEANSWER is non-zero, then
#	determine if it is a valid value and return accordingly without
#	prompting the user. 1=yes, 2=no
#
#	Optional Switches:
#		None
function yesno () {
	local _prompt _answer
	_prompt="${1-Yes/No}"

	## Implements --assume-yes and --assume-no. Since that
	## global will *only* ever be 0-2, with 0 == off, 1 == yes,
	## and 2 == no then just subtract 1 and we have our return
	##
	## Anything else is an error and is skipped with an error
	## being thrown.
	if (( ASSUMEANSWER > 0 && ASSUMEANSWER < 3)); then
		return "$((ASSUMEANSWER-1))"
	elif (( ASSUMEANSWER > 3 )); then
		message --debug "ASSUMEANSWER has an unknown value: [$ASSUMEANSWER]"
	fi

	while true; do
		printf "[%s]> " "${_prompt}"
		read -r _answer
		case "${_answer}" in
			[yY][eE][sS] | [yY] )
				return 0
				;;
			[nN][oO] | [nN] )
				return 1
				;;
			?)
				echo "Please enter yes or no."
				;;
		esac
	done
}

# int plural (int)
#	Given an int, print an s to the caller if said
#	int does not equal 1
#
#	Optional Switches:
#		None
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

# void showtime (int time)
#	Given a number of seconds, output a string describing
#	how many hours, minutes, and/or seconds are remaining.
#	The format is minimal so, for example, if the number is
#	10, the output is:
#		10 seconds
#	
#	Likewise for minutes and hours:
#		60		1 minute
#		120		2 minutes
#		3600	1 hour
#
#	NOTE: This function *intentionally* omits seconds if there
#	are more than 60!
#
#	Optional Switches:
#		None
function showtime () {
	if ! [[ "$1" =~ ^[0-9][0-9]*$ ]]; then
		die "Invalid variable given to timemetric: <$1>"
	fi

	local __output __hour __min __time
	
	## Save ourselves some pointless math at the cost of
	## a few seconds worth of accuracy. If need be, can
	## be revised later on.
	if (( $1 < 60)); then
		printf '%s second%s' "$1" "$(plural "$1")"
		return 0
	fi

	__output=''
	__time="$1"
	__hour=$((__time/3600))
	__min=$((__time%3600))
	__min=$((__min/60))

	if (( __hour > 0 )); then
		__output="${__hour} hour$(plural "$__hour")"
		if (( __min > 0 )); then
			__output="${__output} and "
		fi
	fi

	if (( __min > 0 )); then
		__output="${__output}${__min} minute$(plural "$__min")"
	fi

	printf '%s' "$__output"
}

# void getactive (void)
#	Prints a list of active avorion@ units to stdout. Unit
#	formatting is stripped of all occurences of avorion@ and 
#	.service to standardize all uses of said instances. Prevents
#	cases where the service name is repeated ala:
#		avorion@avorion@avorion@galaxyname.service
#
#	Optional Switches:
#		None
function getactive () {
	systemctl list-units 'avorion@*' |\
	   	grep "$REGEX_AVORIONUNIT" |\
	   	awk '{print $1}' 2>/dev/null |\
	   	sed 's,avorion@,,; s,\.service,,'
}


###########
## BEGIN ##
###########

## Prechecks before returning to the primary point of execution
__validate_setting_conf
__assert_valid_execution
__setup_tmp

## Our final declarations. These need to be performed *after*
## the initial prechecks and sourcing, so we just do them last.
readonly SUDOPREFIX="sudo -u ${AVORION_USER} -g ${AVORION_ADMIN_GRP} -n"

## Process arguments that are common between all scripts that use
## common.sh. Removes the paramters found in the positional params
## array ($@)
for __arg; do
	shift
	case "$__arg" in
		--debug )
			VERBOSITY=3
			continue
			;;
		
		--verbose )
			if (( VERBOSITY < 3 )); then
				VERBOSITY=2
				continue
			fi
			;;

		--allow-screen )
			NOSCREENCHECK=1
			continue
			;;

		--cron )
			CRON=1
			continue
			;;

		--assume-yes )
			ASSUMEANSWER=1
			;;
		
		--assume-no )
			ASSUMEANSWER=2
			;;
			
		--log-time )
			SHOWTIMESTAMPS=1
			;;
	esac
	set -- "$@" "$__arg"
done

message --debug "Sourced common.sh"