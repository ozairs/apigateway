# Deploy DataPower API Gateway Service on Kubernetes

In this tutorial, you will package the DataPower API Gateway service on Kubernetes. You will package DataPower configuration on Kubernetes using Kubernetes ConfigMaps and crypto material using Kubernetes secrets. In the previous tutorial, you downloaded a DataPower configuration zip file and deployed it to a standalone DataPower docker instance. When running a DataPower instance, it uses a set of `cfg` files from the `config` folder. Since the DataPower docker instance maps the configuration to the host file system, you will use it to create the kubernetes config maps. The certificate files are not included in the `configmaps`. They are manually embedded into Kubernetes secrets per Kubernetes best practices.

**Pre-requisites**

* [Docker Desktop](https://www.docker.com/products/docker-desktop)
* Clone the GitHub repository at [here](https://github.com/ozairs/datapower-container.git) or [Download the respository zip file](https://github.com/ozairs/datapower-container/archive/master.zip). 
* Following tools: [curl](https://curl.haxx.se) and [jq](https://stedolan.github.io/jq/)

## Package for Deployment on Kubernetes

In this section, you will create the Kubernetes artifacts to deploy the API Gateway service into Kubernetes. These instructions assume that you have DataPower configuration within the `docker` folder.
        ```
    |-- _deploy
    |-- docker
    |-- istio
    |-- kubernetes
    |-- scripts
    ```

1. Navigate to the `kubernetes` directory. Enter the following commands to create the kubernetes configmap objects from the deployed configuration
    ```
    kubectl create namespace demo
    kubectl create configmap datapower-config --from-file=../docker/config --from-file=../docker/config/apigateway -n demo
    kubectl create configmap datapower-local-js --from-file=../docker/temporary/apigateway/js/ -n demo
    kubectl create configmap datapower-local-swagger --from-file=../docker/temporary/apigateway/swagger/ -n demo
    ```
6. Create the kubernetes secret object
    ```
    kubectl apply -f k8-secrets.yml
    ```
7. Deploy the Kubernetes deployment pod and service definitions
    ```
    kubectl apply -f dp-deployment.yml
    kubectl apply -f dp-service.yml
    kubectl apply -f dp-service-nodeport.yml
    ```

    The `dp-service-nodeport.yml` file exposes the DataPower runtime port and management interfaces on the host machine, which is not recommended for production deployment. Furthermore, you would deploy the DataPower runtime port using the platform Ingress controller; however, Docker for Desktop does not provide a default ingress controller. You could deploy one but its outside the scope of this tutorial; for simplicity, we will access the API Gateway using the `NodePort` Kubernetes service configuration.

8. Validate that the API Gateway service is deployed sucessfully and running.
    ```
    > kubectl get pods -n demo
    NAME                          READY   STATUS    RESTARTS   AGE
    apigateway-668bc79c7f-9795b   1/1     Running   0          57s
    ```

10. Run a sample request to validate that the API Gateway deployment on Kubernetes is successful
    ```
    ../scripts/test-api.sh -f $PWD/config.cfg utility ping
    SUCCESS
    {"args":{},"headers":{"Accept":"application/json","Cache-Control":"no-transform","Content-Type":"application/json","Host":"httpbin.org","User-Agent":"curl/7.64.1","X-Amzn-Trace-Id":"Root=1-5e3e3aaa-b9fd8ecc381d77f422aeadd0","X-Client-Ip":"172.18.0.6","X-Global-Transaction-Id":"72c7cd995e3e3aaa00001741","X-Ratelimit-Limit":"name=default,100;","X-Ratelimit-Remaining":"name=default,99;"},"origin":"50.101.111.77","url":"https://httpbin.org/get"}
    ```

11. You will now test APIs that require an API subscription. Use the following script to create a API subscription:
    ```
    ../scripts/create-app-subscription.sh -f $PWD/config.cfg
    .
    .
    .
    SUCCESS

    >>>>>>>>>> Script actions completed. Check logs for more details. <<<<<<<<<< 
    ```

12. Obtain an OAuth access token and then call the Sports API with that token. The `test-api.sh` script includes the API parameters needed to call the Sports API with OAuth security.
    ```
    ../scripts/test-api.sh -f $PWD/config.cfg oauth resource-owner
    
    >>>>>>>>>> OAuth API <<<<<<<<<< 

    Resource Owner: https://127.0.0.1.xip.io:30043/localtest/sandbox/oauth2/token

    SUCCESS
    {"token_type":"Bearer","access_token":"AAIgOGMyZmRiNzVlMjBkMDJiMzRiZTZkMzg3ZDhjMTI4ZjdFEKJ2aIyRF7LzQoJKiUcKW94Tj7AAbvKcq8AorBictIvAvAQKLmXW6rEqfFbcN71p63shXOlM4Nm8Kzox0tVi","scope":"sports","expires_in":3600,"consented_on":1582232174,"refresh_token":"AALI3xrJeeCWYi-Ddxy94NM_P5_DNlAb1LDPuXs2-GyZkASksRJfbSw-D7tgBeJChYL9O65jaOVOx3jQRwMOg3eQ8JdHXBuQrPWH8CzXhtFeuw","refresh_token_expires_in":2682000}
    ```

13. Copy the OAuth access token and use it to call the Sports API
    ```
    ../scripts/test-api.sh -f $PWD/config.cfg sports-oauth teams

    >>>>>>>>>> Sports API https://127.0.0.1:9445/localtest/sandbox/sports/teams?league=nba <<<<<<<<<< 

    Enter the access token: AAIgOGMyZmRiNzVlMjBkMDJiMzRiZTZkMzg3ZDhjMTI4ZjdsjchGgOOLEKSkmiAnVvWyqg4kITPPzk55xMp4POlXxn_3JWxFnieayjO4Sw0Phch8Pe7Q2vjZtD1x9me9G9FAETOepZ67mX_9AfG2UPDiCUe65LbIj27WGTNL6C6B_go

    SUCCESS
    ```

14. Once your done testing, delete the existing kubernetes artifacts.
    ```
    kubectl delete cm -n demo --all
    kubectl delete -f k8-secrets.yml
    kubectl delete -f dp-deployment.yml
    kubectl delete -f dp-service.yml
    kubectl delete -f dp-service-nodeport.yml
    ```

Congratulations, you have successfully deployed the DataPower API Gateway service in Kubernetes and tested APIs with no security, OAuth security and API subscriptions.

## Summary

In this tutorial, You packaged and deployed the API Gateway configuration into Kubernetes. In the next tutorial, you will deploy the same DataPower container into an Istio-managed Kubernetes cluster and leverage Istio-based policies for platform resiliency and security.