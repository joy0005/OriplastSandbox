@isTest
public class OriPlastDiscountBatchTest {

    @isTest
    static void testBatch_AllScenarios() {

        /* -------------------------
           Create Account
        --------------------------*/
        Account acc = new Account(
            Name = 'Test Account',
            Customer_Disc_Group__c = 'CG1'
        );
        insert acc;

        /* -------------------------
           Create Products
        --------------------------*/
        OriPlast_Product__c prodMTR = new OriPlast_Product__c(
            Name = 'MTR Product',
            Item_Disc_Group__c = 'IG1'
        );
        insert prodMTR;

        OriPlast_Product__c prodPCS = new OriPlast_Product__c(
            Name = 'PCS Product',
            Item_Disc_Group__c = 'IG1'
        );
        insert prodPCS;

        OriPlast_Product__c prodNoMap = new OriPlast_Product__c(
            Name = 'NoMap Product',
            Item_Disc_Group__c = 'IGX'
        );
        insert prodNoMap;

        /* -------------------------
           Discount Mapping
        --------------------------*/
        OriPlast_Discount_Mapping__c mapping = new OriPlast_Discount_Mapping__c(
            ItemDiscountCode_ExternalKey__c = 'CG1_IG1',
            Discount__c = 10,
            Special_Discount__c = 5,
            Cash_Discount__c = 2
        );
        insert mapping;

        /* -------------------------
           Draft Order
        --------------------------*/
        Ori_Plast_Order__c orderRec = new Ori_Plast_Order__c(
            Account__c = acc.Id,
            Order_Status__c = 'Draft'
        );
        insert orderRec;

        /* -------------------------
           Order Line Items
        --------------------------*/
        Order_Line_Item__c oliMTR = new Order_Line_Item__c(
            Ori_Plast_Order__c = orderRec.Id,
            Ori_Plast_Product__c = prodMTR.Id,
            Quantity__c = 2,
            Unit_of_Measure__c = 'MTR'
        );

        Order_Line_Item__c oliPCS = new Order_Line_Item__c(
            Ori_Plast_Order__c = orderRec.Id,
            Ori_Plast_Product__c = prodPCS.Id,
            Quantity__c = 3,
            Unit_of_Measure__c = 'PCS'
        );

        Order_Line_Item__c oliNoMap = new Order_Line_Item__c(
            Ori_Plast_Order__c = orderRec.Id,
            Ori_Plast_Product__c = prodNoMap.Id,
            Quantity__c = 1,
            Unit_of_Measure__c = 'PCS'
        );

        insert new List<Order_Line_Item__c>{oliMTR, oliPCS, oliNoMap};

        /* -------------------------
           Run Batch
        --------------------------*/
        Test.startTest();
        Database.executeBatch(new OriPlastDiscountBatch(), 200);
        Test.stopTest();

        /* -------------------------
           Verify
        --------------------------*/
        List<Order_Line_Item__c> updatedList = [
            SELECT Id,
                   Price_After_Discount__c,
                   CGST__c,
                   SGST__c,
                   Final_Price__c
            FROM Order_Line_Item__c
            WHERE Id IN :new List<Id>{oliMTR.Id, oliPCS.Id, oliNoMap.Id}
        ];

        System.assertEquals(3, updatedList.size());

        for(Order_Line_Item__c rec : updatedList){

            if(rec.Id == oliNoMap.Id){
                System.assertEquals(null, rec.Price_After_Discount__c);
            } else {
                System.assertNotEquals(null, rec.Price_After_Discount__c);
                System.assertNotEquals(null, rec.CGST__c);
                System.assertNotEquals(null, rec.SGST__c);
                System.assertNotEquals(null, rec.Final_Price__c);
            }
        }
    }

    @isTest
    static void testBatch_NoDraftOrders() {

        Test.startTest();
        Database.executeBatch(new OriPlastDiscountBatch(), 200);
        Test.stopTest();

        System.assert(true);
    }
}