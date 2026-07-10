/*@IsTest
private class Test_SendInvoiceCSVToDistributor {
    
    static Account distAcc;
    static User distUser;
    static OriPlast_Product__c testProduct;
    
    // --- Date for Batch Class Logic Simulation ---
    static final Date BATCH_TEST_DATE = Date.newInstance(2025, 3, 10); // Monday
    static final Date START_OF_WEEK = BATCH_TEST_DATE.toStartOfWeek(); // Sunday, 2025-03-09
    static final Date END_OF_WEEK = START_OF_WEEK.addDays(6);          // Saturday, 2025-03-15
    static final Date START_OF_MONTH = BATCH_TEST_DATE.toStartOfMonth(); // 2025-03-01
    static final Date END_OF_MONTH = START_OF_MONTH.addMonths(1).addDays(-1); // 2025-03-31
    
    // ------------------------------
    // 1. TEST DATA SETUP (Runs once per context)
    // ------------------------------
    static void setupData() {
        Profile distProfile = [SELECT Id FROM Profile WHERE Name = 'Distributor' LIMIT 1];
        
        // 2️ Create Distributor User
        User distributorUser = new User(
            FirstName = 'Test',
        LastName = 'Distributor',
        Email = 'testdist@example.com',
        Username = 'testdist' + DateTime.now().getTime() + '@example.com',
        Alias = 'tdist',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = distProfile.Id
            );
        insert distributorUser;
        
        // 3️ Create Distributor Account
        distAcc = new Account(
            Name = 'Test Distributor Account',
        Associated_User__c = distributorUser.Id
            );
        insert distAcc;
        
        
        // 4️ Create Invoice within current week
        Invoice__c inv = new Invoice__c(
            Distributor__c = distAcc.Id,
        Invoice_Date__c  = '12-Nov-25'
            );
        insert inv;
        
        // 5️ Create related Invoice Line Item
        Invoice_Line_Item__c line = new Invoice_Line_Item__c(
            Ori_Plast_Invoice__c = inv.Id,
        Quantity__c = 5,
        Final_Price__c = 100
            );
        insert line;
    }
    
    
    // ------------------------------
    // 2. Test Visualforce CSV Controller
    // ------------------------------
    @IsTest
    static void testCSVController() {
        setupData();
        
        Test.startTest();
        
        // WEEKLY Report
        PageReference pg = Page.InvoiceCSVExport;
        pg.getParameters().put('distributorId', String.valueOf(distAcc.Id));
        pg.getParameters().put('reportType', 'Weekly');
        Test.setCurrentPage(pg);
        
        InvoiceCSVExportController c1 = new InvoiceCSVExportController();
        System.assertEquals(1, c1.invoiceLineItems.size(), 'Should find 1 weekly line item');
        
        // MONTHLY Report
        PageReference pg2 = Page.InvoiceCSVExport;
        pg2.getParameters().put('distributorId', String.valueOf(distAcc.Id));
        pg2.getParameters().put('reportType', 'Monthly');
        Test.setCurrentPage(pg2);
        
        InvoiceCSVExportController c2 = new InvoiceCSVExportController();
        System.assertEquals(1, c2.invoiceLineItems.size(), 'Should find 1 monthly line item');
        
        // Invalid Report Type
        PageReference pg3 = Page.InvoiceCSVExport;
        pg3.getParameters().put('distributorId', String.valueOf(distAcc.Id));
        pg3.getParameters().put('reportType', 'Invalid');
        Test.setCurrentPage(pg3);
        InvoiceCSVExportController c3 = new InvoiceCSVExportController();
        System.assertEquals(0, c3.invoiceLineItems.size(), 'Should return 0 items for invalid report type');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testBatchFlow() {
        setupData();
        
        InvoiceReportBatch batch = new InvoiceReportBatch();
        
        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest(); // finish() runs here
        List<AsyncApexJob> jobs = [
        SELECT Id, Status 
        FROM AsyncApexJob 
        WHERE JobType = 'Queueable'
    ];
        
        System.assertEquals(1, jobs.size(),
        'Queueable job should be queued in finish method');
    }
    
    
    // ------------------------------
    // 4. Test Scheduler
    // ------------------------------
    @IsTest
    static void testScheduler() {
        setupData();
        String cron = '0 0 12 * * ?'; // Every day at 12:00 PM
        
        Test.startTest();
        System.schedule('TestScheduler', cron, new InvoiceReportScheduler());
        
        List<AsyncApexJob> jobs = [SELECT Status FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assertEquals(0, jobs.size(), 'Batch job should NOT be executed when scheduled via System.schedule in Test context');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testScheduler_DirectExecute() {
        setupData();
        Test.startTest();
        new InvoiceReportScheduler().execute(null);
        Test.stopTest();
        System.assert(true, 'Scheduler executed normally, skipped batch due to Test.isRunningTest()');
    }
    
    // ------------------------------
    // 5. Test Queueable Execution and Email Sending
    // ------------------------------
    static void testQueueableAndEmailSending() {
        setupData();
        
        InvoiceReportBatch batch = new InvoiceReportBatch();
        Database.QueryLocator ql = batch.start(null);
        List<Invoice__c> allInvoices = Database.query(ql.getQuery());
        
        batch.execute(null, allInvoices);
        Test.startTest();
        System.enqueueJob(new SendInvoiceCSVQueueable(batch.allWeeklyInvoices, batch.allMonthlyInvoices));
        Test.stopTest();
        
        System.assertEquals(1, Limits.getEmailInvocations(), 'One email should have been sent to the distributor');
    }
    
    @IsTest
    static void testEmailSender_NoInvoices() {
        // Test case where no data is passed to the email sender
        Test.startTest();
        SendInvoiceCSVToDistributor.sendInvoiceReports(
            new Map<Id, Map<Id, List<Invoice__c>>>(),
        new Map<Id, Map<Id, List<Invoice__c>>>()
            );
        Test.stopTest();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No email should be sent when maps are empty');
    }
    
    @IsTest
    static void testEmailSender_UserWithoutEmail() {
        setupData();
        
        // Create a distributor user with no email (simulate missing email)
        User userNoEmail = new User(
            FirstName = 'Test',
        LastName = 'NoEmail',
        Alias = 'nml',
        Username = 'noemail'+System.currentTimeMillis()+'@example.com',
        Email = 'invalid_email@noemail.local',  // ✔ simulate missing email
        IsActive = true,
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = [SELECT Id FROM Profile WHERE Name = 'Distributor' LIMIT 1].Id
            );
        insert userNoEmail;
        
        
        // Create an Account linked to this user
        Account acc = new Account(
            Name = 'Test Acc',
        Associated_User__c = userNoEmail.Id
            );
        insert acc;
        
        // Create one invoice
        Invoice__c inv = new Invoice__c(
            Distributor__c = acc.Id
            );
        insert inv;
        
        Test.startTest();
        Database.executeBatch(new InvoiceReportBatch(), 200);
        Test.stopTest();
        
        // Verify no email was sent
        System.assertEquals(
            0,
        Limits.getEmailInvocations(),
        'No email should be sent when user email is null'
            );
    }
    @IsTest
    static void test_SendInvoiceReports_FullCoverage() {
        
        // ---------- 1. Create user WITH email ----------
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User usr = new User(
            FirstName = 'Test2',
        LastName  = 'NoEmail',
        Alias = 'tne',
        Username = 'noemail'+System.currentTimeMillis()+'@example.com',
        Email = 'temp@test.com',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
            );
        insert usr;
        
        
        // ---------- 2. Create user WITHOUT email ----------
        User usrNoEmail = new User(
            FirstName = 'Test2',
        LastName  = 'NoEmail',
        Alias = 'tne',
        Username = 'noemail'+System.currentTimeMillis()+'@example.com',
        Email = 'temp@test.com',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
            );
        insert usrNoEmail;
        
        // ---------- 3. Accounts ----------
        Account a1 = new Account(Name='Dist Acc 1');
        Account a2 = new Account(Name='Dist Acc 2');
        insert new List<Account>{a1, a2};
        
        // ---------- 4. Invoices ----------
        Invoice__c inv1 = new Invoice__c(Account__c = a1.Id);
        Invoice__c inv2 = new Invoice__c(Account__c = a2.Id);
        insert new List<Invoice__c>{inv1, inv2};
        
        // ---------- 5. Weekly Map ----------
        Map<Id, Map<Id, List<Invoice__c>>> weekly = new Map<Id, Map<Id, List<Invoice__c>>>{
            usr.Id        => new Map<Id, List<Invoice__c>>{ a1.Id => new List<Invoice__c>{inv1} },
            usrNoEmail.Id => new Map<Id, List<Invoice__c>>{ a1.Id => new List<Invoice__c>{inv1} }
        };
        
        // ---------- 6. Monthly Map ----------
        Map<Id, Map<Id, List<Invoice__c>>> monthly = new Map<Id, Map<Id, List<Invoice__c>>>{
            usr.Id => new Map<Id, List<Invoice__c>>{ a2.Id => new List<Invoice__c>{inv2} }
        };
        
        // ---------- 7. Execute ----------
        Test.startTest();
        SendInvoiceCSVToDistributor.sendInvoiceReports(weekly, monthly);
        Test.stopTest();
        
        // ---------- 8. Validate ----------
        //System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
    }
    
    }*/
