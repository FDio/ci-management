#!/bin/bash -e

# activate the nodepool virtual env
source /opt/venv-nodepool/bin/activate

nodepool -c ${WORKSPACE}/nodepool/nodepool.yaml config-validate
