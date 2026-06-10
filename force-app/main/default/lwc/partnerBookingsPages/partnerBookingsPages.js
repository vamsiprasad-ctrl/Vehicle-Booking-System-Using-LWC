import { LightningElement, wire, track } from 'lwc';
import getBookings          from '@salesforce/apex/PartnerBookingController.getBookings';
import getPaymentsByBooking from '@salesforce/apex/PartnerBookingController.getPaymentsByBooking';
import approveBooking       from '@salesforce/apex/PartnerBookingController.approveBooking';
import rejectBooking        from '@salesforce/apex/PartnerBookingController.rejectBooking';
import getCurrentUserRole   from '@salesforce/apex/PartnerDashboardController.getCurrentUserRole';

const SC  = {
    'Pending':   'badge amber',
    'Approved':  'badge green',
    'Delivered': 'badge teal',
    'Cancelled': 'badge red'
};
const fmt = n => new Intl.NumberFormat('en-IN').format(n || 0);

function enrichBooking(b) {
    const total = b.Total_Booking_Amount__c || 0;
    const paid  = b.Total_Paid__c || 0;
    const rem   = Math.max(0, total - paid);
    const p     = total > 0 ? Math.min(100, Math.round((paid/total)*100)) : 0;
    return {
        ...b,
        initial:       (b.Contact__r ? b.Contact__r.FirstName || 'C' : 'C').charAt(0).toUpperCase(),
        customerName:  b.Contact__r ? (b.Contact__r.FirstName||'') + ' ' + (b.Contact__r.LastName||'') : '—',
        customerPhone: b.Contact__r ? b.Contact__r.Phone  || '—' : '—',
        customerEmail: b.Contact__r ? b.Contact__r.Email  || '—' : '—',
        modelName:     b.Model__r   ? b.Model__r.Name     : '—',
        variantName:   b.Variant__r ? b.Variant__r.Name   : '—',
        ownerName:     b.Owner      ? b.Owner.Name        : '—',
        sc:            SC[b.Status__c] || 'badge',
        totalFmt:      fmt(total),
        paidFmt:       fmt(paid),
        remainFmt:     fmt(rem),
        pct:           p,
        progStyle:     `width:${p}%`,
        isPending:     b.Status__c === 'Pending'
    };
}

export default class PartnerBookingsPages extends LightningElement {
    @track bookings          = [];
    @track loading           = true;
    @track activeFilter      = 'all';
    @track selectedBooking   = null;
    @track approvalBooking   = null;
    @track payments          = [];
    @track loadingPayments   = false;
    @track showPaymentPanel  = false;
    @track showApprovalPanel = false;
    @track rejectionReason   = '';
    @track approvalSuccess   = '';
    @track approvalError     = '';
    @track processing        = false;
    @track userRole          = '';

    get isManager()  { return this.userRole === 'Manager'; }
    get empty()      { return !this.loading && this.bookings.length === 0; }
    get noPayments() { return !this.loadingPayments && this.payments.length === 0; }

    btn(f) { return this.activeFilter === f ? 'fb active' : 'fb'; }
    get allClass() { return this.btn('all'); }
    get penClass() { return this.btn('Pending'); }
    get appClass() { return this.btn('Approved'); }
    get delClass() { return this.btn('Delivered'); }
    get canClass() { return this.btn('Cancelled'); }

    @wire(getCurrentUserRole)
    wiredRole({ data }) { if (data) this.userRole = data; }

    connectedCallback() { this.loadBookings(); }

    loadBookings() {
        this.loading = true;
        getBookings({ statusFilter: this.activeFilter })
            .then(data => {
                this.bookings = data.map(enrichBooking);
                this.loading  = false;
            })
            .catch(() => { this.loading = false; });
    }

    filter(e) {
        this.activeFilter = e.currentTarget.dataset.f;
        this.closePanel();
        this.loadBookings();
    }

    viewPayments(e) {
        const id = e.currentTarget.dataset.id;
        this.selectedBooking   = this.bookings.find(b => b.Id === id);
        this.showPaymentPanel  = true;
        this.showApprovalPanel = false;
        this.loadingPayments   = true;
        getPaymentsByBooking({ bookingId: id })
            .then(data => {
                this.payments = data.map(p => ({
                    ...p,
                    amtFmt: fmt(p.Payment_Amount__c)
                }));
                this.loadingPayments = false;
            })
            .catch(() => { this.loadingPayments = false; });
    }

    openApproval(e) {
        const id = e.currentTarget.dataset.id;
        this.approvalBooking   = this.bookings.find(b => b.Id === id);
        this.showApprovalPanel = true;
        this.showPaymentPanel  = false;
        this.approvalSuccess   = '';
        this.approvalError     = '';
    }

    closePanel() {
        this.showPaymentPanel  = false;
        this.showApprovalPanel = false;
        this.selectedBooking   = null;
        this.approvalBooking   = null;
    }

    handleReason(e) { this.rejectionReason = e.target.value; }

    approveBooking() {
        this.processing    = true;
        this.approvalError = '';
        approveBooking({ bookingId: this.approvalBooking.Id })
            .then(() => {
                this.approvalSuccess = '✅ Booking approved!';
                this.processing      = false;
                this.loadBookings();
            })
            .catch(err => {
                this.approvalError = err.body ? err.body.message : 'Error';
                this.processing    = false;
            });
    }

    rejectBooking() {
        if (!this.rejectionReason.trim()) {
            this.approvalError = 'Please enter a rejection reason.';
            return;
        }
        this.processing    = true;
        this.approvalError = '';
        rejectBooking({
            bookingId: this.approvalBooking.Id,
            reason:    this.rejectionReason
        })
            .then(() => {
                this.approvalSuccess = '❌ Booking rejected.';
                this.processing      = false;
                this.loadBookings();
            })
            .catch(err => {
                this.approvalError = err.body ? err.body.message : 'Error';
                this.processing    = false;
            });
    }
}