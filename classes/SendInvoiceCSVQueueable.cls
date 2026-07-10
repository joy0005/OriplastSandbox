/*public class SendInvoiceCSVQueueable implements Queueable, Database.AllowsCallouts {
    
    Map<Id, Map<Id, List<Invoice__c>>> weekData;
    Map<Id, Map<Id, List<Invoice__c>>> monthData;

    public SendInvoiceCSVQueueable(
        Map<Id, Map<Id, List<Invoice__c>>> weekData,
        Map<Id, Map<Id, List<Invoice__c>>> monthData
    ) {
        this.weekData = weekData;
        this.monthData = monthData;
    }

    public void execute(QueueableContext context) {
        SendInvoiceCSVToDistributor.sendInvoiceReports(weekData, monthData);
    }
}*/
public class SendInvoiceCSVQueueable implements Queueable, Database.AllowsCallouts {
    
    Map<Id, Map<Id, List<Invoice__c>>> weekData;

    // MONTHLY REMOVED
    // Map<Id, Map<Id, List<Invoice__c>>> monthData;

    public SendInvoiceCSVQueueable(
        Map<Id, Map<Id, List<Invoice__c>>> weekData
        // , Map<Id, Map<Id, List<Invoice__c>>> monthData  // removed
    ) {
        this.weekData = weekData;
        // this.monthData = monthData; // removed
    }

    public void execute(QueueableContext context) {
        // Weekly only
        SendInvoiceCSVToDistributor.sendInvoiceReports(weekData);

        // Previously:
        // SendInvoiceCSVToDistributor.sendInvoiceReports(weekData, monthData);
    }
}