public without sharing class PartnerPaymentController {

    @AuraEnabled(cacheable=true)
    public static List<Payment__c> getAllPayments(String methodFilter) {
        Id currentUserId = UserInfo.getUserId();
        Boolean isManager = isManager();

        String query =
            'SELECT Id, Name, Payment_Amount__c, ' +
            'Payment_Date__c, Payment_Method__c, Status__c, ' +
            'Booking__c, Booking__r.Booking_Number__c, ' +
            'Booking__r.Contact__r.FirstName, ' +
            'Booking__r.Contact__r.LastName, ' +
            'Booking__r.Model__r.Name, ' +
            'Booking__r.OwnerId ' +
            'FROM Payment__c ' +
            'WHERE Status__c = \'Completed\' ';

        if (!isManager) {
            query += 'AND Booking__r.OwnerId = \'' + currentUserId + '\' ';
        }

        if (!String.isBlank(methodFilter) && methodFilter != 'all') {
            query += 'AND Payment_Method__c = \'' + methodFilter + '\' ';
        }

        query += 'ORDER BY Payment_Date__c DESC LIMIT 100';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPaymentSummary() {
        Id currentUserId = UserInfo.getUserId();
        Boolean isManager = isManager();

        Map<String, Object> summary = new Map<String, Object>();

        String ownerFilter = isManager
            ? ''
            : 'AND Booking__r.OwnerId = \'' + currentUserId + '\' ';

        List<AggregateResult> totalResult = Database.query(
            'SELECT SUM(Payment_Amount__c) total ' +
            'FROM Payment__c ' +
            'WHERE Status__c = \'Completed\' ' + ownerFilter
        );
        summary.put('totalCollected',
            totalResult[0].get('total') != null
                ? totalResult[0].get('total') : 0);

        Date firstDay = Date.today().toStartOfMonth();
        List<AggregateResult> monthResult = Database.query(
            'SELECT SUM(Payment_Amount__c) total ' +
            'FROM Payment__c ' +
            'WHERE Status__c = \'Completed\' ' +
            ownerFilter +
            'AND Payment_Date__c >= :firstDay'
        );
        summary.put('thisMonth',
            monthResult[0].get('total') != null
                ? monthResult[0].get('total') : 0);

        List<AggregateResult> byMethod = Database.query(
            'SELECT Payment_Method__c method, ' +
            'SUM(Payment_Amount__c) total, COUNT(Id) cnt ' +
            'FROM Payment__c ' +
            'WHERE Status__c = \'Completed\' ' +
            ownerFilter +
            'GROUP BY Payment_Method__c'
        );

        List<Map<String, Object>> methodBreakdown =
            new List<Map<String, Object>>();
        for (AggregateResult ar : byMethod) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('method', ar.get('method'));
            row.put('total',  ar.get('total'));
            row.put('count',  ar.get('cnt'));
            methodBreakdown.add(row);
        }
        summary.put('byMethod', methodBreakdown);

        List<Booking__c> approvedBookings = isManager
            ? [SELECT Id, Total_Booking_Amount__c, Total_Paid__c
               FROM Booking__c WHERE Status__c = 'Approved']
            : [SELECT Id, Total_Booking_Amount__c, Total_Paid__c
               FROM Booking__c
               WHERE Status__c = 'Approved'
               AND OwnerId = :currentUserId];

        Decimal outstanding = 0;
        for (Booking__c b : approvedBookings) {
            Decimal paid  = b.Total_Paid__c != null ? b.Total_Paid__c : 0;
            Decimal total = b.Total_Booking_Amount__c != null
                ? b.Total_Booking_Amount__c : 0;
            outstanding += Math.max(0, total - paid);
        }
        summary.put('totalOutstanding', outstanding);
        summary.put('isManager', isManager);
        return summary;
    }

    @AuraEnabled(cacheable=true)
    public static List<Booking__c> getOutstandingBookings() {
        Id currentUserId = UserInfo.getUserId();
        Boolean isManager = isManager();

        List<Booking__c> bookings = isManager
            ? [SELECT Id, Booking_Number__c,
                      Contact__r.FirstName, Contact__r.LastName,
                      Contact__r.Email, Contact__r.Phone,
                      Model__r.Name, Variant__r.Name,
                      Total_Booking_Amount__c, Total_Paid__c,
                      Status__c, Expected_Delivery_Date__c,
                      Owner.Name
               FROM Booking__c
               WHERE Status__c = 'Approved'
               ORDER BY Expected_Delivery_Date__c ASC]
            : [SELECT Id, Booking_Number__c,
                      Contact__r.FirstName, Contact__r.LastName,
                      Contact__r.Email, Contact__r.Phone,
                      Model__r.Name, Variant__r.Name,
                      Total_Booking_Amount__c, Total_Paid__c,
                      Status__c, Expected_Delivery_Date__c,
                      Owner.Name
               FROM Booking__c
               WHERE Status__c = 'Approved'
               AND OwnerId = :currentUserId
               ORDER BY Expected_Delivery_Date__c ASC];

        List<Booking__c> outstanding = new List<Booking__c>();
        for (Booking__c b : bookings) {
            Decimal paid  = b.Total_Paid__c != null ? b.Total_Paid__c : 0;
            Decimal total = b.Total_Booking_Amount__c != null
                ? b.Total_Booking_Amount__c : 0;
            if (paid < total) outstanding.add(b);
        }
        return outstanding;
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