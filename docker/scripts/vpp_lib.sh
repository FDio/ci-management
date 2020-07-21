# vpp_lib.sh - Docker build script VPP library.
#              For import only.

# Don't import more than once.
if [ -n "$(alias vpp_lib_imported 2> /dev/null)" ] ; then
  return 0
elif [ -z "$CIMAN_ROOT" ] ; then
  echo "ERROR: Missing CIMAN_ROOT environment variable!"
  return 1
fi
alias vpp_lib_imported=true

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/common_lib.sh

make_vpp() {
  local branch=$1
  local target=$2
  local branchname="$(echo $branch | sed -e 's,/,_,')"

  git clean -qfdx
  description="'make UNATTENDED=y $target' in $(pwd) ($branch)"
  echo_log -e "    Starting  $description..."
  make UNATTENDED=y $target 2>&1 | tee -a "$BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME-$branchname-make_vpp_${target}-bld.log"
  git checkout -q -- .
  echo_log "    Completed $description!"
}

make_vpp_test() {
  local branch=$1
  local target=$2
  local branchname="$(echo $branch | sed -e 's,/,_,')"

  git clean -qfdx
  description="'make -C test $target' in $(pwd) ($branch)"
  echo_log "    Starting  $description..."
  make -C test $target 2>&1 | tee -a "$BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME-$branchname-make_vpp_test_${target}-bld.log"
  git checkout -q -- .
  echo_log "    Completed $description!"
}

declare -A VPP_BRANCHES
VPP_BRANCHES["centos-7"]="stable/1908 stable/2001 stable/2005 master"
VPP_BRANCHES["centos-9"]="master"
VPP_BRANCHES["debian-9"]="master"
VPP_BRANCHES["ubuntu-18.04"]="stable/1908 stable/2001 stable/2005 master"
VPP_BRANCHES["ubuntu-20.04"]="master"
export VPP_BRANCHES
export VPP_DIR="$DOCKER_BUILD_DIR/vpp"

if [ ! -d "$VPP_DIR" ] ; then
  echo_log "Cloning VPP into $VPP_DIR..."
  git clone -q https://gerrit.fd.io/r/vpp $VPP_DIR
fi
