@IsTest
public class EditOrderControllerTest {

    /* =========================
       TEST SETUP
       ========================= */
    @testSetup
static void setupData() {

    User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

    Account acc = new Account(
        Name = 'Test Distributor',
        Type = 'Distributor',
        Associated_User__c = u.Id
    );
    insert acc;

    OriPlast_Product__c prod = new OriPlast_Product__c(
        Name = 'Test Product',
        Category_Picklist__c = 'P2',
        Identifire_Picklist__c = 'PN100',
        Base_Unit_of_Measure__c = 'Nos',
        //GST_Value__c = 18,
        Item_Disc_Group__c = 'DISC01'
    );
    insert prod;

    // 🔴 INSERT ORDER FIRST
    Ori_Plast_Order__c ord = new Ori_Plast_Order__c(
        Account__c = acc.Id,
        Order_Status__c = 'Draft'
    );
    insert ord;

    // 🔴 THEN INSERT LINE ITEM WITH ORDER ID
    Order_Line_Item__c oli = new Order_Line_Item__c(
        Ori_Plast_Order__c = ord.Id,       // ✅ REQUIRED
        Ori_Plast_Product__c = prod.Id,
        Quantity__c = 5,
        Final_Price__c = 500,
        Price_After_Discount__c = 450,
        //OriPlast_Product_Unit_Price__c = 100,
        CGST__c = 45,
        SGST__c = 45,
        Trade_Discount_TD__c = 10,
        Cash_Discount_CD__c = 5
        //Unit_of_Measure__c = 'Nos',
        //Ori_Plast_Product_Name__c = prod.Name
    );
    insert oli;
}

    /* =========================
       FETCH ORDER LINE ITEMS
       ========================= */
    @IsTest
    static void testGetOrderLineItems() {
        Ori_Plast_Order__c ord = [SELECT Id FROM Ori_Plast_Order__c LIMIT 1];

        Test.startTest();
        List<EditOrderController.OrderLineDTO> rows =
            EditOrderController.getOrderLineItems(ord.Id);
        Test.stopTest();

        System.assertEquals(1, rows.size());
        System.assertNotEquals(null, rows[0].productId);
    }

    /* =========================
       FETCH ORDER
       ========================= */
    @IsTest
    static void testGetOriPlastOrder() {
        Ori_Plast_Order__c ord = [SELECT Id FROM Ori_Plast_Order__c LIMIT 1];

        Test.startTest();
        List<Ori_Plast_Order__c> res =
            EditOrderController.getOriPlastOrder(ord.Id);
        Test.stopTest();

        System.assertEquals(1, res.size());
    }

    /* =========================
       DELETE ORDER LINE ITEMS
       ========================= */
    @IsTest
    static void testDeleteOrderLineItems() {
        Order_Line_Item__c oli = [SELECT Id, Ori_Plast_Order__c FROM Order_Line_Item__c LIMIT 1];

        Test.startTest();
        String result =
            EditOrderController.deleteOrderLineItems(
                new List<Id>{ oli.Id },
                oli.Ori_Plast_Order__c
            );
        Test.stopTest();

        System.assertEquals('SUCCESS', result);
    }

    /* ❌ NEGATIVE DELETE */
    @IsTest
    static void testDeleteOrderLineItems_NoSelection() {
        Test.startTest();
        try {
            EditOrderController.deleteOrderLineItems(null, null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    /* =========================
       UPDATE ORDER LINE ITEMS
       ========================= */
    @IsTest
    static void testUpdateOrderLineItems() {
        Order_Line_Item__c oli = [SELECT Id, Quantity__c FROM Order_Line_Item__c LIMIT 1];
        oli.Quantity__c = 10;

        Test.startTest();
        String result =
            EditOrderController.updateOrderLineItems(
                new List<Order_Line_Item__c>{ oli }
            );
        Test.stopTest();

        System.assertEquals('SUCCESS', result);
    }

    /* ❌ NEGATIVE UPDATE */
    @IsTest
    static void testUpdateOrderLineItems_Empty() {
        Test.startTest();
        try {
            EditOrderController.updateOrderLineItems(null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    /* =========================
       GET PRODUCTS (NO INVENTORY)
       ========================= */
    @IsTest
    static void testGetProducts() {

        Test.startTest();
        List<OriPlast_Product__c> products =
            EditOrderController.getProducts(
                null,     // 🔴 MUST be null (Inventory__c safe)
                'P2',
                null,
                'PN100'
            );
        Test.stopTest();

        System.assert(!products.isEmpty());
    }
}