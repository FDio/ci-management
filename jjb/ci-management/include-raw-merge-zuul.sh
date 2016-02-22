#!/bin/bash

# vi: sw=4 ts=4 sts=4 et :

cd "${WORKSPACE}/zuul"
/usr/bin/diff layout.yaml /etc/zuul/layout.yaml
RET=$?
if [ "${RET}" -ne '0' ]
then
    echo
    echo 'Zuul layouts differ, updating layout and reloading zuul'
    echo
    /usr/bin/sudo /usr/bin/cp layout.yaml /etc/zuul/layout.yaml
    /usr/bin/sudo /usr/bin/systemctl reload zuul
fi

