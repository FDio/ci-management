#!/bin/bash

make doxygen
cd build-root/docs/html
zip vpp.docs.zip .

