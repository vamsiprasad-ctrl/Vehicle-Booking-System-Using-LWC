public without sharing class PartnerTestDriveController {

    @AuraEnabled(cacheable=true)
    public static List<Test_Drive__c> getTestDrives(
        String statusFilter
    ) {
        Id currentUserId = UserInfo.getUserId();
        Boolean isManager = isManager();

        String query =
            'SELECT Id, ' +
            'Lead__c, Lead__r.FirstName, Lead__r.LastName, ' +
            'Lead__r.Email, Lead__r.Phone, ' +
            'Model__c, Model__r.Name, ' +
            'Variant__c, Variant__r.Name, ' +
            'Preferred_Date_Time__c, ' +
            'Status__c, Notes__c, City__c, ' +
            'OwnerId, Owner.Name, ' +
            'Customer_First_Name__c, ' +
            'Customer_Last_Name__c, ' +
            'Customer_Email__c, ' +
            'Customer_Phone__c ' +
            'FROM Test_Drive__c ';

        if (!isManager) {
            query += 'WHERE OwnerId = \''
                + currentUserId + '\' ';
            if (!String.isBlank(statusFilter)
                && statusFilter != 'all') {
                query += 'AND Status__c = \''
                    + statusFilter + '\' ';
            }
        } else {
            if (!String.isBlank(statusFilter)
                && statusFilter != 'all') {
                query += 'WHERE Status__c = \''
                    + statusFilter + '\' ';
            }
        }

        query += 'ORDER BY Preferred_Date_Time__c ASC LIMIT 100';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<Test_Drive__c> getTodaysTestDrives() {
        Date today = Date.today();
        DateTime startOfDay = DateTime.newInstance(
            today, Time.newInstance(0,0,0,0));
        DateTime endOfDay = DateTime.newInstance(
            today, Time.newInstance(23,59,59,0));
        Boolean isManager  = isManager();
        Id currentUserId   = UserInfo.getUserId();

        if (isManager) {
            return [
                SELECT Id,
                       Lead__r.FirstName, Lead__r.LastName,
                       Lead__r.Phone,
                       Model__r.Name, Variant__r.Name,
                       Preferred_Date_Time__c,
                       Status__c, City__c, Owner.Name,
                       Customer_First_Name__c,
                       Customer_Last_Name__c
                FROM Test_Drive__c
                WHERE Preferred_Date_Time__c >= :startOfDay
                AND   Preferred_Date_Time__c <= :endOfDay
                ORDER BY Preferred_Date_Time__c ASC
            ];
        }
        return [
            SELECT Id,
                   Lead__r.FirstName, Lead__r.LastName,
                   Lead__r.Phone,
                   Model__r.Name, Variant__r.Name,
                   Preferred_Date_Time__c,
                   Status__c, City__c, Owner.Name,
                   Customer_First_Name__c,
                   Customer_Last_Name__c
            FROM Test_Drive__c
            WHERE OwnerId = :currentUserId
            AND   Preferred_Date_Time__c >= :startOfDay
            AND   Preferred_Date_Time__c <= :endOfDay
            ORDER BY Preferred_Date_Time__c ASC
        ];
    }

    @AuraEnabled
    public static String confirmTestDrive(Id testDriveId) {
        try {
            Test_Drive__c td = [
                SELECT Id, Status__c
                FROM Test_Drive__c
                WHERE Id = :testDriveId
                LIMIT 1
            ];
            if (td.Status__c != 'Requested') {
                throw new AuraHandledException(
                    'Only Requested test drives can be confirmed.'
                );
            }
            td.Status__c             = 'Confirmed';
            td.Bypass_Validation__c  = true;
            update td;
            // Reset bypass in separate async transaction
            resetBypassFlag(testDriveId);
            return 'Confirmed';
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error confirming: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static String completeTestDrive(
        Id testDriveId, String notes
    ) {
        try {
            if (String.isBlank(notes)) {
                throw new AuraHandledException(
                    'Notes are required to complete a test drive.'
                );
            }
            Test_Drive__c td = [
                SELECT Id, Status__c
                FROM Test_Drive__c
                WHERE Id = :testDriveId
                LIMIT 1
            ];
            if (td.Status__c != 'Confirmed') {
                throw new AuraHandledException(
                    'Only Confirmed test drives can be completed.'
                );
            }
            td.Status__c            = 'Completed';
            td.Notes__c             = notes;
            td.Bypass_Validation__c = true;
            update td;
            resetBypassFlag(testDriveId);
            return 'Completed';
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error completing: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static String cancelTestDrive(Id testDriveId) {
        try {
            Test_Drive__c td = [
                SELECT Id, Status__c
                FROM Test_Drive__c
                WHERE Id = :testDriveId
                LIMIT 1
            ];
            if (td.Status__c == 'Completed'
                || td.Status__c == 'Cancelled') {
                throw new AuraHandledException(
                    'This test drive cannot be cancelled.'
                );
            }
            td.Status__c            = 'Cancelled';
            td.Bypass_Validation__c = true;
            update td;
            resetBypassFlag(testDriveId);
            return 'Cancelled';
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error cancelling: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserRole() {
        return isManager() ? 'Manager' : 'Executive';
    }

    // Runs in separate transaction — no DML limit issue
    @future
    private static void resetBypassFlag(Id testDriveId) {
        try {
            Test_Drive__c td = new Test_Drive__c(
                Id                   = testDriveId,
                Bypass_Validation__c = false
            );
            update td;
        } catch (Exception e) {
            System.debug('resetBypassFlag error: ' + e.getMessage());
        }
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