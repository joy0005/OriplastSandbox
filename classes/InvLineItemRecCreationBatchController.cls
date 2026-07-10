public without sharing class InvLineItemRecCreationBatchController {
    
    

    public static List<Invoice_Line_Item__c> createInvoiceLineItemRecords(List<TallyJsonDataObject.InvoiceDetails> invoiceDetailsList, Map<String, Id> invoiceExternalIdMap) {
        List<Invoice_Line_Item__c> lineItemRecordsToInsert = new List<Invoice_Line_Item__c>();
        
        for (TallyJsonDataObject.InvoiceDetails invoiceDetail : invoiceDetailsList) {
            Id invoiceId = invoiceExternalIdMap.get(invoiceDetail.InvoiceNumber);
            
            if (invoiceId != null && invoiceDetail.invoiceStatus != 'Cancelled') {
                for (TallyJsonDataObject.InvoiceLineItem lineItem : invoiceDetail.invoiceLineItems) {
                    Invoice_Line_Item__c lineItemRecord = new Invoice_Line_Item__c();
                    lineItemRecord.Ori_Plast_Invoice__c = invoiceId;
                    //lineItemRecord.Description__c = lineItem.description;
                    lineItemRecord.Quantity__c = lineItem.Quantity != 0 ? lineItem.Quantity : null;
                    lineItemRecord.Unit_of_Measure__c = lineItem.UnitofMeasure != 'null' ? lineItem.UnitofMeasure : null;
                    lineItemRecord.Rate__c = lineItem.Rate != 0 ? lineItem.Rate : null;
                    lineItemRecord.Total_Discount_Percentage__c = stringToDecimal(lineItem.TotalDiscountPercentage) != 0 ? stringToDecimal(lineItem.TotalDiscountPercentage) : null;
                    //lineItemRecord.CGST__c = stringToDecimal(lineItem.cgst);
                    //lineItemRecord.CGST_Percentage__c = stringToDecimal(lineItem.cgstPercentage);
                    //lineItemRecord.SGST__c = stringToDecimal(lineItem.sgst);
                    //lineItemRecord.SGST_Percentage__c = stringToDecimal(lineItem.sgstPercentage);
                    //lineItemRecord.IGST__c = stringToDecimal(lineItem.igst);
                    //lineItemRecord.IGST_Percentage__c = stringToDecimal(lineItem.igstPercentage);
                    lineItemRecord.Final_Price__c = lineItem.FinalPrice != 0 ? lineItem.FinalPrice : null;
                    lineItemRecord.SKU__c = lineItem.SKU != 'null' ? lineItem.SKU : null ;
                    
                    
                    lineItemRecordsToInsert.add(lineItemRecord);
                }
            } else {
                System.debug('Invoice External ID not found or Invoice Status is Cancelled for: ' + invoiceDetail.InvoiceNumber);
            }
        }
        //insertInvoiceLineitm(lineItemRecordsToInsert);
        
        return lineItemRecordsToInsert;
    }

   

    // ** Insert Invoice Line Item & Clear the list after insertion
    /*public static void insertInvoiceLineitm(List<Invoice_Line_Item__c> lineItemRecordsToInsert) {
        System.debug('lineItemRecordsToInsert INV++++++ : ' + lineItemRecordsToInsert);
       try {
         if (!lineItemRecordsToInsert.isEmpty()) {
            Database.SaveResult[] newInvoiceLineItemsList = Database.insert(lineItemRecordsToInsert,false);
            lineItemRecordsToInsert.clear();
        }
       } catch(Exception ex) {
        System.debug(ex.getMessage());
        CreateTransactionLog.log('Error', 'distributorIdentificationKeys', 'execute', ex.getMessage(), null,  null ,  ex.getStackTraceString(), null);
       }
    }*/

    // ** Method to convert String to Decimal, handling 'null'====
    public static Decimal stringToDecimal(Decimal value) {
        if (value != null && value != 0) {
            return value;
        } else {
            return null;
        }
    }   
}