public without sharing class TestDriveController {

    @AuraEnabled
    public static String submitTestDriveRequest(
        String   firstName,
        String   lastName,
        String   email,
        String   phone,
        String   city,
        Id       variantId,
        Id       modelId,
        DateTime preferredDateTime
    ) {
        try {
            // Get model and variant names
            String modelName   = '—';
            String variantName = '—';

            if (modelId != null) {
                List<Model__c> models = [
                    SELECT Name FROM Model__c
                    WHERE Id = :modelId LIMIT 1
                ];
                if (!models.isEmpty()) {
                    modelName = models[0].Name;
                }
            }

            if (variantId != null) {
                List<Variant__c> variants = [
                    SELECT Name FROM Variant__c
                    WHERE Id = :variantId LIMIT 1
                ];
                if (!variants.isEmpty()) {
                    variantName = variants[0].Name;
                }
            }

            // ALWAYS assign to Sales Executive
            // Never to System Administrator
            List<User> salesExecs = [
                SELECT Id, Name, Email FROM User
                WHERE IsActive = true
                AND Profile.Name = 'Sales Executive'
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];

            if (salesExecs.isEmpty()) {
                throw new AuraHandledException(
                    'No Sales Executive found. ' +
                    'Please contact administrator.'
                );
            }

            Id execId = salesExecs[0].Id;

            // Create Test Drive ONLY — no Lead yet
            // Lead is created when Sales Exec confirms
            Test_Drive__c td = new Test_Drive__c(
                Customer_First_Name__c = firstName,
                Customer_Last_Name__c  = lastName,
                Customer_Email__c      = email,
                Customer_Phone__c      = phone,
                Model__c               = modelId,
                Variant__c             = variantId,
                Preferred_Date_Time__c = preferredDateTime,
                Status__c              = 'Requested',
                City__c                = city,
                OwnerId                = execId
            );

            td.Bypass_Validation__c = true;
            insert td;
            td.Bypass_Validation__c = false;
            update td;

            // Email customer
            if (!String.isBlank(email)) {
                EmailUtility.sendEmail(
                    email,
                    'Your Test Drive Request — Tata Motors',
                    'Dear ' + firstName + ',\n\n' +
                    'Thank you for booking a test drive ' +
                    'with Tata Motors!\n\n' +
                    'We have received your request and ' +
                    'our team will contact you shortly.\n\n' +
                    'YOUR REQUEST DETAILS\n' +
                    '────────────────────\n' +
                    'Model   : ' + modelName + '\n' +
                    'Variant : ' + variantName + '\n' +
                    'City    : ' + city + '\n\n' +
                    'Call us: 1800 209 7979\n\n' +
                    'Warm Regards,\n' +
                    'Tata Motors Customer Team'
                );
            }

            // Email Sales Executive
            EmailUtility.sendEmail(
                salesExecs[0].Email,
                'New Test Drive Request — ' +
                firstName + ' ' + lastName,
                'Hi ' + salesExecs[0].Name + ',\n\n' +
                'A new test drive request has been ' +
                'submitted and assigned to you.\n\n' +
                'CUSTOMER DETAILS\n' +
                '────────────────\n' +
                'Name    : ' + firstName +
                ' ' + lastName + '\n' +
                'Email   : ' + email + '\n' +
                'Phone   : ' + phone + '\n' +
                'City    : ' + city + '\n' +
                'Model   : ' + modelName + '\n' +
                'Variant : ' + variantName + '\n\n' +
                'Please confirm within 24 hours.\n\n' +
                'Tata Motors CRM'
            );

            return 'Success';

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error submitting: ' + e.getMessage()
            );
        }
    }
}