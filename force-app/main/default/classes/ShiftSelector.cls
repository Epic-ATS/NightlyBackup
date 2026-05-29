public with sharing class ShiftSelector {

    private static ShiftSelector instance;

    public static ShiftSelector getInstance() {
        if (instance == null) {
            instance = new ShiftSelector();
        }
        return instance;
    }

    public List<b3s__Shift__c> selectForShiftEmail(Set<Id> shiftIds) {
        if (shiftIds == null || shiftIds.isEmpty()) return new List<b3s__Shift__c>();
        return [
            SELECT Id,
                   b3s__Contact__c,
                   b3s__Contact__r.FirstName,
                   b3s__Contact__r.LastName,
                   b3s__Contact__r.Email,
                   b3s__Scheduled_Start_Time__c,
                   b3s__Scheduled_End_Time__c,
                   b3s__Site__r.Name,
                   b3s__Site__r.b3o__Full_Address__c,
                   b3s__Job__r.b3o__Job_Type__r.Name,
                   b3_Facility_Notes__c
            FROM b3s__Shift__c
            WHERE Id IN :shiftIds
              AND b3s__Contact__r.Email != null
            ORDER BY b3s__Contact__c, b3s__Scheduled_Start_Time__c ASC, Id ASC
        ];
    }

    public List<b3s__Shift__c> selectForShiftPush(Set<Id> shiftIds) {
        if (shiftIds == null || shiftIds.isEmpty()) return new List<b3s__Shift__c>();
        return [
            SELECT Id,
                   b3s__Contact__c,
                   b3s__Site__r.Name,
                   b3s__Scheduled_Start_Time__c
            FROM b3s__Shift__c
            WHERE Id IN :shiftIds
              AND b3s__Contact__c != null
            ORDER BY b3s__Contact__c, b3s__Scheduled_Start_Time__c ASC, Id ASC
        ];
    }
}