#!/bin/bash
set -xe -o pipefail

DOXYGEN_DOC_DIR="build-doxygen/docs/doxygen/html"
DOC_DIR="docs/build/html"
SITE_DIR="build/doc/deploy-site"

echo "---> jjb/scripts/hicn/docs.sh"

bash scripts/build-packages.sh sphinx
bash scripts/build-packages.sh doxygen

if [[ "${JOB_NAME}" == *merge* ]]; then
  mkdir -p "${SITE_DIR}"/doxygen
  mv -f "${DOC_DIR}" "${SITE_DIR}"
  mv -f "${DOXYGEN_DOC_DIR}" "${SITE_DIR}"/doxygen
  find "${SITE_DIR}" -type f '(' -name '*.md5' -o -name '*.dot' -o -name '*.map' ')' -delete
fi
