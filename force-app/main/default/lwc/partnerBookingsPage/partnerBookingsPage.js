import { LightningElement, wire, track } from 'lwc';
import getBookings from '@salesforce/apex/PartnerBookingController.getBookings';
import getCurrentUserRole from '@salesforce/apex/PartnerDashboardController.getCurrentUserRole';

export default class PartnerBookingsPage extends LightningElement {
    @track bookings = [];
    @track loading = true;
    @track activeFilter = 'all';
    @track selectedBooking = null;
    @track showApprovalModal = false;
    @track approvalBooking = null;
    @track userRole = '';

    get isManager() { return this.userRole === 'Manager'; }

    @wire(getCurrentUserRole)
    wiredRole({ data }) { if (data) this.userRole = data; }

    @wire(getBookings, { statusFilter: '$activeFilter' })
    wiredBookings({ data, error }) {
        this.loading = false;
        if (data) this.bookings = data;
        if (error) console.error(error);
    }

    handleFilter(event) {
        this.activeFilter = event.detail.filter;
        this.loading = true;
    }

    handleBookingSelect(event) { this.selectedBooking = event.detail.booking; }
    closePayments() { this.selectedBooking = null; }

    handleApproval(event) {
        this.approvalBooking = event.detail.booking;
        this.showApprovalModal = true;
    }

    closeApproval() { this.showApprovalModal = false; this.approvalBooking = null; }

    refreshBookings() {
        this.showApprovalModal = false;
        this.approvalBooking = null;
        this.loading = true;
        getBookings({ statusFilter: this.activeFilter })
            .then(data => { this.bookings = data; this.loading = false; })
            .catch(() => { this.loading = false; });
    }
}