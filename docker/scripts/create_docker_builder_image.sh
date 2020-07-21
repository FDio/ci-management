#! /bin/bash

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

set -euxo pipefail

# Log all output to stdout & stderr to a log file
logname="/tmp/$(basename $0).$(date +%Y_%m_%d_%H%M%S).log"
echo -e "\n*** Logging output to $logname ***\n\n"
exec > >(tee -a $logname) 2>&1

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. $CIMAN_DOCKER_SCRIPTS/lib_vpp.sh
. $CIMAN_DOCKER_SCRIPTS/lib_csit.sh
. $CIMAN_DOCKER_SCRIPTS/lib_apt.sh
. $CIMAN_DOCKER_SCRIPTS/lib_yum.sh
. $CIMAN_DOCKER_SCRIPTS/lib_dnf.sh

usage() {
    set +x
    echo
    echo "Usage: $0 [-p] [-t <CI tag>] <os name> [... <os name>]"
    echo "  -p                     Push docker images to Docker Hub"
    echo "  -t <CI tag>-\$(uname -m)  Also tag the image with a CI tag:"
    echo "     test-$OS_ARCH"
    echo "     sandbox-$OS_ARCH"
    list_builder_os_names
    exit 1
}

list_builder_os_names() {
    if [ -n "$(alias lib_vpp_imported 2> /dev/null)" ] ; then
        echo
        echo "Valid builder OS names:"
        for os in "${!VPP_BRANCHES[@]}" ; do
            echo "  $os"
        done | sort
    fi
}

bad_builder_os_name() {
    echo "ERROR: Invalid builder OS name: $1!"
    list_builder_os_names
    echo
}

must_be_run_as_root

push_to_docker_hub=""
ci_tag=""
ci_image=""
while getopts ":hpt:" opt; do
    case "$opt" in
        h) usage ;;
        p) push_to_docker_hub=1
           ;;
        # Only allow test or sandbox tags.
        # Use update_dockerhub_prod_tags.sh for production tagging.
        t) if [ "$OPTARG" = "test-$OS_ARCH" ] \
                  || [ "$OPTARG" = "sandbox-$OS_ARCH" ] ; then
               ci_tag="$OPTARG"
           else
               echo "ERROR: Invalid CI tag: $OPTARG!"
               usage
           fi
           ;;
        \?)
            echo "ERROR: Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "ERROR: Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done
shift $(( $OPTIND-1 ))

# Validate arguments
if [ "$#" -eq "0" ] ; then
    usage
fi

# Build the specified docker images
docker_image_builder_setup_ciman
docker_image_builder_setup_vpp
docker_image_builder_setup_csit
for builder_os_name in $@ ; do
    docker_from_image="$(echo $builder_os_name | sed -e 's/-/:/')"
    # Remove '-' and '.' from builder_os_name in Docker Hub repo name
    os_name="${builder_os_name//-}"
    repository="fdiotools/builder-${os_name//.}"
    docker_builder_image="$repository:$DOCKER_TAG"
    shift

    # Assume all projects build on the same OS's as VPP
    if [ -z "$(echo ${!VPP_BRANCHES[*]} | grep $builder_os_name)" ] ; then
        bad_builder_os_name "$builder_os_name"
        continue
    fi
    case "$builder_os_name" in
        ubuntu*)
            generate_apt_dockerfile $builder_os_name $docker_from_image \
                                    $docker_builder_image ;;
        debian*)
            generate_apt_dockerfile $builder_os_name $docker_from_image \
                                    $docker_builder_image ;;
        centos-7)
            generate_yum_dockerfile $builder_os_name $docker_from_image \
                                    $docker_builder_image ;;
        centos-8)
            generate_dnf_dockerfile $builder_os_name $docker_from_image \
                                    $docker_builder_image ;;
        *)
            echo "ERROR: Don't know how to generate dockerfile for $builder_os_name!"
            usage ;;
    esac

    docker build -t $docker_builder_image $DOCKER_BUILD_DIR
    rm -f $DOCKERFILE
    if [ -n "$ci_tag" ] ; then
        ci_image="$repository:$ci_tag"
        echo -e "\nAdding docker tag $ci_image to $docker_builder_image"
        docker tag $docker_builder_image $ci_image
    fi
    if [ -n "$push_to_docker_hub" ] ; then
        echo -e "\nPushing $docker_builder_image to Docker Hub..."
        docker login
        docker push $docker_builder_image
        if [ -n "$ci_image" ] ; then
            echo -e "\nPushing $ci_image to Docker Hub..."
            docker push $ci_image
        fi
    fi
done
