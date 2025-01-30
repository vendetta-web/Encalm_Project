public class LogErrorUtil {
    public static void logError(Exception e, String apexClassName, String methodName) {
        system.debug('test');
        // Create new Log Parsing Error record
        Log_Parsing_Error__c errorLog = new Log_Parsing_Error__c();
        errorLog.Error_Message__c = e.getMessage();
        errorLog.Apex_Class_Name__c = apexClassName;
        errorLog.Method_Name__c = methodName;
        errorLog.Error_Timestamp__c = System.now();
        errorLog.Stack_Trace__c = e.getStackTraceString();
        errorLog.User__c = UserInfo.getUserId();
        errorLog.Log_Level__c = 'ERROR'; 
        
        // Determine the error type based on the exception
        String errorType = getErrorType(e);
        errorLog.Error_Type__c = errorType;
        
        // Insert the error log record
        insert errorLog;
    }
    
    // Helper method to classify error type
    private static String getErrorType(Exception e) {
        if (e instanceof NullPointerException) {
            return 'Null Pointer Exception';
        } else if (e instanceof QueryException) {
            return 'Query Exception';
        } else if (e instanceof DmlException) {
            return 'DML Exception';
        } else if (e instanceof LimitException) {
            return 'Governor Limits Exception';
        }  else {
            return 'Unknown Exception';
        }
    }
}