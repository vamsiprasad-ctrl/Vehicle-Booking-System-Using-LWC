import { LightningElement, wire, track } from 'lwc';
import getAllPayments      from '@salesforce/apex/PartnerPaymentController.getAllPayments';
import getPaymentSummary  from '@salesforce/apex/PartnerPaymentController.getPaymentSummary';
import getOutstandingBookings from '@salesforce/apex/PartnerPaymentController.getOutstandingBookings';

export default class PartnerPaymentsPage extends LightningElement {
    @track payments = [];
    @track summary  = {};
    @track outstanding = [];
    @track loading = true;
    @track loadingOutstanding = true;
    @track methodFilter = 'all';

    @wire(getPaymentSummary)
    wiredSummary({ data }) { if (data) this.summary = data; }

    @wire(getAllPayments, { methodFilter: '$methodFilter' })
    wiredPayments({ data, error }) {
        this.loading = false;
        if (data) this.payments = data;
        if (error) console.error(error);
    }

    @wire(getOutstandingBookings)
    wiredOutstanding({ data, error }) {
        this.loadingOutstanding = false;
        if (data) this.outstanding = data;
        if (error) console.error(error);
    }

    handleMethodFilter(event) {
        this.methodFilter = event.target.value;
        this.loading = true;
    }
}