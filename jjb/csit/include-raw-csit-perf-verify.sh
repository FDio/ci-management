#!/bin/bash

set -xeu -o pipefail

if [[ ${GERRIT_EVENT_TYPE} == 'comment-added' ]]; then
    TRIGGER=`echo ${GERRIT_EVENT_COMMENT_TEXT} \
        | grep -oE '(perftest$|perftest[[:space:]].+$)'`
else
    TRIGGER=''
fi

# grep to see where minion is running
grep search /etc/resolv.conf  || true

# Export test tags as string.
export TEST_TAG_STRING=${TRIGGER#$"perftest"}

# execute csit bootstrap script if it exists
if [ ! -e bootstrap-verify-perf.sh ]
then
    echo 'ERROR: No bootstrap-verify-perf.sh found'
    exit 1
fi

# make sure that bootstrap-verify-perf.sh is executable
chmod +x bootstrap-verify-perf.sh
# run the script
./bootstrap-verify-perf.sh

# vim: ts=4 ts=4 sts=4 et :
