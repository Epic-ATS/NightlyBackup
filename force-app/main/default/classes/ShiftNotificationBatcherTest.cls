@IsTest
private class ShiftNotificationBatcherTest {

    @IsTest
    static void sendsOneSendEmailInvocation_andSkipsNullEmails() {
        List<Contact> contacts = (List<Contact>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            WfmTestFactory.buildContact('Ada', 'Lovelace', 'ada@example.com'),
            WfmTestFactory.buildContact('Alan', 'Turing', 'alan@example.com'),
            WfmTestFactory.buildContactNoEmail('No', 'Email')
        });

        Contact c1 = contacts[0];
        Contact c2 = contacts[1];
        Contact cNoEmail = contacts[2];

        b3o__Site__c site = (b3o__Site__c) WfmTestFactory.insertSObject(
            WfmTestFactory.buildSite('Athens Clinic', '1 Example St', 'Athens', '10557', 'Facility note from Site')
        );

        b3o__Job_Type__c jobType = (b3o__Job_Type__c) WfmTestFactory.insertSObject(WfmTestFactory.buildJobType('Nurse'));
        b3o__Job__c job = (b3o__Job__c) WfmTestFactory.insertSObject(WfmTestFactory.buildJob(jobType.Id));

        Datetime base = System.now().addDays(1);

        List<b3s__Shift__c> shifts = (List<b3s__Shift__c>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            WfmTestFactory.buildShift(c1.Id, site.Id, job.Id, base, base.addHours(8)),
            WfmTestFactory.buildShift(c1.Id, site.Id, job.Id, base.addDays(1), base.addDays(1).addHours(8)),
            WfmTestFactory.buildShift(c2.Id, site.Id, job.Id, base.addDays(2), base.addDays(2).addHours(6)),
            WfmTestFactory.buildShift(cNoEmail.Id, site.Id, job.Id, base.addDays(3), base.addDays(3).addHours(6))
        });

        List<ShiftNotificationBatcher.FlowInput> inputs = new List<ShiftNotificationBatcher.FlowInput>{
            WfmTestFactory.buildShiftEmailInput(shifts[0].Id, 'Your Upcoming Shifts', 'Here are your scheduled shifts for the next few days.'),
            WfmTestFactory.buildShiftEmailInput(shifts[1].Id, 'Your Upcoming Shifts', 'Here are your scheduled shifts for the next few days.'),
            WfmTestFactory.buildShiftEmailInput(shifts[2].Id, 'Your Upcoming Shifts', 'Here are your scheduled shifts for the next few days.'),
            WfmTestFactory.buildShiftEmailInput(shifts[3].Id, 'Your Upcoming Shifts', 'Here are your scheduled shifts for the next few days.')
        };

        Test.startTest();
        Integer beforeInvocations = Limits.getEmailInvocations();
        ShiftNotificationBatcher.sendConsolidatedEmail(inputs);
        Integer afterInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(beforeInvocations + 1, afterInvocations);
    }

    @IsTest
    static void noValidRecipients_resultsInNoSend() {
        List<Contact> contacts = (List<Contact>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            WfmTestFactory.buildContactNoEmail('No', 'Email1'),
            WfmTestFactory.buildContactNoEmail('No', 'Email2')
        });

        b3o__Site__c site = (b3o__Site__c) WfmTestFactory.insertSObject(
            WfmTestFactory.buildSite('Athens Clinic', '1 Example St', 'Athens', '10557', 'Facility note from Site')
        );

        b3o__Job_Type__c jobType = (b3o__Job_Type__c) WfmTestFactory.insertSObject(WfmTestFactory.buildJobType('Nurse'));
        b3o__Job__c job = (b3o__Job__c) WfmTestFactory.insertSObject(WfmTestFactory.buildJob(jobType.Id));

        Datetime base = System.now().addDays(1);

        List<b3s__Shift__c> shifts = (List<b3s__Shift__c>)(List<Object>) WfmTestFactory.insertSObjects(new List<SObject>{
            WfmTestFactory.buildShift(contacts[0].Id, site.Id, job.Id, base, base.addHours(8)),
            WfmTestFactory.buildShift(contacts[1].Id, site.Id, job.Id, base.addDays(1), base.addDays(1).addHours(8))
        });

        List<ShiftNotificationBatcher.FlowInput> inputs = new List<ShiftNotificationBatcher.FlowInput>{
            WfmTestFactory.buildShiftEmailInput(shifts[0].Id, 'Your Upcoming Shifts', 'Intro'),
            WfmTestFactory.buildShiftEmailInput(shifts[1].Id, 'Your Upcoming Shifts', 'Intro')
        };

        Test.startTest();
        Integer beforeInvocations = Limits.getEmailInvocations();
        ShiftNotificationBatcher.sendConsolidatedEmail(inputs);
        Integer afterInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(beforeInvocations, afterInvocations);
    }

    @IsTest
    static void handlesEmptyRequestList() {
        Test.startTest();
        Integer beforeInvocations = Limits.getEmailInvocations();
        ShiftNotificationBatcher.sendConsolidatedEmail(new List<ShiftNotificationBatcher.FlowInput>());
        Integer afterInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(beforeInvocations, afterInvocations);
    }
}