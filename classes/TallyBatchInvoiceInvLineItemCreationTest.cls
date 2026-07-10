@isTest
public with sharing class TallyBatchInvoiceInvLineItemCreationTest {
    @isTest
    static void batchExecutionTest() {
        
        String jsonData = '{"Distributor":"RASHMI AGENCY - (2023-24)","DistributorIdentificationKey":"CUSBLS0450","InvoiceDetails":[{"InvoiceNumber":"RA/T-833/24-25","InvoiceDate":"1-Jul-24","InvoiceStatus":"Submitted","DealerDetails":{"Name":"Cash"},"InvoiceLineItems":[{"SKU":"1 UPVC BRASS MTA","Quantity":1,"UnitofMeasure":"PCS","rate":119.53,"TotalDiscountPercentage":0,"FinalPrice":119.53}]}]}';
        Staging__c stagingRecord = new Staging__c(Status__c = 'Pending', JSON_Payload__c = jsonData);
        insert stagingRecord;

        Test.startTest();
       
        TallyBatchInvoiceInvoiceLineItemCreation batchInstance = new TallyBatchInvoiceInvoiceLineItemCreation();
        Database.executeBatch(batchInstance);

        Test.stopTest();
        Integer countInvoiceLineItems = [SELECT count() FROM Invoice_Line_Item__c];
        //System.assertEquals(0, countInvoiceLineItems, 'Incorrect number of invoice line items created');
       
    }

    @isTest
    static void schedulableExecutionTest() {
        Test.startTest();
        String jobId = System.schedule('Test Tally Batch Job', '0 0 0 * * ?', new TallyBatchInvoiceInvoiceLineItemCreation());
        Test.stopTest();
        System.assertNotEquals(null, jobId);

    }

    @isTest
    static void batchExecutionNegativeTest() {
        
        Staging__c stagingRecord = new Staging__c(Status__c = 'Pending', JSON_Payload__c = '{}');
        insert stagingRecord;

        Test.startTest();
       
        TallyBatchInvoiceInvoiceLineItemCreation batchInstance = new TallyBatchInvoiceInvoiceLineItemCreation();
       
        Database.executeBatch(batchInstance);

        Test.stopTest();

        
        List<TransactionLog__c> logs = [SELECT Id FROM TransactionLog__c];
        System.assertEquals(0, logs.size(), 'Transaction log should have been created');
    }
}