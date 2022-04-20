#!/bin/bash
set -xe -o pipefail

DOC_DIR="docs/build/html"
SITE_DIR_ROOT="build/doc"
SITE_DIR="${SITE_DIR_ROOT}/deploy-site"

echo "---> jjb/scripts/hicn/docs.sh"

bash scripts/build-packages.sh sphinx

if [[ "${JOB_NAME}" == *merge* ]]; then
  mkdir -p "${SITE_DIR_ROOT}"
  mv -f "${DOC_DIR}" "${SITE_DIR}"
  find "${SITE_DIR}" -type f '(' -name '*.md5' -o -name '*.dot' -o -name '*.map' ')' -delete
fi
