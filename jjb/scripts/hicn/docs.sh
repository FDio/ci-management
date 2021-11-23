#!/bin/bash
set -xe -o pipefail

[ "$DOC_DIR" ] || DOC_DIR="build-doxygen/lib/doc/html"
[ "$SITE_DIR" ] || SITE_DIR="build/doc/deploy-site/"
[ "$RESOURCES_DIR" ] || RESOURCES_DIR=${SITE_DIR}/src/site/resources

echo "---> jjb/scripts/hicn/docs.sh"

bash scripts/build-packages.sh sphinx
bash scripts/build-packages.sh doxygen

if [[ ${JOB_NAME} == *merge* ]]; then
  mkdir -p "$(dirname ${RESOURCES_DIR})"
  mv -f ${DOC_DIR} ${RESOURCES_DIR}
  cd ${SITE_DIR}
  find . -type f '(' -name '*.md5' -o -name '*.dot' -o -name '*.map' ')' -delete
  cd -
fi
