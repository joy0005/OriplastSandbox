// pratik mondal

public with sharing class DistributorAccountController {

    @AuraEnabled(cacheable=true)
    public static List<Account> getDistributorAccounts(){

        return [
            SELECT Id, Name
            FROM Account
            WHERE Associated_User__c != NULL
            AND Associated_User__r.IsActive = true
            AND Associated_User__r.Profile.Name = 'Distributor'
            ORDER BY Name
        ];
    }

    @AuraEnabled
    public static String updateAccountLimit(
        Id accountId,
        List<Id> accountIds,
        Date startDate,
        Integer duration,
        Decimal newLimit
    )
    {

        List<Account> accList = new List<Account>();
        Boolean isHistoryNearLimit = false;

        //
        List<String> warningAccounts = new List<String>();

        // Handle ALL SELECTED
        if(accountIds != null && !accountIds.isEmpty()){
            accList = [
                SELECT Id, Name, Current_Limit__c, History__c
                FROM Account
                WHERE Id IN :accountIds
            ];
        }
        // Handle SINGLE ACCOUNT
        else{

            if(accountId == null){
                throw new AuraHandledException('Please select an Account');
            }

            accList = [
                SELECT Id, Name, Current_Limit__c, History__c
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];
        }

        Date endDate = startDate.addDays(duration);

        for(Account acc : accList){

            //  History length check
            if(acc.History__c != null && acc.History__c.length() > 120500){
                isHistoryNearLimit = true;

                
                warningAccounts.add(acc.Name);
            }

            String historyEntry =
                'Previous Limit: ' + acc.Current_Limit__c +
                ' → New Limit: ' + newLimit +
                ' | Start: ' + String.valueOf(startDate) +
                ' | End: ' + String.valueOf(endDate) +
                ' | Updated On: ' + String.valueOf(Date.today());

            if(String.isNotBlank(acc.History__c)){
                acc.History__c = acc.History__c + '\n' + historyEntry;
            } 
            else{
                acc.History__c = historyEntry;
            }

            acc.Start_Date__c = startDate;
            acc.Duration__c = duration;
            acc.Enhance_Limit__C = newLimit;
            acc.Current_Limit__c = newLimit;
        }

        update accList;

        // message
        if(isHistoryNearLimit){
            return 'Limit Updated Successfully! But History limit reached for: ' 
                + String.join(warningAccounts, ', ') + '. Remove few lines from history fields';
        }

        if(accList.size() > 1){
            return 'Limit Updated for ' + accList.size() + ' Accounts';
        }

        return 'Limit Updated Successfully!';
    }
}