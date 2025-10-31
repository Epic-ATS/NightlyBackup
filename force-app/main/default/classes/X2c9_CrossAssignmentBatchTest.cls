@isTest
public class X2c9_CrossAssignmentBatchTest extends X2c9_CrossAssignmentBaseSetupTest {
    
    @TestSetup
    public static void setup(){
        tc9_pr__Override_TC9P_Validation__c setting = prepareSetting();
        insert setting;
        
        Date startDate = Date.today().toStartOfWeek();
        Date endDate = startDate.addDays(30);
        
        tc9_pr__Location__c location = prepareTaxLocation();
        location.x2c9_WorkCover_Industry_Classification__c = 'testLocation';
        insert location;
        
        tc9_et__Payment_Terms__c pterm = preaprePaymentTerm();
        insert pterm;

        tc9_et__Interpretation_Rule__c intRule = prepareInterpretationRule(38.0, 15.0, 5.0, 5.0, 5.0, false);
        insert intRule;
        
        tc9_pr__Schedule__c schedule = prepareSchedule('Weekly','W','Pay_Schedule');
        tc9_pr__Schedule__c scheduleInv = prepareSchedule('Weekly','W','Invoice_Schedule');
        
        List<tc9_pr__Schedule__c> schList = new List<tc9_pr__Schedule__c>{schedule, scheduleInv};
        insert schList;
        
        Account acc = prepareClientAccount(location.Id, 'Client', schedule.Id);        
        Account invoiceEntity = prepareClientAccount(location.Id, 'Invoice_Entity', schedule.Id);
        Account paymentEntity = prepareClientAccount(location.Id, 'Payment_Entity', schedule.Id);
        Account candAcc = prepareEmployeeAccount(location.Id);
        insert new List<Account>{acc, invoiceEntity, paymentEntity, candAcc};
            
        paymentEntity.Name = 'First Choice Care Pty Ltd1';
        update paymentEntity;
            
        Contact clientCon = prepareClientContact(acc);
        //clientCon.CORE_Local_Phone_Prefix__c = 'Australia +61';
        insert clientCon;

        Contact employee = prepareEmployee(candAcc);
        //employee.CORE_Local_Phone_Prefix__c = 'Australia +61';
        insert employee;

        tc9_pr__Payee__c payee = preparePayee(schedule.Id, employee.Id, paymentEntity.Id,'PAYE');
        insert payee;
        
        tc9_pr__Calendar__c pubCal = preparePublicHolidayCalendar(schedule.Id, paymentEntity.Id);
        insert pubCal;
        
        tc9_pr__Calendar_Period__c pCalItem = prepareHoliday(pubCal.Id, startDate, startDate.addDays(1));
        insert pCalItem;
        
        tc9_pr__Calendar__c tsCal = prepareTimesheetCalendar(schedule.Id, paymentEntity.Id, true, startDate, 'Weekly', 'Start/End Times', 'Start/End Times', scheduleInv.Id, invoiceEntity.Id);
        insert tsCal;
        
        tc9_pr__Calendar_Period__c tsCalItem = prepareHoliday(tsCal.Id, startDate.addDays(-2), startDate.addDays(100));
        insert tsCalItem;
        
        tc9_pr__Template_Group__c tg = new tc9_pr__Template_Group__c(Name='TG Name');
        tg.RecordTypeId = Schema.SObjectType.tc9_pr__Template_Group__c.getRecordTypeInfosByDeveloperName().get('Invoice_Settings')?.getRecordTypeId();
        tg.tc9_pr__Client__c = acc.Id;
        insert tg;
        
        tc9_et__Invoice_Setting__c invSetting = new tc9_et__Invoice_Setting__c();
        invSetting.RecordTypeId = Schema.SObjectType.tc9_et__Invoice_Setting__c.getRecordTypeInfosByDeveloperName().get('Payroll_Items')?.getRecordTypeId(); 
        invSetting.tc9_et__Effective_Date__c = Date.today().addDays(-20);
        invSetting.tc9_et__Account__c = acc.Id;
        invSetting.tc9_et__Invoice_Entity__c = invoiceEntity.Id;
        invSetting.tc9_et__Payment_Terms__c = pTerm.Id;
        invSetting.tc9_et__Template_Group__c = tg.Id;
        invSetting.tc9_et__Send_Invoice_Emails_Setting__c = 'Current User';
        invSetting.tc9_et__Send_Invoice_Emails_From_Email__c = 'salesforce@2cloudnine.com';
        invSetting.tc9_et__Enable_Project_Codes_on_Invoice__c = 'No';
        invSetting.tc9_et__Enable_0_and_Negative_Invoices__c = 'Yes';
        invSetting.tc9_et__Include_Backing_Sheet__c = 'Yes';
        invSetting.tc9_et__Split_Expenses_to_Own_Invoice__c = 'No';
        invSetting.tc9_et__Split_Invoice_By_Project_Code__c = 'No';
        invSetting.tc9_et__Timesheet_Attachments_with_Invoice__c = 'Yes';
        invSetting.tc9_et__Email_Template_Online__c = 'Standard_Email_Invoice_URL_AUS';
        invSetting.tc9_et__Email_Template_Single_PDF__c = 'Standard_Email_Invoice_Single_PDF_AUS';
        invSetting.tc9_et__Invoice_Visualforce_Page__c = 'InvoicePayrollItemsAUS';
        invSetting.tc9_et__Invoice_Record_Type__c = 'Payroll_Items';
        invSetting.tc9_et__Delivery_Method__c = 'Email with URL Online Link';
        insert invSetting;
                
        tc9_pr__Assignment__c assignment = prepareAssignment(tsCal.Id, acc.Id, clientCon.Id, schedule.Id, pubCal.Id, employee.Id, startDate, endDate, intRule.Id, 'Temp', pterm.Id, payee.Id, scheduleInv.Id, paymentEntity.Id);
        assignment.tc9_et__Invoice_Settings_Template_Group__c = tg.Id;
        insert assignment;
        
        tc9_pr__Assignment__c assignment2 = prepareAssignment(tsCal.Id, acc.Id, clientCon.Id, schedule.Id, pubCal.Id, employee.Id, startDate.addDays(-30), endDate, intRule.Id, 'Temp', pterm.Id, payee.Id, scheduleInv.Id, paymentEntity.Id);
        assignment2.x2c9_Cross_Assignment_Group_By_ID__c = 'reallylikesshiftwork';
        assignment2.tc9_pr__Assignment_Name__c = 'assignment2';
        assignment2.tc9_et__Invoice_Settings_Template_Group__c = tg.Id;
        insert assignment2;

        tc9_pr__Assignment__c assignment3 = prepareAssignment(tsCal.Id, acc.Id, clientCon.Id, schedule.Id, pubCal.Id, employee.Id, startDate.addDays(-30), endDate, intRule.Id, 'Temp', pterm.Id, payee.Id, scheduleInv.Id, paymentEntity.Id);
        assignment3.x2c9_Cross_Assignment_Group_By_ID__c = 'reallylikesshiftwork';
        assignment3.x2c9_Cross_Assignment_Timesheet_Status__c = 'Approved';
        assignment3.tc9_pr__Assignment_Name__c = 'assignment3';
        assignment3.tc9_et__Invoice_Settings_Template_Group__c = tg.Id;
        insert assignment3;
        
        tc9_pr__Pay_Code__c payCodeAllowance = preparePayCode('Allowance');
        insert payCodeAllowance;
        
        tc9_pr__Pay_Code__c payCodePayment = preparePayCode('Payment');
        insert payCodePayment;
        
        tc9_pr__Pay_Code__c payCodeUnpaidPayment = preparePayCode('Payment');
        insert payCodeUnpaidPayment;

        tc9_et__Timesheet__c tsApproved = prepareTimesheet(assignment.Id, employee.Id, payee.Id, Date.today(), Date.today().addDays(7), 'Approved');
        tsApproved.tc9_et__Transaction_Creation_Stage__c = '3';
        tsApproved.x2c9_Cross_Assignment_Status__c = 'Pending Delete';
        insert tsApproved;

        tc9_et__Timesheet__c tsApprove2 = prepareTimesheet(assignment2.Id, employee.Id, payee.Id, Date.today(), Date.today().addDays(31), 'Approved');
        tsApprove2.tc9_et__Transaction_Creation_Stage__c = '5';
        tsApprove2.x2c9_Cross_Assignment_Status__c = 'Pending Insert';
        insert tsApprove2;

        tc9_et__Timesheet_Entry__c tse1 = prepareTimesheetEntry(tsApproved.Id, assignment.Id, payee.Id, employee.Id, startDate);
        tse1.x2c9_Cross_Assignment_Timesheet_Entry__c = true;
        insert tse1;

        tc9_et__Timesheet_Entry__c tse2 = prepareTimesheetEntry(tsApproved.Id, assignment.Id, payee.Id, employee.Id, startDate);
        tse2.x2c9_Cross_Assignment_Timesheet_Entry__c = true;
        insert tse2;

        tc9_et__Timesheet_Entry__c tse3 = prepareTimesheetEntry(tsApproved.Id, assignment3.Id, payee.Id, employee.Id, startDate.addDays(5));
        tse3.tc9_et__Total_Hours__c = 15.00;
        tse3.tc9_et__Approval_Flag__c = true;
        tse3.x2c9_Cross_Assignment_Timesheet_Entry__c = false;
        insert tse3;

        tc9_et__Timesheet_Entry__c tse4 = prepareTimesheetEntry(tsApprove2.Id, assignment3.Id, payee.Id, employee.Id, startDate.addDays(5));
        tse4.tc9_et__Total_Hours__c = 25.00;
        tse4.tc9_et__Approval_Flag__c = true;
        tse4.x2c9_Cross_Assignment_Timesheet_Entry__c = true;
        insert tse4;

        tc9_et__Timesheet_Entry__c tse5 = prepareTimesheetEntry(tsApproved.Id, assignment3.Id, payee.Id, employee.Id, startDate.addDays(5));
        tse5.tc9_et__Total_Hours__c = 75.00;
        tse5.tc9_et__Approval_Flag__c = true;
        tse5.x2c9_Cross_Assignment_Timesheet_Entry__c = true;
        insert tse5;

        tc9_pr__Pay_Transaction__c payt = preparePayTransaction(payee.Id, payCodePayment.Id, assignment.Id, 5100, 1100);
        payt.tc9_et__Timesheet_Entry__c = tse1.Id;
        payt.tc9_et__Timesheet__c = tsApproved.Id;
        insert payt;
    }

