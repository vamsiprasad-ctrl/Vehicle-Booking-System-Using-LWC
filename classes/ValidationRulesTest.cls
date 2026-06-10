@isTest
public class ValidationRulesTest {

    static Account getTataMotorsAccount() {
        Account acc = new Account(Name = 'Tata Motors');
        insert acc;
        return acc;
    }

    static Model__c createModel() {
        Model__c m = new Model__c(Name = 'Nexon', Is_Active__c = true);
        insert m;
        return m;
    }

    static Variant__c createVariant(Id modelId) {
        Variant__c v = new Variant__c(
            Name = 'XZ+', Model__c = modelId,
            Price__c = 1100000, Fuel_Type__c = 'Petrol'
        );
        insert v;
        return v;
    }

    static Contact createContact(Id accountId) {
        Contact c = new Contact(
            FirstName = 'Ravi', LastName = 'Kumar',
            Email = 'ravi.kumar@gmail.com', Phone = '9876543210',
            AccountId = accountId
        );
        insert c;
        return c;
    }

    static Opportunity createOpportunity(Id accountId, Id contactId) {
        Opportunity opp = new Opportunity(
            Name = 'Ravi Kumar - Nexon', AccountId = accountId,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(60), Amount = 1100000
        );
        insert opp;
        return opp;
    }

    static Booking__c createApprovedBooking(
        Id contactId, Id oppId, Id modelId, Id variantId
    ) {
        Booking__c b = new Booking__c(
            Contact__c = contactId, Opportunity__c = oppId,
            Model__c = modelId, Variant__c = variantId,
            Total_Booking_Amount__c = 1100000, Status__c = 'Approved',
            Booking_Date__c = Date.today(),
            Expected_Delivery_Date__c = Date.today().addDays(30)
        );
        insert b;
        return b;
    }

    static Lead createValidLead() {
        Model__c m = createModel();
        Variant__c v = createVariant(m.Id);
        Lead l = new Lead(
            FirstName = 'Ravi', LastName = 'Kumar',
            Email = 'ravi@gmail.com', Phone = '9876543210',
            LeadSource = 'Web', Preferred_Variant__c = v.Id,
            Company = 'Individual'
        );
        insert l;
        return l;
    }

    static Booking__c setupApprovedBooking() {
        Account acc = getTataMotorsAccount();
        Model__c m = createModel();
        Variant__c v = createVariant(m.Id);
        Contact con = createContact(acc.Id);
        Opportunity opp = createOpportunity(acc.Id, con.Id);
        return createApprovedBooking(con.Id, opp.Id, m.Id, v.Id);
    }

    // ── Lead Rules ────────────────────────────────

    @isTest static void testRule1_ValidEmail_Pass() {
        Lead l = new Lead(FirstName='Ravi', LastName='Kumar',
            Email='ravi@gmail.com', Phone='9876543210',
            LeadSource='Phone', Company='Individual');
        System.assert(Database.insert(l, false).isSuccess(), 'Valid email should save');
    }

    @isTest static void testRule1_BlankEmail_Fail() {
        Lead l = new Lead(FirstName='Ravi', LastName='Kumar',
            Email=null, Phone='9876543210',
            LeadSource='Phone', Company='Individual');
        System.assert(!Database.insert(l, false).isSuccess(), 'Null email should be blocked');
    }

    @isTest static void testRule1_InvalidEmailFormat_Fail() {
        Lead l = new Lead(FirstName='Ravi', LastName='Kumar',
            Email='ravi@', Phone='9876543210',
            LeadSource='Phone', Company='Individual');
        System.assert(!Database.insert(l, false).isSuccess(), 'Malformed email should be blocked');
    }

    @isTest static void testRule1_ConsecutiveDots_Fail() {
        Lead l = new Lead(FirstName='Ravi', LastName='Kumar',
            Email='ravi..kumar@gmail.com', Phone='9876543210',
            LeadSource='Phone', Company='Individual');
        System.assert(!Database.insert(l, false).isSuccess(), 'Consecutive dots should be blocked');
    }

