#!/bin/bash

# Copyright 2016 The Linux Foundation

source ${CI_MGMT}/vagrant/lib/vagrant-functions.sh


source ${PVERC}

pip install -q --upgrade pip setuptools python-{cinder,glance,keystone,neutron,nova,openstack}client

#
# usage:
#   AGE_JSON=$(latest_src_age ${DIST} ${VERSION} ${ARCH})
#
function latest_src_age ()
{
    SRC_TS=$(latest_src_timestamp "$@")
    NOW_TS=$(new_timestamp)

    perl -I${CI_MGMT}/vagrant/lib -MRespin -e 'Respin::latest_src_age( @ARGV )' "${NOW_TS}" "${SRC_TS}"

    return 0
}

function new_timestamp ()
{
    date +'%F T %T' | sed -e 's/[-: ]//g'
}

function new_dst_timestamp ()
{
    if [ -z "${DST_TIMESTAMP}" ]
    then
        DST_TIMESTAMP=$(new_timestamp)
    fi

    echo ${DST_TIMESTAMP}
    return 0
}

function new_src_timestamp ()
{
    if [ -z "${SRC_TIMESTAMP}" ]
    then
        SRC_TIMESTAMP=$(date +'%F T %T' | sed -e 's/[-: ]//g')
    fi

    echo ${SRC_TIMESTAMP}
    return 0
}

function latest_src_timestamp ()
{
    if [ -z "${SRC_TIMESTAMP}" ]
    then
        SRC_TIMESTAMP=$(glance image-list | perl -n -e 'if( /\((\S+)\) - LF upload/ ){ print "$1\n" }' | sort | tail -1)
    fi

    echo ${SRC_TIMESTAMP}
    return 0
}

#
# usage:
#   glance_image_create ${IMG_NAME} ${IMG_PATH}
#
# example:
#   glance_image_create "CentOS 7 (20160517T143002) - LF upload" /var/lib/libvirt/images/CentOS-7-x86_64-GenericCloud.qcow2c
#
function glance_image_create ()
{
    glance image-create --disk-format qcow2 --container-format bare --progress \
           --name "${1}" --file "${2}"
}

function setup_rh ()
{
    SRC_TIMESTAMP=$(new_src_timestamp)
    DIST=$1
    VERSION=$2
    ARCH=$3
    ARCH=${ARCH:-${RH_ARCH64}}
    IMG_FNAME="${DIST}-${VERSION}-${ARCH}-GenericCloud.qcow2c"
    IMG_PATH="${LV_IMG_DIR}/${IMG_FNAME}"
    IMG_NAME="${DIST} ${VERSION} (${SRC_TIMESTAMP}) - LF upload"
}

#
# usage:
#   create_rh_image ${DIST} ${VERSION} ${ARCH}
#
# example:
#   create_rh_image CentOS 7 x86_64
#
function create_rh_image ()
{
    setup_rh "$@"

    if [ ! -f ${IMG_PATH} ]; then download_rh_image "$@"; fi

    glance_image_create "${IMG_NAME}" "${IMG_PATH}"
}

function download_rh_image ()
{
    setup_rh "$@"
    echo "--> Fetching image file for ${DIST} ${VERSION}"
    wget -qcP ${LV_IMG_DIR} "http://cloud.centos.org/centos/${VERSION}/images/${IMG_FNAME}"
}


declare -A deb_codename_map
deb_codename_map=(['3.0']=woody \
                  ['3.1']=sarge \
                  ['4']=etch \
                  ['5']=lenny \
                  ['6']=squeeze \
                  ['7']=wheezy \
                  ['8']=jessie \
                  ['9']=stretch \
                  ['10']=buster \
                 )
declare -A ubuntu_codename_map
ubuntu_codename_map=(['6.06']=dapper \
                     ['8.04']=hardy \
                     ['10.04']=lucid \
                     ['12.04']=precise \
                     ['14.04']=trusty \
                     ['16.04']=xenial \
                     )
DEB_CURRENT_VER='8.4.0'
DEB_CURRENT_CODENAME='jessie'

DEB_TESTING_VER='9.0.0'
DEB_TESTING_CODENAME='stretch'

DEB_UNSTABLE_VER='10.0.0'
DEB_UNSTABLE_CODENAME='buster'