    @isTest
    public static void givenPayTransactionAndTimesheetEntryWhenCallCrossAssignmentDeleteBatchThenDeleteSuccessfully() {
        Test.startTest();
        new X2c9_CrossAssignmentDeleteBatch().execute(null);
        Test.stopTest();
        List<tc9_et__Timesheet_Entry__c> tses = [SELECT Id FROM tc9_et__Timesheet_Entry__c];
        Assert.areEqual(2, tses.size(), 'It should return 2 TSEs');
    }

    @isTest
    public static void givenTimesheetIdWhenBuildDebugForDeleteTimesheetEntriesThenCreateDebugSuccessfully() {
        tc9_et__Timesheet__c ts = [SELECT Id FROM tc9_et__Timesheet__c LIMIT 1];
        Test.startTest();
        tc9_pr__Debug_Header__c header = X2c9_CrossAssignmentDeleteBatch.buildDebugHeader();
        X2c9_CrossAssignmentDeleteBatch.buildDebugLog(ts.Id, 'Timesheet Entries', 'error message');

        Assert.areEqual('CrossAssignmentDeleteBatch', header.tc9_pr__Area__c, 'Area must has a value');
        Test.stopTest();
    }

    @isTest
    public static void givenTimesheetEntriesWhenCallCrossAssignmentInsertBatchThenCloneTimesheetEntrySuccessfully2() {
        Test.startTest();
        new X2c9_CrossAssignmentInsertBatch().execute(null);
        Test.stopTest();
        List<tc9_et__Timesheet_Entry__c> tses = [SELECT Id FROM tc9_et__Timesheet_Entry__c];
        Assert.areEqual(5, tses.size(), 'It should return 5 TSEs');
    }

