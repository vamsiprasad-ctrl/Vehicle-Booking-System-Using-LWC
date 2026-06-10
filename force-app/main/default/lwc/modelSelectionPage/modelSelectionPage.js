import { LightningElement, wire, track } from 'lwc';
import getActiveModels
    from '@salesforce/apex/ModelController.getActiveModels';

export default class ModelSelectionPage extends LightningElement {
    @track models    = [];
    @track isLoading = true;

    @wire(getActiveModels)
    wiredModels({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.models = data;
        } else if (error) {
            console.error('modelSelectionPage error:', error);
        }
    }

    handleModelClick(event) {
        const modelId   = event.currentTarget.dataset.id;
        const modelName = event.currentTarget.dataset.name;
        this.dispatchEvent(new CustomEvent('modelselected', {
            detail: { modelId, modelName },
            bubbles: true
        }));
    }

    handleImageError(event) {
        event.target.style.display = 'none';
        event.target.parentElement
            .querySelector('.model-image-placeholder')
            .style.display = 'flex';
    }
}