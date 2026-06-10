import { LightningElement, track } from 'lwc';

export default class PartnerTestDrivesFilter extends LightningElement {
    @track active = 'all';
    btn(f) { return this.active === f ? 'filter-btn active' : 'filter-btn'; }
    get allClass()       { return this.btn('all'); }
    get requestedClass() { return this.btn('Requested'); }
    get confirmedClass() { return this.btn('Confirmed'); }
    get completedClass() { return this.btn('Completed'); }
    get cancelledClass() { return this.btn('Cancelled'); }

    handleFilter(e) {
        this.active = e.currentTarget.dataset.filter;
        this.dispatchEvent(new CustomEvent('filterchange', { detail: { filter: this.active } }));
    }
}