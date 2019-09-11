#/usr/bash

__dswift_docker_publish() {
    if [ "$1" == "1" ]; then 
        echo "Publishing image $dockertag"; 
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
    if [ ! -f $templateFile ]; then
        echo "File $templateFile not found!"
        return 1
    fi

    local publishImage=0

    local swiftTags=( $(curl -L -s 'https://registry.hub.docker.com/v2/repositories/library/swift/tags?page_size=1024' | grep -o -E '"name": "[A-Za-z0-9\.\-]+",' | sed 's/"name": "//g' | sed 's/",//g') )
    local swiftVersions=( )
    local tempArray=()
    for i in "${swiftTags[@]}" ; do
        # Only support version 4 and above that are not slim 
        if [[ ( ! ( $i == 3* ) ) && ( ! ( $i == *"slim" ) ) ]] ; then 
            tempArray+=($i)
        fi
    done

    #sort and copy versions into global variable
    read -d '' -r -a swiftVersions < <(printf '%s\n' "${tempArray[@]}" | sort)

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

    unset tempArray
    for i in "${swiftVersions[@]}" ; do
        
        dockertag="$dockerUser/dswift:$i"
        echo "Creating docker file for $dockertag" \
        && mkdir $i \
        && cp -n "$templateFile" "$i/$dockerFile" \
        && cd "$i" \
        && sed -i.bak "s/\$SWIFT_TAG/$i/g" "$dockerFile" && rm "$dockerFile".bak \
        && echo "Building image $dockertag" \
        && docker build -t $dockertag . \
        && __dswift_docker_publish "$publishImage" "$dockertag" \
        && cd .. \
        && rm -r -f $i 
        
       
    done
}

__dswift_docker_file_build $@