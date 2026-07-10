@isTest
public class recalculateOrderClassTest {

    @isTest
    static void testRecalculateOrder() {

        // 1️⃣ Account
        Account acc = new Account(
            Name = 'Test Account',
            Type = 'Distributor'
        );
        insert acc;

        // 2️⃣ Product
        OriPlast_Product__c prod = new OriPlast_Product__c(
            Name = 'Test Product'
        );
        insert prod;

        // 3️⃣ Product Price
        Product_Price__c price = new Product_Price__c(
            Unit_Price__c = 100,
            OriPlast_Product__c = prod.Id
        );
        insert price;

        // 4️⃣ Order
        Ori_Plast_Order__c order = new Ori_Plast_Order__c(
            Account__c = acc.Id,
            Order_Status__c = 'Draft'
        );
        insert order;

        // 5️⃣ Order Line Item (WITH DISCOUNTS)
        Order_Line_Item__c oli = new Order_Line_Item__c(
            Ori_Plast_Order__c = order.Id,
            Ori_Plast_Product__c = prod.Id,
            Quantity__c = 10,
            Trade_Discount__c = 10,              // 🔥 10% TD
            Cash_Discount_Percentage__c = 5      // 🔥 5% CD
        );
        insert oli;

        // 6️⃣ Execute
        Test.startTest();
        recalculateOrderClass.recalculateOrder(order.Id, acc.Id);
        Test.stopTest();

        // 7️⃣ Fetch Updated Line Item
        Order_Line_Item__c updatedOLI = [
            SELECT Final_Price__c,
                   CGST__c,
                   SGST__c,
                   Price_After_Discount__c,
                   Trade_Discount_TD__c,
                   Cash_Discount_CD__c
            FROM Order_Line_Item__c
            WHERE Id = :oli.Id
        ];

        // ✅ ASSERTIONS (VERY IMPORTANT)

        System.assertNotEquals(
            null,
            updatedOLI.Final_Price__c,
            'Final price should be calculated'
        );

        System.assertNotEquals(
            null,
            updatedOLI.CGST__c,
            'CGST should be calculated'
        );

        System.assertNotEquals(
            null,
            updatedOLI.SGST__c,
            'SGST should be calculated'
        );

        System.assertNotEquals(
            null,
            updatedOLI.Trade_Discount_TD__c,
            'Trade Discount (TD) should be calculated'
        );

        System.assertNotEquals(
            null,
            updatedOLI.Cash_Discount_CD__c,
            'Cash Discount (CD) should be calculated'
        );

        // 8️⃣ OPTIONAL (only if you uncomment order update in class)

        /*
        Ori_Plast_Order__c updatedOrder = [
            SELECT Final_Order_Value__c
            FROM Ori_Plast_Order__c
            WHERE Id = :order.Id
        ];

        System.assert(
            updatedOrder.Final_Order_Value__c != null &&
            updatedOrder.Final_Order_Value__c > 0,
            'Order total should be updated'
        );
        */
    }
}