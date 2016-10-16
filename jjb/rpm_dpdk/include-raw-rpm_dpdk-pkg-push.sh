#!/bin/bash
# basic build script example
set -e -o pipefail
echo "Looking for rpms to publish"
# Find the files
RPMS=$(find . -type f -iname '*.rpm')
SRPMS=$(find . -type f -iname '*.srpm')
SRCRPMS=$(find . -type f -name '*.src.rpm')
echo "Found RPMS=${RPMS}"
echo "Found SRPMS=${SRPMS}"
echo "Found SRCRPMS=${SRCRPMS}"
for i in $RPMS $SRPMS $SRCRPMS
do
    push_rpm "$i"
done
