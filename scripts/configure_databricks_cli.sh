#!/bin/bash

set -e

if [[ -z "$SUBSCRIPTION" ]]; then
    echo "SUBSCRIPTION is not configured"
    exit 1
fi
if [[ -z "$RESOURCE_GROUP" ]]; then
    echo "RESOURCE_GROUP is not configured"
    exit 1
fi
if [[ -z "$DATABRICKS_URL" ]]; then
    echo "DATABRICKS_URL is not specified"
    exit 1
fi
if [[ -z "$DATABRICKS_RESOURCE_NAME" ]]; then
    echo "DATABRICKS_RESOURCE_NAME is not specified"
    exit 1
fi

# Get access tokens using the Azure CLI
export MANAGEMENT_ACCESS_TOKEN=$(az account get-access-token --resource https://management.core.windows.net/ | jq --raw-output '.accessToken')
export ACCESS_TOKEN=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d | jq --raw-output '.accessToken')

# Fetch the admin token
OUTPUT=$(curl -s \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "X-Databricks-Azure-SP-Management-Token: ${MANAGEMENT_ACCESS_TOKEN}" \
    -H "X-Databricks-Azure-Workspace-Resource-Id: /subscriptions/${SUBSCRIPTION}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Databricks/workspaces/${DATABRICKS_RESOURCE_NAME}" \
    "${DATABRICKS_URL}/api/2.0/token/create" \
    -d '{"lifetime_seconds": 21600, "comment": "Token for job deployments"}' \
    ${DATABRICKS_URL}/api/2.0/token/create)

# Set the token
DATABRICKS_TOKEN=$(echo ${OUTPUT} | jq -r .token_value | head -n 1)
printf "[DEFAULT]\nhost = ${DATABRICKS_URL}\ntoken = ${DATABRICKS_TOKEN}" >~/.databrickscfg
