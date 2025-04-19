# Azure Flask Test App

A simple Flask application for testing Azure deployment.

## Local Development

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
python test_app.py
```

The application will be available at http://localhost:5000

## Azure Deployment

1. Make sure you have Azure CLI installed and are logged in:
```bash
az login
```

2. Create a resource group (if not exists):
```bash
az group create --name myResourceGroup --location eastus
```

3. Create an App Service plan:
```bash
az appservice plan create --name myAppServicePlan --resource-group myResourceGroup --sku B1 --is-linux
```

4. Create a web app:
```bash
az webapp create --resource-group myResourceGroup --plan myAppServicePlan --name your-app-name --runtime "PYTHON:3.9"
```

5. Deploy the application:
```bash
az webapp deployment source config-local-git --name your-app-name --resource-group myResourceGroup
```

6. Configure the startup command:
```bash
az webapp config set --resource-group myResourceGroup --name your-app-name --startup-file "gunicorn --bind=0.0.0.0 --timeout 600 test_app:app"
```

The application will be available at https://your-app-name.azurewebsites.net 