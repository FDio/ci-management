#!/bin/bash
set -e
make doxygen
cd build-root/docs/html
zip vpp.docs.zip .

