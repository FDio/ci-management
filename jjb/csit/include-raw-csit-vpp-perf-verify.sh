#!/bin/bash

export TRIGGER=`echo ${GERRIT_EVENT_COMMENT_TEXT} | grep -oE '(csit-perftest)+[[:space:]](.+)'`
export TEST_TAG="VERIFY-PERF-PATCH"
export TEST_TAG_ARRAY=${TRIGGER#$"csit-perftest"}

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
