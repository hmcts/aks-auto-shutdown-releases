#!/usr/bin/env bash
#set -x
shopt -s nocasematch
to_date=$(date +'%m-%d-%Y')
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
        #---what are these doing? ENV=${ENV/#sbox/Sandbox}
        #---                      ENV=${ENV/stg/Staging}
        echo $NAME $BU $ENV
        while read id
        do
            BA=$(jq -r '."Business area"' <<< $id)
            ENVT=$(jq -r '."Environment"' <<< $id)
            SD=$(jq -r '."Skip shutdown start date"' <<< $id)
            ED=$(jq -r '."Skip shutdown end date"' <<< $id)
            echo $SD
            echo $ED
            TEST=$(awk -F'-' '{printf("%04d-%02d-%02d\n",$3,$2,$1)}' <<< $SD)
            echo $TEST
            SDS=$(date -d "$TEST 23:59:59" +%s)
            echo $SDS
            EDS=$(date +"%d-%m-%Y" -d $ED)
            TOSEC=$(date +"%d-%m-%Y" -d $to_date)
            echo $EDS
            echo $TOSEC
            DIFF=$(( $EDS - $TOSEC ))
            STARTDIFF=$(( $TOSEC - $SDS ))
            echo $NAME $BU $ENV $BA $ENVT $SD $ED $SDS $EDS  $TOSEC $to_date $DIFF $STARTDIFF
            if [[ ${ENVT} =~ ${ENV} ]] && [[ $BU == $BA ]] && [[ $SDS -eq $TOSEC ]] ; then
                echo "Match: $id"
                SKIP="true"
                continue

            elif [[ ${ENVT} =~ ${ENV} ]] && [[ $BU == $BA ]] && [[ $STARTDIFF -gt 0 ]] &&[[ $DIFF -lt 86401 ]]; then
                echo "Match : $id"
                SKIP="true"
                continue
            fi
        done < <(jq -c '.[]' issues_list.json)
        if [[ $SKIP == "false" ]]; then
            echo "About to shutdown cluster $NAME (rg:$RESOURCE_GROUP)"
        else
            echo "cluster $NAME (rg:$RESOURCE_GROUP) has been skipped from todays shutdown schedule"
        fi


    #echo az aks stop --resource-group $RESOURCE_GROUP --name $NAME || echo Ignoring any errors stopping cluster
    #-az aks stop --resource-group $RESOURCE_GROUP --name $NAME || echo Ignoring any errors stopping cluster
    done # end_of_cluster_loop
done
