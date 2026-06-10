public without sharing class PartnerCustomerController {

    @AuraEnabled(cacheable=true)
    public static List<Contact> getCustomers(String searchKey) {
        Id currentUserId = UserInfo.getUserId();
        Boolean isManager = isManager();

        String query =
            'SELECT Id, FirstName, LastName, Email, Phone, ' +
            'MailingCity, CreatedDate, OwnerId, Owner.Name, ' +
            'AccountId, Account.Name ' +
            'FROM Contact ';

        List<String> conditions = new List<String>();

        if (!isManager) {
            conditions.add('OwnerId = \'' + currentUserId + '\'');
        }

        if (!String.isBlank(searchKey)) {
            String s = String.escapeSingleQuotes(searchKey);
            conditions.add(
                '(FirstName LIKE \'%' + s + '%\' ' +
                'OR LastName LIKE \'%' + s + '%\' ' +
                'OR Email LIKE \'%' + s + '%\' ' +
                'OR Phone LIKE \'%' + s + '%\')'
            );
        }

        if (!conditions.isEmpty()) {
            query += 'WHERE ' + String.join(conditions, ' AND ') + ' ';
        }

        query += 'ORDER BY CreatedDate DESC LIMIT 100';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCustomerProfile(Id contactId) {
        Map<String, Object> profile = new Map<String, Object>();

        Contact c = [
            SELECT Id, FirstName, LastName, Email,
                   Phone, MailingCity, CreatedDate,
                   OwnerId, Owner.Name,
                   AccountId, Account.Name
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];

        List<Booking__c> bookings = [
            SELECT Id, Booking_Number__c,
                   Model__r.Name, Variant__r.Name,
                   Total_Booking_Amount__c, Total_Paid__c,
                   Status__c, Booking_Date__c,
                   Expected_Delivery_Date__c
            FROM Booking__c
            WHERE Contact__c = :contactId
            ORDER BY Booking_Date__c DESC
        ];

        List<Lead> leads = [
            SELECT Id FROM Lead
            WHERE ConvertedContactId = :contactId
            AND IsConverted = true
        ];

        Set<Id> leadIds = new Set<Id>();
        for (Lead l : leads) leadIds.add(l.Id);

        List<Test_Drive__c> testDrives = new List<Test_Drive__c>();
        if (!leadIds.isEmpty()) {
            testDrives = [
                SELECT Id, Model__r.Name, Variant__r.Name,
                       Preferred_Date_Time__c, Status__c,
                       Notes__c, City__c
                FROM Test_Drive__c
                WHERE Lead__c IN :leadIds
                ORDER BY Preferred_Date_Time__c DESC
            ];
        }

        Set<Id> bookingIds = new Set<Id>();
        for (Booking__c b : bookings) bookingIds.add(b.Id);

        List<Payment__c> payments = new List<Payment__c>();
        if (!bookingIds.isEmpty()) {
            payments = [
                SELECT Id, Payment_Amount__c,
                       Payment_Date__c, Payment_Method__c,
                       Status__c, Booking__r.Booking_Number__c
                FROM Payment__c
                WHERE Booking__c IN :bookingIds
                AND Status__c = 'Completed'
                ORDER BY Payment_Date__c DESC
            ];
        }

        profile.put('contact',    c);
        profile.put('bookings',   bookings);
        profile.put('testDrives', testDrives);
        profile.put('payments',   payments);
        return profile;
    }

    @AuraEnabled(cacheable=true)
    public static String sendEmailToCustomer(
        Id contactId,
        String subject,
        String body
    ) {
        try {
            Contact c = [
                SELECT Id, Email, FirstName
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];
            if (String.isBlank(c.Email)) {
                throw new AuraHandledException(
                    'Customer does not have an email address.'
                );
            }
            EmailUtility.sendEmail(c.Email, subject, body);
            return 'Success';
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error sending email: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserRole() {
        return isManager() ? 'Manager' : 'Executive';
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