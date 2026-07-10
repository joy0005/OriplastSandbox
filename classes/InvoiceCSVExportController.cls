/*
@Date-- 12/11/2025
@Description-- Controller for InvoiceCSVExport VF Page.
@Last Modified By-- Ayantika Chakraborty
@Last Modified Date--12/11/2025
 */
/*public with sharing class InvoiceCSVExportController {
    public List<WrapperLineItem> invoiceLineItems { get; set; }
    
    public InvoiceCSVExportController() {
        Id distributorId = ApexPages.currentPage().getParameters().get('distributorId');
        String reportType = ApexPages.currentPage().getParameters().get('reportType');
        
        // --- 1. Determine Date Range based on reportType ---
        // Date today = Date.newInstance(2025, 03, 10); 
        Date today = Date.today();
        Date startDate;
        Date endDate;

        if (reportType == 'Weekly') {
            startDate = today.toStartOfWeek();
            endDate = startDate.addDays(6);
        } else if (reportType == 'Monthly') {
            startDate = today.toStartOfMonth();
            endDate = startDate.addMonths(1).addDays(-1); 
        } else { 
            System.debug('Invalid or missing reportType parameter: ' + reportType);
            invoiceLineItems = new List<WrapperLineItem>();
            return;
        }

        // --- 2. Build Dynamic SOQL Query with Date Filter ---
        String query = 'SELECT Name, Invoice_No__c, Ori_Plast_Invoice__r.Invoice_Number__c, ' +
                       'Ori_Plast_Invoice__r.Name, Ori_Plast_Invoice__r.Invoice_Date__c,Ori_Plast_Invoice__r.CreatedDate, ' +
                       'Ori_Plast_Invoice__r.Distributor__r.Name, Ori_Plast_Invoice__r.Dealer_Name__c, ' +
                       'Ori_Plast_Product_Name__c, SKU__c, Ori_Plast_Product__r.Sub_Category_Picklist__c, ' +
                       'Ori_Plast_Product__r.Category_Picklist__c, Unit_of_Measure__c, Quantity__c, ' +
                       'Final_Price__c ' +
                       'FROM Invoice_Line_Item__c ' +
                       'WHERE Ori_Plast_Invoice__r.Distributor__c = :distributorId ' +
                       'AND Ori_Plast_Invoice__r.CreatedDate >= :startDate ' + 
                       'AND Ori_Plast_Invoice__r.CreatedDate <= :endDate ' +   // <-- NEW DATE FILTER
                       'ORDER BY Ori_Plast_Invoice__r.CreatedDate DESC';

        List<Invoice_Line_Item__c> rawItems = Database.query(query);

        // --- 3. Process Results (Mapping and Wrapper logic remains the same) ---
        invoiceLineItems = new List<WrapperLineItem>();
        for (Invoice_Line_Item__c line : rawItems) {
            String categoryLabel = getPicklistLabelByApiName(line.Ori_Plast_Product__r.Category_Picklist__c);
            invoiceLineItems.add(new WrapperLineItem(line, categoryLabel));
        }
    }
    
    // Helper: Convert picklist API value → Label (No change)
    private static String getPicklistLabelByApiName(String apiName) {
        if (String.isBlank(apiName)) return '';
        Schema.DescribeFieldResult fieldResult = OriPlast_Product__c.Category_Picklist__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.getValue() == apiName) return entry.getLabel();
        }
        return apiName; // fallback
    }
    
    // Wrapper class (No change)
    public class WrapperLineItem {
        public Invoice_Line_Item__c line { get; set; }
        public String categoryLabel { get; set; }
        
        public WrapperLineItem(Invoice_Line_Item__c l, String label) {
            line = l;
            categoryLabel = label;
        }
    }
}*/
/*
@Date-- 12/11/2025
@Description-- Controller for InvoiceCSVExport VF Page (WEEKLY ONLY)
@Last Modified By-- Ayantika Chakraborty
@Last Modified Date--12/11/2025
*/
public with sharing class InvoiceCSVExportController {
    
    public List<WrapperLineItem> invoiceLineItems { get; set; }
    
    public InvoiceCSVExportController() {
        
        Id distributorId = ApexPages.currentPage().getParameters().get('distributorId');
        String reportType = ApexPages.currentPage().getParameters().get('reportType');  // Now only 'Weekly'
        
        // --- 1. Determine Date Range (WEEKLY ONLY) ---
        Date today = Date.today();
        Date startDate;
        Date endDate;

        if (reportType == 'Weekly') {
            startDate = today.toStartOfWeek();
            endDate   = startDate.addDays(6);
        } else {
            System.debug('Invalid reportType (only Weekly supported now): ' + reportType);
            invoiceLineItems = new List<WrapperLineItem>();
            return;
        }

        // --- 2. Dynamic SOQL Query (Weekly Only Filter) ---
        String query = 
            'SELECT Name, Invoice_No__c, Ori_Plast_Invoice__r.Invoice_Number__c, ' +
            'Ori_Plast_Invoice__r.Name, Ori_Plast_Invoice__r.Invoice_Date__c, ' +
            'Ori_Plast_Invoice__r.CreatedDate, Ori_Plast_Invoice__r.Distributor__r.Name, ' +
            'Ori_Plast_Invoice__r.Dealer_Name__c, Ori_Plast_Product_Name__c, SKU__c, ' +
            'Ori_Plast_Product__r.Sub_Category_Picklist__c, ' +
            'Ori_Plast_Product__r.Category_Picklist__c, Unit_of_Measure__c, Quantity__c, ' +
            'Final_Price__c ' +
            'FROM Invoice_Line_Item__c ' +
            'WHERE Ori_Plast_Invoice__r.Distributor__c = :distributorId ' +
            'AND Ori_Plast_Invoice__r.CreatedDate >= :startDate ' +
            'AND Ori_Plast_Invoice__r.CreatedDate <= :endDate ' +
            'ORDER BY Ori_Plast_Invoice__r.CreatedDate DESC';

        List<Invoice_Line_Item__c> rawItems = Database.query(query);

        // --- 3. Process Results ---
        invoiceLineItems = new List<WrapperLineItem>();
        
        for (Invoice_Line_Item__c line : rawItems) {
            
            // Convert category picklist API value → User-facing label
            String categoryLabel = getPicklistLabelByApiName(line.Ori_Plast_Product__r.Category_Picklist__c);
            
            invoiceLineItems.add(new WrapperLineItem(line, categoryLabel));
        }
    }
    
    // Helper: Convert picklist API value to label
    private static String getPicklistLabelByApiName(String apiName) {
        if (String.isBlank(apiName)) return '';
        
        Schema.DescribeFieldResult fieldResult = OriPlast_Product__c.Category_Picklist__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.getValue() == apiName) return entry.getLabel();
        }
        return apiName; // fallback
    }
    
    // Wrapper class
    public class WrapperLineItem {
        public Invoice_Line_Item__c line { get; set; }
        public String categoryLabel { get; set; }
        
        public WrapperLineItem(Invoice_Line_Item__c l, String label) {
            line = l;
            categoryLabel = label;
        }
    }
}