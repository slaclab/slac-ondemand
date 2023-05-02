#!/bin/bash -x

GIT_REPO=${GIT_REPO}
GIT_RELEASE=${GIT_RELEASE:-main}
GIT_UPDATE_INTERVAL=${GIT_UPDATE_INTERVAL:-300}

# always ensure there's some documentation
cd /app
git status
STATUS=$?
if [ $STATUS -gt 0 ]; then
    git clone ${GIT_REPO} .
fi

# do some funky stuff with git remove here

git checkout ${GIT_RELEASE} 
git fetch origin

while :
do
  echo "$(date '+%Y-%m-%d %H%M.%S %z%Z') Updating git repo ${GIT_REPO}:${GIT_RELEASE}"
  git pull -q origin ${GIT_RELEASE}
  sleep ${GIT_UPDATE_INTERVAL}
done
