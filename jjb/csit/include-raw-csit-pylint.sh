#!/bin/bash

set -x

sudo apt-get install -y --force-yes pylint

# Re-create virtual environment
rm -rf env || true
virtualenv env
. env/bin/activate

# Install requirements, so all CSIT python dependencies are met
pip install -r requirements.txt
pip install pylint==1.5.4

# Run pylint, but hide its' return value until python warnings are cleared
PYTHONPATH=`pwd` pylint --rcfile=pylint.cfg resources/ > pylint.log || true

# vim: ts=4 ts=4 sts=4 et :
