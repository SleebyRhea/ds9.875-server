#!/bin/bash

SCRIPTPATH=$( cd "$(dirname "$(readlink -f "$0")")" ; pwd -P )
cd "$SCRIPTPATH"

_name="$1"; shift

export LD_LIBRARY_PATH=${SCRIPTPATH}/linux64
./bin/AvorionServer --galaxy-name "$_name" "$@"
