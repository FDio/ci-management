#! /bin/bash

set -euo pipefail

attic_repo='fdio/attic'
packages_json='/tmp/pkgs.json'
packagecloud_user="$HOME/.ssh/.packagecloud.user"
# shellcheck disable=SC2064
trap "rm -f $packages_json" SIGHUP SIGINT SIGQUIT EXIT

get_more_packages() {
    rm -f $packages_json
    echo "Retrieving packages from packagecloud.io/$attic_repo"
    # shellcheck disable=SC2086
    curl -s https://"$(cat $packagecloud_user)"/api/v1/repos/$attic_repo/packages.json | jq . > $packages_json
}

get_more_packages
while [ "$(cat $packages_json)" != "[]" ] ; do
    for pkg in $(cat $packages_json | jq '.[].destroy_url' | xargs) ; do
        # shellcheck disable=SC2086
        echo "Deleting $(basename $pkg)"
        # shellcheck disable=SC2086
        curl -sX DELETE "https://$(cat $packagecloud_user)$pkg" >& /dev/null
    done
    echo
    get_more_packages
done
echo "No more packages in '$attic_repo'!"
