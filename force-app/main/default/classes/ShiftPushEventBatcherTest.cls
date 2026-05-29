@IsTest
private class ShiftPushEventBatcherTest {

    @IsTest
    static void buildEvents_singleShift_usesTemplate() {
        List<Contact> contacts = (List<Contact>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            WfmTestFactory.buildContactNoEmail('Ada', 'Lovelace')
        });
        Contact c1 = contacts[0];

        b3o__Site__c site = (b3o__Site__c) WfmTestFactory.insertSObject(
            WfmTestFactory.buildSite('Athens Clinic', '1 Example St', 'Athens', '10557', 'Facility note')
        );

        List<b3s__Shift__c> shifts = (List<b3s__Shift__c>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            new b3s__Shift__c(b3s__Contact__c = c1.Id, b3s__Site__c = site.Id)
        });
        b3s__Shift__c s1 = shifts[0];

        List<ShiftPushEventBatcher.FlowInput> inputs = new List<ShiftPushEventBatcher.FlowInput>{
            WfmTestFactory.buildShiftPushInput(s1.Id, 'Shift Update', 'Your shift at ' + ShiftPushEventBatcher.FACILITY_PLACEHOLDER + ' has changed.', '/app/shifts')
        };

        List<X3B_Push_Notification_Event__e> evts = ShiftPushEventBatcher.buildEvents(inputs);

        System.assertEquals(1, evts.size(), 'One contact => one event.');
        System.assertEquals(c1.Id, (Id)evts[0].User_Id__c);
        System.assertEquals('Shift Update', evts[0].Title__c);
        System.assertEquals('/app/shifts', evts[0].Target_Link__c);
        System.assertEquals('Your shift at Athens Clinic has changed.', evts[0].Body__c);
    }

    @IsTest
    static void buildEvents_multipleShifts_sameContact_usesCountBody() {
        List<Contact> contacts = (List<Contact>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            WfmTestFactory.buildContactNoEmail('Ada', 'Lovelace')
        });
        Contact c1 = contacts[0];

        b3o__Site__c site = (b3o__Site__c) WfmTestFactory.insertSObject(
            WfmTestFactory.buildSite('Athens Clinic', '1 Example St', 'Athens', '10557', 'Facility note')
        );

        List<b3s__Shift__c> shifts = (List<b3s__Shift__c>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            new b3s__Shift__c(b3s__Contact__c = c1.Id, b3s__Site__c = site.Id),
            new b3s__Shift__c(b3s__Contact__c = c1.Id, b3s__Site__c = site.Id)
        });

        List<ShiftPushEventBatcher.FlowInput> inputs = new List<ShiftPushEventBatcher.FlowInput>{
            WfmTestFactory.buildShiftPushInput(shifts[0].Id, 'Shift Update', 'Your shift at ' + ShiftPushEventBatcher.FACILITY_PLACEHOLDER + ' has changed.', '/app/shifts'),
            WfmTestFactory.buildShiftPushInput(shifts[1].Id, 'Shift Update', 'Your shift at ' + ShiftPushEventBatcher.FACILITY_PLACEHOLDER + ' has changed.', '/app/shifts')
        };

        List<X3B_Push_Notification_Event__e> evts = ShiftPushEventBatcher.buildEvents(inputs);

        System.assertEquals(1, evts.size(), 'Two shifts but one contact => one event.');
        System.assertEquals('You have 2 shift updates.', evts[0].Body__c);
    }

    @IsTest
    static void buildEvents_twoContacts_createsTwoEvents() {
        List<Contact> contacts = (List<Contact>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            WfmTestFactory.buildContactNoEmail('Ada', 'Lovelace'),
            WfmTestFactory.buildContactNoEmail('Alan', 'Turing')
        });
        Contact c1 = contacts[0];
        Contact c2 = contacts[1];

        b3o__Site__c site = (b3o__Site__c) WfmTestFactory.insertSObject(
            WfmTestFactory.buildSite('Athens Clinic', '1 Example St', 'Athens', '10557', 'Facility note')
        );

        List<b3s__Shift__c> shifts = (List<b3s__Shift__c>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            new b3s__Shift__c(b3s__Contact__c = c1.Id, b3s__Site__c = site.Id),
            new b3s__Shift__c(b3s__Contact__c = c1.Id, b3s__Site__c = site.Id),
            new b3s__Shift__c(b3s__Contact__c = c2.Id, b3s__Site__c = site.Id)
        });

        List<ShiftPushEventBatcher.FlowInput> inputs = new List<ShiftPushEventBatcher.FlowInput>{
            WfmTestFactory.buildShiftPushInput(shifts[0].Id, 'Shift Update', 'Your shift at ' + ShiftPushEventBatcher.FACILITY_PLACEHOLDER + ' has changed.', '/app/shifts'),
            WfmTestFactory.buildShiftPushInput(shifts[1].Id, 'Shift Update', 'Your shift at ' + ShiftPushEventBatcher.FACILITY_PLACEHOLDER + ' has changed.', '/app/shifts'),
            WfmTestFactory.buildShiftPushInput(shifts[2].Id, 'Shift Update', 'Your shift at ' + ShiftPushEventBatcher.FACILITY_PLACEHOLDER + ' has changed.', '/app/shifts')
        };

        List<X3B_Push_Notification_Event__e> evts = ShiftPushEventBatcher.buildEvents(inputs);

        System.assertEquals(2, evts.size(), 'Expected one event per contact.');
        Set<Id> userIds = new Set<Id>();
        for (X3B_Push_Notification_Event__e e : evts) userIds.add((Id)e.User_Id__c);
        System.assertEquals(new Set<Id>{ c1.Id, c2.Id }, userIds);
    }

    @IsTest
    static void publishEvents_returnsSuccessResults() {
        List<Contact> contacts = (List<Contact>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            WfmTestFactory.buildContactNoEmail('Ada', 'Lovelace')
        });
        Contact c1 = contacts[0];

        b3o__Site__c site = (b3o__Site__c) WfmTestFactory.insertSObject(
            WfmTestFactory.buildSite('Athens Clinic', '1 Example St', 'Athens', '10557', 'Facility note')
        );

        List<b3s__Shift__c> shifts = (List<b3s__Shift__c>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            new b3s__Shift__c(b3s__Contact__c = c1.Id, b3s__Site__c = site.Id)
        });

        List<ShiftPushEventBatcher.FlowInput> inputs = new List<ShiftPushEventBatcher.FlowInput>{
            WfmTestFactory.buildShiftPushInput(shifts[0].Id, 'Shift Update', 'Your shift at ' + ShiftPushEventBatcher.FACILITY_PLACEHOLDER + ' has changed.', '/app/shifts')
        };

        List<X3B_Push_Notification_Event__e> evts = ShiftPushEventBatcher.buildEvents(inputs);

        Test.startTest();
        List<Database.SaveResult> results = ShiftPushEventBatcher.publishEvents(evts);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'One event => one publish result.');
        System.assertEquals(true, results[0].isSuccess(), 'Publish should succeed.');
    }

    @IsTest
    static void nullContactShift_isIgnored_andEmptyInputNoOp() {
        b3o__Site__c site = (b3o__Site__c) WfmTestFactory.insertSObject(
            WfmTestFactory.buildSite('Athens Clinic', '1 Example St', 'Athens', '10557', 'Facility note')
        );

        List<b3s__Shift__c> shifts = (List<b3s__Shift__c>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            new b3s__Shift__c(b3s__Site__c = site.Id)
        });

        List<ShiftPushEventBatcher.FlowInput> inputs = new List<ShiftPushEventBatcher.FlowInput>{
            WfmTestFactory.buildShiftPushInput(shifts[0].Id, 'Shift Update', 'Your shift at ' + ShiftPushEventBatcher.FACILITY_PLACEHOLDER + ' has changed.', '/app/shifts')
        };

        List<X3B_Push_Notification_Event__e> evts = ShiftPushEventBatcher.buildEvents(inputs);
        System.assertEquals(0, evts.size(), 'Shifts with null contact should produce no events.');

        Test.startTest();
        ShiftPushEventBatcher.publishPushEvents(new List<ShiftPushEventBatcher.FlowInput>());
        Test.stopTest();

        System.assert(true);
    }
}