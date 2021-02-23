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

echo "---> jjb/scripts/vpp/api-checkstyle.sh"

VPP_CRC_CHECKER="extras/scripts/crcchecker.py"
VPP_CRC_CHECKER_CMD="$VPP_CRC_CHECKER --check-patchset"

send_notify() {
	    # 'roomId' field from the response of:
	    # curl https://api.ciscospark.com/v1/memberships  -H "Authorization: Bearer ${SECRET_WEBEX_TEAMS_ACCESS_TOKEN}"
	    WEBEX_TEAMS_ROOM_ID='Y2lzY29zcGFyazovL3VzL1JPT00vMzUzZmI3OTAtYTVjNS0xMWVhLWI4ZjYtMDUxN2I4NzFmOWU5'
	    curl https://api.ciscospark.com/v1/messages -X POST  -H "Authorization: Bearer ${SECRET_WEBEX_TEAMS_ACCESS_TOKEN}" -H "Content-Type: application/json" --data '{"roomId":"'${WEBEX_TEAMS_ROOM_ID}'", "markdown": "'"${WEBEX_TEAMS_MESSAGE}"'" }' || true
}

if [ -f $VPP_CRC_CHECKER ]; then
    # API checker complains if the git repo is not clean.
    # Help diagnosing those issues easier
    git --no-pager diff
    echo "Running $VPP_CRC_CHECKER_CMD"
    if $VPP_CRC_CHECKER_CMD; then
	    echo "API check successful"

	    # for now - notify the same room during the monitoring period about the successes as well
	    WEBEX_TEAMS_MESSAGE="API check successful for $GERRIT_REFSPEC - see $BUILD_URL"
	    send_notify
    else
	    RET_CODE=$?
	    echo "API check failed: ret code $RET_CODE; please read https://wiki.fd.io/view/VPP/ApiChangeProcess and discuss with ayourtch@gmail.com if unsure how to proceed"
	    WEBEX_TEAMS_MESSAGE="API check FAILED for $GERRIT_REFSPEC -  see $BUILD_URL"
	    send_notify
	    exit $RET_CODE
    fi
else
    echo "Cannot find $VPP_CRC_CHECKER - skipping API compatibility check"
fi