    @isTest
    public static void givenTimesheetEntriesWhenCallCrossAssignmentInsertBatchThenCloneTimesheetEntrySuccessfully3() {
        tc9_pr__Assignment__c assignment = [SELECT Id, x2c9_Cross_Assignment_Timesheet_Status__c FROM tc9_pr__Assignment__c WHERE tc9_pr__Assignment_Name__c = 'assignment2' LIMIT 1];
        assignment.x2c9_Cross_Assignment_Timesheet_Status__c = 'All';
        update assignment;

        Test.startTest();
        new X2c9_CrossAssignmentInsertBatch().execute(null);
        Test.stopTest();
        List<tc9_et__Timesheet_Entry__c> tses = [SELECT Id FROM tc9_et__Timesheet_Entry__c];
        Assert.areEqual(5, tses.size(), 'It should return 5 TSEs');
    }

    @isTest
    public static void givenTimesheetEntriesWhenCallCrossAssignmentInsertBatchThenCloneTimesheetEntrySuccessfully() {
        Test.startTest();
        X2c9_CrossAssignmentInsertBatch.insertCrossAssignment(null);
        Test.stopTest();
        List<tc9_et__Timesheet_Entry__c> tses = [SELECT Id FROM tc9_et__Timesheet_Entry__c];
        Assert.areEqual(5, tses.size(), 'It should return 5 TSEs');
    }

