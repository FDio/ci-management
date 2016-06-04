#!/bin/bash

set -x

# print the current slave hostname
echo "Slave hostname:" $(hostname)

CCACHE_DIR=/tmp/ccache
if [ -d $CCACHE_DIR ];then
    echo "$CCACHE_DIR size in KB:" $(du -sk $CCACHE_DIR|cut -f1)
else
    echo "$CCACHE_DIR does not exist. Slave" $(uptime -p)
fi

PFX=/etc/bootstrap

for FILE in "${PFX}.sha" "${PFX}-functions.sha"
do
    test -f ${FILE} || (echo "Cannot find ${FILE}" && continue)

    CMD="cat ${FILE}"
    echo ${CMD} && eval "${CMD}"
done

echo "sha1 of ${0}:" $(sha1sum $0 | cut -d' ' -f 1)
