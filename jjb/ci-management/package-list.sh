#!/bin/bash

export PACKAGE_LIST_COMMON="libhicnctrl \
libhicnctrl-memif \
hicn-collectd-plugins \
hicn-apps \
hicn-light \
hicn-apps-memif \
libhicntransport-memif \
libhicn \
libhicntransport \
hicn-plugin \
facemgr \
hicn-utils-memif \
hicn-utils \
hicn-sysrepo-plugin \
hicn-extra-plugin \
libparc \
libparc-doc \
longbow \
longbow-doc"

export PACKAGE_LIST_UBUNTU="libhicnctrl-dev \
libhicn-ctrl-dev \
libhicnctrl-memif-dev \
libhicntransport-memif-dev \
libhicn-dev \
libhicntransport-dev \
hicn-plugin-dev \
libdash \
libdash-dev \
libdash-doc \
libparc-dev \
libmemif-dev \
longbow-dev"

export VERSION_WHITELIST="19.01-227 \
19.08-289 \
20.01-73 \
20.01-114"
