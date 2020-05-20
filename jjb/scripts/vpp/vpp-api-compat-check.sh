#!/bin/bash
set -exuo pipefail

VPP_CRC_CHECKER="extras/scripts/crcchecker.py"
VPP_CRC_CHECKER_CMD="$VPP_CRC_CHECKER --check-patchset"

if [ -f $VPP_CRC_CHECKER ];then
    echo "Running $VPP_CRC_CHECKER_CMD"
    $VPP_CRC_CHECKER_CMD
else
    echo "Cannot find $VPP_CRC_CHECKER - skipping API compatibility check"
fi

