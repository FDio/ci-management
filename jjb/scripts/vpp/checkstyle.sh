#!/bin/bash
echo "---> checkstyle.sh"

if [ -n "$(grep -E '^checkstyle:' Makefile)" ]
then
	make checkstyle
else
        echo "Can't find checkstyle target in Makefile - skipping checkstyle"
fi
