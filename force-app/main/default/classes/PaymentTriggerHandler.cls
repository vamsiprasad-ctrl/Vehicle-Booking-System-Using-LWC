public class PaymentTriggerHandler {

    public static void afterInsertUpdate(
        List<Payment__c> newPayments,
        Map<Id, Payment__c> oldMap
    ) {
        Set<Id> bookingIds = new Set<Id>();
        for (Payment__c p : newPayments) {
            if (p.Booking__c != null) bookingIds.add(p.Booking__c);
        }

        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>([
            SELECT Id, Booking_Number__c,
                   Total_Booking_Amount__c, Total_Paid__c,
                   Status__c, OwnerId,
                   Contact__c,
                   Contact__r.FirstName, Contact__r.LastName,
                   Contact__r.Email,
                   Model__r.Name
            FROM Booking__c
            WHERE Id IN :bookingIds
        ]);

        User manager = EmailUtility.getSalesManager();

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();
        List<Booking__c> bookingsToUpdate = new List<Booking__c>();

        for (Payment__c p : newPayments) {

            // Only fire on Completed payments
            Boolean isNewlyCompleted = false;

            if (oldMap == null) {
                // afterInsert
                isNewlyCompleted = p.Status__c == 'Completed';
            } else {
                // afterUpdate
                Payment__c old = oldMap.get(p.Id);
                isNewlyCompleted = p.Status__c == 'Completed'
                    && old.Status__c != 'Completed';
            }

            if (!isNewlyCompleted) continue;

            Booking__c booking = bookingMap.get(p.Booking__c);
            if (booking == null) continue;

            String customerName  = booking.Contact__r != null
                ? booking.Contact__r.FirstName + ' ' + booking.Contact__r.LastName
                : 'Customer';
            String customerEmail = booking.Contact__r != null
                ? booking.Contact__r.Email : '';
            String modelName     = booking.Model__r != null
                ? booking.Model__r.Name : '—';

            Decimal totalPaid    = booking.Total_Paid__c != null
                ? booking.Total_Paid__c : 0;
            Decimal totalAmount  = booking.Total_Booking_Amount__c != null
                ? booking.Total_Booking_Amount__c : 0;
            Decimal remaining    = Math.max(0, totalAmount - totalPaid);

            // Email customer — payment receipt
            if (!String.isBlank(customerEmail)) {
                emails.add(EmailUtility.buildEmail(
                    customerEmail,
                    'Payment Confirmed — Receipt | Tata Motors',
                    'Dear ' + (booking.Contact__r != null
                        ? booking.Contact__r.FirstName : 'Customer') + ',\n\n' +
                    'Your payment has been received successfully.\n\n' +
                    'PAYMENT DETAILS\n' +
                    '───────────────\n' +
                    'Booking No  : ' + booking.Booking_Number__c + '\n' +
                    'Model       : ' + modelName + '\n' +
                    'Amount Paid : Rs. ' + String.valueOf(p.Payment_Amount__c) + '\n' +
                    'Method      : ' + p.Payment_Method__c + '\n' +
                    'Remaining   : Rs. ' + String.valueOf(remaining) + '\n\n' +
                    (remaining <= 0
                        ? 'Full payment received! Your vehicle will be ready for delivery soon.\n\n'
                        : 'Please login to your portal to make the remaining payment.\n\n') +
                    'Warm Regards,\nTata Motors Finance Team'
                ));
            }

            // Email manager — payment received
            if (manager != null) {
                emails.add(EmailUtility.buildEmail(
                    manager.Email,
                    'Payment Received — ' + customerName,
                    'Hi ' + manager.Name + ',\n\n' +
                    'A payment has been received.\n\n' +
                    'PAYMENT DETAILS\n' +
                    '───────────────\n' +
                    'Customer    : ' + customerName + '\n' +
                    'Model       : ' + modelName + '\n' +
                    'Amount Paid : Rs. ' + String.valueOf(p.Payment_Amount__c) + '\n' +
                    'Method      : ' + p.Payment_Method__c + '\n' +
                    'Remaining   : Rs. ' + String.valueOf(remaining) + '\n\n' +
                    (remaining <= 0
                        ? 'Full payment received. Please arrange delivery.\n\n'
                        : '') +
                    'Tata Motors CRM'
                ));
            }

            // Full payment received — update booking to Delivered
            if (remaining <= 0 && booking.Status__c == 'Approved') {
                bookingsToUpdate.add(new Booking__c(
                    Id = booking.Id,
                    Status__c = 'Delivered'
                ));

                // Email manager — full payment, ready for delivery
                if (manager != null) {
                    emails.add(EmailUtility.buildEmail(
                        manager.Email,
                        'Full Payment Received — Ready for Delivery | ' + customerName,
                        'Hi ' + manager.Name + ',\n\n' +
                        'Full payment has been received. Please arrange delivery.\n\n' +
                        'DETAILS\n' +
                        '───────\n' +
                        'Booking No     : ' + booking.Booking_Number__c + '\n' +
                        'Customer       : ' + customerName + '\n' +
                        'Model          : ' + modelName + '\n' +
                        'Total Received : Rs. ' + String.valueOf(totalPaid) + '\n\n' +
                        'Tata Motors CRM'
                    ));
                }
            }
        }

        if (!emails.isEmpty()) EmailUtility.sendEmails(emails);

        if (!bookingsToUpdate.isEmpty()) {
            update bookingsToUpdate;
        }
    }
}