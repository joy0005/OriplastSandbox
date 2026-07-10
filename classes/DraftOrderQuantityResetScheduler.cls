global with sharing class DraftOrderQuantityResetScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        // Execute batch with a scope size of 200 records.
        Database.executeBatch(
            new DraftOrderQuantityResetBatch(),
            200
        );
    }
}