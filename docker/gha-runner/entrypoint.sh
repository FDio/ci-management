#!/bin/bash

set -ex

function deregister_runner {
    echo "Deregistering runner"
    "${DOCKER_GHA_RUNNER_DIR}"/config.sh remove --token "${token}"

}

function register_runner {
    echo "Get Runner Registration Token"
    token=$(
        curl -sS -X POST -H "Authorization: token ${GITHUB_PAT}" "${GITHUB_API_URL}/actions/runners/registration-token" | jq -r .token
    )

    echo "Configuring runner"
    CONFIGURED=false
    "${DOCKER_GHA_RUNNER_DIR}"/config.sh \
        --disableupdate \
        --ephemeral \
        --labels "${RUNNER_LABELS}" \
        --name "${NOMAD_ALLOC_ID}" \
        --replace \
        --token "${token}" \
        --unattended \
        --url "${GITHUB_REPO_URL}"
    CONFIGURED=true
}

export RUNNER_ALLOW_RUNASROOT=1

# Register the Github Runner
register_runner

# Ensure we deregister the Github runner
trap 'deregister_runner' SIGINT SIGQUIT SIGTERM

# Launch the Github Runner
"${DOCKER_GHA_RUNNER_DIR}"/bin/Runner.Listener run

# Deregister the Github runner
deregister_runner

exit 0
