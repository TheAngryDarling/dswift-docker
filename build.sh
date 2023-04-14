
if ! [ -x "$(command -v docker)" ]; then
    echo "Error: DSwift Docker Build requires docker.  Please proceed to https://www.docker.com for installation instructions"
    exit 1
fi
if ! [ -x "$(command -v docker-hub-list)" ]; then
    echo "Error: DSwift Docker Build requires docker-hub-list.  Please proceed to https://github.com/TheAngryDarling/swift-docker for source"
    exit 1
fi

_dswift_docker_file_build_usage() {
    
    echo "Usage:"
    echo "$0 [OPTIONS] [primary|primary-after-last|missing|missing-after-last|swiftt tags...]" 
    echo "$0 --help" 
    echo "[OPTIONS]"
    echo "-s, --source                  Location folder of source (Required)"
    echo "-i, --imageName               Name of Docker Image (Required)"
    echo "-li, --localImageName         The image name of the local copy to remove before building new image"
    echo "-p, --publish                 Publish Images to Docker"
    echo "-c, --clean                   Clean any images/tags that nore not connected to numeric only tags"
    echo "-bp, --builderPrune           Prunes builder cache"
    echo "-rft, --removeFailedTests     Remove images that fail test app"
    echo "-h, --help                    Display Usage Screen"
    
}

    
scriptFolder="$(dirname $0)"
pushd "$scriptFolder" >/dev/null
scriptFolder="$(pwd -P)"
popd >/dev/null


dockerFilePath="$scriptFolder/Dockerfile"

