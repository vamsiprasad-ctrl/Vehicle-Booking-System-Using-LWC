/**
 * Phase4VerificationTest.cls
 *
 * Verifies all Phase 4 setup:
 * - Role Hierarchy
 * - Profiles
 * - Users
 * - OWD (Org Wide Defaults)
 * - Sharing Rules
 * - Record Level Access
 * - Permission Set
 */
@isTest
public class Phase4VerificationTest {

    // ─────────────────────────────────────────────
    // WITH SHARING HELPER
    // ─────────────────────────────────────────────

    private with sharing class WithSharingHelper {
        public List<Booking__c> getBookings(Id bookingId) {
            return [SELECT Id FROM Booking__c WHERE Id = :bookingId];
        }
        public List<Test_Drive__c> getTestDrives(Id tdId) {
            return [SELECT Id FROM Test_Drive__c WHERE Id = :tdId];
        }
        public List<Lead> getLeads(Id leadId) {
            return [SELECT Id FROM Lead WHERE Id = :leadId];
        }
        public List<Model__c> getModels(Id modelId) {
            return [SELECT Id FROM Model__c WHERE Id = :modelId];
        }
    }


    // ─────────────────────────────────────────────
    // TEST SETUP
    // ─────────────────────────────────────────────

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Tata Motors');
        insert acc;

        Model__c model = new Model__c(
            Name         = 'Nexon',
            Is_Active__c = true
        );
        insert model;

