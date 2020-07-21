# lib_common.sh - Docker build script common library.
#                 For import only.

# Don't import more than once.
if [ -n "$(alias lib_common_imported 2> /dev/null)" ] ; then
    return 0
fi
alias lib_common_imported=true

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
export CIMAN_ROOT="$(dirname $(dirname $CIMAN_DOCKER_SCRIPTS))"

# bool function to test if the user is root or not
# From https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
#
is_user_root()
{
  [ ${EUID:-"$(id -u)"} -eq "0" ]
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
  echo_log -e \
    "  'git log --oneline | head':\n----- %< -----\n$(git log --oneline | head)\n----- %< -----"
}

clean_git_repo() {
  local curr_dir=$(pwd)
  cd $1
  git clean -qfdx
  git checkout -q master
  git pull -q
  cd $curr_dir
}

must_be_called_by_docker_build() {
  if [ -z "$(alias running_in_docker_build 2> /dev/null)" ] ; then
    echo_log -e "ERROR: $(basename $0) must be run in 'docker build'\n"
    return 1
  fi
}

remove_pyc_files_and_pycache_dirs() {
  find . -type f -name '*.pyc' -exec rm -f {} \; 2>/dev/null || true
  find . -type d -name __pycache__ -exec echo -n "Removing " \; \
    -print -exec rm -rf {} \; 2>/dev/null || true
}

# All docker builder scripts must be run as root
set_opts=$-
grep -q e <<< $set_opts && set +e # disable exit on errors

is_user_root
if [ "$?" -ne "0" ] ; then
  echo "ERROR: Must be run as root!"
  grep -q e <<< $set_opts && set -e # re-enable exit on errors
  [ -n "$(declare -f usage)" ] && usage || return 1
else
  grep -q e <<< $set_opts && set -e # re-enable exit on errors
fi

# Well-known filename variables
export APT_DOCKER_GPGFILE="docker.linux.ubuntu.gpg"
export YUM_DOCKER_GPGFILE="docker.linux.centos.gpg"

# OS type variables
# TODO: Investigate if sourcing /etc/os-release and using env vars from it
#       works across all OS variants.  If so, clean up copy-pasta...
export OS_ID="$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g')"
export OS_VERSION="$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g')"
export OS_CODENAME="$(grep 'VERSION_CODENAME=' /etc/os-release | cut -d= -f2)"
export OS_NAME="${OS_ID}-${OS_VERSION}"
export OS_ARCH="$(uname -m)"
case "$OS_ARCH" in
  x86_64)
    export DEB_ARCH="amd64"
    ;;
  aarch64)
    export DEB_ARCH="arm64"
    ;;
  *)
    echo "ERROR: Unsupported OS architecture ($OS_ARCH)!"
    return 1
    ;;
esac

# Docker variables
export DOCKER_BUILD_DIR="/scratch/docker-build"
export DOCKER_CIMAN_ROOT="$DOCKER_BUILD_DIR/ci-management"
export DOCKERFILE="$DOCKER_BUILD_DIR/Dockerfile"
export DOCKERIGNOREFILE="$DOCKER_BUILD_DIR/.dockerignore"
export DOCKERFILE_FROM=${DOCKERFILE_FROM:="${OS_ID}:${OS_VERSION}"}
export DOCKER_TAG="$(date +%Y-%m-%d-%H%M%S)-$OS_ARCH"
export DOCKER_VPP_DIR="$DOCKER_BUILD_DIR/vpp"
export DOCKER_CSIT_DIR="$DOCKER_BUILD_DIR/csit"
export DOCKER_GPG_KEY_DIR="$DOCKER_BUILD_DIR/gpg-key"
export DOCKER_APT_DOCKER_GPGFILE="$DOCKER_GPG_KEY_DIR/$APT_DOCKER_GPGFILE"
export DOCKER_YUM_DOCKER_GPGFILE="$DOCKER_GPG_KEY_DIR/$YUM_DOCKER_GPGFILE"
export DOCKER_DOWNLOADS_DIR="/root/Downloads"
mkdir -p $DOCKER_BUILD_DIR $DOCKER_GPG_KEY_DIR

if [ "$(dirname $CIMAN_ROOT)" != "$DOCKER_BUILD_DIR" ] ; then
    echo "Syncing $CIMAN_ROOT into $DOCKER_CIMAN_ROOT..."
    pushd $CIMAN_ROOT
    git submodule update --init --recursive
    popd
    rsync -a $CIMAN_ROOT/. $DOCKER_CIMAN_ROOT
fi

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
