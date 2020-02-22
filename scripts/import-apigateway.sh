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

# ******************** Step 1. Create export.zip ********************
nice_echo "Step 1. Create export zip file"

./_zip-gw-export.sh "$@"

echo "${GREEN}SUCCESS${END_COLOR}"

# ******************** Step 2. Import Certificate Files ********************
nice_echo "Step 2. Import Files"

FROM_FILES_DIR=${CRYPTO_FILES_DIR}

FILES_TO_COPY=''
#loop for each file in directory
for f in $FROM_FILES_DIR
do
  
  FILENAME=`basename $f`
  CUR_PATH='/cert/'$FILENAME
  BASE64_FILE=`openssl base64 < $f | tr -d '\n'`
  
  FILES_TO_COPY=`echo $FILES_TO_COPY`'"file":{
    "path": "'"${CUR_PATH}"'",
    "content": "'"${BASE64_FILE}"'"
  },'

done

CURL_BODY='{
  "LoadConfiguration":{
      "OverwriteFiles": "on",
      '${FILES_TO_COPY%?}'
  }
}'

RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d "$CURL_BODY" ${DP_REST_ENDPOINT}/mgmt/actionqueue/${DOMAIN}`

echo "Step 2." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.LoadConfiguration.status'`

if [[ $RESPONSE_URL == "Action request accepted." ]];
then
 echo "${GREEN}SUCCESS${END_COLOR}"
else
  echo "${RED}FAIL${END_COLOR}"
  echo 'Error  ' $RESPONSE
fi

# ******************** Step 3. Import API Gateway ********************
nice_echo "Step 3. Import API Gateway"

EXPORT_FILE=`cat ${INPUT_CONFIG}`

CURL_BODY='{
   "Import": {
        "InputFile": "'"${EXPORT_FILE}"'",
        "OverwriteObjects": "on",
        "Format": "ZIP"
        }
}'

echo `echo "$CURL_BODY" > ${INPUT_CONFIG}.tmp`

RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d @${INPUT_CONFIG}.tmp ${DP_REST_ENDPOINT}/mgmt/actionqueue/${DOMAIN}`

echo "Step 3." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.Import.status'`

if [[ $RESPONSE_URL == "Action request accepted." ]];
then
 echo "${GREEN}SUCCESS${END_COLOR}"
else
  echo "${RED}FAIL${END_COLOR}"
  echo 'Error  ' $RESPONSE
fi

# ******************** Step 4. Update API Connect Gateway Service Configuration ********************
nice_echo "Step 4. Modify API Connect Gateway Service Object"

EXPORT_FILE=`cat ${INPUT_CONFIG2}`

CURL_BODY='{
   "Import": {
        "InputFile": "'"${EXPORT_FILE}"'",
        "OverwriteObjects": "on",
        "Format": "XML"
        }
}'

RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d "$CURL_BODY" ${DP_REST_ENDPOINT}/mgmt/actionqueue/${DOMAIN}`

echo "Step 4." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.Import.status'`

if [[ $RESPONSE_URL == "Action request accepted." ]];
then
 echo "${GREEN}SUCCESS${END_COLOR}"
else
  echo "${RED}FAIL${END_COLOR}"
  echo 'Error  ' $RESPONSE
fi

echo    
read -p "The script actions finished executing. Check logs to make sure that the configuration is imported (ie Configuration Import completed). When ready, click any key to continue. " -n 1 -r
echo    

# ******************** Step 5. Modify API Gateway Configuration ********************
nice_echo "Step 5. Modify API Connect Gateway Service Object"

EXPORT_FILE=`cat ${INPUT_CONFIG2}`

CURL_BODY='{
  "APICollection": {
    "name" : "'"${APIGATEWAY_OBJ}"'",
    "ApplicationType": "app"
  }
}'

RESPONSE=`curl -s -k -X PUT -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d "$CURL_BODY" ${DP_REST_ENDPOINT}/mgmt/config/${DOMAIN}/APICollection/${APIGATEWAY_OBJ}`

echo "Step 5." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.'"${APIGATEWAY_OBJ}"''`

if [[ $RESPONSE_URL == "Configuration was updated." ]];
then
 echo "${GREEN}SUCCESS${END_COLOR}"
else
  echo "${RED}FAIL${END_COLOR}"
  echo 'Error  ' $RESPONSE
fi

# ******************** Step 6. Modify API Gateway HTTPS FSH ********************
nice_echo "Step 6. Modify API Gateway HTTPS FSH"

CURL_BODY='{
  "HTTPSSourceProtocolHandler": {
    "name" : "apiconnect_https_9443",
    "LocalAddress": "0.0.0.0"
  }
}'

RESPONSE=`curl -s -k -X PUT -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d "$CURL_BODY" ${DP_REST_ENDPOINT}/mgmt/config/${DOMAIN}/HTTPSSourceProtocolHandler/apiconnect_https_9443`

echo "Step 6." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.apiconnect_https_9443'`

if [[ $RESPONSE_URL == "Configuration was updated." ]];
then
 echo "${GREEN}SUCCESS${END_COLOR}"
else
  echo "${RED}FAIL${END_COLOR}"
  echo 'Error  ' $RESPONSE
fi

# ******************** Step 7. Save configuration ********************
nice_echo "Step 7. Save configuration "

CURL_BODY='{"SaveConfig":""}'

RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d "$CURL_BODY" ${DP_REST_ENDPOINT}/mgmt/actionqueue/${DOMAIN}`

echo "Step 7." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.SaveConfig'`

if [[ $RESPONSE_URL == "Operation completed." ]];
then
 echo "${GREEN}SUCCESS${END_COLOR}"
else
  echo "${RED}FAIL${END_COLOR}"
  echo 'Error  ' $RESPONSE
fi

sleep 5

# ******************** Step 8. Restart Domain ********************
nice_echo "Step 8. Restart Domain"

CURL_BODY='{
    "RestartDomain": {
        "Domain": "apigateway"
    }
}'

RESPONSE=`curl -s -k -X POST -H "Content-Type: application/json" -H "Accept: application/json" -u "${ADMIN_USERNAME}:${ADMIN_PWD}" -d "$CURL_BODY" ${DP_REST_ENDPOINT}/mgmt/actionqueue/${DOMAIN}`

echo "Step 8." $RESPONSE

RESPONSE_URL=`echo "$RESPONSE" | jq -r '.RestartDomain.status'`

if [[ $RESPONSE_URL == "Action request accepted." ]];
then
 echo "${GREEN}SUCCESS${END_COLOR}"
else
  echo "${RED}FAIL${END_COLOR}"
  echo 'Error  ' $RESPONSE
fi


nice_echo "Script actions completed. Check logs for more details. The configuration tasks will take a minute to complete."

