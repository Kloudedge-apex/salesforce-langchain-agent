#!/bin/bash

# Exit on error
set -e

# Configuration
RESOURCE_GROUP="salesforce-ai-agent"
LOCATION="eastus"
FUNCTION_APP="salesforce-agent"
FUNCTION_APP_PLAN="salesforce-agent-plan"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting deployment of Salesforce AI Agent to Azure Functions...${NC}"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Azure CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if Function Core Tools is installed
if ! command -v func &> /dev/null; then
    echo -e "${RED}Azure Functions Core Tools is not installed. Please install it first.${NC}"
    echo "Visit: https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local"
    exit 1
fi

# Check if user is logged in to Azure
echo -e "${YELLOW}Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Please log in...${NC}"
    az login
fi

# Create resource group if it doesn't exist
echo -e "${YELLOW}Creating resource group if it doesn't exist...${NC}"
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create function app plan if it doesn't exist
echo -e "${YELLOW}Creating function app plan...${NC}"
az functionapp plan create --name $FUNCTION_APP_PLAN --resource-group $RESOURCE_GROUP --location $LOCATION --sku B1 --is-linux

# Create function app if it doesn't exist
echo -e "${YELLOW}Creating function app...${NC}"
az functionapp create --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --plan $FUNCTION_APP_PLAN --runtime python --runtime-version 3.9 --functions-version 4 --os-type linux

# Configure app settings
echo -e "${YELLOW}Configuring app settings...${NC}"

# Check if .env file exists
if [ -f .env ]; then
    echo -e "${YELLOW}Found .env file. Using it to configure app settings...${NC}"
    
    # Read .env file and set app settings
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        if [[ $line =~ ^#.*$ ]] || [[ -z $line ]]; then
            continue
        fi
        
        # Extract key and value
        key=$(echo $line | cut -d '=' -f 1)
        value=$(echo $line | cut -d '=' -f 2-)
        
        # Set app setting
        az functionapp config appsettings set --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --settings "$key=$value"
    done < .env
else
    echo -e "${RED}No .env file found. Please create one with the following required settings:${NC}"
    echo -e "  - AZURE_OPENAI_ENDPOINT"
    echo -e "  - AZURE_OPENAI_KEY"
    echo -e "  - AZURE_OPENAI_API_VERSION"
    echo -e "  - AZURE_OPENAI_DEPLOYMENT"
    exit 1
fi

# Deploy the function app
echo -e "${YELLOW}Deploying function app...${NC}"
func azure functionapp publish $FUNCTION_APP

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}Function App URL: https://$FUNCTION_APP.azurewebsites.net${NC}" 