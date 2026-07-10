@IsTest
public class InvoiceGenerationTest {
    @IsTest
    static void getInvoiceWithValidTokenTest() {
       
        Tally_Token__c validToken = new Tally_Token__c(Tally_Token__c = 'validToken');
        insert validToken;

        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/invoicegeneration/';
        req.httpMethod = 'POST';
        req.addParameter('token', 'validToken');
        req.requestBody = Blob.valueOf('{"Distributor": "Test Distributor","DistributorIdentificationKey": "DXCP980","InvoiceDetails": [{"InvoiceNumber": "0088243","InvoiceDate": "29/04/2024","InvoiceStatus": "Submitted","DealerDetails": {"Name": "Test Dealer 1","GST": "123894","State": "Odisha","BillingAddress": "Test Address 1","DealerIdentificationKey": "Test Dealer 1"},"InvoiceLineItems": [{"Description": "Test1","SKU": "Test2123","Quantity": "10.50","UnitofMeasure": "Meter","TotalDiscountPercentage": "30.10","CGST": "12.90","CGST Percentage": "09.00","SGST": "12.90","SGST Percentage": "09.00","IGST": "12.90","IGST Percentage": "18.00","Final Price": "2345.90"},{"Description": "Test2","SKU": "Test2123","Quantity": "10.50","UnitofMeasure": "Meter","TotalDiscountPercentage": "30.10","CGST": "12.90","CGST Percentage": "09.00","SGST": "12.90","SGST Percentage": "09.00","IGST": "12.90","IGST Percentage": "18.00","Final Price": "2345.90"}]}, {"InvoiceNumber": "0088244","InvoiceDate": "29/04/2024","InvoiceStatus": "Submitted","DealerDetails": {"Name": "Test Dealer 2","GST": "123884","State": "Odisha","BillingAddress": "Test Address 2","DealerIdentificationKey": "Test Dealer 2"},"InvoiceLineItems": [{"Description": "Test1","SKU": "Test2123","Quantity": "10.50","UnitofMeasure": "Meter","TotalDiscountPercentage": "30.10","CGST": "12.90","CGST Percentage": "09.00","SGST": "12.90","SGST Percentage": "09.00","IGST": "12.90","IGST Percentage": "18.00","Final Price": "2345.90"},{"Description": "Test2","SKU": "Test2123","Quantity": "10.50","UnitofMeasure": "Meter","TotalDiscountPercentage": "30.10","CGST": "12.90","CGST Percentage": "09.00","SGST": "12.90","SGST Percentage": "09.00","IGST": "12.90","IGST Percentage": "18.00","Final Price": "2345.90"}]}]}');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        
        InvoiceGeneration.getInvoice();

        // ** Verify the response
        String expectedResponse = '{"invoiceNumbers":[{"InvoiceNumber":"0088243"},{"InvoiceNumber":"0088244"}],"status":"Success"}';
        System.assertEquals(expectedResponse, res.responseBody.toString(), 'Response body did not match the expected value');


        // ** Verify that Integration_Log__c and Staging__c records were created
        List<Integration_Log__c> logs = [SELECT Id FROM Integration_Log__c WHERE Class_Name__c = 'InvoiceGeneration'];
        System.assertEquals(1, logs.size(), 'Expected one Integration Log record to be created');

        List<Staging__c> stages = [SELECT Id FROM Staging__c WHERE Status__c = 'Pending'];
        System.assertEquals(1, stages.size(), 'Expected one Staging record to be created');
    }

    @IsTest
    static void getInvoiceWithInvalidTokenTest() {
       
        Tally_Token__c validToken = new Tally_Token__c(Tally_Token__c = 'validToken');
        insert validToken;

        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/invoicegeneration/';
        req.httpMethod = 'POST';
        req.addParameter('token', 'invalidToken');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        
        InvoiceGeneration.getInvoice();

        // **Verify the response
        String expectedResponse = '{"status": "TOKEN Is Invalid"}';
        System.assertEquals(expectedResponse, res.responseBody.toString(), 'Response body did not match the expected value for invalid token');
    }

    @IsTest
    static void getInvoiceWithoutTokenTest() {
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/invoicegeneration/';
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        
        InvoiceGeneration.getInvoice();

        // ** Verify the response
        String expectedResponse = '{"status": "Please Provide The TOKEN"}';
        System.assertEquals(expectedResponse, res.responseBody.toString(), 'Response body did not match the expected value for missing token');
    }

    @IsTest
    static void processInvoiceRequestExceptionTest() {
        
        Tally_Token__c validToken = new Tally_Token__c(Tally_Token__c = 'validToken');
        insert validToken;

        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/invoicegeneration/';
        req.httpMethod = 'POST';
        req.addParameter('token', 'validToken');
        req.requestBody = Blob.valueOf('{"Distributor": "Test Distributor","DistributorIdentificationKey": "DXCP980","InvoiceDetails": [{"InvoiceNumber": "0088243","InvoiceDate": "29/04/2024","InvoiceStatus": "Submitted","DealerDetails": {"Name": "Test Dealer 1","GST": "123894","State": "Odisha","BillingAddress": "Test Address 1","DealerIdentificationKey": "Test Dealer 1"},"InvoiceLineItems": [{"Description": "Test1","SKU": "Test2123","Quantity": "10.50","UnitofMeasure": "Meter","TotalDiscountPercentage": "30.10","CGST": "12.90","CGST Percentage": "09.00","SGST": "12.90","SGST Percentage": "09.00","IGST": "12.90","IGST Percentage": "18.00","Final Price": "2345.90"},{"Description": "Test2","SKU": "Test2123","Quantity": "10.50","UnitofMeasure": "Meter","TotalDiscountPercentage": "30.10","CGST": "12.90","CGST Percentage": "09.00","SGST": "12.90","SGST Percentage": "09.00","IGST": "12.90","IGST Percentage": "18.00","Final Price": "2345.90"}]}, {"InvoiceNumber": "0088244","InvoiceDate": "29/04/2024","InvoiceStatus": "Submitted","DealerDetails": {"Name": "Test Dealer 2","GST": "123884","State": "Odisha","BillingAddress": "Test Address 2","DealerIdentificationKey": "Test Dealer 2"},"InvoiceLineItems": [{"Description": "Test1","SKU": "Test2123","Quantity": "10.50","UnitofMeasure": "Meter","TotalDiscountPercentage": "30.10","CGST": "12.90","CGST Percentage": "09.00","SGST": "12.90","SGST Percentage": "09.00","IGST": "12.90","IGST Percentage": "18.00","Final Price": "2345.90"},{"Description": "Test2","SKU": "Test2123","Quantity": "10.50","UnitofMeasure": "Meter","TotalDiscountPercentage": "30.10","CGST": "12.90","CGST Percentage": "09.00","SGST": "12.90","SGST Percentage": "09.00","IGST": "12.90","IGST Percentage": "18.00","Final Price": "2345.90"}]}]}');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

       
        Test.startTest();
        InvoiceGeneration.getInvoice();
        Test.stopTest();

        // ** Verify the response
        String expectedResponse = '{"invoiceNumbers":[{"InvoiceNumber":"0088243"},{"InvoiceNumber":"0088244"}],"status":"Success"}';
        System.assertEquals(expectedResponse, res.responseBody.toString(), 'Response body did not contain the expected error message');
    }
}