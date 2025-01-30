@IsTest
public class LogErrorUtilTest {

    @IsTest
    static void testLogError() {
        Exception e = null;
        
        try {
            String nullString = null;
            Integer stringLength = nullString.length(); 
        } catch (Exception ex) {
            e = ex;
        }
        
        // Set up test data
        String apexClassName = 'TestClassName';
        String methodName = 'testMethodName';
        
        // Call the logError method
        Test.startTest();
        LogErrorUtil.logError(e, apexClassName, methodName);
        Test.stopTest();
        
        // Verify that the Log Parsing Error record was created correctly
        Log_Parsing_Error__c[] errorLogs = [SELECT Id, Error_Message__c, Apex_Class_Name__c, Method_Name__c, 
                                            Error_Timestamp__c, Stack_Trace__c, User__c, Log_Level__c, Error_Type__c
                                            FROM Log_Parsing_Error__c];
        
        System.assertEquals(1, errorLogs.size(), 'One error log should have been created');
        Log_Parsing_Error__c errorLog = errorLogs[0];
        
        System.assertEquals('Attempt to de-reference a null object', errorLog.Error_Message__c, 'Error message should match');
        System.assertEquals('TestClassName', errorLog.Apex_Class_Name__c, 'Apex class name should match');
        System.assertEquals('testMethodName', errorLog.Method_Name__c, 'Method name should match');
        System.assertEquals('Null Pointer Exception', errorLog.Error_Type__c, 'Error type should be Null Pointer Exception');
        System.assertEquals('ERROR', errorLog.Log_Level__c, 'Log level should be ERROR');
    }
}