#!/bin/bash

stage_repo="https://packagecloud.io/api/v1/repos/fdio/staging"
curl --netrc-file /home/jenkins/packagecloud_api $stage_repo/packages.json | python -mjson.tool >filenames.txt
grep 'promote_url' filenames.txt > packages.txt
sed -i 's|[",:]||g' packages.txt
sed -i 's/promote_url//g' packages.txt

while read packages; do
echo $packages
curl --netrc-file /home/jenkins/packagecloud_api -v -o -X POST -F destination=fdio/release/ https://packagecloud.io$packages

done <packages.txt
