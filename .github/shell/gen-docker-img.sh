#!/bin/bash

function replace_env() { # replace a env format to env value in a string
    function escape_for_sed() {
        echo "$1" | sed -e 's/[]\/$*.^|[]/\\&/g'
    }
    local str="$1"
    local key=`escape_for_sed "$2"`
    local val=`escape_for_sed "$3"`
    echo "$str" | sed "s/{{ *$key *}}/$val/g"
}

platform=(
    linux/arm64
)
[ ! -z "$BUILD_PLATFORM" ] && platform=($BUILD_PLATFORM) # workflow dispatch
for rootfs_path in $(find ./bin/targets -name "*rootfs.tar.gz"); do # find all rootfs.tar.gz
    rootfs_dir=$(dirname $rootfs_path)
    version=$(jq '.version_number' "$rootfs_dir/profiles.json" | tr -d '"')
    for key in $(jq '.profiles | keys[]' "$rootfs_dir/profiles.json"  | tr -d '"'); do # find all images
        image_name=openwrt
        image_tag=$key-$version
        image_prefix=$(jq ".profiles[\"$key\"].image_prefix" "$rootfs_dir/profiles.json" | tr -d '"')
        for pf in ${platform[@]}; do # build for all platforms
            docker_work_dir='./.github/docker'
            arch=$(echo $pf | cut -d '/' -f 2)
            filename=docker-$image_prefix-$arch.tar
            echo "======================="
            echo "\033[1;36mBuildin\033[0m $filename"
            echo "\033[34mRootfs file:\033[0m $rootfs_path"
            echo "\033[34mTarget image:\033[0m $image_name:$image_tag"
            echo "\033[34mTarget Platform:\033[0m $pf"
            echo "-----------------------"
            cp $rootfs_path "$docker_work_dir/" # copy rootfs
            replace_env $(cat $docker_work_dir/Dockerfile.template) "rootfs_file" "$(basename $rootfs_path)" > "$docker_work_dir/Dockerfile" # generate Dockerfile
            ./.github/shell/build-docker "$docker_work_dir" -y --name "$image_name" --tag "$image_tag" --platform $pf -o "./bin/docker/$filename"
            rm "$docker_work_dir/Dockerfile"
            rm "$docker_work_dir/$(basename $rootfs_path)"
        done
    done
done