#!/bin/bash
# basic build script example

# do nothing but print the current slave hostname
hostname
autoreconf --install
./configure
make
