import { LightningElement, wire, track } from 'lwc';
import getActiveModels
    from '@salesforce/apex/ModelController.getActiveModels';

export default class ModelCatalog extends LightningElement {
    @track models = [];
    @track isLoading = true;
    @track error = false;

    @wire(getActiveModels)
    wiredModels({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.models = data;
            this.error = false;
        } else if (error) {
            this.error = true;
            console.error('ModelCatalog error:', error);
        }
    }

    handleModelClick(event) {
        const modelId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('modelselect', {
            detail: { modelId },
            bubbles: true
        }));
    }
}