import logging
import os
import json
import azure.functions as func
from time import time
from collections import defaultdict

# For local development, load environment variables from a .env file if available.
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # In production, Application Settings are used.

# Import the OpenAI LLM from LangChain v0.3.23.
from langchain_community.llms import OpenAI

# Attempt to import LangSmith tracer from LangChain.
try:
    from langchain.callbacks.tracers.langsmith import LangSmithTracer
except ImportError:
    LangSmithTracer = None

# Later, for feedback logging, import LangSmith Client.
try:
    from langsmith import Client as LangSmithClient
except ImportError:
    LangSmithClient = None

# Simple rate limiter using in-memory storage
# In production, use Redis or similar for distributed rate limiting
class RateLimiter:
    def __init__(self, requests_per_minute=60):
        self.requests_per_minute = requests_per_minute
        self.requests = defaultdict(list)
        
    def is_allowed(self, api_key: str) -> bool:
        now = time()
        minute_ago = now - 60
        
        # Clean up old requests
        self.requests[api_key] = [req_time for req_time in self.requests[api_key] if req_time > minute_ago]
        
        # Check if under limit
        if len(self.requests[api_key]) < self.requests_per_minute:
            self.requests[api_key].append(now)
            return True
        return False

# Initialize rate limiter
rate_limiter = RateLimiter(requests_per_minute=int(os.environ.get("RATE_LIMIT_PER_MINUTE", "60")))

def validate_api_key(req: func.HttpRequest) -> bool:
    """Validate the API key from the request header."""
    expected_key = os.environ.get("API_KEY")
    if not expected_key:
        logging.error("API_KEY environment variable not configured")
        return False
        
    request_key = req.headers.get("x-api-key")
    return request_key == expected_key

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Processing HTTP request for email draft generation with LangChain and LangSmith.")
    
    # Validate API key
    api_key = req.headers.get("x-api-key")
    if not validate_api_key(req):
        return func.HttpResponse(
            json.dumps({"error": "Unauthorized"}),
            status_code=401,
            mimetype="application/json"
        )
    
    # Check rate limit
    if not rate_limiter.is_allowed(api_key):
        return func.HttpResponse(
            json.dumps({"error": "Rate limit exceeded. Please try again later."}),
            status_code=429,
            mimetype="application/json"
        )

    # Parse the incoming JSON payload.
    try:
        req_body = req.get_json()
    except Exception as e:
        logging.error("Invalid JSON payload: %s", e)
        return func.HttpResponse(
            json.dumps({"error": "Invalid JSON payload."}),
            status_code=400,
            mimetype="application/json"
        )

    first_name = req_body.get("firstName", "Valued Customer")

    # Retrieve Azure OpenAI configuration from environment variables.
    azure_openai_endpoint = os.environ.get("AZURE_OPENAI_ENDPOINT")
    azure_openai_key = os.environ.get("AZURE_OPENAI_KEY")
    azure_openai_api_version = os.environ.get("AZURE_OPENAI_API_VERSION", "2023-12-01-preview")
    azure_openai_deployment = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4")

    if not (azure_openai_endpoint and azure_openai_key):
        error_msg = "Missing required environment variables for Azure OpenAI configuration."
        logging.error(error_msg)
        return func.HttpResponse(
            json.dumps({"error": error_msg}),
            status_code=500,
            mimetype="application/json"
        )

    # Initialize the LangSmith tracer if LANGSMITH_API_KEY is provided.
    langsmith_api_key = os.environ.get("LANGSMITH_API_KEY")
    tracer = None
    if langsmith_api_key and LangSmithTracer:
        try:
            tracer = LangSmithTracer(
                experiment_name="Salesforce_Agent_Email_Generation",
                run_name=f"EmailDraft_for_{first_name}",
                api_key=langsmith_api_key
            )
            logging.info("LangSmith tracer initialized.")
        except Exception as e:
            logging.warning("Failed to initialize LangSmith tracer: %s", e)

    # Instantiate the LLM using the OpenAI class (v0.3.23) with Azure-specific parameters.
    try:
        llm = OpenAI(
            deployment_name=azure_openai_deployment,
            openai_api_base=azure_openai_endpoint,
            openai_api_key=azure_openai_key,
            openai_api_version=azure_openai_api_version,
            temperature=0.7,
            max_tokens=150,
            callbacks=[tracer] if tracer else None
        )
    except Exception as e:
        logging.error("Error instantiating OpenAI LLM: %s", e, exc_info=True)
        return func.HttpResponse(
            json.dumps({"error": "Failed to initialize LLM.", "details": str(e)}),
            status_code=500,
            mimetype="application/json"
        )

    # Build the prompt for generating the email draft.
    prompt = (
        f"Compose a professional email addressed to {first_name}, thanking them for their interest "
        "in our services and inviting them to schedule a meeting for further discussion. "
        "Ensure the tone is friendly and professional."
    )

    # Generate the email draft.
    try:
        email_draft = llm(prompt)
        if not email_draft:
            raise ValueError("Received an empty response from the LLM.")
        logging.info("Email draft generated successfully.")
    except Exception as e:
        logging.error("Error generating email draft: %s", e, exc_info=True)
        return func.HttpResponse(
            json.dumps({"error": "Failed to generate email draft.", "details": str(e)}),
            status_code=500,
            mimetype="application/json"
        )

    # Optionally, log user feedback if provided in the request.
    # Expecting feedback data in the JSON payload (e.g., {"feedback": {"score": 1.0, "comment": "Great result"}})
    feedback_data = req_body.get("feedback")
    if feedback_data and LangSmithClient and tracer and hasattr(tracer, "run_id"):
        try:
            client = LangSmithClient(api_key=langsmith_api_key)
            run_id = tracer.run_id  # Assumes tracer captures a run_id after execution.
            client.create_feedback(
                run_id,
                key="email-generation",
                score=feedback_data.get("score", 1.0),
                comment=feedback_data.get("comment", "No comment provided.")
            )
            logging.info("User feedback logged successfully.")
        except Exception as fe:
            logging.error("Failed to log user feedback: %s", fe)

    result = {"emailDraft": email_draft}
    return func.HttpResponse(
        json.dumps(result),
        status_code=200,
        mimetype="application/json"
    )


# Local testing block.
if __name__ == '__main__':
    # Define a dummy HTTP request class for local testing.
    class DummyHttpRequest(func.HttpRequest):
        def __init__(self, body: str):
            super().__init__(method="POST", url="http://localhost", headers={}, body=body.encode("utf-8"))
        def get_json(self):
            return json.loads(self.get_body().decode("utf-8"))

    # Create sample data including optional feedback.
    sample_data = json.dumps({
        "firstName": "Alice",
        "feedback": {"score": 1.0, "comment": "Great result"}
    })
    
    # Create a dummy request and process it.
    dummy_request = DummyHttpRequest(sample_data)
    response = main(dummy_request)
    
    # Print the response.
    print(f"Status Code: {response.status_code}")
    print(f"Response Body: {response.get_body().decode('utf-8')}") 


