RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#if [ "$(green_enabled)" = true ]; then

productionSlot=$( (
        helm get values --all eshoponcontainers-aks-catalog-api | grep 'productionSlot: ' | awk -F': ' '{print $2}'
    ))
    #the variables has been set in the Azure pipeline during the first stage of the release
    echo -e "${RED}new Release version = ${$(newRelease)}${NC}"
    echo -e "${BLUE}blue Release version = ${$(blueRelease)}${NC}"
    echo -e "${GREEN}green Release version = ${$(greenRelease)}${NC}"
    echo -e "New version is on the $(newVersion) slot"

    #Swap the labels used by the service, effectively switching between the blue and the green deployment
    if [ "$productionSlot" = "blue" ]; then
        productionSlot="green"
        stagingSlot="blue"
    else
        productionSlot="blue"
        stagingSlot="green"
    fi

    green_enabled=true

    helm upgrade --install --values "$SYSTEM_DEFAULTWORKINGDIRECTORY/_specialK-CI-CatalogAPI/helm/shared-yaml/k8s/helm/app.yaml" --values "$SYSTEM_DEFAULTWORKINGDIRECTORY/_specialK-CI-CatalogAPI/helm/shared-yaml/k8s/helm/inf.yaml" --values "$SYSTEM_DEFAULTWORKINGDIRECTORY/_specialK-CI-CatalogAPI/helm/shared-yaml/k8s/helm/ingress_values.yaml" --set inf.k8s.dns="$EXTERNAL_DNS" --set inf.registry.server="$CONTAINER_REGISTRY" --set image.tag="$BUILD_BUILDNUMBER" --set image.pullPolicy="Always" --set inf.appinsights.key="$APP_INSIGHT" --set version.blue=$blueRelease --set version.green=$greenRelease  --set version.productionSlot=$productionSlot --set version.stagingSlot=$stagingSlot --set version.green_enabled=$green_enabled "$APP_NAME-catalog-api" "$SYSTEM_DEFAULTWORKINGDIRECTORY/_specialK-CI-CatalogAPI/helm/catalog-api/k8s/helm/catalog-api"
# else
#     echo "Green Deployment is not enabled"
#     echo "Skipping tasks"
# fi