# Hands-on Special K - Deploy eShop on Containers

## Creating Backing Services 
```
kubectl apply -f sql-data.yaml -f basket-data.yaml -f keystore-data.yaml -f rabbitmq.yaml -f nosql-data.yaml -f ingress.yaml -f eshop-namespace.yaml
```

## Creating gateways

```
kubectl create configmap ocelot --from-file=mm=ocelot/configuration-mobile-marketing.json --from-file=ms=ocelot/configuration-mobile-shopping.json --from-file=wm=ocelot/configuration-web-marketing.json --from-file=ws=ocelot/configuration-web-shopping.json
kubectl apply -f ocelot/deployment.yaml
kubectl apply -f ocelot/service.yaml
```

## Creating services (load balancing) using BASH
```
kubectl apply -f services.yaml
kubectl apply -f internalurls.yaml
externalDns=$(kubectl get svc addon-http-application-routing-nginx-ingress --namespace=kube-system -o=jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo $externalDns
```


## Creating services (load balancing) using Powershell
```
kubectl apply -f services.yaml
kubectl apply -f internalurls.yaml
$externalDns=(kubectl get svc addon-http-application-routing-nginx-ingress --namespace=kube-system -o=jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo $externalDns
```


## Creating Configuration (Bash only)
```
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
    "--from-literal=xamarin_callback_e=http://$externalDns/xamarincallback"

kubectl label configmap urls app=eshop

kubectl apply -f conf_local.yaml
```

## Creating Configuration (Powershell only)
```
kubectl create configmap urls \
    "--from-literal=PicBaseUrl=http://$($externalDns)/webshoppingapigw/api/v1/c/catalog/items/[0]/pic/" `
    "--from-literal=Marketing_PicBaseUrl=http://$($externalDns)/webmarketingapigw/api/v1/m/campaigns/[0]/pic/" `
    "--from-literal=mvc_e=http://$($externalDns)/webmvc" `
    "--from-literal=marketingapigw_e=http://$($externalDns)/webmarketingapigw" `
    "--from-literal=webshoppingapigw_e=http://$($externalDns)/webshoppingapigw" `
    "--from-literal=mobileshoppingagg_e=http://$($externalDns)/mobileshoppingagg" `
    "--from-literal=webshoppingagg_e=http://$($externalDns)/webshoppingagg" `
    "--from-literal=identity_e=http://$($externalDns)/identity" `
    "--from-literal=spa_e=http://$($externalDns)" `
    "--from-literal=locations_e=http://$($externalDns)/locations-api" `
    "--from-literal=marketing_e=http://$($externalDns)/marketing-api" `
    "--from-literal=basket_e=http://$($externalDns)/basket-api" `
    "--from-literal=ordering_e=http://$($externalDns)/ordering-api" `
    "--from-literal=xamarin_callback_e=http://$($externalDns)/xamarincallback"

kubectl label configmap urls app=eshop

kubectl apply -f conf_local.yaml
```

## Deploying the actual containers
We are now ready to deploy our containers through the concept of K8s deployments to ensure high availability or our eShopServices

Note that the deployments are paused, this is done so that you may update the images through the next piece of code. We you may your own images if you've successfully built your docker images and pushed them to Azure Container Registry

```
kubectl apply -f deployments-lab.yaml
```

```
kubectl apply -f helm/aks-httpaddon-cfg.yaml
```





# OPTIONAL - HELM hands-on
In this section we will deploy the _basket-api_ using **Helm Charts** instead of _manuel_ K8s deployment files

### make sure that the helm cli is installed

```
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz
tar -zxvf helm-v2.11.0-linux-amd64.tgz
mv linux-amd64/helm /usr/local/bin/helm
```

### let's configure our AKS cluster to support HELM

```
helm version
helm init
```

## Now let's deploy our application

**Note that we recomanded to delete the existing basket-api deployment we've done to have a _clean slate_ when deploying the application through helm charts**

```
cd eShopOnContainers/k8s/helm/

kubectl config get-contexts

helm init --upgrade
```

### let's retrieve the externalURL
We need to retrieve the externalURL to add this information to the k8s configuration map, this URL will then be _injected_ as an env variable in our containers (or pod as a matter of fact)

```
externalDNS=$(kubectl get svc addon-http-application-routing-nginx-ingress --namespace=kube-system -o=jsonpath="{.status.loadBalancer.ingress[0].ip}")
```

This is the installation phase, we are using the **helm upgrade** command because it is idempotent, remember that we want to use declative configuration as much as posssible. The _--install_ flag will ensure that the _upgrade_ command intalls our pods successfully on the first deployment (i.e on a clean AKS instance)

### Installing the backing services
```
helm upgrade --install \
		    --values app.yaml \
		    --values inf.yaml \
		    --values ingress_values.yaml \
		    --set app.name="eshop" \
		    --set inf.k8s.dns="$externalDNS" \
--force "eshop-aks-rabbitmq" rabbitmq 
```

### installing a container using helm charts

In the command below, note that we are _injecting_ values in helm, helm will then modify/generate the deployment files defined in the template to reflect these values. Behing the scenes helm uses Go Templates.

```
helm upgrade --install \
			  --values app.yaml \
			  --values inf.yaml \
			  --values ingress_values.yaml \
			  --set app.name="eshop" \
			  --set inf.k8s.dns="$externalDNS" \
			  --set inf.appinsights.key="" \
			  --set image.tag="hub" \
			  --set image.pullPolicy="Always" \
			  --set image.repository="nyuen/basket.api" \
			  --force  "eshop-aks-basket-api" basket-api
```
