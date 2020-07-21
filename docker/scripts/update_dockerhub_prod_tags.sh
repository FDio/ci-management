#! /bin/bash

set -euo pipefail
shopt -s extglob

# Log all output to stdout & stderr to a log file
logname="/tmp/$(basename $0).$(date +%Y_%m_%d_%H%M%S).log"
echo -e "\n*** Logging output to $logname ***\n"
exec > >(tee -a $logname) 2>&1

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh

# Global variables
long_bar="################################################################"
short_bar="-----"
image_not_found=""
image_user=""
image_repo=""
image_version=""
image_arch=""
image_name_prod=""
image_name_prev=""
image_name_new=""
image_realname=""
image_realname_prod=""
image_realname_prev=""
image_tags=""
image_tags_prod=""
image_tags_prev=""
image_tags_new=""
docker_id_prod=""
docker_id_prev=""
docker_id_new=""
restore_cmd=""

usage() {
    local script="$(basename $0)"
    echo
    echo "Usage: $script r[evert]  <prod image>"
    echo "       $script p[romote] <new image> [<new image>]"
    echo "       $script i[nspect] <prod image>"
    echo
    echo "  revert: swaps 'prod-<arch>' and 'prod-prev-<arch>' images"
    echo "          <prod image>: e.g. fdiotools/builder-ubuntu1804:prod-x86_64"
    echo
    echo " promote: moves 'prod-<arch>' image to 'prod-prev-<arch>' tag and"
    echo "          tags <new image> with 'prod-<arch>'"
    echo "          <new image>: e.g. fdiotools/builder-ubuntu1804:2020_09_23_151655-x86_64"
    echo " inspect: prints out all tags for prod-<arch> and prod-prev-<arch>"
    echo
    exit 1
}

echo_restore_cmd() {
    echo -e "\n$long_bar"
    echo "To restore tags to original state, issue the following command:"
    echo -e "\n$restore_cmd\n$long_bar"
}

push_to_dockerhub() {
    for image in "$@" ; do
        echo "Pushing '$image' to dockerhub..."
        docker push "$image"
    done
}

parse_image_name() {
    image_user="$(echo $1 | cut -d'/' -f1)"
    image_repo="$(echo $1 | cut -d'/' -f2 | cut -d':' -f1)"
    local tag="$(echo $1 | cut -d':' -f2)"
    image_version="$(echo $tag | cut -d'-' -f1)"
    image_arch="$(echo $tag | sed -e s/$image_version-//)"
    image_name_new="${image_user}/${image_repo}:${image_version}-${image_arch}"
    if [ "$1" != "$image_name_new" ] ; then
        echo "ERROR: Image name parsing failed: $1 != '$image_name_new'"
        usage
    fi
    if [[ "$image_version" =~ "prod" ]] ; then
        image_name_new=""
    fi
    image_name_prod="${image_user}/${image_repo}:prod-${image_arch}"
    image_name_prev="${image_user}/${image_repo}:prod-prev-${image_arch}"
}

format_image_tags() {
    image_tags="$(docker images | grep $1 | sort -r | mawk '{print $1":"$2}' | tr '\n' ' ')"
    # Note: 'grep $image_arch' is required due to a bug in docker hub which
    #       returns old tags which were supposedly deleted, but are pulled
    #       by 'docker pull -a'
    image_realname="$(docker images | grep $1 | grep $image_arch | sort -r | grep -v prod |  mawk '{print $1":"$2}')"
}

get_image_id_tags() {
    for image in "$@" ; do
        if [ -z "$image" ] ; then
            continue
        fi
        set +e
        local id="$(docker image inspect $image | mawk -F':' '/Id/{print $3}')"
        local retval="$?"
        set -e
        if [ "$retval" -ne "0" ] ; then
            echo "ERROR: Invalid image name '$image'!"
            usage
        fi
        if [ "$image" = "$image_name_prod" ] ; then
            docker_id_prod="${id::12}"
            format_image_tags "$docker_id_prod"
            image_tags_prod="$image_tags"
            if [ -z "$image_realname_prod" ] ; then
                image_realname_prod="$image_realname"
            fi
       elif [ "$image" = "$image_name_prev" ] ; then
            docker_id_prev="${id::12}"
            format_image_tags "$docker_id_prev"
            image_tags_prev="$image_tags"
            if [ -z "$image_realname_prev" ] ; then
                image_realname_prev="$image_realname"
            fi
        else
            docker_id_new="${id::12}"
            format_image_tags "$docker_id_new" "new"
            image_tags_new="$image_tags"
        fi
    done
    if [ -z "$restore_cmd" ] \
           && [ -n "$image_realname_prod" ] \
           && [ -n "$image_realname_prev" ] ; then
        restore_cmd="sudo $0 pro $image_realname_prev $image_realname_prod"
    fi
}

get_all_tags_from_dockerhub() {
    local dh_repo="$image_user/$image_repo"
    set +e
    echo "Pulling all tags from docker hub repo '$dh_repo'..."
    docker pull -aq "$dh_repo" >& /dev/null
    local retval="$?"
    set -e
    if [ "$retval" -ne "0" ] ; then
        echo "ERROR: Repository '$dh_repo' not found on docker hub!"
        usage
    fi
}

