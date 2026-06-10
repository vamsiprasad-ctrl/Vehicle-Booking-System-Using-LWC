import { LightningElement, api } from 'lwc';

const fmt = n => new Intl.NumberFormat('en-IN').format(n || 0);

export default class PartnerOutstandingList extends LightningElement {
    @api loading = false;

    _bookings = [];
    @api
    get bookings() { return this._bookings; }
    set bookings(val) {
        this._bookings = (val || []).map(b => {
            const total = b.Total_Booking_Amount__c || 0;
            const paid  = b.Total_Paid__c || 0;
            return {
                ...b,
                totalFmt:     fmt(total),
                paidFmt:      fmt(paid),
                remainingFmt: fmt(Math.max(0, total - paid))
            };
        });
    }

    get empty() { return !this.loading && this._bookings.length === 0; }
}