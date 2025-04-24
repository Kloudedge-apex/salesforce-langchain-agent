from flask import Flask, request, jsonify
import os
import json
import logging
import re
import sys
import platform
from dotenv import load_dotenv
from openai import AzureOpenAI, APIError

# Load environment variables from .env file if it exists
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Initialize Azure OpenAI client at the application level
try:
    client = AzureOpenAI(
        api_key=os.environ.get("AZURE_OPENAI_KEY"),
        api_version=os.environ.get("AZURE_OPENAI_API_VERSION"),
        azure_endpoint=os.environ.get("AZURE_OPENAI_ENDPOINT")
    )
    logger.info("Azure OpenAI client initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize Azure OpenAI client: {e}", exc_info=True)
    client = None

def convert_to_html(text):
    """Convert markdown-like text to HTML"""
    # Replace markdown headers
    html = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', text)
    
    # Replace markdown links
    html = re.sub(r'\[(.*?)\]\((.*?)\)', r'<a href="\2">\1</a>', html)
    
    # Replace newlines with <br> tags
    html = html.replace('\n', '<br>')
    
    # Replace double <br> with paragraph breaks
    html = html.replace('<br><br>', '</p><p>')
    
    # Wrap in paragraph tags
    html = f'<p>{html}</p>'
    
    return html

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
    if client is None:
        return jsonify({"error": "Azure OpenAI client not properly initialized"}), 500

    logger.info("Processing request for email draft generation")
    
    # Parse the incoming JSON payload
    try:
        req_body = request.get_json()
        if not req_body:
            raise ValueError("Empty request body")
    except Exception as e:
        logger.error(f"Invalid JSON payload: {e}")
        return jsonify({"error": "Invalid JSON payload", "details": str(e)}), 400
    
    first_name = req_body.get("firstName", "Valued Customer")
    company = req_body.get("company", "")
    email = req_body.get("email", "")
    feedback = req_body.get("feedback", {})
    format_type = req_body.get("format", "text")  # Default to text format
    
    azure_openai_deployment = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4")
    
    # Build the prompt for generating the email draft
    prompt = f"Compose a professional email addressed to {first_name}"
    if company:
        prompt += f" from {company}"
    prompt += (
        ", thanking them for their interest in our services and inviting them to schedule a meeting "
        "for further discussion. Ensure the tone is friendly and professional."
    )
    
    # Add feedback information if available
    if feedback and isinstance(feedback, dict):
        score = feedback.get("score")
        comment = feedback.get("comment")
        if score is not None:
            prompt += f" The customer provided a feedback score of {score} out of 5."
        if comment:
            prompt += f" Their comment was: '{comment}'"
    
    # Generate the email draft
    try:
        response = client.chat.completions.create(
            model=azure_openai_deployment,
            messages=[
                {"role": "system", "content": "You are a professional email writer for a sales team. Create concise, personalized emails that maintain a professional tone while being friendly and engaging. Include a clear call to action."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=300
        )
        
        if not response.choices:
            raise ValueError("No response choices returned from the API")
            
        email_draft = response.choices[0].message.content
        if not email_draft:
            raise ValueError("Received an empty response from the LLM")
            
        logger.info("Email draft generated successfully")
        
    except APIError as e:
        logger.error(f"Azure OpenAI API error: {e}", exc_info=True)
        return jsonify({"error": "Azure OpenAI API error", "details": str(e)}), 500
    except Exception as e:
        logger.error(f"Error generating email draft: {e}", exc_info=True)
        return jsonify({"error": "Failed to generate email draft", "details": str(e)}), 500
    
    # Return the generated email draft
    result = {"emailDraft": email_draft}
    
    # Add HTML version if requested
    if format_type == "html":
        result["emailDraftHtml"] = convert_to_html(email_draft)
    
    return jsonify(result), 200

@app.route('/health', methods=['GET'])
def health_check():
    """Simple health check endpoint"""
    return jsonify({"status": "healthy"}), 200

@app.route('/', methods=['GET'])
def home():
    """Home endpoint"""
    return jsonify({
        "status": "running",
        "endpoints": {
            "health": "/health",
            "generate_email": "/generate_email",
            "diagnostic": "/diagnostic"
        }
    }), 200

@app.route('/diagnostic', methods=['GET'])
def diagnostic():
    """Diagnostic endpoint to help troubleshoot issues"""
    try:
        # System information
        system_info = {
            "python_version": sys.version,
            "platform": platform.platform(),
            "cwd": os.getcwd(),
            "files": os.listdir("."),
            "env_vars": {k: v for k, v in os.environ.items() if "key" not in k.lower() and "secret" not in k.lower()}
        }
        
        # Check if required packages are installed
        try:
            import openai
            openai_version = openai.__version__
        except ImportError:
            openai_version = "Not installed"
        
        try:
            import flask
            flask_version = flask.__version__
        except ImportError:
            flask_version = "Not installed"
        
        try:
            import gunicorn
            gunicorn_version = gunicorn.__version__
        except ImportError:
            gunicorn_version = "Not installed"
        
        packages = {
            "openai": openai_version,
            "flask": flask_version,
            "gunicorn": gunicorn_version
        }
        
        return jsonify({
            "status": "diagnostic",
            "system_info": system_info,
            "packages": packages
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "error": str(e)
        }), 500

if __name__ == '__main__':
    # For local development
    port = int(os.environ.get("PORT", 5001))
    app.run(debug=True, host='0.0.0.0', port=port) 