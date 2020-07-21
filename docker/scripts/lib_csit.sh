# lib_csit.sh - Docker build script CSIT library.
#               For import only.

# Don't import more than once.
if [ -n "$(alias lib_csit_imported 2> /dev/null)" ] ; then
  return 0
fi
alias lib_csit_imported=true

export CIMAN_DOCKER_SCRIPTS="${CIMAN_DOCKER_SCRIPTS:-$(dirname $BASH_SOURCE)}"
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh
. $CIMAN_DOCKER_SCRIPTS/lib_apt.sh
. $CIMAN_DOCKER_SCRIPTS/lib_yum.sh

csit_checkout_branch_for_vpp() {
  local vpp_branch=$1
  local csit_dir="$DOCKER_CSIT_DIR"
  local csit_bash_function_dir="$csit_dir/resources/libraries/bash/function"

  # import checkout_csit_for_vpp() if not defined
  set +e && [ -z "$(declare -f checkout_csit_for_vpp)" ] \
    && source $csit_bash_function_dir/branch.sh
  CSIT_DIR=$(csit_dir) checkout_csit_for_vpp $vpp_branch

  csit_branch="$(git branch | grep -e '^*' | mawk '{print $2}')"
}

csit_install_packages() {
  local branch="$1"
  local branchname="$(echo $branch | sed -e 's,/,_,')"
  local csit_dir="$DOCKER_CSIT_DIR"
  local csit_ansible_dir="$csit_dir/resources/tools/testbed-setup/ansible"
  local bld_log="$DOCKER_BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME"
  bld_log="${bld_log}-$branchname-csit_install_packages-bld.log"

  git clean -qfdx

  # Not in double quotes to let bash remove newline characters
  local yaml_files=$(grep -r packages_by $csit_ansible_dir | cut -d: -f1 | sort -u | grep -ve calibration -e kernel -e mellanox -e nomad)
  packages=$(csit_get_packages_from_ansible_config.py --$OS_ID --$OS_ARCH $yaml_files)
  if [ -n "$packages" ] ; then
    case $OS_ID in
      ubuntu*)
        apt_install_packages $packages
        ;;
      debian*)
        apt_install_packages $packages
        ;;
      centos*)
        yum_install_packages $packages
        ;;
      *)
        echo "Unsupported OS ($OS_ID): CSIT packages NOT INSTALLED!"
        ;;
    esac
  fi
}

csit_pip_cache() {
  local branch="$1"
  local VENV_OPTS=""
  # ensure PS1 is defined (used by virtualenv activate script)
  PS1=${PS1:-"#"}
  local csit_dir="$DOCKER_CSIT_DIR"
  local csit_bash_function_dir="$csit_dir/resources/libraries/bash/function"

  if [ -f "$csit_dir/VPP_REPO_URL" ] \
         && [ -f "$csit_dir/requirements.txt" ]; then

    local branchname="$(echo $branch | sed -e 's,/,_,')"
    local bld_log="$DOCKER_BUILD_LOG_DIR"
    bld_log="${bld_log}/$FDIOTOOLS_IMAGENAME-$branchname-csit_pip_cache-bld.log"

    export PYTHONPATH=$csit_dir
    git clean -qfdx

    description="Install CSIT python packages from $branch branch"
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

    # Virtualenv version is pinned in common.sh in newer csit branches
    # xargs removes leading/trailing spaces
    install_virtualenv="$(grep 'virtualenv' $csit_bash_function_dir/common.sh | grep pip | grep install | cut -d'|' -f1 | xargs)"
    $install_virtualenv

    deactivate
    rm -rf $PYTHONPATH/env
    git checkout -q -- .
    echo_log "    Completed $description!"
  else
    echo_log "ERROR: Missing or invalid CSIT_DIR: '$csit_dir'!"
    return 1
  fi
}

if [ ! -d "$DOCKER_CSIT_DIR" ] ; then
  echo_log "Cloning CSIT into $DOCKER_CSIT_DIR..."
  git clone -q https://gerrit.fd.io/r/csit $DOCKER_CSIT_DIR
fi
clean_git_repo $DOCKER_CSIT_DIR
