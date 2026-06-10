public without sharing class DashboardController {

    @AuraEnabled(cacheable=true)
    public static List<Lead> getMyLeads() {
        return [
            SELECT Id, FirstName, LastName, Email, Phone,
                   Status, LeadSource, CreatedDate,
                   Preferred_Variant__r.Name
            FROM Lead
            WHERE OwnerId = :UserInfo.getUserId()
            AND IsConverted = false
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getMyOpportunities() {
        return [
            SELECT Id, Name, StageName, Amount,
                   CloseDate, Account.Name
            FROM Opportunity
            WHERE OwnerId = :UserInfo.getUserId()
            AND IsClosed = false
            ORDER BY CloseDate ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Booking__c> getPendingApprovals() {
        return [
            SELECT Id, Booking_Number__c,
                   Total_Booking_Amount__c,
                   Status__c, Booking_Date__c,
                   Contact__r.Name, Variant__r.Name
            FROM Booking__c
            WHERE Status__c = 'Pending'
            ORDER BY Booking_Date__c ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getDashboardKPIs() {
        Map<String, Integer> kpis = new Map<String, Integer>();
        kpis.put('openLeads', [
            SELECT COUNT() FROM Lead
            WHERE OwnerId = :UserInfo.getUserId()
            AND IsConverted = false
        ]);
        kpis.put('pendingApprovals', [
            SELECT COUNT() FROM Booking__c
            WHERE Status__c = 'Pending'
        ]);
        List<Opportunity> myOpps = [
            SELECT Id FROM Opportunity
            WHERE OwnerId = :UserInfo.getUserId()
        ];
        Set<Id> myOppIds = new Set<Id>();
        for (Opportunity o : myOpps) myOppIds.add(o.Id);
        Integer monthlyCount = 0;
        if (!myOppIds.isEmpty()) {
            monthlyCount = [
                SELECT COUNT() FROM Booking__c
                WHERE Booking_Date__c = THIS_MONTH
                AND Opportunity__c IN :myOppIds
            ];
        }
        kpis.put('monthlyBookings', monthlyCount);
        kpis.put('activeOpportunities', [
            SELECT COUNT() FROM Opportunity
            WHERE OwnerId = :UserInfo.getUserId()
            AND IsClosed = false
        ]);
        return kpis;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isCurrentUserManager() {
        User u = [
            SELECT Profile.Name FROM User
            WHERE Id = :UserInfo.getUserId() LIMIT 1
        ];
        return u.Profile.Name == 'Sales Manager';
    }

    @AuraEnabled(cacheable=true)
    public static List<Test_Drive__c> getMyTestDrives() {
        return [
            SELECT Id, Lead__r.FirstName, Lead__r.LastName,
                   Lead__r.Phone, Model__r.Name, Variant__r.Name,
                   Preferred_Date_Time__c, Status__c, Notes__c
            FROM Test_Drive__c
            WHERE OwnerId = :UserInfo.getUserId()
            ORDER BY Preferred_Date_Time__c ASC
        ];
    }
}