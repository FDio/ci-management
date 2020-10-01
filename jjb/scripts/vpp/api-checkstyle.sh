#!/bin/bash
echo "---> api-checkstyle.sh"

VPP_CRC_CHECKER="extras/scripts/crcchecker.py"
VPP_CRC_CHECKER_CMD="$VPP_CRC_CHECKER --check-patchset"

send_notify() {
	    # 'roomId' field from the response of:
	    # curl https://api.ciscospark.com/v1/memberships  -H "Authorization: Bearer ${SECRET_WEBEX_TEAMS_ACCESS_TOKEN}"
	    WEBEX_TEAMS_ROOM_ID='Y2lzY29zcGFyazovL3VzL1JPT00vMzUzZmI3OTAtYTVjNS0xMWVhLWI4ZjYtMDUxN2I4NzFmOWU5'
	    curl https://api.ciscospark.com/v1/messages -X POST  -H "Authorization: Bearer ${SECRET_WEBEX_TEAMS_ACCESS_TOKEN}" -H "Content-Type: application/json" --data '{"roomId":"'${WEBEX_TEAMS_ROOM_ID}'", "markdown": "'"${WEBEX_TEAMS_MESSAGE}"'" }' || true
}

if [ -f $VPP_CRC_CHECKER ]; then
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
