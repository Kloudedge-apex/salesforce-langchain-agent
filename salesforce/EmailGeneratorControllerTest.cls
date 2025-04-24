@IsTest
private class EmailGeneratorControllerTest {
    @TestSetup
    static void setup() {
        // Create test metadata
        EmailGeneratorSettings__mdt settings = new EmailGeneratorSettings__mdt(
            DeveloperName = 'Default',
            API_Endpoint__c = 'https://test-api.example.com',
            API_Key__c = 'test-api-key',
            Timeout_ms__c = 30000
        );
        
        // Create test Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@example.com'
        );
        insert testLead;
        
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Create test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com',
            AccountId = testAccount.Id,
            IsPrimary = true
        );
        insert testContact;
        
        // Create test Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
    }
    
    @IsTest
    static void testGenerateEmailForLead_Success() {
        // Get test lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new EmailGeneratorMock(200, '{"emailDraft": "Test email draft"}'));
        
        Test.startTest();
        Map<String, Object> result = EmailGeneratorController.generateEmailForLead(testLead.Id);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(true, result.get('success'), 'Should return success');
        System.assertEquals('Test email draft', result.get('emailDraft'), 'Should return correct email draft');
    }
    
    @IsTest
    static void testGenerateEmailForLead_Error() {
        // Get test lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Set mock callout response for error
        Test.setMock(HttpCalloutMock.class, new EmailGeneratorMock(500, '{"error": "Internal server error"}'));
        
        Test.startTest();
        Map<String, Object> result = EmailGeneratorController.generateEmailForLead(testLead.Id);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertNotEquals(null, result.get('error'), 'Should return error message');
    }
    
    @IsTest
    static void testGenerateEmailForOpportunity_Success() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new EmailGeneratorMock(200, '{"emailDraft": "Test email draft"}'));
        
        Test.startTest();
        Map<String, Object> result = EmailGeneratorController.generateEmailForOpportunity(testOpp.Id);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(true, result.get('success'), 'Should return success');
        System.assertEquals('Test email draft', result.get('emailDraft'), 'Should return correct email draft');
    }
    
    @IsTest
    static void testGenerateEmailForOpportunity_Error() {
        // Get test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set mock callout response for error
        Test.setMock(HttpCalloutMock.class, new EmailGeneratorMock(500, '{"error": "Internal server error"}'));
        
        Test.startTest();
        Map<String, Object> result = EmailGeneratorController.generateEmailForOpportunity(testOpp.Id);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(false, result.get('success'), 'Should return failure');
        System.assertNotEquals(null, result.get('error'), 'Should return error message');
    }
    
    @IsTest
    static void testInvalidRecordId() {
        Test.startTest();
        Map<String, Object> result = EmailGeneratorController.generateEmailForLead('00Q000000000000');
        Test.stopTest();
        
        // Verify results
        System.assertEquals(false, result.get('success'), 'Should return failure for invalid ID');
        System.assertNotEquals(null, result.get('error'), 'Should return error message');
    }
    
    // Mock class for HTTP callouts
    private class EmailGeneratorMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        
        public EmailGeneratorMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
        
        public HTTPResponse respond(HTTPRequest request) {
            HTTPResponse response = new HTTPResponse();
            response.setStatusCode(statusCode);
            response.setBody(body);
            return response;
        }
    }
} 