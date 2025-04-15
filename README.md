# Salesforce AI Agent Integration

This project provides a backend service for generating AI-powered email drafts that can be integrated with Salesforce. The service uses Azure OpenAI and LangChain to generate personalized email content based on lead information.

## Features

- REST API endpoint for generating email drafts
- Integration with Azure OpenAI for AI-powered content generation
- Optional LangSmith integration for monitoring and feedback
- Health check endpoint for monitoring service status

## Prerequisites

- Python 3.8+
- Azure OpenAI API access
- (Optional) LangSmith API access

## Setup

1. Clone the repository:
   ```
   git clone <repository-url>
   cd salesforce-langchain-agent
   ```

2. Create a virtual environment and activate it:
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

4. Create a `.env` file based on the `.env.example` template:
   ```
   cp .env.example .env
   ```

5. Edit the `.env` file with your Azure OpenAI credentials and other configuration.

## Running the Application

### Local Development

Run the Flask application:
```
python app.py
```

The API will be available at http://localhost:5000.

### Testing the API

Run the test script to verify the API is working:
```
python test_api.py
```

## API Endpoints

### Generate Email Draft

**Endpoint:** `/generate_email`

**Method:** POST

**Request Body:**
```json
{
  "firstName": "John",
  "company": "Acme Inc",
  "email": "john@acme.com",
  "feedback": {"score": 1.0, "comment": "Great result"}  // Optional
}
```

**Response:**
```json
{
  "emailDraft": "Dear John from Acme Inc,\n\nThank you for your interest in our services..."
}
```

### Health Check

**Endpoint:** `/health`

**Method:** GET

**Response:**
```json
{
  "status": "healthy"
}
```

## Salesforce Integration

To integrate this service with Salesforce, you'll need to:

1. Create a custom button or Lightning component in Salesforce
2. Configure an Apex callout to this API endpoint
3. Handle the response and display the generated email draft

## Deployment

This application can be deployed to various cloud platforms:

- Azure Functions (recommended)
- AWS Lambda
- Google Cloud Functions
- Heroku

## License

[MIT License](LICENSE)
