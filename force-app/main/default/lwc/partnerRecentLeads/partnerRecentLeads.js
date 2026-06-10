import { LightningElement, wire, track } from 'lwc';
import getRecentLeads from '@salesforce/apex/PartnerDashboardController.getRecentLeads';

const STATUS_CLASS = {
    'New':       'badge new',
    'Contacted': 'badge contacted',
    'Qualified': 'badge qualified',
    'Lost':      'badge lost'
};

export default class PartnerRecentLeads extends LightningElement {
    @track leads = [];
    @track loading = true;

    get empty() { return !this.loading && this.leads.length === 0; }

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        return window.location.origin + '/' + (match ? match[1] : 'tatadealers');
    }

    @wire(getRecentLeads)
    wiredLeads({ data, error }) {
        this.loading = false;
        if (data) {
            this.leads = data.map(l => ({
                ...l,
                statusClass: STATUS_CLASS[l.Status] || 'badge'
            }));
        }
        if (error) console.error(error);
    }

    goLeads() {
        window.location.href = `${this.siteBase}/leads`;
    }
}