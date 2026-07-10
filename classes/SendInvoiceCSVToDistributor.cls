/*
@Date-- 12/11/2025
@Description-- Sends weekly invoice reports in CSV format to distributors via email
@Last Modified By-- Ayantika Chakraborty
@Last Modified Date--12/11/2025 */
/*public with sharing class SendInvoiceCSVToDistributor {
    
    public static void sendInvoiceReports(
        Map<Id, Map<Id, List<Invoice__c>>> userToDistributorMapWeek,
    Map<Id, Map<Id, List<Invoice__c>>> userToDistributorMapMonth
    ) {
        
        if (userToDistributorMapWeek.isEmpty() && userToDistributorMapMonth.isEmpty()) {
            System.debug('No invoices to send this week or month.');
            return;
        }
        
        Set<Id> userIds = new Set<Id>();
        userIds.addAll(userToDistributorMapWeek.keySet());
        userIds.addAll(userToDistributorMapMonth.keySet());
        
        Map<Id, User> distributorUsersMap = new Map<Id, User>([
            SELECT Id, Name, Email 
            FROM User 
            WHERE Id IN :userIds
        ]);
        
        List<Messaging.SingleEmailMessage> mailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for (Id userId : userIds) {
            User distributorUser = distributorUsersMap.get(userId);
            if (distributorUser == null || distributorUser.Email == null) {
                System.debug('Skipping User Id: ' + userId + '. User not found or has no email.');
                continue;
            }
            
            Map<Id, List<Invoice__c>> distributorMapWeek = userToDistributorMapWeek.get(userId);
            Map<Id, List<Invoice__c>> distributorMapMonth = userToDistributorMapMonth.get(userId);
            
            Set<Id> accountIds = new Set<Id>();
            if (distributorMapWeek != null) accountIds.addAll(distributorMapWeek.keySet());
            if (distributorMapMonth != null) accountIds.addAll(distributorMapMonth.keySet());
            
            for (Id distAccId : accountIds) {
                
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                
                // WEEKLY
                if (distributorMapWeek != null && distributorMapWeek.containsKey(distAccId)) {
                    Messaging.EmailFileAttachment att = createAttachment(distAccId, 'Weekly', 'InvoiceReportWeekly_');
                    if (att != null) attachments.add(att);
                }
                
                // MONTHLY
                if (distributorMapMonth != null && distributorMapMonth.containsKey(distAccId)) {
                    Messaging.EmailFileAttachment att = createAttachment(distAccId, 'Monthly', 'InvoiceReportMonthly_');
                    if (att != null) attachments.add(att);
                }
                
                if (attachments.isEmpty()) {
                    System.debug('Skipping Account Id: ' + distAccId + '. No weekly or monthly invoices found.');
                    continue;
                }
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { 'ayantika_c@pursuitsoftware.com' });
                // mail.setToAddresses(new String[] { distributorUser.Email });
                
                mail.setSubject('Invoice Reports (Weekly & Monthly) - ' + Date.today().format());
                
                String htmlBody = ''
                    + '<html>'
                    + '<body style="font-family:Arial, sans-serif; font-size:14px; color:#333;">'
                    + '<p>Hello <b>' + distributorUser.Name + '</b>,</p>'
                    + '<p>Please find attached your <b>Weekly</b> and <b>Monthly</b> invoice reports.</p>'
                    + '<p>'
                    + 'Kindly review the report and verify the details against your system records.<br/>'
                    + 'If you find any discrepancies, please inform us immediately with the invoice number and relevant details.'
                    + '</p>'
                    + '<p style="margin-top:20px;">Best Regards,<br/><b>Salesforce System</b></p>'
                    + '<hr style="border:0; border-top:1px solid #ccc; margin:20px 0;"/>'
                    + '<p style="color:red; font-weight:bold; text-align:center; font-size:15px;">'
                    + '⚠️ System-generated report: Please verify the attached report carefully.<br/>'
                    + 'If you find any discrepancies, contact us immediately with the invoice number and related details.'
                    + '</p>'
                    + '<p style="font-size:12px; color:gray; text-align:center;">'
                    + 'This is an automated email — please do not reply.'
                    + '</p>'
                    + '</body>'
                    + '</html>';
                
                mail.setHtmlBody(htmlBody);
                mail.setFileAttachments(attachments);
                
                mailsToSend.add(mail);
                System.debug('[103]DEBUG Prepared CSV report(s) for ' + distributorUser.Email + ' with ' + attachments.size() + ' attachments.');
            }
            
            System.debug('[105]DEBUG UserId=' + userId + ' | Distributor Accounts=' + accountIds);
        }
        
        if (!mailsToSend.isEmpty()) {
            Messaging.sendEmail(mailsToSend, false);
            System.debug('[113]DEBUG Successfully sent ' + mailsToSend.size() + ' invoice reports.');
        }
    }
    
    
    // -------------------------------------------------------------------
    // UPDATED CSV ATTACHMENT CREATION — HEADER-ONLY FILTER FIXED
    // -------------------------------------------------------------------
    private static Messaging.EmailFileAttachment createAttachment(Id distributorId, String reportType, String filenamePrefix) {
        
        PageReference csvPage = Page.InvoiceCSVExport;
        csvPage.getParameters().put('distributorId', String.valueOf(distributorId));
        csvPage.getParameters().put('reportType', reportType);
        
        Blob csvBlob;
        
        if (Test.isRunningTest()) {
            csvBlob = Blob.valueOf('Header1,Header2\nData1,Data2');
        }else {
            csvBlob = csvPage.getContent();
        }
        
        // if (Test.isRunningTest()) {
            //     csvBlob = Blob.valueOf('Mock CSV Data For Test ' + reportType);
        // } else {
            //     csvBlob = csvPage.getContent();
        // }
        
        // Convert blob to text and normalize
        String csvText = csvBlob.toString().trim();
        
        // Normalize line breaks
        csvText = csvText.replace('\r\n', '\n').replace('\r', '\n');
        
        List<String> lines = csvText.split('\n');
        
        // Detect: Only header OR header + empty line
        if (lines.size() <= 1 || (lines.size() == 2 && String.isBlank(lines[1]))) {
            System.debug('⚠ No data found for ' + reportType + ' report. No attachment created.');
            return null;
        }
        
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(filenamePrefix + Date.today().format() + '.csv');
        attachment.setBody(csvBlob);
        attachment.setContentType('application/vnd.ms-excel');
        
        return attachment;
    }
}*/
/*
@Date-- 12/11/2025
@Description-- Sends weekly invoice reports in CSV format to distributors via email
@Last Modified By-- Ayantika Chakraborty
@Last Modified Date--12/11/2025
 */
