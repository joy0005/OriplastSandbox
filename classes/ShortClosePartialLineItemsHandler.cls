//Pratik Mondal

public without sharing class ShortClosePartialLineItemsHandler {

    public class FlowInput {

        @InvocableVariable(
            label='Current Order Id'
            description='Id of the submitted order'
            required=true
        )
        public String currentOrderId;

        @InvocableVariable(
            label='Current Order Created By Id'
            description='CreatedById of the submitted order'
            required=true
        )
        public String createdById;
    }

    @InvocableMethod(
        label='Short Close Matching Partial Line Items'
        description='Short Closes Partially Delivered line items on other orders matching same product ID and creator'
    )
    public static void shortCloseMatchingLineItems(List<FlowInput> inputs) {

        if (inputs == null || inputs.isEmpty()) {
            return;
        }

        FlowInput input = inputs[0];

        if (
            String.isBlank(input.currentOrderId) ||
            String.isBlank(input.createdById)
        ) {
            return;
        }

        /*
         * ----------------------------------------------------
         * STEP 1
         * Query the submitted order's line items and collect
         * the Product IDs (Ori_Plast_Product__c lookup field).
         *
         * Using Product ID (Id) not product name (String)
         * for exact reliable matching.
         * ----------------------------------------------------
         */
        List<Order_Line_Item__c> currentOrderItems = [
            SELECT Id,
                   Ori_Plast_Product__c
            FROM   Order_Line_Item__c
            WHERE  Ori_Plast_Order__c = :input.currentOrderId
            AND    Ori_Plast_Product__c != null
        ];

        if (currentOrderItems.isEmpty()) {
            return;
        }

        // Collect Product IDs — Set<Id> not Set<String>
        // This is exact Id matching — no text comparison issues
        Set<Id> productIds = new Set<Id>();

        for (Order_Line_Item__c li : currentOrderItems) {
            productIds.add(li.Ori_Plast_Product__c);
        }

        if (productIds.isEmpty()) {
            return;
        }

        /*
         * ----------------------------------------------------
         * STEP 2
         * Find ALL Partially Delivered line items on OTHER
         * Partially Delivered orders where:
         *   - Status              = Partially Delivered
         *   - Ori_Plast_Product__c IN productIds  (Id match)
         *   - CreatedById         = same creator
         *   - Order Id            != current order
         *   - Parent Order Status = Partially Delivered
         * ----------------------------------------------------
         */
    List<Order_Line_Item__c> matchingItems = [
    SELECT Id,
           Status__c,
           Ori_Plast_Product__c
    FROM Order_Line_Item__c
    WHERE Ori_Plast_Product__c IN :productIds
    AND Ori_Plast_Order__r.CreatedById = :input.createdById
    AND Ori_Plast_Order__c != :input.currentOrderId
    AND Ori_Plast_Order__r.Order_Status__c = 'Partially Delivered'
    AND (
        Status__c = 'Partially Delivered'
        OR Status__c = NULL
        OR Status__c = ''
    )
];

        if (matchingItems.isEmpty()) {
            return;
        }

        /*
         * ----------------------------------------------------
         * STEP 3
         * Build update list — only exact product-matched
         * Partially Delivered line items get Short Closed.
         * ----------------------------------------------------
         */
        List<Order_Line_Item__c> itemsToUpdate = new List<Order_Line_Item__c>();

        for (Order_Line_Item__c item : matchingItems) {
            itemsToUpdate.add(
                new Order_Line_Item__c(
                    Id        = item.Id,
                    Status__c = 'Short Closed'
                )
            );
        }

        /*
         * ----------------------------------------------------
         * STEP 4
         * Bulk DML — partial success, log failures.
         * ----------------------------------------------------
         */
        Database.SaveResult[] results =
            Database.update(itemsToUpdate, false);

        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('STATUS CODE ==> '   + err.getStatusCode());
                    System.debug('ERROR MESSAGE ==> ' + err.getMessage());
                    System.debug('FIELDS ==> '        + err.getFields());
                }
            }
        }
    }
}