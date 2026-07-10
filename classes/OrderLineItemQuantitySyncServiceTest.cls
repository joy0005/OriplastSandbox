@IsTest
public class OrderLineItemQuantitySyncServiceTest {

    @TestSetup
    static void setupTestData() {

        //====================================================
        // Account
        //====================================================

        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        //====================================================
        // Products
        //====================================================

        OriPlast_Product__c mtrProduct = new OriPlast_Product__c(
            Name = 'MTR Test Product',
            Length__c = '30'
          
        );

        OriPlast_Product__c pcsProduct = new OriPlast_Product__c(
            Name = 'PCS Test Product'
           
        );

        OriPlast_Product__c boxProduct = new OriPlast_Product__c(
            Name = 'Box Test Product',
            No_of_Pcs_in_one_box__c = 6
        );

        insert new List<OriPlast_Product__c>{
            mtrProduct,
            pcsProduct,
            boxProduct
        };

        //====================================================
        // Product Prices
        //====================================================

        insert new List<Product_Price__c>{

            new Product_Price__c(
                Oriplast_Product__c = mtrProduct.Id,
                Unit_Price__c = 100
            ),

            new Product_Price__c(
                Oriplast_Product__c = pcsProduct.Id,
                Unit_Price__c = 150
            ),

            new Product_Price__c(
                Oriplast_Product__c = boxProduct.Id,
                Unit_Price__c = 200
            )
        };

        //====================================================
        // Orders
        //====================================================

        Ori_Plast_Order__c partialOrder =
            new Ori_Plast_Order__c(
                Account__c = acc.Id,
                Order_Status__c = 'Partially Delivered'
            );

        Ori_Plast_Order__c navisionOrder =
            new Ori_Plast_Order__c(
                Account__c = acc.Id,
                Order_Status__c = 'Received by Navision'
            );

        Ori_Plast_Order__c draftOrder =
            new Ori_Plast_Order__c(
                Account__c = acc.Id,
                Order_Status__c = 'Draft'
            );

        insert new List<Ori_Plast_Order__c>{
            partialOrder,
            navisionOrder,
            draftOrder
        };

        //====================================================
        // Partial Delivered MTR
        //
        // Quantity = 6
        // Length = 3 Meter
        // ERP = 18
        // Shipped = 10
        // Remaining = 8
        //====================================================

        insert new Order_Line_Item__c(

            Ori_Plast_Order__c = partialOrder.Id,
            Ori_Plast_Product__c = mtrProduct.Id,

            Quantity__c = 6,
            Shipped_Quantity__c = 10,

            Unit_of_Measure__c = 'MTR'
        );

        //====================================================
        // Partial Delivered PCS
        //
        // ERP = 100
        // Remaining = 30
        //====================================================

        insert new Order_Line_Item__c(

            Ori_Plast_Order__c = partialOrder.Id,
            Ori_Plast_Product__c = pcsProduct.Id,

            Quantity__c = 100,
            Shipped_Quantity__c = 70,

            Unit_of_Measure__c = 'PCS'
        );

        //====================================================
        // Partial Delivered Box
        //
        // Remaining = 13
        //====================================================

        insert new Order_Line_Item__c(

            Ori_Plast_Order__c = partialOrder.Id,
            Ori_Plast_Product__c = boxProduct.Id,

            Quantity__c = 20,
            Shipped_Quantity__c = 7,

            Unit_of_Measure__c = 'PCS'
        );

        //====================================================
        // Draft MTR
        //====================================================

        insert new Order_Line_Item__c(

            Ori_Plast_Order__c = draftOrder.Id,
            Ori_Plast_Product__c = mtrProduct.Id,

            Quantity__c = 22,

            Unit_of_Measure__c = 'MTR',

            Trade_Discount__c = 37,
            Cash_Discount_Percentage__c = 2
        );

        //====================================================
        // Draft PCS
        //====================================================

        insert new Order_Line_Item__c(

            Ori_Plast_Order__c = draftOrder.Id,
            Ori_Plast_Product__c = pcsProduct.Id,

            Quantity__c = 100,

            Unit_of_Measure__c = 'PCS',

            Trade_Discount__c = 10,
            Cash_Discount_Percentage__c = 2
        );

        //====================================================
        // Draft Box
        //====================================================

        insert new Order_Line_Item__c(

            Ori_Plast_Order__c = draftOrder.Id,
            Ori_Plast_Product__c = boxProduct.Id,

            Quantity__c = 20,
            Box_Order_Quantity__c = 4,

            Unit_of_Measure__c = 'PCS',

            Trade_Discount__c = 5,
            Cash_Discount_Percentage__c = 1
        );
        
    }
    
