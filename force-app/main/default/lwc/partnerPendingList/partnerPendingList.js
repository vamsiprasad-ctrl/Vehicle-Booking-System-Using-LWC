import { LightningElement, api, track } from 'lwc';
import approveBooking from '@salesforce/apex/PartnerBookingController.approveBooking';
import rejectBooking  from '@salesforce/apex/PartnerBookingController.rejectBooking';

const fmt = n => new Intl.NumberFormat('en-IN').format(n || 0);

export default class PartnerPendingList extends LightningElement {
    @api loading = false;
    @track reasons = {};

    _bookings = [];
    @api
    get bookings() { return this._bookings; }
    set bookings(val) {
        this._bookings = (val || []).map(b => ({
            ...b,
            amountFormatted: fmt(b.Total_Booking_Amount__c),
            successMsg: '',
            errorMsg: ''
        }));
    }

    get empty() { return !this.loading && this._bookings.length === 0; }

    handleReason(event) {
        const id = event.currentTarget.dataset.id;
        this.reasons[id] = event.target.value;
    }

    updateCard(id, patch) {
        this._bookings = this._bookings.map(b =>
            b.Id === id ? { ...b, ...patch } : b
        );
    }

    approveBooking(event) {
        const id = event.currentTarget.dataset.id;
        this.updateCard(id, { errorMsg: '', successMsg: '' });
        approveBooking({ bookingId: id })
            .then(() => {
                this.updateCard(id, { successMsg: 'Approved! Customer notified.' });
                setTimeout(() => this.dispatchEvent(new CustomEvent('refresh')), 2000);
            })
            .catch(err => {
                this.updateCard(id, { errorMsg: err.body ? err.body.message : 'Error' });
            });
    }

    rejectBooking(event) {
        const id = event.currentTarget.dataset.id;
        const reason = this.reasons[id] || '';
        if (!reason.trim()) {
            this.updateCard(id, { errorMsg: 'Please enter a rejection reason.' });
            return;
        }
        this.updateCard(id, { errorMsg: '', successMsg: '' });
        rejectBooking({ bookingId: id, reason })
            .then(() => {
                this.updateCard(id, { successMsg: 'Rejected. Customer notified.' });
                setTimeout(() => this.dispatchEvent(new CustomEvent('refresh')), 2000);
            })
            .catch(err => {
                this.updateCard(id, { errorMsg: err.body ? err.body.message : 'Error' });
            });
    }
}