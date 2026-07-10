//Pratik mondal

global without sharing class AccountLimitService {

    // this method will reset the fields to original values also update history fields
    // if the end date is less than today's date
    global static void resetExpiredLimits(List<Account> scopeAccounts){

        List<Account> accountsToUpdate = new List<Account>();
        Decimal baseLimit = Decimal.valueOf(System.Label.Current_Limit_for_Account);
        Boolean isHistoryNearLimit = false; 

        for(Account acc : scopeAccounts){

            if(acc.End_Date__c == null) continue;

            if(acc.End_Date__c < Date.today()){

                // History length check
                if(acc.History__c != null && acc.History__c.length() > 120500){
                    isHistoryNearLimit = true;
                }

                String historyEntry =
                    'Enhanced limit expired on ' + String.valueOf(acc.End_Date__c) +
                    ' and reset to original limit ' + String.valueOf(baseLimit) +
                    ' | Auto Reset On: ' + String.valueOf(Date.today());

                if(String.isNotBlank(acc.History__c)){
                    acc.History__c += '\n' + historyEntry;
                }else{
                    acc.History__c = historyEntry;
                }

                acc.Start_Date__c = null;
                acc.Duration__c = null;
                acc.Enhance_Limit__c = 0;
                acc.Current_Limit__c = baseLimit;

                accountsToUpdate.add(acc);
            }
        }

        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate;
        }

        //Batch cannot show toast, so no return/throw used
        if(isHistoryNearLimit){
            System.debug('⚠️ History field is reaching its limit for some accounts');
        }
    }
}