#!/bin/bash
source scripts/common/common-functions.sh

#curl -s -X POST --data-urlencode "payload={\"channel\": \"${CHANNEL_NAME}\", \"username\": \"Plato\", \"text\": \"${MESSAGE}\", \"icon_emoji\": \":plato:\"}" ${WEBHOOK_URL}
rm slack-payload.json

# Define Bash variables

# Define Bash variables
id=$CHANGE_JIRA_ID
request_ur_link="*<$REQUEST_URL|$id>*"
current_date=$(get_current_date)

environment_field=$(echo "$ENVIRONMENT" | sed 's/\[//; s/\]//; s/"//g')

#var_without_brackets="${environment//[\"[]/}"
#echo "var without brackets: $var_without_brackets"
#var_without_quotes="${var_without_brackets//\"]/}"

#echo "var without quotes: $var_without_quotes"

# Use jq with variables
jq --arg new_url "$request_ur_link" \
   --arg business_area "$BUSINESS_AREA_ENTRY" \
   --arg current_date "$current_date" \
   --arg start_date "$START_DATE" \
   --arg end_date "$END_DATE" \
   --arg cost_value "£$COST_DETAILS_FORMATTED" \
   --arg environment "$environment_field" \
   '.blocks[0].text.text |= "You have a new request:\n\($new_url)" | 
    .blocks[1].fields[0].text |= "*Business Area:*\n\($business_area)" |
    .blocks[1].fields[1].text |= "*Environment:*\n\($environment)" |
    .blocks[1].fields[2].text |= "*Start Date:*\n\($start_date)" |
    .blocks[1].fields[3].text |= "*End Date:*\n\($end_date)" |
    .blocks[1].fields[4].text |= "*Value:*\n\($cost_value)" |
    .blocks[1].fields[5].text |= "*Submitted:*\n\($current_date)" |
    .blocks[1].fields[6].text |= "*Submitter:*\n\($environment_field)"' scripts/aks/message-template.json > slack-payload.json

MESSAGE=$(< slack-payload.json)

curl -X POST -H 'Content-type: application/json' --data "${MESSAGE}" ${SLACK_WEBHOOK}

