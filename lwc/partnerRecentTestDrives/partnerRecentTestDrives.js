import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getRecentTestDrives from '@salesforce/apex/PartnerDashboardController.getRecentTestDrives';

const STATUS_CLASS = {
    'Requested': 'badge requested',
    'Confirmed': 'badge confirmed',
    'Completed': 'badge completed',
    'Cancelled': 'badge cancelled'
};

export default class PartnerRecentTestDrives extends LightningElement {
    @track testDrives = [];
    _wiredTDsResult;
    @track loading = true;

    get empty() { return !this.loading && this.testDrives.length === 0; }

    get siteBase() {
        const m = window.location.pathname.match(/^\/([^\/]+)/);
        return window.location.origin + '/' + (m ? m[1] : 'tatadealers');
    }

    @wire(getRecentTestDrives)
    wiredTDs(result) {
        this._wiredTDsResult = result;
        this.loading = false;
        if (result.data) {
            const data = result.data;
            this.testDrives = data.map(td => ({
                ...td,
                customerName: td.Lead__r
                    ? (td.Lead__r.FirstName || '') + ' ' + (td.Lead__r.LastName || '')
                    : '—',
                modelName: td.Model__r ? td.Model__r.Name : '—',
                city: td.City__c || '—',
                statusClass: STATUS_CLASS[td.Status__c] || 'badge'
            }));
        }
        if (result.error) console.error(result.error);
    }

    goTestDrives() {
        window.location.href = `${this.siteBase}/test-drives`;
    }
}