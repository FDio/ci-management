# csit_lib.sh - Docker build script CSIT library.
#               For import only.

# Don't import more than once.
if [ -n "$(alias csit_lib_imported 2> /dev/null)" ] ; then
  return 0
elif [ -z "$CIMAN_ROOT" ] ; then
  echo "ERROR: Missing CIMAN_ROOT environment variable!"
  return 1
fi
alias csit_lib_imported=true

export CIMAN_DOCKER_SCRIPTS="${CIMAN_DOCKER_SCRIPTS:-$(dirname $BASH_SOURCE)}"
. $CIMAN_DOCKER_SCRIPTS/common_lib.sh

csit_pip_cache() {
  local branch=$1
  local VENV_OPTS=""
  # ensure PS1 is defined (used by virtualenv activate script)
  PS1=${PS1:-"#"}
  branchname="$(echo $branch | sed -e 's,/,_,')"
  if [ -n "$CSIT_DIR" ] && [ -f "$CSIT_DIR/VPP_REPO_URL" ] && [ -f "$CSIT_DIR/requirements.txt" ]; then
    export PYTHONPATH=$CSIT_DIR
    git clean -qfdx
    description="Install CSIT python packages in $(pwd) ($branch)"
    echo_log "    Starting  $description..."
    [ -n "$(declare -f deactivate)" ] && deactivate
    local PIP=pip
    local setup_framework=$CSIT_DIR/resources/libraries/python/SetupFramework.py
    if [ -n "$(grep pip3 $setup_framework)" ]; then
      PIP=pip3
      VENV_OPTS="-p python3"
    fi
    rm -rf $PYTHONPATH/env
    virtualenv $VENV_OPTS $PYTHONPATH/env
    . $PYTHONPATH/env/bin/activate
    if [ "$(uname -p)" = "aarch64" ] ; then
      local numpy_ver="$(grep numpy $PYTHONPATH/requirements.txt)"
      [ -n "$numpy_ver" ] && $PIP install --upgrade $numpy_ver 2>&1 \
      | tee -a $BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME-$branchname-csit_pip_cache-bld.log
    fi
    $PIP install --upgrade -r $PYTHONPATH/requirements.txt 2>&1 \
      | tee -a $BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME-$branchname-csit_pip_cache-bld.log
    $PIP install --upgrade -r $PYTHONPATH/tox-requirements.txt 2>&1 \
      | tee -a $BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME-$branchname-csit_pip_cache-bld.log
    if [ "$OS_ARCH" = "x86_64" ] ; then
      local PRESENTATION_DIR="$PYTHONPATH/resources/tools/presentation"
      if [ -n "$(grep -r python3 $PRESENTATION_DIR)" ] && [ "$PIP" != "pip3" ] ; then
        PIP=pip3
        deactivate
        virtualenv -p python3 $PYTHONPATH/env
        . $PYTHONPATH/env/bin/activate
      fi
      $PIP install --upgrade -r $PRESENTATION_DIR/requirements.txt 2>&1 \
        | tee -a $BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME-$branchname-csit_pip_cache-bld.log
    fi
    deactivate
    rm -rf $PYTHONPATH/env
    git checkout -q -- .
    echo_log "    Completed $description!"
  else
    echo_log "ERROR: Missing or invalid CSIT_DIR: '$CSIT_DIR'!"
    return 1
  fi
}
CSIT_DIR="$DOCKER_BUILD_DIR"/csit

declare -A CSIT_BRANCHES
CSIT_BRANCHES["centos-7"]="rls1908 rls1908_1 rls1908_2 rls2001 rls2005 master"
CSIT_BRANCHES["centos-9"]="master"
CSIT_BRANCHES["debian-9"]="master"
CSIT_BRANCHES["ubuntu-18.04"]="rls1908 rls1908_1 rls1908_2 rls2001 rls2005 master"
CSIT_BRANCHES["ubuntu-20.04"]="master"

if [ ! -d "$CSIT_DIR" ] ; then
  echo_log "Cloning CSIT into $CSIT_DIR..."
  git clone -q https://gerrit.fd.io/r/csit $CSIT_DIR
fi
