#!/bin/bash
DEBS=$(find . -type f -iname '*.deb')
echo "Found DEBS=${DEBS}"
for i in $DEBS
do
    push_deb "$i"
done