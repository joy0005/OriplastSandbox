/**
 * @description       : The InvoiceLineItmUpdateOriPlastProductBatch class is an Apex batch class designed to facilitate 
 *                      the updation of "Ori_Plast_Product__c" field of
 *                      Invoice Line Item records based on data stored in custom objects of the 
 *                      Product_Transformation_Table__c record. It implements both the Database.Batchable and Schedulable interfaces, allowing for 
 *                      manual execution as a batch job or scheduled automatic execution.
 * @author            : D. K. Sinha
 * @last modified on  : 
 * @last modified by  : 
**/
public class InvoiceLineItmUpdateOriPlastProductBatch implements Database.Batchable<SObject>, Database.Stateful{
   

    private String batchRunScenario;

    // Constructor with parameter to determine query scope
    public InvoiceLineItmUpdateOriPlastProductBatch(String batchRunScenario) {
        this.batchRunScenario = batchRunScenario;
    }

    public InvoiceLineItmUpdateOriPlastProductBatch() {
    }

    // Query Invoice Line Item records based on batchRunScenario
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, SKU__c, Ori_Plast_Product__c, Ori_Plast_Invoice__c, Ori_Plast_Invoice__r.Distributor__c ' +
                       'FROM Invoice_Line_Item__c';
        
        // Add WHERE clause only if processing records created today
        if (batchRunScenario != 'FULL') {
            query += ' WHERE CreatedDate = TODAY';
        }
        system.debug('query '+query);

        return Database.getQueryLocator(query);
    }


    public void execute(Database.BatchableContext BC, List<Invoice_Line_Item__c> invoiceLineItems) {
        
        try {
            Map<String, String> productTransformationMap = new Map<String, String>();
            List<Invoice_Line_Item__c> itemsToUpdate = new List<Invoice_Line_Item__c>();
            List<String> invoLineItmSKUList = new List<String>();

            for(Invoice_Line_Item__c item : invoiceLineItems) {
               String modifiedSKU = item.SKU__c;
               invoLineItmSKUList.add(modifiedSKU);
            }
            
            System.debug('invoLineItmSKUList ====== : ' + JSON.serialize(invoLineItmSKUList));

            //** Load Product_Transformation_Table__c data into the map
            List<Product_Transformation_Table__c> productTransformationRecords = [SELECT Account__c,Tally_Item_Description__c, Ori_Plast_Product__c FROM Product_Transformation_Table__c WHERE Tally_Item_Description__c IN: invoLineItmSKUList]; 

            System.debug('productTransformationRecords=======: ' + productTransformationRecords);
            
            if(!productTransformationRecords.isEmpty()){
                //** Populating the map with SKU and Product ID
                for(Product_Transformation_Table__c ptt : productTransformationRecords) {
                    if(!String.isBlank(ptt.Tally_Item_Description__c) && !String.isBlank(ptt.Ori_Plast_Product__c)) {                                              
                        productTransformationMap.put(ptt.Tally_Item_Description__c+';'+ptt.Account__c,ptt.Ori_Plast_Product__c);
                    }
                }
             

                for(Invoice_Line_Item__c item : invoiceLineItems) {
                    String accID = String.ValueOf(item.Ori_Plast_Invoice__r.Distributor__c);
                    String modifiedSKU = item.SKU__c+';'+accID;
                    
                    //** Check if SKU__c matches with Tally_Item_Description__c in the Product Transformation Map
                    if(!String.isBlank(modifiedSKU) && productTransformationMap.containsKey(modifiedSKU)){
                        item.Ori_Plast_Product__c = productTransformationMap.get(modifiedSKU);
                        itemsToUpdate.add(item);
                    }
                }

                if(!itemsToUpdate.isEmpty()) {
                    System.debug('itemsToUpdate: ' +JSON.serialize(itemsToUpdate));
                    
                    Database.SaveResult[] updateResults = Database.update(itemsToUpdate, false);
                    for (Database.SaveResult sr : updateResults){
                        if (!sr.isSuccess()){
                            CreateTransactionLog.log('Error', 'InvoiceLineItmUpdateOriPlastProductBatch', 'execute','Update failed for Invoice Line Item with Id: ' + sr.getId() + '. Error: ' + sr.getErrors()[0].getMessage(),  null, null,null, null);
                        }
                    }
                }else{
                    System.debug('No invoice litem matches with the SKU in Product Transformation Table. Hence, cannot find the Ori_Plast_Product__c to update.');
                }
            }else{
                System.debug('No invoice litem matches with the SKU in Product Transformation Table. Hence, cannot find the Ori_Plast_Product__c to update.');
            }
        } catch(Exception ex) {
            System.debug(ex.getMessage());
            CreateTransactionLog.log( 'Error', 'InvoiceLineItmUpdateOriPlastProductBatch','execute', ex.getMessage(), null, null , ex.getStackTraceString(), null);
        }
    }


    public void finish(Database.BatchableContext BC) {
        
    }

    public void execute(SchedulableContext SC){  
        InvoiceLineItmUpdateOriPlastProductBatch iliUpdateOriPlastProductBatch = new InvoiceLineItmUpdateOriPlastProductBatch();
        Database.executeBatch(iliUpdateOriPlastProductBatch,2);
    }
}