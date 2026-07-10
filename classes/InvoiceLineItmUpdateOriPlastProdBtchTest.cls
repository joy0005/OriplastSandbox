@isTest
public class InvoiceLineItmUpdateOriPlastProdBtchTest {
    @testSetup
  static void setupData() {
        Account distributorAcc = new Account();
        distributorAcc.Account_External_Key__c = 'CUSBLS0450';
        distributorAcc.Name = 'RASHMI AGENCY - (2023-24)';
        distributorAcc.Type = 'Distributor';
        insert distributorAcc;

        Invoice__c invoiceRecord = new Invoice__c();
        invoiceRecord.Invoice_Number__c = 'RA/T-833/24-25';
        invoiceRecord.Status__c = 'Submitted';
        invoiceRecord.Account__c = distributorAcc.Id;
        invoiceRecord.Distributor__c = distributorAcc.Id;
        insert invoiceRecord;

        
        Invoice_Line_Item__c lineItemRecord = new Invoice_Line_Item__c();
        lineItemRecord.Ori_Plast_Invoice__c = invoiceRecord.Id;
        lineItemRecord.Quantity__c = 10;
        lineItemRecord.Unit_of_Measure__c = 'mtr';
        lineItemRecord.Rate__c = 120;
        lineItemRecord.Total_Discount_Percentage__c = 0;
        lineItemRecord.Final_Price__c = 100;
        lineItemRecord.SKU__c = 'UPVC Pipe 1 1/2" CM Blue M/F 3M Ori';
        insert lineItemRecord;

        OriPlast_Product__c Oproduct = new OriPlast_Product__c(
        Name = '90 mm 4kgf/sq cm UPVC Pipe Plain End 5 Mtr',
        Base_Unit_of_Measure__c = 'PCS',
        Category_Picklist__c = 'P2',
        Product_Category_Code_Picklist__c = 'PVC',
        Sub_Category_Picklist__c = 'Plain End',
        Item_Disc_Group__c = 'PVCPI-4985',
        OriPlast_Product_Unique_Key__c = 'FP201PN040GY00500090'
        );
        insert Oproduct;

        Product_Transformation_Table__c ptr = new Product_Transformation_Table__c();
        ptr.Account__c = distributorAcc.Id;
        ptr.Ori_Plast_Product__c = Oproduct.Id;
        ptr.Tally_Item_Description__c = 'UPVC Pipe 1 1/2" CM Blue M/F 3M Ori';
        insert ptr;
    }

        @isTest
    static void batchExecutionTest() {
        Test.startTest();

        InvoiceLineItmUpdateOriPlastProductBatch batchJob = new InvoiceLineItmUpdateOriPlastProductBatch();
        Database.executeBatch(batchJob, 2);

        Test.stopTest();

        Invoice_Line_Item__c updatedLineItem = [SELECT Id, Ori_Plast_Product__c FROM Invoice_Line_Item__c WHERE SKU__c = 'UPVC Pipe 1 1/2" CM Blue M/F 3M Ori'];
        OriPlast_Product__c expectedProduct = [SELECT Id FROM OriPlast_Product__c WHERE Name = '90 mm 4kgf/sq cm UPVC Pipe Plain End 5 Mtr'];

        System.assertEquals(expectedProduct.Id, updatedLineItem.Ori_Plast_Product__c, 'The Ori_Plast_Product__c should have been updated to the corresponding product.');
    }

    /* @isTest
    static void testScheduledExecution() {
        Test.startTest();

        String sch = '0 0 0 15 3 ? 2024'; 
        InvoiceLineItmUpdateOriPlastProductBatch schedulableBatch = new InvoiceLineItmUpdateOriPlastProductBatch();
        system.schedule('TestScheduledBatch', sch, schedulableBatch);

        Test.stopTest();

        Integer jobCount = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND Status = 'Completed'];
        System.assert(jobCount > 0, 'The batch job should have completed successfully.');
    }*/


}