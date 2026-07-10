/**
 * @description       : The TallyBatchInvoiceInvoiceLineItemCreation class is an Apex class designed to facilitate the creation of 
 *                      Salesforce Invoice and Invoice Line Item records based on data stored in custom objects of the 
 *                      Staging__c type. It implements both the Database.Batchable and Schedulable interfaces, allowing for 
 *                      manual execution as a batch job or scheduled automatic execution.
 * @author            : D. K. Sinha
 * @last modified on  : 
 * @last modified by  : 
**/
global class TallyBatchInvoiceInvoiceLineItemCreation implements Database.Batchable<SObject>, schedulable {
    
    private String batchRunScenario;

    // Constructor with parameter to determine scope for chained batch
    global TallyBatchInvoiceInvoiceLineItemCreation(String batchRunScenario) {this.batchRunScenario = batchRunScenario;}

    global TallyBatchInvoiceInvoiceLineItemCreation() {
    }

     global Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator([SELECT Id,JSON_Payload__c from Staging__c where Status__c = 'Pending']);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope){
        try {
            if(!scope.isEmpty()) Create_Inv_InvLineItm_controller.createInvoice(scope);
        } catch(Exception ex) {System.debug(ex.getMessage()); CreateTransactionLog.log( 'Error', 'TallyBatchInvoiceInvoiceLineItemCreation','execute', ex.getMessage(), null, null , ex.getStackTraceString(), null);}
    } 

    global void finish(Database.BatchableContext BC){
        InvoiceLineItmUpdateOriPlastProductBatch batch = new InvoiceLineItmUpdateOriPlastProductBatch(batchRunScenario);
        Database.executeBatch(batch);
    }
    
    global void execute(SchedulableContext SC){  
        TallyBatchInvoiceInvoiceLineItemCreation tallyBatch = new TallyBatchInvoiceInvoiceLineItemCreation();
        Database.executeBatch(tallyBatch,2);
    }
}