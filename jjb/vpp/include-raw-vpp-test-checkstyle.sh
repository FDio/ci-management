#!/bin/bash

if grep '.PHONY: checkstyle' test/Makefile > /dev/null
then
	make test-checkstyle
else
	echo "Can't find checkstyle target in test/Makefile - skipping test checkstyle"
fi
