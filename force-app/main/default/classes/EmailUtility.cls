public class EmailUtility {

    public static void sendEmail(
        String toAddress,
        String subject,
        String body
    ) {
        if (String.isBlank(toAddress)) return;
        Messaging.SingleEmailMessage mail =
            new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ toAddress });
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        mail.setSaveAsActivity(false);
        try {
            Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ mail }
            );
        } catch (Exception e) {
            System.debug('EmailUtility.sendEmail error: ' + e.getMessage());
        }
    }

    public static void sendEmails(
        List<Messaging.SingleEmailMessage> emails
    ) {
        if (emails == null || emails.isEmpty()) return;
        try {
            Messaging.sendEmail(emails);
        } catch (Exception e) {
            System.debug('EmailUtility.sendEmails error: ' + e.getMessage());
        }
    }

    public static Messaging.SingleEmailMessage buildEmail(
        String toAddress,
        String subject,
        String body
    ) {
        Messaging.SingleEmailMessage mail =
            new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ toAddress });
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        mail.setSaveAsActivity(false);
        return mail;
    }

    public static User getSalesManager() {
    List<User> managers = [
        SELECT Id, Name, Email
        FROM User
        WHERE Profile.Name = 'Sales Manager'
        AND IsActive = true
        LIMIT 1
    ];
    return managers.isEmpty() ? null : managers[0];
}

