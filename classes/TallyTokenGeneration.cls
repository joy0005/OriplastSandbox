@RestResource(urlMapping='/tallytokengeneration/*')
global class TallyTokenGeneration {

    @HttpPost
    global static void getToken(){
        String reqBody = RestContext.request.requestBody.toString();
        Map<String,Object> obj = (Map<String,Object>) JSON.deserializeUntyped(reqBody);   
        Map<String,Object> getTokenObj = (Map<String,Object>)obj.get('TOKENDETAILS');     
        String token = getTokenObj.get('TOKEN').toString();
               
		if(!String.isBlank(token)){
            Tally_Token__c tt = new Tally_Token__c();
            tt.Tally_Token__c = token;
            insert tt;

            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf('{"status": "successfuly save token"}');
        }
        else{
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf('{"status": "token is not provided"}');
        }

		Integration_Log__c intLog = new Integration_Log__c(
            Class_Name__c = 'TallyTokenGeneration',
            Request_Body__c = reqBody,
            Response_Body__c = RestContext.response.responseBody.toString(),
            Type__c = 'Inbound'
        );
        
		Database.insert(intLog);  
    }
}