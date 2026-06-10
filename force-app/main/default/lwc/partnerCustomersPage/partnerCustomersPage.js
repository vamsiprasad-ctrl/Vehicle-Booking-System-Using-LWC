import { LightningElement, wire, track } from 'lwc';
import getCustomers from '@salesforce/apex/PartnerCustomerController.getCustomers';

export default class PartnerCustomersPage extends LightningElement {
    @track customers = [];
    @track loading = true;
    @track searchKey = '';
    @track selectedCustomerId = null;

    @wire(getCustomers, { searchKey: '$searchKey' })
    wiredCustomers({ data, error }) {
        this.loading = false;
        if (data) this.customers = data;
        if (error) console.error(error);
    }

    handleSearch(event) {
        this.searchKey = event.detail.searchKey;
        this.loading = true;
        this.selectedCustomerId = null;
    }

    handleCustomerSelect(event) {
        this.selectedCustomerId = event.detail.contactId;
    }

    closeProfile() { this.selectedCustomerId = null; }
}