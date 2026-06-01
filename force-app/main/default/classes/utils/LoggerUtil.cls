public with sharing class LoggerUtil {
    private static List<System_Log__c> pendingLogs = new List<System_Log__c>();

    public static void logError(String className, String methodName, Exception e, String relatedRecordId) {
        addLog('ERROR', className, methodName, e.getMessage(), e.getStackTraceString(), relatedRecordId);
    }

    public static void logInfo(String className, String methodName, String message, String relatedRecordId) {
        addLog('INFO', className, methodName, message, null, relatedRecordId);
    }
    
    public static void logWarning(String className, String methodName, String message, String relatedRecordId) {
        addLog('WARNING', className, methodName, message, null, relatedRecordId);
    }

    public static void saveLogs() {
        if (!pendingLogs.isEmpty()) {
            Database.insert(pendingLogs, false);
            pendingLogs.clear();
        }
    }

    private static void addLog(String level, String className, String methodName, String message, String stackTrace, String relatedRecordId) {
        pendingLogs.add(new System_Log__c(
            Log_Level__c = level,
            Class_Name__c = className,
            Method_Name__c = methodName,
            Message__c = message,
            Stack_Trace__c = stackTrace,
            Related_Record_Id__c = relatedRecordId,
            User__c = UserInfo.getUserId()
        ));
    }
}