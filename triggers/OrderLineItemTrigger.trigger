trigger OrderLineItemTrigger on Order_Line_Item__c (after update) {
    OrderLineItemSyncHandler.handleAfterUpdate(
        Trigger.newMap,
        Trigger.oldMap
    );
}