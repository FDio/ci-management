#!/bin/bash -ex

# emulate unique name for now
GERRIT_NEWREV=hash`date +%s%N`
WS=${PWD}/$GERRIT_NEWREV

export CCACHE_DIR=/tmp/ccache

fetch_cache

#  temporary don't fail
set +e

function clean_ws {
    rm -rf "$WS"
}
trap clean_ws EXIT

echo "$WS"
clean_ws
mkdir "$WS"
cd "$WS"

# cloning

git clone https://github.com/cisco-system-traffic-generator/trex-core.git
git clone https://github.com/cisco-system-traffic-generator/trex-doc.git
ls -l

# building core

cd trex-core/linux_dpdk
./b configure
./b build
cd -

cd trex-core/linux
./b configure
./b build
cd -

which asciidoc
which sphinx-build
which dblatex
which python
which python3
which pip

# building docs

cd trex-doc
./b configure
./b build
cd -

push_ccache

echo "*******************************************************************"
echo "* TREX BUILD SUCCESSFULLY COMPLETED"
echo "*******************************************************************"

