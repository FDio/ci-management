#!/bin/bash

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

echo "---> jjb/scripts/vpp/decode-cores-and-clean.sh"
set -xe -o pipefail

OS_ID=$(grep '^ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -f2- -d= | sed -e 's/\"//g')
OS_ARCH=$(uname -m)

echo "sha1sum of this script: ${0}"
sha1sum $0

cat >/tmp/gdb-commands <<'__END__'

# Usage:
# gdb $BINFILE $CORE -ex 'source -v gdb-commands' -ex quit

set pagination off
thread apply all bt

define printstack
  set $i=0
  while $i < 15
      frame $i
      x/i $pc
      info locals
      info reg
      set $i = $i + 1
  end
end
thread apply all printstack

# info proc mappings

__END__



cd /
for CORE in $(find /tmp/vpp* -name core*); do
    BINFILE=$(gdb -c ${CORE} -ex quit | grep 'Core was generated' | awk '{ print $5; }' | sed -e s/\`//g)
    echo ====================================================== DECODE CORE: ${CORE}
    gdb ${BINFILE} ${CORE} -ex 'source -v /tmp/gdb-commands' -ex quit 
    # remove the core to save space
    rm ${CORE}
done

