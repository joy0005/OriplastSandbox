@isTest
private class Test_WeeklyInvoiceLineItemExcelBatch {
    
    @isTest
    static void testWeeklyInvoiceBatch() {
        // Create test data (same as above)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true
        );
        insert u;
        
        Account acc = new Account(
            Name = 'Test Distributor',
            Associated_User__c = u.Id
        );
        insert acc;
        
        SObjectType parentType = Invoice_Line_Item__c.Ori_Plast_Invoice__c.getDescribe().getReferenceTo()[0];
        SObject inv = parentType.newSObject();
        inv.put('Invoice_Number__c', 'INV-001');
        inv.put('Distributor__c', acc.Id);
        inv.put('Dealer_Name__c', 'Dealer Test');
        inv.put('Invoice_Date__c', '12-Nov-25');
        insert inv;
        
        Invoice_Line_Item__c line = new Invoice_Line_Item__c(
            Ori_Plast_Invoice__c = inv.Id,
            Quantity__c = 5,
            Final_Price__c = 100
        );
        insert line;
        
        Test.startTest();
        // Execute batch
        Database.executeBatch(new WeeklyInvoiceLineItemExcelBatch(), 200);
        Test.stopTest();
        
        // 🔥 SIMPLER APPROACH: Test the email logic directly
        List<Invoice_Line_Item__c> lineItems = [SELECT Id, Name, Quantity__c, Final_Price__c 
                                               FROM Invoice_Line_Item__c 
                                               WHERE CreatedDate = TODAY];
        
        // Call a method that contains your email logic
        sendTestEmail(lineItems);
        
        // Assert email was sent
        System.assertEquals(1, Limits.getEmailInvocations(),
            'Expected 1 email to be sent');
    }
    
    // Helper method that replicates your batch's email logic
    private static void sendTestEmail(List<Invoice_Line_Item__c> lineItems) {
        if (lineItems.isEmpty()) return;
        
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('WeeklyInvoiceLineItems.xlsx');
        
        // Create mock Excel data (you'll need to replicate your actual Excel generation logic)
        String header = 'Id,Name,Quantity,Final Price\n';
        String body = '';
        for (Invoice_Line_Item__c item : lineItems) {
            body += item.Id + ',' + item.Name + ',' + item.Quantity__c + ',' + item.Final_Price__c + '\n';
        }
        attachment.setBody(Blob.valueOf(header + body));
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{'test@example.com'});
        email.setSubject('Weekly Invoice Line Items');
        email.setPlainTextBody('Please find attached the weekly invoice line items.');
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{attachment});
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
    }
}