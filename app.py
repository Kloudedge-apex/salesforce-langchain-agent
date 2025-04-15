from flask import Flask, request, jsonify
import os
import json
import logging
from dotenv import load_dotenv
from langchain_community.llms import OpenAI

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/generate_email', methods=['POST'])
def generate_email():
    """
    Endpoint to generate an email draft based on lead information.
    Expected JSON payload:
    {
        "firstName": "John",
        "company": "Acme Inc",
        "email": "john@acme.com",
        "feedback": {"score": 1.0, "comment": "Great result"}  # Optional
    }
    """
    logger.info("Processing request for email draft generation")
    
    # Parse the incoming JSON payload
    try:
        req_body = request.get_json()
    except Exception as e:
        logger.error(f"Invalid JSON payload: {e}")
        return jsonify({"error": "Invalid JSON payload."}), 400
    
    first_name = req_body.get("firstName", "Valued Customer")
    company = req_body.get("company", "")
    email = req_body.get("email", "")
    
    # Retrieve Azure OpenAI configuration from environment variables
    azure_openai_endpoint = os.environ.get("AZURE_OPENAI_ENDPOINT")
    azure_openai_key = os.environ.get("AZURE_OPENAI_KEY")
    azure_openai_api_version = os.environ.get("AZURE_OPENAI_API_VERSION", "2024-12-01-preview")
    azure_openai_deployment = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4")
    
    if not (azure_openai_endpoint and azure_openai_key):
        error_msg = "Missing required environment variables for Azure OpenAI configuration."
        logger.error(error_msg)
        return jsonify({"error": error_msg}), 500
    
    # Instantiate the LLM using the OpenAI class
    try:
        llm = OpenAI(
            deployment_name=azure_openai_deployment,
            openai_api_base=azure_openai_endpoint,
            openai_api_key=azure_openai_key,
            openai_api_version=azure_openai_api_version,
            temperature=0.7,
            max_tokens=150
        )
    except Exception as e:
        logger.error(f"Error instantiating OpenAI LLM: {e}", exc_info=True)
        return jsonify({"error": "Failed to initialize LLM.", "details": str(e)}), 500
    
    # Build the prompt for generating the email draft
    prompt = (
        f"Compose a professional email addressed to {first_name}"
    )
    
    if company:
        prompt += f" from {company}"
    
    prompt += (
        ", thanking them for their interest in our services and inviting them to schedule a meeting "
        "for further discussion. Ensure the tone is friendly and professional."
    )
    
    # Generate the email draft
    try:
        email_draft = llm(prompt)
        if not email_draft:
            raise ValueError("Received an empty response from the LLM.")
        logger.info("Email draft generated successfully.")
    except Exception as e:
        logger.error(f"Error generating email draft: {e}", exc_info=True)
        return jsonify({"error": "Failed to generate email draft.", "details": str(e)}), 500
    
    # Return the generated email draft
    result = {"emailDraft": email_draft}
    return jsonify(result), 200

@app.route('/health', methods=['GET'])
def health_check():
    """Simple health check endpoint"""
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    # For local development
    app.run(debug=True, host='0.0.0.0', port=5000) 