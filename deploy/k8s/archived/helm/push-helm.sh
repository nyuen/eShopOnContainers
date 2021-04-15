push=''
acrname=''


usage()
{
    cat <<END
push-helm.sh: package helm charts and push these chart on ACR
Parameters:
  -r| --registry <container registry> 
    Specifies container registry (ACR) to use (required), e.g. myregistry.azurecr.io
  -p | --push
    Push helm charts to the registry
  -h | --help
    Displays this help text and exits the script

It is assumed that the you are already logged in to ACR

END
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p | --push )
        push=true; shift;;
    -r | --registry )
        acrname=$2; shift 2;;
    -h | --help )
        usage;;
    *)
        echo "Unknown option $1"
        usage; exit 2 ;;
  esac
done

# Login to the Helm repo on ACR
az acr helm repo add

services=($(ls -d */))

for service in "${services[@]}"
do
    echo "packaging helm chart service $service..."
    helm package $service
    if [[ $push == true ]]; then
        package_name=${service%?}
        chart_file="$package_name-$package_version.tgz"
        package_version=($(helm inspect chart $package_name | grep -o 'version: [^,]*' | awk -F': ' '{print $2}'))
        echo "pushing service $package_name version $package_version ==> $chart_file"
        az acr helm push $chart_file
        rm $chart_file
    fi
done
