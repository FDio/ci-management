#!/bin/bash

echo "---> jjb/scripts/hicn/checkstyle.sh"

if [ -f ./scripts/checkstyle.sh ];then
    bash scripts/checkstyle.sh
else
    echo "Cannot find scripts/checkstyle.sh - skipping checkstyle"
fi
