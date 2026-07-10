/*
@Date-- 12/11/2025 (Created)
@Description-- Batch class to retrieve all distributors and their current week invoices,
and send weekly invoice reports in CSV format via email.
    @Last Modified By-- Ayantika Chakraborty
@Last Modified Date--13/11/2025 */

/*public class InvoiceReportBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    Map<Id, User> distributorUsersMap = new Map<Id, User>();
    Map<Id, Id> accountToUserMap = new Map<Id, Id>();
    
    public Map<Id, Map<Id, List<Invoice__c>>> allWeeklyInvoices = new Map<Id, Map<Id, List<Invoice__c>>>();
    public Map<Id, Map<Id, List<Invoice__c>>> allMonthlyInvoices = new Map<Id, Map<Id, List<Invoice__c>>>();
    
    
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        // 1. All Distributor Users
        List<User> distributorUsers = [
            SELECT Id, Name, Email
            FROM User
            WHERE Profile.Name = 'Distributor'
            AND IsActive = true
        ];
        for (User u : distributorUsers) {
            distributorUsersMap.put(u.Id, u);
        }
        List<Account> distributorAccounts = [
            SELECT Id, Associated_User__c
            FROM Account
            WHERE Associated_User__c IN :distributorUsersMap.keySet()
        ];
        for (Account acc : distributorAccounts){
            if (acc.Associated_User__c != null) {
                accountToUserMap.put(acc.Id, acc.Associated_User__c);
            }
        }
        
        // 3. Return QueryLocator for Invoice__c (THE MOST IMPORTANT FIX)
        return Database.getQueryLocator([
            SELECT Id, Name, Distributor__c, CreatedDate, Invoice_Date_Formatted__c
            FROM Invoice__c
            WHERE Distributor__c IN :accountToUserMap.keySet()
            AND CreatedDate = LAST_N_DAYS:30
            ORDER BY CreatedDate DESC
        ]);
    }
    
    // ---------------------------------------------------------
    // EXECUTE
    // ---------------------------------------------------------
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        
        List<Invoice__c> invoices = (List<Invoice__c>) scope;
        
        // Temp maps for this batch chunk
        Map<Id, Map<Id, List<Invoice__c>>> weeklyMap  = new Map<Id, Map<Id, List<Invoice__c>>>();
        Map<Id, Map<Id, List<Invoice__c>>> monthlyMap = new Map<Id, Map<Id, List<Invoice__c>>>();
        
        Date today = Date.today();
        // Date today = Date.newInstance(2025, 3, 10);
        
        // Weekly range
        Date startOfWeek = today.toStartOfWeek();
        Date endOfWeek   = startOfWeek.addDays(6);
        
        // Monthly range
        Date startOfMonth = today.toStartOfMonth();
        Date endOfMonth   = startOfMonth.addMonths(1).addDays(-1);
        
        
        // Process each invoice in the scope
        for (Invoice__c inv : invoices) {
            
            Id distAccId = inv.Distributor__c;
            Id userId = accountToUserMap.get(distAccId);
            if (userId == null) continue;
            
            // Weekly - weeklyMap[userId][distributorAccount].add(invoice)
            collectInvoice(inv, userId, distAccId, weeklyMap, startOfWeek, endOfWeek);
            // Monthly
            collectInvoice(inv, userId, distAccId, monthlyMap, startOfMonth, endOfMonth);
        }
        
        // Merge chunk into global stateful maps
        mergeInvoiceMaps(allWeeklyInvoices, weeklyMap);
        mergeInvoiceMaps(allMonthlyInvoices, monthlyMap);
    }
    
    
    // ---------------------------------------------------------
    // FINISH: Runs ONLY once (no more infinite repeats)
    // ---------------------------------------------------------
    public void finish(Database.BatchableContext bc) {
        
        System.debug('✔ Batch Completed. Preparing final Queueable job.');
        
        // Only queue if we have some data
        if (!allWeeklyInvoices.isEmpty() || !allMonthlyInvoices.isEmpty()) {
            System.enqueueJob(
                new SendInvoiceCSVQueueable(allWeeklyInvoices, allMonthlyInvoices)
                );
        }
    }
    
    
    // ---------------------------------------------------------
    // HELPER METHODS
    // ---------------------------------------------------------
    private void collectInvoice(Invoice__c inv,Id userId,Id distAccId,Map<Id, Map<Id, List<Invoice__c>>> mapToUpdate,Date startDate,Date endDate) {
        Date created = inv.CreatedDate.date();
        if (created < startDate || created > endDate) return;
        // Date invoiceDate = inv.Invoice_Date_Formatted__c;
        // if (invoiceDate < startDate || invoiceDate > endDate) return;
        
        
        if (!mapToUpdate.containsKey(userId)) {
            mapToUpdate.put(userId, new Map<Id, List<Invoice__c>>());
        }
        
        Map<Id, List<Invoice__c>> distMap = mapToUpdate.get(userId);
        
        if (!distMap.containsKey(distAccId)) {
            distMap.put(distAccId, new List<Invoice__c>());
        }
        
        distMap.get(distAccId).add(inv);
    }
    
    
    private void mergeInvoiceMaps(Map<Id, Map<Id, List<Invoice__c>>> globalMap,Map<Id, Map<Id, List<Invoice__c>>> chunkMap) {
        for (Id userId : chunkMap.keySet()) {
            
            if (!globalMap.containsKey(userId)) {
                globalMap.put(userId, new Map<Id, List<Invoice__c>>());
            }
            
            Map<Id, List<Invoice__c>> globalDist = globalMap.get(userId);
            Map<Id, List<Invoice__c>> chunkDist  = chunkMap.get(userId);
            
            for (Id accId : chunkDist.keySet()) {
                
                if (!globalDist.containsKey(accId)) {
                    globalDist.put(accId, new List<Invoice__c>());
                }
                
                globalDist.get(accId).addAll(chunkDist.get(accId));
            }
        }
    }
}*/
/*
@Date-- 12/11/2025 (Created)
@Description-- Batch class to retrieve all distributors and their current week invoices,
and send weekly invoice reports in CSV format via email.
    @Last Modified By-- Ayantika Chakraborty
@Last Modified Date--13/11/2025
 */

