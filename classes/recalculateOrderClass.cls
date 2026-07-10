// public with sharing class recalculateOrderClass {
    
    //     @AuraEnabled
    //     public static void recalculateOrder(Id orderId, Id accountId) {
        
        //         // 🔹 Fetch Line Items
        //         List<Order_Line_Item__c> lines = [
        //             SELECT Id, Ori_Plast_Product__c, Quantity__c,
        //                    Unit_of_Measure__c,
        //                    Trade_Discount__c, Cash_Discount_Percentage__c
        //             FROM Order_Line_Item__c
        //             WHERE Ori_Plast_Order__c = :orderId
        //         ];
        
        //         if(lines.isEmpty()) return;
        
        //         // 🔹 Fetch Account
        //         Account acc = [
        //             SELECT Id, Customer_Disc_Group__c
        //             FROM Account
        //             WHERE Id = :accountId
        //             LIMIT 1
        //         ];
        
        //         // 🔹 Collect Product Ids
        //         Set<Id> productIds = new Set<Id>();
        //         for(Order_Line_Item__c li : lines){
            //             if(li.Ori_Plast_Product__c != null){
                //                 productIds.add(li.Ori_Plast_Product__c);
            //             }
        //         }
        
        //         // 🔹 Maps
        //         Map<Id, Decimal> productPriceMap = new Map<Id, Decimal>();
        //         Map<Id, Decimal> productGSTMap = new Map<Id, Decimal>();
        //         Map<Id, Id> productPriceIdMap = new Map<Id, Id>();
        //         Map<Id, String> productDiscGroupMap = new Map<Id, String>();
        
        //         // 🔹 Fetch Product Data
        //         for(OriPlast_Product__c prod : [
        //             SELECT Id, GST_Value__c, Item_Disc_Group__c,
        //                    (SELECT Id, Unit_Price__c FROM Product_Prices__r LIMIT 1)
        //             FROM OriPlast_Product__c
        //             WHERE Id IN :productIds
        //         ]){
            
            //             if(prod.Product_Prices__r != null && !prod.Product_Prices__r.isEmpty()){
                //                 Product_Price__c priceRec = prod.Product_Prices__r[0];
                
                //                 productPriceMap.put(prod.Id, priceRec.Unit_Price__c);
                //                 productPriceIdMap.put(prod.Id, priceRec.Id);
            //             }
            
            //             productGSTMap.put(prod.Id, prod.GST_Value__c);
            //             productDiscGroupMap.put(prod.Id, prod.Item_Disc_Group__c);
        //         }
        
        //         // 🔹 Fetch Discount Mapping (IMPORTANT FIX)
        //         Map<String, OriPlast_Discount_Mapping__c> discountMap = new Map<String, OriPlast_Discount_Mapping__c>();
        
        //         for(OriPlast_Discount_Mapping__c d : [
        //             SELECT ItemDiscountCode_ExternalKey__c,
        //                    Discount__c,
        //                    Special_Discount__c,
        //                    Cash_Discount__c
        //             FROM OriPlast_Discount_Mapping__c
        //         ]){
            //             discountMap.put(d.ItemDiscountCode_ExternalKey__c, d);
        //         }
        
        //         Decimal totalOrderValue = 0;
        
        //         // 🔹 Main Loop
        //         for (Order_Line_Item__c li : lines) {
            
            //             Decimal unitPrice = productPriceMap.get(li.Ori_Plast_Product__c);
            //             Decimal gstPercent = productGSTMap.get(li.Ori_Plast_Product__c);
            
            //             if(unitPrice == null) unitPrice = 0;
            //             if(gstPercent == null) gstPercent = 0;
            
            //             Decimal qty = li.Quantity__c == null ? 0 : li.Quantity__c;
            
            //             // 🔹 BASE PRICE
            //             Decimal base = qty * unitPrice;
            
            //             // 🔥 SAFE KEY BUILD
            //             String custGroup = acc.Customer_Disc_Group__c == null ? '' : acc.Customer_Disc_Group__c;
            //             String itemGroup = productDiscGroupMap.get(li.Ori_Plast_Product__c) == null
            //                                ? ''
            //                                : productDiscGroupMap.get(li.Ori_Plast_Product__c);
            
            //             String discountKey = custGroup + '_' + itemGroup;
            
            //             System.debug('Discount Key 👉 ' + discountKey);
            
            //             Decimal tradePercent = 0;
            //             Decimal cashPercent = 0;
            
            //             // 🔥 APPLY DISCOUNT
            //             if(discountMap.containsKey(discountKey)){
                //                 OriPlast_Discount_Mapping__c d = discountMap.get(discountKey);
                
                //                 Decimal tradeDisc = d.Discount__c == null ? 0 : d.Discount__c;
                //                 Decimal specialDisc = d.Special_Discount__c == null ? 0 : d.Special_Discount__c;
                
                //                 tradePercent = tradeDisc + specialDisc;   // ✅ FIXED
                //                 cashPercent = d.Cash_Discount__c == null ? 0 : d.Cash_Discount__c;
            //             }
            //             else{
                //                 System.debug('⚠️ No discount mapping found for key: ' + discountKey);
            //             }
            
            //             // 🔹 SAVE %
            //             li.Trade_Discount__c = tradePercent;
            //             li.Cash_Discount_Percentage__c = cashPercent;
            
            //             // 🔹 TRADE DISCOUNT
            //             Decimal tradeAmount = (base * tradePercent) / 100;
            //             tradeAmount = tradeAmount.setScale(2);   // ✅ ROUNDING FIX
            //             li.Trade_Discount_TD__c = tradeAmount;
            
            //             Decimal afterTrade = base - tradeAmount;
            
            //             // 🔹 CASH DISCOUNT
            //             Decimal cashAmount = (afterTrade * cashPercent) / 100;
            //             cashAmount = cashAmount.setScale(2);     // ✅ ROUNDING FIX
            //             li.Cash_Discount_CD__c = cashAmount;
            
            //             Decimal afterCash = afterTrade - cashAmount;
            
            //             // 🔹 GST
            //             Decimal gst = (afterCash * gstPercent) / 100;
            //             gst = gst.setScale(2);
            
            //             // 🔹 FINAL VALUES
            //             li.Price_After_Discount__c = afterCash.setScale(2);
            //             li.Final_Price__c = (afterCash + gst).setScale(2);
            //             li.CGST__c = (gst / 2).setScale(2);
            //             li.SGST__c = (gst / 2).setScale(2);
            
            //             // 🔹 SET PRODUCT PRICE LOOKUP
            //             li.OriPlast_Product_Price__c = productPriceIdMap.get(li.Ori_Plast_Product__c);
            
            //             totalOrderValue += li.Final_Price__c;
        //         }
        
        //         // 🔹 SAVE
        //         update lines;
        
        //         // 🔹 OPTIONAL ORDER UPDATE
        //         /*
        //         update new Ori_Plast_Order__c(
        //             Id = orderId,
        //             Final_Order_Value__c = totalOrderValue
        //         );
        //         */
    //     }
