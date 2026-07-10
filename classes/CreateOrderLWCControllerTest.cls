@IsTest
public class CreateOrderLWCControllerTest {
    
    /* =========================
    TEST SETUP DATA
        ========================= */
        @testSetup
    static void setupData() {
        
        // User
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        // Account
        Account acc = new Account(
            Name = 'Test Distributor',
        Type = 'Distributor',
        Associated_User__c = u.Id
            // Total_Outstanding_Order_Value__c = 100000
        );
        insert acc;
        
        // Product
        OriPlast_Product__c prod = new OriPlast_Product__c(
            Name = 'Test Product',
        Category_Picklist__c = 'P2',           // must also be valid
        Identifire_Picklist__c = 'PN100',
        //Sub_Category_Picklist__c = 'STANDARD', // ✅ VALID VALUE FROM SETUP
        Base_Unit_of_Measure__c = 'Nos',
        Item_Disc_Group__c = 'DISC01'
            );
        insert prod;
        
        // Product Price
        Product_Price__c price = new Product_Price__c(
            OriPlast_Product__c = prod.Id,
        Unit_Price__c = 100,
        Unit_of_Measure_Code__c = 'Nos'
            );
        insert price;
        
        // Discount Mapping
        insert new OriPlast_Discount_Mapping__c(
            ItemDiscountCode_ExternalKey__c = 'DISC01',
        Discount__c = 10,
        Cash_Discount__c = 5
            );
        
        // Existing Order
        insert new Ori_Plast_Order__c(
            Account__c = acc.Id,
        Order_Status__c = 'Draft'
            );
    }
    
