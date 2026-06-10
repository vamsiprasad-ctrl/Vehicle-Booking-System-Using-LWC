public without sharing class PartnerBookingController {

    @AuraEnabled
    public static List<Booking__c> getBookings(
        String statusFilter
    ) {
        Id currentUserId = UserInfo.getUserId();
        Boolean isManager = isManager();

        String query =
            'SELECT Id, Booking_Number__c, ' +
            'Contact__c, Contact__r.FirstName, ' +
            'Contact__r.LastName, ' +
            'Contact__r.Email, Contact__r.Phone, ' +
            'Model__c, Model__r.Name, ' +
            'Variant__c, Variant__r.Name, ' +
            'Total_Booking_Amount__c, Total_Paid__c, ' +
            'Status__c, Booking_Date__c, ' +
            'Expected_Delivery_Date__c, ' +
            'Rejection_Reason__c, ' +
            'OwnerId, Owner.Name ' +
            'FROM Booking__c ';

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

        query += 'ORDER BY CreatedDate DESC LIMIT 100';
        return Database.query(query);
    }

    @AuraEnabled
    public static List<Booking__c> getPendingApprovals() {
        return [
            SELECT Id, Booking_Number__c,
                   Contact__r.FirstName, Contact__r.LastName,
                   Contact__r.Email, Contact__r.Phone,
                   Model__r.Name, Variant__r.Name,
                   Total_Booking_Amount__c,
                   Status__c, Booking_Date__c,
                   Expected_Delivery_Date__c,
                   OwnerId, Owner.Name
            FROM Booking__c
            WHERE Status__c = 'Pending'
            ORDER BY CreatedDate ASC
        ];
    }

    @AuraEnabled
    public static String approveBooking(Id bookingId) {
        try {
            Booking__c b = [
                SELECT Id, Status__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];

            if (b.Status__c != 'Pending') {
                throw new AuraHandledException(
                    'Only Pending bookings can be approved.'
                );
            }

            // 1 DML only
            b.Status__c = 'Approved';
            update b;

            // Send emails async
            sendApprovalEmails(bookingId, true, null);

            return 'Approved';

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error approving: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static String rejectBooking(
        Id bookingId, String reason
    ) {
        try {
            Booking__c b = [
                SELECT Id, Status__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];

            if (b.Status__c != 'Pending') {
                throw new AuraHandledException(
                    'Only Pending bookings can be rejected.'
                );
            }

            // 1 DML only
            b.Status__c           = 'Cancelled';
            b.Rejection_Reason__c = reason;
            update b;

            // Send emails async
            sendApprovalEmails(bookingId, false, reason);

            return 'Rejected';

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error rejecting: ' + e.getMessage()
            );
        }
    }

    @future
    private static void sendApprovalEmails(
        Id bookingId,
        Boolean isApproved,
        String reason
    ) {
        try {
            Booking__c b = [
                SELECT Id, Booking_Number__c,
                       Total_Booking_Amount__c,
                       Expected_Delivery_Date__c,
                       Status__c,
                       OwnerId,
                       Contact__r.FirstName,
                       Contact__r.LastName,
                       Contact__r.Email,
                       Model__r.Name,
                       Variant__r.Name
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];

            String customerName = b.Contact__r != null
                ? b.Contact__r.FirstName + ' ' +
                  b.Contact__r.LastName
                : 'Customer';
            String customerEmail = b.Contact__r != null
                ? b.Contact__r.Email : '';
            String modelName = b.Model__r != null
                ? b.Model__r.Name : '—';
            String variantName = b.Variant__r != null
                ? b.Variant__r.Name : '—';

            if (isApproved) {
                if (!String.isBlank(customerEmail)) {
                    EmailUtility.sendBookingApprovedToCustomer(
                        customerEmail,
                        customerName,
                        b.Booking_Number__c,
                        modelName,
                        variantName,
                        b.Total_Booking_Amount__c,
                        b.Expected_Delivery_Date__c
                    );
                }
                User exec = EmailUtility.getSalesExec(b.OwnerId);
                if (exec != null) {
                    EmailUtility.sendBookingApprovedToExec(
                        exec,
                        customerName,
                        modelName,
                        b.Total_Booking_Amount__c
                    );
                }
            } else {
                if (!String.isBlank(customerEmail)) {
                    EmailUtility.sendBookingRejectedToCustomer(
                        customerEmail,
                        customerName,
                        b.Booking_Number__c,
                        modelName,
                        reason
                    );
                }
                User exec = EmailUtility.getSalesExec(b.OwnerId);
                if (exec != null) {
                    EmailUtility.sendBookingRejectedToExec(
                        exec,
                        customerName,
                        modelName,
                        reason
                    );
                }
            }
        } catch (Exception e) {
            System.debug(
                'sendApprovalEmails error: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static String markDelivered(Id bookingId) {
        try {
            Booking__c b = [
                SELECT Id, Status__c,
                       Total_Paid__c,
                       Total_Booking_Amount__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];

            if (b.Status__c != 'Approved') {
                throw new AuraHandledException(
                    'Only Approved bookings can be Delivered.'
                );
            }

            Decimal paid   = b.Total_Paid__c != null
                ? b.Total_Paid__c : 0;
            Decimal total  = b.Total_Booking_Amount__c != null
                ? b.Total_Booking_Amount__c : 0;

            if (paid < total) {
                throw new AuraHandledException(
                    'Full payment required. Remaining: Rs. ' +
                    String.valueOf(total - paid)
                );
            }

            b.Status__c = 'Delivered';
            update b;
            return 'Delivered';

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error marking delivered: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Payment__c> getPaymentsByBooking(
        Id bookingId
    ) {
        return [
            SELECT Id, Name, Payment_Amount__c,
                   Payment_Date__c,
                   Payment_Method__c, Status__c
            FROM Payment__c
            WHERE Booking__c = :bookingId
            ORDER BY Payment_Date__c DESC
        ];
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