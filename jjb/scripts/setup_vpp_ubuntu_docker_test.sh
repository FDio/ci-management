#!/bin/bash
set -e -o pipefail

if ! [ -z ${DOCKER_TEST} ] ; then
		mount -o remount /dev/shm -o size=512M || true
fi
