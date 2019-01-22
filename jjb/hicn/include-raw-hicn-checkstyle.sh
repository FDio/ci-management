#!/bin/bash

if [ -f ./scripts/checkstyle.sh ];then
    bash scripts/checkstyle.sh
else
    echo "Cannot find scripts/checkstyle.sh - skipping checkstyle"
fi
