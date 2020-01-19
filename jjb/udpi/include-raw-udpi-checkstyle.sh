#!/bin/bash

if [ -f scripts/checkstyle.sh ];then
    scripts/checkstyle.sh
else
    echo "Cannot find cat build-root/scripts/checkstyle.sh - skipping checkstyle"
fi
