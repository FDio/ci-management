#!/bin/bash
# basic build script example
set -xe -o pipefail
# do nothing but print the current slave hostname
hostname
export CCACHE_DIR=/tmp/ccache
if [ -d $CCACHE_DIR ];then
    echo "$CCACHE_DIR size in KB: " $(du -sk $CCACHE_DIR | awk '{print $1}')
else
    echo "$CCACHE_DIR does not exist. Slave" $(uptime -p)
fi

PFX=/etc/bootstrap

for FILE in "${PFX}.sha" "${PFX}-functions.sha"
do
    if [ -f ${FILE} ]
    then
        CMD="cat ${FILE}"
        echo ${CMD} && eval "${CMD}"
    else
        echo "Cannot find ${FILE}"
    fi
done

echo "sha1sum of this script: ${0}"
sha1sum $0

make

echo "*******************************************************************"
echo "* TLDK BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"