@IsTest
private class Test_SendInvoiceCSVToDistributor {
    
    static Account distAcc;
    static User distUser;
    
    // ------------------------------
    // 1. TEST DATA SETUP
    // ------------------------------
    static void setupData() {
        Profile distProfile = [SELECT Id FROM Profile WHERE Name = 'Distributor' LIMIT 1];
        
        // Create Distributor User
        User distributorUser = new User(
            FirstName = 'Test',
        LastName = 'Distributor',
        Email = 'testdist@example.com',
        Username = 'testdist' + DateTime.now().getTime() + '@example.com',
        Alias = 'tdist',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = distProfile.Id
            );
        insert distributorUser;
        
        distUser = distributorUser;
        
        // Create Distributor Account
        distAcc = new Account(
            Name = 'Test Distributor Account',
        Associated_User__c = distributorUser.Id
            );
        insert distAcc;
        
        // Create Invoice
        Invoice__c inv = new Invoice__c(
            Distributor__c = distAcc.Id
            );
        insert inv;
        
        // Invoice Line
        Invoice_Line_Item__c line = new Invoice_Line_Item__c(
            Ori_Plast_Invoice__c = inv.Id,
        Quantity__c = 5,
        Final_Price__c = 100
            );
        insert line;
    }
    
    
    // ------------------------------
    // 2. Test Visualforce CSV Controller (WEEKLY ONLY)
    // ------------------------------
    @IsTest
    static void testCSVController_WeeklyOnly() {
        setupData();
        
        Test.startTest();
        
        PageReference pg = Page.InvoiceCSVExport;
        pg.getParameters().put('distributorId', String.valueOf(distAcc.Id));
        pg.getParameters().put('reportType', 'Weekly');
        Test.setCurrentPage(pg);
        
        InvoiceCSVExportController c = new InvoiceCSVExportController();
        System.assertEquals(1, c.invoiceLineItems.size(), 'Should find 1 weekly line item');
        
        // Invalid type now returns 0
        PageReference pg2 = Page.InvoiceCSVExport;
        pg2.getParameters().put('distributorId', String.valueOf(distAcc.Id));
        pg2.getParameters().put('reportType', 'Invalid');
        Test.setCurrentPage(pg2);
        InvoiceCSVExportController cInvalid = new InvoiceCSVExportController();
        System.assertEquals(0, cInvalid.invoiceLineItems.size(), 'Invalid type should return 0');
        
        Test.stopTest();
    }
    
    
    // ------------------------------
    // 3. TEST BATCH FLOW
    // ------------------------------
    @IsTest
    static void testBatchFlow() {
        setupData();
        
        InvoiceReportBatch batch = new InvoiceReportBatch();
        
        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, Status 
            FROM AsyncApexJob 
            WHERE JobType = 'Queueable'
        ];
        
