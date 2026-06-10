import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMyTestDrives from '@salesforce/apex/BookingController.getMyTestDrives';

const STATUS_CLASSES = {
    'Requested':  'status-badge requested',
    'Confirmed':  'status-badge confirmed',
    'Completed':  'status-badge completed',
    'Cancelled':  'status-badge cancelled'
};

export default class MyTestDrives extends LightningElement {
    @track allTestDrives = [];
    _wiredTDsResult;
    @track filteredTestDrives = [];
    @track loading = true;
    @track activeFilter = 'all';

    get siteBase() {
        const path = window.location.pathname;
        const match = path.match(/^\/([^\/]+)/);
        const prefix = match ? match[1] : 'tatasite';
        return window.location.origin + '/' + prefix;
    }

    navigate(page) { window.location.href = `${this.siteBase}/${page}`; }

    get isEmpty() { return !this.loading && this.filteredTestDrives.length === 0; }

    formatDateTime(dt) {
        if (!dt) return '—';
        try {
            return new Date(dt).toLocaleString('en-IN', {
                day: '2-digit', month: 'short', year: 'numeric',
                hour: '2-digit', minute: '2-digit', hour12: true
            });
        } catch (e) { return dt; }
    }

    @wire(getMyTestDrives)
    wiredTDs(result) {
        this._wiredTDsResult = result;
        this.loading = false;
        if (result.data) {
            const data = result.data;
            this.allTestDrives = data.map(td => ({
                ...td,
                statusClass:           STATUS_CLASSES[td.Status__c] || 'status-badge',
                modelName:             td.Model__r   ? td.Model__r.Name   : '—',
                variantName:           td.Variant__r ? td.Variant__r.Name : '—',
                preferredDateFormatted: this.formatDateTime(td.Preferred_Date_Time__c)
            }));
            this.applyFilter();
        }
        if (result.error) console.error('Test drives error:', result.error);
    }

    handleFilter(event) {
        this.activeFilter = event.target.value;
        this.applyFilter();
    }

    applyFilter() {
        this.filteredTestDrives = this.activeFilter === 'all'
            ? [...this.allTestDrives]
            : this.allTestDrives.filter(td => td.Status__c === this.activeFilter);
    }

    bookNew()     { this.navigate('models'); }
    goDashboard() { this.navigate('my-dashboard'); }
}