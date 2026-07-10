/* @Date-- 12/11/2025
@Description-- The weekly invoice email process every Saturday at 10:00 AM.
@Last Modified By-- Ayantika Chakraborty
@Last Modified Date--09/12/2025 */

global with sharing class SecondarySalesReportScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        SendSecondarySalesReportToDistributor.sendWeeklyReportLinks();
    }
}
/*
System.schedule(
    'Weekly Distributor Secondary Sales Reports',
    '0 0 10 ? * SAT',
    new SecondarySalesReportScheduler()
);
*/