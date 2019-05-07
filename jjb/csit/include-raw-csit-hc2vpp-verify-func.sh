#!/bin/bash

# Parse optional arguments from gerrit comment trigger
for i in ${GERRIT_EVENT_COMMENT_TEXT}; do
    case ${i} in
        *honeycomb=*)
            hc_version=`echo "${i}" | cut -d = -f2-`
        ;;
        *)
        ;;
    esac
done

# If HC variable is set, check honeycomb version.
if [[ -n "${hc_version}" ]]; then
    if [[ "${hc_version}" == *"-release" ]]; then
        # we are going to test release build. All release
        # packages should be already present in release repo
        STREAM="release"
        echo "STREAM set to: ${STREAM}"
    fi
fi

# execute csit bootstrap script if it exists
if [[ ! -e bootstrap-hc2vpp-integration.sh ]]
then
    echo 'ERROR: No bootstrap-hc2vpp-integration.sh found'
    exit 1
else
    # make sure that bootstrap.sh is executable
    chmod +x bootstrap-hc2vpp-integration.sh
    # run the script
    ./bootstrap-hc2vpp-integration.sh ${STREAM} ${OS}
fi

# vim: ts=4 ts=4 sts=4 et :
