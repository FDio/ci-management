#! /bin/bash

# Copyright (c) 2024 Cisco and/or its affiliates.
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
export DOCKER_DATE=${DOCKER_DATE:-"$(date -u +%Y_%m_%d_%H%M%S_UTC)"}
logname="/tmp/$(basename $0).${DOCKER_DATE}.log"
echo -e "\n*** Logging output to $logname ***\n\n"
exec > >(tee -a $logname) 2>&1

export CIMAN_DOCKER_SCRIPTS=${CIMAN_DOCKER_SCRIPTS:-"$(dirname $BASH_SOURCE)"}
. "$CIMAN_DOCKER_SCRIPTS/lib_vpp.sh"
. "$CIMAN_DOCKER_SCRIPTS/lib_csit.sh"
. "$CIMAN_DOCKER_SCRIPTS/lib_apt.sh"

all_os_names=""
ci_tag=""
ci_image=""
os_names=""
push_to_docker_hub=""
dump_dockerfile=""
gha_container=""
skip_executor_build=""
executor_docker_image=""

usage() {
    set +x
    echo
    echo "Usage: $0 [-c <class>] [-p] [-r <role>] -a | <os name> [... <os name>]"
    echo "  -a                Run all OS's supported on class $EXECUTOR_CLASS & arch $OS_ARCH"
    echo "  -b <builder img>  Bake GitHub Action variant from specified builder class image"
    echo "  -c <class>        Default is '$EXECUTOR_DEFAULT_CLASS'"
    executor_list_classes
    echo "  -d                Generate Dockerfile, dump it to stdout, and exit"
    echo "  -g                Bake GitHub Action variant of builder class"
    echo "  -p                Push docker images to Docker Hub"
    echo "  -r <role>         Add a role based tag (e.g. sandbox-x86_64):"
    executor_list_roles
    executor_list_os_names
    exit 1
}

must_be_run_as_root_or_docker_group
while getopts ":ab:c:dghpr:" opt; do
    case "$opt" in
        a)  all_os_names="1" ;;
        b) if executor_verify_image "$OPTARG" ; then
               gha_container="1"
               skip_executor_build="1"
               executor_docker_image="$OPTARG"
           else
               echo "ERROR: Existing executor image '$OPTARG' not found!"
               usage
           fi ;;
        c) if executor_verify_class "$OPTARG" ; then
               EXECUTOR_CLASS="$OPTARG"
               EXECUTOR_CLASS_ARCH="$EXECUTOR_CLASS-$OS_ARCH"
           else
               echo "ERROR: Invalid executor class '$OPTARG'!"
               usage
           fi ;;
        d) dump_dockerfile="1"; set +x ;;
        g) gha_container="1" ;;
        h) usage ;;
        p) push_to_docker_hub="1" ;;
        r) if executor_verify_role "$OPTARG" ; then
               ci_tag="${OPTARG}-$OS_ARCH"
           else
               echo "ERROR: Invalid executor role: '$OPTARG'!"
               usage
           fi ;;
        \?)
            echo "ERROR: Invalid option: -$OPTARG" >&2
            usage ;;
        :)
            echo "ERROR: Option -$OPTARG requires an argument." >&2
            usage ;;
    esac
done
shift $(( $OPTIND-1 ))

if [ -n "$all_os_names" ] ; then
    os_names="${EXECUTOR_CLASS_ARCH_OS_NAMES[$EXECUTOR_CLASS_ARCH]}"
else
    os_names="$@"
fi

# Validate arguments
if [ -z "$os_names" ] ; then
    echo "ERROR: Missing executor OS name(s) for class '$EXECUTOR_CLASS'!"
    usage
fi
for executor_os_name in $os_names ; do
    if ! executor_verify_os_name "$executor_os_name" ; then
        set_opts="$-"
        set +x # disable trace output
        echo "ERROR: Invalid executor OS name for class '$EXECUTOR_CLASS': $executor_os_name!"
        executor_list_os_names
        echo
        exit 1
    fi
done

