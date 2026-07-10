@isTest
private class PrintInvoicePageControllerTest {
    @isTest
    static void testProcessInvoice() {
        // Create Account
        Account acc = new Account(Name = 'Test Account',
                                  Type= 'Distributor',
                                  Customer_Disc_Group__c = 'CDGOR',
                                  Phone = '23343434'
                                 );
        insert acc;
        
        // Create Ori_Plast_Order__c record
        Ori_Plast_Order__c order = new Ori_Plast_Order__c(
            Account__c = acc.Id
        );
        insert order;
        
        // Set the recordId parameter
        Test.setCurrentPageReference(new PageReference('/apex/PrintInvoicePageController'));
        ApexPages.currentPage().getParameters().put('id', order.Id);
        
        // Create Ori_Plast_Product__c record
        OriPlast_Product__c Oproduct= new OriPlast_Product__c(
            Name='90 mm 4kgf/sq cm UPVC Pipe Plain End 5 Mtr',
            Base_Unit_of_Measure__c = 'PCS',
            Category_Picklist__c = 'P2',
            Product_Category_Code_Picklist__c='PVC',
            Sub_Category_Picklist__c='Plain End',
            Item_Disc_Group__c='PVCPI-4985',
            OriPlast_Product_Unique_Key__c='FP201PN040GY00500090'
        );
        insert Oproduct;
        // Create Ori_Plast_Product Price record
        Product_Price__c ProPrice = new Product_Price__c(
            Items_Description__c= '90 mm 4kgf/sq cm UPVC Pipe Plain End 5 Mtr',
            Starting_Date__c = System.Today()-3,
            Unit_of_Measure_Code__c = 'MTR',
            Sales_Type__c = 'All Customers',
            Unit_Price__c = 100,
            Oriplast_Product__c = Oproduct.Id
        );
        insert ProPrice;
        // Create OriPlast_Discount_Mapping__c record
        OriPlast_Discount_Mapping__c DicMap = new OriPlast_Discount_Mapping__c(
            Name = 'PVCPI-4985',
            Cash_Discount__c = 4,
            Discount__c = 50,
            ItemDiscountCode_ExternalKey__c = 'CDGOR_PVCPI-4985'
        );
        insert DicMap;
        
        
        
        List< OriPlast_Product__c> OriProduct = [select id,Name,Item_Disc_Group__c,GST_Value__c from OriPlast_Product__c where OriPlast_Product_Unique_Key__c ='FP201PN040GY00500090' Limit 1];
        List<Product_Price__c> ProductPrice = [select Id,Unit_Price__c from Product_Price__c where Oriplast_Product__c =:OriProduct[0].Id ];
        String concatenatedValue = acc.Customer_Disc_Group__c + '_' + oriProduct[0].Item_Disc_Group__c;
        List <  OriPlast_Discount_Mapping__c> Discount = [select id,Discount__c,Cash_Discount__c from OriPlast_Discount_Mapping__c where ItemDiscountCode_ExternalKey__c =: concatenatedValue ];
        
        // Create Order_Line_Item__c records
        Decimal PriceAfterDiscount = (5*(ProductPrice[0].Unit_Price__c))-(((5*(ProductPrice[0].Unit_Price__c))*(Discount[0].Discount__c/100))+((5*(ProductPrice[0].Unit_Price__c))*(Discount[0].Cash_Discount__c/100)));
        Decimal TotalGst = PriceAfterDiscount*(OriProduct[0].GST_Value__c/100);
        Order_Line_Item__c lineItem1 = new Order_Line_Item__c(
            Ori_Plast_Order__c = order.Id,
            Quantity__c = 5,
            OriPlast_Product_Price__c=ProductPrice[0].Id,
            Ori_Plast_Product__c = OriProduct[0].Id,
            Trade_Discount_TD__c = (5*(ProductPrice[0].Unit_Price__c))*(Discount[0].Discount__c/100),
            Cash_Discount_CD__c	 = (5*(ProductPrice[0].Unit_Price__c))*(Discount[0].Cash_Discount__c/100),
            Price_After_Discount__c = PriceAfterDiscount,
            CGST__c = TotalGst/2,
            SGST__c = TotalGst/2,
            Final_Price__c = PriceAfterDiscount + TotalGst
        );
        
        // Create Ori_Plast_Product__c record
        OriPlast_Product__c Oproduct2= new OriPlast_Product__c(
            Name='90 mm 4kgf/sq cm UPVC Pipe Plain End 5 Mtr',
            Base_Unit_of_Measure__c = 'PCS',
            Category_Picklist__c = 'P2',
            Product_Category_Code_Picklist__c='PVC',
            Sub_Category_Picklist__c='Plain End',
            Item_Disc_Group__c='PVCPI-4985',
            OriPlast_Product_Unique_Key__c='FP201PN040GY00500091'
        );
        insert Oproduct2;
        
        
        // Create Ori_Plast_Product Price record
        Product_Price__c ProPrice2 = new Product_Price__c(
            Items_Description__c= '90 mm 4kgf/sq cm UPVC Pipe Plain End 5 Mtr',
            Starting_Date__c = System.Today()-3,
            Unit_of_Measure_Code__c = 'MTR',
            Sales_Type__c = 'All Customers',
            Unit_Price__c = 10000.25,
            Oriplast_Product__c = Oproduct2.Id
        );
        insert ProPrice2;
        
        List< OriPlast_Product__c> OriProduct2 = [select id,Name,Item_Disc_Group__c,GST_Value__c from OriPlast_Product__c where OriPlast_Product_Unique_Key__c ='FP201PN040GY00500091' Limit 1];
        List<Product_Price__c> ProductPrice2 = [select Id,Unit_Price__c from Product_Price__c where Oriplast_Product__c =:OriProduct2[0].Id ];
        String concatenatedValue2 = acc.Customer_Disc_Group__c + '_' + oriProduct2[0].Item_Disc_Group__c;
        List <  OriPlast_Discount_Mapping__c> Discount2 = [select id,Discount__c,Cash_Discount__c from OriPlast_Discount_Mapping__c where ItemDiscountCode_ExternalKey__c =: concatenatedValue2 ];
        
        
        Decimal PriceAfterDiscount2 = (10*(ProductPrice2[0].Unit_Price__c))-(((10*(ProductPrice2[0].Unit_Price__c))*(Discount2[0].Discount__c/100))+((10*(ProductPrice2[0].Unit_Price__c))*(Discount2[0].Cash_Discount__c/100)));
        Decimal TotalGst2 = PriceAfterDiscount*(OriProduct2[0].GST_Value__c/100);
        
        Order_Line_Item__c lineItem2 = new Order_Line_Item__c(
            Ori_Plast_Order__c = order.Id,
            Quantity__c = 10,
            OriPlast_Product_Price__c=ProductPrice2[0].Id,
            Ori_Plast_Product__c = OriProduct2[0].Id,
            Trade_Discount_TD__c = (10*(ProductPrice2[0].Unit_Price__c))*(Discount2[0].Discount__c/100),
            Cash_Discount_CD__c	 = (10*(ProductPrice2[0].Unit_Price__c))*(Discount2[0].Cash_Discount__c/100),
            Price_After_Discount__c = PriceAfterDiscount2,
            CGST__c = TotalGst2/2,
            SGST__c = TotalGst2/2,
            Final_Price__c = PriceAfterDiscount2 + TotalGst2
        );
        
        // Create Ori_Plast_Product__c record
        OriPlast_Product__c Oproduct3 = new OriPlast_Product__c(
            Name='Another Product',
            Base_Unit_of_Measure__c = 'PCS',
            Category_Picklist__c = 'P2',
            Product_Category_Code_Picklist__c='PVC',
            Sub_Category_Picklist__c='Plain End',
            Item_Disc_Group__c='PVCPI-49856',
            OriPlast_Product_Unique_Key__c='FP201PN040GY00500092'
        );
        insert Oproduct3;
        
        // Create Ori_Plast_Product Price record
        Product_Price__c ProPrice3 = new Product_Price__c(
            Items_Description__c= 'Another Product Description',
            Starting_Date__c = System.Today()-3,
            Unit_of_Measure_Code__c = 'MTR',
            Sales_Type__c = 'All Customers',
            Unit_Price__c = 12344444.55,
            Oriplast_Product__c = Oproduct3.Id
        );
        insert ProPrice3;
         // Create OriPlast_Discount_Mapping__c record
        OriPlast_Discount_Mapping__c DicMap2 = new OriPlast_Discount_Mapping__c(
            Name = 'PVCPI-49856',
            Cash_Discount__c = 4,
            Discount__c = 5,
            ItemDiscountCode_ExternalKey__c = 'CDGOR_PVCPI-49856'
        );
        insert DicMap2;
        
        List< OriPlast_Product__c> OriProduct3 = [select id,Name,Item_Disc_Group__c,GST_Value__c from OriPlast_Product__c where OriPlast_Product_Unique_Key__c ='FP201PN040GY00500092' Limit 1];
        List<Product_Price__c> ProductPrice3 = [select Id,Unit_Price__c from Product_Price__c where Oriplast_Product__c =:OriProduct3[0].Id ];
        String concatenatedValue3 = acc.Customer_Disc_Group__c + '_' + oriProduct3[0].Item_Disc_Group__c;
        List <  OriPlast_Discount_Mapping__c> Discount3 = [select id,Discount__c,Cash_Discount__c from OriPlast_Discount_Mapping__c where ItemDiscountCode_ExternalKey__c =: concatenatedValue3 ];
        
        Decimal PriceAfterDiscount3 = (10*(ProductPrice3[0].Unit_Price__c))-(((10*(ProductPrice3[0].Unit_Price__c))*(Discount3[0].Discount__c/100))+((10*(ProductPrice3[0].Unit_Price__c))*(Discount3[0].Cash_Discount__c/100)));
        Decimal TotalGst3 = PriceAfterDiscount*(OriProduct3[0].GST_Value__c/100);
        
        Order_Line_Item__c lineItem3 = new Order_Line_Item__c(
            Ori_Plast_Order__c = order.Id,
            Quantity__c = 10,
            OriPlast_Product_Price__c=ProductPrice3[0].Id,
            Ori_Plast_Product__c = OriProduct3[0].Id,
            Trade_Discount_TD__c = (10*(ProductPrice3[0].Unit_Price__c))*(Discount3[0].Discount__c/100),
            Cash_Discount_CD__c	 = (10*(ProductPrice2[0].Unit_Price__c))*(Discount3[0].Cash_Discount__c/100),
            Price_After_Discount__c = PriceAfterDiscount3,
            CGST__c = TotalGst3/2,
            SGST__c = TotalGst3/2,
            Final_Price__c = PriceAfterDiscount3 + TotalGst3
        );
         // Create Ori_Plast_Product__c record
        OriPlast_Product__c Oproduct4 = new OriPlast_Product__c(
            Name='Another Product',
            Base_Unit_of_Measure__c = 'PCS',
            Category_Picklist__c = 'P2',
            Product_Category_Code_Picklist__c='PVC',
            Sub_Category_Picklist__c='Plain End',
            Item_Disc_Group__c='PVCPI-49857',
            OriPlast_Product_Unique_Key__c='FP201PN040GY00500093'
        );
        insert Oproduct4;
        // Create Ori_Plast_Product Price record
        Product_Price__c ProPrice4 = new Product_Price__c(
            Items_Description__c= 'Another Product Description',
            Starting_Date__c = System.Today()-3,
            Unit_of_Measure_Code__c = 'MTR',
            Sales_Type__c = 'All Customers',
            Unit_Price__c = 123,
            Oriplast_Product__c = Oproduct4.Id
        );
        insert ProPrice4;
        // Create OriPlast_Discount_Mapping__c record
        OriPlast_Discount_Mapping__c DicMap3 = new OriPlast_Discount_Mapping__c(
            Name = 'PVCPI-49857',
            Cash_Discount__c = 4,
            Discount__c = 10,
            ItemDiscountCode_ExternalKey__c = 'CDGOR_PVCPI-49857'
        );
        insert DicMap3;
        List< OriPlast_Product__c> OriProduct4 = [select id,Name,Item_Disc_Group__c,GST_Value__c from OriPlast_Product__c where OriPlast_Product_Unique_Key__c ='FP201PN040GY00500093' Limit 1];
        List<Product_Price__c> ProductPrice4 = [select Id,Unit_Price__c from Product_Price__c where Oriplast_Product__c =:OriProduct4[0].Id ];
        String concatenatedValue4 = acc.Customer_Disc_Group__c + '_' + oriProduct4[0].Item_Disc_Group__c;
        List <  OriPlast_Discount_Mapping__c> Discount4 = [select id,Discount__c,Cash_Discount__c from OriPlast_Discount_Mapping__c where ItemDiscountCode_ExternalKey__c =: concatenatedValue4 ];
         Decimal PriceAfterDiscount4 = (10*(ProductPrice4[0].Unit_Price__c))-(((10*(ProductPrice4[0].Unit_Price__c))*(Discount4[0].Discount__c/100))+((10*(ProductPrice4[0].Unit_Price__c))*(Discount4[0].Cash_Discount__c/100)));
        Decimal TotalGst4 = PriceAfterDiscount*(OriProduct4[0].GST_Value__c/100);
        
        Order_Line_Item__c lineItem4 = new Order_Line_Item__c(
            Ori_Plast_Order__c = order.Id,
            Quantity__c = 10,
            OriPlast_Product_Price__c=ProductPrice4[0].Id,
            Ori_Plast_Product__c = OriProduct4[0].Id,
            Trade_Discount_TD__c = (10*(ProductPrice4[0].Unit_Price__c))*(Discount4[0].Discount__c/100),
            Cash_Discount_CD__c	 = (10*(ProductPrice4[0].Unit_Price__c))*(Discount4[0].Cash_Discount__c/100),
            Price_After_Discount__c = PriceAfterDiscount4,
            CGST__c = TotalGst4/2,
            SGST__c = TotalGst4/2,
            Final_Price__c = PriceAfterDiscount4 + TotalGst4
        );

        insert new List<Order_Line_Item__c>{lineItem1, lineItem2,lineItem3,lineItem4};
            
            Test.startTest();
        // Call the method
        PrintInvoicePageController controller = new PrintInvoicePageController();
        controller.processInvoice();
        // Assert the results if necessary
        Test.stopTest();
    }
    
}