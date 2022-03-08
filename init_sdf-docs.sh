#!/bin/bash -x

SLAC_SDF_DOCS_REPO=${SLAC_SDF_DOCS_REPO:-https://github.com/slaclab/sdf-docs.git}
SLAC_SDF_DOCS_RELEASE=${SLAC_SDF_DOCS_VERSION:-master}
SLAC_SDF_DOCS_PATH=/var/www/ood/public/doc
SLAC_SDF_DOCS_UPDATE_INTERVAL=${SLAC_SDF_DOCS_UPDATE_INTERVAL:-300}
EMPTYDIR_MOUNT_PATH=/sdf-docs

if [ ! -d "${SLAC_SDF_DOCS_PATH}" ] ; then
    mkdir -p ${SLAC_SDF_DOCS_PATH} && cd ${SLAC_SDF_DOCS_PATH}
    git clone ${SLAC_SDF_DOCS_REPO}    
fi

cd ${SLAC_SDF_DOCS_PATH}/sdf-docs
git checkout ${SLAC_SDF_DOCS_RELEASE}
git fetch origin
git pull origin ${SLAC_SDF_DOCS_RELEASE}
cp -r ${SLAC_SDF_DOCS_PATH}/sdf-docs/. ${EMPTYDIR_MOUNT_PATH}

while :
do
  echo "$(date '+%Y-%m-%d %H%M.%S %z%Z') Updating SDF docs"
  git pull origin ${SLAC_SDF_DOCS_RELEASE}
  sleep ${SLAC_SDF_DOCS_UPDATE_INTERVAL}
done
