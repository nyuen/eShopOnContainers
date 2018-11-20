#!/usr/bin/env bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

# This script is comparable to the PowerShell script deploy.ps1 but to be used from a Mac bash environment.
# There are, however, the following few differences/limitations:
 
# It assumes docker/container registry login was already performed
# It assumes K8s was given access to the registry—does not create any K8s secrets
# It does not support explicit kubectl config file (relies on kubectl config use-context to point kubectl at the right cluster/namespace)
# It always deploys infrastructure bits (redis, SQL Server etc)
# The script was tested only with Azure Container Registry (not Docker Hub, although it is expected to work with Docker Hub too)
 
# Feel free to submit a PR in order to improve it.

usage()
{
    cat <<END
deploy.sh: deploys eShopOnContainers application to Kubernetes cluster
Parameters:
  -r | --registry <container registry> 
    Specifies container registry (ACR) to use (required), e.g. myregistry.azurecr.io
  -t | --tag <docker image tag> 
    Default: newly created, date-based timestamp, with 1-minute resolution
  -b | --build-solution
    Force solution build before deployment (default: false)
  --skip-image-build
    Do not build images (default is to build all images)
  --skip-image-push
    Do not upload images to the container registry (just run the Kubernetes deployment portion)
    Default is to push images to container registry
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

#image_tag=$(date '+%Y%m%d')
image_tag='local'
build_solution=''
container_registry=''
build_images='yes'
push_images='yes'

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r | --registry )
        container_registry="$2"; shift 2 ;;
    -t | --tag )
        image_tag="$2"; shift 2 ;;
    -b | --build-solution )
        build_solution='yes'; shift ;;
    --skip-image-build )
        build_images=''; shift ;;
    --skip-image-push )
        push_images=''; shift ;;
    -h | --help )
        usage; exit 1 ;;
    *)
        echo "Unknown option $1"
        usage; exit 2 ;;
  esac
done

if [[ ! $container_registry ]]; then
    echo 'Container registry must be specified (e.g. myregistry.azurecr.io)'
    echo ''
    usage
    exit 3
fi

if [[ $build_solution ]]; then
    echo "#################### Building eShopOnContainers solution ####################"
    dotnet publish -o obj/Docker/publish ../eShopOnContainers-ServicesAndWebApps.sln
fi

export TAG=$image_tag

if [[ $build_images ]]; then
    echo "#################### Building eShopOnContainers Docker images ####################"
    docker-compose -p .. -f ../docker-compose.yml build

    # Remove temporary images
    docker rmi $(docker images -qf "dangling=true")
fi

if [[ $push_images ]]; then
    echo "#################### Pushing images to registry ####################"
    services=(basket.api catalog.api identity.api ordering.api marketing.api payment.api locations.api webmvc webspa webstatus ordering.backgroundtasks ocelotapigw mobileshoppingagg webshoppingagg ordering.signalrhub)

    for service in "${services[@]}"
    do
        echo "Pushing image for service $service..."
        docker tag "eshop/$service:$image_tag" "$container_registry/eshop/$service:$image_tag"
        docker push "$container_registry/eshop/$service:$image_tag"
    done
fi

externalDns=$(kubectl get svc addon-http-application-routing-nginx-ingress --namespace=kube-system -o=jsonpath="{.status.loadBalancer.ingress[0].ip}")

echo "#################### Cleaning up old deployment ####################"
kubectl delete deployments --all
kubectl delete services --all
kubectl delete configmap config-files || true
kubectl delete configmap urls || true
kubectl delete configmap externalcfg || true

echo "#################### Deploying infrastructure components ####################"
kubectl apply -f sql-data.yaml -f basket-data.yaml -f keystore-data.yaml -f rabbitmq.yaml -f nosql-data.yaml -f ingress.yaml -f eshop-namespace.yaml

echo "#################### Deploying Gateway components ####################"
kubectl create configmap ocelot --from-file=mm=ocelot/configuration-mobile-marketing.json --from-file=ms=ocelot/configuration-mobile-shopping.json --from-file=wm=ocelot/configuration-web-marketing.json --from-file=ws=ocelot/configuration-web-shopping.json
kubectl apply -f ocelot/deployment.yaml
kubectl apply -f ocelot/service.yaml

echo "#################### Creating application service definitions ####################"
kubectl apply -f services.yaml 
kubectl apply -f internalurls.yaml
echo "#################### Creating application configuration ####################"

# urls configmap
kubectl create configmap urls \
    "--from-literal=PicBaseUrl=http://$externalDns/webshoppingapigw/api/v1/c/catalog/items/[0]/pic/" \
    "--from-literal=Marketing_PicBaseUrl=http://$externalDns/webmarketingapigw/api/v1/m/campaigns/[0]/pic/" \
    "--from-literal=mvc_e=http://$externalDns/webmvc" \
    "--from-literal=marketingapigw_e=http://$externalDns/webmarketingapigw" \
    "--from-literal=webshoppingapigw_e=http://$externalDns/webshoppingapigw" \
    "--from-literal=mobileshoppingagg_e=http://$externalDns/mobileshoppingagg" \
    "--from-literal=webshoppingagg_e=http://$externalDns/webshoppingagg" \
    "--from-literal=identity_e=http://$externalDns/identity" \
    "--from-literal=spa_e=http://$externalDns" \
    "--from-literal=locations_e=http://$externalDns/locations-api" \
    "--from-literal=marketing_e=http://$externalDns/marketing-api" \
    "--from-literal=basket_e=http://$externalDns/basket-api" \
    "--from-literal=ordering_e=http://$externalDns/ordering-api" \
    "--from-literal=xamarin_callback_e=http://$externalDns/xamarincallback" \

kubectl label configmap urls app=eshop

# externalcfg configmap -- points to local infrastructure components (rabbitmq, SQL Server etc)
kubectl apply -f conf_local.yaml

# Create application pod deployments
kubectl apply -f deployments.yaml

echo "#################### Deploying application pods ####################"

# update deployments with the correct image (with tag and/or registry)

kubectl rollout resume deployments/basket
kubectl rollout resume deployments/catalog
kubectl rollout resume deployments/identity
kubectl rollout resume deployments/ordering
kubectl rollout resume deployments/marketing
kubectl rollout resume deployments/locations
kubectl rollout resume deployments/payment
kubectl rollout resume deployments/webmvc
kubectl rollout resume deployments/webstatus
kubectl rollout resume deployments/webspa
kubectl rollout resume deployments/apigwws
kubectl rollout resume deployments/apigwwm
kubectl rollout resume deployments/apigwms
kubectl rollout resume deployments/apigwmm
kubectl rollout resume deployments/mobileshoppingagg
kubectl rollout resume deployments/webshoppingagg
kubectl rollout resume deployments/apigwmm
kubectl rollout resume deployments/apigwms
kubectl rollout resume deployments/apigwwm
kubectl rollout resume deployments/apigwws
kubectl rollout resume deployments/ordering-signalrhub
kubectl rollout resume deployments/ordering-backgroundtasks

echo "WebSPA is exposed at http://$externalDns, WebMVC at http://$externalDns/webmvc, WebStatus at http://$externalDns/webstatus"
echo "eShopOnContainers deployment is DONE"