function setup_deb ()
{
    SRC_TIMESTAMP=$(new_src_timestamp)
    DIST=$1
    VERSION=$2
    ARCH=$3
    ARCH=${ARCH:-${DEB_ARCH64}}

    declare -A V
    VVAL=$(echo ${VERSION} | perl -ne 'm/(?:(\d+)(?:\.(\d+))?)(?:\.(\d+))?/; $min=$2 // 0; $mic = $3 // 0; print qq{([maj]=$1 [min]=$min [mic]=$mic)}')
    eval "V=${VVAL}"

    LCDIST=$(echo ${DIST} | perl -ne 'print lc')

    MAJOR_VERSION="${V['maj']}"
    MINOR_VERSION="${MAJOR_VERSION}.${V['min']}"
    MICRO_VERSION="${MINOR_VERSION}.${V['mic']}"

    CODENAME=""

    if [ "Debian" == "${DIST}" ]
    then
        CODENAME="${deb_codename_map[$MINOR_VERSION]}"
        CODENAME=${CODENAME:-${deb_codename_map[$MAJOR_VERSION]}}
        if [ -z "$CODENAME" ]
        then
            echo "--> no codename for ${DIST} v${MICRO_VERSION}"
            return -2
        fi

        URL_PFX="http://cdimage.debian.org/cdimage/openstack/"

        if [ "${DEB_CURRENT_CODENAME}" == "${CODENAME}" ]
        then
            OSTACK_SUBDIR='current'
            QCOW_VER=${MICRO_VERSION}
        elif [ "${DEB_TESTING_CODENAME}" == "${CODENAME}" ]
        then
            OSTACK_SUBDIR='testing'
            QCOW_VER='testing'
        else
            echo "--> Not certain where to find images for ${DIST} v${MICRO_VERSION}"
        fi

        IMG_FNAME="${LCDIST}-${QCOW_VER}-openstack-${ARCH}.qcow2"
        URL="http://cdimage.debian.org/cdimage/openstack/${OSTACK_SUBDIR}/${IMG_FNAME}"

    elif [ "Ubuntu" == "${DIST}" ]
    then
        CODENAME="${ubuntu_codename_map[$MINOR_VERSION]}"
        if [ -z "$CODENAME" ]
        then
            echo "--> no codename for ${DIST} v${MICRO_VERSION}"
            return -2
        fi

        IMG_FNAME="${CODENAME}-server-cloudimg-${ARCH}-disk1.img"
        URL="https://cloud-images.ubuntu.com/${CODENAME}/current/${IMG_FNAME}"
    else
        echo "--> unrecognized distribution: ${DIST}"
        return -1
    fi

    export IMG_PATH="${LV_IMG_DIR}/${IMG_FNAME}"
    export IMG_NAME="${DIST} ${VERSION} (${SRC_TIMESTAMP}) - LF upload"

}
#
# usage:
#   download_deb_image ${DIST} ${VERSION} ${ARCH}
#
# example:
#   download_deb_image Ubuntu 14.04 amd64
#
function download_deb_image ()
{
    setup_deb "$@"

    if [ -z "$URL" ]; then echo "Cannot fetch qcow2 image for ${DIST} v${MICRO_VERSION}"; return -3; fi
    echo "--> Fetching image file for ${DIST} ${VERSION}"
    wget -qcP ${LV_IMG_DIR} "${URL}"
}

# Used to upload
#
# usage:
#   create_deb_image ${DIST} ${VERSION} ${ARCH}
#
# example:
#   create_deb_image Ubuntu 14.04 amd64
#
function create_deb_image ()
{
    setup_deb "$@"

    if [ ! -f ${IMG_PATH} ]; then download_deb_image "$@"; fi

    echo "--> Pushing image ${IMG_NAME}"
    glance_image_create "${IMG_NAME}" "${IMG_PATH}"
}

function respin_deb_image ()
{
    SRC_TIMESTAMP=$(latest_src_timestamp)
    DST_TIMESTAMP=$(new_dst_timestamp)
    setup_deb "$@"
    export IMAGE="${IMG_NAME}"
    echo "--> creating instance of image '${IMG_NAME}' as server name '${SERVER_NAME}'"
    export RESEAL=true
    vagrant up --provider=openstack
    if [ "Ubuntu" == "${DIST}" ]
    then
        DST_IMAGE="${DIST} ${VERSION} LTS - basebuild - ${DST_TIMESTAMP}"
    elif [ "Debian" == "${DIST}" ]
    then
        DST_IMAGE="${DIST} ${VERSION} - basebuild - ${DST_TIMESTAMP}"
    else
        echo "unrecognized disribution: ${DIST}"
        exit -4
    fi
    echo "--> Taking snapshot of image '${IMG_NAME}' with name '${DST_IMAGE}'"
    nova image-create --poll "${SERVER_NAME}" "${DST_IMAGE}"
    echo "--> Bringing down vagrant instance"
    vagrant destroy
}

function respin_rh_image ()
{
    SRC_TIMESTAMP=$(latest_src_timestamp)
    DST_TIMESTAMP=$(new_dst_timestamp)
    setup_rh "$@"
    export IMAGE="${IMG_NAME}"
    echo "--> creating instance of image '${IMG_NAME}' as server name '${SERVER_NAME}'"
    export RESEAL=true
    vagrant up --provider=openstack
    DST_IMAGE="${DIST} ${VERSION} - basebuild - ${DST_TIMESTAMP}"
    echo "--> Taking snapshot of image '${IMG_NAME}' with name '${DST_IMAGE}'"
    nova image-create --poll "${SERVER_NAME}" "${DST_IMAGE}"
    echo "--> Bringing down vagrant instance"
    vagrant destroy
}

function dist_type ()
{
  case "${1}" in
      CentOS | RHEL | SuSE)
          echo "rh" ;;
      Debian | Ubuntu | Kali | ProxMox | VyOS)
          echo "deb" ;;
      *)
          echo "Unrecognized distribution: ${1}"
          exit 2 ;;
  esac

}

