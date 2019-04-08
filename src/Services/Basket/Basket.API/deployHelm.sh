echo "Checking Chart Status"
helmStatus=$( (helm status eshoponcontainers-aks-catalog-api | grep "STATUS: " | awk -F': ' '{print $2}'))

if [ "$helmStatus" = "DEPLOYED" ]; then

    #Get current slot in production
    currentVersion=$( (
        helm get values --all eshoponcontainers-aks-catalog-api | grep 'currentSlot: ' | awk -F': ' '{print $2}'
    ))
    echo "Setting up variables with current cluster status"
    newVersion="green"
    blueRelease=$( (helm get values --all eshoponcontainers-aks-catalog-api | grep 'blue: ' | awk -F': ' '{print $2}'))
    greenRelease=$( (helm get values --all eshoponcontainers-aks-catalog-api | grep 'green: ' | awk -F': ' '{print $2}'))
    newRelease=`cat $(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/catalog-api⁩/⁨k8s⁩/⁨helm⁩/⁨catalog-api⁩`
else
    currentVersion="green"
    blueRelease=$(catalogAPI_version)
    greenRelease=$(catalogAPI_version)
    newRelease=`cat $(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/catalog-api⁩/⁨k8s⁩/⁨helm⁩/⁨catalog-api⁩`
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}new Release version = ${newRelease}${NC}"
echo -e "${BLUE}blue Release version = ${blueRelease}${NC}"
echo -e "${GREEN}green Release version = ${greenRelease}${NC}"

if [ "$currentVersion" = "green" ]; then
    newVersion="blue"
    helm upgrade --install --values "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/⁨shared-yaml⁩/k8s⁩/helm⁩/app.yaml" --values "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/⁨shared-yaml⁩/k8s⁩/helm⁩/inf.yaml" --values "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/⁨shared-yaml⁩/k8s⁩/helm⁩/ingress_values.yaml" --set inf.k8s.dns="$(external_dns)" --set inf.registry.server="$(container_registry)" --set image.tag="$(Build.BuildNumber)" --set image.pullPolicy="Always" --set inf.appinsights.key="$(app_insight)" --set version.blue=$greenRelease --set version.green=$newRelease $(app_name)-catalog-api "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/catalog-api⁩/⁨k8s⁩/⁨helm⁩/⁨catalog-api⁩"
else
    helm upgrade --install --values "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/⁨shared-yaml⁩/k8s⁩/helm⁩/app.yaml" --values "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/⁨shared-yaml⁩/k8s⁩/helm⁩/inf.yaml" --values "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/⁨shared-yaml⁩/k8s⁩/helm⁩/ingress_values.yaml" --set inf.k8s.dns="$(external_dns)" --set inf.registry.server="$(container_registry)" --set image.tag="$(Build.BuildNumber)" --set image.pullPolicy="Always" --set inf.appinsights.key="$(app_insight)" --set version.blue=$blueRelease --set version.green=$greenRelease $(app_name)-catalog-api "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/catalog-api⁩/⁨k8s⁩/⁨helm⁩/⁨catalog-api⁩"
fi
