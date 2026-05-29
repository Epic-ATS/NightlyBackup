public class ShiftPushEventBatcher {

    @TestVisible
    static final String FACILITY_PLACEHOLDER = '{Facility}';

    public class FlowInput {
        @InvocableVariable(label='Shift ID' required=true)
        public Id shiftId;
        @InvocableVariable(label='Notification Title' required=true)
        public String title;
        @InvocableVariable(label='Single Item Body Template' required=true)
        public String singleBody;
        @InvocableVariable(label='App Target Link' required=true)
        public String targetLink;
    }

    @InvocableMethod(
        label='Publish Batched Push Event'
        description='Groups shifts by Contact and fires Platform Events'
    )
    public static void publishPushEvents(List<FlowInput> requests) {
        if (requests == null || requests.isEmpty()) return;
        List<X3B_Push_Notification_Event__e> eventsToPublish = buildEvents(requests);
        if (eventsToPublish.isEmpty()) return;
        List<Database.SaveResult> results = publishEvents(eventsToPublish);
    }

    @TestVisible
    static List<X3B_Push_Notification_Event__e> buildEvents(List<FlowInput> requests) {
        if (requests == null || requests.isEmpty()) return new List<X3B_Push_Notification_Event__e>();

        String notifTitle = requests[0].title;
        String singleBodyTemplate = requests[0].singleBody;
        String appLink = requests[0].targetLink;

        Set<Id> shiftIds = new Set<Id>();
        for (FlowInput req : requests) {
            if (req != null && req.shiftId != null) shiftIds.add(req.shiftId);
        }
        if (shiftIds.isEmpty()) return new List<X3B_Push_Notification_Event__e>();

        List<b3s__Shift__c> shifts = ShiftSelector.getInstance().selectForShiftPush(shiftIds);
        if (shifts.isEmpty()) return new List<X3B_Push_Notification_Event__e>();

        Map<Id, List<b3s__Shift__c>> shiftsByContact = new Map<Id, List<b3s__Shift__c>>();
        for (b3s__Shift__c s : shifts) {
            if (s.b3s__Contact__c == null) continue;
            if (!shiftsByContact.containsKey(s.b3s__Contact__c)) {
                shiftsByContact.put(s.b3s__Contact__c, new List<b3s__Shift__c>());
            }
            shiftsByContact.get(s.b3s__Contact__c).add(s);
        }
        if (shiftsByContact.isEmpty()) return new List<X3B_Push_Notification_Event__e>();

        List<X3B_Push_Notification_Event__e> eventsToPublish = new List<X3B_Push_Notification_Event__e>();
        for (Id contactId : shiftsByContact.keySet()) {
            List<b3s__Shift__c> contactShifts = shiftsByContact.get(contactId);
            if (contactShifts == null || contactShifts.isEmpty()) continue;

            X3B_Push_Notification_Event__e evt = new X3B_Push_Notification_Event__e();
            evt.User_Id__c = contactId;
            evt.Title__c = notifTitle;
            evt.Target_Link__c = appLink;

            if (contactShifts.size() == 1) {
                b3s__Shift__c one = contactShifts[0];
                String facilityName = 'a facility';
                if (one.b3s__Site__r != null && !String.isBlank(one.b3s__Site__r.Name)) {
                    facilityName = one.b3s__Site__r.Name;
                }
                evt.Body__c = safe(singleBodyTemplate).replace(FACILITY_PLACEHOLDER, facilityName);
            } else {
                evt.Body__c = 'You have ' + contactShifts.size() + ' shift updates.';
            }
            eventsToPublish.add(evt);
        }
        return eventsToPublish;
    }

    @TestVisible
    static List<Database.SaveResult> publishEvents(List<X3B_Push_Notification_Event__e> eventsToPublish) {
        if (eventsToPublish == null || eventsToPublish.isEmpty()) return new List<Database.SaveResult>();
        return EventBus.publish(eventsToPublish);
    }

    private static String safe(String s) {
        return s == null ? '' : s;
    }
}