variable "EXECUTOR_DOCKER_IMAGE" { }
variable "GHA_DOCKER_IMAGE" { }
variable "PLATFORMS" { }
variable "DOCKER_GHA_RUNNER_DIR" { }

group "default" {
    targets = ["gha"]
}

target "gha" {
    dockerfile = "${DOCKER_GHA_RUNNER_DIR}/Dockerfile"
    tags = ["${GHA_DOCKER_IMAGE}"]
    platforms = ["${PLATFORMS}"]
    args = {
        BASE_IMAGE = "${EXECUTOR_DOCKER_IMAGE}"
        DOCKER_GHA_RUNNER_DIR = "${DOCKER_GHA_RUNNER_DIR}"
    }
}
