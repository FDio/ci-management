# lib_csit.sh - Docker build script CSIT library.
#               For import only.

# Don't import more than once.
if [ -n "$(alias lib_csit_imported 2> /dev/null)" ] ; then
  return 0
fi
alias lib_csit_imported=true

export CIMAN_DOCKER_SCRIPTS="${CIMAN_DOCKER_SCRIPTS:-$(dirname $BASH_SOURCE)}"
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh

csit_pip_cache() {
  local branch=$1
  local VENV_OPTS=""
  # ensure PS1 is defined (used by virtualenv activate script)
  PS1=${PS1:-"#"}
  local branchname="$(echo $branch | sed -e 's,/,_,')"
  local csit_dir="$DOCKER_CSIT_DIR"
  local bld_log="$DOCKER_BUILD_LOG_DIR"
  bld_log="${bld_log}/$FDIOTOOLS_IMAGENAME-$branchname-csit_pip_cache-bld.log"

  if [ -n "$csit_dir" ] && [ -f "$csit_dir/VPP_REPO_URL" ] \
      && [ -f "$csit_dir/requirements.txt" ]; then
    export PYTHONPATH=$csit_dir
    git clean -qfdx
    description="Install CSIT python packages in $(pwd) ($branch)"
    echo_log "    Starting  $description..."
    [ -n "$(declare -f deactivate)" ] && deactivate
    local PIP=pip
    local setup_framework=$csit_dir/resources/libraries/python/SetupFramework.py
    if [ -n "$(grep pip3 $setup_framework)" ]; then
      PIP=pip3
      VENV_OPTS="-p python3"
    fi
    rm -rf $PYTHONPATH/env
    virtualenv $VENV_OPTS $PYTHONPATH/env
    . $PYTHONPATH/env/bin/activate
    if [ "$OS_ARCH" = "aarch64" ] ; then
      local numpy_ver="$(grep numpy $PYTHONPATH/requirements.txt)"
      [ -n "$numpy_ver" ] && $PIP install --upgrade $numpy_ver 2>&1 \
      | tee -a $bld_log
    fi
    $PIP install --upgrade -r $PYTHONPATH/requirements.txt 2>&1 \
      | tee -a $bld_log
    $PIP install --upgrade -r $PYTHONPATH/tox-requirements.txt 2>&1 \
      | tee -a $bld_log
    if [ "$OS_ARCH" = "x86_64" ] ; then
      local PRESENTATION_DIR="$PYTHONPATH/resources/tools/presentation"
      if [ -n "$(grep -r python3 $PRESENTATION_DIR)" ] && [ "$PIP" != "pip3" ] ; then
        PIP=pip3
        deactivate
        virtualenv -p python3 $PYTHONPATH/env
        . $PYTHONPATH/env/bin/activate
      fi
      $PIP install --upgrade -r $PRESENTATION_DIR/requirements.txt 2>&1 \
        | tee -a $bld_log
    fi
    deactivate
    rm -rf $PYTHONPATH/env
    git checkout -q -- .
    echo_log "    Completed $description!"
  else
    echo_log "ERROR: Missing or invalid CSIT_DIR: '$csit_dir'!"
    return 1
  fi
}

declare -A CSIT_BRANCHES
CSIT_BRANCHES["centos-7"]="rls1908 rls1908_1 rls1908_2 rls2001 rls2005 master"
CSIT_BRANCHES["centos-9"]="master"
CSIT_BRANCHES["debian-9"]="master"
CSIT_BRANCHES["ubuntu-18.04"]="rls1908 rls1908_1 rls1908_2 rls2001 rls2005 master"
CSIT_BRANCHES["ubuntu-20.04"]="master"

if [ ! -d "$DOCKER_CSIT_DIR" ] ; then
  echo_log "Cloning CSIT into $DOCKER_CSIT_DIR..."
  git clone -q https://gerrit.fd.io/r/csit $DOCKER_CSIT_DIR
fi
clean_git_repo $DOCKER_CSIT_DIR
