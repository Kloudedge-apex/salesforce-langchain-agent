@IsTest
public class EmailGeneratorControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test lead
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company',
            Email = 'john.doe@test.com'
        );
        insert testLead;
    }
    
    @IsTest
    static void testSuccessfulEmailGeneration() {
        // Set up test settings
        EmailGeneratorSettings__mdt testSettings = new EmailGeneratorSettings__mdt(
            API_Endpoint__c = 'https://test.endpoint.com',
            API_Key__c = 'test-key',
            Timeout_ms__c = 5000
        );
        EmailGeneratorController.testSettings = testSettings;
        
        // Get test lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Set up the mock callout
        Test.setMock(HttpCalloutMock.class, new EmailGeneratorMock());
        
        Test.startTest();
        Map<String, Object> result = EmailGeneratorController.generateEmailForLead(testLead.Id);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(true, result.get('success'), 'Should return success');
        System.assertNotEquals(null, result.get('emailDraft'), 'Should return email draft');
    }
    
    @IsTest
    static void testMissingSettings() {
        Test.startTest();
        try {
            Map<String, Object> result = EmailGeneratorController.generateEmail('Test Lead', 'Test Company', 'test@example.com');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertEquals('Email Generator Settings not configured', e.getMessage(), 'Error message should match');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testInvalidEndpoint() {
        // Set up test settings with invalid endpoint
        EmailGeneratorSettings__mdt testSettings = new EmailGeneratorSettings__mdt(
            API_Endpoint__c = 'http://test.endpoint.com', // Not HTTPS
            API_Key__c = 'test-key',
            Timeout_ms__c = 5000
        );
        EmailGeneratorController.testSettings = testSettings;
        
        // Get test lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = EmailGeneratorController.generateEmailForLead(testLead.Id);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('API Endpoint must use HTTPS', result.get('error'), 
            'Should return HTTPS requirement error');
    }
    
    @IsTest
    static void testMissingLead() {
        // Set up test settings
        EmailGeneratorSettings__mdt testSettings = new EmailGeneratorSettings__mdt(
            API_Endpoint__c = 'https://test.endpoint.com',
            API_Key__c = 'test-key',
            Timeout_ms__c = 5000
        );
        EmailGeneratorController.testSettings = testSettings;
        
        // Delete all test leads to ensure we have a missing lead scenario
        delete [SELECT Id FROM Lead];
        
        // Use the ID of a deleted lead
        Lead deletedLead = new Lead(
            FirstName = 'Deleted',
            LastName = 'Lead',
            Company = 'Deleted Company'
        );
        insert deletedLead;
        Id deletedLeadId = deletedLead.Id;
        delete deletedLead;
        
        Test.startTest();
        Map<String, Object> result = EmailGeneratorController.generateEmailForLead(deletedLeadId);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertEquals('Lead not found', result.get('error'), 'Should return lead not found error');
    }
    
    // Mock class for HTTP callouts
    private class EmailGeneratorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"emailDraft": "Test email draft"}');
            return res;
        }
    }
} 