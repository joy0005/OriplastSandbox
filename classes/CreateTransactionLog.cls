/**
 * @description       : The CreateTransactionLog class is an Apex class designed to facilitate the creation of 
 * 						Salesforce Transaction log records when any error occored during transaction.
 * @author            : D. K. Sinha
 * @last modified on  : 
 * @last modified by  : 
**/
public without sharing class CreateTransactionLog {
    // private static List<TransactionLog__c> transactionLogs = new List<TransactionLog__c>();

    private static List<TransactionLog__c> createEventLog(String logLevel, String className, String methodName, String message, String context, String summary ,  String stackTrace , String referenceId) {

        List<TransactionLog__c> transactionLogs = new List<TransactionLog__c>();

        TransactionLog__c transactionLog =new TransactionLog__c();
        transactionLog.Severity__c = logLevel;
        transactionLog.Process__c = className;
        transactionLog.Action__c = methodName;
        transactionLog.Message__c = message;
        transactionLog.Context__c = context;
        transactionLog.Stack_Trace__c = stackTrace;
        transactionLog.User__c = Userinfo.getUserId();
        transactionLog.Summary__c = summary;
        transactionLog.Reference__c = referenceId;

        // insert transactionLog;
        transactionLogs.add(transactionLog);
       
        return transactionLogs;
    }
   
    public static List<TransactionLog__c> log(String logLevel, String className, String methodName, String message, String context, String summary, String stackTrace , String referenceId) {
  
        List<TransactionLog__c> transactionLogsList = createEventLog( logLevel,  className,  methodName,  message,  context,  summary, stackTrace ,  referenceId);
        return transactionLogsList;
        //insertLogs(transactionLogsList);
    }

    // ** Insert transaction log & Clear the list after insertion
    public static void insertLogs(List<TransactionLog__c> insertTransactionLogs) {
        if (!insertTransactionLogs.isEmpty()) {
            System.debug('insertTransactionLogs:' + insertTransactionLogs);
            Database.insert(insertTransactionLogs,false);
            insertTransactionLogs.clear();
        }
    }
}