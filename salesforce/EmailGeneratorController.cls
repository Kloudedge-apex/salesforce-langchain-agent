/**
 * EmailGeneratorController.cls
 * 
 * Apex class to handle communication with the AI Email Generator API.
 * This class provides methods to generate email drafts for leads and opportunities.
 */
public with sharing class EmailGeneratorController {
    
    // API endpoint URL - should be configured in Custom Setting or Custom Metadata
    private static final String API_ENDPOINT = 'http://localhost:5000/generate_email';
    
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
    private static String makeApiCallout(String payload) {
        // Create the HTTP request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(API_ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(payload);
        request.setTimeout(120000); // 2-minute timeout
        
        // Send the request and get the response
        HttpResponse response = http.send(request);
        
        // Check if the request was successful
        if (response.getStatusCode() == 200) {
            return response.getBody();
        } else {
            throw new AuraHandledException('API callout failed with status code: ' + response.getStatusCode() + 
                                          ', Response: ' + response.getBody());
        }
    }
} 