docker_build_setup_gha() {
    if [ -n "$gha_container" ] && vpp_supported_executor_class ; then
        rm -rf "$DOCKER_GHA_RUNNER_DIR"
        mkdir -p "$DOCKER_GHA_RUNNER_DIR"
        cp "$DOCKER_CIMAN_GHA_RUNNER_DIR"/* "$DOCKER_GHA_RUNNER_DIR"
        pushd "$DOCKER_GHA_RUNNER_DIR"
        local gha_runner_tarball="actions-runner-linux-${GHA_ARCH}-${DOCKER_GHA_RUNNER_VERSION}.tar.gz"
        wget -q https://github.com/actions/runner/releases/download/v${DOCKER_GHA_RUNNER_VERSION}/"$gha_runner_tarball"
        tar xzf ./"$gha_runner_tarball"
        rm -f "$gha_runner_tarball"
        popd
    fi
}

# Build the specified docker images
docker_build_setup_ciman
docker_build_setup_vpp
docker_build_setup_csit
docker_build_setup_gha
for executor_os_name in $os_names ; do
    docker_from_image="${executor_os_name/-/:}"
    # Remove '-' and '.' from executor_os_name in Docker Hub repo name
    os_name="${executor_os_name//-}"
    os_name="${os_name//.}"
    repository="fdiotools/${EXECUTOR_CLASS}-$os_name"
    if [ -z "$executor_docker_image" ] ; then
        executor_docker_image="$repository:$DOCKER_TAG"
    elif ! grep -q "$os_name" <<< "$executor_docker_image" ; then
        set_opts="$-"
        set +x # disable trace output
        echo "ERROR: OS name '$os_name' missing from executor image specified in '-b $executor_docker_image'!"
        echo
        exit 1
    fi

    case "$executor_os_name" in
        ubuntu*)
            generate_apt_dockerfile "$EXECUTOR_CLASS" "$executor_os_name" \
                                    "$docker_from_image" "$executor_docker_image" ;;
        debian*)
            generate_apt_dockerfile "$EXECUTOR_CLASS" "$executor_os_name" \
                                    "$docker_from_image" "$executor_docker_image" ;;
        *)
            echo "ERROR: Don't know how to generate dockerfile for OS $executor_os_name!"
            usage ;;
    esac

    if [ -n "$dump_dockerfile" ] ; then
        line="==========================================================================="
        echo -e "\nDockerfile for '$EXECUTOR_CLASS' executor docker image on OS '$executor_os_name':\n$line"
        cat "$DOCKERFILE"
        echo -e "$line\n"
    else
        docker login
        if [ -z "$skip_executor_build" ] ; then
            docker build -t "$executor_docker_image" "$DOCKER_BUILD_DIR"
            rm -f "$DOCKERFILE"
        fi
        if [ -n "$gha_container" ] ; then
            gha_docker_image="${executor_docker_image/$EXECUTOR_CLASS/gha}"
            pushd "$DOCKER_GHA_RUNNER_DIR"
            EXECUTOR_DOCKER_IMAGE="$executor_docker_image" \
                GHA_DOCKER_IMAGE="$gha_docker_image" \
                PLATFORMS=linux/"$DEB_ARCH" \
                DOCKER_GHA_RUNNER_DIR="$DOCKER_GHA_RUNNER_DIR" \
                docker buildx bake -f "docker-bake.hcl" --no-cache --load
            popd
        fi
        if [ -n "$ci_tag" ] ; then
            ci_image="$repository:$ci_tag"
            echo -e "\nAdding docker tag $ci_image to $executor_docker_image"
            docker tag "$executor_docker_image" "$ci_image"
            if [ -n "$gha_container" ] ; then
                gha_image="${ci_image/$EXECUTOR_CLASS/gha}"
                echo -e "\nAdding docker tag $gha_image to $gha_docker_image"
                docker tag "$gha_docker_image" "$gha_image"
            fi
        fi
        if [ -n "$push_to_docker_hub" ] ; then
            echo -e "\nPushing $executor_docker_image to Docker Hub..."
            docker push "$executor_docker_image"
            if [ -n "$ci_image" ] ; then
                echo -e "\nPushing $ci_image to Docker Hub..."
                docker push "$ci_image"
            fi
            if [ -n "$gha_image" ] ; then
                echo -e "\nPushing $gha_image to Docker Hub..."
                docker push "$gha_image"
            fi
        fi
    fi
done

echo -e "\n$(basename $BASH_SOURCE) COMPLETE\nHave a great day! :D"
