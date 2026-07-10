@IsTest
private class InvoiceReminderServiceTest {

    @IsTest
    static void testInvoiceReminderForDistributors() {
        // 1. Get Distributor profile
        Profile distProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Distributor'
            LIMIT 1
        ];

        // 2. Create Distributor Users
        User u1 = new User(
            FirstName = 'Dist',
            LastName = 'One',
            Alias = 'dist1',
            Email = 'dist1@example.com',
            Username = 'dist1@example.com.test',
            CommunityNickname = 'dist1nick',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = distProfile.Id
        );

        User u2 = new User(
            FirstName = 'Dist',
            LastName = 'Two',
            Alias = 'dist2',
            Email = 'dist2@example.com',
            Username = 'dist2@example.com.test',
            CommunityNickname = 'dist2nick',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = distProfile.Id
        );

        insert new List<User>{ u1, u2 };

        // 3. Create Accounts linked to these Users
        Account acc1 = new Account(
            Name = 'Distributor Account 1',
            Associated_User__c = u1.Id
        );
        Account acc2 = new Account(
            Name = 'Distributor Account 2',
            Associated_User__c = u2.Id
        );
        insert new List<Account>{ acc1, acc2 };

        // 4. Create invoices
        // Invoice for User1: within last 3 days (should be considered "recent")
        Invoice__c invRecent = new Invoice__c(
    Distributor__c = acc1.Id
);
insert invRecent;
Test.setCreatedDate(invRecent.Id, Datetime.now().addDays(-1));

        // Invoice for User2: older than 3 days (should NOT be considered recent)
        Invoice__c invOld = new Invoice__c(
            Distributor__c = acc2.Id
        );
        insert invOld;
        Test.setCreatedDate(invOld.Id, Datetime.now().addDays(-5)); // outside last 3 days

        // 5. Run method
        Test.startTest();
        InvoiceReminderService.sendInvoiceReminders();
        Test.stopTest();

        // 6. Assertions
        System.assertNotEquals(null, InvoiceReminderService.lastEmailsSent, 'Emails list should be initialized');

        // Only one user should receive an email: u2
        System.assertEquals(1, InvoiceReminderService.lastEmailsSent.size(), 'Exactly one distributor should get an email');

        Messaging.SingleEmailMessage email = InvoiceReminderService.lastEmailsSent[0];
        List<String> toAddresses = email.getToAddresses();

        System.assertEquals(1, toAddresses.size(), 'One recipient expected');
        System.assertEquals(u2.Email, toAddresses[0], 'Email should be sent to distributor without recent invoices (u2)');
    }
    
    @IsTest
    static void testScheduler() {
        Test.startTest();
        String cron = '0 0 10 ? * SAT';
        String jobId = System.schedule(
            'Test Invoice Reminder Service',
            cron,
            new InvoiceReminderScheduler()
        );
        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'Job Id should not be null after scheduling the SecondarySalesReportScheduler.'
        );
    }
}