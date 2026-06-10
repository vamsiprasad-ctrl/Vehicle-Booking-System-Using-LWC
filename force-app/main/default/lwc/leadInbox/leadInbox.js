import { LightningElement, wire, track } from 'lwc';
import getMyLeads
    from '@salesforce/apex/DashboardController.getMyLeads';

export default class LeadInbox extends LightningElement {
    @track leads   = [];
    @track noLeads = false;

    @wire(getMyLeads)
    wiredLeads({ error, data }) {
        if (data) {
            this.leads   = data;
            this.noLeads = data.length === 0;
        } else if (error) {
            console.error('leadInbox error:', error);
            this.noLeads = true;
        }
    }

    handleCall(event) {
        window.open('tel:' + event.currentTarget.dataset.phone);
    }

    handleEmail(event) {
        window.open('mailto:' + event.currentTarget.dataset.email);
    }
}