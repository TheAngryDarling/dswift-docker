
if [[ " $@ " == *"-h"* ]] || [[ " $@ " == *"-help"* ]]; then
    echo "Build public DSWIFT Docker Image(s):"
    echo "$0 [OPTIONS] [primary|missing|swiftt tags...]"
    echo "[OPTIONS]"
    echo "-h, --help                    Display Help"
    echo "-p, --publish                 Publish built tags to Docker"
    echo "-c, --clean                   Clean any non primary tags after build"
    echo "-bp, --builderPrune           Prunes builder cache"
    echo "-rft, --removeFailedTests     Remove images that fail test app"
    exit 0
fi




scriptFolder="$(dirname $0)"
pushd "$scriptFolder" >/dev/null
scriptFolder="$(pwd -P)"
popd >/dev/null

buildScriptPath="$scriptFolder/build.sh"

DSWIFT_REPOSITORY="TheAngryDarling/dswift"
DSWIFT_REPO_GIT_URL="https://github.com/$DSWIFT_REPOSITORY"
DSWIFT_BRANCH_LATEST="latest"
DSWIFT_REF_TAG="refs/tags/$DSWIFT_BRANCH_LATEST"
DSWIFT_SED_REF_TAG="$(echo $DSWIFT_REF_TAG | sed 's/\//\\\//g')"
DWIFT_BRANCH_DOWNLOAD="$DSWIFT_REPO_GIT_URL/archive/$DSWIFT_BRANCH_LATEST.tar.gz"
RAW_UPDATE_SCRIPT_DOWNLOAD="https://raw.githubusercontent.com/$DSWIFT_REPOSITORY/master/dswift-update"
    

tmp_docker_root=$(mktemp -d -t dswift-XXXXX)
pushd "$tmp_docker_root" >/dev/null
echo "Grabbing Source Code"
curl -L $DWIFT_BRANCH_DOWNLOAD --output dswift.tar.gz 2>/dev/null
if [[ $? -ne 0 ]]; then
    ehco "Failed to download source '$DWIFT_BRANCH_DOWNLOAD'"
    exit 1
fi

tar xzf dswift.tar.gz

if [[ $? -ne 0 ]]; then
    ehco "Failed to extract source"
    exit 1
fi


#echo "Downloading Updater Script"
echo "Downloading Updater Script"
curl $RAW_UPDATE_SCRIPT_DOWNLOAD --output dswift-update 2>/dev/null
if [[ $? -ne 0 ]]; then
    ehco "Failed to download update script '$RAW_UPDATE_SCRIPT_DOWNLOAD'"
    exit 1
fi


echo "Downloading Latest Source Code SHA"
latestSHA=$(git ls-remote --refs $DSWIFT_REPO_GIT_URL $DSWIFT_REF_TAG | sed -e "s/$DSWIFT_SED_REF_TAG//g" -e 's/[[:space:]]//g')
if [[ $? -ne 0 ]]; then
    ehco "Failed to get SHA of '$DSWIFT_REPO_GIT_URL'"
    exit 1
fi
echo $latestSHA > dswift.sha
    

mkdir Packages


eval "$buildScriptPath --source $tmp_docker_root --imageName theangrydarling/dswift --localImageName dswift $@"
let ret=$?

popd >/dev/null

echo "Cleaning Up"
rm -r "$tmp_docker_root"

exit $ret
