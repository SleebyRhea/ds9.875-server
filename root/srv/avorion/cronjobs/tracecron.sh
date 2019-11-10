#!/bin/bash
EDATE="$(date +%s)"
LOGCNT=1
/usr/local/bin/avorion-cmd exec +all '/status' >/dev/null 2>&1
mkdir -p "/srv/avorion/traces/$EDATE.trace" || exit 1
cp -t "/srv/avorion/traces/$EDATE.trace/" /srv/avorion/server_files/workerpool* /srv/avorion/server_files/profiling_stats.txt
find /srv/avorion/ds9server -maxdepth 1 -name 'serverlog *' -exec stat  -c "%n:%Y" {} \; | sort -t: -k2 -n | tail -n 3 | while read __log; do
        __log="${__log%%:*}"
        cp -t "/srv/avorion/traces/$EDATE.trace/" "${__log}"
        xz -9 "/srv/avorion/traces/$EDATE.trace/${__log##/srv/avorion/ds9server/}"
        mv "/srv/avorion/traces/$EDATE.trace/${__log##/srv/avorion/ds9server/}.xz" "/srv/avorion/traces/$EDATE.trace/${__log##/srv/avorion/ds9server/}-log${LOGCNT}.xz"
        ((LOGCNT++))
done

echo
echo "Traces saved to: /srv/avorion/traces/$EDATE.trace/"
echo "To decompress the .xz compressed files for viewing, run the following:"
echo "  xz -d -k /srv/avorion/traces/$EDATE.trace/*.xz"
echo
