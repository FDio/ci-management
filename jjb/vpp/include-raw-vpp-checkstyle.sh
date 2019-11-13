#!/bin/bash

if [ -f build-root/scripts/checkstyle.sh ];then
    build-root/scripts/checkstyle.sh
else
    echo "Cannot find cat build-root/scripts/checkstyle.sh - skipping checkstyle"
fi
