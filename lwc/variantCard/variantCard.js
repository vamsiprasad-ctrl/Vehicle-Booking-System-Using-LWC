import { LightningElement, api, track } from 'lwc';

const VAR_COLORS = {
    'Sierra Smart': ['#1a1a1a','#fff','#c0392b','#2980b9'],
    'Sierra Pure+': ['#888','#fff','#2c3e50','#e8a100'],
    'Sierra Adventure': ['#1a1a1a','#2980b9','#27ae60'],
    'Sierra Accomplished+': ['#1a1a1a','#8e44ad','#c0392b'],
    'Smart': ['#1a1a1a','#fff','#3498db'],
    'Smart+': ['#e74c3c','#fff','#2c3e50'],
    'Adventure': ['#1a1a1a','#8e44ad','#e67e22'],
    'Empowered+': ['#1a1a1a','#c0392b','#2980b9']
};

export default class VariantCard extends LightningElement {
    @api variant = {};
    @api selected = false;
    @track activeColor = 0;

    get cardClass() { return this.selected ? 'vcard on' : 'vcard'; }
    get badgeClass() { return 'vcard-bdg ' + (this.variant.badge === 'Popular' ? 'vb-pop' : 'vb-top'); }
    get fuelType()     { const p = (this.variant.f || '').split('·'); return p[0] ? p[0].trim() : 'N/A'; }
    get transmission() { const p = (this.variant.f || '').split('·'); return p[1] ? p[1].trim() : 'Auto'; }
    get priceFormatted() {
        if (!this.variant.p) return '';
        const l = this.variant.p / 100000;
        return 'Rs.' + (Number.isInteger(l) ? l : l.toFixed(2)) + 'L';
    }
    get colorDots() {
        const cols = VAR_COLORS[this.variant.n] || ['#1a1a1a','#888','#c0392b'];
        return cols.map((c, i) => ({ color: c, cls: i === this.activeColor ? 'cdot on' : 'cdot', style: 'background:' + c }));
    }

    handleSelect()  { this.dispatchEvent(new CustomEvent('select', { detail: { variant: this.variant }, bubbles: true, composed: true })); }
    handleColorPick(e) { e.stopPropagation(); const cols = VAR_COLORS[this.variant.n] || []; this.activeColor = cols.indexOf(e.target.dataset.color); }
    handleBook(e)   { e.stopPropagation(); this.dispatchEvent(new CustomEvent('book', { detail: { variant: this.variant }, bubbles: true, composed: true })); }
    handleEMI(e)    { e.stopPropagation(); this.dispatchEvent(new CustomEvent('emi', { detail: { variant: this.variant }, bubbles: true, composed: true })); }
}