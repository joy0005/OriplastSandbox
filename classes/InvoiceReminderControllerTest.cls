@isTest
private class InvoiceReminderControllerTest {

    
       //Create Distributor & Distributor User
   
    private static User createUser(Boolean isDistributor){

        Profile p;

        if(isDistributor){
            p = [SELECT Id FROM Profile WHERE Name = 'Distributor' LIMIT 1];
        }else{
            p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        }

        User u = new User(
            FirstName = 'Test',
            LastName = isDistributor ? 'Distributor' : 'Admin',
            Email = 'test' + Math.random() + '@mail.com',
            Username = 'test' + Math.random() + '@mail.com',
            Alias = 'tstusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

  
       //1. Non Distributor → NULL
    
    @isTest
    static void testNonDistributor(){

        User adminUser = createUser(false);

        System.runAs(adminUser){
            Test.startTest();
            String msg = InvoiceReminderController.getReminderMessage();
            Test.stopTest();

            System.assertEquals(null, msg);
        }
    }

    
      // 2. Distributor but NO ACCOUNT
   
    @isTest
    static void testDistributorWithoutAccount(){

        User distUser = createUser(true);

        System.runAs(distUser){
            Test.startTest();
            String msg = InvoiceReminderController.getReminderMessage();
            Test.stopTest();

            System.assertNotEquals(null, msg);
        }
    }

    
      // 3. Distributor + Account but NO invoices (hit invCount == 0)
    
    @isTest
    static void testNoInvoiceLast3Days(){

        User distUser = createUser(true);

        System.runAs(distUser){

            Account acc = new Account(
                Name = 'Distributor Account',
                Associated_User__c = distUser.Id
            );
            insert acc;

            // OLD invoice
            Invoice__c oldInv = new Invoice__c(Account__c = acc.Id);
            insert oldInv;
            Test.setCreatedDate(oldInv.Id, DateTime.now().addDays(-5));

            Test.startTest();
            String msg = InvoiceReminderController.getReminderMessage();
            Test.stopTest();

            // MUST show reminder → invCount == 0 branch
            System.assertNotEquals(null, msg);
        }
    }

  
     //  4. Distributor + Recent Invoice (return null)
    
    @isTest
    static void testRecentInvoice(){

        User distUser = createUser(true);

        System.runAs(distUser){

            Account acc = new Account(
                Name = 'Distributor Account',
                Associated_User__c = distUser.Id
            );
            insert acc;

            // Recent invoice (today)
            Invoice__c inv = new Invoice__c(Account__c = acc.Id);
            insert inv;
            Test.setCreatedDate(inv.Id, DateTime.now());

            Test.startTest();
            String msg = InvoiceReminderController.getReminderMessage();
            Test.stopTest();

            System.assertEquals(null, msg);
        }
    }
}