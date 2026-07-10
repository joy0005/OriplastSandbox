global class WeeklyInvoiceLineItemExcelBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    // Map: DistributorId -> List of rows (each row is a List<String> of column values)
    private Map<Id, List<List<String>>> distributorRows = new Map<Id, List<List<String>>>();
    
    // Week boundaries used in the query (computed once at construction)
    private Datetime startDateTime;
    private Datetime endDateTime;
    
    // Constructor: compute current week's Monday..Sunday (week starts Monday)
    public WeeklyInvoiceLineItemExcelBatch() {
        Date startOfWeek = Date.today().toStartOfWeek();
        Date endOfWeek   = startOfWeek.addDays(6);
        
        this.startDateTime = Datetime.newInstance(startOfWeek, Time.newInstance(0,0,0,0));
        this.endDateTime   = Datetime.newInstance(endOfWeek, Time.newInstance(23,59,59,999));
        
    }
    
    // Start: query Invoice_Line_Item__c for the week's invoices (pull required parent fields)
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [SELECT Name, Invoice_No__c, SKU__c, Ori_Plast_Product_Name__c, Quantity__c, Final_Price__c,
                Ori_Plast_Invoice__r.Id, Ori_Plast_Invoice__r.Invoice_Number__c, Ori_Plast_Invoice__r.Name,
                Ori_Plast_Invoice__r.Invoice_Date__c, Ori_Plast_Invoice__r.CreatedDate, Ori_Plast_Invoice__r.Distributor__c,
                Ori_Plast_Invoice__r.Distributor__r.Name, Ori_Plast_Invoice__r.Dealer_Name__c,
                Ori_Plast_Product__r.Sub_Category_Picklist__c, Ori_Plast_Product__r.Category_Picklist__c, Unit_of_Measure__c
         FROM Invoice_Line_Item__c
         WHERE Ori_Plast_Invoice__r.CreatedDate >= :startDateTime
           AND Ori_Plast_Invoice__r.CreatedDate <= :endDateTime
         ORDER BY Ori_Plast_Invoice__r.CreatedDate DESC]
            );
    }
    
    
    // Execute: group rows by Distributor Id. Keep only strings to reduce memory usage.
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        for (SObject s : scope) {
            Invoice_Line_Item__c line = (Invoice_Line_Item__c)s;
            // Defensive: ensure parent invoice and distributor exist
            if (line.Ori_Plast_Invoice__r == null || line.Ori_Plast_Invoice__r.Distributor__c == null) {
                continue;
            }
            Id distributorId = line.Ori_Plast_Invoice__r.Distributor__c;
            
            // Prepare row: match the columns you requested earlier
            List<String> row = new List<String>{
                safeString(line.Name),
                safeString(line.Invoice_No__c),
                safeString(line.Ori_Plast_Invoice__r.Invoice_Number__c),
                safeString(line.Ori_Plast_Invoice__r.Name),
                safeString(line.Ori_Plast_Invoice__r.Invoice_Date__c),
                String.valueOf(line.Ori_Plast_Invoice__r.CreatedDate),
                safeString(line.Ori_Plast_Invoice__r.Distributor__r != null ? line.Ori_Plast_Invoice__r.Distributor__r.Name : null),
                safeString(line.Ori_Plast_Invoice__r.Dealer_Name__c),
                safeString(line.Ori_Plast_Product_Name__c),
                safeString(line.SKU__c),
                safeString(line.Ori_Plast_Product__r != null ? line.Ori_Plast_Product__r.Sub_Category_Picklist__c : null),
                safeString(line.Ori_Plast_Product__r != null ? line.Ori_Plast_Product__r.Category_Picklist__c : null),
                safeString(line.Unit_of_Measure__c),
                safeString(line.Quantity__c),
                safeString(line.Final_Price__c)
            };
            
            if (!distributorRows.containsKey(distributorId)) {
                distributorRows.put(distributorId, new List<List<String>>());
            }
            distributorRows.get(distributorId).add(row);
        }
    }
    
    // Finish: for each distributor build an Excel XML workbook (one worksheet) and email to Associated_User__c email
    global void finish(Database.BatchableContext bc) {
        
        if (distributorRows.isEmpty()) {
            System.debug('No invoice line items found for the week ' + startDateTime + ' - ' + endDateTime);
            return;
        }
        
        // Query Accounts to get Associated_User__c -> then User email
        Set<Id> distributorIds = distributorRows.keySet();
        Map<Id, Account> accMap = new Map<Id, Account>(
            [SELECT Id, Name, Associated_User__c, Associated_User__r.Email FROM Account WHERE Id IN :distributorIds]
            );
        
        // For each distributor, build XML and send email to the associated user
        for (Id distId : distributorRows.keySet()) {
            Account acc = accMap.get(distId);
            if (acc == null) {
                System.debug('No Account found for distributor id: ' + distId);
                continue;
            }
            
            String recipientEmail;
            if (acc.Associated_User__c != null && acc.Associated_User__r != null) {
                recipientEmail = acc.Associated_User__r.Email;
            }
            if (String.isBlank(recipientEmail)) {
                System.debug('No associated user email for Distributor: ' + acc.Name + ' (' + acc.Id + '), skipping email.');
                continue;
            }
            
            // Build Excel (XML Spreadsheet) content for this distributor
            String xml = buildExcelForDistributor(acc.Name, distributorRows.get(distId));
            
            // Create attachment
            Blob excelBlob = Blob.valueOf(xml);
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            String safeFileName = sanitizeFileName(acc.Name) + '_Invoices_' +
                startDateTime.date().format() + '_to_' + endDateTime.date().format() + '.xls';
            efa.setFileName(safeFileName);
            efa.setBody(excelBlob);
            efa.setContentType('application/vnd.ms-excel');
            
            // Prepare email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // mail.setToAddresses(new String[]{recipientEmail});
            mail.setToAddresses(new String[] { 'ayantika_c@pursuitsoftware.com' });
            mail.setSubject('Weekly Invoice Line Items for ' + acc.Name + ' (' + startDateTime.date().format() + ' - ' + endDateTime.date().format() + ')');
            mail.setPlainTextBody('Please find attached the weekly invoice line items.');
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{efa});
            
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
                System.debug('Sent weekly invoice file to ' + recipientEmail + ' for distributor ' + acc.Name);
            } catch (Exception ex) {
                System.debug('Failed to send email to ' + recipientEmail + ' : ' + ex.getMessage());
            }
        }
    }
    
    // -----------------------
    // Helper methods
    // -----------------------
    
    // Build Excel XML for a distributor - single worksheet per distributor
    private String buildExcelForDistributor(String distributorName, List<List<String>> rows) {
        String excelStart =
            '<?xml version="1.0"?>' +
            '<?mso-application progid="Excel.Sheet"?>' +
            '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"' +
            ' xmlns:o="urn:schemas-microsoft-com:office:office"' +
            ' xmlns:x="urn:schemas-microsoft-com:office:excel"' +
            ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"' +
            ' xmlns:html="http://www.w3.org/TR/REC-html40">';
        String excelEnd = '</Workbook>';
        
        String sheetName = sanitizeSheetName(distributorName);
        String sheet = '<Worksheet ss:Name="' + sheetName + '"><Table>';
        // Header row - same columns as we stored
        List<String> headers = new List<String>{
            'LineItem.Name','LineItem.Invoice_No__c','Invoice.Invoice_Number__c','Invoice.Name','Invoice.Invoice_Date__c',
            'Invoice.CreatedDate','Distributor.Name','Dealer_Name__c','Ori_Plast_Product_Name__c','SKU__c',
            'Product.Sub_Category','Product.Category','Unit_of_Measure__c','Quantity__c','Final_Price__c'
        };
        
        sheet += '<Row>';
        for (String h : headers) {
            sheet += '<Cell><Data ss:Type="String">' + escapeXml(h) + '</Data></Cell>';
        }
        sheet += '</Row>';
        
        // Data rows
        for (List<String> row : rows) {
            sheet += '<Row>';
            for (String col : row) {
                // determine type: we keep everything as String to avoid parsing hassles
                sheet += '<Cell><Data ss:Type="String">' + escapeXml(col) + '</Data></Cell>';
            }
            sheet += '</Row>';
        }
        
        sheet += '</Table></Worksheet>';
        return excelStart + sheet + excelEnd;
    }
    
    // Safe conversion to string; handle nulls and numbers
    private String safeString(Object o) {
        if (o == null) return '';
        try {
            return String.valueOf(o);
        } catch (Exception ex) {
            return '';
        }
    }
    
    // Escape minimal XML characters in cell values
    private String escapeXml(String s) {
        if (s == null) return '';
        s = s.replace('&', '&amp;');
        s = s.replace('<', '&lt;');
        s = s.replace('>', '&gt;');
        s = s.replace('"', '&quot;');
        // s = s.replace("'", '&apos;');
        return s;
    }
    
    // Sanitize worksheet name (Excel limit 31 chars and forbids certain chars)
    private String sanitizeSheetName(String name) {
        if (String.isBlank(name)) name = 'Sheet';
        
        String out = name;
        
        // Replace forbidden Excel sheet name characters : \ / ? * [ ]
        out = out.replace(':', ' ');
        out = out.replace('\\', ' ');
        out = out.replace('/', ' ');
        out = out.replace('?', ' ');
        out = out.replace('*', ' ');
        out = out.replace('[', ' ');
        out = out.replace(']', ' ');
        
        out = out.trim();
        if (out.length() > 30) out = out.substring(0, 30);
        
        return escapeXml(out);
    }
    
    
    // Sanitize filename for attachment
    private String sanitizeFileName(String name) {
        if (String.isBlank(name)) name = 'Distributor';
        
        String out = name;
        
        // Regex-safe replacement of invalid filename characters
        out = out.replaceAll('[\\\\/:*?\"<>|]', '_');
        
        if (out.length() > 40) out = out.substring(0, 40);
        
        return out;
    }
}