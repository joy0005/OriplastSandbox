@IsTest
private class OutstandingOrderValueTest {

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
       FETCH OUTSTANDING ORDER VALUE
       ========================= */
    @IsTest
    static void testgetTotalOutstandingValue() {
        
        Test.startTest();
        Decimal value = OutstandingOrderValue.getTotalOutstandingValue();
        Test.stopTest();

    }
    
    @IsTest
    static void testgetNumberTOWordConvertion1() {
        
        Test.startTest();
        String value = OutstandingOrderValue.getNumberTOWordConvertion(111111.20);
        Test.stopTest();
    }
    @IsTest
    static void testgetNumberTOWordConvertion2() {
        
        Test.startTest();
        String value = OutstandingOrderValue.getNumberTOWordConvertion(1111.20);
        Test.stopTest();
    }
    
    @IsTest
    static void testgetNumberTOWordConvertion3() {
        
        Test.startTest();
        String value = OutstandingOrderValue.getNumberTOWordConvertion(111);
        Test.stopTest();
    }
    
    @IsTest
    static void testgetNumberTOWordConvertion4() {
        
        Test.startTest();
        String value = OutstandingOrderValue.getNumberTOWordConvertion(111111111);
        Test.stopTest();
    }
}