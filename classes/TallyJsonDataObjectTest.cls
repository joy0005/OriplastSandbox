@IsTest
public without sharing class TallyJsonDataObjectTest {
    
    @IsTest
    static void testJsonDeserialization() {
        String jsonData = '{"Distributor":"RASHMI AGENCY - (2023-24)","DistributorIdentificationKey":"CUSBLS0450","InvoiceDetails":[{"InvoiceNumber":"RA/T-833/24-25","InvoiceDate":"1-Jul-24","InvoiceStatus":"Submitted","DealerDetails":{"Name":"Cash"},"InvoiceLineItems":[{"SKU":"1 UPVC BRASS MTA","Quantity":1,"UnitofMeasure":"PCS","rate":119.53,"TotalDiscountPercentage":0,"FinalPrice":119.53}]}]}';

        TallyJsonDataObject obj = (TallyJsonDataObject)JSON.deserialize(jsonData, TallyJsonDataObject.class);
        
        
        System.assertEquals('RASHMI AGENCY - (2023-24)', obj.Distributor);
        System.assertEquals('CUSBLS0450', obj.DistributorIdentificationKey);        
        
        TallyJsonDataObject.InvoiceDetails invoice1 = obj.InvoiceDetails[0];
        System.assertEquals('RA/T-833/24-25', invoice1.invoiceNumber);
        System.assertEquals('1-Jul-24', invoice1.invoiceDate);
        System.assertEquals('Submitted', invoice1.invoiceStatus);
        System.assertEquals('Cash', invoice1.dealerDetails.Name);        
      
        System.assertEquals(119.53, invoice1.invoiceLineItems[0].rate);
        System.assertEquals(1, invoice1.invoiceLineItems[0].quantity);
        System.assertEquals('1 UPVC BRASS MTA', invoice1.invoiceLineItems[0].SKU);
        System.assertEquals(0, invoice1.invoiceLineItems[0].totalDiscountPercentage);
        System.assertEquals(119.53, invoice1.invoiceLineItems[0].FinalPrice);
        System.assertEquals('PCS', invoice1.invoiceLineItems[0].UnitofMeasure);
    }
}