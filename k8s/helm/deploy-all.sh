usage()
{
    cat <<END
deploy-all.sh: deploys eShopOnContainers application to Kubernetes cluster
Parameters:
  -r | --registry <container registry> 
    Specifies container registry (ACR) to use (required), e.g. myregistry.azurecr.io
  -t | --tag <docker image tag> 
    Default: newly created, date-based timestamp, with 1-minute resolution
  -p | --push-images
    Push docker images to the registry
  -b || --build-images
    Build docker images
  -n | --name
    AKS cluster name
  -g | --resource_grouo
    AKS cluster resource group name
  -d | --externale-dns
    AKS public IP exernal DNS (from the ingress controller)
  -h | --help
    Displays this help text and exits the script

It is assumed that the Kubernetes AKS cluster has been granted access to ACR registry.
For more info see 
https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-aks

WARNING! THE SCRIPT WILL COMPLETELY DESTROY ALL DEPLOYMENTS AND SERVICES VISIBLE
FROM THE CURRENT CONFIGURATION CONTEXT.
It is recommended that you create a separate namespace and confguration context
for the eShopOnContainers application, to isolate it from other applications on the cluster.
For more information see https://kubernetes.io/docs/tasks/administer-cluster/namespaces/
You can use eshop-namespace.yaml file (in the same directory) to create the namespace.

END
}

appName='eshoponcontainers-aks'
#image_tag=$(date '+%Y%m%d%H%M')
image_tag="latest"
container_registry=''
build_images=''
push_images=''
external_dns=''
aks_name=''
aks_rg=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a | --app-name )
        appName="$2"; shift 2;;
    -d | --external_dns )
        external_dns="$2"; shift 2;;
    -r | --registry )
        container_registry="$2"; shift 2 ;;
    -t | --tag )
        image_tag="$2"; shift 2 ;;
    -b | --build-images )
        build_images='yes'; shift ;;
    -p | --push-images )
        push_images='yes'; shift ;;
    -h | --help )
        usage; exit 0 ;;
    -n | --name )
        aks_name="$2"; shift 2;;
    -g | --resource_group )
        aks_rg="$2"; shift 2;;
    *)
        echo "Unknown option $1"
        usage; exit 2 ;;
  esac
done

# container registry must be specified
if [[ ! $container_registry ]]; then
    echo 'Container registry must be specified (e.g. myregistry.azurecr.io)'
    echo ''
    usage
    exit 3
fi

if [[ $build_images == 'yes' ]]; then
    echo "#################### Building eShopOnContainers Docker images ####################"
    docker-compose -p ../.. -f ../../docker-compose.yml build

    # Remove temporary images
   # docker rmi $(docker images -qf "dangling=true")
fi

if [[ $push_images == 'yes' ]]; then
    echo "#################### Pushing images to registry ####################"
    services=(basket.api catalog.api identity.api ordering.api marketing.api payment.api locations.api webmvc webspa webstatus ordering.signalrhub webshoppingagg mobileshoppingagg ocelotapigw ordering.backgroundtasks)

    for service in "${services[@]}"
    do
        echo "Pushing image for service $service..."
        docker tag "eshop/$service" "$container_registry/eshop/$service:$image_tag"
        docker push "$container_registry/eshop/$service:$image_tag"
    done
fi


if [[ ! $external_dns ]]; then
        external_dns=`az aks show -n $aks_name  -g $aks_rg --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName`
fi

# external DNS must be specified
if [[ ! $external_dns ]]; then
    echo -e '\033[33mExternal DNS must be specified (e.g. mydomain.com)\033[0m'
    echo '\033[31mNo DNS specified. Ingress resources will be bound to public ip\033[0m'
    echo ''
    usage
    exit 3
fi

echo "Begin eShopOnContainers installation using Helm"

#Specifying static strings (infra name and chart names)
infras=("sql-data" "nosql-data" "rabbitmq" "keystore-data" "basket-data")
charts=("apigwmm" "apigwms" "apigwwm" "apigwws" "basket-api" "catalog-api" "identity-api" "locations-api" "marketing-api" "mobileshoppingagg" "ordering-api" "ordering-backgroundtasks" "ordering-signalrhub" "payment-api" "webmvc" "webshoppingagg" "webspa" "webstatus")

for infra in "${infras[@]}"
do 
    echo -e "\033[32m Installing Infra $infra \033[0m"
    #helm install --replace --values app.yaml --values inf.yaml --values ingress_values.yaml --set app.name="$appName" --set inf.k8s.dns="$external_dns" --name="$appName-$infra" $infra
    helm upgrade --install --values app.yaml --values inf.yaml --values ingress_values.yaml --set app.name="$appName" --set inf.k8s.dns="$external_dns" "$appName-$infra" $infra
    if [[ $? != 0 ]]; then
            echo "\033[31m Error installing Infra $infra \033[0m"
            #exit 4
    fi
done

for chart in "${charts[@]}"
do 
    echo -e "\033[32m Installing Chart $chart \033[0m"
    #helm install --replace --values app.yaml --values inf.yaml --values ingress_values.yaml --set inf.registry.server="$container_registry" --set app.name="$appName" --set inf.k8s.dns="$external_dns" --set inf.appinsights.key="803966d3-8fa5-4e91-bbb7-319e71797142" --set image.tag="$image_tag" --set image.pullPolicy="Always" --name="$appName-$chart" $chart 
    helm upgrade --install --values app.yaml --values inf.yaml --values ingress_values.yaml --set inf.registry.server="$container_registry" --set app.name="$appName" --set inf.k8s.dns="$external_dns" --set inf.appinsights.key="803966d3-8fa5-4e91-bbb7-319e71797142" --set image.tag="$image_tag" --set image.pullPolicy="Always" "$appName-$chart" $chart 

    if [[ $? != 0 ]]; then
            echo -e "\033[33m Error installing Chart $chart \033[0m"
            #exit 4
    fi
done

echo "All charts installed, eShopOnContainers is available at $external_dns"