// }

// public with sharing class recalculateOrderClass {
    
    //     @AuraEnabled
    //     public static void recalculateOrder(Id orderId, Id accountId) {
        
        //         // 🔹 Fetch Line Items
        //         List<Order_Line_Item__c> lines = [
        //             SELECT Id, Ori_Plast_Product__c, Quantity__c,
        //                    Unit_of_Measure__c,
        //                    Trade_Discount__c, Cash_Discount_Percentage__c
        //             FROM Order_Line_Item__c
        //             WHERE Ori_Plast_Order__c = :orderId
        //         ];
        
        //         if(lines.isEmpty()) return;
        
        //         // 🔹 Fetch Account (Customer Discount Group)
        //         Account acc = [
        //             SELECT Id, Customer_Disc_Group__c
        //             FROM Account
        //             WHERE Id = :accountId
        //             LIMIT 1
        //         ];
        
        //         // 🔹 Collect Product Ids
        //         Set<Id> productIds = new Set<Id>();
        //         for(Order_Line_Item__c li : lines){
            //             if(li.Ori_Plast_Product__c != null){
                //                 productIds.add(li.Ori_Plast_Product__c);
            //             }
        //         }
        
        //         // 🔹 Maps
        //         Map<Id, Decimal> productPriceMap = new Map<Id, Decimal>();
        //         Map<Id, Decimal> productGSTMap = new Map<Id, Decimal>();
        //         Map<Id, Id> productPriceIdMap = new Map<Id, Id>();
        //         Map<Id, String> productDiscGroupMap = new Map<Id, String>();
        
        //         // 🔹 Fetch Product + Price + Discount Group
        //         for(OriPlast_Product__c prod : [
        //             SELECT Id, GST_Value__c, Item_Disc_Group__c,
        //                    (SELECT Id, Unit_Price__c FROM Product_Prices__r LIMIT 1)
        //             FROM OriPlast_Product__c
        //             WHERE Id IN :productIds
        //         ]){
            
            //             if(prod.Product_Prices__r != null && !prod.Product_Prices__r.isEmpty()){
                //                 Product_Price__c priceRec = prod.Product_Prices__r[0];
                
                //                 productPriceMap.put(prod.Id, priceRec.Unit_Price__c);
                //                 productPriceIdMap.put(prod.Id, priceRec.Id);
            //             }
            
            //             productGSTMap.put(prod.Id, prod.GST_Value__c);
            //             productDiscGroupMap.put(prod.Id, prod.Item_Disc_Group__c);
        //         }
        
        //         // 🔹 Fetch Discount Mapping
        //         Map<String, OriPlast_Discount_Mapping__c> discountMap = new Map<String, OriPlast_Discount_Mapping__c>();
        
        //         for(OriPlast_Discount_Mapping__c d : [
        //             SELECT ItemDiscountCode_ExternalKey__c, Discount__c, Cash_Discount__c
        //             FROM OriPlast_Discount_Mapping__c
        //         ]){
            //             discountMap.put(d.ItemDiscountCode_ExternalKey__c, d);
        //         }
        
        //         Decimal totalOrderValue = 0;
        
        //         // 🔹 Calculation Loop
        //         for (Order_Line_Item__c li : lines) {
            
            //             Decimal unitPrice = productPriceMap.get(li.Ori_Plast_Product__c);
            //             Decimal gstPercent = productGSTMap.get(li.Ori_Plast_Product__c);
            
            //             if(unitPrice == null) unitPrice = 0;
            //             if(gstPercent == null) gstPercent = 0;
            
            //             Decimal qty = li.Quantity__c == null ? 0 : li.Quantity__c;
            
            //             // 🔹 BASE PRICE
            //             Decimal base = qty * unitPrice;
            
            //             // 🔥 CORRECT DISCOUNT KEY (MAIN FIX)
            //             String custGroup = acc.Customer_Disc_Group__c;
            //             String itemGroup = productDiscGroupMap.get(li.Ori_Plast_Product__c);
            
            //             String discountKey = custGroup + '_' + itemGroup;
            
            //             Decimal tradePercent = 0;
            //             Decimal cashPercent = 0;
            
            //             if(discountMap.containsKey(discountKey)){
                //                 OriPlast_Discount_Mapping__c d = discountMap.get(discountKey);
                
                //                 tradePercent = d.Discount__c == null ? 0 : d.Discount__c;
                //                 cashPercent = d.Cash_Discount__c == null ? 0 : d.Cash_Discount__c;
            //             }
            
            //             // 🔹 Save % on line
            //             li.Trade_Discount__c = tradePercent;
            //             li.Cash_Discount_Percentage__c = cashPercent;
            
            //             // 🔹 TRADE DISCOUNT
            //             Decimal tradeAmount = (base * tradePercent) / 100;
            //             li.Trade_Discount_TD__c = tradeAmount;
            
            //             Decimal afterTrade = base - tradeAmount;
            
            //             // 🔹 CASH DISCOUNT
            //             Decimal cashAmount = (afterTrade * cashPercent) / 100;
            //             li.Cash_Discount_CD__c = cashAmount;
            
            //             Decimal afterCash = afterTrade - cashAmount;
            
            //             // 🔹 GST
            //             Decimal gst = (afterCash * gstPercent) / 100;
            
            //             // 🔹 FINAL VALUES
            //             li.Price_After_Discount__c = afterCash;
            //             li.Final_Price__c = afterCash + gst;
            //             li.CGST__c = gst / 2;
            //             li.SGST__c = gst / 2;
            
            //             // 🔹 SET PRODUCT PRICE LOOKUP
            //             li.OriPlast_Product_Price__c = productPriceIdMap.get(li.Ori_Plast_Product__c);
            
            //             totalOrderValue += li.Final_Price__c;
        //         }
        
        //         // 🔹 Save Line Items
        //         update lines;
        
        //         // 🔹 Optional Order Update
        //         /*
        //         update new Ori_Plast_Order__c(
        //             Id = orderId,
        //             Final_Order_Value__c = totalOrderValue
        //         );
        //         */
    //     }
