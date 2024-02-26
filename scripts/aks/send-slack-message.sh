#!/bin/bash
source scripts/common/common-functions.sh

WEBHOOK_URL=$1
#curl -s -X POST --data-urlencode "payload={\"channel\": \"${CHANNEL_NAME}\", \"username\": \"Plato\", \"text\": \"${MESSAGE}\", \"icon_emoji\": \":plato:\"}" ${WEBHOOK_URL}
rm slack-payload.json

# Define Bash variables

# Define Bash variables
id=$2
request_url="*<$3|$id>*"
business_area=$4
current_date=$(get_current_date)
start_date="$5"
end_date="$6"
cost_value="£$7"
environment="$8"

echo "environment"
echo $environment

# Use jq with variables
jq --arg new_url "$request_url" \
   --arg business_area "$business_area" \
   --arg current_date "$current_date" \
   --arg start_date "$start_date" \
   --arg end_date "$end_date" \
   --arg cost_value "$cost_value" \
   --arg environment $environment \
   '.blocks[0].text.text |= "You have a new request:\n\($new_url)" | 
    .blocks[1].fields[0].text |= "*Business Area:*\n\($business_area)" |
    .blocks[1].fields[1].text |= "*Environment:*\n\($environment)" |
    .blocks[1].fields[2].text |= "*Start Date:*\n\($start_date)" |
    .blocks[1].fields[3].text |= "*End Date:*\n\($end_date)" |
    .blocks[1].fields[4].text |= "*Value:*\n\($cost_value)" |
    .blocks[1].fields[5].text |= "*Submitted:*\n\($current_date)"' scripts/aks/message-template.json > slack-payload.json

MESSAGE=$(< slack-payload.json)

curl -X POST -H 'Content-type: application/json' --data "${MESSAGE}" ${WEBHOOK_URL}
rm slack-payload.json