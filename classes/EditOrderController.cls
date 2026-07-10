public with sharing class EditOrderController {
    
    /* ================= FETCH ORDER LINES ================= */
    @AuraEnabled(cacheable=true)
    public static List<OrderLineDTO> getOrderLineItems(Id orderId) {
        List<OrderLineDTO> rows = new List<OrderLineDTO>();
        
        for (Order_Line_Item__c li : [
            SELECT Id,Name,Quantity__c,Final_Price__c,
            Price_After_Discount__c,
            OriPlast_Product_Unit_Price__c,
            CGST__c,
            SGST__c,Trade_Discount_TD__c,Cash_Discount_CD__c,
            Ori_Plast_Product_Name__c,
            Ori_Plast_Product__r.GST_Value__c,
            Ori_Plast_Product__r.Item_Disc_Group__c,
            Ori_Plast_Product__r.Base_Unit_of_Measure__c,
            Ori_Plast_Product__r.Length_In_Meter__c,
            Ori_Plast_Product__r.Id,
            Unit_of_Measure__c
            FROM Order_Line_Item__c WHERE Ori_Plast_Order__c = :orderId
            ]) {
            rows.add(new OrderLineDTO(li));
        }
        return rows;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Ori_Plast_Order__c> getOriPlastOrder(Id orderId) {
        return [
        SELECT Id, Name, Account__r.Name, Account__c FROM Ori_Plast_Order__c WHERE Id = :orderId LIMIT 1    
        ];
    }
    
    
    /* ================= DELETE ================= */
    
    @AuraEnabled
    public static String deleteOrderLineItems(List<Id> lineItemIds, Id orderId) {
        if (lineItemIds == null || lineItemIds.isEmpty()) {
            throw new AuraHandledException('No Order Line Items selected');
        }
        
        delete [SELECT Id FROM Order_Line_Item__c WHERE Id IN :lineItemIds];
        return 'SUCCESS';
    }
    
    public class OrderLineDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal finalPrice;
        @AuraEnabled public Decimal priceAfterDiscount;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Decimal cgst;
        @AuraEnabled public Decimal sgst;
        @AuraEnabled public Decimal tradeDiscount;
        @AuraEnabled public Decimal cashDiscount;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal gstValue;
        @AuraEnabled public String itemDiscGroup;
        @AuraEnabled public String uom;
        @AuraEnabled public String lengthInMeter;
        @AuraEnabled public String unitOfMeasure;
        @AuraEnabled public Id productId;
        @AuraEnabled public String Unit_of_Measure;

        
        public OrderLineDTO(Order_Line_Item__c oli) {
            this.id = oli.Id;
            this.quantity = oli.Quantity__c;
            this.finalPrice = oli.Final_Price__c;
            this.productId = oli.Ori_Plast_Product__r.Id;
            this.priceAfterDiscount = oli.Price_After_Discount__c;
            this.unitPrice = oli.OriPlast_Product_Unit_Price__c;
            this.cgst = oli.CGST__c;
            this.sgst = oli.SGST__c;
            this.tradeDiscount = oli.Trade_Discount_TD__c;
            this.cashDiscount = oli.Cash_Discount_CD__c;
            this.productName = oli.Ori_Plast_Product_Name__c;
            this.gstValue = oli.Ori_Plast_Product__r.GST_Value__c;
            this.itemDiscGroup = oli.Ori_Plast_Product__r.Item_Disc_Group__c;
            this.uom = oli.Ori_Plast_Product__r.Base_Unit_of_Measure__c;
            this.lengthInMeter = oli.Ori_Plast_Product__r.Length_In_Meter__c;
            this.Unit_of_Measure = oli.Unit_of_Measure__c;
            // this.unitOfMeasure = oli.Ori_Plast_Product__r.Base_Unit_of_Measure__c;
            
        }
    }
    
    @AuraEnabled
    public static String updateOrderLineItems(List<Order_Line_Item__c> lines) {
        if (lines == null || lines.isEmpty()) {
            throw new AuraHandledException('No lines to update');
        }
        
        update lines;
        return 'SUCCESS';
    }
    
    
    public class OrderLineUpdate {
        @AuraEnabled public Id id;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal finalPrice;
        @AuraEnabled public Decimal priceAfterDiscount;
        @AuraEnabled public Decimal cgst;
        @AuraEnabled public Decimal sgst;
        @AuraEnabled public Decimal tradeDiscount;
        @AuraEnabled public Decimal cashDiscount;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<OriPlast_Product__c> getProducts(
        Id accountId,
    String CategoryValue,
    String subCategoryValue,
    String identifierValue
    ) {
        String soql =
            'SELECT Id, Name, Category_Picklist__c, Sub_Category_Picklist__c, ' +
            'Identifire_Picklist__c, Size__c, Base_Unit_of_Measure__c ' +
            'FROM OriPlast_Product__c ' +
            'WHERE (Inactive_Product__c = false OR Inactive_Product__c = NULL)';
        
        // 🔐 Account → Inventory → Product
        if (accountId != null) {
            soql +=
                ' AND Id IN ( ' +
                ' SELECT Ori_Plast_Product__c FROM Inventory__c ' +
                ' WHERE Account__c = :accountId' +
                ')';
        }
        
        if (!String.isBlank(CategoryValue)) {
            soql += ' AND Category_Picklist__c = :CategoryValue';
        }
        
        if (!String.isBlank(subCategoryValue)) {
            soql += ' AND Sub_Category_Picklist__c = :subCategoryValue';
        }
        
        if (!String.isBlank(identifierValue)) {
            soql += ' AND Identifire_Picklist__c = :identifierValue';
        }
        
        return Database.query(soql);
    }
    
    
}