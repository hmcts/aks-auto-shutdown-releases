#!/usr/bin/env bash
#set -x
shopt -s nocasematch
to_date=$(date +'%d-%m-%Y')
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
            SDS=$(date -j -f "%d-%m-%Y" "${SD}" +"%s")
            EDS=$(date -j -f "%d-%m-%Y" "${ED}" +"%s")
            TOSEC=$(date -j -f "%d-%m-%Y" "${to_date}" +"%s")
            echo $NAME $BU $ENV $BA $ENVT $SD $ED $SDS $EDS  $TOSEC $to_date $DIFF    
            DIFF=$(( $EDS - $TOSEC ))
            if [[ ${ENVT} =~ ${ENV} ]] && [[ $BU == $BA ]] && [[ $SDS -eq $TOSEC ]] ; then
                echo $NAME $BU $ENV $BA $ENVT $SD $ED $SDS $EDS  $TOSEC $to_date $DIFF
                echo "Match: $id"
                SKIP="true"
                continue

            elif [[ ${ENVT} =~ ${ENV} ]] && [[ $BU == $BA ]] && [[ $DIFF -lt 129600 ]]; then
                echo "Match : $id"
                echo $NAME $BU $ENV $BA $ENVT $SD $ED $SDS $EDS  $TOSEC $to_date $DIFF
                SKIP="true"
                continue
            fi
            echo $SKIP
        done < <(jq -c '.[]' issues_list.json)
        echo "outside $SKIP"
        if [[ $SKIP == "false" ]]; then
            echo "About to shutdown cluster $NAME (rg:$RESOURCE_GROUP)"
        else
            echo "cluster $NAME (rg:$RESOURCE_GROUP) has been skipped from todays shutdown schedule"
        fi


    #echo az aks stop --resource-group $RESOURCE_GROUP --name $NAME || echo Ignoring any errors stopping cluster
    #-az aks stop --resource-group $RESOURCE_GROUP --name $NAME || echo Ignoring any errors stopping cluster
    done # end_of_cluster_loop
done
