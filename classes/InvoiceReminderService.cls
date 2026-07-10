public with sharing class InvoiceReminderService {

    // Test hook – lets us assert emails in test class
    @TestVisible
    static List<Messaging.SingleEmailMessage> lastEmailsSent;
    private static final List<String> CC_EMAILS = new List<String>{
        'amanna@oriplast.in',
        'spodder@oriplast.in',
        'anupbrata@gmail.com',
        'alokdalai@oriplast.in',
        'ayantika_c@pursuitsoftware.com',
        'saikat.paul@halsaglobal.io'
    };
    /**
     * Entry point – call this from a Scheduler or directly.
     * Logic:
     * 1. Find active users whose Profile.Name = 'Distributor'
     * 2. Find their Distributor Accounts (Account.Associated_User__c)
     * 3. Check which Accounts have Invoice__c in last 3 days
     * 4. For users whose Accounts have NO recent invoices → send mail
     */
    public static void sendInvoiceReminders() {
        lastEmailsSent = new List<Messaging.SingleEmailMessage>();

        // 1. Active Distributor users
        List<User> distributorUsers = [
            SELECT Id, Name, Email
            FROM User
            WHERE IsActive = true
            AND Profile.Name = 'Distributor'
            AND Email != null
        ];

        if (distributorUsers.isEmpty()) {
            return;
        }

        Map<Id, User> userById = new Map<Id, User>(distributorUsers);

        // 2. Accounts where Associated_User__c is a distributor user
        List<Account> distributorAccounts = [
            SELECT Id, Name, Associated_User__c
            FROM Account
            WHERE Associated_User__c IN :userById.keySet()
        ];

        if (distributorAccounts.isEmpty()) {
            return;
        }

        // Map User -> list of Account Ids (a distributor user can have multiple accounts)
        Map<Id, List<Id>> userIdToAccountIds = new Map<Id, List<Id>>();
        for (Account acc : distributorAccounts) {
            if (!userIdToAccountIds.containsKey(acc.Associated_User__c)) {
                userIdToAccountIds.put(acc.Associated_User__c, new List<Id>());
            }
            userIdToAccountIds.get(acc.Associated_User__c).add(acc.Id);
        }

        Set<Id> distributorAccountIds = new Set<Id>();
        for (Account acc : distributorAccounts) {
            distributorAccountIds.add(acc.Id);
        }

        // 3. Find Accounts that HAVE invoices in last 3 days
        Datetime cutoff = Datetime.now().addDays(-3);

        Set<Id> accountsWithRecentInvoices = new Set<Id>();
        for (AggregateResult ar : [
            SELECT Distributor__c distributorId
            FROM Invoice__c
            WHERE Distributor__c IN :distributorAccountIds
            AND CreatedDate >= :cutoff
            GROUP BY Distributor__c
        ]) {
            Id accId = (Id) ar.get('distributorId');
            accountsWithRecentInvoices.add(accId);
        }

        // 4. Decide which Distributor users should get email
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (User distUser : distributorUsers) {
            List<Id> accIds = userIdToAccountIds.get(distUser.Id);

            // If user has no Accounts mapped, skip (or treat differently if business wants)
            if (accIds == null || accIds.isEmpty()) {
                continue;
            }

            Boolean hasRecentInvoice = false;
            for (Id accId : accIds) {
                if (accountsWithRecentInvoices.contains(accId)) {
                    hasRecentInvoice = true;
                    break;
                }
            }

            // If NO recent invoice under this distributor -> send mail
            if (!hasRecentInvoice) {
                emailsToSend.add(buildReminderEmail(distUser));
            }
        }

        // Save for tests
        lastEmailsSent.addAll(emailsToSend);

        // Send emails in chunks of 10 (governor limit)
        if (!Test.isRunningTest() && !emailsToSend.isEmpty()) {
            for (Integer i = 0; i < emailsToSend.size(); i += 10) {
    List<Messaging.SingleEmailMessage> chunk = new List<Messaging.SingleEmailMessage>();

    for (Integer j = i; j < i + 10 && j < emailsToSend.size(); j++) {
        chunk.add(emailsToSend[j]);
    }

    Messaging.sendEmail(chunk);
}

        }
    }

    // Helper to build email message
    private static Messaging.SingleEmailMessage buildReminderEmail(User distUser) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        //email.setToAddresses(new List<String>{'ayantika_c@pursuitsoftware.com'});
        email.setToAddresses(new List<String>{ distUser.Email });
        email.setCcAddresses(CC_EMAILS);
        email.setSubject('Invoice not created in last 3 days');
        email.setPlainTextBody(
            'Hello ' + distUser.Name + ',\n\n' +
            'This is a gentle reminder that we have not received your secondary sales data in Salesforce for the past three days.'+
            'We request you to kindly update the pending secondary sales entries at the earliest, preferably today.\n\n'+
            'Best Regards,\n' +
            'Salesforce System'
        );
        return email;
    }
}