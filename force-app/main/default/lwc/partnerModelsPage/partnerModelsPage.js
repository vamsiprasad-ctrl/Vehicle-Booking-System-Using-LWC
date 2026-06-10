import { LightningElement, wire, track } from 'lwc';
import getActiveModels from '@salesforce/apex/ModelController.getActiveModels';

export default class PartnerModelsPage extends LightningElement {
    @track models = [];
    @track loading = true;

    @wire(getActiveModels)
    wiredModels({ data, error }) {
        this.loading = false;
        if (data) this.models = data;
        if (error) console.error(error);
    }
}