@isTest
private class LeadServiceTest {

    // ─────────────────────────────────────────
    // TEST DATA FACTORY
    // Ek jagah se saare tests ke liye
    // lead banate hain — DRY principle
    // ─────────────────────────────────────────
    private static Lead makeLead(String lastName, String company,
                                  String email, String phone,
                                  String source, String industry,
                                  Integer employees, Decimal revenue) {
        return new Lead(
            FirstName         = 'Test',
            LastName          = lastName,
            Company           = company,
            Email             = email,
            Phone             = phone,
            LeadSource        = source,
            Industry          = industry,
            NumberOfEmployees = employees,
            AnnualRevenue     = revenue,
            Status            = 'Open - Not Contacted'
        );
    }

    // ═════════════════════════════════════════
    // TEST 1 — HOT Lead Score
    // Partner Referral + Technology + 1000 emp
    // + 1Cr revenue = 100 score
    // ═════════════════════════════════════════
    @isTest
    static void testHotLeadScore() {

        Lead l = makeLead(
            'Sharma', 'Tech Giants Pvt Ltd',
            'rahul@techgiants.com', '9876543210',
            'Partner Referral', 'Technology',
            1500, 15000000
        );

        Test.startTest();
        insert l;
        Test.stopTest();

        Lead result = [
            SELECT Lead_Score__c, Score_Category__c
            FROM Lead WHERE Id = :l.Id
        ];

        System.assert(
            result.Lead_Score__c >= 70,
            'HOT lead score 70+ hona chahiye. Mila: ' + result.Lead_Score__c
        );
        System.assertEquals(
            'HOT', result.Score_Category__c,
            'Category HOT honi chahiye'
        );
    }

    // ═════════════════════════════════════════
    // TEST 2 — COLD Lead Score
    // Cold Call + Retail + kam employees
    // = low score
    // ═════════════════════════════════════════
    @isTest
    static void testColdLeadScore() {

        Lead l = makeLead(
            'Kumar', 'Small Shop',
            'small@shop.com', '9876543211',
            'Cold Call', 'Retail',
            10, 100000
        );

        Test.startTest();
        insert l;
        Test.stopTest();

        Lead result = [
            SELECT Lead_Score__c, Score_Category__c
            FROM Lead WHERE Id = :l.Id
        ];

        System.assert(
            result.Lead_Score__c < 40,
            'COLD lead score 40 se kam hona chahiye. Mila: ' + result.Lead_Score__c
        );
    }

    // ═════════════════════════════════════════
    // TEST 3 — Fake Email Flagged
    // mailinator.com = fake domain
    // Is_Duplicate__c = true hona chahiye
    // ═════════════════════════════════════════
    @isTest
    static void testFakeEmailFlagged() {

        Lead l = makeLead(
            'Fake', 'Some Company',
            'test@mailinator.com', '9876543212',
            'Web', 'Technology',
            100, 1000000
        );

        Test.startTest();
        insert l;
        Test.stopTest();

        Lead result = [
            SELECT Is_Duplicate__c
            FROM Lead WHERE Id = :l.Id
        ];

        System.assertEquals(
            true, result.Is_Duplicate__c,
            'Fake email domain Is_Duplicate__c = true karna chahiye'
        );
    }

    // ═════════════════════════════════════════
    // TEST 4 — Blacklisted Company Blocked
    // 'spam corp' insert nahi hona chahiye
    // ═════════════════════════════════════════
    @isTest
    static void testBlacklistedCompanyBlocked() {

        Lead l = makeLead(
            'Test', 'spam corp',
            'real@gmail.com', '9876543213',
            'Web', 'Technology',
            100, 1000000
        );

        Test.startTest();
        try {
            insert l;
            // Yahan nahi aana chahiye
            System.assert(
                false,
                'Blacklisted company insert hone nahi dena chahiye'
            );
        } catch (DmlException e) {
            // Yeh aana chahiye — error expected hai
            System.assert(
                e.getMessage().containsIgnoreCase('blacklisted'),
                'Error mein blacklisted mention hona chahiye'
            );
        }
        Test.stopTest();
    }

    // ═════════════════════════════════════════
    // TEST 5 — Follow Up Date Set
    // Insert ke baad 3 din baad date honi chahiye
    // ═════════════════════════════════════════
    @isTest
    static void testFollowUpDateSet() {

        Lead l = makeLead(
            'Singh', 'Good Company',
            'singh@good.com', '9876543214',
            'Web', 'Finance',
            200, 5000000
        );

        Test.startTest();
        insert l;
        Test.stopTest();

        Lead result = [
            SELECT Follow_Up_Date__c
            FROM Lead WHERE Id = :l.Id
        ];

        System.assertEquals(
            Date.today().addDays(3),
            result.Follow_Up_Date__c,
            'Follow up date aaj se 3 din baad honi chahiye'
        );
    }

