#!/bin/bash -e

# activate the zuul virtual env on system that has tox installed
source /opt/venv-zuul/bin/activate

rm -rf .test
mkdir .test
cd .test

# track the upstream zuul HEAD, this may be honestly a little risky
# but the validations shouldn't fail often due to upstream changes
git clone https://github.com/openstack-infra/zuul --depth 1
cd zuul

# calling tox will actually build out a new virtualenv and use that
# which is honestly a little silly... but whatever
tox -e validate-layout $WORKSPACE/zuul/layout.yaml
