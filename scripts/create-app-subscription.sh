#! /bin/sh

nice_echo() {
    echo "\n\033[1;36m >>>>>>>>>> $1 <<<<<<<<<< \033[0m\n"
}


FILENAME='';
while getopts hf: option
do
case "${option}"
in
f) FILENAME=${OPTARG};;
h) echo "Usage: ./test-api.sh [OPTION] [API] [RESOURCE]
          OPTION:
          -f FILENAME
          -h, --help        Display this help and exit

          API: name of API
          RESOURCE: resource name of API
          "
esac
done

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# no parameters passed, using default config file
if [ "$FILENAME" == '' ]; then
  source ${CURRENT_DIR}/config.cfg
  echo 'Using default config file at ' ${CURRENT_DIR}/config.cfg 
# config file passed as argument
else 
    if [ -e $FILENAME ]; then
        source $FILENAME; # load the file
        echo 'Using config file located at' $FILENAME
    else 
        echo 'Bad config file passed at ' $FILENAME
        exit
    fi
fi

RED='\n\033[1;31m'
GREEN='\n\033[1;32m'
END_COLOR='\033[0m'

# ******************** Step 1. Create Application ********************
nice_echo "Step 1. Create Application"

CURL_BODY='{
  "AddAPIApplication": {
    "APICollection" : "'"${APIGATEWAY_OBJ}"'",
    "AppID": "'"${CONSUMER_APP_ID}"'",
    "AppName": "'"${CONSUMER_APP_NAME}"'",
    "Enabled": "enabled",
    "LifecycleState": "production",
    "ApplicationType": "'"${APIGATEWAY_APP_TYPE_OBJ}"'",
    "OrgID": "'"${CONSUMER_ORG_ID}"'",
    "OrgName": "'"${CONSUMER_ORG_NAME}"'",
    "OrgTitle": "'"${CONSUMER_ORG_NAME}"'",
    "RedirectURLs": "'"${CONSUMER_REDIRECT_URL}"'"
  }
}'

RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d "$CURL_BODY" ${DP_REST_ENDPOINT}/mgmt/actionqueue/${DOMAIN}`

echo "Step 1." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.AddAPIApplication'`

if [[ $RESPONSE_URL == "Operation completed." ]];
then
 echo "${GREEN}SUCCESS${END_COLOR}"
else
  echo "${RED}FAIL${END_COLOR}"
  echo 'Error  ' $RESPONSE
fi

# ******************** Step 2. Create Application Credentials ********************
nice_echo "Step 2. Create Application Credentials"

CURL_BODY='{
    "AddAPIClient": {
        "APICollection": "'"${APIGATEWAY_OBJ}"'",
        "ClientID": "'"${CONSUMER_CLIENT_ID}"'",
        "ClientSecret": "'"${CONSUMER_CLIENT_SECRET}"'",
        "Title": "'"${CONSUMER_APP_CREDS}"'",
        "AppID": "'"${CONSUMER_APP_ID}"'"
    }
}'

RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d "$CURL_BODY" ${DP_REST_ENDPOINT}/mgmt/actionqueue/${DOMAIN}`

echo "Step 2." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.AddAPIClient'`

if [[ $RESPONSE_URL == "Operation completed." ]]; 
then
 echo "${GREEN}SUCCESS${END_COLOR}"
else
  echo "${RED}FAIL${END_COLOR}"
  echo 'Error  ' $RESPONSE
fi

# ******************** Step 3. Create Application Subscription  ********************
nice_echo "Step 3. Create Application Subscription"

CURL_BODY='{
    "UpdateAPISubscription": {
        "APICollection": "'"${APIGATEWAY_OBJ}"'",
        "AppID": "'"${CONSUMER_APP_ID}"'",
        "Plans": "'"${API_PRODUCT_PLAN_OBJ}"'",
        "Status": "enabled"
    }
}'

RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d "$CURL_BODY" ${DP_REST_ENDPOINT}/mgmt/actionqueue/${DOMAIN}`

echo "Step 3." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.UpdateAPISubscription'`

if [[ $RESPONSE_URL == "Operation completed." ]]; 
then
 echo "${GREEN}SUCCESS${END_COLOR}"
else
  echo "${RED}FAIL${END_COLOR}"
  echo 'Error  ' $RESPONSE
fi

nice_echo "Script actions completed. Check logs for more details."