        //=========================================================
    // TEST 1
    // MTR Product Sync
    //=========================================================
    @IsTest
    static void testMTRProductSync() {

        Set<String> productNames =
            new Set<String>{'MTR Test Product'};

        Set<Id> creatorIds =
            new Set<Id>{UserInfo.getUserId()};

        Order_Line_Item__c draftBefore = [
            SELECT Id,
                   Quantity__c
            FROM Order_Line_Item__c
            WHERE Ori_Plast_Order__r.Order_Status__c='Draft'
            AND Ori_Plast_Product__r.Name='MTR Test Product'
            LIMIT 1
        ];

        Test.startTest();

        OrderLineItemQuantitySyncService.syncDraftLines(
            productNames,
            creatorIds
        );

        Test.stopTest();

        Order_Line_Item__c draftAfter = [

            SELECT Quantity__c,
                   Trade_Discount_TD__c,
                   Cash_Discount_CD__c,
                   Price_After_Discount__c,
                   CGST__c,
                   SGST__c,
                   Final_Price__c

            FROM Order_Line_Item__c
            WHERE Id=:draftBefore.Id
        ];

        System.assertNotEquals(
            draftBefore.Quantity__c,
            draftAfter.Quantity__c
        );

        System.assertNotEquals(
            null,
            draftAfter.Final_Price__c
        );
    }

    //=========================================================
    // TEST 2
    // PCS Product Sync
    //=========================================================
    @IsTest
    static void testPCSProductSync() {

        Set<String> productNames =
            new Set<String>{'PCS Test Product'};

        Set<Id> creatorIds =
            new Set<Id>{UserInfo.getUserId()};

        Order_Line_Item__c draftBefore = [

            SELECT Id,
                   Quantity__c

            FROM Order_Line_Item__c

            WHERE Ori_Plast_Order__r.Order_Status__c='Draft'
            AND Ori_Plast_Product__r.Name='PCS Test Product'

            LIMIT 1
        ];

        Test.startTest();

        OrderLineItemQuantitySyncService.syncDraftLines(
            productNames,
            creatorIds
        );

        Test.stopTest();

        Order_Line_Item__c draftAfter=[

            SELECT Quantity__c,
                   Final_Price__c

            FROM Order_Line_Item__c

            WHERE Id=:draftBefore.Id
        ];

        System.assertNotEquals(

            draftBefore.Quantity__c,

            draftAfter.Quantity__c
        );

        System.assertNotEquals(

            null,

            draftAfter.Final_Price__c
        );
    }

    //=========================================================
    // TEST 3
    // BOX Product Sync
    //=========================================================
    @IsTest
    static void testBoxOrderSync() {

        Set<String> productNames =
            new Set<String>{'Box Test Product'};

        Set<Id> creatorIds =
            new Set<Id>{UserInfo.getUserId()};

        Order_Line_Item__c draftBefore=[

            SELECT Id,
                   Quantity__c,
                   Box_Order_Quantity__c

            FROM Order_Line_Item__c

            WHERE Ori_Plast_Order__r.Order_Status__c='Draft'
            AND Ori_Plast_Product__r.Name='Box Test Product'

            LIMIT 1
        ];

        Test.startTest();

        OrderLineItemQuantitySyncService.syncDraftLines(

            productNames,

            creatorIds
        );

        Test.stopTest();

        Order_Line_Item__c draftAfter=[

            SELECT Quantity__c,
                   Box_Order_Quantity__c,
                   Final_Price__c

            FROM Order_Line_Item__c

            WHERE Id=:draftBefore.Id
        ];

        System.assertNotEquals(

            draftBefore.Quantity__c,

            draftAfter.Quantity__c
        );

        System.assertNotEquals(

            null,

            draftAfter.Box_Order_Quantity__c
        );

        System.assertNotEquals(

            null,

            draftAfter.Final_Price__c
        );
    }
    
        //=========================================================
    // TEST 4
    // Empty Product Names
    //=========================================================
    @IsTest
    static void testEmptyProductNames() {

        Test.startTest();

        OrderLineItemQuantitySyncService.syncDraftLines(
            new Set<String>(),
            new Set<Id>{UserInfo.getUserId()}
        );

        Test.stopTest();

        System.assert(true,
            'Method should exit gracefully for empty product set');
    }

    //=========================================================
    // TEST 5
    // Empty Creator Ids
    //=========================================================
    @IsTest
    static void testEmptyCreatorIds() {

        Test.startTest();

        OrderLineItemQuantitySyncService.syncDraftLines(
            new Set<String>{'MTR Test Product'},
            new Set<Id>()
        );

        Test.stopTest();

        System.assert(true,
            'Method should exit gracefully for empty creator ids');
    }

