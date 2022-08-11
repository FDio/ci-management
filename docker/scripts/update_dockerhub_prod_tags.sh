#! /bin/bash

# Copyright (c) 2022 Cisco and/or its affiliates.
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

set -euo pipefail
shopt -s extglob

# Log all output to stdout & stderr to a log file
logname="/tmp/$(basename $0).$(date -u +%Y_%m_%d_%H%M%S).log"
echo -e "\n*** Logging output to $logname ***\n"
exec > >(tee -a $logname) 2>&1

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. "$CIMAN_DOCKER_SCRIPTS/lib_common.sh"

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
digest_prod=""
digest_prev=""
digest_new=""
restore_cmd=""

usage() {
    local script="$(basename $0)"
    echo
    echo "Usage: $script r[evert]  <prod image>"
    echo "       $script p[romote] <new image> [<new image>]"
    echo "       $script i[nspect] <prod image>"
    echo
    echo "  revert: swaps 'prod-<arch>' and 'prod-prev-<arch>' images"
    echo "          <prod image>: e.g. fdiotools/builder-ubuntu2204:prod-x86_64"
    echo
    echo " promote: moves 'prod-<arch>' image to 'prod-prev-<arch>' tag and"
    echo "          tags <new image> with 'prod-<arch>'"
    echo "          <new image>: e.g. fdiotools/builder-ubuntu2204:2022_07_23_151655-x86_64"
    echo " inspect: prints out all tags for prod-<arch> and prod-prev-<arch>"
    echo
    exit 1
}

echo_restore_cmd() {
    echo -e "\n$long_bar\n"
    echo "To restore tags to original state, issue the following command:"
    echo -e "\n$restore_cmd\n\n$long_bar\n"
}

push_to_dockerhub() {
    echo_restore_cmd
    for image in "$@" ; do
        set +e
        echo "Pushing '$image' to docker hub..."
        if ! docker push "$image" ; then
            echo "ERROR: 'docker push $image' failed!"
            exit 1
        fi
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
    # Note: 'grep $image_arch' & grep -v 'prod-curr' is required due to a
    #       bug in docker hub which returns old tags which were deleted via
    #       the webUI, but are still retrieved by 'docker pull -a'
    image_tags="$(docker images | grep $1 | grep $image_arch | grep -v prod-curr | sort -r | mawk '{print $1":"$2}' | tr '\n' ' ')"
    image_realname="$(docker images | grep $1 | grep $image_arch | sort -r | grep -v prod | mawk '{print $1":"$2}' || true)"
    if [ -z "${image_realname:-}" ] ; then
        image_realname="$image_tags"
    fi
}

get_image_id_tags() {
    for image in "$image_name_new" "$image_name_prod" "$image_name_prev" ; do
        if [ -z "$image" ] ; then
            continue
        fi
        # ensure image exists
        set +e
        local image_found="$(docker images | mawk '{print $1":"$2}' | grep $image)"
        set -e
        if [ -z "$image_found" ] ; then
            if [ "$image" = "$image_name_prev" ] ; then
                if [ "$action" = "revert" ] ; then
                    echo "ERROR: Image '$image' not found!"
                    echo "Unable to revert production image '$image_name_prod'!"
                    usage
                else
                    continue
                fi
            else
                echo "ERROR: Image '$image' not found!"
                usage
            fi
        fi
        set +e
        local id="$(docker image inspect $image | mawk -F':' '/Id/{print $3}')"
        local digest="$(docker image inspect $image | grep -A1 RepoDigests | grep -v RepoDigests | mawk -F':' '{print $2}')"
        local retval="$?"
        set -e
        if [ "$retval" -ne "0" ] ; then
            echo "ERROR: Docker ID not found for '$image'!"
            usage
        fi
        if [ "$image" = "$image_name_prod" ] ; then
            docker_id_prod="${id::12}"
            digest_prod="${digest::12}"
            format_image_tags "$docker_id_prod"
            image_tags_prod="$image_tags"
            if [ -z "$image_realname_prod" ] ; then
                image_realname_prod="$image_realname"
            fi
        elif [ "$image" = "$image_name_prev" ] ; then
            docker_id_prev="${id::12}"
            digest_prev="${digest::12}"
            format_image_tags "$docker_id_prev"
            image_tags_prev="$image_tags"
            if [ -z "$image_realname_prev" ] ; then
                image_realname_prev="$image_realname"
            fi
        else
            docker_id_new="${id::12}"
            digest_new="${digest::12}"
            format_image_tags "$docker_id_new" "NEW"
            image_tags_new="$image_tags"
        fi
    done
    if [ -z "$restore_cmd" ] ; then
        restore_cmd="sudo $0 p $image_realname_prev $image_realname_prod"
    fi
}

get_all_tags_from_dockerhub() {
    local dh_repo="$image_user/$image_repo"
    echo -e "Pulling all tags from docker hub repo '$dh_repo':\n$long_bar"
    if ! docker pull -a "$dh_repo" ; then
        echo "ERROR: Repository '$dh_repo' not found on docker hub!"
        usage
    fi
    echo "$long_bar"
}

