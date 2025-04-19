#!/bin/bash

# Print environment information for debugging
echo "Python version:"
python --version

echo "Current directory:"
pwd

echo "Directory contents:"
ls -la

# Create and activate virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Start the application with Gunicorn
echo "Starting the application..."
gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 4 --access-logfile '-' --error-logfile '-' app:app 