    @isTest static void testRule2_ValidPhone_Pass() {
        Lead l = new Lead(FirstName='Ravi', LastName='Kumar',
            Email='ravi@gmail.com', Phone='9876543210',
            LeadSource='Phone', Company='Individual');
        System.assert(Database.insert(l, false).isSuccess(), 'Valid phone should pass');
    }

    @isTest static void testRule2_BlankPhone_Fail() {
        Lead l = new Lead(FirstName='Ravi', LastName='Kumar',
            Email='ravi@gmail.com', Phone='',
            LeadSource='Phone', Company='Individual');
        System.assert(!Database.insert(l, false).isSuccess(), 'Blank phone should be blocked');
    }

    @isTest static void testRule2_PhoneStartingWithZero_Fail() {
        Lead l = new Lead(FirstName='Ravi', LastName='Kumar',
            Email='ravi@gmail.com', Phone='0876543210',
            LeadSource='Phone', Company='Individual');
        System.assert(!Database.insert(l, false).isSuccess(), 'Phone starting with 0 should be blocked');
    }

    @isTest static void testRule2_NineDigitPhone_Fail() {
        Lead l = new Lead(FirstName='Ravi', LastName='Kumar',
            Email='ravi@gmail.com', Phone='987654321',
            LeadSource='Phone', Company='Individual');
        System.assert(!Database.insert(l, false).isSuccess(), '9-digit phone should be blocked');
    }

    @isTest static void testRule3_WebLeadWithVariant_Pass() {
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Lead l = new Lead(FirstName='Ravi', LastName='Kumar',
            Email='ravi@gmail.com', Phone='9876543210',
            LeadSource='Web', Preferred_Variant__c=v.Id, Company='Individual');
        System.assert(Database.insert(l, false).isSuccess(), 'Web lead with variant should save');
    }

    @isTest static void testRule3_WebLeadWithoutVariant_Fail() {
        Lead l = new Lead(FirstName='Ravi', LastName='Kumar',
            Email='ravi@gmail.com', Phone='9876543210',
            LeadSource='Web', Company='Individual');
        Database.SaveResult r = Database.insert(l, false);
        System.assert(!r.isSuccess(), 'Web lead without variant should be blocked');
        System.assert(r.getErrors()[0].getMessage().contains('Variant'), 'Error should mention Variant');
    }

    @isTest static void testRule4_ValidNames_Pass() {
        Lead l = new Lead(FirstName='Ravi', LastName='Kumar',
            Email='ravi@gmail.com', Phone='9876543210',
            LeadSource='Phone', Company='Individual');
        System.assert(Database.insert(l, false).isSuccess(), 'Valid names should save');
    }

    @isTest static void testRule4_SingleCharFirstName_Fail() {
        Lead l = new Lead(FirstName='R', LastName='Kumar',
            Email='ravi@gmail.com', Phone='9876543210',
            LeadSource='Phone', Company='Individual');
        System.assert(!Database.insert(l, false).isSuccess(), 'Single char name should be blocked');
    }

    @isTest static void testRule4_WhitespaceOnlyName_Fail() {
        Lead l = new Lead(FirstName='   ', LastName='Kumar',
            Email='ravi@gmail.com', Phone='9876543210',
            LeadSource='Phone', Company='Individual');
        System.assert(!Database.insert(l, false).isSuccess(), 'Whitespace name should be blocked');
    }

    // ── Test Drive Rules ──────────────────────────

    @isTest static void testRule5_FutureWeekdayDate_Pass() {
        Lead lead = createValidLead();
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Test_Drive__c td = new Test_Drive__c(
            Lead__c=lead.Id, Model__c=m.Id, Variant__c=v.Id,
            Preferred_Date_Time__c=DateTime.newInstance(
                Date.today().addDays(3), Time.newInstance(10,0,0,0)),
            Status__c='Requested');
        System.assert(Database.insert(td, false).isSuccess(), 'Future weekday should pass');
    }

