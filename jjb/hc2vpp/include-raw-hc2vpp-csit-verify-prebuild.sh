#!/bin/bash
set -xe -o pipefail

# Parse optional arguments from gerrit comment trigger
for i in ${GERRIT_EVENT_COMMENT_TEXT}; do
    case ${i} in
        *honeycomb=*)
            hc_commit_id=`echo "${i}" | cut -d = -f2-`
        ;;
        *vpp=*)
            vpp_commit_id=`echo "${i}" | cut -d = -f2-`
        ;;
        *nsh_sfc=*)
            nsh_commit_id=`echo "${i}" | cut -d = -f2-`
        ;;
        *csit=*)
            csit_commit_id=`echo "${i}" | cut -d = -f2-`
        ;;
        *)
        ;;
    esac
done

# If HC variable is set, clone and build Honeycomb infra from the specified commit
# Otherwise skip this step, hc2vpp will use Honeycomb snapshots from Nexus
if [[ -n "${hc_commit_id}" ]]; then
    git clone https://gerrit.fd.io/r/honeycomb
    cd honeycomb
    ref=`git ls-remote -q | grep ${hc_commit_id} | awk '{print $2}'`
    git fetch origin ${ref} && git checkout FETCH_HEAD
    mvn clean install -DskipTests -Dcheckstyle.skip -Dmaven.repo.local=/tmp/r -Dorg.ops4j.pax.url.mvn.localRepository=/tmp/r -gs "${GLOBAL_SETTINGS_FILE}" -s "${SETTINGS_FILE}"
    if [[ $? != 0 ]]; then
        echo "Honeycomb infra build failed."
        exit 1
    fi
    cd ${WORKSPACE}
    # Clean up when done. Leftover build files interfere with building hc2vpp.
    rm -rf honeycomb
fi

# TODO: Add option to build custom VPP and NSH packages

# Get CSIT branch from which to test from
if [[ -f csit-test-branch ]]; then
    chmod +x csit-test-branch
    CSIT_BRANCH=`./csit-test-branch`
else
    CSIT_BRANCH='master'
fi

# Clone csit
git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH}

# If the git clone fails, complain clearly and exit
if [[ $? != 0 ]]; then
    echo "Failed to run: git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH}"
    exit 1
fi

cd csit

# If CSIT commit ID is given, checkout the specified commit
if [[ -n "${csit_commit_id}" ]]; then
    # Example:
    # ...
    # e8f326efebb58e28dacb9ebb653baf95aad1448c refs/changes/08/11808/1
    # ...
    ref=`git ls-remote -q | grep ${csit_commit_id} | awk '{print $2}'`
    git fetch origin ${ref} && git checkout FETCH_HEAD
fi

# Download VPP packages
./resources/tools/scripts/download_hc_build_pkgs.sh ${STREAM} ${OS}


cd ${WORKSPACE}
