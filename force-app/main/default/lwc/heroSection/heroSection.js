import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getActiveModelsWithVariants from '@salesforce/apex/ModelController.getActiveModelsWithVariants';

export default class HeroSection extends NavigationMixin(LightningElement) {

    @track currentIdx = 0;
    @track slides     = [];
    @track isLoading  = true;
    timer;

    // ── Load top 3 active models as hero slides ──
    @wire(getActiveModelsWithVariants)
    wiredModels({ data, error }) {
        if (data) {
            this.slides = data.slice(0, 3).map((m, i) => ({
                id:      m.id,
                idx:     i,
                name:    m.name,
                desc:    m.description || 'Experience the drive of your life.',
                img:     m.imageUrl || '',
                price:   m.startingPrice
                    ? this.formatPrice(m.startingPrice) : '',
                fuelType: m.fuelType || '',
                modelId: m.id
            }));
            this.isLoading = false;
            this.startTimer();
        }
        if (error) {
            console.error('heroSection:', error);
            this.isLoading = false;
        }
    }

    get slideTransform() {
        return 'translateX(-' + (this.currentIdx * 100) + '%)';
    }

    get dots() {
        return this.slides.map((s, i) => ({
            idx: i,
            cls: i === this.currentIdx ? 'hdot on' : 'hdot'
        }));
    }

    connectedCallback()    { /* timer starts after wire */ }
    disconnectedCallback() { clearInterval(this.timer); }

    startTimer() {
        clearInterval(this.timer);
        if (this.slides.length > 1) {
            this.timer = setInterval(() => this.nextSlide(), 5000);
        }
    }

    nextSlide() { this.currentIdx = (this.currentIdx + 1) % this.slides.length; }
    prevSlide() { this.currentIdx = (this.currentIdx - 1 + this.slides.length) % this.slides.length; this.startTimer(); }
    handleDot(e) { this.currentIdx = parseInt(e.target.dataset.idx, 10); this.startTimer(); }

    handleBook(e) {
        const modelId = e.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Model_Detail__c' },
            state: { modelId: modelId }
        });
    }

    handleBrowse() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Browse_Models__c' }
        });
    }

    formatPrice(price) {
        if (!price) return '';
        if (price >= 10000000) return (price / 10000000).toFixed(2) + ' Cr';
        if (price >= 100000)   return (price / 100000).toFixed(2) + ' L';
        return price.toLocaleString('en-IN');
    }
}