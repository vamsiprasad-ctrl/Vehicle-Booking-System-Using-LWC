import { LightningElement, wire, track } from 'lwc';
import getCustomers        from '@salesforce/apex/PartnerCustomerController.getCustomers';
import getCustomerProfile  from '@salesforce/apex/PartnerCustomerController.getCustomerProfile';
import sendEmailToCustomer from '@salesforce/apex/PartnerCustomerController.sendEmailToCustomer';

const SB = { 'Pending':'badge amber','Approved':'badge green','Delivered':'badge teal','Cancelled':'badge red' };

export default class PartnerCustomersPages extends LightningElement {
    @track customers        = [];
    @track loading          = true;
    @track searchKey        = '';
    @track selectedContactId= null;
    @track profile          = null;
    @track loadingProfile   = false;
    @track emailSubject     = '';
    @track emailBody        = '';
    @track emailSuccess     = false;
    @track emailError       = '';

    get empty()          { return !this.loading && this.customers.length === 0; }
    get noBookings()     { return this.profile && (!this.profile.bookings || this.profile.bookings.length === 0); }
    get profileInitial() {
        return this.profile && this.profile.contact && this.profile.contact.FirstName
            ? this.profile.contact.FirstName.charAt(0).toUpperCase() : 'C';
    }

    @wire(getCustomers, { searchKey: '$searchKey' })
    wiredCustomers({ data, error }) {
        this.loading = false;
        if (data) this.customers = data.map(c => ({
            ...c,
            initial:     (c.FirstName || 'C').charAt(0).toUpperCase(),
            createdDate: c.CreatedDate ? new Date(c.CreatedDate).toLocaleDateString('en-IN') : '—'
        }));
        if (error) console.error(error);
    }

    handleInput(e) { this.searchKey = e.target.value; }
    doSearch()     { this.loading = true; }
    clearSearch()  { this.searchKey = ''; this.loading = true; }

    selectCustomer(e) {
        this.selectedContactId = e.currentTarget.dataset.id;
        this.loadingProfile    = true;
        this.profile           = null;
        this.emailSuccess      = false;
        this.emailError        = '';
        getCustomerProfile({ contactId: this.selectedContactId })
            .then(data => {
                this.profile = {
                    ...data,
                    bookings: (data.bookings || []).map(b => ({
                        ...b,
                        sc: SB[b.Status__c] || 'badge',
                        modelName: b.Model__r ? b.Model__r.Name : '—'
                    }))
                };
                this.loadingProfile = false;
            })
            .catch(() => { this.loadingProfile = false; });
    }

    closeProfile()   { this.selectedContactId = null; this.profile = null; }
    handleSubject(e) { this.emailSubject = e.target.value; }
    handleBody(e)    { this.emailBody    = e.target.value; }

    sendEmail() {
        if (!this.emailSubject || !this.emailBody) return;
        sendEmailToCustomer({ contactId: this.selectedContactId, subject: this.emailSubject, body: this.emailBody })
            .then(() => {
                this.emailSuccess  = true;
                this.emailSubject  = '';
                this.emailBody     = '';
                setTimeout(() => { this.emailSuccess = false; }, 3000);
            })
            .catch(err => { this.emailError = err.body ? err.body.message : 'Error'; });
    }
}