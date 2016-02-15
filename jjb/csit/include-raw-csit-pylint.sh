#!/bin/bash

sudo apt-get install -y --force-yes pylint
find resources -name \*.py | xargs pylint --rcfile=pylint.cfg > pylint.log || true

# vim: ts=4 ts=4 sts=4 et :