public static User getSalesExec(Id userId) {
    if (userId == null) return null;
    List<User> execs = [
        SELECT Id, Name, Email
        FROM User
        WHERE Id = :userId
        AND IsActive = true
        LIMIT 1
    ];
    return execs.isEmpty() ? null : execs[0];
}

    // ════════════════════════════════════════════════════════════
    // LEAD EMAILS
    // ════════════════════════════════════════════════════════════

    public static void sendLeadAssignedToExec(Lead l, User exec) {
        if (exec == null || String.isBlank(exec.Email)) return;
        sendEmail(
            exec.Email,
            'New Lead Assigned — ' + l.FirstName + ' ' + l.LastName,
            'Hi ' + exec.Name + ',\n\n' +
            'A new lead has been assigned to you. Please contact them within 24 hours.\n\n' +
            'LEAD DETAILS\n' +
            '────────────\n' +
            'Name    : ' + l.FirstName + ' ' + l.LastName + '\n' +
            'Email   : ' + l.Email + '\n' +
            'Phone   : ' + l.Phone + '\n' +
            'City    : ' + (l.City != null ? l.City : '—') + '\n' +
            'Source  : ' + l.LeadSource + '\n\n' +
            'Login to the Partner Portal to manage this lead.\n\n' +
            'Tata Motors CRM'
        );
    }

    public static void sendLeadContactedEmail(Lead l) {
        if (String.isBlank(l.Email)) return;
        sendEmail(
            l.Email,
            'We Received Your Enquiry — Tata Motors',
            'Dear ' + l.FirstName + ',\n\n' +
            'Thank you for your interest in Tata Motors!\n\n' +
            'Our Sales Executive has been assigned to your enquiry and will ' +
            'contact you shortly to discuss your requirements.\n\n' +
            'If you have any urgent queries, feel free to call us on:\n' +
            '1800 209 7979 (Toll Free)\n\n' +
            'Warm Regards,\nTata Motors Sales Team'
        );
    }

    public static void sendLeadQualifiedEmail(Lead l) {
        if (String.isBlank(l.Email)) return;
        sendEmail(
            l.Email,
            'Your Test Drive is Being Arranged — Tata Motors',
            'Dear ' + l.FirstName + ',\n\n' +
            'Great news! Our Sales Executive has reviewed your enquiry and is ' +
            'arranging a test drive for you.\n\n' +
            'You will receive a confirmation call within 24 hours with the ' +
            'scheduled date and time.\n\n' +
            'Warm Regards,\nTata Motors Sales Team'
        );
    }

    public static void sendLeadConvertedEmail(Lead l) {
        if (String.isBlank(l.Email)) return;
        sendEmail(
            l.Email,
            'Welcome to the Tata Motors Family!',
            'Dear ' + l.FirstName + ',\n\n' +
            'Welcome to the Tata Motors family!\n\n' +
            'Your profile has been created in our Customer Portal. ' +
            'You can now track your bookings, test drives and payments online.\n\n' +
            'To access your portal:\n' +
            '1. Visit your Customer Portal\n' +
            '2. Click Forgot Password\n' +
            '3. Enter your email: ' + l.Email + '\n' +
            '4. Set your password and login\n\n' +
            'Warm Regards,\nTata Motors Team'
        );
    }

    public static void sendLeadLostInternal(Lead l, User manager) {
        if (manager == null || String.isBlank(manager.Email)) return;
        sendEmail(
            manager.Email,
            'Lead Lost — ' + l.FirstName + ' ' + l.LastName,
            'Hi ' + manager.Name + ',\n\n' +
            'A lead has been marked as Lost.\n\n' +
            'LEAD DETAILS\n' +
            '────────────\n' +
            'Name   : ' + l.FirstName + ' ' + l.LastName + '\n' +
            'Email  : ' + l.Email + '\n' +
            'Phone  : ' + l.Phone + '\n' +
            'City   : ' + (l.City != null ? l.City : '—') + '\n\n' +
            'Please review and take necessary action.\n\n' +
            'Tata Motors CRM'
        );
    }

    // ════════════════════════════════════════════════════════════
    // TEST DRIVE EMAILS
    // ════════════════════════════════════════════════════════════

    public static void sendTestDriveRequestedToCustomer(
        String customerEmail,
        String customerName,
        String modelName,
        String variantName,
        String city
    ) {
        if (String.isBlank(customerEmail)) return;
        sendEmail(
            customerEmail,
            'Test Drive Request Received — Tata Motors',
            'Dear ' + customerName + ',\n\n' +
            'Thank you for requesting a test drive with Tata Motors!\n\n' +
            'TEST DRIVE DETAILS\n' +
            '──────────────────\n' +
            'Model   : ' + modelName + '\n' +
            'Variant : ' + variantName + '\n' +
            'City    : ' + city + '\n\n' +
            'Our Sales Executive will contact you within 24 hours to confirm ' +
            'your appointment slot.\n\n' +
            'Test drives are completely free with no purchase obligation.\n\n' +
            'Warm Regards,\nTata Motors Customer Team'
        );
    }

    public static void sendTestDriveRequestedToExec(
        User exec,
        String customerName,
        String customerPhone,
        String customerEmail,
        String modelName,
        String variantName,
        String city,
        DateTime preferredDateTime
    ) {
        if (exec == null || String.isBlank(exec.Email)) return;
        sendEmail(
            exec.Email,
            'New Test Drive Request — ' + customerName,
            'Hi ' + exec.Name + ',\n\n' +
            'A new test drive request has been submitted.\n\n' +
            'CUSTOMER DETAILS\n' +
            '────────────────\n' +
            'Name     : ' + customerName + '\n' +
            'Phone    : ' + customerPhone + '\n' +
            'Email    : ' + customerEmail + '\n' +
            'City     : ' + city + '\n\n' +
            'TEST DRIVE DETAILS\n' +
            '──────────────────\n' +
            'Model    : ' + modelName + '\n' +
            'Variant  : ' + variantName + '\n' +
            'Preferred: ' + (preferredDateTime != null
                ? preferredDateTime.format()
                : '—') + '\n\n' +
            'Please contact the customer and confirm the slot.\n\n' +
            'Tata Motors CRM'
        );
    }

    public static void sendTestDriveConfirmedToCustomer(
        String customerEmail,
        String customerName,
        String modelName,
        String variantName,
        DateTime confirmedDateTime,
        String city
    ) {
        if (String.isBlank(customerEmail)) return;
        sendEmail(
            customerEmail,
            'Your Test Drive is Confirmed — Tata Motors',
            'Dear ' + customerName + ',\n\n' +
            'Great news! Your test drive has been confirmed.\n\n' +
            'TEST DRIVE DETAILS\n' +
            '──────────────────\n' +
            'Model    : ' + modelName + '\n' +
            'Variant  : ' + variantName + '\n' +
            'Date     : ' + (confirmedDateTime != null
                ? confirmedDateTime.format()
                : '—') + '\n' +
            'City     : ' + city + '\n\n' +
            'WHAT TO BRING\n' +
            '─────────────\n' +
            'Valid driving licence\n' +
            'This confirmation email\n' +
            'Valid photo ID\n\n' +
            'See you at the showroom!\n\n' +
            'Warm Regards,\nTata Motors Sales Team'
        );
    }

    public static void sendTestDriveCompletedToCustomer(
        String customerEmail,
        String customerName,
        String modelName
    ) {
        if (String.isBlank(customerEmail)) return;
        sendEmail(
            customerEmail,
            'How Was Your Test Drive? — Tata Motors',
            'Dear ' + customerName + ',\n\n' +
            'Thank you for test driving the ' + modelName + '!\n\n' +
            'We hope you enjoyed the experience. If you are ready to book ' +
            'or have any questions, our Sales Executive is here to help.\n\n' +
            'Call us: 1800 209 7979\n\n' +
            'Warm Regards,\nTata Motors Sales Team'
        );
    }

    public static void sendTestDriveCancelledToCustomer(
        String customerEmail,
        String customerName,
        String modelName
    ) {
        if (String.isBlank(customerEmail)) return;
        sendEmail(
            customerEmail,
            'Test Drive Cancelled — Tata Motors',
            'Dear ' + customerName + ',\n\n' +
            'Your test drive for the ' + modelName + ' has been cancelled.\n\n' +
            'We would love to reschedule at your convenience. ' +
            'Please visit our portal or call us on 1800 209 7979.\n\n' +
            'Warm Regards,\nTata Motors Sales Team'
        );
    }

    public static void sendTestDriveCancelledToExec(
        User exec,
        String customerName,
        String modelName
    ) {
        if (exec == null || String.isBlank(exec.Email)) return;
        sendEmail(
            exec.Email,
            'Test Drive Cancelled — ' + customerName,
            'Hi ' + exec.Name + ',\n\n' +
            'The test drive for ' + customerName + ' (' + modelName + ') ' +
            'has been cancelled. The slot is now free.\n\n' +
            'Please follow up with the customer to reschedule.\n\n' +
            'Tata Motors CRM'
        );
    }

    // ════════════════════════════════════════════════════════════
    // BOOKING EMAILS
    // ════════════════════════════════════════════════════════════

    public static void sendBookingCreatedToCustomer(
        String customerEmail,
        String customerName,
        String bookingNumber,
        String modelName,
        String variantName,
        Decimal amount
    ) {
        if (String.isBlank(customerEmail)) return;
        sendEmail(
            customerEmail,
            'Booking Received — Pending Approval | Tata Motors',
            'Dear ' + customerName + ',\n\n' +
            'Thank you for choosing Tata Motors!\n\n' +
            'Your booking has been received and is awaiting manager approval. ' +
            'You will receive an email once it is approved.\n\n' +
            'BOOKING DETAILS\n' +
            '───────────────\n' +
            'Booking No : ' + bookingNumber + '\n' +
            'Model      : ' + modelName + '\n' +
            'Variant    : ' + variantName + '\n' +
            'Amount     : Rs. ' + String.valueOf(amount) + '\n\n' +
            'Warm Regards,\nTata Motors Sales Team'
        );
    }

    public static void sendBookingCreatedToManager(
        User manager,
        String customerName,
        String bookingNumber,
        String modelName,
        String variantName,
        Decimal amount,
        String execName
    ) {
        if (manager == null || String.isBlank(manager.Email)) return;
        sendEmail(
            manager.Email,
            'New Booking Awaiting Approval — ' + modelName,
            'Hi ' + manager.Name + ',\n\n' +
            'A new booking has been submitted and requires your approval.\n\n' +
            'BOOKING DETAILS\n' +
            '───────────────\n' +
            'Booking No   : ' + bookingNumber + '\n' +
            'Customer     : ' + customerName + '\n' +
            'Model        : ' + modelName + '\n' +
            'Variant      : ' + variantName + '\n' +
            'Amount       : Rs. ' + String.valueOf(amount) + '\n' +
            'Submitted by : ' + execName + '\n\n' +
            'Please login to the Partner Portal to approve or reject.\n\n' +
            'Tata Motors CRM'
        );
    }

    public static void sendBookingApprovedToCustomer(
        String customerEmail,
        String customerName,
        String bookingNumber,
        String modelName,
        String variantName,
        Decimal amount,
        Date deliveryDate
    ) {
        if (String.isBlank(customerEmail)) return;
        sendEmail(
            customerEmail,
            'Your Booking is Approved — Tata Motors',
            'Dear ' + customerName + ',\n\n' +
            'Congratulations! Your booking has been approved.\n\n' +
            'BOOKING DETAILS\n' +
            '───────────────\n' +
            'Booking No        : ' + bookingNumber + '\n' +
            'Model             : ' + modelName + '\n' +
            'Variant           : ' + variantName + '\n' +
            'Total Amount      : Rs. ' + String.valueOf(amount) + '\n' +
            'Expected Delivery : ' + (deliveryDate != null
                ? deliveryDate.format()
                : '—') + '\n\n' +
            'NEXT STEPS\n' +
            '──────────\n' +
            'Please login to your Customer Portal to make the payment.\n' +
            'Accepted methods: Cash, UPI, Card, Loan, Bank Transfer\n\n' +
            'Warm Regards,\nTata Motors Sales Team'
        );
    }

    public static void sendBookingApprovedToExec(
        User exec,
        String customerName,
        String modelName,
        Decimal amount
    ) {
        if (exec == null || String.isBlank(exec.Email)) return;
        sendEmail(
            exec.Email,
            'Booking Approved — Follow Up for Payment | ' + customerName,
            'Hi ' + exec.Name + ',\n\n' +
            'The booking for ' + customerName + ' (' + modelName + ') ' +
            'has been approved by the Manager.\n\n' +
            'Outstanding Amount: Rs. ' + String.valueOf(amount) + '\n\n' +
            'Please follow up with the customer to arrange payment.\n\n' +
            'Tata Motors CRM'
        );
    }

    public static void sendBookingRejectedToCustomer(
        String customerEmail,
        String customerName,
        String bookingNumber,
        String modelName,
        String reason
    ) {
        if (String.isBlank(customerEmail)) return;
        sendEmail(
            customerEmail,
            'Update on Your Booking — Tata Motors',
            'Dear ' + customerName + ',\n\n' +
            'We regret to inform you that your booking could not be approved at this time.\n\n' +
            'BOOKING DETAILS\n' +
            '───────────────\n' +
            'Booking No : ' + bookingNumber + '\n' +
            'Model      : ' + modelName + '\n\n' +
            (String.isBlank(reason) ? '' : 'Reason: ' + reason + '\n\n') +
            'Please contact your Sales Executive to discuss next steps.\n' +
            'Call us: 1800 209 7979\n\n' +
            'Warm Regards,\nTata Motors Sales Team'
        );
    }

    public static void sendBookingRejectedToExec(
        User exec,
        String customerName,
        String modelName,
        String reason
    ) {
        if (exec == null || String.isBlank(exec.Email)) return;
        sendEmail(
            exec.Email,
            'Booking Rejected — ' + customerName,
            'Hi ' + exec.Name + ',\n\n' +
            'The booking for ' + customerName + ' (' + modelName + ') ' +
            'has been rejected by the Manager.\n\n' +
            (String.isBlank(reason) ? '' : 'Reason: ' + reason + '\n\n') +
            'Please contact the customer to discuss alternative options.\n\n' +
            'Tata Motors CRM'
        );
    }

    public static void sendBookingDeliveredToCustomer(
        String customerEmail,
        String customerName,
        String bookingNumber,
        String modelName,
        Decimal totalPaid
    ) {
        if (String.isBlank(customerEmail)) return;
        sendEmail(
            customerEmail,
            'Your Vehicle is Ready for Delivery — Tata Motors',
            'Dear ' + customerName + ',\n\n' +
            'Congratulations! Your vehicle is ready for delivery.\n\n' +
            'DELIVERY DETAILS\n' +
            '────────────────\n' +
            'Booking No   : ' + bookingNumber + '\n' +
            'Model        : ' + modelName + '\n' +
            'Total Paid   : Rs. ' + String.valueOf(totalPaid) + '\n\n' +
            'WHAT TO BRING\n' +
            '─────────────\n' +
            'This email\n' +
            'Valid Photo ID\n' +
            'Driving Licence\n\n' +
            'Thank you for choosing Tata Motors. Enjoy your new vehicle!\n\n' +
            'Warm Regards,\nTata Motors Delivery Team'
        );
    }

    public static void sendBookingDeliveredToManager(
        User manager,
        String customerName,
        String modelName,
        String execName,
        Decimal totalRevenue
    ) {
        if (manager == null || String.isBlank(manager.Email)) return;
        sendEmail(
            manager.Email,
            'Delivery Completed — ' + modelName,
            'Hi ' + manager.Name + ',\n\n' +
            'A vehicle has been successfully delivered.\n\n' +
            'DELIVERY SUMMARY\n' +
            '────────────────\n' +
            'Customer      : ' + customerName + '\n' +
            'Model         : ' + modelName + '\n' +
            'Sales Exec    : ' + execName + '\n' +
            'Total Revenue : Rs. ' + String.valueOf(totalRevenue) + '\n\n' +
            'Tata Motors CRM'
        );
    }

    public static void sendBookingDeliveredToExec(
        User exec,
        String customerName,
        String modelName
    ) {
        if (exec == null || String.isBlank(exec.Email)) return;
        sendEmail(
            exec.Email,
            'Delivery Completed — ' + customerName,
            'Hi ' + exec.Name + ',\n\n' +
            'The delivery for ' + customerName + ' (' + modelName + ') ' +
            'has been marked as completed.\n\n' +
            'Great work! Please follow up with the customer for feedback.\n\n' +
            'Tata Motors CRM'
        );
    }

    // ════════════════════════════════════════════════════════════
    // PAYMENT EMAILS
    // ════════════════════════════════════════════════════════════

    public static void sendPaymentReceiptToCustomer(
        String customerEmail,
        String customerName,
        String bookingNumber,
        String modelName,
        Decimal amountPaid,
        String paymentMethod,
        Decimal remainingBalance
    ) {
        if (String.isBlank(customerEmail)) return;
        sendEmail(
            customerEmail,
            'Payment Confirmed — Receipt | Tata Motors',
            'Dear ' + customerName + ',\n\n' +
            'Your payment has been received successfully.\n\n' +
            'PAYMENT DETAILS\n' +
            '───────────────\n' +
            'Booking No  : ' + bookingNumber + '\n' +
            'Model       : ' + modelName + '\n' +
            'Amount Paid : Rs. ' + String.valueOf(amountPaid) + '\n' +
            'Method      : ' + paymentMethod + '\n' +
            'Remaining   : Rs. ' + String.valueOf(remainingBalance) + '\n\n' +
            (remainingBalance <= 0
                ? 'Full payment received! Your vehicle will be ready for delivery soon.\n\n'
                : 'Please login to your portal to make the remaining payment.\n\n') +
            'Warm Regards,\nTata Motors Finance Team'
        );
    }

    public static void sendPaymentReceivedToManager(
        User manager,
        String customerName,
        String modelName,
        Decimal amountPaid,
        String paymentMethod,
        Decimal remainingBalance
    ) {
        if (manager == null || String.isBlank(manager.Email)) return;
        sendEmail(
            manager.Email,
            'Payment Received — ' + customerName,
            'Hi ' + manager.Name + ',\n\n' +
            'A payment has been received.\n\n' +
            'PAYMENT DETAILS\n' +
            '───────────────\n' +
            'Customer    : ' + customerName + '\n' +
            'Model       : ' + modelName + '\n' +
            'Amount Paid : Rs. ' + String.valueOf(amountPaid) + '\n' +
            'Method      : ' + paymentMethod + '\n' +
            'Remaining   : Rs. ' + String.valueOf(remainingBalance) + '\n\n' +
            (remainingBalance <= 0
                ? 'Full payment received. Vehicle is ready for delivery.\n\n'
                : '') +
            'Tata Motors CRM'
        );
    }

    public static void sendFullPaymentToManager(
        User manager,
        String customerName,
        String modelName,
        String bookingNumber,
        Decimal totalAmount
    ) {
        if (manager == null || String.isBlank(manager.Email)) return;
        sendEmail(
            manager.Email,
            'Full Payment Received — Ready for Delivery | ' + customerName,
            'Hi ' + manager.Name + ',\n\n' +
            'Full payment has been received for the following booking. ' +
            'Please arrange delivery.\n\n' +
            'DETAILS\n' +
            '───────\n' +
            'Booking No     : ' + bookingNumber + '\n' +
            'Customer       : ' + customerName + '\n' +
            'Model          : ' + modelName + '\n' +
            'Total Received : Rs. ' + String.valueOf(totalAmount) + '\n\n' +
            'Tata Motors CRM'
        );
    }

    // ════════════════════════════════════════════════════════════
    // PARTNER ACTION EMAILS
    // ════════════════════════════════════════════════════════════

    public static void sendLeadReassignedToNewExec(
        User newExec,
        String customerName,
        String customerPhone,
        String customerEmail,
        String modelName
    ) {
        if (newExec == null || String.isBlank(newExec.Email)) return;
        sendEmail(
            newExec.Email,
            'Lead Reassigned to You — ' + customerName,
            'Hi ' + newExec.Name + ',\n\n' +
            'A lead has been reassigned to you. Please follow up immediately.\n\n' +
            'LEAD DETAILS\n' +
            '────────────\n' +
            'Name    : ' + customerName + '\n' +
            'Phone   : ' + customerPhone + '\n' +
            'Email   : ' + customerEmail + '\n' +
            'Model   : ' + modelName + '\n\n' +
            'Tata Motors CRM'
        );
    }

    public static void sendLeadReassignedToOldExec(
        User oldExec,
        String customerName
    ) {
        if (oldExec == null || String.isBlank(oldExec.Email)) return;
        sendEmail(
            oldExec.Email,
            'Lead Reassigned — ' + customerName,
            'Hi ' + oldExec.Name + ',\n\n' +
            'The lead for ' + customerName +
            ' has been reassigned to another executive.\n\n' +
            'Tata Motors CRM'
        );
    }
}