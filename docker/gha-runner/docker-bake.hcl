variable "EXECUTOR_DOCKER_IMAGE" { }
variable "GHA_DOCKER_IMAGE" { }
variable "PLATFORMS" { }
variable "DOCKER_GHA_RUNNER_DIR" { }

target "gha" {
    dockerfile = "Dockerfile"
    tags = ["${GHA_DOCKER_IMAGE}"]
    platforms = ["${PLATFORM}"]
    args = {
        BASE_IMAGE = "${EXECUTOR_DOCKER_IMAGE}"
        DOCKER_GHA_RUNNER_DIR = "${DOCKER_GHA_RUNNER_DIR}"
    }
}
