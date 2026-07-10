/* @Date-- 09/12/2025
@Description-- The weekly & monthly invoice email process every Saturday at 10:00 AM.
@Last Modified By-- Ayantika Chakraborty
@Last Modified Date--09/12/2025 */
public with sharing class SendSecondarySalesReportToDistributor {

    @TestVisible private static final String CURRENT_MONTH_REPORT_ID = System.Label.CURRENT_MONTH_REPORT_ID;
    @TestVisible private static final String CURRENT_WEEK_REPORT_ID  = System.Label.CURRENT_WEEK_REPORT_ID;

    public static void sendWeeklyReportLinks() {

        List<User> distributors = [
            SELECT Id, Name, Email
            FROM User
            WHERE IsActive = true
            AND Profile.Name = 'Distributor'
        ];

        if (distributors.isEmpty()) {
            return;
        }

        // Use prod Lightning base URL from custom label
        //String baseUrl = System.Label.Prod_Lightning_Base_URL;
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();

        String monthReportUrl = baseUrl +
            '/lightning/r/Report/' + CURRENT_MONTH_REPORT_ID + '/view?queryScope=userFolders';

        String weekReportUrl = baseUrl +
            '/lightning/r/Report/' + CURRENT_WEEK_REPORT_ID + '/view?queryScope=userFolders';

        Date today = Date.today();
        DateTime todayDt = DateTime.newInstance(today, Time.newInstance(0, 0, 0, 0));
        String monthLabel = todayDt.format('MMMM yyyy');
        String weekEnding = todayDt.format('dd-MMM-yyyy');

        //CC email list (declared once)
        List<String> ccEmails = new List<String>{
            'amanna@oriplast.in',
            'spodder@oriplast.in',
            'anupbrata@gmail.com',
            'alokdalai@oriplast.in',
            'ayantika_c@pursuitsoftware.com',
            'saikat.paul@halsaglobal.io'
        };

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        for (User u : distributors) {
            if (String.isBlank(u.Email)) {
                continue;
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { u.Email });
            mail.setCcAddresses(ccEmails);

            mail.setSubject(
                'Secondary Sales Reports - ' + monthLabel +
                ' | Week Ending ' + weekEnding
            );

            String htmlBody =
                '<html>' +
                '<body style="font-family:Arial, sans-serif; font-size:14px; color:#333; background-color:#f7f7f7; padding:20px;">' +
                    '<div style="max-width:600px; margin:0 auto; background:#ffffff; border-radius:8px; border:1px solid #e0e0e0; padding:20px;">' +
                        '<h2 style="color:#004a8f; text-align:center; margin-top:0;">Secondary Sales Performance</h2>' +
                        '<p>Hello <b>' + u.Name + '</b>,</p>' +
                        '<p>Please find your latest Secondary Sales reports for <b>' + monthLabel +
                        '</b> and the week ending <b>' + weekEnding + '</b>:</p>' +
                        '<table style="width:100%; border-collapse:collapse; margin-top:10px;">' +
                            '<tr>' +
                                '<th style="text-align:left; padding:8px; border-bottom:1px solid #e0e0e0;">Report Name</th>' +
                                '<th style="text-align:left; padding:8px; border-bottom:1px solid #e0e0e0;">Link</th>' +
                            '</tr>' +
                            '<tr>' +
                                '<td style="padding:8px; border-bottom:1px solid #f0f0f0;">Secondary Sales Report - Current Month</td>' +
                                '<td style="padding:8px; border-bottom:1px solid #f0f0f0;">' +
                                    '<a href="' + monthReportUrl + '" ' +
                                       'style="display:inline-block; padding:6px 12px; background-color:#004a8f; color:#ffffff; text-decoration:none; border-radius:4px; font-size:13px;">' +
                                        'View Month Report' +
                                    '</a>' +
                                '</td>' +
                            '</tr>' +
                            '<tr>' +
                                '<td style="padding:8px;">Secondary Sales Report - Current Week</td>' +
                                '<td style="padding:8px;">' +
                                    '<a href="' + weekReportUrl + '" ' +
                                       'style="display:inline-block; padding:6px 12px; background-color:#0070d2; color:#ffffff; text-decoration:none; border-radius:4px; font-size:13px;">' +
                                        'View Week Report' +
                                    '</a>' +
                                '</td>' +
                            '</tr>' +
                        '</table>' +
                        '<p style="margin-top:18px;">You can use these reports to review your secondary sales performance and reconcile with your internal records.</p>' +
                        '<p style="margin-top:20px;">Best Regards,<br/><b>Salesforce System</b></p>' +
                        '<hr style="border:0; border-top:1px solid #e0e0e0; margin:20px 0;"/>' +
                        '<p style="font-size:12px; color:#777; text-align:center;">' +
                            'This is a system-generated email. Please do not reply to this message.' +
                        '</p>' +
                    '</div>' +
                '</body>' +
                '</html>';

            mail.setHtmlBody(htmlBody);
            mails.add(mail);
        }

        if (!mails.isEmpty()) {
            Messaging.sendEmail(mails, false);
        }
    }
}