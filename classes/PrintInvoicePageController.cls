/*@company-- DataColada
@Date-- 23/03/2024
@Author-- Reetabrata Mishra
@Description--This class used in in VF page to map the field value
@Last Modified By-- Reetabrata Mishra
@Last Modified Date--26/03/2024 */


public class PrintInvoicePageController {
    public Ori_Plast_Order__c orders {get;set;}
    public Account acc {get;set;}
    public List<Order_Line_Item__c> lineItems {get;set;}
    public Decimal totalProductPrice { get; set; }
    public String finalOrderValueInWords { get; set; } // String to hold final order value in words
    public string orderDate { get; set; }
    public String proformaInvoiceAddress { get; set; }

    
    public  PageReference processInvoice() {
        string recordId= ApexPages.currentPage().getParameters().get('id');
        if (recordId != null) {
            
            // Perform the first query to retrieve Ori_Plast_Order__c records
            orders = [SELECT Id, Name, Total_CGST__c,
                      Total_Discount__c ,Total_Order_Quantity__c ,
                      Total_SGST__c ,Account__c ,CreatedDate, Final_Order_Value__c, 
                      Total_Cash_Discount__c,Total_Trade_Discount__c,
                       Total_Price_After_Discount__c,Order_Status__c FROM Ori_Plast_Order__c WHERE Id = :recordId LIMIT 1];
            System.debug('Oriplast oder Query result: ' + orders);
            
                    orderDate = orders.CreatedDate.format().remove('00:00:00 GMT');
               

            
            acc = [select Name,GST_Registration_No__c ,GST_Registration_Type__c , P_A_N_No__c, 
                  BillingStreet,BillingCity,BillingPostalCode,BillingState,BillingCountry,Account_External_Key__c
                   from Account where id =:orders.Account__c];
            
            System.debug('Oriplast Account Query result: ' + acc);
            if (acc != null && acc.Account_External_Key__c != null) {
            List<OriPlastProformaInvoiceAddressManagement__mdt> metadataRecords = [
                SELECT MasterLabel, Address__c  
                FROM OriPlastProformaInvoiceAddressManagement__mdt 
                WHERE MasterLabel = :acc.Account_External_Key__c LIMIT 1
            ];

            if (!metadataRecords.isEmpty()) {
                proformaInvoiceAddress = metadataRecords[0].Address__c ;
            } else {
                proformaInvoiceAddress = null;
            }
        } else {
            proformaInvoiceAddress = null;
        }
            // Process the query results
            if (orders!=null) {
                Ori_Plast_Order__c order = orders;
                System.debug('Oriplast oder Query result: ' + order);
                
                // Perform the second query to retrieve related Order_Line_Item__c records
                lineItems = [SELECT Id, Name,Cash_Discount_CD__c ,CGST__c ,IGST__c ,
                             Ori_Plast_Product_Name__c ,OriPlast_Product_Unit_Price__c ,Cash_Discount_Percentage__c ,
                             Price_After_Discount__c ,SGST__c ,Unit_of_Measure__c ,ERP_Quantity__c ,Total_Discount__c ,Total_Price__c ,
                             Trade_Discount_TD__c ,Quantity__c,Ori_Plast_Product__r.HSN_SAC_Code__c,  
                             Ori_Plast_Product__r.GST_Value__c,Trade_Discount__c,
                              CGST_Percentage__c ,SGST_Percentage__c FROM Order_Line_Item__c WHERE Ori_Plast_Order__c = :order.Id];
                
                System.debug('Order_Line_Item__c Query result: ' + lineItems);
                //Calculating Total Product Price
                totalProductPrice = 0;
                for (Order_Line_Item__c item : lineItems) {
                    totalProductPrice += item.Total_Price__c;
                }
                System.debug('total Product Price: ' + totalProductPrice);
                
                finalOrderValueInWords= getNumberTOWordConvertion(orders.Final_Order_Value__c);
                
            } else {
                System.debug('No Ori_Plast_Order__c records found for the provided ID.');
            }
        } else {
            System.debug('No record ID available.');
        }
        return null;
    }
    
