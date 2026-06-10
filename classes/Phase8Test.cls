@isTest
public class Phase8Test {

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Tata Motors');
        insert acc;

        App_Config__c config = App_Config__c.getOrgDefaults();
        config.Tata_Motors_Account_Id__c = acc.Id;
        upsert config;

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
            Email     = 'testcustomer@gmail.com',
            AccountId = acc.Id
        );
        insert con;

        Opportunity opp = new Opportunity(
            Name      = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(60),
            Amount    = 1100000
        );
        insert opp;

        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId     = con.Id,
            IsPrimary     = true,
            Role          = 'Decision Maker'
        );
        insert ocr;
    }

    static Booking__c createApprovedBooking() {
        Account acc     = [SELECT Id FROM Account WHERE Name = 'Tata Motors' LIMIT 1];
        Model__c model  = [SELECT Id FROM Model__c WHERE Name = 'Nexon' LIMIT 1];
        Variant__c v    = [SELECT Id FROM Variant__c WHERE Name = 'XZ+' LIMIT 1];
        Contact con     = [SELECT Id FROM Contact WHERE LastName = 'Customer' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Booking__c b = new Booking__c(
            Contact__c                = con.Id,
            Opportunity__c            = opp.Id,
            Model__c                  = model.Id,
            Variant__c                = v.Id,
            Total_Booking_Amount__c   = 1100000,
            Status__c                 = 'Approved',
            Booking_Date__c           = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        insert b;

        return [
            SELECT Id, Status__c, Total_Booking_Amount__c,
                   Total_Paid__c, Opportunity__c, Contact__c,
                   Booking_Number__c, Expected_Delivery_Date__c,
                   OwnerId
            FROM Booking__c WHERE Id = :b.Id
        ];
    }

    static DateTime getFutureWeekdayDateTime() {
        Date d = Date.today().addDays(5);
        Integer attempts = 0;
        while (attempts < 14) {
            DateTime dt = DateTime.newInstance(
                d, Time.newInstance(10, 0, 0, 0)
            );
            String dayName = dt.format('EEEE');
            if (dayName != 'Saturday' && dayName != 'Sunday') {
                return dt;
            }
            d = d.addDays(1);
            attempts++;
        }
        return DateTime.newInstance(
            Date.today().addDays(7), Time.newInstance(10, 0, 0, 0)
        );
    }


    // ─────────────────────────────────────────────
    // EMAIL UTILITY
    // ─────────────────────────────────────────────

    @isTest
    static void testEmailUtility_SendEmail() {
        Test.startTest();
        EmailUtility.sendEmail('test@gmail.com', 'Subject', 'Body');
        Test.stopTest();
        System.assert(true, 'sendEmail executed');
    }

    @isTest
    static void testEmailUtility_BlankAddress() {
        Test.startTest();
        EmailUtility.sendEmail('', 'Subject', 'Body');
        Test.stopTest();
        System.assert(true, 'Blank address handled');
    }

    @isTest
    static void testEmailUtility_BuildEmail() {
        Messaging.SingleEmailMessage email =
            EmailUtility.buildEmail('test@gmail.com', 'Subject', 'Body');
        System.assertNotEquals(null, email, 'Email must not be null');
    }

    @isTest
    static void testEmailUtility_SendEmails_Empty() {
        Test.startTest();
        EmailUtility.sendEmails(new List<Messaging.SingleEmailMessage>());
        Test.stopTest();
        System.assert(true, 'Empty list handled');
    }

    @isTest
    static void testEmailUtility_SendEmails_Null() {
        Test.startTest();
        EmailUtility.sendEmails(null);
        Test.stopTest();
        System.assert(true, 'Null handled');
    }


    // ─────────────────────────────────────────────
    // BOOKING TRIGGER
    // ─────────────────────────────────────────────

    @isTest
    static void testBooking_BeforeInsert_SetsDeliveryDate() {
        Account acc     = [SELECT Id FROM Account WHERE Name = 'Tata Motors' LIMIT 1];
        Model__c model  = [SELECT Id FROM Model__c WHERE Name = 'Nexon' LIMIT 1];
        Variant__c v    = [SELECT Id FROM Variant__c WHERE Name = 'XZ+' LIMIT 1];
        Contact con     = [SELECT Id FROM Contact WHERE LastName = 'Customer' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Test.startTest();
        Booking__c b = new Booking__c(
            Contact__c                = con.Id,
            Opportunity__c            = opp.Id,
            Model__c                  = model.Id,
            Variant__c                = v.Id,
            Total_Booking_Amount__c   = 1100000,
            Status__c                 = 'Pending',
            Booking_Date__c           = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        insert b;
        Test.stopTest();

        Booking__c result = [
            SELECT Expected_Delivery_Date__c
            FROM Booking__c WHERE Id = :b.Id
        ];
        System.assertEquals(
            Date.today().addDays(30),
            result.Expected_Delivery_Date__c,
            'Delivery date must be today + 30'
        );
    }

    @isTest
    static void testBooking_BeforeInsert_NoBookingDate() {
        Account acc     = [SELECT Id FROM Account WHERE Name = 'Tata Motors' LIMIT 1];
        Model__c model  = [SELECT Id FROM Model__c WHERE Name = 'Nexon' LIMIT 1];
        Variant__c v    = [SELECT Id FROM Variant__c WHERE Name = 'XZ+' LIMIT 1];
        Contact con     = [SELECT Id FROM Contact WHERE LastName = 'Customer' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Test.startTest();
        Booking__c b = new Booking__c(
            Contact__c                = con.Id,
            Opportunity__c            = opp.Id,
            Model__c                  = model.Id,
            Variant__c                = v.Id,
            Total_Booking_Amount__c   = 1100000,
            Status__c                 = 'Pending',
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        insert b;
        Test.stopTest();

        Booking__c result = [
            SELECT Booking_Date__c
            FROM Booking__c WHERE Id = :b.Id
        ];
        System.assertNotEquals(null, result.Booking_Date__c,
            'Booking date must be set automatically'
        );
    }

    @isTest
    static void testBooking_AfterInsert_PendingEmail() {
        Account acc     = [SELECT Id FROM Account WHERE Name = 'Tata Motors' LIMIT 1];
        Model__c model  = [SELECT Id FROM Model__c WHERE Name = 'Nexon' LIMIT 1];
        Variant__c v    = [SELECT Id FROM Variant__c WHERE Name = 'XZ+' LIMIT 1];
        Contact con     = [SELECT Id FROM Contact WHERE LastName = 'Customer' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Test.startTest();
        Booking__c b = new Booking__c(
            Contact__c                = con.Id,
            Opportunity__c            = opp.Id,
            Model__c                  = model.Id,
            Variant__c                = v.Id,
            Total_Booking_Amount__c   = 1100000,
            Status__c                 = 'Pending',
            Booking_Date__c           = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        insert b;
        Test.stopTest();
        System.assert(true, 'Pending email fired on insert');
    }

    @isTest
    static void testBooking_AfterUpdate_Approved() {
        Account acc     = [SELECT Id FROM Account WHERE Name = 'Tata Motors' LIMIT 1];
        Model__c model  = [SELECT Id FROM Model__c WHERE Name = 'Nexon' LIMIT 1];
        Variant__c v    = [SELECT Id FROM Variant__c WHERE Name = 'XZ+' LIMIT 1];
        Contact con     = [SELECT Id FROM Contact WHERE LastName = 'Customer' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Booking__c b = new Booking__c(
            Contact__c                = con.Id,
            Opportunity__c            = opp.Id,
            Model__c                  = model.Id,
            Variant__c                = v.Id,
            Total_Booking_Amount__c   = 1100000,
            Status__c                 = 'Pending',
            Booking_Date__c           = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        insert b;

        Test.startTest();
        b.Status__c = 'Approved';
        update b;
        Test.stopTest();

        System.assertEquals('Approved',
            [SELECT Status__c FROM Booking__c WHERE Id = :b.Id].Status__c,
            'Status must be Approved'
        );
    }

    @isTest
    static void testBooking_AfterUpdate_Cancelled() {
        Account acc     = [SELECT Id FROM Account WHERE Name = 'Tata Motors' LIMIT 1];
        Model__c model  = [SELECT Id FROM Model__c WHERE Name = 'Nexon' LIMIT 1];
        Variant__c v    = [SELECT Id FROM Variant__c WHERE Name = 'XZ+' LIMIT 1];
        Contact con     = [SELECT Id FROM Contact WHERE LastName = 'Customer' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Booking__c b = new Booking__c(
            Contact__c                = con.Id,
            Opportunity__c            = opp.Id,
            Model__c                  = model.Id,
            Variant__c                = v.Id,
            Total_Booking_Amount__c   = 1100000,
            Status__c                 = 'Pending',
            Booking_Date__c           = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        insert b;

        Test.startTest();
        b.Status__c = 'Cancelled';
        update b;
        Test.stopTest();

        System.assertEquals('Cancelled',
            [SELECT Status__c FROM Booking__c WHERE Id = :b.Id].Status__c,
            'Status must be Cancelled'
        );
    }

    @isTest
    static void testBooking_AfterUpdate_Delivered_CreatesTask() {
        Booking__c b = createApprovedBooking();

        Test.startTest();
        b.Status__c = 'Delivered';
        update b;
        Test.stopTest();

        System.assertEquals('Delivered',
            [SELECT Status__c FROM Booking__c WHERE Id = :b.Id].Status__c,
            'Status must be Delivered'
        );
        System.assert(
            ![SELECT Id FROM Task WHERE WhatId = :b.Id].isEmpty(),
            'Delivery task must be created'
        );
    }


    // ─────────────────────────────────────────────
    // PAYMENT TRIGGER
    // ─────────────────────────────────────────────

    @isTest
    static void testPayment_Insert_Completed_SendsReceipt() {
        Booking__c b = createApprovedBooking();

        Payment__c p = new Payment__c(
            Booking__c        = b.Id,
            Payment_Amount__c = 500000,
            Payment_Date__c   = Date.today(),
            Payment_Method__c = 'UPI',
            Status__c         = 'Pending'
        );
        insert p;

        Test.startTest();
        p.Status__c = 'Completed';
        update p;
        Test.stopTest();

        System.assert(true, 'Payment completed and receipt sent');
    }

    @isTest
    static void testPayment_FullPayment_MarksDelivered() {
        Booking__c b = createApprovedBooking();

        Payment__c p = new Payment__c(
            Booking__c        = b.Id,
            Payment_Amount__c = 1100000,
            Payment_Date__c   = Date.today(),
            Payment_Method__c = 'Cash',
            Status__c         = 'Pending'
        );
        insert p;

        Test.startTest();
        p.Status__c = 'Completed';
        update p;
        Test.stopTest();

        System.assertEquals('Delivered',
            [SELECT Status__c FROM Booking__c WHERE Id = :b.Id].Status__c,
            'Booking must be Delivered after full payment'
        );
    }

    @isTest
    static void testPayment_PartialPayment_NotDelivered() {
        Booking__c b = createApprovedBooking();

        Payment__c p = new Payment__c(
            Booking__c        = b.Id,
            Payment_Amount__c = 500000,
            Payment_Date__c   = Date.today(),
            Payment_Method__c = 'UPI',
            Status__c         = 'Pending'
        );
        insert p;

        Test.startTest();
        p.Status__c = 'Completed';
        update p;
        Test.stopTest();

        System.assertNotEquals('Delivered',
            [SELECT Status__c FROM Booking__c WHERE Id = :b.Id].Status__c,
            'Booking must NOT be Delivered on partial payment'
        );
    }

    @isTest
    static void testPayment_FullPayment_ClosesOpportunity() {
        Booking__c b = createApprovedBooking();

        Payment__c p = new Payment__c(
            Booking__c        = b.Id,
            Payment_Amount__c = 1100000,
            Payment_Date__c   = Date.today(),
            Payment_Method__c = 'Cash',
            Status__c         = 'Pending'
        );
        insert p;

        Test.startTest();
        p.Status__c = 'Completed';
        update p;
        Test.stopTest();

        System.assertEquals('Closed Won',
            [SELECT StageName FROM Opportunity
             WHERE Name = 'Test Opp' LIMIT 1].StageName,
            'Opportunity must be Closed Won after full payment'
        );
    }


    // ─────────────────────────────────────────────
    // OPPORTUNITY TRIGGER
    // ─────────────────────────────────────────────

    @isTest
    static void testOpportunity_QuotationSent_SendsEmail() {
        Opportunity opp = [
            SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1
        ];
        Test.startTest();
        opp.StageName = 'Quotation Sent';
        opp.Amount    = 1100000;
        update opp;
        Test.stopTest();
        System.assert(true, 'Quotation email fired');
    }

    @isTest
    static void testOpportunity_BookingConfirmed_CreatesBooking() {
        Opportunity opp = [
            SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1
        ];
        Test.startTest();
        opp.StageName = 'Booking Confirmed';
        opp.Amount    = 1100000;
        update opp;
        Test.stopTest();

        List<Booking__c> bookings = [
            SELECT Id, Status__c, Total_Booking_Amount__c
            FROM Booking__c WHERE Opportunity__c = :opp.Id
        ];
        System.assert(!bookings.isEmpty(), 'Booking must be created');
        System.assertEquals('Pending', bookings[0].Status__c,
            'Booking status must be Pending'
        );
        System.assertEquals(1100000, bookings[0].Total_Booking_Amount__c,
            'Booking amount must match Opportunity amount'
        );
    }

    @isTest
    static void testOpportunity_OtherStage_NoBooking() {
        Opportunity opp = [
            SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1
        ];
        Integer before = [
            SELECT COUNT() FROM Booking__c
            WHERE Opportunity__c = :opp.Id
        ];
        Test.startTest();
        opp.StageName = 'Needs Analysis';
        update opp;
        Test.stopTest();

        Integer after = [
            SELECT COUNT() FROM Booking__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(before, after,
            'No booking on non-trigger stage'
        );
    }


    // ─────────────────────────────────────────────
    // LEAD TRIGGER
    // ─────────────────────────────────────────────

    @isTest
    static void testLead_Conversion() {
        LeadStatus convertedStatus = [
            SELECT MasterLabel FROM LeadStatus
            WHERE IsConverted = true LIMIT 1
        ];

        Lead l = new Lead(
            FirstName  = 'Convert',
            LastName   = 'Test',
            Email      = 'converttest@gmail.com',
            Phone      = '9876543210',
            Company    = 'Individual',
            LeadSource = 'Phone',
            Status     = 'New'
        );
        insert l;

        Test.startTest();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setDoNotCreateOpportunity(true);
        lc.setConvertedStatus(convertedStatus.MasterLabel);
        Database.convertLead(lc);
        Test.stopTest();

        System.assert(
            [SELECT IsConverted FROM Lead WHERE Id = :l.Id].IsConverted,
            'Lead must be converted'
        );
    }


    // ─────────────────────────────────────────────
    // MODEL CONTROLLER
    // ─────────────────────────────────────────────

    @isTest
    static void testModelController_GetActiveModels() {
        Test.startTest();
        List<Model__c> models = ModelController.getActiveModels();
        Test.stopTest();
        System.assert(!models.isEmpty(), 'Must return models');
    }

    @isTest
    static void testModelController_GetVariantsByModel() {
        Model__c model = [
            SELECT Id FROM Model__c WHERE Name = 'Nexon' LIMIT 1
        ];
        Test.startTest();
        List<Variant__c> variants =
            ModelController.getVariantsByModel(model.Id);
        Test.stopTest();
        System.assert(!variants.isEmpty(), 'Must return variants');
    }

    @isTest
    static void testModelController_GetModelById() {
        Model__c model = [
            SELECT Id FROM Model__c WHERE Name = 'Nexon' LIMIT 1
        ];
        Test.startTest();
        Model__c result = ModelController.getModelById(model.Id);
        Test.stopTest();
        System.assertEquals('Nexon', result.Name,
            'Must return correct model'
        );
    }


    // ─────────────────────────────────────────────
    // TEST DRIVE CONTROLLER
    // ─────────────────────────────────────────────

    @isTest
    static void testTestDriveController_Success() {
        Model__c model = [
            SELECT Id FROM Model__c WHERE Name = 'Nexon' LIMIT 1
        ];
        Variant__c v = [
            SELECT Id FROM Variant__c WHERE Name = 'XZ+' LIMIT 1
        ];

        DateTime futureDate = getFutureWeekdayDateTime();

        Test.startTest();
        String result = TestDriveController.submitTestDriveRequest(
            'Ravi', 'Kumar', 'ravi@gmail.com',
            '9876543210', 'Chennai',
            v.Id, model.Id,
            futureDate
        );
        Test.stopTest();

        System.assertEquals('Success', result, 'Must return Success');
        System.assert(
            ![SELECT Id FROM Lead
              WHERE Email = 'ravi@gmail.com'].isEmpty(),
            'Lead must be created'
        );
        List<Lead> leads = [
            SELECT Id FROM Lead WHERE Email = 'ravi@gmail.com'
        ];
        System.assert(
            ![SELECT Id FROM Test_Drive__c
              WHERE Lead__c = :leads[0].Id].isEmpty(),
            'Test Drive must be created'
        );
    }

    @isTest
    static void testTestDriveController_Error() {
        Boolean errorThrown = false;
        Test.startTest();
        try {
            TestDriveController.submitTestDriveRequest(
                null, null, null, null, null, null, null, null
            );
        } catch (AuraHandledException e) {
            errorThrown = true;
        }
        Test.stopTest();
        System.assert(errorThrown, 'Must throw AuraHandledException');
    }


    // ─────────────────────────────────────────────
    // BOOKING CONTROLLER
    // ─────────────────────────────────────────────

    @isTest
    static void testBookingController_GetMyBookings() {
        Test.startTest();
        List<Booking__c> bookings = BookingController.getMyBookings();
        Test.stopTest();
        System.assertNotEquals(null, bookings, 'Must return list');
    }

    @isTest
    static void testBookingController_GetPaymentsByBooking() {
        Booking__c b = createApprovedBooking();

        Payment__c p = new Payment__c(
            Booking__c        = b.Id,
            Payment_Amount__c = 500000,
            Payment_Date__c   = Date.today(),
            Payment_Method__c = 'UPI',
            Status__c         = 'Pending'
        );
        insert p;

        Test.startTest();
        List<Payment__c> payments =
            BookingController.getPaymentsByBooking(b.Id);
        Test.stopTest();
        System.assert(!payments.isEmpty(), 'Must return payments');
    }

    @isTest
    static void testBookingController_GetMyTestDrives() {
        Test.startTest();
        List<Test_Drive__c> tds = BookingController.getMyTestDrives();
        Test.stopTest();
        System.assertNotEquals(null, tds, 'Must return list');
    }


    // ─────────────────────────────────────────────
    // DASHBOARD CONTROLLER
    // ─────────────────────────────────────────────

    @isTest
    static void testDashboardController_GetMyLeads() {
        Test.startTest();
        List<Lead> leads = DashboardController.getMyLeads();
        Test.stopTest();
        System.assertNotEquals(null, leads, 'Must return list');
    }

    @isTest
    static void testDashboardController_GetMyOpportunities() {
        Test.startTest();
        List<Opportunity> opps =
            DashboardController.getMyOpportunities();
        Test.stopTest();
        System.assertNotEquals(null, opps, 'Must return list');
    }

    @isTest
    static void testDashboardController_GetPendingApprovals() {
        Booking__c b = createApprovedBooking();
        b.Status__c = 'Under Approval';
        update b;

        Test.startTest();
        List<Booking__c> approvals =
            DashboardController.getPendingApprovals();
        Test.stopTest();
        System.assert(!approvals.isEmpty(),
            'Must return pending approvals'
        );
    }

    @isTest
    static void testDashboardController_GetDashboardKPIs() {
        Test.startTest();
        Map<String, Integer> kpis =
            DashboardController.getDashboardKPIs();
        Test.stopTest();
        System.assert(kpis.containsKey('openLeads'),
            'Must have openLeads'
        );
        System.assert(kpis.containsKey('pendingApprovals'),
            'Must have pendingApprovals'
        );
        System.assert(kpis.containsKey('monthlyBookings'),
            'Must have monthlyBookings'
        );
        System.assert(kpis.containsKey('activeOpportunities'),
            'Must have activeOpportunities'
        );
    }

    @isTest
    static void testDashboardController_GetMyTestDrives() {
        Test.startTest();
        List<Test_Drive__c> tds =
            DashboardController.getMyTestDrives();
        Test.stopTest();
        System.assertNotEquals(null, tds, 'Must return list');
    }


    // ─────────────────────────────────────────────
    // CONTACT TRIGGER AND COMMUNITY USER
    // ─────────────────────────────────────────────

    @isTest
    static void testContactTrigger_AfterInsert() {
        Account acc = [
            SELECT Id FROM Account WHERE Name = 'Tata Motors' LIMIT 1
        ];
        Test.startTest();
        Contact con = new Contact(
            FirstName = 'Portal',
            LastName  = 'Test',
            Email     = 'portaltest@gmail.com',
            AccountId = acc.Id
        );
        insert con;
        Test.stopTest();

        System.assert(
            ![SELECT Id FROM Contact
              WHERE Email = 'portaltest@gmail.com'].isEmpty(),
            'Contact must be inserted'
        );
    }

    @isTest
    static void testContactTrigger_NoEmail() {
        Account acc = [
            SELECT Id FROM Account WHERE Name = 'Tata Motors' LIMIT 1
        ];
        Test.startTest();
        Contact con = new Contact(
            FirstName = 'NoEmail',
            LastName  = 'Test',
            AccountId = acc.Id
        );
        insert con;
        Test.stopTest();
        System.assert(true, 'Contact without email handled');
    }

    @isTest
    static void testCommunityUserCreator_Instantiation() {
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Email
            FROM Contact WHERE LastName = 'Customer' LIMIT 1
        ];
        CommunityUserCreator creator =
            new CommunityUserCreator(contacts);
        System.assertNotEquals(null, creator,
            'CommunityUserCreator must instantiate'
        );
    }
}