    //=========================================================
    // TEST 6
    // No Matching Partial Order
    //=========================================================
    @IsTest
    static void testNoPartialItemsFound() {

        Order_Line_Item__c draftBefore = [

            SELECT Id,
                   Quantity__c

            FROM Order_Line_Item__c

            WHERE Ori_Plast_Order__r.Order_Status__c='Draft'
            AND Ori_Plast_Product__r.Name='MTR Test Product'

            LIMIT 1
        ];

        Decimal originalQty = draftBefore.Quantity__c;

        Test.startTest();

        OrderLineItemQuantitySyncService.syncDraftLines(

            new Set<String>{'Unknown Product'},

            new Set<Id>{UserInfo.getUserId()}
        );

        Test.stopTest();

        Order_Line_Item__c draftAfter=[

            SELECT Quantity__c

            FROM Order_Line_Item__c

            WHERE Id=:draftBefore.Id
        ];

        System.assertEquals(

            originalQty,

            draftAfter.Quantity__c,

            'Quantity should remain unchanged'
        );
    }

    //=========================================================
    // TEST 7
    // Service Re-entry Guard
    //=========================================================
    @IsTest
    static void testServiceReentryGuard() {

        Set<String> productNames =
            new Set<String>{'PCS Test Product'};

        Set<Id> creatorIds =
            new Set<Id>{UserInfo.getUserId()};

        Test.startTest();

        OrderLineItemQuantitySyncService.syncDraftLines(
            productNames,
            creatorIds
        );

        // Second call in same transaction
        OrderLineItemQuantitySyncService.syncDraftLines(
            productNames,
            creatorIds
        );

        Test.stopTest();

        System.assert(true,
            'Recursive guard should prevent re-entry');
    }
    
        //=========================================================
    // TEST 8
    // MTR Product - Nothing Shipped
    //=========================================================
    @IsTest
    static void testMTRNothingShipped() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        OriPlast_Product__c product = [
            SELECT Id
            FROM OriPlast_Product__c
            WHERE Name = 'MTR Test Product'
            LIMIT 1
        ];

        Ori_Plast_Order__c partialOrder = new Ori_Plast_Order__c(
            Account__c = acc.Id,
            Order_Status__c = 'Partially Delivered'
        );
        insert partialOrder;

        insert new Order_Line_Item__c(
            Ori_Plast_Order__c = partialOrder.Id,
            Ori_Plast_Product__c = product.Id,
            Quantity__c = 4,
            Shipped_Quantity__c = 0,
            Unit_of_Measure__c = 'MTR'
        );

        Order_Line_Item__c draftBefore = [
            SELECT Id, Quantity__c
            FROM Order_Line_Item__c
            WHERE Ori_Plast_Order__r.Order_Status__c='Draft'
            AND Ori_Plast_Product__r.Name='MTR Test Product'
            LIMIT 1
        ];

        Test.startTest();

        OrderLineItemQuantitySyncService.syncDraftLines(
            new Set<String>{'MTR Test Product'},
            new Set<Id>{UserInfo.getUserId()}
        );

        Test.stopTest();

        Order_Line_Item__c draftAfter = [
            SELECT Quantity__c
            FROM Order_Line_Item__c
            WHERE Id=:draftBefore.Id
        ];

        System.assertNotEquals(
            draftBefore.Quantity__c,
            draftAfter.Quantity__c
        );
    }

    //=========================================================
    // TEST 9
    // Received by Navision
    //=========================================================
    @IsTest
    static void testReceivedByNavisionOrder() {

        Ori_Plast_Order__c navisionOrder = [

            SELECT Id

            FROM Ori_Plast_Order__c

            WHERE Order_Status__c='Received by Navision'

            LIMIT 1
        ];

        OriPlast_Product__c pcsProduct = [

            SELECT Id

            FROM OriPlast_Product__c

            WHERE Name='PCS Test Product'

            LIMIT 1
        ];

        insert new Order_Line_Item__c(

            Ori_Plast_Order__c = navisionOrder.Id,
            Ori_Plast_Product__c = pcsProduct.Id,

            Quantity__c = 50,
            Shipped_Quantity__c = 20,

            Unit_of_Measure__c = 'PCS'
        );

        Order_Line_Item__c draftBefore=[

            SELECT Id,
                   Quantity__c

            FROM Order_Line_Item__c

            WHERE Ori_Plast_Order__r.Order_Status__c='Draft'
            AND Ori_Plast_Product__r.Name='PCS Test Product'

            LIMIT 1
        ];

        Test.startTest();

        OrderLineItemQuantitySyncService.syncDraftLines(

            new Set<String>{'PCS Test Product'},

            new Set<Id>{UserInfo.getUserId()}
        );

        Test.stopTest();

        Order_Line_Item__c draftAfter=[

            SELECT Quantity__c

            FROM Order_Line_Item__c

            WHERE Id=:draftBefore.Id
        ];

        System.assertNotEquals(

            draftBefore.Quantity__c,

            draftAfter.Quantity__c
        );
    }

    
}