#!/bin/bash

# Exit on error
set -e

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get resource group from parameters.json
RESOURCE_GROUP=$(jq -r '.parameters.resourceGroup.value' parameters.json)
VM_NAME=$(jq -r '.parameters.vmName.value' parameters.json)
LOCATION=$(jq -r '.parameters.location.value' parameters.json)

# Generate random 10-char password and append !A
generate_password() {
    openssl rand -base64 10 | tr -dc 'a-zA-Z0-9' | head -c 10
    echo "!A"
}

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

# Create DSC package
echo "Creating DSC package..."
cd "$SCRIPT_DIR"
rm -f dsc.zip  # Remove old zip if exists
cp dsc/VMSoftwareConfig.ps1 dsc/config.ps1  # Create a copy with shorter name
zip -r dsc.zip dsc/config.ps1  # Only zip the renamed file
rm dsc/config.ps1  # Clean up the temporary file

# Read the zip file content as base64
DSC_ZIP_BASE64=$(base64 -w 0 dsc.zip)

# Deploy using Bicep
echo "Deploying to resource group: $RESOURCE_GROUP"
echo "VM Name: $VM_NAME"
echo "Location: $LOCATION"

# Deploy with DSC configuration
az deployment group create \
  --name "vm-deployment-$(date +%s)" \
  --resource-group "$RESOURCE_GROUP" \
  --template-file main.bicep \
  --parameters vmName="$VM_NAME" \
  --parameters location="$LOCATION" \
  --parameters adminPassword="$ADMIN_PASSWORD" \
  --parameters postgresPassword="$POSTGRES_PASSWORD" \
  --parameters dscConfiguration="$DSC_ZIP_BASE64"

echo "Deployment completed!"