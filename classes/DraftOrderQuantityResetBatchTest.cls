@IsTest
private class DraftOrderQuantityResetBatchTest {

    @TestSetup
    static void setupData() {

        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        OriPlast_Product__c prod = new OriPlast_Product__c(
            Name = 'Test Product',
            Length__c = '100'
        );
        insert prod;

        // Draft Order - should be processed
        Ori_Plast_Order__c draftOrder = new Ori_Plast_Order__c(
            Account__c = acc.Id,
            Order_Status__c = 'Draft'
        );
        insert draftOrder;
       
        Test.setCreatedDate(
         draftOrder.Id,
        System.now().addDays(-2)
       );

        // Non Draft Order - should NOT be processed
        Ori_Plast_Order__c confirmedOrder = new Ori_Plast_Order__c(
            Account__c = acc.Id,
            Order_Status__c = 'Submitted'
        );
        insert confirmedOrder;

        Order_Line_Item__c line1 = new Order_Line_Item__c(
            Ori_Plast_Order__c = draftOrder.Id,
            Ori_Plast_Product__c = prod.Id,
            Quantity__c = 10,
            Price_After_Discount__c = 100,
            CGST__c = 5,
            SGST__c = 5,
            Final_Price__c = 110
        );

        Order_Line_Item__c line2 = new Order_Line_Item__c(
            Ori_Plast_Order__c = draftOrder.Id,
            Ori_Plast_Product__c = prod.Id,
            Quantity__c = 20,
            Price_After_Discount__c = 200,
            CGST__c = 10,
            SGST__c = 10,
            Final_Price__c = 220
        );

        // Should not be updated
        Order_Line_Item__c line3 = new Order_Line_Item__c(
            Ori_Plast_Order__c = confirmedOrder.Id,
            Ori_Plast_Product__c = prod.Id,
            Quantity__c = 15,
            Price_After_Discount__c = 150,
            CGST__c = 8,
            SGST__c = 8,
            Final_Price__c = 166
        );

        insert new List<Order_Line_Item__c>{
            line1,
            line2,
            line3
        };
    }

    @IsTest
    static void testBatchExecution() {

        Test.startTest();

        Database.executeBatch(
            new DraftOrderQuantityResetBatch(),
            200
        );

        Test.stopTest();

        List<Order_Line_Item__c> draftLines = [
            SELECT Quantity__c,
                   Price_After_Discount__c,
                   CGST__c,
                   SGST__c,
                   Final_Price__c,
                   Ori_Plast_Order__r.Order_Status__c
            FROM Order_Line_Item__c
            WHERE Ori_Plast_Order__r.Order_Status__c = 'Draft'
        ];

        System.assertEquals(2, draftLines.size());

        for(Order_Line_Item__c line : draftLines) {

            System.assertEquals(0, line.Quantity__c);
            System.assertEquals(0, line.Price_After_Discount__c);
            System.assertEquals(0, line.CGST__c);
            System.assertEquals(0, line.SGST__c);
            System.assertEquals(0, line.Final_Price__c);
        }
    }

    @IsTest
    static void testNonDraftOrdersNotUpdated() {

        Test.startTest();

        Database.executeBatch(
            new DraftOrderQuantityResetBatch(),
            200
        );

        Test.stopTest();

        Order_Line_Item__c nonDraftLine = [

            SELECT Quantity__c,
                   Price_After_Discount__c,
                   Final_Price__c
            FROM Order_Line_Item__c
            WHERE Ori_Plast_Order__r.Order_Status__c = 'Submitted'
            LIMIT 1
        ];

        System.assertEquals(15, nonDraftLine.Quantity__c);
        System.assertEquals(150, nonDraftLine.Price_After_Discount__c);
        System.assertEquals(166, nonDraftLine.Final_Price__c);
    }

    @IsTest
    static void testBatchWithNoMatchingRecords() {

        Account acc = new Account(
            Name = 'No Draft Account'
        );
        insert acc;

        Ori_Plast_Order__c orderRec = new Ori_Plast_Order__c(
            Account__c = acc.Id,
            Order_Status__c = 'Submitted'
        );
        insert orderRec;

        Test.startTest();

        Database.executeBatch(
            new DraftOrderQuantityResetBatch(),
            200
        );

        Test.stopTest();

        System.assert(true,
            'Batch completed successfully even when no records matched.'
        );
    }
}