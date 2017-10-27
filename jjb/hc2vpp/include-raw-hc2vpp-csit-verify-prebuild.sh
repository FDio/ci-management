#!/bin/bash
set -xeu -o pipefail

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
        *)
        ;;
    esac
done

# If HC variable is set, clone and build Honeycomb infra from the specified commit
# Otherwise skip this step, hc2vpp will use Honeycomb snapshots from Nexus
if [ -n "${hc_commit_id}" ]; then
    git clone https://gerrit.fd.io/r/honeycomb
    cd honeycomb
    ref=`git ls-remote -q | grep ${hc_commit_id} | awk '{print $2}'`
    git fetch origin ${ref} && git checkout FETCH_HEAD
    mvn clean install -DskipTests -Dcheckstyle.skip -Dmaven.repo.local=/tmp/r -Dorg.ops4j.pax.url.mvn.localRepository=/tmp/r
    if [ $? != 0 ]; then
        echo "Honeycomb infra build failed."
        exit 1
    fi
    cd ${WORKSPACE}
fi

# TODO: Add option to build custom VPP and NSH packages

# Get CSIT branch from which to test from
if [ -f csit-test-branch ]; then
    chmod +x csit-test-branch
    CSIT_BRANCH=`./csit-test-branch`
else
    CSIT_BRANCH='master'
fi

# Clone csit
git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH}

# If the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone https://gerrit.fd.io/r/csit --branch ${CSIT_BRANCH}"
    exit 1
fi

cd csit

# Download VPP packages
if [ ${STREAM} == 'master' ]; then
    ./resources/tools/scripts/download_hc_build_pkgs.sh ${STREAM} ${OS}
else
    ./resources/tools/scripts/download_hc_build_pkgs.sh 'stable.'${STREAM} ${OS}
fi

cd ${WORKSPACE}
