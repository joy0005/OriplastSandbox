@isTest
public without sharing class Create_Inv_InvLineItm_controllerTest {
    @isTest
    static void createInvoiceTest(){
        String jsonData = '{"Distributor":"RASHMI AGENCY - (2023-24)","DistributorIdentificationKey":"CUSBLS0450","InvoiceDetails":[{"InvoiceNumber":"RA/T-833/24-25","InvoiceDate":"1-Jul-24","InvoiceStatus":"Submitted","DealerDetails":{"Name":"Cash"},"InvoiceLineItems":[{"SKU":"1 UPVC BRASS MTA","Quantity":1,"UnitofMeasure":"PCS","rate":119.53,"TotalDiscountPercentage":0,"FinalPrice":119.53}]}]}';
        
        // Create a test user
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User testUser = new User(
            ProfileId = profile.Id,
            Username = 'testuserforpermission@example.com',
            Email = 'testuser@example.com',
            LastName = 'Test',
            FirstName = 'User',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        Account distributorAcc = new  Account();
        distributorAcc.Account_External_Key__c = 'CUSBLS0450';
        distributorAcc.Name = 'RASHMI AGENCY - (2023-24)';
        distributorAcc.Type = 'Distributor';
        distributorAcc.Associated_User__c = testUser.Id;

        insert distributorAcc;

        //**  Create Test data for staging Record
        List<Staging__c> testStagingList = new  List<Staging__c>();
        Staging__c testStaging = new  Staging__c();
        testStaging.Status__c ='Pending';
        testStaging.JSON_Payload__c = jsonData;
        insert testStaging;

        Staging__c testStaging1 = new  Staging__c();
        testStaging.Status__c ='Pending';
        testStaging.JSON_Payload__c = jsonData;
        
        insert testStaging1;

        testStagingList = [Select Id, Name,JSON_Payload__c, Status__c From Staging__c Where Status__c= 'Pending'];
        Test.startTest();
        Create_Inv_InvLineItm_controller.createInvoice(testStagingList);
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Invoice__c WHERE Status__c = 'Submitted'], 'Incorrect number of invoices created');
    }
    
    @isTest
    static void createInvoiceNegativeTest(){
        String jsonData = '{"Distributor":"RASHMI AGENCY - (2023-24)","DistributorIdentificationKey":"CUSBLS0450","InvoiceDetails":[{"InvoiceNumber":"RA/T-833/24-25","InvoiceStatus":"Submitted","DealerDetails":{"Name":"Cash"},"InvoiceLineItems":[{"SKU":"1 UPVC BRASS MTA","Quantity":1,"UnitofMeasure":"PCS","rate":119.53,"TotalDiscountPercentage":0,"FinalPrice":119.53}]}]}';

        Account distributorAcc = new  Account();
        distributorAcc.Account_External_Key__c = 'CUSBLS0450';
        distributorAcc.Name = 'RASHMI AGENCY - (2023-24)';
        distributorAcc.Type = 'Distributor';
        insert distributorAcc;

        //**  Create Test data for staging Record
        List<Staging__c> testStagingList = new  List<Staging__c>();
        Staging__c testStaging = new  Staging__c();
        testStaging.Status__c ='Pending';
        testStaging.JSON_Payload__c = jsonData;
        insert testStaging;

        Staging__c testStaging1 = new  Staging__c();
        testStaging.Status__c ='Pending';
        testStaging.JSON_Payload__c = jsonData;
        insert testStaging1;

        testStagingList = [Select Id, Name,JSON_Payload__c, Status__c From Staging__c Where Status__c= 'Pending'];
        Test.startTest();
            try {
                Create_Inv_InvLineItm_controller.createInvoice(testStagingList);
            } catch (Exception ex) {
                System.assertEquals('Invalid InvoiceDate', ex.getMessage(), 'Unexpected error message');
            }
        Test.stopTest();
    }
    
    @isTest
    static void createInvoiceCancelTest(){
        String jsonData = '{"Distributor":"RASHMI AGENCY - (2023-24)","DistributorIdentificationKey":"CUSBLS0450","InvoiceDetails":[{"InvoiceNumber":"RA/T-833/24-25","InvoiceDate":"1-Jul-24","InvoiceStatus":"Cancelled","DealerDetails":{"Name":"Cash"},"InvoiceLineItems":[{"SKU":"1 UPVC BRASS MTA","Quantity":1,"UnitofMeasure":"PCS","rate":119.53,"TotalDiscountPercentage":0,"FinalPrice":119.53}]}]}';

        Account distributorAcc = new  Account();
        distributorAcc.Account_External_Key__c = 'CUSBLS0450';
        distributorAcc.Name = 'RASHMI AGENCY - (2023-24)';
        distributorAcc.Type = 'Distributor';
        insert distributorAcc;

        //**  Create Test data for staging Record
        List<Staging__c> testStagingList = new  List<Staging__c>();
        Staging__c testStaging = new  Staging__c();
        testStaging.Status__c ='Pending';
        testStaging.JSON_Payload__c = jsonData;
        insert testStaging;   
        
        Staging__c testStaging1 = new  Staging__c();
        testStaging.Status__c ='Pending';
        testStaging.JSON_Payload__c = jsonData;
        insert testStaging1;    

        testStagingList = [Select Id, Name,JSON_Payload__c, Status__c From Staging__c Where Status__c= 'Pending'];
        Test.startTest();
        try {
            Create_Inv_InvLineItm_controller.createInvoice(testStagingList);
        } catch (Exception ex) {
            System.assertEquals('Invalid InvoiceDate', ex.getMessage(), 'Unexpected error message');
        }      
        Test.stopTest();
    }
    

    @isTest
    static void createInvoiceNegativeTestBadData(){
        String jsonData = '{"Distributor":"Test Distributor","DistributorIdentificationKey":"DXCP980","InvoiceDetails":[{"InvoiceNumber":"0087255","DealerDetails":{"Name":"Test Dealer 1","GST":"123894","State":"Odisha","BillingAddress":"Test Address 1","DealerIdentificationKey":"Test Dealer 1"},"InvoiceLineItems":[{"Description":"Test1","SKU":"Test2123","Quantity":"10.50","UnitofMeasure":"Meter","TotalDiscountPercentage":"30.10","CGST":null,"CGST Percentage":null,"SGST":"12.90","SGST Percentage":"09.00","IGST":"12.90","IGST Percentage":"18.00","Final Price":"2345.90"},{"Description":"Test2","SKU":"Test2123","Quantity":"10.50","UnitofMeasure":"Meter","TotalDiscountPercentage":"30.10","CGST":"12.90","CGST Percentage":"09.00","SGST":"12.90","SGST Percentage":"09.00","IGST":"12.90","IGST Percentage":"18.00","Final Price":"2345.90"}]},{"InvoiceNumber":"00878256","InvoiceStatus":"Submitted","DealerDetails":{"Name":"Test Dealer 2","GST":"123884","State":"Odisha","BillingAddress":"Test Address 2","DealerIdentificationKey":"Test Dealer 2"},"InvoiceLineItems":[{"Description":"Test1","SKU":"Test2123","Quantity":"10.50","UnitofMeasure":"Meter","TotalDiscountPercentage":"30.10","CGST":"12.90","CGST Percentage":"09.00","SGST":"12.90","SGST Percentage":"09.00","IGST":"12.90","IGST Percentage":"18.00","Final Price":"2345.90"},{"Description":"Test2","SKU":"Test2123","Quantity":"10.50","UnitofMeasure":"Meter","TotalDiscountPercentage":"30.10","CGST":"12.90","CGST Percentage":"09.00","SGST":"12.90","SGST Percentage":"09.00","IGST":"12.90","IGST Percentage":"18.00","Final Price":"2345.90"}]}]}';
        Account distributorAcc = new  Account();
        distributorAcc.Account_External_Key__c = 'DXCP980';
        distributorAcc.Name = 'Test Distributor';
        distributorAcc.Type = 'Distributor';
        insert distributorAcc;

        //**  Create Test data for staging Record
        List<Staging__c> testStagingList = new  List<Staging__c>();
        Staging__c testStaging = new  Staging__c();
        testStaging.Status__c ='Pending';
        testStaging.JSON_Payload__c = jsonData;
        insert testStaging;

        Staging__c testStaging1 = new  Staging__c();
        testStaging.Status__c ='Pending';
        testStaging.JSON_Payload__c = jsonData;
        insert testStaging1;

        testStagingList = [Select Id, Name,JSON_Payload__c, Status__c From Staging__c Where Status__c= 'Pending'];
        Test.startTest();
            try {
                Create_Inv_InvLineItm_controller.createInvoice(testStagingList);
            } catch (Exception ex) {
                System.assertEquals('Invalid InvoiceDate', ex.getMessage(), 'Unexpected error message');
            }
        Test.stopTest();
    }
}