public with sharing class LeadController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getLeadDashboardStats() {
        Map<String, Object> stats = new Map<String, Object>();

        try {
            stats.put('totalLeads',[SELECT COUNT() FROM Lead WHERE IsConverted = false]);
            stats.put('hotLeads',[SELECT COUNT() FROM Lead WHERE Lead_Score__c >= 70 AND IsConverted = false]);
            stats.put('duplicateLeads',[SELECT COUNT() FROM Lead WHERE Is_Duplicate__c = true AND IsConverted = false]);
            stats.put('overdueFollowUps',[SELECT COUNT() FROM Lead WHERE Follow_Up_Date__c < TODAY AND IsConverted = false]);

            // Status wise count — for pie chart
            List<Map<String, Object>> byStatus = new List<Map<String, Object>>();
            for (AggregateResult ar : LeadSelector.getLeadCountByStatus()) {
                byStatus.add(new Map<String, Object>{
                    'status' => String.valueOf(ar.get('Status')),
                    'total'  => Integer.valueOf(ar.get('total'))
                });
            }
            stats.put('byStatus', byStatus);

            // Source wise count — for bar chart
            List<Map<String, Object>> bySource = new List<Map<String, Object>>();
            for (AggregateResult ar : LeadSelector.getLeadCountBySource()) {
                bySource.add(new Map<String, Object>{
                    'source' => String.valueOf(ar.get('LeadSource')),
                    'total'  => Integer.valueOf(ar.get('total'))
                });
            }
            stats.put('bySource', bySource);

        } catch (Exception e) {
            LoggerUtil.logError('LeadController', 'getLeadDashboardStats', e, null);
            LoggerUtil.saveLogs();
            throw new AuraHandledException('Dashboard load karne mein error: ' + e.getMessage());
        }
        return stats;
    }


    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getLeads(String searchTerm, String statusFilter, String scoreFilter, Integer pageNumber, Integer pageSize) {
        try {
            String baseQuery =
                'SELECT Id, Name, FirstName, LastName, ' +
                'Email, Phone, Company, LeadSource, ' +
                'Status, Lead_Score__c, Score_Category__c, ' +
                'Follow_Up_Date__c, Is_Duplicate__c, ' +
                'CreatedDate, OwnerId ' +
                'FROM Lead WHERE IsConverted = false ';

            String countQuery = 'SELECT COUNT() FROM Lead WHERE IsConverted = false ';
            String conditions = '';
            if (String.isNotBlank(searchTerm)) {
                String s = '%' + String.escapeSingleQuotes(searchTerm) + '%';
                conditions += 'AND (Name LIKE \'' + s + '\' ' +
                              'OR Company LIKE \'' + s + '\' ' +
                              'OR Email LIKE \'' + s + '\') ';
            }

            // Status filter
            if (String.isNotBlank(statusFilter) && statusFilter != 'All') {
                conditions += 'AND Status = \'' +
                    String.escapeSingleQuotes(statusFilter) + '\' ';
            }

            // Score filter
            if (String.isNotBlank(scoreFilter)) {
                if (scoreFilter == 'HOT') {
                    conditions += 'AND Lead_Score__c >= 70 ';
                } else if (scoreFilter == 'WARM') {
                    conditions += 'AND Lead_Score__c >= 40 ' +
                                  'AND Lead_Score__c < 70 ';
                } else if (scoreFilter == 'COLD') {
                    conditions += 'AND Lead_Score__c < 40 ';
                }
            }

            // Pagination
            Integer offset = (pageNumber - 1) * pageSize;
            String finalQuery = baseQuery + conditions +
                'ORDER BY Lead_Score__c DESC NULLS LAST ' +
                'LIMIT ' + pageSize + ' OFFSET ' + offset;

            // Result map
            Map<String, Object> result = new Map<String, Object>();
            result.put('leads',      Database.query(finalQuery));
            result.put('totalCount', Database.countQuery(
                                        countQuery + conditions));
            result.put('pageNumber', pageNumber);
            result.put('pageSize',   pageSize);

            return result;

        } catch (Exception e) {
            LoggerUtil.logError('LeadController', 'getLeads', e, null);
            LoggerUtil.saveLogs();
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static void reassignLeads(List<Id> leadIds, Id newOwnerId) {
        try {
            List<Lead> leadsToUpdate = new List<Lead>();
            for (Id leadId : leadIds) {
                leadsToUpdate.add(new Lead(
                    Id      = leadId,
                    OwnerId = newOwnerId
                ));
            }
            update leadsToUpdate;
            LoggerUtil.logInfo(
                'LeadController', 'reassignLeads',
                leadsToUpdate.size() + ' leads reassigned to ' + newOwnerId,
                null
            );
            LoggerUtil.saveLogs();

        } catch (Exception e) {
            LoggerUtil.logError('LeadController', 'reassignLeads', e, null);
            LoggerUtil.saveLogs();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void refreshLeadScore(Id leadId) {
        try {
            List<Lead> leads = LeadSelector.getLeadsByIds(new Set<Id>{ leadId });
            if (!leads.isEmpty()) { LeadService.processNewLeads(leads); }
        } catch (Exception e) {
            LoggerUtil.logError(
                'LeadController', 'refreshLeadScore', e, leadId
            );
            LoggerUtil.saveLogs();
            throw new AuraHandledException(e.getMessage());
        }
    }
}