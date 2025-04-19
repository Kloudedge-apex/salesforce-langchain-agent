# Flask Application for Azure Deployment

This is a Flask application configured for deployment on Azure App Service.

## Local Development

### Option 1: Using Docker (Recommended)

1. Make sure you have Docker and Docker Compose installed
2. Build and run the container:
   ```bash
   docker-compose up --build
   ```
3. The application will be available at http://localhost:8000

### Option 2: Traditional Setup

1. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run the application:
   ```bash
   python app.py
   ```

## Azure Deployment

### Option 1: Deploy using Azure Container Registry (Recommended)

1. Create an Azure Container Registry:
   ```bash
   az acr create --name <registry-name> --resource-group <resource-group> --sku Basic --admin-enabled true
   ```

2. Build and push the Docker image:
   ```bash
   az acr build --registry <registry-name> --image salesforce-agent:latest .
   ```

3. Create an App Service with Container support:
   ```bash
   az webapp create --resource-group <resource-group> --plan <app-service-plan> --name <app-name> --deployment-container-image-name <registry-name>.azurecr.io/salesforce-agent:latest
   ```

4. Configure the App Service to use the container:
   ```bash
   az webapp config container set --name <app-name> --resource-group <resource-group> --docker-custom-image-name <registry-name>.azurecr.io/salesforce-agent:latest --docker-registry-server-url https://<registry-name>.azurecr.io
   ```

### Option 2: Traditional Azure Deployment

1. Login to Azure CLI:
   ```bash
   az login
   ```

2. Create a resource group (if not exists):
   ```bash
   az group create --name <resource-group> --location <location>
   ```

3. Create an App Service plan:
   ```bash
   az appservice plan create --name <app-service-plan> --resource-group <resource-group> --sku B1 --is-linux
   ```

4. Create a web app:
   ```bash
   az webapp create --resource-group <resource-group> --plan <app-service-plan> --name <app-name> --runtime "PYTHON:3.11"
   ```

5. Deploy the application:
   ```bash
   az webapp deployment source config-zip --resource-group <resource-group> --name <app-name> --src <path-to-zip-file>
   ```

6. Configure the startup command in Azure Portal:
   - Go to Configuration > General settings
   - Set Startup Command to: `./startup.sh`

## Environment Variables

Make sure to set the following environment variables in Azure App Service Configuration:

- `PORT`: The port number (default: 8000)
- `PYTHON_VERSION`: Python version (3.11)
- Add any other required environment variables for your application

## Troubleshooting

1. Check the application logs in Azure Portal
2. Verify the startup command is correctly set
3. Ensure all environment variables are properly configured
4. Check if the Python version matches your requirements 