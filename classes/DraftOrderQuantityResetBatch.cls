//Pratik Mondal
//if any order stays more than 24 hours in draft stage , all the line items quantity present on that order will reset to 0

global with sharing class DraftOrderQuantityResetBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {

        // Fetch draft orders older than 24 hours
       
        // with Quantity greater than zero.
        Datetime cutoffDateTime = System.now().addHours(-24);

        return Database.getQueryLocator([
            SELECT Id
            FROM Ori_Plast_Order__c
            WHERE Order_Status__c = 'Draft'
            AND CreatedDate <= :cutoffDateTime
            AND Id IN (
                SELECT Ori_Plast_Order__c
                FROM Order_Line_Item__c
                WHERE Quantity__c > 0
            )
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Ori_Plast_Order__c> scope) {

        // No records received from batch.
        if (scope.isEmpty()) {
            return;
        }

        try {

            Set<Id> orderIds = new Set<Id>();

            for (Ori_Plast_Order__c orderRec : scope) {
                orderIds.add(orderRec.Id);
            }

            // Retrieve only line items that still require update.
            List<Order_Line_Item__c> orderLineItems = [
                SELECT Id,
                       Quantity__c,
                       Ori_Plast_Order__c
                FROM Order_Line_Item__c
                WHERE Ori_Plast_Order__c IN :orderIds
                AND Quantity__c > 0
            ];

            List<Order_Line_Item__c> lineItemsToUpdate =
                new List<Order_Line_Item__c>();

            for (Order_Line_Item__c lineItem : orderLineItems) {

                lineItemsToUpdate.add(
                    new Order_Line_Item__c(
                        Id = lineItem.Id,
                        Quantity__c = 0,
                        Price_After_Discount__c = 0,
                        CGST__c= 0,
                        SGST__c = 0,
                        Final_Price__c = 0
                    )
                );
            }

            if (!lineItemsToUpdate.isEmpty()) {

                // All line items must succeed or fail together.
                update lineItemsToUpdate;
            }

        } catch (Exception ex) {

            System.debug(
                LoggingLevel.ERROR,
                'DraftOrderQuantityResetBatch Error: '
                + ex.getMessage()
                + ' | Line Number: '
                + ex.getLineNumber()
            );

            throw ex;
        }
    }

    global void finish(Database.BatchableContext bc) {

        System.debug(
            LoggingLevel.INFO,
            'Draft Order Quantity Reset Batch completed successfully.'
        );
    }
}