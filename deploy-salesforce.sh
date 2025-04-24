#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting deployment of Salesforce Email Generator components...${NC}"

# Check if Salesforce CLI is installed
if ! command -v sf &> /dev/null; then
    echo -e "${RED}Salesforce CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://developer.salesforce.com/tools/sfdxcli"
    exit 1
fi

# Check if user is logged in to Salesforce
echo -e "${YELLOW}Checking Salesforce login status...${NC}"
if ! sf org list | grep -q "active"; then
    echo -e "${YELLOW}Not logged in to Salesforce. Please log in...${NC}"
    sf org login web -d
fi

# Deploy the components
echo -e "${YELLOW}Deploying components to Salesforce...${NC}"
sf project deploy start --source-dir force-app/main/default --test-level RunLocalTests

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${YELLOW}Please configure the Email Generator Settings in your org:${NC}"
echo -e "1. Go to Setup > Custom Metadata Types > Email Generator Settings > Manage Records"
echo -e "2. Create a new record with DeveloperName = 'Default'"
echo -e "3. Set the API_Endpoint__c to your Azure Function URL"
echo -e "4. Set the API_Key__c to your API key"
echo -e "5. Set the Timeout_ms__c to 30000 (or your preferred timeout)" 