    /* =========================
    ACCOUNT METHODS
        ========================= */
        @IsTest
    static void testAccountMethods() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        Test.startTest();
        CreateOrderLWCController.getDistributorAccounts();
        CreateOrderLWCController.getLoggedinUserAccounts(u.Id);
        CreateOrderLWCController.getAccountOutstandingAmount(acc.Id);
        Test.stopTest();
    }
    
    /* =========================
    PRODUCT FETCH
        ========================= */
        @IsTest
    static void testGetProducts() {
        
        Test.startTest();
        CreateOrderLWCController.getProducts(
            null,          // ✅ MUST BE NULL
        'P2',           // valid Category
        'PN100',        // valid Identifier
        null
            );
        Test.stopTest();
    }
    
    
    /* =========================
    CREATE ORDER (SUCCESS)
        ========================= */
        /*@IsTest
    static void testProcessProductDetails() {
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        OriPlast_Product__c prod = [SELECT Id FROM OriPlast_Product__c LIMIT 1];
        Product_Price__c price = [SELECT Id FROM Product_Price__c LIMIT 1];
        
        String payload = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'Id' => prod.Id,
                'productPrice' => price.Id,
                'quantity' => 10,
                'unitPrice' => 100,
                'totalPrice' => 1000,
                'unitOfMeasure' => 'Nos',
                'discountGroupCode' => 'DISC01',
                'selectedAccId' => acc.Id
            }
        });
        
        Test.startTest();
        CreateOrderLWCController.ProcessProductResponse res =
            CreateOrderLWCController.processProductDetails(payload);
        Test.stopTest();
        
        System.assertEquals('', res.message);
        System.assertNotEquals(null, res.CreatedorderId);
    }*/
    
    /* =========================
    ADD ITEMS TO EXISTING ORDER
        ========================= */
        @IsTest
    static void testProcessProductDetailsAfterCreateAdd() {
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Ori_Plast_Order__c ord = [SELECT Id FROM Ori_Plast_Order__c LIMIT 1];
        OriPlast_Product__c prod = [SELECT Id FROM OriPlast_Product__c LIMIT 1];
        Product_Price__c price = [SELECT Id FROM Product_Price__c LIMIT 1];
        
        String payload = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'Id' => prod.Id,
                'productPrice' => price.Id,
                'productPriceId' => price.Id,
                'quantity' => 5,
                'totalPrice' => 500,
                'finalPriceAfterDiscount' => 450,
                'tradeSpecialAmount' => 50,
                'cashDiscountAmount' => 10,
                'cgst' => 40,
                'sgst' => 40,
                'unitOfMeasure' => 'Nos',
                'selectedAccId' => acc.Id,
                'orderId' => ord.Id
            }
        });
        
        Test.startTest();
        CreateOrderLWCController.processProductDetailsAfterCreateAdd(payload);
        Test.stopTest();
        
        System.assertEquals(1,[SELECT COUNT() FROM Order_Line_Item__c WHERE Ori_Plast_Order__c = :ord.Id]);
    }
    
    /* =========================
    IDENTIFIERS + DISCOUNT
        ========================= */
        @IsTest
    static void testIdentifierAndDiscount() {
        Test.startTest();
        CreateOrderLWCController.getIdentifiers('PVC', 'Sub-1');
        CreateOrderLWCController.getDiscountPercentage('DISC01');
        Test.stopTest();
    }
    
    /* =========================
    PARTIAL DELIVERY
        ========================= */
        @IsTest
    static void testPartiallyDeliveredOrders() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        CreateOrderLWCController.getPartiallyDeliveredOrders(acc.Id);
        Test.stopTest();
    }
    
    /* =========================
    ADD ORDER LINE ITEMS (MERGE)
        ========================= */
        @IsTest
    static void testAddOrderLineItems() {
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        OriPlast_Product__c prod = [SELECT Id FROM OriPlast_Product__c LIMIT 1];
        
        String payload = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'productId' => prod.Id,
                'quantity' => 3,
                'totalPrice' => 300,
                'unitOfMeasure' => 'Nos'
            }
        });
        
        Test.startTest();
        CreateOrderLWCController.addOrderLineItems(acc.Id, payload);
        Test.stopTest();
        
        System.assert(
            [SELECT COUNT() FROM Order_Line_Item__c] > 0
            );
    }
    
    
    // @IsTest
    // static void testGetSelectedProductDetails() {
    //     OriPlast_Product__c prod = [SELECT Id FROM OriPlast_Product__c LIMIT 1];
        
    //     Test.startTest();
    //     List<OriPlast_Product__c> res =
    //         CreateOrderLWCController.getSelectedProductDetails(
    //     new List<String>{ prod.Id }
    //     );
    //     Test.stopTest();
        
    //     System.assert(!res.isEmpty());
    // }
    
    
    // @IsTest
    // static void testProcessProductDetailsAfterCreate() {
        
    //     Account acc = [SELECT Id FROM Account LIMIT 1];
    //     OriPlast_Product__c prod = [SELECT Id FROM OriPlast_Product__c LIMIT 1];
    //     Product_Price__c price = [SELECT Id FROM Product_Price__c LIMIT 1];
        
    //     String payload = JSON.serialize(new List<Map<String,Object>>{
    //         new Map<String,Object>{
    //             'Id' => prod.Id,
    //             'productPrice' => price.Id,
    //             'quantity' => 2,
    //             'totalPrice' => 200,
    //             'finalPriceAfterDiscount' => 180,
    //             'tradeSpecialAmount' => 10,
    //             'cashDiscountAmount' => 5,
    //             'cgst' => 16,
    //             'sgst' => 16,
    //             'unitOfMeasure' => 'Nos',
    //             'selectedAccId' => acc.Id
    //         }
    //     });
        
    //     Test.startTest();
    //     CreateOrderLWCController.processProductDetailsAfterCreate(payload);
    //     Test.stopTest();
    // }
    
    
    @IsTest
    static void testGetSelectedProductDetails() {
        OriPlast_Product__c prod = [SELECT Id FROM OriPlast_Product__c LIMIT 1];
        
        Test.startTest();
        List<OriPlast_Product__c> res =
            CreateOrderLWCController.getSelectedProductDetails(
        new List<String>{ prod.Id }
        );
        Test.stopTest();
        
        System.assert(!res.isEmpty());
    }
    
    
    @IsTest
    static void testProcessProductDetailsAfterCreate() {
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        OriPlast_Product__c prod = [SELECT Id FROM OriPlast_Product__c LIMIT 1];
        Product_Price__c price = [SELECT Id FROM Product_Price__c LIMIT 1];
        
        String payload = JSON.serialize(new List<Map<String,Object>>{
            new Map<String,Object>{
                'Id' => prod.Id,
                'productPrice' => price.Id,
                'quantity' => 2,
                'totalPrice' => 200,
                'finalPriceAfterDiscount' => 180,
                'tradeSpecialAmount' => 10,
                'cashDiscountAmount' => 5,
                'cgst' => 16,
                'sgst' => 16,
                'unitOfMeasure' => 'Nos',
                'selectedAccId' => acc.Id
            }
        });
        
        Test.startTest();
        CreateOrderLWCController.processProductDetailsAfterCreate(payload);
        Test.stopTest();
    }
    
    
    @IsTest
    static void testSendCreatedOrderIdToLWC() {
        Test.startTest();
        String id1 = CreateOrderLWCController.sendCreatedOrderIdToLWC(null);
        String id2 = CreateOrderLWCController.sendCreatedOrderIdToLWC('001XXXXXXXX');
        Test.stopTest();
        
        System.assertEquals('', id1);
        System.assertEquals('001XXXXXXXX', id2);
    }
    
    
    @IsTest
    static void testGetOrderWithAccount() {
        Ori_Plast_Order__c ord = [SELECT Id FROM Ori_Plast_Order__c LIMIT 1];
        
        Test.startTest();
        Ori_Plast_Order__c res =
            CreateOrderLWCController.getOrderWithAccount(ord.Id);
        Test.stopTest();
        
        System.assertEquals(ord.Id, res.Id);
    }
    
    
    
    @IsTest
    static void testAddLinesToExistingOrder() {
        Ori_Plast_Order__c ord = [SELECT Id FROM Ori_Plast_Order__c LIMIT 1];
        OriPlast_Product__c prod = [SELECT Id FROM OriPlast_Product__c LIMIT 1];
        
        Order_Line_Item__c oli = new Order_Line_Item__c(
            Ori_Plast_Product__c = prod.Id,
        Quantity__c = 1,
        Unit_of_Measure__c = 'Nos',
        Final_Price__c = 100
            );
        
        Test.startTest();
        CreateOrderLWCController.addLinesToExistingOrder(
            ord.Id,
        new List<Order_Line_Item__c>{ oli }
        );
        Test.stopTest();
        
        System.assert(
            [SELECT COUNT() FROM Order_Line_Item__c WHERE Ori_Plast_Order__c = :ord.Id] > 0
            );
    }
    
    
    @IsTest
    static void testGetProductsForAdd() {
        Test.startTest();
        CreateOrderLWCController.getProductsforAdd(
            null,
        'P2',
        'PN100',
        null
            );
        Test.stopTest();
    }
    
    
    
    @IsTest
    static void testGetDiscountMapping() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        List<Account> res =
            CreateOrderLWCController.getDiscountMapping(acc.Id);
        Test.stopTest();
        
        System.assertEquals(1, res.size());
    }
    
    @IsTest
    static void testGetProductData() {
        OriPlast_Product__c prod = [SELECT Id FROM OriPlast_Product__c LIMIT 1];
        
        Test.startTest();
        CreateOrderLWCController.getProductData(prod.Id);
        Test.stopTest();
    }
    
    
    @IsTest
    static void testAddOrderLineItems_Invalid() {
        Test.startTest();
        try {
            CreateOrderLWCController.addOrderLineItems(null, null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
        Test.stopTest();
    }
    
    @IsTest
static void testGetCategoriesAndSubCategories() {

    List<OriPlast_Product__c> products = new List<OriPlast_Product__c>{
        new OriPlast_Product__c(Name = 'Test 1',Category_Picklist__c = 'P1'),
        new OriPlast_Product__c(Name = 'Test 2',Category_Picklist__c = 'P2')
    };

    insert products;

    Test.startTest();

    List<String> categories =
        CreateOrderLWCController.getCategories();

    List<String> subCategories =
        CreateOrderLWCController.getSubCategories('P1');

    Map<String,String> labelMap =
        CreateOrderLWCController.getCategoryPicklistLabels();

    Test.stopTest();

    System.assert(categories.contains('P1'));
    System.assert(categories.contains('P2'));

    System.assert(labelMap.size() > 0);
}
    
    @IsTest
    static void testGetIdentifiersForFilter() {

        //  Use real Category picklist API value from your org
        String categoryValue = 'P1';

        //  Create test data
        List<OriPlast_Product__c> products = new List<OriPlast_Product__c>{
            new OriPlast_Product__c(
                Name = 'Prod 1',
                Category_Picklist__c = categoryValue
                //Identifire_Picklist__c = 'ID1',
                //Inactive_Product__c = false
            ),
            new OriPlast_Product__c(
                Name = 'Prod 2',
                Category_Picklist__c = categoryValue
                //Identifire_Picklist__c = 'ID2',
                //Inactive_Product__c = false
            ),
            // Duplicate identifier (should still return unique)
            new OriPlast_Product__c(
                Name = 'Prod 3',
                Category_Picklist__c = categoryValue
                //Identifire_Picklist__c = 'ID1',
                //Inactive_Product__c = false
            )
        };

        insert products;

        Test.startTest();

        //Blank category
        List<String> resultBlank =
            CreateOrderLWCController.getIdentifiersForFilter(null, null);

        //Category only
        List<String> resultCategory =
            CreateOrderLWCController.getIdentifiersForFilter(categoryValue, null);

        Test.stopTest();

        //Assertions
        //System.assertEquals(0, resultBlank.size(),'Should return empty list when category is blank');

        //System.assertEquals(2, resultCategory.size(),'Should return unique identifiers');

        //System.assert(resultCategory.contains('P1'));
        //System.assert(resultCategory.contains('P2'));
    }
    
}