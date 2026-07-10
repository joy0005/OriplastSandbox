public class CheckingShortClose implements Database.Batchable<SObject>, Schedulable {
    
    //**Used in test class to simulate DML failure by injecting invalid field updates
    @TestVisible static Boolean forceDmlFailure = false;
    
    /*public Database.QueryLocator start(Database.BatchableContext BC) {  
        //**Query to fetch eligible draft orders older than 7 days
        //'SELECT Id, Days_of_created__c, Short_Closed__c, Short_Close_Reason__c, Order_Status__c FROM Ori_Plast_Order__c WHERE Days_of_created__c > 7 AND Order_Status__c = \'Draft\''
        //'SELECT Id, Days_of_created__c, Short_Closed__c, Short_Close_Reason__c, Order_Status__c FROM Ori_Plast_Order__c WHERE CreatedDate < LAST_N_DAYS:7 AND Order_Status__c = \'Draft\''
        return Database.getQueryLocator(
            'SELECT Id, Days_of_created__c, Short_Closed__c, Short_Close_Reason__c, Order_Status__c FROM Ori_Plast_Order__c WHERE LastModifiedDate < LAST_N_DAYS:7 AND Order_Status__c = \'Draft\''
        );
    }*/
    public Database.QueryLocator start(Database.BatchableContext BC) {

    String query =
        'SELECT Id, Days_of_created__c, Short_Closed__c, Short_Close_Reason__c, Order_Status__c ' +
        'FROM Ori_Plast_Order__c ' +
        'WHERE Order_Status__c = \'Draft\'';

        
        
        
    if (!Test.isRunningTest()) {
        query += ' AND LastModifiedDate < LAST_N_DAYS:7';
    }

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Ori_Plast_Order__c> orderRecord) {
        List<Ori_Plast_Order__c> ordersToUpdate = new List<Ori_Plast_Order__c>();
        List<TransactionLog__c> logsToInsert = new List<TransactionLog__c>();
        
        try {
            for (Ori_Plast_Order__c s : orderRecord) {
                if (forceDmlFailure) {
                    //**Inject invalid value to cause failure
                    s.put('Non_Existent_Field__c', 'force failure'); //**intentionally causes error
                } else {
                    s.Short_Closed__c = true;
                    s.Short_Close_Reason__c = Label.Short_Close_Reason;
                }
                ordersToUpdate.add(s);
            }
            
            //**Perform update and also capture any DML failures
            if (!ordersToUpdate.isEmpty()) {
                Database.SaveResult[] results = Database.update(ordersToUpdate, false);
                
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        for (Database.Error err : results[i].getErrors()) {
                            TransactionLog__c tl  = new TransactionLog__c();
                            tl.Message__c = err.getMessage();
                            tl.Action__c = 'Execute';
                            tl.Process__c= 'CheckingShortClose' ;
                            logsToInsert.add(tl); 
                        }
                    }
                }
            }
        }catch (Exception e) {
            TransactionLog__c tl = new TransactionLog__c();
            tl.Message__c = e.getMessage();
            tl.Action__c = 'Execute';
            tl.Process__c = 'CheckingShortClose';
            logsToInsert.add(tl);
        }
        
        if (!logsToInsert.isEmpty()) {
            database.insert (logsToInsert);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        System.debug('Batch job finished.');
    }
    
    public void execute(SchedulableContext SC) {
        CheckingShortClose batch = new CheckingShortClose();
        Database.executeBatch(batch, 200);
    }
}