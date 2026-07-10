/**
 * @description       : This class is creating Invoice Record and this class is using in "Create_Inv_InvLineItm_controller"
 * @author            : D. K. Sinha
 * @group             :
 * @last modified on  : 23-04-2024
 * @last modified by  : 
 **/

public without sharing class InvoiceRecordCreationBatchController_V1 {
private static List<Invoice__c> lineItemRecordsToInsert = new List<Invoice__c>();

   public static List<Invoice__c> cancelledInvoice(String invoiveStatus, String invoiceNumber) {
        List<Invoice__c> cancelInvRecList  = new List<Invoice__c>();
        Invoice__c cancelInvRec = new Invoice__c();

        cancelInvRec.Status__c = invoiveStatus;
        cancelInvRec.Invoice_Number__c = invoiceNumber;
        cancelInvRecList.add(cancelInvRec);
        return cancelInvRecList;

    }


    public static List<Invoice__c> createInvoice(InvoiceCreationParams params, String distributorUniqueKey) {
        TallyJsonDataObject.InvoiceDetails invoiceDetails = params.invoiceDetails;
        Map<String, String> distributorMap = params.distributorMap;
        List<Invoice__c> invoicesToInsert = new  List<Invoice__c>();
        

        if (invoiceDetails.DealerDetails != null && invoiceDetails.DealerDetails.Name != null) {
            String dealerName = invoiceDetails.DealerDetails.Name;
            String distributorKey = distributorUniqueKey;

            //Account distributorAccount;
            /*if(distributorMap.containsKey(distributorKey)){
                distributorAccount = [SELECT Id, Account_External_Key__c,Associated_User__c FROM Account WHERE Id = :distributorMap.get(distributorKey)];
                System.debug('distributorAccount*******: ' + distributorAccount);
                
            }*/
            
            Invoice__c invoiceRecord = new Invoice__c();
            if(distributorMap.containsKey(distributorKey) && distributorMap.get(distributorKey).split(';')[1] != 'No Associated User'){
                invoiceRecord.OwnerId = distributorMap.get(distributorKey).split(';')[1];
            }else{
                invoiceRecord.OwnerId = UserInfo.getUserId();
            }
            
            // Reetabrata For checking FY
            String fyString = getFinancialYearFromString(invoiceDetails.InvoiceDate);
            System.debug('fyString fyString '+fyString);
            
            //invoiceRecord.OwnerId = UserInfo.getUserId();
            invoiceRecord.Invoice_Number__c = invoiceDetails.InvoiceNumber;
            invoiceRecord.Invoice_Date__c = invoiceDetails.InvoiceDate;
            invoiceRecord.Status__c = invoiceDetails.InvoiceStatus;            
            invoiceRecord.Distributor__c = distributorMap.get(distributorKey).split(';')[0];
            invoiceRecord.Invoice_External_Key__c = distributorKey+';'+fyString+';'+ invoiceDetails.InvoiceNumber;
              //invoiceRecord.Invoice_External_Key__c = distributorKey+';'+invoiceDetails.InvoiceNumber;
            invoiceRecord.Dealer_Name__c = invoiceDetails.DealerDetails.Name != 'null' ? invoiceDetails.DealerDetails.Name  : null ;
            
            invoicesToInsert.add(invoiceRecord);
        }
        return invoicesToInsert;
    }


    //** Insert invoice records and invoice line items
   public static Set<ID> insertInvoiceRecord(List<Invoice__c> lineItemRecordsToInsert) {

    Set<ID> successInvoiceId = new Set<ID>();
    System.debug('lineItemRecordsToInsert INV++++++ : ' + lineItemRecordsToInsert);

    if (!lineItemRecordsToInsert.isEmpty()) {

        // Step 1 — Remove duplicates inside the same batch execution
        Map<String, Invoice__c> uniqueInvoiceMap = new Map<String, Invoice__c>();

        for (Invoice__c inv : lineItemRecordsToInsert) {
            if (inv.Invoice_External_Key__c != null) {
                uniqueInvoiceMap.put(inv.Invoice_External_Key__c, inv);
            }
        }

        List<Invoice__c> uniqueInvoices = uniqueInvoiceMap.values();
        System.debug('Unique invoices after duplicate removal: ' + uniqueInvoices);

        // Step 2 — Collect external keys
        Set<String> externalKeys = new Set<String>();
        for (Invoice__c inv : uniqueInvoices) {
            externalKeys.add(inv.Invoice_External_Key__c);
        }

        // Step 3 — Find existing invoices in DB
        List<Invoice__c> existingInvoices = new List<Invoice__c>();
        if (!externalKeys.isEmpty()) {
            existingInvoices = [
                SELECT Id, Invoice_External_Key__c
                FROM Invoice__c
                WHERE Invoice_External_Key__c IN :externalKeys
            ];
        }

        // Step 4 — Delete existing invoices (your original logic)
        if (!existingInvoices.isEmpty()) {
            System.debug('Deleting existing invoices with duplicate external keys: ' + existingInvoices.size());
            Database.delete(existingInvoices, false);
        }

        // Step 5 — Insert invoices
        Database.SaveResult[] insertResults = Database.insert(uniqueInvoices, false);

        // Step 6 — Collect successful IDs
        for (Database.SaveResult sr : insertResults) {
            if (sr.isSuccess()) {
                successInvoiceId.add(sr.getId());
                System.debug('Inserted Invoice record with ID: ' + sr.getId());
            } else {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('Insert Error → ' + err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }

        return successInvoiceId;
    }

    return null;
}



    public class InvoiceCreationParams {
        public TallyJsonDataObject.InvoiceDetails invoiceDetails { get; set; }
        public Map<String, String> distributorMap { get; set; }
        public List<Invoice__c> invoicesToInsert { get; set; }
    }
    
    public static String getFinancialYearFromString(String invoiceDateStr) {
    try {
        // Parse the date string manually
        List<String> parts = invoiceDateStr.split('-');
        Integer day = Integer.valueOf(parts[0]);
        String monthStr = parts[1];
        Integer year = 2000 + Integer.valueOf(parts[2]); // '25' → 2025

        Map<String, Integer> monthMap = new Map<String, Integer>{
            'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6,
            'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12
        };
        Integer month = monthMap.get(monthStr);

        // Create Date object using constructor
        Date invoiceDate = Date.newInstance(year, month, day);

        // Now compute FY
        Integer financialYear;
        if (month >= 4) {
            financialYear = year;
        } else {
            financialYear = year - 1;
        }
        
        return financialYear + '-' + String.valueOf(financialYear + 1).substring(2);
        
    } catch(Exception e) {
        System.debug('Date parsing error: ' + e.getMessage());
        return null; // or handle as needed
    }
}

}