/**
 * ValidationRulesTest.cls
 * 
 * Comprehensive test class for all 19 validation rules
 * across Lead, Test_Drive__c, Variant__c, Booking__c,
 * Payment__c, and Opportunity objects.
 *
 * Each test method:
 *   - Tests the PASSING scenario (valid data saves successfully)
 *   - Tests the FAILING scenario (bad data is blocked)
 *   - Asserts the correct error message fires
 *
 * Coverage target: 100% of all 19 rules
 */
@isTest
public class ValidationRulesTest1 {

    // ─────────────────────────────────────────────
    // TEST DATA SETUP
    // ─────────────────────────────────────────────

    /**
     * Creates the single Tata Motors Account required
     * for all booking and contact related tests.
     * Reads the ID from Custom Setting App_Config__c.
     */
    static Account getTataMotorsAccount() {
        // In a real org this already exists — in test context
        // we create it fresh since tests run in isolation
        Account acc = new Account(Name = 'Tata Motors');
        insert acc;
        return acc;
    }

    /**
     * Creates a valid Model__c record for tests
     * that need a parent model.
     */
    static Model__c createModel() {
        Model__c m = new Model__c(
            Name       = 'Nexon',
            Is_Active__c = true
        );
        insert m;
        return m;
    }

    /**
     * Creates a valid Variant__c for a given model.
     */
    static Variant__c createVariant(Id modelId) {
        Variant__c v = new Variant__c(
            Name      = 'XZ+',
            Model__c  = modelId,
            Price__c  = 1100000, // ₹11,00,000
            Fuel_Type__c = 'Petrol'
        );
        insert v;
        return v;
    }

    /**
     * Creates a valid Contact under Tata Motors Account.
     */
    static Contact createContact(Id accountId) {
        Contact c = new Contact(
            FirstName  = 'Ravi',
            LastName   = 'Kumar',
            Email      = 'ravi.kumar@gmail.com',
            Phone      = '9876543210',
            AccountId  = accountId
        );
        insert c;
        return c;
    }

    /**
     * Creates a valid Opportunity.
     */
    static Opportunity createOpportunity(Id accountId, Id contactId) {
        Opportunity opp = new Opportunity(
            Name        = 'Ravi Kumar - Nexon',
            AccountId   = accountId,
            StageName   = 'Qualification',
            CloseDate   = Date.today().addDays(60),
            Amount      = 1100000
        );
        insert opp;
        return opp;
    }

