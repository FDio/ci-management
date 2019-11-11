#!/bin/bash

if [ "$(grep 'test-checkstyle:' Makefile)" = "test-checkstyle:" ]
then
	make test-checkstyle
else
	echo "Can't find test-checkstyle target in Makefile - skipping test checkstyle"
fi
