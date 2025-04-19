/**
 * EmailGeneratorController.cls
 * 
 * Apex class to handle communication with the AI Email Generator API.
 * This class provides methods to generate email drafts for leads and opportunities.
 */
public with sharing class EmailGeneratorController {
    
    // Get API configuration from Custom Metadata Type
    private static EmailGeneratorSettings__mdt getSettings() {
        EmailGeneratorSettings__mdt[] settings = [
            SELECT API_Endpoint__c, API_Key__c, Timeout_ms__c 
            FROM EmailGeneratorSettings__mdt 
            WHERE DeveloperName = 'Default' 
            LIMIT 1
        ];
        
        if (settings.isEmpty()) {
            throw new AuraHandledException('Email Generator Settings not configured');
        }
        
        // Ensure HTTPS is enforced
        String endpoint = settings[0].API_Endpoint__c;
        if (!endpoint.startsWith('https://')) {
            throw new AuraHandledException('API Endpoint must use HTTPS');
        }
        
        return settings[0];
    }
    
    /**
     * Generates an email draft for a Lead record
     * @param leadId The ID of the Lead record
     * @return Map<String, Object> containing the generated email draft or error information
     */
    @AuraEnabled
    public static Map<String, Object> generateEmailForLead(Id leadId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Query the Lead record
            Lead lead = [SELECT Id, FirstName, LastName, Company, Email 
                         FROM Lead 
                         WHERE Id = :leadId 
                         LIMIT 1];
            
            if (lead == null) {
                throw new AuraHandledException('Lead not found');
            }
            
            // Prepare the request payload
            Map<String, Object> payload = new Map<String, Object>{
                'firstName' => String.isNotBlank(lead.FirstName) ? lead.FirstName : 'Valued Customer',
                'company' => String.isNotBlank(lead.Company) ? lead.Company : '',
                'email' => String.isNotBlank(lead.Email) ? lead.Email : ''
            };
            
            // Make the API callout
            String response = makeApiCallout(JSON.serialize(payload));
            
            // Parse the response
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response);
            
            // Check if the response contains an email draft
            if (responseMap.containsKey('emailDraft')) {
                result.put('success', true);
                result.put('emailDraft', responseMap.get('emailDraft'));
            } else {
                throw new AuraHandledException('Failed to generate email draft: ' + response);
            }
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Error generating email draft: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Generates an email draft for an Opportunity record
     * @param opportunityId The ID of the Opportunity record
     * @return Map<String, Object> containing the generated email draft or error information
     */
    @AuraEnabled
    public static Map<String, Object> generateEmailForOpportunity(Id opportunityId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Query the Opportunity record with related Account and Contact information
            Opportunity opp = [SELECT Id, Name, Account.Name, AccountId, 
                              (SELECT Id, FirstName, LastName, Email 
                               FROM Contacts 
                               WHERE IsPrimary = true 
                               LIMIT 1)
                             FROM Opportunity 
                             WHERE Id = :opportunityId 
                             LIMIT 1];
            
            if (opp == null) {
                throw new AuraHandledException('Opportunity not found');
            }
            
            // Get the primary contact or use account name
            String firstName = 'Valued Customer';
            String company = opp.Account.Name;
            String email = '';
            
            if (!opp.Contacts.isEmpty()) {
                Contact primaryContact = opp.Contacts[0];
                firstName = String.isNotBlank(primaryContact.FirstName) ? primaryContact.FirstName : 'Valued Customer';
                email = String.isNotBlank(primaryContact.Email) ? primaryContact.Email : '';
            }
            
            // Prepare the request payload
            Map<String, Object> payload = new Map<String, Object>{
                'firstName' => firstName,
                'company' => company,
                'email' => email
            };
            
            // Make the API callout
            String response = makeApiCallout(JSON.serialize(payload));
            
            // Parse the response
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response);
            
            // Check if the response contains an email draft
            if (responseMap.containsKey('emailDraft')) {
                result.put('success', true);
                result.put('emailDraft', responseMap.get('emailDraft'));
            } else {
                throw new AuraHandledException('Failed to generate email draft: ' + response);
            }
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Error generating email draft: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Makes an HTTP callout to the API endpoint
     * @param payload JSON string containing the request payload
     * @return String containing the API response
     */
    private static final Integer MAX_RETRIES = 3;
    private static final Integer RETRY_DELAY_MS = 1000; // 1 second
    
    /**
     * Makes an HTTP callout to the API endpoint with retry logic
     * @param payload JSON string containing the request payload
     * @return String containing the API response
     */
    private static String makeApiCallout(String payload) {
        // Get settings
        EmailGeneratorSettings__mdt settings = getSettings();
        
        // Initialize retry counter
        Integer retryCount = 0;
        Exception lastException;
        
        while (retryCount < MAX_RETRIES) {
            try {
                // Create the HTTP request
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(settings.API_Endpoint__c);
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('x-api-key', settings.API_Key__c);
                request.setBody(payload);
                request.setTimeout(Integer.valueOf(settings.Timeout_ms__c));
                
                // Send the request and get the response
                HttpResponse response = http.send(request);
                Integer statusCode = response.getStatusCode();
                
                // Handle different response scenarios
                if (statusCode == 200) {
                    return response.getBody();
                } else if (statusCode == 401) {
                    System.debug(LoggingLevel.ERROR, 'API authentication failed');
                    throw new AuraHandledException('Authentication failed. Please check API configuration.');
                } else if (statusCode == 429) {
                    // Rate limit hit - wait and retry
                    if (retryCount < MAX_RETRIES - 1) {
                        System.debug(LoggingLevel.WARN, 'Rate limit hit, waiting before retry...');
                        sleep(RETRY_DELAY_MS * (retryCount + 1)); // Exponential backoff
                        retryCount++;
                        continue;
                    } else {
                        throw new AuraHandledException('Service is currently busy. Please try again later.');
                    }
                } else {
                    // Log the error but don't expose detailed error message to users
                    System.debug(LoggingLevel.ERROR, 'API callout failed. Status: ' + statusCode + 
                               ', Response: ' + response.getBody());
                    
                    // Retry on 5xx errors
                    if (statusCode >= 500 && retryCount < MAX_RETRIES - 1) {
                        System.debug(LoggingLevel.WARN, 'Server error, retrying...');
                        sleep(RETRY_DELAY_MS * (retryCount + 1));
                        retryCount++;
                        continue;
                    }
                    
                    throw new AuraHandledException('Failed to generate email draft. Please try again later.');
                }
            } catch (System.CalloutException e) {
                lastException = e;
                if (retryCount < MAX_RETRIES - 1) {
                    System.debug(LoggingLevel.WARN, 'Callout failed, retrying... Error: ' + e.getMessage());
                    sleep(RETRY_DELAY_MS * (retryCount + 1));
                    retryCount++;
                    continue;
                }
            }
        }
        
        // If we get here, all retries failed
        System.debug(LoggingLevel.ERROR, 'All retry attempts failed. Last error: ' + lastException?.getMessage());
        throw new AuraHandledException('Unable to connect to email generation service. Please try again later.');
    }
    
    /**
     * Utility method to pause execution
     * @param milliseconds The number of milliseconds to wait
     */
    private static void sleep(Integer milliseconds) {
        Long startTime = System.currentTimeMillis();
        while (System.currentTimeMillis() - startTime < milliseconds) {
            // Simulate sleep in Apex
            continue;
        }
    }
} 




