#!/bin/bash

# Get openwrt source

ori_shopt_status_expand_aliases="$(shopt dotglob | awk '{print $2}')"
function recover_shopt() {
    if [ "$ori_shopt_status_expand_aliases" = "on" ]; then shopt -s dotglob > /dev/null 2>&1
    else shopt -u dotglob > /dev/null 2>&1
    fi
}
shopt -s dotglob

shell_path="$(readlink -f "$0")"
source "$(dirname $shell_path)/repo.conf"
[ ! -z "$BUILD_UP_BRANCH" ] && branch=$BUILD_UP_BRANCH # workflow dispatch

my_repo_dir=$(pwd)
repo_hash=$(echo "$repo" | md5sum | sed 's/[^0-9a-zA-Z]//g' | cut -c 1-16)
time_hash=$(echo "$(date +%s%N)" | md5sum | sed 's/[^0-9a-zA-Z]//g' | cut -c 1-8)
remote_repo_dir=/tmp/tmp.repo.$repo_hash.$hash
mkdir -p $remote_repo_dir
git clone $repo -b $branch --depth 1 $remote_repo_dir
rm -rf $remote_repo_dir/.github
rm -rf $remote_repo_dir/.git
cp -rf $my_repo_dir/* $remote_repo_dir
cd .. && rm -rf $my_repo_dir && mv $remote_repo_dir $my_repo_dir && cd $my_repo_dir
rm -rf $remote_repo_dir

recover_shopt