public class InvoiceReportBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    Map<Id, User> distributorUsersMap = new Map<Id, User>();
    Map<Id, Id> accountToUserMap = new Map<Id, Id>();
    
    // WEEKLY ONLY
    public Map<Id, Map<Id, List<Invoice__c>>> allWeeklyInvoices = new Map<Id, Map<Id, List<Invoice__c>>>();
    
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        // 1. All Distributor Users
        List<User> distributorUsers = [
            SELECT Id, Name, Email
            FROM User
            WHERE Profile.Name = 'Distributor'
            AND IsActive = true
        ];
        for (User u : distributorUsers) {
            distributorUsersMap.put(u.Id, u);
        }
        
        // 2. Get Distributor Accounts
        List<Account> distributorAccounts = [
            SELECT Id, Associated_User__c
            FROM Account
            WHERE Associated_User__c IN :distributorUsersMap.keySet()
        ];
        for (Account acc : distributorAccounts) {
            if (acc.Associated_User__c != null) {
                accountToUserMap.put(acc.Id, acc.Associated_User__c);
            }
        }
        
        // // 3. Query invoices from last 30 days
        // return Database.getQueryLocator([
        //     SELECT Id, Name, Distributor__c, CreatedDate, Invoice_Date_Formatted__c
        //     FROM Invoice__c
        //     WHERE Distributor__c IN :accountToUserMap.keySet()
        //     AND CreatedDate = LAST_N_DAYS:30
        //     ORDER BY CreatedDate DESC
        // ]);
        return Database.getQueryLocator([SELECT Id, Name, Distributor__c, CreatedDate, Invoice_Date_Formatted__c FROM Invoice__c WHERE Distributor__c IN :accountToUserMap.keySet() 
        AND CreatedDate = THIS_WEEK
        ORDER BY CreatedDate DESC
        ]);
        
    }
    
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        
        List<Invoice__c> invoices = (List<Invoice__c>) scope;
        
        // Temporary weekly map for this batch chunk
        Map<Id, Map<Id, List<Invoice__c>>> weeklyMap  = new Map<Id, Map<Id, List<Invoice__c>>>();
        
        // Monthly removed
        // Map<Id, Map<Id, List<Invoice__c>>> monthlyMap = new Map<Id, Map<Id, List<Invoice__c>>>();
        
        Date today = Date.today();
        
        // Weekly range
        Date startOfWeek = today.toStartOfWeek();
        Date endOfWeek   = startOfWeek.addDays(6);
        
        // Monthly removed
        // Date startOfMonth = today.toStartOfMonth();
        // Date endOfMonth   = startOfMonth.addMonths(1).addDays(-1);
        
        
        // Process invoices
        for (Invoice__c inv : invoices) {
            
            Id distAccId = inv.Distributor__c;
            Id userId = accountToUserMap.get(distAccId);
            if (userId == null) continue;
            
            // Weekly only
            collectInvoice(inv, userId, distAccId, weeklyMap, startOfWeek, endOfWeek);
            
            // Monthly removed
            // collectInvoice(inv, userId, distAccId, monthlyMap, startOfMonth, endOfMonth);
        }
        
        // Merge weekly only
        mergeInvoiceMaps(allWeeklyInvoices, weeklyMap);
        
        // Monthly removed
        // mergeInvoiceMaps(allMonthlyInvoices, monthlyMap);
    }
    
    
    public void finish(Database.BatchableContext bc) {
        
        System.debug('✔ Batch Completed. Preparing final Queueable job.');
        
        // Only queue if weekly data exists
        if (!allWeeklyInvoices.isEmpty()) {
            System.enqueueJob(
                new SendInvoiceCSVQueueable(allWeeklyInvoices /*, allMonthlyInvoices removed*/)
                );
        }
    }
    
    
    // -------------------------
    // Helper methods
    // -------------------------
    private void collectInvoice(
        Invoice__c inv,
    Id userId,
    Id distAccId,
    Map<Id, Map<Id, List<Invoice__c>>> mapToUpdate,
    Date startDate,
    Date endDate
    ) {
        Date created = inv.CreatedDate.date();
        if (created < startDate || created > endDate) return;
        
        if (!mapToUpdate.containsKey(userId)) {
            mapToUpdate.put(userId, new Map<Id, List<Invoice__c>>());
        }
        
        Map<Id, List<Invoice__c>> distMap = mapToUpdate.get(userId);
        
        if (!distMap.containsKey(distAccId)) {
            distMap.put(distAccId, new List<Invoice__c>());
        }
        
        distMap.get(distAccId).add(inv);
    }
    
    
    private void mergeInvoiceMaps(
        Map<Id, Map<Id, List<Invoice__c>>> globalMap,
    Map<Id, Map<Id, List<Invoice__c>>> chunkMap
    ) {
        for (Id userId : chunkMap.keySet()) {
            
            if (!globalMap.containsKey(userId)) {
                globalMap.put(userId, new Map<Id, List<Invoice__c>>());
            }
            
            Map<Id, List<Invoice__c>> globalDist = globalMap.get(userId);
            Map<Id, List<Invoice__c>> chunkDist  = chunkMap.get(userId);
            
            for (Id accId : chunkDist.keySet()) {
                
                if (!globalDist.containsKey(accId)) {
                    globalDist.put(accId, new List<Invoice__c>());
                }
                
                globalDist.get(accId).addAll(chunkDist.get(accId));
            }
        }
    }
}