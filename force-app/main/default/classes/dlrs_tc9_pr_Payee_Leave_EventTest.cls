/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_tc9_pr_Payee_Leave_EventTest
{
    @IsTest(SeeAllData=true)
    private static void testTrigger()
    {
        // Force the dlrs_tc9_pr_Payee_Leave_EventTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new tc9_pr__Payee_Leave_Event__c());
    }
}