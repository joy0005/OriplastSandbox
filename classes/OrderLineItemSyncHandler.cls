public without sharing class OrderLineItemSyncHandler {

    private static Boolean isRunning = false;

    public static void handleAfterUpdate(
        Map<Id, Order_Line_Item__c> newMap,
        Map<Id, Order_Line_Item__c> oldMap
    ) {
        /*
         * ------------------------------------------------
         * Guard against recursive trigger calls
         * within the same transaction
         * ------------------------------------------------
         */
        if (isRunning) {
            return;
        }
        isRunning = true;

        try {
            /*
             * ------------------------------------------------
             * Re-fetch records with relationship fields
        
             * ------------------------------------------------
             */
            List<Order_Line_Item__c> updatedItems = [
                SELECT Id,
                       Quantity__c,
                       Shipped_Quantity__c,
                       Ori_Plast_Product_Name__c,
                       Ori_Plast_Order__r.CreatedById,
                       Ori_Plast_Order__r.Order_Status__c
                FROM   Order_Line_Item__c
                WHERE  Id IN :newMap.keySet()
            ];

            Set<String> productNames = new Set<String>();
            Set<Id>     creatorIds   = new Set<Id>();

            for (Order_Line_Item__c newRec : updatedItems) {

                Order_Line_Item__c oldRec =
                    oldMap.get(newRec.Id);

                if (oldRec == null) {
                    continue;
                }

           

                String orderStatus =
                    newRec.Ori_Plast_Order__r.Order_Status__c;

                if (String.isBlank(orderStatus)) {
                    continue;
                }

                String productName =
                    newRec.Ori_Plast_Product_Name__c;

                if (String.isBlank(productName)) {
                    continue;
                }

                Id createdById =
                    newRec.Ori_Plast_Order__r.CreatedById;

                if (createdById == null) {
                    continue;
                }

                /*
                 * ------------------------------------------------
                 * 
                 * Shipped_Quantity__c changed on
                 * Partially Delivered or Received by Navision
                 * → sync ALL matching Draft line items quantity
                 * ------------------------------------------------
                 */
                Boolean isPartialOrReceived =
                    orderStatus == 'Partially Delivered' ||
                    orderStatus == 'Received by Navision';

                Boolean shippedQtyChanged =
                    oldRec.Shipped_Quantity__c !=
                    newRec.Shipped_Quantity__c;

                if (isPartialOrReceived && shippedQtyChanged) {
                    productNames.add(productName);
                    creatorIds.add(createdById);
                    continue;
                }

                /*
                 * ------------------------------------------------
                 *
                 * Quantity__c changed on Draft line item
                 * → ignore user change
                 * → recalculate from ALL matching
                 *   Partially Delivered / Received by Navision
                 * → overwrite ALL Draft line items for
                 *   same product + creator
                 * ------------------------------------------------
                 */
                Boolean isDraft =
                    orderStatus == 'Draft';

                Boolean quantityChanged =
                    oldRec.Quantity__c != newRec.Quantity__c;

                if (isDraft && quantityChanged) {
                    productNames.add(productName);
                    creatorIds.add(createdById);
                }
            }

            /*
             * Nothing qualifies — exit
             */
            if (productNames.isEmpty() || creatorIds.isEmpty()) {
                return;
            }

          // calling main method
            OrderLineItemQuantitySyncService.syncDraftLines(
                productNames,
                creatorIds
            );

        } catch (Exception e) {
            System.debug(
                'OrderLineItemSyncHandler Error => ' +
                e.getMessage() +
                ' | Stack: ' +
                e.getStackTraceString()
            );
        } finally {
         
            isRunning = false;
        }
    }
}