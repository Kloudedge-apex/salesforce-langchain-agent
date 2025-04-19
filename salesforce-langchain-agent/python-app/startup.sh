#!/bin/bash

# Print environment information
echo "Python version:"
python --version

echo "Current directory:"
pwd

echo "Directory contents:"
ls -la

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Start the application
echo "Starting the application..."
gunicorn --bind=0.0.0.0 --timeout 600 app:app 