@isTest
private class AccountLimitResetBatchTest {

    @isTest
    static void testBatchReset(){

        Decimal baseLimit = Decimal.valueOf(System.Label.Current_Limit_for_Account);

        // 1️⃣ Expired + Eligible Account (should reset)
        Account expiredEligible = new Account(
            Name = 'Expired Eligible',
            Current_Limit__c = 800000,
            Enhance_Limit__c = 800000,
            Start_Date__c = Date.today().addDays(-10),
            Duration__c = 2
        );
        insert expiredEligible;

        // 2️⃣ Not Expired Account (should NOT reset)
        Account activeAccount = new Account(
            Name = 'Active Account',
            Current_Limit__c = 900000,
            Enhance_Limit__c = 900000,
            Start_Date__c = Date.today(),
            Duration__c = 5
        );
        insert activeAccount;

        // 3️⃣ Enhance_Limit__c = 0 (filtered in start query)
        Account zeroEnhance = new Account(
            Name = 'Zero Enhance',
            Current_Limit__c = 700000,
            Enhance_Limit__c = 0,
            Start_Date__c = Date.today().addDays(-10),
            Duration__c = 2
        );
        insert zeroEnhance;

        Test.startTest();

        Database.executeBatch(new AccountLimitResetBatch(), 200);

        Test.stopTest();

        // Re-query to validate results
        Map<Id, Account> resultMap = new Map<Id, Account>([
            SELECT Current_Limit__c, Enhance_Limit__c,
                   Start_Date__c, Duration__c
            FROM Account
            WHERE Id IN :new List<Id>{
                expiredEligible.Id,
                activeAccount.Id,
                zeroEnhance.Id
            }
        ]);

        // ✅ Expired + Eligible should reset
        Account updatedExpired = resultMap.get(expiredEligible.Id);

        System.assertEquals(0, updatedExpired.Enhance_Limit__c);
        System.assertEquals(baseLimit, updatedExpired.Current_Limit__c);
        System.assertEquals(null, updatedExpired.Start_Date__c);
        System.assertEquals(null, updatedExpired.Duration__c);

        // ✅ Active should remain unchanged
        Account updatedActive = resultMap.get(activeAccount.Id);

        System.assertEquals(900000, updatedActive.Enhance_Limit__c);
        System.assertEquals(900000, updatedActive.Current_Limit__c);

        // ✅ Zero enhance should remain unchanged (not processed)
        Account updatedZero = resultMap.get(zeroEnhance.Id);

        System.assertEquals(0, updatedZero.Enhance_Limit__c);
        System.assertEquals(700000, updatedZero.Current_Limit__c);
    }
}