#!/bin/bash
# jjb/vpp/include-raw-vpp-test-checkstyle.sh

if [ "$(grep -E '^test-checkstyle:' Makefile)" = "test-checkstyle:" ]
then
	make test-checkstyle
else
	echo "Can't find test-checkstyle target in Makefile - skipping test checkstyle"
fi
