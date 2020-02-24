# Use Istio JWT Security to Protect Microservices using DataPower API Gateway Service

In this tutorial, you will apply Istio policies between the DataPower API Gateway and Microservices deployed within the Istio service mesh. You must complete the [previous tutorial](../istio/README.md).

Last mile security is a common security metaphor used to describe the security policies needed for the last leg of a transaction. The typical flow of a transaction involves authentication / authorization of the user at the ingress or near the ingress. The API Gateway traditonally provides the security at the ingress layer (optionally can also interact with identity and access management systems). Once the authentication / authorization is successful, the API Gateway will generate a token to assert security claims. This token is then sent downstream to the backend microservices which is validated using a public key.

In this tutorial, you will apply a JWT Security policy to the `fancave-teams` microservice. The API Gateway is already pre-configured with a JWT Generate policy that creates a JWT token and sends it to the fancave-teams service.

1. Invoke the **unprotected** fancave-teams service and make sure you get a successful response.
    ```
    curl -k https://127.0.0.1.xip.io/api/team/list?league=nba
    ```
2. Navigate to the `istio` folder and apply the JWT security policy to the fancave-teams service.
    ```
    kubectl apply -f jwt-policy.yaml 
    ```
3. The JWT Security policy requires that a token is sent to the `fancave-teams` service which is validated by the `jwksURI` and must contain the `issuer` value `ozairs4@example.com`.
    ```
      origins:
    - jwt:
        issuer: "ozairs4@example.com"
        jwksUri: "https://raw.githubusercontent.com/ozairs/apiconnect-2018/master/scripts/crypto/jwk-rs256.json"
    ```
4. Invoke the same fancave-teams service, you should now get an error
    ```
    > curl -k https://127.0.0.1.xip.io/api/team/list?league=nba
    Origin authentication failed.
    ```
5. Obtain an OAuth access token and then call the Sports API with that token. The `test-api.sh` script includes the API parameters needed to call the Sports API with OAuth security.
    ```
    ../scripts/test-api.sh -f $PWD/config.cfg oauth application
    
    >>>>>>>>>> OAuth API <<<<<<<<<< 

    Client Credentials: https://127.0.0.1.xip.io/localtest/sandbox/oauth2/token

    SUCCESS
    {"token_type":"Bearer","access_token":"AAIgOGMyZmRiNzVlMjBkMDJiMzRiZTZkMzg3ZDhjMTI4ZjeZ3wcPRXKWGp4Hp_Jhm0jqcBnvUjv_4SGzY2pmPsTOpceIH_lTVPHaPY8bOLMagHK90k7ERupTbzPZcw3ImO5JRyEjJ5lphI-Q3ljArDOXji8ivPZaanwM7ON7snTo6pM","scope":"sports","expires_in":3600,"consented_on":1582235565}
    ```

6. Copy the OAuth access token and use it to call the Sports API (notice it uses the ingress port 443)
    ```
    ../scripts/test-api.sh -f $PWD/config.cfg sports-oauth teams

    >>>>>>>>>> Sports API https://127.0.0.1/localtest/sandbox/sports/teams?league=nba <<<<<<<<<< 

    Enter the access token: AAIgOGMyZmRiNzVlMjBkMDJiMzRiZTZkMzg3ZDhjMTI4ZjdsjchGgOOLEKSkmiAnVvWyqg4kITPPzk55xMp4POlXxn_3JWxFnieayjO4Sw0Phch8Pe7Q2vjZtD1x9me9G9FAETOepZ67mX_9AfG2UPDiCUe65LbIj27WGTNL6C6B_go

    SUCCESS
    ```
Congratulations, you have successfully enforced Istio security between the DataPower API Gateway and the Fancave teams microservice.

## Summary

In this tutorial, you configured "last mile security" using an Istio JWT Security policy to protect access to a microservice with a valid JWT Token. The DataPower API Gateway service is then used to generate a token and invoke the Fancave Teams microservice successfully. 

Next: [Dynamically Route DataPower API Gateway Traffic using Istio Traffic Routing Rules](../istio/README-routing.md)

