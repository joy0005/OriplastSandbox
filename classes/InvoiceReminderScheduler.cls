global with sharing class InvoiceReminderScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        InvoiceReminderService.sendInvoiceReminders();
    }
}