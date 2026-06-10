import { LightningElement, api, wire, track } from 'lwc';
import getPaymentsByBooking from '@salesforce/apex/PartnerBookingController.getPaymentsByBooking';

const fmt = n => new Intl.NumberFormat('en-IN').format(n || 0);

export default class PartnerBookingPayments extends LightningElement {
    @api booking = {};
    @track payments = [];
    @track loadingPayments = true;

    get totalFormatted()     { return fmt(this.booking.Total_Booking_Amount__c); }
    get paidFormatted()      { return fmt(this.booking.Total_Paid__c); }
    get remainingFormatted() {
        const rem = Math.max(0, (this.booking.Total_Booking_Amount__c || 0) - (this.booking.Total_Paid__c || 0));
        return fmt(rem);
    }
    get paymentPercent() {
        const total = this.booking.Total_Booking_Amount__c || 0;
        const paid  = this.booking.Total_Paid__c || 0;
        return total > 0 ? Math.min(100, Math.round((paid / total) * 100)) : 0;
    }
    get progressStyle() { return `width: ${this.paymentPercent}%`; }
    get noPayments()    { return !this.loadingPayments && this.payments.length === 0; }

    @wire(getPaymentsByBooking, { bookingId: '$booking.Id' })
    wiredPayments({ data, error }) {
        this.loadingPayments = false;
        if (data) {
            this.payments = data.map(p => ({
                ...p,
                amountFormatted: fmt(p.Payment_Amount__c)
            }));
        }
        if (error) console.error(error);
    }

    handleClose() { this.dispatchEvent(new CustomEvent('close')); }
}