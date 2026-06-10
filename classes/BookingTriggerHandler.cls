public class BookingTriggerHandler {

    public static void beforeInsert(List<Booking__c> newBookings) {
        for (Booking__c b : newBookings) {
            if (b.Booking_Date__c == null) {
                b.Booking_Date__c = Date.today();
            }
            if (b.Expected_Delivery_Date__c == null) {
                b.Expected_Delivery_Date__c = b.Booking_Date__c.addDays(30);
            }
        }
    }

    public static void afterInsert(List<Booking__c> newBookings) {
        Set<Id> contactIds = new Set<Id>();
        for (Booking__c b : newBookings) {
            if (b.Contact__c != null) contactIds.add(b.Contact__c);
        }

        Map<Id, Contact> contactMap = new Map<Id, Contact>([
            SELECT Id, FirstName, LastName, Email
            FROM Contact
            WHERE Id IN :contactIds
        ]);

        User manager = EmailUtility.getSalesManager();

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();

        for (Booking__c b : newBookings) {
            Contact con = b.Contact__c != null
                ? contactMap.get(b.Contact__c) : null;

            String customerName  = con != null
                ? con.FirstName + ' ' + con.LastName : 'Customer';
            String customerEmail = con != null
                ? con.Email : '';

            // Email customer — booking received
            if (!String.isBlank(customerEmail)) {
                emails.add(EmailUtility.buildEmail(
                    customerEmail,
                    'Booking Received — Pending Approval | Tata Motors',
                    'Dear ' + con.FirstName + ',\n\n' +
                    'Thank you for choosing Tata Motors!\n\n' +
                    'Your booking has been received and is awaiting manager approval.\n\n' +
                    'BOOKING DETAILS\n' +
                    '───────────────\n' +
                    'Booking No : ' + b.Booking_Number__c + '\n' +
                    'Amount     : Rs. ' + String.valueOf(b.Total_Booking_Amount__c) + '\n' +
                    'Date       : ' + b.Booking_Date__c + '\n\n' +
                    'You will receive an email once your booking is approved.\n\n' +
                    'Warm Regards,\nTata Motors Sales Team'
                ));
            }

            // Email manager — new booking awaiting approval
            if (manager != null) {
                User exec = EmailUtility.getSalesExec(b.OwnerId);
                String execName = exec != null ? exec.Name : 'Sales Executive';
                emails.add(EmailUtility.buildEmail(
                    manager.Email,
                    'New Booking Awaiting Approval — ' + customerName,
                    'Hi ' + manager.Name + ',\n\n' +
                    'A new booking has been submitted and requires your approval.\n\n' +
                    'BOOKING DETAILS\n' +
                    '───────────────\n' +
                    'Booking No   : ' + b.Booking_Number__c + '\n' +
                    'Customer     : ' + customerName + '\n' +
                    'Amount       : Rs. ' + String.valueOf(b.Total_Booking_Amount__c) + '\n' +
                    'Submitted by : ' + execName + '\n\n' +
                    'Please login to the Partner Portal to approve or reject.\n\n' +
                    'Tata Motors CRM'
                ));
            }
        }

        if (!emails.isEmpty()) EmailUtility.sendEmails(emails);
    }

    public static void afterUpdate(
        List<Booking__c> newBookings,
        Map<Id, Booking__c> oldMap
    ) {
        Set<Id> contactIds = new Set<Id>();
        for (Booking__c b : newBookings) {
            if (b.Contact__c != null) contactIds.add(b.Contact__c);
        }

        Map<Id, Contact> contactMap = new Map<Id, Contact>([
            SELECT Id, FirstName, LastName, Email
            FROM Contact
            WHERE Id IN :contactIds
        ]);

        User manager = EmailUtility.getSalesManager();

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();
        List<Task> tasksToCreate = new List<Task>();

        for (Booking__c b : newBookings) {
            Booking__c old = oldMap.get(b.Id);
            Contact con = b.Contact__c != null
                ? contactMap.get(b.Contact__c) : null;

            String customerName  = con != null
                ? con.FirstName + ' ' + con.LastName : 'Customer';
            String customerEmail = con != null ? con.Email : '';
            User exec = EmailUtility.getSalesExec(b.OwnerId);

            // Status → Approved
            if (b.Status__c == 'Approved'
                && old.Status__c != 'Approved') {

                // Email customer
                if (!String.isBlank(customerEmail)) {
                    emails.add(EmailUtility.buildEmail(
                        customerEmail,
                        'Your Booking is Approved — Tata Motors',
                        'Dear ' + (con != null ? con.FirstName : 'Customer') + ',\n\n' +
                        'Congratulations! Your booking has been approved.\n\n' +
                        'BOOKING DETAILS\n' +
                        '───────────────\n' +
                        'Booking No        : ' + b.Booking_Number__c + '\n' +
                        'Total Amount      : Rs. ' + String.valueOf(b.Total_Booking_Amount__c) + '\n' +
                        'Expected Delivery : ' + b.Expected_Delivery_Date__c + '\n\n' +
                        'Please login to your Customer Portal to make the payment.\n' +
                        'Accepted methods: Cash, UPI, Card, Loan, Bank Transfer\n\n' +
                        'Warm Regards,\nTata Motors Sales Team'
                    ));
                }

                // Email sales exec
                if (exec != null) {
                    emails.add(EmailUtility.buildEmail(
                        exec.Email,
                        'Booking Approved — Follow Up for Payment | ' + customerName,
                        'Hi ' + exec.Name + ',\n\n' +
                        'The booking for ' + customerName + ' has been approved.\n\n' +
                        'Outstanding Amount: Rs. ' +
                        String.valueOf(b.Total_Booking_Amount__c) + '\n\n' +
                        'Please follow up with the customer to arrange payment.\n\n' +
                        'Tata Motors CRM'
                    ));
                }
            }

            // Status → Cancelled
            if (b.Status__c == 'Cancelled'
                && old.Status__c != 'Cancelled') {

                // Email customer
                if (!String.isBlank(customerEmail)) {
                    emails.add(EmailUtility.buildEmail(
                        customerEmail,
                        'Update on Your Booking — Tata Motors',
                        'Dear ' + (con != null ? con.FirstName : 'Customer') + ',\n\n' +
                        'We regret to inform you that your booking could not be approved.\n\n' +
                        'Booking No : ' + b.Booking_Number__c + '\n\n' +
                        (String.isBlank(b.Rejection_Reason__c) ? '' :
                            'Reason: ' + b.Rejection_Reason__c + '\n\n') +
                        'Please contact your Sales Executive for assistance.\n' +
                        'Call us: 1800 209 7979\n\n' +
                        'Warm Regards,\nTata Motors Sales Team'
                    ));
                }

                // Email sales exec
                if (exec != null) {
                    emails.add(EmailUtility.buildEmail(
                        exec.Email,
                        'Booking Cancelled — ' + customerName,
                        'Hi ' + exec.Name + ',\n\n' +
                        'The booking for ' + customerName + ' has been cancelled.\n\n' +
                        (String.isBlank(b.Rejection_Reason__c) ? '' :
                            'Reason: ' + b.Rejection_Reason__c + '\n\n') +
                        'Please contact the customer to discuss alternatives.\n\n' +
                        'Tata Motors CRM'
                    ));
                }
            }

            // Status → Delivered
            if (b.Status__c == 'Delivered'
                && old.Status__c != 'Delivered') {

                // Email customer
                if (!String.isBlank(customerEmail)) {
                    emails.add(EmailUtility.buildEmail(
                        customerEmail,
                        'Your Vehicle is Ready for Delivery — Tata Motors',
                        'Dear ' + (con != null ? con.FirstName : 'Customer') + ',\n\n' +
                        'Congratulations! Your vehicle is ready for delivery.\n\n' +
                        'DELIVERY DETAILS\n' +
                        '────────────────\n' +
                        'Booking No : ' + b.Booking_Number__c + '\n' +
                        'Total Paid : Rs. ' + String.valueOf(b.Total_Paid__c) + '\n\n' +
                        'WHAT TO BRING\n' +
                        '─────────────\n' +
                        'This email\n' +
                        'Valid Photo ID\n' +
                        'Driving Licence\n\n' +
                        'Thank you for choosing Tata Motors!\n\n' +
                        'Warm Regards,\nTata Motors Delivery Team'
                    ));
                }

                // Email manager
                if (manager != null) {
                    String execName = exec != null ? exec.Name : '—';
                    emails.add(EmailUtility.buildEmail(
                        manager.Email,
                        'Delivery Completed — ' + customerName,
                        'Hi ' + manager.Name + ',\n\n' +
                        'A vehicle has been successfully delivered.\n\n' +
                        'DELIVERY SUMMARY\n' +
                        '────────────────\n' +
                        'Customer      : ' + customerName + '\n' +
                        'Sales Exec    : ' + execName + '\n' +
                        'Total Revenue : Rs. ' + String.valueOf(b.Total_Paid__c) + '\n\n' +
                        'Tata Motors CRM'
                    ));
                }

                // Email exec
                if (exec != null) {
                    emails.add(EmailUtility.buildEmail(
                        exec.Email,
                        'Delivery Completed — ' + customerName,
                        'Hi ' + exec.Name + ',\n\n' +
                        'The delivery for ' + customerName +
                        ' has been marked as completed.\n\n' +
                        'Great work! Please follow up for feedback.\n\n' +
                        'Tata Motors CRM'
                    ));
                }

                // Create delivery task
                tasksToCreate.add(new Task(
                    Subject      = 'Vehicle Delivery — ' + b.Booking_Number__c,
                    Status       = 'Not Started',
                    Priority     = 'High',
                    OwnerId      = b.OwnerId,
                    WhatId       = b.Id,
                    ActivityDate = Date.today()
                ));
            }
        }

        if (!emails.isEmpty())        EmailUtility.sendEmails(emails);
        if (!tasksToCreate.isEmpty()) insert tasksToCreate;
    }
}