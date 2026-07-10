@IsTest
private class ShortClosePartialLineItemsHandlerTest {

    @TestSetup
    static void setupData() {

        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        OriPlast_Product__c prod1 = new OriPlast_Product__c(
            Name = 'Product 1',
            Length__c = '100'
        );

        OriPlast_Product__c prod2 = new OriPlast_Product__c(
            Name = 'Product 2',
            Length__c = '100'
        );

        insert new List<OriPlast_Product__c>{
            prod1,
            prod2
        };

        // Current submitted order
        Ori_Plast_Order__c currentOrder =
            new Ori_Plast_Order__c(
                Account__c = acc.Id,
                Order_Status__c = 'Submitted'
            );

        // Other order
        Ori_Plast_Order__c otherOrder =
            new Ori_Plast_Order__c(
                Account__c = acc.Id,
                Order_Status__c = 'Partially Delivered'
            );

        insert new List<Ori_Plast_Order__c>{
            currentOrder,
            otherOrder
        };

        // Current order line item
        Order_Line_Item__c currentItem =
            new Order_Line_Item__c(
                Ori_Plast_Order__c = currentOrder.Id,
                Ori_Plast_Product__c = prod1.Id,
                Quantity__c = 10,
                Status__c = 'Submitted'
            );

        // Matching item -> should become Short Closed
        Order_Line_Item__c matchingItem =
            new Order_Line_Item__c(
                Ori_Plast_Order__c = otherOrder.Id,
                Ori_Plast_Product__c = prod1.Id,
                Quantity__c = 5,
                Status__c = 'Partially Delivered'
            );

        // Different product -> should not update
        Order_Line_Item__c nonMatchingItem =
            new Order_Line_Item__c(
                Ori_Plast_Order__c = otherOrder.Id,
                Ori_Plast_Product__c = prod2.Id,
                Quantity__c = 5,
                Status__c = 'Partially Delivered'
            );

        insert new List<Order_Line_Item__c>{
            currentItem,
            matchingItem,
            nonMatchingItem
        };
    }

    @IsTest
    static void testShortCloseMatchingLineItems() {

        Ori_Plast_Order__c currentOrder = [
            SELECT Id, CreatedById
            FROM Ori_Plast_Order__c
            WHERE Order_Status__c = 'Submitted'
            LIMIT 1
        ];

        ShortClosePartialLineItemsHandler.FlowInput input =
            new ShortClosePartialLineItemsHandler.FlowInput();

        input.currentOrderId = currentOrder.Id;
        input.createdById = currentOrder.CreatedById;

        Test.startTest();

        ShortClosePartialLineItemsHandler.shortCloseMatchingLineItems(
            new List<ShortClosePartialLineItemsHandler.FlowInput>{ input }
        );

        Test.stopTest();

        List<Order_Line_Item__c> items = [
            SELECT Status__c,
                   Ori_Plast_Product__c
            FROM Order_Line_Item__c
            WHERE Status__c IN ('Short Closed','Partially Delivered')
        ];

        Integer shortClosedCount = 0;
        Integer partialCount = 0;

        for(Order_Line_Item__c item : items) {

            if(item.Status__c == 'Short Closed') {
                shortClosedCount++;
            }

            if(item.Status__c == 'Partially Delivered') {
                partialCount++;
            }
        }

        System.assertEquals(
            1,
            shortClosedCount,
            'One matching line item should be short closed'
        );

        System.assertEquals(
            1,
            partialCount,
            'Non matching product should remain partially delivered'
        );
    }

    @IsTest
    static void testNullInputList() {

        Test.startTest();

        ShortClosePartialLineItemsHandler.shortCloseMatchingLineItems(
            null
        );

        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testEmptyInputList() {

        Test.startTest();

        ShortClosePartialLineItemsHandler.shortCloseMatchingLineItems(
            new List<ShortClosePartialLineItemsHandler.FlowInput>()
        );

        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testBlankInputs() {

        ShortClosePartialLineItemsHandler.FlowInput input =
            new ShortClosePartialLineItemsHandler.FlowInput();

        input.currentOrderId = '';
        input.createdById = '';

        Test.startTest();

        ShortClosePartialLineItemsHandler.shortCloseMatchingLineItems(
            new List<ShortClosePartialLineItemsHandler.FlowInput>{ input }
        );

        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testNoCurrentOrderLineItems() {

        Account acc = new Account(
            Name = 'Second Account'
        );
        insert acc;

        Ori_Plast_Order__c orderRec =
            new Ori_Plast_Order__c(
                Account__c = acc.Id,
                Order_Status__c = 'Submitted'
            );

        insert orderRec;

        ShortClosePartialLineItemsHandler.FlowInput input =
            new ShortClosePartialLineItemsHandler.FlowInput();

        input.currentOrderId = orderRec.Id;
        input.createdById = orderRec.CreatedById;

        Test.startTest();

        ShortClosePartialLineItemsHandler.shortCloseMatchingLineItems(
            new List<ShortClosePartialLineItemsHandler.FlowInput>{ input }
        );

        Test.stopTest();

        System.assert(true);
    }
}