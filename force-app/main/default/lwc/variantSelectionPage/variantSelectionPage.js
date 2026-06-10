import { LightningElement, api, wire, track } from 'lwc';
import getVariantsByModel
    from '@salesforce/apex/ModelController.getVariantsByModel';

export default class VariantSelectionPage extends LightningElement {
    @api modelId;
    @api modelName;
    @track variants  = [];
    @track isLoading = true;

    @wire(getVariantsByModel, { modelId: '$modelId' })
    wiredVariants({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.variants = data;
        } else if (error) {
            console.error('variantSelectionPage error:', error);
        }
    }

    handleVariantClick(event) {
        const variantId   = event.currentTarget.dataset.id;
        const variantName = event.currentTarget.dataset.name;
        this.dispatchEvent(new CustomEvent('variantselected', {
            detail: { variantId, variantName },
            bubbles: true
        }));
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back', {
            bubbles: true
        }));
    }
}