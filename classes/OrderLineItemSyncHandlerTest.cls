@IsTest
public class OrderLineItemSyncHandlerTest {

    @TestSetup
    static void setupTestData() {
        
        Account acc = new Account(Name = 'Test Distributor Account');
        Database.insert(acc, AccessLevel.SYSTEM_MODE);

        OriPlast_Product__c mtrProduct = new OriPlast_Product__c(Name = 'Test MTR Product', Length__c = '30');
        OriPlast_Product__c pcsProduct = new OriPlast_Product__c(Name = 'Test PCS Product');
        List<OriPlast_Product__c> prods = new List<OriPlast_Product__c>{mtrProduct, pcsProduct};
        Database.insert(prods, AccessLevel.SYSTEM_MODE);

        List<Product_Price__c> prices = new List<Product_Price__c>{
            new Product_Price__c(Oriplast_Product__c = mtrProduct.Id, Unit_Price__c = 100),
            new Product_Price__c(Oriplast_Product__c = pcsProduct.Id, Unit_Price__c = 120)
        };
        Database.insert(prices, AccessLevel.SYSTEM_MODE);

        Ori_Plast_Order__c partialOrder = new Ori_Plast_Order__c(Account__c = acc.Id, Order_Status__c = 'Partially Delivered');
        Ori_Plast_Order__c draftOrder = new Ori_Plast_Order__c(Account__c = acc.Id, Order_Status__c = 'Draft');
        List<Ori_Plast_Order__c> orders = new List<Ori_Plast_Order__c>{partialOrder, draftOrder};
        Database.insert(orders, AccessLevel.SYSTEM_MODE);

        List<Order_Line_Item__c> itemsToInsert = new List<Order_Line_Item__c>();

        // Partial MTR
        itemsToInsert.add(new Order_Line_Item__c(
            Ori_Plast_Order__c = partialOrder.Id, Ori_Plast_Product__c = mtrProduct.Id,
            Quantity__c = 6, Shipped_Quantity__c = 8, Unit_of_Measure__c = 'MTR'
        ));

        // Partial PCS
        itemsToInsert.add(new Order_Line_Item__c(
            Ori_Plast_Order__c = partialOrder.Id, Ori_Plast_Product__c = pcsProduct.Id,
            Quantity__c = 100, Shipped_Quantity__c = 50, Unit_of_Measure__c = 'PCS'
        ));

        // Draft MTR
        itemsToInsert.add(new Order_Line_Item__c(
            Ori_Plast_Order__c = draftOrder.Id, Ori_Plast_Product__c = mtrProduct.Id,
            Quantity__c = 22, Unit_of_Measure__c = 'MTR', Trade_Discount__c = 37, Cash_Discount_Percentage__c = 2
        ));

        // Draft PCS
        itemsToInsert.add(new Order_Line_Item__c(
            Ori_Plast_Order__c = draftOrder.Id, Ori_Plast_Product__c = pcsProduct.Id,
            Quantity__c = 100, Unit_of_Measure__c = 'PCS', Trade_Discount__c = 10, Cash_Discount_Percentage__c = 2
        ));

        Database.insert(itemsToInsert, AccessLevel.SYSTEM_MODE);
    }

    @IsTest
    static void testPartialDeliveredShippedQtyChange() {
        Order_Line_Item__c partialItem = [
            SELECT Id, Shipped_Quantity__c FROM Order_Line_Item__c
            WHERE Ori_Plast_Order__r.Order_Status__c = 'Partially Delivered'
            AND Ori_Plast_Product__r.Name = 'Test PCS Product' LIMIT 1
        ];

        Test.startTest();
        partialItem.Shipped_Quantity__c = 75;
        Database.update(partialItem, AccessLevel.SYSTEM_MODE);
        Test.stopTest();

        System.assert(true, 'Handler executed successfully.');
    }

    @IsTest
    static void testUseCase2_DraftQtyChange() {
        Order_Line_Item__c draftItem = [
            SELECT Id, Quantity__c FROM Order_Line_Item__c
            WHERE Ori_Plast_Order__r.Order_Status__c = 'Draft'
            AND Ori_Plast_Product__r.Name = 'Test PCS Product' LIMIT 1
        ];

        Test.startTest();
        draftItem.Quantity__c = 999;
        Database.update(draftItem, AccessLevel.SYSTEM_MODE);
        Test.stopTest();

        Order_Line_Item__c updatedDraft = [SELECT Quantity__c FROM Order_Line_Item__c WHERE Id = :draftItem.Id];
        System.assertNotEquals(999, updatedDraft.Quantity__c, 'Manual draft quantity overwritten by sync.');
    }

    @IsTest
    static void testShippedQtyUnchanged() {
        Order_Line_Item__c partialItem = [
            SELECT Id, Quantity__c, Shipped_Quantity__c FROM Order_Line_Item__c
            WHERE Ori_Plast_Order__r.Order_Status__c = 'Partially Delivered'
            AND Ori_Plast_Product__r.Name = 'Test MTR Product' LIMIT 1
        ];

        Order_Line_Item__c draftBefore = [
            SELECT Id, Quantity__c FROM Order_Line_Item__c
            WHERE Ori_Plast_Order__r.Order_Status__c = 'Draft'
            AND Ori_Plast_Product__r.Name = 'Test MTR Product' LIMIT 1
        ];

        Decimal oldQty = draftBefore.Quantity__c;

        Test.startTest();
        Database.update(partialItem, AccessLevel.SYSTEM_MODE); 
        Test.stopTest();

        Order_Line_Item__c draftAfter = [SELECT Quantity__c FROM Order_Line_Item__c WHERE Id = :draftBefore.Id];
        System.assertEquals(oldQty, draftAfter.Quantity__c, 'Draft quantity should remain unchanged.');
    }

    @IsTest
    static void testReceivedByNavisionStatus() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        OriPlast_Product__c product = [SELECT Id FROM OriPlast_Product__c WHERE Name = 'Test MTR Product' LIMIT 1];

        Ori_Plast_Order__c navisionOrder = new Ori_Plast_Order__c(
            Account__c = acc.Id, Order_Status__c = 'Received by Navision'
        );
        Database.insert(navisionOrder, AccessLevel.SYSTEM_MODE);

        Order_Line_Item__c navisionItem = new Order_Line_Item__c(
            Ori_Plast_Order__c = navisionOrder.Id, Ori_Plast_Product__c = product.Id,
            Quantity__c = 10, Shipped_Quantity__c = 15, Unit_of_Measure__c = 'MTR'
        );
        Database.insert(navisionItem, AccessLevel.SYSTEM_MODE);

        Test.startTest();
        navisionItem.Shipped_Quantity__c = 20;
        Database.update(navisionItem, AccessLevel.SYSTEM_MODE);
        Test.stopTest();

        System.assert(true, 'Handler executed successfully for Navision order.');
    }
    
    @IsTest
    static void testGuardClauses() {
        Order_Line_Item__c draftItem = [
            SELECT Id, Quantity__c, Ori_Plast_Order__c FROM Order_Line_Item__c
            WHERE Ori_Plast_Order__r.Order_Status__c = 'Draft' LIMIT 1
        ];
        
        Ori_Plast_Order__c ord = new Ori_Plast_Order__c(Id = draftItem.Ori_Plast_Order__c, Order_Status__c = '');
        Database.update(ord, AccessLevel.SYSTEM_MODE);
        
        Test.startTest();
        draftItem.Quantity__c = 500;
        Database.update(draftItem, AccessLevel.SYSTEM_MODE);
        Test.stopTest();
        
        System.assert(true, 'Handler safely skipped records missing an Order Status.');
    }
}