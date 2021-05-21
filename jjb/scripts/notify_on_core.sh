#!/bin/bash

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

echo "---> jjb/scripts/notify_on_core.sh"

# Not setting -x to keep tokens and IDs secret.

send_notify() {
    # 'roomId' field from the response of:
    # curl https://api.ciscospark.com/v1/memberships  -H "Authorization: Bearer ${SECRET_WEBEX_TEAMS_ACCESS_TOKEN}"
    curl "https://api.ciscospark.com/v1/messages" -X "POST" -H "Authorization: Bearer ${SECRET_WEBEX_TEAMS_ACCESS_TOKEN}" -H "Content-Type: application/json" --data '{"roomId":"Y2lzY29zcGFyazovL3VzL1JPT00vNmQ3NzllOTAtYjk0NS0xMWViLTgxYzAtMzdhNmIxZThmMzNi", "markdown": "'"${WEBEX_TEAMS_MESSAGE}"'"}' || true
}

if [ -f "core.log" ]; then
    WEBEX_TEAMS_MESSAGE="Core log detected - see ${BUILD_URL}"
    send_notify
else
    echo "No core log detected."
fi
