#!/usr/bin/env bash

# usage: build-container-image.sh <docker_username> <docker_password> <docker_repository>

docker_username=$1
docker_password=$2
docker_repository=$3

set -e

COLOR='\033[0;32m'
NOCOLOR='\033[0m'

# get latest release of a GitHub project
# usage: github-get-latest-release <owner> <project>
github-get-latest-release() {
  local owner=$1 project=$2
  local release_url=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/$owner/$project/releases/latest)
  local release=$(basename $release_url)
  if [[ ${release::1} == "v" ]];
  then
    release=${release:1}
  fi
  latest_release=$release
}

# clone  release of a GitHub project
# usage: git-clone-latest <owner> <project> <release> [output_directory]
github-clone-release() {
  local owner=$1 project=$2 release=$3
  if [[ ${release::1} != "v" ]];
  then
    release="v$release"
  fi
  local output_directory=${4:-$owner-$project-$release}
  if [ -d "$output_directory" ];
  then
    rm -rf $output_directory
  fi
  git clone -b $release -- https://github.com/$owner/$project.git $output_directory
}

# get latest tag of an image from Docker Hub
# usage: dockerhub-get-latest-tag <owner> <project>
dockerhub-get-latest-tag () {
    local owner=$1 project=$2
    local tags
    readarray -t tags < <(curl -L -s https://registry.hub.docker.com/v2/repositories/$owner/$project/tags?page_size=1024 | jq '."results"[]["name"]' | tr -d '"')
    local tag=${tags[0]}
    if [[ $tag == "latest" ]];
    then  
        tag=${tags[1]}
    fi
    latest_tag=$tag
}

latest_tag=""
dockerhub-get-latest-tag $docker_username $docker_repository
printf "\n${COLOR}Latest image tag: $latest_tag${NOCOLOR}\n"

latest_release=""
github-get-latest-release "google" "osv-scanner"
printf "\n${COLOR}Latest release: $latest_release${NOCOLOR}\n"

if [[ $latest_tag == $latest_release ]];
then
    printf "\n${COLOR}Latest image tag and latest release are the same, nothing to do${NOCOLOR}\n"
    exit 0
fi

osv_scanner_dir="osv-scanner-latest"
printf "\n${COLOR}Cloning google/osv-scanner release $latest_release to $osv_scanner_dir${NOCOLOR}\n"
github-clone-release "google" "osv-scanner" $latest_release $osv_scanner_dir

cd $osv_scanner_dir

printf "\n${COLOR}Building docker image with tag $release${NOCOLOR}\n"
docker build -t $docker_username/$docker_repository:$latest_release .
docker tag $docker_username/$docker_repository:$latest_release $docker_username/$docker_repository:latest

printf "\n${COLOR}Login to Docker Hub${NOCOLOR}\n"
docker login -u $docker_username -p $docker_password

printf "\n${COLOR}Pushing docker image${NOCOLOR}\n"
docker push $docker_username/$docker_repository:$latest_release
docker push $docker_username/$docker_repository:latest
