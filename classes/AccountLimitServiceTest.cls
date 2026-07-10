@isTest
private class AccountLimitServiceTest {

    @isTest
    static void testResetExpiredLimits(){

        Decimal baseLimit = Decimal.valueOf(System.Label.Current_Limit_for_Account);

        // 1️⃣ Expired Account (should reset)
        Account expiredAcc = new Account(
            Name = 'Expired Account',
            Current_Limit__c = 800000,
            Enhance_Limit__c = 800000,
            Start_Date__c = Date.today().addDays(-10),
            Duration__c = 2,
            History__c = 'Old History'
        );
        insert expiredAcc;

        // 2️⃣ Active Account (should NOT reset)
        Account activeAcc = new Account(
            Name = 'Active Account',
            Current_Limit__c = 900000,
            Enhance_Limit__c = 900000,
            Start_Date__c = Date.today(),
            Duration__c = 5
        );
        insert activeAcc;

        // 3️⃣ Null End Date (no start/duration)
        Account nullEndAcc = new Account(
            Name = 'Null End Date Account',
            Current_Limit__c = 700000,
            Enhance_Limit__c = 700000
        );
        insert nullEndAcc;

        // Re-query to get formula field End_Date__c populated
        List<Account> testAccounts = [
            SELECT Id, Current_Limit__c, Enhance_Limit__c,
                   Start_Date__c, Duration__c,
                   End_Date__c, History__c
            FROM Account
            WHERE Id IN :new List<Id>{expiredAcc.Id, activeAcc.Id, nullEndAcc.Id}
        ];

        Test.startTest();
        AccountLimitService.resetExpiredLimits(testAccounts);
        Test.stopTest();

        // Re-query to verify updates
        Map<Id, Account> updatedMap = new Map<Id, Account>([
            SELECT Current_Limit__c, Enhance_Limit__c,
                   Start_Date__c, Duration__c, History__c
            FROM Account
            WHERE Id IN :new List<Id>{expiredAcc.Id, activeAcc.Id, nullEndAcc.Id}
        ]);

        // ✅ Expired should reset
        Account updatedExpired = updatedMap.get(expiredAcc.Id);

        System.assertEquals(0, updatedExpired.Enhance_Limit__c);
        System.assertEquals(baseLimit, updatedExpired.Current_Limit__c);
        System.assertEquals(null, updatedExpired.Start_Date__c);
        System.assertEquals(null, updatedExpired.Duration__c);
        System.assert(updatedExpired.History__c.contains('Auto Reset On'));

        // ✅ Active should NOT reset
        Account updatedActive = updatedMap.get(activeAcc.Id);

        System.assertEquals(900000, updatedActive.Enhance_Limit__c);
        System.assertEquals(900000, updatedActive.Current_Limit__c);

        // ✅ Null End Date should remain unchanged
        Account updatedNullEnd = updatedMap.get(nullEndAcc.Id);

        System.assertEquals(700000, updatedNullEnd.Enhance_Limit__c);
        System.assertEquals(700000, updatedNullEnd.Current_Limit__c);
    }
}