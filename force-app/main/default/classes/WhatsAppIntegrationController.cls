/*
    *
        Purpose        :        Controller class to handle WhatsApp integration functionalities.

        Created By     :        Manish Kumar Prajapati

        Revision Log   :        v 1.0 — Created

        Modified By    :        
    *
*/
public with sharing class WhatsAppIntegrationController 
{
/*
    *
        Purpose        :        This method is using for sending messages via WhatsApp. It create a JSON payload based on the message type (text, image, document) 
                                and makes an HTTP callout to the WhatsApp API.
        Created By     :        Manish Kumar Prajapati
        Revision Log   :        v 1.0 — Created
        Modified By    :        
    *
*/
    @AuraEnabled(cacheable=true)
    public static String sendToWhatsApp(String phoneNumber, String message, String messageType, String mediaLink, String mediaCaption) 
    {
        String permanentAccessToken = System.Label.WhatsApp_Permanent_AccessToken;
        // Create the JSON payload based on the message type
        String payload = '';
        if (messageType == WhatsAppIntegrationConstant.TEXT) {
            payload = '{"messaging_product": "whatsapp", "to": "' + phoneNumber + '", "type": "text", "text": { "preview_url": false, "body": "' + message +'" }}';
            system.debug('Payload: '+ payload);
        } else if (messageType == WhatsAppIntegrationConstant.IMAGE) {
            payload = '{"messaging_product": "whatsapp", "to": "' + phoneNumber + '", "type": "image", "image": {"link":"' + mediaLink + '"}}';
            system.debug('Payload: '+ payload);
        } else if (messageType == WhatsAppIntegrationConstant.DOCUMENT) {
            payload = '{"messaging_product": "whatsapp", "to": "' + phoneNumber + '", "type": "document", "document": {"link": "' + mediaLink + '", "caption": "' + mediaCaption + '", "filename": "' + message + '"}}';
            system.debug('Payload: '+ payload);
        }
         else {
            payload = '{"messaging_product": "whatsapp", "to": "' + phoneNumber + '", "type": "video", "video": {"link":"' + mediaLink + '"}}';
            system.debug('Payload: '+ payload);
        }
        
        // Make the HTTP callout to the WhatsApp API
        HttpRequest req = new HttpRequest();
        req.setEndpoint(WhatsAppIntegrationConstant.API_URL);
        req.setMethod(WhatsAppIntegrationConstant.POST_METHOD);
        req.setHeader(WhatsAppIntegrationConstant.CONTENT_TYPE, WhatsAppIntegrationConstant.APPLICATION_JSON);
        req.setHeader(WhatsAppIntegrationConstant.AUTHORIZATION, WhatsAppIntegrationConstant.BEARER + permanentAccessToken);
        req.setBody(payload);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        // Log the response from the WhatsApp API
        System.debug('WhatsApp API Response: ' + res.getBody());
        if(res.getStatusCode() == 200) {
            Whats_App_History__c historyRecord = new Whats_App_History__c();
            historyRecord.PhoneNumber__c = phoneNumber;
            historyRecord.Message__c = message;
            historyRecord.Timestamp__c = System.now();            
            if(String.isNotBlank(messageType)) {
                historyRecord.MessageType__c = messageType;
            }
            
            if(String.isNotBlank(mediaLink)) {
                historyRecord.MediaLink__c = mediaLink;
            }
            if(String.isNotBlank(mediaCaption)) {
                historyRecord.MediaCaption__c = mediaCaption;
            }
            String serializedHistoryRecord = JSON.serialize(historyRecord);
            WhatsAppIntegrationController.myFutureMethod(serializedHistoryRecord);
        }
        
        // Return the response from the WhatsApp API
        return res.getBody();
    }
/*
    *
        Purpose        :        This asynchronous method handles the insertion of WhatsApp message history records into the database.
        Created By     :        Manish Kumar Prajapati
        Revision Log   :        v 1.0 — Created
        Modified By    :        
    *
*/
    @future
    public static void myFutureMethod(String serializedData)
    {    
        Whats_App_History__c historyRecord = (Whats_App_History__c)JSON.deserialize(serializedData, Whats_App_History__c.class);
        insert historyRecord;
    }

/*
    *
        Purpose        :        This method retrieves the public URL of a file uploaded as a ContentVersion record in Salesforce.
        Created By     :        Manish Kumar Prajapati
        Revision Log   :        v 1.0 — Created
        Modified By    :        
    *
*/
    @AuraEnabled
    public static String getPublicUrl(Id cvId) 
    { 
        /* Getting ContentVersion file  */
        ContentVersion cv = [SELECT Id, Title 
                            FROM ContentVersion 
                            WHERE Id =: cvId];
        
        /* Creating ContentDistribution record */
        ContentDistribution conDis = new ContentDistribution();
        conDis.Name = cv.Title;
        conDis.ContentVersionId = cv.Id;
        conDis.PreferencesAllowViewInBrowser = true;
        conDis.PreferencesLinkLatestVersion=true;
        conDis.PreferencesNotifyOnVisit=false;
        conDis.PreferencesPasswordRequired=false;
        conDis.PreferencesAllowOriginalDownload= true;
        insert conDis;
        System.debug('conDis--'+conDis);
        /* Query ContentDownloadUrl to retrieve the public URL */
        conDis = [SELECT Id,ContentDownloadUrl 
                  FROM ContentDistribution 
                  WHERE Id = :conDis.Id];
        System.debug('conDis.ContentDownloadUrl--'+conDis.ContentDownloadUrl);
        /* Returning  the public URL */
        String url = conDis.ContentDownloadUrl;
        return url;    
    }

/*
    *
        Purpose        :        It queries phone-related fields of a specific record in Salesforce by recordId.
        Created By     :        Manish Kumar Prajapati
        Revision Log   :        v 1.0 — Created
        Modified By    :        
    *
*/     
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> queryPhoneFields(String record_Id) 
    {
        Id recordId = (Id)record_Id;
        String objectApiName =recordId.getSObjectType().getDescribe().getName();
        Map<String, Object> result = new Map<String, Object>();
        
        // Query for a specific record
        System.debug('SELECT Id, ' + String.join(getObjectPhoneFields(objectApiName), ', ') + ' FROM ' + objectApiName + ' WHERE Id =:' + record_Id);
        List<SObject> records = Database.query('SELECT Id, ' + String.join(getObjectPhoneFields(objectApiName), ', ') + ' FROM ' + objectApiName + ' WHERE Id =' + '\''+record_Id+'\'');
        
        if (!records.isEmpty()) {
            SObject record = records[0];
            
            List<String> phoneFields = getObjectPhoneFields(objectApiName);
            
            List<Map<String, String>> phoneFieldValues = new List<Map<String, String>>();
            // Iterate through phone fields and get their values from the record
            for (String fieldName : phoneFields) {
                Map<String, String> fieldValueMap = new Map<String, String>();
                fieldValueMap.put('fieldName', fieldName);
                fieldValueMap.put('fieldValue', (String) record.get(fieldName));
                phoneFieldValues.add(fieldValueMap);
            }
            result.put('phoneFields', phoneFieldValues);
        } else {
            result.put('phoneFields', null);
        }
        
        return result;
    }
    
/*
    *
        Purpose        :        This is a helper method used by the queryPhoneFields method. It dynamically retrieves phone 
                                fields for a given object type in Salesforce.
        Created By     :        Manish Kumar Prajapati
        Revision Log   :        v 1.0 — Created
        Modified By    :        
    *
*/
    // Helper method to dynamically retrieve phone fields for an object
    public static List<String> getObjectPhoneFields(String objectApiName) 
    {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType objectType = gd.get(objectApiName);
        
        List<String> phoneFields = new List<String>();
        
        if (objectType != null) {
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = objectDescribe.fields.getMap();
            
            // Iterate through fields and find phone fields
            for (String fieldName : fieldsMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
                
                if (fieldDescribe.getType() == Schema.DisplayType.Phone) {
                    phoneFields.add(fieldName);
                }
            }
        }
        System.debug(phoneFields);
        return phoneFields;
    }

/*
    *
        Purpose        :        This method fetches the message history of a WhatsApp number based on the phone number provided.
        Created By     :        Manish Kumar Prajapati
        Revision Log   :        v 1.0 — Created
        Modified By    :        
    *
*/    
    @AuraEnabled(cacheable=true)
    public static List<Whats_App_History__c> getMessageHistoryByPhoneNumber(String phoneNumber) 
    {
        System.debug('Fetching message history for phone number: ' + phoneNumber);
        
        List<Whats_App_History__c> messageHistory = [SELECT Id, PhoneNumber__c, MessageType__c, Message__c, MediaLink__c, MediaCaption__c,Timestamp__c 
                                                     FROM Whats_App_History__c 
                                                     WHERE PhoneNumber__c = :phoneNumber
                                                     ORDER BY CreatedDate DESC];
        System.debug('Fetched message history records: ' + messageHistory);
        
        return messageHistory;
    }
}