/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_tc9_pr_Payee_Leave_EventTrigger on tc9_pr__Payee_Leave_Event__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(tc9_pr__Payee_Leave_Event__c.SObjectType);
}