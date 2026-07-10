@RestResource(urlMapping='/invoicegeneration/*')
global class InvoiceGeneration {
    @HttpPost
    global static void getInvoice(){       
        String token = RestContext.request.params.get('token');
        //**If else codition for handle #token error managnment
        if(token != null && !String.isBlank(token)){
            Tally_Token__c tokenGet = [SELECT Tally_Token__c FROM Tally_Token__c order by CreatedDate DESC limit 1];
            if(tokenGet.Tally_Token__c == token){
                String requestBody = RestContext.request.requestBody.toString();
                processInvoiceRequest(requestBody);               
            }
            else{
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf('{"status": "TOKEN Is Invalid"}');
            }
        }
        else{
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf('{"status": "Please Provide The TOKEN"}');
        }       
    }
    private static void processInvoiceRequest(String requestBody) {
        try {
            String reqtBody = requestBody;
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(reqtBody);
            
            List<Map<String,String>> invoiceNumberlist = new List<Map<String,String>>();
            
            if (jsonMap != null && jsonMap.containsKey('InvoiceDetails')) {
                List<Object> invoiceDetails = (List<Object>) jsonMap.get('InvoiceDetails');
                if (invoiceDetails != null) {
                    for(Object invoiceDetailObj : invoiceDetails) {
                        if (invoiceDetailObj != null) {
                            Map<String,String> invoiceNumbers = new Map<String,String>();
                            Map<String, Object> invoiceDetail = (Map<String, Object>) invoiceDetailObj;
                            String invoiceNumber = (String) invoiceDetail.get('InvoiceNumber');
                            if (invoiceNumber != null) {
                                invoiceNumbers.put('InvoiceNumber', invoiceNumber);
                                invoiceNumberlist.add(invoiceNumbers);
                            }
                        }
                    }
                }
            }
            
            Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put('status', 'Success');
            responseMap.put('invoiceNumbers', invoiceNumberlist);
            
            String responseBody = JSON.serialize(responseMap);
            Integration_Log__c intLog = new Integration_Log__c(
                Class_Name__c = 'InvoiceGeneration',
                Request_Body__c = requestBody,
                Response_Body__c = responseBody,
                Type__c = 'Inbound'
            );
            
            Staging__c stg = new Staging__c(
                JSON_Payload__c = requestBody,
                Status__c = 'Pending'
            );
            
            Database.Insert(intLog);
            Database.Insert(stg);
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
            
        } catch(Exception e) {
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf('{"status": "Error", "message": "' + e.getMessage() + '"}');
        }
    }   
}