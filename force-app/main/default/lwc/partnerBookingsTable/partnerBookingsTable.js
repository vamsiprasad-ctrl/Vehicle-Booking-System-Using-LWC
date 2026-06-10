import { LightningElement, api } from 'lwc';

const fmt = n => new Intl.NumberFormat('en-IN').format(n || 0);
const STATUS_CLASS = {
    'Pending':   'badge pending',
    'Approved':  'badge approved',
    'Delivered': 'badge delivered',
    'Cancelled': 'badge cancelled'
};

export default class PartnerBookingsTable extends LightningElement {
    @api loading = false;
    @api isManager = false;

    _bookings = [];
    @api
    get bookings() { return this._bookings; }
    set bookings(val) {
        this._bookings = (val || []).map(b => ({
            ...b,
            statusClass: STATUS_CLASS[b.Status__c] || 'badge',
            totalFormatted: fmt(b.Total_Booking_Amount__c),
            paidFormatted:  fmt(b.Total_Paid__c),
            isPending: b.Status__c === 'Pending'
        }));
    }

    get empty() { return !this.loading && this._bookings.length === 0; }

    viewPayments(event) {
        const id = event.currentTarget.dataset.id;
        const booking = this._bookings.find(b => b.Id === id);
        this.dispatchEvent(new CustomEvent('bookingselect', { detail: { booking } }));
    }

    requestApproval(event) {
        const id = event.currentTarget.dataset.id;
        const booking = this._bookings.find(b => b.Id === id);
        this.dispatchEvent(new CustomEvent('approvalrequest', { detail: { booking } }));
    }
}