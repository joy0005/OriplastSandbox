@isTest
private class printInvoiceControllerTest {
    @isTest
    static void testPrintInvoice_NullRecordIds() {
        // Test case for null recordIds
        List<printInvoiceController.RecordIdWrapper> recordIds = null;
        Test.startTest();
        List<Id> result = printInvoiceController.printInvoice(recordIds);
        Test.stopTest();
        // Assert that no ContentDocumentLinkIds are returned
        System.assertEquals(0, result.size());
    }
    
    @isTest
    static void testPrintInvoice_EmptyRecordIds() {
        // Test case for empty recordIds
        List<printInvoiceController.RecordIdWrapper> recordIds = new List<printInvoiceController.RecordIdWrapper>();
        Test.startTest();
        List<Id> result = printInvoiceController.printInvoice(recordIds);
        Test.stopTest();
        // Assert that no ContentDocumentLinkIds are returned
        System.assertEquals(0, result.size());
    }
    
    @isTest
    static void testPrintInvoice_ValidRecordIds() {
        // Test case for valid recordIds
        // Create test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create Ori_Plast_Order__c record
        Ori_Plast_Order__c order = new Ori_Plast_Order__c(Account__c = acc.Id);
        insert order;
        
        // Prepare recordIds list
        List<printInvoiceController.RecordIdWrapper> recordIds = new List<printInvoiceController.RecordIdWrapper>();
        printInvoiceController.RecordIdWrapper wrapper = new printInvoiceController.RecordIdWrapper();
        wrapper.recordId = order.Id;
        recordIds.add(wrapper);
        
        Test.startTest();
        List<Id> result = printInvoiceController.printInvoice(recordIds);
        Test.stopTest();
        
        // Assert that one ContentDocumentLinkId is returned
        System.assertEquals(1, result.size());
        // Perform additional assertions if necessary
    }

}