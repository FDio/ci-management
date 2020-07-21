#! /bin/bash
set -euxo pipefail

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_apt.sh
. $CIMAN_DOCKER_SCRIPTS/lib_yum.sh
. $CIMAN_DOCKER_SCRIPTS/lib_dnf.sh

echo_log
echo_log "Starting  $(basename $0)"

# Assumes that OS packages required for building Python are
# installed in baseline dockerfile stage.
must_be_called_by_docker_build

python_version="$1"
python_exe="python$(echo "$python_version" | mawk -F'.' '{print $1"."$2}')"
wget https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tar.xz
tar -xJf Python-${python_version}.tar.xz
cd Python-${python_version}
./configure --enable-optimizations
make altinstall
if [ "$python_version" = "DOCKER_DEFAULT_PYTHON3_VERSION" ] ; then
  update-alternatives --install /usr/bin/python3 python3 \
    $(readlink /usr/bin/python3) 1
  update-alternatives --install /usr/bin/python3 python3 \
    /usr/local/bin/python${python_exe} 10
fi
echo_log "Python version: $($python_exe --version)"
cd -

echo_log -e "Completed $(basename $0)!\n\n=========="
