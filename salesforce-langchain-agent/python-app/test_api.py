import requests
import json
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# API endpoint
API_URL = "http://localhost:5000/generate_email"

def test_email_generation():
    """Test the email generation endpoint"""
    print("Testing email generation endpoint...")
    
    # Sample payload
    payload = {
        "firstName": "John",
        "company": "Acme Inc",
        "email": "john@acme.com"
    }
    
    try:
        # Make the API request
        response = requests.post(
            API_URL,
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        
        # Check if the request was successful
        if response.status_code == 200:
            result = response.json()
            print("\nEmail Draft:")
            print("-" * 50)
            print(result.get("emailDraft", "No email draft returned"))
            print("-" * 50)
        else:
            print(f"Error: {response.status_code}")
            print(response.text)
    
    except Exception as e:
        print(f"Error making request: {e}")

def test_health_check():
    """Test the health check endpoint"""
    print("\nTesting health check endpoint...")
    
    try:
        response = requests.get("http://localhost:5000/health")
        
        if response.status_code == 200:
            print("Health check passed!")
            print(response.json())
        else:
            print(f"Health check failed: {response.status_code}")
            print(response.text)
    
    except Exception as e:
        print(f"Error making health check request: {e}")

if __name__ == "__main__":
    print("Starting API tests...")
    test_health_check()
    test_email_generation()
    print("\nTests completed.") 