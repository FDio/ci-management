#!/bin/bash
set -euo pipefail

# Number of packages to keep.
N_PACKAGES=5

SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE}")" ; pwd -P )

PACKAGECLOUD_RELEASE_REPO_DEB="https://packagecloud.io/install/repositories/fdio/release/script.deb.sh"
PACKAGECLOUD_RELEASE_REPO_RPM="https://packagecloud.io/install/repositories/fdio/release/script.rpm.sh"

PACKAGE_LIST_COMMON_FILE="${SCRIPT_PATH}/package-list-common.txt"
PACKAGE_LIST_CENTOS_FILE="${SCRIPT_PATH}/package-list-centos.txt"
PACKAGE_LIST_UBUNTU_FILE="${SCRIPT_PATH}/package-list-ubuntu.txt"

FACTER_OS=$(/usr/bin/facter operatingsystem)
PACKAGE_LIST=""

declare -A FUNCTIONS

echo_err () {
    >&2 echo ${@}
    exit -1
}

# Params
# $1: Package list
build_package_blacklist_ubuntu () {
    PACKAGE_LIST=${@}
    OUTPUT_LIST=""
    ARCH=$(dpkg --print-architecture)

    for package in ${PACKAGE_LIST}; do
        OUTPUT=$(apt-cache policy ${package})

        if [ -z "${OUTPUT}" ]; then
            continue
        fi

        VERSIONS="$(echo ${OUTPUT} | grep -E -o "[[:graph:]]*\-release|[0-9]+.[0.9]+-[0-9]+~g[[:graph:]]*" | tail -n +${N_PACKAGES})"

        for version in ${VERSIONS}; do
            OUTPUT_LIST+="${package}_${version}_${ARCH}.deb "
        done
    done

    echo ${OUTPUT_LIST}
}

# Params
# $1: Package list
build_package_blacklist_centos () {
    PACKAGE_LIST=${@}
    OUTPUT_LIST=""
    VERSIONS=""
    ARCH=$(uname -m)

    for package in ${PACKAGE_LIST}; do
        VERSIONS="$(yum --showduplicates list ${package} | grep -o "[[:graph:]]*\_release-1" | head -n -10 +${N_PACKAGES})"

        for version in ${VERSIONS}; do
            OUTPUT_LIST+="${package}-${version}.${ARCH}.rpm "
        done
    done

    echo ${OUTPUT_LIST}
}

cat_without_comments () {
    ret=""
    for file in ${@}; do
        if [[ -f ${file} ]]; then
            while IFS= read -r line; do
                # if value of $var starts with #, ignore it
                [[ $line =~ ^#.* ]] && continue
                ret+="${line} "
            done < ${file}
        fi
    done

    echo ${ret}
}

promote_attic_repo_centos () {
    FACTER_OSMAJREL=$(/usr/bin/facter operatingsystemmajrelease)
    FACTER_ARCH=$(/usr/bin/facter architecture)

    for package in ${@}; do
        echo package_cloud promote \
            ${PCIO_CO}/${STREAM}/el/${FACTER_OSMAJREL}/os/${FACTER_ARCH}/ \
            ${package} ${PCIO_CO}/attic/el/${FACTER_OSMAJREL}/os/${FACTER_ARCH}/
    done
}

promote_attic_repo_ubuntu () {
    FACTER_LSBNAME=$(/usr/bin/facter lsbdistcodename)

    for package in ${@}; do
        echo package_cloud promote ${PCIO_CO}/${STREAM}/ubuntu/${FACTER_LSBNAME}/main/ \
            ${package} ${PCIO_CO}/attic/ubuntu/${FACTER_LSBNAME}/main/
    done
}

promote_to_attic_repo () {
    ${FUNCTIONS["promote_attic_repo"]} ${@}
}

setup_fdio_repo () {
    case "${FACTER_OS}" in
      Ubuntu)
        curl -s ${PACKAGECLOUD_RELEASE_REPO_DEB} | sudo bash
        FUNCTIONS["package_blacklist"]="build_package_blacklist_ubuntu"
        FUNCTIONS["promote_attic_repo"]="promote_attic_repo_ubuntu"
        PACKAGE_LIST=$(cat_without_comments ${PACKAGE_LIST_COMMON_FILE} ${PACKAGE_LIST_UBUNTU_FILE})
      ;;
      CentOS)
        curl -s ${PACKAGECLOUD_RELEASE_REPO_RPM} | sudo bash
        FUNCTIONS["package_blacklist"]="build_package_blacklist_centos"
        FUNCTIONS["promote_attic_repo"]="promote_attic_repo_centos"
        PACKAGE_LIST=$(cat_without_comments ${PACKAGE_LIST_COMMON_FILE} ${PACKAGE_LIST_CENTOS_FILE})
      ;;
      *)
        echo_err "Distribution ${FACTER_OS} is not supported."
      ;;
    esac
}

# Params
# $1: Package list
build_package_blacklist () {
    ${FUNCTIONS["package_blacklist"]} ${@}
}

setup_fdio_repo
PACKAGES_TO_PROMOTE=$(build_package_blacklist ${PACKAGE_LIST})
promote_to_attic_repo ${PACKAGES_TO_PROMOTE}