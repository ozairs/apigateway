# Deploy DataPower API Gateway Service into Istio Service Mesh

In this tutorial, you will package and deploy the DataPower API Gateway service into an Istio service mesh. The same configuration used for Kubernetes is used when deploying into Istio with the exception that Istio will deploy a sidecar alongside the DataPower API Gateway service.

You will also deploy a backend service within the service mesh so you can control and experiment with Istio policies between multiple pods.

**Pre-requisites**

* [Docker Desktop](https://www.docker.com/products/docker-desktop)
* Clone the GitHub repository at [here](https://github.com/ozairs/apigateway.git) or [Download the respository zip file](https://github.com/ozairs/apigateway/archive/master.zip). 
* Following tools: [curl](https://curl.haxx.se) and [jq](https://stedolan.github.io/jq/)

## Configure Istio Environment

In this section, you will configurre the Istio artifacts to deploy the API Gateway service into an Istio service mesh. These instructions assume that you have DataPower configuration within the `docker` folder.
        ```
    |-- _deploy
    |-- docker
    |-- istio
    |-- kubernetes
    |-- scripts
    ```

1. Download the Istio management components into a folder on your workstation. Make sure you add `istioctl` into your path.
    ``` 
    curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
    ```

2. Navigate to the `istio` folder. Enable automatic sidecar injection for each pod
    ```
    kubectl label namespace demo istio-injection=enabled
    ```
3. Install Istio with the following commands, which will also configure Istio add-ons.
    
    ```
    istioctl manifest apply \
    --set values.tracing.ingress.enabled=true \
    --set values.tracing.enabled=true \
    --set values.grafana.enabled=true \
    --set values.prometheus.enabled=true \
    --set values.kiali.enabled=true \
    --set values.pilot.traceSampling=100 \
    --set "values.kiali.dashboard.jaegerURL=http://jaeger-query.istio-system.svc.cluster.local:16686" \
    --set "values.kiali.dashboard.grafanaURL=http://grafana.istio-system.svc.cluster.local:3000"
    ```

4. Make sure the istio pods are deployed successfully and running
    ```
    NAME                                      READY   STATUS    RESTARTS   AGE
    grafana-6c8f45499-tl9k9                   1/1     Running   0          72s
    istio-citadel-7c959c8d59-q5d4r            1/1     Running   0          74s
    istio-galley-5479df66b5-kmqvs             2/2     Running   0          73s
    istio-ingressgateway-7c95796d59-w8gwb     1/1     Running   0          74s
    istio-pilot-59474d8b95-fb7s9              1/2     Running   0          73s
    istio-policy-5b9b9f5cd9-9wdc4             2/2     Running   2          74s
    istio-sidecar-injector-7dbcc9fc89-fffck   1/1     Running   0          73s
    istio-telemetry-7d5b5947db-th77w          2/2     Running   2          74s
    istio-tracing-78548677bc-pp9g5            1/1     Running   0          74s
    kiali-fb5f485fb-rs7mq                     1/1     Running   0          74s
    prometheus-685585888b-vlc6h               1/1     Running   0          74s
    ```

5. Deploy Istio Ingress with TLS. You will need to create public/private key pair:
    ```
    # generate public/private CA key pair
    openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 -subj '/O=IBM./CN=localhost.127.0.0.1.xip.io CA' -keyout localhost-ca.key -out localhost-ca.crt

    # generate public/private TLS key pair
    openssl req -out localhost.csr -newkey rsa:2048 -nodes -keyout localhost.key -subj "/CN=127.0.0.1.xip.io/O=IBM"
    
    # sign the public TLS cert with the CA keypair
    openssl x509 -req -days 365 -CA localhost-ca.crt -CAkey localhost-ca.key -set_serial 0 -in localhost.csr -out localhost.crt

    # create kubernetes secret with the TLS key and cert, using special secret name
    kubectl create -n istio-system secret tls istio-ingressgateway-certs --key localhost.key --cert localhost.crt
    ```

6. Create Istio Gateway ingress resource
    ```
    kubectl apply -f ingress-http.yaml
    ```

7. Since the API Gateway is secured using https, you will need to configure a rule for the ingress to establish a TLS connection to the `apigateway` service.
    ```
    kubectl apply -f apigateway-tls.yaml
    ```

8. Deploy the API Gateway service Kubernetes artifacts
    ```
    kubectl create configmap datapower-config --from-file=../docker/config --from-file=../docker/config/apigateway -n demo
    kubectl create configmap datapower-local-js --from-file=../docker/temporary/apigateway/js/ -n demo
    kubectl create configmap datapower-local-swagger --from-file=../docker/temporary/apigateway/swagger/ -n demo
    kubectl apply -f ../kubernetes/k8-secrets.yml
    kubectl apply -f ../kubernetes/dp-deployment.yml
    kubectl apply -f ../kubernetes/dp-service.yml
    kubectl apply -f ../kubernetes/dp-service-nodeport.yml
    ```

9. Verify that the API Gateway service is successfully deployed. You will notice that an Istio deployment contains 2 containers within each pods.
    ```
    kubectl get pods -n demo
    NAME                          READY   STATUS    RESTARTS   AGE
    apigateway-668bc79c7f-9hzfb   2/2     Running   0          61s
    ```

10. Run a sample request to validate that the API Gateway deployment in the service mesh is successful
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

In the next step, you would typically call the API definition with the OAuth token; however, since we want to experiment with Istio using locally deployed pods, you will tweak the API Gateway configuration to call a locally deployed microservice instead of the externally deployed servicee.

The quickest way to modify the DataPower configuration is to modify the ConfigMap and restart the DataPower pod.

12. Using a text editor, modify the following Invoke policy endpoint to `http://fancave-teams.demo.svc.cluster.local:3080/api/team/list?league={league}`.

    ```
    cd ../docker/config/apigateway/
    open apigateway.cfg
    ```
    .
    .
    .
    ```
    assembly-invoke "localtest_sandbox_sports-api_1.0.0_invoke_6"
    title "invoke"
    correlation-path "$.x-ibm-configuration.assembly.execute[2].switch.case[3].execute[0]"
    url "http://fancave-teams.demo.svc.cluster.local:3080/api/team/list?league={league}"
    ```

13. Re-deploy the config map and restart the DataPower API Gateway service. The API Gateway is ready to call the locally deployed fancave service.
    ```
    kubectl delete configmap/datapower-config --namespace demo
    kubectl create configmap datapower-config --from-file=../docker/config --from-file=../docker/config/apigateway -n demo
    kubectl scale deployment apigateway -n demo --replicas=0
    kubectl scale deployment apigateway -n demo --replicas=1
    ../scripts/create-app-subscription.sh -f $PWD/config.cfg
    ```

Now, we need to deploy the backend microservice.

14. Deploy the fancave microservice. Navigate to the `istio` directory and run the following commands:
    ```
    kubectl apply -f ./fancave -n demo
    ```

15. Validate that the fancave microservices are deployed successfully. You will notice two pods are deployed, you can assume that both of these pods provide the same response.

16. The Istio Ingress contains a rule for calling the Fancave teams service directly. You will lock down direct access in a later step but lets make sure we can access the service directly (note: we are using curl to call directly).
    ```
    curl -k https://127.0.0.1.xip.io/api/team/list?league=nba | jq '.'
    ```

You will call the same sports API using the API Gateway. Since the Sports API is protected using OAuth on the API Gateway, you will need an access token before invoking it. Obviously, we need to lock the backend down, which will be done in a later step.

17. Obtain an OAuth access token and then call the Sports API with that token. The `test-api.sh` script includes the API parameters needed to call the Sports API with OAuth security (make sure your in the `istio` folder.
    ```
    ../scripts/test-api.sh -f $PWD/config.cfg oauth application
    
    >>>>>>>>>> OAuth API <<<<<<<<<< 

    Client Credentials: https://127.0.0.1.xip.io/localtest/sandbox/oauth2/token

    SUCCESS
    {"token_type":"Bearer","access_token":"AAIgOGMyZmRiNzVlMjBkMDJiMzRiZTZkMzg3ZDhjMTI4ZjeZ3wcPRXKWGp4Hp_Jhm0jqcBnvUjv_4SGzY2pmPsTOpceIH_lTVPHaPY8bOLMagHK90k7ERupTbzPZcw3ImO5JRyEjJ5lphI-Q3ljArDOXji8ivPZaanwM7ON7snTo6pM","scope":"sports","expires_in":3600,"consented_on":1582235565}
    ```

18. Copy the OAuth access token and use it to call the Sports API (notice it uses the ingress port 443)
    ```
    ../scripts/test-api.sh -f $PWD/config.cfg sports-oauth teams

    >>>>>>>>>> Sports API https://127.0.0.1:/localtest/sandbox/sports/teams?league=nba <<<<<<<<<< 

    Enter the access token: AAIgOGMyZmRiNzVlMjBkMDJiMzRiZTZkMzg3ZDhjMTI4ZjdsjchGgOOLEKSkmiAnVvWyqg4kITPPzk55xMp4POlXxn_3JWxFnieayjO4Sw0Phch8Pe7Q2vjZtD1x9me9G9FAETOepZ67mX_9AfG2UPDiCUe65LbIj27WGTNL6C6B_go

    SUCCESS
    ```
Congratulations, you have successfully deployed the DataPower API Gateway service into the Istio service mesh and tested APIs with no security, OAuth security and API subscriptions.

## Summary

In this tutorial, You packaged and deployed the API Gateway configuration into the Istio service mesh. In the next tutorial, you will demonsrate how to apply Istio policies to provide enhanced security and platform resiliency. The key value proposition of Istio is that you can enforce policies without modifying any code / configuration within individual pods. You will learn how it can be done.

Next: [Use Istio JWT Security to Protect Microservices using DataPower API Gateway Service](../istio/README-security.md)
