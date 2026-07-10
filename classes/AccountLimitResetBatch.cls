/* Pratik Mondal    25-02-2026
 * This batch class runs to identify Accounts with an active enhanced limit 
 and checks whether the enhancement period has expired. 
 If expired, it calls the service class to reset the limits and update the history accordingly. */

global class AccountLimitResetBatch implements Database.Batchable<SObject>{

    global Database.QueryLocator start(Database.BatchableContext bc){

        return Database.getQueryLocator(
            'SELECT Id, Name, Current_Limit__c, Enhance_Limit__c, Start_Date__c, Duration__c, End_Date__c, History__c ' +
            'FROM Account ' +
            'WHERE End_Date__c != NULL ' +
             'AND Enhance_Limit__c != 0'
        );
    }

    global void execute(Database.BatchableContext bc, List<Account> scope){

        List<Account> eligibleAccounts = new List<Account>();

        for(Account acc : scope){
            if(acc.Enhance_Limit__c != null &&
               acc.Current_Limit__c != null &&
               acc.Enhance_Limit__c == acc.Current_Limit__c){
                eligibleAccounts.add(acc);
            }
        }

        if(!eligibleAccounts.isEmpty()){
            AccountLimitService.resetExpiredLimits(eligibleAccounts);
        }
    }

    global void finish(Database.BatchableContext bc){
        system.debug('success');
    }
}