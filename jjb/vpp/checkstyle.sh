#!/bin/bash
# jjb/vpp/include-raw-vpp-checkstyle.sh

if [ "$(grep -E '^checkstyle:' Makefile)" = "checkstyle:" ]
then
	make checkstyle
else
        echo "Can't find checkstyle target in Makefile - skipping checkstyle"
fi