    @isTest static void testRule5_PastDate_Fail() {
        Lead lead = createValidLead();
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Test_Drive__c td = new Test_Drive__c(
            Lead__c=lead.Id, Model__c=m.Id, Variant__c=v.Id,
            Preferred_Date_Time__c=DateTime.newInstance(
                Date.today().addDays(-1), Time.newInstance(10,0,0,0)),
            Status__c='Requested');
        System.assert(!Database.insert(td, false).isSuccess(), 'Past date should be blocked');
    }

    @isTest static void testRule5_Beyond30Days_Fail() {
        Lead lead = createValidLead();
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Test_Drive__c td = new Test_Drive__c(
            Lead__c=lead.Id, Model__c=m.Id, Variant__c=v.Id,
            Preferred_Date_Time__c=DateTime.newInstance(
                Date.today().addDays(31), Time.newInstance(10,0,0,0)),
            Status__c='Requested');
        System.assert(!Database.insert(td, false).isSuccess(), 'Beyond 30 days should be blocked');
    }

    @isTest static void testRule5_OutsideBusinessHours_Fail() {
        Lead lead = createValidLead();
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Test_Drive__c td = new Test_Drive__c(
            Lead__c=lead.Id, Model__c=m.Id, Variant__c=v.Id,
            Preferred_Date_Time__c=DateTime.newInstance(
                Date.today().addDays(3), Time.newInstance(0,0,0,0)),
            Status__c='Requested');
        System.assert(!Database.insert(td, false).isSuccess(), 'Midnight should be blocked');
    }

    @isTest static void testRule6_CompletedWithNotes_Pass() {
        Lead lead = createValidLead();
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Test_Drive__c td = new Test_Drive__c(
            Lead__c=lead.Id, Model__c=m.Id, Variant__c=v.Id,
            Preferred_Date_Time__c=DateTime.newInstance(
                Date.today().addDays(3), Time.newInstance(10,0,0,0)),
            Status__c='Confirmed');
        insert td;
        td.Status__c='Completed'; td.Notes__c='Customer liked XZ+.';
        System.assert(Database.update(td, false).isSuccess(), 'Completed with notes should save');
    }

    @isTest static void testRule6_CompletedWithoutNotes_Fail() {
        Lead lead = createValidLead();
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Test_Drive__c td = new Test_Drive__c(
            Lead__c=lead.Id, Model__c=m.Id, Variant__c=v.Id,
            Preferred_Date_Time__c=DateTime.newInstance(
                Date.today().addDays(3), Time.newInstance(10,0,0,0)),
            Status__c='Confirmed');
        insert td;
        td.Status__c='Completed';
        System.assert(!Database.update(td, false).isSuccess(), 'Completed without notes should be blocked');
    }

    @isTest static void testRule6B_CompletedToCancelled_Fail() {
        Lead lead = createValidLead();
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Test_Drive__c td = new Test_Drive__c(
            Lead__c=lead.Id, Model__c=m.Id, Variant__c=v.Id,
            Preferred_Date_Time__c=DateTime.newInstance(
                Date.today().addDays(3), Time.newInstance(10,0,0,0)),
            Status__c='Confirmed', Notes__c='Test notes');
        insert td;
        td.Status__c='Completed'; update td;
        td.Status__c='Cancelled';
        System.assert(!Database.update(td, false).isSuccess(), 'Completed to Cancelled should be blocked');
    }

    // ── Variant Rules ─────────────────────────────

    @isTest static void testRule7_ValidPrice_Pass() {
        Model__c m = createModel();
        Variant__c v = new Variant__c(Name='XM', Model__c=m.Id,
            Price__c=850000, Fuel_Type__c='Petrol');
        System.assert(Database.insert(v, false).isSuccess(), 'Valid price should save');
    }

