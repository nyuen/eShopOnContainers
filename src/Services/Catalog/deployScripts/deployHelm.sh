printenv | sort

echo "Checking Chart Status"
helmStatus=$( (helm status eshoponcontainers-aks-catalog-api | grep "STATUS: " | awk -F': ' '{print $2}'))

#Get the new release from the build
newRelease=`cat $SYSTEM_DEFAULTWORKINGDIRECTORY/_specialK-CI-CatalogAPI/helm/catalog-api/k8s/helm/catalog-api/catalogVersion.txt`
green_enabled=true
productionSlot="blue"
stagingSlot="green"
greenRelease=""
blueRelease=""

if [ "$helmStatus" = "DEPLOYED" ]; then

    #Get current slot in production since we already have deployed the chart at least once
    productionSlot=$( (
        helm get values --all eshoponcontainers-aks-catalog-api | grep 'productionSlot: ' | awk -F': ' '{print $2}'
    ))
    stagingSlot=$( (
        helm get values --all eshoponcontainers-aks-catalog-api | grep 'stagingSlot: ' | awk -F': ' '{print $2}'
    ))
    if [ "$productionSlot" = "" ]; then
        productionSlot="blue"
    fi
    if [ "$stagingSlot" =  ]; then
        stagingSlot="green"
    fi

    echo "Setting up variables with current cluster status"
    blueRelease=$( (helm get values --all eshoponcontainers-aks-catalog-api | grep 'blue: ' | awk -F': ' '{print $2}'))
    greenRelease=$( (helm get values --all eshoponcontainers-aks-catalog-api | grep 'green: ' | awk -F': ' '{print $2}'))
    #if the current production slot is blue then we need to deploy the new release in the green slot
    if [ "$productionSlot" = "blue" ]; then
        greenRelease=$newRelease
    else
        blueRelease=$newRelease
    fi
else
    #This is the first deployment, so we deploy twice the services and we set the current version to bleu
    #As an improvement, disable blue green for this specific case, we already have the correct Flag in the Helm chart
    blueRelease=$newRelease
    greenRelease=$newRelease
    green_enabled=false
fi

#extra fail safe is the values are not corretly set
if [ -z "$blueRelease"]; then
    echo "Blue Release is not set"
    blueRelease=$newRelease
fi

if [ -z "$greenRelease" ]; then
    echo "Green Release is not set"
    greenRelease=$newRelease
fi

echo "Setting Azure Devops Pipeline variables"
export PRODUCTIONSLOT=$productionSlot
export STAGINGSLOT=$stagingSlot
export BLUERELEASE=$blueRelease
export GREENRELEASE=$greenRelease
export GREEN_ENABLED=$green_enabled
export NEWRELEASE=$newRelease
echo "##vso[task.setvariable variable=PRODUCTIONSLOT]$productionSlot"
echo "##vso[task.setvariable variable=STAGINGSLOT]$stagingSlot"
echo "##vso[task.setvariable variable=BLUERELEASE]$blueRelease"
echo "##vso[task.setvariable variable=GREENRELEASE]$greenRelease"
echo "##vso[task.setvariable variable=NEWRELEASE]$newRelease"
echo "##vso[task.setvariable variable=GREEN_ENABLED]$green_enabled"


RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}new Release version = ${newRelease}${NC}"
echo -e "${BLUE}blue Release version = ${blueRelease}${NC}"
echo -e "${GREEN}green Release version = ${greenRelease}${NC}"
echo -e "Production slot is $productionSlot"
echo -e "Staging slot is $stagingSlot"

helm upgrade --install --values "$SYSTEM_DEFAULTWORKINGDIRECTORY/_specialK-CI-CatalogAPI/helm/shared-yaml/k8s/helm/app.yaml" --values "$SYSTEM_DEFAULTWORKINGDIRECTORY/_specialK-CI-CatalogAPI/helm/shared-yaml/k8s/helm/inf.yaml" --values "$SYSTEM_DEFAULTWORKINGDIRECTORY/_specialK-CI-CatalogAPI/helm/shared-yaml/k8s/helm/ingress_values.yaml" --set inf.k8s.dns="$EXTERNAL_DNS" --set inf.registry.server="$CONTAINER_REGISTRY" --set image.tag="$BUILD_BUILDNUMBER" --set image.pullPolicy="Always" --set inf.appinsights.key="$APP_INSIGHT" --set version.blue=$blueRelease --set version.green=$greenRelease  --set version.productionSlot=$productionSlot --set version.stagingSlot=$stagingSlot --set version.green_enabled=$green_enabled "$APP_NAME-catalog-api" "$SYSTEM_DEFAULTWORKINGDIRECTORY/_specialK-CI-CatalogAPI/helm/catalog-api/k8s/helm/catalog-api"


# if [ "$currentVersion" = "green" ]; then
#     newVersion="blue"
#     helm upgrade --install --values "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/shared-yaml/k8s/helm/app.yaml" --values "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/shared-yaml/k8s/helm/inf.yaml" --values "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/shared-yaml/k8s/helm/ingress_values.yaml" --set inf.k8s.dns="$(external_dns)" --set inf.registry.server="$(container_registry)" --set image.tag="$(Build.BuildNumber)" --set image.pullPolicy="Always" --set inf.appinsights.key="$(app_insight)" --set version.blue=$newRelease --set version.green=$greenRelease $(app_name)-catalog-api "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/catalog-api/k8s/helm/catalog-api"
# else
#     helm upgrade --install --values "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/shared-yaml/k8s/helm/app.yaml" --values "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/shared-yaml/k8s/helm/inf.yaml" --values "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/shared-yaml/k8s/helm/ingress_values.yaml" --set inf.k8s.dns="$(external_dns)" --set inf.registry.server="$(container_registry)" --set image.tag="$(Build.BuildNumber)" --set image.pullPolicy="Always" --set inf.appinsights.key="$(app_insight)" --set version.blue=$blueRelease --set version.green=$newRelease $(app_name)-catalog-api "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/catalog-api/k8s/helm/catalog-api"
# fi
