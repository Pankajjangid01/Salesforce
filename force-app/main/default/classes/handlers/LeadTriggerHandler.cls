public with sharing class LeadTriggerHandler {
    public static void handleBeforeInsert(List<Lead> newLeads) {
        LeadService.validateLeadsBeforeInsert(newLeads);
    }

    public static void handleAfterInsert(List<Lead> newLeads) {
        LeadService.processNewLeads(newLeads);
    }

    public static void handleAfterUpdate(List<Lead> newLeads,  Map<Id, Lead> oldLeadMap) {
        LeadService.rescoreUpdatedLeads(newLeads, oldLeadMap);
    }
}