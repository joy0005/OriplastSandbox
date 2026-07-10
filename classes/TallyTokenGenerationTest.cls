@isTest
public with sharing class TallyTokenGenerationTest {
   @isTest
    static void getTokenWithTokenProvidedTest() {

        String requestBody = '{"TOKENDETAILS": {"TOKEN": "12345678"}}';
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/tallytokengeneration';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(requestBody);
        RestContext.request = request;
       
        RestResponse res = new RestResponse();
        RestContext.response = res;
        Test.startTest();
        TallyTokenGeneration.getToken();
        Test.stopTest();
        System.assertEquals('application/json', RestContext.response.headers.get('Content-Type'));
        System.assertEquals('{"status": "successfuly save token"}', RestContext.response.responseBody.toString());
        List<Integration_Log__c> integrationLogs = [SELECT Id FROM Integration_Log__c WHERE Class_Name__c = 'TallyTokenGeneration'];
        System.assertEquals(1, integrationLogs.size());
    }

    @isTest
    static void getTokenWithoutTokenTest() {
       
       String requestBody = '{"TOKENDETAILS": {"TOKEN": " "}}';
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/tallytokengeneration';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(requestBody);
        RestContext.request = request;
       
        RestResponse res = new RestResponse();
        RestContext.response = res;
        Test.startTest();
        TallyTokenGeneration.getToken();
        Test.stopTest();
        System.assertEquals('application/json', RestContext.response.headers.get('Content-Type'));
       System.assertEquals('{"status": "token is not provided"}', RestContext.response.responseBody.toString());
        List<Integration_Log__c> integrationLogs = [SELECT Id FROM Integration_Log__c WHERE Class_Name__c = 'TallyTokenGeneration'];
        System.assertEquals(1, integrationLogs.size());
    }
}