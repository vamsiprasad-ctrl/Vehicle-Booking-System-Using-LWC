import { LightningElement, api } from 'lwc';

export default class PartnerPaymentsTable extends LightningElement {
    @api loading = false;

    _payments = [];
    @api
    get payments() { return this._payments; }
    set payments(val) {
        this._payments = (val || []).map(p => ({
            ...p,
            amountFormatted: new Intl.NumberFormat('en-IN').format(p.Payment_Amount__c || 0)
        }));
    }

    get empty() { return !this.loading && this._payments.length === 0; }
}