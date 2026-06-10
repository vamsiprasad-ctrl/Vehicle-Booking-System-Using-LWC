import { LightningElement, wire, track } from 'lwc';
import getPendingApprovals from '@salesforce/apex/PartnerBookingController.getPendingApprovals';

export default class PartnerApprovalsPage extends LightningElement {
    @track bookings = [];
    @track loading = true;

    get pendingCount() { return this.bookings.length; }

    @wire(getPendingApprovals)
    wiredBookings({ data, error }) {
        this.loading = false;
        if (data) this.bookings = data;
        if (error) console.error(error);
    }

    refreshData() {
        this.loading = true;
        getPendingApprovals()
            .then(data => { this.bookings = data; this.loading = false; })
            .catch(() => { this.loading = false; });
    }
}