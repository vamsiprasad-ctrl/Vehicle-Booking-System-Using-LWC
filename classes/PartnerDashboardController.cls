public without sharing class PartnerDashboardController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardStats() {
        Map<String, Object> stats = new Map<String, Object>();
        Id currentUserId = UserInfo.getUserId();
        Boolean isManager = isManager();

        if (isManager) {
            stats.put('totalLeads', [
                SELECT COUNT() FROM Lead
                WHERE IsConverted = false
            ]);
            stats.put('newLeads', [
                SELECT COUNT() FROM Lead
                WHERE IsConverted = false
                AND Status = 'New'
            ]);
            stats.put('totalTestDrives', [
                SELECT COUNT() FROM Test_Drive__c
            ]);
            stats.put('scheduledTestDrives', [
                SELECT COUNT() FROM Test_Drive__c
                WHERE Status__c = 'Confirmed'
            ]);
            stats.put('totalBookings', [
                SELECT COUNT() FROM Booking__c
            ]);
            stats.put('pendingApprovals', [
                SELECT COUNT() FROM Booking__c
                WHERE Status__c = 'Pending'
            ]);
            stats.put('approvedBookings', [
                SELECT COUNT() FROM Booking__c
                WHERE Status__c = 'Approved'
            ]);
            stats.put('deliveredBookings', [
                SELECT COUNT() FROM Booking__c
                WHERE Status__c = 'Delivered'
            ]);
            Date firstDay = Date.today().toStartOfMonth();
            List<AggregateResult> revenue = [
                SELECT SUM(Payment_Amount__c) total
                FROM Payment__c
                WHERE Status__c = 'Completed'
                AND Payment_Date__c >= :firstDay
            ];
            stats.put('monthlyRevenue',
                revenue[0].get('total') != null
                    ? revenue[0].get('total') : 0);
        } else {
            stats.put('totalLeads', [
                SELECT COUNT() FROM Lead
                WHERE OwnerId = :currentUserId
                AND IsConverted = false
            ]);
            stats.put('newLeads', [
                SELECT COUNT() FROM Lead
                WHERE OwnerId = :currentUserId
                AND IsConverted = false
                AND Status = 'New'
            ]);
            stats.put('totalTestDrives', [
                SELECT COUNT() FROM Test_Drive__c
                WHERE OwnerId = :currentUserId
            ]);
            stats.put('scheduledTestDrives', [
                SELECT COUNT() FROM Test_Drive__c
                WHERE OwnerId = :currentUserId
                AND Status__c = 'Confirmed'
            ]);
            stats.put('totalBookings', [
                SELECT COUNT() FROM Booking__c
                WHERE OwnerId = :currentUserId
            ]);
            stats.put('pendingApprovals', [
                SELECT COUNT() FROM Booking__c
                WHERE OwnerId = :currentUserId
                AND Status__c = 'Pending'
            ]);
            stats.put('approvedBookings', [
                SELECT COUNT() FROM Booking__c
                WHERE OwnerId = :currentUserId
                AND Status__c = 'Approved'
            ]);
            stats.put('deliveredBookings', [
                SELECT COUNT() FROM Booking__c
                WHERE OwnerId = :currentUserId
                AND Status__c = 'Delivered'
            ]);
            stats.put('monthlyRevenue', 0);
        }

        stats.put('isManager', isManager);
        return stats;
    }

    @AuraEnabled(cacheable=true)
    public static List<Lead> getRecentLeads() {
        Id currentUserId = UserInfo.getUserId();
        Boolean isManager = isManager();
        if (isManager) {
            return [
                SELECT Id, FirstName, LastName, Email,
                       Phone, Status, LeadSource,
                       City, CreatedDate
                FROM Lead
                WHERE IsConverted = false
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];
        }
        return [
            SELECT Id, FirstName, LastName, Email,
                   Phone, Status, LeadSource,
                   City, CreatedDate
            FROM Lead
            WHERE OwnerId = :currentUserId
            AND IsConverted = false
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Test_Drive__c> getRecentTestDrives() {
        Id currentUserId = UserInfo.getUserId();
        Boolean isManager = isManager();
        if (isManager) {
            return [
                SELECT Id, Lead__r.FirstName, Lead__r.LastName,
                       Model__r.Name, Variant__r.Name,
                       Preferred_Date_Time__c, Status__c, City__c
                FROM Test_Drive__c
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];
        }
        return [
            SELECT Id, Lead__r.FirstName, Lead__r.LastName,
                   Model__r.Name, Variant__r.Name,
                   Preferred_Date_Time__c, Status__c, City__c
            FROM Test_Drive__c
            WHERE OwnerId = :currentUserId
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Booking__c> getRecentBookings() {
        Id currentUserId = UserInfo.getUserId();
        Boolean isManager = isManager();
        if (isManager) {
            return [
                SELECT Id, Booking_Number__c,
                       Contact__r.FirstName, Contact__r.LastName,
                       Model__r.Name, Variant__r.Name,
                       Total_Booking_Amount__c, Total_Paid__c,
                       Status__c, Booking_Date__c
                FROM Booking__c
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];
        }
        return [
            SELECT Id, Booking_Number__c,
                   Contact__r.FirstName, Contact__r.LastName,
                   Model__r.Name, Variant__r.Name,
                   Total_Booking_Amount__c, Total_Paid__c,
                   Status__c, Booking_Date__c
            FROM Booking__c
            WHERE OwnerId = :currentUserId
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
    }

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserRole() {
        return isManager() ? 'Manager' : 'Executive';
    }

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserName() {
        User u = [
            SELECT Name FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        return u.Name;
    }

    private static Boolean isManager() {
        User u = [
            SELECT Profile.Name FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        return u.Profile.Name == 'Sales Manager';
    }
}