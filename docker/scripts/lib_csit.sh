# lib_csit.sh - Docker build script CSIT library.
#               For import only.

# Copyright (c) 2021 Cisco and/or its affiliates.
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

# Don't import more than once.
if [ -n "$(alias lib_csit_imported 2> /dev/null)" ] ; then
    return 0
fi
alias lib_csit_imported=true

export CIMAN_DOCKER_SCRIPTS="${CIMAN_DOCKER_SCRIPTS:-$(dirname $BASH_SOURCE)}"
. "$CIMAN_DOCKER_SCRIPTS/lib_common.sh"
. "$CIMAN_DOCKER_SCRIPTS/lib_apt.sh"

CSIT_SUPPORTED_EXECUTOR_CLASSES="builder csit_dut"
csit_supported_executor_class() {
    if ! grep -q "${1:-}" <<< "$CSIT_SUPPORTED_EXECUTOR_CLASSES" ; then
        return 1
    fi
    return 0
}

csit_supported_os() {
    case "$1" in
        ubuntu-20.04) return 0 ;;
                   *) ;;
    esac
    return 1
}

csit_checkout_branch_for_vpp() {
    local vpp_branch="$1"
    local csit_dir="$DOCKER_CSIT_DIR"
    local csit_bash_function_dir="$csit_dir/resources/libraries/bash/function"

    # import checkout_csit_for_vpp() if not defined
    set +e && [ -z "$(declare -f checkout_csit_for_vpp)" ] \
        && source "$csit_bash_function_dir/branch.sh"
    CSIT_DIR="$csit_dir" checkout_csit_for_vpp "$vpp_branch"

    csit_branch="$(git branch | grep -e '^*' | mawk '{print $2}')"
}

csit_install_packages() {
    local branch="$1"
    local branchname="$(echo $branch | sed -e 's,/,_,')"
    local csit_dir="$DOCKER_CSIT_DIR"
    local csit_ansible_dir="$csit_dir/fdio.infra.ansible"
    if [ ! -d "$csit_ansible_dir" ] ; then
        csit_ansible_dir="$csit_dir/resources/tools/testbed-setup/ansible"
    fi
    local bld_log="$DOCKER_BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME"
    bld_log="${bld_log}-$branchname-csit_install_packages-bld.log"

    git clean -qfdx
    python3 -m pip install pyyaml

    local exclude_roles="-e calibration -e kernel -e mellanox -e nomad -e consul"
    [ "$OS_ARCH" = "aarch64" ] && exclude_roles="$exclude_roles -e iperf"

    # Not in double quotes to let bash remove newline characters
    local yaml_files="$(grep -r packages_by $csit_ansible_dir | cut -d: -f1 | sort -u | grep -v $exclude_roles)"
    packages="$(dbld_csit_find_ansible_packages.py --$OS_ID --$OS_ARCH $yaml_files)"
    packages="${packages/bionic /}"
    packages="${packages/focal /}"
    packages="${packages/libmbedcrypto1/libmbedcrypto3}"
    packages="${packages/libmbedtls10/libmbedtls12}"
    packages="$(echo ${packages//python\-/python3\-} | tr ' ' '\n' | sort -u | xargs)"

    if [ -n "$packages" ] ; then
        case "$OS_NAME" in
            ubuntu*)
                apt_install_packages $packages
                ;;
            debian*)
                apt_install_packages $packages
                ;;
            *)
                echo "Unsupported OS ($OS_ID): CSIT packages NOT INSTALLED!"
                ;;
        esac
    fi
}

