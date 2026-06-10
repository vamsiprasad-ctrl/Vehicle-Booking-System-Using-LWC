import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getActiveModelsWithVariants from '@salesforce/apex/ModelController.getActiveModelsWithVariants';

export default class ModelGrid extends NavigationMixin(LightningElement) {

    @track models    = [];
    @track isLoading = true;

    @wire(getActiveModelsWithVariants)
    wiredModels({ data, error }) {
        if (data) {
            this.models = data.slice(0, 6).map(m => ({
                id:          m.id,
                name:        m.name,
                description: m.description || '',
                img:         m.imageUrl || '',
                fuelType:    m.fuelType || '',
                transmission: m.transmission || '',
                variantCount: m.variantCount || 0,
                startingPrice: m.startingPrice
                    ? this.formatPrice(m.startingPrice) : 'N/A'
            }));
            this.isLoading = false;
        }
        if (error) {
            console.error('modelGrid:', error);
            this.isLoading = false;
        }
    }

    formatPrice(price) {
        if (!price) return 'N/A';
        if (price >= 10000000) return (price / 10000000).toFixed(2) + ' Cr';
        if (price >= 100000)   return (price / 100000).toFixed(2) + ' L';
        return price.toLocaleString('en-IN');
    }

    handleViewAll() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Browse_Models__c' }
        });
    }

    handleExplore(event) {
        const modelId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Model_Detail__c' },
            state: { modelId: modelId }
        });
    }

    handleTestDrive(event) {
        const modelId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Test_Drive__c' },
            state: { modelId: modelId }
        });
    }
}