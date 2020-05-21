#!/bin/sh

# Show max consumed memory 

echo "/sys/fs/cgroup/memory/memory.max_usage_in_bytes: $(cat /sys/fs/cgroup/memory/memory.max_usage_in_bytes)"

