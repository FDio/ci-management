# lib_common.sh - Docker build script common library.
#                 For import only.

# Copyright (c) 2020 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Don't import more than once.
if [ -n "$(alias lib_common_imported 2> /dev/null)" ] ; then
    return 0
fi
alias lib_common_imported=true

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
export CIMAN_ROOT="$(dirname $(dirname $CIMAN_DOCKER_SCRIPTS))"

must_be_run_as_root() {
    set_opts=$-
    grep -q e <<< $set_opts && set +e # disable exit on errors

    # test if the user is root
    if [ "${EUID:-$(id -u)}" -eq "0" ] ; then
        grep -q e <<< $set_opts && set -e # re-enable exit on errors
    else
        set +x
        echo -e "\nERROR: Must be run as root!"
        if [ -n "$(declare -f usage)" ] ; then
            usage
        fi
        grep -q e <<< $set_opts && set -e # re-enable exit on errors
        exit 1
    fi
}

must_be_run_in_docker_build() {
    if [ -z "$(alias running_in_docker_build 2> /dev/null)" ] ; then
        set +x
        echo -e "\nERROR: $(basename $0) must be run in 'docker build'\n"
        exit 1
    fi
}

echo_log() {
    if [ "$#" -eq "0" ] ; then
        if [ -z "$(alias running_in_docker_build 2> /dev/null)" ] ; then
            echo
        else
            echo | tee -a $FDIOTOOLS_IMAGE_BUILD_LOG 1>&2
        fi
        return 0
    fi

    local echo_opts=""
    case "$1" in
        -[en])
            echo_opts="$1 "
            shift
            ;;
    esac
    if [ -z "$(alias running_in_docker_build 2> /dev/null)" ] ; then
        echo ${echo_opts}"####> $@"
    else
        echo ${echo_opts}"####> $(date): $@" | tee -a $FDIOTOOLS_IMAGE_BUILD_LOG 1>&2
    fi
}

dump_echo_log() {
    [ -z "$(alias running_in_docker_build 2> /dev/null)" ] && return 0
    echo -e "\n\n####> $(date) Build log ($FDIOTOOLS_IMAGE_BUILD_LOG):"
    cat $FDIOTOOLS_IMAGE_BUILD_LOG
}

do_git_config() {
    if [ "$#" -ne "1" ] ; then
        echo_log "ERROR: do_git_config(): Invalid number of arguments ($#)!"
        return 1
    fi
    cd $DOCKER_BUILD_DIR/$1

    # Add user to git config so git commands don't fail
    local git_config_list="$(git config -l)"
    if [ -z "$(grep 'user\.email' <<<$git_config_list)" ] ; then
        git config user.email "ci-management-dev@lists.fd.io"
    fi
    if [ -z "$(grep 'user\.name' <<<$git_config_list)" ] ; then
        git config user.name  "ci-management"
    fi
}

do_git_branch() {
    local branch="$1"

    echo_log "  Checking out '$branch' in $(pwd)"
    if [ -n "$(git branch | grep $branch)" ] ; then
        git checkout $branch
    else
        git checkout -b $branch --track origin/$branch
    fi
    git pull -q
    echo_log -e "  'git log --oneline | head':\n----- %< -----\n$(git log --oneline | head)\n----- %< -----"
}

clean_git_repo() {
    local curr_dir=$(pwd)
    cd $1
    git clean -qfdx
    git checkout -q master
    git pull -q
    cd $curr_dir
}

remove_pyc_files_and_pycache_dirs() {
    find . -type f -name '*.pyc' -exec rm -f {} \; 2>/dev/null || true
    find . -type d -name __pycache__ -exec echo -n "Removing " \; \
         -print -exec rm -rf {} \; 2>/dev/null || true
}

