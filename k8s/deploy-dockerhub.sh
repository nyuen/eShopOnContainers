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
ubectl set image deployments/basket "basket=nyuen/basket.api:hub"
kubectl set image deployments/catalog "catalog=nyuen/catalog.api:hub"
kubectl set image deployments/identity "identity=nyuen/identity.api:hub"
kubectl set image deployments/ordering "ordering=nyuen/ordering.api:hub"
kubectl set image deployments/ordering-backgroundtasks "ordering-backgroundtasks=nyuen/ordering.backgroundtasks:hub"
kubectl set image deployments/marketing "marketing=nyuen/marketing.api:hub"
kubectl set image deployments/locations "locations=nyuen/locations.api:hub"
kubectl set image deployments/payment "payment=nyuen/payment.api:hub"
kubectl set image deployments/webmvc "webmvc=nyuen/webmvc:hub"
kubectl set image deployments/webstatus "webstatus=nyuen/webstatus:hub"
kubectl set image deployments/webspa "webspa=nyuen/webspa:hub"
kubectl set image deployments/apigwws "apigwws=nyuen/ocelotapigw:hub"
kubectl set image deployments/apigwwm "apigwwm=nyuen/ocelotapigw:hub"
kubectl set image deployments/apigwms "apigwms=nyuen/ocelotapigw:hub"
kubectl set image deployments/apigwmm "apigwmm=nyuen/ocelotapigw:hub"
kubectl set image deployments/ordering-signalrhub "ordering-signalrhub=nyuen/ordering.signalrhub:hub"

kubectl set image deployments/mobileshoppingagg "mobileshoppingagg=nyuen/mobileshoppingagg:hub"
kubectl set image deployments/webshoppingagg "webshoppingagg=nyuen/webshoppingagg:hub"
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
