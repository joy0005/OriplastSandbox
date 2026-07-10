public with sharing class InvoiceReminderController {

    @AuraEnabled
    public static String getReminderMessage() {

        // 1️ Get current user
        User distUser = [
            SELECT Id, Name, Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        // 2️ Only Distributor profile should proceed
        // System Admin & all other profiles automatically excluded
        if(distUser.Profile.Name == null || distUser.Profile.Name != 'Distributor'){
            return null;
        }

        // 3 Find Distributor Account mapped to user
        List<Account> accList = [
            SELECT Id, Name
            FROM Account
            WHERE Associated_User__c = :distUser.Id
            LIMIT 1
        ];

        // If account not mapped → show reminder
        if(accList.isEmpty()){
            return buildMessage(distUser.Name);
        }

        Id distributorAccountId = accList[0].Id;

        // 4️ Check invoices in last 3 calendar days
     // Check invoices in last 3 calendar days
      Date startDate = Date.today().addDays(-3);
      DateTime startDateTime = DateTime.newInstance(startDate, Time.newInstance(0,0,0,0));

   Integer invCount = [
    SELECT COUNT()
    FROM Invoice__c
    WHERE Account__c = :distributorAccountId
    AND CreatedDate >= :startDateTime
];


        // 5️⃣ If no invoice found → show popup
        if(invCount == 0){
            return buildMessage(distUser.Name);
        }

        return null;
    }


    // Build popup message
    private static String buildMessage(String userName){

        return 'Hello ' + userName + ',\n\n' +
        'This is a gentle reminder that we have not received your secondary sales data in Salesforce for the past three days.' +
        ' We request you to kindly update the pending secondary sales entries at the earliest, preferably today.\n\n';
    }
}