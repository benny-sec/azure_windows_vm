#!/bin/bash

# Exit on error
set -e

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Generate random 10-char password and append !A
generate_password() {
    openssl rand -base64 10 | tr -dc 'a-zA-Z0-9' | head -c 10
    echo "!A"
}

# Get resource group from parameters.json
RESOURCE_GROUP=$(jq -r '.parameters.resourceGroup.value' parameters.json)
VM_NAME=$(jq -r '.parameters.vmName.value' parameters.json)
LOCATION=$(jq -r '.parameters.location.value' parameters.json)

# Generate passwords
ADMIN_PASSWORD=$(generate_password)
POSTGRES_PASSWORD=$(generate_password)

# Update parameters.json with new passwords
jq --arg admin "$ADMIN_PASSWORD" --arg postgres "$POSTGRES_PASSWORD" \
   '.parameters.adminPassword.value = $admin | .parameters.postgresPassword.value = $postgres' \
   parameters.json > temp.json && mv temp.json parameters.json

# Create resource group if it doesn't exist
echo "Checking if resource group exists..."
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo "Creating resource group: $RESOURCE_GROUP in location: $LOCATION"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
else
    echo "Resource group $RESOURCE_GROUP already exists"
fi

# Deploy using Bicep
echo "Deploying to resource group: $RESOURCE_GROUP"
echo "VM Name: $VM_NAME"
echo "Location: $LOCATION"

# Deploy with generated passwords
az deployment group create \
  --name "vm-deployment-$(date +%s)" \
  --resource-group "$RESOURCE_GROUP" \
  --template-file main.bicep \
  --parameters vmName="$VM_NAME" \
  --parameters location="$LOCATION" \
  --parameters adminPassword="$ADMIN_PASSWORD" \
  --parameters postgresPassword="$POSTGRES_PASSWORD"

echo "Deployment completed!"