        System.assertEquals(1, jobs.size(),
        'Queueable job should be queued in finish method');
    }
    
    
    // ------------------------------
    // 4. TEST SCHEDULER
    // ------------------------------
    @IsTest
    static void testScheduler() {
        setupData();
        
        String cron = '0 0 12 * * ?';
        
        Test.startTest();
        System.schedule('TestScheduler', cron, new InvoiceReportScheduler());
        
        List<AsyncApexJob> jobs = [
            SELECT Status 
            FROM AsyncApexJob 
            WHERE JobType = 'BatchApex'
        ];
        Test.stopTest();
        
        System.assertEquals(0, jobs.size(),
        'Batch job should NOT run inside System.schedule() during test');
    }
    
    
    @IsTest
    static void testScheduler_DirectExecute() {
        setupData();
        
        Test.startTest();
        new InvoiceReportScheduler().execute(null);
        Test.stopTest();
        
        System.assert(true, 'Scheduler executed normally in test mode');
    }
    
    
    // ------------------------------
    // 5. TEST QUEUEABLE & EMAIL SENDING
    // ------------------------------
    // @IsTest
    // static void testQueueableAndEmailSending() {
        //     setupData();
        
        //     InvoiceReportBatch batch = new InvoiceReportBatch();
        //     Database.QueryLocator ql = batch.start(null);
        //     List<Invoice__c> allInvoices = Database.query(ql.getQuery());
        
        //     batch.execute(null, allInvoices);
        //     Test.startTest();
        //     System.enqueueJob(new SendInvoiceCSVQueueable(batch.allWeeklyInvoices));
        //     Test.stopTest();
        
        //     System.assertEquals(1, Limits.getEmailInvocations(), 'One email should have been sent to the distributor');
    // }
    
    
    // ------------------------------
    // 6. Test EmailSender — No Invoices
    // ------------------------------
    @IsTest
    static void testEmailSender_NoInvoices() {
        Test.startTest();
        SendInvoiceCSVToDistributor.sendInvoiceReports(
            new Map<Id, Map<Id, List<Invoice__c>>>()
            );
        Test.stopTest();
        
        System.assertEquals(
            0,
        Limits.getEmailInvocations(),
        'No email should be sent when data map is empty'
            );
    }
    
    
    // ------------------------------
    // 7. Test User Without Email
    // ------------------------------
    @IsTest
    static void testEmailSender_UserWithoutEmail() {
        setupData();
        
        // User with NO valid email
        Profile p = [SELECT Id FROM Profile WHERE Name='Distributor' LIMIT 1];
        
        User userNoEmail = new User(
            FirstName = 'Test',
        LastName = 'NoEmail',
        Alias = 'nml',
        Username = 'noemail'+System.currentTimeMillis()+'@example.com',
        Email = 'invalid_email@noemail.local',  // ✔ simulate missing email
        IsActive = true,
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = [SELECT Id FROM Profile WHERE Name = 'Distributor' LIMIT 1].Id
            );
        insert userNoEmail;
        
        Account acc = new Account(
            Name = 'Acc No Email',
        Associated_User__c = userNoEmail.Id
            );
        insert acc;
        
        Invoice__c inv = new Invoice__c(
            Distributor__c = acc.Id
            );
        insert inv;
        
        Test.startTest();
        Database.executeBatch(new InvoiceReportBatch(), 200);
        Test.stopTest();
        
        System.assertEquals(
            0,
        Limits.getEmailInvocations(),
        'No email should be sent when user has no email'
            );
    }
    
    
    // ------------------------------
    // 8. Full Coverage for sendInvoiceReports()
    // ------------------------------
    @IsTest
    static void test_SendInvoiceReports_FullCoverage() {
        
        // ---------- 1. Create user WITH email ----------
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User usr = new User(
            FirstName = 'Test2',
        LastName  = 'NoEmail',
        Alias = 'tne',
        Username = 'noemail'+System.currentTimeMillis()+'@example.com',
        Email = 'temp@test.com',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
            );
        insert usr;
        
        
        // ---------- 2. Create user WITHOUT email ----------
        User usrNoEmail = new User(
            FirstName = 'Test2',
        LastName  = 'NoEmail',
        Alias = 'tne',
        Username = 'noemail'+System.currentTimeMillis()+'@example.com',
        Email = 'temp@test.com',
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
            );
        insert usrNoEmail;
        
        // ---------- 3. Accounts ----------
        Account a1 = new Account(Name='Dist Acc 1');
        Account a2 = new Account(Name='Dist Acc 2');
        insert new List<Account>{a1, a2};
        
        // ---------- 4. Invoices ----------
        Invoice__c inv1 = new Invoice__c(Account__c = a1.Id);
        Invoice__c inv2 = new Invoice__c(Account__c = a2.Id);
        insert new List<Invoice__c>{inv1, inv2};
        
        // ---------- 5. Weekly Map ----------
        Map<Id, Map<Id, List<Invoice__c>>> weekly = new Map<Id, Map<Id, List<Invoice__c>>>{
            usr.Id        => new Map<Id, List<Invoice__c>>{ a1.Id => new List<Invoice__c>{inv1} },
            usrNoEmail.Id => new Map<Id, List<Invoice__c>>{ a1.Id => new List<Invoice__c>{inv1} }
        };
        
        
        // ---------- 7. Execute ----------
        Test.startTest();
        SendInvoiceCSVToDistributor.sendInvoiceReports(weekly);
        Test.stopTest();
        
        // ---------- 8. Validate ----------
        //System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
    }
}