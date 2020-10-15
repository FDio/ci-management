#!/bin/bash

# Copyright (c) 2020 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo "---> jjb/scripts/packagecloud_promote.sh"

stage_repo="https://packagecloud.io/api/v1/repos/fdio/staging"
curl --netrc-file /home/jenkins/packagecloud_api $stage_repo/packages.json | \
    python -mjson.tool >filenames.txt
grep 'promote_url' filenames.txt > packages.txt
sed -i 's|[",:]||g' packages.txt
sed -i 's/promote_url//g' packages.txt

while read packages; do
echo $packages
curl --netrc-file /home/jenkins/packagecloud_api -v -o -X POST -F \
    destination=fdio/release/ https://packagecloud.io$packages

done <packages.txt
