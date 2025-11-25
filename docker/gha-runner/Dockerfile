ARG BASE_IMAGE
FROM ${BASE_IMAGE:-ghcr.io/actions/actions-runner:latest}

ARG DOCKER_GHA_RUNNER_DIR
ENV DOCKER_GHA_RUNNER_DIR=${DOCKER_GHA_RUNNER_DIR}

RUN apt-get update \
 && apt-get install -y \
      curl \
      jq

USER root
ENTRYPOINT ["${DOCKER_GHA_RUNNER_DIR}/entrypoint.sh"]