csit_pip_cache() {
    local branch="$1"
    local VENV_OPTS=""
    # ensure PS1 is defined (used by virtualenv activate script)
    PS1=${PS1:-"#"}
    CSIT_DIR="$DOCKER_CSIT_DIR"

    if [ -f "$CSIT_DIR/VPP_REPO_URL" ] \
           && [ -f "$CSIT_DIR/requirements.txt" ]; then

        local csit_bash_function_dir="$CSIT_DIR/resources/libraries/bash/function"
        local branchname="$(echo $branch | sed -e 's,/,_,')"
        local bld_log="$DOCKER_BUILD_LOG_DIR"
        bld_log="${bld_log}/$FDIOTOOLS_IMAGENAME-$branchname-csit_pip_cache-bld.log"
        local pip_cmd="python3 -m pip --disable-pip-version-check"
        export PYTHONPATH=$CSIT_DIR

        description="Install CSIT python packages from $branch branch"
        echo_log "    Starting  $description..."
        git clean -qfdx
        rm -rf "$PYTHONPATH/env"

        # TODO: Update CSIT release branches to avoid build breakage
        #       Fixes https://github.com/pypa/pip/issues/8260
        $pip_cmd install pip==21.0.1
        #       rls2009_lts-* branches missing cherry-pick of
        #       https://gerrit.fd.io/r/c/csit/+/31338
        sed -i 's/scipy==1.1.0/scipy==1.5.4/' "$PYTHONPATH/requirements.txt"

        # Virtualenv version is pinned in common.sh in newer csit branches.
        # (note: xargs removes leading/trailing spaces)
        local common_sh="$csit_bash_function_dir/common.sh"
        install_virtualenv="$(grep 'virtualenv' $common_sh | grep pip | grep install | cut -d'|' -f1 | xargs)"
        $install_virtualenv
        virtualenv --no-download --python=$(which python3) "$CSIT_DIR/env"
        source "$CSIT_DIR/env/bin/activate"

        if [ "$OS_ARCH" = "aarch64" ] ; then
            local numpy_ver="$(grep numpy $PYTHONPATH/requirements.txt)"
            [ -n "$numpy_ver" ] && $pip_cmd install $numpy_ver 2>&1 | \
                tee -a $bld_log
        fi

        # Install csit python requirements
        $pip_cmd install -r "$CSIT_DIR/requirements.txt" 2>&1 | \
            tee -a "$bld_log"
        # Install tox python requirements
        $pip_cmd install -r "$CSIT_DIR/tox-requirements.txt" 2>&1 | \
            tee -a "$bld_log"
        # Run tox which installs pylint requirments
        pushd $CSIT_DIR >& /dev/null
        tox || true
        popd >& /dev/null

        # Clean up virtualenv directories
        deactivate
        git checkout -q -- .
        git clean -qfdx
        echo_log "    Completed $description!"
    else
        echo_log "ERROR: Missing or invalid CSIT_DIR: '$CSIT_DIR'!"
        return 1
    fi
}

docker_build_setup_csit() {
    if csit_supported_executor_class "$EXECUTOR_CLASS" ; then
        if [ ! -d "$DOCKER_CSIT_DIR" ] ; then
            echo_log "Cloning CSIT into $DOCKER_CSIT_DIR..."
            git clone -q https://gerrit.fd.io/r/csit "$DOCKER_CSIT_DIR"
        fi
        clean_git_repo "$DOCKER_CSIT_DIR"
    fi
}

csit_dut_generate_docker_build_files() {
    local build_files_dir="$DOCKER_BUILD_FILES_DIR"

    mkdir -p "$build_files_dir"
    cat <<EOF >"$build_files_dir/supervisord.conf"
[unix_http_server]
file = /tmp/supervisor.sock
chmod = 0777

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl = unix:///tmp/supervisor.sock

[supervisord]
pidfile = /tmp/supervisord.pid
identifier = supervisor
directory = /tmp
logfile = /tmp/supervisord.log
loglevel = debug
nodaemon = false

[program:vpp]
command = /usr/bin/vpp -c /etc/vpp/startup.conf
autostart = false
autorestart = true
redirect_stderr = true
priority = 1
EOF
}