# Get the refspec for the specified project branch at HEAD
#
# Arguments:
#   $1 - branch
#   $2 - project (Optional: defaults to 'vpp')
get_gerrit_refspec() {
    local branch=${1:-"master"}
    local project=${2:-"vpp"}
    local query="$(ssh -p 29418 gerrit.fd.io gerrit query status:merged project:$project branch:$branch limit:1 --format=JSON --current-patch-set | tr ',' '\n' | grep refs | cut -d'"' -f4)"

    if [ -z "$query" ] ; then
        echo "ERROR: Invalid project ($1) or branch ($2)"
    else
        echo "$query"
    fi
}

# Well-known filename variables
export APT_DEBIAN_DOCKER_GPGFILE="docker.linux.debian.gpg"
export APT_UBUNTU_DOCKER_GPGFILE="docker.linux.ubuntu.gpg"
export YUM_CENTOS_DOCKER_GPGFILE="docker.linux.centos.gpg"

# OS type variables
# TODO: Investigate if sourcing /etc/os-release and using env vars from it
#       works across all OS variants.  If so, clean up copy-pasta...
#       Alternatively use facter as does LF Releng scripts.
export OS_ID="$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g')"
export OS_VERSION_ID="$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g')"
export OS_CODENAME="$(grep 'VERSION_CODENAME=' /etc/os-release | cut -d= -f2)"
export OS_NAME="${OS_ID}-${OS_VERSION_ID}"
export OS_ARCH="$(uname -m)"
case "$OS_ARCH" in
    x86_64)
        export DEB_ARCH="amd64"
        ;;
    aarch64)
        export DEB_ARCH="arm64"
        ;;
    *)
        echo "ERROR: Unsupported OS architecture '$OS_ARCH'!"
        return 1
        ;;
esac

# Executor attribute variables
# Note: the role 'prod' is only applied and uploaded using the script
#       update_dockerhub_prod_tags.sh to avoid accidentally pushing
#       an untested docker image into production.
export EXECUTOR_ROLES="sandbox test"
export EXECUTOR_DEFAULT_CLASS="builder"
export EXECUTOR_CLASS="$EXECUTOR_DEFAULT_CLASS"
export EXECUTOR_CLASS_ARCH="$EXECUTOR_DEFAULT_CLASS-$OS_ARCH"
export EXECUTOR_CLASSES="$EXECUTOR_DEFAULT_CLASS csit csit_dut csit_shim"
export EXECUTOR_ARCHS="aarch64 x86_64"
declare -A EXECUTOR_CLASS_ARCH_OS_NAMES
EXECUTOR_CLASS_ARCH_OS_NAMES["builder-aarch64"]="centos-7 centos-8 ubuntu-18.04 ubuntu-20.04"
EXECUTOR_CLASS_ARCH_OS_NAMES["builder-x86_64"]="centos-7 centos-8 debian-9 debian-10 ubuntu-18.04 ubuntu-20.04"
EXECUTOR_CLASS_ARCH_OS_NAMES["csit-aarch64"]="ubuntu-18.04"
EXECUTOR_CLASS_ARCH_OS_NAMES["csit-x86_64"]="ubuntu-18.04"
EXECUTOR_CLASS_ARCH_OS_NAMES["csit_dut-aarch64"]="ubuntu-18.04"
EXECUTOR_CLASS_ARCH_OS_NAMES["csit_dut-x86_64"]="ubuntu-18.04"
EXECUTOR_CLASS_ARCH_OS_NAMES["csit_shim-aarch64"]="ubuntu-18.04"
EXECUTOR_CLASS_ARCH_OS_NAMES["csit_shim-x86_64"]="ubuntu-18.04"
export EXECUTOR_CLASS_ARCH_OS_NAMES

executor_list_roles() {
    local set_opts=$-
    grep -q u <<< $set_opts && set +u # disable undefined variable check
    local indent=${1:-"     "}
    grep -q u <<< $set_opts && set -u # re-enable undefined variable check

    for role in $EXECUTOR_ROLES ; do
        echo -e "${indent}$role"
    done
}

executor_verify_role() {
    for role in $EXECUTOR_ROLES ; do
        if [ "$role" = "$1" ] ; then
            return 0
        fi
    done
    return 1
}