public with sharing class SendInvoiceCSVToDistributor {
    
    public static void sendInvoiceReports(
        Map<Id, Map<Id, List<Invoice__c>>> userToDistributorMapWeek
    ) {
        
        if (userToDistributorMapWeek == null || userToDistributorMapWeek.isEmpty()) {
            System.debug('No weekly invoices to send.');
            return;
        }
        
        Set<Id> userIds = userToDistributorMapWeek.keySet();
        
        Map<Id, User> distributorUsersMap = new Map<Id, User>([
            SELECT Id, Name, Email 
            FROM User 
            WHERE Id IN :userIds
        ]);
        
        List<Messaging.SingleEmailMessage> mailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for (Id userId : userIds) {
            
            User distributorUser = distributorUsersMap.get(userId);
            
            if (distributorUser == null || distributorUser.Email == null) {
                System.debug('Skipping User Id: ' + userId + '. User not found or has no email.');
                continue;
            }
            
            Map<Id, List<Invoice__c>> distributorMapWeek = userToDistributorMapWeek.get(userId);
            if (distributorMapWeek == null) continue;
            
            Set<Id> accountIds = distributorMapWeek.keySet();
            
            for (Id distAccId : accountIds) {
                
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                
                // WEEKLY ONLY
                if (distributorMapWeek.containsKey(distAccId)) {
                    Messaging.EmailFileAttachment att = createAttachment(distAccId, 'Weekly', 'InvoiceReportWeekly_');
                    if (att != null) attachments.add(att);
                }
                
                if (attachments.isEmpty()) {
                    System.debug('Skipping Account Id: ' + distAccId + ' — No weekly invoice data found.');
                    continue;
                }
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                // FOR TESTING — use your email
                mail.setToAddresses(new String[] { 'ayantika_c@pursuitsoftware.com' });
                
                // For production:
                // mail.setToAddresses(new String[] { distributorUser.Email });
                
                mail.setSubject('Weekly Invoice Report - ' + Date.today().format());
                
                String htmlBody = ''
                    + '<html>'
                    + '<body style="font-family:Arial, sans-serif; font-size:14px; color:#333;">'
                    + '<p>Hello <b>' + distributorUser.Name + '</b>,</p>'
                    + '<p>Please find attached your <b>Weekly</b> invoice report.</p>'
                    + '<p>'
                    + 'Kindly review the report and verify the details against your system records.<br/>'
                    + 'If you find any discrepancies, please inform us immediately with the invoice number and relevant details.'
                    + '</p>'
                    + '<p style="margin-top:20px;">Best Regards,<br/><b>Salesforce System</b></p>'
                    + '<hr style="border:0; border-top:1px solid #ccc; margin:20px 0;"/>'
                    + '<p style="color:red; font-weight:bold; text-align:center; font-size:15px;">'
                    + '⚠️ System-generated report: Please verify the attached report carefully.<br/>'
                    + 'If you find any discrepancies, contact us immediately with the invoice number and related details.'
                    + '</p>'
                    + '<p style="font-size:12px; color:gray; text-align:center;">'
                    + 'This is an automated email — please do not reply.'
                    + '</p>'
                    + '</body>'
                    + '</html>';
                
                mail.setHtmlBody(htmlBody);
                mail.setFileAttachments(attachments);
                
                mailsToSend.add(mail);
                System.debug('✔ Prepared WEEKLY CSV for ' + distributorUser.Name + ' (Attachments: ' + attachments.size() + ')');
            }
        }
        
        if (!mailsToSend.isEmpty()) {
            System.debug('----------------- EMAIL ------------------');
            Messaging.sendEmail(mailsToSend, false);
            System.debug('✔ Successfully sent ' + mailsToSend.size() + ' weekly invoice reports.');
        }
    }
    
    
    // -------------------------------------------------------------------
    // CSV ATTACHMENT CREATOR — HEADER-ONLY FILTER INCLUDED
    // -------------------------------------------------------------------
    /*private static Messaging.EmailFileAttachment createAttachment(Id distributorId, String reportType, String filenamePrefix) {
        
        PageReference csvPage = Page.InvoiceCSVExport;
        csvPage.getParameters().put('distributorId', String.valueOf(distributorId));
        csvPage.getParameters().put('reportType', reportType);
        
        Blob csvBlob;
        
        if (Test.isRunningTest()) {
            csvBlob = Blob.valueOf('Header1,Header2\nData1,Data2');
        } else {
            csvBlob = csvPage.getContent();
        }
        
        String csvText = csvBlob.toString().trim();
        csvText = csvText.replace('\r\n', '\n').replace('\r', '\n');
        
        List<String> lines = csvText.split('\n');
        
        // Skip empty CSVs (header only)
        if (lines.size() <= 1 || (lines.size() == 2 && String.isBlank(lines[1]))) {
            System.debug('⚠ No data found for ' + reportType + ' report. Attachment not created.');
            return null;
        }
        
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(filenamePrefix + Date.today().format() + '.csv');
        attachment.setBody(csvBlob);
        attachment.setContentType('application/vnd.ms-excel');
        
        return attachment;
    }*/
    private static Messaging.EmailFileAttachment createAttachment(Id distributorId, String reportType, String filenamePrefix) {
        
        // 1. Generate CSV via Apex
        Blob csvBlob = InvoiceCSVService.generateWeeklyCSV(distributorId);
        
        // Convert blob → string to check if data exists
        String csvText = csvBlob.toString().trim();
        
        // If only header present → skip
        List<String> lines = csvText.split('\n');
        if (lines.size() <= 1) {
            System.debug('⚠ No invoice records found for this distributor. Skipping attachment.');
            return null;
        }
        
        // 2. Build Email Attachment
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(filenamePrefix + Date.today().format() + '.csv');
        attachment.setBody(csvBlob);
        attachment.setContentType('application/vnd.ms-excel');
        
        return attachment;
    }
    
}