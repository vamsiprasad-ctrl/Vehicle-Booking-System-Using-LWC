import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class VariantList extends NavigationMixin(LightningElement) {
    @api variants = [];
    @track selectedVariant = null;

    connectedCallback() { if (this.variants.length) this.selectedVariant = this.variants[0].n; }

    get variantsWithState() {
        return this.variants.map((v, i) => ({
            ...v,
            badge: i === 1 ? 'Popular' : (i === this.variants.length - 1 && this.variants.length > 2 ? 'Top' : null),
            selected: v.n === this.selectedVariant
        }));
    }

    handleSelect(e) {
        this.selectedVariant = e.detail.variant.n;
        this.dispatchEvent(new CustomEvent('variantselect', { detail: e.detail, bubbles: true, composed: true }));
    }
    handleBook(e) {
        this[NavigationMixin.Navigate]({ type: 'comm__namedPage', attributes: { name: 'Test_Drive__c' }, state: { variant: e.detail.variant.n } });
    }
    handleEMI(e) {
        const p = e.detail.variant.p;
        const emi = Math.round((p * 1.09) / 60);
        alert('Estimated EMI for ' + e.detail.variant.n + ': Rs.' + emi.toLocaleString('en-IN') + '/month (60 months @ 9% p.a.)');
    }
}