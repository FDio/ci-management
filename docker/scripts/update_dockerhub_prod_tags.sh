#! /bin/bash

set -euo pipefail
shopt -s extglob

# Log all output to stdout & stderr to a log file
logname="/tmp/$(basename $0).$(date +%Y_%m_%d_%H%M%S).log"
echo -e "\n*** Logging output to $logname ***\n\n"
exec > >(tee -a $logname) 2>&1

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh

usage() {
    echo
    echo "Usage: $0 revert <production image> [... <production image>]"
    echo "       $0 promote <new image> [... <new image>]"
    echo
    echo "<production image>:  e.g. fdiotools/builder-ubuntu1804:prod-x86_64"
    echo "<new image>:         e.g. fdiotools/builder-ubuntu1804:2020_09_23_151655-x86_64"
    exit 1
}

image_user=""
image_repo=""
image_version=""
image_arch=""
parsed_image_name=""

parse_image_name() {
    image_user="$(echo $1 | cut -d'/' -f1)"
    image_repo="$(echo $1 | cut -d'/' -f2 | cut -d':' -f1)"
    local tag="$(echo $1 | cut -d':' -f2)"
    image_version="$(echo $tag | cut -d'-' -f1)"
    image_arch="$(echo $tag | sed -e s/$image_version-//)"
    parsed_image_name="$image_user/$image_repo:$image_version-$image_arch"
    if [ "$1" != "$parsed_image_name" ] ; then
        echo "ERROR: Image name parsing failed: $1 != '$parsed_image_name'"
        usage
    fi
}

verify_prod_image_name() {
    docker pull -q "$1" >& /dev/null
    if [ "$?" != "0" ] ; then
        echo "ERROR: Invalid production image '$1'!"
        return 1
    fi
}

verify_image_name() {
    # Invalid user
    if [ "$image_user" != "fdiotools" ] ; then
        return 1
    fi
    # Invalid version
    if [ "$image_version" != "prod" ] \
           && [[ "$image_version" =~ *([0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{6}) ]]
    then
        return 1
    fi
    # Invalid arch
    if ! [[ "$SUPPORTED_OS_ARCH" =~ .*"$image_arch".* ]] ; then
        return 1
    fi
    # Invalid repo
    verify_prod_image_name "$image_user/$image_repo:prod-$image_arch"
    return "$?"
}

pull_from_dockerhub() {
    echo "Pulling '$1' from dockerhub..."
    docker pull "$1"
}

push_to_dockerhub() {
    echo "Pushing '$1' to dockerhub..."
    docker push "$1"
}

revert_prod_image() {
    verify_image_name "$1"
}

promote_prod_image() {
    verify_image_name "$1"
}

# Validate arguments
num_args="$#"
if [ "$num_args" -lt "2" ] ; then
    echo "ERROR: Invalid number of arguments: $#"
    usage
fi

action=""
case "$1" in
    rev?(ert))
        action="revert"
        ;;
    pro?(mote))
        action="promote"
        ;;
    *)
        echo "ERROR: Invalid option '$1'!"
        usage
        ;;
esac
shift
docker login >& /dev/null

# Update local tags
tags_to_push=""
for image in "$@" ; do
    parse_image_name $image
    if [ "action" = "promote" ] ; then
        promote_prod_image $image
    else
        revert_prod_image $image
    fi
done

exit 0

# Push tags to repo
for tag in $tags_to_push ; do
    docker login
    docker push $docker_builder_image
done
