#!/bin/bash

# Copyright (c) 2022 Cisco and/or its affiliates.
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

echo "---> jjb/scripts/vpp/dpdk-rdma-version-mismatch.sh"

set -euxo pipefail

line="*************************************************************************"
EXTERNAL_BUILD_DIR="$WORKSPACE/build/external"
RETVAL="0"
MISMATCH_RESULT="INCLUDED IN"

make -C "$EXTERNAL_BUILD_DIR" build-deb
source "$EXTERNAL_BUILD_DIR/dpdk_mlx_default.sh" || true

if [ "${DPDK_MLX_DEFAULT-}" = "n" ] ; then
    MISMATCH_RESULT="MISSING FROM"
    RETVAL="1"
fi
echo -e "\n$line\n* MLX DPDK DRIVER $MISMATCH_RESULT VPP-EXT-DEPS PACKAGE\n$line\n"
exit $RETVAL
