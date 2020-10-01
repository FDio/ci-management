#!/bin/bash
echo "---> test-checkstyle.sh"

if [ -n "$(grep -E '^test-checkstyle:' Makefile)" ]
then
	make test-checkstyle
else
	echo "Can't find test-checkstyle target in Makefile - skipping test-checkstyle"
fi
