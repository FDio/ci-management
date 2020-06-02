#!/bin/bash
set -euo pipefail

# Number of packages to keep.
N_PACKAGES=5

PACKAGECLOUD_RELEASE_REPO_DEB="https://packagecloud.io/install/repositories/fdio/release/script.deb.sh"
PACKAGECLOUD_RELEASE_REPO_RPM="https://packagecloud.io/install/repositories/fdio/release/script.rpm.sh"

FACTER_OS=$(/usr/bin/facter operatingsystem)
PACKAGE_LIST=""
VERSION_REGEX="[0-9]+.[0-9]+[-_][0-9]+[-_]release(-1)?|[0-9]+.[0-9]+[-_][0-9]+~g[[:graph:]]+"

declare -A FUNCTIONS

echo_err () {
    >&2 echo ${@}
    exit 1
}

contains() {
    [[ ${1} =~ (^|[[:space:]])${2}($|[[:space:]]) ]] && return 1 || return 0
}

check_version_whitelist() {
    if [[ ${1} =~ ([0-9]+).([0-9]+)[-_]([0-9]+).+ ]]; then
        MAJOR=${BASH_REMATCH[1]}
        MINOR=${BASH_REMATCH[2]}
        REVISION=${BASH_REMATCH[3]}
        VER="${MAJOR}.${MINOR}-${REVISION}"

        if contains "${VERSION_WHITELIST}" ${VER}; then
            return 1;
        fi
    fi

    return 0
}

# Params
# $1: Package list
build_package_blacklist_ubuntu () {
    PACKAGE_LIST=${@}
    OUTPUT_LIST=""
    ARCH=$(dpkg --print-architecture)

    for package in ${PACKAGE_LIST}; do
        OUTPUT=$(apt-cache policy ${package} 2> /dev/null)

        if [[ ${?} -ne 0 || -z "${OUTPUT}" ]]; then
            continue
        fi

        VERSIONS="$(echo ${OUTPUT} | grep -E -o ${VERSION_REGEX} | tail -n +$((N_PACKAGES + 2)))"

        for version in ${VERSIONS}; do
            if ! check_version_whitelist ${version}; then
                OUTPUT_LIST+="${package}_${version}_${ARCH}.deb "
            fi
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
        OUTPUT=$(yum --showduplicates list ${package} 2> /dev/null)
        if [[ ${?} -ne 0 || -z "${OUTPUT}" ]]; then
            continue
        fi

        VERSIONS="$(echo ${OUTPUT} | grep -Eo "${VERSION_REGEX}" | head -n -${N_PACKAGES})"

        for version in ${VERSIONS}; do
            if ! check_version_whitelist ${version}; then
                OUTPUT_LIST+="${package}-${version}.${ARCH}.rpm "
            fi
        done
    done

    echo ${OUTPUT_LIST}
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
        PACKAGE_LIST="${PACKAGE_LIST_COMMON} ${PACKAGE_LIST_UBUNTU}"
      ;;
      CentOS)
        curl -s ${PACKAGECLOUD_RELEASE_REPO_RPM} | sudo bash
        FUNCTIONS["package_blacklist"]="build_package_blacklist_centos"
        FUNCTIONS["promote_attic_repo"]="promote_attic_repo_centos"
        PACKAGE_LIST="${PACKAGE_LIST_COMMON} ${PACKAGE_LIST_CENTOS}"
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