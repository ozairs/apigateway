#! /bin/sh

nice_echo() {
    echo "\n\033[1;36m >>>>>>>>>> $1 <<<<<<<<<< \033[0m\n"
}


CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# no parameters passed, using default config file
if [ $# -eq 0 ]; then
    #using default config file
    if [ -e config.cfg ]; then
        source ${CURRENT_DIR}/config.cfg
        echo 'Using default config file at ' ${CURRENT_DIR}/config.cfg 
    else 
        echo 'No config file passed and default config file is not available at ' ${CURRENT_DIR}/config.cfg 
        exit
    fi
# usage function
elif [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "Usage: `basename $0` [OPTION] [FILE]...
  Options:
  -h, --help        Display this help and exit
  "
  exit 0
# config file passed as argument
else 
    FILENAME=$1 #get filename
    if [ -e $FILENAME ]; then
        source $FILENAME; # load the file
        echo 'Using config file located at ' $FILENAME
    else 
        echo 'Bad config file passed at ' $FILENAME
        exit
    fi
fi

RED='\n\033[1;31m'
GREEN='\n\033[1;32m'
END_COLOR='\033[0m'

# ******************** Step 1. Delete Application Subscription  ********************
nice_echo "Step 1. Delete Application Subscription"

CURL_BODY='{
    "DeleteAPISubscription": {
        "APICollection": "'"${APIGATEWAY_OBJ}"'",
        "AppID": "'"${CONSUMER_APP_ID}"'",
        "Plans": "'"${API_PRODUCT_PLAN_OBJ}"'"
    }
}'

RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d "$CURL_BODY" ${DP_REST_ENDPOINT}/mgmt/actionqueue/${DOMAIN}`

echo "Step 1." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.DeleteAPISubscription'`

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
    "DeleteAPIClient": {
        "APICollection": "'"${APIGATEWAY_OBJ}"'",
        "ClientID": "'"${CONSUMER_CLIENT_ID}"'"
    }
}'

RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d "$CURL_BODY" ${DP_REST_ENDPOINT}/mgmt/actionqueue/${DOMAIN}`

echo "Step 2." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.DeleteAPIClient'`

if [[ $RESPONSE_URL == "Operation completed." ]]; 
then
 echo "${GREEN}SUCCESS${END_COLOR}"
else
  echo "${RED}FAIL${END_COLOR}"
  echo 'Error  ' $RESPONSE
fi

# ******************** Step 3. Delete Application ********************
nice_echo "Step 3. Delete Application"

CURL_BODY='{
  "DeleteAPIApplication": {
    "APICollection" : "'"${APIGATEWAY_OBJ}"'",
    "AppID": "'"${CONSUMER_APP_ID}"'"
  }
}'

RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d "$CURL_BODY" ${DP_REST_ENDPOINT}/mgmt/actionqueue/${DOMAIN}`

echo "Step 3." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.DeleteAPIApplication'`

if [[ $RESPONSE_URL == "Operation completed." ]];
then
 echo "${GREEN}SUCCESS${END_COLOR}"
else
  echo "${RED}FAIL${END_COLOR}"
  echo 'Error  ' $RESPONSE
fi


nice_echo "Script actions completed. Check logs for more details."