    // ═════════════════════════════════════════
    // TEST 6 — Duplicate Email Detection
    // Same email se doosra lead = duplicate
    // ═════════════════════════════════════════
    @isTest
    static void testDuplicateEmailDetected() {

        // Pehla lead insert karo
        Lead first = makeLead(
            'First', 'Company One',
            'same@email.com', '9876543215',
            'Web', 'Technology',
            100, 1000000
        );
        insert first;

        // Same email se doosra lead
        Lead second = makeLead(
            'Second', 'Company Two',
            'same@email.com', '9876543216',
            'Web', 'Technology',
            100, 1000000
        );

        Test.startTest();
        insert second;
        Test.stopTest();

        Lead result = [
            SELECT Is_Duplicate__c
            FROM Lead WHERE Id = :second.Id
        ];

        System.assertEquals(
            true, result.Is_Duplicate__c,
            'Same email wala lead duplicate flag hona chahiye'
        );
    }

    // ═════════════════════════════════════════
    // TEST 7 — Score Update on Field Change
    // Industry/Source change hone par
    // score update hona chahiye
    // ═════════════════════════════════════════
    @isTest
    static void testScoreUpdatesOnFieldChange() {

        Lead l = makeLead(
            'Update', 'Medium Co',
            'update@medium.com', '9876543217',
            'Cold Call', 'Retail',
            30, 500000
        );
        insert l;

        Lead before = [
            SELECT Lead_Score__c FROM Lead WHERE Id = :l.Id
        ];

        Test.startTest();
        // Score badhane wale fields update karo
        l.LeadSource        = 'Partner Referral';
        l.Industry          = 'Technology';
        l.NumberOfEmployees = 2000;
        l.AnnualRevenue     = 20000000;
        update l;
        Test.stopTest();

        Lead after = [
            SELECT Lead_Score__c FROM Lead WHERE Id = :l.Id
        ];

        System.assert(
            after.Lead_Score__c > before.Lead_Score__c,
            'Fields update hone par score badhna chahiye'
        );
    }

    // ═════════════════════════════════════════
    // TEST 8 — Bulk Insert 200 Leads
    // Governor limits test
    // 200 leads ek saath insert hone chahiye
    // ═════════════════════════════════════════
    @isTest
    static void testBulkInsert200Leads() {

        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            leads.add(makeLead(
                'Bulk' + i,
                'Bulk Company ' + i,
                'bulk' + i + '@gmail.com',
                '98765' + String.valueOf(i).leftPad(5, '0'),
                'Web',
                'Technology',
                100, 1000000
            ));
        }

        Test.startTest();
        insert leads; // Governor limit nahi aani chahiye
        Test.stopTest();

        Integer scored = [
            SELECT COUNT() FROM Lead
            WHERE Lead_Score__c != null
            AND Company LIKE 'Bulk Company %'
        ];

        System.assertEquals(
            200, scored,
            'Saare 200 leads score hone chahiye'
        );
    }

    // ═════════════════════════════════════════
    // TEST 9 — LeadController Stats
    // Dashboard stats sahi aane chahiye
    // ═════════════════════════════════════════
    @isTest
    static void testLeadControllerStats() {

        // 1 HOT lead banao
        Lead hotLead = makeLead(
            'Hot', 'Hot Company',
            'hot@company.com', '9876540001',
            'Partner Referral', 'Technology',
            1500, 15000000
        );
        insert hotLead;

        Test.startTest();
        Map<String, Object> stats = LeadController.getLeadDashboardStats();
        Test.stopTest();

        System.assertNotEquals(
            null, stats,
            'Stats null nahi hone chahiye'
        );
        System.assert(
            (Integer)stats.get('totalLeads') > 0,
            'Total leads 0 se zyada hone chahiye'
        );
    }

    // ═════════════════════════════════════════
    // TEST 10 — LeadController getLeads
    // Pagination sahi kaam karni chahiye
    // ═════════════════════════════════════════
    @isTest
    static void testLeadControllerGetLeads() {

        Lead l = makeLead(
            'Page', 'Page Company',
            'page@company.com', '9876540002',
            'Web', 'Finance',
            200, 5000000
        );
        insert l;

        Test.startTest();
        Map<String, Object> result = LeadController.getLeads(
            '',     // searchTerm
            'All',  // statusFilter
            '',     // scoreFilter
            1,      // pageNumber
            10      // pageSize
        );
        Test.stopTest();

        System.assertNotEquals(
            null, result,
            'Result null nahi hona chahiye'
        );
        System.assert(
            (Integer)result.get('totalCount') > 0,
            'Total count 0 se zyada hona chahiye'
        );
    }
}