    @isTest static void testRule7_ZeroPrice_Fail() {
        Model__c m = createModel();
        Variant__c v = new Variant__c(Name='XM', Model__c=m.Id,
            Price__c=0, Fuel_Type__c='Petrol');
        System.assert(!Database.insert(v, false).isSuccess(), 'Zero price should be blocked');
    }

    @isTest static void testRule7_PriceAboveCap_Fail() {
        Model__c m = createModel();
        Variant__c v = new Variant__c(Name='XM', Model__c=m.Id,
            Price__c=9999999, Fuel_Type__c='Petrol');
        System.assert(!Database.insert(v, false).isSuccess(), 'Price above cap should be blocked');
    }

    // ── Booking Rules ─────────────────────────────

    @isTest static void testRule8_ValidAmount_Pass() {
        Account acc = getTataMotorsAccount();
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Contact con = createContact(acc.Id);
        Opportunity opp = createOpportunity(acc.Id, con.Id);
        Booking__c b = new Booking__c(
            Contact__c=con.Id, Opportunity__c=opp.Id,
            Model__c=m.Id, Variant__c=v.Id,
            Total_Booking_Amount__c=1100000, Status__c='Pending',
            Booking_Date__c=Date.today(),
            Expected_Delivery_Date__c=Date.today().addDays(30));
        System.assert(Database.insert(b, false).isSuccess(), 'Valid amount should save');
    }

    @isTest static void testRule8_AmountBelowMinimum_Fail() {
        Account acc = getTataMotorsAccount();
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Contact con = createContact(acc.Id);
        Opportunity opp = createOpportunity(acc.Id, con.Id);
        Booking__c b = new Booking__c(
            Contact__c=con.Id, Opportunity__c=opp.Id,
            Model__c=m.Id, Variant__c=v.Id,
            Total_Booking_Amount__c=50000, Status__c='Pending',
            Booking_Date__c=Date.today(),
            Expected_Delivery_Date__c=Date.today().addDays(30));
        System.assert(!Database.insert(b, false).isSuccess(), 'Below minimum should be blocked');
    }

    @isTest static void testRule9_DeliveryBeforeBooking_Fail() {
        Account acc = getTataMotorsAccount();
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Contact con = createContact(acc.Id);
        Opportunity opp = createOpportunity(acc.Id, con.Id);
        Booking__c b = new Booking__c(
            Contact__c=con.Id, Opportunity__c=opp.Id,
            Model__c=m.Id, Variant__c=v.Id,
            Total_Booking_Amount__c=1100000, Status__c='Pending',
            Booking_Date__c=Date.today(),
            Expected_Delivery_Date__c=Date.today().addDays(-1));
        System.assert(!Database.insert(b, false).isSuccess(), 'Delivery before booking should be blocked');
    }

    @isTest static void testRule10_RollbackApprovedToPending_Fail() {
        Account acc = getTataMotorsAccount();
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Contact con = createContact(acc.Id);
        Opportunity opp = createOpportunity(acc.Id, con.Id);
        Booking__c b = createApprovedBooking(con.Id, opp.Id, m.Id, v.Id);
        b.Status__c = 'Pending';
        System.assert(!Database.update(b, false).isSuccess(), 'Rollback to Pending should be blocked');
    }

    // ── Payment Rules ─────────────────────────────

    @isTest static void testRule11_ValidPayment_Pass() {
        Booking__c b = setupApprovedBooking();
        Payment__c p = new Payment__c(Booking__c=b.Id,
            Payment_Amount__c=500000, Payment_Date__c=Date.today(),
            Payment_Method__c='UPI', Status__c='Pending');
        System.assert(Database.insert(p, false).isSuccess(), 'Valid payment should save');
    }

    @isTest static void testRule11_ZeroPayment_Fail() {
        Booking__c b = setupApprovedBooking();
        Payment__c p = new Payment__c(Booking__c=b.Id,
            Payment_Amount__c=0, Payment_Date__c=Date.today(),
            Payment_Method__c='UPI', Status__c='Pending');
        System.assert(!Database.insert(p, false).isSuccess(), 'Zero payment should be blocked');
    }

