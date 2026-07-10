@IsTest
private class GetHighestRemainingQtyTest {

    @TestSetup
    static void setupData() {

        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        OriPlast_Product__c prod = new OriPlast_Product__c(
            Name = 'Test Product',
            Length__c = '100' // Length_In_Meter__c = 10
        );
        insert prod;

        Ori_Plast_Order__c ord = new Ori_Plast_Order__c(
            Account__c = acc.Id,
            Order_Status__c = 'Partially Delivered'
        );
        insert ord;

        /*
         * Item 1
         * shipped = 0
         * actualQty = Quantity = 100
         */
        Order_Line_Item__c item1 =
            new Order_Line_Item__c(
                Ori_Plast_Order__c = ord.Id,
                Ori_Plast_Product__c = prod.Id,
                Quantity__c = 100,
                Shipped_Quantity__c = 0,
                Status__c = 'Partially Delivered',
                Unit_of_Measure__c = 'PCS'
            );

        /*
         * Item 2
         *
         * Length = 10
         * ERP Qty = 5 * 10 = 50
         * Remaining = 50 - 10 = 40
         * actualQty = 40 / 10 = 4
         */
        Order_Line_Item__c item2 =
            new Order_Line_Item__c(
                Ori_Plast_Order__c = ord.Id,
                Ori_Plast_Product__c = prod.Id,
                Quantity__c = 5,
                Shipped_Quantity__c = 10,
                Status__c = 'Partially Delivered',
                Unit_of_Measure__c = 'MTR'
            );

        /*
         * Item 3
         *
         * Non-MTR branch
         * Remaining = 50 - 20 = 30
         * actualQty = 30
         */
        Order_Line_Item__c item3 =
            new Order_Line_Item__c(
                Ori_Plast_Order__c = ord.Id,
                Ori_Plast_Product__c = prod.Id,
                Quantity__c = 50,
                Shipped_Quantity__c = 20,
                Status__c = 'Partially Delivered',
                Unit_of_Measure__c = 'PCS'
            );

        insert new List<Order_Line_Item__c>{
            item1,
            item2,
            item3
        };
    }

    @IsTest
    static void testSuccessScenario() {

        List<Order_Line_Item__c> items = [
            SELECT Id
            FROM Order_Line_Item__c
        ];

        GetHighestRemainingQty.Request req =
            new GetHighestRemainingQty.Request();

        req.pendingLineItems = items;

        Test.startTest();

        List<GetHighestRemainingQty.Response> result =
            GetHighestRemainingQty.getHighestQty(
                new List<GetHighestRemainingQty.Request>{ req }
            );

        Test.stopTest();

        System.assertEquals(1, result.size());

        /*
         * item1 = 100
         * item2 = 4
         * item3 = 30
         *
         * Total = 134
         */
        System.assertEquals(
            134,
            result[0].highestQuantity
        );

        System.assertEquals(
            null,
            result[0].errorMessage
        );
    }

    @IsTest
    static void testEmptyCollection() {

        GetHighestRemainingQty.Request req =
            new GetHighestRemainingQty.Request();

        req.pendingLineItems =
            new List<Order_Line_Item__c>();

        List<GetHighestRemainingQty.Response> result =
            GetHighestRemainingQty.getHighestQty(
                new List<GetHighestRemainingQty.Request>{ req }
            );

        System.assertEquals(
            'No line items provided in request.',
            result[0].errorMessage
        );
    }

    @IsTest
    static void testNoIdsProvided() {

        GetHighestRemainingQty.Request req =
            new GetHighestRemainingQty.Request();

        req.pendingLineItems =
            new List<Order_Line_Item__c>{
                new Order_Line_Item__c()
            };

        List<GetHighestRemainingQty.Response> result =
            GetHighestRemainingQty.getHighestQty(
                new List<GetHighestRemainingQty.Request>{ req }
            );

        System.assertEquals(
            'None of the provided line items have a valid Id.',
            result[0].errorMessage
        );
    }

    @IsTest
    static void testNullRequest() {

        List<GetHighestRemainingQty.Response> result =
            GetHighestRemainingQty.getHighestQty(
                new List<GetHighestRemainingQty.Request>{
                    null
                }
            );

        System.assertEquals(
            'No line items provided in request.',
            result[0].errorMessage
        );
    }

    @IsTest
    static void testNonPartiallyDeliveredIgnored() {

        Account acc = new Account(
            Name = 'Account 2'
        );
        insert acc;

        OriPlast_Product__c prod = [
            SELECT Id
            FROM OriPlast_Product__c
            LIMIT 1
        ];

        Ori_Plast_Order__c ord =
            new Ori_Plast_Order__c(
                Account__c = acc.Id,
                Order_Status__c = 'Delivered'
            );

        insert ord;

        Order_Line_Item__c item =
            new Order_Line_Item__c(
                Ori_Plast_Order__c = ord.Id,
                Ori_Plast_Product__c = prod.Id,
                Quantity__c = 50,
                Shipped_Quantity__c = 10,
                Status__c = 'Delivered',
                Unit_of_Measure__c = 'PCS'
            );

        insert item;

        GetHighestRemainingQty.Request req =
            new GetHighestRemainingQty.Request();

        req.pendingLineItems =
            new List<Order_Line_Item__c>{ item };

        List<GetHighestRemainingQty.Response> result =
            GetHighestRemainingQty.getHighestQty(
                new List<GetHighestRemainingQty.Request>{ req }
            );

        System.assertEquals(
            0,
            result[0].highestQuantity
        );
    }
}