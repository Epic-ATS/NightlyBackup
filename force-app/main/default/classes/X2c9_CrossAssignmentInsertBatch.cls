@SuppressWarnings('PMD.AvoidDebugStatements')
public class X2c9_CrossAssignmentInsertBatch implements Database.Batchable<sObject>, Schedulable {

    public static final String LOG_AREA = 'X2c9_CrossAssignmentInsertBatch';
    public static final String LOG_DESCRIPTION = 'One or more errors from X2c9_CrossAssignmentInsertBatch. See Debug Lines for details.';
    public static final String LOG_PROCESS_NAME = 'Insert dummy Cross-Assignment Timesheet Entries and Pay Transactions before Timesheet interpretation';
    
    private List<Id> timesheetIds;

    public void execute(SchedulableContext sc) {
        insertCrossAssignment(null);
    }

    @InvocableMethod(label = 'Cross assignment insertion')
    public static void insertCrossAssignment(List<List<id>> timesheetIds) {
        List<Id> tsIds = new List<Id>();
        if(timesheetIds != null) {
            for (List<Id> request : timesheetIds) {
                tsIds.addAll(request);
            }
        }

        List<AsyncApexJob> jobs = [SELECT Id, ApexClassId, Status 
                                   FROM AsyncApexJob 
                                   WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = 'X2c9_CrossAssignmentInsertBatch')
                                   AND Status NOT IN ('Aborted', 'Completed', 'Failed')
                                   AND JobType = 'BatchApex'];
        if (jobs.isEmpty()) {
            X2c9_CrossAssignmentInsertBatch batch = new X2c9_CrossAssignmentInsertBatch();
            batch.timesheetIds = tsIds;

            Database.executeBatch(batch, 1);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        updateValidationSetting(true);
        String query = ' SELECT Id, tc9_et__End_Date__c, ' + 
                       ' tc9_et__Assignment__r.x2c9_Cross_Assignment_Group_By_ID__c, tc9_et__Assignment__r.x2c9_Cross_Assignment_Timesheet_Status__c, x2c9_Start_Date__c, tc9_et__Payee__c, ' + 
                       '  (SELECT Id, tc9_et__Timesheet__c FROM tc9_et__Timesheet_Entries__r ' + 
                       '   WHERE x2c9_Cross_Assignment_Timesheet_Entry__c = TRUE) ' + 
                       ' FROM tc9_et__Timesheet__c ' +
                       ' WHERE x2c9_Cross_Assignment_Status__c = \'Pending Insert\' ';

        if (timesheetIds != null && !timesheetIds.isEmpty()) {
            query += ' AND Id IN :timesheetIds';
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<tc9_et__Timesheet__c> timesheets) {
        System.debug('[EXECUTE] X2c9_CrossAssignmentInsertBatch.execute timesheets=' + timesheets);
        List<tc9_et__Timesheet_Entry__c> delEntries = new List<tc9_et__Timesheet_Entry__c>();

        Set<String> crossAssignmentGrpSet = new Set<String>();
        for (tc9_et__Timesheet__c ts : timesheets) {
            crossAssignmentGrpSet.add(ts.tc9_et__Assignment__r.x2c9_Cross_Assignment_Group_By_ID__c);

            if (ts.tc9_et__Timesheet_Entries__r != null && !ts.tc9_et__Timesheet_Entries__r.isEmpty()) {
                delEntries.addAll(ts.tc9_et__Timesheet_Entries__r);
            }
        }

        System.debug('[INFO] X2c9_CrossAssignmentInsertBatch.execute delEntries size=' + delEntries.size() + ' delEntries=' + delEntries);
        
        Map<String, List<tc9_et__Timesheet_Entry__c>> nonCrossAssignmentTseMap = getNonCrossAssignmentTseMap(crossAssignmentGrpSet);
        System.debug('[INFO] X2c9_CrossAssignmentInsertBatch.execute nonCrossAssignmentTseMap=' + nonCrossAssignmentTseMap);

        List<tc9_et__Timesheet_Entry__c> newEntries = new List<tc9_et__Timesheet_Entry__c>();
        for (tc9_et__Timesheet__c ts : timesheets) {
            List<tc9_et__Timesheet_Entry__c> nonCrossAssignmentTSEs = nonCrossAssignmentTseMap.get(ts.tc9_et__Assignment__r.x2c9_Cross_Assignment_Group_By_ID__c);
            Set<String> relatedTimesheetNames = new Set<String>();
        
            System.debug('X2c9_CrossAssignmentInsertBatch.execute nonCrossAssignmentTSEs=' + nonCrossAssignmentTSEs);
        
            if (nonCrossAssignmentTSEs == null || nonCrossAssignmentTSEs.isEmpty()) {
                updateTimesheetStatusAndDetails(ts, relatedTimesheetNames, false);
                continue; // Use continue to skip to the next iteration
            }

            processCrossAssignmentTSEs(ts, nonCrossAssignmentTSEs, newEntries, relatedTimesheetNames);
            updateTimesheetStatusAndDetails(ts, relatedTimesheetNames, true);
        }

        System.debug('[INFO] X2c9_CrossAssignmentInsertBatch.execute newEntries=' + newEntries);
        System.debug('[INFO] X2c9_CrossAssignmentInsertBatch.execute newEntries.size()=' + newEntries.size());

        Set<Id> failedInsLineTimesheetIdset = new Set<Id>();
        List<tc9_pr__Debug_Log__c> logs = new List<tc9_pr__Debug_Log__c>();


        X2c9_CrossAssignmentBatchHelper.insertTimesheetEntries(newEntries, logs, failedInsLineTimesheetIdset);
        X2c9_CrossAssignmentBatchHelper.deleteTimesheetEntries(delEntries, logs);


        System.debug('failedInsLineTimesheetIdset=' + failedInsLineTimesheetIdset);

        if(!failedInsLineTimesheetIdset.isEmpty()) {
            for(tc9_et__Timesheet__c ts : timesheets)  {
                if(failedInsLineTimesheetIdset.contains(ts.Id)) {
                    ts.x2c9_Cross_Assignment_Status__c = 'Insert Failed';
                    ts.x2c9_Cross_Assignment_Details__c = 'Cross-Assignment Insert Failed, Check Debug Logs for Error - ' + System.now();
                }
            }

            //delete all inserted TSEs if there is any failed insertion
            deleteErrorTSE(failedInsLineTimesheetIdset);
        }

        X2c9_CrossAssignmentBatchHelper.insertLogs(logs, LOG_AREA, LOG_DESCRIPTION, LOG_PROCESS_NAME);
        update timesheets;
    }

    public void finish(Database.BatchableContext bc) {
        updateValidationSetting(false);
    }

    private static Map<String, List<tc9_et__Timesheet_Entry__c>> getNonCrossAssignmentTseMap(Set<String> crossAssignmentGrpSet) {
        Map<String, List<tc9_et__Timesheet_Entry__c>> nonCrossAssignmentTseMap = new Map<String,List<tc9_et__Timesheet_Entry__c>>();
        String queryTSEStr = ' SELECT ' + getFields('tc9_et__Timesheet_Entry__c') +
                             ' , tc9_et__Timesheet__r.Name ' + 
                             ' FROM tc9_et__Timesheet_Entry__c WHERE x2c9_Cross_Assignment_Timesheet_Entry__c = FALSE ' + 
                             ' AND tc9_et__Total_Hours__c > 0 ' +
                             ' AND x2c9_Cross_Assignment_Group_By_ID__c IN :crossAssignmentGrpSet ';

        List<tc9_et__Timesheet_Entry__c> tses = Database.query(queryTSEStr);
        for(tc9_et__Timesheet_Entry__c tse : tses) {
            if(!nonCrossAssignmentTseMap.containsKey(tse.x2c9_Cross_Assignment_Group_By_ID__c)) {
                nonCrossAssignmentTseMap.put(tse.x2c9_Cross_Assignment_Group_By_ID__c, new List<tc9_et__Timesheet_Entry__c>{tse});
                
            } else {
                nonCrossAssignmentTseMap.get(tse.x2c9_Cross_Assignment_Group_By_ID__c).add(tse);
            }
        }

        return nonCrossAssignmentTseMap;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private void processCrossAssignmentTSEs(tc9_et__Timesheet__c ts, List<tc9_et__Timesheet_Entry__c> nonCrossAssignmentTSEs, List<tc9_et__Timesheet_Entry__c> newEntries, Set<String> relatedTimesheetNames) {
        String status = ts.tc9_et__Assignment__r.x2c9_Cross_Assignment_Timesheet_Status__c;    
        for(tc9_et__Timesheet_Entry__c tse : nonCrossAssignmentTSEs) {
            Boolean isApprovedAndMatches = (status == 'Approved' && tse.tc9_et__Approval_Status__c == status);
            Boolean isNotApproved = (status != 'Approved');

            if ((isApprovedAndMatches || isNotApproved) && validateTSE(ts, tse)) {
                tc9_et__Timesheet_Entry__c newEntry = cloneTSE(tse, ts);
                newEntries.add(newEntry);
                relatedTimesheetNames.add(tse.tc9_et__Timesheet__r.Name);
            }
        }
    }

    private void updateTimesheetStatusAndDetails(tc9_et__Timesheet__c timesheet, Set<String> relatedNames, Boolean foundEntries) {
        timesheet.tc9_et__Transaction_Creation_Stage__c = '2';
        timesheet.x2c9_Cross_Assignment_Status__c = 'Pending Delete';
    
        if (foundEntries) {
            String detail = 'Timesheets Included in Cross-Assignment Interpretation:' + String.join(new List<String>(relatedNames), ',') + ' - ' + System.now();
            timesheet.x2c9_Cross_Assignment_Details__c = detail.left(255);
        } else {
            timesheet.x2c9_Cross_Assignment_Details__c = 'No Cross-Assignment Timesheets Found';
        }
    }

    @Testvisible
    private static void deleteErrorTSE(Set<Id> failedInsLineTimesheetIdset) {
        List<tc9_et__Timesheet_Entry__c> delTSEforErrorTS = new List<tc9_et__Timesheet_Entry__c>();
        List<tc9_et__Timesheet__c> errorTSs = [SELECT Id,tc9_et__End_Date__c,
                                                tc9_et__Assignment__r.x2c9_Cross_Assignment_Group_By_ID__c, tc9_et__Assignment__r.x2c9_Cross_Assignment_Timesheet_Status__c, x2c9_Start_Date__c, tc9_et__Payee__c, 
                                                    (SELECT Id, tc9_et__Timesheet__c 
                                                    FROM tc9_et__Timesheet_Entries__r 
                                                    WHERE x2c9_Cross_Assignment_Timesheet_Entry__c = TRUE) 
                                                FROM tc9_et__Timesheet__c
                                                WHERE Id IN :failedInsLineTimesheetIdset];
        
        for (tc9_et__Timesheet__c ts : errorTSs) {
            if (ts.tc9_et__Timesheet_Entries__r != null && !ts.tc9_et__Timesheet_Entries__r.isEmpty()) {
                delTSEforErrorTS.addAll(ts.tc9_et__Timesheet_Entries__r);
            }
        }

        Database.delete(delTSEforErrorTS, false);
    }

    public static tc9_pr__Debug_Log__c buildDebugLog(String recordId, String objectName, String error) {
        tc9_pr__Debug_Log__c log = new tc9_pr__Debug_Log__c();
        log.tc9_pr__Area__c = 'X2c9_CrossAssignmentInsertBatch';
        log.tc9_pr__Record_Detail__c = '<a href="/' + recordId + '" target="_blank">' + recordId + '</a>';
        log.tc9_pr__Source__c = 'Insert dummy Cross-Assignment ' + objectName + ' and Pay Transactions before Timesheet interpretation';
        log.tc9_pr__Record_Type__c = recordId;
        log.tc9_pr__Description__c = error?.left(10000);
        return log;
    }

    private static String getFields(String objectAPI){
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectAPI).getDescribe().fields.getMap();
    
        return String.join(new List<String>(fieldMap.keySet()), ', ');
    }

    private static void updateValidationSetting(Boolean ovTSE) {
        tc9_pr__Override_TC9P_Validation__c setting = tc9_pr__Override_TC9P_Validation__c.getOrgDefaults();
        setting.tc9_et__OV_Timesheet_Entry__c = ovTSE;
        setting.tc9_et__OV_Timesheet__c = ovTSE;
        update setting;
    }

    private static tc9_et__Timesheet_Entry__c cloneTSE(tc9_et__Timesheet_Entry__c tse, tc9_et__Timesheet__c ts) {
        tc9_et__Timesheet_Entry__c newEntry = tse.clone(false, true, false, false);
        newEntry.tc9_et__Assignment__c = ts.tc9_et__Assignment__c;
        newEntry.tc9_et__Approval_Flag__c = true;
        newEntry.tc9_et__Submitted_Flag__c = true;
        newEntry.tc9_et__Timesheet__c = ts.Id;
        newEntry.x2c9_Cross_Assignment_Timesheet_Entry__c = true;
        newEntry.tc9_et__Date_Pay_Transaction_Generated__c = null;
        newEntry.tc9_et__Project_Code__c = null;
        newEntry.tc9_et__Timesheet_Activity__c = null;

        return newEntry;
    }

    //boolean validateTSE method
    private static Boolean validateTSE(tc9_et__Timesheet__c ts, tc9_et__Timesheet_Entry__c tse) {
        if(tse.tc9_et__Assignment__c != ts.tc9_et__Assignment__c && 
            tse.tc9_et__Start_Date__c <= ts.tc9_et__End_Date__c && 
            tse.tc9_et__Start_Date__c >= ts.x2c9_Start_Date__c) {
            return true;

        } else {
            return false;
        }
    }
}