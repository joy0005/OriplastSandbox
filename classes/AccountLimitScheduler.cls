global class AccountLimitScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new AccountLimitResetBatch(), 200);
    }
}