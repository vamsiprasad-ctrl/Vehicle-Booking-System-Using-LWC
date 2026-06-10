public without sharing class LeadManagementController {

    @AuraEnabled(cacheable=true)
    public static List<Lead> getLeads(String statusFilter) {
        Id currentUserId = UserInfo.getUserId();
        Boolean isManager = isManager();

        String query =
            'SELECT Id, FirstName, LastName, Email, Phone, ' +
            'Status, LeadSource, City, CreatedDate, ' +
            'OwnerId, Owner.Name, ' +
            'Preferred_City__c, ' +
            'Preferred_Model__c, Preferred_Model__r.Name, ' +
            'Preferred_Variant__c, Preferred_Variant__r.Name ' +
            'FROM Lead WHERE IsConverted = false ';

        if (!isManager) {
            query += 'AND OwnerId = \'' + currentUserId + '\' ';
        }

        if (!String.isBlank(statusFilter)
            && statusFilter != 'all') {
            query += 'AND Status = \'' + statusFilter + '\' ';
        }

        query += 'ORDER BY CreatedDate DESC LIMIT 100';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getSalesExecutives() {
        return [
            SELECT Id, Name, Email FROM User
            WHERE Profile.Name = 'Sales Executive'
            AND IsActive = true
            ORDER BY Name ASC
        ];
    }

    @AuraEnabled
    public static String updateLeadStatus(
        Id leadId, String newStatus
    ) {
        try {
            Lead l = new Lead(
                Id     = leadId,
                Status = newStatus
            );
            Database.SaveResult result =
                Database.update(l, false);

            if (!result.isSuccess()) {
                List<String> errors = new List<String>();
                for (Database.Error e : result.getErrors()) {
                    if (!e.getMessage().contains('Preferred_Variant')
                        && !e.getMessage().contains(
                            'Preferred Variant')) {
                        errors.add(e.getMessage());
                    }
                }
                if (!errors.isEmpty()) {
                    throw new AuraHandledException(
                        String.join(errors, ', ')
                    );
                }
            }
            return 'Success';

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error updating lead: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static String assignLead(
        Id leadId, Id newOwnerId
    ) {
        try {
            Lead l = new Lead(
                Id      = leadId,
                OwnerId = newOwnerId
            );
            Database.update(l, false);
            sendAssignEmails(leadId, newOwnerId);
            return 'Success';
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error assigning lead: ' + e.getMessage()
            );
        }
    }

    @future
    private static void sendAssignEmails(
        Id leadId, Id newOwnerId
    ) {
        try {
            Lead l = [
                SELECT Id, FirstName, LastName,
                       Email, Phone, OwnerId,
                       Preferred_Model__r.Name
                FROM Lead WHERE Id = :leadId LIMIT 1
            ];
            Id oldOwnerId = l.OwnerId;
            String modelName = l.Preferred_Model__r != null
                ? l.Preferred_Model__r.Name : '—';
            User newExec = EmailUtility.getSalesExec(newOwnerId);
            User oldExec = EmailUtility.getSalesExec(oldOwnerId);
            if (newExec != null) {
                EmailUtility.sendLeadReassignedToNewExec(
                    newExec,
                    l.FirstName + ' ' + l.LastName,
                    l.Phone, l.Email, modelName
                );
            }
            if (oldExec != null && oldOwnerId != newOwnerId) {
                EmailUtility.sendLeadReassignedToOldExec(
                    oldExec,
                    l.FirstName + ' ' + l.LastName
                );
            }
        } catch (Exception e) {
            System.debug('sendAssignEmails: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String convertLead(Id leadId) {
        try {
            Lead l = [
                SELECT Id, FirstName, LastName, Email,
                       Company, ConvertedContactId,
                       Preferred_Model__c,
                       Preferred_Variant__c,
                       Preferred_Model__r.Name,
                       OwnerId
                FROM Lead WHERE Id = :leadId LIMIT 1
            ];

            if (l.ConvertedContactId != null) {
                throw new AuraHandledException(
                    'This lead has already been converted.'
                );
            }

            // Fix blank company
            if (String.isBlank(l.Company)) {
                String co = l.Preferred_Model__r != null
                    ? 'Tata Motors - ' +
                      l.Preferred_Model__r.Name
                    : 'Tata Motors Customer';
                Database.update(
                    new Lead(Id = leadId, Company = co),
                    false
                );
                l.Company = co;
            }

            LeadStatus convertStatus = [
                SELECT MasterLabel FROM LeadStatus
                WHERE IsConverted = true LIMIT 1
            ];

            Database.LeadConvert lc =
                new Database.LeadConvert();
            lc.setLeadId(leadId);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            lc.setDoNotCreateOpportunity(false);
            lc.setOverwriteLeadSource(false);

            if (!String.isBlank(l.Email)) {
                List<Contact> existing = [
                    SELECT Id, AccountId FROM Contact
                    WHERE Email = :l.Email LIMIT 1
                ];
                if (!existing.isEmpty()
                    && existing[0].AccountId != null) {
                    lc.setContactId(existing[0].Id);
                    lc.setAccountId(existing[0].AccountId);
                }
            }

            Database.LeadConvertResult lcr =
                Database.convertLead(lc);

            if (!lcr.isSuccess()) {
                List<String> errors = new List<String>();
                for (Database.Error e : lcr.getErrors()) {
                    if (e.getStatusCode() !=
                        StatusCode.DUPLICATES_DETECTED) {
                        errors.add(e.getMessage());
                    }
                }
                if (!errors.isEmpty()) {
                    throw new AuraHandledException(
                        'Conversion failed: ' +
                        String.join(errors, ', ')
                    );
                }
            }

            // Get Sales Executive ID
            // Always assign to exec — never to admin
            Id execId = l.OwnerId;
            List<User> execs = [
                SELECT Id FROM User
                WHERE IsActive = true
                AND Profile.Name = 'Sales Executive'
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];
            if (!execs.isEmpty()) {
                execId = execs[0].Id;
            }

            // Create booking async — avoids DML limit
            if (lcr.getContactId() != null
                && l.Preferred_Model__c != null) {
                createBookingAndNotify(
                    lcr.getContactId(),
                    lcr.getOpportunityId(),
                    l.Preferred_Model__c,
                    l.Preferred_Variant__c,
                    execId // Always Sales Executive
                );
            }

            return 'Success';

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error converting lead: ' + e.getMessage()
            );
        }
    }

    @future
    private static void createBookingAndNotify(
        Id contactId,
        Id opportunityId,
        Id modelId,
        Id variantId,
        Id ownerId
    ) {
        try {
            // Get variant price
            Decimal price = 0;
            if (variantId != null) {
                List<Variant__c> variants = [
                    SELECT Price__c FROM Variant__c
                    WHERE Id = :variantId LIMIT 1
                ];
                if (!variants.isEmpty()
                    && variants[0].Price__c != null) {
                    price = variants[0].Price__c;
                }
            }

            // Always assign to Sales Executive
            Id execId = ownerId;
            List<User> execs = [
                SELECT Id FROM User
                WHERE IsActive = true
                AND Profile.Name = 'Sales Executive'
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];
            if (!execs.isEmpty()) {
                execId = execs[0].Id;
            }

            // Insert booking owned by Sales Executive
            Booking__c booking = new Booking__c(
                Contact__c                = contactId,
                Model__c                  = modelId,
                Variant__c                = variantId,
                Opportunity__c            = opportunityId,
                Total_Booking_Amount__c   = price,
                Status__c                 = 'Pending',
                Booking_Date__c           = Date.today(),
                Expected_Delivery_Date__c =
                    Date.today().addDays(30),
                OwnerId                   = execId
            );
            insert booking;

            // Create community user for customer
            List<User> existingUser = [
                SELECT Id FROM User
                WHERE ContactId = :contactId
                AND IsActive = true LIMIT 1
            ];
            if (existingUser.isEmpty()) {
                Contact con = [
                    SELECT Id, FirstName, LastName, Email
                    FROM Contact
                    WHERE Id = :contactId LIMIT 1
                ];
                if (!String.isBlank(con.Email)) {
                    System.enqueueJob(
                        new CommunityUserCreator(
                            new List<Contact>{ con }
                        )
                    );
                }
            }

        } catch (Exception e) {
            System.debug(
                'createBookingAndNotify error: ' +
                e.getMessage()
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static Lead getLeadById(Id leadId) {
        return [
            SELECT Id, FirstName, LastName, Email, Phone,
                   Status, LeadSource, City,
                   Preferred_City__c,
                   OwnerId, Owner.Name,
                   Preferred_Model__c, Preferred_Model__r.Name,
                   Preferred_Variant__c, Preferred_Variant__r.Name,
                   CreatedDate, IsConverted
            FROM Lead WHERE Id = :leadId LIMIT 1
        ];
    }

    private static Boolean isManager() {
        User u = [
            SELECT Profile.Name FROM User
            WHERE Id = :UserInfo.getUserId() LIMIT 1
        ];
        return u.Profile.Name == 'Sales Manager';
    }
}