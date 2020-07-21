#! /bin/bash

set -euxo pipefail

# Log all output to stdout & stderr to a log file
logname="/tmp/$(basename $0).$(date +%Y-%m-%d-%H%M%S).log"
echo -e "\n*** Logging output to $logname ***\n\n"
exec > >(tee -a $logname) 2>&1

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_vpp.sh
. $CIMAN_DOCKER_SCRIPTS/lib_csit.sh
. $CIMAN_DOCKER_SCRIPTS/lib_apt.sh
. $CIMAN_DOCKER_SCRIPTS/lib_yum.sh

usage() {
  echo
  echo "Usage: $0 <os name> [... <os name>]"
  list_builder_os_names
  exit 1
}

list_builder_os_names() {
  if [ -n "$(alias lib_vpp_imported 2> /dev/null)" ] ; then
    echo
    echo "Valid builder OS names:"
    for os in "${!VPP_BRANCHES[@]}" ; do
      echo "  $os"
    done | sort
  fi
}

bad_builder_os_name() {
  echo "ERROR: Invalid builder OS name: $1!"
  list_builder_os_names
  echo
}

clean_scratch_repo() {
  local curr_dir=$(pwd)
  cd $DOCKER_BUILD_DIR/$1
  git clean -qfdx
  git checkout -q  master
  git pull -q
  cd $curr_dir
}

# Validate arguments
if [ "$#" -eq "0" ] ; then
  usage
fi

# Build the specified docker images
for os_name in $@ ; do
  os_tag="$(echo $os_name | sed -e 's/-/:/')"
  tag="$DOCKER_TAG"
  image="builder-${os_name}:$tag"
  shift

  # Assume all projects build on the same OS's as VPP
  if [ -z "$(echo ${!VPP_BRANCHES[*]} | grep $os_name)" ] ; then
    bad_builder_os_name "$os_name"
    continue
  fi
  case $os_name in
    ubuntu*)
      generate_apt_dockerfile
      ;;
    debian*)
      generate_apt_dockerfile
      ;;
    centos*)
      generate_yum_dockerfile
      ;;
    *)
      echo "ERROR: Don't know how to generate dockerfile for $os_name!"
      usage
      ;;
  esac

  clean_scratch_repo vpp
  docker build -t $image $DOCKER_BUILD_DIR
  rm -f $DOCKERFILE
done