        Variant__c variant = new Variant__c(
            Name         = 'XZ+',
            Model__c     = model.Id,
            Price__c     = 1100000,
            Fuel_Type__c = 'Petrol'
        );
        insert variant;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'Customer',
            AccountId = acc.Id
        );
        insert con;

        Opportunity opp = new Opportunity(
            Name      = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Amount    = 1100000
        );
        insert opp;
    }


    // ─────────────────────────────────────────────
    // HELPER METHODS
    // ─────────────────────────────────────────────

    static User getExecUser() {
        return [
            SELECT Id, FirstName, LastName, Profile.Name, UserRole.Name
            FROM User
            WHERE UserRole.Name = 'Sales Executive'
            AND IsActive = true
            LIMIT 1
        ];
    }

    static User getManagerUser() {
        return [
            SELECT Id, FirstName, LastName, Profile.Name, UserRole.Name
            FROM User
            WHERE UserRole.Name = 'Sales Manager'
            AND IsActive = true
            LIMIT 1
        ];
    }

    static Booking__c createBooking(Id ownerId) {
        Account     acc     = [SELECT Id FROM Account WHERE Name = 'Tata Motors' LIMIT 1];
        Model__c    model   = [SELECT Id FROM Model__c WHERE Name = 'Nexon' LIMIT 1];
        Variant__c  variant = [SELECT Id FROM Variant__c WHERE Name = 'XZ+' LIMIT 1];
        Contact     con     = [SELECT Id FROM Contact WHERE LastName = 'Customer' LIMIT 1];
        Opportunity opp     = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Booking__c b = new Booking__c(
            Contact__c                = con.Id,
            Opportunity__c            = opp.Id,
            Model__c                  = model.Id,
            Variant__c                = variant.Id,
            Total_Booking_Amount__c   = 1100000,
            Status__c                 = 'Pending',
            Booking_Date__c           = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30),
            OwnerId                   = ownerId
        );
        insert b;
        return b;
    }

    static Test_Drive__c createTestDrive(Id leadId, Id ownerId) {
        Model__c   model   = [SELECT Id FROM Model__c WHERE Name = 'Nexon' LIMIT 1];
        Variant__c variant = [SELECT Id FROM Variant__c WHERE Name = 'XZ+' LIMIT 1];

        Test_Drive__c td = new Test_Drive__c(
            Lead__c                = leadId,
            Model__c               = model.Id,
            Variant__c             = variant.Id,
            Preferred_Date_Time__c = DateTime.newInstance(
                Date.today().addDays(3), Time.newInstance(10, 0, 0, 0)
            ),
            Status__c = 'Requested',
            OwnerId   = ownerId
        );
        insert td;
        return td;
    }

    // ─────────────────────────────────────────────
    // OWD HELPER
    // Queries EntityDefinition to get sharing model
    // Returns: 'Private', 'Read', 'ReadWrite', 'ControlledByParent'
    // ─────────────────────────────────────────────

    static String getOWD(String objectApiName) {
        List<EntityDefinition> defs = [
            SELECT InternalSharingModel
            FROM EntityDefinition
            WHERE QualifiedApiName = :objectApiName
            LIMIT 1
        ];
        if (defs.isEmpty()) return null;
        return defs[0].InternalSharingModel;
    }

    // ─────────────────────────────────────────────
    // SHARING RULE HELPER
    // Queries EntityDefinition SharingRules count
    // ─────────────────────────────────────────────

    static Integer getSharingRuleCount(String objectApiName) {
        // Query the sharing rule records from the share object
        // e.g. LeadShare, BookingShare etc
        // We use a generic approach via EntityDefinition
        List<EntityDefinition> defs = [
            SELECT QualifiedApiName
            FROM EntityDefinition
            WHERE QualifiedApiName = :objectApiName
            LIMIT 1
        ];
        return defs.size();
    }


    // ─────────────────────────────────────────────
    // CHECK 1 — ROLE HIERARCHY
    // ─────────────────────────────────────────────

    @isTest
    static void testRolesExist() {
        List<UserRole> managerRole = [
            SELECT Id, Name FROM UserRole
            WHERE Name = 'Sales Manager'
        ];
        System.assert(!managerRole.isEmpty(),
            'Sales Manager role must exist — create in Setup → Roles'
        );

        List<UserRole> execRole = [
            SELECT Id, Name FROM UserRole
            WHERE Name = 'Sales Executive'
        ];
        System.assert(!execRole.isEmpty(),
            'Sales Executive role must exist — create in Setup → Roles'
        );
    }

    @isTest
    static void testRoleHierarchy() {
        UserRole execRole = [
            SELECT Id, Name, ParentRoleId
            FROM UserRole
            WHERE Name = 'Sales Executive'
            LIMIT 1
        ];
        UserRole managerRole = [
            SELECT Id, Name
            FROM UserRole
            WHERE Name = 'Sales Manager'
            LIMIT 1
        ];
        System.assertEquals(
            managerRole.Id,
            execRole.ParentRoleId,
            'Sales Executive must report to Sales Manager — ' +
            'fix in Setup → Roles → Sales Executive → Edit'
        );
    }


    // ─────────────────────────────────────────────
    // CHECK 2 — PROFILES EXIST
    // ─────────────────────────────────────────────

    @isTest
    static void testProfilesExist() {
        List<Profile> execProfile = [
            SELECT Id, Name FROM Profile
            WHERE Name = 'Sales Executive'
        ];
        System.assert(!execProfile.isEmpty(),
            'Sales Executive profile must exist — clone Standard User in Setup → Profiles'
        );

        List<Profile> mgrProfile = [
            SELECT Id, Name FROM Profile
            WHERE Name = 'Sales Manager'
        ];
        System.assert(!mgrProfile.isEmpty(),
            'Sales Manager profile must exist — clone Standard User in Setup → Profiles'
        );
    }


    // ─────────────────────────────────────────────
    // CHECK 3 — USERS HAVE CORRECT PROFILE AND ROLE
    // ─────────────────────────────────────────────

    @isTest
    static void testSalesExecUserSetup() {
        List<User> execUsers = [
            SELECT Id, FirstName, LastName, Profile.Name, UserRole.Name, IsActive
            FROM User
            WHERE UserRole.Name = 'Sales Executive'
            AND IsActive = true
        ];
        System.assert(!execUsers.isEmpty(),
            'At least one active user must have Sales Executive role'
        );
        for (User u : execUsers) {
            System.assertEquals(
                'Sales Executive', u.Profile.Name,
                'User ' + u.FirstName + ' ' + u.LastName +
                ' has wrong profile: ' + u.Profile.Name
            );
        }
    }

    @isTest
    static void testSalesManagerUserSetup() {
        List<User> mgrUsers = [
            SELECT Id, FirstName, LastName, Profile.Name, UserRole.Name, IsActive
            FROM User
            WHERE UserRole.Name = 'Sales Manager'
            AND IsActive = true
        ];
        System.assert(!mgrUsers.isEmpty(),
            'At least one active user must have Sales Manager role'
        );
        for (User u : mgrUsers) {
            System.assertEquals(
                'Sales Manager', u.Profile.Name,
                'User ' + u.FirstName + ' ' + u.LastName +
                ' has wrong profile: ' + u.Profile.Name
            );
        }
    }


    // ─────────────────────────────────────────────
    // CHECK 4 — OWD SETTINGS
    // Uses EntityDefinition.InternalSharingModel
    // Private   = 'None'
    // Read Only = 'Read'
    // Read/Write= 'Edit'
    // Controlled By Parent = 'ControlledByParent'
    // ─────────────────────────────────────────────

    @isTest
    static void testOWD_LeadIsPrivate() {
        String owd = getOWD('Lead');
        System.assertNotEquals(null, owd,
            'Could not retrieve Lead OWD'
        );
        System.assertEquals('None', owd,
            'Lead OWD must be Private (None) — ' +
            'current value: ' + owd +
            ' — fix in Setup → Sharing Settings'
        );
    }

    @isTest
    static void testOWD_ContactIsPrivate() {
        String owd = getOWD('Contact');
        System.assertNotEquals(null, owd,
            'Could not retrieve Contact OWD'
        );
        System.assertEquals('None', owd,
            'Contact OWD must be Private (None) — ' +
            'current value: ' + owd +
            ' — fix in Setup → Sharing Settings'
        );
    }

    @isTest
    static void testOWD_OpportunityIsPrivate() {
        String owd = getOWD('Opportunity');
        System.assertNotEquals(null, owd,
            'Could not retrieve Opportunity OWD'
        );
        System.assertEquals('None', owd,
            'Opportunity OWD must be Private (None) — ' +
            'current value: ' + owd +
            ' — fix in Setup → Sharing Settings'
        );
    }

    @isTest
    static void testOWD_BookingIsPrivate() {
        String owd = getOWD('Booking__c');
        System.assertNotEquals(null, owd,
            'Could not retrieve Booking__c OWD'
        );
        System.assertEquals('None', owd,
            'Booking__c OWD must be Private (None) — ' +
            'current value: ' + owd +
            ' — fix in Setup → Sharing Settings'
        );
    }

    @isTest
    static void testOWD_TestDriveIsPrivate() {
        String owd = getOWD('Test_Drive__c');
        System.assertNotEquals(null, owd,
            'Could not retrieve Test_Drive__c OWD'
        );
        System.assertEquals('None', owd,
            'Test_Drive__c OWD must be Private (None) — ' +
            'current value: ' + owd +
            ' — fix in Setup → Sharing Settings'
        );
    }

    @isTest
    static void testOWD_ModelIsPublicReadOnly() {
        String owd = getOWD('Model__c');
        System.assertNotEquals(null, owd,
            'Could not retrieve Model__c OWD'
        );
        System.assertEquals('Read', owd,
            'Model__c OWD must be Public Read Only (Read) — ' +
            'current value: ' + owd +
            ' — fix in Setup → Sharing Settings'
        );
    }


    // ─────────────────────────────────────────────
    // CHECK 5 — SHARING RULES EXIST
    // Queries the Share object for each entity
    // LeadShare, Booking__Share, Test_Drive__Share
    // RowCause = 'Rule' means a sharing rule created it
    // ─────────────────────────────────────────────

    @isTest
    static void testLeadSharingRulesExist() {
        // Insert a lead so share records can exist
        User execUser = getExecUser();
        Lead lead = new Lead(
            FirstName  = 'Share',
            LastName   = 'TestLead',
            Email      = 'share@gmail.com',
            Phone      = '9876543210',
            LeadSource = 'Phone',
            Company    = 'Individual',
            OwnerId    = execUser.Id
        );
        insert lead;

        List<LeadShare> shares = [
            SELECT Id, LeadAccessLevel, RowCause
            FROM LeadShare
            WHERE LeadId = :lead.Id
            AND RowCause = 'Rule'
        ];
        System.assert(!shares.isEmpty(),
            'Lead sharing rule must be sharing this record — ' +
            'check Lead Sharing Rules in Setup → Sharing Settings'
        );
    }

    @isTest
    static void testBookingSharingRulesExist() {
        User execUser = getExecUser();
        Booking__c booking = createBooking(execUser.Id);

        List<Booking__Share> shares = [
            SELECT Id, AccessLevel, RowCause
            FROM Booking__Share
            WHERE ParentId = :booking.Id
            AND RowCause = 'Rule'
        ];
        System.assert(!shares.isEmpty(),
            'Booking__c sharing rule must be sharing this record — ' +
            'check Booking Sharing Rules in Setup → Sharing Settings'
        );
    }

    @isTest
    static void testTestDriveSharingRulesExist() {
        User execUser = getExecUser();

        Lead lead = new Lead(
            FirstName  = 'TDShare',
            LastName   = 'Test',
            Email      = 'tdshare@gmail.com',
            Phone      = '9876543210',
            LeadSource = 'Phone',
            Company    = 'Individual',
            OwnerId    = execUser.Id
        );
        insert lead;

        Test_Drive__c td = createTestDrive(lead.Id, execUser.Id);

        List<Test_Drive__Share> shares = [
            SELECT Id, AccessLevel, RowCause
            FROM Test_Drive__Share
            WHERE ParentId = :td.Id
            AND RowCause = 'Rule'
        ];
        System.assert(!shares.isEmpty(),
            'Test_Drive__c sharing rule must be sharing this record — ' +
            'check Test Drive Sharing Rules in Setup → Sharing Settings'
        );
    }


    // ─────────────────────────────────────────────
    // CHECK 6 — RECORD LEVEL ACCESS
    // ─────────────────────────────────────────────

    @isTest
    static void testManagerCanSeeExecBooking() {
        User execUser = getExecUser();
        User mgrUser  = getManagerUser();
        Booking__c booking = createBooking(execUser.Id);

        WithSharingHelper helper = new WithSharingHelper();
        System.runAs(mgrUser) {
            List<Booking__c> result = helper.getBookings(booking.Id);
            System.assert(!result.isEmpty(),
                'Sales Manager must see Sales Executive bookings — ' +
                'check Booking sharing rule in Setup → Sharing Settings'
            );
        }
    }

    @isTest
    static void testManagerCanSeeExecTestDrive() {
        User execUser = getExecUser();
        User mgrUser  = getManagerUser();

        Lead lead = new Lead(
            FirstName  = 'TD',
            LastName   = 'Customer',
            Email      = 'td@gmail.com',
            Phone      = '9876543210',
            LeadSource = 'Phone',
            Company    = 'Individual',
            OwnerId    = execUser.Id
        );
        insert lead;

        Test_Drive__c td = createTestDrive(lead.Id, execUser.Id);

        WithSharingHelper helper = new WithSharingHelper();
        System.runAs(mgrUser) {
            List<Test_Drive__c> result = helper.getTestDrives(td.Id);
            System.assert(!result.isEmpty(),
                'Sales Manager must see Sales Executive test drives — ' +
                'check Test Drive sharing rule in Setup → Sharing Settings'
            );
        }
    }

    @isTest
    static void testExecCannotDeleteBooking() {
        User execUser = getExecUser();
        Booking__c booking = createBooking(execUser.Id);

        System.runAs(execUser) {
            Boolean exceptionThrown = false;
            try {
                delete booking;
            } catch (DmlException e) {
                exceptionThrown = true;
            }
            System.assert(exceptionThrown,
                'Sales Executive must NOT delete bookings — ' +
                'remove Delete on Booking__c in Sales Executive profile'
            );
        }
    }

    @isTest
    static void testManagerCanDeleteBooking() {
        User execUser = getExecUser();
        User mgrUser  = getManagerUser();
        Booking__c booking = createBooking(execUser.Id);

        System.runAs(mgrUser) {
            Boolean exceptionThrown = false;
            try {
                delete booking;
            } catch (DmlException e) {
                exceptionThrown = true;
                System.debug('Manager delete error: ' + e.getMessage());
            }
            System.assert(!exceptionThrown,
                'Sales Manager must be able to delete bookings — ' +
                'add Delete on Booking__c in Sales Manager profile'
            );
        }
    }

    @isTest
    static void testExecCannotSeeOtherExecLead() {
        List<User> execUsers = [
            SELECT Id FROM User
            WHERE UserRole.Name = 'Sales Executive'
            AND IsActive = true
            LIMIT 2
        ];
        if (execUsers.size() < 2) {
            System.debug(
                'Only 1 Sales Executive found — ' +
                'create a second to test record isolation'
            );
            return;
        }
        Lead lead = new Lead(
            FirstName  = 'Private',
            LastName   = 'LeadTest',
            Email      = 'private@gmail.com',
            Phone      = '9876543210',
            LeadSource = 'Phone',
            Company    = 'Individual',
            OwnerId    = execUsers[0].Id
        );
        insert lead;

        WithSharingHelper helper = new WithSharingHelper();
        System.runAs(execUsers[1]) {
            List<Lead> result = helper.getLeads(lead.Id);
            System.assert(result.isEmpty(),
                'Sales Executive must NOT see another exec private leads — ' +
                'check Lead OWD is Private'
            );
        }
    }


    // ─────────────────────────────────────────────
    // CHECK 7 — MODEL PUBLIC READ ONLY
    // ─────────────────────────────────────────────

    @isTest
    static void testExecCanReadModel() {
        User execUser = getExecUser();
        Model__c model = [SELECT Id FROM Model__c WHERE Name = 'Nexon' LIMIT 1];

        WithSharingHelper helper = new WithSharingHelper();
        System.runAs(execUser) {
            List<Model__c> result = helper.getModels(model.Id);
            System.assert(!result.isEmpty(),
                'Sales Executive must read Model records — ' +
                'check Model__c OWD is Public Read Only'
            );
        }
    }

    @isTest
    static void testExecCannotCreateModel() {
        User execUser = getExecUser();
        System.runAs(execUser) {
            Boolean exceptionThrown = false;
            try {
                Model__c m = new Model__c(
                    Name         = 'Unauthorized Model',
                    Is_Active__c = true
                );
                insert m;
            } catch (DmlException e) {
                exceptionThrown = true;
            }
            System.assert(exceptionThrown,
                'Sales Executive must NOT create Model records — ' +
                'remove Create on Model__c in Sales Executive profile'
            );
        }
    }


    // ─────────────────────────────────────────────
    // CHECK 8 — PERMISSION SET EXISTS
    // ─────────────────────────────────────────────

    @isTest
    static void testCustomerPortalPermissionSetExists() {
        List<PermissionSet> ps = [
            SELECT Id, Name, Label
            FROM PermissionSet
            WHERE Name = 'Customer_Portal_Access'
        ];
        System.assert(!ps.isEmpty(),
            'Customer_Portal_Access permission set must exist — ' +
            'create in Setup → Permission Sets'
        );
    }
}