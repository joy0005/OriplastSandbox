/*@company-- DataColada
@Date-- 23/03/2024
@Author-- Reetabrata Mishra
@Description--This class used for Print Invoice and used in Flow
@Last Modified By-- Reetabrata Mishra
@Last Modified Date--26/03/2024 */


public class printInvoiceController {
    @InvocableMethod
    public static List<Id>  printInvoice(List<RecordIdWrapper> recordIds) {
         List<Id> contentDocumentLinkIds = new List<Id>();
        if(recordIds != null && !recordIds.isEmpty()) {
            RecordIdWrapper wrapper = recordIds.get(0);
            Id recordId = wrapper.recordId;
            System.debug('Received Record Id: ' + recordId);
   //Calling attachmentPDf with the page you have rendered as PDF
            PageReference PDf =  Page.PrintInvoiceController;
            PDf.getParameters().put('Id',recordId);
            PDf.setRedirect(true);
            Attachment attach = new Attachment();
            Blob b ;
            if(Test.isRunningTest()) {
                b = blob.valueOf('Unit.Test');
            } else {
                b = PDf.getContent();
            }
            /*attach.Body = b;
            attach.Name = 'Proforma Invoice.pdf';
            attach.IsPrivate = false;
            attach.ParentId = recordId;
            insert attach;*/
            
            
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Proforma Invoice';
        cv.VersionData = b;
        cv.PathOnClient = 'Proforma Invoice.pdf'; 
        
        // Insert the ContentVersion record
        insert cv;
        system.debug('Proforma Invoice'+cv.id);
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = recordId ; 
        cdl.ShareType = 'V'; 
        cdl.Visibility = 'AllUsers'; 
        insert cdl;
        system.debug('ContentDocumentLink'+cdl.id);
        contentDocumentLinkIds.add(cv.Id);    
            
        } else {
            // Handle the case when the list is empty or null
            System.debug('No record IDs received.');
        }
         return contentDocumentLinkIds;
    }
    
    
    public class RecordIdWrapper {
        @InvocableVariable(label='Record Id' description='Id of the record to process')
        public Id recordId;
    }
}