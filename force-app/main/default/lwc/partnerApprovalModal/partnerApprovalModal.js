import { LightningElement, api, track } from 'lwc';
import approveBooking from '@salesforce/apex/PartnerBookingController.approveBooking';
import rejectBooking from '@salesforce/apex/PartnerBookingController.rejectBooking';

export default class PartnerApprovalModal extends LightningElement {
    @api booking = {};
    @track rejectionReason = '';
    @track successMsg = '';
    @track errorMsg = '';
    @track processing = false;

    get amountFormatted() {
        return new Intl.NumberFormat('en-IN').format(this.booking.Total_Booking_Amount__c || 0);
    }

    handleReason(e) { this.rejectionReason = e.target.value; }
    handleClose()   { this.dispatchEvent(new CustomEvent('close')); }

    approveBooking() {
        this.processing = true;
        this.errorMsg = '';
        approveBooking({ bookingId: this.booking.Id })
            .then(() => {
                this.successMsg = 'Booking approved! Customer has been notified.';
                setTimeout(() => this.dispatchEvent(new CustomEvent('refresh')), 1500);
            })
            .catch(err => {
                this.errorMsg = err.body ? err.body.message : 'Error approving booking';
                this.processing = false;
            });
    }

    rejectBooking() {
        if (!this.rejectionReason.trim()) {
            this.errorMsg = 'Please enter a rejection reason.';
            return;
        }
        this.processing = true;
        this.errorMsg = '';
        rejectBooking({ bookingId: this.booking.Id, reason: this.rejectionReason })
            .then(() => {
                this.successMsg = 'Booking rejected. Customer has been notified.';
                setTimeout(() => this.dispatchEvent(new CustomEvent('refresh')), 1500);
            })
            .catch(err => {
                this.errorMsg = err.body ? err.body.message : 'Error rejecting booking';
                this.processing = false;
            });
    }
}