csit_builder_generate_docker_build_files() {
    local build_files_dir="$DOCKER_BUILD_FILES_DIR"
    local dashes="-----"
    local dbeg="${dashes}BEGIN"
    local dend="${dashes}END"
    local pvt="PRIVATE"
    local kd="KEY$dashes"

    # TODO: Verify why badkey is required & figure out how to avoid it.
    mkdir -p "$build_files_dir"
    cat <<EOF >"$build_files_dir/badkey"
$dbeg RSA $pvt $kd
MIIEowIBAAKCAQEAslDXf4kZOQI8OGQQdIF8o83nBM0B4fzHLYLxxiY2rKiQ5MGM
mQa7p1KKzmd5/NlvFRnXefnjSDQljjPxEY7mh457rX2nXvqHD4GUXZPpBIE73rQ1
TViIAXdDzFXJ6ee4yX8ewmVakzYBnlUPDidkWyRnjm/xCgKUCO+CD5AH3ND0onks
OYAtHqhDh29/QMIKdMnK87FBxfzhInHwpqPur76zBnpw3u36ylKEymDFrO5dwzsh
QvDWjsYRg9ydTXubtwP6+MOpjdR1SNKxcCHKJrPrdAeJW9jg1imYmYpEHZ/P3qsL
Jm0hGWbFjdxZLIYIz0vN/nTalcAeqT2OWKrXuwIDAQABAoIBAQCcj1g2FOR9ZlYD
WPANqucJVy4/y9OcXHlwnyiyRjj47WOSRdGxRfUa2uEeikHT3ACo8TB8WwfQDGDw
8u/075e+az5xvAJo5OQSnD3sz4Hmv6UWSvkFuPZo+xMe5C/M2/QljiQuoBifaeqP
3rTCQ5ncYCFAMU7b8BmTot551Ybhu2jCbDMHU7nFHEFOvYinkwfVcaqkrVDUuH+D
c3NkAEH9Jz2MEYA2Va4uqFpGt5lfGiED2kMenwPa8eS5LS5HJsxkfMHGlaHXHFUb
D+dG/qJtSslVxdzVPgEGvzswo6TgtY1nZTQcB8U63rktFg38B7QGtOkvswAYzxyk
HdMIiU3RAoGBAOdIEQRcAThj9eiIFywtBgLBOSg4SoOnvELLr6lgUg2+ICmx06LQ
yaai1QRdOWw1VwZ6apNCD00kaUhBu+ou93yLSDnR2uYftkylhcnVuhDyIeNyb81V
hV2z0WuNv3aKBFlBxaq391S7WW1XxhpAAagm8fZZur73wV390EVd/hZJAoGBAMVf
negT2bg5PVKWvsiEU6eZ00W97tlEDLclkiZawXNnM2/c+2x1Tks6Yf1E/j2FFTB4
r0fesbwN346hCejtq5Bup5YEdFA3KtwT5UyeQQLFGYlCtRmBtOd10wkRS93D0tpX
iIqkf43Gpx6iFdvBWY5A7N+ZmojCy9zpL5TJ4G3jAoGADOGEoRuGrd9TWMoLkFhJ
l2mvhz/rVn3HDGlPtT06FK3cGLZgtRavxGoZNw8CHbayzBeRS/ZH5+H5Qx72GkrX
WcZgFWhMqrhlbMtjMiSHIl556LL86xCyRs+3ACh6211AdMAnBCUOz1dH2cEjtV6P
ORBCNZg1wGEIEfYK3XIorpECgYBubXfQj8KhUs0fdx3Y3Ehdni/ZdlG7F1qx4YBq
mx5e7d+Wd6Hn5Z3fcxO9+yrvypS3YN5YrJzuZSiuCSWdP9RcY7y5r1ZQRv1g0nTZ
MDWZUiNea4cddTd8xKxFB3tV4SkIZi8LustuzDVWa0Mlh4EOmP6uf6c5WxtqRsEL
UwORFwKBgEjZsfmZGBurjOtSrcsteulOB0D2nOqPVRWXmbSNJT/l73DkEllvVyA/
wdW39nyFrA2Qw1K2F+l8DkzMd/WEjmioSWCsvTkXlvrqPfByKg01zCbYy/mhRW7d
7sQrPOIl8ygsc3JrxmvzibdWmng1MehvpAM1ogWeTUa1lsDTNJ/6
$dend RSA $pvt $kd
EOF
    chmod 600 "$build_files_dir/badkey"
    cat <<EOF >"$build_files_dir/sshconfig"
Host 172.17.0.*
        StrictHostKeyChecking no
        UserKnownHostsFile=/dev/null
EOF
}

