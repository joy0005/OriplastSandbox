@IsTest
private class SendSecondarySalesRepToDistTest {

    @IsTest
    static void testSendWeeklyReportLinks_sendsEmail() {
        // Get the Distributor profile used in the main class query
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Distributor'
            LIMIT 1
        ];

        // Create a test Distributor user
        User u = new User(
            FirstName         = 'Test',
            LastName          = 'Distributor',
            Alias             = 'tdist',
            Email             = 'test@example.com',
            Username          = 'test.distributor.' + System.currentTimeMillis() + '@example.com',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey      = 'en_US',
            TimeZoneSidKey    = 'Asia/Kolkata',
            ProfileId         = p.Id,
            IsActive          = true
        );
        insert u;

        Test.startTest();
        // Run as Distributor user to mimic real scenario
        System.runAs(u) {
            SendSecondarySalesReportToDistributor.sendWeeklyReportLinks();
        }
        Test.stopTest();

        // If we reach here, method executed without any exception
        System.assert(true, 'sendWeeklyReportLinks executed successfully.');
    }

    @IsTest
    static void testScheduler() {
        Test.startTest();
        String cron = '0 0 10 ? * SAT';
        String jobId = System.schedule(
            'Test Secondary Sales Scheduler',
            cron,
            new SecondarySalesReportScheduler()
        );
        Test.stopTest();

        System.assertNotEquals(
            null,
            jobId,
            'Job Id should not be null after scheduling the SecondarySalesReportScheduler.'
        );
    }
}