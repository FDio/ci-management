#!/bin/bash

if [ "$(grep -E '^checkstyle:' Makefile)" = "checkstyle:" ]
then
	make checkstyle
else
        echo "Can't find checkstyle target in Makefile - skipping checkstyle"
fi
