public class OpportunityTriggerHandler {

    public static void afterUpdate(
        List<Opportunity> newOpps, Map<Id, Opportunity> oldMap
    ) {
        List<Id> quotationOppIds   = new List<Id>();
        List<Id> bookingConfOppIds = new List<Id>();

        for (Opportunity opp : newOpps) {
            Opportunity old = oldMap.get(opp.Id);
            if (opp.StageName == 'Quotation Sent' &&
                old.StageName != 'Quotation Sent') {
                quotationOppIds.add(opp.Id);
            }
            if (opp.StageName == 'Booking Confirmed' &&
                old.StageName != 'Booking Confirmed') {
                bookingConfOppIds.add(opp.Id);
            }
        }

        if (!quotationOppIds.isEmpty()) {
            sendQuotationEmails(quotationOppIds, newOpps);
        }
        if (!bookingConfOppIds.isEmpty()) {
            createBookings(bookingConfOppIds, newOpps);
        }
    }

    private static void sendQuotationEmails(
        List<Id> oppIds, List<Opportunity> newOpps
    ) {
        List<OpportunityContactRole> roles = [
            SELECT OpportunityId, Contact.FirstName, Contact.Email,
                   Opportunity.Name, Opportunity.Amount, Opportunity.CloseDate
            FROM OpportunityContactRole
            WHERE OpportunityId IN :oppIds
            AND IsPrimary = true
        ];

        Map<Id, OpportunityContactRole> roleMap =
            new Map<Id, OpportunityContactRole>();
        for (OpportunityContactRole r : roles) {
            roleMap.put(r.OpportunityId, r);
        }

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();

        for (Opportunity opp : newOpps) {
            if (!oppIds.contains(opp.Id)) continue;
            OpportunityContactRole role = roleMap.get(opp.Id);
            if (role == null || String.isBlank(role.Contact.Email)) continue;

            emails.add(EmailUtility.buildEmail(
                role.Contact.Email,
                'Your Tata Motors Quotation',
                'Dear ' + role.Contact.FirstName + ',\n\n' +
                'Please find your official quotation below.\n\n' +
                'Vehicle     : ' + opp.Name + '\n' +
                'Amount      : Rs. ' + opp.Amount + '\n' +
                'Valid Until : ' + opp.CloseDate + '\n\n' +
                'To confirm your booking please contact your Sales Executive.\n\n' +
                'Warm Regards,\nTata Motors Sales Team'
            ));
        }

        if (!emails.isEmpty()) EmailUtility.sendEmails(emails);
    }

    private static void createBookings(
        List<Id> oppIds, List<Opportunity> newOpps
    ) {
        // Get primary contact per opportunity
        List<OpportunityContactRole> roles = [
            SELECT OpportunityId, ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :oppIds
            AND IsPrimary = true
        ];

        Map<Id, Id> oppToContactMap = new Map<Id, Id>();
        for (OpportunityContactRole r : roles) {
            oppToContactMap.put(r.OpportunityId, r.ContactId);
        }

        Set<Id> contactIds = new Set<Id>(oppToContactMap.values());

        // Get Model and Variant from the contact's converted Lead Test Drive
        Map<Id, Test_Drive__c> contactToTestDriveMap =
            new Map<Id, Test_Drive__c>();

        if (!contactIds.isEmpty()) {
            List<Lead> convertedLeads = [
                SELECT Id, ConvertedContactId
                FROM Lead
                WHERE ConvertedContactId IN :contactIds
                AND IsConverted = true
            ];

            Set<Id> leadIds = new Set<Id>();
            Map<Id, Id> leadToContactMap = new Map<Id, Id>();
            for (Lead l : convertedLeads) {
                leadIds.add(l.Id);
                leadToContactMap.put(l.Id, l.ConvertedContactId);
            }

            if (!leadIds.isEmpty()) {
                List<Test_Drive__c> testDrives = [
                    SELECT Id, Lead__c, Model__c, Variant__c
                    FROM Test_Drive__c
                    WHERE Lead__c IN :leadIds
                    ORDER BY CreatedDate DESC
                ];

                // Take most recent test drive per contact
                for (Test_Drive__c td : testDrives) {
                    Id contactId = leadToContactMap.get(td.Lead__c);
                    if (contactId != null &&
                        !contactToTestDriveMap.containsKey(contactId)) {
                        contactToTestDriveMap.put(contactId, td);
                    }
                }
            }
        }

        List<Booking__c> bookingsToCreate = new List<Booking__c>();

        for (Opportunity opp : newOpps) {
            if (!oppIds.contains(opp.Id)) continue;

            Id contactId = oppToContactMap.get(opp.Id);
            Test_Drive__c td = contactToTestDriveMap.get(contactId);

            Booking__c b = new Booking__c(
                Opportunity__c            = opp.Id,
                Contact__c                = contactId,
                Total_Booking_Amount__c   = opp.Amount,
                Status__c                 = 'Pending',
                Booking_Date__c           = Date.today(),
                Expected_Delivery_Date__c = Date.today().addDays(30)
            );

            // Populate Model and Variant from the test drive record
            if (td != null) {
                b.Model__c   = td.Model__c;
                b.Variant__c = td.Variant__c;
            }

            bookingsToCreate.add(b);
        }

        if (!bookingsToCreate.isEmpty()) insert bookingsToCreate;
    }
}