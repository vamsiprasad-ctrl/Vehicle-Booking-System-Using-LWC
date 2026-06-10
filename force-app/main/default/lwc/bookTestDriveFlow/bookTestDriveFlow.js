import { LightningElement, track } from 'lwc';

export default class BookTestDriveFlow extends LightningElement {
    @track showModelPage   = true;
    @track showVariantPage = false;
    @track showFormPage    = false;
    @track showSuccess     = false;

    @track selectedModelId    = '';
    @track selectedModelName  = '';
    @track selectedVariantId  = '';
    @track selectedVariantName = '';

    // Step 1 → Step 2
    handleModelSelected(event) {
        this.selectedModelId   = event.detail.modelId;
        this.selectedModelName = event.detail.modelName;
        this.showModelPage     = false;
        this.showVariantPage   = true;
    }

    // Step 2 → Step 3
    handleVariantSelected(event) {
        this.selectedVariantId   = event.detail.variantId;
        this.selectedVariantName = event.detail.variantName;
        this.showVariantPage     = false;
        this.showFormPage        = true;
    }

    // Step 3 → Back to Step 2
    handleBackToVariants() {
        this.showFormPage    = false;
        this.showVariantPage = true;
    }

    // Step 2 → Back to Step 1
    handleBackToModels() {
        this.showVariantPage = false;
        this.showModelPage   = true;
    }

    // Step 3 → Step 4
    handleFormSubmitted() {
        this.showFormPage = false;
        this.showSuccess  = true;
    }

    // Step 4 → Back to Step 1
    handleNewBooking() {
        this.selectedModelId    = '';
        this.selectedModelName  = '';
        this.selectedVariantId  = '';
        this.selectedVariantName = '';
        this.showSuccess  = false;
        this.showModelPage = true;
    }
}