// }


public with sharing class recalculateOrderClass {
    
    @AuraEnabled
    public static void recalculateOrder(Id orderId, Id accountId) {
        
        // 🔹 Fetch Line Items
        List<Order_Line_Item__c> lines = [
            SELECT Id, Ori_Plast_Product__c, Quantity__c,
                   Unit_of_Measure__c,
                   Trade_Discount__c, Cash_Discount_Percentage__c
            FROM Order_Line_Item__c
            WHERE Ori_Plast_Order__c = :orderId
        ];
        
        if(lines.isEmpty()) return;
        
        // 🔹 Fetch Account
        Account acc = [
            SELECT Id, Customer_Disc_Group__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        
        // 🔹 Collect Product Ids
        Set<Id> productIds = new Set<Id>();
        for(Order_Line_Item__c li : lines){
            if(li.Ori_Plast_Product__c != null){
                productIds.add(li.Ori_Plast_Product__c);
            }
        }
        
        // 🔹 MAPS
        Map<Id, Decimal> productPriceMap = new Map<Id, Decimal>();
        Map<Id, Decimal> productGSTMap = new Map<Id, Decimal>();
        Map<Id, Id> productPriceIdMap = new Map<Id, Id>();
        Map<Id, String> productDiscGroupMap = new Map<Id, String>();
        Map<Id, Decimal> productLengthMap = new Map<Id, Decimal>(); // ✅ FIX
        
        // 🔹 FETCH PRODUCT DATA
        for(OriPlast_Product__c prod : [
            SELECT Id, GST_Value__c, Item_Disc_Group__c, Length_In_Meter__c,
                   (SELECT Id, Unit_Price__c FROM Product_Prices__r LIMIT 1)
            FROM OriPlast_Product__c
            WHERE Id IN :productIds
        ]){
            
            // ✅ CORRECT LENGTH STORE
            String length = prod.Length_In_Meter__c == null ? '0.0' : prod.Length_In_Meter__c;
            productLengthMap.put(prod.Id, Decimal.valueOf(length));
            
            if(prod.Product_Prices__r != null && !prod.Product_Prices__r.isEmpty()){
                Product_Price__c priceRec = prod.Product_Prices__r[0];
                
                productPriceMap.put(prod.Id, priceRec.Unit_Price__c);
                productPriceIdMap.put(prod.Id, priceRec.Id);
            }
            
            productGSTMap.put(prod.Id, prod.GST_Value__c);
            productDiscGroupMap.put(prod.Id, prod.Item_Disc_Group__c);
        }
        
        // 🔹 DISCOUNT MAP
        Map<String, OriPlast_Discount_Mapping__c> discountMap = new Map<String, OriPlast_Discount_Mapping__c>();
        
        for(OriPlast_Discount_Mapping__c d : [
            SELECT ItemDiscountCode_ExternalKey__c,
                   Discount__c,
                   Special_Discount__c,
                   Cash_Discount__c
            FROM OriPlast_Discount_Mapping__c
        ]){
            discountMap.put(d.ItemDiscountCode_ExternalKey__c, d);
        }
        
        Decimal totalOrderValue = 0;
        
        // 🔹 MAIN CALCULATION LOOP
        for (Order_Line_Item__c li : lines) {
            
            Decimal unitPrice = productPriceMap.get(li.Ori_Plast_Product__c);
            Decimal gstPercent = productGSTMap.get(li.Ori_Plast_Product__c);
            
            if(unitPrice == null) unitPrice = 0;
            if(gstPercent == null) gstPercent = 0;
            
            Decimal qty = li.Quantity__c == null ? 0 : li.Quantity__c;
            
            // =========================
            // ✅ CORRECT BASE LOGIC
            // =========================
            Decimal base = 0;
            
            Decimal length = productLengthMap.containsKey(li.Ori_Plast_Product__c)
                ? productLengthMap.get(li.Ori_Plast_Product__c)
                : 0.0;
            
            String uom = li.Unit_of_Measure__c == null ? '' : li.Unit_of_Measure__c;
            
            if(uom == 'MTR' && length > 0){
                base = qty * length * unitPrice;
            } else {
                base = qty * unitPrice;
            }
            
            // =========================
            // 🔹 DISCOUNT KEY
            // =========================
            String custGroup = acc.Customer_Disc_Group__c == null ? '' : acc.Customer_Disc_Group__c;
            String itemGroup = productDiscGroupMap.get(li.Ori_Plast_Product__c) == null
                ? '' : productDiscGroupMap.get(li.Ori_Plast_Product__c);
            
            String discountKey = custGroup + '_' + itemGroup;
            
            Decimal tradePercent = 0;
            Decimal cashPercent = 0;
            
            if(discountMap.containsKey(discountKey)){
                OriPlast_Discount_Mapping__c d = discountMap.get(discountKey);
                
                // ✅ TRADE = Discount + Special Discount
                tradePercent = (d.Discount__c == null ? 0 : d.Discount__c)
                             + (d.Special_Discount__c == null ? 0 : d.Special_Discount__c);
                
                cashPercent = d.Cash_Discount__c == null ? 0 : d.Cash_Discount__c;
            }
            
            // 🔹 SAVE %
            li.Trade_Discount__c = tradePercent;
            li.Cash_Discount_Percentage__c = cashPercent;
            
            // 🔹 TRADE DISCOUNT
            Decimal tradeAmount = (base * tradePercent) / 100;
            li.Trade_Discount_TD__c = tradeAmount.setScale(2);
            
            Decimal afterTrade = base - tradeAmount;
            
            // 🔹 CASH DISCOUNT
            Decimal cashAmount = (afterTrade * cashPercent) / 100;
            li.Cash_Discount_CD__c = cashAmount.setScale(2);
            
            Decimal afterCash = afterTrade - cashAmount;
            
            // 🔹 GST
            Decimal gst = (afterCash * gstPercent) / 100;
            gst = gst.setScale(2);
            
            // 🔹 FINAL VALUES
            li.Price_After_Discount__c = afterCash.setScale(2);
            li.Final_Price__c = (afterCash + gst).setScale(2);
            li.CGST__c = (gst / 2).setScale(2);
            li.SGST__c = (gst / 2).setScale(2);
            
            // 🔹 SET PRICE LOOKUP
            li.OriPlast_Product_Price__c = productPriceIdMap.get(li.Ori_Plast_Product__c);
            
            totalOrderValue += li.Final_Price__c;
        }
        
        // 🔹 UPDATE
        update lines;
    }
}