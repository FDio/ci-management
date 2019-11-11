#!/bin/bash

if [ "$(grep 'checkstyle:' Makefile | grep -v '-')" = "checkstyle:" ]
then
	make checkstyle
else
        echo "Can't find checkstyle target in Makefile - skipping checkstyle"
fi
