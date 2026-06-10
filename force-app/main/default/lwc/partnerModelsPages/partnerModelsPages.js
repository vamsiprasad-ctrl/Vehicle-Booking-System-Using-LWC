import { LightningElement, wire, track } from 'lwc';
import getActiveModels from '@salesforce/apex/ModelController.getActiveModels';

export default class PartnerModelsPages extends LightningElement {
    @track models  = [];
    @track loading = true;
    get empty() { return !this.loading && this.models.length === 0; }

    @wire(getActiveModels)
    wiredModels({ data, error }) {
        this.loading = false;
        if (data) this.models = data;
        if (error) console.error(error);
    }
}