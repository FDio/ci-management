#!/bin/bash

cd build/
cmake ..
make checkstyle
if [ $? -eq 0 ]; then
    echo "DMM checkstyle is SUCCESS"
else
    echo "DMM checkstyle has FAILED"
    exit 1
fi