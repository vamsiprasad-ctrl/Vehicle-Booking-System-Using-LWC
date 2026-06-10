import { LightningElement, wire, track } from 'lwc';
import getLeads from '@salesforce/apex/LeadManagementController.getLeads';

export default class PartnerLeadsPage extends LightningElement {
    @track leads = [];
    @track loading = true;
    @track activeFilter = 'all';
    @track selectedLead = null;

    @wire(getLeads, { statusFilter: '$activeFilter' })
    wiredLeads({ data, error }) {
        this.loading = false;
        if (data) this.leads = data;
        if (error) console.error(error);
    }

    handleFilter(event) {
        this.activeFilter = event.detail.filter;
        this.loading = true;
        this.selectedLead = null;
    }

    handleLeadSelect(event) {
        this.selectedLead = event.detail.lead;
    }

    closeDetail() { this.selectedLead = null; }

    refreshLeads() {
        this.loading = true;
        this.selectedLead = null;
        getLeads({ statusFilter: this.activeFilter })
            .then(data => { this.leads = data; this.loading = false; })
            .catch(() => { this.loading = false; });
    }
}