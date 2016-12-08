#!/bin/bash
set -xeu -o pipefail

# Clone csit and run package download script
git clone https://gerrit.fd.io/r/csit --branch master

# If the git clone fails, complain clearly and exit
if [ $? != 0 ]; then
    echo "Failed to run: git clone https://gerrit.fd.io/r/csit --branch master"
    exit
fi

./resources/tools/download_hc_build_pkgs.sh
