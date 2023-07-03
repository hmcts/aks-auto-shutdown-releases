#!/usr/bin/env bash
#set -x
shopt -s nocasematch
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'

SUBSCRIPTIONS=$(az account list -o json)
jq -c '.[]' <<< $SUBSCRIPTIONS | while read subscription; do
    SUBSCRIPTION_ID=$(jq -r '.id' <<< $subscription)
    az account set -s $SUBSCRIPTION_ID
    #CLUSTERS=$(az resource list \
    #--resource-type Microsoft.ContainerService/managedClusters \
    #--query "[?tags.autoShutdown == 'true']" -o json)
    CLUSTERS=$(az resource list \
        --resource-type Microsoft.ContainerService/managedClusters     -o json)

    jq -c '.[]' <<< $CLUSTERS | while read cluster; do
        RESOURCE_GROUP=$(jq -r '.resourceGroup' <<< $cluster)
        SKIP="false"
        NAME=$(jq -r '.name' <<< $cluster)
        echo "----------------"
        ENV=$(echo $NAME|cut -d'-' -f2)
        BU=$(echo $NAME|cut -d'-' -f1)
        ENV=${ENV/#sbox/Sandbox}
        ENV=${ENV/stg/Staging}
        echo $NAME $BU $ENV
        while read id
        do
            BA=$(jq -r '."Business area"' <<< $id)
            ENVT=$(jq -r '."Environment"' <<< $id)
            SD=$(jq -r '."Skip shutdown start date"' <<< $id)
            ED=$(jq -r '."Skip shutdown end date"' <<< $id)
            #start date formatting
            SDF=$(awk -F'-' '{printf("%04d-%02d-%02d\n",$3,$2,$1)}' <<< $SD)
            SDS=$(date -d "$SDF 00:00:00" +%s)
            #end date formatting
            EDF=$(awk -F'-' '{printf("%04d-%02d-%02d\n",$3,$2,$1)}' <<< $ED)
            EDS=$(date -d "$EDF 00:00:00" +%s)
            #current date formatting
            current_date=$(date +'%d-%m-%Y')
            CDF=$(awk -F'-' '{printf("%04d-%02d-%02d\n",$3,$2,$1)}' <<< $current_date)
            CDS=$(date -d "$CDF 00:00:00" +%s)
            #Skip logic
            echo $NAME $BU $ENV $BA $ENVT $SD $ED $SDS $EDS $CDS
            if [[ ${ENVT} =~ ${ENV} ]] && [[ $BU == $BA ]] && [[ $SDS -eq $CDS ]] ; then
                echo "Match: $id"
                SKIP="true"
                continue

            elif [[ ${ENVT} =~ ${ENV} ]] && [[ $BU == $BA ]] && [[ $CDS -ge $SDS ]] &&[[ $CDS -le $EDS ]]; then
                echo "Match : $id"
                SKIP="true"
                continue
            fi
        done < <(jq -c '.[]' issues_list.json)
        if [[ $SKIP == "false" ]]; then
            echo -e "${GREEN}About to shutdown cluster $NAME (rg:$RESOURCE_GROUP)"
        else
            echo -e "${YELLOW}cluster $NAME (rg:$RESOURCE_GROUP) has been skipped from todays shutdown schedule"
        fi


    #echo az aks stop --resource-group $RESOURCE_GROUP --name $NAME || echo Ignoring any errors stopping cluster
    #-az aks stop --resource-group $RESOURCE_GROUP --name $NAME || echo Ignoring any errors stopping cluster
    done # end_of_cluster_loop
done
