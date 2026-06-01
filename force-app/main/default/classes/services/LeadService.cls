public with sharing class LeadService {

    // ─────────────────────────────────────────
    // CONSTANTS — Fake email domains
    // ─────────────────────────────────────────
    private static final Set<String> FAKE_EMAIL_DOMAINS = new Set<String>{
        'mailinator.com', 'guerrillamail.com', 'tempmail.com',
        'throwaway.email', 'yopmail.com', 'sharklasers.com',
        'trashmail.com', 'fakeinbox.com', 'dispostable.com'
    };

    // ─────────────────────────────────────────
    // CONSTANTS — Blacklisted companies
    // ─────────────────────────────────────────
    private static final Set<String> BLACKLISTED_COMPANIES = new Set<String>{
        'spam corp', 'test company', 'fake business', 'abc xyz'
    };

    public static void validateLeadsBeforeInsert(List<Lead> newLeads) {
        for (Lead l : newLeads) {

            // Blacklisted company? — do not save record
            if (isBlacklistedCompany(l.Company)) {
                l.addError('This company is blacklisted. Lead cannot be created.');
            }
        }
    }

    public static void processNewLeads(List<Lead> newLeads) {
        Set<String> emails = new Set<String>();
        Set<String> phones = new Set<String>();
        Set<Id> newLeadIds = new Set<Id>();
        for (Lead l : newLeads) {
            newLeadIds.add(l.Id);
            if (String.isNotBlank(l.Email)) {
                emails.add(l.Email.toLowerCase());
            }
            if (String.isNotBlank(l.Phone)) {
                phones.add(l.Phone);
            }
        }

        Map<String, Id> existingEmailMap = buildEmailMap(
            LeadSelector.findDuplicatesByEmail(emails,newLeadIds)
        );
        Map<String, Id> existingPhoneMap = buildPhoneMap(
            LeadSelector.findDuplicatesByPhone(phones,newLeadIds)
        );

        // Business Rules load from Custom Metadata
        Map<String, Business_Rule__mdt> rules = loadBusinessRules();
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead l : newLeads) {
            Lead updatedLead = new Lead(Id = l.Id);
            if (isFakeEmailDomain(l.Email)) {
                updatedLead.Is_Duplicate__c = true;
                LoggerUtil.logWarning(
                    'LeadService', 'processNewLeads',
                    'Fake email domain: ' + l.Email,
                    l.Id
                );
            }

            // ── Duplicate email check ──
            if (String.isNotBlank(l.Email)) {
                String emailKey = l.Email.toLowerCase();
                // Map mein hai AND woh koi aur lead hai (current nahi)
                if (existingEmailMap.containsKey(emailKey)) {
                    Id existingId = existingEmailMap.get(emailKey);
                    // Agar existing lead ka Id current lead se alag hai
                    // toh duplicate hai
                    if (existingId != l.Id) {
                        updatedLead.Is_Duplicate__c = true;
                        LoggerUtil.logWarning(
                            'LeadService', 'processNewLeads',
                            'Duplicate email found: ' + l.Email,
                            l.Id
                        );
                    }
                }
            }

            // ── Duplicate phone check ──
            if (String.isNotBlank(l.Phone)) {
                if (existingPhoneMap.containsKey(l.Phone) &&
                    existingPhoneMap.get(l.Phone) != l.Id) {
                    updatedLead.Is_Duplicate__c = true;
                    LoggerUtil.logWarning(
                        'LeadService', 'processNewLeads',
                        'Duplicate phone found: ' + l.Phone,
                        l.Id
                    );
                }
            }
            Integer score = calculateLeadScore(l, rules);
            updatedLead.Lead_Score__c = score;
            updatedLead.Follow_Up_Date__c = Date.today().addDays(3);
            leadsToUpdate.add(updatedLead);
        }
        if (!leadsToUpdate.isEmpty()) {
            try {
                update leadsToUpdate;
                LoggerUtil.logInfo(
                    'LeadService', 'processNewLeads',
                    leadsToUpdate.size() + ' leads processed successfully.',
                    null
                );
            } catch (DmlException e) {
                LoggerUtil.logError('LeadService', 'processNewLeads', e, null);
            }
        }
        LoggerUtil.saveLogs();
    }


    public static void rescoreUpdatedLeads(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        List<Lead> leadsToRescore = new List<Lead>();
        Map<String, Business_Rule__mdt> rules = loadBusinessRules();
        for (Lead l : newLeads) {
            Lead oldLead = oldLeadMap.get(l.Id);
            Boolean relevantFieldChanged =
                l.AnnualRevenue     != oldLead.AnnualRevenue     ||
                l.NumberOfEmployees != oldLead.NumberOfEmployees ||
                l.LeadSource        != oldLead.LeadSource        ||
                l.Industry          != oldLead.Industry;

            if (relevantFieldChanged) {
                Lead updatedLead = new Lead(Id = l.Id);
                updatedLead.Lead_Score__c = calculateLeadScore(l, rules);
                leadsToRescore.add(updatedLead);
            }
        }

        if (!leadsToRescore.isEmpty()) {
            try {
                update leadsToRescore;
            } catch (DmlException e) {
                LoggerUtil.logError('LeadService', 'rescoreUpdatedLeads', e, null);
                LoggerUtil.saveLogs();
            }
        }
    }

    private static Integer calculateLeadScore(Lead l, Map<String, Business_Rule__mdt> rules) {
        Integer score = 0;
        if (l.AnnualRevenue != null) {
            if (l.AnnualRevenue >= 10000000) score += 30; // 1 Crore+
            else if (l.AnnualRevenue >= 5000000)  score += 20; // 50 Lakh+
            else if (l.AnnualRevenue >= 1000000)  score += 10; // 10 Lakh+
        }

        // Employees points — max 25
        if (l.NumberOfEmployees != null) {
            if (l.NumberOfEmployees >= 1000) score += 25;
            else if (l.NumberOfEmployees >= 200)  score += 15;
            else if (l.NumberOfEmployees >= 50)   score += 8;
        }

        // Lead Source points — max 25
        if (l.LeadSource != null) {
            switch on l.LeadSource {
                when 'Partner Referral'  { score += 25; }
                when 'Employee Referral' { score += 20; }
                when 'Web'               { score += 15; }
                when 'Trade Show'        { score += 12; }
                when 'Campaign'          { score += 10; }
                when 'Phone Inquiry'     { score += 8;  }
                when else                { score += 5;  }
            }
        }

        // Industry points — max 20
        if (l.Industry != null) {
            switch on l.Industry {
                when 'Technology'    { score += 20; }
                when 'Finance'       { score += 18; }
                when 'Healthcare'    { score += 15; }
                when 'Manufacturing' { score += 12; }
                when else            { score += 5;  }
            }
        }
        return Math.min(score, 100);
    }

    // ─────────────────────────────────────────
    // Fake email domain check
    // ─────────────────────────────────────────
    private static Boolean isFakeEmailDomain(String email) {
        if (String.isBlank(email)) return false;
        String domain = email.substringAfter('@').toLowerCase();
        return FAKE_EMAIL_DOMAINS.contains(domain);
    }

    // ─────────────────────────────────────────
    // Blacklisted company check
    // ─────────────────────────────────────────
    private static Boolean isBlacklistedCompany(String company) {
        if (String.isBlank(company)) return false;
        return BLACKLISTED_COMPANIES.contains(company.toLowerCase().trim());
    }

    private static Map<String, Id> buildEmailMap(List<Lead> leads) {
        Map<String, Id> emailMap = new Map<String, Id>();
        for (Lead l : leads) {
            if (String.isNotBlank(l.Email)) {
                emailMap.put(l.Email.toLowerCase(), l.Id);
            }
        }
        return emailMap;
    }

    private static Map<String, Id> buildPhoneMap(List<Lead> leads) {
        Map<String, Id> phoneMap = new Map<String, Id>();
        for (Lead l : leads) {
            if (String.isNotBlank(l.Phone)) {
                phoneMap.put(l.Phone, l.Id);
            }
        }
        return phoneMap;
    }

    private static Map<String, Business_Rule__mdt> loadBusinessRules() {
        Map<String, Business_Rule__mdt> ruleMap = new Map<String, Business_Rule__mdt>();
        for (Business_Rule__mdt rule : [
            SELECT Rule_Name__c, Numeric_Value__c,
                   Text_Value__c, Is_Active__c
            FROM Business_Rule__mdt
            WHERE Is_Active__c = true
        ]) {
            ruleMap.put(rule.Rule_Name__c, rule);
        }
        return ruleMap;
    }
}