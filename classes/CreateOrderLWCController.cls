public with sharing class CreateOrderLWCController {
    
    @AuraEnabled
    public static List<Account> getDistributorAccounts() {
        return [
            SELECT Id, Name, Total_Outstanding_Order_Value__c, Type, Customer_Disc_Group__c 
            FROM Account WHERE Type = 'Distributor' AND Associated_User__r.IsActive = true];
    }
    
    @AuraEnabled
    public static List<Account> getLoggedinUserAccounts(String UserId) {
        return [SELECT Id, Name,Total_Outstanding_Order_Value__c , Type,Customer_Disc_Group__c FROM Account WHERE Type = 'Distributor'
                AND Associated_User__c =: UserId];
    }
    
    @AuraEnabled
    public static Account getAccountOutstandingAmount(String AccountId) {
        return [SELECT Id, Name,Total_Outstanding_Order_Value__c FROM Account WHERE Id =: AccountId LIMIT 1];
    }
    
    @AuraEnabled
    public static List<OriPlast_Product__c> getProducts(
        Id accountId,                     // ADD THIS
    String CategoryValue,
    String identifierValue,
    String subCategoryValue
    ) {
        String productQuery =
            'SELECT Id, Name, Product_Category_Code_Picklist__c, Identifire_Picklist__c, Size__c, ' +
            'Category_Picklist__c, Sub_Category_Picklist__c , ' +
            'OriPlast_Product_Unique_Key__c, ' +
            'Base_Unit_of_Measure__c, GST_Value__c ' +
            'FROM OriPlast_Product__c ' +
            'WHERE (Inactive_Product__c = false OR Inactive_Product__c = NULL)';
        
        // ACCOUNT → INVENTORY → PRODUCT FILTER
        if (accountId != null) {
            productQuery +=
                ' AND Id IN (' +
                ' SELECT Ori_Plast_Product__c FROM Inventory__c ' +
                ' WHERE Account__c = :accountId' +
                ')';
        }
        
        if (!String.isBlank(CategoryValue)) {
            productQuery += ' AND Category_Picklist__c = :CategoryValue';
        }
        if (!String.isBlank(identifierValue)) {
            productQuery += ' AND Identifire_Picklist__c = :identifierValue';
        }
        if (!String.isBlank(subCategoryValue)) {
            productQuery += ' AND Sub_Category_Picklist__c = :subCategoryValue';
        }
        
        return Database.query(productQuery);
    }
    
    
    //Get Product Details
    @AuraEnabled
    public static List<OriPlast_Product__c> getSelectedProductDetails(List<String> productIds) {
        if (productIds == null || productIds.isEmpty()) {
            return new List<OriPlast_Product__c>();
        }
        
        // Step 1: Query the OriPlast_Product__c records to get the Category_Picklist__c values
        List<OriPlast_Product__c> products = [
        SELECT Id, Category_Picklist__c ,GST_Value__c
        FROM OriPlast_Product__c 
        WHERE Id IN :productIds
    ];
        
        // Step 2: Collect all unique Category_Picklist__c values
        Set<String> categoryPicklistValues = new Set<String>();
        for (OriPlast_Product__c product : products) {
            if (product.Category_Picklist__c != null) {
                categoryPicklistValues.add(product.Category_Picklist__c);
            }
        }
        
        // Step 3: Query the custom metadata Unit_of_Measure_UoM_Management__mdt based on Category_Picklist__c values
        List<Unit_of_Measure_UoM_Management__mdt> uomMetadata = [
        SELECT MasterLabel, Unit_of_Measure__c
        FROM Unit_of_Measure_UoM_Management__mdt
        WHERE MasterLabel IN :categoryPicklistValues
    ];
        
        // Create a map to store the metadata results
        Map<String, String> uomMapping = new Map<String, String>();
        for (Unit_of_Measure_UoM_Management__mdt uom : uomMetadata) {
            uomMapping.put(uom.MasterLabel, uom.Unit_of_Measure__c);
        }
        
        // Step 4: Query the OriPlast_Product__c records again to get all the details
        List<OriPlast_Product__c> selectedProducts = [
        SELECT Id, Name , Base_Unit_of_Measure__c, Size__c, Length__c, Length_In_Meter__c, Item_Disc_Group__c, Category_Picklist__c,GST_Value__c,
        (SELECT Id, Unit_Price__c, Unit_of_Measure_Code__c FROM Product_Prices__r)
        FROM OriPlast_Product__c
        WHERE Id IN :productIds
    ];
        
        // Step 5: Attach the corresponding Unit_of_Measure__c from metadata to the products
        for (OriPlast_Product__c product : selectedProducts) {
            if (product.Category_Picklist__c != null && uomMapping.containsKey(product.Category_Picklist__c)) {
                product.Base_Unit_of_Measure__c = uomMapping.get(product.Category_Picklist__c);
            }
            
            // Step 6: Replace Unit_of_Measure_Code__c in Product Prices with metadata value
            if (product.Product_Prices__r != null) {
                for (Product_Price__c price : product.Product_Prices__r) {
                    if (uomMapping.containsKey(price.Unit_of_Measure_Code__c)) {
                        price.Unit_of_Measure_Code__c = uomMapping.get(price.Unit_of_Measure_Code__c);
                    }
                }
            }
        }
        
        return selectedProducts;
    }
    
    
    public class ProcessProductResponse {
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String orderName { get; set; }
        @AuraEnabled public String CreatedorderId { get; set; }
    }
    
    /*@AuraEnabled
    public static ProcessProductResponse processProductDetails(String products) {
        ProcessProductResponse response = new ProcessProductResponse();
        try {
            // Deserialize the JSON string into an Object
            Object deserializedData = JSON.deserializeUntyped(products);
            
            if (deserializedData instanceof List<Object>) {
                List<Object> productList = (List<Object>) deserializedData;
                List<String> discountGroupCodes = new List<String>();
                Map<String, Map<String, Decimal>> discountMap = new Map<String, Map<String, Decimal>>();
                List<Order_Line_Item__c> orderLineItems = new List<Order_Line_Item__c>();
                
                // Prepare to extract all discount group codes
                for (Object productObj : productList) {
                    if (productObj instanceof Map<String, Object>) {
                        Map<String, Object> product = (Map<String, Object>) productObj;
                        String discountGroupCode = (String) product.get('discountGroupCode');
                        system.debug('discountGroupCode'+discountGroupCode);
                        
                        if (discountGroupCode != null && discountGroupCode != '') {
                            discountGroupCodes.add(discountGroupCode);
                        }
                    }
                }
                
                // Query discounts in bulk
                if (!discountGroupCodes.isEmpty()) {
                    List<OriPlast_Discount_Mapping__c> discounts = [
                    SELECT ItemDiscountCode_ExternalKey__c, Discount__c, Cash_Discount__c
                    FROM OriPlast_Discount_Mapping__c
                    WHERE ItemDiscountCode_ExternalKey__c IN :discountGroupCodes
                ];
                    system.debug('!!discounts'+discounts);
                    for (OriPlast_Discount_Mapping__c discount : discounts) {
                        Map<String, Decimal> discountValues = new Map<String, Decimal>();
                        discountValues.put('Discount', discount.Discount__c);
                        discountValues.put('CashDiscount', discount.Cash_Discount__c);
                        discountMap.put(discount.ItemDiscountCode_ExternalKey__c, discountValues);
                        system.debug('discountValues'+discountValues);
                    }
                }
                
                String selectedAccId;
                Decimal AccountOutstandingValue = 0.00;
                Decimal TotalOrderValueAfterDiscount = 0.00;
                Decimal TotalOutstandingValueAfterDiscount = 0.00;
                
                for (Object productObj : productList) {
                    if (productObj instanceof Map<String, Object>) {
                        Map<String, Object> product = (Map<String, Object>) productObj;
                        String productId = (String) product.get('Id');
                        Decimal unitPrice = (Decimal) product.get('unitPrice');
                        String unitOfMeasure = (String) product.get('unitOfMeasure');
                        Decimal totalPrice = (Decimal) product.get('totalPrice');
                        Integer quantity = (Integer) product.get('quantity');
                        String discountGroupCode = (String) product.get('discountGroupCode');
                        system.debug('@@@@discountGroupCode'+discountGroupCode);
                        selectedAccId = (String) product.get('selectedAccId');
                        String ProductPriceId = (String) product.get('productPrice');
                        
                        Decimal discount = 0.00;
                        Decimal cashDiscount = 4;
                        
                        if (discountGroupCode != null && discountMap.containsKey(discountGroupCode)) {
                            discount = discountMap.get(discountGroupCode).get('Discount') != null
                                ? discountMap.get(discountGroupCode).get('Discount')
                                : 0;
                            cashDiscount = discountMap.get(discountGroupCode).get('CashDiscount') != null
                                ? discountMap.get(discountGroupCode).get('CashDiscount')
                                : 4;
                        }
                        system.debug('discount'+discount);
                        
                        Decimal tradeDiscountAmount = (totalPrice * discount) / 100;
                        Decimal priceAfterTradeDiscount = totalPrice - tradeDiscountAmount;
                        Decimal cashDiscountAmount = (priceAfterTradeDiscount * cashDiscount) / 100;
                        Decimal priceAfterCashDiscount = priceAfterTradeDiscount - cashDiscountAmount;
                        Decimal extraDiscountAmount = 0.00;
                        
                        if (priceAfterCashDiscount > 100000) {
                            extraDiscountAmount = (priceAfterCashDiscount * 4) / 100;
                            priceAfterCashDiscount -= extraDiscountAmount;
                        }
                        Decimal gstAmount = (priceAfterCashDiscount * 18) / 100;
                        Decimal finalPrice = priceAfterCashDiscount + gstAmount;
                        Decimal cgst = gstAmount / 2;
                        Decimal sgst = gstAmount / 2;
                        
                        TotalOrderValueAfterDiscount += finalPrice;
                        
                        Order_Line_Item__c orderLineItem = new Order_Line_Item__c(
                            Ori_Plast_Product__c = productId,
                        Quantity__c = quantity,
                        Final_Price__c = finalPrice,
                        Unit_of_Measure__c = unitOfMeasure,
                        Trade_Discount__c = discount,
                        Trade_Discount_TD__c = tradeDiscountAmount,
                        Cash_Discount_CD__c = cashDiscountAmount,
                        SGST__c = sgst,
                        CGST__c = cgst,
                        Price_After_Discount__c = priceAfterCashDiscount,
                        Special_Discount__c = extraDiscountAmount,
                        OriPlast_Product_Price__c = ProductPriceId
                            );
                        orderLineItems.add(orderLineItem);
                    }
                }
                
                Account Acc = [SELECT Id, Name, Total_Outstanding_Order_Value__c FROM Account WHERE Id = :selectedAccId LIMIT 1];
                AccountOutstandingValue = Acc.Total_Outstanding_Order_Value__c;
                TotalOutstandingValueAfterDiscount = TotalOrderValueAfterDiscount + AccountOutstandingValue;
                
                if (TotalOutstandingValueAfterDiscount > 3000000) {
                    response.message = 'Your Outstanding Order value is more than ₹30 Lacs. Please clear some of your outstanding orders and then place the order.';
                } else if (TotalOrderValueAfterDiscount > 1500000) {
                    response.message = 'Total Order Value should not be more than ₹ 1500000 (Fifteen Lakhs)';
                } else {
                    Ori_Plast_Order__c order = new Ori_Plast_Order__c(
                        Account__c = selectedAccId,
                    Order_Status__c = 'Draft'
                        );
                    insert order;
                    
                    for (Order_Line_Item__c lineItem : orderLineItems) {
                        lineItem.Ori_Plast_Order__c = order.Id;
                    }
                    insert orderLineItems;
                    
                    response.message = '';
                    Ori_Plast_Order__c getOrder = [SELECT Id,Name FROM Ori_Plast_Order__c WHERE Id =:order.Id];
                    response.orderName = getOrder.Name;
                    response.CreatedorderId = getOrder.Id;
                }
            } else {
                throw new AuraHandledException('Invalid product list format');
            }
        } catch (Exception ex) {
            System.debug('Error processing product details: ' + ex.getMessage());
            throw new AuraHandledException('Failed to process products: ' + ex.getMessage());
        }
        return response;
    }*/
    
    
    
    // =================================================================
    @AuraEnabled
    public static ProcessProductResponse processProductDetailsAfterCreate(String products) {
        ProcessProductResponse response = new ProcessProductResponse();
        
        try {
            List<Object> productList = (List<Object>) JSON.deserializeUntyped(products);
            
            if (productList == null || productList.isEmpty()) {
                throw new AuraHandledException('No products received');
            }
            
            String selectedAccId;
            Decimal totalOrderValue = 0;
            
            List<Order_Line_Item__c> orderLineItems = new List<Order_Line_Item__c>();
            
            for (Object obj : productList) {
                Map<String, Object> product = (Map<String, Object>) obj;
                selectedAccId = (String) product.get('selectedAccId');
                Integer quantity = (Integer) product.get('quantity');
                String productId = (String) product.get('Id');               // JS sends Id
                String productPriceId = (String) product.get('productPrice'); // JS sends productPrice
                
                Decimal finalPrice = (product.get('totalPrice') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('totalPrice'))));
                
                Decimal priceAfterDiscount = (product.get('finalPriceAfterDiscount') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('finalPriceAfterDiscount'))));
                
                Decimal tradeDiscountAmount = product.get('tradeSpecialAmount') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('tradeSpecialAmount')));
                
                Decimal cashDiscountAmount = product.get('cashDiscountAmount') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('cashDiscountAmount')));
                
                Decimal cgst = product.get('cgst') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('cgst')));
                
                Decimal sgst = product.get('sgst') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('sgst')));
                String unitOfMeasure = (String) product.get('unitOfMeasure');
                
                Decimal tradeDiscountPercent = product.get('tradeDiscountPercent') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('tradeDiscountPercent')));
                
                Decimal cashDiscountPercent = product.get('cashDiscountPercent') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('cashDiscountPercent')));
                
                
                totalOrderValue += finalPrice;
                Order_Line_Item__c line = new Order_Line_Item__c(
                    Ori_Plast_Product__c = productId,
                Quantity__c = quantity,
                // Final_Price__c = finalPrice + cgst + sgst,
                Final_Price__c = finalPrice,
                Price_After_Discount__c = priceAfterDiscount,
                
                // AMOUNTS
                Trade_Discount_TD__c = tradeDiscountAmount,
                Cash_Discount_CD__c = cashDiscountAmount,
                
                // PERCENTAGES (THIS WAS MISSING)
                Trade_Discount__c = tradeDiscountPercent,
                Cash_Discount_Percentage__c = cashDiscountPercent,
                
                CGST__c = cgst,
                SGST__c = sgst,
                Unit_of_Measure__c = unitOfMeasure,
                OriPlast_Product_Price__c = productPriceId
                    );
                
                
                orderLineItems.add(line);
            }
            
            // ================= CREDIT LIMIT =================
            Account acc = [
            SELECT Id, Total_Outstanding_Order_Value__c
            FROM Account
            WHERE Id = :selectedAccId
        ];
            
            Decimal totalOutstanding = (acc.Total_Outstanding_Order_Value__c == null ? 0 : acc.Total_Outstanding_Order_Value__c) + totalOrderValue;
            
            if (totalOutstanding > 3000000) {
                response.message = 'Outstanding amount exceeds ₹30 Lakhs. Please clear previous dues.';
                return response;
            }
            
            if (totalOrderValue > 1500000) {
                response.message = 'Total order value cannot exceed ₹15,00,000';
                return response;
            }
            
            // ================= CREATE ORDER =================
            
            Ori_Plast_Order__c order = new Ori_Plast_Order__c(
                Account__c = selectedAccId,
            Order_Status__c = 'Draft'
                );
            insert order;
            
            for (Order_Line_Item__c li : orderLineItems) {
                li.Ori_Plast_Order__c = order.Id;
            }
            insert orderLineItems;
            
            Ori_Plast_Order__c ord = [SELECT Id, Name FROM Ori_Plast_Order__c WHERE Id = :order.Id];
            
            response.CreatedorderId = ord.Id;
            response.orderName = ord.Name;
            response.message = '';
            
        } catch (Exception ex) {
            System.debug('❌ Order creation failed: ' + ex.getMessage());
            throw new AuraHandledException('Order failed: ' + ex.getMessage());
        }
        
        return response;
    }
    
    
    @AuraEnabled
    public static ProcessProductResponse processProductDetailsAfterCreateAdd(String products) {
        
        ProcessProductResponse response = new ProcessProductResponse();
        
        try {
            // ---------------- DESERIALIZE ----------------
            List<Object> productList = (List<Object>) JSON.deserializeUntyped(products);
            
            if (productList == null || productList.isEmpty()) {
                throw new AuraHandledException('No products received');
            }
            
            String selectedAccId;
            Id existingOrderId;
            Decimal totalOrderValue = 0;
            
            List<Order_Line_Item__c> orderLineItems = new List<Order_Line_Item__c>();
            
            // ---------------- BUILD LINE ITEMS ----------------
            for (Object obj : productList) {
                Map<String, Object> product = (Map<String, Object>) obj;
                
                selectedAccId   = (String) product.get('selectedAccId');
                existingOrderId = (String) product.get('orderId'); // 🔴 REQUIRED
                
                if (existingOrderId == null) {
                    throw new AuraHandledException('Order Id is required to add items.');
                }
                
                Integer quantity = (Integer) product.get('quantity');
                
                String productId      = (String) product.get('Id');
                // String productPriceId = (String) product.get('productPrice');
                
                Decimal finalPrice = product.get('totalPrice') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('totalPrice')));
                
                Decimal priceAfterDiscount = product.get('finalPriceAfterDiscount') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('finalPriceAfterDiscount')));
                
                Decimal tradeDiscountAmount = product.get('tradeSpecialAmount') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('tradeSpecialAmount')));
                
                Decimal cashDiscountAmount = product.get('cashDiscountAmount') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('cashDiscountAmount')));
                
                Decimal cgst = product.get('cgst') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('cgst')));
                
                Decimal sgst = product.get('sgst') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('sgst')));
                
                Decimal unitPrice = (Decimal) product.get('unitPrice');
                String unitOfMeasure = (String) product.get('unitOfMeasure');
                
                Decimal tradeSpecialPercent = product.get('tradeSpecialPercent') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('tradeSpecialPercent')));
                
                Decimal cashDiscountPercent = product.get('cashDiscountPercent') == null ? 0 :
                    Decimal.valueOf(String.valueOf(product.get('cashDiscountPercent')));
                
                String productPriceId = (String) product.get('productPriceId');
                
                if (productPriceId == null) {
                    throw new AuraHandledException('Product Price Id is required.');
                }
                
                totalOrderValue += finalPrice;
                
                orderLineItems.add(new Order_Line_Item__c(
                    Ori_Plast_Product__c        = productId,
                Quantity__c                 = quantity,
                Final_Price__c              = finalPrice ,
                //Final_Price__c              = finalPrice  + cgst + sgst,
                Price_After_Discount__c     = priceAfterDiscount,
                Trade_Discount_TD__c        = tradeDiscountAmount,
                Cash_Discount_CD__c         = cashDiscountAmount,
                CGST__c                     = cgst,
                SGST__c                     = sgst,
                Unit_of_Measure__c          = unitOfMeasure,
                OriPlast_Product_Price__c = productPriceId,
                Trade_Discount__c           = tradeSpecialPercent,
                Cash_Discount_Percentage__c = cashDiscountPercent
                    ));
            }
            
            // ---------------- VALIDATE EXISTING ORDER ----------------
            Ori_Plast_Order__c order = [SELECT Id, Name, Account__c FROM Ori_Plast_Order__c WHERE Id = :existingOrderId LIMIT 1 ];
            
            
            // ---------------- CREDIT LIMIT CHECK ----------------
            Account acc = [
            SELECT Id, Total_Outstanding_Order_Value__c
            FROM Account
            WHERE Id = :selectedAccId
            LIMIT 1
        ];
            
            Decimal totalOutstanding =
                (acc.Total_Outstanding_Order_Value__c == null ? 0 : acc.Total_Outstanding_Order_Value__c)
                + totalOrderValue;
            
            if (totalOutstanding > 3000000) {
                response.message = 'Outstanding amount exceeds ₹30 Lakhs. Please clear previous dues.';
                return response;
            }
            
            if (totalOrderValue > 1500000) {
                response.message = 'Total order value cannot exceed ₹15,00,000';
                return response;
            }
            
            // ---------------- INSERT LINE ITEMS ----------------
            for (Order_Line_Item__c li : orderLineItems) {
                li.Ori_Plast_Order__c = order.Id;
            }
            insert orderLineItems;
            
            // ---------------- RESPONSE ----------------
            response.CreatedorderId = order.Id;
            response.orderName = order.Name;
            response.message = '';
            
        } catch (Exception ex) {
            System.debug('❌ Add order items failed: ' + ex.getMessage());
            throw new AuraHandledException('Failed to add items: ' + ex.getMessage());
        }
        
        return response;
    }
    
    
    @AuraEnabled
    public static String sendCreatedOrderIdToLWC(String createdOrdertId) {
        String OrderId = '';
        if(string.isBlank(createdOrdertId)){
            OrderId = '';
        }else{
            OrderId = createdOrdertId;
        }
        return OrderId;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getIdentifiersForFilter(String categoryValue, String subCategoryValue) {
        
        // Safety check
        if (String.isBlank(categoryValue)) {
            return new List<String>();
        }
        
        // Base query
        String soql =
            'SELECT Identifire_Picklist__c, GST_Value__c,Item_Disc_Group__c ' +
            'FROM OriPlast_Product__c ' +
            'WHERE (Inactive_Product__c = false OR Inactive_Product__c = NULL) ' +
            'AND Identifire_Picklist__c != NULL ' +
            'AND Category_Picklist__c = :categoryValue';
        
        // Optional sub-category filter
        if (!String.isBlank(subCategoryValue)) {
            soql += ' AND Sub_Category_Picklist__c = :subCategoryValue';
        }
        
        // Execute query
        List<OriPlast_Product__c> products = Database.query(soql);
        
        // Collect UNIQUE identifiers
        Set<String> identifierSet = new Set<String>();
        for (OriPlast_Product__c p : products) {
            identifierSet.add(p.Identifire_Picklist__c);
        }
        
        // Return as List
        return new List<String>(identifierSet);
    }
    
    /*@AuraEnabled(cacheable=true)
    public static List<Ori_Plast_Order__c> getPartiallyDeliveredOrders(Id accountId) {
        if (accountId == null) {
            return new List<Ori_Plast_Order__c>();
        }
        
        return [
        SELECT Id, Name, Final_Order_Value__c, Order_Status__c, CreatedDate, Remaining_Total_Order_Item_Value__c
        FROM Ori_Plast_Order__c
        WHERE Account__c = :accountId
        AND Order_Status__c = 'Partially Delivered , Submitted , Received by Navision'
        ORDER BY CreatedDate DESC
    ];
    }*/
    
    @AuraEnabled(cacheable=true)
    public static List<Ori_Plast_Order__c> getPartiallyDeliveredOrders(Id accountId) {
        if (accountId == null) {
            return new List<Ori_Plast_Order__c>();
        }
        
        return [
        SELECT Id, Name, Final_Order_Value__c, Order_Status__c, CreatedDate, Remaining_Total_Order_Item_Value__c
        FROM Ori_Plast_Order__c
        WHERE Account__c = :accountId
        AND Order_Status__c IN ('Partially Delivered', 'Submitted', 'Received by Navision')
        ORDER BY CreatedDate DESC
    ];
    }
    
    @AuraEnabled
    public static List<OriPlast_Discount_Mapping__c> getDiscountPercentage(String discountGroupCode) {
        if(String.isBlank(discountGroupCode)) {
            return new List<OriPlast_Discount_Mapping__c>();
        }
        
        return [
        SELECT Id, Name, Special_Discount__c,ItemDiscountCode_ExternalKey__c , Discount__c, Cash_Discount__c
        FROM OriPlast_Discount_Mapping__c
        WHERE ItemDiscountCode_ExternalKey__c  = :discountGroupCode
        LIMIT 1
    ];
    }
    
    @AuraEnabled
    public static Ori_Plast_Order__c getOrderWithAccount(Id orderId) {
        return [
        SELECT Id, Account__c, Account__r.Customer_Disc_Group__c
        FROM Ori_Plast_Order__c
        WHERE Id = :orderId
    ];
    }
    
    @AuraEnabled
    public static void addLinesToExistingOrder(Id orderId,List<Order_Line_Item__c> lines) {
        for (Order_Line_Item__c li : lines) {
            li.Ori_Plast_Order__c = orderId;
        }
        insert lines;
    }
    
    
    @AuraEnabled
    public static List<OriPlast_Product__c> getProductsforAdd(Id accountId,String CategoryValue,String identifierValue,String subCategoryValue) {
        String soql =
            'SELECT Id, Name, Identifire_Picklist__c, Size__c, ' +
            'Category_Picklist__c, Sub_Category_Picklist__c, ' +'OriPlast_Product_Unique_Key__c, ' +
            'Base_Unit_of_Measure__c, GST_Value__c , Item_Disc_Group__c ' +
            'FROM OriPlast_Product__c ' +
            'WHERE (Inactive_Product__c = false OR Inactive_Product__c = NULL)';
        
        // if (accountId != null) {
            //     soql +=
            //         ' AND Id IN (SELECT Ori_Plast_Product__c FROM Inventory__c WHERE Account__c = :accountId)';
        // }
        
        if (!String.isBlank(CategoryValue)) {
            soql += ' AND Category_Picklist__c = :CategoryValue';
        }
        if (!String.isBlank(identifierValue)) {
            soql += ' AND Identifire_Picklist__c = :identifierValue';
        }
        if (!String.isBlank(subCategoryValue)) {
            soql += ' AND Sub_Category_Picklist__c = :subCategoryValue';
        }
        
        return Database.query(soql);
    }
    
    
    @AuraEnabled
    public static List<Account> getDiscountMapping(
        String accountId
    ) {
        return [
        SELECT Id, Name, Customer_Disc_Group__c FROM Account WHERE Id = :accountId
        ];
    }
    
    @AuraEnabled
    public static List<OriPlast_Product__c> getProductData(
        String productId
    ) {
        return [
        SELECT Id, Name, Base_Unit_of_Measure__c, Size__c, Length__c, Length_In_Meter__c, Item_Disc_Group__c, Category_Picklist__c,GST_Value__c
        FROM OriPlast_Product__c
        WHERE Id = :productId
    ];
    }
    
    @AuraEnabled
    public static void addOrderLineItems(
        Id accountId,
    String productsJson
    ) {
        if (accountId == null || String.isBlank(productsJson)) {
            throw new AuraHandledException('Invalid input');
        }
        
        // 1️⃣ Get existing Order for Account
        Ori_Plast_Order__c orderRec = [
            SELECT Id
            FROM Ori_Plast_Order__c
            WHERE Account__c = :accountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (orderRec == null) {
            throw new AuraHandledException('No Order found for this Account');
        }
        
        // 2️⃣ Parse products JSON
        List<Object> productList =
            (List<Object>) JSON.deserializeUntyped(productsJson);
        
        if (productList.isEmpty()) return;
        
        // 3️⃣ Fetch existing Order-Line-Items
        Map<Id, Order_Line_Item__c> existingItemsMap = new Map<Id, Order_Line_Item__c>();
        
        for (Order_Line_Item__c oli : [
            SELECT Id, Ori_Plast_Product__c, Quantity__c,Unit_of_Measure__c
            FROM Order_Line_Item__c
            WHERE Ori_Plast_Order__c = :orderRec.Id
        ]) {
            existingItemsMap.put(oli.Ori_Plast_Product__c, oli);
        }
        
        List<Order_Line_Item__c> itemsToInsert = new List<Order_Line_Item__c>();
        List<Order_Line_Item__c> itemsToUpdate = new List<Order_Line_Item__c>();
        
        // 4️⃣ Insert / Update logic
        for (Object obj : productList) {
            Map<String, Object> prod = (Map<String, Object>) obj;
            
            Id productId;
            if (prod.containsKey('productId')) {
                productId = (Id) prod.get('productId');
            } else if (prod.containsKey('id')) {
                productId = (Id) prod.get('id');
            }
            
            if (productId == null) {
                continue;
            }
            
            Decimal quantity =
                Decimal.valueOf(String.valueOf(prod.get('quantity')));
            
            Decimal totalPrice =
                Decimal.valueOf(String.valueOf(prod.get('totalPrice')));
            
            if (existingItemsMap.containsKey(productId)) {
                Order_Line_Item__c oli = existingItemsMap.get(productId);
                oli.Quantity__c += quantity;
                itemsToUpdate.add(oli);
            } else {
                itemsToInsert.add(new Order_Line_Item__c(
                    Ori_Plast_Order__c = orderRec.Id,
                Ori_Plast_Product__c = productId,
                Quantity__c = quantity,
                Unit_of_Measure__c = (String) prod.get('unitOfMeasure'),
                Price_After_Discount__c = totalPrice
                    ));
            }
        }
        
        
        if (!itemsToInsert.isEmpty()) insert itemsToInsert;
        if (!itemsToUpdate.isEmpty()) update itemsToUpdate;
    }
    
    
    
    // *********************************************
    
    
    // 1️⃣ Get Categories
    @AuraEnabled(cacheable=true)
    public static List<String> getCategories() {
        List<String> result = new List<String>();
        
        for (AggregateResult ar : [
        SELECT Category_Picklist__c c
        FROM OriPlast_Product__c
        WHERE Category_Picklist__c != NULL
        GROUP BY Category_Picklist__c
        ORDER BY Category_Picklist__c
    ]) {
            result.add((String) ar.get('c'));
        }
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCategoryPicklistLabels() {
        Map<String, String> valueToLabel = new Map<String, String>();
        
        Schema.DescribeFieldResult d =
            OriPlast_Product__c.Category_Picklist__c.getDescribe();
        
        for (Schema.PicklistEntry p : d.getPicklistValues()) {
            valueToLabel.put(p.getValue(), p.getLabel());
        }
        return valueToLabel;
    }
    
    
    
    // 2️⃣ Get Sub Categories (by Category)
    @AuraEnabled(cacheable=true)
    public static List<String> getSubCategories(String categoryValue) {
        List<String> result = new List<String>();
        
        for (AggregateResult ar : [
        SELECT Sub_Category_Picklist__c sc
        FROM OriPlast_Product__c
        WHERE Category_Picklist__c = :categoryValue
        AND Sub_Category_Picklist__c != NULL
        GROUP BY Sub_Category_Picklist__c
        ORDER BY Sub_Category_Picklist__c
    ]) {
            result.add((String) ar.get('sc'));
        }
        return result;
    }
    
    
    // 3️⃣ Get Identifiers (by Category + Sub Category)
    @AuraEnabled(cacheable=true)
    public static List<String> getIdentifiers(
        String categoryValue,
    String subCategoryValue
    ) {
        List<String> result = new List<String>();
        
        for (AggregateResult ar : [
        SELECT Identifire_Picklist__c idf
        FROM OriPlast_Product__c
        WHERE Category_Picklist__c = :categoryValue
        AND Sub_Category_Picklist__c = :subCategoryValue
        AND Identifire_Picklist__c != NULL
        GROUP BY Identifire_Picklist__c
        ORDER BY Identifire_Picklist__c
    ]) {
            result.add((String) ar.get('idf'));
        }
        return result;
    }
    
}