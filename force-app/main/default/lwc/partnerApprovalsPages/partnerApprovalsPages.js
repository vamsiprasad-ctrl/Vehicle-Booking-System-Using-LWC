import { LightningElement, wire, track } from 'lwc';
import getPendingApprovals from '@salesforce/apex/PartnerBookingController.getPendingApprovals';
import approveBooking      from '@salesforce/apex/PartnerBookingController.approveBooking';
import rejectBooking       from '@salesforce/apex/PartnerBookingController.rejectBooking';
import getCurrentUserRole  from '@salesforce/apex/PartnerDashboardController.getCurrentUserRole';

const fmt = n => new Intl.NumberFormat('en-IN').format(n || 0);

export default class PartnerApprovalsPages extends LightningElement {
    @track bookings = [];
    @track loading  = true;
    @track userRole = '';
    reasons = {};

    get isManager()  { return this.userRole === 'Manager'; }
    get empty()      { return !this.loading && this.bookings.length === 0; }
    get hasPending() { return this.bookings.length > 0; }

    get siteBase() {
        const m = window.location.pathname.match(/^\/([^\/]+)/);
        return window.location.origin + '/' + (m ? m[1] : 'partnerportal');
    }

    goDashboard() {
        window.location.href = `${this.siteBase}/dashboard`;
    }

    @wire(getCurrentUserRole)
    wiredRole({ data }) { if (data) this.userRole = data; }

    connectedCallback() { this.loadApprovals(); }

    loadApprovals() {
        this.loading = true;
        getPendingApprovals()
            .then(data => {
                this.bookings = data.map(b => ({
                    ...b,
                    initial:       (b.Contact__r ? b.Contact__r.FirstName || 'C' : 'C').charAt(0).toUpperCase(),
                    customerName:  b.Contact__r ? (b.Contact__r.FirstName||'') + ' ' + (b.Contact__r.LastName||'') : '—',
                    customerPhone: b.Contact__r ? b.Contact__r.Phone  || '—' : '—',
                    customerEmail: b.Contact__r ? b.Contact__r.Email  || '—' : '—',
                    modelName:     b.Model__r   ? b.Model__r.Name     : '—',
                    variantName:   b.Variant__r ? b.Variant__r.Name   : '—',
                    ownerName:     b.Owner      ? b.Owner.Name        : '—',
                    totalFmt:      fmt(b.Total_Booking_Amount__c),
                    successMsg:    '',
                    errorMsg:      ''
                }));
                this.loading = false;
            })
            .catch(() => { this.loading = false; });
    }

    handleReason(e) {
        this.reasons[e.currentTarget.dataset.id] = e.target.value;
    }

    updateCard(id, patch) {
        this.bookings = this.bookings.map(b =>
            b.Id === id ? { ...b, ...patch } : b
        );
    }

    approveBooking(e) {
        const id = e.currentTarget.dataset.id;
        this.updateCard(id, { successMsg: '', errorMsg: '' });
        approveBooking({ bookingId: id })
            .then(() => {
                this.updateCard(id, {
                    successMsg: '✅ Approved! Emails sent.'
                });
                setTimeout(() => this.loadApprovals(), 2000);
            })
            .catch(err => {
                this.updateCard(id, {
                    errorMsg: err.body ? err.body.message : 'Error'
                });
            });
    }

    rejectBooking(e) {
        const id     = e.currentTarget.dataset.id;
        const reason = this.reasons[id] || '';
        if (!reason.trim()) {
            this.updateCard(id, {
                errorMsg: 'Please enter a rejection reason.'
            });
            return;
        }
        this.updateCard(id, { successMsg: '', errorMsg: '' });
        rejectBooking({ bookingId: id, reason })
            .then(() => {
                this.updateCard(id, {
                    successMsg: '❌ Rejected. Emails sent.'
                });
                setTimeout(() => this.loadApprovals(), 2000);
            })
            .catch(err => {
                this.updateCard(id, {
                    errorMsg: err.body ? err.body.message : 'Error'
                });
            });
    }
}