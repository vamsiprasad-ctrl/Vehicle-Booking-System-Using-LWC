import { LightningElement, wire, track } from 'lwc';
import getAllPayments        from '@salesforce/apex/PartnerPaymentController.getAllPayments';
import getPaymentSummary    from '@salesforce/apex/PartnerPaymentController.getPaymentSummary';
import getOutstandingBookings from '@salesforce/apex/PartnerPaymentController.getOutstandingBookings';

const fmt = n => new Intl.NumberFormat('en-IN').format(n || 0);

export default class PartnerPaymentsPages extends LightningElement {
    @track payments     = [];
    @track outstanding  = [];
    @track summary      = {};
    @track loading      = true;
    @track loadingO     = true;
    @track methodFilter = 'all';

    get totalCollectedFmt() { return fmt(this.summary.totalCollected); }
    get thisMonthFmt()      { return fmt(this.summary.thisMonth); }
    get outstandingFmt()    { return fmt(this.summary.totalOutstanding); }
    get emptyP()            { return !this.loading    && this.payments.length === 0; }
    get emptyO()            { return !this.loadingO   && this.outstanding.length === 0; }

    @wire(getPaymentSummary)
    wiredSummary({ data }) { if (data) this.summary = data; }

    @wire(getAllPayments, { methodFilter: '$methodFilter' })
    wiredPayments({ data, error }) {
        this.loading = false;
        if (data) this.payments = data.map(p => ({
            ...p,
            amtFmt:        fmt(p.Payment_Amount__c),
            customerName:  p.Booking__r && p.Booking__r.Contact__r
                ? (p.Booking__r.Contact__r.FirstName || '') + ' ' + (p.Booking__r.Contact__r.LastName || '') : '—',
            modelName:     p.Booking__r && p.Booking__r.Model__r ? p.Booking__r.Model__r.Name : '—',
            bookingNumber: p.Booking__r ? p.Booking__r.Booking_Number__c : '—'
        }));
        if (error) console.error(error);
    }

    @wire(getOutstandingBookings)
    wiredOutstanding({ data, error }) {
        this.loadingO = false;
        if (data) this.outstanding = data.map(b => {
            const total = b.Total_Booking_Amount__c || 0;
            const paid  = b.Total_Paid__c || 0;
            return {
                ...b,
                customerName:  b.Contact__r ? (b.Contact__r.FirstName || '') + ' ' + (b.Contact__r.LastName || '') : '—',
                customerPhone: b.Contact__r ? b.Contact__r.Phone || '—' : '—',
                modelName:     b.Model__r   ? b.Model__r.Name   : '—',
                ownerName:     b.Owner      ? b.Owner.Name      : '—',
                totalFmt:  fmt(total),
                paidFmt:   fmt(paid),
                remainFmt: fmt(Math.max(0, total - paid))
            };
        });
        if (error) console.error(error);
    }

    handleMethod(e) { this.methodFilter = e.target.value; this.loading = true; }
}