public without sharing class BookingController {

    @AuraEnabled
    public static List<Booking__c> getMyBookings() {
        Id contactId = getContactId();
        if (contactId == null) return new List<Booking__c>();
        return [
            SELECT Id, Booking_Number__c,
                   Total_Booking_Amount__c,
                   Total_Paid__c, Status__c,
                   Booking_Date__c,
                   Expected_Delivery_Date__c,
                   Model__c, Model__r.Name,
                   Variant__c, Variant__r.Name,
                   Contact__c,
                   Contact__r.FirstName,
                   Contact__r.LastName,
                   Contact__r.Email
            FROM Booking__c
            WHERE Contact__c = :contactId
            ORDER BY Booking_Date__c DESC
        ];
    }

    @AuraEnabled
    public static List<Payment__c> getPaymentsByBooking(
        Id bookingId
    ) {
        return [
            SELECT Id, Payment_Amount__c,
                   Payment_Date__c,
                   Payment_Method__c, Status__c
            FROM Payment__c
            WHERE Booking__c = :bookingId
            ORDER BY Payment_Date__c DESC
        ];
    }

    @AuraEnabled
    public static List<Test_Drive__c> getMyTestDrives() {
        Id contactId = getContactId();
        if (contactId == null) return new List<Test_Drive__c>();

        List<Lead> leads = [
            SELECT Id FROM Lead
            WHERE ConvertedContactId = :contactId
        ];

        if (leads.isEmpty()) {
            List<Contact> contacts = [
                SELECT Email FROM Contact
                WHERE Id = :contactId LIMIT 1
            ];
            if (!contacts.isEmpty()
                && !String.isBlank(contacts[0].Email)) {
                leads = [
                    SELECT Id FROM Lead
                    WHERE Email = :contacts[0].Email
                    LIMIT 10
                ];
            }
        }

        if (leads.isEmpty()) return new List<Test_Drive__c>();

        Set<Id> leadIds = new Set<Id>();
        for (Lead l : leads) leadIds.add(l.Id);

        return [
            SELECT Id,
                   Model__c, Model__r.Name,
                   Variant__c, Variant__r.Name,
                   Preferred_Date_Time__c,
                   Status__c, Notes__c, City__c
            FROM Test_Drive__c
            WHERE Lead__c IN :leadIds
            ORDER BY Preferred_Date_Time__c DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Contact getMyContact() {
        User u = [
            SELECT ContactId FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (u.ContactId == null) return null;
        return [
            SELECT Id, FirstName, LastName,
                   Email, Phone, MailingCity
            FROM Contact
            WHERE Id = :u.ContactId
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static Map<String, Object> getBookingReceipt(
        Id bookingId
    ) {
        Map<String, Object> receipt = new Map<String, Object>();
        List<Booking__c> bookings = [
            SELECT Id, Booking_Number__c,
                   Total_Booking_Amount__c, Total_Paid__c,
                   Status__c, Booking_Date__c,
                   Expected_Delivery_Date__c,
                   Model__r.Name, Model__r.Image_URL__c,
                   Variant__r.Name, Variant__r.Price__c,
                   Variant__r.Fuel_Type__c,
                   Variant__r.Transmission__c,
                   Contact__r.FirstName, Contact__r.LastName,
                   Contact__r.Email, Contact__r.Phone
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];
        if (bookings.isEmpty()) return receipt;
        List<Payment__c> payments = [
            SELECT Id, Name, Payment_Amount__c,
                   Payment_Date__c, Payment_Method__c, Status__c
            FROM Payment__c
            WHERE Booking__c = :bookingId
            AND Status__c = 'Completed'
            ORDER BY Payment_Date__c ASC
        ];
        receipt.put('booking',  bookings[0]);
        receipt.put('payments', payments);
        return receipt;
    }

    @AuraEnabled
    public static Map<String, Integer> getMyDashboardKPIs() {
        Id contactId = getContactId();
        Map<String, Integer> kpis = new Map<String, Integer>();
        if (contactId == null) {
            kpis.put('totalBookings',    0);
            kpis.put('approvedBookings', 0);
            kpis.put('totalTestDrives',  0);
            kpis.put('pendingPayments',  0);
            return kpis;
        }
        kpis.put('totalBookings', [
            SELECT COUNT() FROM Booking__c
            WHERE Contact__c = :contactId
        ]);
        kpis.put('approvedBookings', [
            SELECT COUNT() FROM Booking__c
            WHERE Contact__c = :contactId
            AND Status__c = 'Approved'
        ]);
        List<Lead> leads = [
            SELECT Id FROM Lead
            WHERE ConvertedContactId = :contactId
        ];
        Set<Id> leadIds = new Set<Id>();
        for (Lead l : leads) leadIds.add(l.Id);
        Integer tdCount = 0;
        if (!leadIds.isEmpty()) {
            tdCount = [
                SELECT COUNT() FROM Test_Drive__c
                WHERE Lead__c IN :leadIds
            ];
        }
        kpis.put('totalTestDrives', tdCount);
        List<Booking__c> approvedList = [
            SELECT Id, Total_Booking_Amount__c, Total_Paid__c
            FROM Booking__c
            WHERE Contact__c = :contactId
            AND Status__c = 'Approved'
        ];
        Integer pendingCount = 0;
        for (Booking__c b : approvedList) {
            Decimal paid  = b.Total_Paid__c == null ? 0 : b.Total_Paid__c;
            Decimal total = b.Total_Booking_Amount__c == null
                ? 0 : b.Total_Booking_Amount__c;
            if (paid < total) pendingCount++;
        }
        kpis.put('pendingPayments', pendingCount);
        return kpis;
    }

    private static Id getContactId() {
        User u = [
            SELECT ContactId FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        return u.ContactId;
    }
}