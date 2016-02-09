#!/bin/bash

find resources -name \*.py | xargs pylint --rcfile=pylint.cfg > pylint.log || true

# vim: ts=4 ts=4 sts=4 et :
