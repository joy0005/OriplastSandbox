/*
@Date-- 12/11/2025
@Description-- Retrieves all distributors and their current week invoices. It groups them by user and distributor, returning a map used to send weekly invoice reports.
@Last Modified By-- Ayantika Chakraborty
@Last Modified Date--12/11/2025 
*/
public class SendMailToDistributor {
    
    public static List<Account> getDistributorAccounts() {
        List<User> distributorUsers = [
            SELECT Id, Name, Profile.Name 
            FROM User 
            WHERE Profile.Name = 'Distributor'
            AND IsActive = true
        ];
        
        Set<Id> distributorUserIds = new Set<Id>();
        for (User u : distributorUsers) {
            distributorUserIds.add(u.Id);
        }
        
        List<Account> distributorAccounts = new List<Account>();
        if (!distributorUserIds.isEmpty()) {
            distributorAccounts = [
                SELECT Id, Name, Associated_User__c
                FROM Account
                WHERE Associated_User__c IN :distributorUserIds
            ];
        }
        
        System.debug('Total Distributor Users Found: ' + distributorUserIds.size());
        System.debug('Total Distributor Accounts Found: ' + distributorAccounts.size());
        
        return distributorAccounts;
    }
    
    // Collect current week invoices grouped by User -> Distributor
    public static Map<Id, Map<Id, List<Invoice__c>>> getCurrentWeekInvoices(List<Account> distributorAccounts) {
        if (distributorAccounts.isEmpty()) {
            System.debug('No distributor accounts provided to process.');
            return new Map<Id, Map<Id, List<Invoice__c>>>();
        }
        
        // Collect Distributor Account IDs and build a helper map to find the User
        Set<Id> distributorAccIds = new Set<Id>();
        Map<Id, Id> accountToUserMap = new Map<Id, Id>();
        for (Account acc : distributorAccounts) {
            distributorAccIds.add(acc.Id);
            if (acc.Associated_User__c != null) {
                accountToUserMap.put(acc.Id, acc.Associated_User__c);
            }
        }
        
        // Define start and end of current week (Keep original date logic)
        Date today = Date.today();
        Date startOfWeek = today.toStartOfWeek();
        Date endOfWeek = startOfWeek.addDays(6);
        
        // Define start and end of current week
        // Date today = Date.newInstance(2025, 03, 01);
        // Date startOfWeek = today.toStartOfWeek();
        // Date endOfWeek = startOfWeek.addDays(6);
        
        // Query Invoices for current week and the accounts in the batch
        List<Invoice__c> invoiceList = [
            SELECT Id, Name, Distributor__c, CreatedDate, Invoice_Date_Formatted__c
            FROM Invoice__c
            WHERE Distributor__c IN :distributorAccIds
            AND CreatedDate >= :startOfWeek
            AND CreatedDate <= :endOfWeek
        ];
        System.debug('startOfWeek :-' + startOfWeek + ' endOfWeek :-' + endOfWeek);
        
        
        // Build nested map: User -> Distributor -> Invoices
        Map<Id, Map<Id, List<Invoice__c>>> userToDistributorMap = new Map<Id, Map<Id, List<Invoice__c>>>();
        
        // Group invoices by distributor and user
        for (Invoice__c inv : invoiceList) {
            Id distAccId = inv.Distributor__c;
            Id userId = accountToUserMap.get(distAccId);
            
            if (userId == null) continue;
            
            if (!userToDistributorMap.containsKey(userId)) {
                userToDistributorMap.put(userId, new Map<Id, List<Invoice__c>>());
            }
            
            Map<Id, List<Invoice__c>> distributorMap = userToDistributorMap.get(userId);
            
            if (!distributorMap.containsKey(distAccId)) {
                distributorMap.put(distAccId, new List<Invoice__c>());
            }
            
            distributorMap.get(distAccId).add(inv);
        }
        
        return userToDistributorMap;
    }

    // Step 2(month): Collect current month invoices grouped by User -> Distributor
    public static Map<Id, Map<Id, List<Invoice__c>>> getCurrentMonthInvoices(List<Account> distributorAccounts) {
        if (distributorAccounts.isEmpty()) {
            System.debug('No distributor accounts provided to process for monthly report.');
            return new Map<Id, Map<Id, List<Invoice__c>>>();
        }
        
        // Collect Distributor Account IDs and User mapping (same as weekly)
        Set<Id> distributorAccIds = new Set<Id>();
        Map<Id, Id> accountToUserMap = new Map<Id, Id>();
        for (Account acc : distributorAccounts) {
            distributorAccIds.add(acc.Id);
            if (acc.Associated_User__c != null) {
                accountToUserMap.put(acc.Id, acc.Associated_User__c);
                System.debug('Account Id  :-' + acc.Id + ' Associated_User Id :-' + acc.Associated_User__c);
            }
        }
        
        // --- Define start and end of CURRENT MONTH ---
        // Date today = Date.today();
        Date today = Date.newInstance(2025, 03, 01);
        Date startOfMonth = today.toStartOfMonth();
        Date endOfMonth = startOfMonth.addMonths(1).addDays(-1); 
        
        System.debug('startOfMonth :-' + startOfMonth + ' endOfMonth :-' + endOfMonth);
        
        // Query Invoices for current month and the accounts in the batch
        List<Invoice__c> invoiceList = [
            SELECT Id, Name, Distributor__c, Invoice_Date_Formatted__c , CreatedDate
            FROM Invoice__c
            WHERE Distributor__c IN :distributorAccIds
            AND CreatedDate >= :startOfMonth
            AND CreatedDate <= :endOfMonth
        ];
        
        // Build nested map: User -> Distributor -> Invoices (same grouping logic)
        Map<Id, Map<Id, List<Invoice__c>>> userToDistributorMap = new Map<Id, Map<Id, List<Invoice__c>>>();
        
        for (Invoice__c inv : invoiceList) {
            Id distAccId = inv.Distributor__c;
            Id userId = accountToUserMap.get(distAccId);
            
            if (userId == null) continue;
            
            if (!userToDistributorMap.containsKey(userId)) {
                userToDistributorMap.put(userId, new Map<Id, List<Invoice__c>>());
            }
            
            Map<Id, List<Invoice__c>> distributorMap = userToDistributorMap.get(userId);
            
            if (!distributorMap.containsKey(distAccId)) {
                distributorMap.put(distAccId, new List<Invoice__c>());
            }
            
            distributorMap.get(distAccId).add(inv);
        }
        
        return userToDistributorMap;
    }
}