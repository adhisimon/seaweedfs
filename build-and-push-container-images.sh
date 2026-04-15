#!/bin/bash

########
## THIS IS A SCRIPT TO HELP ME BUILD AND PUSH CONTAINER IMAGES
## TO IMAGE REPOSITORY.
##
## PART OF MY SEAWEEDFS SOFT FORK AT:
## https://github.com/adhisimon/seaweedfs
##
## IT ONLY SUITS WITH MY ENVIRONMENT.
## BUT YOU CAN MODIFY AND USE IT FREELY TO SUIT YOUR NEEDS.
##
## ADHIDARMA HADIWINOTO a.k.a ADHISIMON <me@adhisimon.org>
########

REMOTE_IMAGE=ghcr.io/adhisimon/seaweedfs

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd ${SCRIPT_DIR}

echo '[*] Checking out master branch'
git checkout master

echo '[*] Pull origin'
git pull || ( echo '[!] Failed on pulling origin'; exit 1 )

echo '[*] Fetching upstream changes'
git fetch upstream || \
    ( echo '[!] Failed on fetching upstream changes'; exit 1 )

echo '[*] Merging with upstream/master'
git merge -m "Merge remote-tracking branch 'upstream/master'" upstream/master || \
    ( echo '[!] Failed on fetching upstream changes'; exit 1 )
    
echo '[*] Pushing merges to origin'
git push || ( echo '[!] Failed on pushing merges to origin'; exit 1 )

echo '[*] Getting know what is the newest version'
NEWEST_VERSION=`git tag|grep '^[0-9]'|tail -n1`

SHOULD_BUILD_RELEASE_TAG=Y

if [ ! -d "build" ]; then
    mkdir -fv build
fi

if [ -f "build/.latest_successful_release_container_build" ]: then
    LATEST_SUCCESSFUL_RELEASE_CONTAINER_BUILD=$(< build/.latest_successful_release_container_build)

    if [[ "${NEWEST_VERSION}" == "${LATEST_SUCCESSFUL_RELEASE_CONTAINER_BUILD}"]]; then
        SHOULD_BUILD_RELEASE_TAG=N
    fi
fi

if [[ ${SHOULD_BUILD_RELEASE_TAG} == 'Y' ]]; then
    echo '[*] Change to newest tag: ' ${NEWEST_VERSION}
    git checkout ${NEWEST_VERSION} || ( echo '[!] Failed to change to newest tag'; exit 1 )

    echo '[*] We are on this branch/tag right now:';
    git branch

    cd ${SCRIPT_DIR}/docker || ( echo '[!] Failed to change working directory to docker'; exit 1 )

    echo '[*] Build and push "release"' ${NEWEST_VERSION} 'image tag (also update latest tag to it)'
    (
        make clean && \
        make build && \
        podman push localhost/chrislusf/seaweedfs:local ${REMOTE_IMAGE}:${NEWEST_VERSION} && \
        podman push localhost/chrislusf/seaweedfs:local ${REMOTE_IMAGE}:latest \
    ) || ( echo '[!] Failed to build and push release/latest image tag'; exit 1 )

    echo ${NEWEST_VERSION} > ../build/.latest_successful_release_container_build
fi

echo '[*] Change to master branch to update "dev" image tag'
git checkout master

echo '[*] Build and push "dev" image tag'
(
    make clean && \
    make build && \
    podman push localhost/chrislusf/seaweedfs:local ${REMOTE_IMAGE}:dev \
) || ( echo '[!] Failed to build and push dev image tag'; exit 1 )

echo '[*] Finished'
