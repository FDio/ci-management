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

# bash function to set up jenkins sandbox environment
#
# See LF Sandbox documentation:
#   https://docs.releng.linuxfoundation.org/en/latest/jenkins-sandbox.html
#
# Prerequisites:
#   1. Create jenkins sandbox token and add it to your local jenkins.ini file
#      Either specify the location of the init file in $JENKINS_INI or
#      JENKINS_INI will be initialized to either
#         ~/.config/jenkins_jobs/jenkins.ini
#         $WS_ROOT/jenkins.ini
#   2. Clone ci-management workspace from gerrit.fd.io
#   3. export WS_ROOT=<local ci-management workspace>
#   4. cd $WS_ROOT
#   5. git submodule update --init --recursive

jjb-sandbox-env()
{
    local jjb_version=${JJB_VERSION:-"4.1.0"}

    if [ -z "$WS_ROOT" ] ; then
        echo "ERROR: WS_ROOT is not set!"
        return
    elif [ ! -d "$WS_ROOT/jjb" ] ; then
        echo "ERROR: WS_ROOT is not set to a ci-management workspace:"
        echo "       '$WS_ROOT'"
        return
    fi

    if [ -n "$(declare -f deactivate)" ]; then
        echo "Deactivating Python Virtualenv!"
        deactivate
    fi

    if [ -z "$JENKINS_INI" ] ; then
        local user_jenkins_ini="/home/$USER/.config/jenkins_jobs/jenkins.ini"
        if [ -f "$user_jenkins_ini" ] ; then
            export JENKINS_INI=$user_jenkins_ini
        elif [ -f "$WS_ROOT/jenkins.ini" ] ; then
            export JENKINS_INI="$WS_ROOT/jenkins.ini"
        else
            echo "ERROR: Unable to find 'jenkins.ini'!"
            return
        fi
        echo "Exporting JENKINS_INI=$JENKINS_INI"
    elif [ ! -f "$JENKINS_INI" ] ; then
        echo "ERROR: file specified in JENKINS_INI ($JENKINS_INI) not found!"
        return
    fi

    if [ -n "$(declare -f deactivate)" ]; then
        echo "Deactivating Python Virtualenv!"
        deactivate
    fi
    cd $WS_ROOT
    git submodule update --init --recursive

    local VENV_DIR=$WS_ROOT/venv
    rm -rf $VENV_DIR \
       && python3 -m venv $VENV_DIR \
       && source $VENV_DIR/bin/activate \
       && pip3 install wheel \
       && pip3 install jenkins-job-builder==$jjb_version

    alias jjsb='jenkins-jobs --conf $JENKINS_INI'
    function jjsb-test() {
        if [ -z "$(which jenkins-jobs 2>&1)" ] ; then
            echo "jenkins-jobs not found!  Run jjb-sandbox-env to activate."
            return
        fi
        local grep_job_names=""
        if [ "$1" = "-n" ] ; then
            grep_job_names="true"
            shift
        fi
        if [ -z "$1" ] ; then
            echo "Usage: $FUNCNAME <jenkins-job-name>"
            return
        fi
        if [ -z "$grep_job_names" ]; then
            jenkins-jobs --conf $JENKINS_INI test $WS_ROOT/jjb $@
        else
            jenkins-jobs --conf $JENKINS_INI test $WS_ROOT/jjb $@ 2>&1 | grep -e'Number of jobs' -e'Job name' | sed -e 's/INFO:jenkins_jobs.builder://g'
        fi
    }
    function jjsb-update() {
        if [ -z "$(which jenkins-jobs 2>&1)" ] ; then
            echo "jenkins-jobs not found!  Run jjb-sandbox-env to activate."
            return
        fi
        local grep_num_jobs=""
        if [ "$1" = "-n" ] ; then
            grep_num_jobs="true"
            shift
        fi
        if [ -z "$1" ] ; then
            echo "Usage: $FUNCNAME <jenkins-job-name>"
            return
        fi
        if [ -z "grep_num_jobs" ] ; then
            jenkins-jobs --conf $JENKINS_INI update $WS_ROOT/jjb $@
        else
            jenkins-jobs --conf $JENKINS_INI update $WS_ROOT/jjb $@ 2>&1 | grep -e'Number of jobs'
        fi
    }

    jenkins-jobs --version
}

# Get the refspec for the specified project branch at HEAD
#
# Arguments:
#   $1 - branch
#   $2 - project (Optional: defaults to 'vpp')
get_gerrit_refspec() {
    local branch=${1:-"master"}
    local project=${2:-"vpp"}
    local query="$(ssh -p 29418 gerrit.fd.io gerrit query status:merged project:$project branch:$branch limit:1 --format=JSON --current-patch-set | tr ',' '\n' | grep refs | cut -d'"' -f4)"

    if [ -z "$query" ] ; then
        echo "ERROR: Invalid argument(s): branch ($1) project ($2)"
        echo "Usage: $0 <branch> <project>"
    else
        echo "$query"
    fi
}
