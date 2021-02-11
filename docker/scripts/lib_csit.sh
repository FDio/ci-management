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
. $CIMAN_DOCKER_SCRIPTS/lib_common.sh
. $CIMAN_DOCKER_SCRIPTS/lib_apt.sh
. $CIMAN_DOCKER_SCRIPTS/lib_yum.sh
. $CIMAN_DOCKER_SCRIPTS/lib_dnf.sh

CSIT_SUPPORTED_EXECUTOR_CLASSES="builder csit_dut"
csit_supported_executor_class() {
    if ! grep -q "${1:-}" <<< $CSIT_SUPPORTED_EXECUTOR_CLASSES ; then
        return 1
    fi
    return 0
}

csit_supported_os() {
    case "$1" in
        # TODO: Remove ubuntu-18.04 once CSIT has completed transition
        #       to ubuntu-20.04
        ubuntu-18.04) return 0 ;;
        ubuntu-20.04) return 0 ;;
                   *) ;;
    esac
    return 1
}

csit_checkout_branch_for_vpp() {
    local vpp_branch=$1
    local csit_dir="$DOCKER_CSIT_DIR"
    local csit_bash_function_dir="$csit_dir/resources/libraries/bash/function"

    # import checkout_csit_for_vpp() if not defined
    set +e && [ -z "$(declare -f checkout_csit_for_vpp)" ] \
        && source $csit_bash_function_dir/branch.sh
    CSIT_DIR=$csit_dir checkout_csit_for_vpp $vpp_branch

    csit_branch="$(git branch | grep -e '^*' | mawk '{print $2}')"
}

csit_install_packages() {
    local branch="$1"
    local branchname="$(echo $branch | sed -e 's,/,_,')"
    local csit_dir="$DOCKER_CSIT_DIR"
    local csit_ansible_dir="$csit_dir/resources/tools/testbed-setup/ansible"
    local bld_log="$DOCKER_BUILD_LOG_DIR/$FDIOTOOLS_IMAGENAME"
    bld_log="${bld_log}-$branchname-csit_install_packages-bld.log"

    git clean -qfdx

    # Install PyYAML required by dbld_csit_find_ansible_packages.py
    #
    # Note: Conditional install due to Bug 1696324 -
    #       Update to python3.6 breaks PyYAML dependencies
    # Status:       CLOSED CANTFIX
    # https://bugzilla.redhat.com/show_bug.cgi?id=1696324
    if [ "$OS_NAME" = "centos-8" ] ; then
        dnf_install_packages python3-pyyaml
    else
        python3 -m pip install pyyaml
    fi

    local exclude_roles="-e calibration -e kernel -e mellanox -e nomad -e consul"
    [ "$OS_ARCH" = "aarch64" ] && exclude_roles="$exclude_roles -e iperf"

    # Not in double quotes to let bash remove newline characters
    local yaml_files=$(grep -r packages_by $csit_ansible_dir | cut -d: -f1 | sort -u | grep -v $exclude_roles)
    packages=$(dbld_csit_find_ansible_packages.py --$OS_ID --$OS_ARCH $yaml_files)

    # TODO: Fix Ubuntu-18.04 specific package names that fail on Ubuntu-20.04
    #       (remove when CSIT is updated)
    if [ "$OS_NAME" = "ubuntu-20.04" ] ; then
        packages="${packages/libmbedcrypto1/libmbedcrypto3}"
        packages="${packages/libmbedtls10/libmbedtls12}"
        packages="$(echo ${packages//python\-/python3\-} | tr ' ' '\n' | sort -u | xargs)"
    fi
    if [ -n "$packages" ] ; then
        case "$OS_NAME" in
            ubuntu*)
                apt_install_packages $packages
                ;;
            debian*)
                apt_install_packages $packages
                ;;
            centos-7)
                yum_install_packages $packages
                ;;
            centos-8)
                dnf_install_packages $packages
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
    local csit_dir="$DOCKER_CSIT_DIR"
    local csit_bash_function_dir="$csit_dir/resources/libraries/bash/function"

    if [ -f "$csit_dir/VPP_REPO_URL" ] \
           && [ -f "$csit_dir/requirements.txt" ]; then

        local branchname="$(echo $branch | sed -e 's,/,_,')"
        local bld_log="$DOCKER_BUILD_LOG_DIR"
        bld_log="${bld_log}/$FDIOTOOLS_IMAGENAME-$branchname-csit_pip_cache-bld.log"

        export PYTHONPATH=$csit_dir
        git clean -qfdx

        description="Install CSIT python packages from $branch branch"
        echo_log "    Starting  $description..."
        [ -n "$(declare -f deactivate)" ] && deactivate
        local PIP=pip
        local setup_framework=$csit_dir/resources/libraries/python/SetupFramework.py
        if [ -n "$(grep pip3 $setup_framework)" ]; then
            PIP=pip3
            VENV_OPTS="-p python3"
        fi
        rm -rf $PYTHONPATH/env
        virtualenv $VENV_OPTS $PYTHONPATH/env
        . $PYTHONPATH/env/bin/activate
        if [ "$OS_ARCH" = "aarch64" ] ; then
            local numpy_ver="$(grep numpy $PYTHONPATH/requirements.txt)"
            [ -n "$numpy_ver" ] && $PIP install --upgrade $numpy_ver 2>&1 \
                | tee -a $bld_log
        fi
        $PIP install --upgrade -r $PYTHONPATH/requirements.txt 2>&1 \
            | tee -a $bld_log
        $PIP install --upgrade -r $PYTHONPATH/tox-requirements.txt 2>&1 \
            | tee -a $bld_log
        if [ "$OS_ARCH" = "x86_64" ] ; then
            local PRESENTATION_DIR="$PYTHONPATH/resources/tools/presentation"
            # TODO: Remove condition when 19.08 is deprecated.
            if [ -n "$(grep -r python3 $PRESENTATION_DIR)" ] && [ "$PIP" = "pip3" ] ; then
                $PIP install --upgrade -r $PRESENTATION_DIR/requirements.txt 2>&1 \
                    | tee -a $bld_log
            else
                echo_log "Skipping 'pip install $PRESENTATION_DIR/requirements.txt' in branch $branch!"
            fi
        fi

        deactivate
        rm -rf $PYTHONPATH/env

        # Virtualenv version is pinned in common.sh in newer csit branches.
        # (note: xargs removes leading/trailing spaces)
        install_virtualenv="$(grep 'virtualenv' $csit_bash_function_dir/common.sh | grep pip | grep install | cut -d'|' -f1 | xargs)"
        $install_virtualenv

        git checkout -q -- .
        echo_log "    Completed $description!"
    else
        echo_log "ERROR: Missing or invalid CSIT_DIR: '$csit_dir'!"
        return 1
    fi
}

