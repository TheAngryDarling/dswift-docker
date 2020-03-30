#!/bin/bash

__dswift_docker_file_build() {

    if [ "$1" == "--help" ]; then
        echo "Usage:"
        echo "'$0' - Build image for all swift tags"
        echo "'$0 {swift tag}...' - Build images for specific swift versions"
        return
    fi

    local dockerUser="theangrydarling"
    local templateFile="Dockerfile.template"
    local dockerFile="Dockerfile"
    local shaFile="dswift.sha"
    if [ ! -f $templateFile ]; then
        echo "File $templateFile not found!"
        return 1
    fi

    local publishImage=0

    local DSWIFT_REPOSITORY="https://github.com/TheAngryDarling/dswift"
    local DSWIFT_BRANCH_LATEST="latest"
    local DSWIFT_REF_TAG="refs/tags/$DSWIFT_BRANCH_LATEST"
    local DSWIFT_SED_REF_TAG="$(echo $DSWIFT_REF_TAG | sed 's/\//\\\//g')"
    local swiftVersions=( $(curl -L -s 'https://registry.hub.docker.com/v2/repositories/library/swift/tags?page_size=1024' | grep -o -E '"name": "[A-Za-z0-9\.\-]+",' | sed 's/"name": "//g' | sed 's/",//g' | grep -E '^\d' | grep -v '-' | grep -v -E '^4$' | grep -v -E '^3.*' | sort | tr '\n' ' ') )
    
    
    if [ $# -ge 1 ]; then
        local args=( "$@" )
        if [ "${@: -1}" == "publish" ]; then
            publishImage=1
           
            if [ $# -eq 1 ]; then
                args=( "${swiftVersions[@]}" )
            else
                 unset "args[${#args[@]}-1]"
            fi
        fi
        swiftVersions=( "${args[@]}" )
    fi
    currentLocation=$(pwd)
    templateFilePath="$currentLocation/$templateFile"
    tmp_docker_root=$(mktemp -d -t dswift-)
    cd "$tmp_docker_root"
    echo "Temp DIR: $tmp_docker_root"

    echo "Grabbing Source Code"
    rsync -a ~/development/swift/Executables/dswift/ ./dswift-latest --exclude .build --exclude .git --exclude *.xcodeproj --exclude Package.resolved
    
    mkdir ./Packages
 
    local localPackages=( $(swift package --package-path ~/development/swift/Executables/dswift/ show-dependencies --format json | grep "url" | sed -e 's/ //g' -e 's/"url"://g' -e 's/",//g' -e 's/"//g' | grep -v http | grep -v dswift) )
    for package in "${localPackages[@]}" ; do
        packageName="$(basename $package)"
        echo "Importing local package $packageName @ $package"
        rsync -a "$package/" "./Packages/$packageName" --exclude .build --exclude *.xcodeproj --exclude Package.resolved
    done
    
    #echo "Downloading Latest Source Code SHA"
    #latestSHA=$(git ls-remote --refs $DSWIFT_REPOSITORY $DSWIFT_REF_TAG | sed -e "s/$DSWIFT_SED_REF_TAG//g" -e 's/[[:space:]]//g')
    #echo $latestSHA > $shaFile
    echo "LOCAL" > $shaFile

    #echo "Downloading Updater Script"
    echo "echo 'Update unavailable for local build'" > dswift-update
    #curl https://raw.githubusercontent.com/TheAngryDarling/dswift/master/dswift-update --output dswift-update 2>/dev/null
    
    for i in "${swiftVersions[@]}" ; do
        # Try and download/update swift image for given tag.  
        # This is required because tags latest, xenial, and bionic get updated when 
        # a new verson of swift becomes available
        docker pull --quiet "swift:$i" 1>/dev/null
        
        dockertag="dswift:$i"
        printf "Creating docker file for $dockertag" \
        && mkdir "$i" \
        && cp -n "$templateFilePath" "$i/$dockerFile" \
        && cp -r "dswift-latest" "$i/dswift-latest" \
        && cp -r "Packages" "$i/Packages" \
        && cp "$shaFile" "$i/$shaFile" \
        && cp "dswift-update" "$i/dswift-update" \
        && cd "$i" \
        && sed -i.bak "s/\$SWIFT_TAG/$i/g" "$dockerFile" && rm "$dockerFile".bak \
        && printf "\033[2K\033[GBuilding image $dockertag" \
        && docker build -q --rm -t $dockertag . 1>/dev/null \
        && cd ".." \
        && rm -r -f "$i" \
        && printf "\033[2K\033[GCreated $dockertag\n"
        
       
    done

    cd "$currentLocation"
    echo "Cleaning up..."
    rm -r -f "$tmp_docker_root"
}

__dswift_docker_file_build $@