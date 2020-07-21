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
    echo "Usage: $0 [-c <class>] [-p] [-t <CI tag>] <os name> [... <os name>]"
    echo "  -c <class>               Defaults to 'builder'"
    executor_list_classes
    echo "  -p                       Push docker images to Docker Hub"
    echo "  -t <CI tag>-\$(uname -m)  Tag the image with a well-known CI tag:"
    echo "     test-$OS_ARCH"
    echo "     sandbox-$OS_ARCH"
    executor_list_os_names
    exit 1
}

must_be_run_as_root

push_to_docker_hub=""
ci_tag=""
ci_image=""
executor_class="builder"
while getopts ":hpc:t:" opt; do
    case "$opt" in
        c) if grep -q "$OPTARG" <<< $EXECUTOR_CLASSES ; then
               executor_class="$OPTARG"
           else
               echo "ERROR: Invalid executor class '$OPTARG'!"
               usage
           fi ;;
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
docker_build_setup_ciman
docker_build_setup_vpp
docker_build_setup_csit
for executor_os_name in $@ ; do
    docker_from_image="$(echo $executor_os_name | sed -e 's/-/:/')"
    # Remove '-' and '.' from executor_os_name in Docker Hub repo name
    os_name="${executor_os_name//-}"
    repository="fdiotools/${executor_class}-${os_name//.}"
    executor_docker_image="$repository:$DOCKER_TAG"
    shift

    # Assume all projects build on the same OS's as VPP
    if [ -z "$(echo ${!VPP_BRANCHES[*]} | grep $executor_os_name)" ] ; then
        executor_bad_os_name "$executor_os_name"
        continue
    fi
    case "$executor_os_name" in
        ubuntu*)
            generate_apt_dockerfile $executor_os_name $docker_from_image \
                                    $executor_docker_image ;;
        debian*)
            generate_apt_dockerfile $executor_os_name $docker_from_image \
                                    $executor_docker_image ;;
        centos-7)
            generate_yum_dockerfile $executor_os_name $docker_from_image \
                                    $executor_docker_image ;;
        centos-8)
            generate_dnf_dockerfile $executor_os_name $docker_from_image \
                                    $executor_docker_image ;;
        *)
            echo "ERROR: Don't know how to generate dockerfile for $executor_os_name!"
            usage ;;
    esac

    docker build -t $executor_docker_image $DOCKER_BUILD_DIR
    rm -f $DOCKERFILE
    if [ -n "$ci_tag" ] ; then
        ci_image="$repository:$ci_tag"
        echo -e "\nAdding docker tag $ci_image to $executor_docker_image"
        docker tag $executor_docker_image $ci_image
    fi
    if [ -n "$push_to_docker_hub" ] ; then
        echo -e "\nPushing $executor_docker_image to Docker Hub..."
        docker login
        docker push $executor_docker_image
        if [ -n "$ci_image" ] ; then
            echo -e "\nPushing $ci_image to Docker Hub..."
            docker push $ci_image
        fi
    fi
done