    @isTest
    public static void givenTimesheetIdWhenBuildDebugForInsertTimesheetEntriesThenCreateDebugSuccessfully() {
        tc9_et__Timesheet__c ts = [SELECT Id FROM tc9_et__Timesheet__c LIMIT 1];
        Test.startTest();
        
        tc9_pr__Debug_Log__c log = new tc9_pr__Debug_Log__c();
        log.tc9_pr__Area__c = 'X2c9_CrossAssignmentInsertBatch';
        log.tc9_pr__Record_Detail__c = '<a href="/' + ts.Id + '" target="_blank">' + ts.Id + '</a>';
        log.tc9_pr__Source__c = 'Insert dummy Cross-Assignment ' + 'tc9_et__Timesheet__c' + ' and Pay Transactions before Timesheet interpretation';
        
        X2c9_CrossAssignmentBatchHelper.insertLogs(new List<tc9_pr__Debug_Log__c>{log}, 'X2c9_CrossAssignmentInsertBatch', 'test', 'test');
        X2c9_CrossAssignmentInsertBatch.buildDebugLog(ts.Id, 'Timesheet Entries', 'error message');
        X2c9_CrossAssignmentInsertBatch.deleteErrorTSE(new Set<Id>{ts.Id});
        
        List<tc9_pr__Debug_Log__c> logs = [SELECT Id FROM tc9_pr__Debug_Log__c];
        Assert.areEqual(1, logs.size(), 'It should return 1 log');
        Test.stopTest();
   }
    @isTest
    static void testBuildCrossAssignmentInsertDebugLog() {
        // Sample input values
        String recordId = '001XXXXXXXXXXXXAAA';
        String objectName = 'Account';
        String errorMessage = 'Sample error message for testing purpose';
        
        // Call the method
        X2c9_CrossAssignmentBatchHelper.buildCrossAssignmentInsertDebugLog(recordId, objectName, errorMessage);
     
    }
}