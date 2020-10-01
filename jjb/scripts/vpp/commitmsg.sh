#!/bin/bash
echo "---> commitmsg.sh"

if [ -f extras/scripts/check_commit_msg.sh ];then
	echo "Running extras/scripts/check_commit_msg.sh"
    extras/scripts/check_commit_msg.sh
else
    echo "Cannot find cat extras/scripts/check_commit_msg.sh - skipping commit message check"
fi
