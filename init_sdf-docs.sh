#!/bin/bash -x

SLAC_SDF_DOCS_REPO=https://github.com/slaclab/sdf-docs.git
SLAC_SDF_DOCS_RELEASE=master
SLAC_SDF_DOCS_PATH=/var/www/ood/public/doc
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
  echo "$(date '+%Y-%m-%d %H%M.%S %z%Z') Populating SDF docs"
  sleep 10
done
