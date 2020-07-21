# common_lib.sh - Docker build script common library.
#                 For import only.

# Don't import more than once.
if [ -n "$(alias common_lib_imported 2> /dev/null)" ] ; then
  return 0
elif [ -z "$CIMAN_ROOT" ] ; then
  echo "ERROR: Missing CIMAN_ROOT environment variable!"
  return 1
fi
alias common_lib_imported=true


export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}

# bool function to test if the user is root or not
# From https://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
#
is_user_root()
{
  [ ${EUID:-"$(id -u)"} -eq "0" ]
}

echo_log() {
  if [ "$#" -eq "0" ] ; then
    if [ -z "$FDIOTOOLS_IMAGE_BUILD_LOG" ] ; then
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
  if [ -z "$FDIOTOOLS_IMAGE_BUILD_LOG" ] ; then
    echo ${echo_opts}"####> $@"
  else
    mkdir -p $BUILD_LOG_DIR
    echo ${echo_opts}"####> $(date): $@" | tee -a $FDIOTOOLS_IMAGE_BUILD_LOG 1>&2
  fi
}

dump_echo_log() {
  [ -z "$FDIOTOOLS_IMAGE_BUILD_LOG" ] && return 0
  echo -e "\n\n####> $(date) Build log ($FDIOTOOLS_IMAGE_BUILD_LOG):"
  cat $FDIOTOOLS_IMAGE_BUILD_LOG
}

do_git_pull() {
  if [ -z "$1" ] ; then
    echo_log "ERROR: Missing workspace directory argument!"
    return 1
  fi
  cd $DOCKER_BUILD_DIR/$1

  # Add user to git config so git commands don't fail
  git config user.email "ciman@fd.io"
  git config user.name  "ci-management"
  git pull -q
}

do_git_branch() {
  local branch="$1"
  if [ "$#" -ne "1" ] ; then
    echo_log "ERROR: do_git_branch(): Invalid number of arguments ($#)!"
    return 1
  fi
  echo_log "  Checking out '$branch' in $(pwd)"
  if [ -n "$(git branch | grep $branch)" ] ; then
    git checkout $branch
  else
    git checkout -b $branch --track origin/$branch
  fi
  echo_log -e \
	  "  'git log --oneline | head':\n----- %< -----\n$(git log --oneline | head)\n----- %< -----"
}

must_be_called_by_docker_build() {
  local set_opts=$-
  grep -q u <<< $set_opts && set +u # disable undefined variable check

  if [ -z "$FDIOTOOLS_IMAGE" ] ; then
    echo_log -e "ERROR: Missing FDIOTOOLS_IMAGE environment variable!\n" \
                "            $(basename $0) must be run in 'docker build'\n" 
    return 1
  fi
  grep -q u <<< $set_opts && set -u # re-enable undefined variable check
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
export OS_ID="$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g')"
export OS_VERSION="$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g')"
export OS_CODENAME="$(grep 'VERSION_CODENAME=' /etc/os-release | cut -d= -f2)"
export OS_NAME="${OS_ID}-${OS_VERSION}"
export OS_ARCH="$(uname -p)"
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
export DOCKERFILE="$DOCKER_BUILD_DIR/Dockerfile"
export DOCKERFILE_FROM=${DOCKERFILE_FROM:="${OS_ID}:${OS_VERSION}"} 
export DOCKER_TAG="$(date +%Y-%m-%d-%H%M%S)"
export DOCKER_VPP_DIR="$DOCKER_BUILD_DIR/vpp"
export DOCKER_CSIT_DIR="$DOCKER_BUILD_DIR/csit"
export DOCKER_GPG_KEY_DIR="$DOCKER_BUILD_DIR/gpg-key"
export DOCKER_APT_DOCKER_GPGFILE="$DOCKER_GPG_KEY_DIR/$APT_DOCKER_GPGFILE"
export DOCKER_YUM_DOCKER_GPGFILE="$DOCKER_GPG_KEY_DIR/$YUM_DOCKER_GPGFILE"
mkdir -p $DOCKER_GPG_KEY_DIR

# Variables used in docker build environment
set_opts=$-
grep -q u <<< $set_opts && set +u # disable undefined variable check
if [ -n "$FDIOTOOLS_IMAGE" ] ; then
  export BUILD_LOG_DIR="$DOCKER_BUILD_DIR/build-logs"
  export FDIOTOOLS_IMAGENAME="$(echo $FDIOTOOLS_IMAGE | sed -e 's/:/-/')"
  export FDIOTOOLS_IMAGE_BUILD_LOG="$BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME.log"
  mkdir -p $BUILD_LOG_DIR
fi
grep -q u <<< $set_opts && set -u # re-enable undefined variable check