csit_shim_generate_docker_build_files() {
    local build_files_dir="$DOCKER_BUILD_FILES_DIR"
    # TODO: Verify why badkey is required & figure out how to avoid it.
    local badkey='AAAAB3NzaC1yc2EAAAADAQABAAABAQCyUNd/iRk5Ajw4ZBB0gXyjzecEzQHh/MctgvHGJjasqJDkwYyZBrunUorOZ3n82W8VGdd5+eNINCWOM/ERjuaHjnutfade+ocPgZRdk+kEgTvetDVNWIgBd0PMVcnp57jJfx7CZVqTNgGeVQ8OJ2RbJGeOb/EKApQI74IPkAfc0PSieSw5gC0eqEOHb39Awgp0ycrzsUHF/OEicfCmo+6vvrMGenDe7frKUoTKYMWs7l3DOyFC8NaOxhGD3J1Ne5u3A/r4w6mN1HVI0rFwIcoms+t0B4lb2ODWKZiZikQdn8/eqwsmbSEZZsWN3FkshgjPS83+dNqVwB6pPY5Yqte7'

    mkdir -p "$build_files_dir"
    # TODO: Verify why badkeypub is required & figure out how to avoid it.
    echo "ssh-rsa $badkey ejk@bhima.local" >"$build_files_dir/badkeypub"

    cat <<EOF >"$build_files_dir/sshconfig"
Host 172.17.0.*
        StrictHostKeyChecking no
        UserKnownHostsFile=/dev/null
EOF
    cat <<EOF >"$build_files_dir/wrapdocker"
#!/bin/bash

# Ensure that all nodes in /dev/mapper correspond to mapped devices currently loaded by the device-mapper kernel driver
dmsetup mknodes

# First, make sure that cgroups are mounted correctly.
CGROUP=/sys/fs/cgroup
: {LOG:=stdio}

[ -d \$CGROUP ] ||
    mkdir \$CGROUP

mountpoint -q \$CGROUP ||
    mount -n -t tmpfs -o uid=0,gid=0,mode=0755 cgroup \$CGROUP || {
        echo "Could not make a tmpfs mount. Did you use --privileged?"
        exit 1
    }

if [ -d /sys/kernel/security ] && ! mountpoint -q /sys/kernel/security
then
    mount -t securityfs none /sys/kernel/security || {
        echo "Could not mount /sys/kernel/security."
        echo "AppArmor detection and --privileged mode might break."
    }
fi

# Mount the cgroup hierarchies exactly as they are in the parent system.
for SUBSYS in \$(cut -d: -f2 /proc/1/cgroup)
do
        [ -d \$CGROUP/\$SUBSYS ] || mkdir \$CGROUP/\$SUBSYS
        mountpoint -q \$CGROUP/\$SUBSYS ||
                mount -n -t cgroup -o \$SUBSYS cgroup \$CGROUP/\$SUBSYS

        # The two following sections address a bug which manifests itself
        # by a cryptic "lxc-start: no ns_cgroup option specified" when
        # trying to start containers withina container.
        # The bug seems to appear when the cgroup hierarchies are not
        # mounted on the exact same directories in the host, and in the
        # container.

        # Named, control-less cgroups are mounted with "-o name=foo"
        # (and appear as such under /proc/<pid>/cgroup) but are usually
        # mounted on a directory named "foo" (without the "name=" prefix).
        # Systemd and OpenRC (and possibly others) both create such a
        # cgroup. To avoid the aforementioned bug, we symlink "foo" to
        # "name=foo". This shouldn't have any adverse effect.
        echo \$SUBSYS | grep -q ^name= && {
                NAME=\$(echo \$SUBSYS | sed s/^name=//)
                ln -s \$SUBSYS \$CGROUP/\$NAME
        }

        # Likewise, on at least one system, it has been reported that
        # systemd would mount the CPU and CPU accounting controllers
        # (respectively "cpu" and "cpuacct") with "-o cpuacct,cpu"
        # but on a directory called "cpu,cpuacct" (note the inversion
        # in the order of the groups). This tries to work around it.
        [ \$SUBSYS = cpuacct,cpu ] && ln -s \$SUBSYS \$CGROUP/cpu,cpuacct
done

# Note: as I write those lines, the LXC userland tools cannot setup
# a "sub-container" properly if the "devices" cgroup is not in its
# own hierarchy. Let's detect this and issue a warning.
grep -q :devices: /proc/1/cgroup ||
    echo "WARNING: the 'devices' cgroup should be in its own hierarchy."
grep -qw devices /proc/1/cgroup ||
    echo "WARNING: it looks like the 'devices' cgroup is not mounted."

# Now, close extraneous file descriptors.
pushd /proc/self/fd >/dev/null
for FD in *
do
    case "\$FD" in
    # Keep stdin/stdout/stderr
    [012])
        ;;
    # Nuke everything else
    *)
        eval exec "\$FD>&-"
        ;;
    esac
done
popd >/dev/null


# If a pidfile is still around (for example after a container restart),
# delete it so that docker can start.
rm -rf /var/run/docker.pid

# If we were given a PORT environment variable, start as a simple daemon;
# otherwise, spawn a shell as well
if [ "\$PORT" ]
then
    exec dockerd -H 0.0.0.0:\$PORT -H unix:///var/run/docker.sock \
        \$DOCKER_DAEMON_ARGS
else
    if [ "\$LOG" == "file" ]
    then
        dockerd \$DOCKER_DAEMON_ARGS &>/var/log/docker.log &
    else
        dockerd \$DOCKER_DAEMON_ARGS &
    fi
    (( timeout = 60 + SECONDS ))
    until docker info >/dev/null 2>&1
    do
        if (( SECONDS >= timeout )); then
            echo 'Timed out trying to connect to internal docker host.' >&2
            break
        fi
        sleep 1
    done
    [[ \$1 ]] && exec "\$@"
    exec bash --login
fi
EOF
}
