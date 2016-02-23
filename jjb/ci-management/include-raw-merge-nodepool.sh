#!/bin/bash

# vi: sw=4 ts=4 sts=4 et :

cd "${WORKSPACE}/nodepool"
/usr/bin/diff nodepool.yaml /etc/nodepool/nodepool.yaml
RET=$?
if [ "${RET}" -ne '0' ]
then
    echo
    echo 'Nodepool layouts differ, updating layout'
    echo
    /usr/bin/sudo /usr/bin/cp nodepool.yaml /etc/nodepool/nodepool.yaml
else
    echo
    echo 'No differences in layout, not updating'
    echo
fi