sourceLocation=""
publish="false"
clean="false"
buildPrune="false"
removeFailedTests="false"
imageName=""
localImageName=""
swiftVersions=()
manualSwiftVersions="true"
primaryOnly="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--h|-help|--help)
            shift
            
            _dswift_docker_file_build_usage
            exit 0
            ;;
        -p|--p|-publish|--publish)
            publish="true"
            shift
            ;;
        -c|--c|-clean|--clean)
            clean="true"
            shift
            ;;
        -bp|--bp|-builderPrune|--builderPrune)
            buildPrune="true"
            shift
            ;;
        -rft|--rft|-removeFailedTests|--removeFailedTests)
            removeFailedTests="true"
            shift
            ;;
        -s|--s|-source|--source)
            shift
            if [[ $# -eq 0 ]]; then
                echo "Missing 'source' path"
                _dswift_docker_file_build_usage
                exit 1
            fi
            sourceLocation="$1"
            shift
            ;;
        -i|--i|-imageName|--imageName)
            shift
            if [[ $# -eq 0 ]]; then
                echo "Missing 'imageName' value"
                exit 1
            fi
            imageName="$1"
            shift
            ;;
        -li|--li|-localImageName|--localImageName)
            shift
            if [[ $# -eq 0 ]]; then
                echo "Missing 'localImageName' value"
                exit 1
            fi
            localImageName="$1"
            shift
            ;;
        *)
            swiftVersions+=("$1")
            shift
            # copy rest of arguments here
            while [[ $# -gt 0 ]]; do
                swiftVersions+=("$1")
                shift
            done
            ;;
    esac
done

# ensure source is set
if [ -z "$sourceLocation" ]; then
    echo "Missing 'source'"
    _dswift_docker_file_build_usage
    exit 1
fi

# ensure source location exists
if [ ! -d "$sourceLocation" ]; then
    echo "'source': '$sourceLocation' does not exist"
    exit 1
fi

# ensure image name is set
if [ -z "$imageName" ]; then
    echo "Missing 'imageName'"
    _dswift_docker_file_build_usage
    exit 1
fi

# if publishing, ensure image name is a publishable name
if [[ "$publish" == "true" ]] && [[ "$imageName" != *"/"* ]]; then
    echo "Image Name '$imageName' is a local name only and can not be published"
    exit 1
fi


if [[ ${#swiftVersions[@]} -eq 0 ]]; then
    # there were no specific tags so we'll get all usable tags
    manualSwiftVersions="false"
    swiftVersions=( $(docker-hub-list --tagExcludeX '^3' --tagExcludeX '\-slim$' --tagExcludeX '\-sim$' -tagExclude slim) )

    # clean builder cache since this is going to be a big process
    docker builder prune --all --force > /dev/null 2>&1
   
elif [[ ${#swiftVersions[@]} -eq 1 ]] && [[ "${swiftVersions[0]}" == "missing" ]]; then
    # we must find missing tags
    manualSwiftVersions="false"
    # clear swiftVersions as it contains 'missing'
    swiftVersions=()
    # setup current tag array
    currentTags=()
    if [[ "$publish" == "true" ]]; then
        # Get current list of tags from docker hub
        currentTags=( $(docker-hub-list $imageName) )
    else
        # Get current list of tags from docker locally
        currentTags=( $(docker images $imageName --format "{{.Tag}}" | sort) )
    fi
    allSwiftTags=( $(docker-hub-list --tagExcludeX '^3' --tagExcludeX '\-slim$' --tagExcludeX '\-sim$' -tagExclude slim) )
    for i in "${allSwiftTags[@]}"; do 
            if [[ ! " ${currentTags[@]} " =~ " $i " ]] ; then
                swiftVersions+=( "$i" )
            fi
    done
elif [[ ${#swiftVersions[@]} -eq 1 ]] && [[ "${swiftVersions[0]}" == "missing-after-last" ]]; then
    # we must find missing tags
    manualSwiftVersions="false"
    # clear swiftVersions as it contains 'missing-after-last'
    swiftVersions=()
    # setup current tag array
    currentTags=()
    if [[ "$publish" == "true" ]]; then
        # Get current list of tags from docker hub
        currentTags=( $(docker-hub-list $imageName) )
    else
        # Get current list of tags from docker locally
        currentTags=( $(docker images $imageName --format "{{.Tag}}" | grep -v "-" | grep -E "[1-9][0-9]*(\.[0-9]+(\.[0-9]+)?)?" | sort) )
    fi
    allSwiftTags=( $(docker-hub-list --tagExcludeX '^3' --tagExcludeX '\-slim$' --tagExcludeX '\-sim$' -tagExclude slim) )
    hasFoundLast="false"
    
    lastSwiftTag="${currentTags[${#currentTags[@]}-1]}"
    #echo "Last Swift Version: $lastSwiftTag"
    for i in "${allSwiftTags[@]}"; do 
        #echo "Testing $i"
        if [[ "$i" == "$lastSwiftTag" ]] || [[ "$i" == $lastSwiftTag* ]] ; then
            hasFoundLast="true"
        elif [[ "$hasFoundLast" == "true" ]] && [[ ! " ${currentTags[@]} " =~ " $i " ]] ; then
           swiftVersions+=( "$i" )
        fi
    done
elif [[ ${#swiftVersions[@]} -eq 1 ]] && [[ "${swiftVersions[0]}" == "primary" ]]; then
    # we must find missing tags
    manualSwiftVersions="false"
    primaryOnly="true"
    currentTags=( $(docker-hub-list --tagFilterX "^[4-9][(0-9)]*(\.[0-9]+){0,2}$") )
    # clear swiftVersions as it contains 'primary'
    swiftVersions=()
    for i in "${currentTags[@]}"; do 
        if [[ "$i" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]]; then
            swiftVersions+=( "$i" )
        fi
    done

    # clean builder cache since this is going to be a big process
    docker builder prune --all --force > /dev/null 2>&1

elif [[ ${#swiftVersions[@]} -eq 1 ]] && [[ "${swiftVersions[0]}" == "primary-after-last" ]]; then
    # we must find missing tags
    manualSwiftVersions="false"
    primaryOnly="true"
    # clear swiftVersions as it contains 'primary-after-last'
    swiftVersions=()
    # setup current tag array
    currentTags=()
    if [[ "$publish" == "true" ]]; then
        # Get current list of tags from docker hub
        curentTags=( $(docker-hub-list $imageName | grep -v "-" | grep -E "[1-9][0-9]*(\.[0-9]+(\.[0-9]+)?)?" | sort) )
    else
        # Get current list of tags from docker locally
        curentTags=( $(docker images $imageName --format "{{.Tag}}" | grep -v "-" | grep -E "[1-9][0-9]*(\.[0-9]+(\.[0-9]+)?)?" | sort) )
    fi
    allSwiftTags=( $(docker-hub-list --tagFilterX "^[4-9][(0-9)]*(\.[0-9]+){0,2}$") )
    hasFoundLast="false"
    lastSwiftTag="${currentTags[${#currentTags[@]}-1]}"
    for i in "${allSwiftTags[@]}"; do 
        if [[ "$i" == "$lastSwiftTag" ]] || [[ "$i" == $lastSwiftTag* ]] ; then
            hasFoundLast="true"
        elif [[ "$hasFoundLast" == "true" ]] && [[ ! " ${curentTags[@]} " =~ " $i " ]] ; then
            if [[ "$i" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]]; then
                swiftVersions+=( "$i" )
            fi
        fi
    done
fi

pushd "$sourceLocation" >/dev/null

#echo "Swift Tags: ${swiftVersions[@]}"

usedTags=()
workingIndex=1
totalTags=${#swiftVersions[@]}
countBeforePrune=0
countToPrune=10
for i in "${swiftVersions[@]}" ; do
    countBeforePrune=$((countBeforePrune+1))
    #echo "'$i'"
    #continue
    similarTags=()
    if [[ ! " ${usedTags[*]} " =~ " ${i} " ]]; then
        usedTags+=( "$i" )
        # Try and download/update swift image for given tag.  
        # This is required because tags latest, xenial, and bionic get updated when 
        # a new verson of swift becomes available
        docker pull --quiet "swift:$i" 1>/dev/null
        
        dockerTagParam="-t $imageName:$i"
        dockertag="$imageName:$i"
        similarTags=( $(docker-hub-list --similarTo $i) )
        #echo "Similar Swift Tags to '$i': ${similarTags[@]}"
        if [ $? -ne 0 ]; then
            echo "Unable to get similar tags to '$i'" 1>&2
            exit 1
        fi
        for tag in ${similarTags[@]}; do
            # if we are only doing primary, we will not
            # tag with os specific tags that are the same
            # as the primary
            if [[ "$primaryOnly" != "true" ]] || ( [[ "$primaryOnly" == "true" ]] && [[ "$tag" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] ); then
                dockertag+=" $imageName:$tag"
                dockerTagParam+=" -t $imageName:$tag"
            fi
            usedTags+=( "$tag" )
        done
        
        #echo "Docker Tags: $dockertag"
        printf "\033[2K\033[G[$workingIndex/$totalTags]: Building image for $dockertag"
        #echo "docker build -q --rm $dockerTagParam --build-arg SWIFT_TAG=$i --file $dockerFilePath . 1>/dev/null"
        startProcessTime=$SECONDS
        docker build -q --rm $dockerTagParam --build-arg SWIFT_TAG=$i --file "$dockerFilePath" . 1>/dev/null 
        buildExitCode=$?
        endProcessTime=$SECONDS
        elapsedProcessTime=$(( startProcessTime - endProcessTime ))
        if [ $buildExitCode -ne 0 ]; then
            printf "\033[2K\033[G[$workingIndex/$totalTags]: Failed to create $dockertag\n"
        else
            printf TZ=UTC0 "\033[2K\033[G[$workingIndex/$totalTags]: Built $dockertag in %(%H:%M:%S)T\n" $elapsedProcessTime
            
            # should do a build test here
            
            didTestBuild="false"
            testBuildPassed="true"
            testAppName="TestSwiftApp"
            
            testAppLoc="$sourceLocation/dswift-latest/Tests/dswiftlibTests/$testAppName"
            if ! [ -d "$testAppLoc" ]; then
                printf "\033[2K\033[G[$workingIndex/$totalTags]: Built image $dockertag"
            else
                testBuildRetry=0
                didTestBuild="true"
                testBuildPassed="false"
                
                #echo "testBuildPassed: $testBuildPassed"
                #echo "testBuildRetry: $testBuildRetry"
                while [[ "$testBuildPassed" == "false" ]] && [ "$testBuildRetry" -lt 2 ]; do
                    testBuildRetry=$((testBuildRetry+1))
                    printf "\033[2K\033[G     [$workingIndex/$totalTags]: Found Testing app for verification";
                    tempTestLoc=$(mktemp -d)
                    mkdir "$tempTestLoc/$testAppName" >/dev/null
                    printf "\033[2K\033[G     [$workingIndex/$totalTags]: Creating test app";
                    #echo "docker run --rm -v \"$tempTestLoc:/root\" -w \"/root/$testAppName\" \"$imageName:$i\" dswift package init --type executable"
                    dockerResponse=$(docker run --rm -v "$tempTestLoc:/root" -w "/root/$testAppName" "$imageName:$i" dswift package init --type executable)
                    if [ $? -ne 0 ]; then
                        printf "\033[2K\033[G     [$workingIndex/$totalTags]: Failed to create test app on $dockertag";
                        printf "\n"
                        echo "$dockerResponse"
                    else
                        sourceRoot="$tempTestLoc/$testAppName/Sources/$testAppName"
                        oldMain=""
                        mainName="$testAppName.swift"
                        newMain="$testAppLoc/testapp_main._swift"

                        if [ -f "$tempTestLoc/$testAppName/Sources/main.swift" ]; then
                             # starting as of Swift 5.8
                            oldMain="$tempTestLoc/$testAppName/Sources/main.swift"
                            sourceRoot="$tempTestLoc/$testAppName/Sources"
                            mainName="$testAppName.swift"
                        elif [ -f "$tempTestLoc/$testAppName/Sources/$testAppName/main.swift" ]; then
                            oldMain="$tempTestLoc/$testAppName/Sources/$testAppName/main.swift"
                            sourceRoot="$tempTestLoc/$testAppName/Sources/$testAppName"
                            mainName="$testAppName.swift"
                        elif  [ -f "$tempTestLoc/$testAppName/Sources/$testAppName/$testAppName.swift" ]; then
                            oldMain="$tempTestLoc/$testAppName/Sources/$testAppName/$testAppName.swift"
                            sourceRoot="$tempTestLoc/$testAppName/Sources/$testAppName"
                            mainName="$testAppName.swift"
                        else
                            printf "\033[2K\033[G     [$workingIndex/$totalTags]: Failed to find main file for swift application";
                            continue
                        fi
                        # remove old main
                        printf "\033[2K\033[G     [$workingIndex/$totalTags]: Removing old main";
                        rm "$oldMain"
                        # copy new main
                        printf "\033[2K\033[G     [$workingIndex/$totalTags]: Copying new main";
                        cp "$newMain" "$sourceRoot/$mainName"


                        # copy core dswift file
                        printf "\033[2K\033[G     [$workingIndex/$totalTags]: Copying dswift file";
                        cp "$testAppLoc/testapp_dswift._dswift" "$sourceRoot/testapp_dswift.dswift"
                        # copy core dswift include file
                        printf "\033[2K\033[G     [$workingIndex/$totalTags]: Copying include file";
                        cp "$testAppLoc/included.file.dswiftInclude" "$sourceRoot/included.file.dswiftInclude"
                        # copy dswift include folder
                        printf "\033[2K\033[G     [$workingIndex/$totalTags]: copying include folder";
                        cp -r "$testAppLoc/includeFolder" "$sourceRoot/"
                        printf "\033[2K\033[G     [$workingIndex/$totalTags]: building test app";
                        dockerResponse=$(docker run --rm -v "$tempTestLoc:/root" -w "/root/$testAppName" "$imageName:$i" dswift build 2>/dev/null)
                        if [ $? -ne 0 ]; then
                            printf "\033[2K\033[G     [$workingIndex/$totalTags]: Failed to build test app on $dockertag\n";
                            printf "\n"
                            echo "$dockerResponse"
                        else
                            appBuildPath=$(docker run --rm -v "$tempTestLoc:/root" -w "/root/$testAppName" "$imageName:$i" dswift build --show-bin-path)
                            printf "\033[2K\033[G     [$workingIndex/$totalTags]: Executing testing app $appBuildPath/$testAppName";
                            dockerResponse=$(docker run --rm -v "$tempTestLoc:/root" -w "/root/$testAppName" "$imageName:$i" "$appBuildPath/$testAppName")
                            if [ $? -ne 0 ]; then
                                printf "\033[2K\033[G     [$workingIndex/$totalTags]: Failed to run test app $testAppName in $appBuildPath on $dockertag\n";
                                printf "\n"
                                echo "$dockerResponse"
                            else
                                if [[ ${dockerResponse} != *"Hello World"* ]];then
                                    printf "\033[2K\033[G     [$workingIndex/$totalTags]: Could not find 'Hello World' output on $dockertag";
                                    printf "\n"
                                    echo "$dockerResponse"
                                else
                                    if [[ ${dockerResponse} != *"Code Execution took"* ]];then
                                        printf "\033[2K\033[G     [$workingIndex/$totalTags]: Could not find 'Code Execution took' output on $dockertag";
                                        printf "\n"
                                        echo "$dockerResponse"
                                    else
                                        if [[ ${dockerResponse} != *"This is content from the included file"* ]];then
                                            printf "\033[2K\033[G     [$workingIndex/$totalTags]: Could not find 'This is content from the included file' output on $dockertag";
                                            printf "\n"
                                            echo "$dockerResponse"
                                        else
                                            if [[ ${dockerResponse} != *"This is content from the included folder file"* ]];then
                                                printf "\033[2K\033[G     [$workingIndex/$totalTags]: Could not find 'This is content from the included folder file' output on $dockertag";
                                                printf "\n"
                                                secho "$dockerResponse"
                                            else
                                                printf "\033[2K\033[G[$workingIndex/$totalTags]: Built and Tested image $dockertag"
                                                testBuildPassed="true"
                                            fi
                                        fi
                                    fi
                                fi
                            fi
                            
                        fi
                    fi
                done
            fi
            
            # Did try build test but it failed.  Lets remove the image?
            if [[ "$removeFailedTests" == "true" && "$didTestBuild" == "true" && "$testBuildPassed" == "false" ]]; then
                for img in "${similarTags[@]}" ; do
                    # remove any similar tags
                    docker rmi "$imageName:$img" > /dev/null 2>&1
                done 
                docker rmi -f "$imageName:$i" > /dev/null 2>&1
            fi
            # we make sure any test build passed before doing any publishing
            if [[ "$testBuildPassed" == "true" ]]; then
                
                # if localImageName is set then we will remove and docker images with local name and same / similar tag to the working one
                if [[ -z "$localImageName" ]]; then
                    for img in "${similarTags[@]}" ; do
                        # remove any similar tags
                        docker rmi "$localImageName:$img" > /dev/null 2>&1
                    done 
                    docker rmi -f "$localImageName:$i" > /dev/null 2>&1
                fi
        
                # check to see if we should publish
                if [[ "$publish" == "true" ]]; then
                    printf "\033[2K\033[G[$workingIndex/$totalTags]: Publishing image $dockertag";
                    docker push "$imageName:$i" 1>/dev/null
                    if [ $? -eq 0 ]; then
                        for img in "${similarTags[@]}" ; do
                            # remove any similar tags
                            docker push "$imageName:$img" 1>/dev/null
                            if [ $? -ne 0 ]; then
                                break
                            fi
                        done 
                    fi
                    
                    if [ $? -eq 0 ]; then
                        if [[ "$didTestBuild" == "true" ]]; then
                            printf "\033[2K\033[G[$workingIndex/$totalTags]: Built, Tested and Published image $dockertag";
                        else
                            printf "\033[2K\033[G[$workingIndex/$totalTags]: Built and Published image $dockertag";
                        fi
                    else
                        printf "\033[2K\033[G[$workingIndex/$totalTags]: Faliled to publishing image $dockertag";
                    fi
                fi
            fi
            
            printf "\n"
            
        fi
        
        if [[ "$clean" == "true" ]]; then
            # if the tag is not 'latest' OR not swift version only, OR not similar to swift version only then we will remove the image
            if ! ( [[ "$i" == "latest" ]] || [[ "$i" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || [[ "$similarTags" =~ \s[0-9]+(\.[0-9]+){0,2}\s ]] ) ; then
                for img in "${similarTags[@]}" ; do
                    # remove any similar tags
                    docker rmi "$imageName:$img" > /dev/null 2>&1
                    docker rmi "swift:$img" > /dev/null 2>&1
                done 
                # remove image with force
                docker rmi -f "$imageName:$i" > /dev/null 2>&1
                docker rmi -f "swift:$i" > /dev/null 2>&1
                printf "\033[2K\033[G[$workingIndex/$totalTags]: Removing $dockertag per clean policy\n"
            fi
        fi
        
    fi
    workingIndex=$((workingIndex+1))
    if [[ "$manualSwiftVersions" == "false" ]]; then
        workingIndex=$((workingIndex+${#similarTags[@]}))
    fi

    if [[ "$buildPrune" == "true" ]] && [[ "$countBeforePrune" ==  "$countToPrune" ]]; then
        docker builder prune --all --force > /dev/null 2>&1
    fi
done

if [[ "$buildPrune" == "true" ]]; then
    docker builder prune --all --force > /dev/null 2>&1
fi

# clean up any untagged dswift images
docker rmi $(docker images --filter="dangling=true" --filter "LABEL=Description=Docker Container for Dynamic Swift programming language" -q) > /dev/null 2>&1

popd >/dev/null
    
    

    
    