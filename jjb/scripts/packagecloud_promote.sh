#!/bin/bash

set -x

stage_repo="https://packagecloud.io/api/v1/repos/fdio/staging"
release_repo=" https://packagecloud.io/api/v1/repos/fdio/release"
curl --netrc-file packagecloud_api $stage_repo/packages.json | python -mjson.tool >>filenames.txt

grep 'filename' filenames.txt | awk '{print $2}' | grep 17.07 >>packages.txt

while read packages; do
  echo "$packages"
  package_cloud promote --config=/home/jenkins/.packagecloud "fdio/$stage_repo" "$packages" "fdio/$release_repo"
done <packages.txt
