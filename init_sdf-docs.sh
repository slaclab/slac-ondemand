#!/bin/bash -x

SLAC_SDF_DOCS_REPO=${SLAC_SDF_DOCS_REPO:-https://github.com/slaclab/sdf-docs.git}
SLAC_SDF_DOCS_RELEASE=${SLAC_SDF_DOCS_VERSION:-master}
TMPDIR=${TMPDIR:-/stage}
SLAC_SDF_DOCS_UPDATE_INTERVAL=${SLAC_SDF_DOCS_UPDATE_INTERVAL:-300}
SLAC_SDF_DOCS_PATH=${SLAC_SDF_DOCS_PATH:-/sdf-docs}

# always ensure there's some documentation, otherwise exit
if [ ! -d "${SLAC_SDF_DOCS_PATH}" ] ; then
    mkdir -p ${TMPDIR} && cd ${TMPDIR}
    git clone ${SLAC_SDF_DOCS_REPO}
    cp -r ${TMPDIR}/sdf-docs/. ${SLAC_SDF_DOCS_PATH}
else
    exit 1
fi

cd ${SLAC_SDF_DOCS_PATH}
git checkout ${SLAC_SDF_DOCS_RELEASE}
git fetch origin

while :
do
  echo "$(date '+%Y-%m-%d %H%M.%S %z%Z') Updating SDF docs"
  git pull origin ${SLAC_SDF_DOCS_RELEASE}
  sleep ${SLAC_SDF_DOCS_UPDATE_INTERVAL}
done
