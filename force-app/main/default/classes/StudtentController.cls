public with sharing class StudtentController {
    @AuraEnabled
    public static Id getRecordTypeId(String objectName, String developerName) {

        return Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get(developerName)
            .getRecordTypeId();
    }
}