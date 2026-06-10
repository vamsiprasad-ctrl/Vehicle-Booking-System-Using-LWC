public without sharing class PaymentController {

    @AuraEnabled
    public static String processPayment(
        Id      bookingId,
        Decimal paymentAmount,
        String  paymentMethod
    ) {
        try {
            List<Booking__c> bookings = [
                SELECT Id, Contact__c, Model__r.Name,
                       Variant__r.Name,
                       Total_Booking_Amount__c,
                       Total_Paid__c, Status__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];
            if (bookings.isEmpty()) {
                throw new AuraHandledException('Booking not found');
            }
            Booking__c booking = bookings[0];
            if (booking.Status__c != 'Approved') {
                throw new AuraHandledException(
                    'Payments can only be made on Approved bookings. ' +
                    'Current status: ' + booking.Status__c
                );
            }
            // Insert as Pending first
            Payment__c payment = new Payment__c(
                Booking__c        = bookingId,
                Payment_Amount__c = paymentAmount,
                Payment_Method__c = paymentMethod,
                Status__c         = 'Pending',
                Payment_Date__c   = System.today()
            );
            insert payment;

            // Update to Completed — PaymentTriggerHandler fires
            // and auto-delivers on full payment
            payment.Status__c = 'Completed';
            update payment;

            Booking__c updated = [
                SELECT Status__c FROM Booking__c
                WHERE Id = :bookingId LIMIT 1
            ];
            return 'Payment processed successfully. Booking status: '
                + updated.Status__c;

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error processing payment: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static Decimal getRemainingBalance(Id bookingId) {
        try {
            List<Booking__c> bookings = [
                SELECT Total_Booking_Amount__c, Total_Paid__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];
            if (bookings.isEmpty()) return 0;
            Booking__c b = bookings[0];
            Decimal remaining =
                (b.Total_Booking_Amount__c == null ? 0 : b.Total_Booking_Amount__c) -
                (b.Total_Paid__c           == null ? 0 : b.Total_Paid__c);
            return remaining > 0 ? remaining : 0;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error calculating balance: ' + e.getMessage()
            );
        }
    }
}