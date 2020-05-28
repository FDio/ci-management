#!/bin/bash
# basic build script example
set -xe -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')

echo OS_ID: $OS_ID
echo OS_VERSION_ID: $OS_VERSION_ID

# do nothing but print the current slave hostname
hostname
export CCACHE_DIR=/tmp/ccache
if [ -d $CCACHE_DIR ];then
    echo $CCACHE_DIR exists
    du -sk $CCACHE_DIR
else
    echo $CCACHE_DIR does not exist.  This must be a new slave.
fi

echo "cat /etc/bootstrap.sha"
if [ -f /etc/bootstrap.sha ];then
    cat /etc/bootstrap.sha
else
    echo "Cannot find cat /etc/bootstrap.sha"
fi

echo "cat /etc/bootstrap-functions.sha"
if [ -f /etc/bootstrap-functions.sha ];then
    cat /etc/bootstrap-functions.sha
else
    echo "Cannot find cat /etc/bootstrap-functions.sha"
fi

echo "sha1sum of this script: ${0}"
sha1sum $0

echo "CC=${CC}"
echo "IS_CSIT_VPP_JOB=${IS_CSIT_VPP_JOB}"

# prepare the command file to feed to gdb
# gdb ${BINFILE} ${CORE} -ex 'source -v gdb-commands' -ex quit
cat >/tmp/gdb-commands.txt <<'__EE__'
set pagination off
bt

define printstack
  set $i=0
  while $i < 15
      frame $i
      x/i $pc
      info locals
      info reg
      set $i = $i + 1
  end
end
printstack

__EE__

# install gdb in case it isn't there
sudo apt-get install -y gdb

echo "TIMING: $(date): start verify"
if make UNATTENDED=yes TEST_JOBS=auto verify; then
        echo "Make verify: success"
else
        EXIT_CODE=$?
        echo "Inside docker: failure, exit code ${EXIT_CODE}"

        for CORE in $(find /tmp/vpp* -name core*); do
                echo "FOUND CORE: ${CORE}, invoke GDB"
                BINFILE=$(gdb -c ${CORE} -ex quit | grep 'Core was generated' | awk '{ print $5; }' | sed -e s/\`//g)
                echo ====================================================== DECODE CORE: ${CORE}
                gdb ${BINFILE} ${CORE} -ex 'source -v /tmp/gdb-commands.txt' -ex quit
        done
fi

echo "TIMING: $(date): make-verify end"

echo "*******************************************************************"
echo "* DEBUG-ENABLED VPP BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
