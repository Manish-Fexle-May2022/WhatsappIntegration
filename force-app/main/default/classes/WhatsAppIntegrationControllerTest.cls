/*
    *
        Purpose        :        Test class for WhatsAppIntegrationController methods.

        Created By     :        Manish Kumar Prajapati

        Revision Log   :        v 1.0 — Created

        Modified By    :        
    *
*/
@isTest
private class WhatsAppIntegrationControllerTest {
    
    // Test sending text message
    @isTest
    static void testSendToWhatsAppText() 
    {
        String phoneNumber = '1234567890';
        String message = 'Test message';
        String messageType = 'text';
        String mediaLink = '';
        String mediaCaption = '';
        
        // Set up the mock HTTP response with status code 200
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();        
        String response = WhatsAppIntegrationController.sendToWhatsApp(phoneNumber, message, messageType, mediaLink, mediaCaption);
        Test.stopTest();
        
        
        System.assertNotEquals(null, response, 'Response should not be null');
        
        List<Whats_App_History__c> historyRecords = [SELECT Id, MessageType__c, Message__c FROM Whats_App_History__c];
        System.assertEquals(1, historyRecords.size(), 'Expected one history record to be inserted');
        
        Whats_App_History__c insertedRecord = historyRecords[0];
        System.assertEquals(messageType, insertedRecord.MessageType__c, 'Unexpected message type');
        System.assertEquals(message, insertedRecord.Message__c, 'Unexpected message');
    }
    
    // Test sending image message
    @isTest
    static void testSendToWhatsAppImage() 
    {
        String phoneNumber = '1234567890';
        String messageType = 'image';
        String mediaLink = 'https://example.com/image.jpg';
        String mediaCaption = 'Image caption';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        String response = WhatsAppIntegrationController.sendToWhatsApp(phoneNumber, '', messageType, mediaLink, mediaCaption);
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        
        List<Whats_App_History__c> historyRecords = [SELECT Id,MessageType__c, Message__c, MediaLink__c, MediaCaption__c FROM Whats_App_History__c];
        System.assertEquals(1, historyRecords.size());
        
        Whats_App_History__c insertedRecord = historyRecords[0];
        System.assertEquals(messageType, insertedRecord.MessageType__c);
        System.assertEquals(mediaLink, insertedRecord.MediaLink__c);
        System.assertEquals(mediaCaption, insertedRecord.MediaCaption__c);
    }
    
    // Test sending document message
    @isTest
    static void testSendToWhatsAppDocument() 
    {    
        String phoneNumber = '1234567890';
        String message = 'Document';
        String messageType = 'document';
        String mediaLink = 'https://example.com/document.pdf';
        String mediaCaption = 'Document caption';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        String response = WhatsAppIntegrationController.sendToWhatsApp(phoneNumber, message, messageType, mediaLink, mediaCaption);
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        
        List<Whats_App_History__c> historyRecords = [SELECT Id,MessageType__c, Message__c, MediaLink__c, MediaCaption__c FROM Whats_App_History__c];
        System.assertEquals(1, historyRecords.size());
        
        Whats_App_History__c insertedRecord = historyRecords[0];
        System.assertEquals(messageType, insertedRecord.MessageType__c);
        System.assertEquals(mediaLink, insertedRecord.MediaLink__c);
        System.assertEquals(mediaCaption, insertedRecord.MediaCaption__c);
    }
    
    // Test sending video message
    @isTest
    static void testSendVideoToWhatsApp() 
    {    
        String phoneNumber = '1234567890';
        String message = 'video';
        String messageType = 'video';
        String mediaLink = 'https://example.com/document.mp4';
        String mediaCaption = 'video';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        String response = WhatsAppIntegrationController.sendToWhatsApp(phoneNumber, message, messageType, mediaLink, mediaCaption);
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        
        List<Whats_App_History__c> historyRecords = [SELECT Id,MessageType__c, Message__c, MediaLink__c, MediaCaption__c FROM Whats_App_History__c];
        System.assertEquals(1, historyRecords.size());
        
        Whats_App_History__c insertedRecord = historyRecords[0];
        System.assertEquals(messageType, insertedRecord.MessageType__c);
        System.assertEquals(mediaLink, insertedRecord.MediaLink__c);
        System.assertEquals(mediaCaption, insertedRecord.MediaCaption__c);
    }
    
    
    
    // Test getting public URL
    @isTest
    static void testGetPublicUrl() 
    {
        ContentVersion cv = new ContentVersion(
            Title = 'Test Content',
            VersionData = Blob.valueOf('Test data'),
            PathOnClient = 'Test_File.txt'
        );
        insert cv;
        
        Test.startTest();
        String url = WhatsAppIntegrationController.getPublicUrl(cv.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, url);
    }
    
    // Test querying phone fields
    @isTest
    static void testQueryPhoneFields() 
    {
        Account acc = new Account(Name = 'Test Account', Phone = '1234567890');
        insert acc;
        
        Test.startTest();
        Map<String, Object> result = WhatsAppIntegrationController.queryPhoneFields(acc.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    //Test History according to phone number  
    @isTest
    static void testGetMessageHistoryByPhoneNumber() 
    {
        Whats_App_History__c historyRecord = new Whats_App_History__c(
            PhoneNumber__c = 'TestPhoneNumber',
            MessageType__c = 'Test Type',
            Message__c = 'Test Message',
            MediaLink__c = 'Test Media Link',
            MediaCaption__c = 'Test Media Caption'
        );
        insert historyRecord;
    
        Test.startTest();
        List<Whats_App_History__c> result = WhatsAppIntegrationController.getMessageHistoryByPhoneNumber('TestPhoneNumber');
        Test.stopTest();
 
        System.assertEquals('Test Type', result[0].MessageType__c, 'Unexpected message type');
        System.assertEquals('Test Message', result[0].Message__c, 'Unexpected message');
        System.assertEquals('Test Media Link', result[0].MediaLink__c, 'Unexpected media link');
        System.assertEquals('Test Media Caption', result[0].MediaCaption__c, 'Unexpected media caption');
    }

    
    // Mock HTTP response class to simulate success response
    private class MockHttpResponseGenerator implements HttpCalloutMock 
    {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            return res;
        }
    }
}