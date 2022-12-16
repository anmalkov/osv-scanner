#!/usr/bin/env bash

set -e
COLOR='\033[0;32m'
NOCOLOR='\033[0m'

# clone latest release of a github project
# usage: git-clone-latest <owner> <project> [output_directory]
gh-clone-latest() {
  local owner=$1 project=$2
  local release_url=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/$owner/$project/releases/latest)
  local release_tag=$(basename $release_url)
  release=$release_tag
  local output_directory=${3:-$owner-$project-release-$release_tag}
  if [ -d "$output_directory" ];
  then
    printf "${COLOR}Directory already exists, removing $output_directory${NOCOLOR}\n"
    rm -rf $output_directory
  fi
  printf "\n${COLOR}Cloning $owner/$project release $release_tag to $output_directory${NOCOLOR}\n"
  git clone -b $release_tag -- https://github.com/$owner/$project.git $output_directory
}

release=""
osv_scanner_dir="osv-scanner-release-latest"
gh-clone-latest "google" "osv-scanner" $osv_scanner_dir

if [[ ${release::1} == "v" ]];
then
  release=${release:1}
fi

cd $osv_scanner_dir

printf "\n${COLOR}Building docker image with tag $relese${NOCOLOR}\n"
docker build -t anmalkov/osv-scanner:$release .
docker tag anmalkov/osv-scanner:$release anmalkov/osv-scanner:latest

printf "\n${COLOR}Pushing docker image${NOCOLOR}\n"
docker push anmalkov/osv-scanner:$release
docker push anmalkov/osv-scanner:latest
