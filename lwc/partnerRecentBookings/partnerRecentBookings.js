import { LightningElement, wire, track } from 'lwc';
import getRecentBookings from '@salesforce/apex/PartnerDashboardController.getRecentBookings';

const STATUS_CLASS = {
    'Pending':        'badge pending',
    'Under Approval': 'badge pending',
    'Approved':       'badge approved',
    'Delivered':      'badge delivered',
    'Cancelled':      'badge cancelled'
};

export default class PartnerRecentBookings extends LightningElement {
    @track bookings = [];
    @track loading = true;

    get empty() { return !this.loading && this.bookings.length === 0; }

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        return window.location.origin + '/' + (match ? match[1] : 'tatadealers');
    }

    @wire(getRecentBookings)
    wiredBookings({ data, error }) {
        this.loading = false;
        if (data) {
            this.bookings = data.map(b => ({
                ...b,
                statusClass: STATUS_CLASS[b.Status__c] || 'badge',
                amountFormatted: new Intl.NumberFormat('en-IN').format(b.Total_Booking_Amount__c || 0)
            }));
        }
        if (error) console.error(error);
    }

    goBookings() {
        window.location.href = `${this.siteBase}/bookings`;
    }
}