import { LightningElement, api } from 'lwc';

export default class PartnerCustomersList extends LightningElement {
    @api loading = false;

    _customers = [];
    @api
    get customers() { return this._customers; }
    set customers(val) {
        this._customers = (val || []).map(c => ({
            ...c,
            initial: c.FirstName ? c.FirstName.charAt(0).toUpperCase() : 'C',
            accountName: c.Account ? c.Account.Name : '—',
            createdDate: c.CreatedDate
                ? new Date(c.CreatedDate).toLocaleDateString('en-IN') : '—'
        }));
    }

    get empty() { return !this.loading && this._customers.length === 0; }

    selectCustomer(event) {
        const contactId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('customerselect', { detail: { contactId } }));
    }
}