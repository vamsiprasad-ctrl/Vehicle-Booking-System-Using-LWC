public class LeadTriggerHandler {

    public static void afterUpdate(
        List<Lead> newLeads,
        Map<Id, Lead> oldMap
    ) {
        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();

        for (Lead l : newLeads) {
            Lead old = oldMap.get(l.Id);

            // Status changed to Contacted
            if (l.Status == 'Contacted' && old.Status != 'Contacted') {
                if (!String.isBlank(l.Email)) {
                    emails.add(EmailUtility.buildEmail(
                        l.Email,
                        'We Received Your Enquiry — Tata Motors',
                        'Dear ' + l.FirstName + ',\n\n' +
                        'Thank you for your interest in Tata Motors!\n\n' +
                        'Our Sales Executive has been assigned to your enquiry ' +
                        'and will contact you shortly.\n\n' +
                        'For urgent queries call us: 1800 209 7979\n\n' +
                        'Warm Regards,\nTata Motors Sales Team'
                    ));
                }
            }

            // Status changed to Qualified
            if (l.Status == 'Qualified' && old.Status != 'Qualified') {
                if (!String.isBlank(l.Email)) {
                    emails.add(EmailUtility.buildEmail(
                        l.Email,
                        'Your Test Drive is Being Arranged — Tata Motors',
                        'Dear ' + l.FirstName + ',\n\n' +
                        'Our Sales Executive has reviewed your enquiry and is ' +
                        'arranging a test drive for you.\n\n' +
                        'You will receive a confirmation call within 24 hours.\n\n' +
                        'Warm Regards,\nTata Motors Sales Team'
                    ));
                }
            }

            // Status changed to Converted
            if (l.IsConverted && !old.IsConverted) {
                if (!String.isBlank(l.Email)) {
                    emails.add(EmailUtility.buildEmail(
                        l.Email,
                        'Welcome to the Tata Motors Family! 🎉',
                        'Dear ' + l.FirstName + ',\n\n' +
                        'Welcome to the Tata Motors family!\n\n' +
                        'Your profile has been created in our Customer Portal.\n\n' +
                        'To access your portal:\n' +
                        '1. Visit your Customer Portal\n' +
                        '2. Click Forgot Password\n' +
                        '3. Enter your email: ' + l.Email + '\n' +
                        '4. Set your password and login\n\n' +
                        'Warm Regards,\nTata Motors Team'
                    ));
                }
            }

            // Status changed to Lost
            if (l.Status == 'Lost' && old.Status != 'Lost') {
                User manager = EmailUtility.getSalesManager();
                if (manager != null) {
                    emails.add(EmailUtility.buildEmail(
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
                        'Tata Motors CRM'
                    ));
                }
            }

            // OwnerId changed — lead reassigned
            if (l.OwnerId != old.OwnerId) {
                User newExec = EmailUtility.getSalesExec(l.OwnerId);
                User oldExec = EmailUtility.getSalesExec(old.OwnerId);

                if (newExec != null) {
                    emails.add(EmailUtility.buildEmail(
                        newExec.Email,
                        'Lead Reassigned to You — ' + l.FirstName + ' ' + l.LastName,
                        'Hi ' + newExec.Name + ',\n\n' +
                        'A lead has been reassigned to you.\n\n' +
                        'LEAD DETAILS\n' +
                        '────────────\n' +
                        'Name  : ' + l.FirstName + ' ' + l.LastName + '\n' +
                        'Phone : ' + l.Phone + '\n' +
                        'Email : ' + l.Email + '\n\n' +
                        'Please follow up immediately.\n\n' +
                        'Tata Motors CRM'
                    ));
                }

                if (oldExec != null) {
                    emails.add(EmailUtility.buildEmail(
                        oldExec.Email,
                        'Lead Reassigned — ' + l.FirstName + ' ' + l.LastName,
                        'Hi ' + oldExec.Name + ',\n\n' +
                        'The lead for ' + l.FirstName + ' ' + l.LastName +
                        ' has been reassigned to another executive.\n\n' +
                        'Tata Motors CRM'
                    ));
                }
            }
        }

        if (!emails.isEmpty()) EmailUtility.sendEmails(emails);
    }
}