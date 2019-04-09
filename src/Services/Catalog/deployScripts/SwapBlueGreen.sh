RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#the variables has been set in the Azure pipeline during the first stage of the release
echo -e "${RED}new Release version = ${$(newRelease)}${NC}"
echo -e "${BLUE}blue Release version = ${$(blueRelease)}${NC}"
echo -e "${GREEN}green Release version = ${$(greenRelease)}${NC}"
echo -e "New version is on the $(newVersion) slot"

#Swap the labels used by the service, effectively switching between the blue and the green deployment
if [ "$(productionSlot)" = "blue" ]; then
    productionSlot = "green"
    stagingSlot = "blue"
else
    productionSlot = "blue"
    stagingSlot = "green"
fi

$green_enabled = true
blueRelease=$(blueRelease)
greenRelease=$(greenRelease)

echo "Setting Azure Devops Pipeline variables"
echo "##vso[task.setvariable variable=productionSlot]$productionSlot"
echo "##vso[task.setvariable variable=stagingSlot]$stagingSlot"
echo "##vso[task.setvariable variable=green_enabled]$green_enabled"

helm upgrade --install  --reuse-values --set version.productionSlot=$productionSlot --set version.stagingSlot=$stagingSlot --set version.green_enabled=$green_enabled $(app_name)-catalog-api "$(System.DefaultWorkingDirectory)/_specialK-CI-CatalogAPI/helm/catalog-api/k8s/helm/catalog-api"
