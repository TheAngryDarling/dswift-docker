#/bin/bash

__dswift_docker_publish() {
    if [ "$1" == "1" ]; then 
        printf "\033[2K\033[GPublishing image $2"; 
        docker push $2
    fi
}
__dswift_docker_file_build() {

    if [ "$1" == "--help" ]; then
        echo "Usage:"
        echo "'$0' - Build image for all swift tags"
        echo "'$0 publish' - Build image for all swift tags and publish mages to docker hub"
        echo "'$0 {swift tag}...' - Build images for specific swift versions"
        echo "'$0 {swift tag}... publish' - Build images for specific swift versions and publish to docker hub"
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
    local swiftVersions=( $(curl -L -s 'https://registry.hub.docker.com/v2/repositories/library/swift/tags?page_size=1024' | grep -o -E '"name":\s?"[A-Za-z0-9\.\-]+",' | sed -E 's/"name":\s?"//g' | sed 's/",//g' | grep -v 'slim' | grep -v 'sim' | grep -v -E '^3.*' | sort) )

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
    # Added directory for packages for support for local build
    mkdir Packages

    echo "Downloading Latest Source Code"
    curl -L https://github.com/TheAngryDarling/dswift/archive/latest.tar.gz --output dswift.tar.gz 2>/dev/null
    tar xzf dswift.tar.gz
    #cp -r ~/development/swift/Executables/dswift ./dswift-latest

    echo "Downloading Latest Source Code SHA"
    latestSHA=$(git ls-remote --refs $DSWIFT_REPOSITORY $DSWIFT_REF_TAG | sed -e "s/$DSWIFT_SED_REF_TAG//g" -e 's/[[:space:]]//g')
    echo $latestSHA > $shaFile

    echo "Downloading Updater Script"
    curl https://raw.githubusercontent.com/TheAngryDarling/dswift/master/dswift-update --output dswift-update 2>/dev/null
    

    for i in "${swiftVersions[@]}" ; do
        
        dockertag="$dockerUser/dswift:$i"
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
        && __dswift_docker_publish "$publishImage" "$dockertag" \
        && cd ".." \
        && rm -r -f "$i" \
        && printf "\033[2K\033[GCreated $dockertag\n"
        
       
    done

    cd "$currentLocation"
    echo "Cleaning up..."
    rm -r -f "$tmp_docker_root"
}

__dswift_docker_file_build $@