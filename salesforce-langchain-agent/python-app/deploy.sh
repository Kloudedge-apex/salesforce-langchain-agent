#!/bin/bash

# Build and deploy to Azure
echo "Building and deploying to Azure..."

# Install dependencies
pip install -r requirements.txt

# Run the application locally first to test
echo "Testing application locally..."
python test_app.py 