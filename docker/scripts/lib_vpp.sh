# lib_vpp.sh - Docker build script VPP library.
#              For import only.

# Don't import more than once.
if [ -n "$(alias lib_vpp_imported 2> /dev/null)" ] ; then
  return 0
fi
alias lib_vpp_imported=true

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh

make_vpp() {
  local target=$1
  local branch=${2:-"master"}
  local branchname="$(echo $branch | sed -e 's,/,_,')"
  local bld_log="$DOCKER_BUILD_LOG_DIR"
  bld_log="${bld_log}/$FDIOTOOLS_IMAGENAME-$branchname"
  bld_log="${bld_log}-make_vpp_${target}-bld.log"

  git clean -qfdx
  description="'make UNATTENDED=y $target' in $(pwd) ($branch)"
  echo_log -e "    Starting  $description..."
  make UNATTENDED=y CONFIRM="-y" FORCE="--force-yes" \
    $target 2>&1 | tee -a "$bld_log"
  git checkout -q -- .
  echo_log "    Completed $description!"
}

make_vpp_test() {
  local target=$1
  local branch=${2:-"master"}
  local branchname="$(echo $branch | sed -e 's,/,_,')"
  local bld_log="$DOCKER_BUILD_LOG_DIR"
  bld_log="${bld_log}/$FDIOTOOLS_IMAGENAME-$branchname"
  bld_log="${bld_log}-make_vpp_test_${target}-bld.log"

  git clean -qfdx
  description="'make -C test $target' in $(pwd) ($branch)"
  echo_log "    Starting  $description..."
  make WS_ROOT="$DOCKER_VPP_DIR" BR="$DOCKER_VPP_DIR/build-root" \
    TEST_DIR="$DOCKER_VPP_DIR/test" -C test $target 2>&1 | tee -a $bld_log
  remove_pyc_files_and_pycache_dirs
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

if [ ! -d "$DOCKER_VPP_DIR" ] ; then
  echo_log "Cloning VPP into $DOCKER_VPP_DIR..."
  git clone -q https://gerrit.fd.io/r/vpp $DOCKER_VPP_DIR
fi
clean_git_repo $DOCKER_VPP_DIR
