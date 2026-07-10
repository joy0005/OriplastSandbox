// --------------------- NEW CLASS: InvoiceCSVService.cls ---------------------
public class InvoiceCSVService {

    public static Blob generateWeeklyCSV(Id distributorId) {

        Date today = Date.today();
        Date startDate = today.toStartOfWeek();
        Date endDate   = startDate.addDays(6);

        List<Invoice_Line_Item__c> rawItems = [
            SELECT Name, Invoice_No__c, Ori_Plast_Invoice__r.Invoice_Number__c,
                   Ori_Plast_Invoice__r.Name, Ori_Plast_Invoice__r.Invoice_Date__c,
                   Ori_Plast_Invoice__r.CreatedDate, Ori_Plast_Invoice__r.Distributor__r.Name,
                   Ori_Plast_Invoice__r.Dealer_Name__c, Ori_Plast_Product_Name__c, SKU__c,
                   Ori_Plast_Product__r.Sub_Category_Picklist__c,
                   Ori_Plast_Product__r.Category_Picklist__c, Unit_of_Measure__c,
                   Quantity__c, Final_Price__c
            FROM Invoice_Line_Item__c
            WHERE Ori_Plast_Invoice__r.Distributor__c = :distributorId
            AND Ori_Plast_Invoice__r.CreatedDate >= :startDate
            AND Ori_Plast_Invoice__r.CreatedDate <= :endDate
            ORDER BY Ori_Plast_Invoice__r.CreatedDate DESC
            LIMIT 45000
        ];

        // Fully compatible String builder technique
        String csv = '';

        // Header
        csv += 'Invoice Number,Invoice Name,Invoice Line Item No,Invoice Date,Created Date,Distributor,Dealer Name,Product,SKU,Category,Quantity,Unit of Measure,Final Price\n';

        if (rawItems.isEmpty()) {
            return Blob.valueOf(csv);
        }

        Map<String, String> categoryLabelMap = buildCategoryLabelMap();

        for (Invoice_Line_Item__c line : rawItems) {

            String categoryLabel = categoryLabelMap.get(line.Ori_Plast_Product__r.Category_Picklist__c);

            csv += sanitize(line.Ori_Plast_Invoice__r.Invoice_Number__c) + ',';
            csv += sanitize(line.Ori_Plast_Invoice__r.Name) + ',';
            csv += sanitize(line.Name) + ',';
            csv += sanitize(String.valueOf(line.Ori_Plast_Invoice__r.Invoice_Date__c)) + ',';
            csv += sanitize(String.valueOf(line.Ori_Plast_Invoice__r.CreatedDate)) + ',';
            csv += sanitize(line.Ori_Plast_Invoice__r.Distributor__r.Name) + ',';
            csv += sanitize(line.Ori_Plast_Invoice__r.Dealer_Name__c) + ',';
            csv += sanitize(line.Ori_Plast_Product_Name__c) + ',';
            csv += sanitize(line.SKU__c) + ',';
            csv += sanitize(categoryLabel) + ',';
            csv += sanitize(String.valueOf(line.Quantity__c)) + ',';
            csv += sanitize(line.Unit_of_Measure__c) + ',';
            csv += sanitize(String.valueOf(line.Final_Price__c)) + '\n';
        }

        return Blob.valueOf(csv);
    }

    private static Map<String, String> buildCategoryLabelMap() {
        Map<String, String> mapLabels = new Map<String, String>();
        Schema.DescribeFieldResult d = OriPlast_Product__c.Category_Picklist__c.getDescribe();

        for (Schema.PicklistEntry entry : d.getPicklistValues()) {
            mapLabels.put(entry.getValue(), entry.getLabel());
        }
        return mapLabels;
    }

    private static String sanitize(String input) {
        if (input == null) return '';
        String val = input.replace(',', ' ');
        return val.replace('\n', ' ').replace('\r', ' ');
    }
}