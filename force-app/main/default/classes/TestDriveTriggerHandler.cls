public class TestDriveTriggerHandler {

    public static void afterUpdate(
        List<Test_Drive__c> newList,
        Map<Id, Test_Drive__c> oldMap
    ) {
        // ── Collect model/variant ids for name lookup ──
        Set<Id> modelIds   = new Set<Id>();
        Set<Id> variantIds = new Set<Id>();
        for (Test_Drive__c td : newList) {
            if (td.Model__c   != null) modelIds.add(td.Model__c);
            if (td.Variant__c != null) variantIds.add(td.Variant__c);
        }

        Map<Id, String> modelNames   = new Map<Id, String>();
        Map<Id, String> variantNames = new Map<Id, String>();

        for (Model__c m : [
            SELECT Id, Name FROM Model__c
            WHERE Id IN :modelIds
        ]) { modelNames.put(m.Id, m.Name); }

        for (Variant__c v : [
            SELECT Id, Name FROM Variant__c
            WHERE Id IN :variantIds
        ]) { variantNames.put(v.Id, v.Name); }

        // ── Collect lead info if already linked ────────
        Set<Id> leadIds = new Set<Id>();
        for (Test_Drive__c td : newList) {
            if (td.Lead__c != null) leadIds.add(td.Lead__c);
        }
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        if (!leadIds.isEmpty()) {
            for (Lead l : [
                SELECT Id, FirstName, LastName, Email, Phone
                FROM Lead WHERE Id IN :leadIds
            ]) { leadMap.put(l.Id, l); }
        }

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();
        User manager = EmailUtility.getSalesManager();

        // TDs that need Lead created (Confirm OR Complete)
        List<Test_Drive__c> toCreateLead =
            new List<Test_Drive__c>();

        for (Test_Drive__c td : newList) {
            Test_Drive__c old = oldMap.get(td.Id);

            String modelName   = modelNames.containsKey(td.Model__c)
                ? modelNames.get(td.Model__c)   : '—';
            String variantName = variantNames.containsKey(td.Variant__c)
                ? variantNames.get(td.Variant__c) : '—';
            String city = td.City__c != null ? td.City__c : '—';

            // Get customer info from Lead if linked
            // else from Customer_*__c fields on TD
            String customerName  = '';
            String customerEmail = '';
            String customerPhone = '';

            if (td.Lead__c != null
                && leadMap.containsKey(td.Lead__c)) {
                Lead l = leadMap.get(td.Lead__c);
                customerName  = ((l.FirstName != null
                    ? l.FirstName : '') + ' ' +
                    (l.LastName != null
                    ? l.LastName : '')).trim();
                customerEmail = l.Email != null ? l.Email : '';
                customerPhone = l.Phone != null ? l.Phone : '';
            } else {
                customerName  = ((td.Customer_First_Name__c != null
                    ? td.Customer_First_Name__c : '') + ' ' +
                    (td.Customer_Last_Name__c != null
                    ? td.Customer_Last_Name__c : '')).trim();
                customerEmail = td.Customer_Email__c != null
                    ? td.Customer_Email__c : '';
                customerPhone = td.Customer_Phone__c != null
                    ? td.Customer_Phone__c : '';
            }

            // ── Requested → Confirmed ──────────────────
            if (td.Status__c == 'Confirmed'
                && old.Status__c != 'Confirmed') {

                // Create Lead if not already linked
                if (td.Lead__c == null) {
                    toCreateLead.add(td);
                }

                // Email customer
                if (!String.isBlank(customerEmail)) {
                    emails.add(EmailUtility.buildEmail(
                        customerEmail,
                        'Your Test Drive is Confirmed ✅ — Tata Motors',
                        'Dear ' + customerName + ',\n\n' +
                        'Great news! Your test drive is confirmed.\n\n' +
                        'TEST DRIVE DETAILS\n' +
                        '──────────────────\n' +
                        'Model    : ' + modelName + '\n' +
                        'Variant  : ' + variantName + '\n' +
                        'Date     : ' +
                        (td.Preferred_Date_Time__c != null
                            ? td.Preferred_Date_Time__c.format()
                            : '—') + '\n' +
                        'City     : ' + city + '\n\n' +
                        'WHAT TO BRING\n' +
                        '─────────────\n' +
                        '✓ Valid driving licence\n' +
                        '✓ This email\n' +
                        '✓ Valid photo ID\n\n' +
                        'Warm Regards,\nTata Motors Sales Team'
                    ));
                }
            }

            // ── Confirmed → Completed ──────────────────
            if (td.Status__c == 'Completed'
                && old.Status__c != 'Completed') {

                // Safety net — create Lead if missed on Confirm
                if (td.Lead__c == null) {
                    toCreateLead.add(td);
                }

                if (!String.isBlank(customerEmail)) {
                    emails.add(EmailUtility.buildEmail(
                        customerEmail,
                        'How Was Your Test Drive? — Tata Motors',
                        'Dear ' + customerName + ',\n\n' +
                        'Thank you for test driving the ' +
                        modelName + '!\n\n' +
                        'Our Sales Executive will contact you soon.\n\n' +
                        (String.isBlank(td.Notes__c) ? '' :
                            'Executive Notes: ' +
                            td.Notes__c + '\n\n') +
                        'Call us: 1800 209 7979\n\n' +
                        'Warm Regards,\nTata Motors Sales Team'
                    ));
                }

                if (manager != null) {
                    emails.add(EmailUtility.buildEmail(
                        manager.Email,
                        'Test Drive Completed — ' + customerName,
                        'Hi ' + manager.Name + ',\n\n' +
                        'Test drive completed.\n\n' +
                        'Customer : ' + customerName + '\n' +
                        'Model    : ' + modelName + '\n' +
                        'Variant  : ' + variantName + '\n' +
                        'City     : ' + city + '\n\n' +
                        (String.isBlank(td.Notes__c) ? '' :
                            'Notes: ' + td.Notes__c + '\n\n') +
                        'Tata Motors CRM'
                    ));
                }
            }

            // ── Any → Cancelled ───────────────────────
            if (td.Status__c == 'Cancelled'
                && old.Status__c != 'Cancelled') {

                if (!String.isBlank(customerEmail)) {
                    emails.add(EmailUtility.buildEmail(
                        customerEmail,
                        'Test Drive Cancelled — Tata Motors',
                        'Dear ' + customerName + ',\n\n' +
                        'Your test drive for the ' + modelName +
                        ' has been cancelled.\n\n' +
                        'Call us: 1800 209 7979 to reschedule.\n\n' +
                        'Warm Regards,\nTata Motors Sales Team'
                    ));
                }

                User exec = EmailUtility.getSalesExec(td.OwnerId);
                if (exec != null) {
                    emails.add(EmailUtility.buildEmail(
                        exec.Email,
                        'Test Drive Cancelled — ' + customerName,
                        'Hi ' + exec.Name + ',\n\n' +
                        'The test drive for ' + customerName +
                        ' (' + modelName + ') has been cancelled.\n\n' +
                        'Please follow up to reschedule.\n\n' +
                        'Tata Motors CRM'
                    ));
                }
            }
        }

        if (!emails.isEmpty()) {
            try {
                EmailUtility.sendEmails(emails);
            } catch (Exception e) {
                System.debug('Email error: ' + e.getMessage());
            }
        }

        // Create Leads for TDs that need one
        if (!toCreateLead.isEmpty()) {
            createLeadsForConfirmed(toCreateLead);
        }
    }

    // ── Create Lead on Confirm or Complete ────────────
    private static void createLeadsForConfirmed(
        List<Test_Drive__c> testDrives
    ) {
        // Always assign to Sales Executive
        List<User> salesExecs = [
            SELECT Id FROM User
            WHERE IsActive = true
            AND Profile.Name = 'Sales Executive'
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        Id execId = salesExecs.isEmpty()
            ? null : salesExecs[0].Id;

        List<Lead> leadsToInsert   = new List<Lead>();
        Map<Integer, Id> idxToTDId = new Map<Integer, Id>();

        for (Test_Drive__c td : testDrives) {
            Lead l = new Lead(
                FirstName = td.Customer_First_Name__c,
                LastName  = !String.isBlank(td.Customer_Last_Name__c)
                    ? td.Customer_Last_Name__c : 'Customer',
                Email     = td.Customer_Email__c,
                Phone     = td.Customer_Phone__c,
                City      = td.City__c,
                Preferred_City__c = td.City__c,
                LeadSource        = 'Web',
                Status            = 'New',
                Company           = 'Tata Motors Customer'
            );

            if (td.Model__c != null)
                l.Preferred_Model__c   = td.Model__c;
            if (td.Variant__c != null)
                l.Preferred_Variant__c = td.Variant__c;
            if (execId != null)
                l.OwnerId = execId;

            leadsToInsert.add(l);
            idxToTDId.put(leadsToInsert.size() - 1, td.Id);
        }

        if (leadsToInsert.isEmpty()) {
            System.debug('No leads to create');
            return;
        }

        // Insert leads — allow duplicates
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        List<Database.SaveResult> results =
            Database.insert(leadsToInsert, dml);

        System.debug('Leads inserted: ' + leadsToInsert.size());

        // Build TD → Lead mapping from results
        Set<Id> tdIdsToLink      = new Set<Id>();
        Map<Id, Id> tdIdToLeadId = new Map<Id, Id>();

        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                Id tdId   = idxToTDId.get(i);
                Id leadId = results[i].getId();
                tdIdToLeadId.put(tdId, leadId);
                tdIdsToLink.add(tdId);
                System.debug('Lead ' + leadId
                    + ' created for TD: ' + tdId);
            } else {
                System.debug('Lead insert failed: '
                    + results[i].getErrors()[0].getMessage());
            }
        }

        if (tdIdsToLink.isEmpty()) return;

        // Link TD to Lead in ONE update with bypass
        List<Test_Drive__c> toUpdate = new List<Test_Drive__c>();
        for (Id tdId : tdIdsToLink) {
            toUpdate.add(new Test_Drive__c(
                Id                   = tdId,
                Lead__c              = tdIdToLeadId.get(tdId),
                OwnerId              = execId,
                Bypass_Validation__c = true
            ));
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
            System.debug('TDs linked: ' + toUpdate.size());
            // Reset bypass in separate async transaction
            resetBypassAsync(tdIdsToLink);
        }
    }

    // ── Reset Bypass in separate transaction ──────────
    @future
    private static void resetBypassAsync(Set<Id> tdIds) {
        List<Test_Drive__c> tds = new List<Test_Drive__c>();
        for (Id tdId : tdIds) {
            tds.add(new Test_Drive__c(
                Id                   = tdId,
                Bypass_Validation__c = false
            ));
        }
        if (!tds.isEmpty()) {
            try {
                update tds;
            } catch (Exception e) {
                System.debug('resetBypass error: '
                    + e.getMessage());
            }
        }
    }
}