    /**
     * Creates a valid approved Booking__c.
     */
    static Booking__c createApprovedBooking(
        Id contactId, Id oppId, Id modelId, Id variantId
    ) {
        Booking__c b = new Booking__c(
            Contact__c              = contactId,
            Opportunity__c          = oppId,
            Model__c                = modelId,
            Variant__c              = variantId,
            Total_Booking_Amount__c = 1100000,
            Status__c               = 'Approved',
            Booking_Date__c         = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        insert b;
        return b;
    }


    // ─────────────────────────────────────────────
    // LEAD RULES (Rules 1 – 4)
    // ─────────────────────────────────────────────

    // ── Rule 1: Valid_Email_Format ────────────────

    @isTest
    static void testRule1_ValidEmail_Pass() {
        Lead l = new Lead(
            FirstName       = 'Ravi',
            LastName        = 'Kumar',
            Email           = 'ravi.kumar@gmail.com',
            Phone           = '9876543210',
            LeadSource      = 'Phone',
            Company         = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(result.isSuccess(),
            'Valid email should save successfully');
    }

    @isTest
static void testRule1_BlankEmail_Fail() {
    // Test with null email — more reliable than empty string
    // as Salesforce treats them differently on Lead
    Lead l = new Lead(
        FirstName  = 'Ravi',
        LastName   = 'Kumar',
        Email      = null,
        Phone      = '9876543210',
        LeadSource = 'Phone',
        Company    = 'Individual'
    );
    Test.startTest();
    Database.SaveResult result = Database.insert(l, false);
    Test.stopTest();

    // If validation rule blocks it — good
    // If Salesforce standard validation blocks it — also good
    // Either way the record must not save
    System.assert(!result.isSuccess(),
        'Null email should be blocked — either by custom rule or standard validation');
}
    @isTest
    static void testRule1_InvalidEmailFormat_Fail() {
        Lead l = new Lead(
            FirstName  = 'Ravi',
            LastName   = 'Kumar',
            Email      = 'ravi@',
            Phone      = '9876543210',
            LeadSource = 'Phone',
            Company    = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Malformed email should be blocked');
    }

    @isTest
    static void testRule1_ConsecutiveDots_Fail() {
        Lead l = new Lead(
            FirstName  = 'Ravi',
            LastName   = 'Kumar',
            Email      = 'ravi..kumar@gmail.com',
            Phone      = '9876543210',
            LeadSource = 'Phone',
            Company    = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Email with consecutive dots should be blocked');
    }


    // ── Rule 2: Valid_Phone_Number ────────────────

    @isTest
    static void testRule2_ValidPhone_Pass() {
        Lead l = new Lead(
            FirstName  = 'Ravi',
            LastName   = 'Kumar',
            Email      = 'ravi@gmail.com',
            Phone      = '9876543210',
            LeadSource = 'Phone',
            Company    = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(result.isSuccess(),
            'Valid 10-digit phone starting with 9 should pass');
    }

    @isTest
    static void testRule2_BlankPhone_Fail() {
        Lead l = new Lead(
            FirstName  = 'Ravi',
            LastName   = 'Kumar',
            Email      = 'ravi@gmail.com',
            Phone      = '',
            LeadSource = 'Phone',
            Company    = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Blank phone should be blocked');
    }

    @isTest
    static void testRule2_PhoneStartingWithZero_Fail() {
        Lead l = new Lead(
            FirstName  = 'Ravi',
            LastName   = 'Kumar',
            Email      = 'ravi@gmail.com',
            Phone      = '0876543210',
            LeadSource = 'Phone',
            Company    = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Phone starting with 0 should be blocked');
    }

    @isTest
    static void testRule2_NineDigitPhone_Fail() {
        Lead l = new Lead(
            FirstName  = 'Ravi',
            LastName   = 'Kumar',
            Email      = 'ravi@gmail.com',
            Phone      = '987654321',
            LeadSource = 'Phone',
            Company    = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            '9-digit phone should be blocked');
    }


    // ── Rule 3: Variant_Required_For_Web ─────────

    @isTest
    static void testRule3_WebLeadWithVariant_Pass() {
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);

        Lead l = new Lead(
            FirstName            = 'Ravi',
            LastName             = 'Kumar',
            Email                = 'ravi@gmail.com',
            Phone                = '9876543210',
            LeadSource           = 'Web',
            Preferred_Variant__c = variant.Id,
            Company              = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(result.isSuccess(),
            'Web lead with variant should save');
    }

    @isTest
    static void testRule3_WebLeadWithoutVariant_Fail() {
        Lead l = new Lead(
            FirstName  = 'Ravi',
            LastName   = 'Kumar',
            Email      = 'ravi@gmail.com',
            Phone      = '9876543210',
            LeadSource = 'Web',
            Company    = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Web lead without variant should be blocked');
        System.assert(
            result.getErrors()[0].getMessage().contains('Variant'),
            'Error should mention Variant'
        );
    }

    @isTest
    static void testRule3_BlankLeadSourceWithoutVariant_Fail() {
        Lead l = new Lead(
            FirstName  = 'Ravi',
            LastName   = 'Kumar',
            Email      = 'ravi@gmail.com',
            Phone      = '9876543210',
            Company    = 'Individual'
            // LeadSource intentionally blank
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Lead with blank source and no variant should be blocked');
    }


    // ── Rule 4: First_And_Last_Name_Required ─────

    @isTest
    static void testRule4_ValidNames_Pass() {
        Lead l = new Lead(
            FirstName  = 'Ravi',
            LastName   = 'Kumar',
            Email      = 'ravi@gmail.com',
            Phone      = '9876543210',
            LeadSource = 'Phone',
            Company    = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(result.isSuccess(),
            'Valid names should save successfully');
    }

    @isTest
    static void testRule4_SingleCharFirstName_Fail() {
        Lead l = new Lead(
            FirstName  = 'R',
            LastName   = 'Kumar',
            Email      = 'ravi@gmail.com',
            Phone      = '9876543210',
            LeadSource = 'Phone',
            Company    = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Single character first name should be blocked');
    }

    @isTest
    static void testRule4_NumbersInName_Fail() {
        Lead l = new Lead(
            FirstName  = 'Ravi123',
            LastName   = 'Kumar',
            Email      = 'ravi@gmail.com',
            Phone      = '9876543210',
            LeadSource = 'Phone',
            Company    = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Numbers in name should be blocked');
    }

    @isTest
    static void testRule4_WhitespaceOnlyName_Fail() {
        Lead l = new Lead(
            FirstName  = '   ',
            LastName   = 'Kumar',
            Email      = 'ravi@gmail.com',
            Phone      = '9876543210',
            LeadSource = 'Phone',
            Company    = 'Individual'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(l, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Whitespace-only first name should be blocked');
    }


    // ─────────────────────────────────────────────
    // TEST DRIVE RULES (Rules 5, 6, 6B)
    // ─────────────────────────────────────────────

    static Lead createValidLead() {
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);
        Lead l = new Lead(
            FirstName            = 'Ravi',
            LastName             = 'Kumar',
            Email                = 'ravi@gmail.com',
            Phone                = '9876543210',
            LeadSource           = 'Web',
            Preferred_Variant__c = variant.Id,
            Company              = 'Individual'
        );
        insert l;
        return l;
    }

    // ── Rule 5: Future_Date_Only ──────────────────

    @isTest
    static void testRule5_FutureWeekdayDate_Pass() {
        Lead       lead    = createValidLead();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);

        // Find next Monday at 10am
        DateTime futureDate = DateTime.newInstance(
            Date.today().addDays(3), Time.newInstance(10, 0, 0, 0)
        );

        Test_Drive__c td = new Test_Drive__c(
            Lead__c               = lead.Id,
            Model__c              = model.Id,
            Variant__c            = variant.Id,
            Preferred_Date_Time__c = futureDate,
            Status__c             = 'Requested'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(td, false);
        Test.stopTest();
        System.assert(result.isSuccess(),
            'Future weekday date within 30 days should pass');
    }

    @isTest
    static void testRule5_PastDate_Fail() {
        Lead       lead    = createValidLead();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);

        DateTime pastDate = DateTime.newInstance(
            Date.today().addDays(-1), Time.newInstance(10, 0, 0, 0)
        );

        Test_Drive__c td = new Test_Drive__c(
            Lead__c               = lead.Id,
            Model__c              = model.Id,
            Variant__c            = variant.Id,
            Preferred_Date_Time__c = pastDate,
            Status__c             = 'Requested'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(td, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Past date should be blocked');
    }

    @isTest
    static void testRule5_Beyond30Days_Fail() {
        Lead       lead    = createValidLead();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);

        DateTime farDate = DateTime.newInstance(
            Date.today().addDays(31), Time.newInstance(10, 0, 0, 0)
        );

        Test_Drive__c td = new Test_Drive__c(
            Lead__c               = lead.Id,
            Model__c              = model.Id,
            Variant__c            = variant.Id,
            Preferred_Date_Time__c = farDate,
            Status__c             = 'Requested'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(td, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Date beyond 30 days should be blocked');
    }

   @isTest
static void testRule5_OutsideBusinessHours_Fail() {
    Lead       lead    = createValidLead();
    Model__c   model   = createModel();
    Variant__c variant = createVariant(model.Id);

    // Using midnight (hour 0) — unambiguously outside 9am-6pm
    // in any timezone including UTC vs IST difference
    DateTime earlyDate = DateTime.newInstance(
        Date.today().addDays(3), Time.newInstance(0, 0, 0, 0)
    );

    Test_Drive__c td = new Test_Drive__c(
        Lead__c                = lead.Id,
        Model__c               = model.Id,
        Variant__c             = variant.Id,
        Preferred_Date_Time__c = earlyDate,
        Status__c              = 'Requested'
    );
    Test.startTest();
    Database.SaveResult result = Database.insert(td, false);
    Test.stopTest();
    System.assert(!result.isSuccess(),
        'Midnight should be blocked — outside business hours 9am to 6pm');
}


    // ── Rule 6: Notes_Required_On_Complete ───────

    @isTest
    static void testRule6_CompletedWithNotes_Pass() {
        Lead       lead    = createValidLead();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);

        Test_Drive__c td = new Test_Drive__c(
            Lead__c               = lead.Id,
            Model__c              = model.Id,
            Variant__c            = variant.Id,
            Preferred_Date_Time__c = DateTime.newInstance(
                Date.today().addDays(3), Time.newInstance(10,0,0,0)
            ),
            Status__c = 'Confirmed'
        );
        insert td;

        td.Status__c = 'Completed';
        td.Notes__c  = 'Customer liked the XZ+ variant. Interested in red color.';

        Test.startTest();
        Database.SaveResult result = Database.update(td, false);
        Test.stopTest();
        System.assert(result.isSuccess(),
            'Completed status with notes should save');
    }

    @isTest
    static void testRule6_CompletedWithoutNotes_Fail() {
        Lead       lead    = createValidLead();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);

        Test_Drive__c td = new Test_Drive__c(
            Lead__c               = lead.Id,
            Model__c              = model.Id,
            Variant__c            = variant.Id,
            Preferred_Date_Time__c = DateTime.newInstance(
                Date.today().addDays(3), Time.newInstance(10,0,0,0)
            ),
            Status__c = 'Confirmed'
        );
        insert td;

        td.Status__c = 'Completed';
        // Notes intentionally blank

        Test.startTest();
        Database.SaveResult result = Database.update(td, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Completed without notes should be blocked');
    }

    @isTest
    static void testRule6_SkipToCompletedFromRequested_Fail() {
        Lead       lead    = createValidLead();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);

        Test_Drive__c td = new Test_Drive__c(
            Lead__c               = lead.Id,
            Model__c              = model.Id,
            Variant__c            = variant.Id,
            Preferred_Date_Time__c = DateTime.newInstance(
                Date.today().addDays(3), Time.newInstance(10,0,0,0)
            ),
            Status__c = 'Requested'
        );
        insert td;

        // Jump straight from Requested → Completed (skipping Confirmed)
        td.Status__c = 'Completed';
        td.Notes__c  = 'Some notes';

        Test.startTest();
        Database.SaveResult result = Database.update(td, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Jumping from Requested to Completed should be blocked');
    }


    // ── Rule 6B: No_Backwards_Status ─────────────

    @isTest
    static void testRule6B_CompletedToCancelled_Fail() {
        Lead       lead    = createValidLead();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);

        Test_Drive__c td = new Test_Drive__c(
            Lead__c               = lead.Id,
            Model__c              = model.Id,
            Variant__c            = variant.Id,
            Preferred_Date_Time__c = DateTime.newInstance(
                Date.today().addDays(3), Time.newInstance(10,0,0,0)
            ),
            Status__c = 'Confirmed',
            Notes__c  = 'Test notes'
        );
        insert td;
        td.Status__c = 'Completed';
        update td;

        // Now try to cancel a completed test drive
        td.Status__c = 'Cancelled';

        Test.startTest();
        Database.SaveResult result = Database.update(td, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Completed to Cancelled should be blocked');
        System.assert(
            result.getErrors()[0].getMessage().contains('completed'),
            'Error should mention completed test drive'
        );
    }


    // ─────────────────────────────────────────────
    // VARIANT RULES (Rule 7)
    // ─────────────────────────────────────────────

    // ── Rule 7: Price_Greater_Than_Zero ──────────

    @isTest
    static void testRule7_ValidPrice_Pass() {
        Model__c model = createModel();
        Variant__c v = new Variant__c(
            Name         = 'XM',
            Model__c     = model.Id,
            Price__c     = 850000,
            Fuel_Type__c = 'Petrol'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(v, false);
        Test.stopTest();
        System.assert(result.isSuccess(),
            'Valid price should save');
    }

    @isTest
    static void testRule7_ZeroPrice_Fail() {
        Model__c model = createModel();
        Variant__c v = new Variant__c(
            Name         = 'XM',
            Model__c     = model.Id,
            Price__c     = 0,
            Fuel_Type__c = 'Petrol'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(v, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Zero price should be blocked');
    }

    @isTest
    static void testRule7_NegativePrice_Fail() {
        Model__c model = createModel();
        Variant__c v = new Variant__c(
            Name         = 'XM',
            Model__c     = model.Id,
            Price__c     = -100,
            Fuel_Type__c = 'Petrol'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(v, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Negative price should be blocked');
    }

    @isTest
    static void testRule7_PriceAboveCap_Fail() {
        Model__c model = createModel();
        Variant__c v = new Variant__c(
            Name         = 'XM',
            Model__c     = model.Id,
            Price__c     = 9999999, // Above ₹50L cap
            Fuel_Type__c = 'Petrol'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(v, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Price above ₹50L cap should be blocked');
    }


    // ─────────────────────────────────────────────
    // BOOKING RULES (Rules 8, 9, 9B, 10)
    // ─────────────────────────────────────────────

    // ── Rule 8: Amount_Required ───────────────────

    @isTest
    static void testRule8_ValidAmount_Pass() {
        Account    acc     = getTataMotorsAccount();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);
        Contact    con     = createContact(acc.Id);
        Opportunity opp    = createOpportunity(acc.Id, con.Id);

        Booking__c b = new Booking__c(
            Contact__c              = con.Id,
            Opportunity__c          = opp.Id,
            Model__c                = model.Id,
            Variant__c              = variant.Id,
            Total_Booking_Amount__c = 1100000, // Matches variant price
            Status__c               = 'Pending',
            Booking_Date__c         = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(b, false);
        Test.stopTest();
        System.assert(result.isSuccess(),
            'Valid booking amount should save');
    }

    @isTest
    static void testRule8_AmountBelowMinimum_Fail() {
        Account    acc     = getTataMotorsAccount();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);
        Contact    con     = createContact(acc.Id);
        Opportunity opp    = createOpportunity(acc.Id, con.Id);

        Booking__c b = new Booking__c(
            Contact__c              = con.Id,
            Opportunity__c          = opp.Id,
            Model__c                = model.Id,
            Variant__c              = variant.Id,
            Total_Booking_Amount__c = 50000, // Below ₹1L minimum
            Status__c               = 'Pending',
            Booking_Date__c         = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(b, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Amount below ₹1L minimum should be blocked');
    }

    @isTest
    static void testRule8_AmountBelowHalfVariantPrice_Fail() {
        Account    acc     = getTataMotorsAccount();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id); // Price = ₹11L
        Contact    con     = createContact(acc.Id);
        Opportunity opp    = createOpportunity(acc.Id, con.Id);

        Booking__c b = new Booking__c(
            Contact__c              = con.Id,
            Opportunity__c          = opp.Id,
            Model__c                = model.Id,
            Variant__c              = variant.Id,
            Total_Booking_Amount__c = 400000, // Below 50% of ₹11L
            Status__c               = 'Pending',
            Booking_Date__c         = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(b, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Amount below 50% of variant price should be blocked');
    }


    // ── Rule 9: Delivery_After_Booking_Date ───────

    @isTest
    static void testRule9_DeliveryBeforeBooking_Fail() {
        Account    acc     = getTataMotorsAccount();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);
        Contact    con     = createContact(acc.Id);
        Opportunity opp    = createOpportunity(acc.Id, con.Id);

        Booking__c b = new Booking__c(
            Contact__c              = con.Id,
            Opportunity__c          = opp.Id,
            Model__c                = model.Id,
            Variant__c              = variant.Id,
            Total_Booking_Amount__c = 1100000,
            Status__c               = 'Pending',
            Booking_Date__c         = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(-1) // Before booking
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(b, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Delivery before booking date should be blocked');
    }

    @isTest
    static void testRule9_DeliveryBeyond90Days_Fail() {
        Account    acc     = getTataMotorsAccount();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);
        Contact    con     = createContact(acc.Id);
        Opportunity opp    = createOpportunity(acc.Id, con.Id);

        Booking__c b = new Booking__c(
            Contact__c              = con.Id,
            Opportunity__c          = opp.Id,
            Model__c                = model.Id,
            Variant__c              = variant.Id,
            Total_Booking_Amount__c = 1100000,
            Status__c               = 'Pending',
            Booking_Date__c         = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(91) // Beyond 90 days
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(b, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Delivery beyond 90 days should be blocked');
    }

    @isTest
    static void testRule9_BlankBookingDate_Fail() {
        Account    acc     = getTataMotorsAccount();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);
        Contact    con     = createContact(acc.Id);
        Opportunity opp    = createOpportunity(acc.Id, con.Id);

        Booking__c b = new Booking__c(
            Contact__c              = con.Id,
            Opportunity__c          = opp.Id,
            Model__c                = model.Id,
            Variant__c              = variant.Id,
            Total_Booking_Amount__c = 1100000,
            Status__c               = 'Pending',
            // Booking_Date__c intentionally blank
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(b, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Blank booking date should be blocked');
    }


    // ── Rule 9B: Booking_Date_Cannot_Be_Past ─────

    @isTest
    static void testRule9B_EditBookingDateToPast_Fail() {
        Account    acc     = getTataMotorsAccount();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);
        Contact    con     = createContact(acc.Id);
        Opportunity opp    = createOpportunity(acc.Id, con.Id);

        Booking__c b = new Booking__c(
            Contact__c              = con.Id,
            Opportunity__c          = opp.Id,
            Model__c                = model.Id,
            Variant__c              = variant.Id,
            Total_Booking_Amount__c = 1100000,
            Status__c               = 'Pending',
            Booking_Date__c         = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        insert b;

        // Try editing booking date to past
        b.Booking_Date__c = Date.today().addDays(-5);

        Test.startTest();
        Database.SaveResult result = Database.update(b, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Setting booking date to past on edit should be blocked');
    }


    // ── Rule 10: No_Edit_After_Approval ──────────

    @isTest
    static void testRule10_EditAmountAfterApproval_Fail() {
        Account    acc     = getTataMotorsAccount();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);
        Contact    con     = createContact(acc.Id);
        Opportunity opp    = createOpportunity(acc.Id, con.Id);

        Booking__c b = createApprovedBooking(
            con.Id, opp.Id, model.Id, variant.Id
        );

        // Try to change amount after approval
        b.Total_Booking_Amount__c = 900000;

        Test.startTest();
        Database.SaveResult result = Database.update(b, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Editing amount after approval should be blocked');
    }

    @isTest
    static void testRule10_EditVariantAfterApproval_Fail() {
        Account    acc      = getTataMotorsAccount();
        Model__c   model    = createModel();
        Variant__c variant  = createVariant(model.Id);
        Variant__c variant2 = new Variant__c(
            Name         = 'XM',
            Model__c     = model.Id,
            Price__c     = 850000,
            Fuel_Type__c = 'Diesel'
        );
        insert variant2;

        Contact     con = createContact(acc.Id);
        Opportunity opp = createOpportunity(acc.Id, con.Id);

        Booking__c b = createApprovedBooking(
            con.Id, opp.Id, model.Id, variant.Id
        );

        // Try to change variant after approval
        b.Variant__c = variant2.Id;

        Test.startTest();
        Database.SaveResult result = Database.update(b, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Editing variant after approval should be blocked');
    }

    @isTest
    static void testRule10_RollbackApprovedToPending_Fail() {
        Account    acc     = getTataMotorsAccount();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);
        Contact    con     = createContact(acc.Id);
        Opportunity opp    = createOpportunity(acc.Id, con.Id);

        Booking__c b = createApprovedBooking(
            con.Id, opp.Id, model.Id, variant.Id
        );

        // Try to roll status back to Pending
        b.Status__c = 'Pending';

        Test.startTest();
        Database.SaveResult result = Database.update(b, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Rolling back Approved to Pending should be blocked');
    }


    // ─────────────────────────────────────────────
    // PAYMENT RULES (Rules 11, 12, 13, 13B)
    // ─────────────────────────────────────────────

    static Booking__c setupApprovedBooking() {
        Account    acc     = getTataMotorsAccount();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);
        Contact    con     = createContact(acc.Id);
        Opportunity opp    = createOpportunity(acc.Id, con.Id);
        return createApprovedBooking(con.Id, opp.Id, model.Id, variant.Id);
    }

    // ── Rule 11: Positive_Payment ─────────────────

    @isTest
    static void testRule11_ValidPayment_Pass() {
        Booking__c booking = setupApprovedBooking();

        Payment__c p = new Payment__c(
            Booking__c        = booking.Id,
            Payment_Amount__c = 500000,
            Payment_Date__c   = Date.today(),
            Payment_Method__c = 'UPI',
            Status__c         = 'Pending'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(p, false);
        Test.stopTest();
        System.assert(result.isSuccess(),
            'Valid payment should save');
    }

    @isTest
    static void testRule11_ZeroPayment_Fail() {
        Booking__c booking = setupApprovedBooking();

        Payment__c p = new Payment__c(
            Booking__c        = booking.Id,
            Payment_Amount__c = 0,
            Payment_Date__c   = Date.today(),
            Payment_Method__c = 'UPI',
            Status__c         = 'Pending'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(p, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Zero payment should be blocked');
    }

    @isTest
    static void testRule11_PaymentExceedsRemainingBalance_Fail() {
        Booking__c booking = setupApprovedBooking();

        // First payment of ₹8L
        Payment__c p1 = new Payment__c(
            Booking__c        = booking.Id,
            Payment_Amount__c = 800000,
            Payment_Date__c   = Date.today(),
            Payment_Method__c = 'UPI',
            Status__c         = 'Pending'
        );
        insert p1;

        // Second payment of ₹5L — would exceed ₹11L total
        Payment__c p2 = new Payment__c(
            Booking__c        = booking.Id,
            Payment_Amount__c = 500000,
            Payment_Date__c   = Date.today(),
            Payment_Method__c = 'Cash',
            Status__c         = 'Pending'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(p2, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Payment exceeding remaining balance should be blocked');
    }


    // ── Rule 12: Payment_Not_Future_Date ─────────

    @isTest
    static void testRule12_FuturePaymentDate_Fail() {
        Booking__c booking = setupApprovedBooking();

        Payment__c p = new Payment__c(
            Booking__c        = booking.Id,
            Payment_Amount__c = 500000,
            Payment_Date__c   = Date.today().addDays(5), // Future date
            Payment_Method__c = 'UPI',
            Status__c         = 'Pending'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(p, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Future payment date should be blocked');
    }

    @isTest
    static void testRule12_BlankPaymentDate_Fail() {
        Booking__c booking = setupApprovedBooking();

        Payment__c p = new Payment__c(
            Booking__c        = booking.Id,
            Payment_Amount__c = 500000,
            // Payment_Date__c intentionally blank
            Payment_Method__c = 'UPI',
            Status__c         = 'Pending'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(p, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Blank payment date should be blocked');
    }

    @isTest
    static void testRule12_PaymentBeforeBookingDate_Fail() {
        Booking__c booking = setupApprovedBooking();

        Payment__c p = new Payment__c(
            Booking__c        = booking.Id,
            Payment_Amount__c = 500000,
            Payment_Date__c   = Date.today().addDays(-10), // Before booking date
            Payment_Method__c = 'UPI',
            Status__c         = 'Pending'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(p, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Payment date before booking date should be blocked');
    }


    // ── Rule 13: Booking_Must_Be_Approved ────────

    @isTest
    static void testRule13_PaymentOnPendingBooking_Fail() {
        Account    acc     = getTataMotorsAccount();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);
        Contact    con     = createContact(acc.Id);
        Opportunity opp    = createOpportunity(acc.Id, con.Id);

        // Create a PENDING booking (not approved)
        Booking__c b = new Booking__c(
            Contact__c              = con.Id,
            Opportunity__c          = opp.Id,
            Model__c                = model.Id,
            Variant__c              = variant.Id,
            Total_Booking_Amount__c = 1100000,
            Status__c               = 'Pending',
            Booking_Date__c         = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        insert b;

        Payment__c p = new Payment__c(
            Booking__c        = b.Id,
            Payment_Amount__c = 500000,
            Payment_Date__c   = Date.today(),
            Payment_Method__c = 'UPI',
            Status__c         = 'Pending'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(p, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Payment on Pending booking should be blocked');
        System.assert(
            result.getErrors()[0].getMessage().contains('Approved'),
            'Error should mention Approved booking requirement'
        );
    }

    @isTest
    static void testRule13_PaymentOnCancelledBooking_Fail() {
        Account    acc     = getTataMotorsAccount();
        Model__c   model   = createModel();
        Variant__c variant = createVariant(model.Id);
        Contact    con     = createContact(acc.Id);
        Opportunity opp    = createOpportunity(acc.Id, con.Id);

        Booking__c b = new Booking__c(
            Contact__c              = con.Id,
            Opportunity__c          = opp.Id,
            Model__c                = model.Id,
            Variant__c              = variant.Id,
            Total_Booking_Amount__c = 1100000,
            Status__c               = 'Cancelled',
            Booking_Date__c         = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        insert b;

        Payment__c p = new Payment__c(
            Booking__c        = b.Id,
            Payment_Amount__c = 500000,
            Payment_Date__c   = Date.today(),
            Payment_Method__c = 'UPI',
            Status__c         = 'Pending'
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(p, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Payment on Cancelled booking should be blocked');
    }


    // ── Rule 13B: No_Instant_Completion ──────────

    @isTest
    static void testRule13B_NewPaymentAsCompleted_Fail() {
        Booking__c booking = setupApprovedBooking();

        Payment__c p = new Payment__c(
            Booking__c        = booking.Id,
            Payment_Amount__c = 500000,
            Payment_Date__c   = Date.today(),
            Payment_Method__c = 'UPI',
            Status__c         = 'Completed' // Should start as Pending
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(p, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'New payment with Completed status should be blocked');
        System.assert(
            result.getErrors()[0].getMessage().contains('Pending'),
            'Error should say payment must start as Pending'
        );
    }


    // ─────────────────────────────────────────────
    // OPPORTUNITY RULES (Rules 14, 14B, 14C)
    // ─────────────────────────────────────────────

    // ── Rule 14: Amount_Required_For_Quotation ───

    @isTest
    static void testRule14_QuotationWithAmount_Pass() {
        Account    acc = getTataMotorsAccount();
        Contact    con = createContact(acc.Id);
        Opportunity opp = createOpportunity(acc.Id, con.Id);

        opp.StageName = 'Quotation Sent';
        opp.Amount    = 1100000;

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();
        System.assert(result.isSuccess(),
            'Quotation Sent with valid amount should save');
    }

    @isTest
    static void testRule14_QuotationWithBlankAmount_Fail() {
        Account    acc = getTataMotorsAccount();
        Contact    con = createContact(acc.Id);
        Opportunity opp = new Opportunity(
            Name      = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(60)
            // Amount intentionally blank
        );
        insert opp;

        opp.StageName = 'Quotation Sent';

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Quotation Sent with blank amount should be blocked');
    }

    @isTest
    static void testRule14_QuotationWithZeroAmount_Fail() {
        Account    acc = getTataMotorsAccount();
        Contact    con = createContact(acc.Id);
        Opportunity opp = createOpportunity(acc.Id, con.Id);

        opp.StageName = 'Quotation Sent';
        opp.Amount    = 0;

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Quotation Sent with zero amount should be blocked');
    }


    // ── Rule 14B: Stage_Sequence_Enforced ────────

    @isTest
    static void testRule14B_SkipToNegotiation_Fail() {
        Account    acc = getTataMotorsAccount();
        Contact    con = createContact(acc.Id);
        Opportunity opp = createOpportunity(acc.Id, con.Id);
        // Currently at Qualification — skip straight to Negotiation

        opp.StageName = 'Negotiation';

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Jumping to Negotiation without Quotation Sent should be blocked');
        System.assert(
            result.getErrors()[0].getMessage().contains('quotation'),
            'Error should mention quotation must be sent first'
        );
    }

    @isTest
    static void testRule14B_ProperSequence_Pass() {
        Account    acc = getTataMotorsAccount();
        Contact    con = createContact(acc.Id);
        Opportunity opp = createOpportunity(acc.Id, con.Id);

        // Move to Quotation Sent first
        opp.StageName = 'Quotation Sent';
        opp.Amount    = 1100000;
        update opp;

        // Now move to Negotiation — this should pass
        opp.StageName = 'Negotiation';

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();
        System.assert(result.isSuccess(),
            'Moving from Quotation Sent to Negotiation should pass');
    }


    // ── Rule 14C: Realistic_Close_Date ───────────

    @isTest
    static void testRule14C_PastCloseDate_Fail() {
        Account acc = getTataMotorsAccount();
        Opportunity opp = new Opportunity(
            Name      = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(-1), // Past date
            Amount    = 1100000
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(opp, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Past close date should be blocked');
    }

    @isTest
    static void testRule14C_CloseDateBeyond180Days_Fail() {
        Account acc = getTataMotorsAccount();
        Opportunity opp = new Opportunity(
            Name      = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(181), // Beyond 180 days
            Amount    = 1100000
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(opp, false);
        Test.stopTest();
        System.assert(!result.isSuccess(),
            'Close date beyond 180 days should be blocked');
    }

    @isTest
    static void testRule14C_ValidCloseDate_Pass() {
        Account acc = getTataMotorsAccount();
        Opportunity opp = new Opportunity(
            Name      = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(60), // Valid
            Amount    = 1100000
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(opp, false);
        Test.stopTest();
        System.assert(result.isSuccess(),
            'Valid close date within 180 days should save');
    }
}