docker_build_setup_csit() {
    if csit_supported_executor_class "$EXECUTOR_CLASS" ; then
        if [ ! -d "$DOCKER_CSIT_DIR" ] ; then
            echo_log "Cloning CSIT into $DOCKER_CSIT_DIR..."
            git clone -q https://gerrit.fd.io/r/csit $DOCKER_CSIT_DIR
        fi
        clean_git_repo $DOCKER_CSIT_DIR
    fi
}

csit_dut_generate_docker_build_files() {
    local build_files_dir="$DOCKER_BUILD_FILES_DIR"

    cat <<EOF >$build_files_dir/suporvisord.conf
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

csit_shim_generate_docker_build_files() {
    local build_files_dir="$DOCKER_BUILD_FILES_DIR"
    local badkey='AAAAB3NzaC1yc2EAAAADAQABAAABAQCyUNd/iRk5Ajw4ZBB0gXyjzecEzQHh/MctgvHGJjasqJDkwYyZBrunUorOZ3n82W8VGdd5+eNINCWOM/ERjuaHjnutfade+ocPgZRdk+kEgTvetDVNWIgBd0PMVcnp57jJfx7CZVqTNgGeVQ8OJ2RbJGeOb/EKApQI74IPkAfc0PSieSw5gC0eqEOHb39Awgp0ycrzsUHF/OEicfCmo+6vvrMGenDe7frKUoTKYMWs7l3DOyFC8NaOxhGD3J1Ne5u3A/r4w6mN1HVI0rFwIcoms+t0B4lb2ODWKZiZikQdn8/eqwsmbSEZZsWN3FkshgjPS83+dNqVwB6pPY5Yqte7'

    mkdir -p $build_files_dir
    echo "ssh-rsa $badkey ejk@bhima.local" >$build_files_dir/badkeypub

    cat <<EOF >$build_files_dir/sshconfig
Host 172.17.0.*
	StrictHostKeyChecking no
	UserKnownHostsFile=/dev/null
EOF
    cat <<EOF >$build_files_dir/wrapdocker
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
