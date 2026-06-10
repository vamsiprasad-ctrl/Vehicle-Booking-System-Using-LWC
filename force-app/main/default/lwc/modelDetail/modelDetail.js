import { LightningElement, api, wire, track } from 'lwc';
import getModelById
    from '@salesforce/apex/ModelController.getModelById';
import getVariantsByModel
    from '@salesforce/apex/ModelController.getVariantsByModel';

export default class ModelDetail extends LightningElement {
    @api modelId;
    @track model;
    @track variants = [];
    @track error;

    @wire(getModelById, { modelId: '$modelId' })
    wiredModel({ error, data }) {
        if (data) {
            this.model = data;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getVariantsByModel, { modelId: '$modelId' })
    wiredVariants({ error, data }) {
        if (data) {
            this.variants = data;
        } else if (error) {
            this.error = error;
        }
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back', {
            bubbles: true
        }));
    }

    handleTestDrive(event) {
        const variantId = event.currentTarget.dataset.variantid;
        const modelId   = event.currentTarget.dataset.modelid;
        this.dispatchEvent(new CustomEvent('testdrive', {
            detail: { variantId, modelId },
            bubbles: true
        }));
    }
}