    public String getNumberTOWordConvertion(Decimal num) {
        
        Decimal junkVal = num;
        Decimal junkValPaisa = junkVal - Math.floor(junkVal);
        junkVal = Math.floor(junkVal);
        
        String obStr = junkVal.toPlainString();
        String[] numReversed = obStr.split('');
        String[] actnumber = reverse(numReversed);
        String firstHalf = convertInWords(numReversed, actnumber);
        
        Integer tmp = Math.round(junkValPaisa * 100);
        junkValPaisa = (Decimal)tmp / 100; System.debug('jj :' + junkValPaisa);
        String paisaStr = junkValPaisa.toPlainString();
        String secondHalf;
        if (paisaStr == '0') {
            secondHalf = '';
        } else if (paisaStr.length() != 4) {
            paisaStr = paisaStr + '0';
            paisaStr = paisaStr.substring(2);
            String [] numReversedPaisa = paisaStr.split('');
            String[] actnumberPaisa = reverse(numReversedPaisa);
            secondHalf = convertInWords(numReversedPaisa, actnumberPaisa);
        } else {
            paisaStr = paisaStr.substring(2);
            String [] numReversedPaisa = paisaStr.split('');
            String[] actnumberPaisa = reverse(numReversedPaisa);
            secondHalf = convertInWords(numReversedPaisa, actnumberPaisa);
        }
        
        String SumOFHalves = '';
        
        if (secondHalf.length() > 4) {
            firstHalf = firstHalf.replace('Only', 'Rupess And ');
            secondHalf = secondHalf.replace('Only', 'Paisa Only');
            SumOFHalves = firstHalf + secondHalf;
        } else {
            firstHalf = firstHalf.replace('Only', 'Rupess Only');
            SumOFHalves = firstHalf;
        }
        
        // IF amount has any value
        if (SumOFHalves.length() > 5) {
            return SumOFHalves;
        } else {
            return '';
        }
    }
    
    // Method reverse the number
    public List<String> reverse(List<String> strToRev) {
        List<String> revList = new List<String>();
        for (Integer i = strToRev.size() - 1; i >= 0; i--) {
            revList.add(strToRev.get(i));
        }
        revList.add('');
        return revList;
    }
    
    public String convertInWords(String[] numRev, String[] actnum) {
        List<String> iWords = new List<String> {'Zero', ' One', ' Two', ' Three', ' Four', ' Five', ' Six', ' Seven', ' Eight', ' Nine'};
            List<String> ePlace = new List<String> {' Ten', ' Eleven', ' Twelve', ' Thirteen', ' Fourteen', ' Fifteen', ' Sixteen', ' Seventeen', ' Eighteen', ' Nineteen'};
                List<String> tensPlace = new List<String> {'dummy', ' Ten', ' Twenty', ' Thirty', ' Forty', ' Fifty', ' Sixty', ' Seventy', ' Eighty', ' Ninety' };
                    
                    Integer iWordsLength = numRev.size();
        String totalWords = '';
        List<String> inWords = new List<String>();
        for (Integer k = 0; k < iWordsLength; k++) {
            inWords.add('');
        }
        String finalWord = '';
        Integer j = 0;
        
        // Main For loop
        for (Integer i = 0; i < iWordsLength; i++) {
            
            if (i == 0) {
                if (actnum[i] == '0' || actnum[i + 1] == '1') {
                    inWords[j] = '';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])];
                }
                inWords[j] = inWords[j] + ' Only';
            } else if (i == 1) {
                
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i] == '1') {
                    inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                } else {
                    inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                }
            } else if (i == 2) {
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i - 1] != '0' && actnum[i - 2] != '0') {
                    inWords[j] = iWords[Integer.valueof(actnum[i])] + ' Hundred and';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])] + ' Hundred';
                }
            } else if (i == 3) {
                if (actnum[i] == '0' || actnum[i + 1] == '1') {
                    inWords[j] = '';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])];
                }
                if (actnum[i + 1] != '0' || Integer.valueof(actnum[i]) > 0) {
                    inWords[j] = inWords[j] + ' Thousand';
                }
            } else if (i == 4) {
                
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i] == '1') {
                    inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                } else {
                    inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                }
                
            } else if (i == 5) {
                if (actnum[i] == '0' || actnum[i + 1] == '1') {
                    inWords[j] = '';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])];
                }
                if (actnum[i + 1] != '0' || Integer.valueof(actnum[i]) > 0) {
                    inWords[j] = inWords[j] + ' Lakh';
                }
            } else if (i == 6) {
                
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i] == '1') {
                    inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                } else {
                    inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                }
                
            } else if (i == 7) {
                if (actnum[i] == '0' || actnum[i + 1] == '1' ) {
                    inWords[j] = '';
                } else {
                    inWords[j] = iWords[Integer.valueof(actnum[i])];
                }
                inWords[j] = inWords[j] + ' Crore';
            } else if (i == 8) {
                
                if (actnum[i] == '0') {
                    inWords[j] = '';
                } else if (actnum[i] == '1') {
                    inWords[j] = ePlace[Integer.valueof(actnum[i - 1])];
                } else {
                    inWords[j] = tensPlace[Integer.valueof(actnum[i])];
                }
                
            }
            
            j++;
        }
        // End of For loop
        
        // Reverse the List
        inWords = reverse(inWords);
        
        for (Integer i = 0; i < inWords.size(); i++) {
            finalWord += inWords[i];
        }
        
        return finalWord;
    }
    
}