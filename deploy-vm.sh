#!/bin/bash

# Exit on error
set -e

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to generate a random password
generate_password() {
    openssl rand -base64 10 | tr -dc 'a-zA-Z0-9' | head -c 10
    echo "!A"
}

# Get parameters from parameters.json
RESOURCE_GROUP=$(jq -r '.parameters.resourceGroup.value' parameters.json)
VM_NAME=$(jq -r '.parameters.vmName.value' parameters.json)
LOCATION=$(jq -r '.parameters.location.value' parameters.json)

# Generate random passwords
ADMIN_PASSWORD=$(generate_password)
POSTGRES_PASSWORD=$(generate_password)

# Update parameters.json with generated passwords
jq --arg admin "$ADMIN_PASSWORD" --arg postgres "$POSTGRES_PASSWORD" \
    '.parameters.adminPassword.value = $admin | .parameters.postgresPassword.value = $postgres' \
    parameters.json > parameters.tmp.json && mv parameters.tmp.json parameters.json

# Check if resource group exists
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo "Creating resource group: $RESOURCE_GROUP"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
else
    echo "Resource group $RESOURCE_GROUP already exists"
fi

# Deploy the VM
echo "Deploying to resource group: $RESOURCE_GROUP"
echo "VM Name: $VM_NAME"
echo "Location: $LOCATION"

az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters vmName="$VM_NAME" \
    --parameters location="$LOCATION" \
    --parameters adminPassword="$ADMIN_PASSWORD"

echo "Deployment complete!"
