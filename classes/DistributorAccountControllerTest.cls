@isTest
private class DistributorAccountControllerTest {

    /* -----------------------------
       Utility Method - Create User
    ------------------------------ */
    private static User createDistributorUser(){

        Profile distributorProfile = [
            SELECT Id 
            FROM Profile 
            WHERE Name = 'Distributor' 
            LIMIT 1
        ];

        User u = new User(
            FirstName = 'Test',
            LastName = 'Distributor',
            Email = 'testdist' + Math.random() + '@mail.com',
            Username = 'testdist' + Math.random() + '@mail.com',
            Alias = 'tdist',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = distributorProfile.Id
        );

        insert u;
        return u;
    }

    /* -----------------------------
       Test getDistributorAccounts
    ------------------------------ */
    @isTest
    static void testGetDistributorAccounts(){

        User distUser = createDistributorUser();

        Account acc = new Account(
            Name = 'Test Distributor Account',
            Associated_User__c = distUser.Id
        );
        insert acc;

        Test.startTest();
        List<Account> result = DistributorAccountController.getDistributorAccounts();
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(acc.Id, result[0].Id);
    }

    /* -----------------------------
       Test updateAccountLimit (Single Account)
    ------------------------------ */
    @isTest
    static void testUpdateAccountLimit(){

        User distUser = createDistributorUser();

        Account acc = new Account(
            Name = 'Limit Test Account',
            Associated_User__c = distUser.Id,
            Current_Limit__c = 300000
        );
        insert acc;

        Date startDate = Date.today();
        Integer duration = 5;
        Decimal newLimit = 800000;

        Test.startTest();

        String response = DistributorAccountController.updateAccountLimit(
            acc.Id,
            null,
            startDate,
            duration,
            newLimit
        );

        Test.stopTest();

        Account updatedAcc = [
            SELECT Start_Date__c, Duration__c, Enhance_Limit__c,
                   Current_Limit__c, History__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals('Limit Updated Successfully!', response);
        System.assertEquals(startDate, updatedAcc.Start_Date__c);
        System.assertEquals(duration, updatedAcc.Duration__c);
        System.assertEquals(newLimit, updatedAcc.Enhance_Limit__C);
        System.assertEquals(newLimit, updatedAcc.Current_Limit__c);
        System.assert(updatedAcc.History__c.contains('New Limit'));
    }

    /* -----------------------------
       Test updateAccountLimit
       with Existing History
    ------------------------------ */
    @isTest
    static void testUpdateAccountLimit_WithExistingHistory(){

        User distUser = createDistributorUser();

        Account acc = new Account(
            Name = 'History Test Account',
            Associated_User__c = distUser.Id,
            Current_Limit__c = 300000,
            History__c = 'Old History Entry'
        );
        insert acc;

        Date startDate = Date.today();
        Integer duration = 3;
        Decimal newLimit = 600000;

        Test.startTest();

        DistributorAccountController.updateAccountLimit(
            acc.Id,
            null,
            startDate,
            duration,
            newLimit
        );

        Test.stopTest();

        Account updatedAcc = [
            SELECT History__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assert(
            updatedAcc.History__c.contains('Old History Entry'),
            'Old history should remain'
        );

        System.assert(
            updatedAcc.History__c.contains('New Limit'),
            'New history should be appended'
        );
    }

    /* -----------------------------
       Test updateAccountLimit
       for ALL SELECTED Accounts
    ------------------------------ */
    @isTest
    static void testUpdateAccountLimit_AllAccounts(){

        User distUser = createDistributorUser();

        Account acc1 = new Account(
            Name = 'Bulk Account 1',
            Associated_User__c = distUser.Id,
            Current_Limit__c = 200000
        );

        Account acc2 = new Account(
            Name = 'Bulk Account 2',
            Associated_User__c = distUser.Id,
            Current_Limit__c = 250000
        );

        insert new List<Account>{acc1, acc2};

        List<Id> accountIds = new List<Id>{acc1.Id, acc2.Id};

        Date startDate = Date.today();
        Integer duration = 4;
        Decimal newLimit = 900000;

        Test.startTest();

        String response = DistributorAccountController.updateAccountLimit(
            null,
            accountIds,
            startDate,
            duration,
            newLimit
        );

        Test.stopTest();

        List<Account> updatedAccs = [
            SELECT Current_Limit__c, Enhance_Limit__c
            FROM Account
            WHERE Id IN :accountIds
        ];

        System.assertEquals(2, updatedAccs.size());
        System.assertEquals('Limit Updated for 2 Accounts', response);

        for(Account a : updatedAccs){
            System.assertEquals(newLimit, a.Current_Limit__c);
            System.assertEquals(newLimit, a.Enhance_Limit__c);
        }
    }
}