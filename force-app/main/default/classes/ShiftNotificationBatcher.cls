public class ShiftNotificationBatcher {

    private static final String PORTAL_PATH = '/onboarding/b3p__Portal#CandidateApp';

    private static final String TABLE_HEADER =
        '<table border="1" style="border-collapse: collapse; width: 100%; text-align: left;">' +
        '<tr style="background-color: #f2f2f2;">' +
        '<th style="padding: 8px;">Start Time</th>' +
        '<th style="padding: 8px;">End Time</th>' +
        '<th style="padding: 8px;">Facility</th>' +
        '<th style="padding: 8px;">Job</th>' +
        '<th style="padding: 8px;">Notes</th>' +
        '</tr>';

    public class FlowInput {
        @InvocableVariable(label='Shift ID' required=true)
        public Id shiftId;

        @InvocableVariable(label='Email Subject' required=true)
        public String emailSubject;

        @InvocableVariable(label='Email Intro Text' required=true description='The first sentence of the email body.')
        public String introText;
    }

    @InvocableMethod(label='Send Batched Shift Emails' description='Sends consolidated emails with dynamic text')
    public static void sendConsolidatedEmail(List<FlowInput> requests) {

        if (requests == null || requests.isEmpty()) return;

        Set<Id> shiftIds = new Set<Id>();
        for (FlowInput req : requests) {
            if (req != null && req.shiftId != null) shiftIds.add(req.shiftId);
        }
        if (shiftIds.isEmpty()) return;

        // Assume same subject/intro per invocable execution.
        String subjectLine = requests[0].emailSubject;
        String introBody   = requests[0].introText;

        // Query via selector
        List<b3s__Shift__c> shifts = ShiftSelector.getInstance().selectForShiftEmail(shiftIds);
        if (shifts.isEmpty()) return;

        // Group by contact (keep list: needed for building the table)
        Map<Id, List<b3s__Shift__c>> shiftsByContact = new Map<Id, List<b3s__Shift__c>>();
        for (b3s__Shift__c s : shifts) {
            if (s.b3s__Contact__c == null) continue;
            if (!shiftsByContact.containsKey(s.b3s__Contact__c)) {
                shiftsByContact.put(s.b3s__Contact__c, new List<b3s__Shift__c>());
            }
            shiftsByContact.get(s.b3s__Contact__c).add(s);
        }
        if (shiftsByContact.isEmpty()) return;

        String senderName = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

        String portalUrl = URL.getOrgDomainUrl().toExternalForm() + PORTAL_PATH;

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Id contactId : shiftsByContact.keySet()) {
            List<b3s__Shift__c> contactShifts = shiftsByContact.get(contactId);
            if (contactShifts == null || contactShifts.isEmpty()) continue;

            // Deterministic "first" because selector orders by contact + start time + id
            b3s__Shift__c firstShift = contactShifts[0];
            if (firstShift.b3s__Contact__r == null || String.isBlank(firstShift.b3s__Contact__r.Email)) continue;

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ firstShift.b3s__Contact__r.Email });
            mail.setSubject(subjectLine);

            String htmlBody =
                'Hi ' + safe(firstShift.b3s__Contact__r.FirstName) + ' ' + safe(firstShift.b3s__Contact__r.LastName) + ',<br/><br/>' +
                safe(introBody) + '<br/><br/>' +
                TABLE_HEADER;

            for (b3s__Shift__c s : contactShifts) {
                String startDt = (s.b3s__Scheduled_Start_Time__c != null)
                    ? s.b3s__Scheduled_Start_Time__c.format('MM/dd/yyyy h:mm a')
                    : '';
                String endDt = (s.b3s__Scheduled_End_Time__c != null)
                    ? s.b3s__Scheduled_End_Time__c.format('MM/dd/yyyy h:mm a')
                    : '';

                String siteName = (s.b3s__Site__r != null) ? safe(s.b3s__Site__r.Name) : '';
                String siteAddr = (s.b3s__Site__r != null) ? safe(s.b3s__Site__r.b3o__Full_Address__c) : '';
                String facilityInfo = (siteName + ' ' + siteAddr).trim();

                String jobTypeName = '';
                if (s.b3s__Job__r != null && s.b3s__Job__r.b3o__Job_Type__r != null) {
                    jobTypeName = safe(s.b3s__Job__r.b3o__Job_Type__r.Name);
                }

                String notes = safe(s.b3_Facility_Notes__c);

                htmlBody +=
                    '<tr>' +
                    '<td style="padding: 8px;">' + startDt + '</td>' +
                    '<td style="padding: 8px;">' + endDt + '</td>' +
                    '<td style="padding: 8px;">' + facilityInfo + '</td>' +
                    '<td style="padding: 8px;">' + jobTypeName + '</td>' +
                    '<td style="padding: 8px;">' + notes + '</td>' +
                    '</tr>';
            }

            htmlBody +=
                '</table><br/>' +
                'Click <a href="' + portalUrl + '">HERE</a> to access your Portal.<br/><br/>' +
                'Kind regards,<br/>' +
                senderName;

            mail.setHtmlBody(htmlBody);
            emailsToSend.add(mail);
        }

        if (emailsToSend.isEmpty()) return;

        try {
            Messaging.sendEmail(emailsToSend);
        } catch (Exception e) {
            throw e;
        }
    }

    private static String safe(String s) {
        return s == null ? '' : s;
    }
}