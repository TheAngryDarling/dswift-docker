
if [[ " $@ " == *"-h"* ]] || [[ " $@ " == *"-help"* ]]; then
    echo "Build local DSWIFT Docker Image(s):"
    echo "$0 [OPTIONS] [primary|primary-after-last|missing|missing-after-last|swiftt tags...]"
    echo "[OPTIONS]"
    echo "-h, --help                    Display Help"
    echo "-c, --clean                   Clean any non primary tags after build"
    echo "-bp, --builderPrune           Prunes builder cache"
    echo "-rft, --removeFailedTests     Remove images that fail test app"
    exit 0
fi

# used for copying swift projects
__syncFolder() {
    rsync -a $1 $2 --exclude .build --exclude DerivedData --exclude .git --exclude *.xcodeproj --exclude Package.resolved
    return $?
}

scriptFolder="$(dirname $0)"
pushd "$scriptFolder" >/dev/null
scriptFolder="$(pwd -P)"
popd >/dev/null

buildScriptPath="$scriptFolder/build.sh"

pushd ~ >/dev/null
homeFolder="$(pwd -P)"
popd >/dev/null


developmentFolder="$homeFolder/development"
swiftDevFolder="$developmentFolder/swift"
swiftDevExeFolder="$swiftDevFolder/Executables"
swiftDevPackageFolder="$swiftDevFolder/Packages"
dswiftFolder="$swiftDevExeFolder/dswift"

tmp_docker_root=$(mktemp -d -t dswift-XXXXX)
pushd "$tmp_docker_root" >/dev/null
echo "Grabbing Source Code"
__syncFolder "$dswiftFolder/" ./dswift-latest

if [[ $? -ne 0 ]]; then
    ehco "Faild to copy source"
    exit 1
fi


#echo "Downloading Updater Script"
echo "echo 'Update unavailable for local build'" > dswift-update


#echo "Downloading Latest Source Code SHA"
#latestSHA=$(git ls-remote --refs $DSWIFT_REPOSITORY $DSWIFT_REF_TAG | sed -e "s/$DSWIFT_SED_REF_TAG//g" -e 's/[[:space:]]//g')
#echo $latestSHA > $shaFile
echo "LOCAL" > dswift.sha
    

mkdir Packages

# find any locally referenced packages
localPackages=( $(swift package --package-path "$dswiftFolder" show-dependencies --format json | grep "url" | sed -e 's/ //g' -e 's/"url"://g' -e 's/",//g' -e 's/"//g' | grep -v http | grep -v dswift) )
# copy locally referenced packages to our temp location
for package in "${localPackages[@]}" ; do
        packageName="$(basename $package)"
        echo "Importing local package $packageName @ $package"
        __syncFolder "$package/" "./Packages/$packageName"
        if [[ $? -ne 0 ]]; then
            ehco "Failed to copy package '$packageName'"
            exit 1
        fi
done

eval "$buildScriptPath --source $tmp_docker_root --imageName dswift -localImageName theangrydarling/dswift $@"
let ret=$?

popd >/dev/null

echo "Cleaning Up"
rm -r "$tmp_docker_root"

exit $ret
