#!/bin/bash

set -e

if [[ -z "$SCOPE_NAME" ]]; then
  echo "SCOPE_NAME is not configured"
  exit 1
fi

if [[ -z "$CLIENT_SECRET" ]]; then
  echo "CLIENT_SECRET is not configured"
  exit 1
fi

# Create secret scope if it doesn't exist
if [[ -z $(databricks secrets list-scopes | grep "$SCOPE_NAME") ]]; then
  echo "Creating secret scope: $SCOPE_NAME"
  databricks secrets create-scope --scope "$SCOPE_NAME"
fi

# Create/update client secret
echo "Creating/updating client secret within scope $SCOPE_NAME..."
databricks secrets write --scope "$SCOPE_NAME" --key "client_secret" --string-value "$CLIENT_SECRET"

echo "Listing secrets in scope $SCOPE_NAME"
databricks secrets list --scope "$SCOPE_NAME"
