/**
 * @description       : This will replace the JSON  received by the tally integration & this class is called in "TallyBatchInvoiceInvoiceLineItemCreation" batch class.
 * @author            : D. K. Sinha
 * @group             :
 * @last modified on  : 16-04-2024
 * @last modified by  : 
 **/


public without sharing class Create_Inv_InvLineItm_controller {

    public static List<TransactionLog__c> insertTransactionLogs;

    public static void createInvoice(List<Staging__c> scope) {
        List<String> distributorIdentificationKeys = new List<String>();
        insertTransactionLogs = new List<TransactionLog__c>();

        extractDealerNamesAndDistributorKeys(scope, distributorIdentificationKeys);
        Map<String, String> distributorMap = getDistributorMap(distributorIdentificationKeys);

        try {
            checkInvoiceStatusInJSON(scope, distributorMap);
        } catch(Exception ex) {
            System.debug(ex.getMessage());
            insertTransactionLogs.addAll(
                CreateTransactionLog.log('Error','InvoiceRecordCreationBatchController','execute',
                ex.getMessage(), null, null , ex.getStackTraceString(), null)
            );
        }
    }
    
    //***********************************************************

// This method removes duplicate invoice line items generated 
// from multiple staging records.
// It ensures only unique records (based on Invoice + SKU) are inserted.
//***********************************************************
public static void insertInvoiceLineitm(List<Invoice_Line_Item__c> lineItemRecordsToInsert) {

    System.debug('lineItemRecordsToInsert INV++++++ : ' + lineItemRecordsToInsert);

    try {

        if (!lineItemRecordsToInsert.isEmpty()) {

            // Remove duplicates based on Invoice + SKU
            Map<String, Invoice_Line_Item__c> uniqueLineItemMap = new Map<String, Invoice_Line_Item__c>();

            for (Invoice_Line_Item__c item : lineItemRecordsToInsert) {

                String key = item.Ori_Plast_Invoice__c + '-' + item.SKU__c;

                if (!uniqueLineItemMap.containsKey(key)) {
                    uniqueLineItemMap.put(key, item);
                }
            }

            List<Invoice_Line_Item__c> finalLineItems = uniqueLineItemMap.values();

            System.debug('Unique Line Items to insert: ' + finalLineItems);

            Database.insert(finalLineItems, false);

            lineItemRecordsToInsert.clear();
        }

    } catch (Exception ex) {

        System.debug(ex.getMessage());

        insertTransactionLogs.addAll(
            CreateTransactionLog.log(
                'Error',
                'insertInvoiceLineitm',
                'execute',
                ex.getMessage(),
                null,
                null,
                ex.getStackTraceString(),
                null
            )
        );
    }
}

    private static void checkInvoiceStatusInJSON(List<Staging__c> scope, Map<String, String> distributorMap) {

        Set<ID> successInvoiveId = new Set<ID>();
        Set<Id> skippedStagingIds = new Set<Id>();

        Map<String,Id> invNumberMap = new Map<String,Id>();
        List<Invoice__c> invRecListToBeUpsert = new List<Invoice__c>();
        List<Staging__c> updateStgRec = new List<Staging__c>();
        List<Invoice_Line_Item__c> lineItemRecordsToInsert = new List<Invoice_Line_Item__c>();

        for (Staging__c stg : scope) {

            String invNumber = '';
            Integer successINVCount = 0;
            Staging__c updateStg = new Staging__c();

            try {
                TallyJsonDataObject payloadObj = (TallyJsonDataObject) JSON.deserialize(stg.JSON_Payload__c, TallyJsonDataObject.class);

                if(payloadObj.invoiceDetails != null){

                    for (TallyJsonDataObject.InvoiceDetails invoiceDetails : payloadObj.invoiceDetails) {

                        if(invoiceDetails.InvoiceStatus == 'Cancelled'){

                            invRecListToBeUpsert.addAll(
                                InvoiceRecordCreationBatchController_V1.cancelledInvoice(
                                    invoiceDetails.InvoiceStatus,
                                    invoiceDetails.InvoiceNumber
                                )
                            );
                            successINVCount++;

                        }else if(invoiceDetails.DealerDetails != null &&
                                 invoiceDetails.InvoiceDate != null &&
                                 invoiceDetails.invoiceLineItems != null &&
                                 invoiceDetails.InvoiceNumber != null &&
                                 invoiceDetails.InvoiceStatus != null &&
                                 invoiceDetails.DealerDetails.Name != null &&
                                 payloadObj.DistributorIdentificationKey != null){

                            invNumber = invoiceDetails.InvoiceNumber;

                            InvoiceRecordCreationBatchController_V1.InvoiceCreationParams params =
                                new InvoiceRecordCreationBatchController_V1.InvoiceCreationParams();

                            params.invoiceDetails = invoiceDetails;
                            params.distributorMap = distributorMap;

                            // comment this block to skip
                             /*if(shouldSkipInvoice(
                                stg,
                                invoiceDetails,
                                payloadObj.DistributorIdentificationKey,
                                updateStgRec,
                                skippedStagingIds
                            )){
                                continue;
                            }*/

                            invRecListToBeUpsert.addAll(
                                InvoiceRecordCreationBatchController_V1.createInvoice(
                                    params,
                                    payloadObj.DistributorIdentificationKey
                                )
                            );

                            successINVCount++;
                        }
                    }

                    //  Status update (only if NOT skipped)
                    if(!skippedStagingIds.contains(stg.Id)){

                        if(payloadObj.invoiceDetails.size() == successINVCount){

                            updateStg.Id = stg.Id;
                            updateStg.Status__c = 'Processed';
                            updateStgRec.add(updateStg);

                        }else if(payloadObj.invoiceDetails.size() > successINVCount && successINVCount != 0){

                            updateStg.Id = stg.Id;
                            updateStg.Status__c = 'Partially Processed With Error';
                            updateStgRec.add(updateStg);

                        }else if(successINVCount == 0){

                            updateStg.Id = stg.Id;
                            updateStg.Status__c = 'Errors';
                            updateStgRec.add(updateStg);
                        }
                    }
                }

            } catch(Exception ex) {

                updateStg.Id = stg.Id;
                updateStg.Status__c = 'Errors';
                updateStgRec.add(updateStg);

                insertTransactionLogs.addAll(
                    CreateTransactionLog.log('Error','InvoiceRecordCreationBatchController','execute',
                    ex.getMessage(), null, null , ex.getStackTraceString(), null)
                );
            }
        }

        //  Insert invoices
        if(!invRecListToBeUpsert.isEmpty()){
            successInvoiveId = InvoiceRecordCreationBatchController_V1.insertInvoiceRecord(invRecListToBeUpsert);
        }

        //  Create line items (skip duplicates)
        if(!successInvoiveId.isEmpty()){

            List<Invoice__c> newInvoiceForLineItm = [
                SELECT Id, Invoice_Number__c
                FROM Invoice__c
                WHERE Id IN :successInvoiveId
            ];

            for(Invoice__c inv : newInvoiceForLineItm){
                invNumberMap.put(inv.Invoice_Number__c, inv.Id);
            }

            for(Staging__c stg : scope){

                //  SKIP duplicate staging
                if(skippedStagingIds.contains(stg.Id)){
                    continue;
                }

                try {
                    TallyJsonDataObject payloadObj = (TallyJsonDataObject) JSON.deserialize(stg.JSON_Payload__c, TallyJsonDataObject.class);

                    if(payloadObj.invoiceDetails != null){
                        lineItemRecordsToInsert.addAll(
                            InvLineItemRecCreationBatchController.createInvoiceLineItemRecords(
                                payloadObj.invoiceDetails,
                                invNumberMap
                            )
                        );
                    }

                } catch(Exception ex) {
                    insertTransactionLogs.addAll(
                        CreateTransactionLog.log('Error','InvoiceRecordCreationBatchController','execute',
                        ex.getMessage(), null, null , ex.getStackTraceString(), null)
                    );
                }
            }
        }

        if(!updateStgRec.isEmpty()){
            Database.update(updateStgRec, false);
        }

        insertInvoiceLineitm(lineItemRecordsToInsert);
    }

    //  Toggle Method
    //  if enabled this method (suppose same invoice came with two diff line items ) no new line items will insert it will skip that invoice totally
    /*private static Boolean shouldSkipInvoice(
        Staging__c stg,
        TallyJsonDataObject.InvoiceDetails invoiceDetails,
        String distributorKey,
        List<Staging__c> updateStgRec,
        Set<Id> skippedStagingIds
    ){
        String fyString = InvoiceRecordCreationBatchController_V1.getFinancialYearFromString(invoiceDetails.InvoiceDate);
        String externalKey = distributorKey + ';' + fyString + ';' + invoiceDetails.InvoiceNumber;

        List<Invoice__c> existingInv = [
            SELECT Id FROM Invoice__c
            WHERE Invoice_External_Key__c = :externalKey
            LIMIT 1
        ];

        if (!existingInv.isEmpty()) {

            Staging__c updateStg = new Staging__c();
            updateStg.Id = stg.Id;
            updateStg.Status__c = 'Processed';

            updateStgRec.add(updateStg);
            skippedStagingIds.add(stg.Id);

            return true;
        }

        return false;
    }*/

    private static void extractDealerNamesAndDistributorKeys(List<Staging__c> scope, List<String> distributorIdentificationKeys) {

        for (Staging__c stg : scope) {

            try {
                TallyJsonDataObject payloadObj = (TallyJsonDataObject) JSON.deserialize(stg.JSON_Payload__c, TallyJsonDataObject.class);

                if (payloadObj.invoiceDetails != null) {
                    for (TallyJsonDataObject.InvoiceDetails invoiceDetails : payloadObj.invoiceDetails) {
                        if (payloadObj.DistributorIdentificationKey != null) {
                            distributorIdentificationKeys.add(payloadObj.DistributorIdentificationKey);
                        }
                    }
                }

            } catch(Exception ex) {
                System.debug(ex.getMessage());
            }
        }
    }

    private static Map<String, String> getDistributorMap(List<String> distributorIdentificationKeys) {

        Map<String, String> distributorMap = new Map<String, String>();

        List<Account> distributorAccountList = [
            SELECT Id, Account_External_Key__c, Associated_User__c
            FROM Account
            WHERE Account_External_Key__c IN :distributorIdentificationKeys
        ];

        for (Account distributorAcc : distributorAccountList) {

            if(!String.isBlank(distributorAcc.Associated_User__c)){
                distributorMap.put(distributorAcc.Account_External_Key__c,
                    distributorAcc.Id + ';' + distributorAcc.Associated_User__c);
            } else {
                distributorMap.put(distributorAcc.Account_External_Key__c,
                    distributorAcc.Id + ';No Associated User');
            }
        }

        return distributorMap;
    }

    public static void insertTransactionLogs(){
        if(!insertTransactionLogs.isEmpty()){
            CreateTransactionLog.insertLogs(insertTransactionLogs);
        }
    }
}