    @isTest static void testRule13_PaymentOnPendingBooking_Fail() {
        Account acc = getTataMotorsAccount();
        Model__c m = createModel(); Variant__c v = createVariant(m.Id);
        Contact con = createContact(acc.Id);
        Opportunity opp = createOpportunity(acc.Id, con.Id);
        Booking__c b = new Booking__c(
            Contact__c=con.Id, Opportunity__c=opp.Id,
            Model__c=m.Id, Variant__c=v.Id,
            Total_Booking_Amount__c=1100000, Status__c='Pending',
            Booking_Date__c=Date.today(),
            Expected_Delivery_Date__c=Date.today().addDays(30));
        insert b;
        Payment__c p = new Payment__c(Booking__c=b.Id,
            Payment_Amount__c=500000, Payment_Date__c=Date.today(),
            Payment_Method__c='UPI', Status__c='Pending');
        Database.SaveResult r = Database.insert(p, false);
        System.assert(!r.isSuccess(), 'Payment on Pending booking should be blocked');
        System.assert(r.getErrors()[0].getMessage().contains('Approved'), 'Error must mention Approved');
    }

    @isTest static void testRule13B_NewPaymentAsCompleted_Fail() {
        Booking__c b = setupApprovedBooking();
        Payment__c p = new Payment__c(Booking__c=b.Id,
            Payment_Amount__c=500000, Payment_Date__c=Date.today(),
            Payment_Method__c='UPI', Status__c='Completed');
        Database.SaveResult r = Database.insert(p, false);
        System.assert(!r.isSuccess(), 'New Completed payment should be blocked');
        System.assert(r.getErrors()[0].getMessage().contains('Pending'), 'Error must mention Pending');
    }

    // ── Opportunity Rules ─────────────────────────

    @isTest static void testRule14_QuotationWithAmount_Pass() {
        Account acc = getTataMotorsAccount();
        Opportunity opp = createOpportunity(acc.Id, createContact(acc.Id).Id);
        opp.StageName='Quotation Sent'; opp.Amount=1100000;
        System.assert(Database.update(opp, false).isSuccess(), 'Quotation with amount should save');
    }

    @isTest static void testRule14_QuotationWithBlankAmount_Fail() {
        Account acc = getTataMotorsAccount();
        Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acc.Id,
            StageName='Qualification', CloseDate=Date.today().addDays(60));
        insert opp;
        opp.StageName='Quotation Sent';
        System.assert(!Database.update(opp, false).isSuccess(), 'Quotation without amount should be blocked');
    }

    @isTest static void testRule14B_SkipToNegotiation_Fail() {
        Account acc = getTataMotorsAccount();
        Opportunity opp = createOpportunity(acc.Id, createContact(acc.Id).Id);
        opp.StageName='Negotiation';
        System.assert(!Database.update(opp, false).isSuccess(), 'Skip to Negotiation should be blocked');
    }

    @isTest static void testRule14B_ProperSequence_Pass() {
        Account acc = getTataMotorsAccount();
        Opportunity opp = createOpportunity(acc.Id, createContact(acc.Id).Id);
        opp.StageName='Quotation Sent'; opp.Amount=1100000; update opp;
        opp.StageName='Negotiation';
        System.assert(Database.update(opp, false).isSuccess(), 'Proper sequence should pass');
    }

    @isTest static void testRule14C_PastCloseDate_Fail() {
        Account acc = getTataMotorsAccount();
        Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acc.Id,
            StageName='Qualification', CloseDate=Date.today().addDays(-1), Amount=1100000);
        System.assert(!Database.insert(opp, false).isSuccess(), 'Past close date should be blocked');
    }

    @isTest static void testRule14C_ValidCloseDate_Pass() {
        Account acc = getTataMotorsAccount();
        Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acc.Id,
            StageName='Qualification', CloseDate=Date.today().addDays(60), Amount=1100000);
        System.assert(Database.insert(opp, false).isSuccess(), 'Valid close date should save');
    }
}