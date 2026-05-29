@IsTest
public class WfmTestFactory {

    // -------- Builders (NO DML) --------

    public static Contact buildContact(String first, String last, String email) {
        return new Contact(
            FirstName = first,
            LastName  = last,
            Email     = email
        );
    }

    public static Contact buildContactNoEmail(String first, String last) {
        return new Contact(
            FirstName = first,
            LastName  = last,
            MobilePhone     = '0000000000'
        );
    }

    public static b3o__Site__c buildSite(String name, String street, String city, String postCode, String facilityNotes) {
        b3o__Site__c site = new b3o__Site__c(Name = name);
        site.b3o__Street_Address__c = street;
        site.b3o__City__c = city;
        site.b3o__Post_Code__c = postCode;
        site.b3_Facility_Notes__c = facilityNotes;
        return site;
    }

    public static b3o__Job_Type__c buildJobType(String name) {
        return new b3o__Job_Type__c(Name = name);
    }

    public static b3o__Job__c buildJob(Id jobTypeId) {
        return new b3o__Job__c(b3o__Job_Type__c = jobTypeId);
    }

    public static b3s__Shift__c buildShift(Id contactId, Id siteId, Id jobId, Datetime startDt, Datetime endDt) {
        return new b3s__Shift__c(
            b3s__Contact__c = contactId,
            b3s__Site__c = siteId,
            b3s__Job__c = jobId,
            b3s__Scheduled_Start_Time__c = startDt,
            b3s__Scheduled_End_Time__c = endDt
        );
    }

    // -------- Inserters (generic DML helpers) --------

    public static SObject insertSObject(final SObject sobj) {
        return insertSObjects(new List<SObject>{ sobj })[0];
    }

    public static List<SObject> insertSObjects(final List<SObject> sobjects) {
        if (sobjects == null || sobjects.isEmpty()) return new List<SObject>();
        insert sobjects;
        return sobjects;
    }

    // -------- Flow input builders --------

    public static ShiftNotificationBatcher.FlowInput buildShiftEmailInput(Id shiftId, String subject, String intro) {
        ShiftNotificationBatcher.FlowInput fi = new ShiftNotificationBatcher.FlowInput();
        fi.shiftId = shiftId;
        fi.emailSubject = subject;
        fi.introText = intro;
        return fi;
    }

    public static ShiftPushEventBatcher.FlowInput buildShiftPushInput(Id shiftId, String title, String singleBody, String targetLink) {
        ShiftPushEventBatcher.FlowInput fi = new ShiftPushEventBatcher.FlowInput();
        fi.shiftId = shiftId;
        fi.title = title;
        fi.singleBody = singleBody;
        fi.targetLink = targetLink;
        return fi;
    }
}