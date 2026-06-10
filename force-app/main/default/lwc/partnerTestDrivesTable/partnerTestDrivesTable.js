import { LightningElement, api } from 'lwc';

const STATUS_CLASS = {
    'Requested': 'badge requested',
    'Confirmed': 'badge confirmed',
    'Completed': 'badge completed',
    'Cancelled': 'badge cancelled'
};

export default class PartnerTestDrivesTable extends LightningElement {
    @api loading = false;

    _testDrives = [];
    @api
    get testDrives() { return this._testDrives; }
    set testDrives(val) {
        this._testDrives = (val || []).map(td => ({
            ...td,
            statusClass: STATUS_CLASS[td.Status__c] || 'badge',
            dateFormatted: td.Preferred_Date_Time__c
                ? new Date(td.Preferred_Date_Time__c).toLocaleString('en-IN', {
                    day: '2-digit', month: 'short', year: 'numeric',
                    hour: '2-digit', minute: '2-digit', hour12: true
                })
                : '—'
        }));
    }

    get empty() { return !this.loading && this._testDrives.length === 0; }

    handleAction(event) {
        const id = event.currentTarget.dataset.id;
        const testDrive = this._testDrives.find(td => td.Id === id);
        this.dispatchEvent(new CustomEvent('actionrequest', { detail: { testDrive } }));
    }
}