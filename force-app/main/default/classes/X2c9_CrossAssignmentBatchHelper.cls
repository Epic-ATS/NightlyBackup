public with sharing class X2c9_CrossAssignmentBatchHelper {
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void insertLogs(List<tc9_pr__Debug_Log__c> logs, String area, String description, String processName) {
        if(!logs.isEmpty()) {
            tc9_pr__Debug_Header__c header = buildDebugHeader(area, description, processName);
            insert header; // NOPMD

            for(tc9_pr__Debug_Log__c log : logs) {
                log.tc9_pr__Debug_Header__c = header.Id;
            }
            insert logs; // NOPMD
        }
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void insertTimesheetEntries(List<tc9_et__Timesheet_Entry__c> newEntries, List<tc9_pr__Debug_Log__c> logs, Set<Id> failedInsLineTimesheetIdset) {
        if(!newEntries.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(newEntries, false);
            for (Integer i = 0; i < insertResults.size(); i++) {
                if (!insertResults[i].isSuccess()) {
                    logs.add(buildCrossAssignmentInsertDebugLog(newEntries[i].Id, 'Timesheet Entries', JSON.serialize(insertResults[i].getErrors())));
                    failedInsLineTimesheetIdset.add(newEntries[i].tc9_et__Timesheet__c);
                } 
            }
        }
    }

    public static void deleteTimesheetEntries(List<tc9_et__Timesheet_Entry__c> delEntries, List<tc9_pr__Debug_Log__c> logs) {
        if(!delEntries.isEmpty()) {
            Database.DeleteResult[] delResults = Database.delete(delEntries, false);
            for (Integer i = 0; i < delResults.size(); i++) {
                if (!delResults[i].isSuccess()) {
                    logs.add(buildCrossAssignmentInsertDebugLog(delEntries[i].Id, 'Timesheet Entries', JSON.serialize(delResults[i].getErrors())));
                } 
            }
        }
    }
    
    public static tc9_pr__Debug_Header__c buildDebugHeader(String area, String description, String processName) {
        tc9_pr__Debug_Header__c header = new tc9_pr__Debug_Header__c();
        header.tc9_pr__Area__c = area;
        header.tc9_pr__Description__c = description;
        header.tc9_pr__Process_Name__c = processName;
        return header;
    }

    public static tc9_pr__Debug_Log__c buildCrossAssignmentInsertDebugLog(String recordId, String objectName, String error) {
        tc9_pr__Debug_Log__c log = new tc9_pr__Debug_Log__c();
        log.tc9_pr__Area__c = 'X2c9_CrossAssignmentInsertBatch';
        log.tc9_pr__Record_Detail__c = '<a href="/' + recordId + '" target="_blank">' + recordId + '</a>';
        log.tc9_pr__Source__c = 'Insert dummy Cross-Assignment ' + objectName + ' and Pay Transactions before Timesheet interpretation';
        log.tc9_pr__Record_Type__c = recordId;
        log.tc9_pr__Description__c = error?.left(10000);
        return log;
    }
}