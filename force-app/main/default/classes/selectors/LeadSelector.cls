public with sharing class LeadSelector {

    public static List<Lead> getLeadsByIds(Set<Id> leadIds) {
        return [
            SELECT Id, Name, FirstName, LastName,
                   Email, Phone, Company,
                   Industry, AnnualRevenue, LeadSource,
                   NumberOfEmployees, Status,
                   Lead_Score__c, Is_Duplicate__c,
                   Blacklisted__c, Follow_Up_Date__c,
                   Score_Category__c, OwnerId
            FROM Lead
            WHERE Id IN :leadIds
            WITH SECURITY_ENFORCED
        ];
    }

    // Duplicate check — same email leads
    public static List<Lead> findDuplicatesByEmail(Set<String> emails, Set<Id> excludeIds) {
        return [
            SELECT Id, Name, Email, Status
            FROM Lead
            WHERE Email IN :emails
            AND IsConverted = false
            AND Id NOT IN :excludeIds
            WITH SECURITY_ENFORCED
        ];
    }

    // Duplicate check — same phone leads
    public static List<Lead> findDuplicatesByPhone(Set<String> phones, Set<Id> excludeIds) {
        return [
            SELECT Id, Name, Phone, Status
            FROM Lead
            WHERE Phone IN :phones
            AND IsConverted = false
            AND Id NOT IN :excludeIds
            WITH SECURITY_ENFORCED
        ];
    }

    // Overdue follow-up leads
    public static List<Lead> getOverdueFollowUpLeads() {
        return [
            SELECT Id, Name, Email, OwnerId, Follow_Up_Date__c
            FROM Lead
            WHERE Follow_Up_Date__c < TODAY
            AND IsConverted = false
            AND Status != 'Closed - Not Converted'
            WITH SECURITY_ENFORCED
            ORDER BY Follow_Up_Date__c ASC
        ];
    }

    // HOT leads — score >= threshold
    public static List<Lead> getHotLeads() {
        Business_Rule__mdt rule = Business_Rule__mdt.getInstance(
            'Lead_Score_Threshold'
        );
        Decimal threshold = (rule != null) ? rule.Numeric_Value__c : 70;

        return [
            SELECT Id, Name, Email, Company,
                   Lead_Score__c, Score_Category__c,
                   LeadSource, Status, OwnerId
            FROM Lead
            WHERE Lead_Score__c >= :threshold
            AND IsConverted = false
            WITH SECURITY_ENFORCED
            ORDER BY Lead_Score__c DESC
        ];
    }


    public static List<AggregateResult> getLeadCountByStatus() {
        return [
            SELECT Status, COUNT(Id) total
            FROM Lead
            WHERE IsConverted = false
            GROUP BY Status
        ];
    }

    public static List<AggregateResult> getLeadCountBySource() {
        return [
            SELECT LeadSource, COUNT(Id) total
            FROM Lead
            WHERE IsConverted = false
            AND LeadSource != null
            GROUP BY LeadSource
        ];
    }
}