verify_image_version_date_format() {
    version="$1"
    # TODO: Remove regex1 when legacy nomenclature is no longer on docker hub.
    local regex1="^[0-9]{4}_[0-1][0-9]_[0-3][0-9]_[0-2][0-9][0-5][0-9][0-5][0-9]$"
    local regex2="^[0-9]{4}_[0-1][0-9]_[0-3][0-9]_[0-2][0-9][0-5][0-9][0-5][0-9]_UTC$"
    if [[ "$version" =~ $regex1 ]] || [[ "$version" =~ $regex2 ]]; then
        return 0
    fi
    return 1
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
           && ! verify_image_version_date_format "$image_version"  ]] ; then
        image_not_found="true"
        echo "ERROR: invalid version '$image_version' in '$image_name_new'!"
    fi
    # Invalid arch
    if [ -z "$image_not_found" ] \
           && ! [[ "$EXECUTOR_ARCHS" =~ .*"$image_arch".* ]] ; then
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
    docker tag "$1" "$2"
    local retval="$?"
    set -e
    if [ "$retval" -ne "0" ] ; then
        echo "WARNING: 'docker tag $1 $2' failed!"
    fi
}

docker_rmi_tag() {
    set +e
    echo ">>> docker rmi $1"
    docker rmi "$1"
    local retval="$?"
    set -e
    if [ "$retval" -ne "0" ] ; then
        echo "WARNING: 'docker rmi $1' failed!"
    fi
}

print_image_list() {
    if [ -z "$2" ] ; then
        echo "$1 Image Not Found"
        return
    fi
    echo "$1 (Id $2, Digest $3):"
    for image in $4 ; do
        echo -e "\t$image"
    done
}

inspect_images() {
    echo -e "\n${1}Production Docker Images:"
    echo "$short_bar"
    if [ -n "$image_tags_new" ] ; then
        print_image_list "NEW" "$docker_id_new" "$digest_new" "$image_tags_new"
        echo
    fi
    print_image_list "prod-$image_arch" "$docker_id_prod" "$digest_prod" \
                     "$image_tags_prod"
    echo
    print_image_list "prod-prev-$image_arch" "$docker_id_prev" "$digest_prev" \
                     "$image_tags_prev"
    echo -e "$short_bar\n"
}

revert_prod_image() {
    inspect_images "EXISTING "
    docker_tag_image "$docker_id_prod" "$image_name_prev"
    docker_tag_image "$docker_id_prev" "$image_name_prod"
    get_image_id_tags
    inspect_images "REVERTED "

    local yn=""
    while true; do
        read -p "Push Reverted tags to '$image_user/$image_repo' (yes/no)? " yn
        case ${yn:0:1} in
            y|Y )
                break ;;
            n|N )
                echo -e "\nABORTING REVERT!\n"
                docker_tag_image $docker_id_prev $image_name_prod
                docker_tag_image $docker_id_prod $image_name_prev
                get_image_id_tags
                inspect_images "RESTORED LOCAL "
                exit 1 ;;
            * )
                echo "Please answer yes or no." ;;
        esac
    done
    echo
    push_to_dockerhub $image_name_prev $image_name_prod
    inspect_images ""
    echo_restore_cmd
}

promote_new_image() {
    inspect_images "EXISTING "
    docker_tag_image "$docker_id_prod" "$image_name_prev"
    docker_tag_image "$docker_id_new" "$image_name_prod"
    get_image_id_tags
    inspect_images "PROMOTED "

    local yn=""
    while true; do
        read -p "Push promoted tags to '$image_user/$image_repo' (yes/no)? " yn
        case "${yn:0:1}" in
            y|Y )
                break ;;
            n|N )
                echo -e "\nABORTING PROMOTION!\n"
                docker_tag_image "$docker_id_prev" "$image_name_prod"
                local restore_both="$(echo $restore_cmd | mawk '{print $5}')"
                if [[ -n "$restore_both" ]] ; then
                    docker_tag_image "$image_realname_prev" "$image_name_prev"
                else
                    docker_rmi_tag "$image_name_prev"
                    image_name_prev=""
                    docker_id_prev=""
                fi
                get_image_id_tags
                inspect_images "RESTORED "
                exit 1 ;;
            * )
                echo "Please answer yes or no." ;;
        esac
    done
    echo
    push_to_dockerhub "$image_name_new" "$image_name_prev" "$image_name_prod"
    inspect_images ""
    echo_restore_cmd
}

must_be_run_as_root_or_docker_group

# Validate arguments
num_args="$#"
if [ "$num_args" -lt "1" ] ; then
    usage
fi
action=""
case "$1" in
    r?(evert))
        action="revert"
        if [ "$num_args" -ne "2" ] ; then
            echo "ERROR: Invalid number of arguments: $#"
            usage
        fi ;;
    p?(romote))
        if [ "$num_args" -eq "2" ] || [ "$num_args" -eq "3" ] ; then
            action="promote"
        else
            echo "ERROR: Invalid number of arguments: $#"
            usage
        fi ;;
    i?(nspect))
        action="inspect"
        if [ "$num_args" -ne "2" ] ; then
            echo "ERROR: Invalid number of arguments: $#"
            usage
        fi ;;
    *)
        echo "ERROR: Invalid option '$1'!"
        usage ;;
esac
shift
docker login >& /dev/null

# Update local tags
tags_to_push=""
for image in "$@" ; do
    parse_image_name "$image"
    verify_image_name "$image"
    get_all_tags_from_dockerhub
    get_image_id_tags
    if [ "$action" = "promote" ] ; then
        if [ -n "$image_name_new" ] ; then
            promote_new_image
        else
            echo "ERROR: No new image specified to promote!"
            usage
        fi
    elif [ "$action" = "revert" ] ; then
        if [ "$image_version" = "prod" ] ; then
            revert_prod_image
        else
            echo "ERROR: Non-production image '$image' specified!"
            usage
        fi
    else
        if [ "$image_version" = "prod" ] ; then
            inspect_images ""
        else
            echo "ERROR: Non-production image '$image' specified!"
            usage
        fi
    fi
done
