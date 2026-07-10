@isTest
public class CheckingShortCloseTest {
    @testSetup
    static void setupTestData() {
        //** Inserting Account 
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        //**Insering Ori-Plast Order for test
        Ori_Plast_Order__c order = new Ori_Plast_Order__c(
            Order_Status__c = 'Draft',
            Account__c = acc.Id
        );
        insert order;
        
        //**Set created date of Ori-Plast Order
        Test.setCreatedDate(order.Id, System.now().addDays(-9));
    }
    
    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        CheckingShortClose batch = new CheckingShortClose();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        //**Validate updates
        Ori_Plast_Order__c updatedOrders = [
            SELECT Id, Short_Closed__c, Short_Close_Reason__c 
            FROM Ori_Plast_Order__c 
            WHERE Short_Closed__c = true
        ];
        
        System.assertEquals(true, updatedOrders.Short_Closed__c,'All order short closed status must be true');
        System.assertEquals(Label.Short_Close_Reason, updatedOrders.Short_Close_Reason__c);
        
    }
    
    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String jobId = System.schedule('Test Scheduled Job', '0 0 2 * * ?', new CheckingShortClose());
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Scheduled job should return a job ID');
    }
    
    @isTest
    static void testErrorLogging() {
        //**Insert a record with invalid data to force a DML error
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Ori_Plast_Order__c invalidOrder = new Ori_Plast_Order__c(
            Account__c = acc.id,
            Short_Close_Reason__c='Trigger Error',
            is_Sales_Order_Received__c =true
        );
        insert invalidOrder;
        Test.setCreatedDate(invalidOrder.Id, System.now().addDays(-9));
        CheckingShortClose.forceDmlFailure = true;
        //**Lock the record to simulate an update failure (simplified logic)
        Test.startTest();
        CheckingShortClose batch = new CheckingShortClose();
        
        //**Simulate the error by mocking the DML behavior (in a real scenario you'd use field constraints)
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        //**Assert that at least one error log was created
        List<TransactionLog__c> logs = [SELECT Id, Message__c, Action__c, Process__c FROM TransactionLog__c];
        
        //**Note: depending on whether DML error was actually triggered, this may be empty in test
        System.assertEquals(true, logs.size()>0); //**Relaxed condition for general use
    }
}