verify_image_name() {
    image_not_found=""
    # Invalid user
    if [ "$image_user" != "fdiotools" ] ; then
        image_not_found="true"
        echo "ERROR: invalid user '$image_user' in '$image_name_new'!"
    fi
    # Invalid version
    if [ -z "$image_not_found" ] \
           && [ "$image_version" != "prod" ] \
           && ! [[ "$image_version" =~ \
              ^[0-9]{4}_[0-1][0-9]_[0-3][0-9]_[0-2][0-9][0-5][0-9][0-5][0-9]$ ]]
    then
        image_not_found="true"
        echo "ERROR: invalid version '$image_version' in '$image_name_new'!"
    fi
    # Invalid arch
    if [ -z "$image_not_found" ] \
           && ! [[ "$SUPPORTED_OS_ARCH" =~ .*"$image_arch".* ]] ; then
        image_not_found="true"
        echo "ERROR: invalid arch '$image_arch' in '$image_name_new'!"
    fi
    if [ -n "$image_not_found" ] ; then
        echo "ERROR: Invalid image '$image_name_new'!"
        usage
    fi
}

docker_tag_image() {
    echo ">>> docker tag $1 $2"
    set +e
    docker tag $1 $2
    local retval="$?"
    set -e
    if [ "$retval" -ne "0" ] ; then
        echo "ERROR: 'docker tag $1 $2' failed!"
    fi
}

print_image_list() {
    echo "$1:"
    for image in $2 ; do
        echo -e "\t$image"
    done
    echo
}

push_to_dockerhub() {
    # Set up a signal handler to inform user how to restore the
    # docker hub repo if the script is killed during the upload
    # loop
    function cleanup_on_int() {
        echo -e "\n$long_bar\nWARNING: INTERRUPT or TERMINATION SIGNALLED!"
        echo "Docker hub repo '$image_user/$image_repo' may be in an invalid state!"
        echo_restore_cmd
        trap -- INT
        kill -s INT "$$"
    }

    trap 'cleanup_on_int' INT TERM HUP QUIT
    for image in "$@" ; do
        set +e
        echo "Pushing '$image' to docker hub..."
        docker push $image
        local retval="$?"
        set -e
        if [ "$retval" != "0" ] ; then
            echo "ERROR: 'docker push $image' failed!"
            echo_restore_cmd
            exit 1
        fi
    done
    trap -- INT TERM HUP QUIT
}


inspect_images() {
    echo -e "\n$1 Docker Images:"
    echo "$short_bar"
    print_image_list "prod-$image_arch Id $docker_id_prod" "$image_tags_prod"
    print_image_list "prod-prev-$image_arch Id $docker_id_prev" \
                     "$image_tags_prev"
    if [ -n "$image_tags_new" ] ; then
        print_image_list "new Id $docker_id_new" "$image_tags_new"
    fi
    echo "$short_bar"
}

revert_prod_image() {
    inspect_images "REVERT EXISTING"
    docker_tag_image $docker_id_prod $image_name_prev
    docker_tag_image $docker_id_prev $image_name_prod
    get_image_id_tags "$image_name_prod" "$image_name_prev" \
                      "$image_name_new"
    inspect_images "REVERTED"

    local yn=""
    while true; do
        read -p "Push Reverted tags to '$image_user/$image_repo' (yes/no)? " yn
        case ${yn:0:1} in
            y|Y )
                break;;
            n|N )
                echo "ABORTING REVERT!"
                docker_tag_image $docker_id_prev $image_name_prod
                docker_tag_image $docker_id_prod $image_name_prev
                get_image_id_tags "$image_name_prod" "$image_name_prev" \
                                  "$image_name_new"
                inspect_images "RESTORED"
                exit 1;;
            * )
                echo "Please answer yes or no.";;
        esac
    done
    echo
    push_to_dockerhub $image_name_prev $image_name_prod
    echo_restore_cmd
}

promote_new_image() {
    inspect_images "EXISTING"
    docker_tag_image $docker_id_prod $image_name_prev
    docker_tag_image $docker_id_new $image_name_prod
    get_image_id_tags "$image_name_prod" "$image_name_prev" \
                      "$image_name_new"
    inspect_images "PROMOTED"

    local yn=""
    while true; do
        read -p "Push promoted tags to '$image_user/$image_repo' (yes/no)? " yn
        case ${yn:0:1} in
            y|Y )
                break;;
            n|N )
                echo "ABORTING PROMOTION!"
                docker_tag_image $docker_id_prev $image_name_prod
                docker_tag_image $image_realname_prev $image_name_prev
                get_image_id_tags "$image_name_prod" "$image_name_prev" \
                                  "$image_name_new"
                inspect_images "RESTORED"
                exit 1;;
            * )
                echo "Please answer yes or no.";;
        esac
    done
    echo
    push_to_dockerhub $image_name_prev $image_name_prod
    echo_restore_cmd
}

# Validate arguments
num_args="$#"
action=""
case "$1" in
    r?(evert))
        action="revert"
        if [ "$num_args" -ne "2" ] ; then
            echo "ERROR: Invalid number of arguments: $#"
            usage
        fi
        ;;
    p?(romote))
        action="promote"
        if [ "$num_args" -lt "2" ] || [ "$num_args -gt 3" ] ; then
            echo "ERROR: Invalid number of arguments: $#"
            usage
        fi
        ;;
    i?(nspect))
        action="inspect"
        if [ "$num_args" -ne "2" ] ; then
            echo "ERROR: Invalid number of arguments: $#"
            usage
        fi
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
    parse_image_name "$image"
    verify_image_name "$image"
    get_all_tags_from_dockerhub
    get_image_id_tags "$image_name_prod" "$image_name_prev" "$image_name_new"
    if [ "$action" = "promote" ] ; then
        promote_new_image
    elif [ "$action" = "revert" ] ; then
        revert_prod_image
    else
        inspect_images "INSPECT PRODUCTION"
    fi
done
