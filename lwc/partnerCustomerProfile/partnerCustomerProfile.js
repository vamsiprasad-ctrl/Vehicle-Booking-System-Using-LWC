import { LightningElement, api, wire, track } from 'lwc';
import getCustomerProfile from '@salesforce/apex/PartnerCustomerController.getCustomerProfile';
import sendEmailToCustomer from '@salesforce/apex/PartnerCustomerController.sendEmailToCustomer';

const STATUS_CLASS = {
    'Pending':   'badge pending',
    'Approved':  'badge approved',
    'Delivered': 'badge delivered',
    'Cancelled': 'badge cancelled'
};

export default class PartnerCustomerProfile extends LightningElement {
    @api contactId;
    @track profile = null;
    @track loading = true;
    @track emailSubject = '';
    @track emailBody = '';
    @track emailSuccess = false;

    get initial() {
        return this.profile && this.profile.contact && this.profile.contact.FirstName
            ? this.profile.contact.FirstName.charAt(0).toUpperCase() : 'C';
    }
    get bookingCount() { return this.profile ? this.profile.bookings.length : 0; }
    get tdCount()      { return this.profile ? this.profile.testDrives.length : 0; }
    get paymentCount() { return this.profile ? this.profile.payments.length : 0; }

    @wire(getCustomerProfile, { contactId: '$contactId' })
    wiredProfile({ data, error }) {
        this.loading = false;
        if (data) {
            this.profile = {
                ...data,
                bookings: (data.bookings || []).map(b => ({
                    ...b,
                    statusClass: STATUS_CLASS[b.Status__c] || 'badge'
                }))
            };
        }
        if (error) console.error(error);
    }

    handleSubject(e) { this.emailSubject = e.target.value; }
    handleBody(e)    { this.emailBody    = e.target.value; }

    sendEmail() {
        if (!this.emailSubject || !this.emailBody) return;
        sendEmailToCustomer({
            contactId: this.contactId,
            subject: this.emailSubject,
            body: this.emailBody
        })
        .then(() => {
            this.emailSuccess = true;
            this.emailSubject = '';
            this.emailBody = '';
            setTimeout(() => { this.emailSuccess = false; }, 3000);
        })
        .catch(err => console.error(err));
    }

    handleClose() { this.dispatchEvent(new CustomEvent('close')); }
}