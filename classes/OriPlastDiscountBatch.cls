/*
 * Pratik Mondal
 * Created on - 24-02-2026
 * ---------------------
 * This batch class processes Draft Ori-Plast Orders and calculates Trade Discount,
 * Cash Discount, GST (CGST & SGST), and Final Price for related Order Line Items.
 * It dynamically derives discount mappings using Customer & Item Discount Groups
 */

global class OriPlastDiscountBatch implements Database.Batchable<SObject> {

  
    // START METHOD
   
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, Account__c
                FROM Ori_Plast_Order__c
                WHERE Order_Status__c = 'Draft'
            ]
        );
    }

   
    // EXECUTE METHOD
    
    global void execute(Database.BatchableContext bc, List<Ori_Plast_Order__c> scopeOrders) {

        if(scopeOrders.isEmpty()) return;

        Set<Id> orderIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Ori_Plast_Order__c> orderMap = new Map<Id, Ori_Plast_Order__c>();

        for(Ori_Plast_Order__c ord : scopeOrders){
            orderIds.add(ord.Id);
            accountIds.add(ord.Account__c);
            orderMap.put(ord.Id, ord);
        }

       
       //  Fetch Accounts
     
        Map<Id, Account> accMap = new Map<Id, Account>(
            [
                SELECT Id, Customer_Disc_Group__c
                FROM Account
                WHERE Id IN :accountIds
            ]
        );

       
      //   Fetch Order Line Items
       
        List<Order_Line_Item__c> lineItems = [
            SELECT Id,
                   Ori_Plast_Order__c,
                   Ori_Plast_Product__c,
                   Quantity__c,
                   Total_Price__c,
                   Cash_Discount_CD__c,
                   Unit_of_Measure__c,
                   OriPlast_Product_Unit_Price__c
            FROM Order_Line_Item__c
            WHERE Ori_Plast_Order__c IN :orderIds
        ];

        if(lineItems.isEmpty()) return;

      
        // Collect Product Ids
     
        Set<Id> productIds = new Set<Id>();
        for(Order_Line_Item__c oli : lineItems){
            if(oli.Ori_Plast_Product__c != null){
                productIds.add(oli.Ori_Plast_Product__c);
            }
        }

      
       //  Fetch Products 
     
        Map<Id, OriPlast_Product__c> productMap = new Map<Id, OriPlast_Product__c>(
            [
                SELECT Id,
                       Item_Disc_Group__c,
                       Length_In_Meter__c,
                       GST_Value__c
                FROM OriPlast_Product__c
                WHERE Id IN :productIds
            ]
        );


       //  Prepare Discount Keys
      
        Set<String> discountKeys = new Set<String>();

        for(Order_Line_Item__c oli : lineItems){

            Ori_Plast_Order__c ord = orderMap.get(oli.Ori_Plast_Order__c);
            Account acc = accMap.get(ord.Account__c);
            OriPlast_Product__c prod = productMap.get(oli.Ori_Plast_Product__c);

            if(acc == null || prod == null) continue;

            if(String.isBlank(acc.Customer_Disc_Group__c) ||
               String.isBlank(prod.Item_Disc_Group__c)) continue;

            String key = acc.Customer_Disc_Group__c + '_' + prod.Item_Disc_Group__c;
            discountKeys.add(key);
        }

        
         //Fetch Discount Mapping
        
        Map<String, OriPlast_Discount_Mapping__c> discountMap =
            new Map<String, OriPlast_Discount_Mapping__c>();

        for(OriPlast_Discount_Mapping__c dm : [
            SELECT ItemDiscountCode_ExternalKey__c,
                   Discount__c,
                   Special_Discount__c,
                   Line_Discount__c,
                   Cash_Discount__c
            FROM OriPlast_Discount_Mapping__c
            WHERE ItemDiscountCode_ExternalKey__c IN :discountKeys
        ]){
            discountMap.put(dm.ItemDiscountCode_ExternalKey__c, dm);
        }

        
          //calculation logic
      
        List<Order_Line_Item__c> updateList = new List<Order_Line_Item__c>();

        for(Order_Line_Item__c oli : lineItems){

            Ori_Plast_Order__c ord = orderMap.get(oli.Ori_Plast_Order__c);
            Account acc = accMap.get(ord.Account__c);
            OriPlast_Product__c prod = productMap.get(oli.Ori_Plast_Product__c);

            if(acc == null || prod == null) continue;
            if(String.isBlank(acc.Customer_Disc_Group__c) ||
               String.isBlank(prod.Item_Disc_Group__c)) continue;

            String key = acc.Customer_Disc_Group__c + '_' + prod.Item_Disc_Group__c;
            if(!discountMap.containsKey(key)) continue;

            OriPlast_Discount_Mapping__c disc = discountMap.get(key);

            Decimal quantity = oli.Quantity__c == null ? 0 : oli.Quantity__c;
            Decimal unitPrice = oli.OriPlast_Product_Unit_Price__c == null ? 0 : oli.OriPlast_Product_Unit_Price__c;

            // Base Price Calculation 
            Decimal basePrice;

            if(oli.Unit_of_Measure__c == 'MTR'){
                Decimal length = 1;
                if(!String.isBlank(prod.Length_In_Meter__c)){
                    try{
                        length = Decimal.valueOf(prod.Length_In_Meter__c);
                    }catch(Exception e){
                        length = 1;
                    }
                }
                basePrice = unitPrice * quantity * length;
            } else {
                basePrice = unitPrice * quantity;
            }

            // Trade Discount 
            Decimal tradePercent =
                (disc.Discount__c == null ? 0 : disc.Discount__c) +
                (disc.Special_Discount__c == null ? 0 : disc.Special_Discount__c);

            Decimal tradeAmount = basePrice * tradePercent / 100;
            Decimal tradeAfter = basePrice - tradeAmount;

            Decimal tradeDiscountAmount = disc.Discount__c * oli.Total_Price__c / 100;

            // Cash Discount 
            Decimal cashPercent = disc.Cash_Discount__c == null ? 0 : disc.Cash_Discount__c;
            Decimal cashAmount = tradeAfter * cashPercent / 100;

            Decimal priceAfterDiscount = tradeAfter - cashAmount;

            
              // GST CALCULATION
             
            Decimal gstPercent = prod.GST_Value__c == null ? 0 : prod.GST_Value__c;
            Decimal gstAmount = priceAfterDiscount * gstPercent / 100;
           
            Decimal cgst = gstAmount / 2;
            Decimal sgst = gstAmount / 2;
            

            Decimal finalPriceWithGST = priceAfterDiscount + gstAmount;

            //Update fields
            oli.Trade_Discount__c = disc.Discount__c;
            oli.Cash_Discount_Percentage__c = disc.Cash_Discount__c;
            oli.Trade_Discount_TD_After_Shipment__c = tradeAfter;
            oli.Price_After_Discount__c = priceAfterDiscount;
            oli.Cash_Discount_CD__c = cashAmount;
            oli.Trade_Discount_TD__c = tradeDiscountAmount;

            // GST Fields 
            oli.CGST__c = cgst;
            oli.SGST__c = sgst;
            oli.Final_Price__c = finalPriceWithGST;
           

            updateList.add(oli);
        }

        if(!updateList.isEmpty()){
            update updateList;
        }
    }

    
      // Finish method
 
    global void finish(Database.BatchableContext bc){
        System.debug('OriPlast Discount + GST Batch Completed Successfully');
    }
}