executor_list_classes() {
    local set_opts=$-
    grep -q u <<< $set_opts && set +u # disable undefined variable check
    local indent=${1:-"     "}
    grep -q u <<< $set_opts && set -u # re-enable undefined variable check

    for class in $EXECUTOR_CLASSES ; do
        echo -e "${indent}$class"
    done
}

executor_verify_class() {
    for class in $EXECUTOR_CLASSES ; do
        if [ "$class" = "$1" ] ; then
            return 0
        fi
    done
    return 1
}

executor_list_os_names() {
    local set_opts=$-
    grep -q u <<< $set_opts && set +u # disable undefined variable check
    local indent=${1:-"     "}
    grep -q u <<< $set_opts && set -u # re-enable undefined variable check

    echo
    echo "Valid executor OS names for class '$EXECUTOR_CLASS':"
    for os in ${EXECUTOR_CLASS_ARCH_OS_NAMES[$EXECUTOR_CLASS_ARCH]} ; do
        echo "${indent}$os"
    done | sort
}

executor_verify_os_name() {
    for os in ${EXECUTOR_CLASS_ARCH_OS_NAMES[$EXECUTOR_CLASS_ARCH]} ; do
        if [ "$os" = "$1" ] ; then
            return 0
        fi
    done
    return 1
}

# Docker variables
export DOCKER_BUILD_DIR="/scratch/docker-build"
export DOCKER_CIMAN_ROOT="$DOCKER_BUILD_DIR/ci-management"
export DOCKERFILE="$DOCKER_BUILD_DIR/Dockerfile"
export DOCKERIGNOREFILE="$DOCKER_BUILD_DIR/.dockerignore"
export DOCKERFILE_FROM=${DOCKERFILE_FROM:="${OS_ID}:${OS_VERSION_ID}"}
export DOCKER_TAG="$(date +%Y_%m_%d_%H%M%S)-$OS_ARCH"
export DOCKER_VPP_DIR="$DOCKER_BUILD_DIR/vpp"
export DOCKER_CSIT_DIR="$DOCKER_BUILD_DIR/csit"
export DOCKER_GPG_KEY_DIR="$DOCKER_BUILD_DIR/gpg-key"
export DOCKER_APT_UBUNTU_DOCKER_GPGFILE="$DOCKER_GPG_KEY_DIR/$APT_UBUNTU_DOCKER_GPGFILE"
export DOCKER_APT_DEBIAN_DOCKER_GPGFILE="$DOCKER_GPG_KEY_DIR/$APT_DEBIAN_DOCKER_GPGFILE"
export DOCKER_DOWNLOADS_DIR="/root/Downloads"

docker_build_setup_ciman() {
    mkdir -p $DOCKER_BUILD_DIR $DOCKER_GPG_KEY_DIR

    if [ "$(dirname $CIMAN_ROOT)" != "$DOCKER_BUILD_DIR" ] ; then
        echo_log "Syncing $CIMAN_ROOT into $DOCKER_CIMAN_ROOT..."
        pushd $CIMAN_ROOT
        git submodule update --init --recursive
        popd
        rsync -a $CIMAN_ROOT/. $DOCKER_CIMAN_ROOT
    fi
}

# Variables used in docker build environment
set_opts=$-
grep -q u <<< $set_opts && set +u # disable undefined variable check
if [ -n "$FDIOTOOLS_IMAGE" ] ; then
    alias running_in_docker_build=true
    export DOCKER_BUILD_LOG_DIR="$DOCKER_BUILD_DIR/logs"
    export FDIOTOOLS_IMAGENAME="$(echo $FDIOTOOLS_IMAGE | sed -e 's/:/-/' -e 's,/,_,g')"
    export FDIOTOOLS_IMAGE_BUILD_LOG="$DOCKER_BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME.log"
    mkdir -p $DOCKER_BUILD_LOG_DIR
fi
grep -q u <<< $set_opts && set -u # re-enable undefined variable check
